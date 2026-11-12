`timescale 1ns / 1ps
// ============================================================================
// top_biobot_de10lite.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Prototipo del nucleo de la mochila en la DE10-Lite. El ESP32 (o la PC por
// el puente de la Practica 4) manda cada cuadro de la matriz termica y la
// actividad de la IMU por UART; la tarjeta corre la politica y contesta con
// el estado. Asi se prueba el circuito real contra un insecto simulado.
//
//   SW0        1 = mision en marcha
//   KEY0       reset
//   LEDR[2:0]  estimulo activo: avance, izquierda, derecha
//   LEDR[3]    insecto quieto
//   LEDR[4]    mancha de calor a la vista
//   LEDR[7:5]  estado de la politica
//   LEDR[8]    cambia con cada cuadro recibido
//   LEDR[9]    alerta: persona detectada
//   HEX0       estado (0 reposo, 1 explorar, 2 reactivar, 3 reorientar,
//              4 acercar, 5 confirmar, 6 alertar, 7 descanso)
//   HEX1       estimulos acumulados en el presupuesto (0 a C)
//   HEX3-HEX2  pixeles calientes, filtrado (hexadecimal)
// ============================================================================
module top_biobot_de10lite #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600,
    parameter F_EST     = 50,
    parameter N_PULSOS  = 25
)(
    input  wire       CLOCK_50,
    input  wire       RESET_N,        // KEY0, activo en bajo
    input  wire       SW0,
    input  wire       UART_RX,
    output wire       UART_TX,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3
);

wire reset = ~RESET_N;

// SW0 no esta sincronizado con el reloj: dos flip-flops
reg sw_meta, sw_sync;
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        sw_meta <= 1'b0;
        sw_sync <= 1'b0;
    end else begin
        sw_meta <= SW0;
        sw_sync <= sw_meta;
    end
end

wire [7:0] rx_dato;
wire       rx_valido;
wire       px_valido, px_ultimo;
wire [7:0] px_temp, actividad;
wire       tick, disparo, alerta, baliza, quieto, pre;
wire [2:0] estado;
wire [1:0] canal;
wire [6:0] n_fil;
wire [7:0] fondo;
wire [15:0] cuenta, n_est;
wire [2:0] fase_a, fase_b, led_on;
wire       tx_busy, tx_start;
wire [7:0] tx_dato;

uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
    .clk(CLOCK_50), .reset(reset), .rx(UART_RX), .data_out(rx_dato), .data_valid(rx_valido)
);

receptor_trama #(.T_HUECO(CLK_FREQ / 200)) u_trama (
    .clk(CLOCK_50), .reset(reset), .dato(rx_dato), .valido(rx_valido),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad)
);

nucleo_biobot #(.CLK_FREQ(CLK_FREQ), .F_EST(F_EST), .N_PULSOS(N_PULSOS)) u_nucleo (
    .clk(CLOCK_50), .reset(reset), .habilita(sw_sync),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est)
);

emisor_estado u_emisor (
    .clk(CLOCK_50), .reset(reset), .tick(tick), .disparo(disparo),
    .estado(estado), .canal(canal), .alerta(alerta), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .cuenta(cuenta), .tx_busy(tx_busy), .tx_start(tx_start), .tx_dato(tx_dato)
);

uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
    .clk(CLOCK_50), .reset(reset), .tx_start(tx_start), .data_in(tx_dato), .tx(UART_TX), .busy(tx_busy)
);

// Testigo de cuadros recibidos
reg latido;
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset)     latido <= 1'b0;
    else if (tick) latido <= ~latido;
end

assign LEDR = {alerta, latido, estado, pre, quieto, led_on};

hex7seg u_h0 (.x({1'b0, estado}),   .seg(HEX0));
hex7seg u_h1 (.x(cuenta[11:8]),     .seg(HEX1));
hex7seg u_h2 (.x(n_fil[3:0]),       .seg(HEX2));
hex7seg u_h3 (.x({1'b0, n_fil[6:4]}), .seg(HEX3));

endmodule

// ----------------------------------------------------------------------------
// Decodificador hexadecimal a siete segmentos. Los displays de la DE10-Lite
// encienden con 0: seg[0] = a ... seg[6] = g.
// ----------------------------------------------------------------------------
module hex7seg (
    input  wire [3:0] x,
    output reg  [6:0] seg
);
always @(*) begin
    case (x)
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;
        4'h2: seg = 7'b0100100;
        4'h3: seg = 7'b0110000;
        4'h4: seg = 7'b0011001;
        4'h5: seg = 7'b0010010;
        4'h6: seg = 7'b0000010;
        4'h7: seg = 7'b1111000;
        4'h8: seg = 7'b0000000;
        4'h9: seg = 7'b0010000;
        4'hA: seg = 7'b0001000;
        4'hB: seg = 7'b0000011;
        4'hC: seg = 7'b1000110;
        4'hD: seg = 7'b0100001;
        4'hE: seg = 7'b0000110;
        default: seg = 7'b0001110;
    endcase
end
endmodule
