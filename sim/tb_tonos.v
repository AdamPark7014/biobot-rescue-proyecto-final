`timescale 1ns / 1ps
// ============================================================================
// tb_tonos.v
// Banco de pruebas del detector de tonos (hdl/tonos.v), visto desde la mochila A
// (emite 1 kHz y escucha 2 kHz de B y 4 kHz del receptor). Recorre las cuatro
// combinaciones del canal simulado y revisa que el detector oiga exactamente
// los tonos que llegan, y que nunca oiga el suyo.
// Reloj declarado de 400 kHz: 25 ciclos por muestra de 16 kHz.
// ============================================================================
module tb_tonos;

reg        clk = 1'b0, reset = 1'b1;
reg  [2:0] presente = 3'b000;
wire       tono;
wire [2:0] oye;
wire [15:0] p0, p1, p2;

tri_tonos #(.CLK_FREQ(400000), .FS(16000), .YO(1)) dut (.clk(clk), .reset(reset), .presente(presente),
    .tono(tono), .oye(oye), .pot0(p0), .pot1(p1), .pot2(p2));

always #5 clk = ~clk;

integer errores = 0, k, flancos = 0;
reg     tono_prev = 1'b0;
always @(posedge clk) begin
    if (tono && !tono_prev) flancos = flancos + 1;
    tono_prev <= tono;
end

task prueba;
    input [2:0] llega;                 // {B, A, receptor}
    input [2:0] esperado;
    begin
        presente = llega;
        repeat (4 * 64 * 25) @(posedge clk);      // cuatro bloques de 4 ms
        $display("MEDIDA tb_tonos llegan %b: oye %b; potencia 4 kHz %0d, 1 kHz %0d, 2 kHz %0d", llega, oye, p0, p1, p2);
        if (oye !== esperado) begin
            errores = errores + 1;
            $display("ERROR tb_tonos llegan %b: oye %b y se esperaba %b", llega, oye, esperado);
        end
    end
endtask

initial begin
    repeat (5) @(posedge clk);
    reset = 1'b0;
    prueba(3'b000, 3'b000);            // silencio: solo ruido
    prueba(3'b001, 3'b001);            // solo el receptor
    prueba(3'b100, 3'b100);            // solo B
    prueba(3'b101, 3'b101);            // los dos
    prueba(3'b111, 3'b101);            // el tono propio (1 kHz) nunca se cuenta
    prueba(3'b010, 3'b000);
    prueba(3'b000, 3'b000);            // se pierden al dejar de llegar
    // el tono propio debe ser de 1 kHz: en 5 x 16 ms mas hay unos 80 periodos
    flancos = 0;
    repeat (80 * 400) @(posedge clk);  // 80 ms
    $display("MEDIDA tb_tonos tono propio: %0d periodos en 80 ms (1 kHz = 80)", flancos);
    if (flancos < 79 || flancos > 81) begin errores = errores + 1; $display("ERROR tb_tonos: frecuencia del tono propio"); end
    if (errores == 0) $display("RESULTADO tb_tonos: 8 de 8 comprobaciones correctas");
    else              $display("RESULTADO tb_tonos: %0d errores", errores);
    $finish;
end

endmodule
