# Reloj de 50 MHz de la DE10-Lite (MAX10_CLK1_50, PIN_P11)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

# RX, el boton de reset y SW0 son asincronos al reloj (pasan por sincronizadores)
# y las salidas van a LEDs, displays y a un dispositivo con su propio reloj.
set_false_path -from [get_ports {RESET_N UART_RX SW0}]
set_false_path -to   [get_ports {UART_TX LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*]}]
