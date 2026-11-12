# Lectura rapida de la mochila (USB-0) con las dos tarjetas unidas, escenario persona:
# imprime cada cambio de estado, pixeles o alerta, para ver que cuenta justo antes de alertar.
array set SEG {
    1000000 0 1111001 1 0100100 2 0110000 3 0011001 4 0010010 5 0000010 6 1111000 7
    0000000 8 0010000 9 0001000 A 0000011 B 1000110 C 0100001 D 0000110 E 0001110 F
    0111111 - 1111111 " "
}
proc digito {bits} { global SEG; if {[info exists SEG($bits)]} { return $SEG($bits) }; return "?" }
proc bit {v n}       { return [string index $v [expr {[string length $v] - 1 - $n}]] }
proc campo {v hi lo} { return [string range $v [expr {[string length $v] - 1 - $hi}] [expr {[string length $v] - 1 - $lo}]] }
proc a_entero {b}    { scan $b %b n; return $n }

set cables [get_hardware_names]
set hw_m [lindex $cables 0]
set hw_i [lindex $cables 1]
set dev_m [lindex [get_device_names -hardware_name $hw_m] 0]
set dev_i [lindex [get_device_names -hardware_name $hw_i] 0]
proc escribe {hw dev valor} {
    start_insystem_source_probe -hardware_name $hw -device_name $dev
    write_source_data -instance_index 0 -value $valor
    end_insystem_source_probe
}
escribe $hw_m $dev_m 10000000
escribe $hw_i $dev_i 10000000
after 200
escribe $hw_i $dev_i 00000010
start_insystem_source_probe -hardware_name $hw_m -device_name $dev_m
write_source_data -instance_index 0 -value 00000001
set t0 [clock milliseconds]
set previo ""
set lecturas 0
set alerta_en -1
while {1} {
    set t [expr {([clock milliseconds] - $t0) / 1000.0}]
    set m [read_probe_data -instance_index 0]
    incr lecturas
    set actual "estado [a_entero [campo $m 7 5]] px [digito [campo $m 37 31]][digito [campo $m 30 24]] alerta [bit $m 9]"
    if {$actual ne $previo} { puts [format "%6.2f s  %s" $t $actual]; set previo $actual }
    if {[bit $m 9] && $alerta_en < 0} { set alerta_en $t }
    if {$alerta_en >= 0 && $t > $alerta_en + 6} { break }
    if {$t > 90} { break }
}
end_insystem_source_probe
puts "LECTURAS $lecturas en [format %.1f $t] s; alerta a los $alerta_en s"
