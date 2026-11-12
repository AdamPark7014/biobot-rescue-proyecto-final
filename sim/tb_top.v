`timescale 1ns / 1ps
// ============================================================================
// tb_top.v
// Banco de prueba del sistema completo, como va en la DE10-Lite: los cuadros
// entran por UART (0xA5, actividad, 64 pixeles) y la respuesta sale por UART
// (0x5A y tres bytes de estado). Se usan los cuadros del escenario de
// acercamiento de vectores.hex y se compara con esperado.hex.
// La linea corre a 1 Mbaud para acortar la simulacion; el circuito es el
// mismo que a 9600.
// ============================================================================
module tb_top;

`include "casos.vh"

localparam integer N_CUADROS = 500;   // llega hasta la deteccion confirmada
localparam integer T_BIT     = 1000;  // ns por bit a 1 Mbaud

reg        clk = 1'b0;
reg        reset_n = 1'b0;
reg        sw0 = 1'b0;
reg        rx = 1'b1;
wire       tx;
wire [9:0] ledr;
wire [6:0] hex0, hex1, hex2, hex3;

top_biobot_de10lite #(.CLK_FREQ(50000000), .BAUD_RATE(1000000), .F_EST(50), .N_PULSOS(1)) dut (
    .CLOCK_50(clk), .RESET_N(reset_n), .SW0(sw0), .UART_RX(rx), .UART_TX(tx),
    .LEDR(ledr), .HEX0(hex0), .HEX1(hex1), .HEX2(hex2), .HEX3(hex3)
);

always #10 clk = ~clk;

reg [527:0] vec [0:N_VEC-1];
reg [55:0]  esp [0:N_VEC-1];
reg [527:0] v;
reg [55:0]  e;
reg [7:0]   resp [0:3];
integer     k, i, errores, mostrados, n_resp, n_estimulos;

task enviar(input [7:0] b);
    integer j;
begin
    rx = 1'b0; #(T_BIT);
    for (j = 0; j < 8; j = j + 1) begin rx = b[j]; #(T_BIT); end
    rx = 1'b1; #(T_BIT);
end
endtask

// Receptor de la respuesta: muestrea TX a medio bit
task recibir(output [7:0] b);
    integer j;
begin
    @(negedge tx);
    #(T_BIT + T_BIT / 2);
    for (j = 0; j < 8; j = j + 1) begin b[j] = tx; #(T_BIT); end
end
endtask

always begin : escucha
    reg [7:0] b;
    recibir(b);
    resp[n_resp] = b;
    n_resp = n_resp + 1;
end

initial begin
    $readmemh("vectores.hex", vec);
    $readmemh("esperado.hex", esp);
    errores = 0; mostrados = 0; n_resp = 0; n_estimulos = 0;
    repeat (10) @(posedge clk);
    reset_n = 1'b1;
    sw0 = 1'b1;
    repeat (10) @(posedge clk);

    for (k = 0; k < N_CUADROS; k = k + 1) begin
        v = vec[INICIO_B + k];
        e = esp[INICIO_B + k];
        n_resp = 0;
        enviar(8'hA5);
        enviar(v[519:512]);
        for (i = 0; i < 64; i = i + 1) enviar(v[511 - 8*i -: 8]);
        wait (n_resp == 4);
        #(2 * T_BIT);
        if (resp[1][3]) n_estimulos = n_estimulos + 1;
        if (resp[0] !== 8'h5A || {1'b0, resp[1][6:4]} !== e[55:52] || {3'b0, resp[1][3]} !== e[51:48] ||
            {2'b0, resp[1][2:1]} !== e[47:44] || {3'b0, resp[1][7]} !== e[43:40] ||
            {1'b0, resp[2][6:0]} !== e[39:32] || resp[3] !== e[31:24]) begin
            errores = errores + 1;
            if (mostrados < 10) begin
                mostrados = mostrados + 1;
                $display("ERROR cuadro %0d: recibido %h %h %h %h, esperado estado %0d disparo %0d canal %0d alerta %0d n_fil %0d cuenta %0d",
                         k, resp[0], resp[1], resp[2], resp[3], e[55:52], e[51:48], e[47:44], e[43:40], e[39:32], e[31:24]);
            end
        end
    end
    $display("MEDIDA tb_top: estimulos reportados %0d, alerta al final %0d, estado final %0d", n_estimulos, ledr[9], ledr[7:5]);
    $display("RESULTADO tb_top: %0d de %0d respuestas por UART coinciden con el modelo de referencia", N_CUADROS - errores, N_CUADROS);
    $finish;
end

endmodule
