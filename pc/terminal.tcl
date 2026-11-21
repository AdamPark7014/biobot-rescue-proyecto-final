# Terminal del operador para la red de tres DE10-Lite. La computadora se conecta al receptor
# por su cable USB-Blaster: no hace falta ningun adaptador.
#
#   quartus_stp -t pc/terminal.tcl vivo     monitor en vivo (MONITOR.cmd): muestra lo que sabe el
#                                           receptor y se actualiza en cuanto algo cambia en las
#                                           tarjetas. Atiende las ordenes que se escriben en
#                                           TERMINAL.cmd (llegan por el archivo pc/ordenes.txt).
#   quartus_stp -t pc/terminal.tcl          terminal sola: se escriben las ordenes aqui mismo
#   quartus_stp -t pc/terminal.tcl detalle  una lectura de las tres tarjetas y sale
#
# Ordenes:
#   pos A|B x y     pone la cucaracha en (x, y) metros, de 0 a 64 (el receptor esta en 0, 0)
#   pos A|B sw      la posicion vuelve a los interruptores SW9-SW6
#   temp A|B t      el sensor termico lee t grados C (detecta de 35 a 38)
#   temp A|B sw     la temperatura vuelve a los interruptores SW5-SW0
#   boton A|B       aprieta el boton de ayuda
#   vista 0..3      displays del receptor: 0 r Pd, 1 persona X/Y, 2 distancia A-B, 3 rumbos
#   vista sw        la vista del receptor vuelve a sus interruptores SW1-SW0
#   reset           reinicia las tres tarjetas        suelta   todo vuelve a los interruptores

set AQUI [file dirname [info script]]
source [file join $AQUI tri_lib.tcl]
set COLA [file join $AQUI ordenes.txt]

puts "Buscando las tarjetas..."
if {![encuentra_tarjetas]} {
    puts "ERROR: hacen falta la mochila A, la mochila B y el receptor. Corre CARGAR_RED.cmd."
    exit 1
}
fuente_inicial

set AYUDA "Ordenes: pos A 31 0 | pos B sw | temp A 36 | temp A sw | boton B | vista 0..3 | vista sw | reset | suelta"

if {[lindex $argv 0] eq "detalle"} {
    muestra_estado
    exit 0
}

if {[lindex $argv 0] eq "vivo"} {
    catch { file delete $COLA }
    set pie "Sensor: SW5-SW0 = grados C (detecta de 35 a 38). Boton de ayuda: KEY1. Reset: KEY0."
    set aviso "Listo. Las ordenes se escriben en la ventana TERMINAL."
    set previo ""
    puts -nonewline "\033\[2J\033\[H"
    start_insystem_source_probe -hardware_name $HW(0) -device_name $DEV(0)
    while {1} {
        # ordenes que llegaron de la otra ventana
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

# ---- terminal sola
puts $AYUDA
puts "La persona esta escondida en (25.50, 19.25) m; el receptor en (0, 0); se oye a menos de 32 m."
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
