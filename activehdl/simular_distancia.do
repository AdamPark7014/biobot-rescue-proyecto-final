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
