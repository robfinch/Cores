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
`include ".\nvio3-config.sv"
`include ".\nvio3-defines.sv"

module idecoder(instr,predict_taken,Rt,Rd2,bus,debug_on);
input [39:0] instr;
input predict_taken;
input [5:0] Rt;
input [5:0] Rd2;
output reg [`IBTOP:0] bus;
input debug_on;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter penta = 3'd3;
parameter octa = 3'd4;
parameter hexi = 3'd5;

// Really IsPredictableBranch
// Does not include BccR's
//function IsBranch;
//input [47:0] isn;
//casez(isn[`INSTRUCTION_OP])
//`Bcc:   IsBranch = TRUE;
//`BBc:   IsBranch = TRUE;
//`BEQI:  IsBranch = TRUE;
//`CHK:   IsBranch = TRUE;
//default:    IsBranch = FALSE;
//endcase
//endfunction

function [6:0] fnRd;
input [39:0] ins;
casez(ins[`OPCODE])
8'h1A:			fnRd = 7'd121;// LDCR
`JSR:			fnRd = {4'b1100,ins[`RD3]};
`RTS:				fnRd = {2'b00,ins[`RD]};
`BMISC2:
	case(ins[`BFUNCT4])
	`SEI: fnRd = {2'b0,ins[`RD]};
	`MTL:	fnRd = {2'b11,ins[`RD]};				// MTM and MTL
	`CRLOG:	fnRd = {4'b1110,ins[13:11]};	// CRLOG (for dependency check)
	default: fnRd = 7'd0;
	endcase
8'b10??????:
	case(ins[`OPCODE])
	`CMPI,`CMPUI:	fnRd = {4'b1110,ins[`RD3]};
	`R2,`R2S:
		case(ins[`FUNCT6])
		`CMP,`CMPU:	fnRd = {4'b1110,ins[`RD3]};
		default:
			fnRd = {2'b0,ins[`RD]};	// ALU
		endcase
	default:
		fnRd = {2'b0,ins[`RD]};	// ALU
	endcase
8'hE1:
	case(ins[`FUNCT6])
	`FTOI:	fnRd = {2'b0,ins[`RD]};
	default:	fnRd = {2'b01,ins[`RD]};
	endcase
`FLT2,`FLT2S:
	case(ins[`FFUNCT5])
	`FCMP,`FCMPM:	fnRd = {4'b1110,ins[`RD3]};
	default:
		fnRd = {2'b01,ins[`RD]};
	endcase
8'hE3,8'hE4,8'hE5,8'hE6,8'hE7:
		fnRd = {2'b01,ins[`RD]};
8'h2D:	fnRd = {2'b00,ins[`RD]};	// TLB
8'b0?,8'h1?:
				fnRd = {2'b00,ins[`RD]};	// MLD
`STORE:
	case(ins[`OPCODE])
	`PUSH,`PUSHC:	fnRd = {2'b0,ins[`RD]};
	default:	fnRd = 7'd0;
	endcase
8'h4?,8'h5?:
				fnRd = {2'b10,ins[`RD]};	// VMLD
default:	fnRd = 7'd0;
endcase
endfunction


function [6:0] fnRd2;
input [39:0] ins;
casez(ins[`OPCODE])
`POP:			fnRd2 = {1'b0,ins[`RS1]};
8'b0???????:
	case(ins[`AM])
	2'd1:	fnRd2 = {2'b00,ins[`RS1]};
	2'd2:	fnRd2 = {2'b00,ins[`RS1]};
	2'd3:
		case(ins[`AMX])
		2'd1:	fnRd2 = {2'b00,ins[`RS1]};
		2'd2:	fnRd2 = {2'b00,ins[`RS1]};
		default:	fnRd2 = 7'd0;
		endcase
	default:	fnRd2 = 7'd0;
	endcase
default:	fnRd2 = 7'd0;
endcase
endfunction

function fnZ;
input [39:0] ins;
casez(ins[`OPCODE])
8'b10??????:	fnZ=ins[36];
8'hEx:	fnZ = ins[27];
default:	fnZ = 0;
endcase
endfunction

function IsAndi;
input [39:0] isn;
IsAndi = isn[`OPCODE]==`ANDI;
endfunction

function IsOri;
input [39:0] isn;
IsOri = isn[`OPCODE]==`ORI;
endfunction

function IsXori;
input [39:0] isn;
IsXori = isn[`OPCODE]==`XORI;
endfunction

function IsVSet;
input [39:0] isn;
IsVSet = (isn[`OPCODE]==`R2 || isn[`OPCODE]==`R2S) && (isn[`FUNCT6] >= `SLT && isn[`FUNCT6] <= `SNE);
endfunction

function IsTLB;
input [39:0] isn;
IsTLB = isn[`OPCODE]==`TLB;
endfunction

function IsAMO;
input [39:0] isn;
casez(isn[`OPCODE])
`AMO:	IsAMO = TRUE;
default:	IsAMO = FALSE;
endcase
endfunction

// fnCanException
//
// Used by memory issue logic (stores).
// Returns TRUE if the instruction can cause an exception.
// In debug mode any instruction could potentially cause a breakpoint exception.
// Rather than check all the addresses for potential debug exceptions it's
// simpler to just have it so that all instructions could exception. This will
// slow processing down somewhat as stores will only be done at the head of the
// instruction queue, but it's debug mode so we probably don't care.
//
function fnCanException;
input [39:0] isn;
begin
// ToDo add debug_on as input
`ifdef SUPPORT_DBG
if (debug_on)
    fnCanException = `TRUE;
else
`endif
case(isn[`OPCODE])
`FMA,`FMS,`FNMA,`FNMS:
	fnCanException = TRUE;
`FLT2,`FLT2I:
	case({isn[`FFUNCT5]})
  `FDIV,`FMUL,`FADD,`FSUB,`FTX:
     fnCanException = `TRUE;
  default:    fnCanException = FALSE;
	endcase
`DIVI,`MODI,`MULI:
  fnCanException = `TRUE;
`CHK:	fnCanException = TRUE;
`CHKI:		fnCanException = TRUE;
`R2,`R2S:
	case(isn[`FUNCT6])
  `MUL,`DIV,`MOD:
     fnCanException = TRUE;
  default:    fnCanException = FALSE;
	endcase
`BMISC:
	case(isn[`BFUNCT4])
	`BRK:	fnCanException = TRUE;
  default:    fnCanException = FALSE;
	endcase
// Stores can stil exception if there is a write buffer, but we allow following
// stores to be issued by ignoring the fact they can exception because the stores
// can be undone by invalidating the write buffer.
8'b0???????:
	fnCanException = TRUE;
default:
	fnCanException = FALSE;
endcase
end
endfunction

function IsPush;
input [39:0] isn;
IsPush = isn[`OPCODE]==`PUSH || isn[`OPCODE]==`PUSHC;
endfunction

function IsPushc;
input [39:0] isn;
IsPushc = isn[`OPCODE]==`PUSHC;
endfunction

function IsPop;
input [39:0] isn;
IsPop = isn[`OPCODE]==`POP;
endfunction

function IsMemNdx;
input [39:0] isn;
IsMemNdx = !isn[7] && isn[`AM]==2'd3;
endfunction

function HasMemRes2;
input [39:0] inst;
casez(inst[`OPCODE])
8'b0???????:
	casez(inst[`OPCODE])
	`LEA:		HasMemRes2 = TRUE;
	`PUSH:	HasMemRes2 = TRUE;
	`PUSHC:	HasMemRes2 = TRUE;
	`POP:		HasMemRes2 = TRUE;
	`UNLK:	HasMemRes2 = TRUE;
	`LINK:	HasMemRes2 = TRUE;
	default:
		case(inst[`AM])
		2'd1:	HasMemRes2 = TRUE;
		2'd2:	HasMemRes2 = TRUE;
		2'd3:	
			case(inst[`AMX])
			2'd1:	HasMemRes2 = TRUE;
			2'd2:	HasMemRes2 = TRUE;
			default:	HasMemRes2 = FALSE;
			endcase
		default:	HasMemRes2 = FALSE;
		endcase
	endcase
default:	HasMemRes2 = FALSE;
endcase
endfunction

function [2:0] MemSize;
input [39:0] isn;
casez(isn[`OPCODE])
`LDB:	MemSize = byt;
`LDW:	MemSize = wyde;
`LDP:	MemSize = penta;
`LDH:	MemSize = hexi;
`LDBU:	MemSize = byt;
`LDWU:	MemSize = wyde;
`LDPU:	MemSize = penta;
`LDHR:	MemSize = hexi;
`LDT:	MemSize = tetra;
`LDO:	MemSize = octa;
`LDTU:	MemSize = tetra;
`LDOU:	MemSize = octa;
`LDFD:	MemSize = octa;
`LDFQ:	MemSize = hexi;
`LEA:	MemSize = hexi;
`POP:	MemSize = hexi;
`STB:	MemSize = byt;
`STW:	MemSize = wyde;
`STP:	MemSize = penta;
`STH:	MemSize = hexi;
`STT:	MemSize = tetra;
`STO:	MemSize = octa;
`STHC:	MemSize = hexi;
`STFD:	MemSize = octa;
`STFQ:	MemSize = hexi;
`PUSH:	MemSize = hexi;
`PUSHC:	MemSize = hexi;
default:	MemSize = hexi;
endcase
endfunction

function IsCache;
input [39:0] isn;
IsCache = isn[`OPCODE]==`CACHE;
endfunction

function IsJsr;
input [39:0] isn;
IsJsr = isn[`OPCODE]==`JSR;
endfunction

function IsCAS;
input [39:0] isn;
IsCAS = isn[`OPCODE]==`CAS;
endfunction

function IsChki;
input [39:0] isn;
IsChki = isn[`OPCODE]==`CHKI;
endfunction

function IsChk;
input [39:0] isn;
IsChk = isn[`OPCODE]==`CHK || IsChki(isn);
endfunction

function IsFSync;
input [39:0] isn;
IsFSync = isn[`OPCODE]==`FLT2 && isn[`FFUNCT5]==`FSYNC; 
endfunction

function IsMemdb;
input [39:0] isn;
IsMemdb = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`MEMDB;
endfunction

function IsMemsb;
input [39:0] isn;
IsMemsb = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`MEMSB;
endfunction

function IsSEI;
input [39:0] isn;
IsSEI = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`SEI;
endfunction

function IsWait;
input [39:0] isn;
IsWait = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`WAIT;
endfunction

function IsLea;
input [39:0] isn;
IsLea = isn[`OPCODE]==`LEA;
endfunction

function IsLWRX;
input [39:0] isn;
IsLWRX = isn[`OPCODE]==`LDHR;
endfunction

// Aquire / release bits are only available on indexed SWC / LWR
function IsSWCX;
input [39:0] isn;
IsSWCX = isn[`OPCODE]==`STHC;
endfunction

function IsJmp;
input [39:0] isn;
IsJmp = isn[`OPCODE]==`JSR && isn[`RD3]==3'd0;
endfunction

function IsCSR;
input [39:0] isn;
IsCSR = isn[`OPCODE]==`CSRRW;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [39:0] isn;
case(isn[`OPCODE])
`BRANCH:
	IsBranch = TRUE;
default:
	IsBranch = FALSE;
endcase
endfunction

function IsJRL;
input [39:0] isn;
IsJRL = isn[`OPCODE]==`JRL;
endfunction

function IsRts;
input [39:0] isn;
IsRts = isn[`OPCODE]==`RTS;
endfunction

function IsIrq;
input [39:0] isn;
IsIrq = isn[`OPCODE]==`BMISC && isn[`BFUNCT4]==`BRK && isn[39];
endfunction

function IsBrk;
input [39:0] isn;
IsBrk = isn[`OPCODE]==`BMISC && isn[`BFUNCT4]==`BRK;
endfunction

function IsRti;
input [39:0] isn;
IsRti = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`RTI;
endfunction

function IsSei;
input [39:0] isn;
IsSei = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`SEI;
endfunction

function IsSync;
input [39:0] isn;
IsSync = (isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`SYNC) || IsRti(isn);
endfunction

function IsRex;
input [39:0] isn;
IsRex = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`REX;
endfunction

function IsOddball;
input [39:0] instr;
IsOddball = IsRti(instr) || IsSei(instr) || IsCache(instr)
						|| IsCSR(instr) || IsRex(instr) || instr[39:36]==4'hE;	// Float instructions
endfunction
    
function IsRFW;
input [39:0] isn;
if ((fnRd(isn)==7'd0 || fnRd(isn)==7'd32) && (fnRd2(isn)==7'd0 || fnRd2(isn)==7'd32))
    IsRFW = FALSE;
else
casez(isn[`OPCODE])
// BUnit:
`BMISC:	
	case(isn[`BFUNCT4])
	`SEI:	IsRFW = TRUE;
	`MTL:	IsRFW = TRUE;
	`MFL:	IsRFW = TRUE;
	default:	IsRFW = FALSE;
	endcase	
`JRL:     IsRFW = TRUE;
`JSR:     IsRFW = TRUE;  
`RTS:     IsRFW = TRUE; 
// IUnit
8'h8?,8'h9?,8'hA?,8'hB?:
	IsRFW = !IsChk(isn);
// FUnit:
8'hE?:
	case(isn[`OPCODE])
	`FLT1:
		case(isn[`FFUNCT5])
		`FTX:		IsRFW = FALSE;
		`FCX:		IsRFW = FALSE;
		`FEX:		IsRFW = FALSE;
		`FDX:		IsRFW = FALSE;
		`FRM:		IsRFW = FALSE;
		`FSYNC:	IsRFW = FALSE;
		default:	IsRFW = TRUE;
		endcase
	default:	IsRFW = TRUE;
	endcase
// MUnit
8'b0???????:	// Memory
	casez(isn[`OPCODE])
	8'h0?,8'h1?,8'h4?,8'h5?:	IsRFW = TRUE;
	`TLB:		IsRFW = TRUE;
	`PUSH:	IsRFW = TRUE;
	`PUSHC:	IsRFW = TRUE;
	`CAS:		IsRFW = TRUE;
	default:
		if (isn[`AM]==2'b01 || isn[`AM]==2'b10 ||
			  (isn[`AM]==2'b11 && (isn[`AMX]==2'b01 || isn[`AMX]==2'b10)))
			IsRFW = TRUE;
		else
			IsRFW = FALSE;
	endcase
default: IsRFW = FALSE;
endcase
endfunction


function HasConst;
input [39:0] ins;
casez(ins[`OPCODE])
`ADDI:	HasConst = TRUE;
`ANDI:	HasConst = TRUE;
`ORI:		HasConst = TRUE;
`XORI:	HasConst = TRUE;
`MULI,`MULUI,`MULSUI:
				HasConst = TRUE;
`DIVI,`DIVUI,`DIVSUI:
				HasConst = TRUE;
`MODI,`MODUI,`MODSUI:
				HasConst = TRUE;
`CHKI:	HasConst = TRUE;
`JRL:		HasConst = TRUE;
8'b0???????:
	case(ins[`OPCODE])
	`PUSH:	HasConst = FALSE;
	`PUSHC:	HasConst = TRUE;
	`POP:		HasConst = FALSE;
	`LINK:	HasConst = FALSE;
	`LDST:	HasConst = FALSE;
	`STST:	HasConst = FALSE;
	`TLB:		HasConst = FALSE;
	default:
		if (ins[`AM]!=2'd0)
			HasConst = FALSE;
		else
			HasConst = TRUE;
	endcase
default:	HasConst = FALSE;
endcase
endfunction

function IsAlu0Only;
input [39:0] ins;
casez(ins[`OPCODE])
`CSRRW:	IsAlu0Only = TRUE;
default:	IsAlu0Only = FALSE;
endcase
endfunction

wire isRts = IsRts(instr);
wire isJrl = IsJRL(instr);
wire isBrk = IsBrk(instr);
wire isRti = IsRti(instr);

always @*
begin
	bus <= 1'h0;
	bus[`IB_CMP] <= 1'b0;//IsCmp(instr);
	casez(instr[`OPCODE])
	`PUSHC: bus[`IB_CONST] <= {{107{instr[38]}},instr[38:18]};
	`STORE:	bus[`IB_CONST] <= {{110{instr[35]}},instr[35:23],instr[4:0]};
	`LOAD:	bus[`IB_CONST] <= {{110{instr[35]}},instr[35:18]};
	`JRL:		bus[`IB_CONST] <= {{110{instr[38]}},instr[38:21]};
	`CHKI:	bus[`IB_CONST] <= {{107{instr[38]}},instr[38:23],instr[4:0]};
	default:	bus[`IB_CONST] <= {{107{instr[38]}},instr[38:18]};
	endcase
//	bus[`IB_RT]		 <= fnRd(instr,ven,vl,thrd) | {thrd,7'b0};
//	bus[`IB_RC]		 <= fnRc(instr,ven,thrd) | {thrd,7'b0};
//	bus[`IB_RA]		 <= fnRa(instr,ven,vl,thrd) | {thrd,7'b0};
	bus[`IB_RS1]		 <= instr[`RS1];
	bus[`IB_RS2]		 <= instr[`RS2];
	bus[`IB_RS3]		 <= instr[`RS3];
	bus[`IB_IMM]	 <= HasConst(instr);
//	bus[`IB_A3V]   <= Source3Valid(instr);
//	bus[`IB_A2V]   <= Source2Valid(instr);
//	bus[`IB_A1V]   <= Source1Valid(instr);
	bus[`IB_TLB]	 <= IsTLB(instr);
	bus[`IB_FMT]   <= instr[32:29];	// 3'd3=word size
	bus[`IB_Z]		 <= fnZ(instr);
	bus[`IB_VSET]  <= IsVSet(instr);
	bus[`IB_IRQ]	 <= IsIrq(instr);
	bus[`IB_BRK]	 <= isBrk;
	bus[`IB_RTI]	 <= isRti;
	bus[`IB_JSR]	 <= IsJsr(instr);
	bus[`IB_RTS]	 <= isRts;
	bus[`IB_JRL]	 <= isJrl;
	bus[`IB_REX]	 <= IsRex(instr);
	bus[`IB_WAIT]	 <= IsWait(instr);
	bus[`IB_CHK]	 <= IsChk(instr);
	// IB_BT is now used to indicate when to update the branch target buffer.
	// This occurs when one of the instructions with an unknown or calculated
	// target is present.
	bus[`IB_BT]		 <= isJrl | isRts | isBrk | isRti;
	bus[`IB_ALU]   <= instr[7:6]==2'b10;
	bus[`IB_ALU0]	 <= IsAlu0Only(instr);
	bus[`IB_FPU]   <= instr[7:4]==4'hE;
	bus[`IB_FC]		 <= instr[7:5]==3'h6;
	bus[`IB_CANEX] <= fnCanException(instr);
	bus[`IB_LEA]	 <= IsLea(instr);
	bus[`IB_LOAD]	 <= !instr[7] && !instr[5] && !IsPushc(instr);
	bus[`IB_PRELOAD] <= !instr[7] && !instr[5] && Rt==5'd0 && Rd2==5'd0;
	bus[`IB_STORE]	<= (!instr[7] && instr[5]) || IsPushc(instr);
	bus[`IB_PUSH]   <= IsPush(instr)|IsPushc(instr);
	bus[`IB_PUSHC]   <= IsPushc(instr);
	bus[`IB_POP]		<= IsPop(instr);
	bus[`IB_MEM2]		<= HasMemRes2(instr);
	bus[`IB_ODDBALL] <= IsOddball(instr);
	bus[`IB_MEMSZ]  <= MemSize(instr);
	bus[`IB_MEM]		<= !instr[7];
	bus[`IB_MEMNDX]	<= IsMemNdx(instr);
	bus[`IB_RMW]		<= IsCAS(instr);// || IsInc(instr);
	bus[`IB_MEMDB]	<= IsMemdb(instr);
	bus[`IB_MEMSB]	<= IsMemsb(instr);
	bus[`IB_SEI]		<= IsSEI(instr);
	bus[`IB_AQ]			<= instr[32] && IsAMO(instr);
	bus[`IB_RL]			<= instr[31] && IsAMO(instr);
	bus[`IB_JMP]		<= IsJmp(instr);
	bus[`IB_BR]			<= IsBranch(instr);
	bus[`IB_SYNC]		<= IsSync(instr)|| isBrk || isRti;
	bus[`IB_FSYNC]	<= IsFSync(instr);
	bus[`IB_RFW]		<= (Rt==6'd0) && (Rd2==6'd0) ? 1'b0 : IsRFW(instr);
end

endmodule

