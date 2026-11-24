`timescale 1ns / 1ps

// tope demo
module top_demo_de10lite #(
    parameter CLK_FREQ = 50000000,
    parameter F_EST    = 50,
    parameter N_PULSOS = 25
)(
    input  wire       CLOCK_50,
    input  wire       RESET_N,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [2:0] ESTIMULO
);

localparam integer PERIODO_NORMAL = CLK_FREQ / 10;
localparam integer PERIODO_RAPIDO = CLK_FREQ / 80;

wire reset = ~RESET_N;

// sincronizador
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
wire       habilita  = sw[0];
wire [1:0] escenario = sw[2:1];
wire       rapido    = sw[9];

// reloj de cuadros
reg [31:0] cnt_periodo;
reg [6:0]  paso;
reg        px_valido, px_ultimo;
reg [7:0]  px_temp;
reg        tick_insecto;

wire [31:0] periodo    = rapido ? PERIODO_RAPIDO : PERIODO_NORMAL;
wire        fin_cuenta = (cnt_periodo >= periodo - 32'd1);
wire [5:0]  idx        = paso[5:0] - 6'd1;
wire [7:0]  px_insecto, actividad;

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        cnt_periodo  <= 32'd0;
        paso         <= 7'd0;
        px_valido    <= 1'b0;
        px_ultimo    <= 1'b0;
        px_temp      <= 8'd0;
        tick_insecto <= 1'b0;
    end else begin
        px_valido    <= 1'b0;
        px_ultimo    <= 1'b0;
        tick_insecto <= 1'b0;
        cnt_periodo  <= fin_cuenta ? 32'd0 : cnt_periodo + 32'd1;

        if (paso == 7'd0) begin
            if (fin_cuenta) paso <= 7'd1;
        end else if (paso <= 7'd64) begin
            px_valido <= 1'b1;
            px_temp   <= px_insecto;
            px_ultimo <= (paso == 7'd64);
            paso      <= paso + 7'd1;
        end else if (paso == 7'd80) begin
            tick_insecto <= 1'b1;
            paso         <= 7'd0;
        end else begin
            paso <= paso + 7'd1;
        end
    end
end

wire        tick, disparo, alerta, baliza, quieto, pre;
wire [2:0]  estado;
wire [1:0]  canal;
wire [6:0]  n_fil;
wire [7:0]  fondo;
wire [15:0] cuenta, n_est;
wire [2:0]  fase_a, fase_b, led_on;
wire [11:0] dist;
wire signed [7:0] rumbo;
wire        anda, hay_mancha;
wire [7:0]  n_obedecidos;

insecto_sim u_insecto (
    .clk(CLOCK_50), .reset(reset), .tick(tick_insecto), .escenario(escenario),
    .estimulo(disparo), .canal(canal), .idx(idx),
    .px_temp(px_insecto), .actividad(actividad),
    .dist(dist), .rumbo(rumbo), .anda(anda), .hay_mancha(hay_mancha),
    .n_obedecidos(n_obedecidos)
);

nucleo_biobot #(.CLK_FREQ(CLK_FREQ), .F_EST(F_EST), .N_PULSOS(N_PULSOS)) u_nucleo (
    .clk(CLOCK_50), .reset(reset), .habilita(habilita),
    .px_valido(px_valido), .px_temp(px_temp), .px_ultimo(px_ultimo), .actividad(actividad),
    .fase_a(fase_a), .fase_b(fase_b), .led_on(led_on),
    .tick(tick), .estado(estado), .disparo(disparo), .canal(canal),
    .alerta(alerta), .baliza(baliza), .quieto(quieto), .pre(pre),
    .n_fil(n_fil), .fondo(fondo), .cuenta(cuenta), .n_est(n_est)
);

// salidas
reg latido;
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset)     latido <= 1'b0;
    else if (tick) latido <= ~latido;
end

assign LEDR     = {alerta, latido, estado, pre, quieto, led_on};
assign ESTIMULO = led_on;

// distancia en dm
wire [17:0] dm_x    = dist * 6'd41;
wire [5:0]  dm      = dm_x[17:12];
wire [3:0]  decenas = (dm >= 6'd40) ? 4'd4 : (dm >= 6'd30) ? 4'd3 : (dm >= 6'd20) ? 4'd2
                    : (dm >= 6'd10) ? 4'd1 : 4'd0;
wire [5:0]  resto   = dm - {decenas, 3'b000} - {1'b0, decenas, 1'b0};
wire [6:0]  seg4, seg5;

hex7seg u_h0 (.x({1'b0, estado}),     .seg(HEX0));
hex7seg u_h1 (.x(cuenta[11:8]),       .seg(HEX1));
hex7seg u_h2 (.x(n_fil[3:0]),         .seg(HEX2));
hex7seg u_h3 (.x({1'b0, n_fil[6:4]}), .seg(HEX3));
hex7seg u_h4 (.x(resto[3:0]),         .seg(seg4));
hex7seg u_h5 (.x(decenas),            .seg(seg5));

assign HEX4 = hay_mancha ? seg4 : 7'b0111111;
assign HEX5 = hay_mancha ? seg5 : 7'b0111111;

endmodule
