`timescale 1ns / 1ps
// ============================================================================
// tb_demo.v
// Banco de pruebas de top_demo_de10lite: la demostracion en una sola tarjeta.
// Corre los cuatro escenarios con el lazo cerrado (insecto de prueba + nucleo)
// y revisa que cada uno termine como debe:
//
//   01 persona            -> debe llegar a ALERTAR
//   10 objeto caliente    -> nunca debe ver mancha ni alertar
//   00 sin persona        -> no alerta y al menos una vez pasa por REACTIVAR
//   11 insecto que no     -> no alerta, hay estimulos y la espera entre
//      responde              ellos crece (retroceso)
//
// Para que la simulacion sea corta el reloj se declara de 8 kHz y se usa el
// modo rapido (SW9): un cuadro son 100 ciclos.
// ============================================================================
module tb_demo;

localparam CLK_FREQ = 8000;

reg        clk = 1'b0;
reg        reset_n = 1'b0;
reg  [9:0] sw = 10'd0;
wire [9:0] ledr;
wire [6:0] hex0, hex1, hex2, hex3, hex4, hex5;
wire [2:0] estimulo;

top_demo_de10lite #(.CLK_FREQ(CLK_FREQ)) dut (
    .CLOCK_50(clk), .RESET_N(reset_n), .SW(sw), .LEDR(ledr),
    .HEX0(hex0), .HEX1(hex1), .HEX2(hex2), .HEX3(hex3), .HEX4(hex4), .HEX5(hex5),
    .ESTIMULO(estimulo)
);

always #5 clk = ~clk;

integer cuadros, errores, visitas [0:7];
integer t_est [0:7], n_marcas;
integer cuadro_alerta, max_nfil, k;
reg     vio_pre;

// Cuenta cuadros, estados visitados y estimulos
always @(posedge clk) begin
    if (dut.tick) begin
        cuadros = cuadros + 1;
        visitas[dut.estado] = visitas[dut.estado] + 1;
        if (dut.n_fil > max_nfil) max_nfil = dut.n_fil;
        if (dut.pre) vio_pre = 1'b1;
        if (dut.alerta && cuadro_alerta < 0) cuadro_alerta = cuadros;
    end
    if (dut.disparo && n_marcas < 8) begin
        t_est[n_marcas] = cuadros;
        n_marcas = n_marcas + 1;
    end
end

task arranca;
    input [1:0] esc;
    begin
        reset_n = 1'b0;
        sw = {1'b1, 6'd0, esc, 1'b1};        // rapido, escenario, mision en marcha
        repeat (5) @(posedge clk);
        cuadros = 0; cuadro_alerta = -1; max_nfil = 0; vio_pre = 1'b0; n_marcas = 0;
        for (k = 0; k < 8; k = k + 1) visitas[k] = 0;
        reset_n = 1'b1;
    end
endtask

task corre;
    input integer n;
    input integer para_en_alerta;
    begin
        while (cuadros < n && !(para_en_alerta && cuadro_alerta >= 0)) @(posedge clk);
    end
endtask

initial begin
    errores = 0;

    // ---- 01: persona
    arranca(2'b01);
    corre(4000, 1);
    $display("MEDIDA tb_demo persona: alerta en el cuadro %0d (%0d s a 10 cuadros/s), %0d estimulos, %0d obedecidos, distancia final %0d mm",
             cuadro_alerta, cuadro_alerta / 10, dut.n_est, dut.n_obedecidos, dut.dist);
    if (cuadro_alerta < 0) begin
        errores = errores + 1;
        $display("ERROR tb_demo persona: no llego a ALERTAR en 4000 cuadros");
    end
    if (visitas[4] == 0 || visitas[5] == 0) begin
        errores = errores + 1;
        $display("ERROR tb_demo persona: no paso por ACERCAR y CONFIRMAR");
    end

    // ---- 10: objeto caliente en ambiente tibio
    arranca(2'b10);
    corre(2000, 0);
    $display("MEDIDA tb_demo objeto caliente: maximo de pixeles calientes %0d, estimulos %0d", max_nfil, dut.n_est);
    if (cuadro_alerta >= 0 || vio_pre) begin
        errores = errores + 1;
        $display("ERROR tb_demo objeto caliente: vio mancha o alerto");
    end

    // ---- 00: sin persona
    arranca(2'b00);
    corre(4000, 0);
    $display("MEDIDA tb_demo sin persona: cuadros en EXPLORAR %0d, REACTIVAR %0d, REORIENTAR %0d, estimulos %0d",
             visitas[1], visitas[2], visitas[3], dut.n_est);
    if (cuadro_alerta >= 0 || vio_pre) begin
        errores = errores + 1;
        $display("ERROR tb_demo sin persona: vio mancha o alerto");
    end
    if (visitas[2] == 0) begin
        errores = errores + 1;
        $display("ERROR tb_demo sin persona: nunca reactivo al insecto");
    end

    // ---- 11: insecto que no responde
    arranca(2'b11);
    corre(9000, 0);
    $display("MEDIDA tb_demo no responde: estimulos %0d, en los cuadros %0d, %0d, %0d, %0d; obedecidos %0d",
             dut.n_est, t_est[0], t_est[1], t_est[2], t_est[3], dut.n_obedecidos);
    if (cuadro_alerta >= 0 || dut.n_obedecidos != 0) begin
        errores = errores + 1;
        $display("ERROR tb_demo no responde: alerto o el insecto obedecio");
    end
    if (n_marcas < 4 || (t_est[2] - t_est[1]) <= (t_est[1] - t_est[0]) || (t_est[3] - t_est[2]) <= (t_est[2] - t_est[1])) begin
        errores = errores + 1;
        $display("ERROR tb_demo no responde: la espera entre estimulos no crece");
    end

    if (errores == 0) $display("RESULTADO tb_demo: 4 de 4 escenarios correctos");
    else              $display("RESULTADO tb_demo: %0d errores", errores);
    $finish;
end

endmodule
