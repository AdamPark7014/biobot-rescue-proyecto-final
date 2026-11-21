# Prueba de cada mochila por separado, sin cables entre tarjetas: comprueba en la FPGA real
# el sensor termico simulado (35 a 38 C), el rechazo del objeto caliente, el boton y el
# detector de tonos (el tono del receptor llega si la mochila esta a menos de 32 m).
# Uso: quartus_stp -t sim/prueba_sin_cables.tcl
source [file join [file dirname [info script]] .. pc tri_lib.tcl]
puts "Tarjetas:"
encuentra_tarjetas
fuente_inicial
set errores 0
proc revisa {nombre cond} {
    global errores
    if {$cond} { puts "   correcto: $nombre" } else { puts "   INCORRECTO: $nombre"; incr errores }
}
proc prepara {r temp x y} {
    pon_pos $r $x $y; pon_temp $r $temp
    pon $r 0 1; manda_mochila $r
    after 200
    pon $r 0 0; manda_mochila $r
}
foreach r {1 2} nom {A B} {
    if {![info exists HW($r)]} { puts "mochila $nom: no esta"; continue }
    puts "\n== Mochila $nom"
    foreach {temp espera_alerta} {36 1 47 0 34 0 35 1 38 1 39 0 22 0} {
        prepara $r $temp 25.25 19.00
        after 3000
        array set D [lee_mochila $r]
        puts [format "   sensor %2d C -> termica %s, pixeles calientes %2d, estado %s, conteo %d, rumbo %s" \
            $temp [si_no $D(alerta)] $D(pix) [lindex $ESTADOS $D(estado)] $D(cuenta) \
            [expr {$D(rumbo_ok) ? [format "%.1f grados" $D(rumbo)] : "--"}]]
        revisa "a $temp C [expr {$espera_alerta ? {detecta} : {no detecta}}]" [expr {$D(alerta) == $espera_alerta}]
    }
    prepara $r 22 25.25 19.00
    after 500
    ejecuta_orden "boton $nom"
    after 500
    array set D [lee_mochila $r]
    puts [format "   boton de ayuda -> boton %s" [si_no $D(boton)]]
    revisa "el boton queda marcado" [expr {$D(boton) == 1}]
    foreach {x esperado} {31 1 32 0 10 1 45 0} {
        prepara $r 22 $x 0
        after 1200
        array set D [lee_mochila $r]
        puts [format "   a %2d m del receptor -> oye su tono de 4 kHz: %s (potencia %d), LED %s" $x [si_no $D(oye_rec)] $D(pot_rec) $D(led)]
        revisa "a $x m [expr {$esperado ? {se oye} : {no se oye}}]" [expr {$D(oye_rec) == $esperado}]
    }
}
foreach r {1 2} { if {[info exists HW($r)]} { set F($r) [list 1 0 0 0 0 0 0]; manda_mochila $r; after 200; pon $r 0 0; manda_mochila $r } }
puts ""
if {$errores == 0} { puts "RESULTADO: CORRECTO. Cada mochila detecta sola como en la simulacion." } else { puts "RESULTADO: $errores comprobaciones no coinciden." }
