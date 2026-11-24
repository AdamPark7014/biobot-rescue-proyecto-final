`timescale 1ns / 1ps

// actividad del netlist
module tb_potencia;

reg        clk = 1'b0, reset = 1'b1, habilita = 1'b0;
reg        px_valido = 1'b0, px_ultimo = 1'b0;
reg  [7:0] px_temp = 8'd0, actividad = 8'd0;
wire [2:0] fase_a, fase_b, led_on, estado;
wire       tick, disparo, alerta, baliza, quieto, pre;
wire [1:0] canal;
wire [6:0] n_fil;
wire [7:0] fondo;
wire [15:0] cuenta, n_est;

nucleo_biobot dut (.clk(clk), .reset(reset), .habilita(habilita), .px_valido(px_valido), .px_temp(px_temp),
    .px_ultimo(px_ultimo), .actividad(actividad), .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal), .alerta(alerta), .baliza(baliza),
    .quieto(quieto), .pre(pre), .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est));

always #10 clk = ~clk;

integer i, k, modo, cuadros;
reg [1023:0] salida;
reg          visto = 1'b0;
always @(posedge clk) if (disparo === 1'b1) visto <= 1'b1;

// un pixel por ciclo
task cuadro;
    begin
        for (i = 0; i < 64; i = i + 1) begin
            @(negedge clk);
            px_valido = 1'b1; px_ultimo = (i == 63);
            px_temp = 8'd88 + ($random & 8'd1);
            if (i[2:0] >= 3'd3 && i[2:0] <= 3'd4 && i[5:3] == 3'd3 && modo == 1) px_temp = 8'd140;
        end
        @(negedge clk); px_valido = 1'b0; px_ultimo = 1'b0;
        repeat (4) @(negedge clk);
    end
endtask

initial begin
    if (!$value$plusargs("modo=%d", modo)) modo = 0;
    if (!$value$plusargs("vcd=%s", salida)) salida = "x.vcd";
    repeat (5) @(negedge clk); reset = 1'b0; habilita = 1'b1;
    // calentamiento
    repeat (5) cuadro;
    if (modo == 0) begin
        repeat (20) @(negedge clk);
        $dumpfile(salida); $dumpvars(0, dut);
        repeat (2000) @(negedge clk);
    end else if (modo == 1) begin
        $dumpfile(salida); $dumpvars(0, dut);
        repeat (20) cuadro;
    end else begin
        k = 0;
        while (!visto && k < 400) begin cuadro; k = k + 1; end
        $display("disparo tras %0d cuadros, estado %0d, led %b", k, estado, led_on);
        repeat (20) @(negedge clk);
        $display("led %b fase_a %b", led_on, fase_a);
        $dumpfile(salida); $dumpvars(0, dut);
        repeat (4096) @(negedge clk);
    end
    $display("FIN modo %0d estado %0d cuenta %0d n_est %0d", modo, estado, cuenta, n_est);
    $finish;
end

endmodule
