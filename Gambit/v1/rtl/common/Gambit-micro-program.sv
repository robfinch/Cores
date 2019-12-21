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
parameter REF9 = 4'd8;
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
parameter JSI = 6'd34;
parameter NOP = 6'd35;

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
parameter LNOP = 91;
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

// The first instruction of this table is a NOP by design so that when the 
// micro-program counters are zeroed out they will cause a fetch of the NOP
// instruction.
MicroOp uop_prg [0:188] = '{
'{2'd3, NOP, 4'd0,4'd0,4'd0,4'd0},
'{2'd3,	ADDu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	ADDu,	Rtreg,Rareg,ZERO,REF23},
'{2'd3,	ADDu,	Rtreg,Rareg,ZERO,REF36},
'{2'd3,	SUBu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	SUBu,	Rtreg,Rareg,ZERO,REF23},
'{2'd3,	SUBu,	Rtreg,Rareg,ZERO,REF36},
'{2'd3,	ANDu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	ANDu,	Rtreg,Rareg,ZERO,REF23},
'{2'd3,	ANDu,	Rtreg,Rareg,ZERO,REF36},
'{2'd3,	ORu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	ORu,	Rtreg,Rareg,ZERO,REF23},
'{2'd3,	ORu,	Rtreg,Rareg,ZERO,REF36},
'{2'd3,	EORu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	EORu,	Rtreg,Rareg,ZERO,REF23},
'{2'd3,	EORu,	Rtreg,Rareg,ZERO,REF36},
'{2'd3,	ASLu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	ROLu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	LSRu,	Rtreg,Rareg,Rbreg,REF9},
'{2'd3,	RORu,	Rtreg,Rareg,Rbreg,REF9},
// MVNB (20):
'{2'd1,	LDB,		TMP1,xr,ZERO,ZERO},
'{2'd0,	STB,		TMP1,yr,ZERO,ZERO},
'{2'd0,	ADD,		xr,xr,ZERO,ONE},
'{2'd0,	ADD,		yr,yr,ZERO,ONE},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd2,	BNE,		ZERO,ZERO,ZERO,ZERO},
// MVPB (26):
'{2'd1,	LDB,		TMP1,xr,ZERO,ZERO},
'{2'd0,	STB,		TMP1,yr,ZERO,ZERO},
'{2'd0,	SUB,		xr,xr,ZERO,ONE},
'{2'd0,	SUB,		yr,yr,ZERO,ONE},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd2,	BNE,		ZERO,ZERO,ZERO,ZERO},
// STSB (32):
'{2'd1,	STB,		xr,yr,ZERO,ZERO},
'{2'd0,	ADD,		yr,yr,ZERO,ONE},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd2,	BNE,		ZERO,ZERO,ZERO,ZERO},
// CMPSB (36):
'{2'd1,	LDB,		TMP1,xr,ZERO,ZERO},
'{2'd0,	LDB,		tmp2,yr,ZERO,ZERO},
'{2'd0,	ADD,		xr,xr,ZERO,ONE},
'{2'd0,	ADD,		yr,yr,ZERO,ONE},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd0,	BEQ,		ONE,ZERO,ZERO,ZERO},
'{2'd0, SUBu,		ZERO,TMP1,tmp2,ZERO},
'{2'd2,	BEQ,		ZERO,ZERO,ZERO,ZERO},
// MVN (FOURFOUR):
'{2'd1,	LD,			TMP1,xr,ZERO,ZERO},
'{2'd0,	ST,			TMP1,yr,ZERO,ZERO},
'{2'd0,	ADD,		xr,xr,ZERO,FOUR},
'{2'd0,	ADD,		yr,yr,ZERO,FOUR},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd2,	BNE,		ZERO,ZERO,ZERO,ZERO},
// MVP (50):
'{2'd1,	LD,			TMP1,xr,ZERO,ZERO},
'{2'd0,	ST,			TMP1,yr,ZERO,ZERO},
'{2'd0,	SUB,		xr,xr,ZERO,FOUR},
'{2'd0,	SUB,		yr,yr,ZERO,FOUR},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd2,	BNE,		ZERO,ZERO,ZERO,ZERO},
// STS(56):
'{2'd1,	STB,		xr,yr,ZERO,ZERO},
'{2'd0,	ADD,		yr,yr,ZERO,FOUR},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd2,	BNE,		ZERO,ZERO,ZERO,ZERO},
// CMPS (60):
'{2'd1,	LD,			TMP1,xr,ZERO,ZERO},
'{2'd0,	LD,			tmp2,yr,ZERO,ZERO},
'{2'd0,	ADD,		xr,xr,ZERO,FOUR},
'{2'd0,	ADD,		yr,yr,ZERO,FOUR},
'{2'd0,	SUB,		acc,acc,ZERO,ONE},
'{2'd0, BEQ,		ONE,ZERO,ZERO,ZERO},
'{2'd0,	SUBu,		ZERO,TMP1,tmp2,ZERO},
'{2'd2,	BEQ,		ZERO,ZERO,ZERO,ZERO},
// BRK (68):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JMP,		ZERO,TMP1,ZERO,ZERO},
// JMP_R (75):
'{2'd3,	JMP,		ZERO,Rareg,ZERO,ZERO},
// JMP_ABS (76):
'{2'd3,	JMP,		ZERO,ZERO,ZERO,REF46},
// JSR_R (77):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd2,	JMP,		ZERO,Rareg,ZERO,ZERO},
// JSR_ABS(80):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC4,SP,ZERO,ZERO},
'{2'd2,	JMP,		ZERO,ZERO,ZERO,REF46},
// RTS (83):
'{2'd1,	LD,			TMP1,SP,ZERO,ZERO},
'{2'd0,	ADD,		SP,SP,ZERO,FOUR},
'{2'd2,	JMP,		ZERO,TMP1,ZERO,ZERO},
// RTI (86):
'{2'd1,	LD,			SR,SP,ZERO,ZERO},
'{2'd0,	ADD,		SP,SP,ZERO,FOUR},
'{2'd0,	LD,			TMP1,SP,ZERO,ZERO},
'{2'd0,	ADD,		SP,SP,ZERO,FOUR},
'{2'd2,	JMP,		ZERO,TMP1,ZERO,ZERO},
// NOP (9ONE):
'{2'd3,	ADD,		ZERO,ZERO,ZERO,ZERO},
//	PFI_0 (92):
'{2'd3,	ADD,		ZERO,ZERO,ZERO,ZERO},
// PFI_1 (93):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,-FOUR},
'{2'd2,	JMP,		ZERO,TMP1,ZERO,ZERO},
// STP (ONE00):
'{2'd3,	STP,		ZERO,ZERO,ZERO,ZERO},
// WAI_0 (ONE0ONE):
'{2'd3,	WAI,		ZERO,ZERO,ZERO,ZERO},
// WAI_1 (ONE02):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,-FOUR},
'{2'd2,	JMP,		ZERO,TMP1,ZERO,ZERO},
// BRA_DFOUR (ONE09):
'{2'd3,	BRA,		ZERO,ZERO,ZERO,REF4},
// BEQ_DFOUR (ONEONE0):
'{2'd3,	BEQ,		ZERO,ZERO,ZERO,REF4},	
// BNE_DFOUR (ONEONEONE):
'{2'd3,	BNE,		ZERO,ZERO,ZERO,REF4},
// BCC_DFOUR (ONEONE2):
'{2'd3,	BCC,		ZERO,ZERO,ZERO,REF4},
// BCS_DFOUR (ONEONE3):
'{2'd3,	BCS,		ZERO,ZERO,ZERO,REF4},
// BMI_DFOUR (ONEONEFOUR):
'{2'd3,	BMI,		ZERO,ZERO,ZERO,REF4},
// BPL_DFOUR (ONEONE5):
'{2'd3,	BPL,		ZERO,ZERO,ZERO,REF4},
// BVS_DFOUR (ONEONE6):
'{2'd3,	BVS,		ZERO,ZERO,ZERO,REF4},
// BVC_DFOUR (ONEONE7):
'{2'd3,	BVC,		ZERO,ZERO,ZERO,REF4},
// BUC_DFOUR (ONEONE8)
'{2'd3,	BUC,		ZERO,ZERO,ZERO,REF4},
// BUS_DFOUR (ONEONE9)
'{2'd3,	BUS,		ZERO,ZERO,ZERO,REF4},

// BRA_DONE7 (ONE20):
'{2'd3,	BRA,		ZERO,ZERO,ZERO,REF17},
// BEQ_DONE7 (ONE2ONE):
'{2'd3,	BEQ,		ZERO,ZERO,ZERO,REF17},	
// BNE_DONE7 (ONE22):
'{2'd3,	BNE,		ZERO,ZERO,ZERO,REF17},
// BCC_DONE7 (ONE23):
'{2'd3,	BCC,		ZERO,ZERO,ZERO,REF17},
// BCS_DONE7 (ONE2FOUR):
'{2'd3,	BCS,		ZERO,ZERO,ZERO,REF17},
// BMI_DONE7 (ONE25):
'{2'd3,	BMI,		ZERO,ZERO,ZERO,REF17},
// BPL_DONE7 (ONE26):
'{2'd3,	BPL,		ZERO,ZERO,ZERO,REF17},
// BVS_DONE7 (ONE27):
'{2'd3,	BVS,		ZERO,ZERO,ZERO,REF17},
// BVC_DONE7 (ONE28):
'{2'd3,	BVC,		ZERO,ZERO,ZERO,REF17},
// BUC_DONE7 (ONE29)
'{2'd3,	BUC,		ZERO,ZERO,ZERO,REF17},
// BUS_DONE7 (ONE3ZERO)
'{2'd3,	BUS,		ZERO,ZERO,ZERO,REF17},
// LD_D9 (ONE3ONE):
'{2'd3,	LD,			Rtreg,Rareg,Rbreg,REF9},
// LD_D23 (ONE32):
'{2'd3,	LD,			Rtreg,Rareg,ZERO,REF23},
// LD_D36 (ONE33):
'{2'd3,	LD,			Rtreg,Rareg,ZERO,REF36},
// LDB_D36 (ONE3FOUR):
'{2'd3,	LDB,		Rtreg,Rareg,ZERO,REF36},
// ST_D9 (ONE35):
'{2'd3,	ST,			Rtreg,Rareg,Rbreg,REF9},
// ST_D23 (ONE36):
'{2'd3,	ST,			Rtreg,Rareg,ZERO,REF23},
// STD_36 (ONE37):
'{2'd3,	ST,			Rtreg,Rareg,ZERO,REF36},
// STB_D36 (ONE38):
'{2'd3,	STB,		Rtreg,Rareg,ZERO,REF36},
// POP (ONE39):
'{2'd1,	LD,			Rtreg,SP,ZERO,ZERO},
'{2'd2,	ADD,		SP,SP,ZERO,FOUR},
// PSH (ONEFOURONE):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd2,	ST,			Rtreg,SP,ZERO,ZERO},
// PLP (ONEFOUR3):
'{2'd1,	LD,			SR,SP,ZERO,ZERO},
'{2'd2,	ADD,		SP,SP,ZERO,FOUR},
// PHP (ONEFOUR5):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd2,	ST,			SR,SP,ZERO,ZERO},
// LSEP (ONEFOUR7):
'{2'd3,	SEP,		ZERO,ZERO,ZERO,REF7},
// LREP (ONEFOUR8):
'{2'd3,	REP,		ZERO,ZERO,ZERO,REF7},
// UNIMP (ONEFOUR9):
'{2'd1, CAUSE,	ZERO,ZERO,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JSI,		ZERO,TMP1,ZERO,ZERO},
// IRQ (ONE57):
'{2'd1, CAUSE,	ZERO,ZERO,ZERO,ONE},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JSI,		ZERO,TMP1,ZERO,ZERO},
// NMI (ONE65):
'{2'd1, CAUSE,	ZERO,ZERO,ZERO,TWO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JSI,		ZERO,TMP1,ZERO,ZERO},
// RST (ONE73):
'{2'd1, CAUSE,	ZERO,ZERO,ZERO,THREE},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JSI,		ZERO,TMP1,ZERO,ZERO},
// BRK (ONE8ONE):
'{2'd1, CAUSE,	ZERO,ZERO,ZERO,FOUR},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JSI,		ZERO,TMP1,ZERO,ZERO}
};
