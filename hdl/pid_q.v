`timescale 1ns / 1ps

// PID
module pid_q #(
    parameter signed [15:0] KP         = 16'sd128,
    parameter signed [15:0] KI         = 16'sd13,
    parameter signed [15:0] KD         = 16'sd64,
    parameter integer       U_MAX      = 255,
    parameter integer       ANTIWINDUP = 1
) (
    input  wire               clk,
    input  wire               reset,
    input  wire               tick,
    input  wire signed [15:0] referencia,
    input  wire signed [15:0] medida,
    output reg  signed [15:0] u,
    output reg                saturada
);

localparam signed [31:0] TOPE_U   = U_MAX;
localparam signed [39:0] TOPE_Q   = U_MAX * 256;
localparam signed [34:0] TOPE_INT = 35'sh03FFFFFFF;

reg  signed [16:0] e_prev;
reg  signed [31:0] integ;

// error y derivada
wire signed [16:0] e  = {referencia[15], referencia} - {medida[15], medida};
wire signed [17:0] de = {e[16], e} - {e_prev[16], e_prev};

wire signed [33:0] p_q = e  * KP;
wire signed [33:0] i_q = e  * KI;
wire signed [34:0] d_q = de * KD;

// suma
wire signed [39:0] suma  = {{6{p_q[33]}}, p_q} + {{8{integ[31]}}, integ} + {{5{d_q[34]}}, d_q};
wire signed [31:0] u_raw = suma[39:8];

// saturacion
wire arriba = (suma >  TOPE_Q);
wire abajo  = (suma < -TOPE_Q);

// anti-windup
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
