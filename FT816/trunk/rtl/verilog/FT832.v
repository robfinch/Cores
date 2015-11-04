`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT832.v
//  - 8/16/32 bit CPU
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
`define TRUE		1'b1
`define FALSE		1'b0

`define DEBUG		1'b1

`define SUPPORT_ICACHE	1'b1
`define ICACHE_4K		1'b1
//`define ICACHE_16K		1'b1
//`define ICACHE_2WAY		1'b1
//`define SUPPORT_DCACHE	1'b1
`define SUPPORT_BCD		1'b1
`define SUPPORT_DIVMOD		1'b1
`define SUPPORT_EM8		1'b1
`define SUPPORT_816		1'b1
//`define SUPPORT_EXEC	1'b1
`define SUPPORT_BERR	1'b1
`define SUPPORT_STRING	1'b1
`define SUPPORT_SHIFT	1'b1
//`define SUPPORT_CGI		1'b1			// support the control giveaway interrupt

`define BRK_VECTNO	9'd0
`define SLP_VECTNO	9'd1
`define BYTE_RST_VECT	24'h00FFFC
`define BYTE_NMI_VECT	24'h00FFFA
`define BYTE_IRQ_VECT	24'h00FFFE
`define BYTE_ABT_VECT	24'h00FFF8
`define BYTE_COP_VECT	24'h00FFF4
`define RST_VECT_816	24'h00FFFC
`define IRQ_VECT_816	24'h00FFEE
`define NMI_VECT_816	24'h00FFEA
`define ABT_VECT_816	24'h00FFE8
`define BRK_VECT_816	24'h00FFE6
`define COP_VECT_816	24'h00FFE4
`define RST_VECT_832	24'h00FFFC
`define IRQ_VECT_832	24'h00FFDE
`define NMI_VECT_832	24'h00FFDA
`define ABT_VECT_832	24'h00FFD8
`define BRK_VECT_832	24'h00FFD6
`define COP_VECT_832	24'h00FFD4

`define BRK			9'h00
`define BRK2		9'h100
`define RTI			9'h40
`define RTS			9'h60
`define PHP			9'h08
`define CLC			9'h18
`define CMC         9'h118
`define PLP			9'h28
`define SEC			9'h38
`define PHA			9'h48
`define CLI			9'h58
`define PLA			9'h68
`define SEI			9'h78
`define DEY			9'h88
`define DEY4		9'h188
`define TYA			9'h98
`define TAY			9'hA8
`define CLV			9'hB8
`define SEV			9'h1B8
`define INY			9'hC8
`define INY4		9'h1C8
`define CLD			9'hD8
`define INX			9'hE8
`define INX4		9'h1E8
`define SED			9'hF8
`define ROR_ACC		9'h6A
`define TXA			9'h8A
`define TXS			9'h9A
`define TAX			9'hAA
`define TSX			9'hBA
`define DEX			9'hCA
`define DEX4		9'h1CA
`define NOP			9'hEA
`define NOP2		9'h1EA
`define TXY			9'h9B
`define TYX			9'hBB
`define TAS			9'h1B
`define TSA			9'h3B
`define TRS			9'h8B
`define TSR			9'hAB
`define TCD			9'h5B
`define TDC			9'h7B
`define STP			9'hDB
`define NAT			9'hFB
`define EMM			9'hFB
`define XCE			9'hFB
`define INA			9'h1A
`define DEA			9'h3A
`define SEP			9'hE2
`define REP			9'hC2
`define PEA			9'hF4
`define PEI			9'hD4
`define PER			9'h62
`define WDM			9'h42
`define PEAxl       9'h1F4

`define ADC_IMM		9'h69
`define ADC_ZP		9'h65
`define ADC_ZPX		9'h75
`define ADC_IX		9'h61
`define ADC_IY		9'h71
`define ADC_IYL		9'h77
`define ADC_ABS		9'h6D
`define ADC_ABSX	9'h7D
`define ADC_ABSY	9'h79
`define ADC_I		9'h72
`define ADC_IL		9'h67
`define ADC_AL		9'h6F
`define ADC_ALX		9'h7F
`define ADC_DSP		9'h63
`define ADC_DSPIY	9'h73
`define ADC_XDSPIY	9'h173
`define ADC_XIYL	9'h177
`define ADC_XIL		9'h167
`define ADC_XABS	9'h16D
`define ADC_XABSX	9'h17D
`define ADC_XABSY	9'h179

`define SBC_IMM		9'hE9
`define SBC_ZP		9'hE5
`define SBC_ZPX		9'hF5
`define SBC_IX		9'hE1
`define SBC_IY		9'hF1
`define SBC_IYL		9'hF7
`define SBC_ABS		9'hED
`define SBC_ABSX	9'hFD
`define SBC_ABSY	9'hF9
`define SBC_I		9'hF2
`define SBC_IL		9'hE7
`define SBC_AL		9'hEF
`define SBC_ALX		9'hFF
`define SBC_DSP		9'hE3
`define SBC_DSPIY	9'hF3
`define SBC_XDSPIY	9'h1F3
`define SBC_XIYL	9'h1F7
`define SBC_XIL		9'h1E7
`define SBC_XABS	9'h1ED
`define SBC_XABSX	9'h1FD
`define SBC_XABSY	9'h1F9

`define CMP_IMM		9'hC9
`define CMP_ZP		9'hC5
`define CMP_ZPX		9'hD5
`define CMP_IX		9'hC1
`define CMP_IY		9'hD1
`define CMP_IYL		8'hD7
`define CMP_ABS		9'hCD
`define CMP_ABSX	9'hDD
`define CMP_ABSY	9'hD9
`define CMP_I		9'hD2
`define CMP_IL		9'hC7
`define CMP_AL		9'hCF
`define CMP_ALX		9'hDF
`define CMP_DSP		9'hC3
`define CMP_DSPIY	9'hD3
`define CMP_XDSPIY	9'h1D3
`define CMP_XIYL	8'h1D7
`define CMP_XIL		9'h1C7
`define CMP_XABS	9'h1CD
`define CMP_XABSX	9'h1DD
`define CMP_XABSY	9'h1D9

`define LDA_IMM8	9'hA5
`define LDA_IMM16	9'hB9
`define LDA_IMM32	9'hA9

`define AND_IMM		9'h29
`define AND_ZP		9'h25
`define AND_ZPX		9'h35
`define AND_IX		9'h21
`define AND_IY		9'h31
`define AND_IYL		9'h37
`define AND_ABS		9'h2D
`define AND_ABSX	9'h3D
`define AND_ABSY	9'h39
`define AND_RIND	9'h32
`define AND_I		9'h32
`define AND_IL		9'h27
`define AND_DSP		9'h23
`define AND_DSPIY	9'h33
`define AND_AL		9'h2F
`define AND_ALX		9'h3F
`define AND_XDSPIY	9'h133
`define AND_XIL		9'h127
`define AND_XIYL	9'h137
`define AND_XABS	9'h12D
`define AND_XABSX	9'h13D
`define AND_XABSY	9'h139

`define ORA_IMM		9'h09
`define ORA_ZP		9'h05
`define ORA_ZPX		9'h15
`define ORA_IX		9'h01
`define ORA_IY		9'h11
`define ORA_IYL		9'h17
`define ORA_ABS		9'h0D
`define ORA_ABSX	9'h1D
`define ORA_ABSY	9'h19
`define ORA_I		9'h12
`define ORA_IL		9'h07
`define ORA_AL		9'h0F
`define ORA_ALX		9'h1F
`define ORA_DSP		9'h03
`define ORA_DSPIY	9'h13
`define ORA_XDSPIY	9'h113
`define ORA_XIL		9'h107
`define ORA_XIYL	9'h117
`define ORA_XABS	9'h10D
`define ORA_XABSX	9'h11D
`define ORA_XABSY	9'h119

`define EOR_IMM		9'h49
`define EOR_ZP		9'h45
`define EOR_ZPX		9'h55
`define EOR_IX		9'h41
`define EOR_IY		9'h51
`define EOR_IYL		9'h57
`define EOR_ABS		9'h4D
`define EOR_ABSX	9'h5D
`define EOR_ABSY	9'h59
`define EOR_RIND	9'h52
`define EOR_I		9'h52
`define EOR_IL		9'h47
`define EOR_DSP		9'h43
`define EOR_DSPIY	9'h53
`define EOR_AL		9'h4F
`define EOR_ALX		9'h5F
`define EOR_XDSPIY	9'h153
`define EOR_XIL		9'h147
`define EOR_XIYL	9'h157
`define EOR_XABS	9'h14D
`define EOR_XABSX	9'h15D
`define EOR_XABSY	9'h159

//`define LDB_RIND	9'hB2	// Conflict with LDX #imm16

`define LDA_IMM		9'hA9
`define LDA_ZP		9'hA5
`define LDA_ZPX		9'hB5
`define LDA_IX		9'hA1
`define LDA_IY		9'hB1
`define LDA_IYL		9'hB7
`define LDA_ABS		9'hAD
`define LDA_ABSX	9'hBD
`define LDA_ABSY	9'hB9
`define LDA_I		9'hB2
`define LDA_IL		9'hA7
`define LDA_AL		9'hAF
`define LDA_ALX		9'hBF
`define LDA_DSP		9'hA3
`define LDA_DSPIY	9'hB3
`define LDA_XDSPIY	9'h1B3
`define LDA_XIL		9'h1A7
`define LDA_XIYL	9'h1B7
`define LDA_XABS	9'h1AD
`define LDA_XABSX	9'h1BD
`define LDA_XABSY	9'h1B9

`define STA_ZP		9'h85
`define STA_ZPX		9'h95
`define STA_IX		9'h81
`define STA_IY		9'h91
`define STA_IYL		9'h97
`define STA_ABS		9'h8D
`define STA_ABSX	9'h9D
`define STA_ABSY	9'h99
`define STA_I		9'h92
`define STA_IL		9'h87
`define STA_AL		9'h8F
`define STA_ALX		9'h9F
`define STA_DSP		9'h83
`define STA_DSPIY	9'h93
`define STA_XDSPIY	9'h193
`define STA_XIL		9'h187
`define STA_XIYL	9'h197
`define STA_XABS	9'h18D
`define STA_XABSX	9'h19D
`define STA_XABSY	9'h199

`define ASL_ACC		9'h0A
`define ASR_ACC		9'h10A
`define ASL_ZP		9'h06
`define ASL_RR		9'h06
`define ASL_ZPX		9'h16
`define ASL_ABS		9'h0E
`define ASL_ABSX	9'h1E
`define ASL_XABS	9'h10E
`define ASL_XABSX	9'h11E

`define ROL_ACC		9'h2A
`define ROL_ZP		9'h26
`define ROL_RR		9'h26
`define ROL_ZPX		9'h36
`define ROL_ABS		9'h2E
`define ROL_ABSX	9'h3E
`define ROL_XABS	9'h12E
`define ROL_XABSX	9'h13E

`define LSR_ACC		9'h4A
`define LSR_ZP		9'h46
`define LSR_RR		9'h46
`define LSR_ZPX		9'h56
`define LSR_ABS		9'h4E
`define LSR_ABSX	9'h5E
`define LSR_XABS	9'h14E
`define LSR_XABSX	9'h15E

`define ROR_RR		9'h66
`define ROR_ZP		9'h66
`define ROR_ZPX		9'h76
`define ROR_ABS		9'h6E
`define ROR_ABSX	9'h7E
`define ROR_XABS	9'h16E
`define ROR_XABSX	9'h17E

`define DEC_RR		9'hC6
`define DEC_ZP		9'hC6
`define DEC_ZPX		9'hD6
`define DEC_ABS		9'hCE
`define DEC_ABSX	9'hDE
`define DEC_XABS	9'h1CE
`define DEC_XABSX	9'h1DE
`define INC_RR		9'hE6
`define INC_ZP		9'hE6
`define INC_ZPX		9'hF6
`define INC_ABS		9'hEE
`define INC_ABSX	9'hFE
`define INC_XABS	9'h1EE
`define INC_XABSX	9'h1FE

`define BIT_IMM		9'h89
`define BIT_ZP		9'h24
`define BIT_ZPX		9'h34
`define BIT_ABS		9'h2C
`define BIT_ABSX	9'h3C
`define BIT_XABS	9'h12C
`define BIT_XABSX	9'h13C

// CMP = SUB r0,...
// BIT = AND r0,...
`define BPL			9'h10
`define BVC			9'h50
`define BCC			9'h90
`define BNE			9'hD0
`define BMI			9'h30
`define BVS			9'h70
`define BCS			9'hB0
`define BEQ			9'hF0
`define BRL			9'h82
`define BRA			9'h80
`define BGT         9'h110
`define BLT         9'h130
`define BGE         9'h190
`define BLE         8'h1B0

`define JML			9'h5C
`define JMF			9'h15C
`define JMP			9'h4C
`define JMP_IND		9'h6C
`define JMP_INDX	9'h7C
`define JMP_RIND	9'hD2
`define JSR			9'h20
`define JSL			9'h22
`define JSF			9'h122
`define JSR_IND		9'h2C
`define JSR_INDX	9'hFC
`define JSR_RIND	9'hC2
`define RTS			9'h60
`define RTL			9'h6B
`define RTF			9'h16B
`define BSR			9'h62
`define NOP			9'hEA

`define PLX			9'hFA
`define PLY			9'h7A
`define PHX			9'hDA
`define PHY			9'h5A
`define WAI			9'hCB
`define PHB			9'h8B
`define PHD			9'h0B
`define PHK			9'h4B
`define XBA			9'hEB
`define COP			9'h02
`define PLB			9'hAB
`define PLD			9'h2B

`define LDX_IMM		9'hA2
`define LDX_ZP		9'hA6
`define LDX_ZPX		9'hB6
`define LDX_ZPY		9'hB6
`define LDX_ABS		9'hAE
`define LDX_ABSY	9'hBE
`define LDX_XABS	9'h1AE
`define LDX_XABSY	9'h1BE

`define LDX_IMM32	9'hA2
`define LDX_IMM16	9'hB2
`define LDX_IMM8	9'hA6

`define LDY_IMM		9'hA0
`define LDY_ZP		9'hA4
`define LDY_ZPX		9'hB4
`define LDY_IMM32	9'hA0
`define LDY_IMM8	9'hA1
`define LDY_ABS		9'hAC
`define LDY_ABSX	9'hBC
`define LDY_XABS	9'h1AC
`define LDY_XABSX	9'h1BC

`define STX_ZP		9'h86
`define STX_ZPX		9'h96
`define STX_ZPY		9'h96
`define STX_ABS		9'h8E
`define STX_XABS	9'h18E

`define STY_ZP		9'h84
`define STY_ZPX		9'h94
`define STY_ABS		9'h8C
`define STY_XABS	9'h18C

`define STZ_ZP		9'h64
`define STZ_ZPX		9'h74
`define STZ_ABS		9'h9C
`define STZ_ABSX	9'h9E
`define STZ_XABS	9'h19C
`define STZ_XABSX	9'h19E

`define CPX_IMM		9'hE0
`define CPX_IMM32	9'hE0
`define CPX_IMM8	9'hE2
`define CPX_ZP		9'hE4
`define CPX_ZPX		9'hE4
`define CPX_ABS		9'hEC
`define CPX_XABS	9'h1EC
`define CPY_IMM		9'hC0
`define CPY_IMM32	9'hC0
`define CPY_IMM8	9'hC1
`define CPY_ZP		9'hC4
`define CPY_ZPX		9'hC4
`define CPY_ABS		9'hCC
`define CPY_XABS	9'h1CC

`define TRB_ZP		9'h14
`define TRB_ZPX		9'h14
`define TRB_ABS		9'h1C
`define TRB_XABS	9'h11C
`define TSB_ZP		9'h04
`define TSB_ZPX		9'h04
`define TSB_ABS		9'h0C
`define TSB_XABS	9'h10C

`define MVP			9'h44
`define MVN			9'h54
`define STS			9'h144

// Page Two Opcodes
`define PG2			9'h42

`define NOTHING		5'd0
`define SR_70		5'd1
`define SR_310		5'd2
`define BYTE_70		5'd3
`define WORD_310	5'd4
`define PC_70		5'd5
`define PC_158		5'd6
`define PC_2316		5'd7
`define PC_3124		5'd8
`define PC_310		5'd9
`define WORD_311	5'd10
`define IA_310		5'd11
`define IA_70		5'd12
`define IA_158		5'd13
`define BYTE_71		5'd14
`define WORD_312	5'd15
`define WORD_313	5'd16
`define WORD_314	5'd17
`define IA_2316		5'd18
`define HALF_70		5'd19
`define HALF_158	5'd20
`define HALF_71		5'd21
`define HALF_159	5'd22
`define HALF_71S	5'd23
`define HALF_159S	5'd24
`define BYTE_72		5'd25
`define TRIP_2316	5'd26
`define WORD_71S    5'd27

`define STW_DEF		6'h0
`define STW_RES8	6'd14
`define STW_R4		6'd15
`define STW_ACC8	6'd16
`define STW_X8		6'd17
`define STW_Y8		6'd18
`define STW_PC3124	6'd19
`define STW_PC2316	6'd20
`define STW_PC158	6'd21
`define STW_PC70	6'd22
`define STW_SR70	6'd23
`define STW_Z8		6'd24
`define STW_DEF8	6'd25
`define STW_DEF70	6'd26
`define STW_DEF158	6'd27
`define STW_DEF2316	6'd28

`define STW_ACC70	6'd32
`define STW_ACC158	6'd33
`define STW_X70		6'd34
`define STW_X158	6'd35
`define STW_Y70		6'd36
`define STW_Y158	6'd37
`define STW_Z70		6'd38
`define STW_Z158	6'd39
`define STW_DBR		6'd40
`define STW_DPR158	6'd41
`define STW_DPR70	6'd42
`define STW_TMP158	6'd43
`define STW_TMP70	6'd44
`define STW_IA158	6'd45
`define STW_IA70	6'd46
`define STW_BRA		6'd47

`define STW_X3124   6'd48
`define STW_X2316   6'd49
`define STW_Y3124   6'd50
`define STW_Y2316   6'd51
`define STW_Z3124   6'd52
`define STW_Z2316   6'd53
`define STW_DBR70	6'd54
`define STW_DBR158	6'd55
`define STW_DBR2316	6'd56
`define STW_DBR3124	6'd57

// Input Frequency is 32 times the 00 clock

module FT832(rst, clk, clko, cyc, phi11, phi12, phi81, phi82, nmi, irq, abort, e, mx, rdy, be, vpa, vda, mlb, vpb, rw, ad, db, err_i, rty_i);
parameter SUPPORT_TRIBYTES = 1'b0;
parameter STORE_SKIPPING = 1'b1;
parameter EXTRA_LONG_BRANCHES = 1'b1;
parameter RESET1 = 6'd0;
parameter IFETCH = 6'd1;
parameter DECODE = 6'd5;
parameter STORE1 = 6'd9;
parameter STORE2 = 6'd10;
parameter JSR161 = 6'd11;
parameter RTS1 = 6'd12;
parameter IY3 = 6'd13;
parameter BSR1 = 6'd14;
parameter BYTE_IX5 = 6'd15;
parameter BYTE_IY5 = 6'd16;
parameter WAIT_DHIT = 6'd17;
parameter BYTE_CALC = 6'd18;
parameter BUS_ERROR = 6'd19;
parameter LOAD_MAC1 = 6'd20;
parameter LOAD_MAC2 = 6'd21;
parameter LOAD_MAC3 = 6'd22;
parameter MVN3 = 6'd23;
parameter IFETCH0 = 6'd24;
parameter LOAD_DCACHE = 6'd26;
parameter LOAD_ICACHE = 6'd27;
parameter LOAD_IBUF1 = 6'd28;
parameter LOAD_IBUF2 = 6'd29;
parameter LOAD_IBUF3 = 6'd30;
parameter ICACHE1 = 6'd31;
parameter IBUF1 = 6'd32;
parameter DCACHE1 = 6'd33;
parameter HALF_CALC = 6'd35;
parameter MVN816 = 6'd36;
parameter WORD_CALC = 6'd42;

input rst;
input clk;
output clko;
output reg [4:0] cyc;
output phi11;
output phi12;
output phi81;
output phi82;
input nmi;
input irq;
input abort;
output e;
output mx;
input rdy;
input be;
output reg vpa;
output reg vda;
output reg mlb;
output reg vpb;
output tri rw;
output tri [31:0] ad;
inout tri [7:0] db;
input err_i;
input rty_i;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

reg [31:0] phi1r,phi2r;
reg rwo;
reg [23:0] ado;
reg [7:0] dbo;

reg [7:0] dbi;
reg pg2;
reg [5:0] state;
reg [5:0] retstate;
reg [127:0] ir;
wire [8:0] ir9 = {pg2,ir[7:0]};
reg [23:0] pc,opc;
reg [31:0] cs;      // code segment
wire [31:0] cspc = cs + pc;
reg [15:0] dpr;		// direct page register
reg [31:0] ds;      // data segment
wire [7:0] dbr = ds[23:16];		// data bank register
reg [31:0] x,y,acc,sp;
reg [15:0] tmp;
wire [15:0] acc16 = acc[15:0];
wire [7:0] acc8=acc[7:0];
wire [7:0] x8=x[7:0];
wire [7:0] y8=y[7:0];
wire [15:0] x16 = x[15:0];
wire [15:0] y16 = y[15:0];
wire [15:0] sp16 = sp[15:0];
wire [31:0] acc_dec = acc - 32'd1;
wire [31:0] acc_inc = acc + 32'd1;
wire [31:0] x_dec = x - 32'd1;
wire [31:0] x_inc = x + 32'd1;
wire [31:0] y_dec = y - 32'd1;
wire [31:0] y_inc = y + 32'd1;
wire [31:0] sp_dec = sp - 32'd1;
wire [31:0] sp_inc = sp + 32'd1;
wire [31:0] sp_dec2 = sp - 32'd2;
wire [31:0] sp_dec4 = sp - 32'd4;
reg gie;	// global interrupt enable (set when sp is loaded)
reg hwi;	// hardware interrupt indicator
reg im;
reg cf,vf,nf,zf,df,em,bf;
reg m816,m832;
reg x_bit,m_bit;
reg m16,m32;
reg xb16,xb32;
//wire m16 = m816 & ~m_bit;
//wire xb16 = m816 & ~x_bit;
always @(m816,m832,x_bit,m_bit)
begin
    case ({~m832,~m816,x_bit,m_bit})
    4'b0000:    begin m32 = `FALSE; m16 = `TRUE; xb32 = `TRUE; xb16 = `FALSE; end
    4'b0001:    begin m32 = `FALSE; m16 = `TRUE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b0010:    begin m32 = `FALSE; m16 = `FALSE; xb32 = `TRUE; xb16 = `FALSE; end
    4'b0011:    begin m32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b0100:    begin m32 = `TRUE; m16 = `FALSE; xb32 = `TRUE; xb16 = `FALSE; end
    4'b0101:    begin m32 = `TRUE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b0110:    begin m32 = `FALSE; m16 = `FALSE; xb32 = `TRUE; xb16 = `FALSE; end
    4'b0111:    begin m32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b1000:    begin m32 = `FALSE; m16 = `TRUE; xb32 = `FALSE; xb16 = `TRUE; end
    4'b1001:    begin m32 = `FALSE; m16 = `TRUE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b1010:    begin m32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `TRUE; end
    4'b1011:    begin m32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b1100:    begin n32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b1101:    begin n32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b1110:    begin n32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    4'b1111:    begin n32 = `FALSE; m16 = `FALSE; xb32 = `FALSE; xb16 = `FALSE; end
    endcase 
end
wire [31:0] x32 = xb32 ? x : xb16 ? {16'h0000,x[15:0] : {24'h000000,x[7:0]};
wire [31:0] y32 = xb32 ? y : xb16 ? {16'h0000,y[15:0] : {24'h000000,y[7:0]};
wire [7:0] sr8 = m816 ? {nf,vf,m_bit,x_bit,df,im,zf,cf} : {nf,vf,1'b0,bf,df,im,zf,cf};
reg nmi1,nmi_edge;
reg wai;
reg [31:0] b32;
wire [15:0] b16 = b32[15:0];
wire [7:0] b8 = b32[7:0];
reg [32:0] res32;
wire resc8 = res32[8];
wire resc16 = res32[16];
wire resc32 = res32[32];
wire resz8 = ~|res32[7:0];
wire resz16 = ~|res32[15:0];
wire resz32 = ~|res32[31:0];
wire resn8 = res32[7];
wire resn16 = res32[15];
wire resn32 = res32[31];
reg [31:0] radr;
reg [31:0] wadr;
reg [31:0] wdat;
wire [7:0] rdat;
reg [4:0] load_what;
reg [5:0] store_what;
reg s8,s16,s32;
reg [15:0] tmp16;
reg first_ifetch;
reg [31:0] derr_address;

reg [8:0] intno;
reg isBusErr;
reg isBrk,isMove,isSts;
reg isMove816;
reg isRTI,isRTL,isRTS,isRTF;
reg isRMW;
reg isSub;
reg isJsrIndx,isJsrInd;
reg isIY,isIY24,isI24,isIY32,isI32;

wire isCmp = ir9==`CPX_ZPX || ir9==`CPX_ABS ||
			 ir9==`CPY_ZPX || ir9==`CPY_ABS;
wire isRMW8 =
			 ir9==`ASL_ZP || ir9==`ROL_ZP || ir9==`LSR_ZP || ir9==`ROR_ZP || ir9==`INC_ZP || ir9==`DEC_ZP ||
			 ir9==`ASL_ZPX || ir9==`ROL_ZPX || ir9==`LSR_ZPX || ir9==`ROR_ZPX || ir9==`INC_ZPX || ir9==`DEC_ZPX ||
			 ir9==`ASL_ABS || ir9==`ROL_ABS || ir9==`LSR_ABS || ir9==`ROR_ABS || ir9==`INC_ABS || ir9==`DEC_ABS ||
			 ir9==`ASL_ABSX || ir9==`ROL_ABSX || ir9==`LSR_ABSX || ir9==`ROR_ABSX || ir9==`INC_ABSX || ir9==`DEC_ABSX ||
			 ir9==`ASL_XABS || ir9==`ROL_XABS || ir9==`LSR_XABS || ir9==`ROR_XABS || ir9==`INC_XABS || ir9==`DEC_XABS ||
             ir9==`ASL_XABSX || ir9==`ROL_XABSX || ir9==`LSR_XABSX || ir9==`ROR_XABSX || ir9==`INC_XABSX || ir9==`DEC_XABSX ||
			 ir9==`TRB_ZP || ir9==`TRB_ZPX || ir9==`TRB_ABS || ir9==`TSB_ZP || ir9==`TSB_ZPX || ir9==`TSB_ABS
			 ;
wire isBranch = ir9==`BRA || ir9==`BEQ || ir9==`BNE || ir9==`BVS || ir9==`BVC || ir9==`BMI || ir9==`BPL || ir9==`BCS || ir9==`BCC ||
                ir9==`BGT || ir9==`BGE || ir9==`BLT || ir9==`BLE;

ft832_icachemem uicm1
(
    .wclk(clk),
    .wce(1'b1),
    .wr(wr_icache),
    .wa(ado[11:0]),
    .i(db),
    .rclk(~clk),
    .rce(1'b1),
    .pc(cspc[11:0]),
    .insn(insn)
);

// Registerable decodes
// The following decodes can be registered because they aren't needed until at least the cycle after
// the DECODE stage.

always @(posedge clk)
	if (state==RESET1)
		isBrk <= `TRUE;
	else if (state==DECODE) begin
		isRMW <= isRMW8;
		isRTI <= ir9==`RTI;
		isRTL <= ir9==`RTL;
		isRTS <= ir9==`RTS;
		isRTF <= ir9==`RTF;
		isBrk <= ir9==`BRK || ir9==`COP;
		isMove <= ir9==`MVP || ir9==`MVN;
		isJsrIndx <= ir9==`JSR_INDX;
		isJsrInd <= ir9==`JSR_IND;
	end

assign mx = clk ? m_bit : x_bit;
assign e = ~m816;

wire [15:0] bcaio;
wire [15:0] bcao;
wire [15:0] bcsio;
wire [15:0] bcso;
wire bcaico,bcaco,bcsico,bcsco;
wire bcaico8,bcaco8,bcsico8,bcsco8;

`ifdef SUPPORT_BCD
BCDAdd4 ubcdai1 (.ci(cf),.a(acc16),.b(ir[23:8]),.o(bcaio),.c(bcaico),.c8(bcaico8));
BCDAdd4 ubcda2 (.ci(cf),.a(acc16),.b(b8),.o(bcao),.c(bcaco),.c8(bcaco8));
BCDSub4 ubcdsi1 (.ci(cf),.a(acc16),.b(ir[23:8]),.o(bcsio),.c(bcsico),.c8(bcsico8));
BCDSub4 ubcds2 (.ci(cf),.a(acc16),.b(b8),.o(bcso),.c(bcsco),.c8(bcsco8));
`endif

wire [7:0] dati = db;

// Evaluate branches
// 
reg takb;
always @(ir9 or cf or vf or nf or zf)
case(ir9)
`BEQ:	takb <= zf;
`BNE:	takb <= !zf;
`BPL:	takb <= !nf;
`BMI:	takb <= nf;
`BCS:	takb <= cf;
`BCC:	takb <= !cf;
`BVS:	takb <= vf;
`BVC:	takb <= !vf;
`BRA:	takb <= 1'b1;
`BRL:	takb <= 1'b1;
`BGT:   takb <= (nf & vf & !zf) | (!nf & !vf & !zf);
`BGE:   takb <= (nf & vf) | (!nf & !vf);
`BLE:   takb <= zf | (nf & !vf) | (!nf & vf);
`BLT:   takb <= (nf & !vf) | (!nf & vf);
default:	takb <= 1'b0;
endcase

reg [31:0] ia;
wire [31:0] mvnsrc_address	= m832 ? ds + x32 : {8'h00,ir[23:16],x32[15:0]};
wire [31:0] mvndst_address	= m832 ? ds + y32 : {8'h00,ir[15: 8],y32[15:0]};
wire [31:0] iapy8 			= ia + y32;		// Don't add in abs8, already included with ia
wire [31:0] zp_address 		= {16'h00,ir[15:8]} + dpr;
wire [31:0] zpx_address 	= {{16'h00,ir[15:8]} + x32} + dpr;
wire [31:0] zpy_address	 	= {{16'h00,ir[15:8]} + y32} + dpr;
wire [31:0] abs_address 	= m832 ? ds + ir[23:8] : {ds[23:16],ir[23:8]};
wire [31:0] absx_address 	= m832 ? ds + ir[23:8] + x32 : {ds[23:16],ir[23:8]} + x32;	// simulates 64k bank wrap-around
wire [31:0] absy_address 	= m832 ? ds + ir[23:8] + y32 : {ds[23:16],ir[23:8]} + y32;
wire [31:0] al_address		= m832 ? ds + ir[31:8] : {8'h00,ir[31:8]};
wire [31:0] alx_address		= m832 ? ds + ir[31:8] + x32 : {8'h00,ir[31:8]} + x32;
wire [31:0] xal_address		= ds + ir[39:8];
wire [31:0] xalx_address	= ds + ir[39:8] + x32;
wire [31:0] xaly_address	= ds + ir[39:8] + y32;

wire [23:0] dsp_address = m832 ? ds + sp + ir[15:8] :
                          m816 ? {16'h0000,sp16 + ir[15:8]} : {24'h000001,sp[7:0]+ir[15:8]};
reg [23:0] vect;

assign rw = be ? rwo : 1'bz;
assign ad = be ? ado : {32{1'bz}};
assign db = rwo ? {8{1'bz}} : be ? dbo : {8{1'bz}};

reg [31:0] phi11r,phi12r,phi81r,phi82r;
assign phi11 = phi11r[31];
assign phi12 = phi12r[31];
assign phi81 = phi81r[31];
assign phi82 = phi82r[31];

always @(posedge clk)
if (~rst) begin
	cyc <= 5'd0;
	phi11r <= 32'b01111111111111100000000000000000;
	phi12r <= 32'b00000000000000000111111111111110;
	phi81r <= 32'b01110000011100000111000001110000;
	phi82r <= 32'b00000111000001110000011100000111;
end
else begin
	cyc <= cyc + 5'd1;
	phi11r <= {phi11r[30:0],phi11r[31]};
	phi12r <= {phi12r[30:0],phi12r[31]};
	phi81r <= {phi81r[30:0],phi81r[31]};
	phi82r <= {phi82r[30:0],phi82r[31]};
end

//-----------------------------------------------------------------------------
// Clock control
// - reset or NMI reenables the clock
// - this circuit must be under the clk_i domain
//-----------------------------------------------------------------------------
//
reg cpu_clk_en;
reg clk_en;
wire clkx;
BUFGCE u20 (.CE(cpu_clk_en), .I(clk), .O(clkx) );
assign clko = clkx;
//assign clkx = clk;

always @(posedge clk)
if (~rst) begin
	cpu_clk_en <= 1'b1;
	nmi1 <= 1'b0;
end
else begin
	nmi1 <= nmi;
	if (nmi)
		cpu_clk_en <= 1'b1;
	else
		cpu_clk_en <= clk_en;
end

reg abort1;
reg abort_edge;
reg [2:0] imcd;	// interrupt mask enable count down

always @(posedge clkx)
if (~rst) begin
	vpa <= `FALSE;
	vda <= `FALSE;
	vpb <= `TRUE;
	rwo <= `TRUE;
	ado <= 32'h000000;
	dbo <= 8'h00;
	nmi_edge <= 1'b0;
	wai <= 1'b0;
	pg2 <= 1'b0;
	ir <= 8'hEA;
	cf <= 1'b0;
	df <= 1'b0;
	m816 <= 1'b0;
	m832 <= 1'b0;
	m_bit <= 1'b1;
	x_bit <= 1'b1;
	vect <= `BYTE_RST_VECT;
	state <= RESET1;
	em <= 1'b1;
	pc <= 24'h00FFF0;		// set high-order pc to zero
	cs <= 32'd0;
	ds <= 32'd0;
	dpr <= 16'h0000;
	clk_en <= 1'b1;
	im <= `TRUE;
	gie <= 1'b0;
	isIY <= 1'b0;
	isIY24 <= 1'b0;
	isI24 <= `FALSE;
	load_what <= `NOTHING;
	abort_edge <= 1'b0;
	abort1 <= 1'b0;
	imcd <= 3'b111;
end
else begin
abort1 <= abort;
if (~abort & abort1)
	abort_edge <= 1'b1;
if (~nmi & nmi1)
	nmi_edge <= 1'b1;
if (~nmi|~nmi1)
	clk_en <= 1'b1;
case(state)
RESET1:
	begin
		radr <= `BYTE_RST_VECT;
		load_what <= `PC_70;
		cs <= 32'd0;
		state <= LOAD_MAC1;
	end
IFETCH0:
	moveto_ifetch();
IFETCH:
	if (rdy) begin
		if (imcd != 3'b111)
			imcd <= {imcd[1:0],1'b0};
		if (imcd == 3'b000) begin
			imcd <= 3'b111;
			im <= 1'b0;
		end
		vect <= m832 ? `BRK_VECT_832 : m816 ? `BRK_VECT_816 : `BYTE_IRQ_VECT;
		hwi <= `FALSE;
		isBusErr <= `FALSE;
		pg2 <= FALSE;
		isIY <= `FALSE;
		isIY24 <= `FALSE;
		isIY32 <= `FALSE;
		isI24 <= `FALSE;
		isI32 <= `FALSE;
		s8 <= FALSE;
		s16 <= FALSE;
		s32 <= FALSE;
		store_what <= (m32 | m16) ? `STW_DEF70 : `STW_DEF;
		ir <= insn;
		opc <= pc;
		if (nmi_edge | ~irq)
			wai <= 1'b0;
		if (abort_edge) begin
			pc <= opc;
			ir[7:0] <= `BRK;
			abort_edge <= 1'b0;
			hwi <= `TRUE;
			vect <= m832 ? `ABT_VECT_832 : m816 ? `ABT_VECT_816 : `BYTE_ABT_VECT;
			vect[23:16] <= 8'h00;
			next_state(DECODE);
		end
		else if (nmi_edge & gie) begin
			ir[7:0] <= `BRK;
			nmi_edge <= 1'b0;
			hwi <= `TRUE;
			vect <= m832 ? `NMI_VECT_832 : m816 ? `NMI_VECT_816 : `BYTE_NMI_VECT;
			vect[23:16] <= 8'h00;
			next_state(DECODE);
		end
		else if (~irq & gie & ~im) begin
			ir[7:0] <= `BRK;
			hwi <= `TRUE;
			if (m832)
			    vect <= `IRQ_VECT_832;
			else if (m816)
				vect <= `IRQ_VECT_816;
			next_state(DECODE);
		end
		else if (!wai) begin
			next_state(DECODE);
		end
		else
			next_state(IFETCH);
		if (!abort_edge) begin
		case(ir9)
		// Note the break flag is not affected by SEP/REP
		// Setting the index registers to eight bit zeros out the upper part of the register.
		`SEP:
			begin
				cf <= cf | ir[8];
				zf <= zf | ir[9];
				im <= im | ir[10];
				df <= df | ir[11];
				if (m816|m832) begin
					x_bit <= x_bit | ir[12];
					m_bit <= m_bit | ir[13];
					//if (ir[13]) acc[31:8] <= 24'd0;
					if (ir[12]) begin
						x[31:8] <= 24'd0;
						y[31:8] <= 24'd0;
					end
				end
				vf <= vf | ir[14];
				nf <= nf | ir[15];
			end
		`REP:
			begin
				cf <= cf & ~ir[8];
				zf <= zf & ~ir[9];
				im <= im & ~ir[10];
				df <= df & ~ir[11];
				if (m816|m832) begin
					x_bit <= x_bit & ~ir[12];
					m_bit <= m_bit & ~ir[13];
				end
				vf <= vf & ~ir[14];
				nf <= nf & ~ir[15];
			end
		`XBA:
			begin
			    if (m832) begin
                    acc <= res32;
                    nf <= resn16;
                    zf <= resz16;
			    end
			    else begin
                    acc[15:0] <= res32[15:0];
                    nf <= resn8;
                    zf <= resz8;
				end
			end
		`TAY,`TXY,`DEY,`INY,`INY4,`DEY4:
			begin
                if (xb32) begin
                    y <= res32;
                    nf <= resn32;
                    zf <= resz32;
                end
                else if (xb16) begin
                    y <= {16'h0000,res32[15:0]};
                    nf <= resn16;
                    zf <= resz16;
                end
                else begin
                    y <= {24'h000000,res32[7:0]};
                    nf <= resn8;
                    zf <= resz8;
                end
            end
        `TAX,`TYX,`TSX,`DEX,`INX,`INX4,`DEX4:
			begin
                if (xb32) begin
                    x <= res32;
                    nf <= resn32;
                    zf <= resz32;
                end
                else if (xb16) begin
                    x <= {16'h0000,res32[15:0]};
                    nf <= resn16;
                    zf <= resz16;
                end
                else begin
                    x <= {24'h000000,res32[7:0]};
                    nf <= resn8;
                    zf <= resz8;
                end
            end
		`TSA,`TYA,`TXA,`INA,`DEA:
			begin
                if (m32) begin
                    acc <= res32;
                    nf <= resn32;
                    zf <= resz32;
                end
                else if (m16) begin
                    acc[15:0] <= {acc[31:16],res32[15:0]};
                    nf <= resn16;
                    zf <= resz16;
                end
                else begin
                    acc[7:0] <= {acc[31:8],res32[7:0]};
                    nf <= resn8;
                    zf <= resz8;
                end
            end
		`TAS,`TXS:
		    begin
		        if (m832) sp <= res32;
		        else if (m816) sp <= res32[15:0];
		        else sp <= {8'h01,res8[7:0]};
		        gie <= `TRUE;
		    end
		`TCD:	begin dpr <= res32[15:0]; end
		`TDC:	begin acc <= {16'h0000,res32[15:0]}; nf <= resn16; zf <= resz16; end
		`ADC_IMM:
			begin
			    if (m32) begin
					acc <= df ? bcaio : res32;
                    cf <= df ? bcaico : resc32;
    //                        vf <= resv8;
                    vf <= (res32[31] ^ b32[31]) & (1'b1 ^ acc[31] ^ b32[31]);
                    nf <= df ? bcaio[15] : resn32;
                    zf <= df ? bcaio==16'h0000 : resz32;
			    end
				else if (m16) begin
					acc[15:0] <= df ? bcaio : res32[15:0];
					cf <= df ? bcaico : resc16;
//						vf <= resv8;
					vf <= (res16[15] ^ b32[15]) & (1'b1 ^ acc[15] ^ b32[15]);
					nf <= df ? bcaio[15] : resn16;
					zf <= df ? bcaio==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcaio[7:0] : res32[7:0];
					cf <= df ? bcaico8 : resc8;
//						vf <= resv8;
					vf <= (res8[7] ^ b32[7]) & (1'b1 ^ acc[7] ^ b32[7]);
					nf <= df ? bcaio[7] : resn8;
					zf <= df ? bcaio[7:0]==8'h00 : resz8;
				end
			end
		`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_IYL,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_I,`ADC_IL,`ADC_AL,`ADC_ALX,`ADC_DSP,`ADC_DSPIY,
		`ADC_XABS,`ADC_XABSX,`ADC_XABSY,`ADC_XIYL,`ADC_XIL,`ADC_XDSPIY:
			begin
			    if (m32) begin
					acc <= df ? bcao : res32;
                    cf <= df ? bcaco : resc32;
                    vf <= (res32[31] ^ b32[31]) & (1'b1 ^ acc[31] ^ b32[31]);
                    nf <= df ? bcao[15] : resn32;
                    zf <= df ? bcao==16'h0000 : resz32;
			    end
				else if (m16) begin
					acc[15:0] <= df ? bcao : res32[15:0];
					cf <= df ? bcaco : resc16;
					vf <= (res32[15] ^ b32[15]) & (1'b1 ^ acc[15] ^ b32[15]);
					nf <= df ? bcao[15] : resn16;
					zf <= df ? bcao==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcao[7:0] : res32[7:0];
					cf <= df ? bcaco8 : resc8;
					vf <= (res32[7] ^ b32[7]) & (1'b1 ^ acc[7] ^ b32[7]);
					nf <= df ? bcao[7] : resn8;
					zf <= df ? bcao[7:0]==8'h00 : resz8;
				end
			end
		`SBC_IMM:
			begin
				if (m32) begin
                    acc <= df ? bcsio : res32;
                    cf <= ~(df ? bcsico : resc32);
                    vf <= (1'b1 ^ res32[31] ^ b32[31]) & (acc[31] ^ b32[31]);
                    nf <= df ? bcsio[15] : resn16;
                    zf <= df ? bcsio==16'h0000 : resz16;
                end
				else if (m16) begin
					acc[15:0] <= df ? bcsio : res32[15:0];
					cf <= ~(df ? bcsico : resc16);
					vf <= (1'b1 ^ res32[15] ^ b32[15]) & (acc[15] ^ b32[15]);
					nf <= df ? bcsio[15] : resn16;
					zf <= df ? bcsio==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcsio[7:0] : res32[7:0];
					cf <= ~(df ? bcsico8 : resc8);
					vf <= (1'b1 ^ res32[7] ^ b32[7]) & (acc[7] ^ b32[7]);
					nf <= df ? bcsio[7] : resn8;
					zf <= df ? bcsio[7:0]==8'h00 : resz8;
				end
			end
		`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_IYL,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_I,`SBC_IL,`SBC_AL,`SBC_ALX,`SBC_DSP,`SBC_DSPIY,
		`SBC_XABS,`SBC_XABSX,`SBC_XABSY,`SBC_XIYL,`SBC_XIL,`SBC_XDSPIY:
			begin
				if (m32) begin
                    acc <= df ? bcso : res32;
                    vf <= (1'b1 ^ res32[31] ^ b32[31]) & (acc[31] ^ b32[31]);
                    cf <= ~(df ? bcsco : resc16);
                    nf <= df ? bcso[15] : resn16;
                    zf <= df ? bcso==16'h0000 : resz16;
                end
				else if (m16) begin
					acc[15:0] <= df ? bcso : res32[15:0];
					vf <= (1'b1 ^ res32[15] ^ b32[15]) & (acc[15] ^ b32[15]);
					cf <= ~(df ? bcsco : resc16);
					nf <= df ? bcso[15] : resn16;
					zf <= df ? bcso==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcso[7:0] : res32[7:0];
					vf <= (1'b1 ^ res32[7] ^ b32[7]) & (acc[7] ^ b32[7]);
					cf <= ~(df ? bcsco8 : resc8);
					nf <= df ? bcso[7] : resn8;
					zf <= df ? bcso[7:0]==8'h00 : resz8;
				end
			end
		`CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_IYL,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_I,`CMP_IL,`CMP_AL,`CMP_ALX,`CMP_DSP,`CMP_DSPIY,
		`CMP_XABS,`CMP_XABSX,`CMP_XABSY,`CMP_XIYL,`CMP_XIL,`CMP_XDSPIY:
		        if (m32) begin cf <= ~resc32; nf <= resn32; zf <= resz32; end 
				else if (m16) begin cf <= ~resc16; nf <= resn16; zf <= resz16; end
				else                cf <= ~resc8; nf <= resn8; zf <= resz8; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS,`CPX_XABS,
		`CPY_IMM,`CPY_ZP,`CPY_ABS,`CPY_XABS:
		        if (xb32) begin cf <= ~resc32; nf <= resn32; zf <= resz32; end 
				else if (xb16) begin cf <= ~resc16; nf <= resn16; zf <= resz16; end
				else                 cf <= ~resc8; nf <= resn8; zf <= resz8; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX,`BIT_XABS,`BIT_XABSX:
		        if (m32) begin nf <= b32[31]; vf <= b32[30]; zf <= resz32; end 
				else if (m16) begin nf <= b32[15]; vf <= b32[14]; zf <= resz16; end
				else                nf <= b32[7]; vf <= b32[6]; zf <= resz8; end
		`TRB_ZP,`TRB_ABS,`TSB_ZP,`TSB_ABS,`TRB_XABS,`TSB_XABS:
		    if (n32) begin zf <= resz32; end
			else if (m16) begin zf <= resz16; end
			else                zf <= resz8; end
		`LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_IYL,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_I,`LDA_IL,`LDA_AL,`LDA_ALX,`LDA_DSP,`LDA_DSPIY,
		`LDA_XABS,`LDA_XABSX,`LDA_XABSY,`LDA_XIYL,`LDA_XIL,`LDA_XDSPIY,
		`AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_IYL,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_I,`AND_IL,`AND_AL,`AND_ALX,`AND_DSP,`AND_DSPIY,
		`AND_XABS,`AND_XABSX,`AND_XABSY,`AND_XIYL,`AND_XIL,`AND_XDSPIY,
		`ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_IYL,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_I,`ORA_IL,`ORA_AL,`ORA_ALX,`ORA_DSP,`ORA_DSPIY,
		`ORA_XABS,`ORA_XABSX,`ORA_XABSY,`ORA_XIYL,`ORA_XIL,`ORA_XDSPIY,
		`EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_IYL,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_I,`EOR_IL,`EOR_AL,`EOR_ALX,`EOR_DSP,`EOR_DSPIY,
		`ORA_XABS,`ORA_XABSX,`ORA_XABSY,`ORA_XIYL,`ORA_XIL,`ORA_XDSPIY:
		    if (m32) begin acc <= res32; nf <= resn32; zf <= resz32; end
			else if (m16) begin acc[15:0] <= res32[15:0]; nf <= resn16; zf <= resz16; end
			else begin acc[7:0] <= res32[7:0]; nf <= resn8; zf <= resz8; end
		`ASL_ACC:
		      if (m32) begin acc <= res32; cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin acc[15:0] <= res32[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end
		      else begin acc[7:0] <= res32[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ASR_ACC:
                if (m32) begin acc <= res32; cf <= resc32; nf <= resn32; zf <= resz32; end 
                else if (m16) begin acc[15:0] <= res32[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end
                else begin acc[7:0] <= res32[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
        `ROL_ACC:
		      if (m32) begin acc <= res32; cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin acc[15:0] <= res32[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end
		      else begin acc[7:0] <= res32[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`LSR_ACC:
		      if (m32) begin acc <= res32; cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin acc[15:0] <= res32[15:0]; cf <= resc32; nf <= resn16; zf <= resz16; end
		      else begin acc[7:0] <= res32[7:0]; cf <= resc32; nf <= resn8; zf <= resz8; end
		`ROR_ACC:
		      if (n32) begin acc <= res32; cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin acc[15:0] <= res32[15:0]; cf <= resc32; nf <= resn16; zf <= resz16; end
		      else begin acc[7:0] <= res32[7:0]; cf <= resc32; nf <= resn8; zf <= resz8; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX,`ASL_XABS,`ASL_XABSX:
		      if (m32) begin cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin cf <= resc16; nf <= resn16; zf <= resz16; end
		      else begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX,`ROL_XABS,`ROL_XABSX:
		      if (m32) begin cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin cf <= resc16; nf <= resn16; zf <= resz16; end
		      else begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX,`LSR_XABS,`LSR_XABSX:
		      if (m32) begin cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin cf <= resc32; nf <= resn16; zf <= resz16; end
		      else begin cf <= resc32; nf <= resn8; zf <= resz8; end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX,`ROR_XABS,`ROR_XABSZ:
		      if (m32) begin cf <= resc32; nf <= resn32; zf <= resz32; end 
		      else if (m16) begin cf <= resc32; nf <= resn16; zf <= resz16; end
		      else begin cf <= resc32; nf <= resn8; zf <= resz8; end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX,`INC_XABS,`INC_XABSX:
		      if (m32) begin nf <= resn32; zf <= resz32; end 
		      else if (m16) begin nf <= resn16; zf <= resz16; end
		      else begin nf <= resn8; zf <= resz8; end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX,`DEC_XABS,`DEC_XABSX:
		      if (m32) begin nf <= resn32; zf <= resz32; end 
		      else if (m16) begin nf <= resn16; zf <= resz16; end
		      else begin nf <= resn8; zf <= resz8; end
		`PLA:
		      if (m32) begin acc <= res32; zf <= resz32; nf <= resn32; end 
		      else if (m16) begin acc[15:0] <= res32[15:0]; zf <= resz16; nf <= resn16; end
		      else begin acc[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLX:
		      if (xb32) begin x <= res32; zf <= resz32; nf <= resn32; end 
		      else if (xb16) begin x[15:0] <= res32[15:0]; zf <= resz16; nf <= resn16; end
		      else begin x[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLY:
		      if (xb32) begin y <= res32; zf <= resz32; nf <= resn32; end 
		      else if (xb16) begin y[15:0] <= res16[15:0]; zf <= resz16; nf <= resn16; end
		      else begin y[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLB:	
		      if (m832) ds <= res32; nf <= resn32; zf <= resz32; end
		      else begin ds <= {8'h00,res8[7:0],16'h0000}; nf <= resn8; zf <= resz8; end
		`PLDS:	
                begin ds <= res32; nf <= resn32; zf <= resz32; end
        `PLD:   if (m832) begin dpr <= res32; nf <= resn32; zf <= resz32; end
		      	else begin dpr <= res16[15:0]; nf <= resn16; zf <= resz16; end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY,`LDX_XABS,`LDX_XABSY:
		      if (xb32) begin x <= res32; nf <= resn32; zf <= resz32; end 
		      else if (xb16) begin x[15:0] <= res32[15:0]; nf <= resn16; zf <= resz16; end
		      else begin x[7:0] <= res32[7:0]; nf <= resn8; zf <= resz8; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX,`LDY_XABS,`LDY_XABSX:
		      if (xb32) begin y <= res32; nf <= resn32; zf <= resz32; end 
		      else if (xb16) begin y[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end
		      else begin y[7:0] <= res32[7:0]; nf <= resn8; zf <= resz8; end
		endcase
		end	// abort_edge
	end

// Decode
DECODE:
	begin
		next_state(IFETCH);
		pc <= pc + 24'd1;
		case(ir9)
		`PG2: begin
		      pg2 <= TRUE;
		      ir <= {8'h00,ir[127:8]};
		      next_state(DECODE);
		      end
		`SEP:	;	// see byte_ifetch
		`REP:	;
		// XBA cannot be done in the ifetch stage because it'd repeat when there
		// was a cache miss, causing the instruction to be done twice.
		`XBA:	
			begin
			    if (m32)
			        res32 <= {acc[15:0],acc[31:16]};
			    else
			        res32 <= {acc[31:16],acc[7:0],acc[15:8]};
			end
		`STP:	begin clk_en <= 1'b0; end
		// Switching the processor mode always zeros out the upper part of the index registers.
		// switching to emulation mode sets 8 bit memory/indexes
		`XCE:	begin
					m816 <= ~cf;
					m832 <= ~vf;
					cf <= ~m816;
					vf <= ~m832;
					if (cf) begin		
						m_bit <= 1'b1;
						x_bit <= 1'b1;
						sp[31:8] <= 24'h01;
					end
					x[31:8] <= 24'd0;
					y[31:8] <= 24'd0;
				end
//		`NOP:	;	// may help routing
		`CLC:	begin cf <= 1'b0; end
		`SEC:	begin cf <= 1'b1; end
		`CMC:   cf <= ~cf;
		`CLV:	begin vf <= 1'b0; end
		`SEV:   vf <= 1'b1;
		`CLI:	begin imcd <= 3'b110; end
		`SEI:	begin im <= 1'b1; end
		`CLD:	begin df <= 1'b0; end
		`SED:	begin df <= 1'b1; end
		`WAI:	begin wai <= 1'b1; end
		`DEX:	begin res32 <= x_dec; end
		`INX:	begin res32 <= x_inc; end
		`DEY:	begin res32 <= y_dec; end
		`INY:	begin res32 <= y_inc; end
		`DEX4:    res32 <= x - 32'd4;
		`DEY4:    res32 <= y - 32'd4;
		`INX4:    res32 <= x + 32'd4;
		`INY4:    res32 <= y + 32'd4;
		`DEA:	res32 <= acc_dec;
		`INA:	res32 <= acc_inc;
		`TSX,`TSA:	res32 <= sp;
		`TXS,`TXA,`TXY:	begin res32 <= x; end
		`TAX,`TAY:	begin res32 <= acc; end
		`TAS:	res32 <= acc;
		`TYA,`TYX:	begin res32 <= y; end
		`TDC:		begin res32 <= dpr; end
		`TCD:		begin res32 <= acc; end
		`ASL_ACC:   res32 <= {acc,1'b0};
		`ROL_ACC:	res32 <= {acc,cf};
		`LSR_ACC:	if (m32) res32 <= {acc[0],1'b0,acc[31:1]};
		            else if (m16) res32 <= {acc[0],acc[31:16],1'b0,acc[15:1]};
		            else res32 <= {acc[0],acc[31:8],1'b0,acc[7:1]};
		`ROR_ACC:	if (m32) res32 <= {acc[0],cf,acc[31:1]};
		            else if (m16) res32 <= {acc[0],acc[31:16],cf,acc[15:1]};
		            else if res32 <= {acc[0],acc[31:8],cf,acc[7:1]};
		`RTS,`RTL,`RTF:
			begin
                begin
                    if (m832) begin
                        radr <= sp_inc;
                        sp <= sp_inc;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else begin
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
                    end
                end
				data_nack();
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end
		`RTI:	begin
                begin
                    if (m832) begin
                        radr <= sp_inc;
                        sp <= sp_inc;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else begin
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
                    end
                end
				data_nack();
				load_what <= `SR_70;
				state <= LOAD_MAC1;
				end
		`PHP:
    		begin
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                        store_what <= `STW_SR3124;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
        				store_what <= `STW_SR70;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
        				store_what <= `STW_SR70;
                    end
               end	
         		data_nack();
				state <= STORE1;
			end
        `PHA:   tsk_push(`STW_ACC70,m16);
		`PHX:	tsk_push(`STW_X70,xb16);
		`PHY:	tsk_push(`STW_Y70,xb16);
		`PLP:
			begin
                begin
                    if (m832) begin
                        radr <= sp_inc;
                        sp <= sp_inc;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else begin
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
                    end
                end
				load_what <= `SR_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PLA:
			begin
                begin
                    if (m832) begin
                        radr <= sp_inc;
                        sp <= sp_inc;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else begin
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
                    end
                end
                load_what <= m832 ? `WORD_71S : m16 ? `HALF_71S : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PLX,`PLY:
			begin
                begin
                    if (m832) begin
                        radr <= sp_inc;
                        sp <= sp_inc;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else begin
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
                    end
                end
				load_what <= m832 ? `WORD_71S : xb16 ? `HALF_71S : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PHDS:
		      begin
                  radr <= sp;
                  wadr <= sp;
                  sp <= sp_dec;
                  store_what <= `STW_DS3124;
                  data_nack();
                  state <= STORE1;
		      end
		`PHB:
			begin
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
        				store_what <= `STW_DS3124;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
        				store_what <= `STW_DS2316;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
        				store_what <= `STW_DS2316;
                    end
                end
				data_nack();
				state <= STORE1;
			end
		`PHD:
			begin
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
        				store_what <= `STW_DPR3124;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
        				store_what <= `STW_DPR158;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
        				store_what <= `STW_DPR158;
                    end
                end
				data_nack();
				state <= STORE1;
			end
		`PHCS:
            begin
                store_what <= `STW_CS3124;
                radr <= sp;
                wadr <= sp;
                sp <= sp_dec;
				data_nack();
                state <= STORE1;
            end
		`PHK:
			begin
                begin
                    if (m832) begin
                        store_what <= `STW_CS3124;
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                    end
                    else if (m816) begin
                        store_what <= `STW_PC2316;
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                    end
                    else begin
                        store_what <= `STW_PC2316;
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
                    end
                end
				data_nack();
				state <= STORE1;
			end
		`PLDS:
            begin
                radr <= sp_inc;
                sp <= sp_inc;
                load_what <= `WORD_71;
				data_nack();
                state <= LOAD_MAC1;
            end
		`PLB:
			begin
                begin
                    if (m832) begin
                        radr <= sp_inc;
                        sp <= sp_inc;
        				load_what <= `WORD_71;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
        				load_what <= `BYTE_71;
                    end
                    else begin
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
        				load_what <= `BYTE_71;
                    end
                end
				data_nack();
				state <= LOAD_MAC1;
			end
		`PLD:
			begin
                begin
                    if (m832) begin
        				load_what <= `WORD_71S;
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else if (m816) begin
        				load_what <= `HALF_71S;
                        radr <= {8'h00,sp_inc[15:0]};
                        sp <= sp_inc;
                    end
                    else begin
        				load_what <= `HALF_71S;
                        radr <= {16'h0001,sp_inc[7:0]};
                        sp <= {8'h1,sp_inc[7:0]};
                    end
                end
				data_nack();
				state <= LOAD_MAC1;
			end
		// Handle # mode
        `LDA_IMM:
            begin
                if (m32) pc <= pc + 24'd5;
                else if (m16) pc <= pc + 24'd3;
                else pc <= pc + 24'd2;
                res32 <= ir[39:8];
                next_state(IFETCH);
            end
        `LDX_IMM,`LDY_IMM:
            begin
                if (xb32) pc <= pc + 24'd5;
                else if (xb16) pc <= pc + 24'd3;
                else pc <= pc + 24'd2;
                res32 <= ir[39:8];
                next_state(IFETCH);
            end
        `ADC_IMM:
            begin
                if (m32) begin
                    pc <= pc + 24'd5;
                    res32 <= acc + ir[39:8] + {31'b0,cf};
                    b32 <= ir[39:8];        // for overflow calc
                end
                else if (m16) begin
                    pc <= pc + 24'd3;
                    res32 <= acc16 + ir[23:8] + {15'b0,cf};
                    b32 <= ir[23:8];        // for overflow calc
                end
                else begin
                    pc <= pc + 24'd2;
                    res32 <= acc8 + ir[15:8] + {7'b0,cf};
                    b32 <= ir[15:8];        // for overflow calc
                end
                next_state(IFETCH);
            end
        `SBC_IMM:
            begin
                if (m32) begin
                    pc <= pc + 24'd5;
                    res32 <= acc - ir[39:8] - {31'b0,~cf};
                    b32 <= ir[39:8];        // for overflow calc
                end
                else if (m16) begin
                     pc <= pc + 24'd3;
                     res32 <= acc16 - ir[23:8] - {15'b0,~cf};
                     b32 <= ir[15:8];        // for overflow calc
                end
                else begin
                    pc <= pc + 24'd2;
                    res32 <= acc8 - ir[15:8] - {7'b0,~cf};
                    b32 <= ir[15:8];        // for overflow calc
                end
                next_state(IFETCH);
            end
        `AND_IMM,`BIT_IMM:
            begin
                if (m32) pc <= pc + 24'd5;
                else if (m16) pc <= pc + 24'd3;
                else pc <= pc + 24'd2;
                res32 <= acc & ir[39:8];
                b32 <= ir[39:8];    // for bit flags
                next_state(IFETCH);
            end
        `ORA_IMM:
            begin
                if (m32) pc <= pc + 24'd5;
                else if (m16) pc <= pc + 24'd3;
                else pc <= pc + 24'd2;
                res32 <= acc | ir[39:8];
                next_state(IFETCH);
            end
        `EOR_IMM:
            begin
                if (m32) pc <= pc + 24'd5;
                else if (m16) pc <= pc + 24'd3;
                else pc <= pc + 24'd2;
                res32 <= acc ^ ir[39:8];
                next_state(IFETCH);
            end
        `CMP_IMM:
            begin
                if (m32) begin
                    pc <= pc + 24'd5;
                    res32 <= acc - ir[39:8];
                    b32 <= ir[39:8];        // for overflow calc
                end
                else if (m16) begin
                     pc <= pc + 24'd3;
                     res32 <= acc16 - ir[23:8];
                     b32 <= ir[15:8];        // for overflow calc
                end
                else begin
                    pc <= pc + 24'd2;
                    res32 <= acc8 - ir[15:8];
                    b32 <= ir[15:8];        // for overflow calc
                end
                next_state(IFETCH);
            end
        `CPX_IMM:
            begin
                if (m32) begin
                    pc <= pc + 24'd5;
                    res32 <= x32 - ir[39:8];
                    b32 <= ir[39:8];        // for overflow calc
                end
                else if (m16) begin
                     pc <= pc + 24'd3;
                     res32 <= x16 - ir[23:8];
                     b32 <= ir[15:8];        // for overflow calc
                end
                else begin
                    pc <= pc + 24'd2;
                    res32 <= x8 - ir[15:8];
                    b32 <= ir[15:8];        // for overflow calc
                end
                next_state(IFETCH);
            end
        `CPY_IMM:
            begin
                if (m32) begin
                    pc <= pc + 24'd5;
                    res32 <= y32 - ir[39:8];
                    b32 <= ir[39:8];        // for overflow calc
                end
                else if (m16) begin
                     pc <= pc + 24'd3;
                     res32 <= y16 - ir[23:8];
                     b32 <= ir[15:8];        // for overflow calc
                end
                else begin
                    pc <= pc + 24'd2;
                    res32 <= y8 - ir[15:8];
                    b32 <= ir[15:8];        // for overflow calc
                end
                next_state(IFETCH);
            end
		// Handle zp mode
        `LDA_ZP:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDX_ZP,`LDY_ZP:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_ZP,`SBC_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`CMP_ZP,
        `BIT_ZP,
        `ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`TRB_ZP,`TSB_ZP:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                wadr <= zp_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `INC_ZP,`DEC_ZP:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                wadr <= zp_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `CPX_ZP,`CPY_ZP:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                load_what <= xb32 ? `WORD_70 : xb16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_ZP:
            begin
                pc <= pc + 24'd2;
                wadr <= zp_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `STX_ZP:
            begin
                pc <= pc + 24'd2;
                wadr <= zp_address;
                if (xb32) s32 <= TRUE;
                else if (xb16) s16 <= TRUE;
                store_what <= `STW_X70;
                data_nack();
                state <= STORE1;
            end
        `STY_ZP:
            begin
                pc <= pc + 24'd2;
                wadr <= zp_address;
                if (xb32) s32 <= TRUE;
                else if (xb16) s16 <= TRUE;
                store_what <= `STW_Y70;
                data_nack();
                state <= STORE1;
            end
        `STZ_ZP:
            begin
                pc <= pc + 24'd2;
                wadr <= zp_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_Z70;
                data_nack();
                state <= STORE1;
            end
		// Handle zp,x mode
        `LDA_ZPX:
            begin
                pc <= pc + 24'd2;
                radr <= zpx_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDY_ZPX:
            begin
                pc <= pc + 24'd2;
                radr <= zpx_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_ZPX,`SBC_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`CMP_ZPX,
        `BIT_ZPX,
        `ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX:
            begin
                pc <= pc + 24'd2;
                radr <= zpx_address;
                wadr <= zpx_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_ZPX:
            begin
                pc <= pc + 24'd2;
                wadr <= zpx_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `STY_ZPX:
            begin
                pc <= pc + 24'd2;
                wadr <= zpx_address;
                if (xb32) s32 <= TRUE;
                else if (xb16) s16 <= TRUE;
                store_what <= `STW_Y70;
                data_nack();
                state <= STORE1;
            end
        `STZ_ZPX:
            begin
                pc <= pc + 24'd2;
                wadr <= zpx_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_Z70;
                data_nack();
                state <= STORE1;
            end
        // Handle zp,y
        `LDX_ZPY:
            begin
                pc <= pc + 24'd2;
                radr <= zpy_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STX_ZPY:
            begin
                pc <= pc + 24'd2;
                wadr <= zpy_address;
                if (xb32) s32 <= TRUE;
                else if (xb16) s16 <= TRUE;
                store_what <= `STW_X70;
                data_nack();
                state <= STORE1;
            end
		// Handle (zp,x)
        `ADC_IX,`SBC_IX,`AND_IX,`ORA_IX,`EOR_IX,`CMP_IX,`LDA_IX,`STA_IX:
            begin
                pc <= pc + 24'd2;
                radr <= zpx_address;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        // Handle (zp),y
        `ADC_IY,`SBC_IY,`AND_IY,`ORA_IY,`EOR_IY,`CMP_IY,`LDA_IY,`STA_IY:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                isIY <= `TRUE;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
		// Handle d,sp
        `LDA_DSP:
            begin
                pc <= pc + 24'd2;
                radr <= dsp_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_DSP,`SBC_DSP,`CMP_DSP,`ORA_DSP,`AND_DSP,`EOR_DSP:
            begin
                pc <= pc + 24'd2;
                radr <= dsp_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_DSP:
            begin
                pc <= pc + 24'd2;
                wadr <= dsp_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
		// Handle (d,sp),y
        `ADC_DSPIY,`SBC_DSPIY,`CMP_DSPIY,`ORA_DSPIY,`AND_DSPIY,`EOR_DSPIY,`LDA_DSPIY,`STA_DSPIY:
            begin
                pc <= pc + 24'd2;
                radr <= dsp_address;
                isIY <= `TRUE;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
		// Handle {d,sp},y
       `ADC_XDSPIY,`SBC_XDSPIY,`CMP_XDSPIY,`ORA_XDSPIY,`AND_XDSPIY,`EOR_XDSPIY,`LDA_XDSPIY,`STA_XDSPIY:
            begin
                pc <= pc + 24'd2;
                radr <= dsp_address;
                isIY32 <= `TRUE;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        // Handle [zp],y
        `ADC_IYL,`SBC_IYL,`AND_IYL,`ORA_IYL,`EOR_IYL,`CMP_IYL,`LDA_IYL,`STA_IYL:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                isIY24 <= `TRUE;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        // Handle {zp},y
        `ADC_XIYL,`SBC_XIYL,`AND_XIYL,`ORA_XIYL,`EOR_XIYL,`CMP_XIYL,`LDA_XIYL,`STA_XIYL:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                isIY32 <= `TRUE;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
		// Handle [zp]
        `ADC_IL,`SBC_IL,`AND_IL,`ORA_IL,`EOR_IL,`CMP_IL,`LDA_IL,`STA_IL:
            begin
                pc <= pc + 24'd2;
                isI24 <= `TRUE;
                radr <= zp_address;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
		// Handle {zp}
        `ADC_XIL,`SBC_XIL,`AND_XIL,`ORA_XIL,`EOR_XIL,`CMP_XIL,`LDA_XIL,`STA_XIL:
            begin
                pc <= pc + 24'd2;
                isI32 <= `TRUE;
                radr <= zp_address;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        // Handle (zp)
        `ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,`PEI:
            begin
                pc <= pc + 24'd2;
                radr <= zp_address;
                load_what <= `IA_70;
                data_nack();
                state <= LOAD_MAC1;
            end
		// Handle abs
        `LDA_ABS:
            begin
                pc <= pc + 24'd3;
                radr <= abs_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDX_ABS,`LDY_ABS:
            begin
                pc <= pc + 24'd3;
                radr <= abs_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_ABS,`SBC_ABS,`AND_ABS,`ORA_ABS,`EOR_ABS,`CMP_ABS,
        `ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS,`TRB_ABS,`TSB_ABS,
        `BIT_ABS:
            begin
                pc <= pc + 24'd3;
                radr <= abs_address;
                wadr <= abs_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `CPX_ABS,`CPY_ABS:
            begin
                pc <= pc + 24'd3;
                radr <= abs_address;
                load_what <= xb32 ? `WORD_70 : xb16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_ABS:
            begin
                pc <= pc + 24'd3;
                wadr <= abs_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `STX_ABS:
            begin
                pc <= pc + 24'd3;
                wadr <= abs_address;
                if (xb2) s32 <= `TRUE;
                else if (xb16) s16 <= `TRUE;
                store_what <= `STW_X70;
                data_nack();
                state <= STORE1;
            end    
        `STY_ABS:
            begin
                pc <= pc + 24'd3;
                wadr <= abs_address;
                if (xb2) s32 <= `TRUE;
                else if (xb16) s16 <= `TRUE;
                store_what <= `STW_Y70;
                data_nack();
                state <= STORE1;
            end
        `STZ_ABS:
            begin
                pc <= pc + 24'd3;
                wadr <= abs_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_Z70;
                data_nack();
                state <= STORE1;
            end
		// Handle xlabs
        `LDA_XABS:
            begin
                pc <= pc + 24'd5;
                radr <= xal_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDX_XABS,`LDY_XABS:
            begin
                pc <= pc + 24'd5;
                radr <= xal_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_XABS,`SBC_XABS,`AND_XABS,`ORA_XABS,`EOR_XABS,`CMP_XABS,
        `ASL_XABS,`ROL_XABS,`LSR_XABS,`ROR_XABS,`INC_XABS,`DEC_XABS,`TRB_XABS,`TSB_XABS,
        `BIT_XABS:
            begin
                pc <= pc + 24'd5;
                radr <= xal_address;
                wadr <= xal_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `CPX_XABS,`CPY_XABS:
            begin
                pc <= pc + 24'd5;
                radr <= xal_address;
                load_what <= xb32 ? `WORD_70 : xb16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_XABS:
            begin
                pc <= pc + 24'd5;
                wadr <= xal_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `STX_XABS:
            begin
                pc <= pc + 24'd5;
                wadr <= xal_address;
                if (xb2) s32 <= `TRUE;
                else if (xb16) s16 <= `TRUE;
                store_what <= `STW_X70;
                data_nack();
                state <= STORE1;
            end    
        `STY_XABS:
            begin
                pc <= pc + 24'd5;
                wadr <= xal_address;
                if (xb2) s32 <= `TRUE;
                else if (xb16) s16 <= `TRUE;
                store_what <= `STW_Y70;
                data_nack();
                state <= STORE1;
            end
        `STZ_XABS:
            begin
                pc <= pc + 24'd5;
                wadr <= xal_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_Z70;
                data_nack();
                state <= STORE1;
            end
        // Handle abs,x
        `LDA_ABSX:
            begin
                pc <= pc + 24'd3;
                radr <= absx_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_ABSX,`SBC_ABSX,`AND_ABSX,`ORA_ABSX,`EOR_ABSX,`CMP_ABSX,
        `ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX,`BIT_ABSX:
            begin
                pc <= pc + 24'd3;
                radr <= absx_address;
                wadr <= absx_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDY_ABSX:
            begin
                pc <= pc + 24'd3;
                radr <= absx_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_ABSX:
            begin
                pc <= pc + 24'd3;
                wadr <= absx_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `STZ_ABSX:
            begin
                pc <= pc + 24'd3;
                wadr <= absx_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_Z70;
                data_nack();
                state <= STORE1;
            end
        // Handle xlabs,x
        `LDA_XABSX:
            begin
                pc <= pc + 24'd5;
                radr <= xalx_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_XABSX,`SBC_XABSX,`AND_XABSX,`ORA_XABSX,`EOR_XABSX,`CMP_XABSX,
        `ASL_XABSX,`ROL_XABSX,`LSR_XABSX,`ROR_XABSX,`INC_XABSX,`DEC_XABSX,`BIT_XABSX:
            begin
                pc <= pc + 24'd5;
                radr <= xalx_address;
                wadr <= xalx_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDY_XABSX:
            begin
                pc <= pc + 24'd5;
                radr <= xalx_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_XABSX:
            begin
                pc <= pc + 24'd5;
                wadr <= xalx_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `STZ_XABSX:
            begin
                pc <= pc + 24'd5;
                wadr <= xalx_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_Z70;
                data_nack();
                state <= STORE1;
            end
		// Handle abs,y
        `LDA_ABSY:
            begin
                pc <= pc + 24'd3;
                radr <= absy_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                state <= LOAD_MAC1;
                data_nack();
            end
        `ADC_ABSY,`SBC_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`CMP_ABSY:
            begin
                pc <= pc + 24'd3;
                radr <= absy_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDX_ABSY:
            begin
                pc <= pc + 24'd3;
                radr <= absy_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_ABSY:
            begin
                pc <= pc + 24'd3;
                wadr <= absy_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
		// Handle xlabs,y
        `LDA_XABSY:
            begin
                pc <= pc + 24'd5;
                radr <= xaly_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                state <= LOAD_MAC1;
                data_nack();
            end
        `ADC_XABSY,`SBC_XABSY,`AND_XABSY,`ORA_XABSY,`EOR_XABSY,`CMP_XABSY:
            begin
                pc <= pc + 24'd5;
                radr <= xaly_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `LDX_XABSY:
            begin
                pc <= pc + 24'd5;
                radr <= xaly_address;
                load_what <= xb32 ? `WORD_71 : xb16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_XABSY:
            begin
                pc <= pc + 24'd5;
                wadr <= xaly_address;
                if (m32) s32 <= `TRUE;
                else if (m16) s16 <= `TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
		// Handle al
        `LDA_AL:
            begin
                pc <= pc + 24'd4;
                radr <= al_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_AL,`SBC_AL,`AND_AL,`ORA_AL,`EOR_AL,`CMP_AL:
            begin
                pc <= pc + 24'd4;
                radr <= al_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_AL:
            begin
                pc <= pc + 24'd4;
                wadr <= al_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
		// Handle alx
        `LDA_ALX:
            begin
                pc <= pc + 24'd4;
                radr <= alx_address;
                load_what <= m32 ? `WORD_71 : m16 ? `HALF_71 : `BYTE_71;
                data_nack();
                state <= LOAD_MAC1;
            end
        `ADC_ALX,`SBC_ALX,`AND_ALX,`ORA_ALX,`EOR_ALX,`CMP_ALX:
            begin
                pc <= pc + 24'd4;
                radr <= alx_address;
                load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `STA_ALX:
            begin
                pc <= pc + 24'd4;
                wadr <= alx_address;
                if (m32) s32 <= TRUE;
                else if (m16) s16 <= TRUE;
                store_what <= `STW_ACC70;
                data_nack();
                state <= STORE1;
            end
        `BRK:
            begin
                pc <= pc + 24'd2;
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
                    end
                end
                store_what <= m832 ? `STW_CS3124 : m816 ? `STW_PC2316 : `STW_PC158;// `STW_PC3124;
                data_nack();
                state <= STORE1;
                bf <= !hwi;
            end
		`COP:
            begin
                pc <= pc + 24'd2;
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
                    end
                end
                store_what <= m832 ? `STW_CS3124 : m816 ? `STW_PC2316 : `STW_PC158;// `STW_PC3124;
                state <= STORE1;
                vect <= m832 ? `COP_VECT_832 : m816 ? `COP_VECT_816 : `BYTE_COP_VECT;
                data_nack();
            end
		`BEQ,`BNE,`BPL,`BMI,`BCC,`BCS,`BVC,`BVS,`BRA,`BGT,`BGE,`BLT,`BLE:
            begin
                if (ir[15:8]==8'hFF) begin
                    if (takb)
                        pc <= pc + {{8{ir[31]}},ir[31:16]};
                    else
                        pc <= pc + 24'd4;
                end
                else begin
                    if (takb)
                        pc <= pc + {{16{ir[15]}},ir[15:8]};
                    else
                        pc <= pc + 24'd2;
                end
                next_state(IFETCH);
            end
		`JMP:
            begin
                vpa <= `TRUE;
                vda <= `TRUE;
                pc[15:0] <= ir[23:8];
                next_state(IFETCH);
            end
        `JMP_IND:
            begin
                radr <= abs_address;
                load_what <= `PC_70;
                data_nack();
                state <= LOAD_MAC1;
            end
        `JMP_INDX:
            begin
                radr <= absx_address;
                load_what <= `PC_70;
                data_nack();
                state <= LOAD_MAC1;
            end    
        `JSR,`JSR_INDX:
            begin
                pc <= pc + 24'd2;
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                        store_what <= `STW_PC158;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                        store_what <= `STW_PC158;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[31:8] <= 24'h1;
                        store_what <= `STW_PC158;
                    end
                end
                data_nack();
                state <= STORE1;
            end
        `BRL:
            begin
                vpa <= `TRUE;
                vda <= `TRUE;
                pc <= pc + {{8{ir[23]}},ir[23:8]};
                next_state(IFETCH);
            end
		`JML:
            begin
                vpa <= `TRUE;
                vda <= `TRUE;
                pc <= ir[31:8];
                next_state(IFETCH);
            end
		`JMF:
            begin
                vpa <= `TRUE;
                vda <= `TRUE;
                pc <= ir[31:8];
                // Switch modes ?
                if (ir[63:32]==32'hFFFFFFFF) begin
                    m832 <= `FALSE;
                    m816 <= `FALSE;
                    cs <= 32'd0;
                    x[31:8] <= 24'd0;
                    y[31:8] <= 24'd0;
                    sp[31:8] <= 24'd1;
                end
                else if (ir[63:32]==32'hFFFFFFFE) begin
                    m832 <= `FALSE;
                    m816 <= `TRUE;
                    cs <= 32'd0;
                    x[31:8] <= 24'd0;
                    y[31:8] <= 24'd0;
                    sp[31:16] <= 16'd0;
                end
                else
                    cs <= ir[63:32];
                next_state(IFETCH);
            end
        `JSL:
            begin
                pc <= pc + 24'd3;
                begin
                   if (m832) begin
                       store_what <= `STW_PC2316;
                       radr <= sp;
                       wadr <= sp;
                       sp <= sp_dec;
                   end
                   else if (m816) begin
                        store_what <= `STW_PC2316;
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                    end
                    else begin
                        store_what <= `STW_PC2316;
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[31:8] <= 24'h1;
                    end
                end
                data_nack();
                state <= STORE1;
            end
        `JSF:
            begin
                pc <= pc + 24'd7;
                store_what <= `STW_CS3124;
                radr <= sp;
                wadr <= sp;
                sp <= sp_dec;
                data_nack();
                state <= STORE1;
            end
		`PEA:
            begin
                pc <= pc + 24'd3;
                tmp32 <= ir[23:8];
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
                    end
                end
                store_what <= `STW_TMP158;
                data_nack();
                state <= STORE1;
            end
        `PER:
            begin
                pc <= pc + 24'd3;
                tmp32 <= pc[15:0] + ir[23:8] + 16'd3;
                begin
                    if (m832) begin
                        radr <= sp;
                        wadr <= sp;
                        sp <= sp_dec;
                        store_what <= `STW_TMP3124;
                    end
                    else if (m816) begin
                        radr <= {8'h00,sp[15:0]};
                        wadr <= {8'h00,sp[15:0]};
                        sp <= sp_dec;
                        store_what <= `STW_TMP158;
                    end
                    else begin
                        radr <= {16'h0001,sp[7:0]};
                        wadr <= {16'h0001,sp[7:0]};
                        sp[7:0] <= sp[7:0] - 8'd1;
                        sp[15:8] <= 8'h1;
                        store_what <= `STW_TMP158;
                    end
                end
                data_nack();
                state <= STORE1;
            end
		`MVN,`MVP:
            begin
                radr <= mvnsrc_address;
                load_what <= `BYTE_72;
                pc <= pc;       // override increment above
                data_nack();
                state <= LOAD_MAC1;
            end
        default:
			begin
				next_state(IFETCH);
			end
		endcase
	end

LOAD_MAC1:
`ifdef SUPPORT_DCACHE
    if (unCachedData)
`endif
    begin
        if (isRMW)
            mlb <= 1'b1;
        if (isBrk)
            vpb <= `TRUE;
        data_read(radr);
        state <= LOAD_MAC2;
    end
`ifdef SUPPORT_DCACHE
    else if (dhit)
        load_tsk(rdat,rdat8,rdat16);
    else begin
        retstate <= LOAD_MAC1;
        state <= DCACHE1;
    end
`endif
LOAD_MAC2:
    if (rdy) begin
        data_nack();
        begin
            case(load_what)
            `BYTE_70:
                    begin
                        b32 <= db;
                        state <= BYTE_CALC;
                    end
            `BYTE_71:
                    begin
                        moveto_ifetch();
                        res32 <= db;
                    end
            `HALF_70:
                        begin
                            b32[7:0] <= db;
                            load_what <= `HALF_158;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `HALF_158:
                        begin
                            b32[15:8] <= db;
                            state <= HALF_CALC;
                        end
            `HALF_71:
                        begin
                            res32[7:0] <= db;
                            load_what <= `HALF_159;
                            radr <= radr+32'd1;
                            next_state(LOAD_MAC1);
                        end
            `HALF_159:
                        begin
                            res32[15:8] <= db;
                            moveto_ifetch();
                        end
            `HALF_71S:
                        begin
                            res32[7:0] <= db;
                            load_what <= `HALF_159S;
                            inc_sp();
                            next_state(LOAD_MAC1);
                        end
            `HALF_159S:
                        begin
                            res32[15:8] <= db;
                            moveto_ifetch();
                        end
            `BYTE_72:
                        begin
                            wdat[7:0] <= db;
                            radr <= mvndst_address;
                            wadr <= mvndst_address;
                            store_what <= `STW_DEF70;
                            acc <= acc_dec;
                            if (ir9==`MVN) begin
                                x <= x_inc;
                                y <= y_inc;
                            end
                            else begin
                                x <= x_dec;
                                y <= y_dec;
                            end
                            next_state(STORE1);
                        end
            `WORD_70:
                        begin
                            b32[7:0] <= db;
                            load_what <= `WORD_158;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `WORD_158:
                        begin
                            b32[15:8] <= db;
                            load_what <= `WORD_2316;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `WORD_2316:
                        begin
                            b32[23:16] <= db;
                            load_what <= `WORD_3124;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `WORD_3124:
                        begin
                            b32[31:24] <= db;
                            state <= WORD_CALC;
                        end
            `WORD_71:
                        begin
                            b32[7:0] <= db;
                            load_what <= `WORD_159;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `WORD_159:
                        begin
                            b32[15:8] <= db;
                            load_what <= `WORD_2317;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `WORD_2317:
                        begin
                            b32[23:16] <= db;
                            load_what <= `WORD_3125;
                            radr <= radr+32'd1;
                            state <= LOAD_MAC1;
                        end
            `WORD_3125:
                        begin
                            b32[31:24] <= db;
                            moveto_ifetch();
                        end
            `SR_70:        begin
                            cf <= db[0];
                            zf <= db[1];
                            if (db[2])
                                im <= 1'b1;
                            else
                                imcd <= 3'b110;
                            df <= db[3];
                            if (m816|m832) begin
                                x_bit <= db[4];
                                m_bit <= db[5];
                                if (db[4]) begin
                                    x[31:8] <= 24'd0;
                                    y[31:8] <= 24'd0;
                                end
                                //if (db[5]) acc[31:8] <= 24'd0;
                            end
                            // The following load of the break flag is different than the '02
                            // which never loads the flag.
                            else
                                bf <= db[4];
                            vf <= db[6];
                            nf <= db[7];
                            if (m832) begin
                                load_what <= `SR158;
                                inc_sp();
                                state <= LOAD_MAC1;
                            end
                            else if (isRTI) begin
                                load_what <= `PC_70;
                                inc_sp();
                                state <= LOAD_MAC1;
                            end        
                            else begin    // PLP
                                moveto_ifetch();
                            end
                        end
            `SR_158:
                        begin
                            load_what <= `SR2316;
                            inc_sp();
                            state <= LOAD_MAC1;
                        end
            `SR_2316:
                        begin
                            load_what <= `SR3124;
                            inc_sp();
                            state <= LOAD_MAC1;
                        end
            `SR_3124:
                        begin
                            if (isRTI) begin
                                load_what <= `PC_70;
                                inc_sp();
                                state <= LOAD_MAC1;
                            end
                            else
                                moveto_ifetch();
                        end
             `PC_70:        begin
                            pc[7:0] <= db;
                            load_what <= `PC_158;
                            if (isRTI|isRTS|isRTL) begin
                                inc_sp();
                            end
                            else begin    // JMP (abs)
                                radr <= radr + 32'd1;
                            end
                            state <= LOAD_MAC1;
                        end
            `PC_158:    begin
                            pc[15:8] <= db;
                            if ((isRTI&m816)|isRTL|m832) begin
                                load_what <= `PC_2316;
                                inc_sp();
                                state <= LOAD_MAC1;
                            end
                            else if (isRTS)    // rts instruction
                                next_state(RTS1);
                            else            // jmp (abs)
                            begin
                                vpb <= `FALSE;
                                next_state(IFETCH0);
                            end
                        end
            `PC_2316:    begin
                            pc[23:16] <= db;
                            if (m832) begin
                                load_what <= `PC_3124;
                                inc_sp();
                                next_state(LOAD_MAC1);
                            end
                            else if (isRTL) begin
                                load_what <= `NOTHING;
                                next_state(RTS1);
                            end
                            else begin
                                load_what <= `NOTHING;
                                next_state(IFETCH0);
        //                        load_what <= `PC_3124;
        //                        if (isRTI) begin
        //                            inc_sp();
        //                        end
        //                        state <= LOAD_MAC1;    
                            end
                        end
              `PC_3124: begin
                            if (isRTS) begin
                                load_what <= `NOTHING;
                                next_state(RTS1);
                            end
                            else begin
                                inc_sp();
                                load_what <= `CS_70;
                                next_state(LOAD_MAC1);
                            end
                        end
              `CS_70:   begin
                              inc_sp();
                              cs[7:0] <= db;
                              load_what <= `CS_158;
                              next_state(LOAD_MAC1);
                        end
              `CS_158:   begin
                            inc_sp();
                            cs[15:8] <= db;
                            load_what <= `CS_2316;
                            next_state(LOAD_MAC1);
                        end
              `CS_2316:   begin
                              inc_sp();
                              cs[23:16] <= db;
                              load_what <= `CS_3124;
                              next_state(LOAD_MAC1);
                          end
              `CS_3124:   begin
                              cs[31:24] <= db;
                              vpb <= `FALSE;
                              next_state(IFETCH0);
                          end
        //    `PC_3124:    begin
        //                    pc[31:24] <= db;
        //                    load_what <= `NOTHING;
        //                    next_state(BYTE_IFETCH);
        //                end
            `IA_70:
                    begin
                        radr <= radr + 24'd1;
                        ia[7:0] <= db;
                        load_what <= `IA_158;
                        state <= LOAD_MAC1;
                    end
            `IA_158:
                    begin
                        ia[15:8] <= db;
                        ia[23:16] <= dbr;
                        if (isIY24|isI24) begin
                            radr <= radr + 24'd1;
                            load_what <= `IA_2316;
                            state <= LOAD_MAC1;
                        end
                        else
                            state <= isIY ? BYTE_IY5 : BYTE_IX5;
                    end
            `IA_2316:
                    begin
                        ia[23:16] <= db;
                        if (m832) begin
                            load_what <= `IA_3124;
                            next_atate(LOAD_MAC1);
                        end
                        else
                            state <= isIY24 ? BYTE_IY5 : BYTE_IX5;
                    end
            `IA_3124:
                    begin
                        ia[31:24] <= db;
                        state <= isIY24 ? BYTE_IY5 : BYTE_IX5;
                    end
            endcase
        end
        //endtask
//        load_tsk(db,b16);
    end
`ifdef SUPPORT_BERR
    else if (err_i) begin
        mlb <= 1'b0;
        data_nack();
        derr_address <= ado;
        intno <= 9'd508;
        state <= BUS_ERROR;
    end
`endif
RTS1:
    begin
        vpa <= `TRUE;
        vda <= `TRUE;
        pc <= pc + 24'd1;
        ado <= cs + pc + 24'd1;
        next_state(IFETCH1);
    end
BYTE_IX5:
    begin
        isI24 <= `FALSE;
        radr <= ia;
        load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
        state <= LOAD_MAC1;
        if (m32) s32 <= TRUE;
        else if (m16) s16 <= TRUE;
        if (ir[7:0]==`STA_IX || ir[7:0]==`STA_I || ir[7:0]==`STA_IL) begin
            wadr <= ia;
            store_what <= `STW_ACC70;
            state <= STORE1;
        end
        else if (ir[7:0]==`PEI) begin
            set_sp();
            store_what <= m832 ? `STW_IA3124 : `STW_IA158;
            state <= STORE1;
        end
    end
BYTE_IY5:
    begin
        isIY <= `FALSE;
        isIY24 <= `FALSE;
        radr <= iapy8;
        wadr <= iapy8;
        if (m32) s32 <= TRUE;
        else if (m16) s16 <= TRUE;
        store_what <= `STW_ACC70;
        load_what <= m32 ? `WORD_70 : m16 ? `HALF_70 : `BYTE_70;
        $display("IY addr: %h", iapy8);
        if (ir[7:0]==`STA_IY || ir[7:0]==`STA_IYL || ir[7:0]==`STA_DSPIY)
            state <= STORE1;
        else
            state <= LOAD_MAC1;
    end

STORE1:
	begin
		case(store_what)
		`STW_CS3124:    data_write(cs[31:24]);
		`STW_CS2316:    data_write(cs[23:16]);
		`STW_CS158:     data_write(cs[15:8]);
		`STW_CS70:      data_write(cs[7:0]);
		`STW_PC3124:    data_write(8'h00);
		`STW_PC2316:	data_write(pc[23:16]);
		`STW_PC158:		data_write(pc[15:8]);
		`STW_PC70:		data_write(pc[7:0]);
		`STW_SR3124:    data_write(8'h00);
		`STW_SR2316:    data_write(8'h00);
		`STW_SR158:     data_write(8'h00);
		`STW_SR70:		data_write(sr8);
		`STW_DEF8:		data_write(wdat);
		`STW_DEF70:		begin data_write(wdat); mlb <= 1'b1; end
		`STW_DEF158:	data_write(wdat[15:8]);
		`STW_DEF2316:	data_write(wdat[23:16]);
		`STW_DEF3124:	data_write(wdat[31:24]);
		`STW_ACC70:		begin data_write(acc); mlb <= 1'b1; end
		`STW_ACC158:	data_write(acc[15:8]);
		`STW_ACC2316:	data_write(acc[23:16]);
		`STW_ACC3124:	data_write(acc[31:24]);
		`STW_X70:		begin data_write(x); mlb <= 1'b1; end
		`STW_X158:		data_write(x[15:8]);
		`STW_X2316:		data_write(x[23:16]);
		`STW_X3124:		data_write(x[31:24]);
		`STW_Y70:		begin data_write(y); mlb <= 1'b1; end
		`STW_Y158:		data_write(y[15:8]);
		`STW_Y2316:		data_write(y[23:16]);
		`STW_Y3124:		data_write(y[31:24]);
		`STW_Z70:		begin data_write(8'h00); mlb <= 1'b1; end
		`STW_Z158:		data_write(8'h00);
		`STW_Z2316:		data_write(8'h00);
		`STW_Z3124:		data_write(8'h00);
		`STW_DS3124:    data_write(ds[31:24]);
		`STW_DS2316:    data_write(ds[23:16]);
		`STW_DS158:     data_write(ds[15:8]);
		`STW_DS70:      data_write(ds[7:0]);
		`STW_DPR158:	begin data_write(dpr[15:8]); mlb<= 1'b1; end
		`STW_DPR70:		data_write(dpr);
		`STW_TMP158:	begin data_write(tmp16[15:8]); mlb <= 1'b1; end
		`STW_TMP70:		data_write(tmp16);
		`STW_IA3124:	begin data_write(ia[31:24]); mlb <= 1'b1; end
		`STW_IA2316:	data_write(ia[23:16]);
		`STW_IA158:		begin data_write(ia[15:8]); mlb <= 1'b1; end
		`STW_IA70:		data_write(ia);
		default:	data_write(wdat);
		endcase
`ifdef SUPPORT_DCACHE
		radr <= wadr;		// Do a cache read to test the hit
`endif
		state <= STORE2;
	end
	
// Terminal state for stores. Update the data cache if there was a cache hit.
// Clear any previously set lock status
STORE2:
	if (rdy) begin
//		wdat <= dat_o;
		mlb <= 1'b0;
		data_nack();
		if (!em && (isMove|isSts)) begin
			state <= MVN3;
			retstate <= MVN3;
		end
		else begin
			if (em) begin
				if (isMove) begin
					state <= MVN816;
					retstate <= MVN816;
				end
				else begin
					moveto_ifetch();
					retstate <= IFETCH1;
				end
			end
			else begin
				moveto_ifetch();
				retstate <= IFETCH1;
			end
		end
		case(store_what)
		`STW_DEF70:
			begin
				wadr <= wadr + 32'd1;
				store_what <= `STW_DEF158;
				retstate <= STORE1;
				if (s16|s32) begin
					mlb <= 1'b1;
					vpa <= `FALSE;	// override moveto_ifetch() setting.
					vda <= `TRUE;
					state <= STORE1;
				end
			end
		`STW_DEF158:
			if (s32) begin
				wadr <= wadr + 32'd1;
				vpa <= `FALSE;	// override moveto_ifetch() setting.
                vda <= `TRUE;
				store_what <= `STW_DEF2316;
				state <= STORE1;
			end
		`STW_DEF2316:
            begin
                wadr <= wadr + 32'd1;
                vpa <= `FALSE;    // override moveto_ifetch() setting.
                vda <= `TRUE;
                store_what <= `STW_DEF3124;
                state <= STORE1;
            end
        `STW_ACC70:
            if (s16|s32) begin
                wadr <= wadr + 32'd1;
                mlb <= 1'b1;
                vpa <= `FALSE;
                vda <= `TRUE;
                store_what <= `STW_ACC158;
                state <= STORE1;
            end
		`STW_X70:
			if (s16|s32) begin
				mlb <= 1'b1;
				wadr <= wadr + 32'd1;
				vpa <= `FALSE;
				vda <= `TRUE;
				store_what <= `STW_X158;
				state <= STORE1;
			end
		`STW_Y70:
			if (s16|s32) begin
				mlb <= 1'b1;
				wadr <= wadr + 32'd1;
				vpa <= `FALSE;
				vda <= `TRUE;
				store_what <= `STW_Y158;
				state <= STORE1;
			end
		`STW_Z70:
			if (s16|s32) begin
				mlb <= 1'b1;
				wadr <= wadr + 32'd1;
				vpa <= `FALSE;
				vda <= `TRUE;
				store_what <= `STW_Z158;
				state <= STORE1;
			end
		`STW_DPR158:
			begin
				set_sp();
				vpa <= `FALSE;
				vda <= `TRUE;
				store_what <= `STW_DPR70;
				state <= STORE1;
			end
		`STW_TMP158:
			begin
				set_sp();
				vpa <= `FALSE;
				vda <= `FALSE;
				store_what <= `STW_TMP70;
				state <= STORE1;
			end
		`STW_IA158:
			begin
				set_sp();
				vpa <= `FALSE;
				vda <= `FALSE;
				store_what <= `STW_IA70;
				state <= STORE1;
			end
		`STW_CS3124:
		    begin
		        mlb <= `TRUE;
				set_sp();
                vpa <= `FALSE;
                vda <= `TRUE;
                store_what <= `STW_CS2316;
                state <= STORE1;
		    end
		`STW_CS2316:
            begin
                set_sp();
                store_what <= `STW_CS158;
                state <= STORE1;
            end
		`STW_CS158:
            begin
                set_sp();
                store_what <= `STW_CS70;
                state <= STORE1;
            end
		`STW_CS70:
            begin
                if (ir9 != `PHK) begin
                    set_sp();
                    store_what <= `STW_PC3124;
                    state <= STORE1;
                end
            end
        `STW_PC3124:
			begin
                set_sp();
                vpa <= `FALSE;
                vda <= `TRUE;
                store_what <= `STW_PC2316;
                state <= STORE1;
            end
        `STW_PC2316:
			begin
				if (ir9 != `PHK) begin
					set_sp();
					vpa <= `FALSE;
					vda <= `FALSE;
					store_what <= `STW_PC158;
					state <= STORE1;
				end
			end
		`STW_PC158:
			begin
				set_sp();
				vpa <= `FALSE;
				vda <= `FALSE;
				store_what <= `STW_PC70;
				state <= STORE1;
			end
		`STW_PC70:
			begin
				case({1'b0,ir[7:0]})
				`BRK,`COP:
						begin
						set_sp();
						vpa <= `FALSE;
						vda <= `TRUE;
						if (m832)
						    store_what <= `STW_SR3124;
						else
						    store_what <= `STW_SR70;
						state <= STORE1;
						end
				`JSR: 	begin
				        if (m832) begin
				            pc <= ir[31:8];
				            ado <= cs + ir[31:8];
				        end
				        else begin
						    pc[15:0] <= ir[23:8];
						    ado <= cs + {pc[23:16],ir[23:8]};
						end
						end
				`JSL: 	begin
				        if (m832) begin
				            pc <= ir[31:8];
				            cs <= ir[63:32];
                            ado <= ir[63:32] + ir[31:8];
				        end
				        else begin
                            pc[23:0] <= ir[31:8];
                            ado <= cs + ir[31:8];
						end
						end
				`JSR_INDX:
						begin
						vpa <= `FALSE;
						vda <= `FALSE;
						state <= LOAD_MAC1;
						load_what <= `PC_70;
						radr <= absx_address;
						end
				endcase
			end
		`STW_SR3124:
		    begin
				set_sp();
		        store_what <= `STW_SR2316;
		        state <= STORE1;
		    end
		`STW_SR2316:
            begin
				set_sp();
                store_what <= `STW_SR158;
                state <= STORE1;
            end
        `STW_SR158:
            begin
				set_sp();
                store_what <= `STW_SR70;
                state <= STORE1;
            end
        `STW_SR70:
			begin
				if (ir[7:0]==`BRK) begin
					load_what <= `PC_70;
					state <= LOAD_MAC1;
					vpa <= `FALSE;
					vda <= `FALSE;
					pc[23:16] <= 8'h00;//abs8[23:16];
					radr <= vect;
					im <= hwi;
					df <= 1'b0;
				end
				else if (ir[7:0]==`COP) begin
					load_what <= `PC_70;
					vpa <= `FALSE;
					vda <= `FALSE;
					state <= LOAD_MAC1;
					pc[23:16] <= 8'h00;//abs8[23:16];
					radr <= vect;
					im <= 1'b1;
				end
			end
		default:
			if (isJsrIndx) begin
				load_what <= `PC_310;
				vpa <= `FALSE;
				vda <= `FALSE;
				state <= LOAD_MAC1;
				radr <= ir[31:8] + x;
			end
			else if (isJsrInd) begin
				load_what <= `PC_310;
				vpa <= `FALSE;
				vda <= `FALSE;
				state <= LOAD_MAC1;
				radr <= ir[31:8];
			end
		endcase
`ifdef SUPPORT_DCACHE
		if (!dhit && write_allocate) begin
			state <= DCACHE1;
		end
`endif
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		mlb <= 1'b0;
		data_nack();
		derr_address <= ado[23:0];
		intno <= 9'd508;
		state <= BUS_ERROR;
	end
`endif

BYTE_CALC:
	begin
		moveto_ifetch();
		store_what <= `STW_DEF70;
		s8 <= TRUE;
		case(ir9)
		`ADC_IMM,`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_XABS,`ADC_XABSX,`ADC_XABSY,
		`ADC_IYL,`ADC_XIYL,`ADC_I,`ADC_IL,`ADC_XIL,`ADC_AL,`ADC_ALX,`ADC_DSP,`ADC_DSPIY,`ADC_XDSPIY:
		      begin res32 <= acc8 + b8 + {7'b0,cf}; end
		`SBC_IMM,`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_XABS,`SBC_XABSX,`SBC_XABSY,
		`SBC_IYL,`SBC_XIYL,`SBC_I,`SBC_IL,`SBC_XIL,`SBC_AL,`SBC_ALX,`SBC_DSP,`SBC_DSPIY,`SBC_XDSPIY:
		      begin res32 <= acc8 - b8 - {7'b0,~cf}; end
		`CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_XABS,`CMP_XABSX,`CMP_XABSY,
		`CMP_IYL,`CMP_XIYL,`CMP_I,`CMP_IL,`CMP_XIL,`CMP_AL,`CMP_ALX,`CMP_DSP,`CMP_DSPIY,`CMP_XDSPIY:
		      begin res32 <= acc8 - b8; end
		`AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_XABS,`AND_XABSX,`AND_XABSY,
		`AND_IYL,`AND_XIYL,`AND_I,`AND_IL,`AND_XIL,`AND_AL,`AND_ALX,`AND_DSP,`AND_DSPIY,`AND_XDSPIY:
		      begin res32 <= acc & b32; end
		`ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_XABS,`ORA_XABSX,`ORA_XABSY,
		`ORA_IYL,`ORA_XIYL,`ORA_I,`ORA_IL,`ORA_XIL,`ORA_AL,`ORA_ALX,`ORA_DSP,`ORA_DSPIY,`ORA_XDSPIY:
		      begin res32 <= acc | b32; end
		`EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_XABS,`EOR_XABSX,`EOR_XABSY,
		`EOR_IYL,`EOR_XIYL,`EOR_I,`EOR_IL,`EOR_XIL,`EOR_AL,`EOR_ALX,`EOR_DSP,`EOR_DSPIY,`EOR_XDSPIY:
		      begin res32 <= acc ^ b32; end
		`LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_XABS,`LDA_XABSX,`LDA_XABSY,
		`LDA_IYL,`LDA_XIYL,`LDA_I,`LDA_IL,`LDA_XIL,`LDA_AL,`LDA_ALX,`LDA_DSP,`LDA_DSPIY,`LDA_XDSPIY:
		      begin res32 <= b32; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX,`BIT_XABS,`BIT_XABSX:	begin res32 <= acc & b32; end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY,`LDX_XABS,`LDX_XABSY:	begin res32 <= b32; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX,`LDY_XABS,`LDY_XABSX:	begin res32 <= b32; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS,`CPX_XABS:	begin res32 <= x8 - b8; end
		`CPY_IMM,`CPY_ZP,`CPY_ABS,`CPY_XABS:	begin res32 <= y8 - b8; end
		`TRB_ZP,`TRB_ABS,`TRB_XABS:	begin res32 <= ~acc32 & b32; wdat <= ~acc32 & b32; state <= STORE1; data_nack(); end
		`TSB_ZP,`TSB_ABS,`TSB_XABS:	begin res32 <= acc32 | b32; wdat <= acc32 | b32; state <= STORE1; data_nack(); end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX,`ASL_XABS,`ASL_XABSX:	begin res32 <= {b8[7],23'b0,b8,1'b0}; wdat <= {b32[31:0],1'b0}; state <= STORE1; data_nack(); end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX,`ROL_XABS,`ROL_XABSX:	begin res32 <= {b8[7],23'b0,b8,cf}; wdat <= {b32[31:0],cf}; state <= STORE1; data_nack(); end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX,`LSR_XABS,`LSR_XABSX:	begin res32 <= {b8[0],b32[31:8],1'b0,b8[7:1]}; wdat <= {b32[31:8],1'b0,b8[7:1]}; state <= STORE1; data_nack(); end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX,`ROR_XABS,`ROR_XABSX:	begin res32 <= {b8[0],b32[31:8],cf,b8[7:1]}; wdat <= {b32[31:8],cf,b8[7:1]}; state <= STORE1; data_nack(); end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX,`INC_XABS,`INC_XABSX:	begin res32 <= b32 + 32'd1; wdat <= {b32+32'd1}; state <= STORE1; data_nack(); end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX,`DEC_XABS,`DEC_XABSX:	begin res32 <= b32 - 32'd1; wdat <= {b32-32'd1}; state <= STORE1; data_nack(); end
		endcase
	end

HALF_CALC:
	begin
		moveto_ifetch();
		store_what <= `STW_DEF70;
		s16 <= TRUE;
		case(ir9)
		`ADC_IMM,`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_XABS,`ADC_XABSX,`ADC_XABSY,
        `ADC_IYL,`ADC_XIYL,`ADC_I,`ADC_IL,`ADC_XIL,`ADC_AL,`ADC_ALX,`ADC_DSP,`ADC_DSPIY,`ADC_XDSPIY:
              begin res32 <= acc16 + b16 + {15'b0,cf}; end
        `SBC_IMM,`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_XABS,`SBC_XABSX,`SBC_XABSY,
        `SBC_IYL,`SBC_XIYL,`SBC_I,`SBC_IL,`SBC_XIL,`SBC_AL,`SBC_ALX,`SBC_DSP,`SBC_DSPIY,`SBC_XDSPIY:
              begin res32 <= acc16 - b16 - {15'b0,~cf}; end
        `CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_XABS,`CMP_XABSX,`CMP_XABSY,
        `CMP_IYL,`CMP_XIYL,`CMP_I,`CMP_IL,`CMP_XIL,`CMP_AL,`CMP_ALX,`CMP_DSP,`CMP_DSPIY,`CMP_XDSPIY:
              begin res32 <= acc16 - b16; end
        `AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_XABS,`AND_XABSX,`AND_XABSY,
        `AND_IYL,`AND_XIYL,`AND_I,`AND_IL,`AND_XIL,`AND_AL,`AND_ALX,`AND_DSP,`AND_DSPIY,`AND_XDSPIY:
              begin res32 <= acc & b32; end
        `ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_XABS,`ORA_XABSX,`ORA_XABSY,
        `ORA_IYL,`ORA_XIYL,`ORA_I,`ORA_IL,`ORA_XIL,`ORA_AL,`ORA_ALX,`ORA_DSP,`ORA_DSPIY,`ORA_XDSPIY:
              begin res32 <= acc | b32; end
        `EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_XABS,`EOR_XABSX,`EOR_XABSY,
        `EOR_IYL,`EOR_XIYL,`EOR_I,`EOR_IL,`EOR_XIL,`EOR_AL,`EOR_ALX,`EOR_DSP,`EOR_DSPIY,`EOR_XDSPIY:
              begin res32 <= acc ^ b32; end
        `LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_XABS,`LDA_XABSX,`LDA_XABSY,
        `LDA_IYL,`LDA_XIYL,`LDA_I,`LDA_IL,`LDA_XIL,`LDA_AL,`LDA_ALX,`LDA_DSP,`LDA_DSPIY,`LDA_XDSPIY:
              begin res32 <= b32; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX,`BIT_XABS,`BIT_XABSX:	begin res32 <= acc & b32; end
		`TRB_ZP,`TRB_ABS,`TRB_XABS:	begin res32 <= ~acc32 & b32; wdat <= ~acc32 & b32; state <= STORE1; data_nack(); end
		`TSB_ZP,`TSB_ABS,`TSB_XABS:	begin res32 <= acc32 | b32; wdat <= acc32 | b32; state <= STORE1; data_nack(); end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY,`LDX_XABS,`LDX_XABSY:	begin res32 <= b32; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX,`LDY_XABS,`LDY_XABSX:	begin res32 <= b32; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS,`CPX_XABS:	begin res32 <= x16 - b16; end
		`CPY_IMM,`CPY_ZP,`CPY_ABS,`CPY_XABS:	begin res32 <= y16 - b16; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX,`ASL_XABS,`ASL_XABSX:	begin res32 <= {b16[15],15'b0,b16,1'b0}; wdat <= {16'h0,b16[14:0],1'b0}; state <= STORE1; data_nack(); end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX,`ROL_XABS,`ROL_XABSX:	begin res32 <= {b16[15],15'b0,b16,cf}; wdat <= {16'h0,b16[14:0],cf}; state <= STORE1; data_nack(); end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX,`LSR_XABS,`LSR_XABSX:	begin res32 <= {b16[0],17'b0,b16[15:1]}; wdat <= {17'b0,b16[15:1]}; state <= STORE1; data_nack(); end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX,`ROR_XABS,`ROR_XABSX:	begin res32 <= {b16[0],16'b0,cf,b16[15:1]}; wdat <= {16'h0,cf,b16[15:1]}; state <= STORE1; data_nack(); end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX,`INC_XABS,`INC_XABSX:	begin res32 <= b32 + 32'd1; wdat <= b32+32'd1; state <= STORE1; data_nack(); end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX,`DEC_XABS,`DEC_XABSX:	begin res32 <= b32 - 32'd1; wdat <= b32-32'd1; state <= STORE1; data_nack(); end
		endcase
	end

WORD_CALC:
	begin
		moveto_ifetch();
		store_what <= `STW_DEF70;
		s32 <= TRUE;
		case(ir9)
		`ADC_IMM,`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_XABS,`ADC_XABSX,`ADC_XABSY,
        `ADC_IYL,`ADC_XIYL,`ADC_I,`ADC_IL,`ADC_XIL,`ADC_AL,`ADC_ALX,`ADC_DSP,`ADC_DSPIY,`ADC_XDSPIY:
              begin res32 <= acc32 + b32 + {31'b0,cf}; end
        `SBC_IMM,`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_XABS,`SBC_XABSX,`SBC_XABSY,
        `SBC_IYL,`SBC_XIYL,`SBC_I,`SBC_IL,`SBC_XIL,`SBC_AL,`SBC_ALX,`SBC_DSP,`SBC_DSPIY,`SBC_XDSPIY:
              begin res32 <= acc32 - b32 - {31'b0,~cf}; end
        `CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_XABS,`CMP_XABSX,`CMP_XABSY,
        `CMP_IYL,`CMP_XIYL,`CMP_I,`CMP_IL,`CMP_XIL,`CMP_AL,`CMP_ALX,`CMP_DSP,`CMP_DSPIY,`CMP_XDSPIY:
              begin res32 <= acc32 - b32; end
        `AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_XABS,`AND_XABSX,`AND_XABSY,
        `AND_IYL,`AND_XIYL,`AND_I,`AND_IL,`AND_XIL,`AND_AL,`AND_ALX,`AND_DSP,`AND_DSPIY,`AND_XDSPIY:
              begin res32 <= acc & b32; end
        `ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_XABS,`ORA_XABSX,`ORA_XABSY,
        `ORA_IYL,`ORA_XIYL,`ORA_I,`ORA_IL,`ORA_XIL,`ORA_AL,`ORA_ALX,`ORA_DSP,`ORA_DSPIY,`ORA_XDSPIY:
              begin res32 <= acc | b32; end
        `EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_XABS,`EOR_XABSX,`EOR_XABSY,
        `EOR_IYL,`EOR_XIYL,`EOR_I,`EOR_IL,`EOR_XIL,`EOR_AL,`EOR_ALX,`EOR_DSP,`EOR_DSPIY,`EOR_XDSPIY:
              begin res32 <= acc ^ b32; end
        `LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_XABS,`LDA_XABSX,`LDA_XABSY,
        `LDA_IYL,`LDA_XIYL,`LDA_I,`LDA_IL,`LDA_XIL,`LDA_AL,`LDA_ALX,`LDA_DSP,`LDA_DSPIY,`LDA_XDSPIY:
              begin res32 <= b32; end
        `BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX,`BIT_XABS,`BIT_XABSX:    begin res32 <= acc & b32; end
        `TRB_ZP,`TRB_ABS,`TRB_XABS:    begin res32 <= ~acc32 & b32; wdat <= ~acc32 & b32; state <= STORE1; data_nack(); end
        `TSB_ZP,`TSB_ABS,`TSB_XABS:    begin res32 <= acc32 | b32; wdat <= acc32 | b32; state <= STORE1; data_nack(); end
        `LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY,`LDX_XABS,`LDX_XABSY:    begin res32 <= b32; end
        `LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX,`LDY_XABS,`LDY_XABSX:    begin res32 <= b32; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS,`CPX_XABS:	begin res32 <= x - b32; end
		`CPY_IMM,`CPY_ZP,`CPY_ABS,`CPY_XABS:	begin res32 <= y - b32; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX,`ASL_XABS,`ASL_XABSX:	begin res32 <= {b32,1'b0}; wdat <= {b32[30:0],1'b0}; state <= STORE1; data_nack(); end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX,`ROL_XABS,`ROL_XABSX:	begin res32 <= {b32,cf}; wdat <= {b32[30:0],cf}; state <= STORE1; data_nack(); end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX,`LSR_XABS,`LSR_XABSX:	begin res32 <= {b32[0],1'b0,b32[31:1]}; wdat <= {1'b0,b32[31:1]}; state <= STORE1; data_nack(); end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX,`ROR_XABS,`ROR_XABSX:	begin res32 <= {b32[0],cf,b32[31:1]}; wdat <= {cf,b32[31:1]}; state <= STORE1; data_nack(); end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX,`INC_XABS,`INC_XABSX:	begin res32 <= b32 + 32'd1; wdat <= b32+32'd1; state <= STORE1; data_nack(); end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX,`DEC_XABS,`DEC_XABSX:	begin res32 <= b32 - 32'd1; wdat <= b32-32'd1; state <= STORE1; data_nack(); end
		endcase
	end

MVN816:
	begin
		moveto_ifetch();
		if (m832) begin
            if (&acc) begin
                pc <= pc + 24'd3;
            end
		end
		else begin
            if (&acc[15:0]) begin
                pc <= pc + 24'd3;
                ds[23:16] <= ir[15:8];
            end
		end
	end
endcase
end

`include "bus_task.v"
`include "FT832misc_task.v"

task next_state;
input [5:0] nxt;
begin
	state <= nxt;
end
endtask

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET1:	fnStateName = "RESET1     ";
IFETCH1:	fnStateName = "IFETCH1    ";
IFETCH2:	fnStateName = "IFETCH2    ";
IFETCH3:	fnStateName = "IFETCH3    ";
IFETCH4:	fnStateName = "IFETCH4    ";
IFETCH5:	fnStateName = "IFETCH5    ";
IFETCH6:	fnStateName = "IFETCH6    ";
IFETCH7:	fnStateName = "IFETCH7    ";
IFETCH8:	fnStateName = "IFETCH8    ";
STORE1:	fnStateName = "STORE1     ";
STORE2:	fnStateName = "STORE2     ";
RTS1:	fnStateName = "RTS1       ";
IY3:	fnStateName = "IY3        ";
BYTE_IX5:	fnStateName = "BYTE_IX5   ";
BYTE_IY5:	fnStateName = "BYTE_IY5   ";
DECODE1:	fnStateName = "DECODE1    ";
DECODE2:	fnStateName = "DECODE2    ";
DECODE3:	fnStateName = "DECODE3    ";
DECODE4:	fnStateName = "DECODE4    ";
DECODE5:	fnStateName = "DECODE5    ";
DECODE8:	fnStateName = "DECODE8    ";
BYTE_CALC:	fnStateName = "BYTE_CALC  ";
BUS_ERROR:	fnStateName = "BUS_ERROR  ";
LOAD_MAC1:	fnStateName = "LOAD_MAC1  ";
LOAD_MAC2:	fnStateName = "LOAD_MAC2  ";
LOAD_MAC3:	fnStateName = "LOAD_MAC3  ";
MVN3:		fnStateName = "MVN3       ";
LOAD_DCACHE:	fnStateName = "LOAD_DCACHE";
LOAD_ICACHE:	fnStateName = "LOAD_ICACHE";
LOAD_IBUF1:		fnStateName = "LOAD_IBUF1 ";
LOAD_IBUF2:		fnStateName = "LOAD_IBUF2 ";
LOAD_IBUF3:		fnStateName = "LOAD_IBUF3 ";
ICACHE1:		fnStateName = "ICACHE1    ";
IBUF1:			fnStateName = "IBUF1      ";
DCACHE1:		fnStateName = "DCACHE1    ";
HALF_CALC:		fnStateName = "HALF_CALC  ";
WORD_CALC:		fnStateName = "WORD_CALC  ";
MVN816:			fnStateName = "MVN816     ";
default:		fnStateName = "UNKNOWN    ";
endcase
endfunction

endmodule


// ============================================================================
// Cache Memories
// ============================================================================
module ft832_icachemem(wclk, wce, wr, wa, i, rclk, rce, pc, insn);
input wclk;
input wce;
input wr;
input [11:0] wa;
input [7:0] i;
input rclk;
input rce;
input [11:0] pc;
output [127:0] insn;
reg [127:0] insn;

reg [127:0] mem [0:255];
reg [11:0] rpc,rpcp16;

genvar g;
generate
begin : wstrobes
for (g = 0; g < 16; g = g + 1)
always @(posedge wclk)
	if (wce & wr && wa[3:0]==g) mem[wa[11:4]][g*8+7:g*8] <= i;
end
endgenerate

always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp16 <= pc + 12'd16;
wire [127:0] insn0 = mem[rpc[11:4]];
wire [127:0] insn1 = mem[rpcp16[11:4]];
always @(insn0 or insn1 or rpc)
case(rpc[3:0])
4'h0:	insn <= insn0;
h'h1:	insn <= {insn1[7:0],insn0[127:8]};
4'h2:	insn <= {insn1[15:0],insn0[127:16]};
4'h3:	insn <= {insn1[23:0],insn0[127:24]};
4'h4:	insn <= {insn1[31:0],insn0[127:32]};
4'h5:	insn <= {insn1[39:0],insn0[127:40]};
4'h6:	insn <= {insn1[47:0],insn0[127:48]};
4'h7:	insn <= {insn1[55:0],insn0[127:56]};
4'h8:	insn <= {insn1[63:0],insn0[127:64]};
4'h9:	insn <= {insn1[71:0],insn0[127:72]};
4'hA:	insn <= {insn1[79:0],insn0[127:80]};
4'hB:	insn <= {insn1[87:0],insn0[127:88]};
4'hC:	insn <= {insn1[95:0],insn0[127:96]};
4'hD:	insn <= {insn1[103:0],insn0[127:104]};
4'hE:	insn <= {insn1[111:0],insn0[127:112]};
4'hF:	insn <= {insn1[119:0],insn0[127:120]};
endcase

endmodule

module ft832_itagmem(wclk, wce, wr, wa, invalidate, rclk, rce, pc, hit0, hit1);
input wclk;
input wce;
input wr;
input [31:0] wa;
input invalidate;
input rclk;
input rce;
input [31:0] pc;
output hit0;
output hit1;

reg [31:12] mem [0:255];
reg [0:255] tvalid;
reg [31:0] rpc,rpcp16;
wire [20:0] tag0,tag1;

always @(posedge wclk)
	if (wce & wr) mem[wa[11:4]] <= wa[31:12];
always @(posedge wclk)
	if (invalidate) tvalid <= 256'd0;
	else if (wce & wr) tvalid[wa[11:4]] <= 1'b1;
always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp16 <= pc + 32'd16;
assign tag0 = {mem[rpc[11:4]],tvalid[rpc[11:4]]};
assign tag1 = {mem[rpcp16[11:4]],tvalid[rpcp16[11:4]]};

assign hit0 = tag0 == {rpc[31:12],1'b1};
assign hit1 = tag1 == {rpcp16[31:12],1'b1};

endmodule
