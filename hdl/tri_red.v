`timescale 1ns / 1ps

// transmisor de trama
module tri_tx_n #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer N         = 12,
    parameter [7:0]   CAB       = 8'hA5
) (
    input  wire           clk,
    input  wire           reset,
    input  wire           start,
    input  wire [8*N-1:0] carga,
    output wire           tx,
    output wire           ocupado
);

reg  [7:0]  dato;
reg         arranca;
wire        busy;
uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (.clk(clk), .reset(reset), .tx_start(arranca),
    .data_in(dato), .tx(tx), .busy(busy));

reg  [8*N-1:0] c;
reg  [7:0]     k;
reg  [1:0]     st;
reg  [15:0]    crc;
assign ocupado = (st != 2'd0);
wire [7:0] byte_k = c[8*N-1:8*N-8];

// CRC-16
function [15:0] crc16;
    input [15:0] c0;
    input [7:0]  d;
    integer i;
    reg [15:0] r;
    begin
        r = c0 ^ {d, 8'h00};
        for (i = 0; i < 8; i = i + 1) r = r[15] ? ((r << 1) ^ 16'h1021) : (r << 1);
        crc16 = r;
    end
endfunction

always @(posedge clk or posedge reset) begin
    if (reset) begin
        dato <= 8'h00; arranca <= 1'b0; c <= 0; k <= 0; st <= 0; crc <= 16'hFFFF;
    end else begin
        arranca <= 1'b0;
        case (st)
            2'd0: if (start) begin c <= carga; k <= 8'd0; crc <= 16'hFFFF; st <= 2'd1; end
            2'd1: begin
                      if (k == 8'd0)       dato <= CAB;
                      else if (k <= N)     begin dato <= byte_k; crc <= crc16(crc, byte_k); end
                      else if (k == N + 1) dato <= crc[15:8];
                      else                 dato <= crc[7:0];
                      arranca <= 1'b1;
                      st <= 2'd2;
                  end
            2'd2: if (busy) st <= 2'd3;
            default: if (!busy) begin
                      if (k >= 8'd1 && k <= N) c <= c << 8;
                      if (k == N + 2) st <= 2'd0;
                      else begin k <= k + 8'd1; st <= 2'd1; end
                  end
        endcase
    end
end

endmodule

// receptor de trama
module tri_rx_n #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer N         = 12,
    parameter [7:0]   CAB       = 8'hA5
) (
    input  wire           clk,
    input  wire           reset,
    input  wire           rx,
    output reg            listo,
    output reg  [8*N-1:0] carga,
    output reg            mala
);

wire [7:0] d;
wire       v;
uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (.clk(clk), .reset(reset), .rx(rx),
    .data_out(d), .data_valid(v));

localparam integer T_HUECO = CLK_FREQ / 500;

reg [7:0]     n;
reg [8*N-1:0] b;
reg [15:0]    crc;
reg [7:0]     crc_alto;
reg [31:0]    hueco;

// CRC-16
function [15:0] crc16;
    input [15:0] c0;
    input [7:0]  d0;
    integer i;
    reg [15:0] r;
    begin
        r = c0 ^ {d0, 8'h00};
        for (i = 0; i < 8; i = i + 1) r = r[15] ? ((r << 1) ^ 16'h1021) : (r << 1);
        crc16 = r;
    end
endfunction

always @(posedge clk or posedge reset) begin
    if (reset) begin
        n <= 0; b <= 0; crc <= 16'hFFFF; crc_alto <= 8'h00; hueco <= 0; listo <= 1'b0; mala <= 1'b0; carga <= 0;
    end else begin
        listo <= 1'b0;
        mala  <= 1'b0;
        if (v) begin
            hueco <= 0;
            if (n == 8'd0) begin
                if (d == CAB) begin n <= 8'd1; crc <= 16'hFFFF; end
            end else if (n <= N) begin
                b <= {b[8*N-9:0], d}; crc <= crc16(crc, d); n <= n + 8'd1;
            end else if (n == N + 1) begin
                crc_alto <= d; n <= n + 8'd1;
            end else begin
                n <= 8'd0;
                if ({crc_alto, d} == crc) begin listo <= 1'b1; carga <= b; end
                else                      mala <= 1'b1;
            end
        end else if (n != 8'd0) begin
            if (hueco < T_HUECO) hueco <= hueco + 1;
            else begin n <= 8'd0; hueco <= 0; mala <= 1'b1; end
        end
    end
end

endmodule

// posiciones
module tri_posicion (
    input  wire [3:0] k,
    output reg  [9:0] x,
    output reg  [9:0] y
);
always @(*) begin
    case (k)
        4'd0:  begin x = 10'd404; y = 10'd304; end
        4'd1:  begin x = 10'd412; y = 10'd304; end
        4'd2:  begin x = 10'd412; y = 10'd312; end
        4'd3:  begin x = 10'd404; y = 10'd312; end
        4'd4:  begin x = 10'd408; y = 10'd303; end
        4'd5:  begin x = 10'd640; y = 10'd480; end
        4'd6:  begin x = 10'd800; y = 10'd640; end
        4'd7:  begin x = 10'd72;  y = 10'd48;  end
        4'd8:  begin x = 10'd32;  y = 10'd32;  end
        4'd9:  begin x = 10'd160; y = 10'd160; end
        4'd10: begin x = 10'd320; y = 10'd160; end
        4'd11: begin x = 10'd160; y = 10'd320; end
        4'd12: begin x = 10'd320; y = 10'd320; end
        4'd13: begin x = 10'd368; y = 10'd352; end
        4'd14: begin x = 10'd384; y = 10'd352; end
        default: begin x = 10'd960; y = 10'd960; end
    endcase
end
endmodule

// raiz entera
module tri_distancia (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [9:0] x1, y1, x2, y2,
    output reg  [9:0] d,
    output reg        listo
);

wire signed [10:0] dx  = $signed({1'b0, x1}) - $signed({1'b0, x2});
wire signed [10:0] dy  = $signed({1'b0, y1}) - $signed({1'b0, y2});
wire signed [21:0] dx2 = dx * dx;
wire signed [21:0] dy2 = dy * dy;
wire        [21:0] n2  = dx2 + dy2;

reg  [21:0] m;
reg  [12:0] r;
reg  [10:0] q;
reg  [3:0]  k;
reg         corriendo;
wire [12:0] r_sh   = {r[10:0], m[21:20]};
wire [12:0] prueba = {q, 2'b01};
wire        cabe   = (r_sh >= prueba);
wire [10:0] q_sig  = {q[9:0], cabe};

always @(posedge clk or posedge reset) begin
    if (reset) begin
        m <= 22'd0; r <= 13'd0; q <= 11'd0; k <= 4'd0; corriendo <= 1'b0; d <= 10'd0; listo <= 1'b0;
    end else begin
        listo <= 1'b0;
        if (start) begin
            m <= n2; r <= 13'd0; q <= 11'd0; k <= 4'd0; corriendo <= 1'b1;
        end else if (corriendo) begin
            r <= cabe ? (r_sh - prueba) : r_sh;
            q <= q_sig;
            m <= {m[19:0], 2'b00};
            if (k == 4'd10) begin
                corriendo <= 1'b0;
                listo     <= 1'b1;
                d         <= q_sig[10] ? 10'd1023 : q_sig[9:0];
            end
            k <= k + 4'd1;
        end
    end
end

endmodule

// escena termica
module tri_escena #(
    parameter [9:0]  PX     = 10'd408,
    parameter [9:0]  PY     = 10'd308,
    parameter [15:0] OFFSET = 16'd2185
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        calcula,
    input  wire        avanza,
    input  wire [9:0]  xm,
    input  wire [9:0]  ym,
    input  wire [5:0]  temp,
    input  wire        estimulo,
    input  wire [1:0]  canal,
    input  wire [5:0]  idx,
    output wire [7:0]  px_temp,
    output wire [7:0]  actividad,
    output reg  [15:0] rumbo_insecto,
    output reg  [15:0] rumbo_real,
    output reg  [11:0] dist_mm,
    output reg         listo
);

localparam [15:0] GIRO   = 16'd2731;
localparam [7:0]  T_AMB  = 8'd88;

wire signed [23:0] dx = $signed({14'd0, PX}) - $signed({14'd0, xm});
wire signed [23:0] dy = $signed({14'd0, PY}) - $signed({14'd0, ym});

reg               c_start;
wire signed [23:0] cx, cy;
wire        [15:0] cz;
wire               c_listo;
cordic #(.W(24), .N(16)) u_cordic (.clk(clk), .reset(reset), .start(c_start), .modo(1'b1),
    .x0(dx <<< 6), .y0(dy <<< 6), .z0(16'd0), .x(cx), .y(cy), .z(cz), .listo(c_listo));

reg [9:0]  x_prev, y_prev;
reg        reapunta;
reg [15:0] azar;
wire       azar_bit = azar[15] ^ azar[13] ^ azar[12] ^ azar[10];

wire [39:0] mm_x = cx * 40'sd38864;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        c_start <= 1'b0; x_prev <= 10'd0; y_prev <= 10'd0; reapunta <= 1'b1;
        azar <= 16'h1D2B; rumbo_insecto <= 16'd0; rumbo_real <= 16'd0; dist_mm <= 12'd4095; listo <= 1'b0;
    end else begin
        c_start <= 1'b0;
        listo   <= 1'b0;
        if (avanza) azar <= {azar[14:0], azar_bit};
        if (calcula) begin
            c_start <= 1'b1;
            if ((xm != x_prev) || (ym != y_prev)) reapunta <= 1'b1;
            x_prev <= xm; y_prev <= ym;
        end
        if (c_listo) begin
            rumbo_real <= cz;
            dist_mm    <= (mm_x[39:16] > 24'd4095) ? 12'd4095 : mm_x[27:16];
            if (reapunta) begin
                rumbo_insecto <= cz + OFFSET;
                reapunta <= 1'b0;
            end
            listo <= 1'b1;
        end
        if (estimulo && canal == 2'b01) rumbo_insecto <= rumbo_insecto + GIRO;
        if (estimulo && canal == 2'b10) rumbo_insecto <= rumbo_insecto - GIRO;
    end
end

wire signed [15:0] phi      = rumbo_real - rumbo_insecto;
wire signed [31:0] phi_q3   = phi * 32'sd3;
wire signed [31:0] q_32     = -(phi_q3 >>> 10);
wire signed [15:0] q        = q_32[15:0];
wire               en_campo = (phi > -16'sd10923) && (phi < 16'sd10923);
wire [11:0]        d_vis    = (dist_mm > 12'd380) ? 12'd380 : dist_mm;

// radio de la mancha
reg [9:0] radio2;
always @(*) begin
    case (d_vis[11:6])
        6'd0: radio2 = 10'd1023;  6'd1: radio2 = 10'd957;  6'd2: radio2 = 10'd344;
        6'd3: radio2 = 10'd176;   6'd4: radio2 = 10'd106;  default: radio2 = 10'd71;
    endcase
end

wire signed [15:0] qc     = (q > 16'sd60) ? 16'sd60 : (q < -16'sd60) ? -16'sd60 : q;

reg signed [15:0] centro;
reg               en_campo_r;
always @(posedge clk or posedge reset) begin
    if (reset) begin centro <= 16'sd16; en_campo_r <= 1'b0; end
    else       begin centro <= 16'sd16 + qc; en_campo_r <= en_campo; end
end

wire signed [15:0] px_x   = {11'd0, idx[2:0], 2'b10};
wire signed [15:0] px_y   = {11'd0, idx[5:3], 2'b10};
wire signed [15:0] ddx    = px_x - centro;
wire signed [15:0] ddy    = px_y - 16'sd16;
wire        [31:0] d2     = ddx * ddx + ddy * ddy;
wire               dentro = en_campo_r && (d2 <= {22'd0, radio2});
wire        [7:0]  t_m    = {temp, 2'b00};

assign px_temp   = (dentro ? t_m : T_AMB) + {7'd0, azar[idx[3:0]]};
assign actividad = {6'd0, azar[1:0]};

endmodule

// mochila
module tri_mochila #(
    parameter integer ROL           = 1,
    parameter integer CLK_FREQ      = 50000000,
    parameter integer BAUD_RATE     = 115200,
    parameter integer F_EST         = 50,
    parameter integer N_PULSOS      = 25,
    parameter [9:0]   PX            = 10'd408,
    parameter [9:0]   PY            = 10'd308,
    parameter [15:0]  OFFSET        = 16'd2185,
    parameter [15:0]  DERIVA        = 16'd0,
    parameter integer T_PERSONA_MIN = 35,
    parameter integer T_PERSONA_MAX = 38,
    parameter integer ALCANCE_M     = 32,
    parameter integer T_PULSA_MS    = 100,
    parameter integer REARMA        = 1
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        boton,
    input  wire [9:0]  sw,
    input  wire        pos_ext,
    input  wire [9:0]  x_ext,
    input  wire [9:0]  y_ext,
    input  wire        rx1,
    input  wire        rx2,
    output wire        tx,
    output reg  [9:0]  ledr,
    output reg  [6:0]  hex0, hex1, hex2, hex3, hex4, hex5,
    output wire [9:0]  x_yo,
    output wire [9:0]  y_yo,
    output wire [5:0]  temp,
    output reg  [9:0]  d_rec,
    output wire        oye_rec,
    output wire        oye_otra,
    output wire [15:0] pot_rec,
    output wire [15:0] pot_otra,
    output wire        tono,
    output wire [1:0]  cuenta_pd,
    output reg  [15:0] rumbo_med,
    output reg         rumbo_ok,
    output wire        alerta,
    output reg         persona,
    output wire [2:0]  estado,
    output wire [6:0]  n_fil,
    output reg  [7:0]  rango,
    output wire [15:0] rumbo_real,
    output reg  [9:0]  d_otra,
    output wire        otra_viva,
    output wire        otra_detecta
);

localparam integer C_CUADRO = CLK_FREQ / 10;
localparam integer C_PULSA  = (CLK_FREQ / 1000) * T_PULSA_MS;
localparam [3:0]   T_FRESCO = 4'd5;
localparam [3:0]   T_VIVO   = 4'd10;
localparam integer C_PIEL_MIN = 4 * T_PERSONA_MIN;
localparam integer C_PIEL_MAX = 4 * T_PERSONA_MAX + 3;
localparam [7:0]   T_PIEL_MIN = C_PIEL_MIN[7:0];
localparam [7:0]   T_PIEL_MAX = C_PIEL_MAX[7:0];
localparam integer ALC2     = (16 * ALCANCE_M) * (16 * ALCANCE_M);
wire [1:0] yo   = ROL[1:0];
wire [1:0] otra = (ROL == 1) ? 2'd2 : 2'd1;

// sincronizador
reg [9:0] sw_m, sw_s;
always @(posedge clk or posedge reset) begin
    if (reset) begin sw_m <= 10'd0; sw_s <= 10'd0; end
    else begin sw_m <= sw; sw_s <= sw_m; end
end
assign temp = sw_s[5:0];
wire [9:0] x_tab, y_tab;
tri_posicion u_pos (.k(sw_s[9:6]), .x(x_tab), .y(y_tab));
assign x_yo = pos_ext ? x_ext : x_tab;
assign y_yo = pos_ext ? y_ext : y_tab;

// reloj de cuadros
reg [31:0] c_cuadro;
reg [6:0]  paso;
reg        calcula, avanza, px_valido, px_ultimo;
reg [7:0]  px_temp;
reg [2:0]  px_col;
wire       esc_listo;
wire [7:0] px_escena, actividad;
wire [5:0] idx = paso[5:0] - 6'd1;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        c_cuadro <= 0; paso <= 7'd0; calcula <= 1'b0; avanza <= 1'b0;
        px_valido <= 1'b0; px_ultimo <= 1'b0; px_temp <= 8'd0; px_col <= 3'd0;
    end else begin
        calcula <= 1'b0; avanza <= 1'b0; px_valido <= 1'b0; px_ultimo <= 1'b0;
        c_cuadro <= (c_cuadro >= C_CUADRO - 1) ? 0 : c_cuadro + 1;
        if (paso == 7'd0) begin
            if (c_cuadro >= C_CUADRO - 1) begin calcula <= 1'b1; paso <= 7'd100; end
        end else if (paso == 7'd100) begin
            if (esc_listo) paso <= 7'd1;
        end else if (paso <= 7'd64) begin
            px_valido <= 1'b1;
            px_temp   <= px_escena;
            px_col    <= idx[2:0];
            px_ultimo <= (paso == 7'd64);
            paso      <= paso + 7'd1;
        end else if (paso == 7'd80) begin
            avanza <= 1'b1;
            paso   <= 7'd0;
        end else
            paso <= paso + 7'd1;
    end
end

wire        tick, disparo, baliza, quieto, pre;
wire [1:0]  canal;
wire [7:0]  fondo;
wire [15:0] cuenta, n_est;
wire [2:0]  fase_a, fase_b, led_on;
wire [15:0] rumbo_insecto;
wire [11:0] dist_mm;

tri_escena #(.PX(PX), .PY(PY), .OFFSET(OFFSET)) u_escena (
    .clk(clk), .reset(reset), .calcula(calcula), .avanza(avanza), .xm(x_yo), .ym(y_yo),
    .temp(temp), .estimulo(disparo), .canal(canal), .idx(idx),
    .px_temp(px_escena), .actividad(actividad), .rumbo_insecto(rumbo_insecto),
    .rumbo_real(rumbo_real), .dist_mm(dist_mm), .listo(esc_listo)
);

// rearme
reg [2:0] sin_mancha;
reg       rearma;
always @(posedge clk or posedge reset) begin
    if (reset) begin sin_mancha <= 3'd0; rearma <= 1'b0; end
    else begin
        rearma <= 1'b0;
        if (tick) begin
            if (!alerta || pre)          sin_mancha <= 3'd0;
            else if (sin_mancha == 3'd4) begin sin_mancha <= 3'd0; rearma <= (REARMA != 0); end
            else                         sin_mancha <= sin_mancha + 3'd1;
        end
    end
end
wire reset_nucleo = reset | rearma;

// nucleo
nucleo_biobot #(.CLK_FREQ(CLK_FREQ), .F_EST(F_EST), .N_PULSOS(N_PULSOS),
                .T_MIN(T_PIEL_MIN), .T_MAX(T_PIEL_MAX), .DELTA(8'd8)) u_nucleo (
    .clk(clk), .reset(reset_nucleo), .habilita(1'b1),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est)
);

wire        caliente = (px_temp >= T_PIEL_MIN) && (px_temp <= T_PIEL_MAX) && ({1'b0, px_temp} >= {1'b0, fondo} + 9'd8);
reg  [6:0]  n_c;
reg  [9:0]  s_c;
reg         d_start;
reg  [19:0] d_num;
reg  [6:0]  d_den;
wire [19:0] d_coc;
wire        d_listo;
divisor_u #(.WN(20), .WD(7)) u_div (.clk(clk), .reset(reset), .start(d_start), .num(d_num), .den(d_den),
    .coc(d_coc), .listo(d_listo));
wire signed [15:0] desv = $signed({1'b0, d_coc[14:0]}) - 16'sd4779;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        n_c <= 0; s_c <= 0; d_start <= 1'b0; d_num <= 0; d_den <= 7'd1; rumbo_med <= 16'd0; rumbo_ok <= 1'b0;
    end else begin
        d_start <= 1'b0;
        if (px_valido) begin
            if (px_ultimo) begin
                n_c <= 0; s_c <= 0;
                if ((n_c + caliente) >= 7'd2) begin
                    d_num   <= (s_c + (caliente ? {7'd0, px_col} : 10'd0)) * 20'd1365;
                    d_den   <= n_c + caliente;
                    d_start <= 1'b1;
                end else
                    rumbo_ok <= 1'b0;
            end else if (caliente) begin
                n_c <= n_c + 7'd1;
                s_c <= s_c + {7'd0, px_col};
            end
        end
        if (d_listo) begin
            rumbo_med <= rumbo_insecto + DERIVA - desv;
            rumbo_ok  <= 1'b1;
        end
    end
end

always @(*) begin
    if      (n_fil >= 7'd40) rango = 8'd2;
    else if (n_fil >= 7'd24) rango = 8'd4;
    else if (n_fil >= 7'd12) rango = 8'd6;
    else if (n_fil >= 7'd4)  rango = 8'd12;
    else if (n_fil >= 7'd2)  rango = 8'd17;
    else                     rango = 8'd0;
end

reg [31:0] c_pulsa;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_pulsa <= 0; persona <= 1'b0; end
    else if (!boton) c_pulsa <= 0;
    else if (c_pulsa < C_PULSA) c_pulsa <= c_pulsa + 1;
    else persona <= 1'b1;
end

wire         l1, l2;
wire [103:0] r1x, r2x;
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx1 (.clk(clk), .reset(reset), .rx(rx1), .listo(l1), .carga(r1x), .mala());
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx2 (.clk(clk), .reset(reset), .rx(rx2), .listo(l2), .carga(r2x), .mala());
wire [95:0] r1 = r1x[103:8], r2 = r2x[103:8];
wire [7:0]  q1 = r1x[7:0],   q2 = r2x[7:0];

// campos de la trama
function [1:0] c_org;  input [95:0] c; c_org = c[95:94]; endfunction
function [1:0] c_emi;  input [95:0] c; c_emi = c[93:92]; endfunction
function [1:0] c_sal;  input [95:0] c; c_sal = c[91:90]; endfunction
function [9:0] c_xo;   input [95:0] c; c_xo  = {c[63:62], c[79:72]}; endfunction
function [9:0] c_yo;   input [95:0] c; c_yo  = {c[61:60], c[71:64]}; endfunction
function [9:0] c_xe;   input [95:0] c; c_xe  = {c[15:14], c[31:24]}; endfunction
function [9:0] c_ye;   input [95:0] c; c_ye  = {c[13:12], c[23:16]}; endfunction
// alcance
function en_alcance;
    input [95:0] c;
    input [9:0]  xa, ya;
    reg signed [11:0] ddx, ddy;
    begin
        ddx = $signed({2'b00, c_xe(c)}) - $signed({2'b00, xa});
        ddy = $signed({2'b00, c_ye(c)}) - $signed({2'b00, ya});
        en_alcance = (ddx * ddx + ddy * ddy) < ALC2;
    end
endfunction

wire ok1 = l1 && (c_org(r1) == otra) && (c_emi(r1) != yo) && en_alcance(r1, x_yo, y_yo);
wire ok2 = l2 && (c_org(r2) == otra) && (c_emi(r2) != yo) && en_alcance(r2, x_yo, y_yo);

reg  [31:0] c_tick;
reg         tick100;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_tick <= 0; tick100 <= 1'b0; end
    else if (c_tick >= C_CUADRO - 1) begin c_tick <= 0; tick100 <= 1'b1; end
    else begin c_tick <= c_tick + 1; tick100 <= 1'b0; end
end

reg  [95:0] f_carga;
reg  [7:0]  f_seq;
reg  [3:0]  t_fwd, t_otra;
reg  [9:0]  xo_otra, yo_otra;
reg         det_otra;
always @(posedge clk or posedge reset) begin
    if (reset) begin f_carga <= 0; f_seq <= 8'd0; t_fwd <= 0; t_otra <= 0; xo_otra <= 0; yo_otra <= 0; det_otra <= 1'b0; end
    else begin
        if (tick100) begin
            if (t_fwd  != 0) t_fwd  <= t_fwd - 4'd1;
            if (t_otra != 0) t_otra <= t_otra - 4'd1;
        end
        if (ok1 || ok2) begin
            f_carga  <= ok1 ? r1 : r2;
            f_seq    <= ok1 ? q1 : q2;
            t_fwd    <= (c_sal(ok1 ? r1 : r2) < 2'd2) ? T_FRESCO : t_fwd;
            t_otra   <= T_VIVO;
            xo_otra  <= c_xo(ok1 ? r1 : r2);
            yo_otra  <= c_yo(ok1 ? r1 : r2);
            det_otra <= (ok1 ? (r1[87] | r1[86]) : (r2[87] | r2[86]));
        end
    end
end
assign otra_viva    = (t_otra != 0);
assign otra_detecta = otra_viva && det_otra;
wire   puente       = (t_fwd != 0);

wire [9:0] dq_otra;
wire       dl_otra;
// distancia a la otra
tri_distancia u_d_otra (.clk(clk), .reset(reset), .start(tick100),
    .x1(xo_otra), .y1(yo_otra), .x2(x_yo), .y2(y_yo), .d(dq_otra), .listo(dl_otra));
always @(posedge clk or posedge reset) begin
    if (reset) d_otra <= 10'd0;
    else if (dl_otra) d_otra <= otra_viva ? dq_otra : 10'd0;
end

wire [9:0] dq_rec;
wire       dl_rec;
// distancia al receptor
tri_distancia u_d_rec (.clk(clk), .reset(reset), .start(tick100),
    .x1(x_yo), .y1(y_yo), .x2(10'd0), .y2(10'd0), .d(dq_rec), .listo(dl_rec));
always @(posedge clk or posedge reset) begin
    if (reset) d_rec <= 10'd0;
    else if (dl_rec) d_rec <= dq_rec;
end

wire cruda1 = l1 && (c_org(r1) == otra) && (c_emi(r1) == otra);
wire cruda2 = l2 && (c_org(r2) == otra) && (c_emi(r2) == otra);
reg  [9:0] xr_otra, yr_otra;
reg  [3:0] t_cable;
always @(posedge clk or posedge reset) begin
    if (reset) begin xr_otra <= 10'd0; yr_otra <= 10'd0; t_cable <= 4'd0; end
    else if (cruda1 || cruda2) begin
        xr_otra <= c_xo(cruda1 ? r1 : r2);
        yr_otra <= c_yo(cruda1 ? r1 : r2);
        t_cable <= T_VIVO;
    end else if (tick100 && t_cable != 0)
        t_cable <= t_cable - 4'd1;
end
function cerca;
    input [9:0] x1, y1, x2, y2;
    reg signed [11:0] ex, ey;
    begin
        ex = $signed({2'b00, x1}) - $signed({2'b00, x2});
        ey = $signed({2'b00, y1}) - $signed({2'b00, y2});
        cerca = (ex * ex + ey * ey) < ALC2;
    end
endfunction
wire        llega_otra = (t_cable != 0) && cerca(xr_otra, yr_otra, x_yo, y_yo);
wire        llega_rec  = cerca(10'd0, 10'd0, x_yo, y_yo);
wire [2:0]  presente   = (ROL == 1) ? {llega_otra, 1'b0, llega_rec} : {1'b0, llega_otra, llega_rec};
wire [2:0]  oye_t;
wire [15:0] p0, p1, p2;
// tonos
tri_tonos #(.CLK_FREQ(CLK_FREQ), .YO(ROL)) u_tonos (.clk(clk), .reset(reset), .presente(presente),
    .tono(tono), .oye(oye_t), .pot0(p0), .pot1(p1), .pot2(p2));
assign oye_rec  = oye_t[0];
assign oye_otra = (ROL == 1) ? oye_t[2] : oye_t[1];
assign pot_rec  = p0;
assign pot_otra = (ROL == 1) ? p2 : p1;

wire [9:0] th = rumbo_med[15:6];
wire [95:0] propia = {yo, yo, 2'b00, 2'b00,
                      alerta, persona, pre, rumbo_ok, 1'b0, estado,
                      x_yo[7:0], y_yo[7:0], x_yo[9:8], y_yo[9:8], th[9:8], 2'b00,
                      th[7:0], rango, 1'b0, n_fil,
                      x_yo[7:0], y_yo[7:0], x_yo[9:8], y_yo[9:8], 4'b0000,
                      oye_otra, oye_rec, temp};
wire [95:0] reenvio = {f_carga[95:94], yo, f_carga[91:90] + 2'd1, 2'b00,
                       f_carga[87:32],
                       x_yo[7:0], y_yo[7:0], x_yo[9:8], y_yo[9:8], 4'b0000,
                       f_carga[7:0]};

reg          t_start, segunda;
reg  [103:0] t_carga;
reg  [7:0]   seq_yo;
wire         t_ocupado;
tri_tx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13), .CAB(8'hA5)) u_tx (.clk(clk), .reset(reset),
    .start(t_start), .carga(t_carga), .tx(tx), .ocupado(t_ocupado));

always @(posedge clk or posedge reset) begin
    if (reset) begin t_start <= 1'b0; segunda <= 1'b0; t_carga <= 0; seq_yo <= 8'd0; end
    else begin
        t_start <= 1'b0;
        if (tick100 && !t_ocupado) begin
            t_carga <= {propia, seq_yo}; t_start <= 1'b1; segunda <= puente; seq_yo <= seq_yo + 8'd1;
        end else if (segunda && !t_ocupado && !t_start) begin
            t_carga <= {reenvio, f_seq}; t_start <= 1'b1; segunda <= 1'b0;
        end
    end
end

// siete segmentos
function [6:0] seg;
    input [4:0] c;
    case (c)
        5'd0: seg = 7'b1000000;  5'd1: seg = 7'b1111001;  5'd2: seg = 7'b0100100;  5'd3: seg = 7'b0110000;
        5'd4: seg = 7'b0011001;  5'd5: seg = 7'b0010010;  5'd6: seg = 7'b0000010;  5'd7: seg = 7'b1111000;
        5'd8: seg = 7'b0000000;  5'd9: seg = 7'b0010000;
        5'd10: seg = 7'b0001000;
        5'd11: seg = 7'b0000011;
        5'd13: seg = 7'b0100001;
        5'd16: seg = 7'b0111111;
        5'd18: seg = 7'b0001100;
        5'd19: seg = 7'b0101111;
        default: seg = 7'b1111111;
    endcase
endfunction

// metros a LED
function [4:0] metros5;
    input [9:0] c;
    begin
        if      (c[9:4] > 6'd31) metros5 = 5'd31;
        else if (c[9:4] == 6'd0) metros5 = 5'd1;
        else                     metros5 = c[8:4];
    end
endfunction

wire det_yo = alerta | persona;
assign cuenta_pd = det_yo + otra_detecta;

always @(*) begin
    hex5 = seg((ROL == 1) ? 5'd10 : 5'd11);
    hex4 = seg(5'd18);
    hex3 = seg(5'd13);
    hex2 = seg({3'b000, cuenta_pd});
    hex1 = oye_otra ? seg((ROL == 1) ? 5'd11 : 5'd10) : seg(5'd16);
    hex0 = oye_rec ? seg(5'd19) : seg(5'd16);
    ledr = {(oye_otra && otra_viva) ? metros5(d_otra) : 5'd0, oye_rec ? metros5(d_rec) : 5'd0};
end

endmodule

// triangulacion
module tri_triangula #(
    parameter integer T_MAX = 48
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [9:0]  ax, ay, bx, by,
    input  wire [9:0]  tha, thb,
    input  wire [7:0]  ra, rb,
    output reg  [9:0]  px, py,
    output reg  [9:0]  pax, pay, pbx, pby,
    output reg  [1:0]  error,
    output reg         listo
);

reg               c_start;
reg        [15:0] c_z;
wire signed [23:0] cx, cy;
wire        [15:0] cz;
wire               c_listo;
cordic #(.W(24), .N(16)) u_cordic (.clk(clk), .reset(reset), .start(c_start), .modo(1'b0),
    .x0(24'sd9949), .y0(24'sd0), .z0(c_z), .x(cx), .y(cy), .z(cz), .listo(c_listo));

reg               d_start;
reg        [43:0] d_num;
reg        [31:0] d_den;
wire       [43:0] d_coc;
wire              d_listo;
divisor_u #(.WN(44), .WD(32)) u_div (.clk(clk), .reset(reset), .start(d_start), .num(d_num), .den(d_den),
    .coc(d_coc), .listo(d_listo));

localparam signed [31:0] DEN_MIN = 32'sd46603904;

reg [3:0] st;
reg signed [17:0] ca, sa, cb, sb;
reg signed [31:0] den, num, num2;
reg signed [11:0] ddx, ddy;
reg signed [43:0] t;

// saturacion
function [9:0] satura;
    input signed [31:0] v;
    satura = (v < 0) ? 10'd0 : (v > 32'sd1023) ? 10'd1023 : v[9:0];
endfunction

wire signed [31:0] apa_x = $signed({22'd0, ax}) + (($signed({24'd0, ra}) * ca + 32'sd8192) >>> 14);
wire signed [31:0] apa_y = $signed({22'd0, ay}) + (($signed({24'd0, ra}) * sa + 32'sd8192) >>> 14);
wire signed [31:0] apb_x = $signed({22'd0, bx}) + (($signed({24'd0, rb}) * cb + 32'sd8192) >>> 14);
wire signed [31:0] apb_y = $signed({22'd0, by}) + (($signed({24'd0, rb}) * sb + 32'sd8192) >>> 14);
wire signed [47:0] tca   = t * ca;
wire signed [47:0] tsa   = t * sa;
wire signed [47:0] tca_r = (tca + 48'sd8192) >>> 14;
wire signed [47:0] tsa_r = (tsa + 48'sd8192) >>> 14;
wire signed [31:0] cru_x = $signed({22'd0, ax}) + $signed(tca_r[31:0]);
wire signed [31:0] cru_y = $signed({22'd0, ay}) + $signed(tsa_r[31:0]);
wire [31:0] den_abs = den[31] ? -den : den;
wire [31:0] num_abs = num[31] ? -num : num;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        st <= 4'd0; c_start <= 1'b0; c_z <= 16'd0; d_start <= 1'b0; d_num <= 0; d_den <= 32'd1;
        ca <= 0; sa <= 0; cb <= 0; sb <= 0; den <= 0; num <= 0; num2 <= 0; ddx <= 0; ddy <= 0; t <= 0;
        px <= 0; py <= 0; pax <= 0; pay <= 0; pbx <= 0; pby <= 0; error <= 2'd0; listo <= 1'b0;
    end else begin
        c_start <= 1'b0; d_start <= 1'b0; listo <= 1'b0;
        case (st)
            4'd0: if (start) begin c_z <= {tha, 6'd0}; c_start <= 1'b1; st <= 4'd1; end
            4'd1: if (c_listo) begin ca <= cx[17:0]; sa <= cy[17:0]; c_z <= {thb, 6'd0}; c_start <= 1'b1; st <= 4'd2; end
            4'd2: if (c_listo) begin cb <= cx[17:0]; sb <= cy[17:0]; st <= 4'd3; end
            4'd3: begin
                      ddx <= $signed({2'b00, bx}) - $signed({2'b00, ax});
                      ddy <= $signed({2'b00, by}) - $signed({2'b00, ay});
                      den <= ca * sb - sa * cb;
                      st  <= 4'd4;
                  end
            4'd4: begin
                      num  <= ddx * sb - ddy * cb;
                      num2 <= ddx * sa - ddy * ca;
                      pax <= satura(apa_x); pay <= satura(apa_y);
                      pbx <= satura(apb_x); pby <= satura(apb_y);
                      st   <= 4'd5;
                  end
            4'd5: begin
                      if ((den < DEN_MIN) && (den > -DEN_MIN)) begin
                          error <= 2'd1; listo <= 1'b1; st <= 4'd0;
                      end else if ((num != 0 && (num[31] ^ den[31])) || (num2 != 0 && (num2[31] ^ den[31]))) begin
                          error <= 2'd2; listo <= 1'b1; st <= 4'd0;
                      end else begin
                          d_num <= {num_abs[29:0], 14'd0}; d_den <= den_abs; d_start <= 1'b1; st <= 4'd6;
                      end
                  end
            4'd6: if (d_listo) begin t <= $signed(d_coc); st <= 4'd7; end
            4'd7: begin
                      if (t > T_MAX) error <= 2'd3;
                      else begin error <= 2'd0; px <= satura(cru_x); py <= satura(cru_y); end
                      listo <= 1'b1;
                      st <= 4'd0;
                  end
            default: st <= 4'd0;
        endcase
    end
end

endmodule

// receptor
module tri_receptor #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer ALCANCE_M = 32
) (
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  vista,
    input  wire        rx1,
    input  wire        rx2,
    output wire        tx_pc,
    output reg  [9:0]  ledr,
    output reg  [6:0]  hex0, hex1, hex2, hex3, hex4, hex5,
    output reg  [9:0]  est_x,
    output reg  [9:0]  est_y,
    output reg  [2:0]  modo,
    output wire [2:0]  n_ev,
    output wire [1:0]  tri_error,
    output wire [9:0]  tha_o, thb_o,
    output reg  [9:0]  d_ab,
    output reg  [9:0]  d_a,
    output reg  [9:0]  d_b,
    output wire [1:0]  cuenta_pd,
    output wire [3:0]  enlaces,
    output wire [7:0]  perd_a,
    output wire [7:0]  perd_b,
    output reg  [7:0]  malas,
    output wire [41:0] info_a,
    output wire [41:0] info_b,
    output wire        oye_a,
    output wire        oye_b,
    output wire [15:0] pot_a,
    output wire [15:0] pot_b,
    output wire        tono
);

localparam integer C_TICK = CLK_FREQ / 10;
localparam [3:0]   T_VIVO = 4'd10;
localparam integer ALC2   = (16 * ALCANCE_M) * (16 * ALCANCE_M);

wire         l1, l2, m1, m2;
wire [103:0] r1x, r2x;
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx1 (.clk(clk), .reset(reset), .rx(rx1), .listo(l1), .carga(r1x), .mala(m1));
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx2 (.clk(clk), .reset(reset), .rx(rx2), .listo(l2), .carga(r2x), .mala(m2));
wire [95:0] r1 = r1x[103:8], r2 = r2x[103:8];
wire [7:0]  q1 = r1x[7:0],   q2 = r2x[7:0];

function cerca;
    input [9:0] x, y;
    cerca = ({10'd0, x} * {10'd0, x} + {10'd0, y} * {10'd0, y}) < ALC2;
endfunction
// alcance
function en_alcance;
    input [95:0] c;
    en_alcance = cerca({c[15:14], c[31:24]}, {c[13:12], c[23:16]});
endfunction
wire ok1 = l1 && (r1[95:94] == 2'd1 || r1[95:94] == 2'd2) && en_alcance(r1);
wire ok2 = l2 && (r2[95:94] == 2'd1 || r2[95:94] == 2'd2) && en_alcance(r2);

reg [95:0] dat_a, dat_b;
reg [3:0]  dir_a, rel_a, dir_b, rel_b;
reg [31:0] c_tick;
reg        tick;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_tick <= 0; tick <= 1'b0; end
    else if (c_tick >= C_TICK - 1) begin c_tick <= 0; tick <= 1'b1; end
    else begin c_tick <= c_tick + 1; tick <= 1'b0; end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        dat_a <= 0; dat_b <= 0; dir_a <= 0; rel_a <= 0; dir_b <= 0; rel_b <= 0;
    end else begin
        if (tick) begin
            if (dir_a != 0) dir_a <= dir_a - 4'd1;
            if (rel_a != 0) rel_a <= rel_a - 4'd1;
            if (dir_b != 0) dir_b <= dir_b - 4'd1;
            if (rel_b != 0) rel_b <= rel_b - 4'd1;
        end
        if (ok1) begin
            if (r1[95:94] == 2'd1) begin dat_a <= r1; if (r1[91:90] == 2'd0) dir_a <= T_VIVO; else rel_a <= T_VIVO; end
            else                   begin dat_b <= r1; if (r1[91:90] == 2'd0) dir_b <= T_VIVO; else rel_b <= T_VIVO; end
        end
        if (ok2) begin
            if (r2[95:94] == 2'd1) begin dat_a <= r2; if (r2[91:90] == 2'd0) dir_a <= T_VIVO; else rel_a <= T_VIVO; end
            else                   begin dat_b <= r2; if (r2[91:90] == 2'd0) dir_b <= T_VIVO; else rel_b <= T_VIVO; end
        end
    end
end

wire       vivo_a = (dir_a != 0) || (rel_a != 0);
wire       vivo_b = (dir_b != 0) || (rel_b != 0);
wire       term_a = vivo_a && dat_a[87];
wire       term_b = vivo_b && dat_b[87];
wire       bot_a  = vivo_a && dat_a[86];
wire       bot_b  = vivo_b && dat_b[86];
wire       rv_a   = vivo_a && dat_a[84];
wire       rv_b   = vivo_b && dat_b[84];
wire [2:0] est_a  = dat_a[82:80];
wire [2:0] est_b  = dat_b[82:80];
wire [9:0] ax     = {dat_a[63:62], dat_a[79:72]};
wire [9:0] ay     = {dat_a[61:60], dat_a[71:64]};
wire [9:0] tha    = {dat_a[59:58], dat_a[55:48]};
wire [7:0] ra     = dat_a[47:40];
wire [5:0] temp_a = dat_a[5:0];
wire [9:0] bx     = {dat_b[63:62], dat_b[79:72]};
wire [9:0] by     = {dat_b[61:60], dat_b[71:64]};
wire [9:0] thb    = {dat_b[59:58], dat_b[55:48]};
wire [7:0] rb     = dat_b[47:40];
wire [5:0] temp_b = dat_b[5:0];

assign tha_o = tha;
assign thb_o = thb;
assign n_ev  = term_a + term_b + bot_a + bot_b;

// seguimiento
function [16:0] sigue;
    input [16:0] e;
    input [7:0]  q;
    reg        visto;
    reg [7:0]  ult, perd, delta;
    reg [8:0]  s;
    begin
        {visto, ult, perd} = e;
        s     = 9'd0;
        delta = q - ult;
        if (!visto) begin
            ult = q; visto = 1'b1;
        end else if (delta == 8'd0) begin
            ult = q;
        end else if (delta < 8'd128) begin
            s    = {1'b0, perd} + {1'b0, delta} - 9'd1;
            perd = s[8] ? 8'hFF : s[7:0];
            ult  = q;
        end else
            ult = q;
        sigue = {visto, ult, perd};
    end
endfunction

reg [16:0] ea, eb;
reg [16:0] na, nb;
always @(posedge clk or posedge reset) begin
    if (reset) begin ea <= 17'd0; eb <= 17'd0; malas <= 8'd0; end
    else begin
        na = ea; nb = eb;
        if (!vivo_a) na[16] = 1'b0;
        if (!vivo_b) nb[16] = 1'b0;
        if (ok1) begin if (r1[95:94] == 2'd1) na = sigue(na, q1); else nb = sigue(nb, q1); end
        if (ok2) begin if (r2[95:94] == 2'd1) na = sigue(na, q2); else nb = sigue(nb, q2); end
        ea <= na; eb <= nb;
        if ((m1 || m2) && malas != 8'hFF) malas <= malas + 8'd1;
    end
end
assign perd_a = ea[7:0];
assign perd_b = eb[7:0];
assign info_a = {ax, ay, temp_a, dat_a[87], dat_a[86], dat_a[85], dat_a[84], est_a, dat_a[7], dat_a[6], dat_a[38:32]};
assign info_b = {bx, by, temp_b, dat_b[87], dat_b[86], dat_b[85], dat_b[84], est_b, dat_b[7], dat_b[6], dat_b[38:32]};

wire [9:0] px, py, pax, pay, pbx, pby;
wire       t_listo;
// triangulacion
tri_triangula u_tri (.clk(clk), .reset(reset), .start(tick),
    .ax(ax), .ay(ay), .bx(bx), .by(by), .tha(tha), .thb(thb), .ra(ra), .rb(rb),
    .px(px), .py(py), .pax(pax), .pay(pay), .pbx(pbx), .pby(pby), .error(tri_error), .listo(t_listo));

wire [10:0] sx  = {1'b0, pax} + {1'b0, pbx};
wire [10:0] sy  = {1'b0, pay} + {1'b0, pby};
wire [10:0] sxm = {1'b0, ax} + {1'b0, bx};
wire [10:0] sym = {1'b0, ay} + {1'b0, by};

always @(posedge clk or posedge reset) begin
    if (reset) begin est_x <= 0; est_y <= 0; modo <= 3'd0; end
    else if (t_listo) begin
        if (term_a && term_b && rv_a && rv_b) begin
            if (tri_error == 2'd0) begin est_x <= px; est_y <= py; modo <= 3'd2; end
            else                    begin est_x <= sx[10:1]; est_y <= sy[10:1]; modo <= 3'd3; end
        end else if (term_a && term_b) begin
            est_x <= rv_a ? pax : rv_b ? pbx : sxm[10:1];
            est_y <= rv_a ? pay : rv_b ? pby : sym[10:1];
            modo  <= 3'd3;
        end else if (term_a) begin
            est_x <= rv_a ? pax : ax; est_y <= rv_a ? pay : ay; modo <= 3'd1;
        end else if (term_b) begin
            est_x <= rv_b ? pbx : bx; est_y <= rv_b ? pby : by; modo <= 3'd1;
        end else if (bot_a && bot_b) begin
            est_x <= sxm[10:1]; est_y <= sym[10:1]; modo <= 3'd4;
        end else if (bot_a) begin
            est_x <= ax; est_y <= ay; modo <= 3'd4;
        end else if (bot_b) begin
            est_x <= bx; est_y <= by; modo <= 3'd4;
        end else
            modo <= 3'd0;
    end
end

wire [9:0] dq_ab, dq_a, dq_b;
wire       dl_ab, dl_a, dl_b;
// distancias
tri_distancia u_d_ab (.clk(clk), .reset(reset), .start(tick),
    .x1(ax), .y1(ay), .x2(bx), .y2(by), .d(dq_ab), .listo(dl_ab));
tri_distancia u_d_a (.clk(clk), .reset(reset), .start(tick),
    .x1(ax), .y1(ay), .x2(10'd0), .y2(10'd0), .d(dq_a), .listo(dl_a));
tri_distancia u_d_b (.clk(clk), .reset(reset), .start(tick),
    .x1(bx), .y1(by), .x2(10'd0), .y2(10'd0), .d(dq_b), .listo(dl_b));
always @(posedge clk or posedge reset) begin
    if (reset) begin d_ab <= 10'd0; d_a <= 10'd0; d_b <= 10'd0; end
    else begin
        if (dl_ab) d_ab <= (vivo_a && vivo_b) ? dq_ab : 10'd0;
        if (dl_a)  d_a  <= dq_a;
        if (dl_b)  d_b  <= dq_b;
    end
end
assign enlaces   = {(dir_a != 0), (rel_a != 0), (dir_b != 0), (rel_b != 0)};

wire cr1 = l1 && (r1[95:94] == r1[93:92]) && (r1[95:94] == 2'd1 || r1[95:94] == 2'd2);
wire cr2 = l2 && (r2[95:94] == r2[93:92]) && (r2[95:94] == 2'd1 || r2[95:94] == 2'd2);
reg  [9:0] xr_a, yr_a, xr_b, yr_b;
reg  [3:0] tc_a, tc_b;
always @(posedge clk or posedge reset) begin
    if (reset) begin xr_a <= 0; yr_a <= 0; xr_b <= 0; yr_b <= 0; tc_a <= 0; tc_b <= 0; end
    else begin
        if (tick) begin
            if (tc_a != 0) tc_a <= tc_a - 4'd1;
            if (tc_b != 0) tc_b <= tc_b - 4'd1;
        end
        if (cr1) begin
            if (r1[95:94] == 2'd1) begin xr_a <= {r1[63:62], r1[79:72]}; yr_a <= {r1[61:60], r1[71:64]}; tc_a <= T_VIVO; end
            else                   begin xr_b <= {r1[63:62], r1[79:72]}; yr_b <= {r1[61:60], r1[71:64]}; tc_b <= T_VIVO; end
        end
        if (cr2) begin
            if (r2[95:94] == 2'd1) begin xr_a <= {r2[63:62], r2[79:72]}; yr_a <= {r2[61:60], r2[71:64]}; tc_a <= T_VIVO; end
            else                   begin xr_b <= {r2[63:62], r2[79:72]}; yr_b <= {r2[61:60], r2[71:64]}; tc_b <= T_VIVO; end
        end
    end
end
wire llega_a = (tc_a != 0) && cerca(xr_a, yr_a);
wire llega_b = (tc_b != 0) && cerca(xr_b, yr_b);
wire [2:0]  oye_t;
wire [15:0] p0;
// tonos
tri_tonos #(.CLK_FREQ(CLK_FREQ), .YO(0)) u_tonos (.clk(clk), .reset(reset), .presente({llega_b, llega_a, 1'b0}),
    .tono(tono), .oye(oye_t), .pot0(p0), .pot1(pot_a), .pot2(pot_b));
assign oye_a = oye_t[1];
assign oye_b = oye_t[2];
assign cuenta_pd = (term_a | bot_a) + (term_b | bot_b);

wire [255:0] resumen = {
    modo, n_ev, tri_error,
    term_a, term_b, bot_a, bot_b, vivo_a, vivo_b, rv_a, rv_b,
    (dir_a != 0), (rel_a != 0), (dir_b != 0), (rel_b != 0), 1'b0, est_a,
    5'd0, est_b,
    6'd0, est_x[9:8], est_x[7:0],
    6'd0, est_y[9:8], est_y[7:0],
    6'd0, ax[9:8], ax[7:0],
    6'd0, ay[9:8], ay[7:0],
    6'd0, bx[9:8], bx[7:0],
    6'd0, by[9:8], by[7:0],
    6'd0, tha[9:8], tha[7:0],
    6'd0, thb[9:8], thb[7:0],
    2'd0, temp_a,
    2'd0, temp_b,
    6'd0, d_ab[9:8], d_ab[7:0],
    6'd0, d_a[9:8], d_a[7:0],
    6'd0, d_b[9:8], d_b[7:0],
    6'd0, cuenta_pd,
    perd_a, perd_b, malas};
reg  pc_start;
wire pc_ocupado;
always @(posedge clk or posedge reset) begin
    if (reset) pc_start <= 1'b0;
    else       pc_start <= t_listo && !pc_ocupado;
end
tri_tx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(32), .CAB(8'hA6)) u_tx_pc (.clk(clk), .reset(reset),
    .start(pc_start), .carga(resumen), .tx(tx_pc), .ocupado(pc_ocupado));

// siete segmentos
function [6:0] seg;
    input [4:0] c;
    case (c)
        5'd0: seg = 7'b1000000;  5'd1: seg = 7'b1111001;  5'd2: seg = 7'b0100100;  5'd3: seg = 7'b0110000;
        5'd4: seg = 7'b0011001;  5'd5: seg = 7'b0010010;  5'd6: seg = 7'b0000010;  5'd7: seg = 7'b1111000;
        5'd8: seg = 7'b0000000;  5'd9: seg = 7'b0010000;
        5'd10: seg = 7'b0001000;
        5'd11: seg = 7'b0000011;
        5'd13: seg = 7'b0100001;
        5'd14: seg = 7'b0000110;
        5'd16: seg = 7'b0111111;
        5'd17: seg = 7'b0000111;
        5'd18: seg = 7'b0001100;
        5'd19: seg = 7'b0101111;
        default: seg = 7'b1111111;
    endcase
endfunction
// metros a LED
function [4:0] metros5;
    input [9:0] c;
    begin
        if      (c[9:4] > 6'd31) metros5 = 5'd31;
        else if (c[9:4] == 6'd0) metros5 = 5'd1;
        else                     metros5 = c[8:4];
    end
endfunction
// binario a BCD
function [11:0] bcd3;
    input [9:0] b;
    integer i;
    reg [21:0] s;
    begin
        s = {12'd0, b};
        for (i = 0; i < 10; i = i + 1) begin
            if (s[13:10] >= 5) s[13:10] = s[13:10] + 4'd3;
            if (s[17:14] >= 5) s[17:14] = s[17:14] + 4'd3;
            if (s[21:18] >= 5) s[21:18] = s[21:18] + 4'd3;
            s = s << 1;
        end
        bcd3 = s[21:10];
    end
endfunction
function [11:0] dm3;
    input [9:0] p;
    reg [17:0] d;
    begin
        d = ({8'd0, p} * 18'd5 + 18'd4) >> 3;
        dm3 = bcd3(d[9:0]);
    end
endfunction
function [8:0] grados;
    input [9:0] th;
    reg [18:0] g;
    begin
        g = th * 19'd360;
        grados = g[18:10];
    end
endfunction

wire        hay   = term_a | term_b | bot_a | bot_b;
wire [11:0] ex_d  = dm3(est_x), ey_d = dm3(est_y), dab_d = dm3(d_ab);
wire [11:0] ga    = bcd3({1'b0, grados(tha)});
wire [11:0] gb    = bcd3({1'b0, grados(thb)});
wire [4:0]  ruta_a = (dir_a != 0) ? 5'd0 : (rel_a != 0) ? 5'd1 : 5'd16;
wire [4:0]  ruta_b = (dir_b != 0) ? 5'd0 : (rel_b != 0) ? 5'd1 : 5'd16;

always @(*) begin
    case (vista)
        2'b00: begin
            hex5 = seg(5'd19);
            hex4 = seg(5'd18);
            hex3 = seg(5'd13);
            hex2 = seg({3'b000, cuenta_pd});
            hex1 = oye_a ? seg(5'd10) : seg(5'd16);
            hex0 = oye_b ? seg(5'd11) : seg(5'd16);
        end
        2'b01: begin
            hex5 = hay ? seg({1'b0, ex_d[11:8]}) : seg(5'd16);
            hex4 = hay ? seg({1'b0, ex_d[7:4]})  : seg(5'd16);
            hex3 = hay ? seg({1'b0, ex_d[3:0]})  : seg(5'd16);
            hex2 = hay ? seg({1'b0, ey_d[11:8]}) : seg(5'd16);
            hex1 = hay ? seg({1'b0, ey_d[7:4]})  : seg(5'd16);
            hex0 = hay ? seg({1'b0, ey_d[3:0]})  : seg(5'd16);
        end
        2'b10: begin
            hex5 = seg({1'b0, dab_d[11:8]});
            hex4 = seg({1'b0, dab_d[7:4]});
            hex3 = seg({1'b0, dab_d[3:0]});
            hex2 = seg(5'd31);
            hex1 = seg(ruta_a);
            hex0 = seg(ruta_b);
        end
        default: begin
            hex5 = rv_a ? seg({1'b0, ga[11:8]}) : seg(5'd16);
            hex4 = rv_a ? seg({1'b0, ga[7:4]})  : seg(5'd16);
            hex3 = rv_a ? seg({1'b0, ga[3:0]})  : seg(5'd16);
            hex2 = rv_b ? seg({1'b0, gb[11:8]}) : seg(5'd16);
            hex1 = rv_b ? seg({1'b0, gb[7:4]})  : seg(5'd16);
            hex0 = rv_b ? seg({1'b0, gb[3:0]})  : seg(5'd16);
        end
    endcase
    ledr = {(oye_a && dir_a != 0) ? metros5(d_a) : 5'd0, (oye_b && dir_b != 0) ? metros5(d_b) : 5'd0};
end

endmodule
