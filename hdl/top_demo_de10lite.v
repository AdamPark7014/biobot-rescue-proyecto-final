`timescale 1ns / 1ps
// ============================================================================
// top_demo_de10lite.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Demostracion en UNA sola DE10-Lite, sin ESP32 ni sensor. Dentro de la
// tarjeta van las dos mitades:
//
//   insecto_sim  -- pixeles y actividad -->  nucleo_biobot
//        ^                                        |
//        +-------------- estimulos ---------------+
//
// El insecto de prueba genera lo que veria la matriz termica y reacciona a
// los estimulos; el nucleo es exactamente el mismo que se verifico contra el
// modelo de referencia. El lazo queda cerrado dentro del chip.
//
//   KEY0        reset (reinicia la mision y la escena)
//   SW0         1 = mision en marcha
//   SW2-SW1     escenario: 00 sin persona, 01 persona, 10 objeto caliente,
//               11 insecto que no responde
//   SW9         1 = ocho veces mas rapido (80 cuadros por segundo)
//
//   LEDR[2:0]   estimulo activo: avance, izquierda, derecha
//   LEDR[3]     el nucleo ve al insecto quieto
//   LEDR[4]     mancha de calor a la vista
//   LEDR[7:5]   estado de la politica
//   LEDR[8]     cambia con cada cuadro
//   LEDR[9]     alerta: persona detectada
//   HEX0        estado (0 reposo, 1 explorar, 2 reactivar, 3 reorientar,
//               4 acercar, 5 confirmar, 6 alertar, 7 descanso)
//   HEX1        estimulos acumulados en el presupuesto (0 a C)
//   HEX3-HEX2   pixeles calientes, filtrado (hexadecimal)
//   HEX5-HEX4   distancia a la persona en decimetros; "--" si no hay persona
//
//   ESTIMULO[2:0]  los mismos tres canales en GPIO_0, GPIO_1 y GPIO_2 (pines
//               1, 2 y 3 de JP1), por si se conectan LED externos con su
//               resistencia. No hace falta conectar nada para la prueba.
// ============================================================================
module top_demo_de10lite #(
    parameter CLK_FREQ = 50000000,
    parameter F_EST    = 50,
    parameter N_PULSOS = 25
)(
    input  wire       CLOCK_50,
    input  wire       RESET_N,        // KEY0, activo en bajo
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

localparam integer PERIODO_NORMAL = CLK_FREQ / 10;    // 10 cuadros por segundo
localparam integer PERIODO_RAPIDO = CLK_FREQ / 80;    // 80 cuadros por segundo

wire reset = ~RESET_N;

// Los interruptores no estan sincronizados con el reloj: dos flip-flops
reg [9:0] sw_meta, sw;
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        sw_meta <= 10'd0;
        sw      <= 10'd0;
    end else begin
        sw_meta <= SW;
        sw      <= sw_meta;
    end
end
wire       habilita  = sw[0];
wire [1:0] escenario = sw[2:1];
wire       rapido    = sw[9];

// ------------------------------------------------------- reloj de cuadros
// Cada periodo: se mandan los 64 pixeles al nucleo, uno por ciclo, y unos
// ciclos despues avanza el insecto. Asi el estimulo que el nucleo decide con
// este cuadro ya influye en el siguiente.
reg [31:0] cnt_periodo;
reg [6:0]  paso;                      // 0 en espera; 1..64 pixeles; 65..79 pausa; 80 avanza el insecto
reg        px_valido, px_ultimo;
reg [7:0]  px_temp;
reg        tick_insecto;

wire [31:0] periodo    = rapido ? PERIODO_RAPIDO : PERIODO_NORMAL;
wire        fin_cuenta = (cnt_periodo >= periodo - 32'd1);
wire [5:0]  idx        = paso[5:0] - 6'd1;            // pixel que se manda en este paso
wire [7:0]  px_insecto, actividad;

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        cnt_periodo  <= 32'd0;
        paso         <= 7'd0;
        px_valido    <= 1'b0;
        px_ultimo    <= 1'b0;
        px_temp      <= 8'd0;
        tick_insecto <= 1'b0;
    end else begin
        px_valido    <= 1'b0;
        px_ultimo    <= 1'b0;
        tick_insecto <= 1'b0;
        cnt_periodo  <= fin_cuenta ? 32'd0 : cnt_periodo + 32'd1;

        if (paso == 7'd0) begin
            if (fin_cuenta) paso <= 7'd1;
        end else if (paso <= 7'd64) begin
            px_valido <= 1'b1;
            px_temp   <= px_insecto;
            px_ultimo <= (paso == 7'd64);
            paso      <= paso + 7'd1;
        end else if (paso == 7'd80) begin
            tick_insecto <= 1'b1;
            paso         <= 7'd0;
        end else begin
            paso <= paso + 7'd1;
        end
    end
end

// ------------------------------------------------------------ las dos mitades
wire        tick, disparo, alerta, baliza, quieto, pre;
wire [2:0]  estado;
wire [1:0]  canal;
wire [6:0]  n_fil;
wire [7:0]  fondo;
wire [15:0] cuenta, n_est;
wire [2:0]  fase_a, fase_b, led_on;
wire [11:0] dist;
wire signed [7:0] rumbo;
wire        anda, hay_mancha;
wire [7:0]  n_obedecidos;

insecto_sim u_insecto (
    .clk(CLOCK_50), .reset(reset), .tick(tick_insecto), .escenario(escenario),
    .estimulo(disparo), .canal(canal), .idx(idx),
    .px_temp(px_insecto), .actividad(actividad),
    .dist(dist), .rumbo(rumbo), .anda(anda), .hay_mancha(hay_mancha),
    .n_obedecidos(n_obedecidos)
);

nucleo_biobot #(.CLK_FREQ(CLK_FREQ), .F_EST(F_EST), .N_PULSOS(N_PULSOS)) u_nucleo (
    .clk(CLOCK_50), .reset(reset), .habilita(habilita),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est)
);

// ----------------------------------------------------------------- salidas
reg latido;
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset)     latido <= 1'b0;
    else if (tick) latido <= ~latido;
end

assign LEDR     = {alerta, latido, estado, pre, quieto, led_on};
assign ESTIMULO = led_on;

// Distancia en decimetros: dist / 100 = dist * 41 / 4096, con error menor a 1
wire [17:0] dm_x    = dist * 6'd41;
wire [5:0]  dm      = dm_x[17:12];                    // 0 a 40
wire [3:0]  decenas = (dm >= 6'd40) ? 4'd4 : (dm >= 6'd30) ? 4'd3 : (dm >= 6'd20) ? 4'd2
                    : (dm >= 6'd10) ? 4'd1 : 4'd0;
wire [5:0]  resto   = dm - {decenas, 3'b000} - {1'b0, decenas, 1'b0};   // dm - 10*decenas
wire [6:0]  seg4, seg5;

hex7seg u_h0 (.x({1'b0, estado}),     .seg(HEX0));
hex7seg u_h1 (.x(cuenta[11:8]),       .seg(HEX1));
hex7seg u_h2 (.x(n_fil[3:0]),         .seg(HEX2));
hex7seg u_h3 (.x({1'b0, n_fil[6:4]}), .seg(HEX3));
hex7seg u_h4 (.x(resto[3:0]),         .seg(seg4));
hex7seg u_h5 (.x(decenas),            .seg(seg5));

// Sin persona en la escena los dos displays muestran un guion (solo el segmento g)
assign HEX4 = hay_mancha ? seg4 : 7'b0111111;
assign HEX5 = hay_mancha ? seg5 : 7'b0111111;

endmodule
