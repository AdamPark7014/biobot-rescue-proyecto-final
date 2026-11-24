`timescale 1ns / 1ps
module tb_pid;

localparam real KP_I = 0.50, KI_I = 0.05, KD_I = 0.25;
localparam real KP_Q = 128.0 / 256.0, KI_Q = 13.0 / 256.0, KD_Q = 64.0 / 256.0;
localparam real U_MAX = 255.0;

reg clk = 1'b0, reset = 1'b1, tick = 1'b0;
always #5 clk = ~clk;

reg  signed [15:0] ref_ = 16'sd0, y_con = 16'sd0, y_sin = 16'sd0;
wire signed [15:0] u_con, u_sin;
wire               sat_con, sat_sin;

pid_q #(.KP(16'sd128), .KI(16'sd13), .KD(16'sd64), .U_MAX(255), .ANTIWINDUP(1)) con (
    .clk(clk), .reset(reset), .tick(tick), .referencia(ref_), .medida(y_con), .u(u_con), .saturada(sat_con));
pid_q #(.KP(16'sd128), .KI(16'sd13), .KD(16'sd64), .U_MAX(255), .ANTIWINDUP(0)) sin (
    .clk(clk), .reset(reset), .tick(tick), .referencia(ref_), .medida(y_sin), .u(u_sin), .saturada(sat_sin));

// plantas
real p_con, p_sin, p_q, p_i;
real eq, eq_prev, int_q, uq, uq_raw;
real ei, ei_prev, int_i, ui, ui_raw;
real max_du, max_dy, max_dy_i, pico_con, pico_sin, ref_r, d;
integer n, errores = 0, ft, traza;
integer t_asienta, sat_n;

function real abs_r;
    input real v;
    abs_r = (v < 0.0) ? -v : v;
endfunction
function integer redondea;
    input real v;
    redondea = (v < 0.0) ? -$rtoi(0.5 - v) : $rtoi(v + 0.5);
endfunction

task arranca;
    input integer r;
    begin
        reset = 1'b1; ref_ = r; ref_r = r;
        p_con = 0.0; p_sin = 0.0; p_q = 0.0; p_i = 0.0;
        eq_prev = 0.0; int_q = 0.0; ei_prev = 0.0; int_i = 0.0;
        max_du = 0.0; max_dy = 0.0; max_dy_i = 0.0; pico_con = 0.0; pico_sin = 0.0;
        t_asienta = 0; sat_n = 0;
        y_con = 16'sd0; y_sin = 16'sd0;
        repeat (3) @(negedge clk);
        reset = 1'b0;
    end
endtask

// una muestra
task paso;
    begin
        y_con = redondea(p_con);
        y_sin = redondea(p_sin);
        @(negedge clk) tick = 1'b1;
        @(negedge clk) tick = 1'b0;
        // PID cuantizado
        eq = ref_r - $itor(y_con);
        uq_raw = KP_Q * eq + int_q + KD_Q * (eq - eq_prev);
        if (!((uq_raw > U_MAX && eq > 0.0) || (uq_raw < -U_MAX && eq < 0.0))) int_q = int_q + KI_Q * eq;
        eq_prev = eq;
        uq = (uq_raw > U_MAX) ? U_MAX : (uq_raw < -U_MAX) ? -U_MAX : uq_raw;
        // PID ideal
        ei = ref_r - p_i;
        ui_raw = KP_I * ei + int_i + KD_I * (ei - ei_prev);
        if (!((ui_raw > U_MAX && ei > 0.0) || (ui_raw < -U_MAX && ei < 0.0))) int_i = int_i + KI_I * ei;
        ei_prev = ei;
        ui = (ui_raw > U_MAX) ? U_MAX : (ui_raw < -U_MAX) ? -U_MAX : ui_raw;
        // comparacion
        d = abs_r($itor(u_con) - uq);     if (d > max_du) max_du = d;
        if (sat_con) sat_n = sat_n + 1;
        if (traza) $fdisplay(ft, "%0d,%0d,%0d,%0d,%0d,%0d,%0.3f", n, ref_, y_con, y_sin, u_con, u_sin, p_i);
        // plantas
        p_con = p_con + (4.0 * u_con - p_con) / 20.0;
        p_sin = p_sin + (4.0 * u_sin - p_sin) / 20.0;
        p_i   = p_i   + (4.0 * ui    - p_i)   / 20.0;
        d = abs_r(p_con - p_i);           if (d > max_dy_i) max_dy_i = d;
        if (ref_r >= 0.0) begin
            if (p_con > pico_con) pico_con = p_con;
            if (p_sin > pico_sin) pico_sin = p_sin;
        end else begin
            if (p_con < pico_con) pico_con = p_con;
            if (p_sin < pico_sin) pico_sin = p_sin;
        end
        if (abs_r(p_con - ref_r) > 0.02 * abs_r(ref_r)) t_asienta = n + 1;
        if (u_con > 16'sd255 || u_con < -16'sd255 || u_sin > 16'sd255 || u_sin < -16'sd255) begin
            errores = errores + 1;
            $display("ERROR tb_pid: la salida paso del tope en la muestra %0d", n);
        end
    end
endtask

task revisa;
    input [8*40-1:0] nombre;
    input            cond;
    begin
        if (!cond) begin errores = errores + 1; $display("ERROR tb_pid: %0s", nombre); end
    end
endtask

initial begin
    traza = 0;

    // escalon chico
    arranca(200);
    for (n = 0; n < 300; n = n + 1) paso;
    $display("MEDIDA tb_pid 1 escalon de 200: sobrepaso %0.1f %%, asentamiento al 2 %% en %0d muestras, valor final %0.2f, muestras saturadas %0d",
             (pico_con - 200.0) / 2.0, t_asienta, p_con, sat_n);
    $display("MEDIDA tb_pid 1 punto fijo contra reales: salida u, diferencia maxima %0.3f cuentas con las mismas muestras; respuesta de la planta, %0.3f cuentas frente al lazo con las ganancias ideales",
             max_du, max_dy_i);
    revisa("1 la salida difiere de los reales", max_du < 1.0);
    revisa("1 no llega a la referencia", abs_r(p_con - 200.0) <= 1.0);
    revisa("1 se saturo", sat_n == 0);

    // escalon grande
    arranca(1000);
    if ($test$plusargs("traza")) begin
        ft = $fopen("trazas/pid.csv", "w");
        $fdisplay(ft, "muestra,ref,y_con,y_sin,u_con,u_sin,y_reales");
        traza = 1;
    end
    for (n = 0; n < 400; n = n + 1) paso;
    if (traza) begin $fclose(ft); traza = 0; end
    $display("MEDIDA tb_pid 2 escalon de 1000: con integracion condicional, sobrepaso %0.1f %% y valor final %0.2f; sin ella, sobrepaso %0.1f %%; muestras saturadas %0d",
             (pico_con - 1000.0) / 10.0, p_con, (pico_sin - 1000.0) / 10.0, sat_n);
    $display("MEDIDA tb_pid 2 punto fijo contra reales: salida u, diferencia maxima %0.3f cuentas con las mismas muestras; respuesta de la planta, %0.3f cuentas frente al lazo con las ganancias ideales", max_du, max_dy_i);
    revisa("2 el integrador saturado no sobrepasa mas", pico_sin > pico_con + 10.0);
    revisa("2 la salida difiere de los reales", max_du < 1.0);
    revisa("2 no llega a la referencia", abs_r(p_con - 1000.0) <= 2.0);
    revisa("2 no se saturo", sat_n > 0);

    // escalon negativo
    arranca(-600);
    for (n = 0; n < 400; n = n + 1) paso;
    $display("MEDIDA tb_pid 3 escalon de -600: sobrepaso %0.1f %%, valor final %0.2f, diferencia maxima de u contra reales %0.3f cuentas",
             (pico_con + 600.0) / -6.0, p_con, max_du);
    revisa("3 la salida difiere de los reales", max_du < 1.0);
    revisa("3 no llega a la referencia", abs_r(p_con + 600.0) <= 2.0);

    if (errores == 0) $display("RESULTADO tb_pid: 3 de 3 escenarios correctos");
    else              $display("RESULTADO tb_pid: %0d errores", errores);
    $finish;
end

endmodule
