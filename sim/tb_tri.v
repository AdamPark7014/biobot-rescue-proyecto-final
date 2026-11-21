`timescale 1ns / 1ps
// ============================================================================
// tb_tri.v
// Banco de pruebas de la red de deteccion y triangulacion con tres FPGA
// (hdl/tri_red.v): mochila A, mochila B y receptor, cableadas como en el
// laboratorio:
//   A.TX -> receptor.RX1 y B.RX1      B.TX -> receptor.RX2 y A.RX1
// El mapa mide 64 m (1 cuenta = 6.25 cm). El receptor esta en la entrada
// (0, 0) y la persona en (25.50, 19.25) m, a 31.95 m: en el borde del
// alcance, que es de 32 m para el radio y para los tonos. Interruptores de
// cada mochila: SW5-SW0 temperatura (detecta de 35 a 38 C), SW9-SW6 posicion.
//
//   1 triangulacion   A en la posicion 1 (a 32.00 m: fuera de alcance) y B en
//                     la 0 (a 31.60 m), las dos a 36 C: el aviso de A llega
//                     por B, el conteo sube a 2 en las tres tarjetas y el
//                     receptor cruza los dos rumbos
//   2 objeto caliente a 47 C no cuenta; tampoco 34 ni 39 C; 35 y 38 C si
//   3 solo A          B en la posicion 7 (cerca de la entrada) a 22 C hace de
//                     puente: conteo 1 en las tres
//   4 rumbos opuestos las rectas no se cruzan: se promedia
//   5 boton           nada caliente; se aprieta el boton de B: conteo 1 en todas
//   6 sin alcance     B lejos (posicion 5): las mochilas se oyen entre si pero
//                     ninguna llega al receptor
//   7 sigue al sensor al salir de 35-38 C el conteo baja; al volver, sube
//   8 ruido           la linea de B al receptor se ensucia 3 s: las tramas
//                     danadas se descartan por CRC, el receptor cuenta las
//                     perdidas y no usa ningun dato equivocado
//   9 umbral          A sola, puesta por la terminal a 31 m (se oye) y a 32 m
//                     (ya no se oye): radio y tono cortan en el mismo punto
// Con +rapido solo corren el 1 y el 9.
// Reloj declarado de 400 kHz y 40 000 baudios (10 ciclos por bit).
// ============================================================================
module tb_tri;

localparam CLK  = 400000;
localparam BAUD = 40000;

reg        clk = 1'b0;
reg        reset = 1'b1;
reg        boton_a = 1'b0, boton_b = 1'b0;
reg  [9:0] sw_a = 0, sw_b = 0;
reg        pe_a = 1'b0;                // la posicion de A la fija la terminal
reg  [9:0] xe_a = 0, ye_a = 0;
reg        ruido = 1'b0, mete_ruido = 1'b0;
wire       tx_a, tx_b, tx_pc;
wire       rx2_r = tx_b ^ ruido;       // linea de B al receptor, con ruido
wire [9:0] led_a, led_b, led_r;
wire [6:0] ha0, ha1, ha2, ha3, ha4, ha5, hb0, hb1, hb2, hb3, hb4, hb5, hr0, hr1, hr2, hr3, hr4, hr5;

wire [9:0]  xa, ya, xb, yb, est_x, est_y, tha, thb, do_a, do_b, dr_a, dr_b, d_ab, d_ra, d_rb;
wire [15:0] rm_a, rm_b, rr_a, rr_b, po_a, pr_a, po_b, pr_b, pt_a, pt_b;
wire        ok_a, ok_b, al_a, al_b, pe_ba, pe_bb, ov_a, ov_b, od_a, od_b, or_a, or_b, ot_a, ot_b;
wire        oye_ra, oye_rb, tono_a, tono_b, tono_r;
wire [2:0]  es_a, es_b, modo, n_ev;
wire [6:0]  nf_a, nf_b;
wire [7:0]  rg_a, rg_b, perd_a, perd_b, malas;
wire [5:0]  tp_a, tp_b;
wire [1:0]  terr, cu_a, cu_b, cu_r;
wire [3:0]  enl;
wire [41:0] info_a, info_b;

tri_mochila #(.ROL(1), .CLK_FREQ(CLK), .BAUD_RATE(BAUD), .OFFSET(16'd2185)) a (
    .clk(clk), .reset(reset), .boton(boton_a), .sw(sw_a), .pos_ext(pe_a), .x_ext(xe_a), .y_ext(ye_a),
    .rx1(tx_b), .rx2(1'b1), .tx(tx_a), .ledr(led_a),
    .hex0(ha0), .hex1(ha1), .hex2(ha2), .hex3(ha3), .hex4(ha4), .hex5(ha5),
    .x_yo(xa), .y_yo(ya), .temp(tp_a), .d_rec(dr_a), .oye_rec(or_a), .oye_otra(ot_a), .pot_rec(pr_a),
    .pot_otra(po_a), .tono(tono_a), .cuenta_pd(cu_a),
    .rumbo_med(rm_a), .rumbo_ok(ok_a), .alerta(al_a), .persona(pe_ba), .estado(es_a),
    .n_fil(nf_a), .rango(rg_a), .rumbo_real(rr_a), .d_otra(do_a), .otra_viva(ov_a), .otra_detecta(od_a));
tri_mochila #(.ROL(2), .CLK_FREQ(CLK), .BAUD_RATE(BAUD), .OFFSET(16'd63898)) b (
    .clk(clk), .reset(reset), .boton(boton_b), .sw(sw_b), .pos_ext(1'b0), .x_ext(10'd0), .y_ext(10'd0),
    .rx1(tx_a), .rx2(1'b1), .tx(tx_b), .ledr(led_b),
    .hex0(hb0), .hex1(hb1), .hex2(hb2), .hex3(hb3), .hex4(hb4), .hex5(hb5),
    .x_yo(xb), .y_yo(yb), .temp(tp_b), .d_rec(dr_b), .oye_rec(or_b), .oye_otra(ot_b), .pot_rec(pr_b),
    .pot_otra(po_b), .tono(tono_b), .cuenta_pd(cu_b),
    .rumbo_med(rm_b), .rumbo_ok(ok_b), .alerta(al_b), .persona(pe_bb), .estado(es_b),
    .n_fil(nf_b), .rango(rg_b), .rumbo_real(rr_b), .d_otra(do_b), .otra_viva(ov_b), .otra_detecta(od_b));
tri_receptor #(.CLK_FREQ(CLK), .BAUD_RATE(BAUD)) r (
    .clk(clk), .reset(reset), .vista(2'b00), .rx1(tx_a), .rx2(rx2_r), .tx_pc(tx_pc), .ledr(led_r),
    .hex0(hr0), .hex1(hr1), .hex2(hr2), .hex3(hr3), .hex4(hr4), .hex5(hr5),
    .est_x(est_x), .est_y(est_y), .modo(modo), .n_ev(n_ev), .tri_error(terr), .tha_o(tha), .thb_o(thb),
    .d_ab(d_ab), .d_a(d_ra), .d_b(d_rb), .cuenta_pd(cu_r), .enlaces(enl),
    .perd_a(perd_a), .perd_b(perd_b), .malas(malas), .info_a(info_a), .info_b(info_b),
    .oye_a(oye_ra), .oye_b(oye_rb), .pot_a(pt_a), .pot_b(pt_b), .tono(tono_r));

always #5 clk = ~clk;

// ruido en la linea: un pulso de bit y medio cada 61.3 us mientras mete_ruido = 1
initial forever begin
    #61300;
    if (mete_ruido) begin ruido = 1'b1; #150; ruido = 1'b0; end
end

// sw = {posicion[3:0], temperatura[5:0]}
function [9:0] sw;
    input [3:0] k;
    input [5:0] t;
    sw = {k, t};
endfunction

integer errores = 0, total = 0;
real    t0, t_hit, ex_m, ey_m, err_m;
real    PX = 408.0 / 16.0, PY = 308.0 / 16.0;
reg     rapido;

task arranca;
    input [9:0] swa, swb;
    begin
        reset = 1'b1; sw_a = swa; sw_b = swb; boton_a = 1'b0; boton_b = 1'b0; pe_a = 1'b0; mete_ruido = 1'b0;
        repeat (20) @(posedge clk);
        reset = 1'b0;
        t0 = $realtime;
        total = total + 1;
    end
endtask
task espera_s;
    input real s;
    begin
        repeat ($rtoi(s * CLK)) @(posedge clk);
    end
endtask
task espera_modo;
    input [2:0] m;
    input real  max_s;
    integer n;
    begin
        n = 0; t_hit = -1.0;
        while (modo != m && n < $rtoi(max_s * CLK)) begin @(posedge clk); n = n + 1; end
        if (modo == m) t_hit = ($realtime - t0) * 1.0e-9 * (100000000.0 / CLK);
    end
endtask
function real m_;                     // cuentas de 1/16 m a metros
    input [9:0] c;
    m_ = c / 16.0;
endfunction
function real g16;
    input [15:0] v;
    g16 = v * 360.0 / 65536.0;
endfunction

task revisa;
    input [8*48-1:0] nombre;
    input            cond;
    begin
        if (!cond) begin
            errores = errores + 1;
            $display("ERROR tb_tri %0s: modo=%0d cuenta A/B/R=%0d/%0d/%0d err=%0d est=(%f, %f) enlaces=%b tonos A[b=%b r=%b] B[a=%b r=%b] R[a=%b b=%b] ledA=%b ledB=%b ledR=%b",
                     nombre, modo, cu_a, cu_b, cu_r, terr, m_(est_x), m_(est_y), enl, ot_a, or_a, ot_b, or_b, oye_ra, oye_rb, led_a, led_b, led_r);
        end
    end
endtask

task resumen;
    input [8*24-1:0] nombre;
    begin
        $display("MEDIDA tb_tri %0s: conteo A/B/R = %0d/%0d/%0d; tonos: A oye a B %b y al receptor %b; B oye a A %b y al receptor %b; el receptor oye a A %b y a B %b; radio: A directo %b, A por puente %b, B directo %b",
                 nombre, cu_a, cu_b, cu_r, ot_a, or_a, ot_b, or_b, oye_ra, oye_rb, enl[3], enl[2], enl[1]);
        $display("MEDIDA tb_tri %0s: LED A = %b (B a %0d m | receptor a %0d m), LED B = %b (A a %0d m | receptor a %0d m), LED receptor = %b (A a %0d m | B a %0d m)",
                 nombre, led_a, led_a[9:5], led_a[4:0], led_b, led_b[9:5], led_b[4:0], led_r, led_r[9:5], led_r[4:0]);
    end
endtask

initial begin
    rapido = $test$plusargs("rapido");

    // ---- 1: triangulacion con puente
    arranca(sw(4'd1, 6'd36), sw(4'd0, 6'd36));
    espera_modo(3'd2, 6.0);
    espera_s(1.0);
    ex_m = m_(est_x) - PX; ey_m = m_(est_y) - PY;
    err_m = $sqrt(ex_m * ex_m + ey_m * ey_m);
    $display("MEDIDA tb_tri 1 triangulacion: persona estimada en (%0.3f, %0.3f) m, verdadera (%0.3f, %0.3f), error %0.3f m; latencia %0.2f s",
             m_(est_x), m_(est_y), PX, PY, err_m, t_hit);
    $display("MEDIDA tb_tri 1 rumbos: A %0.1f grados (verdadero %0.1f), B %0.1f (verdadero %0.1f); distancia A-B %0.3f m, receptor-A %0.2f m, receptor-B %0.2f m",
             g16(rm_a), g16(rr_a), g16(rm_b), g16(rr_b), m_(d_ab), m_(d_ra), m_(d_rb));
    $display("MEDIDA tb_tri 1 tonos: potencia en A de 2 kHz (B) %0d y de 4 kHz (receptor) %0d; en el receptor de 1 kHz (A) %0d y de 2 kHz (B) %0d",
             po_a, pr_a, pt_a, pt_b);
    resumen("1");
    revisa("1 triangulacion", modo == 3'd2 && err_m < 0.10 && cu_a == 2 && cu_b == 2 && cu_r == 2
           && enl[3:1] == 3'b011 && ot_a && ot_b && !or_a && or_b && !oye_ra && oye_rb
           && led_a == 10'b0000000000 && led_b == 10'b0000011111 && led_r == 10'b0000011111
           && perd_a == 0 && perd_b == 0 && malas == 0);

    if (!rapido) begin
    // ---- 2: objeto caliente, y los bordes de la ventana: 34 y 39 C no, 35 y 38 C si
    arranca(sw(4'd1, 6'd47), sw(4'd0, 6'd47));
    espera_s(4.0);
    resumen("2");
    revisa("2 objeto caliente", modo == 3'd0 && cu_a == 0 && cu_b == 0 && cu_r == 0 && !al_a && !al_b);
    arranca(sw(4'd1, 6'd34), sw(4'd0, 6'd39));
    espera_s(4.0);
    $display("MEDIDA tb_tri 2 bordes: A a 34 C alerta %b, B a 39 C alerta %b", al_a, al_b);
    revisa("2 bordes 34 y 39", !al_a && !al_b && cu_r == 0);
    arranca(sw(4'd1, 6'd35), sw(4'd0, 6'd38));
    espera_s(4.0);
    $display("MEDIDA tb_tri 2 bordes: A a 35 C alerta %b, B a 38 C alerta %b", al_a, al_b);
    revisa("2 bordes 35 y 38", al_a && al_b && cu_r == 2);
    total = total - 2;

    // ---- 3: solo A detecta; B cerca de la entrada hace de puente
    arranca(sw(4'd1, 6'd36), sw(4'd7, 6'd22));
    espera_modo(3'd1, 6.0);
    espera_s(1.0);
    ex_m = m_(est_x) - PX; ey_m = m_(est_y) - PY;
    err_m = $sqrt(ex_m * ex_m + ey_m * ey_m);
    $display("MEDIDA tb_tri 3 solo A: posicion aproximada (%0.3f, %0.3f) m, error %0.3f m", m_(est_x), m_(est_y), err_m);
    resumen("3");
    revisa("3 solo A", modo == 3'd1 && err_m < 0.25 && cu_a == 1 && cu_b == 1 && cu_r == 1 && enl[2]
           && led_a[9:5] == 5'd26 && led_b == {5'd26, 5'd5} && led_r == {5'd0, 5'd5});

    // ---- 4: rumbos opuestos
    arranca(sw(4'd2, 6'd36), sw(4'd0, 6'd36));
    espera_modo(3'd3, 6.0);
    espera_s(0.5);
    $display("MEDIDA tb_tri 4 rumbos opuestos: error de triangulacion %0d (1 = casi paralelos), promedio (%0.3f, %0.3f) m",
             terr, m_(est_x), m_(est_y));
    revisa("4 rumbos opuestos", modo == 3'd3 && terr == 2'd1 && cu_r == 2);

    // ---- 5: boton de B
    arranca(sw(4'd1, 6'd22), sw(4'd0, 6'd22));
    espera_s(1.0);
    boton_b = 1'b1; espera_s(0.3); boton_b = 1'b0;
    espera_modo(3'd4, 3.0);
    espera_s(0.5);
    resumen("5");
    revisa("5 boton", modo == 3'd4 && cu_a == 1 && cu_b == 1 && cu_r == 1 && est_x == xb && est_y == yb);

    // ---- 6: B lejos de la entrada
    arranca(sw(4'd1, 6'd36), sw(4'd5, 6'd36));
    espera_s(4.0);
    resumen("6");
    revisa("6 sin alcance", modo == 3'd0 && cu_r == 0 && enl == 4'b0000 && cu_a == 2 && cu_b == 2
           && ot_a && ot_b && !or_a && !or_b && !oye_ra && !oye_rb && led_r == 10'd0 && led_a == {5'd18, 5'd0});

    // ---- 7: la deteccion sigue al sensor
    arranca(sw(4'd1, 6'd36), sw(4'd0, 6'd36));
    espera_s(3.0);
    $display("MEDIDA tb_tri 7 las dos a 36 C: conteo A/B/R = %0d/%0d/%0d", cu_a, cu_b, cu_r);
    revisa("7 sube a 2", cu_a == 2 && cu_b == 2 && cu_r == 2);
    sw_a = sw(4'd1, 6'd25);
    espera_s(2.5);
    $display("MEDIDA tb_tri 7 A baja a 25 C: conteo A/B/R = %0d/%0d/%0d, estado de A %0d", cu_a, cu_b, cu_r, es_a);
    revisa("7 baja a 1", cu_a == 1 && cu_b == 1 && cu_r == 1 && !al_a && al_b);
    sw_b = sw(4'd0, 6'd40);
    espera_s(2.5);
    $display("MEDIDA tb_tri 7 B sube a 40 C: conteo A/B/R = %0d/%0d/%0d", cu_a, cu_b, cu_r);
    revisa("7 baja a 0", cu_a == 0 && cu_b == 0 && cu_r == 0);
    sw_a = sw(4'd1, 6'd37);
    espera_s(3.0);
    $display("MEDIDA tb_tri 7 A vuelve a 37 C: conteo A/B/R = %0d/%0d/%0d", cu_a, cu_b, cu_r);
    revisa("7 vuelve a 1", cu_a == 1 && cu_b == 1 && cu_r == 1 && al_a);

    // ---- 8: ruido en la linea de B al receptor
    arranca(sw(4'd1, 6'd36), sw(4'd0, 6'd36));
    espera_s(3.0);
    revisa("8 antes del ruido", modo == 3'd2 && cu_r == 2 && malas == 0 && perd_a == 0 && perd_b == 0);
    mete_ruido = 1'b1;
    espera_s(3.0);
    mete_ruido = 1'b0;
    espera_s(1.5);
    ex_m = m_(est_x) - PX; ey_m = m_(est_y) - PY;
    err_m = $sqrt(ex_m * ex_m + ey_m * ey_m);
    $display("MEDIDA tb_tri 8 ruido: tramas descartadas por CRC %0d; perdidas de A %0d y de B %0d; despues: modo %0d, conteo %0d, error %0.3f m",
             malas, perd_a, perd_b, modo, cu_r, err_m);
    revisa("8 ruido", malas > 0 && (perd_a + perd_b) > 0 && modo == 3'd2 && cu_r == 2 && err_m < 0.10);
    end

    // ---- 9: umbral de alcance, con la posicion de A fijada por la terminal
    arranca(sw(4'd0, 6'd36), sw(4'd15, 6'd22));
    pe_a = 1'b1; xe_a = 10'd496; ye_a = 10'd0;          // 31.00 m
    espera_s(3.5);
    $display("MEDIDA tb_tri 9 A a %0.2f m: radio directo %b, tono de A en el receptor %b (potencia %0d), conteo %0d, LED receptor %b, LED A %b",
             m_(dr_a), enl[3], oye_ra, pt_a, cu_r, led_r, led_a);
    revisa("9 a 31 m se oye", enl[3] && oye_ra && or_a && cu_r == 1 && led_r == {5'd31, 5'd0} && led_a == {5'd0, 5'd31});
    xe_a = 10'd512;                                     // 32.00 m
    espera_s(2.0);
    $display("MEDIDA tb_tri 9 A a %0.2f m: radio directo %b, tono de A en el receptor %b (potencia %0d), conteo %0d, LED receptor %b, LED A %b",
             m_(dr_a), enl[3], oye_ra, pt_a, cu_r, led_r, led_a);
    revisa("9 a 32 m ya no", !enl[3] && !oye_ra && !or_a && cu_r == 0 && led_r == 10'd0 && led_a == 10'd0);
    xe_a = 10'd511;                                     // 31.94 m
    espera_s(2.0);
    $display("MEDIDA tb_tri 9 A a %0.2f m: radio directo %b, tono %b, conteo %0d", m_(dr_a), enl[3], oye_ra, cu_r);
    revisa("9 a 31.94 m se oye", enl[3] && oye_ra && cu_r == 1);

    if (errores == 0) $display("RESULTADO tb_tri: %0d de %0d escenarios correctos", total, total);
    else              $display("RESULTADO tb_tri: %0d errores", errores);
    $finish;
end

endmodule
