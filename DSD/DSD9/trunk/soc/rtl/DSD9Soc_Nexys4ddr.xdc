## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { xclk }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {xclk}];
create_clock -add -name clk_pll_i -period 13.333 -waveform {0 6.667} [get_pins umpmc1/u_ddr/u_ddr2_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]
create_clock -add -name clk100u -period 53.333 -waveform {0 26.667} [get_pins ucg1/u1/CLKOUT4]
create_clock -add -name clk200u -period 5.000 -waveform {0 2.5} [get_pins ucg1/u1/CLKOUT2]
#create_clock -add -name iserdesA -
#umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/iserdes_clk
#umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/iserdes_clk
create_generated_clock -name cpu_clk -source [get_pins ucg1/u1/CLKIN1] -multiply_by 3 -divide_by 8 [get_pins ucg1/u1/CLKOUT1]
create_generated_clock -name clk85u -source [get_pins ucg1/u1/CLKIN1] -multiply_by 6 -divide_by 7 [get_pins ucg1/u1/CLKOUT0]
create_generated_clock -name mem_ui_clk -source [get_pins umpmc1/u_ddr/u_ddr2_infrastructure/gen_mmcm.mmcm_i/CLKIN1] \
    -divide_by 4 [get_pins umpmc1/u_ddr/u_ddr2_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]
#set_false_path -from [get_clocks ub_sys_clk] -to [get_clocks clkout1]
set_false_path -from [get_clocks clk85u] -to [get_clocks [list cpu_clk mem_ui_clk clk_pll_i]] 
set_false_path -from [get_clocks cpu_clk] -to [get_clocks [list clk85u mem_ui_clk clk_pll_i]]
set_false_path -from [get_clocks clk_pll_i] - to [get_clocks [list cpu_clk clk200u]]
set_false_path -from [get_clocks mem_ui_clk] -to [get_clocks cpu_clk]
set_false_path -from [get_clocks clk100u] -to [get_clocks mem_ui_clk]
set_false_path -from [get_clocks clk200u] -to [get_clocks mem_ui_clk]
 
#Switches

set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L24N_T3_RS0_15 Sch=sw[0]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=sw[1]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L6N_T0_D08_VREF_14 Sch=sw[2]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L13N_T2_MRCC_14 Sch=sw[3]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { sw[4] }]; #IO_L12N_T1_MRCC_14 Sch=sw[4]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { sw[5] }]; #IO_L7N_T1_D10_14 Sch=sw[5]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { sw[6] }]; #IO_L17N_T2_A13_D29_14 Sch=sw[6]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { sw[7] }]; #IO_L5N_T0_D07_14 Sch=sw[7]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { sw[8] }]; #IO_L24N_T3_34 Sch=sw[8]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { sw[9] }]; #IO_25_34 Sch=sw[9]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { sw[10] }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=sw[10]
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { sw[11] }]; #IO_L23P_T3_A03_D19_14 Sch=sw[11]
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { sw[12] }]; #IO_L24P_T3_35 Sch=sw[12]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { sw[13] }]; #IO_L20P_T3_A08_D24_14 Sch=sw[13]
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { sw[14] }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=sw[14]
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { sw[15] }]; #IO_L21P_T3_DQS_14 Sch=sw[15]

# LEDs

set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L18P_T2_A24_15 Sch=led[0]
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L24P_T3_RS1_15 Sch=led[1]
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_L17N_T2_A25_15 Sch=led[2]
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L8P_T1_D11_14 Sch=led[3]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { led[4] }]; #IO_L7P_T1_D09_14 Sch=led[4]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { led[5] }]; #IO_L18N_T2_A11_D27_14 Sch=led[5]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { led[6] }]; #IO_L17P_T2_A14_D30_14 Sch=led[6]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { led[7] }]; #IO_L18P_T2_A12_D28_14 Sch=led[7]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led[8] }]; #IO_L16N_T2_A15_D31_14 Sch=led[8]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { led[9] }]; #IO_L14N_T2_SRCC_14 Sch=led[9]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { led[10] }]; #IO_L22P_T3_A05_D21_14 Sch=led[10]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { led[11] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=led[11]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { led[12] }]; #IO_L16P_T2_CSI_B_14 Sch=led[12]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { led[13] }]; #IO_L22N_T3_A04_D20_14 Sch=led[13]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { led[14] }]; #IO_L20N_T3_A07_D23_14 Sch=led[14]
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { led[15] }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=led[15]

#set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { led16_b }]; #IO_L5P_T0_D06_14 Sch=led16_b
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { led16_g }]; #IO_L10P_T1_D14_14 Sch=led16_g
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { led16_r }]; #IO_L11P_T1_SRCC_14 Sch=led16_r
#set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led17_b }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=led17_b
#set_property -dict { PACKAGE_PIN R11   IOSTANDARD LVCMOS33 } [get_ports { led17_g }]; #IO_0_14 Sch=led17_g
#set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { led17_r }]; #IO_L11N_T1_SRCC_14 Sch=led17_r

#7 segment display

set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { ssg[0] }]; #IO_L24N_T3_A00_D16_14 Sch=ca
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports { ssg[1] }]; #IO_25_14 Sch=cb
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { ssg[2] }]; #IO_25_15 Sch=cc
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { ssg[3] }]; #IO_L17P_T2_A26_15 Sch=cd
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { ssg[4] }]; #IO_L13P_T2_MRCC_14 Sch=ce
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { ssg[5] }]; #IO_L19P_T3_A10_D26_14 Sch=cf
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { ssg[6] }]; #IO_L4P_T0_D04_14 Sch=cg

set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { ssg[7] }]; #IO_L19N_T3_A21_VREF_15 Sch=dp

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { an[0] }]; #IO_L23P_T3_FOE_B_15 Sch=an[0]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { an[1] }]; #IO_L23N_T3_FWE_B_15 Sch=an[1]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { an[2] }]; #IO_L24P_T3_A01_D17_14 Sch=an[2]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { an[3] }]; #IO_L19P_T3_A22_15 Sch=an[3]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { an[4] }]; #IO_L8N_T1_D12_14 Sch=an[4]
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { an[5] }]; #IO_L14P_T2_SRCC_14 Sch=an[5]
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { an[6] }]; #IO_L23P_T3_35 Sch=an[6]
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { an[7] }]; #IO_L23N_T3_A02_D18_14 Sch=an[7]

#Buttons

set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { cpu_resetn }]; #IO_L3P_T0_DQS_AD1P_15 Sch=cpu_resetn

set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { btnc }]; #IO_L9P_T1_DQS_14 Sch=btnc
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { btnu }]; #IO_L4N_T0_D05_14 Sch=btnu
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { btnl }]; #IO_L12P_T1_MRCC_14 Sch=btnl
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { btnr }]; #IO_L10N_T1_D15_14 Sch=btnr
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { btnd }]; #IO_L9N_T1_DQS_D13_14 Sch=btnd

##PWM Audio Amplifier
set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { aud_pwm }];   #IO_L4N_T0_15
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { aud_sd }];    #IO_L6P_T0_15


#VGA Connector

set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { red[0] }]; #IO_L8N_T1_AD14N_35 Sch=vga_r[0]
set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { red[1] }]; #IO_L7N_T1_AD6N_35 Sch=vga_r[1]
set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { red[2] }]; #IO_L1N_T0_AD4N_35 Sch=vga_r[2]
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { red[3] }]; #IO_L8P_T1_AD14P_35 Sch=vga_r[3]

set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { green[0] }]; #IO_L1P_T0_AD4P_35 Sch=vga_g[0]
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { green[1] }]; #IO_L3N_T0_DQS_AD5N_35 Sch=vga_g[1]
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { green[2] }]; #IO_L2N_T0_AD12N_35 Sch=vga_g[2]
set_property -dict { PACKAGE_PIN A6    IOSTANDARD LVCMOS33 } [get_ports { green[3] }]; #IO_L3P_T0_DQS_AD5P_35 Sch=vga_g[3]

set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { blue[0] }]; #IO_L2P_T0_AD12P_35 Sch=vga_b[0]
set_property -dict { PACKAGE_PIN C7    IOSTANDARD LVCMOS33 } [get_ports { blue[1] }]; #IO_L4N_T0_35 Sch=vga_b[1]
set_property -dict { PACKAGE_PIN D7    IOSTANDARD LVCMOS33 } [get_ports { blue[2] }]; #IO_L6N_T0_VREF_35 Sch=vga_b[2]
set_property -dict { PACKAGE_PIN D8    IOSTANDARD LVCMOS33 } [get_ports { blue[3] }]; #IO_L4P_T0_35 Sch=vga_b[3]

set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { hSync }]; #IO_L4P_T0_15 Sch=vga_hs
set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33 } [get_ports { vSync }]; #IO_L3N_T0_DQS_AD1N_15 Sch=vga_vs

# Uart

set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { UartTx }]; #IO_L11N_T1_SRCC_35
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { UartRx }]; #IO_L7P_T1_AD6P_35

#USB HID (PS/2)

set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33 } [get_ports { kclk }]; #IO_L13P_T2_MRCC_35 Sch=ps2_clk
set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33 } [get_ports { kd }]; #IO_L10N_T1_AD15N_35 Sch=ps2_data

#DDR2

set_property SLEW FAST [get_ports {ddr2_dq[0]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[0]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[0]}]
set_property PACKAGE_PIN R7 [get_ports {ddr2_dq[0]}]

set_property SLEW FAST [get_ports {ddr2_dq[1]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[1]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[1]}]
set_property PACKAGE_PIN V6 [get_ports {ddr2_dq[1]}]

set_property SLEW FAST [get_ports {ddr2_dq[2]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[2]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[2]}]
set_property PACKAGE_PIN R8 [get_ports {ddr2_dq[2]}]

set_property SLEW FAST [get_ports {ddr2_dq[3]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[3]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[3]}]
set_property PACKAGE_PIN U7 [get_ports {ddr2_dq[3]}]

set_property SLEW FAST [get_ports {ddr2_dq[4]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[4]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[4]}]
set_property PACKAGE_PIN V7 [get_ports {ddr2_dq[4]}]

set_property SLEW FAST [get_ports {ddr2_dq[5]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[5]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[5]}]
set_property PACKAGE_PIN R6 [get_ports {ddr2_dq[5]}]

set_property SLEW FAST [get_ports {ddr2_dq[6]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[6]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[6]}]
set_property PACKAGE_PIN U6 [get_ports {ddr2_dq[6]}]

set_property SLEW FAST [get_ports {ddr2_dq[7]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[7]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[7]}]
set_property PACKAGE_PIN R5 [get_ports {ddr2_dq[7]}]

set_property SLEW FAST [get_ports {ddr2_dq[8]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[8]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[8]}]
set_property PACKAGE_PIN T5 [get_ports {ddr2_dq[8]}]

set_property SLEW FAST [get_ports {ddr2_dq[9]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[9]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[9]}]
set_property PACKAGE_PIN U3 [get_ports {ddr2_dq[9]}]

set_property SLEW FAST [get_ports {ddr2_dq[10]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[10]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[10]}]
set_property PACKAGE_PIN V5 [get_ports {ddr2_dq[10]}]

set_property SLEW FAST [get_ports {ddr2_dq[11]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[11]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[11]}]
set_property PACKAGE_PIN U4 [get_ports {ddr2_dq[11]}]

set_property SLEW FAST [get_ports {ddr2_dq[12]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[12]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[12]}]
set_property PACKAGE_PIN V4 [get_ports {ddr2_dq[12]}]

set_property SLEW FAST [get_ports {ddr2_dq[13]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[13]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[13]}]
set_property PACKAGE_PIN T4 [get_ports {ddr2_dq[13]}]

set_property SLEW FAST [get_ports {ddr2_dq[14]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[14]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[14]}]
set_property PACKAGE_PIN V1 [get_ports {ddr2_dq[14]}]

set_property SLEW FAST [get_ports {ddr2_dq[15]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dq[15]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dq[15]}]
set_property PACKAGE_PIN T3 [get_ports {ddr2_dq[15]}]

set_property SLEW FAST [get_ports {ddr2_addr[12]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[12]}]
set_property PACKAGE_PIN N6 [get_ports {ddr2_addr[12]}]

set_property SLEW FAST [get_ports {ddr2_addr[11]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[11]}]
set_property PACKAGE_PIN K5 [get_ports {ddr2_addr[11]}]

set_property SLEW FAST [get_ports {ddr2_addr[10]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[10]}]
set_property PACKAGE_PIN R2 [get_ports {ddr2_addr[10]}]

set_property SLEW FAST [get_ports {ddr2_addr[9]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[9]}]
set_property PACKAGE_PIN N5 [get_ports {ddr2_addr[9]}]

set_property SLEW FAST [get_ports {ddr2_addr[8]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[8]}]
set_property PACKAGE_PIN L4 [get_ports {ddr2_addr[8]}]

set_property SLEW FAST [get_ports {ddr2_addr[7]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[7]}]
set_property PACKAGE_PIN N1 [get_ports {ddr2_addr[7]}]

set_property SLEW FAST [get_ports {ddr2_addr[6]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[6]}]
set_property PACKAGE_PIN M2 [get_ports {ddr2_addr[6]}]

set_property SLEW FAST [get_ports {ddr2_addr[5]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[5]}]
set_property PACKAGE_PIN P5 [get_ports {ddr2_addr[5]}]

set_property SLEW FAST [get_ports {ddr2_addr[4]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[4]}]
set_property PACKAGE_PIN L3 [get_ports {ddr2_addr[4]}]

set_property SLEW FAST [get_ports {ddr2_addr[3]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[3]}]
set_property PACKAGE_PIN T1 [get_ports {ddr2_addr[3]}]

set_property SLEW FAST [get_ports {ddr2_addr[2]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[2]}]
set_property PACKAGE_PIN M6 [get_ports {ddr2_addr[2]}]

set_property SLEW FAST [get_ports {ddr2_addr[1]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[1]}]
set_property PACKAGE_PIN P4 [get_ports {ddr2_addr[1]}]

set_property SLEW FAST [get_ports {ddr2_addr[0]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_addr[0]}]
set_property PACKAGE_PIN M4 [get_ports {ddr2_addr[0]}]

set_property SLEW FAST [get_ports {ddr2_ba[2]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_ba[2]}]
set_property PACKAGE_PIN R1 [get_ports {ddr2_ba[2]}]

set_property SLEW FAST [get_ports {ddr2_ba[1]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_ba[1]}]
set_property PACKAGE_PIN P3 [get_ports {ddr2_ba[1]}]

set_property SLEW FAST [get_ports {ddr2_ba[0]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_ba[0]}]
set_property PACKAGE_PIN P2 [get_ports {ddr2_ba[0]}]

set_property SLEW FAST [get_ports {ddr2_ras_n}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_ras_n}]
set_property PACKAGE_PIN N4 [get_ports {ddr2_ras_n}]

set_property SLEW FAST [get_ports {ddr2_cas_n}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_cas_n}]
set_property PACKAGE_PIN L1 [get_ports {ddr2_cas_n}]

set_property SLEW FAST [get_ports {ddr2_we_n}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_we_n}]
set_property PACKAGE_PIN N2 [get_ports {ddr2_we_n}]

set_property SLEW FAST [get_ports {ddr2_cke}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_cke}]
set_property PACKAGE_PIN M1 [get_ports {ddr2_cke}]

set_property SLEW FAST [get_ports {ddr2_odt}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_odt}]
set_property PACKAGE_PIN M3 [get_ports {ddr2_odt}]

set_property SLEW FAST [get_ports {ddr2_cs_n}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_cs_n}]
set_property PACKAGE_PIN K6 [get_ports {ddr2_cs_n}]

set_property SLEW FAST [get_ports {ddr2_dm[0]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dm[0]}]
set_property PACKAGE_PIN T6 [get_ports {ddr2_dm[0]}]

set_property SLEW FAST [get_ports {ddr2_dm[1]}]
set_property IOSTANDARD SSTL18_II [get_ports {ddr2_dm[1]}]
set_property PACKAGE_PIN U1 [get_ports {ddr2_dm[1]}]

set_property SLEW FAST [get_ports {ddr2_dqs_p[0]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dqs_p[0]}]
set_property IOSTANDARD DIFF_SSTL18_II [get_ports {ddr2_dqs_p[0]}]
set_property PACKAGE_PIN U9 [get_ports {ddr2_dqs_p[0]}]

set_property SLEW FAST [get_ports {ddr2_dqs_n[0]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dqs_n[0]}]
set_property IOSTANDARD DIFF_SSTL18_II [get_ports {ddr2_dqs_n[0]}]
set_property PACKAGE_PIN V9 [get_ports {ddr2_dqs_n[0]}]

set_property SLEW FAST [get_ports {ddr2_dqs_p[1]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dqs_p[1]}]
set_property IOSTANDARD DIFF_SSTL18_II [get_ports {ddr2_dqs_p[1]}]
set_property PACKAGE_PIN U2 [get_ports {ddr2_dqs_p[1]}]

set_property SLEW FAST [get_ports {ddr2_dqs_n[1]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr2_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL18_II [get_ports {ddr2_dqs_n[1]}]
set_property PACKAGE_PIN V2 [get_ports {ddr2_dqs_n[1]}]

set_property SLEW FAST [get_ports {ddr2_ck_p}]
set_property IOSTANDARD DIFF_SSTL18_II [get_ports {ddr2_ck_p}]
set_property PACKAGE_PIN L6 [get_ports {ddr2_ck_p}]

set_property SLEW FAST [get_ports {ddr2_ck_n}]
set_property IOSTANDARD DIFF_SSTL18_II [get_ports {ddr2_ck_n}]
set_property PACKAGE_PIN L5 [get_ports {ddr2_ck_n}]

set_property INTERNAL_VREF 0.9 [get_iobanks 34]

set_property LOC PHASER_OUT_PHY_X1Y7 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out]
set_property LOC PHASER_OUT_PHY_X1Y5 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out]
set_property LOC PHASER_OUT_PHY_X1Y6 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out]
set_property LOC PHASER_OUT_PHY_X1Y4 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out]

## INST "*/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_in_gen.phaser_in" LOC=PHASER_IN_PHY_X1Y7;
## INST "*/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_in_gen.phaser_in" LOC=PHASER_IN_PHY_X1Y5;
set_property LOC PHASER_IN_PHY_X1Y6 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in]
set_property LOC PHASER_IN_PHY_X1Y4 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in]



set_property LOC OUT_FIFO_X1Y7 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo]
set_property LOC OUT_FIFO_X1Y5 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo]
set_property LOC OUT_FIFO_X1Y6 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo]
set_property LOC OUT_FIFO_X1Y4 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo]

set_property LOC IN_FIFO_X1Y6 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/in_fifo_gen.in_fifo]
set_property LOC IN_FIFO_X1Y4 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/in_fifo_gen.in_fifo]

set_property LOC PHY_CONTROL_X1Y1 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/phy_control_i]

set_property LOC PHASER_REF_X1Y1 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/phaser_ref_i]


set_property LOC OLOGIC_X1Y81 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/ddr_byte_group_io/slave_ts.oserdes_slave_ts]
set_property LOC OLOGIC_X1Y57 [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/ddr_byte_group_io/slave_ts.oserdes_slave_ts]

set_property LOC PLLE2_ADV_X1Y1 [get_cells umpmc1/u_ddr/u_ddr2_infrastructure/plle2_i]
set_property LOC MMCME2_ADV_X1Y1 [get_cells umpmc1/u_ddr/u_ddr2_infrastructure/gen_mmcm.mmcm_i]


# C:/Cores3/FISA64/trunk/rtl/Nexys4DDRFISA64.ucf:385
# A PERIOD placed on an internal net will result in a clock defined with an internal source. Any upstream source clock latency will not be analyzed
create_clock -name umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/iserdes_clk -period 3.333 [get_pins umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in/ICLK]
# A PERIOD placed on an internal net will result in a clock defined with an internal source. Any upstream source clock latency will not be analyzed
create_clock -name umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/iserdes_clk -period 3.333 [get_pins umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in/ICLK]

# The following cross clock domain false path constraints can be uncommented in order to mimic ucf constraints behavior (see message at the beginning of this file)
# set_false_path -from [get_clocks clk] -to [get_clocks [list clk50 dot_clk umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/iserdes_clk umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/iserdes_clk]]
# set_false_path -from [get_clocks clk50] -to [get_clocks [list clk dot_clk umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/iserdes_clk umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/iserdes_clk]]
# set_false_path -from [get_clocks dot_clk] -to [get_clocks [list clk clk50 umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/iserdes_clk umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/iserdes_clk]]
# set_false_path -from [get_clocks [list umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/iserdes_clk umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/iserdes_clk]] -to [get_clocks [list clk clk50 dot_clk]]

# C:/Cores3/FISA64/trunk/rtl/Nexys4DDRFISA64.ucf:386
set_multicycle_path 6 -from [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/mc0/mc_read_idle_r] -to [get_cells {*/ddr_byte_group_io/input_[?].iserdes_dq_.iserdesdq}]
set_multicycle_path -hold 5 -from [get_cells umpmc1/u_ddr/u_memc_ui_top_std/mem_intfc0/mc0/mc_read_idle_r] -to [get_cells {*/ddr_byte_group_io/input_[?].iserdes_dq_.iserdesdq}]
          

# C:/Cores3/FISA64/trunk/rtl/Nexys4DDRFISA64.ucf:390
# The path delay constraint with the DATAPATHONLY keyword will not be translated and should be converted manually. 'set_max_delay -datapath_only' provides limited support for some DATAPATHONLY use cases. Please consult the documentation to determine if it is appropriate to use in this context

set_max_delay -from [get_cells -hier -filter {*/device_temp_sync_r1*}] -to [get_cells -hier -filter {*/device_temp_sync_r1*}] 20.0
#INST "*/device_temp_sync_r1*" TNM="TNM_MULTICYCLEPATH_DEVICE_TEMP_SYNC";
#TIMESPEC "TS_MULTICYCLEPATH_DEVICE_TEMP_SYNC" = TO "TNM_MULTICYCLEPATH_DEVICE_TEMP_SYNC" 20 ns DATAPATHONLY;

# Character Glyphs
# 512 Ascii characters
#
set_property -dict { INIT_00 "256'h003C66060606663C003E66663E66663E006666667E663C18003C46067676663C" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_01 "256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_02 "256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_03 "256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_04 "256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_05 "256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_06 "256'h003C0C0C0C0C0C3C007E060C1830607E001818183C6666660066663C183C6666" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_07 "256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_08 "256'h006666FF66FF6666000000000066666600180000181818180000000000000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_09 "256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_0A "256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_0B "256'h00060C183060C0000018180000000000000000007E0000000C18180000000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_0C "256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_0D "256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_0E "256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_0F "256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_10 "256'h000000FFFF0000001818181818181818007C38FEFE7C3810000000FFFF000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_11 "256'h0C0C0C0C0C0C0C0C0000FFFF000000000000000000FFFF0000000000FFFF0000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_12 "256'h000000070F1C1818000000E0F038181818181C0F070000003030303030303030" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_13 "256'h030303030303FFFF03070E1C3870E0C0C0E070381C0E0703FFFF030303030303" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_14 "256'h0010387CFEFEFE6C00FFFF0000000000003C7E7E7E7E3C00C0C0C0C0C0C0FFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_15 "256'h003C7E66667E3C00C3E77E3C3C7EE7C3181838F0E00000000606060606060606" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_16 "256'h181818FFFF1818180010387CFE7C38106060606060606060003C181866661818" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_17 "256'h80C0E0F0F8FCFEFF006C6C6E7CC0000018181818181818180C0C03030C0C0303" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_18 "256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_19 "256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_1A "256'h181818F8F8181818C0C0C0C0C0C0C0C00103070F1F3F7FFFCCCC333300000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_1B "256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_1C "256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_1D "256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_1E "256'h0F0F0F0F00000000FFFFC0C0C0C0C0C0FFFFFF00000000000000000000FFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_1F "256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_20 "256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFC399F9898999C3" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_21 "256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_22 "256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_23 "256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_24 "256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_25 "256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_26 "256'hFFC3F3F3F3F3F3C3FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_27 "256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_28 "256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_29 "256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_2A "256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_2B "256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_2C "256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_2D "256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_2E "256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_2F "256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_30 "256'hFFFFFF0000FFFFFFE7E7E7E7E7E7E7E7FF83C7010183C7EFFFFFFF0000FFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_31 "256'hF3F3F3F3F3F3F3F3FFFF0000FFFFFFFFFFFFFFFFFF0000FFFFFFFFFF0000FFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_32 "256'hFFFFFFF8F0E3E7E7FFFFFF1F0FC7E7E7E7E7E3F0F8FFFFFFCFCFCFCFCFCFCFCF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_33 "256'hFCFCFCFCFCFC0000FCF8F1E3C78F1F3F3F1F8FC7E3F1F8FC0000FCFCFCFCFCFC" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_34 "256'hFFEFC78301010193FF0000FFFFFFFFFFFFC381818181C3FF3F3F3F3F3F3F0000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_35 "256'hFFC381999981C3FF3C1881C3C381183CE7E7C70F1FFFFFFFF9F9F9F9F9F9F9F9" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_36 "256'hE7E7E70000E7E7E7FFEFC7830183C7EF9F9F9F9F9F9F9F9FFFC3E7E79999E7E7" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_37 "256'h7F3F1F0F07030100FF939391833FFFFFE7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_38 "256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_39 "256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_3A "256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3FFEFCF8F0E0C080003333CCCCFFFFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_3B "256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_3C "256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_3D "256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_3E "256'hF0F0F0F0FFFFFFFF00003F3F3F3F3F3F000000FFFFFFFFFFFFFFFFFFFF000000" } [get_cells {tc1/charRam0/ram0}]
set_property -dict { INIT_3F "256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F" } [get_cells {tc1/charRam0/ram0}]


set_property -dict { INIT_00 "256'h003C0606063C0000003E66663E060600007C667C603C0000003C46067676663C" } [get_cells {tc1/charRam0/ram1}]  
set_property -dict { INIT_01 "256'h3E607C66667C0000001818187C187000003C067E663C0000007C66667C606000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_02 "256'h0066361E360606003C60606060006000003C18181C001800006666663E060600" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_03 "256'h003C6666663C000000666666663E000000C6D6FEFE660000003C181818181C00" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_04 "256'h003E603C067C000000060606663E000060607C66667C000006063E66663E0000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_05 "256'h006C7CFED6C6000000183C6666660000007C66666666000000701818187E1800" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_06 "256'h003C0C0C0C0C0C3C007E0C18307E00001E307C666666000000663C183C660000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_07 "256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_08 "256'h006666FF66FF6666000000000066666600180000181818180000000000000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_09 "256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_0A "256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_0B "256'h00060C183060C0000018180000000000000000007E0000000C18180000000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_0C "256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_0D "256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_0E "256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_0F "256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_10 "256'h003C66060606663C003E66663E66663E006666667E663C18000000FFFF000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_11 "256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_12 "256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_13 "256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_14 "256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_15 "256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_16 "256'h181818FFFF181818007E060C1830607E001818183C6666660066663C183C6666" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_17 "256'h663399CC663399CC3333CCCC3333CCCC18181818181818180C0C03030C0C0303" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_18 "256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_19 "256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_1A "256'h181818F8F8181818C0C0C0C0C0C0C0C066CC993366CC9933CCCC333300000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_1B "256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_1C "256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_1D "256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_1E "256'h0F0F0F0F0000000000060E1E3660C080FFFFFF00000000000000000000FFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_1F "256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_20 "256'hFFC3F9F9F9C3FFFFFFC19999C1F9F9FFFF8399839FC3FFFFFFC399F9898999C3" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_21 "256'hC19F83999983FFFFFFE7E7E783E78FFFFFC3F98199C3FFFFFF839999839F9FFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_22 "256'hFF99C9E1C9F9F9FFC39F9F9F9FFF9FFFFFC3E7E7E3FFE7FFFF999999C1F9F9FF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_23 "256'hFFC3999999C3FFFFFF99999999C1FFFFFF3929010199FFFFFFC3E7E7E7E7E3FF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_24 "256'hFFC19FC3F983FFFFFFF9F9F999C1FFFF9F9F83999983FFFFF9F9C19999C1FFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_25 "256'hFF9383012939FFFFFFE7C3999999FFFFFF8399999999FFFFFF8FE7E7E781E7FF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_26 "256'hFFC3F3F3F3F3F3C3FF81F3E7CF81FFFFE1CF83999999FFFFFF99C3E7C399FFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_27 "256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_28 "256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_29 "256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_2A "256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_2B "256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_2C "256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_2D "256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_2E "256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_2F "256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_30 "256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFFFFF0000FFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_31 "256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_32 "256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_33 "256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_34 "256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_35 "256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_36 "256'hE7E7E70000E7E7E7FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_37 "256'h99CC663399CC6633CCCC3333CCCC3333E7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_38 "256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_39 "256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_3A "256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3F993366CC993366CC3333CCCCFFFFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_3B "256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_3C "256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_3D "256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_3E "256'hF0F0F0F0FFFFFFFFFFF9F1E1C99F3F7F000000FFFFFFFFFFFFFFFFFFFF000000" } [get_cells {tc1/charRam0/ram1}]
set_property -dict { INIT_3F "256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F" } [get_cells {tc1/charRam0/ram1}]

set_property -dict { INIT_00 "256'h003C66060606663C003E66663E66663E006666667E663C18003C46067676663C" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_01 "256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_02 "256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_03 "256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_04 "256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_05 "256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_06 "256'h003C0C0C0C0C0C3C007E060C1830607E001818183C6666660066663C183C6666" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_07 "256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_08 "256'h006666FF66FF6666000000000066666600180000181818180000000000000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_09 "256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_0A "256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_0B "256'h00060C183060C0000018180000000000000000007E0000000C18180000000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_0C "256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_0D "256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_0E "256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_0F "256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_10 "256'h000000FFFF0000001818181818181818007C38FEFE7C3810000000FFFF000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_11 "256'h0C0C0C0C0C0C0C0C0000FFFF000000000000000000FFFF0000000000FFFF0000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_12 "256'h000000070F1C1818000000E0F038181818181C0F070000003030303030303030" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_13 "256'h030303030303FFFF03070E1C3870E0C0C0E070381C0E0703FFFF030303030303" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_14 "256'h0010387CFEFEFE6C00FFFF0000000000003C7E7E7E7E3C00C0C0C0C0C0C0FFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_15 "256'h003C7E66667E3C00C3E77E3C3C7EE7C3181838F0E00000000606060606060606" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_16 "256'h181818FFFF1818180010387CFE7C38106060606060606060003C181866661818" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_17 "256'h80C0E0F0F8FCFEFF006C6C6E7CC0000018181818181818180C0C03030C0C0303" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_18 "256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_19 "256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_1A "256'h181818F8F8181818C0C0C0C0C0C0C0C00103070F1F3F7FFFCCCC333300000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_1B "256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_1C "256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_1D "256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_1E "256'h0F0F0F0F00000000FFFFC0C0C0C0C0C0FFFFFF00000000000000000000FFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_1F "256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_20 "256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFC399F9898999C3" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_21 "256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_22 "256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_23 "256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_24 "256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_25 "256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_26 "256'hFFC3F3F3F3F3F3C3FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_27 "256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_28 "256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_29 "256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_2A "256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_2B "256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_2C "256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_2D "256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_2E "256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_2F "256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_30 "256'hFFFFFF0000FFFFFFE7E7E7E7E7E7E7E7FF83C7010183C7EFFFFFFF0000FFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_31 "256'hF3F3F3F3F3F3F3F3FFFF0000FFFFFFFFFFFFFFFFFF0000FFFFFFFFFF0000FFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_32 "256'hFFFFFFF8F0E3E7E7FFFFFF1F0FC7E7E7E7E7E3F0F8FFFFFFCFCFCFCFCFCFCFCF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_33 "256'hFCFCFCFCFCFC0000FCF8F1E3C78F1F3F3F1F8FC7E3F1F8FC0000FCFCFCFCFCFC" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_34 "256'hFFEFC78301010193FF0000FFFFFFFFFFFFC381818181C3FF3F3F3F3F3F3F0000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_35 "256'hFFC381999981C3FF3C1881C3C381183CE7E7C70F1FFFFFFFF9F9F9F9F9F9F9F9" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_36 "256'hE7E7E70000E7E7E7FFEFC7830183C7EF9F9F9F9F9F9F9F9FFFC3E7E79999E7E7" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_37 "256'h7F3F1F0F07030100FF939391833FFFFFE7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_38 "256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_39 "256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_3A "256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3FFEFCF8F0E0C080003333CCCCFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_3B "256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_3C "256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_3D "256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_3E "256'hF0F0F0F0FFFFFFFF00003F3F3F3F3F3F000000FFFFFFFFFFFFFFFFFFFF000000" } [get_cells {tc2/charRam0/ram0}]
set_property -dict { INIT_3F "256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F" } [get_cells {tc2/charRam0/ram0}]


set_property -dict { INIT_00 "256'h003C0606063C0000003E66663E060600007C667C603C0000003C46067676663C" } [get_cells {tc2/charRam0/ram1}]  
set_property -dict { INIT_01 "256'h3E607C66667C0000001818187C187000003C067E663C0000007C66667C606000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_02 "256'h0066361E360606003C60606060006000003C18181C001800006666663E060600" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_03 "256'h003C6666663C000000666666663E000000C6D6FEFE660000003C181818181C00" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_04 "256'h003E603C067C000000060606663E000060607C66667C000006063E66663E0000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_05 "256'h006C7CFED6C6000000183C6666660000007C66666666000000701818187E1800" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_06 "256'h003C0C0C0C0C0C3C007E0C18307E00001E307C666666000000663C183C660000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_07 "256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_08 "256'h006666FF66FF6666000000000066666600180000181818180000000000000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_09 "256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_0A "256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_0B "256'h00060C183060C0000018180000000000000000007E0000000C18180000000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_0C "256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_0D "256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_0E "256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_0F "256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_10 "256'h003C66060606663C003E66663E66663E006666667E663C18000000FFFF000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_11 "256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_12 "256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_13 "256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_14 "256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_15 "256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_16 "256'h181818FFFF181818007E060C1830607E001818183C6666660066663C183C6666" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_17 "256'h663399CC663399CC3333CCCC3333CCCC18181818181818180C0C03030C0C0303" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_18 "256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_19 "256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_1A "256'h181818F8F8181818C0C0C0C0C0C0C0C066CC993366CC9933CCCC333300000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_1B "256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_1C "256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_1D "256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_1E "256'h0F0F0F0F0000000000060E1E3660C080FFFFFF00000000000000000000FFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_1F "256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_20 "256'hFFC3F9F9F9C3FFFFFFC19999C1F9F9FFFF8399839FC3FFFFFFC399F9898999C3" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_21 "256'hC19F83999983FFFFFFE7E7E783E78FFFFFC3F98199C3FFFFFF839999839F9FFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_22 "256'hFF99C9E1C9F9F9FFC39F9F9F9FFF9FFFFFC3E7E7E3FFE7FFFF999999C1F9F9FF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_23 "256'hFFC3999999C3FFFFFF99999999C1FFFFFF3929010199FFFFFFC3E7E7E7E7E3FF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_24 "256'hFFC19FC3F983FFFFFFF9F9F999C1FFFF9F9F83999983FFFFF9F9C19999C1FFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_25 "256'hFF9383012939FFFFFFE7C3999999FFFFFF8399999999FFFFFF8FE7E7E781E7FF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_26 "256'hFFC3F3F3F3F3F3C3FF81F3E7CF81FFFFE1CF83999999FFFFFF99C3E7C399FFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_27 "256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_28 "256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_29 "256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_2A "256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_2B "256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_2C "256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_2D "256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_2E "256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_2F "256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_30 "256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFFFFF0000FFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_31 "256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_32 "256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_33 "256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_34 "256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_35 "256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_36 "256'hE7E7E70000E7E7E7FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_37 "256'h99CC663399CC6633CCCC3333CCCC3333E7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_38 "256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_39 "256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_3A "256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3F993366CC993366CC3333CCCCFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_3B "256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_3C "256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_3D "256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_3E "256'hF0F0F0F0FFFFFFFFFFF9F1E1C99F3F7F000000FFFFFFFFFFFFFFFFFFFF000000" } [get_cells {tc2/charRam0/ram1}]
set_property -dict { INIT_3F "256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F" } [get_cells {tc2/charRam0/ram1}]

