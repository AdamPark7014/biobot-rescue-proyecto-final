`timescale 1ns / 1ps

// generador de pulsos
module gen_estimulo #(
    parameter CLK_FREQ = 50000000,
    parameter F_EST    = 50,
    parameter N_PULSOS = 25
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       disparo,
    input  wire [1:0] canal,
    output reg  [2:0] fase_a,
    output reg  [2:0] fase_b,
    output reg  [2:0] led_on,
    output reg        ocupado
);

localparam integer MEDIO = CLK_FREQ / (2 * F_EST);

reg        activo;
reg [31:0] cnt;
reg [7:0]  pulsos;
reg        mitad;
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
        // salidas registradas
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
                // fin del periodo
                if (pulsos == 8'd1) activo <= 1'b0;
                pulsos <= pulsos - 8'd1;
            end
        end
    end
end

endmodule
