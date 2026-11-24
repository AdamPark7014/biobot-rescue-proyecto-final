`timescale 1ns / 1ps
module tb_cordic_iter;

localparam integer CASOS = 9;
localparam real    PI    = 3.14159265358979;

reg clk = 1'b0, reset = 1'b1;
always #5 clk = ~clk;

reg                start = 1'b0, modo = 1'b0;
reg  signed [23:0] x0 = 0, y0 = 0;
reg  [15:0]        z0 = 0;
wire signed [23:0] x [0:CASOS-1];
wire signed [23:0] y [0:CASOS-1];
wire [15:0]        z [0:CASOS-1];

reg  signed [23:0] x0_rot [0:CASOS-1];

genvar g;
generate
    for (g = 0; g < CASOS; g = g + 1) begin : c
        wire listo;
        cordic #(.W(24), .N(4 + 2 * g)) dut (.clk(clk), .reset(reset), .start(start), .modo(modo),
            .x0(modo ? x0 : x0_rot[g]), .y0(y0), .z0(z0), .x(x[g]), .y(y[g]), .z(z[g]), .listo(listo));
    end
endgenerate

real    kn [0:CASOS-1];
real    max_ang [0:CASOS-1], max_mag [0:CASOS-1], max_rot [0:CASOS-1];
real    sum_ang [0:CASOS-1];
real    ang, ex, e, mag, k_acum;
integer i, j, k, n_iter, errores = 0;

task corre;
    begin
        @(posedge clk); start <= 1'b1;
        @(posedge clk); start <= 1'b0;
        repeat (26) @(posedge clk);
    end
endtask

function real abs_r;
    input real v;
    abs_r = (v < 0.0) ? -v : v;
endfunction

initial begin
    for (j = 0; j < CASOS; j = j + 1) begin
        n_iter = 4 + 2 * j;
        k_acum = 1.0;
        for (i = 0; i < n_iter; i = i + 1) k_acum = k_acum * $sqrt(1.0 + $pow(2.0, -2.0 * i));
        kn[j] = k_acum;
        x0_rot[j] = $rtoi(16384.0 / k_acum + 0.5);
        max_ang[j] = 0.0; max_mag[j] = 0.0; max_rot[j] = 0.0; sum_ang[j] = 0.0;
    end
    repeat (3) @(posedge clk);
    reset = 1'b0;

    // vectorizacion
    modo <= 1'b1;
    for (k = 0; k < 360; k = k + 1) begin
        ang = (k + 0.37) * PI / 180.0;
        x0 <= $rtoi(12000.0 * $cos(ang));
        y0 <= $rtoi(12000.0 * $sin(ang));
        z0 <= 16'd0;
        corre;
        ex  = $atan2($itor(y0), $itor(x0)) * 180.0 / PI;
        mag = $sqrt($itor(x0) * $itor(x0) + $itor(y0) * $itor(y0));
        for (j = 0; j < CASOS; j = j + 1) begin
            e = $itor($signed(z[j])) * 360.0 / 65536.0 - ex;
            if (e > 180.0)  e = e - 360.0;
            if (e < -180.0) e = e + 360.0;
            if (abs_r(e) > max_ang[j]) max_ang[j] = abs_r(e);
            sum_ang[j] = sum_ang[j] + e * e;
            e = ($itor(x[j]) / kn[j] - mag) * 100.0 / mag;
            if (abs_r(e) > max_mag[j]) max_mag[j] = abs_r(e);
        end
    end

    // rotacion
    modo <= 1'b0;
    for (k = 0; k < 360; k = k + 1) begin
        z0 <= $rtoi((k + 0.37) * 65536.0 / 360.0);
        y0 <= 24'sd0;
        corre;
        ang = $itor(z0) * 2.0 * PI / 65536.0;
        for (j = 0; j < CASOS; j = j + 1) begin
            e = ($itor(x[j]) / 16384.0 - $cos(ang)) * 100.0;
            if (abs_r(e) > max_rot[j]) max_rot[j] = abs_r(e);
            e = ($itor(y[j]) / 16384.0 - $sin(ang)) * 100.0;
            if (abs_r(e) > max_rot[j]) max_rot[j] = abs_r(e);
        end
    end

    for (j = 0; j < CASOS; j = j + 1)
        $display("MEDIDA tb_cordic_iter N=%0d: K=%0.6f; angulo, error maximo %0.5f grados y eficaz %0.5f; magnitud, error maximo %0.5f %%; coseno y seno, error maximo %0.5f %%",
                 4 + 2 * j, kn[j], max_ang[j], $sqrt(sum_ang[j] / 360.0), max_mag[j], max_rot[j]);

    // comprobacion
    for (j = 1; j <= 5; j = j + 1)
        if (max_ang[j] >= max_ang[j - 1]) begin
            errores = errores + 1;
            $display("ERROR tb_cordic_iter: el error de angulo no baja de N=%0d a N=%0d", 2 + 2 * j, 4 + 2 * j);
        end
    if (max_ang[6] > 0.05 || max_mag[6] > 0.1 || max_rot[6] > 0.1) begin
        errores = errores + 1;
        $display("ERROR tb_cordic_iter: con N=16 el error pasa de 0.05 grados o de 0.1 %%");
    end
    if (errores == 0) $display("RESULTADO tb_cordic_iter: el error baja con N y con N=16 queda en %0.4f grados y %0.4f %%", max_ang[6], max_mag[6]);
    else              $display("RESULTADO tb_cordic_iter: %0d errores", errores);
    $finish;
end

endmodule
