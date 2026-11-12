`timescale 1ns / 1ps
// ============================================================================
// uart_rx.v
// Practica 4 - Sistemas Embebidos (CN113)
// Receptor UART 8N1: 8 bits de datos, sin paridad, 1 bit de paro.
//
// La linea RX vale 1 cuando nadie transmite (reposo). Una trama empieza con
// el bit de inicio (0), siguen los 8 bits de datos empezando por el menos
// significativo (LSB) y termina con el bit de paro (1).
//
// Cada bit dura CLKS_PER_BIT ciclos de reloj:
//     50 000 000 / 9600 = 5208 ciclos = 104.16 us por bit
//
// El receptor detecta el flanco de bajada del bit de inicio, espera medio bit
// para colocarse en el centro del bit de inicio y desde ahi cuenta bits
// completos, asi cada bit de datos se lee justo en su centro, que es el punto
// mas alejado de los cambios de nivel.
//
// Diferencias con el listado de la guia:
//  1. En la guia la primera muestra (a medio bit) se guardaba en rx_shift[0],
//     pero en ese instante la linea todavia esta en el bit de inicio. El byte
//     quedaba recorrido un lugar (se recibia el doble del dato: 10 -> 20) y
//     el bit 7 se perdia. Aqui la primera muestra solo confirma el bit de
//     inicio (bit_index = 0) y los datos se guardan con bit_index = 1..8.
//  2. El byte se entrega en el centro del bit de paro (linea en 1). En la
//     guia se entregaba en el centro del bit 7; si ese bit era 0, el receptor
//     veia un 0 en reposo y arrancaba una trama falsa.
//  3. RX pasa por un sincronizador de dos flip-flops porque la senal llega
//     del ESP32, que no comparte el reloj de la FPGA.
// ============================================================================
module uart_rx #(
    parameter CLK_FREQ  = 50000000,   // frecuencia del reloj (Hz)
    parameter BAUD_RATE = 9600        // velocidad de la linea (baudios)
)(
    input  wire       clk,            // reloj de 50 MHz de la tarjeta
    input  wire       reset,          // reset asincrono, activo en alto
    input  wire       rx,             // linea serial que llega del ESP32
    output reg  [7:0] data_out,       // ultimo byte recibido
    output reg        data_valid      // pulso de un ciclo: hay un byte nuevo
);

// Ciclos de reloj que dura un bit y medio bit
localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;   // 5208
localparam integer HALF_BIT     = CLKS_PER_BIT / 2;       // 2604

reg        rx_meta;      // primera etapa del sincronizador
reg        rx_sync;      // RX ya sincronizado con clk (es el que se usa)
reg [15:0] clk_count;    // cuenta ciclos dentro del bit actual
reg [3:0]  bit_index;    // 0 = inicio, 1..8 = datos, 9 = paro
reg [7:0]  rx_shift;     // aqui se arma el byte bit por bit
reg        receiving;    // 1 mientras hay una trama en curso

// ----------------------------------------------------------------------------
// Sincronizador de dos flip-flops. Si RX cambia muy cerca del flanco del
// reloj, el primer flip-flop puede quedar un instante en un nivel intermedio
// (metaestabilidad); el segundo le da un ciclo completo para estabilizarse.
// En reset ambos valen 1, que es el nivel de reposo de la linea.
// ----------------------------------------------------------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_meta <= 1'b1;
        rx_sync <= 1'b1;
    end else begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end
end

// ----------------------------------------------------------------------------
// Maquina de recepcion
// ----------------------------------------------------------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_count  <= 0;
        bit_index  <= 0;
        rx_shift   <= 0;
        receiving  <= 1'b0;
        data_out   <= 8'd0;
        data_valid <= 1'b0;
    end else begin
        // data_valid dura un solo ciclo: por defecto vuelve a 0
        data_valid <= 1'b0;

        if (!receiving) begin
            // Reposo: se espera el flanco de bajada del bit de inicio
            if (rx_sync == 1'b0) begin
                receiving <= 1'b1;
                clk_count <= HALF_BIT;   // la primera espera es de medio bit
                bit_index <= 0;
            end
        end else begin
            if (clk_count < CLKS_PER_BIT - 1) begin
                // Todavia no se llega al centro del bit
                clk_count <= clk_count + 1;
            end else begin
                // Centro de un bit: se reinicia la cuenta para el siguiente
                clk_count <= 0;

                if (bit_index == 0) begin
                    // Centro del bit de inicio: si la linea sigue en 0 es una
                    // trama real; si ya volvio a 1 fue ruido y se descarta
                    if (rx_sync == 1'b0)
                        bit_index <= 1;
                    else
                        receiving <= 1'b0;
                end else if (bit_index <= 8) begin
                    // Centro de un bit de datos: LSB primero
                    rx_shift[bit_index - 1] <= rx_sync;
                    bit_index <= bit_index + 1;
                end else begin
                    // Centro del bit de paro: el byte esta completo
                    receiving  <= 1'b0;
                    data_out   <= rx_shift;
                    data_valid <= 1'b1;
                end
            end
        end
    end
end

endmodule
