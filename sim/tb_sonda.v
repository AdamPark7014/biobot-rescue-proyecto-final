`timescale 1ns / 1ps
module tb_sonda;

localparam CLK  = 400000;
localparam BAUD = 40000;

reg        clk = 1'b0;
reg  [1:0] key_a = 2'b11, key_b = 2'b11, key_r = 2'b11;
reg  [9:0] sw_a = {4'd1, 6'd22};
reg  [9:0] sw_b = {4'd0, 6'd22};
reg  [9:0] sw_r = 10'b0000000001;
wire       a_tx1, a_tx2, b_tx1, b_tx2, r_tx1, r_tx2;
wire       tono_a, tono_b, tono_r;
wire [9:0] led_a, led_b, led_r;
wire [6:0] ha0, ha1, ha2, ha3, ha4, ha5, hb0, hb1, hb2, hb3, hb4, hb5, hr0, hr1, hr2, hr3, hr4, hr5;

top_tri_mochila #(.ROL(1), .CLK_FREQ(CLK), .BAUD_RATE(BAUD)) a (
    .CLOCK_50(clk), .KEY(key_a), .SW(sw_a), .RX1(b_tx2), .RX2(1'b1), .TX1(a_tx1), .TX2(a_tx2), .LEDR(led_a),
    .HEX0(ha0), .HEX1(ha1), .HEX2(ha2), .HEX3(ha3), .HEX4(ha4), .HEX5(ha5), .TONO(tono_a));
top_tri_mochila #(.ROL(2), .CLK_FREQ(CLK), .BAUD_RATE(BAUD)) b (
    .CLOCK_50(clk), .KEY(key_b), .SW(sw_b), .RX1(a_tx2), .RX2(1'b1), .TX1(b_tx1), .TX2(b_tx2), .LEDR(led_b),
    .HEX0(hb0), .HEX1(hb1), .HEX2(hb2), .HEX3(hb3), .HEX4(hb4), .HEX5(hb5), .TONO(tono_b));
top_tri_receptor #(.CLK_FREQ(CLK), .BAUD_RATE(BAUD)) r (
    .CLOCK_50(clk), .KEY(key_r), .SW(sw_r), .RX1(a_tx1), .RX2(b_tx1), .TX1(r_tx1), .TX2(r_tx2), .LEDR(led_r),
    .HEX0(hr0), .HEX1(hr1), .HEX2(hr2), .HEX3(hr3), .HEX4(hr4), .HEX5(hr5), .TONO(tono_r));

always #5 clk = ~clk;

task espera_decimas;
    input integer d;
    begin
        repeat (d * (CLK / 10)) @(posedge clk);
    end
endtask

integer    f, g, leidos, tipo, paso, dato, pasos;
reg [35:0] valor;

initial begin
    pasos = 0;
    f = $fopen("fuentes_sonda.txt", "r");
    g = $fopen("sondas.txt", "w");
    if (f == 0 || g == 0) begin
        $display("ERROR tb_sonda: falta fuentes_sonda.txt (correr antes prueba_terminal.tcl genera)");
        $finish;
    end
    // encendido
    key_a[0] = 1'b0; key_b[0] = 1'b0; key_r[0] = 1'b0;
    repeat (20) @(posedge clk);
    key_a[0] = 1'b1; key_b[0] = 1'b1; key_r[0] = 1'b1;

    leidos = $fscanf(f, "%d %d %d %b", tipo, paso, dato, valor);
    while (leidos == 4) begin
        if (tipo == 0) begin
            // orden de la terminal
            case (dato)
                1:       a.u_sonda.valor = valor;
                2:       b.u_sonda.valor = valor;
                default: r.u_sonda.valor = valor[12:0];
            endcase
            repeat ((CLK * 15) / 100) @(posedge clk);
        end else begin
            espera_decimas(dato);
            $fdisplay(g, "%0d %b %b %b %b", paso, a.sonda, b.sonda, r.sonda, {hr5, hr4, hr3, hr2, hr1, hr0});
            pasos = pasos + 1;
        end
        leidos = $fscanf(f, "%d %d %d %b", tipo, paso, dato, valor);
    end
    $fclose(f);
    $fclose(g);
    $display("RESULTADO tb_sonda: %0d pasos simulados, sondas en sondas.txt", pasos);
    $finish;
end

endmodule
