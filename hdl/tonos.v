`timescale 1ns / 1ps
// ============================================================================
// tonos.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Localizacion por tonos. Cada nodo emite todo el tiempo un tono propio y
// escucha los de los demas; con saber a quien oye, sabe quien le queda cerca.
//
//   nodo 0  receptor   4 kHz
//   nodo 1  mochila A  1 kHz
//   nodo 2  mochila B  2 kHz
//
// El microfono se muestrea a 16 kHz. Cada 64 muestras (4 ms) tres filtros de
// Goertzel miden la potencia en 1, 2 y 4 kHz (son las lineas 4, 8 y 16 de una
// transformada de 64 puntos, asi que un tono no se cuela en el filtro de otro).
// El filtro de Goertzel es un IIR de segundo orden:
//     s[n] = x[n] + c * s[n-1] - s[n-2],   c = 2 cos(2 pi k / 64)
//     potencia = s[N-1]^2 + s[N-2]^2 - c * s[N-1] * s[N-2]
// Un tono se da por oido si su potencia pasa de UMBRAL en dos bloques
// seguidos, y por perdido si queda debajo en dos bloques seguidos.
//
// El canal acustico va simulado: la entrada presente[i] dice si el tono del
// nodo i llega hasta aqui (lo decide quien instancia el modulo, con la
// distancia). Con eso se arma la senal del microfono: la suma de las ondas
// cuadradas que llegan (amplitud 4) mas un ruido de +-1. Con un microfono
// real, esa suma se sustituye por las muestras del convertidor.
// ============================================================================
module tri_tonos #(
    parameter integer CLK_FREQ = 50000000,
    parameter integer FS       = 16000,        // muestras por segundo
    parameter integer YO       = 1,            // 0 receptor, 1 mochila A, 2 mochila B
    parameter integer UMBRAL   = 4000          // potencia minima para dar un tono por oido
) (
    input  wire        clk,
    input  wire        reset,
    input  wire [2:0]  presente,               // canal simulado: llega el tono del nodo i
    output wire        tono,                   // tono propio (onda cuadrada), para un zumbador
    output reg  [2:0]  oye,                    // tonos oidos (el propio siempre en 0)
    output reg  [15:0] pot0,                   // potencia medida en 4 kHz (receptor)
    output reg  [15:0] pot1,                   // en 1 kHz (mochila A)
    output reg  [15:0] pot2                    // en 2 kHz (mochila B)
);

localparam integer DIV = CLK_FREQ / FS;

// c = 2 cos(2 pi k / 64) en Q2.14
localparam signed [15:0] C_4K = 16'sd0;        // k = 16
localparam signed [15:0] C_1K = 16'sd30274;    // k = 4:  1.847759
localparam signed [15:0] C_2K = 16'sd23170;    // k = 8:  1.414214

// ---- reloj de muestras y cuenta dentro del bloque
reg [15:0] c_div;
reg        muestra;
reg [5:0]  n;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_div <= 16'd0; muestra <= 1'b0; end
    else if (c_div >= DIV - 1) begin c_div <= 16'd0; muestra <= 1'b1; end
    else begin c_div <= c_div + 16'd1; muestra <= 1'b0; end
end

// ---- las tres ondas cuadradas, cada una con su fase
wire [5:0] n1 = n + 6'd3;
wire [5:0] n2 = n + 6'd1;
wire       sq0 = n[1];                         // 4 kHz: periodo de 4 muestras
wire       sq1 = n1[3];                        // 1 kHz: periodo de 16 muestras
wire       sq2 = n2[2];                        // 2 kHz: periodo de 8 muestras
assign tono = (YO == 0) ? sq0 : (YO == 1) ? sq1 : sq2;

// ---- microfono simulado: suma de los tonos que llegan, mas ruido
// El canal se guarda en un registro: asi la cuenta de la distancia (que decide que tonos
// llegan) no queda en la misma ruta que la aritmetica de los filtros.
reg  [2:0]  canal;
always @(posedge clk or posedge reset) begin
    if (reset) canal <= 3'b000;
    else       canal <= presente;
end
reg  [15:0] azar;
wire        azar_bit = azar[15] ^ azar[13] ^ azar[12] ^ azar[10];
wire signed [5:0] ruido = (azar[1:0] == 2'b01) ? 6'sd1 : (azar[1:0] == 2'b10) ? -6'sd1 : 6'sd0;
wire signed [5:0] t0 = (canal[0] && YO != 0) ? (sq0 ? 6'sd4 : -6'sd4) : 6'sd0;
wire signed [5:0] t1 = (canal[1] && YO != 1) ? (sq1 ? 6'sd4 : -6'sd4) : 6'sd0;
wire signed [5:0] t2 = (canal[2] && YO != 2) ? (sq2 ? 6'sd4 : -6'sd4) : 6'sd0;
wire signed [5:0] x  = t0 + t1 + t2 + ruido;

// ---- tres filtros de Goertzel
reg  signed [17:0] a1, a2;                     // 4 kHz: s[n-1], s[n-2]
reg  signed [17:0] b1, b2;                     // 1 kHz
reg  signed [17:0] d1, d2;                     // 2 kHz
wire signed [33:0] pb = C_1K * b1;
wire signed [33:0] pd = C_2K * d1;
wire signed [17:0] cb = pb[31:14];             // c * s[n-1], sin los 14 bits de fraccion
wire signed [17:0] cd = pd[31:14];
wire signed [17:0] xe = {{12{x[5]}}, x};
wire signed [17:0] a0 = xe - a2;               // con c = 0
wire signed [17:0] b0 = xe + cb - b2;
wire signed [17:0] d0 = xe + cd - d2;

reg  [1:0]  fase;                              // 0 filtrando, 1 y 2 cierre del bloque
reg  signed [17:0] mb, md;                     // c * s[N-1], guardado
reg  signed [35:0] pa_r, pb_r, pd_r;           // potencias
reg  [1:0]  h0, h1, h2;                        // historia de los dos ultimos bloques

function [15:0] satura16;
    input signed [35:0] p;
    satura16 = p[35] ? 16'd0 : (|p[34:16]) ? 16'hFFFF : p[15:0];
endfunction

always @(posedge clk or posedge reset) begin
    if (reset) begin
        n <= 6'd0; azar <= 16'hACE1; fase <= 2'd0;
        a1 <= 0; a2 <= 0; b1 <= 0; b2 <= 0; d1 <= 0; d2 <= 0;
        mb <= 0; md <= 0; pa_r <= 0; pb_r <= 0; pd_r <= 0;
        h0 <= 2'b00; h1 <= 2'b00; h2 <= 2'b00;
        oye <= 3'b000; pot0 <= 16'd0; pot1 <= 16'd0; pot2 <= 16'd0;
    end else begin
        case (fase)
            2'd0: if (muestra) begin
                      azar <= {azar[14:0], azar_bit};
                      a2 <= a1; a1 <= a0;
                      b2 <= b1; b1 <= b0;
                      d2 <= d1; d1 <= d0;
                      n  <= n + 6'd1;
                      if (n == 6'd63) fase <= 2'd1;
                  end
            2'd1: begin                        // c * s[N-1] ya con el ultimo valor
                      mb <= cb; md <= cd;
                      fase <= 2'd2;
                  end
            2'd2: begin
                      pa_r <= a1 * a1 + a2 * a2;
                      pb_r <= b1 * b1 + b2 * b2 - mb * b2;
                      pd_r <= d1 * d1 + d2 * d2 - md * d2;
                      fase <= 2'd3;
                  end
            default: begin
                      pot0 <= satura16(pa_r); pot1 <= satura16(pb_r); pot2 <= satura16(pd_r);
                      h0 <= {h0[0], (pa_r > UMBRAL)};
                      h1 <= {h1[0], (pb_r > UMBRAL)};
                      h2 <= {h2[0], (pd_r > UMBRAL)};
                      if ({h0[0], (pa_r > UMBRAL)} == 2'b11) oye[0] <= (YO != 0);
                      if ({h0[0], (pa_r > UMBRAL)} == 2'b00) oye[0] <= 1'b0;
                      if ({h1[0], (pb_r > UMBRAL)} == 2'b11) oye[1] <= (YO != 1);
                      if ({h1[0], (pb_r > UMBRAL)} == 2'b00) oye[1] <= 1'b0;
                      if ({h2[0], (pd_r > UMBRAL)} == 2'b11) oye[2] <= (YO != 2);
                      if ({h2[0], (pd_r > UMBRAL)} == 2'b00) oye[2] <= 1'b0;
                      a1 <= 0; a2 <= 0; b1 <= 0; b2 <= 0; d1 <= 0; d2 <= 0;
                      fase <= 2'd0;
                  end
        endcase
    end
end

endmodule
