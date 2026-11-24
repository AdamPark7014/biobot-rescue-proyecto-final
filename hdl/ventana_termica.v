`timescale 1ns / 1ps

// ventana termica
module ventana_termica #(
    parameter COLS      = 8,
    parameter LOG2_PIX  = 6,
    parameter T_MIN     = 8'd112,
    parameter T_MAX     = 8'd152,
    parameter DELTA     = 8'd8,
    parameter COL_IZQ   = 3,
    parameter COL_DER   = 5
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       px_valido,
    input  wire [7:0] px_temp,
    input  wire       px_ultimo,
    output reg  [LOG2_PIX:0] n_cal,
    output reg  [1:0] lado,
    output reg  [7:0] fondo,
    output reg        cuadro
);

reg [LOG2_PIX:0]   cnt_cal;
reg [LOG2_PIX:0]   cnt_izq;
reg [LOG2_PIX:0]   cnt_der;
reg [LOG2_PIX+7:0] suma;
reg [7:0]          col;

// umbral contra el fondo
wire [8:0] umbral_fondo = {1'b0, fondo} + {1'b0, DELTA};
wire       en_ventana   = (px_temp >= T_MIN) && (px_temp <= T_MAX);
wire       sobre_fondo  = ({1'b0, px_temp} >= umbral_fondo);
wire       caliente     = en_ventana && sobre_fondo;

// pixel actual ya sumado
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
        fondo   <= 8'd255;
        cuadro  <= 1'b0;
    end else begin
        cuadro <= 1'b0;
        if (px_valido) begin
            if (px_ultimo) begin
                // cierre del cuadro
                n_cal <= cal_n;
                if (cal_n == 0)
                    lado <= 2'b00;
                else if ((izq_n > der_n) && (izq_n >= cen_n))
                    lado <= 2'b01;
                else if ((der_n > izq_n) && (der_n >= cen_n))
                    lado <= 2'b10;
                else
                    lado <= 2'b00;
                fondo   <= suma_n[LOG2_PIX+7:LOG2_PIX];
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
