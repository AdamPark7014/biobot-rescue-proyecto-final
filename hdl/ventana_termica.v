`timescale 1ns / 1ps
// ============================================================================
// ventana_termica.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Recibe un cuadro de la matriz termica pixel por pixel y cuenta cuantos
// pixeles "calientes" tiene, en que lado de la imagen estan y cual es la
// temperatura media del cuadro.
//
// Cada pixel llega como un byte sin signo con resolucion de 0.25 grados C
// (el formato de la AMG8833): 112 = 28 C, 152 = 38 C.
//
// Un pixel cuenta como caliente si cumple las dos condiciones:
//   1. Esta en la ventana de temperatura de la piel:  T_MIN <= T <= T_MAX.
//      Es el criterio de Tran-Ngoc et al. (2023): 28 a 38 grados C.
//   2. Esta DELTA por encima del fondo, que es la media del cuadro anterior.
//      Asi un ambiente tibio (30 C) no llena la imagen de pixeles calientes.
//
// Al terminar el cuadro (px_ultimo) entrega durante un ciclo de reloj:
//   n_cal  cuantos pixeles calientes hubo
//   lado   01 = la mancha esta a la izquierda, 10 = a la derecha, 00 = centro
//          o no hay mancha
//   fondo  temperatura media del cuadro (se usa en el cuadro siguiente)
//   cuadro pulso de un ciclo: los datos de arriba son validos
// ============================================================================
module ventana_termica #(
    parameter COLS      = 8,          // columnas de la matriz
    parameter LOG2_PIX  = 6,          // log2 del numero de pixeles (64 -> 6)
    parameter T_MIN     = 8'd112,     // 28.00 C
    parameter T_MAX     = 8'd152,     // 38.00 C
    parameter DELTA     = 8'd8,       // 2.00 C sobre el fondo
    parameter COL_IZQ   = 3,          // columnas 0 .. COL_IZQ-1 son "izquierda"
    parameter COL_DER   = 5           // columnas COL_DER .. COLS-1 son "derecha"
)(
    input  wire       clk,
    input  wire       reset,          // asincrono, activo en alto
    input  wire       px_valido,      // pulso de un ciclo: hay un pixel nuevo
    input  wire [7:0] px_temp,        // temperatura del pixel, 0.25 C por cuenta
    input  wire       px_ultimo,      // acompana al ultimo pixel del cuadro
    output reg  [LOG2_PIX:0] n_cal,   // pixeles calientes del cuadro
    output reg  [1:0] lado,           // 01 izquierda, 10 derecha, 00 centro
    output reg  [7:0] fondo,          // media del cuadro, 0.25 C por cuenta
    output reg        cuadro          // pulso: termino un cuadro
);

reg [LOG2_PIX:0]   cnt_cal;           // calientes en lo que va del cuadro
reg [LOG2_PIX:0]   cnt_izq;           // de esos, cuantos a la izquierda
reg [LOG2_PIX:0]   cnt_der;           // y cuantos a la derecha
reg [LOG2_PIX+7:0] suma;              // suma de temperaturas del cuadro
reg [7:0]          col;               // columna del pixel que llega

// Umbral contra el fondo, saturado para que no se desborde con fondos altos
wire [8:0] umbral_fondo = {1'b0, fondo} + {1'b0, DELTA};
wire       en_ventana   = (px_temp >= T_MIN) && (px_temp <= T_MAX);
wire       sobre_fondo  = ({1'b0, px_temp} >= umbral_fondo);
wire       caliente     = en_ventana && sobre_fondo;

// Valores con el pixel actual ya sumado (hacen falta para cerrar el cuadro
// en el mismo ciclo en que llega el ultimo pixel)
wire [LOG2_PIX:0]   cal_n  = cnt_cal + (caliente ? 1'b1 : 1'b0);
wire [LOG2_PIX:0]   izq_n  = cnt_izq + ((caliente && (col <  COL_IZQ)) ? 1'b1 : 1'b0);
wire [LOG2_PIX:0]   der_n  = cnt_der + ((caliente && (col >= COL_DER)) ? 1'b1 : 1'b0);
wire [LOG2_PIX+7:0] suma_n = suma + px_temp;
wire [LOG2_PIX:0]   cen_n  = cal_n - izq_n - der_n;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        cnt_cal <= 0;
        cnt_izq <= 0;
        cnt_der <= 0;
        suma    <= 0;
        col     <= 0;
        n_cal   <= 0;
        lado    <= 2'b00;
        fondo   <= 8'd255;            // hasta tener un cuadro, nada supera el fondo
        cuadro  <= 1'b0;
    end else begin
        cuadro <= 1'b0;               // por defecto: pulso de un solo ciclo
        if (px_valido) begin
            if (px_ultimo) begin
                // Cierre del cuadro: se publican los resultados
                n_cal <= cal_n;
                if (cal_n == 0)
                    lado <= 2'b00;
                else if ((izq_n > der_n) && (izq_n >= cen_n))
                    lado <= 2'b01;
                else if ((der_n > izq_n) && (der_n >= cen_n))
                    lado <= 2'b10;
                else
                    lado <= 2'b00;
                fondo   <= suma_n[LOG2_PIX+7:LOG2_PIX];   // suma / numero de pixeles
                cuadro  <= 1'b1;
                cnt_cal <= 0;
                cnt_izq <= 0;
                cnt_der <= 0;
                suma    <= 0;
                col     <= 0;
            end else begin
                cnt_cal <= cal_n;
                cnt_izq <= izq_n;
                cnt_der <= der_n;
                suma    <= suma_n;
                col     <= (col == COLS - 1) ? 8'd0 : col + 8'd1;
            end
        end
    end
end

endmodule
