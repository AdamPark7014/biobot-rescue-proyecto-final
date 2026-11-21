# Prueba la terminal del operador (pc/tri_lib.tcl) contra las tres FPGA simuladas, sin tarjetas.
# Uso:  pwsh -File sim\probar_terminal.ps1          (cerca de una hora)
# 1. La terminal real ejecuta las ordenes de cada paso; los bits que mandaria a las tarjetas
#    quedan en fuentes_sonda.txt.
# 2. tb_sonda.v simula las tres tarjetas con sus modulos superiores y guarda sus sondas.
# 3. La terminal real interpreta esas sondas y se comprueba cada paso. Lo que veria el
#    operador queda en terminal_simulada.txt.
$ErrorActionPreference = 'Stop'
$sim = $PSScriptRoot
$hdl = Join-Path $PSScriptRoot '..\hdl'
$qsh = 'C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_sh.exe'
$env:PATH = "C:\iverilog\bin;$env:PATH"
$fuentes = @("$hdl\ventana_termica.v", "$hdl\detectores.v", "$hdl\fsm_politica.v", "$hdl\gen_estimulo.v",
             "$hdl\nucleo_biobot.v", "$hdl\uart_rx.v", "$hdl\uart_tx.v", "$hdl\cordic.v", "$hdl\tonos.v",
             "$hdl\tri_red.v", "$hdl\tri_top.v")

Push-Location $sim
try {
    & $qsh -t prueba_terminal.tcl genera | Select-String 'RESULTADO|ERROR' -NoEmphasis
    if ($LASTEXITCODE -ne 0) { throw 'la terminal no pudo generar las ordenes' }

    & iverilog -g2005 -Wall -s tb_sonda -o tb_sonda.out tb_sonda.v altsource_probe_sim.v @fuentes
    if ($LASTEXITCODE -ne 0) { throw 'iverilog falló en tb_sonda' }
    & vvp -n tb_sonda.out | Tee-Object -FilePath tb_sonda.log | Select-String 'RESULTADO|ERROR' -NoEmphasis

    & $qsh -t prueba_terminal.tcl revisa | Select-String '^PASO|^    bien|^    FALLA|RESULTADO|ERROR' -NoEmphasis
    if ($LASTEXITCODE -ne 0) { throw 'la prueba de la terminal no pasó' }
}
finally { Pop-Location }
