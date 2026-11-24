asim +access +r tb_tonos

wave /tb_tonos/clk
wave -radix binary   /tb_tonos/presente
wave /tb_tonos/tono
wave /tb_tonos/dut/muestra
wave -radix unsigned /tb_tonos/dut/n
wave -radix decimal  /tb_tonos/dut/x
wave -radix decimal  /tb_tonos/dut/a1
wave -radix decimal  /tb_tonos/dut/b1
wave -radix decimal  /tb_tonos/dut/d1
wave -radix unsigned /tb_tonos/p0
wave -radix unsigned /tb_tonos/p1
wave -radix unsigned /tb_tonos/p2
wave -radix binary   /tb_tonos/oye

run -all
