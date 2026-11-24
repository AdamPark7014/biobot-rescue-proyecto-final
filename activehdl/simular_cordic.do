asim +access +r tb_cordic

wave /tb_cordic/clk
wave /tb_cordic/start
wave /tb_cordic/modo
wave -radix decimal  /tb_cordic/x0
wave -radix decimal  /tb_cordic/y0
wave -radix unsigned /tb_cordic/z0
wave /tb_cordic/listo
wave -radix decimal  /tb_cordic/x
wave -radix decimal  /tb_cordic/y
wave -radix decimal  /tb_cordic/z
wave -radix unsigned /tb_cordic/dut/i
wave /tb_cordic/dstart
wave -radix unsigned /tb_cordic/num
wave -radix unsigned /tb_cordic/den
wave -radix unsigned /tb_cordic/coc
wave /tb_cordic/dlisto

run -all
