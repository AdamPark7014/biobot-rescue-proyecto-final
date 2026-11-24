`timescale 1ns / 1ps

// receptor y B
module top_lab_red_rb (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    input  wire       RX1,
    input  wire       RX2,
    output wire       TX1,
    output wire       TX2,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

wire [12:0] fuente;
wire [53:0] sonda = {2'd3, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"),
    .sld_instance_index(0),
    .instance_id("RDRB"),
    .probe_width(54),
    .source_width(13),
    .source_initial_value("0"),
    .enable_metastability("NO")
) u_sonda (
    .probe(sonda),
    .source(fuente)
);

reg [1:0] s1 = 2'b11;
always @(posedge CLOCK_50) s1 <= {s1[0], RX1};

wire reset = ~KEY[0] | fuente[12];
wire tx_b;
wire [9:0] led_r, led_b;
wire [6:0] b0, b1, b2, b3, b4, b5;

// mochila B
red_nodo #(.ROL(2)) u_b (
    .clk(CLOCK_50), .reset(reset), .boton(~KEY[1] | fuente[11]),
    .pos(fuente[10] ? fuente[9:0] : SW),
    .rx1(s1[1]), .rx2(1'b1), .tx(tx_b), .ledr(led_b),
    .hex0(b0), .hex1(b1), .hex2(b2), .hex3(b3), .hex4(b4), .hex5(b5)
);

// receptor
red_nodo #(.ROL(0)) u_r (
    .clk(CLOCK_50), .reset(reset), .boton(1'b0), .pos(10'd0),
    .rx1(s1[1]), .rx2(tx_b), .tx(), .ledr(led_r),
    .hex0(HEX0), .hex1(HEX1), .hex2(HEX2), .hex3(HEX3), .hex4(HEX4), .hex5(HEX5)
);

assign LEDR = {led_r[9:8], led_b[7], led_b[9], led_b[8], led_r[4:0]};
assign TX1  = 1'b1;
assign TX2  = 1'b1;

endmodule
