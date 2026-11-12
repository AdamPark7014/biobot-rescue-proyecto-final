# Prueba automatica de la red de tres DE10-Lite (mochila A, mochila B y receptor)
# por los cables USB-Blaster. Requiere las versiones con sonda ya cargadas:
#   quartus_red_a/output_files/red_a.sof, quartus_red_b/output_files/red_b.sof,
#   quartus_red_receptor/output_files/red_receptor.sof
# Cada tarjeta dice su papel por la sonda, asi que no importa en que USB quedo.
#
# Uso:  quartus_stp -t sim/prueba_red.tcl
#
# Mueve las distancias por la sonda (igual que los interruptores) y aprieta los
# botones; imprime lo que muestra el receptor en cada paso:
#   1. A a 150 m y B a 80 m; A aprieta su boton  -> el aviso llega por B
#   2. B se aleja a 300 m                        -> el aviso de A se pierde
#   3. A se acerca a 60 m                        -> el aviso llega directo
#   4. B a 55 m aprieta su boton                 -> deteccion confirmada a 57 m
# Al final deja las tres tarjetas reiniciadas y obedeciendo a sus interruptores.

array set SEG {
    1000000 0 1111001 1 0100100 2 0110000 3 0011001 4 0010010 5 0000010 6 1111000 7
    0000000 8 0010000 9 0001000 A 0000011 b 1000110 C 0111111 - 0101111 r 1111111 " "
}
proc digito {bits} { global SEG; if {[info exists SEG($bits)]} { return $SEG($bits) }; return "?" }
proc bit {v n}       { return [string index $v [expr {[string length $v] - 1 - $n}]] }
proc campo {v hi lo} { return [string range $v [expr {[string length $v] - 1 - $hi}] [expr {[string length $v] - 1 - $lo}]] }
proc a_entero {b}    { scan $b %b n; return $n }

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
# fuente: bit 12 reset, bit 11 boton, bit 10 usar distancia de la fuente, bits 9-0 distancia
proc fuente {reset boton usar pos} { return "${reset}${boton}${usar}[format %010b $pos]" }

# ---- quien es quien
set NOMBRE_ROL {receptor A B}
set combinado 0
foreach hw [get_hardware_names] {
    set dev [lindex [get_device_names -hardware_name $hw] 0]
    if {[catch {set v [lee $hw $dev]}]} { puts "$hw: sin sonda de la red"; continue }
    set rol [a_entero [campo $v 53 52]]
    if {$rol == 3} {
        # top_lab_red_rb: receptor y mochila B en la misma tarjeta
        foreach papel {0 2} { set HW($papel) $hw; set DEV($papel) $dev }
        set combinado 1
        puts "$hw: receptor con la mochila B adentro"
        continue
    }
    set HW($rol) $hw
    set DEV($rol) $dev
    puts "$hw: [lindex $NOMBRE_ROL $rol]"
}
foreach rol {0 1} {
    if {![info exists HW($rol)]} { puts "ERROR: falta la tarjeta [lindex $NOMBRE_ROL $rol]"; exit 1 }
}
set hay_b [info exists HW(2)]

proc pon {rol reset boton usar pos} {
    global HW DEV combinado
    # con receptor y B en la misma tarjeta, la fuente de esa tarjeta es la de B
    if {$combinado && $rol == 0} { return }
    escribe $HW($rol) $DEV($rol) [fuente $reset $boton $usar $pos]
}
proc receptor {} {
    global HW DEV
    set v [lee $HW(0) $DEV(0)]
    set r(led) [campo $v 9 0]
    set r(a_dir)   [bit $v 0]
    set r(a_rel)   [bit $v 1]
    set r(b_dir)   [bit $v 2]
    set r(det_a)   [bit $v 3]
    set r(det_b)   [bit $v 4]
    set r(posible) [bit $v 8]
    set r(conf)    [bit $v 9]
    set r(dist)    "[digito [campo $v 37 31]][digito [campo $v 30 24]][digito [campo $v 23 17]][digito [campo $v 16 10]]"
    set r(saltos)  [digito [campo $v 44 38]]
    set r(quien)   [digito [campo $v 51 45]]
    return [array get r]
}
proc muestra {paso} {
    array set r [receptor]
    puts [format "%-34s | A directo %s  A por B %s  B directo %s | A ve %s  B ve %s | posible %s confirmada %s | HEX: %s %s %s m" \
        $paso $r(a_dir) $r(a_rel) $r(b_dir) $r(det_a) $r(det_b) $r(posible) $r(conf) $r(quien) $r(saltos) $r(dist)]
    return [array get r]
}

set errores 0
proc revisa {nombre cond} {
    global errores
    if {$cond} { puts "   correcto: $nombre" } else { puts "   INCORRECTO: $nombre"; incr errores }
}

if {!$hay_b} {
    # Solo A y el receptor (cable de A pin 35 al receptor pin 37 y tierra)
    puts "No esta la mochila B: prueba de dos tarjetas"
    foreach rol {0 1} { pon $rol 1 0 1 0 }
    after 300
    pon 0 0 0 1 0
    pon 1 0 0 1 60
    after 1500
    array set r [muestra "a. A a 60 m, sin boton"]
    revisa "A llega directo y sin aviso" [expr {$r(a_dir) == 1 && $r(det_a) == 0}]
    pon 1 0 1 1 60
    after 800
    pon 1 0 0 1 60
    after 1500
    array set r [muestra "b. A aprieta el boton"]
    revisa "aviso de A directo, a 60 m" [expr {$r(a_dir) == 1 && $r(det_a) == 1 && $r(posible) == 1}]
    pon 1 0 0 1 150
    after 2500
    array set r [muestra "c. A se aleja a 150 m"]
    revisa "fuera del alcance de 100 m, el aviso se pierde" [expr {$r(a_dir) == 0 && $r(det_a) == 0}]
    foreach rol {0 1} { pon $rol 1 0 0 0 }
    after 200
    foreach rol {0 1} { pon $rol 0 0 0 0 }
    puts ""
    if {$errores == 0} { puts "RESULTADO: CORRECTO con dos tarjetas. Falta la mochila B para probar el puente." } else { puts "RESULTADO: $errores pasos no coinciden." }
    return
}

# reinicia las tres tarjetas
foreach rol {0 1 2} { pon $rol 1 0 1 0 }
after 300
pon 0 0 0 1 0
pon 1 0 0 1 150
pon 2 0 0 1 80
after 1500
muestra "0. A a 150 m, B a 80 m, sin boton"

pon 1 0 1 1 150
after 800
pon 1 0 0 1 150
after 1500
array set r [muestra "1. A aprieta el boton"]
revisa "el aviso de A llega solo a traves de B" [expr {$r(a_dir) == 0 && $r(a_rel) == 1 && $r(det_a) == 1 && $r(dist) eq " 150" || $r(a_dir) == 0 && $r(a_rel) == 1 && $r(det_a) == 1 && $r(dist) eq "0150"}]

pon 2 0 0 1 300
after 2500
array set r [muestra "2. B se aleja a 300 m"]
revisa "sin puente, el receptor pierde a A" [expr {$r(a_dir) == 0 && $r(a_rel) == 0 && $r(det_a) == 0}]

pon 1 0 0 1 60
after 1500
array set r [muestra "3. A se acerca a 60 m"]
revisa "el aviso de A llega directo" [expr {$r(a_dir) == 1 && $r(det_a) == 1}]

pon 2 0 1 1 55
after 800
pon 2 0 0 1 55
after 1500
array set r [muestra "4. B a 55 m aprieta su boton"]
revisa "deteccion confirmada por las dos mochilas" [expr {$r(conf) == 1 && $r(det_a) == 1 && $r(det_b) == 1}]

# deja todo como estaba: reinicio y de vuelta a los interruptores
foreach rol {0 1 2} { pon $rol 1 0 0 0 }
after 200
foreach rol {0 1 2} { pon $rol 0 0 0 0 }

puts ""
if {$errores == 0} { puts "RESULTADO: CORRECTO. Los cuatro pasos de la red salieron como en la simulacion." } else { puts "RESULTADO: $errores pasos no coinciden." }
