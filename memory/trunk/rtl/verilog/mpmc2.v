`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
// ============================================================================
//
module mpmc2(
rst_i, clk200MHz, fpga_temp,
mem_ui_clk,
cyc0, stb0, ack0, we0, sel0, adr0, dati0, dato0,
cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
ddr2_dq, ddr2_dqs_n, ddr2_dqs_p,
ddr2_addr, ddr2_ba, ddr2_ras_n, ddr2_cas_n, ddr2_we_n,
ddr2_ck_p, ddr2_ck_n, ddr2_cke, ddr2_cs_n, ddr2_dm, ddr2_odt
);
parameter SIM= "FALSE";
parameter SIM_BYPASS_INIT_CAL = "OFF";
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;
// State machine states
parameter IDLE = 4'd1;
parameter PRESET = 4'd2;
parameter SEND_DATA = 4'd3;
parameter SET_CMD_RD = 4'd4;
parameter SET_CMD_WR = 4'd5;
parameter WAIT_NACK = 4'd6;
parameter WAIT_RD = 4'd7;


input rst_i;
input clk200MHz;
input [11:0] fpga_temp;
output mem_ui_clk;

// Channel 0 is reserved for bitmapped graphics display.
//
input cyc0;
input stb0;
output ack0;
input [15:0] sel0;
input we0;
input [31:0] adr0;
input [127:0] dati0;
output reg [127:0] dato0;
reg [127:0] dato0n;

// Channel 1 is reserved for cpu1
input cs1;
input cyc1;
input stb1;
output ack1;
input we1;
input [15:0] sel1;
input [31:0] adr1;
input [127:0] dati1;
output reg [127:0] dato1;
input sr1;
input cr1;
output reg rb1;

// Channel 2 is reserved for the ethernet controller
input cyc2;
input stb2;
output ack2;
input we2;
input [3:0] sel2;
input [31:0] adr2;
input [31:0] dati2;
output reg [31:0] dato2;

// Channel 3 is reserved for the graphics controller
input cyc3;
input stb3;
output ack3;
input we3;
input [15:0] sel3;
input [31:0] adr3;
input [127:0] dati3;
output reg [127:0] dato3;

// Channel 4 is reserved for the graphics controller
input cyc4;
input stb4;
output ack4;
input we4;
input [15:0] sel4;
input [31:0] adr4;
input [127:0] dati4;
output reg [127:0] dato4;

// Channel 5 is reserved for sprite DMA, which is read-only
input cyc5;
input stb5;
output ack5;
input [31:0] adr5;
output reg [127:0] dato5;

// Channel 6 is reserved for the SD/MMC controller
input cyc6;
input stb6;
output ack6;
input we6;
input [3:0] sel6;
input [31:0] adr6;
input [31:0] dati6;
output reg [31:0] dato6;

// Channel 7 is reserved for the cpu
input cs7;
input cyc7;
input stb7;
output ack7;
input we7;
input [15:0] sel7;
input [31:0] adr7;
input [127:0] dati7;
output reg [127:0] dato7;
input sr7;
input cr7;
output reg rb7;

inout [15:0] ddr2_dq;
inout [1:0] ddr2_dqs_p;
inout [1:0] ddr2_dqs_n;
output [12:0] ddr2_addr;
output [2:0] ddr2_ba;
output ddr2_ras_n;
output ddr2_cas_n;
output ddr2_we_n;
output ddr2_ck_p;
output ddr2_ck_n;
output ddr2_cke;
output ddr2_cs_n;
output [1:0] ddr2_dm;
output ddr2_odt;

reg [7:0] sel;
reg [31:0] adr;
reg [63:0] dato;
reg [63:0] dati;
reg [127:0] dat128;
reg [15:0] wmask;

reg [3:0] state;
reg [2:0] ch;
reg do_wr;
reg [1:0] sreg;
reg rstn;
reg fast_read0, fast_read1, fast_read2, fast_read3;
reg fast_read4, fast_read5, fast_read6, fast_read7;
reg read0,read1,read2,read3;
reg read4,read5,read6,read7;

wire cs0 = cyc0 && stb0 && adr0[31:28]==4'h0;
wire ics1 = cyc1 & stb1 & cs1;
wire cs2 = cyc2 && stb2 && adr2[31:28]==4'h0;
wire cs3 = cyc3 && stb3 && adr3[31:28]==4'h0;
wire cs4 = cyc4 && stb4 && adr4[31:28]==4'h0;
wire cs5 = cyc5 && stb5 && adr5[31:28]==4'h0;
wire cs6 = cyc6 && stb6 && adr6[31:28]==4'h0;
wire ics7 = cyc7 & stb7 & cs7;

reg acki0,acki1,acki2,acki3,acki4,acki5,acki6,acki7;

// Record of the last read address for each channel.
// Cache address tag
reg [31:0] ch0_addr;
reg [31:0] ch1_addr;
reg [31:0] ch2_addr;
reg [31:0] ch3_addr;
reg [31:0] ch4_addr;
reg [31:0] ch5_addr;
reg [31:0] ch6_addr;
reg [31:0] ch7_addr;

// Read data caches
reg [127:0] ch0_rd_data [0:3];
reg [127:0] ch1_rd_data [0:1];
reg [127:0] ch2_rd_data;
reg [127:0] ch3_rd_data;
reg [127:0] ch4_rd_data;
reg [127:0] ch5_rd_data [0:3];
reg [127:0] ch6_rd_data;
reg [127:0] ch7_rd_data [0:1];

reg [1:0] num_strips;
reg [1:0] strip_cnt;
reg [1:0] strip_cnt2;
reg [26:0] mem_addr;
wire [2:0] mem_cmd;
wire mem_en;
reg [127:0] mem_wdf_data;
reg [15:0] mem_wdf_mask;
wire mem_wdf_end;
wire mem_wdf_wren;

wire [127:0] mem_rd_data;
wire mem_rd_data_end;
wire mem_rd_data_valid;
wire mem_rdy;
wire mem_wdf_rdy;
wire mem_ui_clk;
wire mem_ui_rst;
wire calib_complete;
reg [15:0] refcnt;
reg refreq;
wire refack;

reg [3:0] resv_ch0,resv_ch1;
reg [31:0] resv_adr0,resv_adr1;

reg [7:0] match;
always @(posedge mem_ui_clk)
if (rst_i)
	match <= 8'h00;
else
	match <= match + 8'd1;

reg cs1xx;
reg we1xx;
reg [15:0] sel1xx;
reg [31:0] adr1xx;
reg [127:0] dati1xx;
reg sr1xx;
reg cr1xx;

reg cs7xx;
reg we7xx;
reg [15:0] sel7xx;
reg [31:0] adr7xx;
reg [127:0] dati7xx;
reg sr7xx;
reg cr7xx;

reg [63:0] mem_rd_data1;
reg [7:0] to_cnt;

// Terminate the ack signal as soon as the circuit select goes away.
assign ack0 = acki0 & cs0;
assign ack1 = acki1 & ics1;
assign ack2 = acki2 & cs2;
assign ack3 = acki3 & cs3;
assign ack4 = acki4 & cs4;
assign ack5 = acki5 & cs5;
assign ack6 = acki6 & cs6;
assign ack7 = acki7 & ics7;

// Register signals onto mem_ui_clk domain
// The following channels don't need to be registered as they are operating
// under the mem_ui_clk domain already.
// Channel 0 (bmp controller) 
// Channel 5 (sprite controller)
always @(posedge mem_ui_clk)
begin
	cs1xx <= ics1;
	we1xx <= we1;
	sel1xx <= sel1;
	adr1xx <= adr1;
	dati1xx <= dati1;
	sr1xx <= sr1;
	cr1xx <= cr1;

	cs7xx <= ics7;
    we7xx <= we7;
    sel7xx <= sel7;
    adr7xx <= adr7;
    dati7xx <= dati7;
    sr7xx <= sr7;
    cr7xx <= cr7;
end

//------------------------------------------------------------------------
// Component Declarations
//------------------------------------------------------------------------

ddr2  # (

   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   .BANK_WIDTH                    (3),
                                     // # of memory Bank Address bits.
   .CK_WIDTH                      (1),
                                     // # of CK/CK# outputs to memory.
   .COL_WIDTH                     (10),
                                     // # of memory Column Address bits.
   .CS_WIDTH                      (1),
                                     // # of unique CS outputs to memory.
   .nCS_PER_RANK                  (1),
                                     // # of unique CS outputs per rank for phy
   .CKE_WIDTH                     (1),
                                     // # of CKE outputs to memory.
   .DATA_BUF_ADDR_WIDTH           (5),
   .DQ_CNT_WIDTH                  (4),
                                     // = ceil(log2(DQ_WIDTH))
   .DQ_PER_DM                     (8),
   .DM_WIDTH                      (2),
                                     // # of DM (data mask)
   .DQ_WIDTH                      (16),
                                     // # of DQ (data)
   .DQS_WIDTH                     (2),
   .DQS_CNT_WIDTH                 (1),
                                     // = ceil(log2(DQS_WIDTH))
   .DRAM_WIDTH                    (8),
                                     // # of DQ per DQS
   .ECC                           ("OFF"),
   .DATA_WIDTH                    (16),
   .ECC_TEST                      ("OFF"),
   .PAYLOAD_WIDTH                 (16),
   .ECC_WIDTH                     (8),
   .MC_ERR_ADDR_WIDTH             (31),
   .nBANK_MACHS                   (4),
   .RANKS                         (1),
                                     // # of Ranks.
   .ODT_WIDTH                     (1),
                                     // # of ODT outputs to memory.
   .ROW_WIDTH                     (13),
                                     // # of memory Row Address bits.
   .ADDR_WIDTH                    (27),
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
   .USE_CS_PORT                   (1),
                                     // # = 1, When Chip Select (CS#) output is enabled
                                     //   = 0, When Chip Select (CS#) output is disabled
                                     // If CS_N disabled, user must connect
                                     // DRAM CS_N input(s) to ground
   .USE_DM_PORT                   (1),
                                     // # = 1, When Data Mask option is enabled
                                     //   = 0, When Data Mask option is disbaled
                                     // When Data Mask option is disabled in
                                     // MIG Controller Options page, the logic
                                     // related to Data Mask should not get
                                     // synthesized
   .USE_ODT_PORT                  (1),
                                     // # = 1, When ODT output is enabled
                                     //   = 0, When ODT output is disabled
   .PHY_CONTROL_MASTER_BANK       (0),
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   .AL                            ("0"),
                                     // DDR3 SDRAM:
                                     // Additive Latency (Mode Register 1).
                                     // # = "0", "CL-1", "CL-2".
                                     // DDR2 SDRAM:
                                     // Additive Latency (Extended Mode Register).
   .nAL                           (0),
                                     // # Additive Latency in number of clock
                                     // cycles.
   .BURST_MODE                    ("8"),
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
   .BURST_TYPE                    ("SEQ"),
                                     // DDR3 SDRAM: Burst Type (Mode Register 0).
                                     // DDR2 SDRAM: Burst Type (Mode Register).
                                     // # = "SEQ" - (Sequential),
                                     //   = "INT" - (Interleaved).
   .CL                            (5),
                                     // in number of clock cycles
                                     // DDR3 SDRAM: CAS Latency (Mode Register 0).
                                     // DDR2 SDRAM: CAS Latency (Mode Register).
   .OUTPUT_DRV                    ("HIGH"),
                                     // Output Drive Strength (Extended Mode Register).
                                     // # = "HIGH" - FULL,
                                     //   = "LOW" - REDUCED.
   .RTT_NOM                       (1),
                                     // RTT (Nominal) (Extended Mode Register).
                                     //   = "150" - 150 Ohms,
                                     //   = "75" - 75 Ohms,
                                     //   = "50" - 50 Ohms.
   .ADDR_CMD_MODE                 ("1T" ),
                                     // # = "1T", "2T".
   .REG_CTRL                      ("OFF"),
                                     // # = "ON" - RDIMMs,
                                     //   = "OFF" - Components, SODIMMs, UDIMMs.
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   .CLKIN_PERIOD                  (4999),
                                     // Input Clock Period
   .CLKFBOUT_MULT                 (6),
                                     // write PLL VCO multiplier
   .DIVCLK_DIVIDE                 (1),
                                     // write PLL VCO divisor
   .CLKOUT0_DIVIDE                (2),
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   .CLKOUT1_DIVIDE                (4),
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   .CLKOUT2_DIVIDE                (64),
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   .CLKOUT3_DIVIDE                (16),
                                     // VCO output divisor for PLL output clock (CLKOUT3)

   //***************************************************************************
   // Memory Timing Parameters. These parameters varies based on the selected
   // memory part.
   //***************************************************************************
   .tCKE                          (7500),
                                     // memory tCKE paramter in pS.
   .tFAW                          (45000),
                                     // memory tRAW paramter in pS.
   .tPRDI                         (1_000_000),
                                     // memory tPRDI paramter in pS.
   .tRAS                          (40000),
                                     // memory tRAS paramter in pS.
   .tRCD                          (15000),
                                     // memory tRCD paramter in pS.
   .tREFI                         (7800000),
                                     // memory tREFI paramter in pS.
   .tRFC                          (127500),
                                     // memory tRFC paramter in pS.
   .tRP                           (12500),
                                     // memory tRP paramter in pS.
   .tRRD                          (10000),
                                     // memory tRRD paramter in pS.
   .tRTP                          (7500),
                                     // memory tRTP paramter in pS.
   .tWTR                          (7500),
                                     // memory tWTR paramter in pS.
   .tZQI                          (128_000_000),
                                     // memory tZQI paramter in nS.
   .tZQCS                         (64),
                                     // memory tZQCS paramter in clock cycles.

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   .SIM_BYPASS_INIT_CAL           (SIM_BYPASS_INIT_CAL),
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence
   .SIMULATION                    (SIM),
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   .BYTE_LANES_B0                 (4'b1111),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B1                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B2                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B3                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B4                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .DATA_CTL_B0                   (4'b0101),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B1                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B2                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B3                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B4                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane

   .PHY_0_BITLANES                (48'hFFC3F7FFF3FE),
   .PHY_1_BITLANES                (48'h000000000000),
   .PHY_2_BITLANES                (48'h000000000000),
   .CK_BYTE_MAP                   (144'h000000000000000000000000000000000003),
   .ADDR_MAP                      (192'h00000000001003301A01903203A034018036012011017015),
   .BANK_MAP                      (36'h01301601B),
   .CAS_MAP                       (12'h039),
   .CKE_ODT_BYTE_MAP              (8'h00),
   .CKE_MAP                       (96'h000000000000000000000038),
   .ODT_MAP                       (96'h000000000000000000000035),
   .CS_MAP                        (120'h000000000000000000000000000037),
   .PARITY_MAP                    (12'h000),
   .RAS_MAP                       (12'h014),
   .WE_MAP                        (12'h03B),
   .DQS_BYTE_MAP                  (144'h000000000000000000000000000000000200),
   .DATA0_MAP                     (96'h008004009007005001006003),
   .DATA1_MAP                     (96'h022028020024027025026021),
   .DATA2_MAP                     (96'h000000000000000000000000),
   .DATA3_MAP                     (96'h000000000000000000000000),
   .DATA4_MAP                     (96'h000000000000000000000000),
   .DATA5_MAP                     (96'h000000000000000000000000),
   .DATA6_MAP                     (96'h000000000000000000000000),
   .DATA7_MAP                     (96'h000000000000000000000000),
   .DATA8_MAP                     (96'h000000000000000000000000),
   .DATA9_MAP                     (96'h000000000000000000000000),
   .DATA10_MAP                    (96'h000000000000000000000000),
   .DATA11_MAP                    (96'h000000000000000000000000),
   .DATA12_MAP                    (96'h000000000000000000000000),
   .DATA13_MAP                    (96'h000000000000000000000000),
   .DATA14_MAP                    (96'h000000000000000000000000),
   .DATA15_MAP                    (96'h000000000000000000000000),
   .DATA16_MAP                    (96'h000000000000000000000000),
   .DATA17_MAP                    (96'h000000000000000000000000),
   .MASK0_MAP                     (108'h000000000000000000000029002),
   .MASK1_MAP                     (108'h000000000000000000000000000),

   .SLOT_0_CONFIG                 (8'b00000001),
                                     // Mapping of Ranks.
   .SLOT_1_CONFIG                 (8'b0000_0000),
                                     // Mapping of Ranks.
   .MEM_ADDR_ORDER                ("BANK_ROW_COLUMN"),
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   .IODELAY_HP_MODE               ("ON"),
                                     // to phy_top
   .IBUF_LPWR_MODE                ("OFF"),
                                     // to phy_top
   .DATA_IO_IDLE_PWRDWN           ("ON"),
                                     // # = "ON", "OFF"
   .DATA_IO_PRIM_TYPE             ("HR_LP"),
                                     // # = "HP_LP", "HR_LP", "DEFAULT"
   .CKE_ODT_AUX                   ("FALSE"),
   .USER_REFRESH                  ("OFF"),
   .WRLVL                         ("OFF"),
                                     // # = "ON" - DDR3 SDRAM
                                     //   = "OFF" - DDR2 SDRAM.
   .ORDERING                      ("STRICT"),
                                     // # = "NORM", "STRICT", "RELAXED".
   .CALIB_ROW_ADD                 (16'h0000),
                                     // Calibration row address will be used for
                                     // calibration read and write operations
   .CALIB_COL_ADD                 (12'h000),
                                     // Calibration column address will be used for
                                     // calibration read and write operations
   .CALIB_BA_ADD                  (3'h0),
                                     // Calibration bank address will be used for
                                     // calibration read and write operations
   .TCQ                           (100),
   .IODELAY_GRP                   ("IODELAY_MIG"),
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency.
   .SYSCLK_TYPE                   ("NO_BUFFER"),
                                     // System clock type DIFFERENTIAL or SINGLE_ENDED
   .REFCLK_TYPE                   ("USE_SYSTEM_CLOCK"),
                                     // Reference clock type DIFFERENTIAL or SINGLE_ENDED
   .CMD_PIPE_PLUS1                ("ON"),
                                     // add pipeline stage between MC and PHY
   .DRAM_TYPE                       ("DDR2"),
   .CAL_WIDTH                     ("HALF"),
   .STARVE_LIMIT                  (2),
                                     // # = 2,3,4.
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   .REFCLK_FREQ                   (200.0),
                                     // IODELAYCTRL reference clock frequency
   .DIFF_TERM_REFCLK              ("TRUE"),
                                     // Differential Termination for idelay
                                     // reference clock input pins
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   .tCK                           (3333),
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   .nCK_PER_CLK                   (4),
                                     // # of memory CKs per fabric CLK
   .DIFF_TERM_SYSCLK              ("TRUE"),
                                     // Differential Termination for System
                                     // clock input pins

   
   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   .DEBUG_PORT                      ("OFF"),
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
   .RST_ACT_LOW                   (1)
                                     // =1 for active low reset,
                                     // =0 for active high.
   )
u_ddr
(
   // Inouts
   .ddr2_dq(ddr2_dq),
   .ddr2_dqs_p(ddr2_dqs_p),
   .ddr2_dqs_n(ddr2_dqs_n),
   // Outputs
   .ddr2_addr(ddr2_addr),
   .ddr2_ba(ddr2_ba),
   .ddr2_ras_n(ddr2_ras_n),
   .ddr2_cas_n(ddr2_cas_n),
   .ddr2_we_n(ddr2_we_n),
   .ddr2_ck_p(ddr2_ck_p),
   .ddr2_ck_n(ddr2_ck_n),
   .ddr2_cke(ddr2_cke),
   .ddr2_cs_n(ddr2_cs_n),
   .ddr2_dm(ddr2_dm),
   .ddr2_odt(ddr2_odt),
   // Inputs
   .sys_clk_i(clk200MHz),
   //.clk_ref_i(clk200MHz),
   .sys_rst(rstn),
   // user interface signals
   .app_addr(mem_addr),
   .app_cmd(mem_cmd),
   .app_en(mem_en),
   .app_wdf_data(mem_wdf_data),
   .app_wdf_end(mem_wdf_end),
   .app_wdf_mask(mem_wdf_mask),
   .app_wdf_wren(mem_wdf_wren),
   .app_rd_data(mem_rd_data),
   .app_rd_data_end(mem_rd_data_end),
   .app_rd_data_valid(mem_rd_data_valid),
   .app_rdy(mem_rdy),
   .app_wdf_rdy(mem_wdf_rdy),
   .app_sr_req(1'b0),
   .app_sr_active(),
   .app_ref_req(1'b0),
   .app_ref_ack(),
   .app_zq_req(1'b0),
   .app_zq_ack(),
   .ui_clk(mem_ui_clk),
   .ui_clk_sync_rst(mem_ui_rst),
   .device_temp_i(fpga_temp),
   .init_calib_complete(calib_complete)
);


always @(posedge clk200MHz)
begin
	sreg <= {sreg[0],rst_i};
	rstn <= ~sreg[1];
end

reg toggle;	// CPU1 / CPU0 priority toggle
reg toggle_sr;
reg [19:0] resv_to_cnt;
reg sr1x,sr7x;
reg [127:0] dati128;

wire ch1_read = ics1 && !we1xx && cs1xx && (adr1xx[31:5]==ch1_addr[31:5]);
wire ch7_read = ics7 && !we7xx && cs7xx && (adr7xx[31:5]==ch7_addr[31:5]);

always @*
begin
	fast_read0 = FALSE;
	fast_read1 = FALSE;
	fast_read2 = FALSE;
	fast_read3 = FALSE;
    fast_read4 = FALSE;
	fast_read5 = FALSE;
	fast_read6 = FALSE;
    fast_read7 = FALSE;
	if (cs0 && !we0 && adr0[31:7]==ch0_addr[31:7])
		fast_read0 = TRUE;
	if (ch1_read)
		fast_read1 = TRUE;
	if (!we2 && cs2 && adr2[31:4]==ch2_addr[31:4])
    	fast_read2 = TRUE;
	if (!we3 && cs3 && adr3[31:4]==ch3_addr[31:4])
		fast_read3 = TRUE;
	if (!we4 && cs4 && adr4[31:4]==ch4_addr[31:4])
		fast_read4 = TRUE;
	if (cs5 && adr5[31:4]==ch5_addr[31:4])
		fast_read5 = TRUE;
	if (!we6 && cs6 && adr6[31:4]==ch6_addr[31:4])
    	fast_read6 = TRUE;
    if (ch7_read)
        fast_read7 = TRUE;
end

always @*
begin
	sr1x = FALSE;
    if (ch1_read)
        sr1x = sr1xx;
end
always @*
begin
	sr7x = FALSE;
    if (ch7_read)
        sr7x = sr7xx;
end

always @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	state <= IDLE;
	ch0_addr <= 32'hFFFFFFFF;
	ch1_addr <= 32'hFFFFFFFF;
	ch2_addr <= 32'hFFFFFFFF;
	ch3_addr <= 32'hFFFFFFFF;
	ch4_addr <= 32'hFFFFFFFF;
	ch5_addr <= 32'hFFFFFFFF;
	ch6_addr <= 32'hFFFFFFFF;
	ch7_addr <= 32'hFFFFFFFF;
	read1 <= FALSE;
	read2 <= FALSE;
	read3 <= FALSE;
	read4 <= FALSE;
	read5 <= FALSE;
	read6 <= FALSE;
	acki0 <= FALSE;
	acki1 <= FALSE;
	acki2 <= FALSE;
	acki3 <= FALSE;
	acki4 <= FALSE;
	acki5 <= FALSE;
	acki6 <= FALSE;
	acki7 <= FALSE;
	resv_to_cnt <= 20'd0;
	refcnt <= 16'd278;
	refreq <= FALSE;
	rb1 <= FALSE;
	rb7 <= FALSE;
	toggle <= FALSE;
	toggle_sr <= FALSE;
	resv_ch0 <= 4'hF;
	resv_ch1 <= 4'hF;
	mem_addr <= 27'h0;
	mem_wdf_data <= 128'd0;
	mem_wdf_mask <= 16'hFFFF;
end
else begin
	resv_to_cnt <= resv_to_cnt + 20'd1;
	//refcnt <= refcnt + 16'd1;
	//refreq <= FALSE;

	// Fast read channels
	// All these read channels allow data to be read in parallel with another
	// access.
	// Read the data from the channel read buffer rather than issuing a memory
	// request.
	
	// Bitmap controller
	dato0 <= ch0_rd_data[adr0[5:4]];
	if (cs0 && !we0 && adr0[31:6]==ch0_addr[31:6])
		acki0 <= TRUE;

    // CPU #1
    dato1 <= adr1xx[4] ? ch1_rd_data[1] : ch1_rd_data[0];
	if (ch1_read)
		acki1 <= TRUE;

    // Ethernet controller
	case(adr2[3:2])
    2'd0:    dato2 <= ch2_rd_data[31:0];
    2'd1:    dato2 <= ch2_rd_data[63:32];
    2'd2:    dato2 <= ch2_rd_data[95:64];
    2'd3:    dato2 <= ch2_rd_data[127:96];
    endcase
	if (!we2 && cs2 && adr2[31:4]==ch2_addr[31:4])
		acki2 <= TRUE;

    // graphics controller
	dato3 <= ch3_rd_data;
	if (!we3 && cs3 && adr3[31:4]==ch3_addr[31:4])
		acki3 <= TRUE;
	dato4 <= ch4_rd_data;
	if (!we4 && cs4 && adr4[31:4]==ch4_addr[31:4])
		acki4 <= TRUE;

    // Sprite controller (read only)
    dato5 <= ch5_rd_data[adr5[5:4]];
	if (cs5 && adr5[31:6]==ch5_addr[31:6])
        acki5 <= TRUE;

    // SD card (disk) controller 
	case(adr6[3:2])
    2'd0:    dato6 <= ch6_rd_data[31:0];
    2'd1:    dato6 <= ch6_rd_data[63:32];
    2'd2:    dato6 <= ch6_rd_data[95:64];
    2'd3:    dato6 <= ch6_rd_data[127:96];
    endcase
	if (!we6 && cs6 && adr6[31:4]==ch6_addr[31:4])
		acki6 <= TRUE;

    // CPU #2
    dato7 <= adr7xx[4] ? ch7_rd_data[1] : ch7_rd_data[0];
    if (ch7_read)
        acki7 <= TRUE;

    // Address reservations
	if (sr1x & sr7x) begin
		if (toggle_sr) begin
			reserve_adr(4'h1,adr1xx);
			toggle_sr <= 1'b0;
		end
		else begin
			reserve_adr(4'h7,adr7xx);
			toggle_sr <= 1'b1;
		end
	end
	else begin
		if (sr1x)
			reserve_adr(4'h1,adr1xx);
		if (sr7x)
			reserve_adr(4'h7,adr7xx);
	end

	if (!cs0) acki0 <= FALSE;
	if (!cs1xx || !ics1) acki1 <= FALSE;
	if (!cs2) acki2 <= FALSE;
	if (!cs3) acki3 <= FALSE;
	if (!cs4) acki4 <= FALSE;
	if (!cs5) acki5 <= FALSE;
	if (!cs6) acki6 <= FALSE;
	if (!cs7xx || !ics7) acki7 <= FALSE;

case(state)
IDLE:
  // According to the docs there's no need to wait for calib complete.
  // Calib complete goes high in sim about 111 us.
  // Simulation setting must be set to FAST.
	if (calib_complete) begin
	  num_strips <= 2'd0;
	  strip_cnt <= 2'd0;
	  strip_cnt2 <= 2'd0;
		// Refresh must be about 8us. 292 clocks at 40MHz
/*
		if (refcnt>=16'd280) begin
			refcnt <= 16'd0;
			refreq <= TRUE;
			state <= WAIT_REFACK;
		end
		else
*/
		begin
		do_wr <= FALSE;
		// Write cycles take priority over read cycles.
		if (cs0 & we0) begin
			clear_cache(adr0);
			ch <= 3'd0;
			adr <= adr0;
			wmask <= ~sel0;
			dat128 <= dati0;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs0 & ~fast_read0) begin
			ch <= 3'd0;
			adr <= adr0;
			wmask <= 16'h0000;
			num_strips <= 2'd3;
			state <= PRESET;
		end
		else if (cs1xx & we1xx & (cs7xx ? toggle : 1'b1)) begin
            write_(4'd1,sel1xx,adr1xx,dati1xx,cr1,acki1,rb1,1'b0);
		end
		else if (cs2 & we2) begin
			clear_cache(adr2);
			ch <= 3'd2;
			sel <= sel2;
			adr <= adr2;
			dati <= dati2;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs3 & we3) begin
			clear_cache(adr3);
			ch <= 3'd3;
			adr <= adr3;
			wmask <= ~sel3;
			dat128 <= dati3;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs4 & we4) begin
			clear_cache(adr4);
			ch <= 3'd4;
			adr <= adr4;
			wmask <= ~sel4;
			dat128 <= dati4;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs6 & we6) begin
			clear_cache(adr6);
			ch <= 3'd6;
			sel <= sel6;
			adr <= adr6;
			dati <= dati6;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs7xx & we7xx) begin
            write_(4'd7,sel7xx,adr7xx,dati7xx,cr7xx,acki7,rb7,1'b1);
		end
		// Read cycles
		else if (!we1xx & cs1xx & ~fast_read1 & (cs7xx ? toggle : 1'b1)) begin
			toggle <= 1'b0;
			ch <= 3'd1;
			adr <= adr1xx;
			wmask <= 16'h0000;
			num_strips <= 2'd1;
			state <= PRESET;
		end
		else if (!we2 & cs2 & ~fast_read2) begin
			ch <= 3'd2;
			adr <= adr2;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we3 & cs3 & ~fast_read3) begin
			ch <= 3'd3;
			adr <= adr3;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we4 & cs4 & ~fast_read4) begin
			ch <= 3'd4;
			adr <= adr4;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (cs5 & ~fast_read5) begin
			ch <= 3'd5;
			adr <= adr5;
			wmask <= 16'h0000;
			num_strips = 2'd3;
			state <= PRESET;
		end
		else if (!we6 & cs6 & ~fast_read6) begin
			ch <= 3'd6;
			adr <= adr6;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we7xx & cs7xx & ~fast_read7) begin
			toggle <= 1'b1;
            ch <= 3'd7;
            adr <= adr7xx;
            wmask <= 16'h0000;
            dat128 <= {16{8'hff}};
			num_strips <= 2'd1;
            state <= PRESET;
		end
		end
	end
	else begin
		refcnt <= 16'd278;
	end

PRESET:
	begin
	    to_cnt <= 8'd0;
		case(ch)
		3'd0:
			begin
		        if (do_wr)
                    mem_addr <= {adr[26:4],4'h0};
		        else
                    mem_addr <= {adr[26:6],6'h0};
				mem_wdf_mask <= wmask;//{16{~we0}};
				mem_wdf_data <= dat128;
            end
        3'd1:
            begin
            if (do_wr)
                mem_addr <= {adr[26:4],4'h0};
            else
                mem_addr <= {adr[26:5],5'h0};
            mem_wdf_mask <= wmask;
            mem_wdf_data <= dat128;
            end

		3'd2:
            begin
            mem_addr <= {adr[26:4],4'h0};
            case(adr[3:2])
            2'd0:  mem_wdf_mask <= {12'hFFF,~sel[3:0]};
            2'd1:  mem_wdf_mask <= {8'hFF,~sel[3:0],4'hF};
            2'd2:  mem_wdf_mask <= {4'hF,~sel[3:0],8'hFF};
            2'd3:  mem_wdf_mask <= {~sel[3:0],12'hFFF};
            endcase
            mem_wdf_data <= {4{dati[31:0]}};
            end

		3'd3:
            begin
            mem_addr <= {adr[26:4],4'h0};
            mem_wdf_mask <= wmask;
            mem_wdf_data <= dat128;
            end
        3'd4:	
            begin
            mem_addr <= {adr[26:4],4'h0};
            mem_wdf_mask <= wmask;
            mem_wdf_data <= dat128;
            end
        3'd5:
            begin
            mem_addr <= {adr[26:6],6'h0};
            mem_wdf_mask <= wmask;
            mem_wdf_data <= dat128;
            end

		3'd6:
				begin
                mem_addr <= {adr[26:4],4'h0};
				case(adr[3:2])
				2'd0:	mem_wdf_mask <= {12'hFFF,~sel[3:0]};
				2'd1:	mem_wdf_mask <= {8'hFF,~sel[3:0],4'hF};
				2'd2:	mem_wdf_mask <= {4'hF,~sel[3:0],8'hFF};
				2'd3:	mem_wdf_mask <= {~sel[3:0],12'hFFF};
				endcase
				mem_wdf_data <= {4{dati[31:0]}};
				end
		3'd7:
		   begin
		      if (do_wr)
                mem_addr <= {adr[26:4],4'h0};
		      else
                mem_addr <= {adr[26:5],5'h0};
		      mem_wdf_mask <= wmask;
			  mem_wdf_data <= dat128;
		   end
		endcase
		if (do_wr)
			state <= SEND_DATA;
		else
			state <= SET_CMD_RD;
	end
SEND_DATA:
    begin
        to_cnt <= to_cnt + 8'd1;
        if (to_cnt==8'd100) begin
            state <= IDLE;
            idle_ack();
        end
        if (mem_wdf_rdy == TRUE) begin
            to_cnt <= 8'd0;
            state <= SET_CMD_WR;
        end
    end
SET_CMD_WR:
    begin
        to_cnt <= to_cnt + 8'd1;
        if (to_cnt==8'd100) begin
            state <= IDLE;
            idle_ack();
        end
        if (mem_rdy == TRUE)
            idle_ack();
    end
SET_CMD_RD:
    begin
        if (mem_rdy == TRUE) begin
            to_cnt <= 8'd0;
            if (strip_cnt==num_strips) begin
                state <= WAIT_RD;
            end
            else begin
                strip_cnt <= strip_cnt + 2'd1;
                mem_addr[26:4] <= mem_addr[26:4] + 10'd1;
            end
        end
        else begin
            to_cnt <= to_cnt + 8'd1;
            if (to_cnt==8'd100) begin
                idle_ack();
                state <= IDLE;
            end
        end
        if (mem_rd_data_valid & mem_rd_data_end) begin
            rd_data();
            if (strip_cnt2==num_strips)
                state <= IDLE;
        end
    end
WAIT_RD:
    begin
        to_cnt <= to_cnt + 1;
        if (to_cnt==8'd100) begin
            idle_ack();
            state <= IDLE;
        end
        if (mem_rd_data_valid & mem_rd_data_end) begin
            to_cnt <= 8'd0;
            rd_data();
            if (strip_cnt2==num_strips)
                state <= IDLE;
        end
    end
endcase
end

assign mem_wdf_wren = state==SEND_DATA;
assign mem_wdf_end = state==SEND_DATA;
assign mem_en = state==SET_CMD_RD || state==SET_CMD_WR;
assign mem_cmd = state==SET_CMD_RD ? CMD_READ : CMD_WRITE;

task rd_data;
begin
    case(ch)
    3'd0:
        begin
        if (strip_cnt2==num_strips)
          ch0_addr <= {adr0[31:6],6'h0};
        ch0_rd_data[strip_cnt2] <= mem_rd_data;
        strip_cnt2 <= strip_cnt2 + 2'd1;
        end
    3'd1:
        begin
        if (strip_cnt2==num_strips)
            ch1_addr <= {adr1xx[31:5],5'h00};
        ch1_rd_data[strip_cnt2[0]] <= mem_rd_data;
        strip_cnt2 <= strip_cnt2 + 2'd1;
        end
    3'd2:
        begin
        ch2_addr <= adr2;
        ch2_rd_data <= mem_rd_data;
        end
    3'd3:
        begin
        ch3_addr <= adr3;
        ch3_rd_data <= mem_rd_data;
        end
    3'd4:
        begin
        ch4_addr <= adr4;
        ch4_rd_data <= mem_rd_data;
        end
    3'd5:
        begin
        if (strip_cnt2==num_strips)
            ch5_addr <= {adr5[31:6],6'h00};
        ch5_rd_data[strip_cnt2] <= mem_rd_data;
        strip_cnt2 <= strip_cnt2 + 2'd1;
        end
    3'd6:
        begin
        ch6_addr <= adr6;
        ch6_rd_data <= mem_rd_data;
        end
    3'd7:
        begin
        if (strip_cnt2==num_strips)
          ch7_addr <= {adr7xx[31:5],5'h0};
        ch7_rd_data[strip_cnt2[0]] <= mem_rd_data;
        strip_cnt2 <= strip_cnt2 + 2'd1;
        end
    endcase
end
endtask

// Clear the read cache where the cache address matches the given address. This is to
// prevent reading stale data from a cache.
task clear_cache;
input [31:0] adr;
begin
	if (ch0_addr[31:6]==adr[31:6])
		ch0_addr <= 32'hFFFFFFFF;
	if (ch1_addr[31:5]==adr[31:5])
		ch1_addr <= 32'hFFFFFFFF;
	if (ch2_addr[31:4]==adr[31:4])
		ch2_addr <= 32'hFFFFFFFF;
	if (ch3_addr[31:4]==adr[31:4])
		ch3_addr <= 32'hFFFFFFFF;
	if (ch4_addr[31:4]==adr[31:4])
		ch4_addr <= 32'hFFFFFFFF;
	if (ch5_addr[31:6]==adr[31:6])
		ch5_addr <= 32'hFFFFFFFF;
	if (ch6_addr[31:4]==adr[31:4])
		ch6_addr <= 32'hFFFFFFFF;
	if (ch7_addr[31:5]==adr[31:5])
		ch7_addr <= 32'hFFFFFFFF;
end
endtask

// Two reservation buckets are allowed for. There are two (or more) CPU's in the
// system and as long as they are not trying to control the same resource (the
// same semaphore) then they should be able to set a reservation. Ideally there
// could be more reservation buckets available, but it starts to be a lot of
// hardware.
task reserve_adr;
input [3:0] ch;
input [31:0] adr;
begin
	// Ignore an attempt to reserve an address that's already reserved. The LWAR
	// instruction is usually called in a loop and we don't want it to use up
	// both address reservations.
	if (!(resv_ch0==ch && resv_adr0==adr) && !(resv_ch1==ch && resv_adr1==adr)) begin
		if (resv_ch0==4'hF) begin
			resv_ch0 <= ch;
			resv_adr0 <= adr;
		end
		else if (resv_ch1==4'hF) begin
			resv_ch1 <= ch;
			resv_adr1 <= adr;
		end
		else begin
			// Here there were no free reservation buckets, so toss one of the
			// old reservations out.
			if (match[6]) begin
				resv_ch0 <= ch;
				resv_adr0 <= adr;
			end
			else begin
				resv_ch1 <= ch;
				resv_adr1 <= adr;
			end
		end
	end
end
endtask

task next_state;
input [3:0] st;
begin
    state <= st;
end
endtask

task idle_ack;
begin
    next_state(IDLE);
    case(ch)
    3'd0:   acki0 <= TRUE;
    3'd1:   acki1 <= TRUE;
    3'd2:   acki2 <= TRUE;
    3'd3:   acki3 <= TRUE;
    3'd4:   acki4 <= TRUE;
    3'd5:   acki5 <= TRUE;
    3'd6:   acki6 <= TRUE;
    3'd7:   acki7 <= TRUE;
    endcase
end
endtask

task write_;
input [3:0] channel;
input [15:0] sel;
input [31:0] ad;
input [127:0] dat;
input cr;
output acki;
output rb;
input tog;
begin
    toggle <= tog;
    ch <= channel;
    adr <= ad;
    dat128 <= dat;
    wmask <= ~sel;
    //    acki7 <= TRUE;
    //    nextcyc7 <= 1'b0;
    if (cr) begin
        rb <= FALSE;
        acki <= TRUE;
        state <= IDLE;
        if ((resv_ch0==channel) && (resv_adr0[31:4]==ad[31:4])) begin
            resv_ch0 <= 4'hF;
            do_wr <= TRUE;
            state <= PRESET;
            rb <= TRUE;
            acki <= FALSE;
            clear_cache(ad);
        end
        if ((resv_ch1==channel) && (resv_adr1[31:4]==ad[31:4])) begin
            resv_ch1 <= 4'hF;
            do_wr <= TRUE;
            state <= PRESET;
            rb <= TRUE;
            acki <= FALSE;
            clear_cache(ad);
        end
    end
    else begin
        do_wr <= TRUE;
        acki <= FALSE;
        state <= PRESET;
        clear_cache(ad);
    end
end
endtask

endmodule

