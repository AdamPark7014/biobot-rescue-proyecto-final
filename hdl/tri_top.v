`timescale 1ns / 1ps
// ============================================================================
// tri_top.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Modulos superiores de la red de deteccion y triangulacion (tri_red.v) para
// la DE10-Lite. Cada uno lleva una sonda de Quartus (In-System Sources and
// Probes) por el cable USB-Blaster: la terminal de la computadora
// (pc/terminal.tcl) lee los datos, mueve las cucarachas y puede hacer lo
// mismo que el reset, el boton y los interruptores. Botones e interruptores
// siguen funcionando igual.
//
// Pines de JP1: pin 35 TX, pin 33 TX (copia), pin 37 RX1, pin 39 RX2,
//               pines 30 y 12 tierra, pin 1 el tono propio (1, 2 o 4 kHz).
//
//   top_tri_mochila   ROL 1 = mochila A, ROL 2 = mochila B
//       KEY0 reset, KEY1 boton de ayuda (la persona lo aplasta)
//       SW5-SW0 temperatura que lee el sensor termico, en grados C (detecta de 35 a 38)
//       SW9-SW6 posicion de la cucaracha (16 posiciones fijas) si la terminal no la fija
//   top_tri_receptor  receptor del operador; manda el resumen a la PC por TX
//       KEY0 reset, SW1-SW0 vista: 00 r Pd, 01 persona X/Y, 10 distancia A-B, 11 rumbos
//   top_tri_rb        receptor con la mochila B dentro (para hacerlo con dos tarjetas):
//       SW5-SW0 temperatura de B, SW8-SW6 posicion de B (0 a 7), SW9 vista, KEY1 boton de B.
//       Manda las tramas de B por TX1 para que A las oiga y el resumen de la PC por TX2.
//
// Sonda (lectura), del bit mas alto al mas bajo:
//   mochila:  {oye_otra, pot_otra[15:0], pot_rec[15:0],
//              ROL[1:0], alerta, persona, rumbo_ok, estado[2:0], n_fil[6:0], rumbo_med[15:0],
//              temp[5:0], x[9:0], y[9:0], d_otra[9:0], d_rec[9:0], otra_detecta, otra_viva,
//              oye_rec, cuenta[1:0], LEDR[9:0]}                                             125 bits
//   receptor: {oye_a, oye_b, pot_a[15:0], pot_b[15:0], info_a[41:0], info_b[41:0],
//              perd_a[7:0], perd_b[7:0], malas[7:0],
//              2'd0, est_x[9:0], est_y[9:0], modo[2:0], n_ev[2:0], error[1:0], thA[9:0],
//              thB[9:0], d_ab[9:0], d_a[9:0], d_b[9:0], cuenta[1:0], enlaces[3:0], LEDR[9:0]} 238 bits
//   rb:       igual que el receptor con 2'd3 en los bits de rol                             238 bits
// Fuente de la mochila y de rb (36 bits): 35 reset, 34 boton, 33 usar la temperatura de la
//   fuente, 32 usar la posicion de la fuente, 31-22 x, 21-12 y, 5-0 temperatura.
// Fuente del receptor (13 bits): 12 reset, 10 usar la vista de la fuente, 1-0 vista.
// La sonda y la fuente se prueban sin tarjetas con sim/tb_sonda.v y sim/prueba_terminal.tcl.
// ============================================================================

module top_tri_mochila #(
    parameter integer ROL       = 1,
    parameter integer CLK_FREQ  = 50000000,     // solo se cambian en simulacion (sim/tb_sonda.v)
    parameter integer BAUD_RATE = 115200
) (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    input  wire       RX1,
    input  wire       RX2,
    output wire       TX1,
    output wire       TX2,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output wire       TONO                // tono propio, en el pin 1 de JP1 (para un zumbador)
);

// A queda girada 12 grados a la izquierda de la persona y B, 9 a la derecha
localparam [15:0] OFF = (ROL == 1) ? 16'd2185 : 16'd63898;

wire [35:0] fuente;
wire        alerta, persona, rumbo_ok, otra_viva, otra_detecta, oye_rec;
wire [2:0]  estado;
wire [6:0]  n_fil;
wire [15:0] rumbo_med, rumbo_real;
wire [7:0]  rango;
wire [5:0]  temp;
wire [9:0]  x, y, d_otra, d_rec;
wire [1:0]  cuenta;
wire [1:0]  rol = ROL[1:0];
wire        oye_otra;
wire [15:0] pot_otra, pot_rec;
wire [124:0] sonda = {oye_otra, pot_otra, pot_rec,
                      rol, alerta, persona, rumbo_ok, estado, n_fil, rumbo_med, temp, x, y, d_otra, d_rec,
                      otra_detecta, otra_viva, oye_rec, cuenta, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"), .sld_instance_index(0), .instance_id("TRIM"),
    .probe_width(125), .source_width(36), .source_initial_value("0"), .enable_metastability("NO")
) u_sonda (.probe(sonda), .source(fuente));

reg [1:0] s1 = 2'b11, s2 = 2'b11;
always @(posedge CLOCK_50) begin s1 <= {s1[0], RX1}; s2 <= {s2[0], RX2}; end
wire tx;
assign TX1 = tx;
assign TX2 = tx;

tri_mochila #(.ROL(ROL), .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .OFFSET(OFF)) u_mochila (
    .clk(CLOCK_50), .reset(~KEY[0] | fuente[35]), .boton(~KEY[1] | fuente[34]),
    .sw({SW[9:6], fuente[33] ? fuente[5:0] : SW[5:0]}),
    .pos_ext(fuente[32]), .x_ext(fuente[31:22]), .y_ext(fuente[21:12]),
    .rx1(s1[1]), .rx2(s2[1]), .tx(tx), .ledr(LEDR),
    .hex0(HEX0), .hex1(HEX1), .hex2(HEX2), .hex3(HEX3), .hex4(HEX4), .hex5(HEX5),
    .x_yo(x), .y_yo(y), .temp(temp), .d_rec(d_rec), .oye_rec(oye_rec), .oye_otra(oye_otra),
    .pot_rec(pot_rec), .pot_otra(pot_otra), .tono(TONO), .cuenta_pd(cuenta),
    .rumbo_med(rumbo_med), .rumbo_ok(rumbo_ok), .alerta(alerta),
    .persona(persona), .estado(estado), .n_fil(n_fil), .rango(rango), .rumbo_real(rumbo_real),
    .d_otra(d_otra), .otra_viva(otra_viva), .otra_detecta(otra_detecta)
);

endmodule

// ----------------------------------------------------------------------------
module top_tri_receptor #(
    parameter integer CLK_FREQ  = 50000000,     // solo se cambian en simulacion (sim/tb_sonda.v)
    parameter integer BAUD_RATE = 115200
) (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    input  wire       RX1,
    input  wire       RX2,
    output wire       TX1,
    output wire       TX2,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output wire       TONO                // tono propio, en el pin 1 de JP1 (para un zumbador)
);

wire [12:0] fuente;
wire [9:0]  est_x, est_y, tha, thb, d_ab, d_a, d_b;
wire [2:0]  modo, n_ev;
wire [1:0]  terr, cuenta;
wire [3:0]  enlaces;
wire [7:0]  perd_a, perd_b, malas;
wire [41:0] info_a, info_b;
wire        oye_a, oye_b;
wire [15:0] pot_a, pot_b;
wire [237:0] sonda = {oye_a, oye_b, pot_a, pot_b, info_a, info_b, perd_a, perd_b, malas,
                      2'd0, est_x, est_y, modo, n_ev, terr, tha, thb, d_ab, d_a, d_b, cuenta, enlaces, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"), .sld_instance_index(0), .instance_id("TRIR"),
    .probe_width(238), .source_width(13), .source_initial_value("0"), .enable_metastability("NO")
) u_sonda (.probe(sonda), .source(fuente));

reg [1:0] s1 = 2'b11, s2 = 2'b11;
always @(posedge CLOCK_50) begin s1 <= {s1[0], RX1}; s2 <= {s2[0], RX2}; end
wire tx_pc;
assign TX1 = tx_pc;                 // hacia la computadora (puente USB-serie o ESP32)
assign TX2 = tx_pc;

tri_receptor #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_receptor (
    .clk(CLOCK_50), .reset(~KEY[0] | fuente[12]), .vista(fuente[10] ? fuente[1:0] : SW[1:0]),
    .rx1(s1[1]), .rx2(s2[1]), .tx_pc(tx_pc), .ledr(LEDR),
    .hex0(HEX0), .hex1(HEX1), .hex2(HEX2), .hex3(HEX3), .hex4(HEX4), .hex5(HEX5),
    .est_x(est_x), .est_y(est_y), .modo(modo), .n_ev(n_ev), .tri_error(terr), .tha_o(tha), .thb_o(thb),
    .d_ab(d_ab), .d_a(d_a), .d_b(d_b), .cuenta_pd(cuenta), .enlaces(enlaces),
    .perd_a(perd_a), .perd_b(perd_b), .malas(malas), .info_a(info_a), .info_b(info_b),
    .oye_a(oye_a), .oye_b(oye_b), .pot_a(pot_a), .pot_b(pot_b), .tono(TONO)
);

endmodule

// ----------------------------------------------------------------------------
// Receptor y mochila B en la misma tarjeta.
// ----------------------------------------------------------------------------
module top_tri_rb #(
    parameter integer CLK_FREQ  = 50000000,     // solo se cambian en simulacion (sim/tb_sonda.v)
    parameter integer BAUD_RATE = 115200
) (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    input  wire       RX1,
    input  wire       RX2,
    output wire       TX1,
    output wire       TX2,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output wire       TONO                // tono propio, en el pin 1 de JP1 (para un zumbador)
);

wire [35:0] fuente;
wire [9:0]  est_x, est_y, tha, thb, d_ab, d_a, d_b;
wire [2:0]  modo, n_ev;
wire [1:0]  terr, cuenta;
wire [3:0]  enlaces;
wire [7:0]  perd_a, perd_b, malas;
wire [41:0] info_a, info_b;
wire        oye_a, oye_b;
wire [15:0] pot_a, pot_b;
wire [237:0] sonda = {oye_a, oye_b, pot_a, pot_b, info_a, info_b, perd_a, perd_b, malas,
                      2'd3, est_x, est_y, modo, n_ev, terr, tha, thb, d_ab, d_a, d_b, cuenta, enlaces, LEDR};

altsource_probe #(
    .sld_auto_instance_index("YES"), .sld_instance_index(0), .instance_id("TRRB"),
    .probe_width(238), .source_width(36), .source_initial_value("0"), .enable_metastability("NO")
) u_sonda (.probe(sonda), .source(fuente));

reg [1:0] s1 = 2'b11;
always @(posedge CLOCK_50) s1 <= {s1[0], RX1};
wire reset = ~KEY[0] | fuente[35];
wire tx_b, tx_pc;

tri_mochila #(.ROL(2), .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .OFFSET(16'd63898)) u_b (
    .clk(CLOCK_50), .reset(reset), .boton(~KEY[1] | fuente[34]),
    .sw({1'b0, SW[8:6], fuente[33] ? fuente[5:0] : SW[5:0]}),
    .pos_ext(fuente[32]), .x_ext(fuente[31:22]), .y_ext(fuente[21:12]),
    .rx1(s1[1]), .rx2(1'b1), .tx(tx_b), .ledr(),
    .hex0(), .hex1(), .hex2(), .hex3(), .hex4(), .hex5(),
    .x_yo(), .y_yo(), .temp(), .d_rec(), .oye_rec(), .oye_otra(), .pot_rec(), .pot_otra(), .tono(),
    .cuenta_pd(),
    .rumbo_med(), .rumbo_ok(), .alerta(), .persona(), .estado(), .n_fil(),
    .rango(), .rumbo_real(), .d_otra(), .otra_viva(), .otra_detecta()
);

tri_receptor #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_receptor (
    .clk(CLOCK_50), .reset(reset), .vista({1'b0, SW[9]}),
    .rx1(s1[1]), .rx2(tx_b), .tx_pc(tx_pc), .ledr(LEDR),
    .hex0(HEX0), .hex1(HEX1), .hex2(HEX2), .hex3(HEX3), .hex4(HEX4), .hex5(HEX5),
    .est_x(est_x), .est_y(est_y), .modo(modo), .n_ev(n_ev), .tri_error(terr), .tha_o(tha), .thb_o(thb),
    .d_ab(d_ab), .d_a(d_a), .d_b(d_b), .cuenta_pd(cuenta), .enlaces(enlaces),
    .perd_a(perd_a), .perd_b(perd_b), .malas(malas), .info_a(info_a), .info_b(info_b),
    .oye_a(oye_a), .oye_b(oye_b), .pot_a(pot_a), .pot_b(pot_b), .tono(TONO)
);

assign TX1 = tx_b;                  // B hacia A (pin 35 -> pin 37 de A)
assign TX2 = tx_pc;                 // resumen hacia la computadora (pin 33)

endmodule
