`timescale 1ns / 1ps
// ============================================================================
// tb_cordic.v
// Banco de pruebas del CORDIC y del divisor (hdl/cordic.v): compara contra el
// valor exacto calculado con aritmetica real, en los cuatro cuadrantes.
//   vectorizacion: atan2 y magnitud de 24 vectores alrededor del circulo
//   rotacion:      cos y sin de 24 angulos alrededor del circulo
//   divisor:       200 divisiones al azar
// Criterio: error de angulo < 0.05 grados y de magnitud/cos/sin < 0.1 %.
// ============================================================================
module tb_cordic;

reg clk = 1'b0, reset = 1'b1;
always #5 clk = ~clk;

reg         start = 1'b0, modo = 1'b0;
reg  signed [23:0] x0 = 0, y0 = 0;
reg  [15:0] z0 = 0;
wire signed [23:0] x, y;
wire [15:0] z;
wire        listo;

cordic #(.W(24), .N(16)) dut (.clk(clk), .reset(reset), .start(start), .modo(modo),
    .x0(x0), .y0(y0), .z0(z0), .x(x), .y(y), .z(z), .listo(listo));

reg  dstart = 1'b0;
reg  [31:0] num = 0;
reg  [15:0] den = 1;
wire [31:0] coc;
wire        dlisto;
divisor_u #(.WN(32), .WD(16)) div (.clk(clk), .reset(reset), .start(dstart), .num(num), .den(den),
    .coc(coc), .listo(dlisto));

localparam real PI = 3.14159265358979;
localparam real K  = 1.646760258;

integer k, errores = 0;
real    ang, ex, ey, e_ang, e_mag, mag, peor_ang = 0, peor_mag = 0, peor_rot = 0;

task corre;
    begin
        @(posedge clk); start <= 1'b1;
        @(posedge clk); start <= 1'b0;
        wait (listo); @(posedge clk);
    end
endtask

initial begin
    repeat (3) @(posedge clk);
    reset = 1'b0;

    // ---- vectorizacion
    for (k = 0; k < 24; k = k + 1) begin
        ang = (k * 15.0 + 7.0) * PI / 180.0;
        modo <= 1'b1;
        x0 <= $rtoi(3000.0 * $cos(ang));
        y0 <= $rtoi(3000.0 * $sin(ang));
        corre;
        ex = $atan2($itor(y0), $itor(x0)) * 180.0 / PI;   // -180..180
        e_ang = $itor($signed(z)) * 360.0 / 65536.0 - ex;
        if (e_ang > 180.0) e_ang = e_ang - 360.0;
        if (e_ang < -180.0) e_ang = e_ang + 360.0;
        if (e_ang < 0) e_ang = -e_ang;
        mag = $sqrt($itor(x0) * $itor(x0) + $itor(y0) * $itor(y0)) * K;
        e_mag = ($itor(x) - mag) / mag; if (e_mag < 0) e_mag = -e_mag;
        if (e_ang > peor_ang) peor_ang = e_ang;
        if (e_mag > peor_mag) peor_mag = e_mag;
        if (e_ang > 0.05 || e_mag > 0.001) begin
            errores = errores + 1;
            $display("ERROR tb_cordic vectorizacion k=%0d: z=%0d (%f grados, se esperaba %f), x=%0d (se esperaba %f)",
                     k, $signed(z), $itor($signed(z)) * 360.0 / 65536.0, ex, x, mag);
        end
    end

    // ---- rotacion de (1/K, 0) escalado a 2^14
    for (k = 0; k < 24; k = k + 1) begin
        ang = (k * 15.0 + 3.0);
        modo <= 1'b0;
        x0 <= 24'sd9949; y0 <= 24'sd0;
        z0 <= $rtoi(ang * 65536.0 / 360.0);
        corre;
        ex = 16384.0 * $cos(ang * PI / 180.0);
        ey = 16384.0 * $sin(ang * PI / 180.0);
        e_mag = ($itor(x) - ex) / 16384.0; if (e_mag < 0) e_mag = -e_mag;
        if (e_mag > peor_rot) peor_rot = e_mag;
        e_ang = ($itor(y) - ey) / 16384.0; if (e_ang < 0) e_ang = -e_ang;
        if (e_ang > peor_rot) peor_rot = e_ang;
        if (e_mag > 0.001 || e_ang > 0.001) begin
            errores = errores + 1;
            $display("ERROR tb_cordic rotacion %f grados: cos %0d (se esperaba %f), sin %0d (se esperaba %f)",
                     ang, x, ex, y, ey);
        end
    end

    // ---- divisor
    for (k = 0; k < 200; k = k + 1) begin
        num <= $urandom; den <= ($urandom % 65535) + 1;
        @(posedge clk); dstart <= 1'b1;
        @(posedge clk); dstart <= 1'b0;
        wait (dlisto); @(posedge clk);
        if (coc !== num / den) begin
            errores = errores + 1;
            $display("ERROR tb_cordic divisor: %0d / %0d = %0d, se esperaba %0d", num, den, coc, num / den);
        end
    end

    $display("MEDIDA tb_cordic: peor error de angulo %f grados, de magnitud %f %%, de cos/sin %f %%",
             peor_ang, peor_mag * 100.0, peor_rot * 100.0);
    if (errores == 0) $display("RESULTADO tb_cordic: 248 de 248 casos correctos");
    else              $display("RESULTADO tb_cordic: %0d errores", errores);
    $finish;
end

endmodule
