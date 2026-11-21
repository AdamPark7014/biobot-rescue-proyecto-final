# CORDIC y divisor (sim/tb_cordic.v): 24 vectores en vectorizacion, 24 angulos en
# rotacion y 200 divisiones, comparados contra el valor exacto. Termina con una linea
# RESULTADO en la consola.
# Uso:  do ".../activehdl/simular_cordic.do"   (antes: endsim)

asim +access +r tb_cordic

wave /tb_cordic/clk
wave /tb_cordic/start
wave /tb_cordic/modo
wave -radix decimal  /tb_cordic/x0
wave -radix decimal  /tb_cordic/y0
wave -radix unsigned /tb_cordic/z0
wave /tb_cordic/listo
wave -radix decimal  /tb_cordic/x
wave -radix decimal  /tb_cordic/y
wave -radix decimal  /tb_cordic/z
wave -radix unsigned /tb_cordic/dut/i
wave /tb_cordic/dstart
wave -radix unsigned /tb_cordic/num
wave -radix unsigned /tb_cordic/den
wave -radix unsigned /tb_cordic/coc
wave /tb_cordic/dlisto

run -all
