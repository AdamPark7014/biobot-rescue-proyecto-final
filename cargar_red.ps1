# Carga la red de triangulación en las tres DE10-Lite y comprueba los enlaces.
#
#   pwsh -File cargar_red.ps1            carga lo que falte y verifica los cuatro enlaces
#   pwsh -File cargar_red.ps1 -Todo      vuelve a cargar las tres aunque ya tengan la red
#   pwsh -File cargar_red.ps1 -Prueba    además corre los seis escenarios (sim\prueba_tri.tcl)
#   pwsh -File cargar_red.ps1 -Terminal  al terminar abre la terminal del operador
#
# El .sof se pierde cuando la tarjeta se queda sin corriente: basta volver a correr esto.
# No importa en qué puerto USB quedó cada tarjeta. El cableado decide cuál es el receptor
# (la tarjeta que recibe de las otras dos); las dos mochilas son intercambiables. Si los
# enlaces no salen con una asignación, se prueba con otra tarjeta como receptor.
param([switch]$Todo, [switch]$Prueba, [switch]$Terminal)
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$q = 'C:\intelFPGA_lite\24.1std\quartus\bin64'
$sof = @{
    A = Join-Path $raiz 'quartus_tri_a\output_files\tri_a.sof'
    B = Join-Path $raiz 'quartus_tri_b\output_files\tri_b.sof'
    R = Join-Path $raiz 'quartus_tri_receptor\output_files\tri_receptor.sof'
}

function Leer-Papeles([switch]$Enlaces) {
    Push-Location $raiz
    try {
        $arg = if ($Enlaces) { 'enlaces' } else { '' }
        $salida = & "$q\quartus_stp.exe" -t sim/papeles.tcl $arg 2>&1 | ForEach-Object { "$_" }
    } finally { Pop-Location }
    $papeles = [ordered]@{}
    foreach ($l in $salida) {
        if ($l -match '^PAPEL USB-Blaster \[(USB-\d+)\] (\S+)') { $papeles[$Matches[1]] = $Matches[2] }
    }
    $enl = ($salida | Where-Object { $_ -match '^ENLACES' } | Select-Object -First 1)
    return @{ Papeles = $papeles; Enlaces = $enl }
}
function Cargar($cable, $papel) {
    & "$q\quartus_pgm.exe" -c "USB-Blaster [$cable]" -m jtag -o "p;$($sof[$papel])@1" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudo cargar $papel en $cable" }
    "  $cable <- $papel"
}

$estado = Leer-Papeles
$cables = @($estado.Papeles.Keys)
"Tarjetas conectadas: $($cables.Count) ($($cables -join ', '))"
if ($cables.Count -lt 3) {
    $estado.Papeles.GetEnumerator() | ForEach-Object { "  $($_.Key): $($_.Value)" }
    throw "Hacen falta tres tarjetas por USB y solo hay $($cables.Count). Revisa el cable de la que falta."
}

# Posibles receptores, empezando por el que ya lo era
$orden = @($cables | Where-Object { $estado.Papeles[$_] -eq 'R' }) + @($cables | Where-Object { $estado.Papeles[$_] -ne 'R' })
$bien = $false
foreach ($receptor in $orden) {
    $mochilas = @($cables | Where-Object { $_ -ne $receptor })
    $plan = @{ $receptor = 'R' }
    # conserva la letra de las mochilas que ya la tienen
    $yaA = $mochilas | Where-Object { $estado.Papeles[$_] -eq 'A' } | Select-Object -First 1
    $yaB = $mochilas | Where-Object { $estado.Papeles[$_] -eq 'B' } | Select-Object -First 1
    if ($yaA -and $yaB)     { $plan[$yaA] = 'A'; $plan[$yaB] = 'B' }
    elseif ($yaA)           { $plan[$yaA] = 'A'; $plan[($mochilas | Where-Object { $_ -ne $yaA })] = 'B' }
    elseif ($yaB)           { $plan[$yaB] = 'B'; $plan[($mochilas | Where-Object { $_ -ne $yaB })] = 'A' }
    else                    { $plan[$mochilas[0]] = 'A'; $plan[$mochilas[1]] = 'B' }
    "Asignación: " + (($cables | ForEach-Object { "$_ = $($plan[$_])" }) -join ', ')
    foreach ($c in $cables) {
        if ($Todo -or $estado.Papeles[$c] -ne $plan[$c]) { Cargar $c $plan[$c] }
    }
    $estado = Leer-Papeles -Enlaces
    if ($estado.Enlaces -match '^ENLACES (\d) (\d) (\d) (\d)') {
        "Enlaces: receptor oye a A $($Matches[1]), receptor oye a B $($Matches[2]), A oye a B $($Matches[3]), B oye a A $($Matches[4])"
        if ($estado.Enlaces -eq 'ENLACES 1 1 1 1') { $bien = $true; break }
        if ($Matches[1] -eq '1' -and $Matches[2] -eq '1') {
            "El receptor recibe a las dos mochilas, pero falta un cable entre ellas (pin 33 de una al pin 37 de la otra)."
            $bien = $true; break
        }
    } else { "No se pudieron leer los enlaces." }
    $Todo = $false
}
if (-not $bien) {
    "RESULTADO: las tarjetas están cargadas, pero los enlaces no salen. Revisa los seis cables de JP1 (GUIA_LABORATORIO.md, montaje E)."
    exit 1
}
"RESULTADO: red cargada y enlazada. Cada tarjeta muestra su letra a la izquierda: A, b o r."
if ($Prueba) {
    Push-Location $raiz
    try { & "$q\quartus_stp.exe" -t sim/prueba_tri.tcl 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^\s*Info|^-+$|TBBmalloc' } }
    finally { Pop-Location }
}
if ($Terminal) {
    Push-Location $raiz
    try { & "$q\quartus_stp.exe" -t pc/terminal.tcl }
    finally { Pop-Location }
}
