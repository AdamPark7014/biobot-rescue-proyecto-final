`timescale 1ns / 1ps
// ============================================================================
// top_lab_red.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Una tarjeta de la red de tres (red_mochilas.v) con una sonda de Quartus
// (In-System Sources and Probes) que viaja por el cable USB-Blaster. Hace lo
// mismo que top_red_de10lite y ademas deja que la computadora lea los LED y
// los displays, y haga lo mismo que el reset, el boton y los interruptores.
//
//   ROL: 0 receptor, 1 mochila A, 2 mochila B (se fija en cada proyecto)
//   sonda  (lectura)    {ROL[1:0], HEX5..HEX0, LEDR}
//   fuente (escritura)  bit 12 reset, bit 11 boton, bit 10 usar la distancia
//                       de la fuente en lugar de SW, bits 9-0 esa distancia
// El script que la usa es sim/prueba_red.tcl.
// ============================================================================
module top_lab_red #(
    parameter integer ROL = 1
) (
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
wire [1:0]  rol = ROL;
wire [53:0] sonda = {rol, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"),
    .sld_instance_index(0),
    .instance_id("RED"),
    .probe_width(54),
    .source_width(13),
    .source_initial_value("0"),
    .enable_metastability("NO")
) u_sonda (
    .probe(sonda),
    .source(fuente)
);

reg [1:0] s1 = 2'b11, s2 = 2'b11;
always @(posedge CLOCK_50) begin s1 <= {s1[0], RX1}; s2 <= {s2[0], RX2}; end

wire tx;
assign TX1 = tx;
assign TX2 = tx;

red_nodo #(.ROL(ROL)) u_nodo (
    .clk(CLOCK_50),
    .reset(~KEY[0] | fuente[12]),
    .boton(~KEY[1] | fuente[11]),
    .pos(fuente[10] ? fuente[9:0] : SW),
    .rx1(s1[1]), .rx2(s2[1]), .tx(tx), .ledr(LEDR),
    .hex0(HEX0), .hex1(HEX1), .hex2(HEX2), .hex3(HEX3), .hex4(HEX4), .hex5(HEX5)
);

endmodule
