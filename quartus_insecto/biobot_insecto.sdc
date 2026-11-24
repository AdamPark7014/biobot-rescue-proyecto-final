create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

# entradas asincronas
set_false_path -from [get_ports {RESET_N UART_RX SW[*]}]
set_false_path -to   [get_ports {UART_TX LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
