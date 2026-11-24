`timescale 1ns / 1ps

// nucleo
module nucleo_biobot #(
    parameter CLK_FREQ = 50000000,
    parameter F_EST    = 50,
    parameter N_PULSOS = 25,
    // ventana de piel
    parameter [7:0] T_MIN = 8'd112,
    parameter [7:0] T_MAX = 8'd152,
    parameter [7:0] DELTA = 8'd8
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        habilita,
    // matriz termica
    input  wire        px_valido,
    input  wire [7:0]  px_temp,
    input  wire        px_ultimo,
    // IMU
    input  wire [7:0]  actividad,
    // estimulo
    output wire [2:0]  fase_a,
    output wire [2:0]  fase_b,
    output wire [2:0]  led_on,
    // estado y telemetria
    output wire        tick,
    output wire [2:0]  estado,
    output wire        disparo,
    output wire [1:0]  canal,
    output wire        alerta,
    output wire        baliza,
    output wire        quieto,
    output wire        pre,
    output wire [6:0]  n_fil,
    output wire [7:0]  fondo,
    output wire [15:0] cuenta,
    output wire [15:0] n_est
);

wire [6:0]  n_cal;
wire [1:0]  lado;
wire        sobre, confirmado;
wire [15:0] azar;
wire        ocupado;

ventana_termica #(.T_MIN(T_MIN), .T_MAX(T_MAX), .DELTA(DELTA)) u_ventana (
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
