# Dice que circuito con sonda tiene cargado cada DE10-Lite conectada.
# Uso:  quartus_stp -t sim/quien_es_quien.tcl
foreach hw [get_hardware_names] {
    set dev [lindex [get_device_names -hardware_name $hw] 0]
    if {[catch {set info [get_insystem_source_probe_instance_info -hardware_name $hw -device_name $dev]} err]} {
        puts "$hw: sin sonda"
    } else {
        puts "$hw: $info"
    }
}
