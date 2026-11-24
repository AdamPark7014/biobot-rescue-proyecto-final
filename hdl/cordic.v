`timescale 1ns / 1ps

// CORDIC
module cordic #(
    parameter integer W = 24,
    parameter integer N = 16
) (
    input  wire                clk,
    input  wire                reset,
    input  wire                start,
    input  wire                modo,
    input  wire signed [W-1:0] x0,
    input  wire signed [W-1:0] y0,
    input  wire        [15:0]  z0,
    output reg  signed [W-1:0] x,
    output reg  signed [W-1:0] y,
    output reg         [15:0]  z,
    output reg                 listo
);

// tabla de arcotangentes
function [15:0] atan_tab;
    input [4:0] i;
    case (i)
        5'd0:  atan_tab = 16'd8192;  5'd1:  atan_tab = 16'd4836;  5'd2:  atan_tab = 16'd2555;
        5'd3:  atan_tab = 16'd1297;  5'd4:  atan_tab = 16'd651;   5'd5:  atan_tab = 16'd326;
        5'd6:  atan_tab = 16'd163;   5'd7:  atan_tab = 16'd81;    5'd8:  atan_tab = 16'd41;
        5'd9:  atan_tab = 16'd20;    5'd10: atan_tab = 16'd10;    5'd11: atan_tab = 16'd5;
        5'd12: atan_tab = 16'd3;     5'd13: atan_tab = 16'd1;     5'd14: atan_tab = 16'd1;
        default: atan_tab = 16'd0;
    endcase
endfunction

// bits de guarda
localparam integer G  = 4;
localparam integer WI = W + G;

reg                 corriendo;
reg                 m;
reg        [4:0]    i;
reg signed [WI-1:0] xs, ys;
reg        [15:0]   zs;

wire signed [WI-1:0] x0g = {x0, {G{1'b0}}};
wire signed [WI-1:0] y0g = {y0, {G{1'b0}}};
wire signed [WI-1:0] xd  = xs >>> i;
wire signed [WI-1:0] yd  = ys >>> i;
wire        [15:0]   a   = atan_tab(i);
// sentido de giro
wire dir = m ? ~ys[WI-1] : ~zs[15];

reg signed [WI-1:0] xn, yn;
reg        [15:0]   zn;
always @(*) begin
    if (m) begin
        // vectorizacion
        if (dir) begin xn = xs + yd; yn = ys - xd; zn = zs + a; end
        else     begin xn = xs - yd; yn = ys + xd; zn = zs - a; end
    end else begin
        // rotacion
        if (dir) begin xn = xs - yd; yn = ys + xd; zn = zs - a; end
        else     begin xn = xs + yd; yn = ys - xd; zn = zs + a; end
    end
end

// redondeo
localparam signed [WI-1:0] MEDIO = {{(WI-G){1'b0}}, 1'b1, {(G-1){1'b0}}};
wire signed [WI-1:0] xr = xn + MEDIO;
wire signed [WI-1:0] yr = yn + MEDIO;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        corriendo <= 1'b0; m <= 1'b0; i <= 5'd0;
        xs <= 0; ys <= 0; zs <= 16'd0;
        x <= 0; y <= 0; z <= 16'd0; listo <= 1'b0;
    end else begin
        listo <= 1'b0;
        if (start) begin
            m <= modo;
            i <= 5'd0;
            corriendo <= 1'b1;
            if (modo) begin
                // vectorizacion
                if (x0[W-1]) begin xs <= -x0g; ys <= -y0g; zs <= 16'h8000; end
                else         begin xs <=  x0g; ys <=  y0g; zs <= 16'h0000; end
            end else begin
                // rotacion
                if (z0[15] ^ z0[14]) begin xs <= -x0g; ys <= -y0g; zs <= z0 + 16'h8000; end
                else                 begin xs <=  x0g; ys <=  y0g; zs <= z0; end
            end
        end else if (corriendo) begin
            xs <= xn; ys <= yn; zs <= zn;
            if (i == N - 1) begin
                corriendo <= 1'b0;
                listo     <= 1'b1;
                x <= xr[WI-1:G];
                y <= yr[WI-1:G];
                z <= zn;
            end
            i <= i + 5'd1;
        end
    end
end

endmodule

// divisor
module divisor_u #(
    parameter integer WN = 32,
    parameter integer WD = 16
) (
    input  wire          clk,
    input  wire          reset,
    input  wire          start,
    input  wire [WN-1:0] num,
    input  wire [WD-1:0] den,
    output reg  [WN-1:0] coc,
    output reg           listo
);

reg  [WN-1:0] q;
reg  [WD:0]   r;
reg  [WN-1:0] n;
reg  [7:0]    k;
reg           corriendo;

wire [WD:0] r_sh  = {r[WD-1:0], n[WN-1]};
wire        cabe  = (r_sh >= {1'b0, den});

always @(posedge clk or posedge reset) begin
    if (reset) begin
        q <= 0; r <= 0; n <= 0; k <= 0; corriendo <= 1'b0; coc <= 0; listo <= 1'b0;
    end else begin
        listo <= 1'b0;
        if (start) begin
            q <= 0; r <= 0; n <= num; k <= 0; corriendo <= 1'b1;
        end else if (corriendo) begin
            r <= cabe ? (r_sh - {1'b0, den}) : r_sh;
            q <= {q[WN-2:0], cabe};
            n <= {n[WN-2:0], 1'b0};
            if (k == WN - 1) begin
                corriendo <= 1'b0;
                listo     <= 1'b1;
                coc       <= {q[WN-2:0], cabe};
            end
            k <= k + 8'd1;
        end
    end
end

endmodule
