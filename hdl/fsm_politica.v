`timescale 1ns / 1ps

// politica de estimulo
module fsm_politica #(
    parameter T_ESPERA  = 13'd150,
    parameter RETRO_MAX = 2'd3,
    parameter T_REF     = 7'd100,
    parameter T_OBS     = 7'd30,
    parameter T_EST     = 7'd5,
    parameter T_PERD    = 7'd50,
    parameter T_FUGA    = 5'd23,
    parameter LIM       = 16'd3072,
    parameter T_BALIZA  = 6'd50
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        tick,
    input  wire        habilita,
    input  wire        quieto,
    input  wire        pre,
    input  wire        sobre,
    input  wire        confirmado,
    input  wire [1:0]  lado,
    input  wire [15:0] azar,
    output reg  [2:0]  estado,
    output reg         disparo,
    output reg  [1:0]  canal,
    output reg         alerta,
    output reg         baliza,
    output reg  [15:0] cuenta,
    output reg  [15:0] n_est
);

localparam [2:0] REPOSO = 3'd0, EXPLORAR = 3'd1, REACTIVAR = 3'd2, REORIENTAR = 3'd3,
                 ACERCAR = 3'd4, CONFIRMAR = 3'd5, ALERTAR = 3'd6, DESCANSO = 3'd7;

localparam [1:0] C_AVANCE = 2'b00, C_IZQ = 2'b01, C_DER = 2'b10;

reg [12:0] cnt_quieto;
reg [1:0]  retro;
reg [6:0]  t_ref;
reg [6:0]  t_obs;
reg [6:0]  t_perd;
reg [4:0]  div_fuga;
reg [5:0]  cnt_baliza;

// espera
wire [15:0] espera = {3'b000, T_ESPERA} << retro;
wire        espero_suficiente = ({3'b000, cnt_quieto} >= espera);

wire        libre  = (t_ref == 7'd0);
wire        puede  = libre && (cuenta < LIM);

// fuga
wire        toca_fuga = (div_fuga == T_FUGA - 5'd1);
wire [15:0] fuga      = (cuenta[15:8] != 8'd0) ? {8'd0, cuenta[15:8]}
                      : ((cuenta != 16'd0) ? 16'd1 : 16'd0);

// decision
reg       dispara;
reg [1:0] canal_n;
reg [2:0] estado_n;

always @(*) begin
    dispara  = 1'b0;
    canal_n  = canal;
    estado_n = estado;
    case (estado)
        REPOSO: begin
            if (habilita) estado_n = EXPLORAR;
        end
        EXPLORAR: begin
            if (pre)
                estado_n = ACERCAR;
            else if (cuenta >= LIM)
                estado_n = DESCANSO;
            else if (quieto && espero_suficiente && libre) begin
                dispara  = 1'b1;
                canal_n  = C_AVANCE;
                estado_n = REACTIVAR;
            end else if (!quieto && (azar[8:0] == 9'd0) && libre) begin
                dispara  = 1'b1;
                canal_n  = azar[9] ? C_DER : C_IZQ;
                estado_n = REORIENTAR;
            end
        end
        REACTIVAR: begin
            if (!quieto || (t_obs == 7'd0)) estado_n = EXPLORAR;
        end
        REORIENTAR: begin
            if (t_obs == 7'd0) estado_n = EXPLORAR;
        end
        ACERCAR: begin
            if (sobre)
                estado_n = CONFIRMAR;
            else if (!pre && (t_perd == 7'd0))
                estado_n = EXPLORAR;
            else if (pre && puede) begin
                if (quieto) begin
                    dispara = 1'b1;
                    canal_n = C_AVANCE;
                end else if (lado == 2'b01) begin
                    dispara = 1'b1;
                    canal_n = C_IZQ;
                end else if (lado == 2'b10) begin
                    dispara = 1'b1;
                    canal_n = C_DER;
                end
            end
        end
        CONFIRMAR: begin
            if (confirmado)   estado_n = ALERTAR;
            else if (!sobre)  estado_n = ACERCAR;
        end
        ALERTAR: begin
            estado_n = ALERTAR;
        end
        DESCANSO: begin
            if (pre)                estado_n = ACERCAR;
            else if (cuenta < LIM)  estado_n = EXPLORAR;
        end
        default: estado_n = REPOSO;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        estado     <= REPOSO;
        disparo    <= 1'b0;
        canal      <= C_AVANCE;
        alerta     <= 1'b0;
        baliza     <= 1'b0;
        cuenta     <= 16'd0;
        n_est      <= 16'd0;
        cnt_quieto <= 13'd0;
        retro      <= 2'd0;
        t_ref      <= 7'd0;
        t_obs      <= 7'd0;
        t_perd     <= 7'd0;
        div_fuga   <= 5'd0;
        cnt_baliza <= 6'd0;
    end else begin
        disparo <= 1'b0;
        baliza  <= 1'b0;
        if (tick) begin
            estado <= estado_n;
            canal  <= canal_n;
            alerta <= (estado_n == ALERTAR);

            // tiempo quieto
            if (!quieto || ((estado == REACTIVAR) && (t_obs == 7'd0)))
                cnt_quieto <= 13'd0;
            else if (cnt_quieto != 13'h1FFF)
                cnt_quieto <= cnt_quieto + 13'd1;

            // retroceso
            if (estado == REACTIVAR) begin
                if (!quieto)
                    retro <= 2'd0;
                else if ((t_obs == 7'd0) && (retro != RETRO_MAX))
                    retro <= retro + 2'd1;
            end

            // temporizadores
            if (dispara)
                t_ref <= T_REF;
            else if (t_ref != 7'd0)
                t_ref <= t_ref - 7'd1;

            if (dispara)
                t_obs <= (canal_n == C_AVANCE) ? T_OBS : T_EST;
            else if (t_obs != 7'd0)
                t_obs <= t_obs - 7'd1;

            if ((estado != ACERCAR) || pre)
                t_perd <= T_PERD;
            else if (t_perd != 7'd0)
                t_perd <= t_perd - 7'd1;

            // presupuesto
            div_fuga <= toca_fuga ? 5'd0 : div_fuga + 5'd1;
            if (dispara) begin
                disparo <= 1'b1;
                n_est   <= n_est + 16'd1;
                cuenta  <= cuenta - (toca_fuga ? fuga : 16'd0) + 16'd256;
            end else if (toca_fuga)
                cuenta  <= cuenta - fuga;

            // baliza
            if (estado_n == ALERTAR) begin
                if (cnt_baliza == 6'd0) begin
                    baliza     <= 1'b1;
                    cnt_baliza <= T_BALIZA - 6'd1;
                end else
                    cnt_baliza <= cnt_baliza - 6'd1;
            end else
                cnt_baliza <= 6'd0;
        end
    end
end

endmodule
