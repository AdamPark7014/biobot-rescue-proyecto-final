# Funciones comunes para hablar con las tarjetas de la red de triangulacion por la sonda de
# Quartus (In-System Sources and Probes). Las usan pc/terminal.tcl y los scripts de sim/.
# Formatos de la sonda y de la fuente: ver hdl/tri_top.v.
# Unidades: las tarjetas trabajan en cuentas de 1/16 m (mapa de 0 a 64 m); aqui todo va en metros.

proc bit {v n}       { return [string index $v [expr {[string length $v] - 1 - $n}]] }
proc campo {v hi lo} { return [string range $v [expr {[string length $v] - 1 - $hi}] [expr {[string length $v] - 1 - $lo}]] }
proc a_entero {b}    { scan $b %b n; return $n }
proc m {c}           { return [expr {$c / 16.0}] }
proc cuentas {metros} {
    set c [expr {int(round($metros * 16.0))}]
    if {$c < 0} { set c 0 }
    if {$c > 1023} { set c 1023 }
    return $c
}
set ANCHO_MOCHILA  125
set ANCHO_RECEPTOR 238

# Si un cable USB parpadea (pasa al mover la tarjeta), se reintenta unas veces antes de fallar.
proc con_reintentos {cuerpo} {
    for {set k 0} {$k < 6} {incr k} {
        if {![catch {uplevel 1 $cuerpo} res]} { return $res }
        catch { end_insystem_source_probe }
        after 700
    }
    error "no responde la tarjeta: $res"
}
proc lee {hw dev} {
    return [con_reintentos {
        start_insystem_source_probe -hardware_name $hw -device_name $dev
        set v [read_probe_data -instance_index 0]
        end_insystem_source_probe
        set v
    }]
}
proc escribe {hw dev valor} {
    con_reintentos {
        start_insystem_source_probe -hardware_name $hw -device_name $dev
        write_source_data -instance_index 0 -value $valor
        end_insystem_source_probe
    }
}

# ---- encuentra las tarjetas: 1 = mochila A, 2 = mochila B, 0 = receptor, 3 = receptor con B adentro
proc encuentra_tarjetas {} {
    global HW DEV COMBINADO ANCHO_MOCHILA ANCHO_RECEPTOR
    set COMBINADO 0
    array unset HW
    array unset DEV
    foreach hw [get_hardware_names] {
        set dev [lindex [get_device_names -hardware_name $hw] 0]
        if {[catch {set v [lee $hw $dev]}]} { puts "  $hw: sin la red cargada"; continue }
        set ancho [string length $v]
        if {$ancho == $ANCHO_MOCHILA} {
            set rol [a_entero [campo $v 91 90]]
        } elseif {$ancho == $ANCHO_RECEPTOR} {
            set rol [a_entero [campo $v 95 94]]
        } else {
            puts "  $hw: otra version del circuito ($ancho bits): hay que volver a cargar la red"; continue
        }
        if {$rol == 3} {
            foreach p {0 2} { set HW($p) $hw; set DEV($p) $dev }
            set COMBINADO 1
            puts "  $hw: receptor con la mochila B adentro"
        } else {
            set HW($rol) $hw; set DEV($rol) $dev
            puts "  $hw: [lindex {receptor {mochila A} {mochila B}} $rol]"
        }
    }
    foreach rol {0 1 2} {
        if {![info exists HW($rol)]} { return 0 }
    }
    return 1
}

# ---- estado de la fuente de cada mochila (se conserva entre ordenes)
#      reset boton usar_temp usar_pos x y temp     (x, y en cuentas)
# y de la del receptor: reset usar_vista vista
proc fuente_inicial {} {
    global F
    foreach r {1 2} { set F($r) [list 0 0 0 0 0 0 0] }
    set F(0) [list 0 0 0]
}
proc fuente_mochila {r} {
    global F
    lassign $F($r) rs bt ut up x y t
    return "${rs}${bt}${ut}${up}[format %010b $x][format %010b $y]000000[format %06b $t]"
}
proc manda_mochila {r} {
    global HW DEV
    escribe $HW($r) $DEV($r) [fuente_mochila $r]
}
proc manda_receptor {} {
    global HW DEV F COMBINADO
    if {$COMBINADO} { return }
    lassign $F(0) rs usar vista
    escribe $HW(0) $DEV(0) "${rs}0${usar}[format %010b $vista]"
}
proc pon {r indice valor} {
    global F
    set F($r) [lreplace $F($r) $indice $indice $valor]
}
proc pon_pos {r x_m y_m} { pon $r 3 1; pon $r 4 [cuentas $x_m]; pon $r 5 [cuentas $y_m] }
proc pon_temp {r t}      { pon $r 2 1; pon $r 6 [expr {int($t) & 63}] }
proc reinicia_todo {} {
    foreach r {1 2} { pon $r 0 1; manda_mochila $r }
    pon 0 0 1; manda_receptor
    after 200
    foreach r {1 2} { pon $r 0 0; manda_mochila $r }
    pon 0 0 0; manda_receptor
}
proc suelta_todo {} {
    # deja las tarjetas obedeciendo a sus interruptores y las reinicia
    global F
    foreach r {1 2} { set F($r) [list 1 0 0 0 0 0 0]; manda_mochila $r }
    set F(0) [list 1 0 0]; manda_receptor
    after 200
    foreach r {1 2} { pon $r 0 0; manda_mochila $r }
    pon 0 0 0; manda_receptor
}

# ---- lectura
proc lee_mochila {r} {
    global HW DEV
    set v [lee $HW($r) $DEV($r)]
    set d(oye_otra) [bit $v 124]
    set d(pot_otra) [a_entero [campo $v 123 108]]
    set d(pot_rec)  [a_entero [campo $v 107 92]]
    set d(alerta)   [bit $v 89]
    set d(boton)    [bit $v 88]
    set d(rumbo_ok) [bit $v 87]
    set d(estado)   [a_entero [campo $v 86 84]]
    set d(pix)      [a_entero [campo $v 83 77]]
    set d(rumbo)    [expr {[a_entero [campo $v 76 61]] * 360.0 / 65536}]
    set d(temp)     [a_entero [campo $v 60 55]]
    set d(x)        [m [a_entero [campo $v 54 45]]]
    set d(y)        [m [a_entero [campo $v 44 35]]]
    set d(d_otra)   [m [a_entero [campo $v 34 25]]]
    set d(d_rec)    [m [a_entero [campo $v 24 15]]]
    set d(otra_det) [bit $v 14]
    set d(otra)     [bit $v 13]
    set d(oye_rec)  [bit $v 12]
    set d(cuenta)   [a_entero [campo $v 11 10]]
    set d(led)      [campo $v 9 0]
    return [array get d]
}
# lo que el receptor sabe de una mochila (42 bits que llegaron por radio)
proc interpreta_info {i} {
    set d(x)        [m [a_entero [campo $i 41 32]]]
    set d(y)        [m [a_entero [campo $i 31 22]]]
    set d(temp)     [a_entero [campo $i 21 16]]
    set d(termica)  [bit $i 15]
    set d(boton)    [bit $i 14]
    set d(pre)      [bit $i 13]
    set d(rumbo_ok) [bit $i 12]
    set d(estado)   [a_entero [campo $i 11 9]]
    set d(oye_otra) [bit $i 8]
    set d(oye_rec)  [bit $i 7]
    set d(pix)      [a_entero [campo $i 6 0]]
    return [array get d]
}
proc interpreta_receptor {v} {
    set d(oye_a)  [bit $v 237]
    set d(oye_b)  [bit $v 236]
    set d(pot_a)  [a_entero [campo $v 235 220]]
    set d(pot_b)  [a_entero [campo $v 219 204]]
    set d(info_a) [campo $v 203 162]
    set d(info_b) [campo $v 161 120]
    set d(perd_a) [a_entero [campo $v 119 112]]
    set d(perd_b) [a_entero [campo $v 111 104]]
    set d(malas)  [a_entero [campo $v 103 96]]
    set d(x)      [m [a_entero [campo $v 93 84]]]
    set d(y)      [m [a_entero [campo $v 83 74]]]
    set d(modo)   [a_entero [campo $v 73 71]]
    set d(ev)     [a_entero [campo $v 70 68]]
    set d(err)    [a_entero [campo $v 67 66]]
    set d(tha)    [expr {[a_entero [campo $v 65 56]] * 360.0 / 1024}]
    set d(thb)    [expr {[a_entero [campo $v 55 46]] * 360.0 / 1024}]
    set d(d_ab)   [m [a_entero [campo $v 45 36]]]
    set d(d_a)    [m [a_entero [campo $v 35 26]]]
    set d(d_b)    [m [a_entero [campo $v 25 16]]]
    set d(cuenta) [a_entero [campo $v 15 14]]
    set d(a_dir)  [bit $v 13]
    set d(a_rel)  [bit $v 12]
    set d(b_dir)  [bit $v 11]
    set d(b_rel)  [bit $v 10]
    set d(led)    [campo $v 9 0]
    return [array get d]
}
proc lee_receptor {} {
    global HW DEV
    return [interpreta_receptor [lee $HW(0) $DEV(0)]]
}

set ESTADOS {REPOSO EXPLORAR REACTIVAR REORIENTAR ACERCAR CONFIRMAR ALERTAR DESCANSO}
set MODOS   {{sin aviso} {aproximada (una mochila)} {TRIANGULADA (dos rumbos)} {rumbos sin cruce: promedio} {solo boton: posicion de la mochila}}
proc si_no {b} { return [expr {$b ? "SI" : "no"}] }

# ---- vista del operador: solo lo que sabe el receptor (lo que llego por radio y por tonos)
proc lineas_receptor {v} {
    global ESTADOS MODOS
    array set R [interpreta_receptor $v]
    set L {}
    lappend L "=============== BioBot-Rescue: vista del operador (receptor) ==============="
    lappend L [format "PERSONAS DETECTADAS: %d" $R(cuenta)]
    if {$R(modo) != 0} {
        lappend L [format {Persona estimada en (%.2f, %.2f) m  ->  %s} $R(x) $R(y) [lindex $MODOS $R(modo)]]
    } else {
        lappend L "Persona estimada en --  (sin avisos)"
    }
    lappend L ""
    foreach nom {A B} dir [list $R(a_dir) $R(b_dir)] rel [list $R(a_rel) $R(b_rel)] info [list $R(info_a) $R(info_b)] \
            dist [list $R(d_a) $R(d_b)] rumbo [list $R(tha) $R(thb)] otra {B A} {
        if {!$dir && !$rel} {
            lappend L "Mochila $nom   \[radio: SIN SENAL, esta a 32 m o mas y nadie la retransmite\]"
            lappend L ""
            lappend L ""
            continue
        }
        array set D [interpreta_info $info]
        set ruta [expr {$dir ? "directo" : "por el puente $otra"}]
        lappend L [format "Mochila %s   \[radio: %s\]   posicion (%.2f, %.2f) m, a %.2f m del receptor" $nom $ruta $D(x) $D(y) $dist]
        set term [expr {$D(termica) ? [format "SI, %d C" $D(temp)] : [format "no (sensor en %d C)" $D(temp)]}]
        lappend L [format "            termica %s | boton %s | %s | pixeles calientes %d | rumbo %s" \
            $term [si_no $D(boton)] [lindex $ESTADOS $D(estado)] $D(pix) \
            [expr {$D(rumbo_ok) ? [format "%.1f grados" $rumbo] : "--"}]]
        lappend L [format "            tonos: oye a %s %s, oye al receptor %s" $otra [si_no $D(oye_otra)] [si_no $D(oye_rec)]]
    }
    lappend L ""
    lappend L [format "Receptor    tonos: oye a A (1 kHz) %s \[potencia %d\], oye a B (2 kHz) %s \[potencia %d\]" \
        [si_no $R(oye_a)] $R(pot_a) [si_no $R(oye_b)] $R(pot_b)]
    lappend L [format "            distancia entre A y B %.2f m | LED %s (metros a A | metros a B)" $R(d_ab) $R(led)]
    lappend L [format "Enlace      tramas perdidas: de A %d, de B %d | descartadas por CRC %d" $R(perd_a) $R(perd_b) $R(malas)]
    return $L
}

# ---- vista de detalle: lee las tres tarjetas, cada una por su cable (para pruebas)
proc muestra_estado {} {
    global ESTADOS MODOS
    array set A [lee_mochila 1]
    array set B [lee_mochila 2]
    set v [lee $::HW(0) $::DEV(0)]
    array set R [interpreta_receptor $v]
    set L [list ""]
    foreach l [lineas_receptor $v] { lappend L $l }
    lappend L "--- cada mochila, leida por su propio cable ---"
    foreach nom {A B} otra {B A} {
        upvar 0 $nom D
        lappend L [format "Mochila %s: (%.2f, %.2f) m | sensor %2d C | termica %s | boton %s | conteo %d | LED %s" \
            $nom $D(x) $D(y) $D(temp) [si_no $D(alerta)] [si_no $D(boton)] $D(cuenta) $D(led)]
        lappend L [format "           tono de %s %s \[%d\] a %.2f m | tono del receptor %s \[%d\] a %.2f m | radio de %s %s" \
            $otra [si_no $D(oye_otra)] $D(pot_otra) $D(d_otra) [si_no $D(oye_rec)] $D(pot_rec) $D(d_rec) $otra [si_no $D(otra)]]
    }
    puts [join $L "\n"]
    flush stdout
    return [list [array get A] [array get B] [array get R]]
}

# ---- ordenes de la terminal (devuelve un texto con lo que hizo)
proc rol_de {nombre} {
    switch -- [string toupper $nombre] { A { return 1 } B { return 2 } default { return 0 } }
}
proc ejecuta_orden {linea} {
    set p [regexp -all -inline {\S+} $linea]
    set orden [string tolower [lindex $p 0]]
    switch -- $orden {
        "" { return "" }
        pos {
            set r [rol_de [lindex $p 1]]
            if {$r == 0} { error "di A o B: pos A 31 0" }
            if {[string tolower [lindex $p 2]] eq "sw"} {
                pon $r 3 0; manda_mochila $r
                return "La posicion de [lindex $p 1] vuelve a sus interruptores SW9-SW6."
            }
            pon_pos $r [lindex $p 2] [lindex $p 3]; manda_mochila $r
            return [format "Mochila %s puesta en (%.2f, %.2f) m: a %.2f m del receptor." [string toupper [lindex $p 1]] \
                [lindex $p 2] [lindex $p 3] [expr {hypot([lindex $p 2], [lindex $p 3])}]]
        }
        temp {
            set r [rol_de [lindex $p 1]]
            if {$r == 0} { error "di A o B: temp A 36" }
            if {[string tolower [lindex $p 2]] eq "sw"} {
                pon $r 2 0; manda_mochila $r
                return "La temperatura de [lindex $p 1] vuelve a sus interruptores SW5-SW0."
            }
            pon_temp $r [lindex $p 2]; manda_mochila $r
            return "El sensor de [string toupper [lindex $p 1]] lee [lindex $p 2] C."
        }
        boton {
            set r [rol_de [lindex $p 1]]
            if {$r == 0} { error "di A o B: boton B" }
            pon $r 1 1; manda_mochila $r
            after 400
            pon $r 1 0; manda_mochila $r
            return "Boton de ayuda de [string toupper [lindex $p 1]] apretado."
        }
        vista {
            if {[string tolower [lindex $p 1]] eq "sw"} {
                pon 0 1 0; manda_receptor
                return "La vista del receptor vuelve a sus interruptores SW1-SW0."
            }
            pon 0 1 1; pon 0 2 [expr {int([lindex $p 1]) & 3}]; manda_receptor
            return "Vista [lindex $p 1] en los displays del receptor."
        }
        reset  { reinicia_todo; return "Tarjetas reiniciadas (se conserva lo que fijo la terminal)." }
        suelta { suelta_todo;   return "Todo vuelve a los interruptores de las tarjetas." }
        default { error "no conozco la orden \"$orden\"" }
    }
}
