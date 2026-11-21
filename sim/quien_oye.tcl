# Para descubrir el cableado: con mochilas cargadas en las tarjetas, dice de cada una
# su papel y si oye a la otra mochila. Lo usa sim/descubrir_cableado.ps1.
# Antes pone todas las mochilas en el mismo punto (16, 16) m por la sonda, para que el
# alcance del radio simulado no dependa de como esten los interruptores.
source [file join [file dirname [info script]] .. pc tri_lib.tcl]
set junto "0001[format %010b 256][format %010b 256]000000000000"
foreach hw [get_hardware_names] {
    set dev [lindex [get_device_names -hardware_name $hw] 0]
    catch { if {[string length [lee $hw $dev]] == $ANCHO_MOCHILA} { escribe $hw $dev $junto } }
}
after 2000
foreach hw [get_hardware_names] {
    set dev [lindex [get_device_names -hardware_name $hw] 0]
    if {[catch {set v [lee $hw $dev]}]} { puts "OYE $hw sin-sonda"; continue }
    if {[string length $v] != $ANCHO_MOCHILA} { puts "OYE $hw otro"; continue }
    puts "OYE $hw rol [a_entero [campo $v 91 90]] oye [bit $v 13] x [a_entero [campo $v 54 45]] y [a_entero [campo $v 44 35]]"
}
