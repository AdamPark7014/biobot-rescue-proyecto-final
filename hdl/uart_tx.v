`timescale 1ns / 1ps
// ============================================================================
// uart_tx.v
// Practica 4 - Sistemas Embebidos (CN113)
// Transmisor UART 8N1: 8 bits de datos, sin paridad, 1 bit de paro.
//
// Cuando llega un pulso en tx_start, el modulo arma la trama completa de
// 10 bits en un registro de corrimiento:
//
//     tx_shift = { paro(1), dato[7:0], inicio(0) }
//
// y la saca por la linea TX empezando por el bit 0 (el bit de inicio), luego
// el LSB del dato, y asi hasta el bit de paro. Cada bit se mantiene
// CLKS_PER_BIT ciclos de reloj (5208 ciclos a 50 MHz y 9600 baudios).
// Mientras transmite, busy vale 1 y se ignoran nuevas peticiones.
//
// Este modulo es el mismo de la guia; solo se le agregaron comentarios.
// ============================================================================
module uart_tx #(
    parameter CLK_FREQ  = 50000000,   // frecuencia del reloj (Hz)
    parameter BAUD_RATE = 9600        // velocidad de la linea (baudios)
)(
    input  wire       clk,            // reloj de 50 MHz de la tarjeta
    input  wire       reset,          // reset asincrono, activo en alto
    input  wire       tx_start,       // pulso de un ciclo: enviar data_in
    input  wire [7:0] data_in,        // byte a transmitir
    output reg        tx,             // linea serial que va al ESP32
    output reg        busy            // 1 mientras se transmite una trama
);

// Ciclos de reloj que dura cada bit en la linea
localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;   // 5208

reg [15:0] clk_count;   // cuenta ciclos dentro del bit actual
reg [3:0]  bit_index;   // bit que se esta enviando: 0 inicio ... 9 paro
reg [9:0]  tx_shift;    // trama completa; el bit 0 es el que sale por tx

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx        <= 1'b1;             // la linea en reposo vale 1
        busy      <= 1'b0;
        clk_count <= 0;
        bit_index <= 0;
        tx_shift  <= 10'b1111111111;
    end else begin
        if (!busy) begin
            // Reposo: linea en 1 hasta que llegue una peticion
            tx <= 1'b1;
            if (tx_start) begin
                busy      <= 1'b1;
                tx_shift  <= {1'b1, data_in, 1'b0};   // paro, dato, inicio
                clk_count <= 0;
                bit_index <= 0;
            end
        end else begin
            // Transmitiendo: el bit 0 del registro es el que esta en la linea
            tx <= tx_shift[0];
            if (clk_count < CLKS_PER_BIT - 1) begin
                // El bit actual todavia no cumple su duracion
                clk_count <= clk_count + 1;
            end else begin
                // Se cumplio un bit: se recorre la trama a la derecha
                // (entra un 1 por la izquierda) y se pasa al siguiente bit
                clk_count <= 0;
                tx_shift  <= {1'b1, tx_shift[9:1]};
                if (bit_index < 9)
                    bit_index <= bit_index + 1;
                else begin
                    // Ya salio el bit de paro: termina la trama
                    busy <= 1'b0;
                    tx   <= 1'b1;
                end
            end
        end
    end
end

endmodule
