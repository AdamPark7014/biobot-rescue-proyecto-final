`timescale 1ns / 1ps
// ============================================================================
// gen_estimulo.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Genera el tren de pulsos de un estimulo. Con cada pulso en disparo saca
// N_PULSOS periodos de una onda cuadrada bifasica de F_EST hertz por el canal
// pedido. Valores por omision: 50 Hz, 50 % de ciclo y 0.5 s (25 periodos),
// que es la zona en que coinciden Erickson et al. (2015) y el grupo de Sato.
//
// Cada canal tiene dos salidas en contrafase:
//     fase_a = 1 durante el primer medio periodo
//     fase_b = 1 durante el segundo medio periodo
// Conectadas a los dos electrodos de un par dan una onda bifasica de +-Vdd
// sin componente continua. Para estimulo luminoso basta led_on, que vale 1
// mientras dura el tren.
//
// Canales: 0 = avance (los dos lados), 1 = giro a la izquierda, 2 = giro a
// la derecha. Mientras hay un tren en curso se ignoran nuevos disparos.
// Todas las salidas son registros, para que no tengan transitorios.
// ============================================================================
module gen_estimulo #(
    parameter CLK_FREQ = 50000000,    // frecuencia del reloj (Hz)
    parameter F_EST    = 50,          // frecuencia de la onda (Hz)
    parameter N_PULSOS = 25           // periodos por tren (0.5 s a 50 Hz)
)(
    input  wire       clk,
    input  wire       reset,          // asincrono, activo en alto
    input  wire       disparo,        // pulso de un ciclo
    input  wire [1:0] canal,          // 00 avance, 01 izquierda, 10 derecha
    output reg  [2:0] fase_a,         // primera mitad del periodo, por canal
    output reg  [2:0] fase_b,         // segunda mitad del periodo, por canal
    output reg  [2:0] led_on,         // 1 durante todo el tren, por canal
    output reg        ocupado         // 1 mientras hay un tren en curso
);

localparam integer MEDIO = CLK_FREQ / (2 * F_EST);   // ciclos por medio periodo

reg        activo;                    // hay un tren en curso
reg [31:0] cnt;                       // ciclos dentro del medio periodo
reg [7:0]  pulsos;                    // periodos que faltan
reg        mitad;                     // 0 = primera mitad, 1 = segunda
reg [1:0]  canal_r;

wire [2:0] sel = (canal_r == 2'b01) ? 3'b010 :
                 (canal_r == 2'b10) ? 3'b100 : 3'b001;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        activo  <= 1'b0;
        cnt     <= 0;
        pulsos  <= 0;
        mitad   <= 1'b0;
        canal_r <= 2'b00;
        fase_a  <= 3'b000;
        fase_b  <= 3'b000;
        led_on  <= 3'b000;
        ocupado <= 1'b0;
    end else begin
        // Las salidas son la imagen del estado interno, un ciclo despues
        ocupado <= activo;
        led_on  <= activo ? sel : 3'b000;
        fase_a  <= (activo && !mitad) ? sel : 3'b000;
        fase_b  <= (activo &&  mitad) ? sel : 3'b000;

        if (!activo) begin
            if (disparo) begin
                activo  <= 1'b1;
                canal_r <= canal;
                pulsos  <= N_PULSOS;
                mitad   <= 1'b0;
                cnt     <= 0;
            end
        end else if (cnt < MEDIO - 1)
            cnt <= cnt + 1;
        else begin
            cnt   <= 0;
            mitad <= ~mitad;
            if (mitad) begin
                // termino un periodo completo
                if (pulsos == 8'd1) activo <= 1'b0;
                pulsos <= pulsos - 8'd1;
            end
        end
    end
end

endmodule
