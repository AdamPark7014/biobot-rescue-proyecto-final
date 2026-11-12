`timescale 1ns / 1ps
// ============================================================================
// tb_gen_estimulo.v
// Banco de prueba del generador de pulsos. El reloj se baja a 100 kHz para
// que el tren de 0.5 s quepa en 50 000 ciclos; las proporciones son las del
// circuito real (50 Hz, 50 % de ciclo, 25 periodos).
// Revisa: numero de periodos, periodo, ciclo de trabajo, duracion del tren,
// que las dos fases nunca coincidan, que solo se mueva el canal pedido y que
// un disparo a medio tren se ignore.
// ============================================================================
module tb_gen_estimulo;

localparam integer F_CLK = 100000;    // Hz
localparam integer T_CLK = 10000;     // ns

reg        clk = 1'b0;
reg        reset = 1'b1;
reg        disparo = 1'b0;
reg  [1:0] canal = 2'b00;
wire [2:0] fase_a, fase_b, led_on;
wire       ocupado;

gen_estimulo #(.CLK_FREQ(F_CLK), .F_EST(50), .N_PULSOS(25)) dut (
    .clk(clk), .reset(reset), .disparo(disparo), .canal(canal),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on), .ocupado(ocupado)
);

always #(T_CLK/2) clk = ~clk;

integer errores = 0;
integer pruebas = 0;
integer flancos, ciclos_a, ciclos_b, ciclos_tren, traslapes, ajenos, ch;
realtime t_ini, t_fin, t_prev, periodo;
reg     a_prev;

task tren(input [1:0] c, input integer indice);
begin
    @(negedge clk);
    canal = c; disparo = 1'b1;
    @(negedge clk);
    disparo = 1'b0;
    flancos = 0; ciclos_a = 0; ciclos_b = 0; ciclos_tren = 0; traslapes = 0; ajenos = 0;
    a_prev = 1'b0; periodo = 0; t_prev = 0;
    // se muestrea a mitad de ciclo, en el flanco de bajada
    while (!ocupado) @(negedge clk);
    t_ini = $realtime;
    while (ocupado) begin
        ciclos_tren = ciclos_tren + 1;
        if (fase_a[indice]) ciclos_a = ciclos_a + 1;
        if (fase_b[indice]) ciclos_b = ciclos_b + 1;
        if (fase_a[indice] && fase_b[indice]) traslapes = traslapes + 1;
        for (ch = 0; ch < 3; ch = ch + 1)
            if (ch != indice && (fase_a[ch] || fase_b[ch] || led_on[ch])) ajenos = ajenos + 1;
        if (fase_a[indice] && !a_prev) begin
            flancos = flancos + 1;
            if (flancos > 1) periodo = $realtime - t_prev;
            t_prev = $realtime;
        end
        a_prev = fase_a[indice];
        // a medio tren llega otro disparo por otro canal: debe ignorarse
        if (flancos == 10 && ciclos_a == 9 * 1000 + 500) begin
            canal = c + 2'b01; disparo = 1'b1;
        end else disparo = 1'b0;
        @(negedge clk);
    end
    t_fin = $realtime;
    pruebas = pruebas + 1;
    $display("MEDIDA canal %0d: %0d periodos, periodo %0.3f ms, fase A %0d ciclos, fase B %0d ciclos, tren %0.1f ms",
             indice, flancos, periodo / 1.0e6, ciclos_a, ciclos_b, (t_fin - t_ini) / 1.0e6);
    if (flancos != 25 || periodo != 20.0e6 || ciclos_a != 25000 || ciclos_b != 25000 ||
        ciclos_tren != 50000 || traslapes != 0 || ajenos != 0) begin
        errores = errores + 1;
        $display("ERROR canal %0d: traslapes %0d, actividad en otros canales %0d", indice, traslapes, ajenos);
    end
    repeat (20) @(posedge clk);
    if (fase_a != 3'b000 || fase_b != 3'b000 || led_on != 3'b000 || ocupado) begin
        errores = errores + 1;
        $display("ERROR canal %0d: las salidas no vuelven a cero", indice);
    end
end
endtask

initial begin
    repeat (4) @(posedge clk);
    reset = 1'b0;
    tren(2'b00, 0);                   // avance
    tren(2'b01, 1);                   // izquierda
    tren(2'b10, 2);                   // derecha
    $display("RESULTADO tb_gen_estimulo: %0d de %0d trenes correctos", pruebas - errores, pruebas);
    $finish;
end

endmodule
