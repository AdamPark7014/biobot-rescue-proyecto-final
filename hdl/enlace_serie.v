`timescale 1ns / 1ps
// ============================================================================
// enlace_serie.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Protocolo del enlace entre la tarjeta y el ESP32 (o la PC) en el prototipo.
// En la mochila real estos dos bloques se sustituyen por el lector I2C de la
// matriz termica y por el radio; el nucleo no cambia.
//
//   receptor_trama  arma un cuadro a partir de los bytes que llegan:
//                       0xA5, actividad, pixel 0, pixel 1, ... pixel 63
//                   La actividad va antes que los pixeles para que ya este
//                   estable cuando el ultimo pixel cierra el cuadro.
//   emisor_estado   despues de cada cuadro contesta con cuatro bytes:
//                       0x5A
//                       {alerta, estado[2:0], hubo_estimulo, canal[1:0], quieto}
//                       {pre, n_fil[6:0]}
//                       cuenta[15:8]   (estimulos acumulados, parte entera)
// ============================================================================

module receptor_trama #(
    parameter N_PIX   = 64,
    parameter T_HUECO = 250000        // ciclos sin bytes que abortan una trama (5 ms a 50 MHz)
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] dato,           // byte recibido por uart_rx
    input  wire       valido,         // pulso de un ciclo
    output reg        px_valido,
    output reg  [7:0] px_temp,
    output reg        px_ultimo,
    output reg  [7:0] actividad
);

localparam [1:0] ESPERA = 2'd0, ACT = 2'd1, PIXELES = 2'd2;

reg [1:0]  fase;
reg [7:0]  idx;                       // pixel que se espera
reg [31:0] hueco;                     // ciclos desde el ultimo byte

always @(posedge clk or posedge reset) begin
    if (reset) begin
        fase      <= ESPERA;
        idx       <= 0;
        hueco     <= 0;
        px_valido <= 1'b0;
        px_temp   <= 8'd0;
        px_ultimo <= 1'b0;
        actividad <= 8'd0;
    end else begin
        px_valido <= 1'b0;
        px_ultimo <= 1'b0;
        if (valido) begin
            hueco <= 0;
            case (fase)
                ESPERA: if (dato == 8'hA5) fase <= ACT;
                ACT: begin
                    actividad <= dato;
                    idx       <= 0;
                    fase      <= PIXELES;
                end
                PIXELES: begin
                    px_valido <= 1'b1;
                    px_temp   <= dato;
                    if (idx == N_PIX - 1) begin
                        px_ultimo <= 1'b1;
                        fase      <= ESPERA;
                    end
                    idx <= idx + 8'd1;
                end
                default: fase <= ESPERA;
            endcase
        end else if (fase != ESPERA) begin
            // Una trama a medias que se queda sin bytes se descarta, para
            // volver a sincronizar con el siguiente 0xA5
            if (hueco < T_HUECO)
                hueco <= hueco + 1;
            else begin
                hueco <= 0;
                fase  <= ESPERA;
            end
        end
    end
end

endmodule

// ----------------------------------------------------------------------------
module emisor_estado (
    input  wire        clk,
    input  wire        reset,
    input  wire        tick,          // termino un cuadro
    input  wire        disparo,       // pulso: salio un estimulo
    input  wire [2:0]  estado,
    input  wire [1:0]  canal,
    input  wire        alerta,
    input  wire        quieto,
    input  wire        pre,
    input  wire [6:0]  n_fil,
    input  wire [15:0] cuenta,
    input  wire        tx_busy,       // de uart_tx
    output reg         tx_start,
    output reg  [7:0]  tx_dato
);

reg [2:0] paso;                       // 0 = en espera; 1..4 = byte por enviar
reg [1:0] retardo;                    // ciclos para que el nucleo actualice
reg       hubo;                       // hubo estimulo desde el ultimo reporte
reg       lanzado;                    // se pidio el byte y falta que arranque

always @(posedge clk or posedge reset) begin
    if (reset) begin
        paso     <= 0;
        retardo  <= 0;
        hubo     <= 1'b0;
        lanzado  <= 1'b0;
        tx_start <= 1'b0;
        tx_dato  <= 8'd0;
    end else begin
        tx_start <= 1'b0;
        if (disparo) hubo <= 1'b1;

        if (paso == 0) begin
            if (tick) begin
                paso    <= 3'd1;
                retardo <= 2'd3;      // el estado nuevo aparece un ciclo despues del tick
                lanzado <= 1'b0;
            end
        end else if (retardo != 0) begin
            retardo <= retardo - 2'd1;
        end else if (!lanzado) begin
            if (!tx_busy) begin
                case (paso)
                    3'd1: tx_dato <= 8'h5A;
                    3'd2: begin
                        tx_dato <= {alerta, estado, hubo, canal, quieto};
                        hubo    <= disparo;       // se reinicia sin perder uno simultaneo
                    end
                    3'd3: tx_dato <= {pre, n_fil};
                    default: tx_dato <= cuenta[15:8];
                endcase
                tx_start <= 1'b1;
                lanzado  <= 1'b1;
            end
        end else if (tx_busy) begin
            // el byte ya salio hacia uart_tx: se prepara el siguiente
            lanzado <= 1'b0;
            paso    <= (paso == 3'd4) ? 3'd0 : paso + 3'd1;
        end
    end
end

endmodule
