`timescale 1ns / 1ps
module tb_distancia;

reg        clk = 1'b0;
reg        reset = 1'b1;
reg        start = 1'b0;
reg  [9:0] x1 = 0, y1 = 0, x2 = 0, y2 = 0;
wire [9:0] d;
wire       listo;

tri_distancia dut (.clk(clk), .reset(reset), .start(start), .x1(x1), .y1(y1), .x2(x2), .y2(y2),
    .d(d), .listo(listo));

always #5 clk = ~clk;

localparam integer ALC2 = 512 * 512;

integer total = 0, errores = 0, mostrados = 0;
integer en_corte = 0, se_oyen = 0, ciclos = 0, ciclos_max = 0;

// parte entera de la raiz
function integer raiz;
    input integer n;
    integer r;
    begin
        r = $rtoi($sqrt($itor(n)));
        while (r * r > n) r = r - 1;
        while ((r + 1) * (r + 1) <= n) r = r + 1;
        raiz = r;
    end
endfunction

task mide;
    input integer ax, ay, bx, by;
    integer n, esperado, ex, ey;
    begin
        x1 = ax[9:0]; y1 = ay[9:0]; x2 = bx[9:0]; y2 = by[9:0];
        @(negedge clk) start = 1'b1;
        @(negedge clk) start = 1'b0;
        ciclos = 1;
        while (!listo) begin @(negedge clk); ciclos = ciclos + 1; end
        if (ciclos > ciclos_max) ciclos_max = ciclos;
        ex = ax - bx; ey = ay - by;
        n = ex * ex + ey * ey;
        esperado = raiz(n);
        if (esperado > 1023) esperado = 1023;
        total = total + 1;
        if (n < ALC2) se_oyen = se_oyen + 1;
        // comprobacion
        if (d !== esperado[9:0] || ((n < ALC2) != (d < 10'd512))) begin
            errores = errores + 1;
            if (mostrados < 10) begin
                mostrados = mostrados + 1;
                $display("ERROR tb_distancia: (%0d, %0d) a (%0d, %0d): da %0d cuentas, lo exacto es %0d", ax, ay, bx, by, d, esperado);
            end
        end
    end
endtask

task caso;
    input [8*40-1:0] nombre;
    input integer ax, ay;
    input integer cuentas;
    input         se_oye;
    begin
        mide(ax, ay, 0, 0);
        // LED en metros
        if (d < 10'd512)
            $display("MEDIDA tb_distancia %0s: (%0.2f, %0.2f) m -> %0.2f m (%0d cuentas): se oye, LED en %0d m",
                     nombre, ax / 16.0, ay / 16.0, d / 16.0, d, (d[9:4] == 6'd0) ? 6'd1 : d[9:4]);
        else
            $display("MEDIDA tb_distancia %0s: (%0.2f, %0.2f) m -> %0.2f m (%0d cuentas): no se oye, LED apagados",
                     nombre, ax / 16.0, ay / 16.0, d / 16.0, d);
        if (d !== cuentas[9:0] || ((d < 10'd512) != se_oye)) begin
            errores = errores + 1;
            $display("ERROR tb_distancia %0s: se esperaban %0d cuentas y se_oye = %b", nombre, cuentas, se_oye);
        end
    end
endtask

integer i, j, n, semilla;
initial begin
    semilla = 20261121;
    repeat (4) @(posedge clk);
    reset = 1'b0;

    if (!$test$plusargs("casos")) begin
    // los dos ejes
    for (i = 0; i < 1024; i = i + 1) begin mide(i, 0, 0, 0); mide(0, i, 0, 0); end
    $display("MEDIDA tb_distancia 1 ejes: %0d distancias, %0d errores", total, errores);

    // corte de 32 m
    for (i = 0; i <= 528; i = i + 1)
        for (j = 0; j <= 528; j = j + 1) begin
            n = i * i + j * j;
            if (n >= 495 * 495 && n < 529 * 529) begin mide(i, j, 0, 0); en_corte = en_corte + 1; end
        end
    $display("MEDIDA tb_distancia 2 corte: %0d puntos entre 30.94 y 33.06 m, %0d errores acumulados", en_corte, errores);

    // pares al azar
    for (i = 0; i < 60000; i = i + 1)
        mide({$random(semilla)} % 1024, {$random(semilla)} % 1024, {$random(semilla)} % 1024, {$random(semilla)} % 1024);
    $display("MEDIDA tb_distancia 3 al azar: 60000 pares, %0d errores acumulados", errores);
    end

    // casos
    caso("31.00 m en el eje X", 496, 0, 496, 1'b1);
    caso("31.00 m en el eje Y", 0, 496, 496, 1'b1);
    caso("32.00 m en el eje X", 512, 0, 512, 1'b0);
    caso("32.00 m en el eje Y", 0, 512, 512, 1'b0);
    caso("31.25 m en diagonal", 300, 400, 500, 1'b1);
    caso("31.88 m en diagonal", 240, 450, 510, 1'b1);
    caso("32.50 m en diagonal", 200, 480, 520, 1'b0);
    caso("lo mas lejos que se oye", 412, 303, 511, 1'b1);
    caso("junto a el, ya no se oye", 412, 304, 512, 1'b0);
    caso("a medio metro", 8, 0, 8, 1'b1);
    caso("esquina del mapa", 1023, 1023, 1023, 1'b0);

    // todo el mapa
    if ($test$plusargs("completo")) begin
        for (i = 0; i < 1024; i = i + 1)
            for (j = 0; j < 1024; j = j + 1) mide(i, j, 0, 0);
        $display("MEDIDA tb_distancia completo: los 1 048 576 pares (dx, dy), %0d errores acumulados", errores);
    end

    $display("MEDIDA tb_distancia: latencia %0d ciclos; %0d de las distancias probadas quedan a menos de 32 m", ciclos_max, se_oyen);
    if (errores == 0) $display("RESULTADO tb_distancia: %0d de %0d distancias exactas", total, total);
    else              $display("RESULTADO tb_distancia: %0d errores en %0d distancias", errores, total);
    $finish;
end

endmodule
