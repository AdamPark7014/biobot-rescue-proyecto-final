# Regenera las figuras (simulación incluida) y compila el esquema de investigación.
# Uso: pwsh -File compilar.ps1            (figuras + PDF)
#      pwsh -File compilar.ps1 -SoloPdf   (no vuelve a correr la simulación)
param([switch]$SoloPdf)
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$salida = Join-Path $raiz 'Esquema_Investigacion_BioBot-Rescue.pdf'

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
    foreach ($pasada in 1, 2) {
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
