`timescale 1ns / 1ps
// ============================================================================
// tri_red.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Red de deteccion y triangulacion con tres FPGA: dos mochilas (A y B) y el
// receptor del operador, unidas por UART. La terminal de la computadora
// (pc/terminal.tcl) muestra todos los datos con decimales y mueve las
// cucarachas.
//
// Cada mochila corre el nucleo verificado (nucleo_biobot) sobre una escena
// termica simulada:
//   - El sensor termico se simula con los interruptores: SW5-SW0 son la
//     temperatura que lee la matriz, en grados C. El nucleo detecta a una
//     persona si esta entre 35 y 38 C (y 2 C sobre el fondo). Si la
//     temperatura sale de ese intervalo, la deteccion se apaga en menos de
//     un segundo.
//   - El boton KEY1 es el segundo metodo: basta apretarlo 0.1 s y queda
//     marcado hasta el reset. Los dos metodos son redundantes.
//   - La posicion de la cucaracha la fija la terminal; sin terminal, SW9-SW6
//     eligen una de 16 posiciones fijas.
// Cuando una mochila detecta, lo difunde: las tres tarjetas muestran "Pd" y
// el numero de personas detectadas (0, 1 o 2). Cada nodo muestra a quien
// oye y a que distancia, en metros y en binario, en los LED.
//
// El receptor cruza los dos rumbos para estimar donde esta la persona
// (triangulacion por angulos, con CORDIC y un divisor).
//
// Distancias: 10 bits, 0 a 64 m, 1 cuenta = 64/1024 m = 6.25 cm (5 m = 80 cuentas = 7.8 %).
// Alcance del radio y del tono: se oye a menos de 32 m (511 cuentas = 31.94 m).
// Angulos: binario de 16 bits (65 536 = 360 grados); en la red, 10 bits.
//
// Protocolo de enlace, sobre UART 8N1 a 115 200 baudios. Trama de una mochila
// (16 bytes, cada 100 ms):
//   0   0xA5                   sincronia
//   1   {origen[1:0], emisor[1:0], saltos[1:0], 2'b00}
//   2   {termica, boton, pre, rumbo_valido, 1'b0, estado[2:0]}
//   3   x_origen[7:0]          4  y_origen[7:0]
//   5   {x_origen[9:8], y_origen[9:8], rumbo[9:8], 2'b00}
//   6   rumbo[7:0]             7  rango[7:0] (distancia estimada a la persona)
//   8   {1'b0, pixeles_calientes[6:0]}
//   9   x_emisor[7:0]          10 y_emisor[7:0]
//   11  {x_emisor[9:8], y_emisor[9:8], 4'b0000}
//   12  {oye_a_la_otra_mochila, oye_al_receptor, temperatura[5:0]}
//   13  numero de secuencia del origen (sube de uno en uno)
//   14, 15  CRC-16/CCITT de los bytes 1 a 13 (polinomio 0x1021, inicial 0xFFFF)
// origen = la mochila que mide; emisor = la que transmite esta copia (la otra
// mochila cuando hace de puente). 1 = A, 2 = B.
// Reglas de quien recibe:
//   - Una trama con el CRC equivocado, o que se corta mas de 2 ms, se descarta.
//   - Solo se acepta si el emisor esta dentro del alcance (menos de 32 m).
//   - Una mochila reenvia una vez las tramas de la otra (saltos + 1): multisalto.
//   - Con el numero de secuencia el receptor cuenta las tramas perdidas y
//     reconoce la que le llega repetida por dos caminos.
//   - Si en 1 s no llega nada de una mochila, se da por perdida.
// ============================================================================

// ----------------------------------------------------------------------------
// Transmisor de una trama de N bytes de carga: cabecera, carga y CRC-16/CCITT
// ----------------------------------------------------------------------------
module tri_tx_n #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer N         = 12,
    parameter [7:0]   CAB       = 8'hA5
) (
    input  wire           clk,
    input  wire           reset,
    input  wire           start,
    input  wire [8*N-1:0] carga,       // el primer byte en los bits altos
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
reg  [1:0]     st;                    // 0 libre, 1 pedir, 2 esperar arranque, 3 esperar fin
reg  [15:0]    crc;
assign ocupado = (st != 2'd0);
wire [7:0] byte_k = c[8*N-1:8*N-8];

// CRC-16/CCITT (polinomio 0x1021, valor inicial 0xFFFF), un byte por llamada
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

// orden de salida: cabecera, N bytes de carga, CRC alto, CRC bajo
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

// ----------------------------------------------------------------------------
// Receptor de tramas de N bytes de carga: revisa la cabecera y el CRC-16/CCITT
// ----------------------------------------------------------------------------
module tri_rx_n #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer N         = 12,
    parameter [7:0]   CAB       = 8'hA5
) (
    input  wire           clk,
    input  wire           reset,
    input  wire           rx,
    output reg            listo,      // pulso: trama completa y con el CRC correcto
    output reg  [8*N-1:0] carga,
    output reg            mala        // pulso: trama completa pero con el CRC equivocado
);

wire [7:0] d;
wire       v;
uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (.clk(clk), .reset(reset), .rx(rx),
    .data_out(d), .data_valid(v));

localparam integer T_HUECO = CLK_FREQ / 500;   // 2 ms sin bytes reinicia la trama

reg [7:0]     n;
reg [8*N-1:0] b;
reg [15:0]    crc;
reg [7:0]     crc_alto;
reg [31:0]    hueco;

function [15:0] crc16;                         // igual que en el transmisor
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

// ----------------------------------------------------------------------------
// Las 16 posiciones de una cucaracha (cuentas de 1/16 m). La persona esta en
// (408, 308) = (25.50, 19.25) m, a 31.95 m del receptor, que esta en la entrada (0, 0):
// justo en el borde del alcance de 32 m. Distancia al receptor entre parentesis.
//   0 (25.25, 19.00)  junto a la persona, la ve a 45 grados   (31.60 m: SE OYE)
//   1 (25.75, 19.00)  junto a la persona, la ve a 135 grados  (32.00 m: NO se oye)
//   2 (25.75, 19.50)  junto a la persona, la ve a 225 grados  (32.30 m: no se oye)
//   3 (25.25, 19.50)  junto a la persona, la ve a 315 grados  (31.90 m: se oye)
//   4 (25.50, 18.94)  junto a la persona, la ve a 90 grados   (31.76 m: se oye)
//   5 (40.00, 30.00)  lejos                                    (50.00 m)
//   6 (50.00, 40.00)  muy lejos                                (64.03 m)
//   7 ( 4.50,  3.00)  cerca de la entrada: sirve de puente     ( 5.41 m)
//   8 (2, 2)  9 (10, 10)  10 (20, 10)  11 (10, 20)  12 (20, 20)
//   13 (23, 22) a 31.83 m   14 (24, 22) a 32.56 m   15 (60, 60)
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Escena termica simulada. Sabe donde esta la persona (PX, PY); con la
// posicion y el rumbo del insecto calcula con el CORDIC (vectorizacion) en
// que direccion la veria la matriz de 8x8 y genera los 64 pixeles. La
// temperatura de la mancha es la que marcan los interruptores; el fondo esta
// a 22 C. Como la temperatura es la lectura simulada del sensor, la mancha se
// dibuja como si la persona estuviera enfrente (a 0.38 m o menos). El insecto
// gira 15 grados con cada estimulo de giro.
// ----------------------------------------------------------------------------
module tri_escena #(
    parameter [9:0]  PX     = 10'd408,
    parameter [9:0]  PY     = 10'd308,
    parameter [15:0] OFFSET = 16'd2185     // el insecto queda girado 12 grados respecto a la persona
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        calcula,
    input  wire        avanza,
    input  wire [9:0]  xm,
    input  wire [9:0]  ym,
    input  wire [5:0]  temp,               // grados C
    input  wire        estimulo,
    input  wire [1:0]  canal,              // 01 izquierda, 10 derecha
    input  wire [5:0]  idx,
    output wire [7:0]  px_temp,
    output wire [7:0]  actividad,
    output reg  [15:0] rumbo_insecto,
    output reg  [15:0] rumbo_real,
    output reg  [11:0] dist_mm,
    output reg         listo
);

localparam [15:0] GIRO   = 16'd2731;        // 15 grados por estimulo
localparam [7:0]  T_AMB  = 8'd88;           // 22 C

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

// mm = magnitud * 0.60725 / 64 * 62.5 = magnitud * 38864 / 65536
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

// donde queda la persona respecto al frente: phi = rumbo_real - rumbo_insecto (izquierda positivo);
// en cuartos de columna (1 cuarto = 1.875 grados = 341.33 cuentas), derecha positivo
wire signed [15:0] phi      = rumbo_real - rumbo_insecto;
wire signed [31:0] phi_q3   = phi * 32'sd3;
wire signed [31:0] q_32     = -(phi_q3 >>> 10);
wire signed [15:0] q        = q_32[15:0];         // cabe: |q| <= 96
wire               en_campo = (phi > -16'sd10923) && (phi < 16'sd10923);   // +-60 grados
wire [11:0]        d_vis    = (dist_mm > 12'd380) ? 12'd380 : dist_mm;

reg [9:0] radio2;
always @(*) begin
    case (d_vis[11:6])
        6'd0: radio2 = 10'd1023;  6'd1: radio2 = 10'd957;  6'd2: radio2 = 10'd344;
        6'd3: radio2 = 10'd176;   6'd4: radio2 = 10'd106;  default: radio2 = 10'd71;
    endcase
end

wire signed [15:0] qc     = (q > 16'sd60) ? 16'sd60 : (q < -16'sd60) ? -16'sd60 : q;

// El centro de la mancha se guarda en un registro: solo cambia entre cuadros, y asi la
// cuenta del angulo no queda en la misma ruta que el calculo de cada pixel.
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
assign actividad = {6'd0, azar[1:0]};      // el insecto esta detenido

endmodule

// ----------------------------------------------------------------------------
// Mochila. ROL 1 = A, 2 = B.
//   sw[5:0]  temperatura que lee el sensor (grados C); detecta de 35 a 38 C
//   sw[9:6]  posicion (tri_posicion)
//   boton    la persona lo sostiene T_PULSA_MS
// Displays: HEX5-HEX2 "PdA", "Pd b" o "PdAb" segun quien detecto (propia u otra
//   mochila); "----" si nadie. HEX1-HEX0 la temperatura que lee esta mochila.
// LED: 9-5 metros a la otra mochila, 4-0 metros al receptor (apagados: no la oye).
// ----------------------------------------------------------------------------
module tri_mochila #(
    parameter integer ROL        = 1,
    parameter integer CLK_FREQ   = 50000000,
    parameter integer BAUD_RATE  = 115200,
    parameter integer F_EST      = 50,
    parameter integer N_PULSOS   = 25,
    parameter [9:0]   PX         = 10'd408,
    parameter [9:0]   PY         = 10'd308,
    parameter [15:0]  OFFSET     = 16'd2185,
    parameter [15:0]  DERIVA     = 16'd0,       // error de la IMU en el rumbo
    parameter integer ALC        = 511,         // alcance: se oye a menos de 32 m
    parameter integer T_PULSA_MS = 100,         // el boton debe durar apretado 0.1 s (quita rebotes)
    parameter integer REARMA     = 1            // 1 = la deteccion termica se apaga al perder la mancha
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        boton,
    input  wire [9:0]  sw,
    input  wire        pos_ext,                 // 1 = la posicion viene de la terminal (x_ext, y_ext)
    input  wire [9:0]  x_ext,
    input  wire [9:0]  y_ext,
    input  wire        rx1,
    input  wire        rx2,
    output wire        tx,
    output reg  [9:0]  ledr,
    output reg  [6:0]  hex0, hex1, hex2, hex3, hex4, hex5,
    // telemetria
    output wire [9:0]  x_yo,
    output wire [9:0]  y_yo,
    output wire [5:0]  temp,
    output reg  [9:0]  d_rec,                   // distancia al receptor (en la entrada)
    output wire        oye_rec,                 // oye el tono del receptor (4 kHz)
    output wire        oye_otra,                // oye el tono de la otra mochila
    output wire [15:0] pot_rec,                 // potencia medida de cada tono
    output wire [15:0] pot_otra,
    output wire        tono,                    // tono propio: 1 kHz en A, 2 kHz en B
    output wire [1:0]  cuenta_pd,               // personas detectadas (0, 1 o 2)
    output reg  [15:0] rumbo_med,
    output reg         rumbo_ok,
    output wire        alerta,
    output reg         persona,
    output wire [2:0]  estado,
    output wire [6:0]  n_fil,
    output reg  [7:0]  rango,
    output wire [15:0] rumbo_real,
    output reg  [9:0]  d_otra,                  // distancia a la otra mochila
    output wire        otra_viva,
    output wire        otra_detecta
);

localparam integer C_CUADRO = CLK_FREQ / 10;
localparam integer C_PULSA  = (CLK_FREQ / 1000) * T_PULSA_MS;
localparam [3:0]   T_FRESCO = 4'd5;
localparam [3:0]   T_VIVO   = 4'd10;
localparam [7:0]   T_PIEL_MIN = 8'd140;         // 35.00 C (0.25 C por cuenta)
localparam [7:0]   T_PIEL_MAX = 8'd155;         // 38.75 C
wire [1:0] yo   = ROL[1:0];
wire [1:0] otra = (ROL == 1) ? 2'd2 : 2'd1;

// ---- interruptores sincronizados
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

// ---- reloj de cuadros
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

// ---- escena y nucleo (ventana de 35 a 38 C)
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

// Rearme: en el nucleo, ALERTAR es un estado final (en una mision real el aviso se sostiene).
// Aqui la deteccion termica debe seguir al sensor: si la mochila ya habia alertado y deja de
// ver la mancha durante medio segundo (cinco cuadros), el nucleo se reinicia y vuelve a
// explorar, con lo que el conteo de personas baja. El nucleo no se modifica.
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

// Ventana de la piel: 35.00 a 38.75 C. Con el sensor en grados enteros detecta 35, 36, 37 y
// 38 y rechaza 34 y 39; los 0.75 C de arriba absorben el ruido de un bit de la lectura.
nucleo_biobot #(.CLK_FREQ(CLK_FREQ), .F_EST(F_EST), .N_PULSOS(N_PULSOS),
                .T_MIN(T_PIEL_MIN), .T_MAX(T_PIEL_MAX), .DELTA(8'd8)) u_nucleo (
    .clk(clk), .reset(reset_nucleo), .habilita(1'b1),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est)
);

// ---- rumbo medido: centroide de las columnas calientes (mismo criterio que el nucleo)
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

// ---- distancia a la persona estimada por el tamano de la mancha (cuentas de 6.25 cm)
always @(*) begin
    if      (n_fil >= 7'd40) rango = 8'd2;      // 0.13 m
    else if (n_fil >= 7'd24) rango = 8'd4;      // 0.25 m
    else if (n_fil >= 7'd12) rango = 8'd6;      // 0.39 m
    else if (n_fil >= 7'd4)  rango = 8'd12;     // 0.77 m
    else if (n_fil >= 7'd2)  rango = 8'd17;     // 1.09 m
    else                     rango = 8'd0;
end

// ---- boton
reg [31:0] c_pulsa;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_pulsa <= 0; persona <= 1'b0; end
    else if (!boton) c_pulsa <= 0;
    else if (c_pulsa < C_PULSA) c_pulsa <= c_pulsa + 1;
    else persona <= 1'b1;
end

// ---- radio: 13 bytes de carga (los 12 de datos y el numero de secuencia)
wire         l1, l2;
wire [103:0] r1x, r2x;
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx1 (.clk(clk), .reset(reset), .rx(rx1), .listo(l1), .carga(r1x), .mala());
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx2 (.clk(clk), .reset(reset), .rx(rx2), .listo(l2), .carga(r2x), .mala());
wire [95:0] r1 = r1x[103:8], r2 = r2x[103:8];
wire [7:0]  q1 = r1x[7:0],   q2 = r2x[7:0];

// campos de la carga (byte 1 en [95:88])
function [1:0] c_org;  input [95:0] c; c_org = c[95:94]; endfunction
function [1:0] c_emi;  input [95:0] c; c_emi = c[93:92]; endfunction
function [1:0] c_sal;  input [95:0] c; c_sal = c[91:90]; endfunction
function [9:0] c_xo;   input [95:0] c; c_xo  = {c[63:62], c[79:72]}; endfunction
function [9:0] c_yo;   input [95:0] c; c_yo  = {c[61:60], c[71:64]}; endfunction
function [9:0] c_xe;   input [95:0] c; c_xe  = {c[15:14], c[31:24]}; endfunction
function [9:0] c_ye;   input [95:0] c; c_ye  = {c[13:12], c[23:16]}; endfunction
function en_alcance;
    input [95:0] c;
    input [9:0]  xa, ya;
    reg signed [11:0] ddx, ddy;
    begin
        ddx = $signed({2'b00, c_xe(c)}) - $signed({2'b00, xa});
        ddy = $signed({2'b00, c_ye(c)}) - $signed({2'b00, ya});
        en_alcance = (ddx * ddx + ddy * ddy) <= ALC * ALC;
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

// lo que se sabe de la otra mochila, y la trama para reenviar (puente)
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
            det_otra <= (ok1 ? (r1[87] | r1[86]) : (r2[87] | r2[86]));   // termica o boton
        end
    end
end
assign otra_viva    = (t_otra != 0);
assign otra_detecta = otra_viva && det_otra;
wire   puente       = (t_fwd != 0);

// ---- distancia a la otra mochila con un segundo CORDIC (cada 100 ms)
wire signed [23:0] ddx_o = $signed({14'd0, xo_otra}) - $signed({14'd0, x_yo});
wire signed [23:0] ddy_o = $signed({14'd0, yo_otra}) - $signed({14'd0, y_yo});
wire signed [23:0] mx, my;
wire        [15:0] mz;
wire               m_listo;
cordic #(.W(24), .N(16)) u_cordic_d (.clk(clk), .reset(reset), .start(tick100), .modo(1'b1),
    .x0(ddx_o <<< 4), .y0(ddy_o <<< 4), .z0(16'd0), .x(mx), .y(my), .z(mz), .listo(m_listo));
wire [39:0] d_x = mx * 40'sd9949;           // magnitud * 0.60725 / 16
always @(posedge clk or posedge reset) begin
    if (reset) d_otra <= 10'd0;
    else if (m_listo) d_otra <= !otra_viva ? 10'd0 : (d_x[39:18] > 22'd1023) ? 10'd1023 : d_x[27:18];
end

// ---- distancia al receptor, que esta en la entrada (0, 0): tercer CORDIC
wire signed [23:0] rx_, ry_;
wire        [15:0] rz_;
wire               r_listo;
cordic #(.W(24), .N(16)) u_cordic_r (.clk(clk), .reset(reset), .start(tick100), .modo(1'b1),
    .x0($signed({14'd0, x_yo}) <<< 4), .y0($signed({14'd0, y_yo}) <<< 4), .z0(16'd0),
    .x(rx_), .y(ry_), .z(rz_), .listo(r_listo));
wire [39:0] dr_x = rx_ * 40'sd9949;
always @(posedge clk or posedge reset) begin
    if (reset) d_rec <= 10'd0;
    else if (r_listo) d_rec <= (dr_x[39:18] > 22'd1023) ? 10'd1023 : dr_x[27:18];
end
// ---- localizacion por tonos (tonos.v). El canal acustico va simulado: el tono de otro
// nodo llega si ese nodo esta a menos de 32 m. La posicion verdadera de la otra mochila se
// toma de sus tramas tal como llegan por el cable, antes de aplicar el alcance del radio.
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
function cerca;                                 // dos puntos a ALC o menos
    input [9:0] x1, y1, x2, y2;
    reg signed [11:0] ex, ey;
    begin
        ex = $signed({2'b00, x1}) - $signed({2'b00, x2});
        ey = $signed({2'b00, y1}) - $signed({2'b00, y2});
        cerca = (ex * ex + ey * ey) <= ALC * ALC;
    end
endfunction
wire        llega_otra = (t_cable != 0) && cerca(xr_otra, yr_otra, x_yo, y_yo);
wire        llega_rec  = cerca(10'd0, 10'd0, x_yo, y_yo);      // el receptor emite siempre
wire [2:0]  presente   = (ROL == 1) ? {llega_otra, 1'b0, llega_rec} : {1'b0, llega_otra, llega_rec};
wire [2:0]  oye_t;
wire [15:0] p0, p1, p2;
tri_tonos #(.CLK_FREQ(CLK_FREQ), .YO(ROL)) u_tonos (.clk(clk), .reset(reset), .presente(presente),
    .tono(tono), .oye(oye_t), .pot0(p0), .pot1(p1), .pot2(p2));
assign oye_rec  = oye_t[0];                                     // oye los 4 kHz del receptor
assign oye_otra = (ROL == 1) ? oye_t[2] : oye_t[1];             // oye el tono de la otra mochila
assign pot_rec  = p0;
assign pot_otra = (ROL == 1) ? p2 : p1;

// ---- transmision
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

// Cada trama propia lleva un numero de secuencia que sube de uno en uno; la reenviada
// conserva el de su origen. Con el, quien recibe sabe si se perdieron tramas o si la misma
// le llego por dos caminos.
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

// ---- displays y LED
function [6:0] seg;
    input [4:0] c;
    case (c)
        5'd0: seg = 7'b1000000;  5'd1: seg = 7'b1111001;  5'd2: seg = 7'b0100100;  5'd3: seg = 7'b0110000;
        5'd4: seg = 7'b0011001;  5'd5: seg = 7'b0010010;  5'd6: seg = 7'b0000010;  5'd7: seg = 7'b1111000;
        5'd8: seg = 7'b0000000;  5'd9: seg = 7'b0010000;
        5'd10: seg = 7'b0001000; // A
        5'd11: seg = 7'b0000011; // b
        5'd13: seg = 7'b0100001; // d
        5'd16: seg = 7'b0111111; // -
        5'd18: seg = 7'b0001100; // P
        5'd19: seg = 7'b0101111; // r
        default: seg = 7'b1111111;
    endcase
endfunction

// cuentas de 1/16 m a metros enteros (0 a 31), sin redondear: 31.9 m se muestra como 31
function [4:0] metros5;
    input [9:0] c;
    reg [13:0] m;
    begin
        m = {8'd0, c[9:4]};
        metros5 = (m > 14'd31) ? 5'd31 : m[4:0];
    end
endfunction

wire det_yo = alerta | persona;                 // termica o boton
assign cuenta_pd = det_yo + otra_detecta;

// HEX5 quien soy (A o b), HEX4-HEX3 "Pd", HEX2 personas detectadas, HEX1 la letra de la otra
// mochila si oigo su tono, HEX0 "r" si oigo el tono del receptor. LED9-5 metros a la otra
// mochila, LED4-0 metros al receptor (apagados si no se oye su tono).
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

// ----------------------------------------------------------------------------
// Triangulacion: cruza las rectas que salen de A y de B con sus rumbos.
//   P = A + t * (cos thA, sin thA),  t = ((B - A) x uB) / (uA x uB)
// Da tambien la posicion aproximada de cada mochila sola: A + rango_A * uA.
// error: 0 bien, 1 rumbos casi paralelos (menos de 10 grados entre si),
//        2 las rectas se cruzan detras de alguna mochila, 3 cruce a mas de T_MAX
// ----------------------------------------------------------------------------
module tri_triangula #(
    parameter integer T_MAX = 48           // 3 m
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

localparam signed [31:0] DEN_MIN = 32'sd46603904;   // sin(10 grados) * 2^28

reg [3:0] st;
reg signed [17:0] ca, sa, cb, sb;
reg signed [31:0] den, num, num2;
reg signed [11:0] ddx, ddy;
reg signed [43:0] t;

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
wire signed [47:0] tca_r = (tca + 48'sd8192) >>> 14;   // t*cos redondeado, en cuentas
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
                          d_num <= {num_abs[29:0], 14'd0}; d_den <= den_abs; d_start <= 1'b1; st <= 4'd6;   // |num| < 2^26
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

// ----------------------------------------------------------------------------
// Receptor del operador.
//   vista (SW1-SW0): 00 "r Pd", personas detectadas y a quien oye (A, b)
//                    01 persona: X y Y en decimetros (tres digitos cada uno)
//                    10 distancia entre A y B en decimetros + rutas de A y de B
//                    11 rumbos de A y de B en grados
//   LED: 9-5 metros a la mochila A, 4-0 metros a la B (apagados si no oye su tono)
//   tx_pc: cada 100 ms un resumen de 32 bytes para la computadora (0xA6 ... CRC-16)
// ----------------------------------------------------------------------------
module tri_receptor #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer ALC       = 511          // alcance: se oye a menos de 32 m
) (
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  vista,
    input  wire        rx1,
    input  wire        rx2,
    output wire        tx_pc,
    output reg  [9:0]  ledr,
    output reg  [6:0]  hex0, hex1, hex2, hex3, hex4, hex5,
    // telemetria
    output reg  [9:0]  est_x,
    output reg  [9:0]  est_y,
    output reg  [2:0]  modo,                   // 0 nada, 1 una mochila, 2 triangulada, 3 rumbos sin cruce, 4 solo boton
    output wire [2:0]  n_ev,
    output wire [1:0]  tri_error,
    output wire [9:0]  tha_o, thb_o,
    output reg  [9:0]  d_ab,
    output reg  [9:0]  d_a,                    // distancia del receptor a la mochila A
    output reg  [9:0]  d_b,
    output wire [1:0]  cuenta_pd,              // personas detectadas (0, 1 o 2)
    output wire [3:0]  enlaces,                // {A directo, A por puente, B directo, B por puente}
    output wire [7:0]  perd_a,                 // tramas de A que no llegaron (por el numero de secuencia)
    output wire [7:0]  perd_b,
    output reg  [7:0]  malas,                  // tramas descartadas por CRC equivocado o incompletas
    // lo ultimo que se supo de cada mochila, para la computadora del operador:
    // {x[9:0], y[9:0], temp[5:0], termica, boton, pre, rumbo_ok, estado[2:0], oye_otra, oye_rec, pixeles[6:0]}
    output wire [41:0] info_a,
    output wire [41:0] info_b,
    // localizacion por tonos: el receptor emite 4 kHz y escucha 1 kHz (A) y 2 kHz (B)
    output wire        oye_a,
    output wire        oye_b,
    output wire [15:0] pot_a,
    output wire [15:0] pot_b,
    output wire        tono
);

localparam integer C_TICK = CLK_FREQ / 10;
localparam [3:0]   T_VIVO = 4'd10;

wire         l1, l2, m1, m2;
wire [103:0] r1x, r2x;
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx1 (.clk(clk), .reset(reset), .rx(rx1), .listo(l1), .carga(r1x), .mala(m1));
tri_rx_n #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .N(13)) u_rx2 (.clk(clk), .reset(reset), .rx(rx2), .listo(l2), .carga(r2x), .mala(m2));
wire [95:0] r1 = r1x[103:8], r2 = r2x[103:8];
wire [7:0]  q1 = r1x[7:0],   q2 = r2x[7:0];

function en_alcance;
    input [95:0] c;
    reg [9:0] xe, ye;
    begin
        xe = {c[15:14], c[31:24]};
        ye = {c[13:12], c[23:16]};
        en_alcance = ({10'd0, xe} * {10'd0, xe} + {10'd0, ye} * {10'd0, ye}) <= ALC * ALC;
    end
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

// campos: byte 2 [87:80] banderas; x [63:62]+[79:72]; y [61:60]+[71:64]; th [59:58]+[55:48];
// rango [47:40]; pixeles [38:32]; temperatura [5:0]
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

// ---- numero de secuencia: tramas perdidas y repetidas de cada mochila
// Estado por origen: {visto, ultima secuencia, perdidas}. Si la secuencia salta, las que
// faltan se cuentan como perdidas; si se repite (la misma trama llego directa y por el
// puente) se ignora; si retrocede, la mochila se reinicio y solo se vuelve a sincronizar.
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
            ult = q;                                  // repetida
        end else if (delta < 8'd128) begin
            s    = {1'b0, perd} + {1'b0, delta} - 9'd1;
            perd = s[8] ? 8'hFF : s[7:0];
            ult  = q;
        end else
            ult = q;                                  // la mochila se reinicio
        sigue = {visto, ult, perd};
    end
endfunction

reg [16:0] ea, eb;                                    // estado de A y de B
reg [16:0] na, nb;                                    // valores intermedios
always @(posedge clk or posedge reset) begin
    if (reset) begin ea <= 17'd0; eb <= 17'd0; malas <= 8'd0; end
    else begin
        na = ea; nb = eb;
        if (!vivo_a) na[16] = 1'b0;                   // si dejo de oirse, la siguiente trama sincroniza
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

// ---- triangulacion cada 100 ms
wire [9:0] px, py, pax, pay, pbx, pby;
wire       t_listo;
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

// ---- distancia entre A y B (CORDIC, vectorizacion)
wire signed [23:0] dabx = $signed({14'd0, bx}) - $signed({14'd0, ax});
wire signed [23:0] daby = $signed({14'd0, by}) - $signed({14'd0, ay});
wire signed [23:0] mx, my;
wire        [15:0] mz;
wire               m_listo;
cordic #(.W(24), .N(16)) u_cordic_d (.clk(clk), .reset(reset), .start(tick), .modo(1'b1),
    .x0(dabx <<< 4), .y0(daby <<< 4), .z0(16'd0), .x(mx), .y(my), .z(mz), .listo(m_listo));
wire [39:0] d_x = mx * 40'sd9949;
always @(posedge clk or posedge reset) begin
    if (reset) d_ab <= 10'd0;
    else if (m_listo) d_ab <= !(vivo_a && vivo_b) ? 10'd0 : (d_x[39:18] > 22'd1023) ? 10'd1023 : d_x[27:18];
end

// ---- distancia del receptor (origen) a cada mochila
wire signed [23:0] ax_c, ay_c, bx_c, by_c;
wire        [15:0] az_c, bz_c;
wire               a_listo, b_listo;
cordic #(.W(24), .N(16)) u_cordic_a (.clk(clk), .reset(reset), .start(tick), .modo(1'b1),
    .x0($signed({14'd0, ax}) <<< 4), .y0($signed({14'd0, ay}) <<< 4), .z0(16'd0),
    .x(ax_c), .y(ay_c), .z(az_c), .listo(a_listo));
cordic #(.W(24), .N(16)) u_cordic_b (.clk(clk), .reset(reset), .start(tick), .modo(1'b1),
    .x0($signed({14'd0, bx}) <<< 4), .y0($signed({14'd0, by}) <<< 4), .z0(16'd0),
    .x(bx_c), .y(by_c), .z(bz_c), .listo(b_listo));
wire [39:0] da_x = ax_c * 40'sd9949;
wire [39:0] db_x = bx_c * 40'sd9949;
always @(posedge clk or posedge reset) begin
    if (reset) begin d_a <= 10'd0; d_b <= 10'd0; end
    else begin
        if (a_listo) d_a <= (da_x[39:18] > 22'd1023) ? 10'd1023 : da_x[27:18];
        if (b_listo) d_b <= (db_x[39:18] > 22'd1023) ? 10'd1023 : db_x[27:18];
    end
end
assign enlaces   = {(dir_a != 0), (rel_a != 0), (dir_b != 0), (rel_b != 0)};

// ---- localizacion por tonos (tonos.v), con el canal simulado: el tono de una mochila
// llega si esta a menos de 32 m. Su posicion verdadera se toma de las tramas que manda ella
// misma (origen = emisor), tal como llegan por el cable y antes de aplicar el alcance.
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
wire llega_a = (tc_a != 0) && (({10'd0, xr_a} * {10'd0, xr_a} + {10'd0, yr_a} * {10'd0, yr_a}) <= ALC * ALC);
wire llega_b = (tc_b != 0) && (({10'd0, xr_b} * {10'd0, xr_b} + {10'd0, yr_b} * {10'd0, yr_b}) <= ALC * ALC);
wire [2:0]  oye_t;
wire [15:0] p0;
tri_tonos #(.CLK_FREQ(CLK_FREQ), .YO(0)) u_tonos (.clk(clk), .reset(reset), .presente({llega_b, llega_a, 1'b0}),
    .tono(tono), .oye(oye_t), .pot0(p0), .pot1(pot_a), .pot2(pot_b));
assign oye_a = oye_t[1];
assign oye_b = oye_t[2];
assign cuenta_pd = (term_a | bot_a) + (term_b | bot_b);

// ---- resumen para la computadora: 32 bytes de carga cada 100 ms
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

// ---- displays
function [6:0] seg;
    input [4:0] c;
    case (c)
        5'd0: seg = 7'b1000000;  5'd1: seg = 7'b1111001;  5'd2: seg = 7'b0100100;  5'd3: seg = 7'b0110000;
        5'd4: seg = 7'b0011001;  5'd5: seg = 7'b0010010;  5'd6: seg = 7'b0000010;  5'd7: seg = 7'b1111000;
        5'd8: seg = 7'b0000000;  5'd9: seg = 7'b0010000;
        5'd10: seg = 7'b0001000; // A
        5'd11: seg = 7'b0000011; // b
        5'd13: seg = 7'b0100001; // d
        5'd14: seg = 7'b0000110; // E
        5'd16: seg = 7'b0111111; // -
        5'd17: seg = 7'b0000111; // t
        5'd18: seg = 7'b0001100; // P
        5'd19: seg = 7'b0101111; // r
        default: seg = 7'b1111111;
    endcase
endfunction
function [4:0] metros5;                 // cuentas de 1/16 m a metros enteros (0 a 31)
    input [9:0] c;
    reg [13:0] m;
    begin
        m = {8'd0, c[9:4]};
        metros5 = (m > 14'd31) ? 5'd31 : m[4:0];
    end
endfunction
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
function [11:0] dm3;                    // cuentas de 1/16 m a decimetros, tres digitos
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
        2'b00: begin    // r Pd <personas detectadas> <oye a A> <oye a B>
            hex5 = seg(5'd19);
            hex4 = seg(5'd18);
            hex3 = seg(5'd13);
            hex2 = seg({3'b000, cuenta_pd});
            hex1 = oye_a ? seg(5'd10) : seg(5'd16);
            hex0 = oye_b ? seg(5'd11) : seg(5'd16);
        end
        2'b01: begin    // persona: X y Y en decimetros
            hex5 = hay ? seg({1'b0, ex_d[11:8]}) : seg(5'd16);
            hex4 = hay ? seg({1'b0, ex_d[7:4]})  : seg(5'd16);
            hex3 = hay ? seg({1'b0, ex_d[3:0]})  : seg(5'd16);
            hex2 = hay ? seg({1'b0, ey_d[11:8]}) : seg(5'd16);
            hex1 = hay ? seg({1'b0, ey_d[7:4]})  : seg(5'd16);
            hex0 = hay ? seg({1'b0, ey_d[3:0]})  : seg(5'd16);
        end
        2'b10: begin    // distancia A-B en decimetros, rutas
            hex5 = seg({1'b0, dab_d[11:8]});
            hex4 = seg({1'b0, dab_d[7:4]});
            hex3 = seg({1'b0, dab_d[3:0]});
            hex2 = seg(5'd31);
            hex1 = seg(ruta_a);
            hex0 = seg(ruta_b);
        end
        default: begin  // rumbos en grados
            hex5 = rv_a ? seg({1'b0, ga[11:8]}) : seg(5'd16);
            hex4 = rv_a ? seg({1'b0, ga[7:4]})  : seg(5'd16);
            hex3 = rv_a ? seg({1'b0, ga[3:0]})  : seg(5'd16);
            hex2 = rv_b ? seg({1'b0, gb[11:8]}) : seg(5'd16);
            hex1 = rv_b ? seg({1'b0, gb[7:4]})  : seg(5'd16);
            hex0 = rv_b ? seg({1'b0, gb[3:0]})  : seg(5'd16);
        end
    endcase
    // LED9-5 metros a la mochila A, LED4-0 metros a la B (apagados si no se oye su tono)
    ledr = {(oye_a && dir_a != 0) ? metros5(d_a) : 5'd0, (oye_b && dir_b != 0) ? metros5(d_b) : 5'd0};
end

endmodule
