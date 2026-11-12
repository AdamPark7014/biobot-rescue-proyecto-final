# Compila la hoja de una página (latex\hoja.tex) y la deja en la raíz del proyecto.
# Uso:  pwsh -File compilar_hoja.ps1
# Las dos figuras de la hoja las genera modelo\hoja.py.
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
Push-Location (Join-Path $raiz 'latex')
try {
    & pdflatex -interaction=nonstopmode -halt-on-error hoja.tex | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'pdflatex falló (ver latex\hoja.log)' }
    $paginas = (Select-String -Path hoja.log -Pattern 'Output written on hoja.pdf \((\d+) page').Matches[0].Groups[1].Value
    $desbordes = @(Select-String -Path hoja.log -Pattern '^Overfull').Count
    Copy-Item hoja.pdf (Join-Path $raiz 'BioBot-Rescue_en_una_pagina.pdf') -Force
    "hoja: $paginas página(s), $desbordes cajas desbordadas"
}
finally { Pop-Location }
