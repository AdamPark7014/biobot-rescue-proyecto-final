#!/usr/bin/env bash
# correr_flujo.sh - Corre el flujo RTL-a-GDS de LibreLane (sky130A) con el nucleo de BioBot-Rescue
# y junta en resultados/ lo que se versiona: GDS final, metricas, resumen de tiempos y captura.
# Se corre DENTRO de la VM, desde una copia de la carpeta del proyecto (hdl/ y layout/).
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

# Captura del GDS con los colores de capa de la PDK
PDK_ROOT="${PDK_ROOT:-$HOME/.ciel}"
LYP="$(find "$PDK_ROOT" -path '*sky130A/libs.tech/klayout/tech/sky130A.lyp' | head -1)"
klayout -zz -r captura_klayout.py \
    -rd gds=resultados/nucleo_biobot.gds -rd lyp="$LYP" -rd png=resultados/nucleo_biobot_klayout.png
# Acercamiento de 25 x 25 micras en el centro del nucleo: se ven las celdas y sus conexiones
klayout -zz -r captura_klayout.py \
    -rd gds=resultados/nucleo_biobot.gds -rd lyp="$LYP" -rd png=resultados/nucleo_biobot_detalle.png \
    -rd zona=96,100,121,125

echo "Resultados en $(pwd)/resultados"
