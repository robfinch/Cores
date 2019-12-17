// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
// Micro-program for Gambit
//
parameter ZERO = 4'd0;
parameter ONE = 4'd1;
parameter TWO = 4'd2;
parameter THREE = 4'd3;
parameter FOUR = 4'd4;
parameter REF17 = 4'd5;
parameter REF4 = 4'd6;
parameter REF46 = 4'd7;
parameter REF23 = 4'd9;
parameter REF36	= 4'd10;
parameter REF7 = 4'd11;
parameter MFOUR = 4'd15;

parameter Rareg = 1;
parameter Rbreg = 1;
parameter Rtreg = 1;
parameter acc = 2;
parameter xr = 3;
parameter yr = 4;
parameter sp = 5;
parameter SP = 5;
parameter tmp1 = 6;
parameter TMP1 = 6;
parameter tmp2 = 7;
parameter TMP2 = 7;
parameter PC = 9;
parameter PC1 = 10;
parameter PC4 = 11;
parameter SR = 12;
parameter IFLAG = 13;

// Micro Instructions
parameter ADD = 6'd0;
parameter ADDu = 6'd1;
parameter SUB = 6'd2;
parameter SUBu = 6'd3;
parameter ANDu = 6'd4;
parameter ORu = 6'd5;
parameter EORu = 6'd6;
parameter LD = 6'd7;
parameter LDu = 6'd8;
parameter LDB = 6'd9;
parameter LDBu = 6'd10;
parameter ST = 6'd11;
parameter STB = 6'd12;
parameter ASLu = 6'd13;
parameter ROLu = 6'd14;
parameter LSRu = 6'd15;
parameter RORu = 6'd16;
parameter BRA = 6'd17;
parameter BEQ = 6'd18;
parameter BNE = 6'd19;
parameter BMI = 6'd20;
parameter BPL = 6'd21;
parameter BCS = 6'd22;
parameter BCC = 6'd23;
parameter BVS = 6'd24;
parameter BVC = 6'd25;
parameter SEP = 6'd26;
parameter REP = 6'd27;
parameter JMP = 6'd28;
parameter STP = 6'd29;
parameter WAI = 6'd30;
parameter CAUSE = 6'd31;
parameter BUC = 6'd32;
parameter BUS = 6'd33;

parameter ADD_RR = 1;
parameter ADD_RI23 = 2;
parameter ADD_RI36 = 3;
parameter SUB_RR = 4;
parameter SUB_RI23 = 5;
parameter SUB_RI36 = 6;
parameter AND_RR = 7;
parameter AND_RI23 = 8;
parameter AND_RI36 = 9;
parameter OR_RR = 10;
parameter OR_RI23 = 11;
parameter OR_RI36 = 12;
parameter EOR_RR = 13;
parameter EOR_RI23 = 14;
parameter EOR_RI36 = 15;
parameter ASL_RR = 16;
parameter ROL_RR = 17;
parameter LSR_RR = 18;
parameter ROR_RR = 19;
parameter MVNB = 20;
parameter MVPB = 26;
parameter STSB = 32;
parameter CMPSB = 36;
parameter MVN = 44;
parameter MVP = 50;
parameter STS = 56;
parameter CMPS = 60;
parameter JMP_R = 75;
parameter JMP_ABS = 76;
parameter JSR_R = 77;
parameter JSR_ABS = 80;
parameter RTS = 83;
parameter RTI = 86;
parameter NOP = 91;
parameter PFI_0 = 92;
parameter PFI_1 = 93;
parameter LSTP = 100;
parameter WAI_0 = 101;
parameter WAI_1 = 102;
parameter BRA_D4 = 109;
parameter BEQ_D4 = 110;
parameter BNE_D4 = 111;
parameter BCC_D4 = 112;
parameter BCS_D4 = 113;
parameter BMI_D4 = 114;
parameter BPL_D4 = 115;
parameter BVS_D4 = 116;
parameter BVC_D4 = 117;
parameter BUC_D4 = 118;
parameter BUS_D4 = 119;
parameter BRA_D17 = 120;
parameter BEQ_D17 = 121;
parameter BNE_D17 = 122;
parameter BCC_D17 = 123;
parameter BCS_D17 = 124;
parameter BMI_D17 = 125;
parameter BPL_D17 = 126;
parameter BVS_D17 = 127;
parameter BVC_D17 = 128;
parameter BUC_D17 = 129;
parameter BUS_D17 = 130;
parameter LD_D9 = 131;
parameter LD_D23 = 132;
parameter LD_D36 = 133;
parameter LDB_D36 = 134;
parameter ST_D9 = 135;
parameter ST_D23 = 136;
parameter ST_D36 = 137;
parameter STB_D36 = 138;
parameter POP = 139;
parameter PSH = 141;
parameter PLP = 143;
parameter PHP = 145;
parameter LSEP = 147;
parameter LREP = 148;
parameter UNIMP = 149;
parameter IRQ = 157;
parameter NMI = 165;
parameter RST = 173;
parameter BRK = 181;

MicroOp uop_prg [0:191] = {
{3, ADD, 0,0,0,0},
{3,	ADDu,	Rtreg,Rareg,Rbreg,0},
{3,	ADDu,	Rtreg,Rareg,0,REF23},
{3,	ADDu,	Rtreg,Rareg,0,REF36},
{3,	SUBu,	Rtreg,Rareg,Rbreg,0},
{3,	SUBu,	Rtreg,Rareg,0,REF23},
{3,	SUBu,	Rtreg,Rareg,0,REF36},
{3,	ANDu,	Rtreg,Rareg,Rbreg,0},
{3,	ANDu,	Rtreg,Rareg,0,REF23},
{3,	ANDu,	Rtreg,Rareg,0,REF36},
{3,	ORu,	Rtreg,Rareg,Rbreg,0},
{3,	ORu,	Rtreg,Rareg,0,REF23},
{3,	ORu,	Rtreg,Rareg,0,REF36},
{3,	EORu,	Rtreg,Rareg,Rbreg,0},
{3,	EORu,	Rtreg,Rareg,0,REF23},
{3,	EORu,	Rtreg,Rareg,0,REF36},
{3,	ASLu,	Rtreg,Rareg,Rbreg,0},
{3,	ROLu,	Rtreg,Rareg,Rbreg,0},
{3,	LSRu,	Rtreg,Rareg,Rbreg,0},
{3,	RORu,	Rtreg,Rareg,Rbreg,0},
// MVNB (20):
{1,	LDB,		tmp1,xr,0,0},
{0,	STB,		tmp1,yr,0,0},
{0,	ADD,		xr,xr,0,1},
{0,	ADD,		yr,yr,0,1},
{0,	SUB,		acc,acc,0,1},
{2,	BNE,		0,0,0,0},
// MVPB (26):
{1,	LDB,		tmp1,xr,0,0},
{0,	STB,		tmp1,yr,0,0},
{0,	SUB,		xr,xr,0,1},
{0,	SUB,		yr,yr,0,1},
{0,	SUB,		acc,acc,0,1},
{2,	BNE,		0,0,0,0},
// STSB (32):
{1,	STB,		xr,yr,0,0},
{0,	ADD,		yr,yr,0,1},
{0,	SUB,		acc,acc,0,1},
{2,	BNE,		0,0,0,0},
// CMPSB (36):
{1,	LDB,		tmp1,xr,0,0},
{0,	LDB,		tmp2,yr,0,0},
{0,	ADD,		xr,xr,0,1},
{0,	ADD,		yr,yr,0,1},
{0,	SUB,		acc,acc,0,1},
{0,	BEQ,		1,0,0,0},
{0, SUBu,		0,tmp1,tmp2,0},
{2,	BEQ,		0,0,0,0},
// MVN (44):
{1,	LD,			tmp1,xr,0,0},
{0,	ST,			tmp1,yr,0,0},
{0,	ADD,		xr,xr,0,4},
{0,	ADD,		yr,yr,0,4},
{0,	SUB,		acc,acc,0,1},
{2,	BNE,		0,0,0,0},
// MVP (50):
{1,	LD,			tmp1,xr,0,0},
{0,	ST,			tmp1,yr,0,0},
{0,	SUB,		xr,xr,0,4},
{0,	SUB,		yr,yr,0,4},
{0,	SUB,		acc,acc,0,1},
{2,	BNE,		0,0,0,0},
// STS(56):
{1,	STB,		xr,yr,0,0},
{0,	ADD,		yr,yr,0,4},
{0,	SUB,		acc,acc,0,1},
{2,	BNE,		0,0,0,0},
// CMPS (60):
{1,	LD,			tmp1,xr,0,0},
{0,	LD,			tmp2,yr,0,0},
{0,	ADD,		xr,xr,0,4},
{0,	ADD,		yr,yr,0,4},
{0,	SUB,		acc,acc,0,1},
{0, BEQ,		1,0,0,0},
{0,	SUBu,		0,tmp1,tmp2,0},
{2,	BEQ,		0,0,0,0},
// BRK (68):
{1,	SUB,		SP,SP,0,4},
{0,	ST,			PC1,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// JMP_R (75):
{3,	JMP,		0,Rareg,0,0},
// JMP_ABS (76):
{3,	JMP,		0,0,0,REF46},
// JSR_R (77):
{1,	SUB,		SP,SP,0,4},
{0,	ST,			PC1,SP,0,0},
{2,	JMP,		0,Rareg,0,0},
// JSR_ABS(80):
{1,	SUB,		SP,SP,0,4},
{0,	ST,			PC4,SP,0,0},
{2,	JMP,		0,0,0,REF46},
// RTS (83):
{1,	LD,			TMP1,SP,0,0},
{0,	ADD,		SP,SP,0,4},
{2,	JMP,		0,TMP1,0,0},
// RTI (86):
{1,	LD,			SR,SP,0,0},
{0,	ADD,		SP,SP,0,4},
{0,	LD,			TMP1,SP,0,0},
{0,	ADD,		SP,SP,0,4},
{2,	JMP,		0,TMP1,0,0},
// NOP (91):
{3,	ADD,		0,0,0,0},
//	PFI_0 (92):
{3,	ADD,		0,0,0,0},
// PFI_1 (93):
{1,	SUB,		SP,SP,0,4},
{0,	ST,			PC1,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// STP (100):
{3,	STP,		0,0,0,0},
// WAI_0 (101):
{3,	WAI,		0,0,0,0},
// WAI_1 (102):
{1,	SUB,		SP,SP,0,4},
{0,	ST,			PC1,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// BRA_D4 (109):
{3,	BRA,		0,0,0,REF4},
// BEQ_D4 (110):
{3,	BEQ,		0,0,0,REF4},	
// BNE_D4 (111):
{3,	BNE,		0,0,0,REF4},
// BCC_D4 (112):
{3,	BCC,		0,0,0,REF4},
// BCS_D4 (113):
{3,	BCS,		0,0,0,REF4},
// BMI_D4 (114):
{3,	BMI,		0,0,0,REF4},
// BPL_D4 (115):
{3,	BPL,		0,0,0,REF4},
// BVS_D4 (116):
{3,	BVS,		0,0,0,REF4},
// BVC_D4 (117):
{3,	BVC,		0,0,0,REF4},
// BUC_D4 (118)
{3,	BUC,		0,0,0,REF4},
// BUS_D4 (119)
{3,	BUS,		0,0,0,REF4},

// BRA_D17 (120):
{3,	BRA,		0,0,0,REF17},
// BEQ_D17 (121):
{3,	BEQ,		0,0,0,REF17},	
// BNE_D17 (122):
{3,	BNE,		0,0,0,REF17},
// BCC_D17 (123):
{3,	BCC,		0,0,0,REF17},
// BCS_D17 (124):
{3,	BCS,		0,0,0,REF17},
// BMI_D17 (125):
{3,	BMI,		0,0,0,REF17},
// BPL_D17 (126):
{3,	BPL,		0,0,0,REF17},
// BVS_D17 (127):
{3,	BVS,		0,0,0,REF17},
// BVC_D17 (128):
{3,	BVC,		0,0,0,REF17},
// BUC_D17 (129)
{3,	BUC,		0,0,0,REF17},
// BUS_D17 (130)
{3,	BUS,		0,0,0,REF17},
// LD_D9 (131):
{3,	LD,			Rtreg,Rareg,Rbreg,0},
// LD_D23 (132):
{3,	LD,			Rtreg,Rareg,0,REF23},
// LD_D36 (133):
{3,	LD,			Rtreg,Rareg,0,REF36},
// LDB_D36 (134):
{3,	LDB,		Rtreg,Rareg,0,REF36},
// ST_D9 (135):
{3,	ST,			Rtreg,Rareg,Rbreg,0},
// ST_D23 (136):
{3,	ST,			Rtreg,Rareg,0,REF23},
// STD_36 (137):
{3,	ST,			Rtreg,Rareg,0,REF36},
// STB_D36 (138):
{3,	STB,		Rtreg,Rareg,0,REF36},
// POP (139):
{1,	LD,			Rtreg,SP,0,0},
{2,	ADD,		SP,SP,0,4},
// PSH (141):
{1,	SUB,		SP,SP,0,4},
{2,	ST,			Rtreg,SP,0,0},
// PLP (143):
{1,	LD,			SR,SP,0,0},
{2,	ADD,		SP,SP,0,4},
// PHP (145):
{1,	SUB,		SP,SP,0,4},
{2,	ST,			SR,SP,0,0},
// LSEP (147):
{3,	SEP,		0,0,0,REF7},
// LREP (148):
{3,	REP,		0,0,0,REF7},
// UNIMP (149):
{1, CAUSE,	0,0,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			PC1,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// IRQ (157):
{1, CAUSE,	0,0,0,1},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			PC,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// NMI (165):
{1, CAUSE,	0,0,0,2},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			PC,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// RST (173):
{1, CAUSE,	0,0,0,3},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			PC,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0},
// BRK (181):
{1, CAUSE,	0,0,0,4},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			PC1,SP,0,0},
{0,	SUB,		SP,SP,0,4},
{0,	ST,			SR,SP,0,0},
{0,	SEP,		IFLAG,0,0,0},
{0,	LD,			TMP1,0,0,-4},
{2,	JMP,		0,TMP1,0,0}
};
