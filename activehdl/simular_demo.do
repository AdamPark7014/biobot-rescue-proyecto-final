# Demostracion en una tarjeta: los cuatro escenarios con el lazo cerrado
# (insecto de prueba + nucleo). El primero es el de la persona: el estado pasa
# de 1 (explorar) a 4 (acercar), 5 (confirmar) y 6 (alertar).
# Uso:  do ".../activehdl/simular_demo.do"   (si hay una simulacion activa, antes: endsim)

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
