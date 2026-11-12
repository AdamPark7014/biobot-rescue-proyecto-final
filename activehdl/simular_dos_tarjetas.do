# Dos tarjetas unidas solo por UART: la mochila y la tarjeta insecto.
# Se ven las dos lineas serie, lo que decide la mochila y lo que la tarjeta
# insecto recibe de vuelta.
# Uso:  do ".../activehdl/simular_dos_tarjetas.do"   (antes: endsim)

asim +access +r tb_dos_tarjetas

wave /tb_dos_tarjetas/reset_n
wave /tb_dos_tarjetas/tx_insecto
wave /tb_dos_tarjetas/tx_mochila
wave -radix unsigned /tb_dos_tarjetas/mochila/estado
wave /tb_dos_tarjetas/mochila/alerta
wave -radix unsigned /tb_dos_tarjetas/mochila/n_fil
wave /tb_dos_tarjetas/mochila/disparo
wave -radix unsigned /tb_dos_tarjetas/mochila/canal
wave /tb_dos_tarjetas/insecto/estimulo
wave -radix unsigned /tb_dos_tarjetas/insecto/estado_m
wave -radix unsigned /tb_dos_tarjetas/insecto/dist
wave -radix decimal  /tb_dos_tarjetas/insecto/rumbo
wave /tb_dos_tarjetas/insecto/anda
wave -radix unsigned /tb_dos_tarjetas/cuadros

run -all
