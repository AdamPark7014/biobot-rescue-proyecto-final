`timescale 1ns / 1ps

// media movil
module media_movil4 #(
    parameter W = 7
)(
    input  wire         clk,
    input  wire         reset,
    input  wire         tick,
    input  wire [W-1:0] dato,
    output wire [W-1:0] media
);

reg [W-1:0] m0, m1, m2, m3;
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

// presencia
module detector_presencia #(
    parameter W      = 7,
    parameter N_PRE  = 2,
    parameter N_DET  = 8,
    parameter N_CONF = 4
)(
    input  wire         clk,
    input  wire         reset,
    input  wire         tick,
    input  wire [W-1:0] n_fil,
    output wire         pre,
    output wire         sobre,
    output wire         confirmado
);

reg [3:0] seguidos;

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

// quietud
module detector_quietud #(
    parameter U_ACT    = 8'd8,
    parameter N_QUIETO = 4'd10
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

// LFSR
module lfsr16 #(
    parameter SEMILLA = 16'hACE1
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
