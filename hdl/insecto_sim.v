`timescale 1ns / 1ps

// insecto simulado
module insecto_sim #(
    parameter SEMILLA = 16'h1D2B
)(
    input  wire              clk,
    input  wire              reset,
    input  wire              tick,
    input  wire [1:0]        escenario,
    input  wire              estimulo,
    input  wire [1:0]        canal,
    input  wire [5:0]        idx,
    output wire [7:0]        px_temp,
    output wire [7:0]        actividad,
    output reg  [11:0]       dist,
    output reg  signed [7:0] rumbo,
    output reg               anda,
    output wire              hay_mancha,
    output reg  [7:0]        n_obedecidos
);

localparam [1:0] E_VACIO = 2'b00, E_PERSONA = 2'b01, E_OBJETO = 2'b10, E_TERCO = 2'b11;

localparam [11:0] DIST_MIN = 12'd250, DIST_MAX = 12'd3500;
localparam signed [7:0] RUMBO_MAX = 8'sd60;

localparam [7:0] T_AMB_FRESCO = 8'd88;
localparam [7:0] T_AMB_TIBIO  = 8'd120;
localparam [7:0] T_PIEL       = 8'd132;
localparam [7:0] T_OBJETO     = 8'd190;

reg [15:0] azar;
reg [8:0]  pausa;
reg [5:0]  impulso;
reg [2:0]  div8;
reg [1:0]  esc_prev;

wire azar_bit = azar[15] ^ azar[13] ^ azar[12] ^ azar[10];

assign hay_mancha = (escenario == E_PERSONA) || (escenario == E_OBJETO);

// escena
reg [9:0] radio2;
always @(*) begin
    case (dist[11:6])
        6'd0:  radio2 = 10'd1023;  6'd1:  radio2 = 10'd957;  6'd2:  radio2 = 10'd344;
        6'd3:  radio2 = 10'd176;   6'd4:  radio2 = 10'd106;  6'd5:  radio2 = 10'd71;
        6'd6:  radio2 = 10'd51;    6'd7:  radio2 = 10'd38;   6'd8:  radio2 = 10'd30;
        6'd9:  radio2 = 10'd24;    6'd10: radio2 = 10'd20;   6'd11: radio2 = 10'd16;
        6'd12: radio2 = 10'd14;    6'd13: radio2 = 10'd12;   6'd14: radio2 = 10'd10;
        6'd15: radio2 = 10'd9;     6'd16: radio2 = 10'd8;    6'd17: radio2 = 10'd7;
        6'd18: radio2 = 10'd6;     6'd19: radio2 = 10'd6;    6'd20: radio2 = 10'd5;
        6'd21: radio2 = 10'd5;     6'd22: radio2 = 10'd4;    6'd23: radio2 = 10'd4;
        6'd24: radio2 = 10'd4;     6'd25: radio2 = 10'd3;    6'd26: radio2 = 10'd3;
        6'd27: radio2 = 10'd3;     6'd28: radio2 = 10'd3;    6'd29: radio2 = 10'd2;
        6'd30: radio2 = 10'd2;     6'd31: radio2 = 10'd2;    6'd32: radio2 = 10'd2;
        6'd33: radio2 = 10'd2;     6'd34: radio2 = 10'd2;    6'd35: radio2 = 10'd2;
        6'd36: radio2 = 10'd2;     6'd37: radio2 = 10'd2;
        default: radio2 = 10'd1;
    endcase
end

// centro del pixel
wire signed [9:0] px_x = {4'b0000, idx[2:0], 2'b10};
wire signed [9:0] px_y = {4'b0000, idx[5:3], 2'b10};
wire signed [9:0] cx   = 10'sd16 + {{2{rumbo[7]}}, rumbo};
wire signed [9:0] dx   = px_x - cx;
wire signed [9:0] dy   = px_y - 10'sd16;
wire [19:0] dist2 = dx * dx + dy * dy;
wire dentro = hay_mancha && (dist2 <= {10'd0, radio2});

wire [7:0] t_fondo  = (escenario == E_OBJETO) ? T_AMB_TIBIO : T_AMB_FRESCO;
wire [7:0] t_mancha = (escenario == E_OBJETO) ? T_OBJETO    : T_PIEL;
// ruido
wire       ruido    = azar[idx[3:0]];

assign px_temp   = (dentro ? t_mancha : t_fondo) + {7'd0, ruido};
assign actividad = anda ? {3'b001, 2'b00, azar[2:0]}
                        : {6'd0, azar[1:0]};

// insecto
wire [7:0] abs_rumbo = rumbo[7] ? (~rumbo + 8'd1) : rumbo;
wire       de_frente = (abs_rumbo <= 8'd8);
wire       de_lado   = (abs_rumbo <= 8'd24);
wire [11:0] paso     = (impulso != 6'd0) ? 12'd6 : 12'd3;

wire signed [8:0] giro    = {5'b00000, 2'b10, azar[5:4]};
wire signed [8:0] rumbo_e = {rumbo[7], rumbo};
wire signed [8:0] gira_iz = rumbo_e + giro;
wire signed [8:0] gira_de = rumbo_e - giro;
wire              obedece = (azar[11:10] != 2'b00);

function signed [7:0] acota;
    input signed [8:0] v;
    begin
        if (v > 9'sd60)        acota = RUMBO_MAX;
        else if (v < -9'sd60)  acota = -RUMBO_MAX;
        else                   acota = v[7:0];
    end
endfunction

task condiciones_iniciales;
    input [1:0] esc;
    begin
        anda    <= (esc != E_TERCO);
        pausa   <= 9'd0;
        impulso <= 6'd0;
        div8    <= 3'd0;
        case (esc)
            E_PERSONA: begin dist <= 12'd1650; rumbo <= -8'sd10; end
            E_OBJETO:  begin dist <= 12'd700;  rumbo <=  8'sd6;  end
            default:   begin dist <= 12'd3000; rumbo <=  8'sd0;  end
        endcase
    end
endtask

always @(posedge clk or posedge reset) begin
    if (reset) begin
        azar         <= SEMILLA;
        esc_prev     <= E_VACIO;
        n_obedecidos <= 8'd0;
        anda         <= 1'b1;
        pausa        <= 9'd0;
        impulso      <= 6'd0;
        div8         <= 3'd0;
        dist         <= 12'd3000;
        rumbo        <= 8'sd0;
    end else begin
        esc_prev <= escenario;
        if (escenario != esc_prev) begin
            // cambio de escena
            condiciones_iniciales(escenario);
            n_obedecidos <= 8'd0;
        end else begin
            if (tick) begin
                azar <= {azar[14:0], azar_bit};
                div8 <= div8 + 3'd1;
                if (escenario == E_TERCO) begin
                    anda <= 1'b0;
                end else if (anda) begin
                    // avance
                    if (de_frente)
                        dist <= (dist > DIST_MIN + paso) ? dist - paso : DIST_MIN;
                    else if (de_lado)
                        dist <= (dist > DIST_MIN + 12'd1) ? dist - 12'd1 : DIST_MIN;
                    else
                        dist <= (dist < DIST_MAX) ? dist + 12'd1 : DIST_MAX;
                    if (impulso != 6'd0) impulso <= impulso - 6'd1;
                    // deriva
                    if (div8 == 3'd7) begin
                        if (azar[1:0] == 2'b00)      rumbo <= acota(rumbo_e + 9'sd1);
                        else if (azar[1:0] == 2'b01) rumbo <= acota(rumbo_e - 9'sd1);
                    end
                    // pausa
                    if ((impulso == 6'd0) && (azar[14:7] == 8'd0)) begin
                        anda  <= 1'b0;
                        pausa <= 9'd200 + {2'b00, azar[6:0]};
                    end
                end else begin
                    if (pausa != 9'd0) pausa <= pausa - 9'd1;
                    else               anda  <= 1'b1;
                end
            end
            // estimulo
            if (estimulo && (escenario != E_TERCO) && obedece) begin
                n_obedecidos <= n_obedecidos + 8'd1;
                anda  <= 1'b1;
                pausa <= 9'd0;
                case (canal)
                    2'b01:   rumbo   <= acota(gira_iz);
                    2'b10:   rumbo   <= acota(gira_de);
                    default: impulso <= 6'd40;
                endcase
            end
        end
    end
end

endmodule
