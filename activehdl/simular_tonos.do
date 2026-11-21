# Detector de tonos (sim/tb_tonos.v), visto desde la mochila A: emite 1 kHz y escucha los
# 2 kHz de B y los 4 kHz del receptor con tres filtros de Goertzel. Se ven el tono propio,
# la senal del microfono simulado, el estado de los filtros y los tonos que da por oidos.
# Uso:  do ".../activehdl/simular_tonos.do"   (antes: endsim)

asim +access +r tb_tonos

wave /tb_tonos/clk
wave -radix binary   /tb_tonos/presente
wave /tb_tonos/tono
wave /tb_tonos/dut/muestra
wave -radix unsigned /tb_tonos/dut/n
wave -radix decimal  /tb_tonos/dut/x
wave -radix decimal  /tb_tonos/dut/a1
wave -radix decimal  /tb_tonos/dut/b1
wave -radix decimal  /tb_tonos/dut/d1
wave -radix unsigned /tb_tonos/p0
wave -radix unsigned /tb_tonos/p1
wave -radix unsigned /tb_tonos/p2
wave -radix binary   /tb_tonos/oye

run -all
