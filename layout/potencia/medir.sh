#!/bin/bash
set -e
cd "$(dirname "$0")"
RUN="$(cd .. && pwd)/runs/nucleo"
PDK="$(ls -d "${PDK_ROOT:-$HOME/.ciel}"/ciel/sky130/versions/*/sky130A | head -1)"
V=/pdk/libs.ref/sky130_fd_sc_hd/verilog
T="$(mktemp -d)"; chmod 777 "$T"; cp tb_potencia.v potencia.tcl "$T/"

# simulacion del netlist y potencia
docker run --rm -v "$T":/pot -v "$RUN/final":/run/final:ro -v "$PDK":/pdk:ro \
  -e LIBS=/pdk/libs.ref/sky130_fd_sc_hd/lib -w /pot ghcr.io/librelane/librelane:3.0.17 sh -c "
  iverilog -g2005-sv -DFUNCTIONAL -DUNIT_DELAY='#0' -s tb_potencia -o p.vvp tb_potencia.v /run/final/nl/nucleo_biobot.nl.v $V/primitives.v $V/sky130_fd_sc_hd.v &&
  vvp -n p.vvp +modo=0 +vcd=espera.vcd && vvp -n p.vvp +modo=1 +vcd=cuadro.vcd && vvp -n p.vvp +modo=2 +vcd=estimulo.vcd &&
  sta -no_splash -exit potencia.tcl > potencia.rpt 2>&1"
grep -v -E "^Warning" "$T/potencia.rpt" > ../resultados/potencia.rpt
grep -E "^==|^Total" ../resultados/potencia.rpt
