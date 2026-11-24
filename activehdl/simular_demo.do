asim +access +r tb_demo

wave /tb_demo/reset_n
wave -radix binary   /tb_demo/sw
wave -radix unsigned /tb_demo/dut/estado
wave /tb_demo/dut/alerta
wave /tb_demo/dut/pre
wave /tb_demo/dut/quieto
wave -radix unsigned /tb_demo/dut/n_fil
wave /tb_demo/dut/disparo
wave -radix unsigned /tb_demo/dut/canal
wave -radix binary   /tb_demo/dut/led_on
wave -radix unsigned /tb_demo/dut/cuenta
wave -radix unsigned /tb_demo/dut/dist
wave -radix decimal  /tb_demo/dut/rumbo
wave /tb_demo/dut/anda
wave -radix unsigned /tb_demo/cuadros

run -all
