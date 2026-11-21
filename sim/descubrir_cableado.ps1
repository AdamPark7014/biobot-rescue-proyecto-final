# Descubre qué tarjeta está cableada con cuál, sin mirar los cables.
# En cada ronda una tarjeta hace de mochila A y las otras dos de mochila B; las B que oyen a
# la A son las que reciben su línea TX. Con las tres rondas sale quién transmite a quién.
# Uso: pwsh -File sim\descubrir_cableado.ps1
$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent
$q = 'C:\intelFPGA_lite\24.1std\quartus\bin64'
$sofA = Join-Path $raiz 'quartus_tri_a\output_files\tri_a.sof'
$sofB = Join-Path $raiz 'quartus_tri_b\output_files\tri_b.sof'
$cables = @(& "$q\jtagconfig.exe" 2>&1 | Select-String 'USB-Blaster \[(USB-\d+)\]' | ForEach-Object { $_.Matches[0].Groups[1].Value })
"Cables: $($cables -join ', ')"
if ($cables.Count -lt 3) { throw 'Hacen falta tres tarjetas conectadas' }
$oyen = @{}
foreach ($emisor in $cables) {
    foreach ($c in $cables) {
        $sof = if ($c -eq $emisor) { $sofA } else { $sofB }
        & "$q\quartus_pgm.exe" -c "USB-Blaster [$c]" -m jtag -o "p;$sof@1" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudo cargar $c" }
    }
    Push-Location $raiz
    try { $salida = & "$q\quartus_stp.exe" -t sim/quien_oye.tcl 2>&1 | Select-String '^OYE' | ForEach-Object { $_.Line } }
    finally { Pop-Location }
    $receptores = @($salida | Where-Object { $_ -match 'rol 2 oye 1' } | ForEach-Object { if ($_ -match '\[(USB-\d+)\]') { $Matches[1] } })
    $oyen[$emisor] = $receptores
    "Lo que transmite $emisor lo oyen: $(if ($receptores.Count) { $receptores -join ', ' } else { 'nadie' })"
}
# Papeles: el receptor es la tarjeta que oye a las otras dos y a la que nadie necesita oír.
"RESUMEN " + (($cables | ForEach-Object { "$_ -> [$($oyen[$_] -join ' ')]" }) -join ' ; ')
