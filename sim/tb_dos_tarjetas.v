`timescale 1ns / 1ps
// ============================================================================
// tb_dos_tarjetas.v
// Banco de pruebas del montaje con dos DE10-Lite: la mochila
// (top_biobot_de10lite) y la tarjeta que hace de insecto
// (top_insecto_de10lite), unidas solo por las dos lineas de UART, cruzadas,
// igual que con los cables.
//
//   1. persona            -> la mochila debe llegar a ALERTAR y la tarjeta
//                            insecto debe verlo en la respuesta
//   2. objeto caliente    -> la mochila no debe alertar
//
// El reloj se declara de 80 kHz y la linea de 10 000 baudios: 8 ciclos por
// bit y 8000 ciclos por cuadro, para que la simulacion sea corta.
// ============================================================================
module tb_dos_tarjetas;

localparam CLK_FREQ  = 80000;
localparam BAUD_RATE = 10000;

reg        clk = 1'b0;
reg        reset_n = 1'b0;
reg  [9:0] sw_insecto = 10'd0;
reg        sw0_mochila = 1'b0;
wire       tx_mochila, tx_insecto;
wire [9:0] led_m, led_i;
wire [6:0] m0, m1, m2, m3, i0, i1, i2, i3, i4, i5;

top_biobot_de10lite #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) mochila (
    .CLOCK_50(clk), .RESET_N(reset_n), .SW0(sw0_mochila),
    .UART_RX(tx_insecto), .UART_TX(tx_mochila), .LEDR(led_m),
    .HEX0(m0), .HEX1(m1), .HEX2(m2), .HEX3(m3)
);

top_insecto_de10lite #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) insecto (
    .CLOCK_50(clk), .RESET_N(reset_n), .SW(sw_insecto),
    .UART_RX(tx_mochila), .UART_TX(tx_insecto), .LEDR(led_i),
    .HEX0(i0), .HEX1(i1), .HEX2(i2), .HEX3(i3), .HEX4(i4), .HEX5(i5)
);

always #5 clk = ~clk;

integer cuadros, errores, cuadro_alerta;
reg     vio_pre;

always @(posedge clk) begin
    if (mochila.tick) begin
        cuadros = cuadros + 1;
        if (mochila.pre) vio_pre = 1'b1;
        if (mochila.alerta && cuadro_alerta < 0) cuadro_alerta = cuadros;
    end
end

task arranca;
    input [1:0] esc;
    begin
        reset_n = 1'b0;
        sw_insecto  = {7'd0, esc, 1'b0};
        sw0_mochila = 1'b1;
        repeat (5) @(posedge clk);
        cuadros = 0; cuadro_alerta = -1; vio_pre = 1'b0;
        reset_n = 1'b1;
    end
endtask

initial begin
    errores = 0;

    // ---- 1: persona
    arranca(2'b01);
    while (cuadros < 2500 && cuadro_alerta < 0) @(posedge clk);
    repeat (3 * CLK_FREQ / 10) @(posedge clk);       // tres cuadros mas: que llegue la respuesta
    $display("MEDIDA tb_dos_tarjetas persona: alerta en el cuadro %0d, %0d estimulos ordenados, %0d obedecidos, distancia final %0d mm",
             cuadro_alerta, mochila.n_est, insecto.n_obedecidos, insecto.dist);
    if (cuadro_alerta < 0) begin
        errores = errores + 1;
        $display("ERROR tb_dos_tarjetas persona: la mochila no llego a ALERTAR");
    end
    if (!led_i[8] || !led_i[9] || insecto.estado_m != 3'd6) begin
        errores = errores + 1;
        $display("ERROR tb_dos_tarjetas persona: la tarjeta insecto no vio la alerta (enlace %b, alerta %b, estado %0d)",
                 led_i[8], led_i[9], insecto.estado_m);
    end
    if (insecto.n_obedecidos == 0) begin
        errores = errores + 1;
        $display("ERROR tb_dos_tarjetas persona: ningun estimulo llego al insecto");
    end

    // ---- 2: objeto caliente
    arranca(2'b10);
    while (cuadros < 600) @(posedge clk);
    $display("MEDIDA tb_dos_tarjetas objeto caliente: %0d cuadros, enlace %b, estado que ve la tarjeta insecto %0d",
             cuadros, led_i[8], insecto.estado_m);
    if (cuadro_alerta >= 0 || vio_pre) begin
        errores = errores + 1;
        $display("ERROR tb_dos_tarjetas objeto caliente: vio mancha o alerto");
    end
    if (!led_i[8]) begin
        errores = errores + 1;
        $display("ERROR tb_dos_tarjetas objeto caliente: enlace caido");
    end

    if (errores == 0) $display("RESULTADO tb_dos_tarjetas: 2 de 2 escenarios correctos");
    else              $display("RESULTADO tb_dos_tarjetas: %0d errores", errores);
    $finish;
end

endmodule
