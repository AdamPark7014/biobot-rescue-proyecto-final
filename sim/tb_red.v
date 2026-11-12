`timescale 1ns / 1ps
// ============================================================================
// tb_red.v
// Banco de pruebas de la red de tres tarjetas: mochila A, mochila B y receptor,
// cableadas como en el laboratorio:
//   A.TX1 -> receptor.RX1     A.TX2 -> B.RX1     B.TX1 -> receptor.RX2
//
//   1. A a 150 m y B a 80 m, A aprieta el boton: el aviso de A llega al receptor
//      solo a traves de B (A esta fuera de los 100 m del radio).
//   2. B se aleja a 300 m: ya nadie lleva el aviso de A; el receptor lo pierde.
//   3. A se acerca a 60 m: el aviso llega directo.
//   4. B, a 55 m, tambien aprieta su boton: deteccion confirmada a 57 m.
//
// Reloj declarado de 200 kHz y linea de 20 000 baudios (10 ciclos por bit),
// para que la simulacion sea corta.
// ============================================================================
module tb_red;

localparam CLK  = 200000;
localparam BAUD = 20000;

reg        clk = 1'b0;
reg        reset = 1'b1;
reg        boton_a = 1'b0, boton_b = 1'b0;
reg  [9:0] pos_a = 10'd150, pos_b = 10'd80;
wire       tx_a, tx_b, tx_r;
wire [9:0] led_a, led_b, led_r;
wire [6:0] ha0, ha1, ha2, ha3, ha4, ha5, hb0, hb1, hb2, hb3, hb4, hb5, hr0, hr1, hr2, hr3, hr4, hr5;

red_nodo #(.ROL(1), .CLK_FREQ(CLK), .BAUD_RATE(BAUD)) a (.clk(clk), .reset(reset), .boton(boton_a), .pos(pos_a),
    .rx1(1'b1), .rx2(1'b1), .tx(tx_a), .ledr(led_a), .hex0(ha0), .hex1(ha1), .hex2(ha2), .hex3(ha3), .hex4(ha4), .hex5(ha5));
red_nodo #(.ROL(2), .CLK_FREQ(CLK), .BAUD_RATE(BAUD)) b (.clk(clk), .reset(reset), .boton(boton_b), .pos(pos_b),
    .rx1(tx_a), .rx2(1'b1), .tx(tx_b), .ledr(led_b), .hex0(hb0), .hex1(hb1), .hex2(hb2), .hex3(hb3), .hex4(hb4), .hex5(hb5));
red_nodo #(.ROL(0), .CLK_FREQ(CLK), .BAUD_RATE(BAUD)) r (.clk(clk), .reset(reset), .boton(1'b0), .pos(10'd0),
    .rx1(tx_a), .rx2(tx_b), .tx(tx_r), .ledr(led_r), .hex0(hr0), .hex1(hr1), .hex2(hr2), .hex3(hr3), .hex4(hr4), .hex5(hr5));

always #5 clk = ~clk;

integer errores = 0;

task espera_s;                 // segundos simulados
    input integer decimas;
    begin
        repeat (decimas * (CLK / 10)) @(posedge clk);
    end
endtask

task revisa;
    input [8*40-1:0] nombre;
    input            cond;
    begin
        if (!cond) begin
            errores = errores + 1;
            $display("ERROR tb_red %0s: led_r=%b det_a=%b det_b=%b dir_a=%0d rel_a=%0d estimada=%0d",
                     nombre, led_r, r.det_a, r.det_b, r.t_dir_a, r.t_rel_a, r.estimada);
        end
    end
endtask

initial begin
    repeat (20) @(posedge clk);
    reset = 1'b0;

    // ---- 1: A fuera de alcance, B de puente
    boton_a = 1'b1; espera_s(7); boton_a = 1'b0;
    espera_s(10);
    $display("MEDIDA tb_red puente: led_r=%b, A directo %b, A por B %b, B directo %b, A detecta %b, distancia %0d m, B reenvia %b",
             led_r, led_r[0], led_r[1], led_r[2], led_r[3], r.estimada, led_b[7]);
    revisa("1 puente", !led_r[0] && led_r[1] && led_r[2] && led_r[3] && led_r[8] && !led_r[9] && r.estimada == 150 && led_b[7]);

    // ---- 2: B se aleja, el aviso se pierde
    pos_b = 10'd300;
    espera_s(20);
    $display("MEDIDA tb_red sin puente: led_r=%b", led_r);
    revisa("2 sin puente", !led_r[0] && !led_r[1] && !led_r[2] && !led_r[3] && !led_r[8]);

    // ---- 3: A se acerca, llega directo
    pos_a = 10'd60;
    espera_s(10);
    $display("MEDIDA tb_red directo: led_r=%b, distancia %0d m", led_r, r.estimada);
    revisa("3 directo", led_r[0] && led_r[3] && r.estimada == 60);

    // ---- 4: B tambien encuentra a la persona, cerca de A
    pos_b = 10'd55;
    boton_b = 1'b1; espera_s(7); boton_b = 1'b0;
    espera_s(10);
    $display("MEDIDA tb_red confirmada: led_r=%b, distancia estimada %0d m", led_r, r.estimada);
    revisa("4 confirmada", led_r[9] && !led_r[8] && led_r[3] && led_r[4] && r.estimada == 57);

    if (errores == 0) $display("RESULTADO tb_red: 4 de 4 escenarios correctos");
    else              $display("RESULTADO tb_red: %0d errores", errores);
    $finish;
end

endmodule
