# Reloj de 50 MHz de la DE10-Lite (MAX10_CLK1_50, PIN_P11)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

# Botones, interruptores y lineas RX son asincronos al reloj (pasan por sincronizadores);
# las salidas van a LED, displays y a las otras tarjetas.
set_false_path -from [get_ports {KEY[*] SW[*] RX1 RX2}]
set_false_path -to   [get_ports {TX1 TX2 LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
