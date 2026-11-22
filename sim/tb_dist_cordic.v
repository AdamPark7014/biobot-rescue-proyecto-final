`timescale 1ns / 1ps
// ============================================================================
// tb_dist_cordic.v
// Por que la distancia entre nodos no se calcula con el CORDIC.
//
// La primera version de la red sacaba la distancia de la magnitud del CORDIC
// en vectorizacion: d = (K * |v|) * 9949 / 2^18, truncada a la cuenta. Este
// banco reproduce esa cuenta con el mismo cordic.v y la compara con el valor
// exacto, la parte entera de sqrt(dx^2 + dy^2), para los 1 048 576 pares
// (dx, dy) de 0 a 1023.
//
// Resultado (lo imprime al final): el error del CORDIC es de menos de una
// cuenta, pero al truncar basta para que la lectura caiga una cuenta abajo en
// mas de la mitad de las distancias exactas. Por ejemplo, 31.00 m sobre el
// eje Y se leia 30.94 m. Por eso la red usa tri_distancia, una raiz cuadrada
// entera (sim/tb_distancia.v), y el CORDIC queda para los angulos.
//
// No esta en sim/simular.ps1 porque tarda unos 8 minutos:
//   iverilog -g2005 -s tb_dist_cordic -o tb_dist_cordic.out tb_dist_cordic.v ../hdl/cordic.v
//   vvp -n tb_dist_cordic.out
// ============================================================================
module tb_dist_cordic;

reg clk = 1'b0;
always #1 clk = ~clk;
reg reset = 1'b1;
reg start = 1'b0;
reg  signed [23:0] dx = 0, dy = 0;
wire signed [23:0] mx, my;
wire [15:0] mz;
wire listo;
cordic #(.W(24), .N(16)) u (.clk(clk), .reset(reset), .start(start), .modo(1'b1),
    .x0(dx <<< 4), .y0(dy <<< 4), .z0(16'd0), .x(mx), .y(my), .z(mz), .listo(listo));

// la cuenta de la primera version: magnitud * 0.60725 / 16, truncada
wire [39:0] d_x  = mx * 40'sd9949;
wire [9:0]  d_hw = (d_x[39:18] > 22'd1023) ? 10'd1023 : d_x[27:18];

integer ix, iy, n, r, ex;
integer total = 0, mal = 0, menos = 0, mas = 0, lejos = 0, cuad = 0, cuad_mal = 0;
integer anillo = 0, anillo_mal = 0, mostrados = 0, incoh = 0;

initial begin
    #10 reset = 1'b0;
    for (ix = 0; ix < 1024; ix = ix + 1) begin
        for (iy = 0; iy < 1024; iy = iy + 1) begin
            dx = ix; dy = iy;
            @(negedge clk) start = 1'b1;
            @(negedge clk) start = 1'b0;
            @(posedge listo);
            @(negedge clk);
            n = ix * ix + iy * iy;
            r = $rtoi($sqrt($itor(n)));
            while (r * r > n) r = r - 1;
            while ((r + 1) * (r + 1) <= n) r = r + 1;
            ex = (r > 1023) ? 1023 : r;
            total = total + 1;
            if (d_hw != ex) begin
                mal = mal + 1;
                if (d_hw == ex - 1)      menos = menos + 1;
                else if (d_hw == ex + 1) mas = mas + 1;
                else                     lejos = lejos + 1;
            end
            if (r * r == n) begin                       // la distancia exacta es un entero
                cuad = cuad + 1;
                if (d_hw != ex) begin
                    cuad_mal = cuad_mal + 1;
                    if (mostrados < 8) begin
                        mostrados = mostrados + 1;
                        $display("MEDIDA tb_dist_cordic ejemplo: (%0d, %0d) cuentas, exacto %0d, con CORDIC truncado %0d", ix, iy, ex, d_hw);
                    end
                end
            end
            if (r >= 500 && r <= 520) begin             // alrededor del corte de 32 m
                anillo = anillo + 1;
                if (d_hw != ex) anillo_mal = anillo_mal + 1;
            end
            if ((n < 262144) != (d_hw < 512)) incoh = incoh + 1;
        end
    end
    $display("MEDIDA tb_dist_cordic: %0d pares; la lectura difiere de la exacta en %0d (una cuenta menos %0d, una mas %0d, dos o mas %0d)", total, mal, menos, mas, lejos);
    $display("MEDIDA tb_dist_cordic: distancias exactas (cuadrados perfectos) %0d, mal leidas %0d", cuad, cuad_mal);
    $display("MEDIDA tb_dist_cordic: entre 500 y 520 cuentas, %0d puntos, mal leidos %0d", anillo, anillo_mal);
    $display("MEDIDA tb_dist_cordic: puntos donde (menos de 32 m) y (lectura menor que 512) no coinciden: %0d", incoh);
    $display("RESULTADO tb_dist_cordic: el CORDIC truncado falla en %0d de %0d distancias exactas", cuad_mal, cuad);
    $finish;
end

endmodule
