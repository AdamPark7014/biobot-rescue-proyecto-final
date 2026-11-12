`timescale 1ns / 1ps
// ============================================================================
// top_lab_sondas.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Envolturas de laboratorio para las dos tarjetas. No cambian nada del
// diseno: solo le cuelgan una sonda de Quartus (In-System Sources and
// Probes) que viaja por el mismo cable USB-Blaster. Con ella la computadora
// puede leer lo que muestran los LED y los displays, y hacer lo mismo que los
// interruptores y el boton de reset, para probar las tarjetas sin tocarlas.
//
//   sonda  (lectura)    {displays, LEDR}, tal como se ven en la tarjeta
//   fuente (escritura)  bit 7      reset, igual que KEY0
//                       bit 0      mochila: mision en marcha, igual que SW0
//                       bits 2-1   insecto: escenario, igual que SW2-SW1
//
// Los interruptores y el boton siguen funcionando: la fuente solo se suma.
// El script que la usa es sim/prueba_tarjetas.tcl.
// ============================================================================

module top_lab_mochila (
    input  wire       CLOCK_50,
    input  wire       RESET_N,
    input  wire       SW0,
    input  wire       UART_RX,
    output wire       UART_TX,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3
);

wire [7:0]  fuente;
wire [37:0] sonda = {HEX3, HEX2, HEX1, HEX0, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"),
    .sld_instance_index(0),
    .instance_id("MOCH"),
    .probe_width(38),
    .source_width(8),
    .source_initial_value("0"),
    .enable_metastability("NO")
) u_sonda (
    .probe(sonda),
    .source(fuente)
);

top_biobot_de10lite u_mochila (
    .CLOCK_50(CLOCK_50),
    .RESET_N(RESET_N & ~fuente[7]),
    .SW0(SW0 | fuente[0]),
    .UART_RX(UART_RX), .UART_TX(UART_TX), .LEDR(LEDR),
    .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3)
);

endmodule

// ----------------------------------------------------------------------------
// Demostracion en una sola tarjeta, con sonda.
//   fuente: bit 7 reset, bit 3 rapido (SW9), bits 2-1 escenario, bit 0 mision
// ----------------------------------------------------------------------------
module top_lab_demo (
    input  wire       CLOCK_50,
    input  wire       RESET_N,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [2:0] ESTIMULO
);

wire [7:0]  fuente;
wire [51:0] sonda = {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"),
    .sld_instance_index(0),
    .instance_id("DEMO"),
    .probe_width(52),
    .source_width(8),
    .source_initial_value("0"),
    .enable_metastability("NO")
) u_sonda (
    .probe(sonda),
    .source(fuente)
);

top_demo_de10lite u_demo (
    .CLOCK_50(CLOCK_50),
    .RESET_N(RESET_N & ~fuente[7]),
    .SW({SW[9] | fuente[3], SW[8:3], SW[2:0] | fuente[2:0]}),
    .LEDR(LEDR),
    .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
    .ESTIMULO(ESTIMULO)
);

endmodule

// ----------------------------------------------------------------------------
module top_lab_insecto (
    input  wire       CLOCK_50,
    input  wire       RESET_N,
    input  wire [9:0] SW,
    input  wire       UART_RX,
    output wire       UART_TX,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5
);

wire [7:0]  fuente;
wire [51:0] sonda = {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"),
    .sld_instance_index(0),
    .instance_id("INSE"),
    .probe_width(52),
    .source_width(8),
    .source_initial_value("0"),
    .enable_metastability("NO")
) u_sonda (
    .probe(sonda),
    .source(fuente)
);

top_insecto_de10lite u_insecto (
    .CLOCK_50(CLOCK_50),
    .RESET_N(RESET_N & ~fuente[7]),
    .SW({SW[9:3], SW[2:1] | fuente[2:1], SW[0]}),
    .UART_RX(UART_RX), .UART_TX(UART_TX), .LEDR(LEDR),
    .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5)
);

endmodule
