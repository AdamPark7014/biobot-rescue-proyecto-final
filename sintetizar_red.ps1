# Sintetiza las cuatro variantes de la red de tres FPGA con Quartus Prime 24.1 y resume
# recursos, frecuencia maxima y advertencias. Termina con codigo 1 si alguna no cumple.
# Uso:  pwsh -File sintetizar_red.ps1            (las cuatro en paralelo, unos diez minutos)
#       pwsh -File sintetizar_red.ps1 -Resumen   (solo lee los reportes que ya existen)
param([switch]$Resumen)
$ErrorActionPreference = 'Stop'
$raiz      = $PSScriptRoot
$quartus   = 'C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_sh.exe'
$variantes = @('tri_a', 'tri_b', 'tri_receptor', 'tri_rb')
$nombres   = @{ tri_a = 'Mochila A'; tri_b = 'Mochila B'; tri_receptor = 'Receptor'; tri_rb = 'Receptor con B' }

if (-not $Resumen) {
    $procesos = foreach ($v in $variantes) {
        $dir = Join-Path $raiz "quartus_$v"
        Start-Process -FilePath $quartus -ArgumentList '--flow', 'compile', $v -WorkingDirectory $dir `
            -RedirectStandardOutput (Join-Path $dir 'compile.log') -WindowStyle Hidden -PassThru
    }
    $procesos | Wait-Process
}

function Lee-Campo($texto, $patron) {
    $m = [regex]::Match($texto, $patron)
    if ($m.Success) { $m.Groups[1].Value.Trim() } else { '?' }
}

$falla = $false
$filas = foreach ($v in $variantes) {
    $out = Join-Path $raiz "quartus_$v\output_files"
    $sof = Join-Path $out "$v.sof"
    if (-not (Test-Path $sof)) { $falla = $true; Write-Output "FALTA $v.sof"; continue }
    $fit = Get-Content (Join-Path $out "$v.fit.summary") -Raw
    $sta = Get-Content (Join-Path $out "$v.sta.rpt") -Raw
    $map = Get-Content (Join-Path $out "$v.map.rpt")
    $fmax = [regex]::Matches($sta, ';\s*([\d.]+) MHz\s*;\s*[\d.]+ MHz\s*;\s*CLOCK_50') |
        ForEach-Object { [double]$_.Groups[1].Value } | Measure-Object -Minimum
    $holgura = Lee-Campo $sta 'Slow 1200mV 85C Model Setup Summary[\s\S]*?;\s*CLOCK_50\s*;\s*(-?[\d.]+)\s*;'
    $criticas = @(Get-ChildItem $out -Filter '*.rpt' | Select-String -Pattern '^Critical Warning' ).Count
    # advertencias del codigo: anchos, senales sin usar, cerrojos
    $codigo = @($map | Select-String -Pattern '^Warning \((10230|10036|10776|10240|10235|10199)\)').Count
    if ($fmax.Minimum -lt 50 -or $criticas -gt 0) { $falla = $true }
    [pscustomobject]@{
        Variante     = $nombres[$v]
        Elementos    = Lee-Campo $fit 'Total logic elements : ([\d,]+ / [\d,]+ \( *\d+ % \))'
        Registros    = Lee-Campo $fit 'Total registers : (\d+)'
        Mult9        = Lee-Campo $fit 'Embedded Multiplier 9-bit elements : (\d+)'
        Pines        = Lee-Campo $fit 'Total pins : (\d+)'
        'Fmax (MHz)' = '{0:N2}' -f $fmax.Minimum
        'Holgura ns' = $holgura
        Criticas     = $criticas
        'Av. codigo' = $codigo
        Sof          = (Get-Item $sof).LastWriteTime.ToString('dd-MM HH:mm')
    }
}
$filas | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
if ($falla) { Write-Output 'RESULTADO sintesis: NO cumple'; exit 1 }
Write-Output 'RESULTADO sintesis: las cuatro variantes cumplen 50 MHz sin advertencias criticas'
