# Distancia exacta (sim/tb_distancia.v): la raiz cuadrada entera de tri_distancia. Con +casos
# corren los once casos de la demostracion (31 y 32 m en los dos ejes y en diagonal). Se ven
# los dos puntos, la suma de cuadrados, la raiz que se va armando bit por bit y la distancia
# final. Termina con una linea RESULTADO en la consola.
# Sin +casos recorre ademas los dos ejes, el corte de 32 m y 60 000 pares al azar.
# Uso:  do ".../activehdl/simular_distancia.do"   (antes: endsim)

asim +access +r +casos tb_distancia

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
