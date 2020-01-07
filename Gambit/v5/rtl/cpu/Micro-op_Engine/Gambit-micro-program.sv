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
// The first instruction of this table is a NOP by design so that when the 
// micro-program counters are zeroed out they will cause a fetch of the NOP
// instruction.
MicroOp uop_prg [0:`LAST_UOP] = '{
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
'{2'd3,	NOP,		ZERO,ZERO,ZERO,ZERO},
//	PFI_0 (92):
'{2'd3,	NOP,		ZERO,ZERO,ZERO,ZERO},
// PFI_1 (93):
'{2'd1,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
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
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
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

// BRA_DONE7 (120):
'{2'd3,	BRA,		ZERO,ZERO,ZERO,REF17},
// BEQ_DONE7 (121):
'{2'd3,	BEQ,		ZERO,ZERO,ZERO,REF17},	
// BNE_DONE7 (122):
'{2'd3,	BNE,		ZERO,ZERO,ZERO,REF17},
// BCC_DONE7 (123):
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
// ST_D9 (135):
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
// BRK (181):
'{2'd1, CAUSE,	ZERO,ZERO,ZERO,FOUR},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			PC1,SP,ZERO,ZERO},
'{2'd0,	SUB,		SP,SP,ZERO,FOUR},
'{2'd0,	ST,			SR,SP,ZERO,ZERO},
'{2'd0,	SEP,		IFLAG,ZERO,ZERO,ZERO},
'{2'd0,	LD,			TMP1,ZERO,ZERO,MFOUR},
'{2'd2,	JSI,		ZERO,TMP1,ZERO,ZERO},
// 
'{2'd3, NOP, 4'd0,4'd0,4'd0,4'd0},
'{2'd3, NOP, 4'd0,4'd0,4'd0,4'd0},
'{2'd3, NOP, 4'd0,4'd0,4'd0,4'd0},
'{2'd3, NOP, 4'd0,4'd0,4'd0,4'd0}
};
