set AQUI [file dirname [info script]]
set MODO [lindex $argv 0]

array set ROL_DE {SIM-A 1 SIM-B 2 SIM-R 0}
proc get_hardware_names {}            { return {SIM-A SIM-B SIM-R} }
proc get_device_names {args}          { return [list "@1: 10M50DA (simulada)"] }
proc start_insystem_source_probe {args} { array set o $args; set ::ACTUAL $o(-hardware_name) }
proc end_insystem_source_probe {}     { }
proc read_probe_data {args}           { return $::SONDA($::ACTUAL) }
proc write_source_data {args} {
    array set o $args
    if {[info exists ::SALIDA]} { puts $::SALIDA "0 $::PASO $::ROL_DE($::ACTUAL) $o(-value)" }
}

source [file join $AQUI .. pc tri_lib.tcl]

# los pasos
set PASOS {}
proc paso {ordenes decimas titulo comprobaciones} {
    lappend ::PASOS [list $ordenes $decimas $titulo $comprobaciones]
}
proc cerca {a b tol} { return [expr {abs($a - $b) <= $tol}] }

paso {} 25 "Encendido. A en (25.75, 19.00) m, a 32.00 m; B en (25.25, 19.00) m, a 31.60 m; las dos a 22 C" {
    "la terminal reconoce las tres tarjetas por su sonda"  {$::ENCONTRADAS == 1}
    "conteo 0 en las tres tarjetas"                       {$A(cuenta) == 0 && $B(cuenta) == 0 && $R(cuenta) == 0}
    "posiciones de A y de B"                              {[cerca $A(x) 25.75 0.01] && [cerca $A(y) 19.0 0.01] && [cerca $B(x) 25.25 0.01] && [cerca $B(y) 19.0 0.01]}
    "sensores en 22 C"                                    {$A(temp) == 22 && $B(temp) == 22}
    "B llega directo al receptor; A, por el puente"       {$R(b_dir) == 1 && $R(a_dir) == 0 && $R(a_rel) == 1}
    "el receptor conoce la posicion de A por el puente"   {[cerca $IA(x) 25.75 0.01] && [cerca $IA(y) 19.0 0.01]}
    "tonos: el receptor oye a B y no a A"                 {$R(oye_b) == 1 && $R(oye_a) == 0}
    "tonos: A no oye al receptor; B si; se oyen entre si" {$A(oye_rec) == 0 && $B(oye_rec) == 1 && $A(oye_otra) == 1 && $B(oye_otra) == 1}
    "distancia de B al receptor: 31.56 m (505 cuentas)"   {$B(d_rec) == 31.5625 && $R(d_b) == 31.5625}
    "distancia de A al receptor: 32.00 m (512 cuentas)"   {$A(d_rec) == 32.0 && $R(d_a) == 32.0}
    "LED: 31 m a B en el receptor y en B; A apagada"      {[campo $R(led) 4 0] eq "11111" && [campo $R(led) 9 5] eq "00000" && [campo $B(led) 4 0] eq "11111" && [campo $A(led) 4 0] eq "00000"}
    "LED: A y B se oyen a 0.50 m y marcan 1 m"            {[campo $A(led) 9 5] eq "00001" && [campo $B(led) 9 5] eq "00001"}
    "sin avisos"                                          {$R(modo) == 0}
}
paso {{temp A 36}} 30 "temp A 36: deteccion termica en A" {
    "A detecta con 36 C"                                  {$A(alerta) == 1 && $A(temp) == 36}
    "conteo 1 en las tres tarjetas"                       {$A(cuenta) == 1 && $B(cuenta) == 1 && $R(cuenta) == 1}
    "el receptor recibe: termica SI, 36 C"                {$IA(termica) == 1 && $IA(temp) == 36}
    "posicion aproximada con una mochila"                 {$R(modo) == 1}
}
paso {{temp B 37}} 30 "temp B 37: segunda deteccion y triangulacion" {
    "conteo 2 en las tres tarjetas"                       {$A(cuenta) == 2 && $B(cuenta) == 2 && $R(cuenta) == 2}
    "el receptor recibe de B: termica SI, 37 C"           {$IB(termica) == 1 && $IB(temp) == 37}
    "triangulada sin error"                               {$R(modo) == 2 && $R(err) == 0}
    "persona a menos de 20 cm de (25.50, 19.25) m"        {hypot($R(x) - 25.5, $R(y) - 19.25) < 0.20}
    "distancia entre A y B: 0.50 m"                       {$R(d_ab) == 0.5}
}
paso {{temp A 40}} 25 "temp A 40: A sale del intervalo" {
    "A deja de detectar"                                  {$A(alerta) == 0 && $A(temp) == 40}
    "el conteo baja a 1 en las tres"                      {$A(cuenta) == 1 && $B(cuenta) == 1 && $R(cuenta) == 1}
    "el receptor recibe de A: termica no, 40 C"           {$IA(termica) == 0 && $IA(temp) == 40}
}
paso {{temp A sw} {temp B sw}} 25 "temp A sw, temp B sw: los sensores vuelven a los interruptores" {
    "sensores en 22 C"                                    {$A(temp) == 22 && $B(temp) == 22}
    "conteo 0 en las tres"                                {$A(cuenta) == 0 && $B(cuenta) == 0 && $R(cuenta) == 0}
    "sin avisos"                                          {$R(modo) == 0}
}
paso {{boton B}} 20 "boton B: boton de ayuda" {
    "B marca el boton"                                    {$B(boton) == 1}
    "conteo 1 en las tres"                                {$A(cuenta) == 1 && $B(cuenta) == 1 && $R(cuenta) == 1}
    "el receptor recibe de B: boton SI"                   {$IB(boton) == 1 && $IB(termica) == 0}
    "posicion: la de la mochila del boton"                {$R(modo) == 4 && [cerca $R(x) 25.25 0.01] && [cerca $R(y) 19.0 0.01]}
}
paso {reset} 30 "reset: reinicia las tres tarjetas" {
    "se borra el boton y el conteo vuelve a 0"            {$B(boton) == 0 && $A(cuenta) == 0 && $B(cuenta) == 0 && $R(cuenta) == 0}
    "los enlaces se recuperan"                            {$R(b_dir) == 1 && $R(a_rel) == 1}
}
paso {{pos A 31 0}} 25 "pos A 31 0: A a 31 m del receptor" {
    "A en (31.00, 0.00) m"                                {[cerca $A(x) 31.0 0.01] && [cerca $A(y) 0.0 0.01]}
    "radio directo y distancia de 31.00 m exactos"        {$R(a_dir) == 1 && $R(d_a) == 31.0 && $A(d_rec) == 31.0}
    "tonos: el receptor oye a A y A al receptor"          {$R(oye_a) == 1 && $A(oye_rec) == 1}
    "LED: 31 m en el receptor y en A"                     {[campo $R(led) 9 5] eq "11111" && [campo $A(led) 4 0] eq "11111"}
}
paso {{pos A 0 31}} 25 "pos A 0 31: A a 31 m por el otro eje" {
    "A en (0.00, 31.00) m"                                {$A(x) == 0.0 && $A(y) == 31.0}
    "radio directo y distancia de 31.00 m exactos"        {$R(a_dir) == 1 && $R(d_a) == 31.0 && $A(d_rec) == 31.0}
    "tonos: el receptor oye a A y A al receptor"          {$R(oye_a) == 1 && $A(oye_rec) == 1}
    "LED: 31 m en el receptor y en A"                     {[campo $R(led) 9 5] eq "11111" && [campo $A(led) 4 0] eq "11111"}
}
paso {{pos A 25.75 18.94}} 25 "pos A 25.75 18.94: en diagonal, a 31.96 m (lo mas lejos que se oye)" {
    "A en (25.75, 18.94) m"                               {$A(x) == 25.75 && $A(y) == 18.9375}
    "se oye: radio directo y tonos en los dos sentidos"   {$R(a_dir) == 1 && $R(oye_a) == 1 && $A(oye_rec) == 1}
    "distancia de 31.94 m (511 cuentas)"                  {$R(d_a) == 31.9375 && $A(d_rec) == 31.9375}
    "LED: 31 m en el receptor y en A; B, a 0.50 m, 1 m"   {[campo $R(led) 9 5] eq "11111" && [campo $A(led) 4 0] eq "11111" && [campo $A(led) 9 5] eq "00001"}
}
paso {{pos A 32 0}} 25 "pos A 32 0: A a 32 m del receptor" {
    "A en (32.00, 0.00) m, a 32.00 m"                     {$A(x) == 32.0 && $A(y) == 0.0 && $A(d_rec) == 32.0}
    "ya no llega directo ni se oye su tono"               {$R(a_dir) == 0 && $R(oye_a) == 0 && $A(oye_rec) == 0}
    "LED apagados en el receptor y en A"                  {[campo $R(led) 9 5] eq "00000" && [campo $A(led) 4 0] eq "00000"}
    "B, a 20.12 m de A (322 cuentas), hace de puente"     {$R(a_rel) == 1 && $A(d_otra) == 20.125}
}
paso {{pos B 60 60}} 30 "pos B 60 60: B tambien fuera de alcance" {
    "ninguna mochila llega al receptor"                   {$R(a_dir) == 0 && $R(a_rel) == 0 && $R(b_dir) == 0 && $R(b_rel) == 0}
    "nadie oye a nadie"                                   {$R(oye_a) == 0 && $R(oye_b) == 0 && $A(oye_otra) == 0 && $B(oye_otra) == 0 && $B(oye_rec) == 0}
    "la terminal avisa SIN SENAL de las dos"              {[llength [lsearch -all -glob $::VISTA "*SIN SENAL*"]] == 2}
}
paso {{vista 2}} 10 "vista 2: la terminal cambia los displays del receptor" {
    "los displays del receptor cambian"                   {$::HEX ne $::HEX_PREVIO}
}
paso {suelta} 35 "suelta: todo vuelve a los interruptores" {
    "A y B vuelven a sus posiciones"                      {[cerca $A(x) 25.75 0.01] && [cerca $B(x) 25.25 0.01]}
    "conteo 0 y enlaces como al encender"                 {$R(cuenta) == 0 && $R(b_dir) == 1 && $R(a_dir) == 0 && $R(a_rel) == 1}
    "los displays del receptor, como al encender"         {$::HEX eq $::HEX_INICIAL}
}

if {$MODO eq "genera"} {
    # sondas vacias del ancho correcto
    proc sonda_vacia {ancho hi rol} {
        set v [string repeat 0 $ancho]
        set i [expr {$ancho - 1 - $hi}]
        return [string replace $v $i [expr {$i + 1}] [format %02b $rol]]
    }
    set SONDA(SIM-A) [sonda_vacia $ANCHO_MOCHILA 91 1]
    set SONDA(SIM-B) [sonda_vacia $ANCHO_MOCHILA 91 2]
    set SONDA(SIM-R) [sonda_vacia $ANCHO_RECEPTOR 95 0]
    if {![encuentra_tarjetas]} { puts "ERROR prueba_terminal: la terminal no reconoce las tarjetas"; exit 1 }
    fuente_inicial
    set SALIDA [open [file join $AQUI fuentes_sonda.txt] w]
    set PASO 0
    foreach p $PASOS {
        lassign $p ordenes decimas titulo comprobaciones
        foreach orden $ordenes {
            if {[catch {ejecuta_orden $orden} res]} { puts "ERROR prueba_terminal: orden \"$orden\": $res"; exit 1 }
        }
        puts $SALIDA "1 $PASO $decimas 0"
        incr PASO
    }
    close $SALIDA
    puts "RESULTADO prueba_terminal genera: $PASO pasos en fuentes_sonda.txt"
    exit 0
}

# revisa
if {$MODO ne "revisa"} { puts "uso: prueba_terminal.tcl genera | revisa"; exit 1 }

set f [open [file join $AQUI sondas.txt] r]
set lineas [split [string trim [read $f]] "\n"]
close $f
if {[llength $lineas] != [llength $PASOS]} {
    puts "ERROR prueba_terminal: hay [llength $lineas] pasos simulados y se esperaban [llength $PASOS]"
    exit 1
}
set registro [open [file join $AQUI terminal_simulada.txt] w]
puts $registro "Lo que muestra la terminal del operador en cada paso, con las tres FPGA simuladas"
puts $registro "(sim/tb_sonda.v). Lo genera sim/probar_terminal.ps1."

set buenas 0
set malas 0
set HEX ""
set ENCONTRADAS 0
proc comprueba {cond} {
    global A B R IA IB
    return [expr $cond]
}
for {set n 0} {$n < [llength $PASOS]} {incr n} {
    lassign [lindex $PASOS $n] ordenes decimas titulo comprobaciones
    lassign [lindex $lineas $n] paso sa sb sr hex
    set SONDA(SIM-A) $sa
    set SONDA(SIM-B) $sb
    set SONDA(SIM-R) $sr
    set HEX_PREVIO $HEX
    set HEX $hex
    if {$n == 0} {
        set HEX_INICIAL $hex
        set ENCONTRADAS [encuentra_tarjetas]
        if {!$ENCONTRADAS} { puts "ERROR prueba_terminal: la terminal no reconoce las sondas simuladas"; exit 1 }
    }
    array unset A; array unset B; array unset R; array unset IA; array unset IB
    array set A  [lee_mochila 1]
    array set B  [lee_mochila 2]
    array set R  [lee_receptor]
    array set IA [interpreta_info $R(info_a)]
    array set IB [interpreta_info $R(info_b)]
    set VISTA [lineas_receptor $sr]

    puts "PASO $n: $titulo"
    puts $registro ""
    puts $registro "PASO $n: $titulo"
    foreach l $VISTA { puts $registro "    $l" }
    foreach {texto cond} $comprobaciones {
        if {[catch {comprueba $cond} bien]} { set bien 0; set texto "$texto (error: $bien)" }
        if {$bien} {
            incr buenas
            puts "    bien   $texto"
        } else {
            incr malas
            puts "    FALLA  $texto"
        }
    }
}
close $registro

puts "RESPUESTAS de la terminal"
fuente_inicial
foreach {texto orden patron} {
    "pos A 31 0: 31.00 m, dentro del alcance"             {pos A 31 0}     {*(31.00, 0.00) m: a 31.00 m del receptor, dentro del alcance*}
    "pos A 0 31: 31.00 m, dentro del alcance"             {pos A 0 31}     {*(0.00, 31.00) m: a 31.00 m del receptor, dentro del alcance*}
    "pos A 32 0: 32.00 m, fuera del alcance"              {pos A 32 0}     {*(32.00, 0.00) m: a 32.00 m del receptor, fuera del alcance*}
    "pos A 31.97 0: queda en 32.00 m, fuera del alcance"  {pos A 31.97 0}  {*(32.00, 0.00) m: a 32.00 m del receptor, fuera del alcance*}
    "pos B 25.75 18.94: 31.94 m, dentro del alcance"      {pos B 25.75 18.94} {*(25.75, 18.94) m: a 31.94 m del receptor, dentro del alcance*}
    "temp A 35: dentro de la ventana"                     {temp A 35}      {*lee 35 C: dentro de la ventana de 35 a 38 C*}
    "temp A 38: dentro de la ventana"                     {temp A 38}      {*lee 38 C: dentro de la ventana de 35 a 38 C*}
    "temp A 34: fuera de la ventana"                      {temp A 34}      {*lee 34 C: fuera de la ventana de 35 a 38 C*}
    "temp A 39: fuera de la ventana"                      {temp A 39}      {*lee 39 C: fuera de la ventana de 35 a 38 C*}
    "pos A 70 0: se rechaza"                              {pos A 70 0}     ERROR
    "pos A treinta 0: se rechaza"                         {pos A treinta 0} ERROR
    "temp A 99: se rechaza"                               {temp A 99}      ERROR
    "vista 7: se rechaza"                                 {vista 7}        ERROR
    "orden desconocida: se rechaza"                       {vuela A}        ERROR
} {
    set fallo [catch {ejecuta_orden $orden} res]
    if {$patron eq "ERROR"} { set bien $fallo } else { set bien [expr {!$fallo && [string match $patron $res]}] }
    if {$bien} {
        incr buenas
        puts "    bien   $texto"
    } else {
        incr malas
        puts "    FALLA  $texto  ->  $res"
    }
}

if {$malas == 0} {
    puts "RESULTADO prueba_terminal: $buenas de $buenas comprobaciones correctas en [llength $PASOS] pasos"
    exit 0
}
puts "RESULTADO prueba_terminal: $malas fallas de [expr {$buenas + $malas}] comprobaciones"
exit 1
