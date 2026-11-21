# Imprime las rutas mas lentas de un proyecto ya compilado.
# Uso (dentro de la carpeta del proyecto de Quartus): quartus_sta -t ../sim/rutas_lentas.tcl <revision>
set rev [lindex $argv 0]
project_open $rev
create_timing_netlist
read_sdc
update_timing_netlist
report_timing -setup -from_clock CLOCK_50 -to_clock CLOCK_50 -npaths 6 -detail summary -stdout
project_close
