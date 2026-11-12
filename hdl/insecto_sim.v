`timescale 1ns / 1ps
// ============================================================================
// insecto_sim.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Insecto y escena de prueba. Sustituye al insecto vivo, a la matriz termica
// y a la IMU para poder probar el nucleo solo con tarjetas: calcula lo que
// veria la matriz de 8x8 y lo que sentiria la IMU, y reacciona a los
// estimulos que ordena la mochila. No es el modelo cientifico del proyecto
// (ese esta en modelo/biobot_sim.py); es un banco de pruebas en hardware.
//
// Estado del insecto, que avanza una vez por cuadro (entrada tick):
//   dist    distancia a la persona, en mm
//   rumbo   donde queda la persona respecto al frente, en cuartos de columna
//           de la matriz (1 cuarto = 1.875 grados); positivo = a la derecha
//   anda    1 = camina, 0 = esta en una pausa
//
// Reglas (valores redondos, elegidos para que la prueba dure cerca de un
// minuto):
//   - Camina a 3 mm por cuadro (3 cm/s) y a 6 durante 4 s tras un estimulo
//     de avance. Si la persona esta casi al frente se acerca a toda su
//     velocidad; si esta de lado, a la tercera parte; si esta atras, se aleja.
//   - De vez en cuando se detiene de 20 a 33 s.
//   - Obedece 3 de cada 4 estimulos. Un estimulo de giro lo hace girar de 15
//     a 21 grados; el de avance lo pone a caminar. El giro real que produce
//     un pulso de luz no esta medido: este valor solo hace que la escena de
//     prueba converja.
//
// Escenarios (entrada escenario):
//   00  sin persona: el insecto explora; se ven EXPLORAR, REACTIVAR y
//       REORIENTAR
//   01  persona a 1.65 m y a la izquierda: ACERCAR, CONFIRMAR y ALERTAR
//   10  ambiente a 30 C con un objeto a 47.5 C: no debe haber alerta
//   11  insecto que no responde: la espera se duplica y el presupuesto baja
//
// El pixel que se consulta con idx (fila*8 + columna) sale por px_temp en
// el mismo ciclo, en el formato del nucleo: 0.25 grados C por cuenta.
// ============================================================================
module insecto_sim #(
    parameter SEMILLA = 16'h1D2B      // semilla del azar del insecto
)(
    input  wire              clk,
    input  wire              reset,       // asincrono, activo en alto
    input  wire              tick,        // pulso: avanza un cuadro
    input  wire [1:0]        escenario,
    input  wire              estimulo,    // pulso: la mochila ordeno un estimulo
    input  wire [1:0]        canal,       // 00 avance, 01 izquierda, 10 derecha
    input  wire [5:0]        idx,         // pixel consultado
    output wire [7:0]        px_temp,
    output wire [7:0]        actividad,
    output reg  [11:0]       dist,
    output reg  signed [7:0] rumbo,
    output reg               anda,
    output wire              hay_mancha,  // el escenario tiene algo caliente
    output reg  [7:0]        n_obedecidos
);

localparam [1:0] E_VACIO = 2'b00, E_PERSONA = 2'b01, E_OBJETO = 2'b10, E_TERCO = 2'b11;

localparam [11:0] DIST_MIN = 12'd250, DIST_MAX = 12'd3500;
localparam signed [7:0] RUMBO_MAX = 8'sd60;

localparam [7:0] T_AMB_FRESCO = 8'd88;    // 22.0 C
localparam [7:0] T_AMB_TIBIO  = 8'd120;   // 30.0 C
localparam [7:0] T_PIEL       = 8'd132;   // 33.0 C
localparam [7:0] T_OBJETO     = 8'd190;   // 47.5 C

reg [15:0] azar;                      // LFSR de 16 bits, avanza con cada cuadro
reg [8:0]  pausa;                     // cuadros que faltan de la pausa
reg [5:0]  impulso;                   // cuadros que faltan de marcha rapida
reg [2:0]  div8;                      // la deriva del rumbo se aplica cada 8 cuadros
reg [1:0]  esc_prev;

wire azar_bit = azar[15] ^ azar[13] ^ azar[12] ^ azar[10];

assign hay_mancha = (escenario == E_PERSONA) || (escenario == E_OBJETO);

// ---------------------------------------------------------------- la escena
// Radio al cuadrado de la mancha, en cuartos de columna, segun la distancia
// (tramos de 64 mm). Sale de n = A / (d tan 7.5)^2 con A = 0.03 m2: una cara.
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

// Centro del pixel consultado y de la mancha, en cuartos de columna. El
// centro de la columna c esta en 4c + 2; el centro de la imagen, en 16.
wire signed [9:0] px_x = {4'b0000, idx[2:0], 2'b10};
wire signed [9:0] px_y = {4'b0000, idx[5:3], 2'b10};
wire signed [9:0] cx   = 10'sd16 + {{2{rumbo[7]}}, rumbo};
wire signed [9:0] dx   = px_x - cx;
wire signed [9:0] dy   = px_y - 10'sd16;
wire [19:0] dist2 = dx * dx + dy * dy;
wire dentro = hay_mancha && (dist2 <= {10'd0, radio2});

wire [7:0] t_fondo  = (escenario == E_OBJETO) ? T_AMB_TIBIO : T_AMB_FRESCO;
wire [7:0] t_mancha = (escenario == E_OBJETO) ? T_OBJETO    : T_PIEL;
// Un bit de ruido por pixel (0.25 C), distinto en cada cuadro
wire       ruido    = azar[idx[3:0]];

assign px_temp   = (dentro ? t_mancha : t_fondo) + {7'd0, ruido};
assign actividad = anda ? {3'b001, 2'b00, azar[2:0]}      // 32 a 39: camina
                        : {6'd0, azar[1:0]};              // 0 a 3: quieto

// --------------------------------------------------------------- el insecto
wire [7:0] abs_rumbo = rumbo[7] ? (~rumbo + 8'd1) : rumbo;
wire       de_frente = (abs_rumbo <= 8'd8);               // dentro de +-15 grados
wire       de_lado   = (abs_rumbo <= 8'd24);              // dentro de +-45 grados
wire [11:0] paso     = (impulso != 6'd0) ? 12'd6 : 12'd3;

wire signed [8:0] giro    = {5'b00000, 2'b10, azar[5:4]}; // 8 a 11 cuartos de columna
wire signed [8:0] rumbo_e = {rumbo[7], rumbo};
wire signed [8:0] gira_iz = rumbo_e + giro;               // gira a la izquierda: la persona se va a la derecha
wire signed [8:0] gira_de = rumbo_e - giro;
wire              obedece = (azar[11:10] != 2'b00);       // 3 de cada 4

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
            // Cambio de escenario: la escena empieza de nuevo
            condiciones_iniciales(escenario);
            n_obedecidos <= 8'd0;
        end else begin
            if (tick) begin
                azar <= {azar[14:0], azar_bit};
                div8 <= div8 + 3'd1;
                if (escenario == E_TERCO) begin
                    anda <= 1'b0;                          // nunca se mueve
                end else if (anda) begin
                    // avance segun hacia donde mira
                    if (de_frente)
                        dist <= (dist > DIST_MIN + paso) ? dist - paso : DIST_MIN;
                    else if (de_lado)
                        dist <= (dist > DIST_MIN + 12'd1) ? dist - 12'd1 : DIST_MIN;
                    else
                        dist <= (dist < DIST_MAX) ? dist + 12'd1 : DIST_MAX;
                    if (impulso != 6'd0) impulso <= impulso - 6'd1;
                    // deriva lenta del rumbo
                    if (div8 == 3'd7) begin
                        if (azar[1:0] == 2'b00)      rumbo <= acota(rumbo_e + 9'sd1);
                        else if (azar[1:0] == 2'b01) rumbo <= acota(rumbo_e - 9'sd1);
                    end
                    // pausa espontanea: una cada 26 s en promedio
                    if ((impulso == 6'd0) && (azar[14:7] == 8'd0)) begin
                        anda  <= 1'b0;
                        pausa <= 9'd200 + {2'b00, azar[6:0]};
                    end
                end else begin
                    if (pausa != 9'd0) pausa <= pausa - 9'd1;
                    else               anda  <= 1'b1;
                end
            end
            // Un estimulo se atiende en cuanto llega y manda sobre lo anterior
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
