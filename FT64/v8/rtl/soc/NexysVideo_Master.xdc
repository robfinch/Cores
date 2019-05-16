## This file is a general .xdc for the Nexys Video Rev. A
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


#Clock Signal
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports xclk]
create_clock -period 10.000 -name xclk -waveform {0.000 5.000} -add [get_ports xclk]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets -of_objects [get_ports xclk]]
#create_generated_clock -name clk20 -source [get_pins ucg1/clk_in1] -divide_by 32 -multiply_by 8 [get_pins ucg1/clk20]
create_generated_clock -name clk40 -source [get_pins ucg1/clk_in1] -divide_by 16 -multiply_by 8 [get_pins ucg1/clk40]
create_generated_clock -name clk50 -source [get_pins ucg1/clk_in1] -divide_by 16 -multiply_by 8 [get_pins ucg1/clk50]
create_generated_clock -name clk80 -source [get_pins ucg1/clk_in1] -divide_by 10 -multiply_by 8 [get_pins ucg1/clk80]
set_false_path -from [get_clocks clk20] -to [get_clocks clk80]
set_false_path -from [get_clocks clk80] -to [get_clocks clk20]
set_false_path -from [get_clocks clk80] -to [get_clocks clk50]
set_false_path -from [get_clocks clk50] -to [get_clocks clk80]
set_false_path -from [get_clocks clk80] -to [get_clocks clk40]
set_false_path -from [get_clocks clk40] -to [get_clocks clk80]
set_false_path -from [get_clocks clk20] -to [get_clocks clk40]
set_false_path -from [get_clocks clk40] -to [get_clocks clk20]
set_false_path -from [get_clocks clk_pll_i] -to [get_clocks clk20]
set_false_path -from [get_clocks clk_20] -to [get_clocks clk_pll_i]

#set_false_path -from [All_clocks] -to [All_clocks]

#set_false_path -from [get_clocks mem_ui_clk] -to [get_clocks cpu_clk]
#set_false_path -from [get_clocks clk100u] -to [get_clocks mem_ui_clk]
#set_false_path -from [get_clocks clk200u] -to [get_clocks mem_ui_clk]

### Clock constraints ###
# rgb2dvi
#create_clock -period 11.666 [get_ports PixelClk]
#create_generated_clock -source [get_ports PixelClk] -multiply_by 5 [get_ports SerialClk]
#create_clock -period 5 [get_ports clk200]
#create_clock -period 5 [get_ports sys_clk_i]
### Asynchronous clock domain crossings ###
#set_false_path -through [get_pins -filter {NAME =~ */SyncAsync*/oSyncStages*/PRE || NAME =~ */SyncAsync*/oSyncStages*/CLR} -hier]
#set_false_path -through [get_pins -filter {NAME =~ *SyncAsync*/oSyncStages_reg[0]/D} -hier]

##LEDs
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS25} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS25} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS25} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS25} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS25} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS25} [get_ports {led[7]}]


## Buttons
set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS12 } [get_ports { btnc }]; #IO_L20N_T3_16 Sch=btnc
set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { btnd }]; #IO_L22N_T3_16 Sch=btnd
set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS12 } [get_ports { btnl }]; #IO_L20P_T3_16 Sch=btnl
set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS12 } [get_ports { btnr }]; #IO_L6P_T0_16 Sch=btnr
set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports { btnu }]; #IO_0_16 Sch=btnu
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS15} [get_ports cpu_resetn]


##Switches
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS12} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS12} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS12} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS12} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS12} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS12} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS12} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS12} [get_ports {sw[7]}]


##OLED Display
set_property -dict { PACKAGE_PIN W22   IOSTANDARD LVCMOS33 } [get_ports { oled_dc }]; #IO_L7N_T1_D10_14 Sch=oled_dc
set_property -dict { PACKAGE_PIN U21   IOSTANDARD LVCMOS33 } [get_ports { oled_res }]; #IO_L4N_T0_D05_14 Sch=oled_res
set_property -dict { PACKAGE_PIN W21   IOSTANDARD LVCMOS33 } [get_ports { oled_sclk }]; #IO_L7P_T1_D09_14 Sch=oled_sclk
set_property -dict { PACKAGE_PIN Y22   IOSTANDARD LVCMOS33 } [get_ports { oled_sdin }]; #IO_L9N_T1_DQS_D13_14 Sch=oled_sdin
set_property -dict { PACKAGE_PIN P20   IOSTANDARD LVCMOS33 } [get_ports { oled_vbat }]; #IO_0_14 Sch=oled_vbat
set_property -dict { PACKAGE_PIN V22   IOSTANDARD LVCMOS33 } [get_ports { oled_vdd }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=oled_vdd


#HDMI in
###set_property -dict { PACKAGE_PIN AA5   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_cec }]; #IO_L10P_T1_34 Sch=hdmi_rx_cec
#set_property -dict { PACKAGE_PIN W4    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_clk_n }]; #IO_L12N_T1_MRCC_34 Sch=hdmi_rx_clk_n
#set_property -dict { PACKAGE_PIN V4    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_clk_p }]; #IO_L12P_T1_MRCC_34 Sch=hdmi_rx_clk_p
#create_clock -period 17.500 -name tmds_clk_pin -waveform {0.000 8.75} -add [get_ports TMDS_IN_clk_p];
##set_property -dict { PACKAGE_PIN AB12  IOSTANDARD LVCMOS25 } [get_ports { hdmi_hpd }]; #IO_L7N_T1_13 Sch=hdmi_rx_hpa
##set_property -dict { PACKAGE_PIN Y4    IOSTANDARD LVCMOS33 } [get_ports { ddc_scl_io }]; #IO_L11P_T1_SRCC_34 Sch=hdmi_rx_scl
##set_property -dict { PACKAGE_PIN AB5   IOSTANDARD LVCMOS33 } [get_ports { ddc_sda_io }]; #IO_L10N_T1_34 Sch=hdmi_rx_sda
##set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_txen }]; #IO_L3P_T0_DQS_34 Sch=hdmi_rx_txen
#set_property -dict { PACKAGE_PIN AA3   IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_data_n[0] }]; #IO_L9N_T1_DQS_34 Sch=hdmi_rx_n[0]
#set_property -dict { PACKAGE_PIN Y3    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_data_p[0] }]; #IO_L9P_T1_DQS_34 Sch=hdmi_rx_p[0]
#set_property -dict { PACKAGE_PIN Y2    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_data_n[1] }]; #IO_L4N_T0_34 Sch=hdmi_rx_n[1]
#set_property -dict { PACKAGE_PIN W2    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_data_p[1] }]; #IO_L4P_T0_34 Sch=hdmi_rx_p[1]
#set_property -dict { PACKAGE_PIN V2    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_data_n[2] }]; #IO_L2N_T0_34 Sch=hdmi_rx_n[2]
#set_property -dict { PACKAGE_PIN U2    IOSTANDARD TMDS_33     } [get_ports { TMDS_IN_data_p[2] }]; #IO_L2P_T0_34 Sch=hdmi_rx_p[2]


#HDMI out
#set_property -dict { PACKAGE_PIN AA4   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }]; #IO_L11N_T1_SRCC_34 Sch=hdmi_tx_cec
set_property -dict {PACKAGE_PIN U1 IOSTANDARD TMDS_33} [get_ports TMDS_OUT_clk_n]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD TMDS_33} [get_ports TMDS_OUT_clk_p]
#set_property -dict { PACKAGE_PIN AB13  IOSTANDARD LVCMOS25 } [get_ports { hdmi_hpd }]; #IO_L3N_T0_DQS_13 Sch=hdmi_tx_hpd
#set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_rscl }]; #IO_L6P_T0_34 Sch=hdmi_tx_rscl
#set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_rsda }]; #IO_L6N_T0_VREF_34 Sch=hdmi_tx_rsda
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD TMDS_33} [get_ports {TMDS_OUT_data_n[0]}]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD TMDS_33} [get_ports {TMDS_OUT_data_p[0]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD TMDS_33} [get_ports {TMDS_OUT_data_n[1]}]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD TMDS_33} [get_ports {TMDS_OUT_data_p[1]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD TMDS_33} [get_ports {TMDS_OUT_data_n[2]}]
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD TMDS_33} [get_ports {TMDS_OUT_data_p[2]}]


#Display Port
#set_property -dict { PACKAGE_PIN AB10  IOSTANDARD LVDS     } [get_ports { dp_tx_aux_n }]; #IO_L8N_T1_13 Sch=dp_tx_aux_n
#set_property -dict { PACKAGE_PIN AA11  IOSTANDARD LVDS     } [get_ports { dp_tx_aux_n }]; #IO_L9N_T1_DQS_13 Sch=dp_tx_aux_n
#set_property -dict { PACKAGE_PIN AA9   IOSTANDARD LVDS     } [get_ports { dp_tx_aux_p }]; #IO_L8P_T1_13 Sch=dp_tx_aux_p
#set_property -dict { PACKAGE_PIN AA10  IOSTANDARD LVDS     } [get_ports { dp_tx_aux_p }]; #IO_L9P_T1_DQS_13 Sch=dp_tx_aux_p
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { dp_tx_hpd }]; #IO_25_14 Sch=dp_tx_hpd
#set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVDS         } [get_ports { gtp_clk_p}];
#set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVDS         } [get_ports { gtp_clk_n}];
#set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVDS         } [get_ports { dp_tx_lane0_p}];
#set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVDS         } [get_ports { dp_tx_lane0_n}];
#set_property -dict { PACKAGE_PIN D5    IOSTANDARD LVDS         } [get_ports { dp_tx_lane1_p}];
#set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVDS         } [get_ports { dp_tx_lane1_n}];
##set_property -dict { PACKAGE_PIN F10   IOSTANDARD LVDS         } [get_ports { fmc_mgt_clk_p}];
##set_property -dict { PACKAGE_PIN E10   IOSTANDARD LVDS         } [get_ports { fmc_mgt_clk_n}];
##Audio Codec
set_property -dict { PACKAGE_PIN T4    IOSTANDARD LVCMOS33 } [get_ports { ac_adc_sdata }]; #IO_L13N_T2_MRCC_34 Sch=ac_adc_sdata
set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { ac_bclk }]; #IO_L14P_T2_SRCC_34 Sch=ac_bclk
set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { ac_dac_sdata }]; #IO_L15P_T2_DQS_34 Sch=ac_dac_sdata
set_property -dict { PACKAGE_PIN U5    IOSTANDARD LVCMOS33 } [get_ports { ac_lrclk }]; #IO_L14N_T2_SRCC_34 Sch=ac_lrclk
set_property -dict { PACKAGE_PIN U6    IOSTANDARD LVCMOS33 } [get_ports { ac_mclk }]; #IO_L16P_T2_34 Sch=ac_mclk


##Pmod header JA
#set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33 } [get_ports { ja[0] }]; #IO_L10N_T1_D15_14 Sch=ja[1]
#set_property -dict { PACKAGE_PIN AB21  IOSTANDARD LVCMOS33 } [get_ports { ja[1] }]; #IO_L10P_T1_D14_14 Sch=ja[2]
#set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33 } [get_ports { ja[2] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=ja[3]
#set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33 } [get_ports { ja[3] }]; #IO_L17N_T2_A13_D29_14 Sch=ja[4]
#set_property -dict { PACKAGE_PIN Y21   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]; #IO_L9P_T1_DQS_14 Sch=ja[7]
#set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]; #IO_L8N_T1_D12_14 Sch=ja[8]
set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33 } [get_ports { spiCS_n }]; 
set_property -dict { PACKAGE_PIN AB21  IOSTANDARD LVCMOS33 } [get_ports { spiDataOut }];
set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33 } [get_ports { spiDataIn }];
set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33 } [get_ports { spiClkOut }]; 
set_property PULLUP true [get_ports {spiCS_n}]
set_property PULLUP true [get_ports {spiDataOut}]
set_property PULLUP true [get_ports {spiDataIn}]
set_property -dict { PACKAGE_PIN AA20  IOSTANDARD LVCMOS33 } [get_ports { rtc_clk }];
set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33 } [get_ports { rtc_data }];
set_property PULLUP true [get_ports {rtc_clk}]
set_property PULLUP true [get_ports {rtc_data}]


##Pmod header JB
#set_property -dict { PACKAGE_PIN V9    IOSTANDARD LVCMOS33 } [get_ports { jb[1] }]; #IO_L21P_T3_DQS_34 Sch=jb_p[1]
#set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { jb[0] }]; #IO_L21N_T3_DQS_34 Sch=jb_n[1]
#set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33 } [get_ports { jb[3] }]; #IO_L19P_T3_34 Sch=jb_p[2]
#set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { jb[2] }]; #IO_L19N_T3_VREF_34 Sch=jb_n[2]
#set_property -dict { PACKAGE_PIN W9    IOSTANDARD LVCMOS33 } [get_ports { rs485_re_n }]; #IO_L24P_T3_34 Sch=jb_p[3]
#set_property -dict { PACKAGE_PIN Y9    IOSTANDARD LVCMOS33 } [get_ports { rs485_txd }]; #IO_L24N_T3_34 Sch=jb_n[3]
#set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33 } [get_ports { rs485_rxd }]; #IO_L23P_T3_34 Sch=jb_p[4]
#set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33 } [get_ports { rs485_de }]; #IO_L23N_T3_34 Sch=jb_n[4]


##Pmod header JC
#set_property -dict { PACKAGE_PIN AA6   IOSTANDARD LVCMOS33 } [get_ports { jc[0] }]; #IO_L18N_T2_34 Sch=jc_n[1]
#set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33 } [get_ports { jc[1] }]; #IO_L18P_T2_34 Sch=jc_p[1]
#set_property -dict { PACKAGE_PIN AB8   IOSTANDARD LVCMOS33 } [get_ports { jc[2] }]; #IO_L22N_T3_34 Sch=jc_n[2]
#set_property -dict { PACKAGE_PIN AA8   IOSTANDARD LVCMOS33 } [get_ports { jc[3] }]; #IO_L22P_T3_34 Sch=jc_p[2]
#set_property -dict { PACKAGE_PIN T6    IOSTANDARD LVCMOS33 } [get_ports { jc[4] }]; #IO_L17N_T2_34 Sch=jc_n[3]
#set_property -dict { PACKAGE_PIN R6    IOSTANDARD LVCMOS33 } [get_ports { jc[5] }]; #IO_L17P_T2_34 Sch=jc_p[3]
#set_property -dict { PACKAGE_PIN AB6   IOSTANDARD LVCMOS33 } [get_ports { jc[6] }]; #IO_L20N_T3_34 Sch=jc_n[4]
#set_property -dict { PACKAGE_PIN AB7   IOSTANDARD LVCMOS33 } [get_ports { jc[7] }]; #IO_L20P_T3_34 Sch=jc_p[4]


##XADC Header
#set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { xa_n[0] }]; #IO_L3N_T0_DQS_AD1N_15 Sch=xa_n[1]
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { xa_p[0] }]; #IO_L3P_T0_DQS_AD1P_15 Sch=xa_p[1]
#set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { xa_n[1] }]; #IO_L1N_T0_AD0N_15 Sch=xa_n[2]
#set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33 } [get_ports { xa_p[1] }]; #IO_L1P_T0_AD0P_15 Sch=xa_p[2]
#set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { xa_n[2] }]; #IO_L2N_T0_AD8N_15 Sch=xa_n[3]
#set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { xa_p[2] }]; #IO_L2P_T0_AD8P_15 Sch=xa_p[3]
#set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { xa_n[3] }]; #IO_L5N_T0_AD9N_15 Sch=xa_n[4]
#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { xa_p[3] }]; #IO_L5P_T0_AD9P_15 Sch=xa_p[4]


#UART
#set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33 } [get_ports { uart_rx_out }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=uart_rx_out
#set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_in }]; #IO_L14P_T2_SRCC_14 Sch=uart_tx_in


##Ethernet
##set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS25 } [get_ports { eth_int_b }]; #IO_L6N_T0_VREF_13 Sch=eth_int_b
#set_property -dict { PACKAGE_PIN AA16  IOSTANDARD LVCMOS25 } [get_ports { eth_mdc }]; #IO_L1N_T0_13 Sch=eth_mdc
#set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS25 } [get_ports { eth_mdio }]; #IO_L1P_T0_13 Sch=eth_mdio
#set_property PULLUP true [get_ports {eth_mdio}]
##set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS25 } [get_ports { eth_pme_b }]; #IO_L6P_T0_13 Sch=eth_pme_b
#set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { eth_rst_b }]; #IO_25_34 Sch=eth_rst_b
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS25 } [get_ports { eth_rxclk }]; #IO_L13P_T2_MRCC_13 Sch=eth_rxck
#set_property -dict { PACKAGE_PIN W10   IOSTANDARD LVCMOS25 } [get_ports { eth_rxctl }]; #IO_L10N_T1_13 Sch=eth_rxctl
#set_property -dict { PACKAGE_PIN AB16  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[0] }]; #IO_L2P_T0_13 Sch=eth_rxd[0]
#set_property -dict { PACKAGE_PIN AA15  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[1] }]; #IO_L4P_T0_13 Sch=eth_rxd[1]
#set_property -dict { PACKAGE_PIN AB15  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[2] }]; #IO_L4N_T0_13 Sch=eth_rxd[2]
#set_property -dict { PACKAGE_PIN AB11  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[3] }]; #IO_L7P_T1_13 Sch=eth_rxd[3]
#set_property -dict { PACKAGE_PIN AA14  IOSTANDARD LVCMOS25 } [get_ports { eth_txclk }]; #IO_L5N_T0_13 Sch=eth_txck
#set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS25 } [get_ports { eth_txctl }]; #IO_L10P_T1_13 Sch=eth_txctl
#set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[0] }]; #IO_L11N_T1_SRCC_13 Sch=eth_txd[0]
#set_property -dict { PACKAGE_PIN W12   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[1] }]; #IO_L12N_T1_MRCC_13 Sch=eth_txd[1]
#set_property -dict { PACKAGE_PIN W11   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[2] }]; #IO_L12P_T1_MRCC_13 Sch=eth_txd[2]
#set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[3] }]; #IO_L11P_T1_SRCC_13 Sch=eth_txd[3]
#set_property PULLDOWN true [get_ports {eth_txd[0]}]
#set_property PULLDOWN true [get_ports {eth_txd[1]}]
#set_property PULLDOWN true [get_ports {eth_txd[2]}]
#set_property PULLUP true [get_ports {eth_txd[3]}]

##Fan PWM
#set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS25 } [get_ports { fan_pwm }]; #IO_L14P_T2_SRCC_13 Sch=fan_pwm


##DPTI/DSPI
#set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { prog_clko }]; #IO_L13P_T2_MRCC_14 Sch=prog_clko
#set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } [get_ports { prog_d[0]}]; #IO_L11P_T1_SRCC_14 Sch=prog_d0/sck
#set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { prog_d[1] }]; #IO_L19P_T3_A10_D26_14 Sch=prog_d1/mosi
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { prog_d[2] }]; #IO_L22P_T3_A05_D21_14 Sch=prog_d2/miso
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { prog_d[3]}]; #IO_L18P_T2_A12_D28_14 Sch=prog_d3/ss
#set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { prog_d[4] }]; #IO_L24N_T3_A00_D16_14 Sch=prog_d[4]
#set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { prog_d[5] }]; #IO_L24P_T3_A01_D17_14 Sch=prog_d[5]
#set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { prog_d[6] }]; #IO_L20P_T3_A08_D24_14 Sch=prog_d[6]
#set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { prog_d[7] }]; #IO_L23N_T3_A02_D18_14 Sch=prog_d[7]
#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { prog_oen }]; #IO_L16P_T2_CSI_B_14 Sch=prog_oen
#set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports { prog_rdn }]; #IO_L5P_T0_D06_14 Sch=prog_rdn
#set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { prog_rxen }]; #IO_L21P_T3_DQS_14 Sch=prog_rxen
#set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { prog_siwun }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=prog_siwun
#set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { prog_spien }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=prog_spien
#set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { prog_txen }]; #IO_L13N_T2_MRCC_14 Sch=prog_txen
#set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { prog_wrn }]; #IO_L5N_T0_D07_14 Sch=prog_wrn

set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { pti_clk }]; #IO_L13P_T2_MRCC_14 Sch=prog_clko
set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[0]}]; #IO_L11P_T1_SRCC_14 Sch=prog_d0/sck
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[1] }]; #IO_L19P_T3_A10_D26_14 Sch=prog_d1/mosi
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[2] }]; #IO_L22P_T3_A05_D21_14 Sch=prog_d2/miso
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[3]}]; #IO_L18P_T2_A12_D28_14 Sch=prog_d3/ss
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[4] }]; #IO_L24N_T3_A00_D16_14 Sch=prog_d[4]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[5] }]; #IO_L24P_T3_A01_D17_14 Sch=prog_d[5]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[6] }]; #IO_L20P_T3_A08_D24_14 Sch=prog_d[6]
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { pti_dat[7] }]; #IO_L23N_T3_A02_D18_14 Sch=prog_d[7]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { pti_oe }]; #IO_L16P_T2_CSI_B_14 Sch=prog_oen
set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports { pti_rd }]; #IO_L5P_T0_D06_14 Sch=prog_rdn
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { pti_rxf }]; #IO_L21P_T3_DQS_14 Sch=prog_rxen
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { pti_siwu }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=prog_siwun
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { spien }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=prog_spien
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { pti_txe }]; #IO_L13N_T2_MRCC_14 Sch=prog_txen
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { pti_wr }]; #IO_L5N_T0_D07_14 Sch=prog_wrn


##HID port
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports { kclk }]; #IO_L16N_T2_A15_D31_14 Sch=ps2_clk
set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33 } [get_ports { kd }]; #IO_L23P_T3_A03_D19_14 Sch=ps2_data
set_property PULLUP true [get_ports {kclk}]
set_property PULLUP true [get_ports {kd}]


##QSPI
#set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN P22   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN R22   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN P21   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN R21   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]

#set_property -dict { PACKAGE_PIN W5    IOSTANDARD LVCMOS33 } [get_ports { scl }]; #IO_L15N_T2_DQS_34 Sch=scl
#set_property -dict { PACKAGE_PIN V5    IOSTANDARD LVCMOS33 } [get_ports { sda }]; #IO_L16N_T2_34 Sch=sda

##SD card
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { sd_clk }]; #IO_L12P_T1_MRCC_14 Sch=sd_cclk
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { sd_cd }]; #IO_L20N_T3_A07_D23_14 Sch=sd_cd
set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33 } [get_ports { sd_cmd }]; #IO_L12N_T1_MRCC_14 Sch=sd_cmd
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[0] }]; #IO_L14N_T2_SRCC_14 Sch=sd_d[0]
set_property -dict { PACKAGE_PIN T21   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[1] }]; #IO_L4P_T0_D04_14 Sch=sd_d[1]
set_property -dict { PACKAGE_PIN T20   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[2] }]; #IO_L6N_T0_D08_VREF_14 Sch=sd_d[2]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[3] }]; #IO_L18N_T2_A11_D27_14 Sch=sd_d[3]
set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { sd_reset }]; #IO_L11N_T1_SRCC_14 Sch=sd_reset



##Voltage Adjust
#set_property -dict { PACKAGE_PIN AA13  IOSTANDARD LVCMOS25 } [get_ports { set_vadj[0] }]; #IO_L3P_T0_DQS_13 Sch=set_vadj[0]
#set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVCMOS25 } [get_ports { set_vadj[1] }]; #IO_L2N_T0_13 Sch=set_vadj[1]
#set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS25 } [get_ports { vadj_en }]; #IO_L13N_T2_MRCC_13 Sch=vadj_en


#DDR3
#set_property -dict { PACKAGE_PIN M2   } [get_ports { ddr3_addr[0] }]; #IO_L16N_T2_35 Sch=ddr3_addr[0]
#set_property -dict { PACKAGE_PIN M5   } [get_ports { ddr3_addr[1] }]; #IO_L23N_T3_35 Sch=ddr3_addr[1]
#set_property -dict { PACKAGE_PIN M3   } [get_ports { ddr3_addr[2] }]; #IO_L16P_T2_35 Sch=ddr3_addr[2]
#set_property -dict { PACKAGE_PIN M1   } [get_ports { ddr3_addr[3] }]; #IO_L15P_T2_DQS_35 Sch=ddr3_addr[3]
#set_property -dict { PACKAGE_PIN L6   } [get_ports { ddr3_addr[4] }]; #IO_25_35 Sch=ddr3_addr[4]
#set_property -dict { PACKAGE_PIN P1   } [get_ports { ddr3_addr[5] }]; #IO_L20N_T3_35 Sch=ddr3_addr[5]
#set_property -dict { PACKAGE_PIN N3   } [get_ports { ddr3_addr[6] }]; #IO_L19N_T3_VREF_35 Sch=ddr3_addr[6]
#set_property -dict { PACKAGE_PIN N2   } [get_ports { ddr3_addr[7] }]; #IO_L22N_T3_35 Sch=ddr3_addr[7]
#set_property -dict { PACKAGE_PIN M6   } [get_ports { ddr3_addr[8] }]; #IO_L23P_T3_35 Sch=ddr3_addr[8]
#set_property -dict { PACKAGE_PIN R1   } [get_ports { ddr3_addr[9] }]; #IO_L20P_T3_35 Sch=ddr3_addr[9]
#set_property -dict { PACKAGE_PIN L5   } [get_ports { ddr3_addr[10] }]; #IO_L18P_T2_35 Sch=ddr3_addr[10]
#set_property -dict { PACKAGE_PIN N5   } [get_ports { ddr3_addr[11] }]; #IO_L24N_T3_35 Sch=ddr3_addr[11]
#set_property -dict { PACKAGE_PIN N4   } [get_ports { ddr3_addr[12] }]; #IO_L19P_T3_35 Sch=ddr3_addr[12]
#set_property -dict { PACKAGE_PIN P2   } [get_ports { ddr3_addr[13] }]; #IO_L22P_T3_35 Sch=ddr3_addr[13]
#set_property -dict { PACKAGE_PIN P6   } [get_ports { ddr3_addr[14] }]; #IO_L24P_T3_35 Sch=ddr3_addr[14]
#set_property -dict { PACKAGE_PIN L3   } [get_ports { ddr3_ba[0] }]; #IO_L14P_T2_SRCC_35 Sch=ddr3_ba[0]
#set_property -dict { PACKAGE_PIN K6   } [get_ports { ddr3_ba[1] }]; #IO_L17P_T2_35 Sch=ddr3_ba[1]
#set_property -dict { PACKAGE_PIN L4   } [get_ports { ddr3_ba[2] }]; #IO_L18N_T2_35 Sch=ddr3_ba[2]
#set_property -dict { PACKAGE_PIN K3   } [get_ports { ddr3_cas }]; #IO_L14N_T2_SRCC_35 Sch=ddr3_cas
#set_property -dict { PACKAGE_PIN J6   } [get_ports { ddr3_cke[0] }]; #IO_L17N_T2_35 Sch=ddr3_cke[0]
#set_property -dict { PACKAGE_PIN P4    IOSTANDARD LVDS     } [get_ports { ddr3_clk_n[0] }]; #IO_L21N_T3_DQS_35 Sch=ddr3_clk_n[0]
#set_property -dict { PACKAGE_PIN P5    IOSTANDARD LVDS     } [get_ports { ddr3_clk_p[0] }]; #IO_L21P_T3_DQS_35 Sch=ddr3_clk_p[0]
#set_property -dict { PACKAGE_PIN G3   } [get_ports { ddr3_dm[0] }]; #IO_L11N_T1_SRCC_35 Sch=ddr3_dm[0]
#set_property -dict { PACKAGE_PIN F1   } [get_ports { ddr3_dm[1] }]; #IO_L5N_T0_AD13N_35 Sch=ddr3_dm[1]
#set_property -dict { PACKAGE_PIN G2   } [get_ports { ddr3_dq[0] }]; #IO_L8N_T1_AD14N_35 Sch=ddr3_dq[0]
#set_property -dict { PACKAGE_PIN H4   } [get_ports { ddr3_dq[1] }]; #IO_L12P_T1_MRCC_35 Sch=ddr3_dq[1]
#set_property -dict { PACKAGE_PIN H5   } [get_ports { ddr3_dq[2] }]; #IO_L10N_T1_AD15N_35 Sch=ddr3_dq[2]
#set_property -dict { PACKAGE_PIN J1   } [get_ports { ddr3_dq[3] }]; #IO_L7N_T1_AD6N_35 Sch=ddr3_dq[3]
#set_property -dict { PACKAGE_PIN K1   } [get_ports { ddr3_dq[4] }]; #IO_L7P_T1_AD6P_35 Sch=ddr3_dq[4]
#set_property -dict { PACKAGE_PIN H3   } [get_ports { ddr3_dq[5] }]; #IO_L11P_T1_SRCC_35 Sch=ddr3_dq[5]
#set_property -dict { PACKAGE_PIN H2   } [get_ports { ddr3_dq[6] }]; #IO_L8P_T1_AD14P_35 Sch=ddr3_dq[6]
#set_property -dict { PACKAGE_PIN J5   } [get_ports { ddr3_dq[7] }]; #IO_L10P_T1_AD15P_35 Sch=ddr3_dq[7]
#set_property -dict { PACKAGE_PIN E3   } [get_ports { ddr3_dq[8] }]; #IO_L6N_T0_VREF_35 Sch=ddr3_dq[8]
#set_property -dict { PACKAGE_PIN B2   } [get_ports { ddr3_dq[9] }]; #IO_L2N_T0_AD12N_35 Sch=ddr3_dq[9]
#set_property -dict { PACKAGE_PIN F3   } [get_ports { ddr3_dq[10] }]; #IO_L6P_T0_35 Sch=ddr3_dq[10]
#set_property -dict { PACKAGE_PIN D2   } [get_ports { ddr3_dq[11] }]; #IO_L4N_T0_35 Sch=ddr3_dq[11]
#set_property -dict { PACKAGE_PIN C2   } [get_ports { ddr3_dq[12] }]; #IO_L2P_T0_AD12P_35 Sch=ddr3_dq[12]
#set_property -dict { PACKAGE_PIN A1   } [get_ports { ddr3_dq[13] }]; #IO_L1N_T0_AD4N_35 Sch=ddr3_dq[13]
#set_property -dict { PACKAGE_PIN E2   } [get_ports { ddr3_dq[14] }]; #IO_L4P_T0_35 Sch=ddr3_dq[14]
#set_property -dict { PACKAGE_PIN B1   } [get_ports { ddr3_dq[15] }]; #IO_L1P_T0_AD4P_35 Sch=ddr3_dq[15]
#set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_n[0] }]; #IO_L9N_T1_DQS_AD7N_35 Sch=ddr3_dqs_n[0]
#set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_p[0] }]; #IO_L9P_T1_DQS_AD7P_35 Sch=ddr3_dqs_p[0]
#set_property -dict { PACKAGE_PIN D1    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_n[1] }]; #IO_L3N_T0_DQS_AD5N_35 Sch=ddr3_dqs_n[1]
#set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_p[1] }]; #IO_L3P_T0_DQS_AD5P_35 Sch=ddr3_dqs_p[1]
#set_property -dict { PACKAGE_PIN K4   } [get_ports { ddr3_odt }]; #IO_L13P_T2_MRCC_35 Sch=ddr3_odt
#set_property -dict { PACKAGE_PIN J4   } [get_ports { ddr3_ras }]; #IO_L13N_T2_MRCC_35 Sch=ddr3_ras
#set_property -dict { PACKAGE_PIN G1   } [get_ports { ddr3_reset }]; #IO_L5P_T0_AD13P_35 Sch=ddr3_reset
#set_property -dict { PACKAGE_PIN L1   } [get_ports { ddr3_we }]; #IO_L15N_T2_DQS_35 Sch=ddr3_we


##FMC
#set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports { fmc_clk0_m2c_n }]; #IO_L12N_T1_MRCC_15 Sch=fmc_clk0_m2c_n
#set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { fmc_clk0_m2c_p }]; #IO_L12P_T1_MRCC_15 Sch=fmc_clk0_m2c_p
#set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS33 } [get_ports { fmc_clk1_m2c_n }]; #IO_L13N_T2_MRCC_16 Sch=fmc_clk1_m2c_n
#set_property -dict { PACKAGE_PIN C18   IOSTANDARD LVCMOS33 } [get_ports { fmc_clk1_m2c_p }]; #IO_L13P_T2_MRCC_16 Sch=fmc_clk1_m2c_p
#set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la00_cc_n }]; #IO_L13N_T2_MRCC_15 Sch=fmc_la00_cc_n
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la00_cc_p }]; #IO_L13P_T2_MRCC_15 Sch=fmc_la00_cc_p
#set_property -dict { PACKAGE_PIN J21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la01_cc_n }]; #IO_L11N_T1_SRCC_15 Sch=fmc_la01_cc_n
#set_property -dict { PACKAGE_PIN J20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la01_cc_p }]; #IO_L11P_T1_SRCC_15 Sch=fmc_la01_cc_p
#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[02] }]; #IO_L16N_T2_A27_15 Sch=fmc_la_n[02]
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[02] }]; #IO_L16P_T2_A28_15 Sch=fmc_la_p[02]
#set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[03] }]; #IO_L17N_T2_A25_15 Sch=fmc_la_n[03]
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[03] }]; #IO_L17P_T2_A26_15 Sch=fmc_la_p[03]
#set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[04] }]; #IO_L18N_T2_A23_15 Sch=fmc_la_n[04]
#set_property -dict { PACKAGE_PIN N20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[04] }]; #IO_L18P_T2_A24_15 Sch=fmc_la_p[04]
#set_property -dict { PACKAGE_PIN L21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[05] }]; #IO_L10N_T1_AD11N_15 Sch=fmc_la_n[05]
#set_property -dict { PACKAGE_PIN M21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[05] }]; #IO_L10P_T1_AD11P_15 Sch=fmc_la_p[05]
#set_property -dict { PACKAGE_PIN M22   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[06] }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=fmc_la_n[06]
#set_property -dict { PACKAGE_PIN N22   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[06] }]; #IO_L15P_T2_DQS_15 Sch=fmc_la_p[06]
#set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[07] }]; #IO_L20N_T3_A19_15 Sch=fmc_la_n[07]
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[07] }]; #IO_L20P_T3_A20_15 Sch=fmc_la_p[07]
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[08] }]; #IO_L24N_T3_RS0_15 Sch=fmc_la_n[08]
#set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[08] }]; #IO_L24P_T3_RS1_15 Sch=fmc_la_p[08]
#set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[09] }]; #IO_L8N_T1_AD10N_15 Sch=fmc_la_n[09]
#set_property -dict { PACKAGE_PIN H20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[09] }]; #IO_L8P_T1_AD10P_15 Sch=fmc_la_p[09]
#set_property -dict { PACKAGE_PIN K22   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[10] }]; #IO_L9N_T1_DQS_AD3N_15 Sch=fmc_la_n[10]
#set_property -dict { PACKAGE_PIN K21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[10] }]; #IO_L9P_T1_DQS_AD3P_15 Sch=fmc_la_p[10]
#set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[11] }]; #IO_L22N_T3_A16_15 Sch=fmc_la_n[11]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[11] }]; #IO_L22P_T3_A17_15 Sch=fmc_la_p[11]
#set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[12] }]; #IO_L14N_T2_SRCC_15 Sch=fmc_la_n[12]
#set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[12] }]; #IO_L14P_T2_SRCC_15 Sch=fmc_la_p[12]
#set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[13] }]; #IO_L21N_T3_DQS_A18_15 Sch=fmc_la_n[13]
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[13] }]; #IO_L21P_T3_DQS_15 Sch=fmc_la_p[13]
#set_property -dict { PACKAGE_PIN H22   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[14] }]; #IO_L7N_T1_AD2N_15 Sch=fmc_la_n[14]
#set_property -dict { PACKAGE_PIN J22   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[14] }]; #IO_L7P_T1_AD2P_15 Sch=fmc_la_p[14]
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[15] }]; #IO_L23N_T3_FWE_B_15 Sch=fmc_la_n[15]
#set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[15] }]; #IO_L23P_T3_FOE_B_15 Sch=fmc_la_p[15]
#set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[16] }]; #IO_L4N_T0_15 Sch=fmc_la_n[16]
#set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[16] }]; #IO_L4P_T0_15 Sch=fmc_la_p[16]
#set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la17_cc_n }]; #IO_L11N_T1_SRCC_16 Sch=fmc_la17_cc_n
#set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la17_cc_p }]; #IO_L11P_T1_SRCC_16 Sch=fmc_la17_cc_p
#set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la18_cc_n }]; #IO_L12N_T1_MRCC_16 Sch=fmc_la18_cc_n
#set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la18_cc_p }]; #IO_L12P_T1_MRCC_16 Sch=fmc_la18_cc_p
#set_property -dict { PACKAGE_PIN A19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[19] }]; #IO_L17N_T2_16 Sch=fmc_la_n[19]
#set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[19] }]; #IO_L17P_T2_16 Sch=fmc_la_p[19]
#set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[20] }]; #IO_L18N_T2_16 Sch=fmc_la_n[20]
#set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[20] }]; #IO_L18P_T2_16 Sch=fmc_la_p[20]
#set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[21] }]; #IO_L14N_T2_SRCC_16 Sch=fmc_la_n[21]
#set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[21] }]; #IO_L14P_T2_SRCC_16 Sch=fmc_la_p[21]
#set_property -dict { PACKAGE_PIN D21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[22] }]; #IO_L23N_T3_16 Sch=fmc_la_n[22]
#set_property -dict { PACKAGE_PIN E21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[22] }]; #IO_L23P_T3_16 Sch=fmc_la_p[22]
#set_property -dict { PACKAGE_PIN A21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[23] }]; #IO_L21N_T3_DQS_16 Sch=fmc_la_n[23]
#set_property -dict { PACKAGE_PIN B21   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[23] }]; #IO_L21P_T3_DQS_16 Sch=fmc_la_p[23]
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[24] }]; #IO_L7N_T1_16 Sch=fmc_la_n[24]
#set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[24] }]; #IO_L7P_T1_16 Sch=fmc_la_p[24]
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[25] }]; #IO_L2N_T0_16 Sch=fmc_la_n[25]
#set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[25] }]; #IO_L2P_T0_16 Sch=fmc_la_p[25]
#set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[26] }]; #IO_L15N_T2_DQS_16 Sch=fmc_la_n[26]
#set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[26] }]; #IO_L15P_T2_DQS_16 Sch=fmc_la_p[26]
#set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[27] }]; #IO_L16N_T2_16 Sch=fmc_la_n[27]
#set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[27] }]; #IO_L16P_T2_16 Sch=fmc_la_p[27]
#set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[28] }]; #IO_L8N_T1_16 Sch=fmc_la_n[28]
#set_property -dict { PACKAGE_PIN C13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[28] }]; #IO_L8P_T1_16 Sch=fmc_la_p[28]
#set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[29] }]; #IO_L3N_T0_DQS_16 Sch=fmc_la_n[29]
#set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[29] }]; #IO_L3P_T0_DQS_16 Sch=fmc_la_p[29]
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[30] }]; #IO_L10N_T1_16 Sch=fmc_la_n[30]
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[30] }]; #IO_L10P_T1_16 Sch=fmc_la_p[30]
#set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[31] }]; #IO_L4N_T0_16 Sch=fmc_la_n[31]
#set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[31] }]; #IO_L4P_T0_16 Sch=fmc_la_p[31]
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[32] }]; #IO_L9N_T1_DQS_16 Sch=fmc_la_n[32]
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[32] }]; #IO_L9P_T1_DQS_16 Sch=fmc_la_p[32]
#set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_n[33] }]; #IO_L1N_T0_16 Sch=fmc_la_n[33]
#set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { fmc_la_p[33] }]; #IO_L1P_T0_16 Sch=fmc_la_p[33]

#set_property -dict { PACKAGE_PIN D15  } [get_ports { vrefa_m2c }]; #IO_L6N_T0_VREF_16 Sch=vrefa_m2c
#set_property -dict { PACKAGE_PIN K14  } [get_ports { vrefa_m2c }]; #IO_L19N_T3_A21_VREF_15 Sch=vrefa_m2c
#set_property -dict { PACKAGE_PIN H18  } [get_ports { vrefa_m2c }]; #IO_L6N_T0_VREF_15 Sch=vrefa_m2c
#set_property -dict { PACKAGE_PIN C20  } [get_ports { vrefa_m2c }]; #IO_L19N_T3_VREF_16 Sch=vrefa_m2c

#set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { prsnt_m2c }]; #IO_L22N_T3_A04_D20_14 Sch=prsnt_m2c


#???????????
#set_property PACKAGE_PIN D16 [get_ports {netic20_d16}]; #IO_L5N_T0_16
#set_property PACKAGE_PIN D20 [get_ports {netic20_d20}]; #IO_L19P_T3_16
#set_property PACKAGE_PIN E16 [get_ports {netic20_e16}]; #IO_L5P_T0_16
#set_property PACKAGE_PIN F4 [get_ports {netic20_f4}]; #IO_0_35
#set_property PACKAGE_PIN T3 [get_ports {netic20_t3}]; #IO_0_34
#set_property PACKAGE_PIN Y17 [get_ports {netic20_y17}]; #IO_0_13

#set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports { pic_ss_b }]; #IO_L3N_T0_DQS_34 Sch=pic_ss_b

# Character Glyphs
# 512 Ascii characters
#
#set_property -dict {INIT_00 256'h003C66060606663C003E66663E66663E006666667E663C18003C46067676663C} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_01 256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_02 256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_03 256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_04 256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_05 256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_06 256'h003C0C0C0C0C0C3C007E060C1830607E001818183C6666660066663C183C6666} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_07 256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_08 256'h006666FF66FF6666000000000066666600180000181818180000000000000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_09 256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_0A 256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_0B 256'h00060C183060C0000018180000000000000000007E0000000C18180000000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_0C 256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_0D 256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_0E 256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_0F 256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_10 256'h000000FFFF0000001818181818181818007C38FEFE7C3810000000FFFF000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_11 256'h0C0C0C0C0C0C0C0C0000FFFF000000000000000000FFFF0000000000FFFF0000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_12 256'h000000070F1C1818000000E0F038181818181C0F070000003030303030303030} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_13 256'h030303030303FFFF03070E1C3870E0C0C0E070381C0E0703FFFF030303030303} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_14 256'h0010387CFEFEFE6C00FFFF0000000000003C7E7E7E7E3C00C0C0C0C0C0C0FFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_15 256'h003C7E66667E3C00C3E77E3C3C7EE7C3181838F0E00000000606060606060606} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_16 256'h181818FFFF1818180010387CFE7C38106060606060606060003C181866661818} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_17 256'h80C0E0F0F8FCFEFF006C6C6E7CC0000018181818181818180C0C03030C0C0303} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_18 256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_19 256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_1A 256'h181818F8F8181818C0C0C0C0C0C0C0C00103070F1F3F7FFFCCCC333300000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_1B 256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_1C 256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_1D 256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_1E 256'h0F0F0F0F00000000FFFFC0C0C0C0C0C0FFFFFF00000000000000000000FFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_1F 256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_20 256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFC399F9898999C3} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_21 256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_22 256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_23 256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_24 256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_25 256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_26 256'hFFC3F3F3F3F3F3C3FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_27 256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_28 256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_29 256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_2A 256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_2B 256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_2C 256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_2D 256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_2E 256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_2F 256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_30 256'hFFFFFF0000FFFFFFE7E7E7E7E7E7E7E7FF83C7010183C7EFFFFFFF0000FFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_31 256'hF3F3F3F3F3F3F3F3FFFF0000FFFFFFFFFFFFFFFFFF0000FFFFFFFFFF0000FFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_32 256'hFFFFFFF8F0E3E7E7FFFFFF1F0FC7E7E7E7E7E3F0F8FFFFFFCFCFCFCFCFCFCFCF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_33 256'hFCFCFCFCFCFC0000FCF8F1E3C78F1F3F3F1F8FC7E3F1F8FC0000FCFCFCFCFCFC} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_34 256'hFFEFC78301010193FF0000FFFFFFFFFFFFC381818181C3FF3F3F3F3F3F3F0000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_35 256'hFFC381999981C3FF3C1881C3C381183CE7E7C70F1FFFFFFFF9F9F9F9F9F9F9F9} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_36 256'hE7E7E70000E7E7E7FFEFC7830183C7EF9F9F9F9F9F9F9F9FFFC3E7E79999E7E7} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_37 256'h7F3F1F0F07030100FF939391833FFFFFE7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_38 256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_39 256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_3A 256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3FFEFCF8F0E0C080003333CCCCFFFFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_3B 256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_3C 256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_3D 256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_3E 256'hF0F0F0F0FFFFFFFF00003F3F3F3F3F3F000000FFFFFFFFFFFFFFFFFFFF000000} [get_cells tc1/charRam0/ram0]
#set_property -dict {INIT_3F 256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F} [get_cells tc1/charRam0/ram0]


#set_property -dict {INIT_00 256'h003C0606063C0000003E66663E060600007C667C603C0000003C46067676663C} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_01 256'h3E607C66667C0000001818187C187000003C067E663C0000007C66667C606000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_02 256'h0066361E360606003C60606060006000003C18181C001800006666663E060600} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_03 256'h003C6666663C000000666666663E000000C6D6FEFE660000003C181818181C00} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_04 256'h003E603C067C000000060606663E000060607C66667C000006063E66663E0000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_05 256'h006C7CFED6C6000000183C6666660000007C66666666000000701818187E1800} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_06 256'h003C0C0C0C0C0C3C007E0C18307E00001E307C666666000000663C183C660000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_07 256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_08 256'h006666FF66FF6666000000000066666600180000181818180000000000000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_09 256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_0A 256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_0B 256'h00060C183060C0000018180000000000000000007E0000000C18180000000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_0C 256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_0D 256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_0E 256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_0F 256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_10 256'h003C66060606663C003E66663E66663E006666667E663C18000000FFFF000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_11 256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_12 256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_13 256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_14 256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_15 256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_16 256'h181818FFFF181818007E060C1830607E001818183C6666660066663C183C6666} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_17 256'h663399CC663399CC3333CCCC3333CCCC18181818181818180C0C03030C0C0303} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_18 256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_19 256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_1A 256'h181818F8F8181818C0C0C0C0C0C0C0C066CC993366CC9933CCCC333300000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_1B 256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_1C 256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_1D 256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_1E 256'h0F0F0F0F0000000000060E1E3660C080FFFFFF00000000000000000000FFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_1F 256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_20 256'hFFC3F9F9F9C3FFFFFFC19999C1F9F9FFFF8399839FC3FFFFFFC399F9898999C3} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_21 256'hC19F83999983FFFFFFE7E7E783E78FFFFFC3F98199C3FFFFFF839999839F9FFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_22 256'hFF99C9E1C9F9F9FFC39F9F9F9FFF9FFFFFC3E7E7E3FFE7FFFF999999C1F9F9FF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_23 256'hFFC3999999C3FFFFFF99999999C1FFFFFF3929010199FFFFFFC3E7E7E7E7E3FF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_24 256'hFFC19FC3F983FFFFFFF9F9F999C1FFFF9F9F83999983FFFFF9F9C19999C1FFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_25 256'hFF9383012939FFFFFFE7C3999999FFFFFF8399999999FFFFFF8FE7E7E781E7FF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_26 256'hFFC3F3F3F3F3F3C3FF81F3E7CF81FFFFE1CF83999999FFFFFF99C3E7C399FFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_27 256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_28 256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_29 256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_2A 256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_2B 256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_2C 256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_2D 256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_2E 256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_2F 256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_30 256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFFFFF0000FFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_31 256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_32 256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_33 256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_34 256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_35 256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_36 256'hE7E7E70000E7E7E7FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_37 256'h99CC663399CC6633CCCC3333CCCC3333E7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_38 256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_39 256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_3A 256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3F993366CC993366CC3333CCCCFFFFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_3B 256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_3C 256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_3D 256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_3E 256'hF0F0F0F0FFFFFFFFFFF9F1E1C99F3F7F000000FFFFFFFFFFFFFFFFFFFF000000} [get_cells tc1/charRam0/ram1]
#set_property -dict {INIT_3F 256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F} [get_cells tc1/charRam0/ram1]

#set_property -dict { INIT_00 "256'h003C66060606663C003E66663E66663E006666667E663C18003C46067676663C" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_01 "256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_02 "256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_03 "256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_04 "256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_05 "256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_06 "256'h003C0C0C0C0C0C3C007E060C1830607E001818183C6666660066663C183C6666" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_07 "256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_08 "256'h006666FF66FF6666000000000066666600180000181818180000000000000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_09 "256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_0A "256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_0B "256'h00060C183060C0000018180000000000000000007E0000000C18180000000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_0C "256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_0D "256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_0E "256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_0F "256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_10 "256'h000000FFFF0000001818181818181818007C38FEFE7C3810000000FFFF000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_11 "256'h0C0C0C0C0C0C0C0C0000FFFF000000000000000000FFFF0000000000FFFF0000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_12 "256'h000000070F1C1818000000E0F038181818181C0F070000003030303030303030" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_13 "256'h030303030303FFFF03070E1C3870E0C0C0E070381C0E0703FFFF030303030303" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_14 "256'h0010387CFEFEFE6C00FFFF0000000000003C7E7E7E7E3C00C0C0C0C0C0C0FFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_15 "256'h003C7E66667E3C00C3E77E3C3C7EE7C3181838F0E00000000606060606060606" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_16 "256'h181818FFFF1818180010387CFE7C38106060606060606060003C181866661818" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_17 "256'h80C0E0F0F8FCFEFF006C6C6E7CC0000018181818181818180C0C03030C0C0303" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_18 "256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_19 "256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_1A "256'h181818F8F8181818C0C0C0C0C0C0C0C00103070F1F3F7FFFCCCC333300000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_1B "256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_1C "256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_1D "256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_1E "256'h0F0F0F0F00000000FFFFC0C0C0C0C0C0FFFFFF00000000000000000000FFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_1F "256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_20 "256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFC399F9898999C3" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_21 "256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_22 "256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_23 "256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_24 "256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_25 "256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_26 "256'hFFC3F3F3F3F3F3C3FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_27 "256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_28 "256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_29 "256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_2A "256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_2B "256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_2C "256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_2D "256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_2E "256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_2F "256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_30 "256'hFFFFFF0000FFFFFFE7E7E7E7E7E7E7E7FF83C7010183C7EFFFFFFF0000FFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_31 "256'hF3F3F3F3F3F3F3F3FFFF0000FFFFFFFFFFFFFFFFFF0000FFFFFFFFFF0000FFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_32 "256'hFFFFFFF8F0E3E7E7FFFFFF1F0FC7E7E7E7E7E3F0F8FFFFFFCFCFCFCFCFCFCFCF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_33 "256'hFCFCFCFCFCFC0000FCF8F1E3C78F1F3F3F1F8FC7E3F1F8FC0000FCFCFCFCFCFC" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_34 "256'hFFEFC78301010193FF0000FFFFFFFFFFFFC381818181C3FF3F3F3F3F3F3F0000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_35 "256'hFFC381999981C3FF3C1881C3C381183CE7E7C70F1FFFFFFFF9F9F9F9F9F9F9F9" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_36 "256'hE7E7E70000E7E7E7FFEFC7830183C7EF9F9F9F9F9F9F9F9FFFC3E7E79999E7E7" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_37 "256'h7F3F1F0F07030100FF939391833FFFFFE7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_38 "256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_39 "256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_3A "256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3FFEFCF8F0E0C080003333CCCCFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_3B "256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_3C "256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_3D "256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_3E "256'hF0F0F0F0FFFFFFFF00003F3F3F3F3F3F000000FFFFFFFFFFFFFFFFFFFF000000" } [get_cells {tc2/charRam0/ram0}]
#set_property -dict { INIT_3F "256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F" } [get_cells {tc2/charRam0/ram0}]


#set_property -dict { INIT_00 "256'h003C0606063C0000003E66663E060600007C667C603C0000003C46067676663C" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_01 "256'h3E607C66667C0000001818187C187000003C067E663C0000007C66667C606000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_02 "256'h0066361E360606003C60606060006000003C18181C001800006666663E060600" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_03 "256'h003C6666663C000000666666663E000000C6D6FEFE660000003C181818181C00" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_04 "256'h003E603C067C000000060606663E000060607C66667C000006063E66663E0000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_05 "256'h006C7CFED6C6000000183C6666660000007C66666666000000701818187E1800" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_06 "256'h003C0C0C0C0C0C3C007E0C18307E00001E307C666666000000663C183C660000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_07 "256'h00080CFEFE0C0800181818187E3C1800003C30303030303C003F460C3E0C4830" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_08 "256'h006666FF66FF6666000000000066666600180000181818180000000000000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_09 "256'h000000000018306000FC66E61C3C663C0062660C1830664600183E603C067C18" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_0A "256'h000018187E1818000000663CFF3C6600000C18303030180C0030180C0C0C1830" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_0B "256'h00060C183060C0000018180000000000000000007E0000000C18180000000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_0C "256'h003C66603860663C007E060C3060663C007E1818181C1818003C66666E76663C" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_0D "256'h001818181830667E003C66663E06663C003C6660603E067E006060FE66787060" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_0E "256'h0C181800001800000000180000180000003C66607C66663C003C66663C66663C" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_0F "256'h001800183060663C000E18306030180E0000007E007E00000070180C060C1870" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_10 "256'h003C66060606663C003E66663E66663E006666667E663C18000000FFFF000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_11 "256'h003C66667606663C000606061E06067E007E06061E06067E001E36666666361E" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_12 "256'h0066361E0E1E3666001C363030303078003C18181818183C006666667E666666" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_13 "256'h003C66666666663C006666767E7E6E6600C6C6C6D6FEEEC6007E060606060606" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_14 "256'h003C66603C06663C0066361E3E66663E00703C666666663C000606063E66663E" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_15 "256'h00C6EEFED6C6C6C600183C6666666666003C666666666666001818181818187E" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_16 "256'h181818FFFF181818007E060C1830607E001818183C6666660066663C183C6666" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_17 "256'h663399CC663399CC3333CCCC3333CCCC18181818181818180C0C03030C0C0303" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_18 "256'h00000000000000FFFFFFFFFF000000000F0F0F0F0F0F0F0F0000000000000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_19 "256'hC0C0C0C0C0C0C0C0CCCC3333CCCC33330303030303030303FF00000000000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_1A "256'h181818F8F8181818C0C0C0C0C0C0C0C066CC993366CC9933CCCC333300000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_1B "256'hFFFF0000000000001818181F1F000000000000F8F8181818F0F0F0F000000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_1C "256'h1818181F1F181818181818FFFF000000000000FFFF181818181818F8F8000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_1D "256'h000000000000FFFFE0E0E0E0E0E0E0E007070707070707070303030303030303" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_1E "256'h0F0F0F0F0000000000060E1E3660C080FFFFFF00000000000000000000FFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_1F "256'hF0F0F0F00F0F0F0F000000000F0F0F0F0000001F1F18181800000000F0F0F0F0" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_20 "256'hFFC3F9F9F9C3FFFFFFC19999C1F9F9FFFF8399839FC3FFFFFFC399F9898999C3" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_21 "256'hC19F83999983FFFFFFE7E7E783E78FFFFFC3F98199C3FFFFFF839999839F9FFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_22 "256'hFF99C9E1C9F9F9FFC39F9F9F9FFF9FFFFFC3E7E7E3FFE7FFFF999999C1F9F9FF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_23 "256'hFFC3999999C3FFFFFF99999999C1FFFFFF3929010199FFFFFFC3E7E7E7E7E3FF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_24 "256'hFFC19FC3F983FFFFFFF9F9F999C1FFFF9F9F83999983FFFFF9F9C19999C1FFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_25 "256'hFF9383012939FFFFFFE7C3999999FFFFFF8399999999FFFFFF8FE7E7E781E7FF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_26 "256'hFFC3F3F3F3F3F3C3FF81F3E7CF81FFFFE1CF83999999FFFFFF99C3E7C399FFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_27 "256'hFFF7F30101F3F7FFE7E7E7E781C3E7FFFFC3CFCFCFCFCFC3FFC0B9F3C1F3B7CF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_28 "256'hFF99990099009999FFFFFFFFFF999999FFE7FFFFE7E7E7E7FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_29 "256'hFFFFFFFFFFE7CF9FFF039919E3C399C3FF9D99F3E7CF99B9FFE7C19FC3F983E7" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_2A "256'hFFFFE7E781E7E7FFFFFF99C300C399FFFFF3E7CFCFCFE7F3FFCFE7F3F3F3E7CF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_2B "256'hFFF9F3E7CF9F3FFFFFE7E7FFFFFFFFFFFFFFFFFF81FFFFFFF3E7E7FFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_2C "256'hFFC3999FC79F99C3FF81F9F3CF9F99C3FF81E7E7E7E3E7E7FFC39999918999C3" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_2D "256'hFFE7E7E7E7CF9981FFC39999C1F999C3FFC3999F9FC1F981FF9F9F0199878F9F" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_2E "256'hF3E7E7FFFFE7FFFFFFFFE7FFFFE7FFFFFFC3999F839999C3FFC39999C39999C3" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_2F "256'hFFE7FFE7CF9F99C3FFF1E7CF9FCFE7F1FFFFFF81FF81FFFFFF8FE7F3F9F3E78F" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_30 "256'hFFC399F9F9F999C3FFC19999C19999C1FF9999998199C3E7FFFFFF0000FFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_31 "256'hFFC3999989F999C3FFF9F9F9E1F9F981FF81F9F9E1F9F981FFE1C9999999C9E1" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_32 "256'hFF99C9E1F1E1C999FFE3C9CFCFCFCF87FFC3E7E7E7E7E7C3FF99999981999999" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_33 "256'hFFC39999999999C3FF99998981819199FF39393929011139FF81F9F9F9F9F9F9" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_34 "256'hFFC3999FC3F999C3FF99C9E1C19999C1FF8FC399999999C3FFF9F9F9C19999C1" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_35 "256'hFF39110129393939FFE7C39999999999FFC3999999999999FFE7E7E7E7E7E781" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_36 "256'hE7E7E70000E7E7E7FF81F9F3E7CF9F81FFE7E7E7C3999999FF9999C3E7C39999" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_37 "256'h99CC663399CC6633CCCC3333CCCC3333E7E7E7E7E7E7E7E7F3F3FCFCF3F3FCFC" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_38 "256'hFFFFFFFFFFFFFF0000000000FFFFFFFFF0F0F0F0F0F0F0F0FFFFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_39 "256'h3F3F3F3F3F3F3F3F3333CCCC3333CCCCFCFCFCFCFCFCFCFC00FFFFFFFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_3A "256'hE7E7E70707E7E7E73F3F3F3F3F3F3F3F993366CC993366CC3333CCCCFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_3B "256'h0000FFFFFFFFFFFFE7E7E7E0E0FFFFFFFFFFFF0707E7E7E70F0F0F0FFFFFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_3C "256'hE7E7E7E0E0E7E7E7E7E7E70000FFFFFFFFFFFF0000E7E7E7E7E7E70707FFFFFF" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_3D "256'hFFFFFFFFFFFF00001F1F1F1F1F1F1F1FF8F8F8F8F8F8F8F8FCFCFCFCFCFCFCFC" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_3E "256'hF0F0F0F0FFFFFFFFFFF9F1E1C99F3F7F000000FFFFFFFFFFFFFFFFFFFF000000" } [get_cells {tc2/charRam0/ram1}]
#set_property -dict { INIT_3F "256'h0F0F0F0FF0F0F0F0FFFFFFFFF0F0F0F0FFFFFFE0E0E7E7E7FFFFFFFF0F0F0F0F" } [get_cells {tc2/charRam0/ram1}]

## PadFunction: IO_L8N_T1_AD14N_35
#set_property SLEW FAST [get_ports {ddr3_dq[0]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[0]}]
#set_property PACKAGE_PIN G2 [get_ports {ddr3_dq[0]}]

## PadFunction: IO_L12P_T1_MRCC_35
#set_property SLEW FAST [get_ports {ddr3_dq[1]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[1]}]
#set_property PACKAGE_PIN H4 [get_ports {ddr3_dq[1]}]

## PadFunction: IO_L10N_T1_AD15N_35
#set_property SLEW FAST [get_ports {ddr3_dq[2]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[2]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[2]}]
#set_property PACKAGE_PIN H5 [get_ports {ddr3_dq[2]}]

## PadFunction: IO_L7N_T1_AD6N_35
#set_property SLEW FAST [get_ports {ddr3_dq[3]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[3]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[3]}]
#set_property PACKAGE_PIN J1 [get_ports {ddr3_dq[3]}]

## PadFunction: IO_L7P_T1_AD6P_35
#set_property SLEW FAST [get_ports {ddr3_dq[4]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[4]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[4]}]
#set_property PACKAGE_PIN K1 [get_ports {ddr3_dq[4]}]

## PadFunction: IO_L11P_T1_SRCC_35
#set_property SLEW FAST [get_ports {ddr3_dq[5]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[5]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[5]}]
#set_property PACKAGE_PIN H3 [get_ports {ddr3_dq[5]}]

## PadFunction: IO_L8P_T1_AD14P_35
#set_property SLEW FAST [get_ports {ddr3_dq[6]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[6]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[6]}]
#set_property PACKAGE_PIN H2 [get_ports {ddr3_dq[6]}]

## PadFunction: IO_L10P_T1_AD15P_35
#set_property SLEW FAST [get_ports {ddr3_dq[7]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[7]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[7]}]
#set_property PACKAGE_PIN J5 [get_ports {ddr3_dq[7]}]

## PadFunction: IO_L6N_T0_VREF_35
#set_property SLEW FAST [get_ports {ddr3_dq[8]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[8]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[8]}]
#set_property PACKAGE_PIN E3 [get_ports {ddr3_dq[8]}]

## PadFunction: IO_L2N_T0_AD12N_35
#set_property SLEW FAST [get_ports {ddr3_dq[9]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[9]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[9]}]
#set_property PACKAGE_PIN B2 [get_ports {ddr3_dq[9]}]

## PadFunction: IO_L6P_T0_35
#set_property SLEW FAST [get_ports {ddr3_dq[10]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[10]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[10]}]
#set_property PACKAGE_PIN F3 [get_ports {ddr3_dq[10]}]

## PadFunction: IO_L4N_T0_35
#set_property SLEW FAST [get_ports {ddr3_dq[11]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[11]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[11]}]
#set_property PACKAGE_PIN D2 [get_ports {ddr3_dq[11]}]

## PadFunction: IO_L2P_T0_AD12P_35
#set_property SLEW FAST [get_ports {ddr3_dq[12]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[12]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[12]}]
#set_property PACKAGE_PIN C2 [get_ports {ddr3_dq[12]}]

## PadFunction: IO_L1N_T0_AD4N_35
#set_property SLEW FAST [get_ports {ddr3_dq[13]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[13]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[13]}]
#set_property PACKAGE_PIN A1 [get_ports {ddr3_dq[13]}]

## PadFunction: IO_L4P_T0_35
#set_property SLEW FAST [get_ports {ddr3_dq[14]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[14]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[14]}]
#set_property PACKAGE_PIN E2 [get_ports {ddr3_dq[14]}]

## PadFunction: IO_L1P_T0_AD4P_35
#set_property SLEW FAST [get_ports {ddr3_dq[15]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[15]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[15]}]
#set_property PACKAGE_PIN B1 [get_ports {ddr3_dq[15]}]

## PadFunction: IO_L24P_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[14]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[14]}]
#set_property PACKAGE_PIN P6 [get_ports {ddr3_addr[14]}]

## PadFunction: IO_L22P_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[13]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[13]}]
#set_property PACKAGE_PIN P2 [get_ports {ddr3_addr[13]}]

## PadFunction: IO_L19P_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[12]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[12]}]
#set_property PACKAGE_PIN N4 [get_ports {ddr3_addr[12]}]

## PadFunction: IO_L24N_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[11]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[11]}]
#set_property PACKAGE_PIN N5 [get_ports {ddr3_addr[11]}]

## PadFunction: IO_L18P_T2_35
#set_property SLEW FAST [get_ports {ddr3_addr[10]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[10]}]
#set_property PACKAGE_PIN L5 [get_ports {ddr3_addr[10]}]

## PadFunction: IO_L20P_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[9]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[9]}]
#set_property PACKAGE_PIN R1 [get_ports {ddr3_addr[9]}]

## PadFunction: IO_L23P_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[8]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[8]}]
#set_property PACKAGE_PIN M6 [get_ports {ddr3_addr[8]}]

## PadFunction: IO_L22N_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[7]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[7]}]
#set_property PACKAGE_PIN N2 [get_ports {ddr3_addr[7]}]

## PadFunction: IO_L19N_T3_VREF_35
#set_property SLEW FAST [get_ports {ddr3_addr[6]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[6]}]
#set_property PACKAGE_PIN N3 [get_ports {ddr3_addr[6]}]

## PadFunction: IO_L20N_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[5]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[5]}]
#set_property PACKAGE_PIN P1 [get_ports {ddr3_addr[5]}]

## PadFunction: IO_25_35
#set_property SLEW FAST [get_ports {ddr3_addr[4]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[4]}]
#set_property PACKAGE_PIN L6 [get_ports {ddr3_addr[4]}]

## PadFunction: IO_L15P_T2_DQS_35
#set_property SLEW FAST [get_ports {ddr3_addr[3]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[3]}]
#set_property PACKAGE_PIN M1 [get_ports {ddr3_addr[3]}]

## PadFunction: IO_L16P_T2_35
#set_property SLEW FAST [get_ports {ddr3_addr[2]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[2]}]
#set_property PACKAGE_PIN M3 [get_ports {ddr3_addr[2]}]

## PadFunction: IO_L23N_T3_35
#set_property SLEW FAST [get_ports {ddr3_addr[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[1]}]
#set_property PACKAGE_PIN M5 [get_ports {ddr3_addr[1]}]

## PadFunction: IO_L16N_T2_35
#set_property SLEW FAST [get_ports {ddr3_addr[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[0]}]
#set_property PACKAGE_PIN M2 [get_ports {ddr3_addr[0]}]

## PadFunction: IO_L18N_T2_35
#set_property SLEW FAST [get_ports {ddr3_ba[2]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[2]}]
#set_property PACKAGE_PIN L4 [get_ports {ddr3_ba[2]}]

## PadFunction: IO_L17P_T2_35
#set_property SLEW FAST [get_ports {ddr3_ba[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[1]}]
#set_property PACKAGE_PIN K6 [get_ports {ddr3_ba[1]}]

## PadFunction: IO_L14P_T2_SRCC_35
#set_property SLEW FAST [get_ports {ddr3_ba[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[0]}]
#set_property PACKAGE_PIN L3 [get_ports {ddr3_ba[0]}]

## PadFunction: IO_L13N_T2_MRCC_35
#set_property SLEW FAST [get_ports {ddr3_ras_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ras_n}]
#set_property PACKAGE_PIN J4 [get_ports {ddr3_ras_n}]

## PadFunction: IO_L14N_T2_SRCC_35
#set_property SLEW FAST [get_ports {ddr3_cas_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cas_n}]
#set_property PACKAGE_PIN K3 [get_ports {ddr3_cas_n}]

## PadFunction: IO_L15N_T2_DQS_35
#set_property SLEW FAST [get_ports {ddr3_we_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_we_n}]
#set_property PACKAGE_PIN L1 [get_ports {ddr3_we_n}]

## PadFunction: IO_L5P_T0_AD13P_35
#set_property SLEW FAST [get_ports {ddr3_reset_n}]
#set_property IOSTANDARD LVCMOS15 [get_ports {ddr3_reset_n}]
#set_property PACKAGE_PIN G1 [get_ports {ddr3_reset_n}]

## PadFunction: IO_L17N_T2_35
#set_property SLEW FAST [get_ports {ddr3_cke[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke[0]}]
#set_property PACKAGE_PIN J6 [get_ports {ddr3_cke[0]}]

## PadFunction: IO_L13P_T2_MRCC_35
#set_property SLEW FAST [get_ports {ddr3_odt[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt[0]}]
#set_property PACKAGE_PIN K4 [get_ports {ddr3_odt[0]}]

## PadFunction: IO_L11N_T1_SRCC_35
#set_property SLEW FAST [get_ports {ddr3_dm[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[0]}]
#set_property PACKAGE_PIN G3 [get_ports {ddr3_dm[0]}]

## PadFunction: IO_L5N_T0_AD13N_35
#set_property SLEW FAST [get_ports {ddr3_dm[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[1]}]
#set_property PACKAGE_PIN F1 [get_ports {ddr3_dm[1]}]

## PadFunction: IO_L9P_T1_DQS_AD7P_35
#set_property SLEW FAST [get_ports {ddr3_dqs_p[0]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_p[0]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[0]}]
#set_property PACKAGE_PIN K2 [get_ports {ddr3_dqs_p[0]}]

## PadFunction: IO_L9N_T1_DQS_AD7N_35
#set_property SLEW FAST [get_ports {ddr3_dqs_n[0]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_n[0]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[0]}]
#set_property PACKAGE_PIN J2 [get_ports {ddr3_dqs_n[0]}]

## PadFunction: IO_L3P_T0_DQS_AD5P_35
#set_property SLEW FAST [get_ports {ddr3_dqs_p[1]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_p[1]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[1]}]
#set_property PACKAGE_PIN E1 [get_ports {ddr3_dqs_p[1]}]

## PadFunction: IO_L3N_T0_DQS_AD5N_35
#set_property SLEW FAST [get_ports {ddr3_dqs_n[1]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_n[1]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[1]}]
#set_property PACKAGE_PIN D1 [get_ports {ddr3_dqs_n[1]}]

## PadFunction: IO_L21P_T3_DQS_35
#set_property SLEW FAST [get_ports {ddr3_ck_p[0]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_p[0]}]
#set_property PACKAGE_PIN P5 [get_ports {ddr3_ck_p[0]}]

## PadFunction: IO_L21N_T3_DQS_35
#set_property SLEW FAST [get_ports {ddr3_ck_n[0]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_n[0]}]
#set_property PACKAGE_PIN P4 [get_ports {ddr3_ck_n[0]}]


#set_property INTERNAL_VREF  0.750 [get_iobanks 35]

#set_property LOC PHASER_OUT_PHY_X1Y13 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
#set_property LOC PHASER_OUT_PHY_X1Y12 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out}]
#set_property LOC PHASER_OUT_PHY_X1Y15 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
#set_property LOC PHASER_OUT_PHY_X1Y14 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]

### set_property LOC PHASER_IN_PHY_X1Y13 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_in_gen.phaser_in}]
### set_property LOC PHASER_IN_PHY_X1Y12 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in}]
#set_property LOC PHASER_IN_PHY_X1Y15 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_in_gen.phaser_in}]
#set_property LOC PHASER_IN_PHY_X1Y14 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in}]



#set_property LOC OUT_FIFO_X1Y13 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
#set_property LOC OUT_FIFO_X1Y12 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo}]
#set_property LOC OUT_FIFO_X1Y15 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
#set_property LOC OUT_FIFO_X1Y14 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]

#set_property LOC IN_FIFO_X1Y15 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/in_fifo_gen.in_fifo}]
#set_property LOC IN_FIFO_X1Y14 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/in_fifo_gen.in_fifo}]

#set_property LOC PHY_CONTROL_X1Y3 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phy_control_i}]

#set_property LOC PHASER_REF_X1Y3 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phaser_ref_i}]

#set_property LOC OLOGIC_X1Y193 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/ddr_byte_group_io/*slave_ts}]
#set_property LOC OLOGIC_X1Y181 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/ddr_byte_group_io/*slave_ts}]

#set_property LOC PLLE2_ADV_X1Y3 [get_cells -hier -filter {NAME =~ */u_ddr3_infrastructure/plle2_i}]
#set_property LOC MMCME2_ADV_X1Y3 [get_cells -hier -filter {NAME =~ */u_ddr3_infrastructure/gen_mmcm.mmcm_i}]


#set_multicycle_path -from [get_cells -hier -filter {NAME =~ */mc0/mc_read_idle_r_reg}] #                    -to   [get_cells -hier -filter {NAME =~ */input_[?].iserdes_dq_.iserdesdq}] #                    -setup 6

#set_multicycle_path -from [get_cells -hier -filter {NAME =~ */mc0/mc_read_idle_r_reg}] #                    -to   [get_cells -hier -filter {NAME =~ */input_[?].iserdes_dq_.iserdesdq}] #                    -hold 5



#set_false_path -through [get_pins -filter {NAME =~ */DQSFOUND} -of [get_cells -hier -filter {REF_NAME == PHASER_IN_PHY}]]

#set_multicycle_path -through [get_pins -filter {NAME =~ */OSERDESRST} -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] -setup 2 -start
#set_multicycle_path -through [get_pins -filter {NAME =~ */OSERDESRST} -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] -hold 1 -start

#set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/device_temp_sync_r1*}] 20
#set_max_delay -from [get_cells -hier *rstdiv0_sync_r1_reg*] -to [get_pins -filter {NAME =~ */RESET} -of [get_cells -hier -filter {REF_NAME == PHY_CONTROL}]] -datapath_only 5

#set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *ddr3_infrastructure/rstdiv0_sync_r1_reg*}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/xadc_supplied_temperature.rst_r1*}] 20


