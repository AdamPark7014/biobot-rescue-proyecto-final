`timescale 1ns / 1ps
// ============================================================================
// top_insecto_de10lite.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Segunda DE10-Lite: hace de insecto, de matriz termica y de IMU. Ocupa el
// lugar del ESP32 y habla con la tarjeta de la mochila (top_biobot_de10lite)
// con el mismo protocolo y la misma velocidad, 9600 baudios:
//
//   esta tarjeta  -- 0xA5, actividad, 64 pixeles (10 veces por segundo) -->  mochila
//   esta tarjeta  <-- 0x5A, estado y estimulo, pixeles calientes, cuenta --  mochila
//
// Cuando la respuesta dice que hubo un estimulo, el insecto de prueba
// reacciona, y el cuadro siguiente ya lo refleja: el lazo se cierra entre
// las dos tarjetas.
//
// Cableado entre los conectores JP1 (cruzado, con tierra comun):
//   pin 35 (GPIO_30, UART_TX) de esta tarjeta  ->  pin 37 (GPIO_32, UART_RX) de la mochila
//   pin 37 (GPIO_32, UART_RX) de esta tarjeta  <-  pin 35 (GPIO_30, UART_TX) de la mochila
//   pin 30 (GND)                               --  pin 30 (GND)
//
//   KEY0        reset (reinicia la escena)
//   SW2-SW1     escenario: 00 sin persona, 01 persona, 10 objeto caliente,
//               11 insecto que no responde
//
//   LEDR[2:0]   estimulo recibido: avance, izquierda, derecha (medio segundo)
//   LEDR[3]     el insecto camina
//   LEDR[4]     la mochila reporta mancha de calor
//   LEDR[7:5]   estado que reporta la mochila
//   LEDR[8]     enlace vivo: la mochila esta contestando
//   LEDR[9]     la mochila reporta alerta
//   HEX0        estado que reporta la mochila
//   HEX1        estimulos que el insecto obedecio (ultimo digito hexadecimal)
//   HEX3-HEX2   pixeles calientes que reporta la mochila (hexadecimal)
//   HEX5-HEX4   distancia a la persona en decimetros; "--" si no hay persona
// ============================================================================
module top_insecto_de10lite #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire       CLOCK_50,
    input  wire       RESET_N,        // KEY0, activo en bajo
    input  wire [9:0] SW,
    input  wire       UART_RX,
    output wire       UART_TX,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5
);

localparam integer PERIODO  = CLK_FREQ / 10;          // 10 cuadros por segundo
localparam integer T_HUECO  = CLK_FREQ / 200;         // 5 ms sin bytes abortan una respuesta
localparam integer T_ENLACE = CLK_FREQ / 2;           // 0.5 s sin respuesta: enlace caido
localparam integer T_LED    = CLK_FREQ / 2;           // el LED del estimulo dura 0.5 s
localparam [6:0]   N_BYTES  = 7'd66;                  // encabezado, actividad y 64 pixeles

wire reset = ~RESET_N;

reg [9:0] sw_meta, sw;
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        sw_meta <= 10'd0;
        sw      <= 10'd0;
    end else begin
        sw_meta <= SW;
        sw      <= sw_meta;
    end
end
wire [1:0] escenario = sw[2:1];

// ------------------------------------------------------------ el insecto
reg         tick_insecto;
reg         estimulo;
reg  [1:0]  canal;
wire [5:0]  idx;
wire [7:0]  px_insecto, actividad;
wire [11:0] dist;
wire signed [7:0] rumbo;
wire        anda, hay_mancha;
wire [7:0]  n_obedecidos;

insecto_sim u_insecto (
    .clk(CLOCK_50), .reset(reset), .tick(tick_insecto), .escenario(escenario),
    .estimulo(estimulo), .canal(canal), .idx(idx),
    .px_temp(px_insecto), .actividad(actividad),
    .dist(dist), .rumbo(rumbo), .anda(anda), .hay_mancha(hay_mancha),
    .n_obedecidos(n_obedecidos)
);

// ----------------------------------------------------- envio de cuadros
// Cada periodo avanza el insecto y despues salen los 66 bytes seguidos (la
// mochila descarta una trama que se quede mas de 5 ms sin bytes).
wire       tx_busy;
reg        tx_start;
reg  [7:0] tx_dato;
reg [31:0] cnt_periodo;
reg [6:0]  n_byte;                    // byte que toca: 0 encabezado, 1 actividad, 2..65 pixeles
reg        enviando, lanzado;
reg [1:0]  espera;                    // ciclos para que el insecto termine de avanzar

wire fin_cuenta = (cnt_periodo >= PERIODO - 1);
assign idx = n_byte[5:0] - 6'd2;      // pixel del byte que toca

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        cnt_periodo  <= 32'd0;
        n_byte       <= 7'd0;
        enviando     <= 1'b0;
        lanzado      <= 1'b0;
        espera       <= 2'd0;
        tx_start     <= 1'b0;
        tx_dato      <= 8'd0;
        tick_insecto <= 1'b0;
    end else begin
        tx_start     <= 1'b0;
        tick_insecto <= 1'b0;
        cnt_periodo  <= fin_cuenta ? 32'd0 : cnt_periodo + 32'd1;

        if (!enviando) begin
            if (fin_cuenta) begin
                tick_insecto <= 1'b1;
                enviando     <= 1'b1;
                lanzado      <= 1'b0;
                n_byte       <= 7'd0;
                espera       <= 2'd3;
            end
        end else if (espera != 2'd0) begin
            espera <= espera - 2'd1;
        end else if (!lanzado) begin
            if (!tx_busy) begin
                tx_dato  <= (n_byte == 7'd0) ? 8'hA5
                          : (n_byte == 7'd1) ? actividad : px_insecto;
                tx_start <= 1'b1;
                lanzado  <= 1'b1;
            end
        end else if (tx_busy) begin
            // el byte ya salio hacia uart_tx: se prepara el siguiente
            lanzado <= 1'b0;
            if (n_byte == N_BYTES - 7'd1) enviando <= 1'b0;
            else                          n_byte   <= n_byte + 7'd1;
        end
    end
end

uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
    .clk(CLOCK_50), .reset(reset), .tx_start(tx_start), .data_in(tx_dato), .tx(UART_TX), .busy(tx_busy)
);

// -------------------------------------------------- respuesta de la mochila
wire [7:0] rx_dato;
wire       rx_valido;

uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
    .clk(CLOCK_50), .reset(reset), .rx(UART_RX), .data_out(rx_dato), .data_valid(rx_valido)
);

reg [1:0]  fase;                      // 0 espera 0x5A; 1, 2 y 3: los tres bytes de datos
reg [31:0] hueco;
reg [31:0] t_enlace;
reg [31:0] t_led;
reg [2:0]  estado_m;                  // lo que reporta la mochila
reg        alerta_m, pre_m;
reg [6:0]  nfil_m;
reg [2:0]  led_canal;

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        fase      <= 2'd0;
        hueco     <= 32'd0;
        t_enlace  <= 32'd0;
        t_led     <= 32'd0;
        estado_m  <= 3'd0;
        alerta_m  <= 1'b0;
        pre_m     <= 1'b0;
        nfil_m    <= 7'd0;
        led_canal <= 3'b000;
        estimulo  <= 1'b0;
        canal     <= 2'b00;
    end else begin
        estimulo <= 1'b0;
        if (t_enlace != 32'd0) t_enlace <= t_enlace - 32'd1;
        if (t_led != 32'd0)    t_led    <= t_led - 32'd1;
        else                   led_canal <= 3'b000;

        if (rx_valido) begin
            hueco <= 32'd0;
            case (fase)
                2'd0: if (rx_dato == 8'h5A) fase <= 2'd1;
                2'd1: begin
                    alerta_m <= rx_dato[7];
                    estado_m <= rx_dato[6:4];
                    if (rx_dato[3]) begin             // hubo un estimulo desde el reporte anterior
                        estimulo  <= 1'b1;
                        canal     <= rx_dato[2:1];
                        t_led     <= T_LED;
                        led_canal <= (rx_dato[2:1] == 2'b01) ? 3'b010
                                   : (rx_dato[2:1] == 2'b10) ? 3'b100 : 3'b001;
                    end
                    fase <= 2'd2;
                end
                2'd2: begin
                    pre_m  <= rx_dato[7];
                    nfil_m <= rx_dato[6:0];
                    fase   <= 2'd3;
                end
                default: begin
                    t_enlace <= T_ENLACE;             // respuesta completa: el enlace vive
                    fase     <= 2'd0;
                end
            endcase
        end else if (fase != 2'd0) begin
            if (hueco < T_HUECO) hueco <= hueco + 32'd1;
            else begin
                hueco <= 32'd0;
                fase  <= 2'd0;
            end
        end
    end
end

// ----------------------------------------------------------------- salidas
wire enlace = (t_enlace != 32'd0);

assign LEDR = {alerta_m & enlace, enlace, estado_m, pre_m & enlace, anda, led_canal};

wire [17:0] dm_x    = dist * 6'd41;                   // dist / 100, en decimetros
wire [5:0]  dm      = dm_x[17:12];
wire [3:0]  decenas = (dm >= 6'd40) ? 4'd4 : (dm >= 6'd30) ? 4'd3 : (dm >= 6'd20) ? 4'd2
                    : (dm >= 6'd10) ? 4'd1 : 4'd0;
wire [5:0]  resto   = dm - {decenas, 3'b000} - {1'b0, decenas, 1'b0};
wire [6:0]  seg4, seg5;

hex7seg u_h0 (.x({1'b0, estado_m}),    .seg(HEX0));
hex7seg u_h1 (.x(n_obedecidos[3:0]),   .seg(HEX1));
hex7seg u_h2 (.x(nfil_m[3:0]),         .seg(HEX2));
hex7seg u_h3 (.x({1'b0, nfil_m[6:4]}), .seg(HEX3));
hex7seg u_h4 (.x(resto[3:0]),          .seg(seg4));
hex7seg u_h5 (.x(decenas),             .seg(seg5));

assign HEX4 = hay_mancha ? seg4 : 7'b0111111;
assign HEX5 = hay_mancha ? seg5 : 7'b0111111;

endmodule
