`timescale 1ns / 1ps
// ============================================================================
// tb_nucleo.v
// Banco de prueba autoverificable del nucleo digital.
//
// Lee vectores.hex (un cuadro por linea: banderas, actividad y 64 pixeles) y
// esperado.hex (lo que debe verse despues de cada cuadro), los dos generados
// por modelo/politica_ref.py, y compara cuadro por cuadro:
//     estado, disparo, canal, alerta, n_fil, cuenta y n_est
// ============================================================================
module tb_nucleo;

`include "casos.vh"

reg         clk = 1'b0;
reg         reset = 1'b1;
reg         habilita = 1'b0;
reg         px_valido = 1'b0;
reg         px_ultimo = 1'b0;
reg  [7:0]  px_temp = 8'd0;
reg  [7:0]  actividad = 8'd0;

wire [2:0]  fase_a, fase_b, led_on;
wire        tick, disparo, alerta, baliza, quieto, pre;
wire [2:0]  estado;
wire [1:0]  canal;
wire [6:0]  n_fil;
wire [7:0]  fondo;
wire [15:0] cuenta, n_est;

// El generador de pulsos se acorta para no alargar la simulacion: aqui solo
// interesa la politica (gen_estimulo tiene su propio banco)
nucleo_biobot #(.CLK_FREQ(1000), .F_EST(50), .N_PULSOS(2)) dut (
    .clk(clk), .reset(reset), .habilita(habilita),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est)
);

always #10 clk = ~clk;                // 50 MHz

reg [527:0] vec [0:N_VEC-1];
reg [55:0]  esp [0:N_VEC-1];
reg [527:0] v;
reg [55:0]  e;
integer     k, i, errores, mostrados;
integer     visitas [0:7];
integer     n_disparos, n_alertas;

initial begin
    $readmemh("vectores.hex", vec);
    $readmemh("esperado.hex", esp);
    errores = 0; mostrados = 0; n_disparos = 0; n_alertas = 0;
    for (i = 0; i < 8; i = i + 1) visitas[i] = 0;

    repeat (4) @(posedge clk);
    for (k = 0; k < N_VEC; k = k + 1) begin
        v = vec[k];
        e = esp[k];
        @(negedge clk);
        if (v[520]) begin             // reinicio antes de este cuadro
            reset = 1'b1;
            @(negedge clk);
            @(negedge clk);
        end
        reset     = 1'b0;
        habilita  = v[521];
        actividad = v[519:512];
        for (i = 0; i < 64; i = i + 1) begin
            px_valido = 1'b1;
            px_temp   = v[511 - 8*i -: 8];
            px_ultimo = (i == 63);
            @(negedge clk);
        end
        px_valido = 1'b0;
        px_ultimo = 1'b0;
        // El flanco anterior cerro el cuadro; en el siguiente llega el tick y
        // se actualiza todo. Medio ciclo despues se compara (disparo dura un ciclo).
        @(negedge clk);
        visitas[estado] = visitas[estado] + 1;
        if (disparo) n_disparos = n_disparos + 1;
        if (alerta && (k > 0) && (esp[k-1][43:40] == 4'd0)) n_alertas = n_alertas + 1;
        if ({1'b0, estado} !== e[55:52] || {3'b0, disparo} !== e[51:48] || {2'b0, canal} !== e[47:44] ||
            {3'b0, alerta} !== e[43:40] || {1'b0, n_fil} !== e[39:32] || cuenta !== e[31:16] || n_est !== e[15:0]) begin
            errores = errores + 1;
            if (mostrados < 10) begin
                mostrados = mostrados + 1;
                $display("ERROR cuadro %0d: estado %0d/%0d disparo %0d/%0d canal %0d/%0d alerta %0d/%0d n_fil %0d/%0d cuenta %0d/%0d n_est %0d/%0d",
                         k, estado, e[55:52], disparo, e[51:48], canal, e[47:44], alerta, e[43:40],
                         n_fil, e[39:32], cuenta, e[31:16], n_est, e[15:0]);
            end
        end
    end

    $display("MEDIDA tb_nucleo: cuadros por estado  REPOSO %0d  EXPLORAR %0d  REACTIVAR %0d  REORIENTAR %0d  ACERCAR %0d  CONFIRMAR %0d  ALERTAR %0d  DESCANSO %0d",
             visitas[0], visitas[1], visitas[2], visitas[3], visitas[4], visitas[5], visitas[6], visitas[7]);
    $display("MEDIDA tb_nucleo: estimulos disparados %0d, alertas levantadas %0d", n_disparos, n_alertas);
    $display("RESULTADO tb_nucleo: %0d de %0d cuadros coinciden con el modelo de referencia", N_VEC - errores, N_VEC);
    $finish;
end

endmodule
