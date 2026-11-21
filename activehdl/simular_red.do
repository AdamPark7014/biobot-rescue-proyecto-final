# Red de tres FPGA: mochila A, mochila B y receptor (sim/tb_tri.v).
# Se ven las dos lineas de radio (UART con CRC-16), el estado y la alerta de cada mochila,
# los rumbos medidos, los tonos que oye cada nodo, el conteo de personas en las tres
# tarjetas, la posicion que triangula el receptor y los LED.
# Con +rapido corre el escenario 1 (triangulacion con puente) y el 9 (umbral de 31 y 32 m):
# unos 12 s simulados.
# Uso:  do ".../activehdl/simular_red.do"   (antes: endsim si hay otra simulacion abierta)
# Para los nueve escenarios: quitar +rapido y correr run -all (tarda bastante mas).

asim +access +r +rapido tb_tri

wave /tb_tri/reset
wave /tb_tri/tx_a
wave /tb_tri/tx_b
wave -radix unsigned /tb_tri/tp_a
wave -radix unsigned /tb_tri/tp_b
wave -radix unsigned /tb_tri/es_a
wave -radix unsigned /tb_tri/es_b
wave -radix unsigned /tb_tri/nf_a
wave -radix unsigned /tb_tri/nf_b
wave /tb_tri/al_a
wave /tb_tri/al_b
wave -radix unsigned /tb_tri/rm_a
wave -radix unsigned /tb_tri/rm_b
wave /tb_tri/tono_a
wave /tb_tri/tono_b
wave /tb_tri/tono_r
wave /tb_tri/ot_a
wave /tb_tri/or_a
wave /tb_tri/ot_b
wave /tb_tri/or_b
wave /tb_tri/oye_ra
wave /tb_tri/oye_rb
wave -radix unsigned /tb_tri/pt_a
wave -radix unsigned /tb_tri/pt_b
wave -radix unsigned /tb_tri/cu_a
wave -radix unsigned /tb_tri/cu_b
wave -radix unsigned /tb_tri/cu_r
wave -radix binary   /tb_tri/enl
wave -radix unsigned /tb_tri/modo
wave -radix unsigned /tb_tri/est_x
wave -radix unsigned /tb_tri/est_y
wave -radix unsigned /tb_tri/d_ab
wave -radix unsigned /tb_tri/perd_a
wave -radix unsigned /tb_tri/perd_b
wave -radix unsigned /tb_tri/malas
wave -radix binary   /tb_tri/led_a
wave -radix binary   /tb_tri/led_b
wave -radix binary   /tb_tri/led_r

run -all
