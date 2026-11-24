# esquinas y condiciones
set lib $::env(LIBS)
foreach {esq nombre} {tt tt_025C_1v80 ss ss_100C_1v60 ff ff_n40C_1v95} {
    foreach m {omision espera cuadro estimulo} {
        read_liberty $lib/sky130_fd_sc_hd__$nombre.lib
        read_verilog /run/final/nl/nucleo_biobot.nl.v
        link_design nucleo_biobot
        read_sdc /run/final/sdc/nucleo_biobot.sdc
        read_spef /run/final/spef/nom/nucleo_biobot.nom.spef
        if {$m ne "omision"} { read_vcd -scope tb_potencia/dut /pot/$m.vcd }
        puts "== $esq $m"
        report_power -digits 6
        puts "== fin"
    }
}
exit
