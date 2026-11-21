# Prueba automatica de la red de deteccion y triangulacion en las DE10-Lite, por los cables
# USB-Blaster. Requiere cargada la red (CARGAR_RED.cmd) y cerrado el monitor en vivo.
#
# Uso:  quartus_stp -t sim/prueba_tri.tcl
#
# Repite en las tarjetas los escenarios de sim/tb_tri.v fijando temperatura y posicion por la
# sonda, imprime el estado completo en cada uno y al final deja las tarjetas en sus interruptores.

source [file join [file dirname [info script]] .. pc tri_lib.tcl]

puts "Tarjetas:"
if {![encuentra_tarjetas]} {
    puts "ERROR: hacen falta la mochila A, la mochila B y el receptor (o el receptor con B adentro)."
    exit 1
}
fuente_inicial

set errores 0
set total 0
proc revisa {nombre cond} {
    global errores total
    incr total
    if {$cond} { puts "   correcto: $nombre" } else { puts "   INCORRECTO: $nombre"; incr errores }
}
# posiciones de la tabla tri_posicion, en metros; la persona esta en (25.50, 19.25)
array set P {0 {25.25 19.00} 1 {25.75 19.00} 2 {25.75 19.50} 5 {40.0 30.0} 7 {4.5 3.0} 15 {60.0 60.0}}
proc escena {ka ta kb tb} {
    global P
    pon_pos 1 {*}$P($ka); pon_temp 1 $ta; manda_mochila 1
    pon_pos 2 {*}$P($kb); pon_temp 2 $tb; manda_mochila 2
    reinicia_todo
}
proc estado {titulo} {
    puts "\n---- $titulo"
    return [muestra_estado]
}
proc lee3 {titulo} {
    uplevel 1 [list lassign [estado $titulo] la lb lr]
    uplevel 1 { array set A $la; array set B $lb; array set R $lr }
}

escena 1 36 0 36
after 4500
lee3 "1 triangulacion: A a 32.00 m (fuera de alcance), B a 31.60 m, las dos a 36 C"
set e [expr {hypot($R(x) - 25.5, $R(y) - 19.25)}]
puts [format "   error de la triangulacion: %.3f m" $e]
revisa "triangula a menos de 10 cm, A llega por el puente y el conteo es 2 en las tres" \
    [expr {$R(modo) == 2 && $e < 0.10 && $R(a_rel) && !$R(a_dir) && $R(b_dir) && $R(cuenta) == 2 && $A(cuenta) == 2 && $B(cuenta) == 2}]
revisa "tonos: el receptor oye a B y no a A; A oye a B y no al receptor" \
    [expr {$R(oye_b) && !$R(oye_a) && $A(oye_otra) && !$A(oye_rec) && $B(oye_otra) && $B(oye_rec)}]
revisa "LED: receptor 0000011111, B 0000011111, A apagados" \
    [expr {$R(led) eq "0000011111" && $B(led) eq "0000011111" && $A(led) eq "0000000000"}]

escena 1 47 0 47
after 4000
lee3 "2 objeto caliente a 47 C"
revisa "sin deteccion con el objeto caliente" [expr {$R(cuenta) == 0 && $A(cuenta) == 0 && $B(cuenta) == 0}]

escena 1 36 7 22
after 4000
lee3 "3 solo A detecta; B cerca de la entrada hace de puente"
revisa "conteo 1 en las tres; B lo sabe por la difusion" [expr {$R(modo) == 1 && $R(cuenta) == 1 && $A(cuenta) == 1 && $B(cuenta) == 1 && $R(a_rel)}]
revisa "LED: A ve a B a 26 m; B ve a A a 26 m y al receptor a 5 m" \
    [expr {[string range $A(led) 0 4] eq "11010" && $B(led) eq "1101000101" && $R(led) eq "0000000101"}]

escena 2 36 0 36
after 4000
lee3 "4 rumbos opuestos"
revisa "detecta rumbos paralelos y promedia" [expr {$R(modo) == 3 && $R(err) == 1}]

escena 1 22 0 22
after 1000
ejecuta_orden "boton B"
after 1500
lee3 "5 se aprieta el boton de ayuda de B"
revisa "el boton cuenta: conteo 1 en las tres" [expr {$R(modo) == 4 && $R(cuenta) == 1 && $A(cuenta) == 1 && $B(cuenta) == 1}]

escena 1 36 5 36
after 4000
lee3 "6 B lejos de la entrada"
revisa "las mochilas se oyen entre si pero no llegan al receptor" \
    [expr {$R(cuenta) == 0 && !$R(a_dir) && !$R(a_rel) && !$R(b_dir) && $A(oye_otra) && $B(oye_otra) && $A(cuenta) == 2}]

escena 1 36 0 36
after 3500
pon_temp 1 25; manda_mochila 1
after 2500
lee3 "7 A sale del intervalo (25 C)"
revisa "el conteo baja a 1 en las tres" [expr {$R(cuenta) == 1 && $A(cuenta) == 1 && $B(cuenta) == 1}]
pon_temp 2 40; manda_mochila 2
after 2500
lee3 "7 B sale del intervalo (40 C)"
revisa "el conteo baja a 0" [expr {$R(cuenta) == 0 && $A(cuenta) == 0 && $B(cuenta) == 0}]

pon_pos 2 60 60; pon_temp 2 22; manda_mochila 2
pon_pos 1 31 0; pon_temp 1 36; manda_mochila 1
reinicia_todo
after 4000
lee3 "9 A sola a 31 m del receptor"
revisa "a 31 m se oye: radio directo, tono y LED 11111" [expr {$R(a_dir) && $R(oye_a) && $R(cuenta) == 1 && $R(led) eq "1111100000"}]
pon_pos 1 32 0; manda_mochila 1
after 2500
lee3 "9 A a 32 m"
revisa "a 32 m ya no se oye" [expr {!$R(a_dir) && !$R(oye_a) && $R(cuenta) == 0 && $R(led) eq "0000000000"}]
puts [format "   enlace: tramas perdidas de A %d, de B %d; descartadas por CRC %d" $R(perd_a) $R(perd_b) $R(malas)]

suelta_todo
puts ""
if {$errores == 0} { puts "RESULTADO: CORRECTO. Las $total comprobaciones salieron como en la simulacion." } else { puts "RESULTADO: $errores de $total comprobaciones no coinciden." }
