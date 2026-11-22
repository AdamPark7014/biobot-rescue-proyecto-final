`timescale 1ns / 1ps
// ============================================================================
// pid_q.v
// Proyecto final y practica 5 - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Controlador PID en punto fijo, forma posicional:
//     e[n] = referencia - medida
//     u[n] = KP * e[n] + KI * suma(e) + KD * (e[n] - e[n-1])
//
// Formatos:
//   referencia, medida, e, u   enteros de 16 bits con signo
//   KP, KI, KD          Q8.8 con signo (16 bits; 256 = 1.0)
//   integrador          32 bits con signo, en Q.8: guarda KI * suma(e)
// La salida se satura en +-U_MAX, que es lo que da el actuador.
//
// Integrador saturado (windup). Si el actuador se satura y el error persiste,
// el termino integral sigue creciendo sin efecto y despues tarda en
// descargarse: el sistema sobrepasa. Con ANTIWINDUP = 1 el integrador se
// congela mientras la salida esta saturada y el error empuja hacia el mismo
// lado (integracion condicional). Con ANTIWINDUP = 0 solo queda el tope que
// evita el desbordamiento de los 32 bits.
//
// Una muestra por pulso de tick. El calculo es combinacional (tres
// multiplicaciones de 16 x 16) y se registra en el mismo flanco.
// ============================================================================
module pid_q #(
    parameter signed [15:0] KP         = 16'sd128,   // 0.50
    parameter signed [15:0] KI         = 16'sd13,    // 0.051
    parameter signed [15:0] KD         = 16'sd64,    // 0.25
    parameter integer       U_MAX      = 255,        // tope de la salida
    parameter integer       ANTIWINDUP = 1
) (
    input  wire               clk,
    input  wire               reset,
    input  wire               tick,        // pulso: hay una muestra nueva
    input  wire signed [15:0] referencia,
    input  wire signed [15:0] medida,
    output reg  signed [15:0] u,
    output reg                saturada     // la salida quedo en el tope
);

localparam signed [31:0] TOPE_U   = U_MAX;
localparam signed [39:0] TOPE_Q   = U_MAX * 256;          // el mismo tope, en Q.8
localparam signed [34:0] TOPE_INT = 35'sh03FFFFFFF;      // el integrador no desborda los 32 bits

reg  signed [16:0] e_prev;
reg  signed [31:0] integ;                                // KI * suma(e), en Q.8

// error y derivada con un bit de guarda
wire signed [16:0] e  = {referencia[15], referencia} - {medida[15], medida};
wire signed [17:0] de = {e[16], e} - {e_prev[16], e_prev};

wire signed [33:0] p_q = e  * KP;                        // Q.8
wire signed [33:0] i_q = e  * KI;
wire signed [34:0] d_q = de * KD;

// suma en 40 bits: no desborda con los topes de arriba
wire signed [39:0] suma  = {{6{p_q[33]}}, p_q} + {{8{integ[31]}}, integ} + {{5{d_q[34]}}, d_q};
wire signed [31:0] u_raw = suma[39:8];                   // quita los 8 bits de fraccion

// la saturacion se decide con la suma completa, antes de quitar la fraccion
wire arriba = (suma >  TOPE_Q);
wire abajo  = (suma < -TOPE_Q);

// integracion condicional: no se integra si la salida esta saturada y el error empuja mas
wire congela = (ANTIWINDUP != 0) && ((arriba && !e[16] && (e != 0)) || (abajo && e[16]));

wire signed [34:0] integ_sig = {{3{integ[31]}}, integ} + {i_q[33], i_q};
wire signed [34:0] integ_top = (integ_sig >  TOPE_INT) ?  TOPE_INT :
                               (integ_sig < -TOPE_INT) ? -TOPE_INT : integ_sig;
wire signed [31:0] integ_lim = integ_top[31:0];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        e_prev <= 17'sd0; integ <= 32'sd0; u <= 16'sd0; saturada <= 1'b0;
    end else if (tick) begin
        e_prev   <= e;
        if (!congela) integ <= integ_lim;
        u        <= arriba ? TOPE_U[15:0] : abajo ? -TOPE_U[15:0] : u_raw[15:0];
        saturada <= arriba | abajo;
    end
end

endmodule
