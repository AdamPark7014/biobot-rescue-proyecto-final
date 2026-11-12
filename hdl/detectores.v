`timescale 1ns / 1ps
// ============================================================================
// detectores.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Tres bloques pequenos que preparan las senales para la maquina de estados.
// Todos avanzan una vez por cuadro termico (entrada tick, 10 veces por
// segundo con la AMG8833).
//
//   media_movil4        promedio de los ultimos 4 conteos de pixeles calientes
//   detector_presencia  compara ese promedio con dos umbrales y confirma
//   detector_quietud    decide si el insecto esta quieto a partir de la IMU
//   lfsr16              numeros seudoaleatorios para los giros al azar
// ============================================================================

// ----------------------------------------------------------------------------
// Promedio movil de 4 muestras. Quita el parpadeo que mete el vaiven del
// insecto al caminar (el cuerpo oscila entre 3 y 9 Hz). La suma de cuatro
// valores se divide entre 4 con un corrimiento de dos bits.
// ----------------------------------------------------------------------------
module media_movil4 #(
    parameter W = 7                   // bits de cada muestra
)(
    input  wire         clk,
    input  wire         reset,
    input  wire         tick,         // pulso: hay una muestra nueva
    input  wire [W-1:0] dato,
    output wire [W-1:0] media
);

reg [W-1:0] m0, m1, m2, m3;           // ventana: m0 es la mas reciente
wire [W+1:0] suma = m0 + m1 + m2 + m3;
assign media = suma[W+1:2];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        m0 <= 0; m1 <= 0; m2 <= 0; m3 <= 0;
    end else if (tick) begin
        m3 <= m2;
        m2 <= m1;
        m1 <= m0;
        m0 <= dato;
    end
end

endmodule

// ----------------------------------------------------------------------------
// Detector de presencia. Trabaja con el conteo filtrado de pixeles calientes.
//   pre         hay una mancha pequena: conviene acercarse
//   sobre       la mancha ya es grande
//   confirmado  la mancha fue grande N_CONF cuadros seguidos: es una deteccion
// ----------------------------------------------------------------------------
module detector_presencia #(
    parameter W      = 7,
    parameter N_PRE  = 2,             // pixeles para empezar a acercarse
    parameter N_DET  = 8,             // pixeles para declarar presencia
    parameter N_CONF = 4              // cuadros seguidos que se exigen
)(
    input  wire         clk,
    input  wire         reset,
    input  wire         tick,
    input  wire [W-1:0] n_fil,        // conteo filtrado
    output wire         pre,
    output wire         sobre,
    output wire         confirmado
);

reg [3:0] seguidos;                   // cuadros seguidos con sobre = 1

assign pre        = (n_fil >= N_PRE);
assign sobre      = (n_fil >= N_DET);
assign confirmado = (seguidos >= N_CONF);

always @(posedge clk or posedge reset) begin
    if (reset)
        seguidos <= 0;
    else if (tick) begin
        if (!sobre)
            seguidos <= 0;
        else if (seguidos != 4'd15)
            seguidos <= seguidos + 4'd1;
    end
end

endmodule

// ----------------------------------------------------------------------------
// Detector de quietud. La entrada es la "actividad" que entrega la IMU en
// cada cuadro (magnitud del cambio de aceleracion, 0 a 255). Si se mantiene
// por debajo de U_ACT durante N_QUIETO cuadros seguidos, el insecto esta
// quieto. En cuanto hay actividad, la salida baja de inmediato.
// ----------------------------------------------------------------------------
module detector_quietud #(
    parameter U_ACT    = 8'd8,        // umbral de actividad
    parameter N_QUIETO = 4'd10        // cuadros seguidos (1 s a 10 Hz)
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       tick,
    input  wire [7:0] actividad,
    output wire       quieto
);

reg [3:0] cnt;

assign quieto = (cnt >= N_QUIETO);

always @(posedge clk or posedge reset) begin
    if (reset)
        cnt <= 0;
    else if (tick) begin
        if (actividad >= U_ACT)
            cnt <= 0;
        else if (cnt != 4'd15)
            cnt <= cnt + 4'd1;
    end
end

endmodule

// ----------------------------------------------------------------------------
// Registro de corrimiento con realimentacion lineal de 16 bits
// (x^16 + x^14 + x^13 + x^11 + 1, periodo 65 535). Da los numeros con que la
// politica decide cuando y hacia donde girar al azar.
// ----------------------------------------------------------------------------
module lfsr16 #(
    parameter SEMILLA = 16'hACE1      // cualquier valor distinto de cero
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        tick,
    output reg  [15:0] q
);

wire realim = q[0] ^ q[2] ^ q[3] ^ q[5];

always @(posedge clk or posedge reset) begin
    if (reset)
        q <= SEMILLA;
    else if (tick)
        q <= {realim, q[15:1]};
end

endmodule
