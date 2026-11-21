# Corre los bancos de prueba del proyecto con Icarus Verilog 12.
# Uso (desde cualquier carpeta):  pwsh -File sim\simular.ps1            (ocho bancos, unos minutos)
#                                 pwsh -File sim\simular.ps1 -Completa  (ademas tb_tri, cerca de una hora)
# Antes regenera los vectores con el modelo de referencia en Python.
# Deja un .log por banco en sim\.
$ErrorActionPreference = 'Stop'
$sim = $PSScriptRoot
$hdl = Join-Path $PSScriptRoot '..\hdl'
$env:PATH = "C:\iverilog\bin;$env:PATH"

Push-Location (Join-Path $PSScriptRoot '..\modelo')
try { & python politica_ref.py; if ($LASTEXITCODE -ne 0) { throw 'politica_ref.py falló' } }
finally { Pop-Location }

$nucleo = @("$hdl\ventana_termica.v", "$hdl\detectores.v", "$hdl\fsm_politica.v", "$hdl\gen_estimulo.v", "$hdl\nucleo_biobot.v")
$serie  = @("$hdl\uart_rx.v", "$hdl\uart_tx.v", "$hdl\enlace_serie.v", "$hdl\top_biobot_de10lite.v")
$bancos = @(
    @{ tb = 'tb_gen_estimulo'; src = @("$hdl\gen_estimulo.v") },
    @{ tb = 'tb_nucleo';       src = $nucleo },
    @{ tb = 'tb_top';          src = $nucleo + $serie },
    # Demostración en una tarjeta y montaje con dos tarjetas (lazo cerrado con el insecto de prueba)
    @{ tb = 'tb_demo';         src = $nucleo + $serie + @("$hdl\insecto_sim.v", "$hdl\top_demo_de10lite.v") },
    @{ tb = 'tb_dos_tarjetas'; src = $nucleo + $serie + @("$hdl\insecto_sim.v", "$hdl\top_insecto_de10lite.v") },
    # Red de tres tarjetas: boton, puente y receptor
    @{ tb = 'tb_red';          src = @("$hdl\uart_rx.v", "$hdl\uart_tx.v", "$hdl\red_mochilas.v") },
    # Red de deteccion y triangulacion: CORDIC y divisor, detector de tonos y las tres FPGA
    @{ tb = 'tb_cordic';       src = @("$hdl\cordic.v") },
    @{ tb = 'tb_tonos';        src = @("$hdl\tonos.v") }
)
# tb_tri (las tres FPGA con nueve escenarios) tarda cerca de una hora: solo corre con -Completa
if ($args -contains '-Completa') {
    $bancos += @{ tb = 'tb_tri'; src = $nucleo + @("$hdl\uart_rx.v", "$hdl\uart_tx.v", "$hdl\cordic.v", "$hdl\tonos.v", "$hdl\tri_red.v") }
}
Push-Location $sim
try {
    foreach ($b in $bancos) {
        $tb = $b.tb
        & iverilog -g2005 -Wall -s $tb -o "$tb.out" "$tb.v" @($b.src)
        if ($LASTEXITCODE -ne 0) { throw "iverilog falló en $tb" }
        & vvp -n "$tb.out" | Tee-Object -FilePath "$tb.log" | Select-String 'RESULTADO|ERROR|MEDIDA' -NoEmphasis
    }
}
finally { Pop-Location }
