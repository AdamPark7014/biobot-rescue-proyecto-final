# Prueba automatica de la demostracion en UNA DE10-Lite por el cable USB-Blaster.
# Requiere la version con sonda (quartus_lab_demo) ya cargada.
#
# Uso:
#   quartus_stp -t sim/prueba_una_tarjeta.tcl [cable] [escenario] [rapido] [segundos]
#     cable      0 o 1: cual USB-Blaster (por omision 0)
#     escenario  0 sin persona, 1 persona (por omision), 2 objeto caliente, 3 no responde
#     rapido     1 = ocho veces mas rapido (por omision 1)
#     segundos   cuanto dura la prueba (por omision 40)
#
# Reinicia la tarjeta, pone el escenario, arranca la mision e imprime cada
# segundo lo que muestran sus LED y displays.

set cable     [expr {[llength $argv] > 0 ? [lindex $argv 0] : 0}]
set escenario [expr {[llength $argv] > 1 ? [lindex $argv 1] : 1}]
set rapido    [expr {[llength $argv] > 2 ? [lindex $argv 2] : 1}]
set duracion  [expr {[llength $argv] > 3 ? [lindex $argv 3] : 40}]

array set SEG {
    1000000 0 1111001 1 0100100 2 0110000 3 0011001 4 0010010 5 0000010 6 1111000 7
    0000000 8 0010000 9 0001000 A 0000011 B 1000110 C 0100001 D 0000110 E 0001110 F
    0111111 - 1111111 " "
}
proc digito {bits} {
    global SEG
    if {[info exists SEG($bits)]} { return $SEG($bits) }
    return "?"
}
set NOMBRE {REPOSO EXPLORAR REACTIVAR REORIENTAR ACERCAR CONFIRMAR ALERTAR DESCANSO}

set hw  [lindex [get_hardware_names] $cable]
set dev [lindex [get_device_names -hardware_name $hw] 0]
puts "tarjeta: $hw"

proc escribe {valor} {
    global hw dev
    start_insystem_source_probe -hardware_name $hw -device_name $dev
    write_source_data -instance_index 0 -value $valor
    end_insystem_source_probe
}
proc lee {} {
    global hw dev
    start_insystem_source_probe -hardware_name $hw -device_name $dev
    set v [read_probe_data -instance_index 0]
    end_insystem_source_probe
    return $v
}
proc bit {v n}       { return [string index $v [expr {[string length $v] - 1 - $n}]] }
proc campo {v hi lo} { return [string range $v [expr {[string length $v] - 1 - $hi}] [expr {[string length $v] - 1 - $lo}]] }
proc a_entero {b}    { scan $b %b n; return $n }

# fuente: bit 7 reset, bit 3 rapido, bits 2-1 escenario, bit 0 mision
escribe 10000000
after 200
escribe "0000${rapido}[format %02b $escenario]1"
puts "escenario $escenario, [expr {$rapido ? "rapido (x8)" : "tiempo real"}]; mision en marcha"
puts "   t   | estado           px  cuenta  dist   ve calor  quieto  estimulo  alerta"

set t0 [clock milliseconds]
set alerta_en -1
set estados {}
set px_max 0
set n_est_vistos 0
while {1} {
    set t [expr {([clock milliseconds] - $t0) / 1000.0}]
    set v [lee]
    # sonda: {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR}; LEDR = {alerta, latido, estado[2:0], pre, quieto, led_on[2:0]}
    set alerta [bit $v 9]
    set estado [a_entero [campo $v 7 5]]
    set pre    [bit $v 4]
    set quieto [bit $v 3]
    set led    [campo $v 2 0]
    set px     "[digito [campo $v 37 31]][digito [campo $v 30 24]]"
    set cuenta [digito [campo $v 23 17]]
    set dist   "[digito [campo $v 51 45]][digito [campo $v 44 38]]"
    if {[lsearch $estados $estado] < 0} { lappend estados $estado }
    if {[scan $px %x n] == 1 && $n > $px_max} { set px_max $n }
    if {$led ne "000"} { incr n_est_vistos }
    if {$alerta && $alerta_en < 0} { set alerta_en $t }
    puts [format "%6.1f | %-11s (%d)   %s    %s     %s dm     %s        %s       %s      %s" \
        $t [lindex $NOMBRE $estado] $estado $px $cuenta $dist $pre $quieto $led $alerta]
    if {$alerta_en >= 0 && $t > $alerta_en + 2} { break }
    if {$t >= $duracion} { break }
    after 700
}

puts ""
puts "MEDIDA estados vistos: [lsort $estados]; maximo de pixeles calientes: $px_max; lecturas con un LED de estimulo encendido: $n_est_vistos"
if {$escenario == 1} {
    if {$alerta_en >= 0} {
        puts [format "RESULTADO: CORRECTO. Llego a ALERTAR a los %.1f s." $alerta_en]
    } else {
        puts "RESULTADO: no hubo alerta en $duracion s."
    }
} else {
    if {$alerta_en >= 0} {
        puts "RESULTADO: INCORRECTO. Hubo alerta en un escenario sin persona."
    } else {
        puts "RESULTADO: CORRECTO. Sin alerta en $duracion s, como debe ser en este escenario."
    }
}
