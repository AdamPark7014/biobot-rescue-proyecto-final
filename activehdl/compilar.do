# Compila el nucleo, el insecto de prueba, las tarjetas y dos bancos de prueba
# (Verilog-2005). Se llama desde crear_workspace.do; tambien sirve solo para
# recompilar.

set PF "C:/Users/adpoz/OneDrive/Documentos/Universidad/2026-Semestre-5/11-Lab-Sistemas-Embebidos-CN113/Entregas/Proyecto-Final-Biobots-Rescate"

alog -v2k5 -dbg "$PF/hdl/uart_rx.v"
alog -v2k5 -dbg "$PF/hdl/uart_tx.v"
alog -v2k5 -dbg "$PF/hdl/ventana_termica.v"
alog -v2k5 -dbg "$PF/hdl/detectores.v"
alog -v2k5 -dbg "$PF/hdl/fsm_politica.v"
alog -v2k5 -dbg "$PF/hdl/gen_estimulo.v"
alog -v2k5 -dbg "$PF/hdl/nucleo_biobot.v"
alog -v2k5 -dbg "$PF/hdl/enlace_serie.v"
alog -v2k5 -dbg "$PF/hdl/insecto_sim.v"
alog -v2k5 -dbg "$PF/hdl/top_biobot_de10lite.v"
alog -v2k5 -dbg "$PF/hdl/top_demo_de10lite.v"
alog -v2k5 -dbg "$PF/hdl/top_insecto_de10lite.v"
alog -v2k5 -dbg "$PF/sim/tb_demo.v"
alog -v2k5 -dbg "$PF/sim/tb_dos_tarjetas.v"

# Red de deteccion y triangulacion con tres FPGA: CORDIC, divisor, detector de tonos,
# mochilas y receptor
alog -v2k5 -dbg "$PF/hdl/cordic.v"
alog -v2k5 -dbg "$PF/hdl/tonos.v"
alog -v2k5 -dbg "$PF/hdl/tri_red.v"
alog -v2k5 -dbg "$PF/sim/tb_cordic.v"
alog -v2k5 -dbg "$PF/sim/tb_tonos.v"
alog -v2k5 -dbg "$PF/sim/tb_tri.v"
