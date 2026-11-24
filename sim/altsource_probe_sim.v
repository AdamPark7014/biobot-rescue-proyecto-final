`timescale 1ns / 1ps

// sonda simulada
module altsource_probe #(
    parameter         sld_auto_instance_index = "YES",
    parameter integer sld_instance_index      = 0,
    parameter         instance_id             = "NONE",
    parameter integer probe_width             = 1,
    parameter integer source_width            = 1,
    parameter         source_initial_value    = "0",
    parameter         enable_metastability    = "NO"
) (
    input  wire [probe_width-1:0]  probe,
    output wire [source_width-1:0] source
);

reg [source_width-1:0] valor = {source_width{1'b0}};
assign source = valor;

endmodule
