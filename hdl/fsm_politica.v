`timescale 1ns / 1ps
// ============================================================================
// fsm_politica.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Maquina de estados que decide cuando y como estimular al insecto. Avanza
// una vez por cuadro termico (entrada tick, 10 Hz), asi que todos los tiempos
// de abajo estan en decimas de segundo.
//
// Idea general: dejar que el insecto explore solo y estimular lo minimo.
//
//   REPOSO      espera la orden de arranque
//   EXPLORAR    marcha natural; vigila quietud, azar y la mancha de calor
//   REACTIVAR   el insecto llevaba quieto demasiado: pulso de avance y se
//               observa si arranca; si no, la siguiente espera se duplica
//   REORIENTAR  giro al azar para despegarlo de las paredes
//   ACERCAR     hay una mancha de calor: gira hacia ella
//   CONFIRMAR   la mancha es grande: se deja de estimular y se confirma
//   ALERTAR     deteccion confirmada: avisa por radio; estado final
//   DESCANSO    se gasto el presupuesto de estimulos: el insecto descansa
//
// Presupuesto de estimulos: cada estimulo suma 1 a una cuenta con fugas
// (formato Q8.8) que pierde 1/256 de su valor cada T_FUGA ticks. Con
// T_FUGA = 23 la constante de tiempo es de unos 590 s. Mientras la cuenta
// este en LIM o mas, no se estimula. Esto acota la habituacion y la carga
// sobre el animal sin necesidad de medir su respuesta.
// ============================================================================
module fsm_politica #(
    parameter T_ESPERA  = 13'd150,    // 15 s quieto antes del primer estimulo
    parameter RETRO_MAX = 2'd3,       // la espera se duplica hasta 2^3 veces
    parameter T_REF     = 7'd100,     // 10 s minimos entre estimulos
    parameter T_OBS     = 7'd30,      // 3 s para ver si el insecto arranco
    parameter T_EST     = 7'd5,       // 0.5 s que dura el tren de pulsos
    parameter T_PERD    = 7'd50,      // 5 s sin mancha antes de volver a explorar
    parameter T_FUGA    = 5'd23,      // ticks entre fugas de la cuenta
    parameter LIM       = 16'd3072,   // 12.0 estimulos acumulados (Q8.8)
    parameter T_BALIZA  = 6'd50       // 5 s entre avisos en ALERTAR
)(
    input  wire        clk,
    input  wire        reset,         // asincrono, activo en alto
    input  wire        tick,          // pulso de un ciclo por cuadro
    input  wire        habilita,      // 1 = mision en marcha
    input  wire        quieto,        // del detector de quietud
    input  wire        pre,           // mancha pequena a la vista
    input  wire        sobre,         // mancha grande a la vista
    input  wire        confirmado,    // mancha grande N cuadros seguidos
    input  wire [1:0]  lado,          // 01 izquierda, 10 derecha, 00 centro
    input  wire [15:0] azar,          // del LFSR
    output reg  [2:0]  estado,
    output reg         disparo,       // pulso de un ciclo: iniciar un tren
    output reg  [1:0]  canal,         // 00 avance, 01 izquierda, 10 derecha
    output reg         alerta,        // 1 en ALERTAR
    output reg         baliza,        // pulso de un ciclo: mandar aviso
    output reg  [15:0] cuenta,        // presupuesto gastado, Q8.8
    output reg  [15:0] n_est          // total de estimulos aplicados
);

localparam [2:0] REPOSO = 3'd0, EXPLORAR = 3'd1, REACTIVAR = 3'd2, REORIENTAR = 3'd3,
                 ACERCAR = 3'd4, CONFIRMAR = 3'd5, ALERTAR = 3'd6, DESCANSO = 3'd7;

localparam [1:0] C_AVANCE = 2'b00, C_IZQ = 2'b01, C_DER = 2'b10;

reg [12:0] cnt_quieto;                // ticks seguidos con el insecto quieto
reg [1:0]  retro;                     // exponente del retroceso de la espera
reg [6:0]  t_ref;                     // ticks que faltan del periodo refractario
reg [6:0]  t_obs;                     // temporizador de observacion / del tren
reg [6:0]  t_perd;                    // ticks sin mancha en ACERCAR
reg [4:0]  div_fuga;                  // divisor de la fuga
reg [5:0]  cnt_baliza;

// Espera vigente: T_ESPERA * 2^retro
wire [15:0] espera = {3'b000, T_ESPERA} << retro;
wire        espero_suficiente = ({3'b000, cnt_quieto} >= espera);

wire        libre  = (t_ref == 7'd0);                 // paso el refractario
wire        puede  = libre && (cuenta < LIM);         // y queda presupuesto

// Fuga de la cuenta: 1/256 de su valor, y al menos 1 para que llegue a cero
wire        toca_fuga = (div_fuga == T_FUGA - 5'd1);
wire [15:0] fuga      = (cuenta[15:8] != 8'd0) ? {8'd0, cuenta[15:8]}
                      : ((cuenta != 16'd0) ? 16'd1 : 16'd0);

// Decision del tick: se calcula de forma combinacional y se registra abajo
reg       dispara;                    // este tick sale un estimulo
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
        disparo <= 1'b0;              // pulsos de un solo ciclo de reloj
        baliza  <= 1'b0;
        if (tick) begin
            estado <= estado_n;
            canal  <= canal_n;
            alerta <= (estado_n == ALERTAR);

            // --- tiempo quieto (se reinicia tras un intento fallido)
            if (!quieto || ((estado == REACTIVAR) && (t_obs == 7'd0)))
                cnt_quieto <= 13'd0;
            else if (cnt_quieto != 13'h1FFF)
                cnt_quieto <= cnt_quieto + 13'd1;

            // --- retroceso de la espera
            if (estado == REACTIVAR) begin
                if (!quieto)
                    retro <= 2'd0;                              // arranco
                else if ((t_obs == 7'd0) && (retro != RETRO_MAX))
                    retro <= retro + 2'd1;                      // no arranco
            end

            // --- temporizadores
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

            // --- presupuesto de estimulos: fuga y cargo
            div_fuga <= toca_fuga ? 5'd0 : div_fuga + 5'd1;
            if (dispara) begin
                disparo <= 1'b1;
                n_est   <= n_est + 16'd1;
                cuenta  <= cuenta - (toca_fuga ? fuga : 16'd0) + 16'd256;
            end else if (toca_fuga)
                cuenta  <= cuenta - fuga;

            // --- baliza periodica en ALERTAR
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
