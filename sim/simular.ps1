# Corre los bancos de prueba del proyecto con Icarus Verilog 12.
# Uso (desde cualquier carpeta):  pwsh -File sim\simular.ps1            (once bancos, unos minutos)
#                                 pwsh -File sim\simular.ps1 -Completa  (ademas tb_tri: sus nueve escenarios
#                                                                        corren a la vez, unos 5 minutos mas)
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
$red    = $nucleo + @("$hdl\uart_rx.v", "$hdl\uart_tx.v", "$hdl\cordic.v", "$hdl\tonos.v", "$hdl\tri_red.v")
$bancos = @(
    @{ tb = 'tb_gen_estimulo'; src = @("$hdl\gen_estimulo.v") },
    @{ tb = 'tb_nucleo';       src = $nucleo },
    @{ tb = 'tb_top';          src = $nucleo + $serie },
    # Demostración en una tarjeta y montaje con dos tarjetas (lazo cerrado con el insecto de prueba)
    @{ tb = 'tb_demo';         src = $nucleo + $serie + @("$hdl\insecto_sim.v", "$hdl\top_demo_de10lite.v") },
    @{ tb = 'tb_dos_tarjetas'; src = $nucleo + $serie + @("$hdl\insecto_sim.v", "$hdl\top_insecto_de10lite.v") },
    # Red de tres tarjetas: boton, puente y receptor
    @{ tb = 'tb_red';          src = @("$hdl\uart_rx.v", "$hdl\uart_tx.v", "$hdl\red_mochilas.v") },
    # Red de deteccion y triangulacion: CORDIC y divisor, detector de tonos y distancia exacta
    @{ tb = 'tb_cordic';       src = @("$hdl\cordic.v") },
    @{ tb = 'tb_cordic_iter';  src = @("$hdl\cordic.v") },
    @{ tb = 'tb_tonos';        src = @("$hdl\tonos.v") },
    @{ tb = 'tb_pid';          src = @("$hdl\pid_q.v") },
    @{ tb = 'tb_distancia';    src = $red }
)
Push-Location $sim
try {
    foreach ($b in $bancos) {
        $tb = $b.tb
        & iverilog -g2005 -Wall -s $tb -o "$tb.out" "$tb.v" @($b.src)
        if ($LASTEXITCODE -ne 0) { throw "iverilog falló en $tb" }
        & vvp -n "$tb.out" | Tee-Object -FilePath "$tb.log" | Select-String 'RESULTADO|ERROR|MEDIDA' -NoEmphasis
    }
    # tb_tri (las tres FPGA con nueve escenarios) solo corre con -Completa. Cada escenario empieza
    # con un reset, asi que son independientes: se lanza un proceso por escenario y los
    # resultados se juntan en tb_tri.log.
    if ($args -contains '-Completa') {
        & iverilog -g2005 -Wall -s tb_tri -o tb_tri.out tb_tri.v @red
        if ($LASTEXITCODE -ne 0) { throw 'iverilog falló en tb_tri' }
        $procesos = foreach ($k in 1..9) {
            Start-Process -FilePath 'vvp' -ArgumentList @('-n', 'tb_tri.out', "+desde=$k", "+hasta=$k") `
                -WorkingDirectory $sim -RedirectStandardOutput (Join-Path $sim "tb_tri_$k.log") -NoNewWindow -PassThru
        }
        $procesos | Wait-Process
        $bien = 0
        $lineas = foreach ($k in 1..9) {
            $l = Get-Content (Join-Path $sim "tb_tri_$k.log")
            if ($l -match 'RESULTADO tb_tri: 1 de 1 escenarios correctos') { $bien++ }
            $l | Where-Object { $_ -notmatch 'RESULTADO tb_tri|finish called' }
        }
        @($lineas) + "RESULTADO tb_tri: $bien de 9 escenarios correctos" | Set-Content (Join-Path $sim 'tb_tri.log')
        Remove-Item (Join-Path $sim 'tb_tri_?.log')
        Get-Content (Join-Path $sim 'tb_tri.log') | Select-String 'RESULTADO|ERROR|MEDIDA' -NoEmphasis
    }
}
finally { Pop-Location }
