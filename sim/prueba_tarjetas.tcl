set escenario [expr {[llength $argv] > 0 ? [lindex $argv 0] : 1}]
set duracion  [expr {[llength $argv] > 1 ? [lindex $argv 1] : 100}]

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

set cables [get_hardware_names]
if {[llength $cables] < 2} {
    puts "ERROR: se ven [llength $cables] cables USB-Blaster y hacen falta 2: $cables"
    exit 1
}
set hw_m [lindex $cables 0]
set hw_i [lindex $cables 1]
set dev_m [lindex [get_device_names -hardware_name $hw_m] 0]
set dev_i [lindex [get_device_names -hardware_name $hw_i] 0]
puts "mochila: $hw_m   insecto: $hw_i"

proc escribe {hw dev valor} {
    start_insystem_source_probe -hardware_name $hw -device_name $dev
    write_source_data -instance_index 0 -value $valor
    end_insystem_source_probe
}
proc lee {hw dev} {
    start_insystem_source_probe -hardware_name $hw -device_name $dev
    set v [read_probe_data -instance_index 0]
    end_insystem_source_probe
    return $v
}
proc bit {v n}      { return [string index $v [expr {[string length $v] - 1 - $n}]] }
proc campo {v hi lo} { return [string range $v [expr {[string length $v] - 1 - $hi}] [expr {[string length $v] - 1 - $lo}]] }
proc a_entero {b}   { scan $b %b n; return $n }

# reset de las dos
set esc_bits [format %02b $escenario]
escribe $hw_m $dev_m 10000000
escribe $hw_i $dev_i 10000000
after 200
escribe $hw_i $dev_i "00000${esc_bits}0"
escribe $hw_m $dev_m 00000001
puts "escenario $escenario; mision en marcha"
puts "   t   | mochila: estado      px  cuenta alerta | insecto: enlace  estado visto  dist  camina  obedecidos"

set t0 [clock milliseconds]
set alerta_en -1
set enlace_visto 0
set estados_vistos {}
set px_max 0
while {1} {
    set t [expr {([clock milliseconds] - $t0) / 1000.0}]
    set m [lee $hw_m $dev_m]
    set i [lee $hw_i $dev_i]

    # mochila
    set m_alerta [bit $m 9]
    set m_estado [a_entero [campo $m 7 5]]
    set m_px     "[digito [campo $m 37 31]][digito [campo $m 30 24]]"
    set m_cuenta [digito [campo $m 23 17]]
    # insecto
    set i_alerta [bit $i 9]
    set i_enlace [bit $i 8]
    set i_estado [a_entero [campo $i 7 5]]
    set i_anda   [bit $i 3]
    set i_dist   "[digito [campo $i 51 45]][digito [campo $i 44 38]]"
    set i_obed   [digito [campo $i 23 17]]

    if {$i_enlace} { set enlace_visto 1 }
    if {[lsearch $estados_vistos $m_estado] < 0} { lappend estados_vistos $m_estado }
    if {[scan $m_px %x px] == 1 && $px > $px_max} { set px_max $px }
    if {$m_alerta && $alerta_en < 0} { set alerta_en $t }

    puts [format "%6.1f | %-11s (%d)   %s    %s      %s    |          %s       %-11s   %s dm   %s      %s" \
        $t [lindex $NOMBRE $m_estado] $m_estado $m_px $m_cuenta $m_alerta \
        $i_enlace [lindex $NOMBRE $i_estado] $i_dist $i_anda $i_obed]

    if {$alerta_en >= 0 && $t > $alerta_en + 4} { break }
    if {$t >= $duracion} { break }
    after 2000
}

puts ""
puts "MEDIDA estados vistos en la mochila: [lsort $estados_vistos]; maximo de pixeles calientes (hex a decimal): $px_max"
if {!$enlace_visto} {
    puts "RESULTADO: SIN ENLACE. Las tarjetas no se hablan: revisar los tres cables de JP1 (35 -> 37, 37 <- 35, 30 -- 30)."
} elseif {$escenario == 1} {
    if {$alerta_en >= 0} {
        puts [format "RESULTADO: CORRECTO. La mochila llego a ALERTAR a los %.0f s y la tarjeta insecto lo recibio." $alerta_en]
    } else {
        puts "RESULTADO: no hubo alerta en $duracion s."
    }
} else {
    if {$alerta_en >= 0} {
        puts "RESULTADO: INCORRECTO. Hubo alerta en un escenario sin persona."
    } else {
        puts "RESULTADO: CORRECTO. Enlace vivo y sin alerta en $duracion s, como debe ser en este escenario."
    }
}
