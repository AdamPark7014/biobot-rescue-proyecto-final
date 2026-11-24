foreach hw [get_hardware_names] {
    set dev [lindex [get_device_names -hardware_name $hw] 0]
    if {[catch {set info [get_insystem_source_probe_instance_info -hardware_name $hw -device_name $dev]} err]} {
        puts "$hw: sin sonda"
    } else {
        puts "$hw: $info"
    }
}
