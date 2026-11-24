set AQUI [file dirname [info script]]
source [file join $AQUI tri_lib.tcl]
set COLA [file join $AQUI ordenes.txt]

puts "Buscando las tarjetas..."
if {![encuentra_tarjetas]} {
    puts "ERROR: hacen falta la mochila A, la mochila B y el receptor. Corre CARGAR_RED.cmd."
    exit 1
}
fuente_inicial

set AYUDA "Ordenes: usa B | mueve 31 0 | dist 0.5 | pos A 31 0 | pos B sw | temp A 36 | temp A sw | boton B | vista 0..3 | vista sw | reset | suelta"

if {[lindex $argv 0] eq "detalle"} {
    muestra_estado
    exit 0
}

if {[lindex $argv 0] eq "vivo"} {
    catch { file delete $COLA }
    set pie "Sensor: SW5-SW0 = grados C (detecta de $T_PERSONA_MIN a $T_PERSONA_MAX). Boton de ayuda: KEY1. Reset: KEY0. Alcance: menos de $ALCANCE_M m."
    set aviso "Listo. Las ordenes se escriben en la ventana TERMINAL."
    set previo ""
    puts -nonewline "\033\[2J\033\[H"
    start_insystem_source_probe -hardware_name $HW(0) -device_name $DEV(0)
    while {1} {
        if {[file exists $COLA]} {
            end_insystem_source_probe
            set leyendo "$COLA.leyendo"
            catch { file rename -force $COLA $leyendo }
            if {![catch {open $leyendo r} f]} {
                set texto [read $f]; close $f
                catch { file delete $leyendo }
                foreach linea [split $texto "\n"] {
                    set linea [string trim $linea]
                    if {$linea eq ""} { continue }
                    if {[catch {ejecuta_orden $linea} res]} { set aviso "> $linea   ERROR: $res" } else { set aviso "> $linea   $res" }
                }
            }
            con_reintentos { start_insystem_source_probe -hardware_name $HW(0) -device_name $DEV(0) }
            set previo ""
        }
        if {[catch {read_probe_data -instance_index 0} v]} {
            catch { end_insystem_source_probe }
            puts -nonewline "\033\[H(el receptor no responde: revisa su cable USB)\033\[K\n"
            flush stdout
            after 1000
            catch { start_insystem_source_probe -hardware_name $HW(0) -device_name $DEV(0) }
            set previo ""
            continue
        }
        if {$v ne $previo} {
            set previo $v
            set L [lineas_receptor $v]
            lappend L "" $aviso $pie
            puts -nonewline "\033\[H[join $L "\033\[K\n"]\033\[K\n\033\[J"
            flush stdout
        }
        after 60
    }
}

# terminal sola
puts $AYUDA
puts "La persona esta escondida en (25.50, 19.25) m; el receptor en (0, 0); se oye a menos de $ALCANCE_M m."
puts "El sensor detecta de $T_PERSONA_MIN a $T_PERSONA_MAX C."
muestra_estado
while {1} {
    puts -nonewline "\nbiobot> "
    flush stdout
    if {[gets stdin linea] < 0} { break }
    set linea [string trim $linea]
    switch -- [string tolower $linea] {
        salir  { break }
        ayuda  { puts $AYUDA; continue }
        ver    { muestra_estado; continue }
        ""     { continue }
    }
    if {[catch {ejecuta_orden $linea} res]} { puts "Error: $res"; continue }
    puts $res
    after 1200
    muestra_estado
}
puts "Hasta luego."
