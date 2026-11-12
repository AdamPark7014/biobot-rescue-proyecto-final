`timescale 1ns / 1ps
// ============================================================================
// red_mochilas.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Red de tres tarjetas: dos mochilas (A y B) y el receptor del rescatista.
//
//   - La persona atrapada aprieta el boton de la mochila (KEY1) medio segundo:
//     la mochila marca "persona encontrada".
//   - Los interruptores SW9..SW0 de cada mochila dicen a cuantos metros esta del
//     receptor (10 bits: de 0 a 1023 m).
//   - Cada mochila manda una trama cada 100 ms con quien es, donde esta y si
//     encontro a alguien. El radio solo alcanza ALC metros (100 m): una trama
//     se acepta solo si quien la manda esta a ALC metros o menos.
//   - Si A esta demasiado lejos del receptor pero B esta entre los dos, B
//     recibe la trama de A y la reenvia: hace de puente (red multisalto).
//   - El receptor junta lo que llega: quien encontro a la persona, por que
//     camino llego el aviso y a que distancia esta. Si las dos mochilas
//     avisan y estan a CONSENSO metros o menos una de otra, la deteccion se
//     confirma y la distancia es el promedio de las dos.
//
// Trama (6 bytes, 115 200 baudios):
//   0  0xA5
//   1  {origen[1:0], emisor[1:0], saltos[1:0], persona, 0}
//   2  pos_origen[7:0]
//   3  {pos_origen[9:8], pos_emisor[9:8], 4'b0000}
//   4  pos_emisor[7:0]
//   5  bytes 1 a 4 en XOR, y XOR con 0x5A
// origen = la mochila que detecto; emisor = la que transmite esta copia.
// Identificadores: 1 = mochila A, 2 = mochila B (0 = receptor, no transmite).
// ============================================================================

// ----------------------------------------------------------------------------
// Arma una trama a partir de los bytes que llegan por la UART
// ----------------------------------------------------------------------------
module red_rx_trama #(
    parameter integer T_HUECO = 100000          // ciclos sin bytes que reinician la trama
) (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] dato,
    input  wire       valido,
    output reg        listo,                    // pulso: trama completa y correcta
    output reg  [1:0] origen,
    output reg  [1:0] emisor,
    output reg  [1:0] saltos,
    output reg        persona,
    output reg  [9:0] pos_origen,
    output reg  [9:0] pos_emisor
);

reg [2:0]  n;
reg [7:0]  b1, b2, b3, b4;
reg [31:0] hueco;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        n <= 0; listo <= 1'b0; hueco <= 0;
        b1 <= 0; b2 <= 0; b3 <= 0; b4 <= 0;
        origen <= 0; emisor <= 0; saltos <= 0; persona <= 1'b0;
        pos_origen <= 0; pos_emisor <= 0;
    end else begin
        listo <= 1'b0;
        if (valido) begin
            hueco <= 0;
            case (n)
                3'd0: if (dato == 8'hA5) n <= 3'd1;
                3'd1: begin b1 <= dato; n <= 3'd2; end
                3'd2: begin b2 <= dato; n <= 3'd3; end
                3'd3: begin b3 <= dato; n <= 3'd4; end
                3'd4: begin b4 <= dato; n <= 3'd5; end
                default: begin
                    n <= 3'd0;
                    if (dato == (b1 ^ b2 ^ b3 ^ b4 ^ 8'h5A)) begin
                        listo      <= 1'b1;
                        origen     <= b1[7:6];
                        emisor     <= b1[5:4];
                        saltos     <= b1[3:2];
                        persona    <= b1[1];
                        pos_origen <= {b3[7:6], b2};
                        pos_emisor <= {b3[5:4], b4};
                    end
                end
            endcase
        end else if (n != 3'd0) begin
            if (hueco < T_HUECO) hueco <= hueco + 1;
            else begin n <= 3'd0; hueco <= 0; end
        end
    end
end

endmodule

// ----------------------------------------------------------------------------
// Un nodo de la red. ROL: 0 receptor, 1 mochila A, 2 mochila B
// ----------------------------------------------------------------------------
module red_nodo #(
    parameter integer ROL        = 1,
    parameter integer CLK_FREQ   = 50000000,
    parameter integer BAUD_RATE  = 115200,
    parameter integer ALC        = 100,          // alcance del radio (m)
    parameter integer CONSENSO   = 20,           // dos avisos a esta distancia o menos = misma persona (m)
    parameter integer T_PULSA_MS = 500           // tiempo que hay que sostener el boton (ms)
) (
    input  wire       clk,
    input  wire       reset,
    input  wire       boton,                     // 1 = apretado
    input  wire [9:0] pos,                       // metros al receptor (mochilas)
    input  wire       rx1,
    input  wire       rx2,
    output wire       tx,
    output reg  [9:0] ledr,
    output reg  [6:0] hex0, hex1, hex2, hex3, hex4, hex5
);

localparam integer C_TICK  = CLK_FREQ / 10;                    // 100 ms
localparam integer C_PULSA = (CLK_FREQ / 1000) * T_PULSA_MS;
localparam integer C_HUECO = CLK_FREQ / 500;                   // 2 ms
localparam [3:0]   T_FRESCO = 4'd5;                            // 500 ms
localparam [3:0]   T_VIVO   = 4'd10;                           // 1 s

wire [1:0] yo     = ROL;
wire [9:0] pos_yo = (ROL == 0) ? 10'd0 : pos;

function [9:0] dif;                     // |a - b|
    input [9:0] a, b;
    dif = (a > b) ? (a - b) : (b - a);
endfunction

// ---- base de tiempo de 100 ms
reg [31:0] c_tick;
reg        tick;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_tick <= 0; tick <= 1'b0; end
    else if (c_tick >= C_TICK - 1) begin c_tick <= 0; tick <= 1'b1; end
    else begin c_tick <= c_tick + 1; tick <= 1'b0; end
end

// ---- boton: sostenerlo T_PULSA_MS marca la deteccion hasta el reset
reg [31:0] c_pulsa;
reg        persona;
always @(posedge clk or posedge reset) begin
    if (reset) begin c_pulsa <= 0; persona <= 1'b0; end
    else if (ROL != 0) begin
        if (!boton) c_pulsa <= 0;
        else if (c_pulsa < C_PULSA) c_pulsa <= c_pulsa + 1;
        else persona <= 1'b1;
    end
end

// ---- dos receptores UART
wire [7:0] d1, d2;
wire       v1, v2;
uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx1 (.clk(clk), .reset(reset), .rx(rx1), .data_out(d1), .data_valid(v1));
uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx2 (.clk(clk), .reset(reset), .rx(rx2), .data_out(d2), .data_valid(v2));

wire       l1, l2, p1, p2;
wire [1:0] o1, o2, e1, e2, s1, s2;
wire [9:0] po1, po2, pe1, pe2;
red_rx_trama #(.T_HUECO(C_HUECO)) u_t1 (.clk(clk), .reset(reset), .dato(d1), .valido(v1), .listo(l1),
    .origen(o1), .emisor(e1), .saltos(s1), .persona(p1), .pos_origen(po1), .pos_emisor(pe1));
red_rx_trama #(.T_HUECO(C_HUECO)) u_t2 (.clk(clk), .reset(reset), .dato(d2), .valido(v2), .listo(l2),
    .origen(o2), .emisor(e2), .saltos(s2), .persona(p2), .pos_origen(po2), .pos_emisor(pe2));

// Se acepta una trama solo si quien la manda esta dentro del alcance del radio
wire ok1 = l1 && (e1 != yo) && (o1 != yo) && (o1 != 2'd0) && (dif(pe1, pos_yo) <= ALC);
wire ok2 = l2 && (e2 != yo) && (o2 != yo) && (o2 != 2'd0) && (dif(pe2, pos_yo) <= ALC);

// ---- mochilas: guardan lo que oyen de la otra para reenviarlo (puente)
reg  [3:0] t_fwd;
reg  [1:0] f_origen, f_saltos;
reg        f_persona;
reg  [9:0] f_pos;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        t_fwd <= 0; f_origen <= 0; f_saltos <= 0; f_persona <= 1'b0; f_pos <= 0;
    end else if (ROL != 0) begin
        if (ok1 && s1 < 2'd2) begin
            t_fwd <= T_FRESCO; f_origen <= o1; f_saltos <= s1 + 2'd1; f_persona <= p1; f_pos <= po1;
        end else if (ok2 && s2 < 2'd2) begin
            t_fwd <= T_FRESCO; f_origen <= o2; f_saltos <= s2 + 2'd1; f_persona <= p2; f_pos <= po2;
        end else if (tick && t_fwd != 0)
            t_fwd <= t_fwd - 1;
    end
end
wire puente = (t_fwd != 0);

// ---- transmisor: cada 100 ms la trama propia y, si hace de puente, la reenviada
reg  [7:0] tx_dato;
reg        tx_start;
wire       tx_busy;
uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (.clk(clk), .reset(reset), .tx_start(tx_start),
    .data_in(tx_dato), .tx(tx), .busy(tx_busy));

reg  [1:0] st;                  // 0 libre, 1 pedir byte, 2 esperar que arranque, 3 esperar que acabe
reg  [2:0] k;
reg        segunda;             // 0 trama propia, 1 trama reenviada
reg        latido;
reg  [7:0] t1, t2, t3, t4;      // bytes 1 a 4 de la trama en curso
wire [7:0] t5 = t1 ^ t2 ^ t3 ^ t4 ^ 8'h5A;

task arma;                       // carga los bytes de una trama
    input [1:0] org;
    input [1:0] sal;
    input       per;
    input [9:0] porg;
    begin
        t1 <= {org, yo, sal, per, 1'b0};
        t2 <= porg[7:0];
        t3 <= {porg[9:8], pos_yo[9:8], 4'b0000};
        t4 <= pos_yo[7:0];
    end
endtask

always @(posedge clk or posedge reset) begin
    if (reset) begin
        st <= 0; k <= 0; segunda <= 1'b0; latido <= 1'b0; tx_start <= 1'b0; tx_dato <= 8'h00;
        t1 <= 0; t2 <= 0; t3 <= 0; t4 <= 0;
    end else begin
        tx_start <= 1'b0;
        case (st)
            2'd0: if (tick && ROL != 0) begin
                      arma(yo, 2'd0, persona, pos_yo);
                      segunda <= 1'b0; k <= 0; st <= 2'd1; latido <= ~latido;
                  end
            2'd1: begin
                      case (k)
                          3'd0: tx_dato <= 8'hA5;
                          3'd1: tx_dato <= t1;
                          3'd2: tx_dato <= t2;
                          3'd3: tx_dato <= t3;
                          3'd4: tx_dato <= t4;
                          default: tx_dato <= t5;
                      endcase
                      tx_start <= 1'b1;
                      st <= 2'd2;
                  end
            2'd2: if (tx_busy) st <= 2'd3;
            default: if (!tx_busy) begin
                      if (k < 3'd5) begin k <= k + 1; st <= 2'd1; end
                      else if (!segunda && puente) begin
                          arma(f_origen, f_saltos, f_persona, f_pos);
                          segunda <= 1'b1; k <= 0; st <= 2'd1;
                      end else st <= 2'd0;
                  end
        endcase
    end
end

// ---- receptor: tabla de las dos mochilas
reg  [3:0] t_dir_a, t_rel_a, t_dir_b, t_rel_b;
reg        per_a, per_b;
reg  [9:0] pos_a, pos_b;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        t_dir_a <= 0; t_rel_a <= 0; t_dir_b <= 0; t_rel_b <= 0;
        per_a <= 1'b0; per_b <= 1'b0; pos_a <= 0; pos_b <= 0;
    end else if (ROL == 0) begin
        if (tick) begin
            if (t_dir_a != 0) t_dir_a <= t_dir_a - 1;
            if (t_rel_a != 0) t_rel_a <= t_rel_a - 1;
            if (t_dir_b != 0) t_dir_b <= t_dir_b - 1;
            if (t_rel_b != 0) t_rel_b <= t_rel_b - 1;
        end
        if (ok1) begin
            if (o1 == 2'd1) begin
                per_a <= p1; pos_a <= po1;
                if (s1 == 2'd0) t_dir_a <= T_VIVO; else t_rel_a <= T_VIVO;
            end else begin
                per_b <= p1; pos_b <= po1;
                if (s1 == 2'd0) t_dir_b <= T_VIVO; else t_rel_b <= T_VIVO;
            end
        end
        if (ok2) begin
            if (o2 == 2'd1) begin
                per_a <= p2; pos_a <= po2;
                if (s2 == 2'd0) t_dir_a <= T_VIVO; else t_rel_a <= T_VIVO;
            end else begin
                per_b <= p2; pos_b <= po2;
                if (s2 == 2'd0) t_dir_b <= T_VIVO; else t_rel_b <= T_VIVO;
            end
        end
    end
end

wire vivo_a = (t_dir_a != 0) || (t_rel_a != 0);
wire vivo_b = (t_dir_b != 0) || (t_rel_b != 0);
wire det_a  = vivo_a && per_a;
wire det_b  = vivo_b && per_b;
wire confirmada = det_a && det_b && (dif(pos_a, pos_b) <= CONSENSO);
wire posible    = det_a ^ det_b;
wire [10:0] suma = {1'b0, pos_a} + {1'b0, pos_b};
wire [9:0]  estimada = (det_a && det_b) ? (confirmada ? suma[10:1] : pos_a) : (det_a ? pos_a : pos_b);

// ---- displays
localparam [4:0] S_A = 5'd10, S_B = 5'd11, S_C = 5'd12, S_GUION = 5'd13, S_NADA = 5'd14, S_R = 5'd15, S_DOS = 5'd2;

function [6:0] seg;                      // segmentos g..a, encienden con 0
    input [4:0] c;
    case (c)
        5'd0: seg = 7'b1000000;  5'd1: seg = 7'b1111001;  5'd2: seg = 7'b0100100;  5'd3: seg = 7'b0110000;
        5'd4: seg = 7'b0011001;  5'd5: seg = 7'b0010010;  5'd6: seg = 7'b0000010;  5'd7: seg = 7'b1111000;
        5'd8: seg = 7'b0000000;  5'd9: seg = 7'b0010000;
        5'd10: seg = 7'b0001000;     // A
        5'd11: seg = 7'b0000011;     // b
        5'd12: seg = 7'b1000110;     // C
        5'd13: seg = 7'b0111111;     // -
        5'd15: seg = 7'b0101111;     // r
        default: seg = 7'b1111111;   // apagado
    endcase
endfunction

function [15:0] bcd;                     // binario de 10 bits a cuatro digitos decimales
    input [9:0] b;
    integer i;
    reg [25:0] s;
    begin
        s = {16'd0, b};
        for (i = 0; i < 10; i = i + 1) begin
            if (s[13:10] >= 5) s[13:10] = s[13:10] + 4'd3;
            if (s[17:14] >= 5) s[17:14] = s[17:14] + 4'd3;
            if (s[21:18] >= 5) s[21:18] = s[21:18] + 4'd3;
            if (s[25:22] >= 5) s[25:22] = s[25:22] + 4'd3;
            s = s << 1;
        end
        bcd = s[25:10];
    end
endfunction

wire        hay = det_a || det_b;
wire [15:0] dec = bcd((ROL == 0) ? estimada : pos_yo);
wire        muestra_num = (ROL != 0) || hay;
wire [1:0]  saltos_a = (t_dir_a != 0) ? 2'd0 : 2'd1;
wire [1:0]  saltos_b = (t_dir_b != 0) ? 2'd0 : 2'd1;

always @(*) begin
    hex0 = muestra_num ? seg({1'b0, dec[3:0]})   : seg(S_GUION);
    hex1 = muestra_num ? seg({1'b0, dec[7:4]})   : seg(S_GUION);
    hex2 = muestra_num ? seg({1'b0, dec[11:8]})  : seg(S_GUION);
    hex3 = muestra_num ? seg({1'b0, dec[15:12]}) : seg(S_GUION);
    if (ROL == 0) begin
        // HEX5: quien encontro (A, b, C confirmada, 2 dos avisos lejanos); HEX4: saltos del aviso
        if (confirmada)         begin hex5 = seg(S_C);   hex4 = seg({3'b000, saltos_a}); end
        else if (det_a && det_b) begin hex5 = seg(S_DOS); hex4 = seg({3'b000, saltos_a}); end
        else if (det_a)          begin hex5 = seg(S_A);   hex4 = seg({3'b000, saltos_a}); end
        else if (det_b)          begin hex5 = seg(S_B);   hex4 = seg({3'b000, saltos_b}); end
        else                     begin hex5 = seg(S_GUION); hex4 = seg(S_GUION); end
        ledr = {confirmada, posible, 3'b000, det_b, det_a, (t_dir_b != 0), (t_rel_a != 0), (t_dir_a != 0)};
    end else begin
        // HEX5: A o b; HEX4: r cuando esta reenviando avisos de la otra mochila
        hex5 = seg((ROL == 1) ? S_A : S_B);
        hex4 = puente ? seg(S_R) : seg(S_NADA);
        ledr = {persona, latido, puente, 7'b0000000};
    end
end

endmodule

// ----------------------------------------------------------------------------
// Tarjeta DE10-Lite. Pines del conector JP1:
//   pin 35 (GPIO_30)  TX     pin 33 (GPIO_28)  TX, copia (para llegar a dos tarjetas)
//   pin 37 (GPIO_32)  RX1    pin 39 (GPIO_34)  RX2       pines 30 y 12: tierra
// ----------------------------------------------------------------------------
module top_red_de10lite #(
    parameter integer ROL       = 1,
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200
) (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,                // KEY0 reset, KEY1 boton de la persona
    input  wire [9:0] SW,                 // distancia al receptor en metros
    input  wire       RX1,
    input  wire       RX2,
    output wire       TX1,
    output wire       TX2,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

reg [1:0] s1 = 2'b11, s2 = 2'b11;         // sincronizadores de las lineas de entrada
always @(posedge CLOCK_50) begin s1 <= {s1[0], RX1}; s2 <= {s2[0], RX2}; end

wire tx;
assign TX1 = tx;
assign TX2 = tx;

red_nodo #(.ROL(ROL), .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_nodo (
    .clk(CLOCK_50), .reset(~KEY[0]), .boton(~KEY[1]), .pos(SW),
    .rx1(s1[1]), .rx2(s2[1]), .tx(tx), .ledr(LEDR),
    .hex0(HEX0), .hex1(HEX1), .hex2(HEX2), .hex3(HEX3), .hex4(HEX4), .hex5(HEX5)
);

endmodule
