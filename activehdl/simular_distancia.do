# Distancia exacta (sim/tb_distancia.v): la raiz cuadrada entera de tri_distancia, comparada
# contra el valor exacto en los dos ejes, en todos los puntos alrededor del corte de 32 m y en
# 60 000 pares al azar. Se ven los dos puntos, la suma de cuadrados, la raiz que se va
# armando bit por bit y la distancia final. Termina con una linea RESULTADO en la consola.
# Uso:  do ".../activehdl/simular_distancia.do"   (antes: endsim)

asim +access +r tb_distancia

wave /tb_distancia/clk
wave /tb_distancia/start
wave -radix unsigned /tb_distancia/x1
wave -radix unsigned /tb_distancia/y1
wave -radix unsigned /tb_distancia/x2
wave -radix unsigned /tb_distancia/y2
wave -radix unsigned /tb_distancia/dut/n2
wave -radix unsigned /tb_distancia/dut/k
wave -radix unsigned /tb_distancia/dut/r
wave -radix unsigned /tb_distancia/dut/q
wave /tb_distancia/listo
wave -radix unsigned /tb_distancia/d

run -all
