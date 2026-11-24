param([switch]$SoloPdf)
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$salida = Join-Path $raiz 'Reporte_Proyecto_Final_y_Practica_5_BioBot-Rescue.pdf'

if (-not $SoloPdf) {
    Push-Location (Join-Path $raiz 'modelo')
    try {
        & python figuras.py
        if ($LASTEXITCODE -ne 0) { throw 'figuras.py falló' }
    }
    finally { Pop-Location }
}

Push-Location (Join-Path $raiz 'latex')
try {
    foreach ($pasada in 1, 2, 3) {
        & pdflatex -interaction=nonstopmode -halt-on-error main.tex | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Get-Content main.log | Select-String -Pattern '^!' -Context 0, 4 | Out-String | Write-Host
            throw "pdflatex falló en la pasada $pasada (ver latex\main.log)"
        }
    }
    $log = Get-Content main.log -Raw
    if ($log -match 'Output written on main\.pdf \((\d+) page') { Write-Host "Páginas: $($Matches[1])" }
    $avisos = @(Select-String -Path main.log -Pattern 'undefined|Overfull \\hbox \((\d{2,})' | Select-Object -First 12)
    if ($avisos.Count -gt 0) { Write-Warning 'Revisar en main.log:'; $avisos | ForEach-Object { Write-Host "  $($_.Line)" } }
    Copy-Item main.pdf $salida -Force
    Write-Host "PDF: $salida"
}
finally { Pop-Location }

# articulo de congreso
Push-Location (Join-Path $raiz 'latex\congreso')
try {
    foreach ($pasada in 1, 2, 3) {
        & pdflatex -interaction=nonstopmode -halt-on-error articulo.tex | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "pdflatex falló en el artículo (ver latex\congreso\articulo.log)" }
    }
    Copy-Item articulo.pdf (Join-Path $raiz 'Articulo_Congreso_BioBot-Rescue.pdf') -Force
    Write-Host 'PDF: Articulo_Congreso_BioBot-Rescue.pdf'
}
finally { Pop-Location }
