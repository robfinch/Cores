`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT816.v
//  - 16 bit CPU
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

`define BRK			9'h00
`define RTI			9'h40
`define RTS			9'h60
`define PHP			9'h08
`define CLC			9'h18
`define PLP			9'h28
`define SEC			9'h38
`define PHA			9'h48
`define CLI			9'h58
`define PLA			9'h68
`define SEI			9'h78
`define DEY			9'h88
`define TYA			9'h98
`define TAY			9'hA8
`define CLV			9'hB8
`define INY			9'hC8
`define CLD			9'hD8
`define INX			9'hE8
`define SED			9'hF8
`define ROR_ACC		9'h6A
`define TXA			9'h8A
`define TXS			9'h9A
`define TAX			9'hAA
`define TSX			9'hBA
`define DEX			9'hCA
`define NOP			9'hEA
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

// CMP = SUB r0,....

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

`define ASL_ACC		9'h0A
`define ASL_ZP		9'h06
`define ASL_RR		9'h06
`define ASL_ZPX		9'h16
`define ASL_ABS		9'h0E
`define ASL_ABSX	9'h1E

`define ROL_ACC		9'h2A
`define ROL_ZP		9'h26
`define ROL_RR		9'h26
`define ROL_ZPX		9'h36
`define ROL_ABS		9'h2E
`define ROL_ABSX	9'h3E

`define LSR_ACC		9'h4A
`define LSR_ZP		9'h46
`define LSR_RR		9'h46
`define LSR_ZPX		9'h56
`define LSR_ABS		9'h4E
`define LSR_ABSX	9'h5E

`define ROR_RR		9'h66
`define ROR_ZP		9'h66
`define ROR_ZPX		9'h76
`define ROR_ABS		9'h6E
`define ROR_ABSX	9'h7E

`define DEC_RR		9'hC6
`define DEC_ZP		9'hC6
`define DEC_ZPX		9'hD6
`define DEC_ABS		9'hCE
`define DEC_ABSX	9'hDE
`define INC_RR		9'hE6
`define INC_ZP		9'hE6
`define INC_ZPX		9'hF6
`define INC_ABS		9'hEE
`define INC_ABSX	9'hFE

`define BIT_IMM		9'h89
`define BIT_ZP		9'h24
`define BIT_ZPX		9'h34
`define BIT_ABS		9'h2C
`define BIT_ABSX	9'h3C

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

`define JML			9'h5C
`define JMP			9'h4C
`define JMP_IND		9'h6C
`define JMP_INDX	9'h7C
`define JMP_RIND	9'hD2
`define JSR			9'h20
`define JSL			9'h22
`define JSR_IND		9'h2C
`define JSR_INDX	9'hFC
`define JSR_RIND	9'hC2
`define RTS			9'h60
`define RTL			9'h6B
`define BSR			9'h62
`define NOP			9'hEA

`define BRK			9'h00
`define PLX			9'hFA
`define PLY			9'h7A
`define PHX			9'hDA
`define PHY			9'h5A
`define WAI			9'hCB
`define PUSH		9'h0B
`define POP			9'h2B
`define PHB			9'h8B
`define PHD			9'h0B
`define PHK			9'h4B
`define XBA			9'hEB
`define COP			9'h02
`define PLB			9'hAB
`define PLD			9'h2B
`define PSHR4		9'h0F
`define POPR4		9'h2F

`define LDX_IMM		9'hA2
`define LDX_ZP		9'hA6
`define LDX_ZPX		9'hB6
`define LDX_ZPY		9'hB6
`define LDX_ABS		9'hAE
`define LDX_ABSY	9'hBE

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

`define STX_ZP		9'h86
`define STX_ZPX		9'h96
`define STX_ZPY		9'h96
`define STX_ABS		9'h8E

`define STY_ZP		9'h84
`define STY_ZPX		9'h94
`define STY_ABS		9'h8C

`define STZ_ZP		9'h64
`define STZ_ZPX		9'h74
`define STZ_ABS		9'h9C
`define STZ_ABSX	9'h9E

`define CPX_IMM		9'hE0
`define CPX_IMM32	9'hE0
`define CPX_IMM8	9'hE2
`define CPX_ZP		9'hE4
`define CPX_ZPX		9'hE4
`define CPX_ABS		9'hEC
`define CPY_IMM		9'hC0
`define CPY_IMM32	9'hC0
`define CPY_IMM8	9'hC1
`define CPY_ZP		9'hC4
`define CPY_ZPX		9'hC4
`define CPY_ABS		9'hCC

`define TRB_ZP		9'h14
`define TRB_ZPX		9'h14
`define TRB_ABS		9'h1C
`define TSB_ZP		9'h04
`define TSB_ZPX		9'h04
`define TSB_ABS		9'h0C

`define MVP			9'h44
`define MVN			9'h54
`define STS			9'h64

// Page Two Opcodes
`define PG2			9'h42

`define ICOFF		9'h108
`define ICON		9'h128
`define TOFF		9'h118
`define TON			9'h138
`define MUL_IMM8	9'h105
`define MUL_IMM16	9'h119
`define MUL_IMM32	9'h109
`define MULS_IMM8	9'h125
`define MULS_IMM16	9'h139
`define MULS_IMM32	9'h129
`define DIV_IMM8	9'h145
`define DIV_IMM16	9'h159
`define DIV_IMM32	9'h149
`define DIVS_IMM8	9'h165
`define DIVS_IMM16	9'h179
`define DIVS_IMM32	9'h169
`define MOD_IMM8	9'h185
`define MOD_IMM16	9'h199
`define MOD_IMM32	9'h189
`define MODS_IMM8	9'h1A5
`define MODS_IMM16	9'h1B9
`define MODS_IMM32	9'h1A9
`define PUSHA		9'h10B
`define POPA		9'h12B
`define BMS_ZPX		9'h106
`define BMS_ABS		9'h10E
`define BMS_ABSX	9'h11E
`define BMC_ZPX		9'h126
`define BMC_ABS		9'h12E
`define BMC_ABSX	9'h13E
`define BMF_ZPX		9'h146
`define BMF_ABS		9'h14E
`define BMF_ABSX	9'h15E
`define BMT_ZPX		9'h166
`define BMT_ABS		9'h16E
`define BMT_ABSX	9'h17E
`define HOFF		9'h158
`define CMPS		9'h144
`define SPL_ABS		9'h18E
`define SPL_ABSX	9'h19E

`define LEA_ZPX		9'h1D5
`define LEA_IX		9'h1C1
`define LEA_IY		9'h1D1
`define LEA_ABS		9'h1CD
`define LEA_ABSX	9'h1DD
`define LEA_RIND	9'h1D2
`define LEA_I		9'h1D2
`define LEA_DSP		9'h1C3

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

// Input Frequency is 32 times the 00 clock

module FT816(rst, clk, clko, cyc, phi11, phi12, phi81, phi82, nmi, irq, abort, e, mx, rdy, be, vpa, vda, mlb, vpb, rw, ad, db, err_i, rty_i);
parameter SUPPORT_TRIBYTES = 1'b0;
parameter STORE_SKIPPING = 1'b1;
parameter EXTRA_LONG_BRANCHES = 1'b1;
parameter RESET1 = 6'd0;
parameter IFETCH1 = 6'd1;
parameter IFETCH2 = 6'd2;
parameter IFETCH3 = 6'd3;
parameter IFETCH4 = 6'd4;
parameter DECODE1 = 6'd5;
parameter DECODE2 = 6'd6;
parameter DECODE3 = 6'd7;
parameter DECODE4 = 6'd8;
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
output tri [23:0] ad;
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
reg [31:0] ir;
wire [8:0] ir9 = {pg2,ir[7:0]};
reg [23:0] pc,opc;
reg [15:0] dpr;		// direct page register
reg [7:0] dbr;		// data bank register
reg [15:0] x,y,acc,sp;
reg [15:0] tmp;
wire [15:0] acc16 = acc;
wire [7:0] acc8=acc[7:0];
wire [7:0] x8=x[7:0];
wire [7:0] y8=y[7:0];
wire [15:0] x16 = x[15:0];
wire [15:0] y16 = y[15:0];
wire [15:0] acc_dec = acc - 16'd1;
wire [15:0] acc_inc = acc + 16'd1;
wire [15:0] x_dec = x - 16'd1;
wire [15:0] x_inc = x + 16'd1;
wire [15:0] y_dec = y - 16'd1;
wire [15:0] y_inc = y + 16'd1;
wire [15:0] sp_dec = sp - 16'd1;
wire [15:0] sp_inc = sp + 16'd1;
wire [15:0] sp_dec2 = sp - 16'd2;
reg gie;	// global interrupt enable (set when sp is loaded)
reg hwi;	// hardware interrupt indicator
reg im;
reg cf,vf,nf,zf,df,em,bf;
reg m816;
reg x_bit,m_bit;
wire m16 = m816 & ~m_bit;
wire xb16 = m816 & ~x_bit;
wire [7:0] sr8 = m816 ? {nf,vf,m_bit,x_bit,df,im,zf,cf} : {nf,vf,1'b0,bf,df,im,zf,cf};
reg nmi1,nmi_edge;
reg wai;
reg [7:0] b8;
reg [15:0] b16;
reg [7:0] b24;
reg [8:0] res8;
reg [16:0] res16;
wire resc8 = res8[8];
wire resc16 = res16[16];
wire resz8 = ~|res8[7:0];
wire resz16 = ~|res16[15:0];
wire resn8 = res8[7];
wire resn16 = res16[15];
reg [23:0] radr;
reg [23:0] wadr;
reg [23:0] wdat;
wire [7:0] rdat;
reg [4:0] load_what;
reg [5:0] store_what;
reg [15:0] tmp16;
reg first_ifetch;
reg [23:0] derr_address;

reg [8:0] intno;
reg isBusErr;
reg isBrk,isMove,isSts;
reg isMove816;
reg isRTI,isRTL,isRTS;
reg isRMW;
reg isSub;
reg isJsrIndx,isJsrInd;
reg isIY,isIY24,isI24;
reg isTribyte;

wire isCmp = ir9==`CPX_ZPX || ir9==`CPX_ABS ||
			 ir9==`CPY_ZPX || ir9==`CPY_ABS;
wire isRMW8 =
			 ir9==`ASL_ZP || ir9==`ROL_ZP || ir9==`LSR_ZP || ir9==`ROR_ZP || ir9==`INC_ZP || ir9==`DEC_ZP ||
			 ir9==`ASL_ZPX || ir9==`ROL_ZPX || ir9==`LSR_ZPX || ir9==`ROR_ZPX || ir9==`INC_ZPX || ir9==`DEC_ZPX ||
			 ir9==`ASL_ABS || ir9==`ROL_ABS || ir9==`LSR_ABS || ir9==`ROR_ABS || ir9==`INC_ABS || ir9==`DEC_ABS ||
			 ir9==`ASL_ABSX || ir9==`ROL_ABSX || ir9==`LSR_ABSX || ir9==`ROR_ABSX || ir9==`INC_ABSX || ir9==`DEC_ABSX ||
			 ir9==`TRB_ZP || ir9==`TRB_ZPX || ir9==`TRB_ABS || ir9==`TSB_ZP || ir9==`TSB_ZPX || ir9==`TSB_ABS;
wire isBranch = ir9==`BRA || ir9==`BEQ || ir9==`BNE || ir9==`BVS || ir9==`BVC || ir9==`BMI || ir9==`BPL || ir9==`BCS || ir9==`BCC;

// Registerable decodes
// The following decodes can be registered because they aren't needed until at least the cycle after
// the DECODE stage.

always @(posedge clk)
	if (state==RESET1)
		isBrk <= `TRUE;
	else if (state==DECODE1||state==DECODE2||state==DECODE3||state==DECODE4) begin
		isRMW <= isRMW8;
		isRTI <= ir9==`RTI;
		isRTL <= ir9==`RTL;
		isRTS <= ir9==`RTS;
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
default:	takb <= 1'b0;
endcase

reg [23:0] ia;
wire [23:0] mvnsrc_address	= {ir[23:16],x16};
wire [23:0] mvndst_address	= {ir[15: 8],y16};
wire [23:0] iapy8 			= ia + y16;		// Don't add in abs8, already included with ia
wire [23:0] zp_address 		= {8'h00,ir[15:8]} + dpr;
wire [23:0] zpx_address 	= {{16'h00,ir[15:8]} + x16} + dpr;
wire [23:0] zpy_address	 	= {{16'h00,ir[15:8]} + y16} + dpr;
wire [23:0] abs_address 	= {dbr,ir[23:8]};
wire [23:0] absx_address 	= {dbr,ir[23:8] + x16};	// simulates 64k bank wrap-around
wire [23:0] absy_address 	= {dbr,ir[23:8] + y16};
wire [23:0] al_address		= {ir[31:8]};
wire [23:0] alx_address		= {ir[31:8] + x16};

wire [23:0] dsp_address = m816 ? {8'h00,sp + ir[15:8]} : {16'h0001,sp[7:0]+ir[15:8]};
reg [23:0] vect;

assign rw = be ? rwo : 1'bz;
assign ad = be ? ado : {24{1'bz}};
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

// Detect a single byte opcode
function isOneByte;
input [7:0] ir;
casex(ir)
8'hx8:	isOneByte = TRUE;
8'hxA:	isOneByte = TRUE;
8'hxB: isOneByte = TRUE;
`RTI,`RTS:	isOneByte = TRUE;
default:	isOneByte = FALSE;
endcase
endfunction

// Detect double byte opcode
function isTwoBytes;
input [7:0] ir;
input m16;
input xb16;
casex(ir)
`BRK,`COP:	isTwoBytes = TRUE;
8'hx1:	isTwoBytes = TRUE;
8'hx3:	isTwoBytes = TRUE;
8'hx5:	isTwoBytes = TRUE;
8'hx6:	isTwoBytes = TRUE;
8'hx7:	isTwoBytes = TRUE;
`BPL,`BMI,`BVS,`BVC,`BCS,`BCC,`BEQ,`BNE,`BRA:	isTwoBytes = TRUE;
`LDY_IMM,`CPY_IMM,`CPX_IMM,`LDX_IMM:			isTwoBytes = !xb16;
`ORA_I,`AND_I,`EOR_I,`LDA_I,`CMP_I,`STA_I,`ADC_I,`SBC_I,`PEI:
			isTwoBytes = TRUE;
`REP,`SEP:	isTwoBytes = TRUE;
`TSB_ZPX,`TRB_ZPX,`BIT_ZP,`BIT_ZPX,`STZ_ZP,`STZ_ZPX,`STY_ZP,`STY_ZPX,
`LDY_ZP,`LDY_ZPX,`CPY_ZP,`CPX_ZP:
			isTwoBytes = TRUE;
`ORA_IMM,`AND_IMM,`EOR_IMM,`ADC_IMM,`SBC_IMM,`CMP_IMM,`LDA_IMM,`BIT_IMM:
			isTwoBytes = !m16;
default:	isTwoBytes = FALSE;
endcase
endfunction

function isThreeBytes;
input [7:0] ir;
input m16;
input xb16;
casex(ir)
`JSR:	isThreeBytes = TRUE;
`PER,`BRL:	isThreeBytes = TRUE;
`MVP,`MVN,`PEA:	isThreeBytes = TRUE;
`LDY_IMM,`CPY_IMM,`CPX_IMM,`LDX_IMM:			isThreeBytes = xb16;
`ORA_IMM,`AND_IMM,`EOR_IMM,`ADC_IMM,`SBC_IMM,`CMP_IMM,`LDA_IMM,`BIT_IMM:
			isThreeBytes = m16;
8'bxxx11001:	isThreeBytes = TRUE;
`TSB_ABS,`TRB_ABS,`BIT_ABS,`BIT_ABSX,
`JMP,`JMP_IND,`JMP_INDX,`STY_ABS,`STZ_ABS,`LDY_ABS,`LDY_ABSX,`CPY_ABS,
`CPX_ABS,`JSR_INDX:	isThreeBytes = TRUE;
8'hxD,8'hxE:	isThreeBytes = TRUE;
default:	isThreeBytes = FALSE;
endcase
endfunction

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
	ado <= 24'h000000;
	dbo <= 8'h00;
	nmi_edge <= 1'b0;
	wai <= 1'b0;
	pg2 <= 1'b0;
	ir <= 8'hEA;
	cf <= 1'b0;
	df <= 1'b0;
	m816 <= 1'b0;
	m_bit <= 1'b1;
	x_bit <= 1'b1;
	pc <= 24'h00FFF0;		// set high-order pc to zero
	vect <= `BYTE_RST_VECT;
	state <= RESET1;
	em <= 1'b1;
	dbr <= 8'h00;
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
		state <= LOAD_MAC1;
	end
IFETCH0:
	moveto_ifetch();
IFETCH1:
	if (rdy) begin
		if (imcd != 3'b111)
			imcd <= {imcd[1:0],1'b0};
		if (imcd == 3'b000) begin
			imcd <= 3'b111;
			im <= 1'b0;
		end
		vect <= m816 ? `BRK_VECT_816 : `BYTE_IRQ_VECT;
		hwi <= `FALSE;
		isBusErr <= `FALSE;
		pg2 <= `FALSE;
		isIY <= `FALSE;
		isIY24 <= `FALSE;
		isTribyte <= `FALSE;
		store_what <= m16 ? `STW_DEF70 : `STW_DEF;
		ir[7:0] <= db;
		opc <= pc;
		if (nmi_edge | ~irq)
			wai <= 1'b0;
		if (abort_edge) begin
			pc <= opc;
			ir[7:0] <= `BRK;
			abort_edge <= 1'b0;
			hwi <= `TRUE;
			vect <= m816 ? `ABT_VECT_816 : `BYTE_ABT_VECT;
			vect[23:16] <= 8'h00;
			next_state(DECODE2);
		end
		else if (nmi_edge & gie) begin
			ir[7:0] <= `BRK;
			nmi_edge <= 1'b0;
			hwi <= `TRUE;
			vect <= m816 ? `NMI_VECT_816 : `BYTE_NMI_VECT;
			vect[23:16] <= 8'h00;
			next_state(DECODE2);
		end
		else if (~irq & gie & ~im) begin
			ir[7:0] <= `BRK;
			hwi <= `TRUE;
			if (m816)
				vect <= `IRQ_VECT_816;
			next_state(DECODE2);
		end
		else if (!wai) begin
			ado <= pc + 24'd1;
			pc <= pc + 24'd1;
			// Is it more than one byte ?
			if (!isOneByte(db)) begin
				vpa <= TRUE;
				next_state(IFETCH2);
			end
			else begin
				vpa <= FALSE;
				next_state(DECODE1);
			end
			vda <= FALSE;
		end
		else
			next_state(IFETCH1);
		if (!abort_edge) begin
		case(ir[7:0])
		// Note the break flag is not affected by SEP/REP
		// Setting the index registers to eight bit zeros out the upper part of the register.
		`SEP:
			begin
				cf <= cf | ir[8];
				zf <= zf | ir[9];
				im <= im | ir[10];
				df <= df | ir[11];
				if (m816) begin
					x_bit <= x_bit | ir[12];
					m_bit <= m_bit | ir[13];
					//if (ir[13]) acc[31:8] <= 24'd0;
					if (ir[12]) begin
						x[15:8] <= 8'd0;
						y[15:8] <= 8'd0;
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
				if (m816) begin
					x_bit <= x_bit & ~ir[12];
					m_bit <= m_bit & ~ir[13];
				end
				vf <= vf & ~ir[14];
				nf <= nf & ~ir[15];
			end
		`XBA:
			begin
				acc[15:0] <= res16[15:0];
				nf <= resn8;
				zf <= resz8;
			end
		`TAY,`TXY,`DEY,`INY:		if (xb16) begin y[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end	else begin y[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`TAX,`TYX,`TSX,`DEX,`INX:	if (xb16) begin x[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end else begin x[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`TSA,`TYA,`TXA,`INA,`DEA:	if (m16) begin acc[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end else begin acc[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`TAS,`TXS: begin if (m816) sp <= res16[15:0]; else sp <= {8'h01,res8[7:0]}; gie <= `TRUE; end
		`TCD:	begin dpr <= res16[15:0]; end
		`TDC:	begin acc[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end
		`ADC_IMM:
			begin
				if (m16) begin
					acc[15:0] <= df ? bcaio : res16[15:0];
					cf <= df ? bcaico : resc16;
//						vf <= resv8;
					vf <= (res16[15] ^ b16[15]) & (1'b1 ^ acc[15] ^ b16[15]);
					nf <= df ? bcaio[15] : resn16;
					zf <= df ? bcaio==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcaio[7:0] : res8[7:0];
					cf <= df ? bcaico8 : resc8;
//						vf <= resv8;
					vf <= (res8[7] ^ b8[7]) & (1'b1 ^ acc[7] ^ b8[7]);
					nf <= df ? bcaio[7] : resn8;
					zf <= df ? bcaio[7:0]==8'h00 : resz8;
				end
			end
		`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_IYL,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_I,`ADC_IL,`ADC_AL,`ADC_ALX,`ADC_DSP,`ADC_DSPIY:
			begin
				if (m16) begin
					acc[15:0] <= df ? bcao : res16[15:0];
					cf <= df ? bcaco : resc16;
					vf <= (res16[15] ^ b16[15]) & (1'b1 ^ acc[15] ^ b16[15]);
					nf <= df ? bcao[15] : resn16;
					zf <= df ? bcao==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcao[7:0] : res8[7:0];
					cf <= df ? bcaco8 : resc8;
					vf <= (res8[7] ^ b8[7]) & (1'b1 ^ acc[7] ^ b8[7]);
					nf <= df ? bcao[7] : resn8;
					zf <= df ? bcao[7:0]==8'h00 : resz8;
				end
			end
		`SBC_IMM:
			begin
				if (m16) begin
					acc[15:0] <= df ? bcsio : res16[15:0];
					cf <= ~(df ? bcsico : resc16);
					vf <= (1'b1 ^ res16[15] ^ b16[15]) & (acc[15] ^ b16[15]);
					nf <= df ? bcsio[15] : resn16;
					zf <= df ? bcsio==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcsio[7:0] : res8[7:0];
					cf <= ~(df ? bcsico8 : resc8);
					vf <= (1'b1 ^ res8[7] ^ b8[7]) & (acc[7] ^ b8[7]);
					nf <= df ? bcsio[7] : resn8;
					zf <= df ? bcsio[7:0]==8'h00 : resz8;
				end
			end
		`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_IYL,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_I,`SBC_IL,`SBC_AL,`SBC_ALX,`SBC_DSP,`SBC_DSPIY:
			begin
				if (m16) begin
					acc[15:0] <= df ? bcso : res16[15:0];
					vf <= (1'b1 ^ res16[15] ^ b16[15]) & (acc[15] ^ b16[15]);
					cf <= ~(df ? bcsco : resc16);
					nf <= df ? bcso[15] : resn16;
					zf <= df ? bcso==16'h0000 : resz16;
				end
				else begin
					acc[7:0] <= df ? bcso[7:0] : res8[7:0];
					vf <= (1'b1 ^ res8[7] ^ b8[7]) & (acc[7] ^ b8[7]);
					cf <= ~(df ? bcsco8 : resc8);
					nf <= df ? bcso[7] : resn8;
					zf <= df ? bcso[7:0]==8'h00 : resz8;
				end
			end
		`CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_IYL,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_I,`CMP_IL,`CMP_AL,`CMP_ALX,`CMP_DSP,`CMP_DSPIY:
				if (m16) begin cf <= ~resc16; nf <= resn16; zf <= resz16; end else begin cf <= ~resc8; nf <= resn8; zf <= resz8; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS,
		`CPY_IMM,`CPY_ZP,`CPY_ABS:
				if (xb16) begin cf <= ~resc16; nf <= resn16; zf <= resz16; end else begin cf <= ~resc8; nf <= resn8; zf <= resz8; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX:
				if (m16) begin nf <= b16[15]; vf <= b16[14]; zf <= resz16; end else begin nf <= b8[7]; vf <= b8[6]; zf <= resz8; end
		`TRB_ZP,`TRB_ABS,`TSB_ZP,`TSB_ABS:
			if (m16) begin zf <= resz16; end else begin zf <= resz8; end
		`LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_IYL,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_I,`LDA_IL,`LDA_AL,`LDA_ALX,`LDA_DSP,`LDA_DSPIY,
		`AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_IYL,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_I,`AND_IL,`AND_AL,`AND_ALX,`AND_DSP,`AND_DSPIY,
		`ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_IYL,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_I,`ORA_IL,`ORA_AL,`ORA_ALX,`ORA_DSP,`ORA_DSPIY,
		`EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_IYL,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_I,`EOR_IL,`EOR_AL,`EOR_ALX,`EOR_DSP,`EOR_DSPIY:
			if (m16) begin acc[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end
			else begin acc[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`ASL_ACC:	if (m16) begin acc[15:0] <= res16[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end else begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROL_ACC:	if (m16) begin acc[15:0] <= res16[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end else begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`LSR_ACC:	if (m16) begin acc[15:0] <= res16[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end else begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROR_ACC:	if (m16) begin acc[15:0] <= res16[15:0]; cf <= resc16; nf <= resn16; zf <= resz16; end else begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX: if (m16) begin cf <= resc16; nf <= resn16; zf <= resz16; end else begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX: if (m16) begin cf <= resc16; nf <= resn16; zf <= resz16; end else begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX: if (m16) begin cf <= resc16; nf <= resn16; zf <= resz16; end else begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX: if (m16) begin cf <= resc16; nf <= resn16; zf <= resz16; end else begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX: if (m16) begin nf <= resn16; zf <= resz16; end else begin nf <= resn8; zf <= resz8; end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX: if (m16) begin nf <= resn16; zf <= resz16; end else begin nf <= resn8; zf <= resz8; end
		`PLA:	if (m16) begin acc[15:0] <= res16[15:0]; zf <= resz16; nf <= resn16; end else begin acc[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLX:	if (xb16) begin x[15:0] <= res16[15:0]; zf <= resz16; nf <= resn16; end else begin x[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLY:	if (xb16) begin y[15:0] <= res16[15:0]; zf <= resz16; nf <= resn16; end else begin y[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLB:	begin dbr <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`PLD:	begin dpr <= res16[15:0]; nf <= resn16; zf <= resz16; end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY:	if (xb16) begin x[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end else begin x[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX:	if (xb16) begin y[15:0] <= res16[15:0]; nf <= resn16; zf <= resz16; end else begin y[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		endcase
		end	// abort_edge
	end
IFETCH2:
	if (rdy) begin
		ir[15:8] <= db;
		ado <= pc + 24'd1;
		pc <= pc + 24'd1;
		if ((isBranch && db==8'hFF && EXTRA_LONG_BRANCHES) ||
		   (!isTwoBytes(ir,m16,xb16))) begin
			vpa <= TRUE;
			next_state(IFETCH3);
		end
		else begin
			vpa <= FALSE;
			next_state(DECODE2);
		end
		vda <= FALSE;
	end
IFETCH3:
	if (rdy) begin
		ir[23:16] <= db;
		ado <= pc + 24'd1;
		pc <= pc + 24'd1;
		if (!isThreeBytes(ir,m16,xb16)) begin
			vpa <= TRUE;
			next_state(IFETCH4);
		end
		else begin
			vpa <= FALSE;
			next_state(DECODE3);
		end
		vda <= FALSE;
	end
IFETCH4:
	if (rdy) begin
		ir[31:24] <= db;
		ado <= pc + 24'd1;
		pc <= pc + 24'd1;
		next_state(DECODE4);
		vpa <= FALSE;
		vda <= FALSE;
	end

// Decode single byte opcodes
DECODE1:
	if (rdy) begin
		next_state(IFETCH1);
		opcode_read();
		case(ir[7:0])
		`SEP:	;	// see byte_ifetch
		`REP:	;
		// XBA cannot be done in the ifetch stage because it'd repeat when there
		// was a cache miss, causing the instruction to be done twice.
		`XBA:	
			begin
				res16 <= {acc[7:0],acc[15:8]};
				res8 <= acc[15:8];	// for flag settings
			end
		`STP:	begin clk_en <= 1'b0; end
		// Switching the processor mode always zeros out the upper part of the index registers.
		// switching to emulation mode sets 8 bit memory/indexes
		`XCE:	begin
					m816 <= ~cf;
					cf <= ~m816;
					if (cf) begin		
						m_bit <= 1'b1;
						x_bit <= 1'b1;
						sp[15:8] <= 8'h01;
					end
					x[15:8] <= 8'd0;
					y[15:8] <= 8'd0;
				end
//		`NOP:	;	// may help routing
		`CLC:	begin cf <= 1'b0; end
		`SEC:	begin cf <= 1'b1; end
		`CLV:	begin vf <= 1'b0; end
		`CLI:	begin imcd <= 3'b110; end
		`SEI:	begin im <= 1'b1; end
		`CLD:	begin df <= 1'b0; end
		`SED:	begin df <= 1'b1; end
		`WAI:	begin wai <= 1'b1; end
		`DEX:	begin res8 <= x_dec[7:0]; res16 <= x_dec[15:0]; end
		`INX:	begin res8 <= x_inc[7:0]; res16 <= x_inc[15:0]; end
		`DEY:	begin res8 <= y_dec[7:0]; res16 <= y_dec[15:0]; end
		`INY:	begin res8 <= y_inc[7:0]; res16 <= y_inc[15:0]; end
		`DEA:	begin res8 <= acc_dec[7:0]; res16 <= acc_dec[15:0]; end
		`INA:	begin res8 <= acc_inc[7:0]; res16 <= acc_inc[15:0]; end
		`TSX,`TSA:	begin res8 <= sp[7:0]; res16 <= sp[15:0]; end
		`TXS,`TXA,`TXY:	begin res8 <= x[7:0]; res16 <= xb16 ? x[15:0] : {8'h00,x8}; end
		`TAX,`TAY:	begin res8 <= acc[7:0]; res16 <= m16 ? acc[15:0] : {8'h00,acc8}; end
		`TAS:	begin res8 <= acc[7:0]; res16 <= acc[15:0]; end
		`TYA,`TYX:	begin res8 <= y[7:0]; res16 <= xb16 ? y[15:0] : {8'h00,y8}; end
		`TDC:		begin res16 <= dpr; end
		`TCD:		begin res16 <= acc[15:0]; end
		`ASL_ACC:	begin res8 <= {acc8,1'b0}; res16 <= {acc16,1'b0}; end
		`ROL_ACC:	begin res8 <= {acc8,cf}; res16 <= {acc16,cf}; end
		`LSR_ACC:	begin res8 <= {acc8[0],1'b0,acc8[7:1]}; res16 <= {acc16[0],1'b0,acc16[15:1]}; end
		`ROR_ACC:	begin res8 <= {acc8[0],cf,acc8[7:1]}; res16 <= {acc16[0],cf,acc16[15:1]}; end
		`RTS,`RTL:
			begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				data_nack();
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end
		`RTI:	begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				data_nack();
				load_what <= `SR_70;
				state <= LOAD_MAC1;
				end
		`PHP:
			begin
begin
	if (m816) begin
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
end				data_nack();
				store_what <= `STW_SR70;
				state <= STORE1;
			end
		`PHA:
begin
	if (m816) begin
		if (m16) begin
			radr <= {8'h00,sp_dec[15:0]};
			wadr <= {8'h00,sp_dec[15:0]};
			store_what <= `STW_ACC70;
			sp <= sp_dec2;
		end
		else begin
			radr <= {8'h00,sp[15:0]};
			wadr <= {8'h00,sp[15:0]};
			store_what <= `STW_ACC8;
			sp <= sp_dec;
		end
	end
	else begin
		radr <= {16'h01,sp[7:0]};
		wadr <= {16'h01,sp[7:0]};
		store_what <= `STW_ACC8;
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[15:8] <= 8'h1;
	end
	state <= STORE1;
end
//		tsk_push(`STW_ACC8,`STW_ACC70,m16);
		`PHX:	tsk_push(`STW_X8,`STW_X70,xb16);
		`PHY:	tsk_push(`STW_Y8,`STW_Y70,xb16);
		`PLP:
			begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				load_what <= `SR_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PLA:
			begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				load_what <= m16 ? `HALF_71S : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PLX,`PLY:
			begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				load_what <= xb16 ? `HALF_71S : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PHB:
			begin
begin
	if (m816) begin
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
end				store_what <= `STW_DBR;
				data_nack();
				state <= STORE1;
			end
		`PHD:
			begin
begin
	if (m816) begin
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
end				store_what <= `STW_DPR158;
				data_nack();
				state <= STORE1;
			end
		`PHK:
			begin
begin
	if (m816) begin
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
end				store_what <= `STW_PC2316;
				data_nack();
				state <= STORE1;
			end
		`PLB:
			begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				load_what <= `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`PLD:
			begin
begin
	if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end				load_what <= `HALF_71S;
				data_nack();
				state <= LOAD_MAC1;
			end
		default:
			begin
				opcode_read();
				next_state(IFETCH1);
			end
		endcase
	end

// Decode 2-byte opcodes
DECODE2:
	if (rdy) begin
		case(ir[7:0])
		// Handle # mode
		`LDA_IMM:
			begin
				res8 <= ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`LDX_IMM,`LDY_IMM:
			begin
				res8 <= ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`ADC_IMM:
			begin
				res8 <= acc8 + ir[15:8] + {7'b0,cf};
				b8 <= ir[15:8];		// for overflow calc
				opcode_read();
				next_state(IFETCH1);
			end
		`SBC_IMM:
			begin
				res8 <= acc8 - ir[15:8] - {7'b0,~cf};
				$display("sbc: %h= %h-%h-%h", acc8 - ir[15:8] - {7'b0,~cf},acc8,ir[15:8],~cf);
				b8 <= ir[15:8];		// for overflow calc
				opcode_read();
				next_state(IFETCH1);
			end
		`AND_IMM,`BIT_IMM:
			begin
				res8 <= acc8 & ir[15:8];
				b8 <= ir[15:8];	// for bit flags
				opcode_read();
				next_state(IFETCH1);
			end
		`ORA_IMM:
			begin
				res8 <= acc8 | ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`EOR_IMM:
			begin
				res8 <= acc8 ^ ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`CMP_IMM:
			begin
				res8 <= acc8 - ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`CPX_IMM:
			begin
				res8 <= x8 - ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`CPY_IMM:
			begin
				res8 <= y8 - ir[15:8];
				opcode_read();
				next_state(IFETCH1);
			end
		// Handle zp mode
		`LDA_ZP:
			begin
				data_nack();
				radr <= zp_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDX_ZP,`LDY_ZP:
			begin
				radr <= zp_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_ZP,`SBC_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`CMP_ZP,
		`BIT_ZP,
		`ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`TRB_ZP,`TSB_ZP:
			begin
				radr <= zp_address;
				wadr <= zp_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`INC_ZP,`DEC_ZP:
			begin
				radr <= zp_address;
				wadr <= zp_address;
				isTribyte <= zp_address[23:4]==16'h2 && SUPPORT_TRIBYTES;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`CPX_ZP,`CPY_ZP:
			begin
				radr <= zp_address;
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_ZP:
			begin
				wadr <= zp_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		`STX_ZP:
			begin
				wadr <= zp_address;
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				data_nack();
				state <= STORE1;
			end
		`STY_ZP:
			begin
				wadr <= zp_address;
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				data_nack();
				state <= STORE1;
			end
		`STZ_ZP:
			begin
				wadr <= zp_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				data_nack();
				state <= STORE1;
			end
		// Handle zp,x mode
		`LDA_ZPX:
			begin
				radr <= zpx_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`LDY_ZPX:
			begin
				radr <= zpx_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_ZPX,`SBC_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`CMP_ZPX,
		`BIT_ZPX,
		`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX:
			begin
				radr <= zpx_address;
				wadr <= zpx_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_ZPX:
			begin
				wadr <= zpx_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		`STY_ZPX:
			begin
				wadr <= zpx_address;
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				data_nack();
				state <= STORE1;
			end
		`STZ_ZPX:
			begin
				wadr <= zpx_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				data_nack();
				state <= STORE1;
			end
		// Handle zp,y
		`LDX_ZPY:
			begin
				radr <= zpy_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STX_ZPY:
			begin
				wadr <= zpy_address;
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				data_nack();
				state <= STORE1;
			end
		// Handle (zp,x)
		`ADC_IX,`SBC_IX,`AND_IX,`ORA_IX,`EOR_IX,`CMP_IX,`LDA_IX,`STA_IX:
			begin
				radr <= zpx_address;
				load_what <= `IA_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		// Handle (zp),y
		`ADC_IY,`SBC_IY,`AND_IY,`ORA_IY,`EOR_IY,`CMP_IY,`LDA_IY,`STA_IY:
			begin
				radr <= zp_address;
				isIY <= `TRUE;
				load_what <= `IA_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		// Handle d,sp
		`LDA_DSP:
			begin
				radr <= dsp_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_DSP,`SBC_DSP,`CMP_DSP,`ORA_DSP,`AND_DSP,`EOR_DSP:
			begin
				radr <= dsp_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_DSP:
			begin
				wadr <= dsp_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		// Handle (d,sp),y
		`ADC_DSPIY,`SBC_DSPIY,`CMP_DSPIY,`ORA_DSPIY,`AND_DSPIY,`EOR_DSPIY,`LDA_DSPIY,`STA_DSPIY:
			begin
				radr <= dsp_address;
				isIY <= `TRUE;
				load_what <= `IA_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		// Handle [zp],y
		`ADC_IYL,`SBC_IYL,`AND_IYL,`ORA_IYL,`EOR_IYL,`CMP_IYL,`LDA_IYL,`STA_IYL:
			begin
				radr <= zp_address;
				isIY24 <= `TRUE;
				load_what <= `IA_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		// Handle [zp]
		`ADC_IL,`SBC_IL,`AND_IL,`ORA_IL,`EOR_IL,`CMP_IL,`LDA_IL,`STA_IL:
			begin
				isI24 <= `TRUE;
				radr <= zp_address;
				load_what <= `IA_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		// Handle (zp)
		`ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,`PEI:
			begin
				radr <= zp_address;
				load_what <= `IA_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`BRK:
			begin
begin
	if (m816) begin
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
end				store_what <= m816 ? `STW_PC2316 : `STW_PC158;// `STW_PC3124;
				data_nack();
				state <= STORE1;
				bf <= !hwi;
			end
		`COP:
			begin
begin
	if (m816) begin
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
end				store_what <= m816 ? `STW_PC2316 : `STW_PC158;// `STW_PC3124;
				state <= STORE1;
				vect <= m816 ? `COP_VECT_816 : `BYTE_COP_VECT;
				data_nack();
			end
		`BEQ,`BNE,`BPL,`BMI,`BCC,`BCS,`BVC,`BVS,`BRA:
				begin
					vpa <= `TRUE;
					vda <= `TRUE;
					if (takb) begin
						pc <= pc + {{16{ir[15]}},ir[15:8]};
						ado <= pc + {{16{ir[15]}},ir[15:8]};
					end
					next_state(IFETCH1);
				end
			//end
		default:
			begin
				opcode_read();
				next_state(IFETCH1);
			end
		endcase
	end

DECODE3:
	if (rdy) begin
		case(ir[7:0])
		// Handle # mode
		`LDA_IMM:
			begin
				res16 <= ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`LDX_IMM,`LDY_IMM:
			begin
				res16 <= ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`ADC_IMM:
			begin
				res16 <= acc16 + ir[23:8] + {15'b0,cf};
				b16 <= ir[23:8];		// for overflow calc
				opcode_read();
				next_state(IFETCH1);
			end
		`SBC_IMM:
			begin
				res16 <= acc16 - ir[23:8] - {15'b0,~cf};
				b16 <= ir[23:8];		// for overflow calc
				opcode_read();
				next_state(IFETCH1);
			end
		`AND_IMM,`BIT_IMM:
			begin
				res16 <= acc16 & ir[23:8];
				b16 <= ir[23:8];	// for bit flags
				opcode_read();
				next_state(IFETCH1);
			end
		`ORA_IMM:
			begin
				res16 <= acc16 | ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`EOR_IMM:
			begin
				res16 <= acc16 ^ ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`CMP_IMM:
			begin
				res16 <= acc16 - ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`CPX_IMM:
			begin
				res16 <= x16 - ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		`CPY_IMM:
			begin
				res16 <= y16 - ir[23:8];
				opcode_read();
				next_state(IFETCH1);
			end
		// Handle abs
		`LDA_ABS:
			begin
				radr <= abs_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`LDX_ABS,`LDY_ABS:
			begin
				radr <= abs_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_ABS,`SBC_ABS,`AND_ABS,`ORA_ABS,`EOR_ABS,`CMP_ABS,
		`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS,`TRB_ABS,`TSB_ABS,
		`BIT_ABS:
			begin
				radr <= abs_address;
				wadr <= abs_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`CPX_ABS,`CPY_ABS:
			begin
				radr <= abs_address;
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_ABS:
			begin
				wadr <= abs_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		`STX_ABS:
			begin
				wadr <= abs_address;
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				data_nack();
				state <= STORE1;
			end	
		`STY_ABS:
			begin
				wadr <= abs_address;
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				data_nack();
				state <= STORE1;
			end
		`STZ_ABS:
			begin
				wadr <= abs_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				data_nack();
				state <= STORE1;
			end
		// Handle abs,x
		`LDA_ABSX:
			begin
				radr <= absx_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_ABSX,`SBC_ABSX,`AND_ABSX,`ORA_ABSX,`EOR_ABSX,`CMP_ABSX,
		`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX,`BIT_ABSX:
			begin
				radr <= absx_address;
				wadr <= absx_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`LDY_ABSX:
			begin
				radr <= absx_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_ABSX:
			begin
				wadr <= absx_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		`STZ_ABSX:
			begin
				wadr <= absx_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				data_nack();
				state <= STORE1;
			end
		// Handle abs,y
		`LDA_ABSY:
			begin
				radr <= absy_address;
				load_what <= m16 ? `HALF_71	: `BYTE_71;
				state <= LOAD_MAC1;
				data_nack();
			end
		`ADC_ABSY,`SBC_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`CMP_ABSY:
			begin
				radr <= absy_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`LDX_ABSY:
			begin
				radr <= absy_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_ABSY:
			begin
				wadr <= absy_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		`JMP:
			begin
				vpa <= `TRUE;
				vda <= `TRUE;
				pc[15:0] <= ir[23:8];
				ado[15:0] <= ir[23:8];
				next_state(IFETCH1);
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
begin
	if (m816) begin
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
end				pc <= pc - 24'd1;
				store_what <= `STW_PC158;
				data_nack();
				state <= STORE1;
			end
		`BRL:
			begin
				vpa <= `TRUE;
				vda <= `TRUE;
				pc <= pc + {{8{ir[23]}},ir[23:8]};
				ado <= pc + {{8{ir[23]}},ir[23:8]};
				next_state(IFETCH1);
			end
		`PEA:
			begin
				tmp16 <= ir[23:8];
begin
	if (m816) begin
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
end				store_what <= `STW_TMP158;
				data_nack();
				state <= STORE1;
			end
		`PER:
			begin
				tmp16 <= pc[15:0] + ir[23:8] + 16'd3;
begin
	if (m816) begin
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
end				store_what <= `STW_TMP158;
				data_nack();
				state <= STORE1;
			end
		`MVN,`MVP:
			begin
				radr <= mvnsrc_address;
				load_what <= `BYTE_72;
				pc <= pc - 24'd3;	// override increment above
				data_nack();
				state <= LOAD_MAC1;
			end
		default:
			begin
				opcode_read();
				next_state(IFETCH1);
			end
		endcase
	end

DECODE4:
	if (rdy) begin
		first_ifetch <= `TRUE;
		next_state(IFETCH1);
		case(ir[7:0])
		`WDM:	if (ir[15:8]==`XCE) begin
					em <= 1'b0;
					next_state(IFETCH1);
					pc <= pc + 32'd2;
				end
		// Handle al
		`LDA_AL:
			begin
				radr <= al_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_AL,`SBC_AL,`AND_AL,`ORA_AL,`EOR_AL,`CMP_AL:
			begin
				radr <= al_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_AL:
			begin
				wadr <= al_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		// Handle alx
		`LDA_ALX:
			begin
				radr <= alx_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				data_nack();
				state <= LOAD_MAC1;
			end
		`ADC_ALX,`SBC_ALX,`AND_ALX,`ORA_ALX,`EOR_ALX,`CMP_ALX:
			begin
				radr <= alx_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				data_nack();
				state <= LOAD_MAC1;
			end
		`STA_ALX:
			begin
				wadr <= alx_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				data_nack();
				state <= STORE1;
			end
		`JML:
			begin
				vpa <= `TRUE;
				vda <= `TRUE;
				pc[23:0] <= ir[31:8];
				ado[23:0] <= ir[31:8];
				next_state(IFETCH1);
			end
		`JSL:
			begin
begin
	if (m816) begin
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
end				pc <= pc - 24'd1;
				store_what <= `STW_PC2316;
				data_nack();
				state <= STORE1;
			end
		`BEQ,`BNE,`BPL,`BMI,`BCC,`BCS,`BVC,`BVS,`BRA:
			begin
				vpa <= `TRUE;
				vda <= `TRUE;
				if (takb) begin
					pc <= pc + {{8{ir[31]}},ir[31:16]};
					ado <= pc + {{8{ir[31]}},ir[31:16]};
				end
				next_state(IFETCH1);
			end
		default:
			begin
				opcode_read();
				next_state(IFETCH1);
			end
		endcase
	end

`include "load_mac.v"
`include "store.v"
//`include "half_calc.v"
`include "byte_calc.v"
HALF_CALC:
	begin
		moveto_ifetch();
		store_what <= `STW_DEF70;
		case(ir[7:0])
		`ADC_IMM,`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_IYL,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_AL,`ADC_ALX,`ADC_I,`ADC_IL,`ADC_DSP,`ADC_DSPIY:	begin res16 <= acc16 + b16 + {15'd0,cf}; end
		`SBC_IMM,`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_IYL,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_AL,`SBC_ALX,`SBC_I,`SBC_IL,`SBC_DSP,`SBC_DSPIY:	begin res16 <= acc16 - b16 - {15'd0,~cf}; end
		`CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_IYL,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_AL,`CMP_ALX,`CMP_I,`CMP_IL,`CMP_DSP,`CMP_DSPIY:	begin res16 <= acc16 - b16; end
		`AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_IYL,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_AL,`AND_ALX,`AND_I,`AND_IL,`AND_DSP,`AND_DSPIY:	begin res16 <= acc16 & b16; end
		`ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_IYL,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_AL,`ORA_ALX,`ORA_I,`ORA_IL,`ORA_DSP,`ORA_DSPIY:	begin res16 <= acc16 | b16; end
		`EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_IYL,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_AL,`EOR_ALX,`EOR_I,`EOR_IL,`EOR_DSP,`EOR_DSPIY:	begin res16 <= acc16 ^ b16; end
		`LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_IYL,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_AL,`LDA_ALX,`LDA_I,`LDA_IL,`LDA_DSP,`LDA_DSPIY:	begin res16 <= b16; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX:	begin res16 <= acc16 & b16; end
		`TRB_ZP,`TRB_ABS:	begin res16 <= acc16 & b16; wdat <= ~acc16 & b16; state <= STORE1; data_nack(); end
		`TSB_ZP,`TSB_ABS:	begin res16 <= acc16 & b16; wdat <= acc16 | b16; state <= STORE1; data_nack(); end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY:	begin res16 <= b16; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX:	begin res16 <= b16; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS:	begin res16 <= x16 - b16; end
		`CPY_IMM,`CPY_ZP,`CPY_ABS:	begin res16 <= y16 - b16; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX:	begin res16 <= {b16,1'b0}; wdat <= {b16[14:0],1'b0}; state <= STORE1; data_nack(); end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX:	begin res16 <= {b16,cf}; wdat <= {b16[14:0],cf}; state <= STORE1; data_nack(); end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX:	begin res16 <= {b16[0],1'b0,b16[15:1]}; wdat <= {1'b0,b16[15:1]}; state <= STORE1; data_nack(); end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX:	begin res16 <= {b16[0],cf,b16[15:1]}; wdat <= {cf,b16[15:1]}; state <= STORE1; data_nack(); end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX:	begin res16 <= {b24,b16} + 24'd1; wdat <= {{b24,b16}+24'd1}; state <= STORE1; data_nack(); end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX:	begin res16 <= {b24,b16} - 24'd1; wdat <= {{b24,b16}-24'd1}; state <= STORE1; data_nack(); end
		endcase
	end

MVN816:
	begin
		moveto_ifetch();
		if (&acc[15:0]) begin
			pc <= pc + 24'd3;
			ado <= pc + 24'd3;
			dbr <= ir[15:8];
		end
	end
endcase
end

`include "bus_task.v"
`include "misc_task.v"

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
MVN816:			fnStateName = "MVN816     ";
default:		fnStateName = "UNKNOWN    ";
endcase
endfunction

endmodule

