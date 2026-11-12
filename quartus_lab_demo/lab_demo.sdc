# Reloj de 50 MHz de la DE10-Lite (MAX10_CLK1_50, PIN_P11)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

# El boton de reset y los interruptores son asincronos al reloj (pasan por
# sincronizadores) y las salidas van a LEDs y displays.
set_false_path -from [get_ports {RESET_N SW[*]}]
set_false_path -to   [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*] ESTIMULO[*]}]
