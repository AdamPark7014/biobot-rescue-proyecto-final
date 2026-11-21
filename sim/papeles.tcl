# Dice que papel tiene cargado cada DE10-Lite conectada y, si se pide, prueba los enlaces.
# Uso: quartus_stp -t sim/papeles.tcl [enlaces]
# Lineas de salida:  PAPEL <cable> A|B|R|RB|vacia      ENLACES r_oye_a r_oye_b a_oye_b b_oye_a
source [file join [file dirname [info script]] .. pc tri_lib.tcl]
foreach hw [get_hardware_names] {
    set dev [lindex [get_device_names -hardware_name $hw] 0]
    set papel vacia
    if {![catch {
        start_insystem_source_probe -hardware_name $hw -device_name $dev
        set v [read_probe_data -instance_index 0]
        end_insystem_source_probe
    }]} {
        set ancho [string length $v]
        if {$ancho == $ANCHO_MOCHILA} {
            set rol [a_entero [campo $v 91 90]]
            set papel [lindex {? A B ?} $rol]
            set HW($rol) $hw; set DEV($rol) $dev
        } elseif {$ancho == $ANCHO_RECEPTOR} {
            if {[a_entero [campo $v 95 94]] == 3} { set papel RB } else { set papel R; set HW(0) $hw; set DEV(0) $dev }
        }
    } else { catch { end_insystem_source_probe } }
    puts "PAPEL $hw $papel"
}
if {[lindex $argv 0] eq "enlaces" && [info exists HW(0)] && [info exists HW(1)] && [info exists HW(2)]} {
    # las dos mochilas cerca de la entrada, al alcance de todo
    set COMBINADO 0
    fuente_inicial
    foreach r {1 2} { pon_pos $r 4.5 3.0; manda_mochila $r }
    after 2500
    array set A [lee_mochila 1]
    array set B [lee_mochila 2]
    array set R [lee_receptor]
    puts "ENLACES $R(a_dir) $R(b_dir) $A(otra) $B(otra)"
    foreach r {1 2} { pon $r 3 0; manda_mochila $r }
}
