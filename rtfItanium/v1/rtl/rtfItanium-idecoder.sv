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
`include ".\rtfItanium-config.sv"
`include ".\rtfItanium-defines.sv"

module idecoder(unit,instr,predict_taken,Rt,bus,debug_on);
input [2:0] unit;
input [39:0] instr;
input predict_taken;
input [5:0] Rt;
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
parameter deci = 3'd5;

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

function [5:0] mopcode;
input [39:0] ins;
mopcode = {ins[34:33],ins[9:6]};
endfunction

function [6:0] fnRt;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:
	case(ins[`OPCODE4])
	`JAL:		fnRt = {1'b0,ins[`RD]};
	`RET:		fnRt = {1'b0,ins[`RD]};
	`BMISC:		fnRt = ins[`FUNCT5]==`SEI ? {1'b0,ins[`RD]} : 7'd0;
	default:	fnRt = 7'd0;
	endcase
`IUnit:	fnRt = {1'b0,ins[`RD]};
`FUnit:	fnRt = {1'b1,ins[`RD]};
`MUnit: 
	casez(mopcode(ins))
	`LOAD:	
		case(mopcode(ins))
		`LDFS,`LDFD:	fnRt = {1'b1,ins[`RD]};
		default:	fnRt = {1'b0,ins[`RD]};
		endcase
	`PUSH:	fnRt = {1'b0,ins[`RD]};
	`PUSHC:	fnRt = {1'b0,ins[`RD]};
	`TLB:		fnRt = {1'b0,ins[`RD]};
	default:	fnRt = 7'd0;
	endcase
default:	fnRt = 7'd0;
endcase
endfunction


function IsAndi;
input [2:0] unit;
input [39:0] isn;
IsAndi = unit==`IUnit && ({isn[32:31],isn[`OPCODE4]}==`ANDI
												|| {isn[32:31],isn[`OPCODE4]}==`ANDS1
												|| {isn[32:31],isn[`OPCODE4]}==`ANDS2
												|| {isn[32:31],isn[`OPCODE4]}==`ANDS3
												);
endfunction

function IsOri;
input [2:0] unit;
input [39:0] isn;
IsOri = unit==`IUnit && ({isn[32:31],isn[`OPCODE4]}==`ORI
												|| {isn[32:31],isn[`OPCODE4]}==`ORS1
												|| {isn[32:31],isn[`OPCODE4]}==`ORS2
												|| {isn[32:31],isn[`OPCODE4]}==`ORS3
												);
endfunction

function IsXori;
input [2:0] unit;
input [39:0] isn;
IsXori = unit==`IUnit && ({isn[32:31],isn[`OPCODE4]}==`XORI);
endfunction

function IsTLB;
input [2:0] unit;
input [39:0] isn;
IsTLB = unit==`MUnit && mopcode(isn)==`TLB;
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
input [2:0] unit;
input [39:0] isn;
begin
// ToDo add debug_on as input
`ifdef SUPPORT_DBG
if (debug_on)
    fnCanException = `TRUE;
else
`endif
case(unit)
`FUnit:
	case({isn[9:6]})
	4'h2:
		case({isn[27:22]})
    `FDIV,`FMUL,`FADD,`FSUB,`FTX:
        fnCanException = `TRUE;
    default:    fnCanException = FALSE;
		endcase
	4'h4,4'h5,4'h6,4'h7:
        fnCanException = `TRUE;
  default:    fnCanException = FALSE;
	endcase
`IUnit:
	casez({isn[32:31],isn[9:6]})
	`DIVI,`MODI,`MULI:
    fnCanException = `TRUE;
  `R3:
		case({isn[39:35],isn[6]})
    `MUL,`DIV,`MOD:
       fnCanException = TRUE;
	  default:    fnCanException = FALSE;
		endcase
	endcase
`BUnit:
	case(isn[9:6])
	`BRK:	fnCanException = TRUE;
	`CHK:	fnCanException = TRUE;
	`CHKI:		fnCanException = TRUE;
  default:    fnCanException = FALSE;
	endcase
// Stores can stil exception if there is a write buffer, but we allow following
// stores to be issued by ignoring the fact they can exception because the stores
// can be undone by invalidating the write buffer.
`MUnit:
	fnCanException = TRUE;
default:
	fnCanException = FALSE;
endcase
end
endfunction

function IsPush;
input [2:0] unit;
input [39:0] isn;
IsPush = unit==`MUnit && (mopcode(isn)==`PUSH || mopcode(isn)==`PUSHC);
endfunction

function IsPushc;
input [2:0] unit;
input [39:0] isn;
IsPushc = unit==`MUnit && mopcode(isn)==`PUSHC;
endfunction

function IsMemNdx;
input [2:0] unit;
input [39:0] isn;
IsMemNdx = (unit==`MUnit && mopcode(isn)==`MLX) || (unit==`MUnit && mopcode(isn)==`MSX);
endfunction

function [2:0] MemSize;
input [2:0] unit;
input [39:0] isn;
case(unit)
`MUnit:
	casez(mopcode(isn))
	`LDB:	MemSize = byt;
	`LDC:	MemSize = wyde;
	`LDP:	MemSize = penta;
	`LDD:	MemSize = deci;
	`LDBU:	MemSize = byt;
	`LDCU:	MemSize = wyde;
	`LDPU:	MemSize = penta;
	`LDDR:	MemSize = deci;
	`LDT:	MemSize = tetra;
	`LDO:	MemSize = octa;
	`LDTU:	MemSize = tetra;
	`LDOU:	MemSize = octa;
	`LEA:	MemSize = deci;
	`MLX:
		case(isn[`FUNCT5])
		`LDB:	MemSize = byt;
		`LDC:	MemSize = wyde;
		`LDP:	MemSize = penta;
		`LDD:	MemSize = deci;
		`LDBU:	MemSize = byt;
		`LDCU:	MemSize = wyde;
		`LDPU:	MemSize = penta;
		`LDDR:	MemSize = deci;
		`LDT:	MemSize = tetra;
		`LDO:	MemSize = octa;
		`LDTU:	MemSize = tetra;
		`LDOU:	MemSize = octa;
		default:	MemSize = deci;
		endcase
	`STB:	MemSize = byt;
	`STC:	MemSize = wyde;
	`STP:	MemSize = penta;
	`STD:	MemSize = deci;
	`STT:	MemSize = tetra;
	`STO:	MemSize = octa;
	`STDC:	MemSize = deci;
	`PUSH:	MemSize = deci;
	`PUSHC:	MemSize = deci;
	`MSX:
		case(isn[`FUNCT5])
		`STB:	MemSize = byt;
		`STC:	MemSize = wyde;
		`STP:	MemSize = penta;
		`STD:	MemSize = deci;
		`STT:	MemSize = tetra;
		`STO:	MemSize = octa;
		`STDC:	MemSize = deci;
		default:	MemSize = deci;
		endcase
	default:	MemSize = deci;
	endcase
default:	MemSize = deci;
endcase
endfunction

function IsCache;
input [2:0] unit;
input [39:0] isn;
IsCache = unit==`MUnit && (mopcode(isn)==`CACHE || (mopcode(isn)==`MSX && isn[`FUNCT5]==`CACHEX));
endfunction

function IsCall;
input [2:0] unit;
input [39:0] isn;
IsCall = unit==`BUnit && isn[`OPCODE4]==`CALL;
endfunction

function IsCAS;
input [2:0] unit;
input [39:0] isn;
IsCAS = unit==`MUnit && (mopcode(isn)==`CAS || (mopcode(isn)==`MSX && isn[`FUNCT5]==`CASX));
endfunction

function IsChki;
input [2:0] unit;
input [39:0] isn;
IsChki = unit==`BUnit && isn[`OPCODE4]==`CHKI;
endfunction

function IsChk;
input [2:0] unit;
input [39:0] isn;
IsChk = unit==`BUnit && (isn[`OPCODE4]==`CHK || isn[`OPCODE4]==`CHKI);
endfunction

function IsFSync;
input [2:0] unit;
input [39:0] isn;
IsFSync = unit==`FUnit && isn[`OPCODE4]==`FLT2 && isn[`FUNCT5]==`FSYNC; 
endfunction

function IsMemdb;
input [2:0] unit;
input [39:0] isn;
IsMemdb = unit==`MUnit && mopcode(isn)==`MSX && isn[`FUNCT5]==`MEMDB;
endfunction

function IsMemsb;
input [2:0] unit;
input [39:0] isn;
IsMemsb = unit==`MUnit && mopcode(isn)==`MSX && isn[`FUNCT5]==`MEMSB;
endfunction

function IsSEI;
input [2:0] unit;
input [39:0] isn;
IsSEI = unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`SEI;
endfunction

function IsWait;
input [2:0] unit;
input [39:0] isn;
IsWait = unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`WAIT;
endfunction

function IsLea;
input [2:0] unit;
input [39:0] isn;
IsLea = unit==`MUnit && (mopcode(isn)==`LEA || (mopcode(isn)==`MLX && isn[`FUNCT5]==`LEAX));
endfunction

function IsLWRX;
input [2:0] unit;
input [39:0] isn;
IsLWRX = unit==`MUnit && (mopcode(isn)==`MLX && isn[`FUNCT5]==`LDDRX);
endfunction

// Aquire / release bits are only available on indexed SWC / LWR
function IsSWCX;
input [2:0] unit;
input [39:0] isn;
IsSWCX = unit==`MUnit && (mopcode(isn)==`MSX && isn[`FUNCT5]==`STDCX);
endfunction

function IsJmp;
input [2:0] unit;
input [39:0] isn;
IsJmp = unit==`BUnit && isn[`OPCODE4]==`JMP;
endfunction

function IsCSR;
input [2:0] unit;
input [39:0] isn;
IsCSR = unit==`IUnit && {isn[32:31],isn[`OPCODE4]}==`CSRRW;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [2:0] unit;
input [39:0] isn;
if (unit==3'd1)
	case(isn[9:6])
	4'h0,4'h1,	// But not BRcc
	4'h4,4'h6,4'h7:
		IsBranch = TRUE;
	default:
		IsBranch = FALSE;
	endcase
else
	IsBranch = FALSE;
endfunction

function IsBRcc;
input [2:0] unit;
input [39:0] isn;
IsBRcc = unit==`BUnit && isn[`OPCODE4]==`BRcc;
endfunction

function IsJAL;
input [2:0] unit;
input [39:0] isn;
IsJAL = unit==`BUnit && isn[`OPCODE4]==`JAL;
endfunction

function IsRet;
input [2:0] unit;
input [39:0] isn;
IsRet = unit==`BUnit && isn[`OPCODE4]==`RET;
endfunction

function IsIrq;
input [2:0] unit;
input [39:0] isn;
IsIrq = unit==`BUnit && isn[`OPCODE4]==`BRK && isn[39];
endfunction

function IsBrk;
input [2:0] unit;
input [39:0] isn;
IsBrk = unit==`BUnit && isn[`OPCODE4]==`BRK;
endfunction

function IsRti;
input [2:0] unit;
input [39:0] isn;
IsRti = unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`RTI;
endfunction

function IsSei;
input [2:0] unit;
input [39:0] isn;
IsSei = unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`SEI;
endfunction

function IsSync;
input [2:0] unit;
input [39:0] isn;
IsSync = (unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`SYNC) || IsRti(unit,isn);
endfunction

function IsRex;
input [2:0] unit;
input [39:0] isn;
IsRex = (unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`REX);
endfunction

function IsOddball;
input [2:0] unit;
input [39:0] instr;
IsOddball = IsRti(unit,instr) || IsSei(unit,instr) || IsCache(unit,instr)
						|| IsCSR(unit,instr) || IsRex(unit,instr) || unit==`FUnit;
endfunction
    
function IsRFW;
input [2:0] unit;
input [39:0] isn;
if (fnRt(unit,isn)==6'd0) 
    IsRFW = FALSE;
else
case(unit)
`BUnit:
	case(isn[`OPCODE4])
	`BMISC:		IsRFW = isn[`FUNCT5]==`SEI;
	`JAL:     IsRFW = TRUE;
	`CALL:    IsRFW = TRUE;  
	`RET:     IsRFW = TRUE; 
	default:	IsRFW = FALSE;
	endcase
`IUnit:	IsRFW = TRUE;
`FUnit:
	case(isn[`OPCODE4])
	`FLT2:
		case(isn[27:22])
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
`MUnit:
	casez(mopcode(isn))
	`LOAD:	IsRFW = TRUE;
	`TLB:		IsRFW = TRUE;
	`PUSH:	IsRFW = TRUE;
	`PUSHC:	IsRFW = TRUE;
	`CAS:		IsRFW = TRUE;
	`MSX:
		case(isn[`FUNCT5])
		`CAS:	IsRFW = TRUE;
		default:	IsRFW = FALSE;
		endcase
	default:	IsRFW = FALSE;
	endcase
default: IsRFW = FALSE;
endcase
endfunction

function HasConst;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:
	case(ins[`OPCODE4])
	`CHKI:	HasConst = TRUE;
	`JAL:		HasConst = TRUE;
	default:	HasConst = FALSE;
	endcase
`IUnit:
	casez({ins[32:31],ins[`OPCODE4]})
	`R3:	HasConst = FALSE;
	`R1:	HasConst = FALSE;
	default:	HasConst = TRUE;
	endcase
`MUnit:
	case(mopcode(ins))
	`MLX:	HasConst = FALSE;
	`MSX:	HasConst = FALSE;
	`PUSH:	HasConst = FALSE;
	`TLB:	HasConst = FALSE;
	default:	HasConst = TRUE;
	endcase
default:	HasConst = FALSE;
endcase
endfunction

function IsAlu0Only;
input [39:0] ins;
casez({ins[32:31],ins[`OPCODE4]})
`CSRRW:	IsAlu0Only = TRUE;
default:	IsAlu0Only = FALSE;
endcase
endfunction

wire isRet = IsRet(unit,instr);
wire isJal = IsJAL(unit,instr);
wire isBrk = IsBrk(unit,instr);
wire isRti = IsRti(unit,instr);

always @*
begin
	bus <= 160'h0;
	bus[`IB_CMP] <= 1'b0;//IsCmp(instr);
	if (unit==`MUnit) begin
		if (IsPushc(unit,instr))
			bus[`IB_CONST] <= {{58{instr[39]}},instr[39:33],instr[30:16]};
		else if (instr[34])	// Store?
			bus[`IB_CONST] <= {{60{instr[39]}},instr[39:35],instr[30:22],instr[5:0]};
		else
			bus[`IB_CONST] <= {{60{instr[39]}},instr[39:35],instr[30:16]};
	end
	else if (IsChki(unit,instr))
		bus[`IB_CONST] <= {{58{instr[39]}},instr[39:33],instr[30:22],instr[5:0]};
	else
		bus[`IB_CONST] <= {{58{instr[39]}},instr[39:33],instr[30:16]};
//	bus[`IB_RT]		 <= fnRt(instr,ven,vl,thrd) | {thrd,7'b0};
//	bus[`IB_RC]		 <= fnRc(instr,ven,thrd) | {thrd,7'b0};
//	bus[`IB_RA]		 <= fnRa(instr,ven,vl,thrd) | {thrd,7'b0};
	bus[`IB_RS1]		 <= instr[`RS1];
	bus[`IB_RS2]		 <= instr[`RS2];
	bus[`IB_RS3]		 <= instr[`RS3];
	bus[`IB_IMM]	 <= HasConst(unit,instr);
//	bus[`IB_A3V]   <= Source3Valid(instr);
//	bus[`IB_A2V]   <= Source2Valid(instr);
//	bus[`IB_A1V]   <= Source1Valid(instr);
	bus[`IB_TLB]	 <= IsTLB(unit,instr);
	bus[`IB_SZ]    <= {instr[32:31],instr[`OPCODE4]}==`R3 ? instr[30:28] : 3'd3;	// 3'd3=word size
	bus[`IB_IRQ]	 <= IsIrq(unit,instr);
	bus[`IB_BRK]	 <= isBrk;
	bus[`IB_RTI]	 <= isRti;
	bus[`IB_CALL]	 <= IsCall(unit,instr);
	bus[`IB_RET]	 <= isRet;
	bus[`IB_JAL]	 <= isJal;
	bus[`IB_REX]	 <= IsRex(unit,instr);
	bus[`IB_WAIT]	 <= IsWait(unit,instr);
	bus[`IB_CHK]	 <= IsChk(unit,instr);
	// IB_BT is now used to indicate when to update the branch target buffer.
	// This occurs when one of the instructions with an unknown or calculated
	// target is present.
	bus[`IB_BT]		 <= isJal | isRet | isBrk | isRti;
	bus[`IB_ALU]   <= unit==3'd2;
	bus[`IB_ALU0]	 <= IsAlu0Only(instr);
	bus[`IB_FPU]   <= unit==3'd3;
	bus[`IB_FC]		 <= unit==3'd1;
	bus[`IB_CANEX] <= fnCanException(unit,instr);
	bus[`IB_LEA]	 <= IsLea(unit,instr);
	bus[`IB_LOAD]	 <= unit==3'd4;
	bus[`IB_PRELOAD] <= unit==3'd4 && Rt==6'd0;
	bus[`IB_STORE]	<= unit==3'd5;
	bus[`IB_PUSH]   <= IsPush(unit,instr);
	bus[`IB_ODDBALL] <= IsOddball(unit,instr);
	bus[`IB_MEMSZ]  <= MemSize(unit,instr);
	bus[`IB_MEM]		<= unit==3'd4 || unit==3'd5;
	bus[`IB_MEMNDX]	<= IsMemNdx(unit,instr);
	bus[`IB_RMW]		<= IsCAS(unit,instr);// || IsInc(unit,instr);
	bus[`IB_MEMDB]	<= IsMemdb(unit,instr);
	bus[`IB_MEMSB]	<= IsMemsb(unit,instr);
	bus[`IB_SEI]		<= IsSEI(unit,instr);
	bus[`IB_AQ]			<= instr[32];
	bus[`IB_RL]			<= instr[31];
	bus[`IB_JMP]		<= IsJmp(unit,instr);
	bus[`IB_BR]			<= IsBranch(unit,instr);
	bus[`IB_BRCC]		<= IsBRcc(unit,instr);
	bus[`IB_SYNC]		<= IsSync(unit,instr)|| isBrk || isRti;
	bus[`IB_FSYNC]	<= IsFSync(unit,instr);
	bus[`IB_RFW]		<= (Rt==6'd0) ? 1'b0 : IsRFW(unit,instr);
	bus[`IB_UNIT]		<= unit;
end

endmodule

