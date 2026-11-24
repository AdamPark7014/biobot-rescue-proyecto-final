#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source "$HOME/librelane-venv/bin/activate"

TAG="${TAG:-nucleo}"
sg docker -c "librelane --dockerized --pdk sky130A --run-tag $TAG --overwrite config.json"

R="runs/$TAG"
mkdir -p resultados
cp "$R/final/gds/nucleo_biobot.gds" resultados/
cp "$R/final/metrics.json" resultados/
cp "$(ls -d "$R"/*-openroad-stapostpnr | tail -1)/summary.rpt" resultados/sta_resumen.rpt
cp "$R"/*-yosys-synthesis/reports/stat.rpt resultados/sintesis_celdas.rpt
cp "$R"/*-netgen-lvs/reports/lvs.netgen.rpt resultados/lvs.rpt
cp "$R/final/render/nucleo_biobot.png" resultados/nucleo_biobot_render_librelane.png

PDK_ROOT="${PDK_ROOT:-$HOME/.ciel}"
LYP="$(find "$PDK_ROOT" -path '*sky130A/libs.tech/klayout/tech/sky130A.lyp' | head -1)"
klayout -zz -r captura_klayout.py \
    -rd gds=resultados/nucleo_biobot.gds -rd lyp="$LYP" -rd png=resultados/nucleo_biobot_klayout.png
klayout -zz -r captura_klayout.py \
    -rd gds=resultados/nucleo_biobot.gds -rd lyp="$LYP" -rd png=resultados/nucleo_biobot_detalle.png \
    -rd zona=96,100,121,125

echo "Resultados en $(pwd)/resultados"
