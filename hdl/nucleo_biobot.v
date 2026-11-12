`timescale 1ns / 1ps
// ============================================================================
// nucleo_biobot.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Nucleo digital de la mochila: todo lo que iria en el chip. Recibe los
// pixeles de la matriz termica y la actividad de la IMU, y decide cuando
// estimular al insecto y cuando avisar que encontro a una persona.
//
//   pixeles --> ventana_termica --> media_movil4 --> detector_presencia --+
//                    |  (cuadro = tick de todo lo demas)                  |
//   actividad -----> detector_quietud ------------------------------------+--> fsm_politica
//                    lfsr16 ----------------------------------------------+        |
//                                                                         gen_estimulo --> electrodos / LED
//
// No depende de la tarjeta: el modulo superior le entrega los pixeles ya
// separados (por UART en la DE10-Lite, por I2C en la mochila).
// ============================================================================
module nucleo_biobot #(
    parameter CLK_FREQ = 50000000,
    parameter F_EST    = 50,
    parameter N_PULSOS = 25
)(
    input  wire        clk,
    input  wire        reset,         // asincrono, activo en alto
    input  wire        habilita,      // 1 = mision en marcha
    // matriz termica
    input  wire        px_valido,
    input  wire [7:0]  px_temp,
    input  wire        px_ultimo,
    // IMU
    input  wire [7:0]  actividad,     // debe estar estable al cerrar el cuadro
    // estimulo
    output wire [2:0]  fase_a,
    output wire [2:0]  fase_b,
    output wire [2:0]  led_on,
    // estado y telemetria
    output wire        tick,          // un pulso por cuadro procesado
    output wire [2:0]  estado,
    output wire        disparo,
    output wire [1:0]  canal,
    output wire        alerta,
    output wire        baliza,
    output wire        quieto,
    output wire        pre,
    output wire [6:0]  n_fil,         // pixeles calientes, filtrado
    output wire [7:0]  fondo,         // temperatura media del cuadro
    output wire [15:0] cuenta,
    output wire [15:0] n_est
);

wire [6:0]  n_cal;
wire [1:0]  lado;
wire        sobre, confirmado;
wire [15:0] azar;
wire        ocupado;

ventana_termica u_ventana (
    .clk(clk), .reset(reset),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo),
    .n_cal(n_cal), .lado(lado), .fondo(fondo), .cuadro(tick)
);

media_movil4 #(.W(7)) u_media (
    .clk(clk), .reset(reset), .tick(tick), .dato(n_cal), .media(n_fil)
);

detector_presencia #(.W(7)) u_presencia (
    .clk(clk), .reset(reset), .tick(tick), .n_fil(n_fil),
    .pre(pre), .sobre(sobre), .confirmado(confirmado)
);

detector_quietud u_quietud (
    .clk(clk), .reset(reset), .tick(tick), .actividad(actividad), .quieto(quieto)
);

lfsr16 u_lfsr (
    .clk(clk), .reset(reset), .tick(tick), .q(azar)
);

fsm_politica u_fsm (
    .clk(clk), .reset(reset), .tick(tick), .habilita(habilita),
    .quieto(quieto), .pre(pre), .sobre(sobre), .confirmado(confirmado),
    .lado(lado), .azar(azar),
    .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .cuenta(cuenta), .n_est(n_est)
);

gen_estimulo #(.CLK_FREQ(CLK_FREQ), .F_EST(F_EST), .N_PULSOS(N_PULSOS)) u_gen (
    .clk(clk), .reset(reset), .disparo(disparo), .canal(canal),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on), .ocupado(ocupado)
);

endmodule
