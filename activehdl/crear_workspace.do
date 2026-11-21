# Crea (una sola vez) el workspace de Active-HDL del proyecto final, agrega
# los modulos y dos bancos de prueba, compila todo y simula la demostracion
# en una tarjeta. Despues basta con abrir activehdl/BioBot_Rescue.aws
#
# Uso en la consola de Active-HDL:
#   do "C:/Users/adpoz/OneDrive/Documentos/Universidad/2026-Semestre-5/11-Lab-Sistemas-Embebidos-CN113/Entregas/Proyecto-Final-Biobots-Rescate/activehdl/crear_workspace.do"

set PF "C:/Users/adpoz/OneDrive/Documentos/Universidad/2026-Semestre-5/11-Lab-Sistemas-Embebidos-CN113/Entregas/Proyecto-Final-Biobots-Rescate"

workspace create "$PF/activehdl/BioBot_Rescue"
design create -a BioBot_Rescue "$PF/activehdl/BioBot_Rescue"

addfile "$PF/hdl/uart_rx.v"
addfile "$PF/hdl/uart_tx.v"
addfile "$PF/hdl/ventana_termica.v"
addfile "$PF/hdl/detectores.v"
addfile "$PF/hdl/fsm_politica.v"
addfile "$PF/hdl/gen_estimulo.v"
addfile "$PF/hdl/nucleo_biobot.v"
addfile "$PF/hdl/enlace_serie.v"
addfile "$PF/hdl/insecto_sim.v"
addfile "$PF/hdl/top_biobot_de10lite.v"
addfile "$PF/hdl/top_demo_de10lite.v"
addfile "$PF/hdl/top_insecto_de10lite.v"
addfile "$PF/sim/tb_demo.v"
addfile "$PF/sim/tb_dos_tarjetas.v"
addfile "$PF/hdl/cordic.v"
addfile "$PF/hdl/tonos.v"
addfile "$PF/hdl/tri_red.v"
addfile "$PF/sim/tb_cordic.v"
addfile "$PF/sim/tb_tonos.v"
addfile "$PF/sim/tb_tri.v"

do "$PF/activehdl/compilar.do"
do "$PF/activehdl/simular_demo.do"
