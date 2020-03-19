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
clk64_Petajon_clkgen3 \
clk320_Petajon_clkgen3 \
} \
-group { \
clk14_Petajon_clkgen \
} \
-group { \
clk8_Petajon_clkgen \
}

#DDR3
#set_property IOSTANDARD LVCMOS33 [get_ports init_calib_complete]
#set_property PACKAGE_PIN J25 [get_ports init_calib_complete]

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

set_property PACKAGE_PIN F2 [get_ports {FAD[0]}]
set_property PACKAGE_PIN E1 [get_ports {FAD[1]}]
set_property PACKAGE_PIN C1 [get_ports {FAD[2]}]
set_property PACKAGE_PIN E5 [get_ports {FAD[3]}]
set_property PACKAGE_PIN C4 [get_ports {FAD[4]}]
set_property PACKAGE_PIN A3 [get_ports {FAD[5]}]
set_property PACKAGE_PIN B4 [get_ports {FAD[6]}]
set_property PACKAGE_PIN B5 [get_ports {FAD[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FAD[7]}]

set_property PACKAGE_PIN J25 [get_ports {FBEN}]

set_property IOSTANDARD LVCMOS33 [get_ports {FBEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FIRQ[10]}]


set_property PACKAGE_PIN G4 [get_ports {FALE}]
set_property IOSTANDARD LVCMOS33 [get_ports {FALE}]
set_property PACKAGE_PIN F23 [get_ports {RDYN}]
set_property IOSTANDARD LVCMOS33 [get_ports {RDYN}]

#set_property PACKAGE_PIN F22 [get_ports {ANA[0]}]
#set_property PACKAGE_PIN J4 [get_ports {ANA[1]}]
#set_property PACKAGE_PIN H4 [get_ports {ANA[2]}]

set_property PACKAGE_PIN E26 [get_ports {KBDDAT}]
set_property PACKAGE_PIN E25 [get_ports {KBDCLK}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBDDAT}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBDCLK}]
set_property PULLUP true [get_ports {KBDDAT}]
set_property PULLUP true [get_ports {KBDCLK}]

set_property PACKAGE_PIN H26 [get_ports {MSEDAT}]
set_property PACKAGE_PIN G22 [get_ports {MSECLK}]
set_property IOSTANDARD LVCMOS33 [get_ports {MSEDAT}]
set_property IOSTANDARD LVCMOS33 [get_ports {MSECLK}]
set_property PULLUP true [get_ports {MSEDAT}]
set_property PULLUP true [get_ports {MSECLK}]

# Uart
set_property PACKAGE_PIN AB24 [get_ports {uart_rxd}]
set_property PACKAGE_PIN AC24 [get_ports {uart_txd}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rxd}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_txd}]

# RNG
set_property PACKAGE_PIN H9 [get_ports {randi}]
set_property IOSTANDARD LVCMOS33 [get_ports {randi}]

set_property PACKAGE_PIN A5 [get_ports {FDIOWN}]
set_property PACKAGE_PIN A4 [get_ports {FDIORN}]
set_property PACKAGE_PIN A2 [get_ports {FCS1FXN}]
set_property PACKAGE_PIN C2 [get_ports {FCS3FXN}]
set_property PACKAGE_PIN D4 [get_ports {INTRQ}]
set_property PACKAGE_PIN D5 [get_ports {DDIR}]
set_property PACKAGE_PIN B1 [get_ports {DBENN}]
set_property PACKAGE_PIN D1 [get_ports {RESETN}]
set_property PACKAGE_PIN G2 [get_ports {EN138}]
set_property PULLUP true [get_ports {RESETN}]
set_property IOSTANDARD LVCMOS33 [get_ports {FDIOWN}]
set_property IOSTANDARD LVCMOS33 [get_ports {FDIORN}]
set_property IOSTANDARD LVCMOS33 [get_ports {FCS1FXN}]
set_property IOSTANDARD LVCMOS33 [get_ports {FCS3FXN}]
set_property IOSTANDARD LVCMOS33 [get_ports {INTRQ}]
set_property IOSTANDARD LVCMOS33 [get_ports {DDIR}]
set_property IOSTANDARD LVCMOS33 [get_ports {DBENN}]
set_property IOSTANDARD LVCMOS33 [get_ports {RESETN}]
set_property IOSTANDARD LVCMOS33 [get_ports {EN138}]


# Bus master control
set_property PACKAGE_PIN D25 [get_ports {FMRQ[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[0]}]
set_property PACKAGE_PIN G26 [get_ports {FMRQ[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[1]}]
set_property PACKAGE_PIN E23 [get_ports {FMRQ[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[2]}]
set_property PACKAGE_PIN E2 [get_ports {FMRQ[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[3]}]
set_property PACKAGE_PIN F4 [get_ports {FMRQ[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[4]}]
set_property PACKAGE_PIN G1 [get_ports {FMRQ[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[5]}]
set_property PACKAGE_PIN J26 [get_ports {FMRQ[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FMRQ[6]}]

set_property PACKAGE_PIN V21 [get_ports {MS[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {MS[0]}]
set_property PACKAGE_PIN W23 [get_ports {MS[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {MS[1]}]
set_property PACKAGE_PIN Y23 [get_ports {MS[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {MS[2]}]

# HDMI
set_property -dict {PACKAGE_PIN AC26 IOSTANDARD TMDS_33} [get_ports HCLKN]
set_property -dict {PACKAGE_PIN AB26 IOSTANDARD TMDS_33} [get_ports HCLKP]
set_property -dict {PACKAGE_PIN Y26 IOSTANDARD TMDS_33} [get_ports {HD0N}]
set_property -dict {PACKAGE_PIN W25 IOSTANDARD TMDS_33} [get_ports {HD0P}]
set_property -dict {PACKAGE_PIN AA25 IOSTANDARD TMDS_33} [get_ports {HD1N}]
set_property -dict {PACKAGE_PIN Y25 IOSTANDARD TMDS_33} [get_ports {HD1P}]
set_property -dict {PACKAGE_PIN Y21 IOSTANDARD TMDS_33} [get_ports {HD2N}]
set_property -dict {PACKAGE_PIN W21 IOSTANDARD TMDS_33} [get_ports {HD2P}]

# Serial Bus Transmit
set_property -dict {PACKAGE_PIN L4 IOSTANDARD TMDS_33} [get_ports {FTCLKN}]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD TMDS_33} [get_ports {FTCLKP}]
set_property -dict {PACKAGE_PIN K5 IOSTANDARD TMDS_33} [get_ports {FTDAT0N}]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD TMDS_33} [get_ports {FTDAT0P}]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD TMDS_33} [get_ports {FTDAT1N}]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD TMDS_33} [get_ports {FTDAT1P}]
set_property -dict {PACKAGE_PIN M1 IOSTANDARD TMDS_33} [get_ports {FTDAT2N}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD TMDS_33} [get_ports {FTDAT2P}]
set_property IODELAY_GROUP iodelay0 [get_ports {FTCLKN, FTCLKP, FTDAT0N, FTDAT0P, FTDAT1N, FTDAT1P, FTDAT2N, FTDAT2P}]
set_property IODELAY_GROUP iodelay0 [get_cells uopcr1/TMDS_ClockingX/IDelayCtrlX]
set_property -dict {PACKAGE_PIN H1 IOSTANDARD TMDS_33} [get_ports {FTDAT3N}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD TMDS_33} [get_ports {FTDAT3P}]
set_property -dict {PACKAGE_PIN L2 IOSTANDARD TMDS_33} [get_ports {FTDAT4N}]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD TMDS_33} [get_ports {FTDAT4P}]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD TMDS_33} [get_ports {FTDAT5N}]
set_property -dict {PACKAGE_PIN N3 IOSTANDARD TMDS_33} [get_ports {FTDAT5P}]
set_property -dict {PACKAGE_PIN P3 IOSTANDARD TMDS_33} [get_ports {FTDAT6N}]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD TMDS_33} [get_ports {FTDAT6P}]
set_property IODELAY_GROUP iodelay1 [get_ports {FTDAT3N, FTDAT3P, FTDAT4N, FTDAT4P, FTDAT5N, FTDAT5P, FTDAT6N, FTDAT6P}]
set_property IODELAY_GROUP iodelay1 [get_cells uopcr2/TMDS_ClockingX/IDelayCtrlX]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD TMDS_33} [get_ports {FTDAT7N}]
set_property -dict {PACKAGE_PIN R1 IOSTANDARD TMDS_33} [get_ports {FTDAT7P}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD TMDS_33} [get_ports {FTDAT8N}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD TMDS_33} [get_ports {FTDAT8P}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD TMDS_33} [get_ports {FTDAT9N}]
set_property -dict {PACKAGE_PIN T2 IOSTANDARD TMDS_33} [get_ports {FTDAT9P}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD TMDS_33} [get_ports {FTDAT10N}]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD TMDS_33} [get_ports {FTDAT10P}]
set_property IODELAY_GROUP iodelay2 [get_ports {FTDAT7N, FTDAT7P, FTDAT8N, FTDAT8P, FTDAT9N, FTDAT9P, FTDAT10N, FTDAT10P}]
set_property IODELAY_GROUP iodelay2 [get_cells uopcr3/TMDS_ClockingX/IDelayCtrlX]

# Serial Bus Receive
set_property -dict {PACKAGE_PIN T25 IOSTANDARD TMDS_33} [get_ports {FRCLKN}]
set_property -dict {PACKAGE_PIN T24 IOSTANDARD TMDS_33} [get_ports {FRCLKP}]
set_property -dict {PACKAGE_PIN P25 IOSTANDARD TMDS_33} [get_ports {FRDAT0N}]
set_property -dict {PACKAGE_PIN R25 IOSTANDARD TMDS_33} [get_ports {FRDAT0P}]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD TMDS_33} [get_ports {FRDAT1N}]
set_property -dict {PACKAGE_PIN N21 IOSTANDARD TMDS_33} [get_ports {FRDAT1P}]
set_property -dict {PACKAGE_PIN P26 IOSTANDARD TMDS_33} [get_ports {FRDAT2N}]
set_property -dict {PACKAGE_PIN R26 IOSTANDARD TMDS_33} [get_ports {FRDAT2P}]
set_property -dict {PACKAGE_PIN K23 IOSTANDARD TMDS_33} [get_ports {FRDAT3N}]
set_property -dict {PACKAGE_PIN K22 IOSTANDARD TMDS_33} [get_ports {FRDAT3P}]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD TMDS_33} [get_ports {FRDAT4N}]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD TMDS_33} [get_ports {FRDAT4P}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD TMDS_33} [get_ports {FRDAT5N}]
set_property -dict {PACKAGE_PIN H21 IOSTANDARD TMDS_33} [get_ports {FRDAT5P}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD TMDS_33} [get_ports {FRDAT6N}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD TMDS_33} [get_ports {FRDAT6P}]
set_property -dict {PACKAGE_PIN K26 IOSTANDARD TMDS_33} [get_ports {FRDAT7N}]
set_property -dict {PACKAGE_PIN K25 IOSTANDARD TMDS_33} [get_ports {FRDAT7P}]
set_property -dict {PACKAGE_PIN M25 IOSTANDARD TMDS_33} [get_ports {FRDAT8N}]
set_property -dict {PACKAGE_PIN M24 IOSTANDARD TMDS_33} [get_ports {FRDAT8P}]
set_property -dict {PACKAGE_PIN L23 IOSTANDARD TMDS_33} [get_ports {FRDAT9N}]
set_property -dict {PACKAGE_PIN L22 IOSTANDARD TMDS_33} [get_ports {FRDAT9P}]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD TMDS_33} [get_ports {FRDAT10N}]
set_property -dict {PACKAGE_PIN N21 IOSTANDARD TMDS_33} [get_ports {FRDAT10P}]
set_property PULLUP true [get_ports {FRCLKN}]
set_property PULLUP true [get_ports {FRCLKP}]
set_property PULLUP true [get_ports {FRDAT0N}]
set_property PULLUP true [get_ports {FRDAT1N}]
set_property PULLUP true [get_ports {FRDAT2N}]
set_property PULLUP true [get_ports {FRDAT3N}]
set_property PULLUP true [get_ports {FRDAT4N}]
set_property PULLUP true [get_ports {FRDAT5N}]
set_property PULLUP true [get_ports {FRDAT6N}]
set_property PULLUP true [get_ports {FRDAT7N}]
set_property PULLUP true [get_ports {FRDAT8N}]
set_property PULLUP true [get_ports {FRDAT9N}]
set_property PULLUP true [get_ports {FRDAT10N}]
set_property PULLUP true [get_ports {FRDAT0P}]
set_property PULLUP true [get_ports {FRDAT1P}]
set_property PULLUP true [get_ports {FRDAT2P}]
set_property PULLUP true [get_ports {FRDAT3P}]
set_property PULLUP true [get_ports {FRDAT4P}]
set_property PULLUP true [get_ports {FRDAT5P}]
set_property PULLUP true [get_ports {FRDAT6P}]
set_property PULLUP true [get_ports {FRDAT7P}]
set_property PULLUP true [get_ports {FRDAT8P}]
set_property PULLUP true [get_ports {FRDAT9P}]
set_property PULLUP true [get_ports {FRDAT10P}]
 
# VGA

set_property PACKAGE_PIN P6 [get_ports {AUD}]
set_property IOSTANDARD LVCMOS33 [get_ports {AUD}]

#set_property PACKAGE_PIN J26 [get_ports tg_compare_error]
#set_property IOSTANDARD LVCMOS33 [get_ports tg_compare_error]

set_property PACKAGE_PIN J19 [get_ports led_1]
set_property IOSTANDARD LVCMOS33 [get_ports led_1]

set_property IOSTANDARD LVCMOS33 [get_ports clk8]
set_property PACKAGE_PIN N3 [get_ports clk8]
set_property IOSTANDARD LVCMOS33 [get_ports clk14]
set_property PACKAGE_PIN K5 [get_ports clk14]

set_property IOSTANDARD LVCMOS33 [get_ports sys_clk_i]

set_property PACKAGE_PIN U22 [get_ports sys_clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk]

