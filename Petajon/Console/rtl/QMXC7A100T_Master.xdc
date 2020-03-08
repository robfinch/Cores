## This file is a general .xdc for the QMTECH XC7A100T-2
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


#Clock Signal
set_clock_groups -asynchronous \
-group { \
clk_pll_i \
} \
-group { \
clk20_Petajon_clkgen \
clk40_Petajon_clkgen \
} \
-group { \
clk100_Petajon_clkgen \
clk200_Petajon_clkgen \
} \
-group { \
clk14_Petajon_clkgen \
} \
-group { \
clk8_Petajon_clkgen \
}

#DDR3
set_property IOSTANDARD LVCMOS33 [get_ports init_calib_complete]
set_property PACKAGE_PIN J25 [get_ports init_calib_complete]

set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dqs_p[0]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dqs_n[0]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dqs_p[1]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dqs_n[1]}]

set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[0]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[1]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[2]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[3]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[4]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[5]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[6]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[7]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[8]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[9]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[10]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[11]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[12]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[13]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[14]}]
set_property IBUF_LOW_PWR FALSE [get_ports {ddr3_dq[15]}]

set_property PACKAGE_PIN D26 [get_ports {FA[0]}]
set_property PACKAGE_PIN D25 [get_ports {FA[1]}]
set_property PACKAGE_PIN G26 [get_ports {FA[2]}]
set_property PACKAGE_PIN E23 [get_ports {FA[3]}]
set_property PACKAGE_PIN F23 [get_ports {FA[4]}]
set_property PACKAGE_PIN J26 [get_ports {FA[5]}]
set_property PACKAGE_PIN G21 [get_ports {FA[6]}]
set_property PACKAGE_PIN H22 [get_ports {FA[7]}]
set_property PACKAGE_PIN J21 [get_ports {FA[8]}]
set_property PACKAGE_PIN K26 [get_ports {FA[9]}]
set_property PACKAGE_PIN K23 [get_ports {FA[10]}]
set_property PACKAGE_PIN M26 [get_ports {FA[11]}]
set_property PACKAGE_PIN L23 [get_ports {FA[12]}]
set_property PACKAGE_PIN P26 [get_ports {FA[13]}]
set_property PACKAGE_PIN M25 [get_ports {FA[14]}]
set_property PACKAGE_PIN N22 [get_ports {FA[15]}]
set_property PACKAGE_PIN P24 [get_ports {FA[16]}]
set_property PACKAGE_PIN P25 [get_ports {FA[17]}]
set_property PACKAGE_PIN T25 [get_ports {FA[18]}]
set_property PACKAGE_PIN V21 [get_ports {FA[19]}]
set_property PACKAGE_PIN W23 [get_ports {FA[20]}]
set_property PACKAGE_PIN Y23 [get_ports {FA[21]}]
set_property PACKAGE_PIN AA25 [get_ports {FA[22]}]
set_property PACKAGE_PIN Y21 [get_ports {FA[23]}]
set_property PACKAGE_PIN AC24 [get_ports {FA[24]}]
set_property PACKAGE_PIN Y26 [get_ports {FA[25]}]
set_property PACKAGE_PIN AC26 [get_ports {FA[26]}]

set_property PACKAGE_PIN F2 [get_ports {FD[0]}]
set_property PACKAGE_PIN E1 [get_ports {FD[1]}]
set_property PACKAGE_PIN C1 [get_ports {FD[2]}]
set_property PACKAGE_PIN E5 [get_ports {FD[3]}]
set_property PACKAGE_PIN C4 [get_ports {FD[4]}]
set_property PACKAGE_PIN A3 [get_ports {FD[5]}]
set_property PACKAGE_PIN B4 [get_ports {FD[6]}]
set_property PACKAGE_PIN B5 [get_ports {FD[7]}]
set_property PACKAGE_PIN M4 [get_ports {FD[8]}]
set_property PACKAGE_PIN L5 [get_ports {FD[9]}]
set_property PACKAGE_PIN N2 [get_ports {FD[10]}]
set_property PACKAGE_PIN M2 [get_ports {FD[11]}]
set_property PACKAGE_PIN H9 [get_ports {FD[12]}]
set_property PACKAGE_PIN H2 [get_ports {FD[13]}]
set_property PACKAGE_PIN G2 [get_ports {FD[14]}]
set_property PACKAGE_PIN G4 [get_ports {FD[15]}]

set_property PACKAGE_PIN L22 [get_ports {FSBHE}]
set_property PACKAGE_PIN J25 [get_ports {FALE}]

#set_property PACKAGE_PIN F22 [get_ports {ANA[0]}]
#set_property PACKAGE_PIN J4 [get_ports {ANA[1]}]
#set_property PACKAGE_PIN H4 [get_ports {ANA[2]}]

set_property -dict { PACKAGE_PIN E26 IOSTANDARD LVCMOS33 } [get_ports {KBDDAT}]
set_property -dict { PACKAGE_PIN E25 IOSTANDARD LVCMOS33 } [get_ports {KBDCLK}]
set_property PULLUP true [get_ports {KBDDAT}]
set_property PULLUP true [get_ports {KBDCLK}]

set_property -dict { PACKAGE_PIN H26 IOSTANDARD LVCMOS33 } [get_ports {MSEDAT}]
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS33 } [get_ports {MSECLK}]
set_property PULLUP true [get_ports {MSEDAT}]
set_property PULLUP true [get_ports {MSECLK}]

# VGA
set_property PACKAGE_PIN AB24 [get_ports {RED[0]}]
set_property PACKAGE_PIN W21 [get_ports {RED[1]}]
set_property PACKAGE_PIN Y25 [get_ports {RED[2]}]
set_property PACKAGE_PIN Y22 [get_ports {RED[3]}]
set_property PACKAGE_PIN V23 [get_ports {GREEN[0]}]
set_property PACKAGE_PIN U21 [get_ports {GREEN[1]}]
set_property PACKAGE_PIN T24 [get_ports {GREEN[2]}]
set_property PACKAGE_PIN R25 [get_ports {GREEN[3]}]
set_property PACKAGE_PIN P23 [get_ports {BLUE[0]}]
set_property PACKAGE_PIN N21 [get_ports {BLUE[1]}]
set_property PACKAGE_PIN M24 [get_ports {BLUE[2]}]
set_property PACKAGE_PIN R26 [get_ports {BLUE[3]}]
set_property PACKAGE_PIN W25 [get_ports {VS}]
set_property PACKAGE_PIN AB26 [get_ports {HS}]

set_property PACKAGE_PIN J26 [get_ports tg_compare_error]
set_property IOSTANDARD LVCMOS33 [get_ports tg_compare_error]

set_property PACKAGE_PIN J19 [get_ports led_1]
set_property IOSTANDARD LVCMOS33 [get_ports led_1]

set_property IOSTANDARD LVCMOS33 [get_ports clk8]
set_property PACKAGE_PIN N3 [get_ports clk8]
set_property IOSTANDARD LVCMOS33 [get_ports clk14]
set_property PACKAGE_PIN N3 [get_ports clk14]
set_property PACKAGE_PIN K5 [get_ports clk14]

set_property IOSTANDARD LVCMOS33 [get_ports sys_clk_i]

set_property PACKAGE_PIN U22 [get_ports sys_clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk]

