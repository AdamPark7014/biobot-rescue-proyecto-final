# Comprueba en las tarjetas que la deteccion termica sigue al sensor: el conteo sube al
# entrar en 35-38 C y baja al salir, en las tres tarjetas. Con el monitor en vivo cerrado
# y sin tocar los botones mientras corre.
# Uso: quartus_stp -t sim/prueba_baja.tcl
source [file join [file dirname [info script]] .. pc tri_lib.tcl]
puts "Tarjetas:"
if {![encuentra_tarjetas]} { puts "ERROR: faltan tarjetas"; exit 1 }
fuente_inicial
set errores 0
proc cuentas_de {} {
    array set A [lee_mochila 1]
    array set B [lee_mochila 2]
    array set R [lee_receptor]
    return [list $A(cuenta) $B(cuenta) $R(cuenta)]
}
proc paso {texto espera esperado} {
    global errores
    after $espera
    set c [cuentas_de]
    set bien [expr {$c eq $esperado}]
    puts [format "%-34s conteo A/B/receptor = %s  %s" $texto [join $c /] [expr {$bien ? "correcto" : "INCORRECTO (se esperaba [join $esperado /])"}]]
    if {!$bien} { incr errores }
}
# las dos junto a la persona y al alcance una de otra; B tambien al alcance del receptor
pon_pos 1 25.75 19.00; pon_temp 1 22; manda_mochila 1
pon_pos 2 25.25 19.00; pon_temp 2 22; manda_mochila 2
reinicia_todo
paso "las dos a 22 C" 2500 {0 0 0}
pon_temp 1 36; manda_mochila 1
paso "A sube a 36 C" 3500 {1 1 1}
pon_temp 2 37; manda_mochila 2
paso "B sube a 37 C" 3500 {2 2 2}
pon_temp 1 30; manda_mochila 1
paso "A baja a 30 C" 2500 {1 1 1}
pon_temp 2 40; manda_mochila 2
paso "B sube a 40 C (fuera del rango)" 2500 {0 0 0}
pon_temp 1 38; manda_mochila 1
paso "A vuelve a 38 C" 3500 {1 1 1}
suelta_todo
puts ""
if {$errores == 0} { puts "RESULTADO: CORRECTO. El conteo sube y baja con el sensor en las tres tarjetas." } else { puts "RESULTADO: $errores pasos no coinciden." }
