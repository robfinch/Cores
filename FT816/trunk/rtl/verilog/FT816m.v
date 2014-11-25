`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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

`define RST_VECT	32'hFFFFFFF8
`define NMI_VECT	32'hFFFFFFF4
`define IRQ_VECT	32'hFFFFFFF0
`define BRK_VECTNO	9'd0
`define SLP_VECTNO	9'd1
`define BYTE_RST_VECT	32'h0000FFFC
`define BYTE_NMI_VECT	32'h0000FFFA
`define BYTE_IRQ_VECT	32'h0000FFFE
`define RST_VECT_816	32'h0000FFFC
`define IRQ_VECT_816	32'h0000FFEE
`define NMI_VECT_816	32'h0000FFEA
`define ABT_VECT_816	32'h0000FFE8
`define BRK_VECT_816	32'h0000FFE6
`define COP_VECT_816	32'h0000FFE4

`define BYTE		9'h87
`define UBYTE		9'hA7
`define CHAR		9'h97
`define UCHAR		9'hB7
`define LEA			9'hC7
`define R			9'hD7
`define SXB				4'h0
`define SXC				4'h1
`define ZXB				4'h2
`define ZXC				4'h3
`define RBO				4'h4
`define NOT				4'h5
`define COM				4'h6
`define CLR				4'h7

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

`define RR			9'h02
`define ADD_RR			4'd0
`define SUB_RR			4'd1
`define AND_RR			4'd3
`define EOR_RR			4'd4
`define OR_RR			4'd5
`define MUL_RR			4'd8
`define MULS_RR			4'd9
`define DIV_RR			4'd10
`define DIVS_RR			4'd11
`define MOD_RR			4'd12
`define MODS_RR			4'd13
`define ASL_RRR			4'd14
`define LSR_RRR			4'd15
`define LD_RR		9'h7B

`define ADD_R		9'h77
`define ADD_IMM4	9'h67
`define ADD_IMM8	9'h65		// 8 bit operand
`define ADD_IMM16	9'h79		// 16 bit operand
`define ADD_IMM32	9'h69		// 32 bit operand
`define ADD_ZPX		9'h75		// there is no ZP mode, use R0 to syntheisze
`define ADD_IX		9'h61
`define ADD_IY		9'h71
`define ADD_ABS		9'h6D
`define ADD_ABSX	9'h7D
`define ADD_RIND	9'h72
`define ADD_DSP		9'h63

`define SUB_R		9'hF7
`define SUB_IMM4	9'hE7
`define SUB_IMM8	9'hE5
`define SUB_IMM16	9'hF9
`define SUB_IMM32	9'hE9
`define SUB_ZPX		9'hF5
`define SUB_IX		9'hE1
`define SUB_IY		9'hF1
`define SUB_ABS		9'hED
`define SUB_ABSX	9'hFD
`define SUB_RIND	9'hF2
`define SUB_DSP		9'hE3

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

`define CMP_IMM8	9'hC5
`define CMP_IMM32	9'hC9
`define CMP_IMM16	9'hD9
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
`define CMP_RR		9'h86

`define LDA_IMM8	9'hA5
`define LDA_IMM16	9'hB9
`define LDA_IMM32	9'hA9

`define AND_R		9'h37
`define AND_IMM4	9'h27
`define AND_IMM8	9'h25
`define AND_IMM16	9'h39
`define AND_IMM32	9'h29
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

`define OR_R		9'h17
`define OR_IMM4		9'h07
`define OR_IMM8		9'h05
`define OR_IMM16	9'h19
`define OR_IMM32	9'h09
`define OR_ZPX		9'h15
`define OR_IX		9'h01
`define OR_IY		9'h11
`define OR_ABS		9'h0D
`define OR_ABSX		9'h1D
`define OR_RIND		9'h12
`define OR_DSP		9'h03

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

`define EOR_R		9'h57
`define EOR_IMM4	9'h47
`define EOR_IMM		9'h49
`define EOR_IMM8	9'h45
`define EOR_IMM16	9'h59
`define EOR_IMM32	9'h49
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

// LD is OR rt,r0,....

`define ST_ZPX		9'h84
`define ST_IX		9'h81
`define ST_IY		9'h91
`define ST_ABS		9'h9C
`define ST_ABSX		9'h9E
`define ST_RIND		9'h92
`define ST_DSP		9'h83

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

`define ASL_IMM8	9'h24
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

`define LSR_IMM8	9'h34
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
`define BHI			9'h13
`define BLS			9'h33
`define BGE			9'h93
`define BLT			9'hB3
`define BGT			9'hD3
`define BLE			9'hF3
`define ACBR		9'h53

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

`define BAZ			9'hC1
`define BXZ			9'hD1
`define BEQ_RR		9'hE2
`define INT0		9'hDC
`define INT1		9'hDD
`define SUB_SP8		9'h85
`define SUB_SP16	9'h99
`define SUB_SP32	9'h89
`define MVP			9'h44
`define MVN			9'h54
`define STS			9'h64
`define EXEC		9'hEB
`define ATNI		9'h4B
`define MDR			9'h3C

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

`define STW_DEF		6'h0
`define STW_ACC		6'd1
`define STW_X		6'd2
`define STW_Y		6'd3
`define STW_PC		6'd4
`define STW_PC2		6'd5
`define STW_PCHWI	6'd6
`define STW_SR		6'd7
`define STW_RFA		6'd8
`define STW_RFA8	6'd9
`define STW_A		6'd10
`define STW_B		6'd11
`define STW_CALC	6'd12
`define STW_OPC		6'd13
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

module FT816(rst, clk, phi1, phi2, be, bz, vpa, vda, rw, ad, db);
input rst;
input clk;
output phi1;
output phi2;
input be;
input bz;
output reg vpa;
output reg vda;
output tri rw;
output tri [23:0] ad;
inout tri [7:0] db;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

reg [31:0] phi1r,phi2r;
reg rwo;
reg [23:0] ado;
reg [7:0] dbo;

reg [7:0] dbi;
reg pg2;
reg [8:0] ir;
reg [23:0] pc;
reg [15:0] dpr;		// direct page register
reg [15:0] x,y,acc,sp;
reg [7:0] tmp;
wire [15:0] acc16 = acc;
wire [7:0] acc8=acc[7:0];
wire [7:0] x8=x[7:0];
wire [7:0] y8=y[7:0];
wire [15:0] acc_dec = acc - 16'd1;
wire [15:0] acc_inc = acc + 16'd1;
wire [15:0] x_dec = x - 16'd1;
wire [15:0] x_inc = x + 16'd1;
wire [15:0] y_dec = y - 16'd1;
wire [15:0] y_inc = y + 16'd1;
reg cf,vf,nf,zf;
reg m816,m16,xb16;
reg x_bit,m_bit;
reg [8:0] res8;
reg [16:0] res16;

wire [3:0] pc_inc8;
FT816_pcinc u1
(
	.opcode({pg2,ir[7:0]}),
	.suppress_pcinc(),
	.inc(pc_inc8);
);

always @(be,bz,rwo,ado,dbo)
	if (be) begin
		if (~bz) begin
			rw <= 1'b0;
			ad <= 24'd0;
			db <= 8'd0;
		end
		else begin
			rw <= rwo;
			ad <= ado;
			if (~rwo)
				db <= dbo;
			else
				db <= {8{1'bz}};
		end
	end
	else begin
		rw <= 1'bz;
		ad <= {24{1'bz}};
		db <= {8{1'bz}};
	end

assign phi1 = phi1r[31];
assign phi2 = phi2r[31];

always @(posedge clk_i)
if (rst_i)
	phi1r <= 32'b01111111111111100000000000000000;
	phi2r <= 32'b00000000000000000111111111111110;
end
else begin
	phi1r <= {phi1r[30:0],phi1r[31]};
	phi2r <= {phi2r[30:0],phi2r[31]};
end

reg [15:0] ndx;
always @*
case(1'b1)
ndxX:	ndx <= x;
ndxY:	ndx <= y;
default:	ndx <= 16'h0000;
endcase

function isOneByte;
input [8:0] ir;
case(ir)
NOP,SED,CLD,SEI,CLI,SEC,CLC,CLV:
	isOneByte = TRUE;
default:	isOneByte = FALSE;
endcase
endfunction

function isTwoBytes;
input [8:0] ir;
case(ir)
endcase
endfunction

always @(posedge clk)
if (rst) begin
end
else begin
case(state)
RESET:
	begin
		vpa <= TRUE;
		vda <= TRUE;
		rw <= TRUE;
		ado <= pc;
	end
IFETCH:
	if (rdy) begin
		ir[8] <= pg2;
		ir[7:0] <= db;
		ado <= pc + 24'd1;
		pc <= pc + 24'd1;
		vpa <= !isOneByte(db);
		vda <= FALSE;
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
		`TAS,`TXS: begin if (m816) sp <= res16[15:0]; else sp <= {8'h01,res8[7:0]}; end
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
	end
DECODE:
	begin
		first_ifetch <= `TRUE;
		next_state(IFETCH);
		vpa <= `TRUE;
		vda <= `TRUE;
		pc <= pc + 24'd1;
		ado <= pc + 24'd1;
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
//		`NAT:	begin em <= 1'b0; state <= IFETCH; end
		`WDM:	if (ir[15:8]==`XCE) begin
					em <= 1'b0;
					next_state(IFETCH);
					pc <= pc + 32'd2;
				end
		// Switching the processor mode always zeros out the upper part of the index registers.
		// switching to 816 mode sets 8 bit memory/indexes
		`XCE:	begin
					m816 <= ~cf;
					cf <= ~m816;
					if (~cf) begin		
						m_bit <= 1'b1;
						x_bit <= 1'b1;
					end
					x[15:8] <= 8'd0;
					y[15:8] <= 8'd0;
				end
//		`NOP:	;	// may help routing
		`CLC:	begin cf <= 1'b0; end
		`SEC:	begin cf <= 1'b1; end
		`CLV:	begin vf <= 1'b0; end
		`CLI:	begin im <= 1'b0; end
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
		// Handle # mode
		`LDA_IMM:
			begin
				res8 <= db;
				res16[7:0] <= db;
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`LDX_IMM,`LDY_IMM:
			begin
				res8 <= db;
				res16[7:0] <= db;
				if (xb16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`ADC_IMM:
			begin
				res8 <= acc8 + db + {7'b0,cf};
				tmp <= db;
				b8 <= db;		// for overflow calc
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`SBC_IMM:
			begin
				res8 <= acc8 - db - {7'b0,~cf};
				$display("sbc: %h= %h-%h-%h", acc8 - ir[15:8] - {7'b0,~cf},acc8,ir[15:8],~cf);
				b8 <= db;		// for overflow calc
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`AND_IMM,`BIT_IMM:
			begin
				res8 <= acc8 & db;
				b8 <= db;	// for bit flags
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`ORA_IMM:
			begin
				res8 <= acc8 | db;
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`EOR_IMM:
			begin
				res8 <= acc8 ^ db;
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`CMP_IMM:
			begin
				res8 <= acc8 - db;
				if (m16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`CPX_IMM:
			begin
				res8 <= x8 - db;
				if (xb16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		`CPY_IMM:
			begin
				res8 <= y8 - db;
				if (xb16) begin
					vda <= `FALSE;
					next_state(IMM1);
				end
			end
		// Handle zp mode
		`LDA_ZP:
			begin
				vpa <= `FALSE;
				vda <= `TRUE;
				ado <= db;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDX_ZP,`LDY_ZP:
			begin
				radr <= zp_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ZP,`SBC_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`CMP_ZP,
		`BIT_ZP,
		`ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`INC_ZP,`DEC_ZP,`TRB_ZP,`TSB_ZP:
			begin
				radr <= zp_address;
				wadr <= zp_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`CPX_ZP,`CPY_ZP:
			begin
				radr <= zp_address;
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ZP:
			begin
				wadr <= zp_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STX_ZP:
			begin
				wadr <= zp_address;
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				state <= STORE1;
			end
		`STY_ZP:
			begin
				wadr <= zp_address;
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				state <= STORE1;
			end
		`STZ_ZP:
			begin
				wadr <= zp_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle zp,x mode
		`LDA_ZPX:
			begin
				radr <= zpx_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDY_ZPX:
			begin
				radr <= zpx_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ZPX,`SBC_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`CMP_ZPX,
		`BIT_ZPX,
		`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX:
			begin
				radr <= zpx_address;
				wadr <= zpx_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ZPX:
			begin
				wadr <= zpx_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STY_ZPX:
			begin
				wadr <= zpx_address;
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				state <= STORE1;
			end
		`STZ_ZPX:
			begin
				wadr <= zpx_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle zp,y
		`LDX_ZPY:
			begin
				radr <= zpy_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`STX_ZPY:
			begin
				wadr <= zpy_address;
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				state <= STORE1;
			end
		// Handle (zp,x)
		`ADC_IX,`SBC_IX,`AND_IX,`ORA_IX,`EOR_IX,`CMP_IX,`LDA_IX,`STA_IX:
			begin
				radr <= zpx_address;
				load_what <= `IA_70;
				state <= LOAD_MAC1;
			end
		// Handle (zp),y
		`ADC_IY,`SBC_IY,`AND_IY,`ORA_IY,`EOR_IY,`CMP_IY,`LDA_IY,`STA_IY:
			begin
				radr <= zp_address;
				isIY <= `TRUE;
				load_what <= `IA_70;
				state <= LOAD_MAC1;
			end
		// Handle abs
		`LDA_ABS:
			begin
				radr <= abs_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDX_ABS,`LDY_ABS:
			begin
				radr <= abs_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ABS,`SBC_ABS,`AND_ABS,`ORA_ABS,`EOR_ABS,`CMP_ABS,
		`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS,`TRB_ABS,`TSB_ABS,
		`BIT_ABS:
			begin
				radr <= abs_address;
				wadr <= abs_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`CPX_ABS,`CPY_ABS:
			begin
				radr <= abs_address;
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ABS:
			begin
				wadr <= abs_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STX_ABS:
			begin
				wadr <= abs_address;
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				state <= STORE1;
			end	
		`STY_ABS:
			begin
				wadr <= abs_address;
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				state <= STORE1;
			end
		`STZ_ABS:
			begin
				wadr <= abs_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle abs,x
		`LDA_ABSX:
			begin
				radr <= absx_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ABSX,`SBC_ABSX,`AND_ABSX,`ORA_ABSX,`EOR_ABSX,`CMP_ABSX,
		`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX,`BIT_ABSX:
			begin
				radr <= absx_address;
				wadr <= absx_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`LDY_ABSX:
			begin
				radr <= absx_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`STA_ABSX:
			begin
				wadr <= absx_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STZ_ABSX:
			begin
				wadr <= absx_address;
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle abs,y
		`LDA_ABSY:
			begin
				radr <= absy_address;
				load_what <= m16 ? `HALF_71	: `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ABSY,`SBC_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`CMP_ABSY:
			begin
				radr <= absy_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`LDX_ABSY:
			begin
				radr <= absy_address;
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`STA_ABSY:
			begin
				wadr <= absy_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle d,sp
		`LDA_DSP:
			begin
				radr <= dsp_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_DSP,`SBC_DSP,`CMP_DSP,`ORA_DSP,`AND_DSP,`EOR_DSP:
			begin
				radr <= dsp_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_DSP:
			begin
				wadr <= dsp_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle (d,sp),y
		`ADC_DSPIY,`SBC_DSPIY,`CMP_DSPIY,`ORA_DSPIY,`AND_DSPIY,`EOR_DSPIY,`LDA_DSPIY,`STA_DSPIY:
			begin
				radr <= dsp_address;
				isIY <= `TRUE;
				load_what <= `IA_70;
				state <= LOAD_MAC1;
			end
		// Handle [zp],y
		`ADC_IYL,`SBC_IYL,`AND_IYL,`ORA_IYL,`EOR_IYL,`CMP_IYL,`LDA_IYL,`STA_IYL:
			begin
				radr <= zp_address;
				isIY24 <= `TRUE;
				load_what <= `IA_70;
				state <= LOAD_MAC1;
			end
		// Handle al
		`LDA_AL:
			begin
				radr <= al_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_AL,`SBC_AL,`AND_AL,`ORA_AL,`EOR_AL,`CMP_AL:
			begin
				radr <= al_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_AL:
			begin
				wadr <= al_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle alx
		`LDA_ALX:
			begin
				radr <= alx_address;
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ALX,`SBC_ALX,`AND_ALX,`ORA_ALX,`EOR_ALX,`CMP_ALX:
			begin
				radr <= alx_address;
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ALX:
			begin
				wadr <= alx_address;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle [zp]
		`ADC_IL,`SBC_IL,`AND_IL,`ORA_IL,`EOR_IL,`CMP_IL,`LDA_IL,`STA_IL:
			begin
				isI24 <= `TRUE;
				radr <= zp_address;
				load_what <= `IA_70;
				state <= LOAD_MAC1;
			end
		// Handle (zp)
		`ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,`PEI:
			begin
				radr <= zp_address;
				load_what <= `IA_70;
				state <= LOAD_MAC1;
			end
		`BRK:
			begin
				set_sp();
				store_what <= m816 ? `STW_PC2316 : `STW_PC158;// `STW_PC3124;
				state <= STORE1;
				bf <= !hwi;
			end
		`COP:
			begin
				set_sp();
				store_what <= m816 ? `STW_PC2316 : `STW_PC158;// `STW_PC3124;
				state <= STORE1;
				vect <= `COP_VECT_816;
			end
		`JMP:
			begin
				pc[15:0] <= ir[23:8];
			end
		`JML:
			begin
				pc[23:0] <= ir[31:8];
			end
		`JMP_IND:
			begin
				radr <= abs_address;
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end
		`JMP_INDX:
			begin
				radr <= absx_address;
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end	
		`JSR,`JSR_INDX:
			begin
				set_sp();
				store_what <= `STW_PC158;
				state <= STORE1;
			end
		`JSL:
			begin
				set_sp();
				store_what <= `STW_PC2316;
				state <= STORE1;
			end
		`RTS,`RTL:
			begin
				inc_sp();
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end
		`RTI:	begin
				inc_sp();
				load_what <= `SR_70;
				state <= LOAD_MAC1;
				end
		`BEQ,`BNE,`BPL,`BMI,`BCC,`BCS,`BVC,`BVS,`BRA:
				begin
					if (takb)
						pc <= pc + pc_inc8 + {{24{ir[15]}},ir[15:8]};
					else
						pc <= pc + pc_inc8;
				end
			//end
		`BRL:	pc <= pc + pc_inc8 + {{16{ir[23]}},ir[23:8]};
		`PHP:
			begin
				set_sp();
				store_what <= `STW_SR70;
				state <= STORE1;
			end
		`PHA:	tsk_push(`STW_ACC8,`STW_ACC70,m16);
		`PHX:	tsk_push(`STW_X8,`STW_X70,xb16);
		`PHY:	tsk_push(`STW_Y8,`STW_Y70,xb16);
		`PLP:
			begin
				inc_sp();
				load_what <= `SR_70;
				state <= LOAD_MAC1;
			end
		`PLA:
			begin
				inc_sp();
				load_what <= m16 ? `HALF_71S : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`PLX,`PLY:
			begin
				inc_sp();
				load_what <= xb16 ? `HALF_71S : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`PHB:
			begin
				set_sp();
				store_what <= `STW_DBR;
				state <= STORE1;
			end
		`PHD:
			begin
				set_sp();
				store_what <= `STW_DPR158;
				state <= STORE1;
			end
		`PHK:
			begin
				set_sp();
				store_what <= `STW_PC2316;
				state <= STORE1;
			end
		`PEA:
			begin
				tmp16 <= ir[23:8];
				set_sp();
				store_what <= `STW_TMP158;
				state <= STORE1;
			end
		`PER:
			begin
				tmp16 <= pc[15:0] + ir[23:8] + 16'd3;
				set_sp();
				store_what <= `STW_TMP158;
				state <= STORE1;
			end
		`PLB:
			begin
				inc_sp();
				load_what <= `BYTE_71;
				state <= LOAD_MAC1;
			end
		`PLD:
			begin
				inc_sp();
				load_what <= `HALF_71S;
				state <= LOAD_MAC1;
			end
		`MVN,`MVP:
			begin
				radr <= mvnsrc_address;
				load_what <= `BYTE_72;
				pc <= pc;	// override increment above
				state <= LOAD_MAC1;
			end
		default:	// unimplemented opcode
			pc <= pc + 24'd1;
		endcase
	end
IMM1:
	begin
		next_state(IFETCH);
		vpa <= `TRUE;
		vda <= `TRUE;
		pc <= pc + 24'd1;
		ado <= pc + 24'd1;
		b16 <= {db,tmp};	// for overflow calc
		case(ir[7:0])
		// Handle # mode
		`LDA_IMM:	res16[15:8] <= db;
		`LDX_IMM,`LDY_IMM:
					res16[15:8] <= db;
		`ADC_IMM:	res16 <= acc16 + {db,tmp} + {15'b0,cf};
		`SBC_IMM:
			begin
				res16 <= acc16 - {db,tmp} - {15'b0,~cf};
				$display("sbc: %h= %h-%h-%h", acc8 - ir[15:8] - {7'b0,~cf},acc8,ir[15:8],~cf);
			end
		`AND_IMM,`BIT_IMM:
				res16 <= acc16 & {db,tmp};
		`ORA_IMM:	res16 <= acc16 | {db,tmp};
		`EOR_IMM:	res16 <= acc16 ^ {db,tmp};
		`CMP_IMM:	res16 <= acc16 - {db,tmp};
		`CPX_IMM:	res16 <= x16 - {db,tmp};
		`CPY_IMM:	res16 <= y16 - {db,tmp};
		endcase
	end

DECODE:
	if (rdy) begin
		dbi <= db;
		if (isTwoBytes(ir))
			vpa <= FALSE;
		pg2 <= FALSE;
		case(ir)
		NOP:	begin vpa <= TRUE; vda <= TRUE; next_state(IFETCH); end
		CLD:	begin df <= FALSE; vpa <= TRUE; vda <= TRUE; next_state(IFETCH); end
		SED:	begin df <= TRUE;  vpa <= TRUE; vda <= TRUE; next_state(IFETCH); end
		CLC:	begin cf <= FALSE; vpa <= TRUE; vda <= TRUE; next_state(IFETCH); end
		SEC:	begin cf <= TRUE;  vpa <= TRUE; vda <= TRUE; next_state(IFETCH); end
		CLV:	begin vf <= FALSE; vpa <= TRUE; vda <= TRUE; next_state(IFETCH); end
		BCC:	do_branch(~cf);
		BCS:	do_branch( cf);
		BEQ:	do_branch( zf);
		BNE:	do_branch(~zf);
		BMI:	do_branch( nf);
		BPL:	do_branch(~nf);
		BVS:	do_branch( vs);
		BVC:	do_branch(~vs);
		LDA_ZP:
		PHA:
		endcase
	end
ZP1:
	begin
		vpa <= FALSE;
		vda <= TRUE;
		ado <= dp + dbi + ndx;
		next_state(ZP2);
	end
ZP2:
	if (rdy) begin
		dbi <= db;
		next_state(EXECUTE);
	end
EXECUTE:
	begin
		case(ir)
		LDA_ZP:	res <= 
		endcase
	end

endcase

task do_branch;
input flag;
begin
	next_state(IFETCH);
	vpa <= TRUE;
	vda <= TRUE;
	if (flag) begin
		pc <= pc + {{16{db[7]}},db};
		ado <= pc + {{16{db[7]}},db};
	end
	else begin
		pc <= pc + 24'd1;
		ado <= pc + 24'd1;
	end
end
endtask

task push;
input [7:0] dat;
	vpa <= FALSE;
	vda <= TRUE;
	ado <= {8'h00,sp};
	dbo <= dat;
	sp <= sp - 16'd1;
endtask

end

endmodule

// This table being setup to set the pc increment. It should synthesize to a ROM.
module FT816_pcinc(opcode,suppress_pcinc,inc);
input [8:0] opcode;
input [3:0] suppress_pcinc;
output reg [3:0] inc;

always @(opcode,suppress_pcinc)
if (suppress_pcinc==4'hF)
	case(opcode)
	`BRK:	inc <= 4'd0;
	`INT0,`INT1: inc <= 4'd0;
	`BPL,`BMI,`BCS,`BCC,`BVS,`BVC,`BEQ,`BNE,`BRA,`BGT,`BLE,`BGE,`BLT,`BHI,`BLS,`ACBR:	inc <= 4'd2;
	`BRL: inc <= 4'd3;
	`EXEC,`ATNI: inc <= 4'd2;
	`CLC,`SEC,`CLD,`SED,`CLV,`CLI,`SEI:	inc <= 4'd1;
	`TAS,`TSA,`TAY,`TYA,`TAX,`TXA,`TSX,`TXS,`TYX,`TXY:	inc <= 4'd1;
	`TRS,`TSR: inc <= 4'd2;
	`INY,`DEY,`INX,`DEX,`INA,`DEA: inc <= 4'd1;
	`XCE: inc <= 4'd1;
	`STP,`WAI: inc <= 4'd1;
	`JMP,`JML,`JMP_IND,`JMP_INDX,`JMP_RIND,
	`JSR,`JSR_RIND,`JSL,`BSR,`JSR_INDX,`RTS,`RTL,`RTI: inc <= 4'd0;
	`JML,`JSL,`JMP_IND,`JMP_INDX,`JSR_INDX:	inc <= 4'd5;
	`JMP_RIND,`JSR_RIND: inc <= 4'd2;
	`NOP: inc <= 4'd1;
	`BSR: inc <= 4'd3;
	`RR: inc <= 4'd3;
	`LD_RR,`CMP_RR,`R:	inc <= 4'd2;
	`ADD_IMM4,`SUB_IMM4,`AND_IMM4,`OR_IMM4,`EOR_IMM4,
	`ADD_R,`SUB_R,`AND_R,`OR_R,`EOR_R:	inc <= 4'd2;
	`ADD_IMM8,`SUB_IMM8,`AND_IMM8,`OR_IMM8,`EOR_IMM8,`ASL_IMM8,`LSR_IMM8:	inc <= 4'd3;
	`MUL_IMM8,`DIV_IMM8,`MOD_IMM8: inc <= 4'd3;
	`LDX_IMM8,`LDY_IMM8,`LDA_IMM8,`CMP_IMM8,`CPX_IMM8,`CPY_IMM8,`SUB_SP8: inc <= 4'd2;
	`ADD_IMM16,`SUB_IMM16,`AND_IMM16,`OR_IMM16,`EOR_IMM16:	inc <= 4'd4;
	`MUL_IMM16,`DIV_IMM16,`MOD_IMM16: inc <= 4'd4;
	`LDX_IMM16,`LDA_IMM16,`CMP_IMM16,`SUB_SP16: inc <= 4'd3;
	`ADD_IMM32,`SUB_IMM32,`AND_IMM32,`OR_IMM32,`EOR_IMM32:	inc <= 4'd6;
	`MUL_IMM32,`DIV_IMM32,`MOD_IMM32: inc <= 4'd6;
	`LDX_IMM32,`LDY_IMM32,`LDA_IMM32,`SUB_SP32,
	`CMP_IMM32,`CPX_IMM32,`CPY_IMM32: inc <= 4'd5;
	`ADD_ZPX,`SUB_ZPX,`AND_ZPX,`OR_ZPX,`EOR_ZPX,`LEA_ZPX: inc <= 4'd4;
	`ADD_IX,`SUB_IX,`AND_IX,`OR_IX,`EOR_IX,`LEA_IX: inc <= 4'd4;
	`ADD_IY,`SUB_IY,`AND_IY,`OR_IY,`EOR_IY,`LEA_IY: inc <= 4'd4;
	`ADD_ABS,`SUB_ABS,`AND_ABS,`OR_ABS,`EOR_ABS,`LEA_ABS: inc <= 4'd6;
	`ADD_ABSX,`SUB_ABSX,`AND_ABSX,`OR_ABSX,`EOR_ABSX,`LEA_ABSX: inc <= 4'd7;
	`ADD_RIND,`SUB_RIND,`AND_RIND,`OR_RIND,`EOR_RIND,`LEA_RIND: inc <= 4'd3;
	`ADD_DSP,`SUB_DSP,`AND_DSP,`OR_DSP,`EOR_DSP,`LEA_DSP: inc <= 4'd3;
	`ASL_ACC,`LSR_ACC,`ROR_ACC,`ROL_ACC: inc <= 4'd1;
	`ASL_RR,`ROL_RR,`LSR_RR,`ROR_RR,`INC_RR,`DEC_RR: inc <= 4'd2;
	`ST_RIND: inc <= 4'd2;
	`LDA_ZPX,`LDX_ZPX,`LDY_ZPX,`ST_DSP,
	`STA_ZPX,`STX_ZPX,`STY_ZPX,`CPX_ZPX,`CPY_ZPX,
	`BMS_ZPX,`BMC_ZPX,`BMF_ZPX,`BMT_ZPX,
	`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX,
	`ADD_DSP,`SUB_DSP,`OR_DSP,`AND_DSP,`EOR_DSP: inc <= 4'd3;
	`ST_ZPX,`ADD_ZPX,`SUB_ZPX,`OR_ZPX,`AND_ZPX,`EOR_ZPX,
	`ADD_IX,`SUB_IX,`OR_IX,`AND_IX,`EOR_IX,`ST_IX,
	`ADD_IY,`SUB_IY,`OR_IY,`AND_IY,`EOR_IY,`ST_IY: inc <= 4'd4;
	`LDA_ABS,`LDX_ABS,`LDY_ABS,`STX_ABS,`STY_ABS,`STA_ABS,
	`BMS_ABS,`BMC_ABS,`BMF_ABS,`BMT_ABS,
	`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS,`CPX_ABS,`CPY_ABS: inc <= 4'd5;
	`LDA_ABSX,`LDX_ABSY,`LDY_ABSX,`ST_ABS,`STA_ABSX,
	`ADD_ABS,`SUB_ABS,`OR_ABS,`AND_ABS,`EOR_ABS,
	`BMS_ABSX,`BMC_ABSX,`BMF_ABSX,`BMT_ABSX,
	`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX,`SPL_ABSX: inc <= 4'd6;
	`ST_ABSX,
	`ADD_ABSX,`SUB_ABSX,`OR_ABSX,`AND_ABSX,`EOR_ABSX: inc <= 4'd7;
	`PHP,`PHA,`PHX,`PHY,`PLP,`PLA,`PLX,`PLY,`PSHR4,`POPR4: inc <= 4'd1;
	`PUSH,`POP: inc <= 4'd2;
	`MVN,`MVP,`STS,`CMPS: inc <= 4'd1;
	`PG2,`LEA,`PEA,`BYTE,`UBYTE,`CHAR,`UCHAR:	inc <= 4'd1;
	`TON,`TOFF:	inc <= 4'd1;
	`ICON,`ICOFF: inc <= 4'd1;
	`PUSHA,`POPA: inc <= 4'd1;
	`SPL_ABS:	inc <= 4'd5;
	default:	inc <= 4'd0;	// unimplemented instruction
	endcase
else
	inc <= 4'd0;
endmodule

module micro_code_rom(ir,m16,xb16,vp,vpa,vda)
input [8:0] ir;

case(ir)
{`LDA_IMM,4'h0}: 
// Load incoming data into 'b' register,increment program counter
// if m16 
//     Load incoming data into 'bh' register


IFETCH:		ir <= db; ad <= pc + 1; pc <= pc + 1;
INX:		res <= x + 1;	increment X signal, load res signal
DEST = RES;
LOADIR:		DEST = IR; SRCA = DB; SRCB = 0;  OP = LOAD 
NEXT:		DEST = PC; DEST = AD; SRCA = PC; SRCB = #1; OP = ADD; VPA = 1; VDA = 1; JMP = LOADIR

`define MCO_ADD		5'd0
`define MCO_SUB		5'd1
`define MCO_LD		5'd2
`define MCD_XL		5'd07
`define MCD_XX		5'd08
`define MCD_IR		5'd11
`define MCD_PC		5'd13
`define MCD_AD		5'd14
`define MCD_PCAD	5'd16	// program counter and address bus
`define MCD_CF		5'd17

`define MCS_CONST	4'd00
`define MCS_PC		4'd13
`define MCS_XL		4'd07
`define MCS_XX		4'd08
`define MCS_DB		4'd15

`define MCJ_INC		3'd0
`define MCJ_IR		3'd1
`define MCJ_JMP		3'd2
`define MCJ_JSR		3'd3
`define MCJ_RTS		3'd4
`define MCJ_M16		3'd5
`define MCJ_XB16	3'd6


`define MC_JA		[12: 0]		// jump address
`define MC_JBITS	[15:13]

`define MCF_NONE	3'd0
`define MCF_C		3'd1
`define MCF_V		3'd2
`define MCR_CNZ		3'd3
`define MCR_CVNZ	3'd4
`define MCR_NZ		3'd5
`define MCR_D		3'd6


reg [12:0] mpc;		// micro program counter
reg [63:0] mcrom [0:4095];

initial begin
	//   DAPSIAAXXYYSDDT   SRCA  SRCB    CONST     OP  RW   VPA  VDA  VPB J
	//    DCPRXLXLXLRPBM
// RESET:
mcrom[12'h000] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFFC,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h001] <= {`MCD_PCL,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h002] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFFD,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h003] <= {`MCD_PCM,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h004] <= {`MCD_PCH,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h005] <= {`MCD_AD,`MCS_PC,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
// IFETCH:
mcrom[12'h006] <= {`MCD_IR,  `MCS_DB,`MCS_CONST,24'h000000,`MCO_LD ,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h007] <= {`MCD_PCAD,`MCS_PC,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b1,1'b1,1'b0,`MCJ_IR,12'h0000};
// NMI 816:
mcrom[12'h010] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000000,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h011] <= {`MCD_DB,`MCS_PCH,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h012] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000001,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h013] <= {`MCD_DB,`MCS_PCM,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h014] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000002,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h015] <= {`MCD_DB,`MCS_PCL,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h016] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000003,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h017] <= {`MCD_DB,`MCS_SR,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h018] <= {`MCD_SP,`MCS_SP,`MCS_CONST,24'h000003,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h019] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFEA,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h01A] <= {`MCD_PCL,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h01B] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFEB,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h01C] <= {`MCD_PCM,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h01D] <= {`MCD_PCH,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h01E] <= {`MCD_AD,`MCS_PC,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,12'h006};
// NMI:
mcrom[12'h020] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000000,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h021] <= {`MCD_DB,`MCS_PCM,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h022] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000001,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h023] <= {`MCD_DB,`MCS_PCL,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h024] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000002,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h025] <= {`MCD_DB,`MCS_SR,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h026] <= {`MCD_SP,`MCS_SP,`MCS_CONST,24'h000002,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h027] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFFA,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h028] <= {`MCD_PCL,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h029] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFFB,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h02A] <= {`MCD_PCM,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h02B] <= {`MCD_PCH,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h02C] <= {`MCD_AD,`MCS_PC,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,12'h0006};
// IRQ 816:
mcrom[12'h030] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000000,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h031] <= {`MCD_DB,`MCS_PCH,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h032] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000001,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h033] <= {`MCD_DB,`MCS_PCM,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h034] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000002,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h035] <= {`MCD_DB,`MCS_PCL,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h036] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000003,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h037] <= {`MCD_DB,`MCS_SR,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h038] <= {`MCD_SP,`MCS_SP,`MCS_CONST,24'h000003,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h039] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFEE,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h03A] <= {`MCD_PCL,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h03B] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFEF,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h03C] <= {`MCD_PCM,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h03D] <= {`MCD_PCH,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h03E] <= {`MCD_AD,`MCS_PC,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,12'h0006};
// IRQ:
mcrom[12'h040] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000000,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h041] <= {`MCD_DB,`MCS_PCM,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h042] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000001,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h043] <= {`MCD_DB,`MCS_PCL,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h044] <= {`MCD_AD,`MCS_SP,`MCS_CONST,24'h000002,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h045] <= {`MCD_DB,`MCS_SR,`MCS_NONE,24'h000000,`MCD_LD,1'b0,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h046] <= {`MCD_SP,`MCS_SP,`MCS_CONST,24'h000002,`MCD_SUB,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h047] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFFE,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h048] <= {`MCD_PCL,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h049] <= {`MCD_AD,`MCS_CONST,`MCS_CONST,24'h00FFFF,`MCD_LD,1'b1,1'b1,1'b1,1'b1,`MCJ_INC,12'h0000};
mcrom[12'h04A] <= {`MCD_PCM,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h04B] <= {`MCD_PCH,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0000};
mcrom[12'h04C] <= {`MCD_AD,`MCS_PC,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`MCJ_INC,12'h0006};


	{16'b011000000000000,`MCS_PC,4'h0,24'h000001,5'h00,1'b1,1'b1,1'b1,1'b0};
	{`MCD_XX,  `MCS_XX,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b0,1'b0,1'b0};			// INX16
	{`MCD_XL,  `MCS_XL,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b0,1'b0,1'b0,2'd3,12'h000};			// INX8
// LDI16
mcrom[12'h100] <= {`MCD_TL,  `MCS_DB,`MCS_CONST,24'h000000,`MCO_LD, 1'b1,1'b1,1'b0,1'b0,`MCJ_INC,12'h000};
mcrom[12'h101] <= {`MCD_PCAD,`MCS_PC,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b1,1'b0,1'b0,1'b1,`MCJ_INC,12'h000};
mcrom[12'h102] <= {`MCD_TH,  `MCS_DB,`MCS_CONST,24'h000000,`MCO_LD, 1'b1,1'b1,1'b0,1'b0,`MCJ_INC,12'h000};
mcrom[12'h103] <= {`MCD_PCAD,`MCS_PC,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b1,1'b0,1'b0,1'b1,`MCJ_RTS,12'h000};
//LDI8
mcrom[12'h104] <= {`MCD_TL,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b1,1'b0,1'b0,`MCJ_INC,12'h000};
mcrom[12'h105] <= {`MCD_PCAD,`MCS_PC,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b1,1'b0,1'b0,1'b1,`MCJ_RTS,12'h000};
// ZPX8
mcrom[12'h106] <= {`MCD_TL, `MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b1,1'b0,1'b0,`MCJ_INC,12'h000};
mcrom[12'h107] <= {`MCD_PC, `MCS_PC,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b1,1'b0,1'b0,1'b1,`MCJ_INC,12'h000};
mcrom[12'h108] <= {`MCD_AD, `MCS_TL,`MCS_DP,24'h000000,`MCO_ADD,1'b1,1'b1,1'b0,1'b0,1'b1,`MCJ_INC,12'h000};
mcrom[12'h109] <= {`MCD_AD, `MCS_AD,`MCS_XX,24'h000000,`MCO_ADD,1'b1,1'b1,1'b0,1'b0,1'b1,`MCJ_INC,12'h000};
mcrom[12'h10A] <= {`MCD_RES,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b1,1'b0,1'b0,`MCJ_RTS,12'h000};

mcrom[`MCR_LDA_IMM8]:		mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_JSR,12'h104};
mcrom[`MCR_LDA_IMM8+1]:		mcrom <= {`MCD_RES,`MCS_TX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[`MCR_LDA_IMM16]:		mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_JSR,12'h100};
mcrom[`MCR_LDA_IMM16+1]:	mcrom <= {`MCD_RES,`MCS_TX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[`MCR_LDA_ZP16]:		mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_JSR,12'h104};
mcrom[`MCR_LDA_ZP16+1]:		mcrom <= {`MCD_AD, `MCS_TL,`MCS_DP,   24'h000000,`MCO_ADD,1'b1,1'b0,1'b1,1'b0,`INT0,`MCJ_INC,12'h000};
mcrom[`MCR_LDA_ZP16+2]:		mcrom <= {`MCD_TL, `MCS_DB,`MCS_CONST,24'h000000,`MCO_LD, 1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_INC,12'h000};
mcrom[`MCR_LDA_ZP16+3]:		mcrom <= {`MCD_AD, `MCS_AD,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b0,1'b1,1'b0,`INT0,`MCJ_INC,12'h000};
mcrom[`MCR_LDA_ZP16+4]:		mcrom <= {`MCD_TH, `MCS_DB,`MCS_CONST,24'h000000,`MCO_LD, 1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_INC,12'h000};
mcrom[`MCR_LDA_ZP16+5]:		mcrom <= {`MCD_RES,`MCS_TX,`MCS_CONST,24'h000000,`MCO_LD, 1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[`MCR_LDA_ZPX8]:		mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_JSR,12'h104};
mcrom[`MCR_LDA_ZPX8+1]:		mcrom <= {`MCD_AD, `MCS_TL,`MCS_DP,24'h000000,`MCO_ADD,1'b1,1'b0,1'b1,1'b0,`INT0,`MCJ_INC,12'h000};
mcrom[`MCR_LDA_ZPX8+2]:		mcrom <= {`MCD_RES,`MCS_DB,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};

mcrom[`MCR_ORA_IMM8]:		mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_JSR,12'h104};
mcrom[`MCR_ORA_IMM8+1]:		mcrom <= {`MCD_RES, `MCS_TX,`MCS_AX,24'h000000,`MCO_OR,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[`MCR_ORA_IMM16]:		mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT0,`MCJ_JSR,12'h100};
mcrom[`MCR_ORA_IMM16+1]:	mcrom <= {`MCD_RES, `MCS_TX,`MCS_AX,24'h000000,`MCO_OR,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};

mcrom[{3'b111,`SEC}] <=	{`MCD_RES,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`CLC}] <=	{`MCD_RES,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`INX}] <=	{`MCD_RES,`MCS_XX,`MCS_CONST,24'h000001,`MCO_ADD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`DEX}] <=	{`MCD_RES,`MCS_XX,`MCS_CONST,24'h000001,`MCO_SUB,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`TAX}] <=	{`MCD_RES,`MCS_AX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`TAY}] <=	{`MCD_RES,`MCS_AX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`TAS}] <=	{`MCD_RES,`MCS_AX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`TXA}] <=	{`MCD_RES,`MCS_XX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`TXY}] <=	{`MCD_RES,`MCS_XX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};
mcrom[{3'b111,`TXS}] <=	{`MCD_RES,`MCS_XX,`MCS_CONST,24'h000000,`MCO_LD,1'b1,1'b0,1'b0,1'b0,`INT1,`MCJ_JMP,12'h006};;
// LDA_IMM
mcrom[{3'b111,`LDA_IMM}: mcrom <= {`MCD_NONE,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_M16,13'h0000};
mcrom[{3'b110,`LDA_IMM}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_LDA_IMM16};
mcrom[{3'b101,`LDA_IMM}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_LDA_IMM8};
// LDA_ZP
mcrom[{3'b111,`LDA_ZP}: mcrom <= {`MCD_NONE,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_M16,13'h0000};
mcrom[{3'b110,`LDA_ZP}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_LDA_ZP16};
mcrom[{3'b101,`LDA_ZP}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_LDA_ZP8};
// LDA_ZPX
mcrom[{3'b111,`LDA_ZPX}: mcrom <= {`MCD_NONE,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_M16,13'h0000};
mcrom[{3'b110,`LDA_ZPX}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_LDA_ZPX16};
mcrom[{3'b101,`LDA_ZPX}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_LDA_ZPX8};

// ORA_IMM
mcrom[{3'b111,`ORA_IMM}: mcrom <= {`MCD_NONE,`MCS_CONST,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_M16,13'h0000};
mcrom[{3'b110,`ORA_IMM}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_ORA_IMM16};
mcrom[{3'b101,`ORA_IMM}: mcrom <= {`MCD_NONE,`MCS_AX,`MCS_CONST,24'h000000,`MCO_NOP,1'b1,1'b0,1'b0,1'b0,`MCJ_JMP,`MCR_ORA_IMM8};


wire [] mco = micro_code_rom[mpc];

always @*
case(mco[`MC_SRCA])
`MCS_CONST:	srca <= mco[`MC_CONST];
`MCS_DB:	srca <= db;
`MCS_PC:	srca <= pc;
`MCS_XL:	srca <= {{16{x[7]}},x[7:0]};
`MCS_XX:	srca <= {{8{x[15]}},x};
`MCS_YL:	srca <= {{16{y[7]}},y[7:0]};
`MCS_YX:	srca <= {{8{y[15]}},y};
`MCS_TX:	srca <= {{8{tmp[15]}},tmp};
endcase

wire resn8 = alu_o[7];
wire resz8 = alu_o[7:0]==8'h00;

always @*
case(mco[`MC_OP])
`MCO_ADD:	alu_o <= srca + srcb;
`MCO_SUB:	alu_o <= srca - srcb;
`MCO_LD:	alu_o <= srca;
`MCO_AND:	alu_o <= srca & srcb;
`MCO_OR:	alu_o <= srca | srcb;
`MCO_EOR:	alu_o <= srca ^ srcb;
endcase

always @(posedge clk)
if (rst)
	mpc <= 12'h0000;
else begin
	if (mco[`MC_INT] && nmi_edge && gie)
		mpc <= m816 ? 12'h010 : 12'h020;
	else if (mco[`MC_INT] && irq_i && !im && gie)
		mpc <= m816 ? 12'h030 : 12'h040;
	else
		case(mco[`MC_JBITS])
		`MCJ_INC:	mpc <= mpc + 13'h001;
		`MCJ_IR:	mpc <= {3'b111,ir};
		`MCJ_JMP:	mpc <= mco[`MC_JA];
		`MCJ_JSR:	begin mpc <= mco[`MC_JA]; mlr <= mpc + 12'd1; end
		`MCJ_RTS:	mpc <= mlr;
		`MCJ_XB16:	mpc <= xb16 ? {3'b110,ir} : {3'b101,ir};
		`MCJ_M16:	mpc <= m16 ? {3'b110,ir} : {3'b101,ir};
		endcase
end

always @(posedge clk)
if (rst)
else
	case(mco[`MC_DST_BITS])
	`MCD_NONE:	;
	`MCD_AD:	ad <= mc_alu_o;
	`MCD_PCAD:	begin ad <= mc_alu_o; pc <= mc_alu_o; end
	`MCD_IR:	ad <= mc_alu_o;
	`MCD_XL:	x[7:0] <= mc_alu_o[7:0];
	`MCD_XX:	x <= mc_alu_o[15:0];
	`MCD_YL:	y[7:0] <= mc_alu_o[7:0];
	`MCD_YX:	y <= mc_alu_o[15:0];
	`MCD_AL:	acc[7:0] <= mc_alu_o[7:0];
	`MCD_AX:	acc <= mc_alu_o[15:0];
	`MCD_TL:	tmp[7:0] <= alu_o[7:0];
	`MCD_TH:	tmp[15:8] <= alu_o[7:0];
	`MCD_TX:	tmp <= alu_o[15:0];
	`MCD_CF1:	cf <= 1'b1;
	`MCD_CF0:	cf <= 1'b0;
	endcase

always @(posedge clk)
if (storeres)
case(ir)
`SEC:	cf <= 1'b1;
`CLC:	cf <= 1'b0;
`CLD:	df <= 1'b0;
`SED:	df <= 1'b1;
`CLV:	vf <= 1'b0;
`SEI:	im <= 1'b1;
`CLI:	im <= 1'b0;
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
`TAS,`TXS: begin if (m816) sp <= res16[15:0]; else sp <= {8'h01,res8[7:0]}; end
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


endmodule

