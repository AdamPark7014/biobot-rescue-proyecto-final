`timescale 1ns / 1ps
// ============================================================================
// altsource_probe_sim.v
// Proyecto final - Sistemas Embebidos (CN113) - BioBot-Rescue
//
// Modelo de simulacion de la sonda de Quartus (In-System Sources and Probes).
// En la tarjeta, altsource_probe es un bloque de Intel que se lee y se escribe
// por el cable USB-Blaster. Aqui solo guarda la fuente en un registro: el banco
// de pruebas escribe en "valor" lo que mandaria la terminal y lee "probe"
// directamente. Sirve para simular los modulos superiores (hdl/tri_top.v) tal
// como se sintetizan. No se sintetiza.
// ============================================================================
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
