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
`include ".\rtfItanium-config.v"
`include ".\rtfItanium-defines.v"

module idecoder(unit,instr,predict_taken,Rt,bus,debug_on);
input [2:0] unit;
input [39:0] instr;
input predict_taken;
input [5:0] Rt;
output reg [143:0] bus;
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

wire [10:0] brdisp = instr[31:21];

function IsTLB;
input [2:0] unit;
input [47:0] isn;
IsTLB = unit==`MStUnit && opcode==`TLB;
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
	case({isn[32:31],isn[9:6]})
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
`MLdUnit:
	fnCanException = TRUE;
default:
	fnCanException = FALSE;
endcase
end
endfunction

function IsPush;
input [2:0] unit;
input [39:0] isn;
IsPush = unit==`MStUnit && (isn[9:6]==`PUSH || isn[9:6]==`PUSHC);
endfunction

function IsPushc;
input [2:0] unit;
input [39:0] isn;
IsPushc = unit==`MStUnit && isn[9:6]==`PUSHC;
endfunction

function IsMemNdx;
input [2:0] unit;
input [39:0] isn;
IsMemNdx = (unit==`MLdUnit && ins[9:6]==`MLX) || (unit==`MStUnit && ins[9:6]==`MSX);
endfunction

function [2:0] MemSize;
input [2:0] unit;
input [39:0] isn;
case(unit)
`MLdUnit:
	case(isn[9:6])
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
		case(isn[39:35])
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
	default:	MemSize = deci;
	endcase
	endfunction
`MStUnit:
	case(isn[9:6])
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
		case(isn[39:35])
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
	endfunction
default:	MemSize = deci;
endcase

function IsCAS;
input [2:0] unit;
input [39:0] isn;
IsCAS = unit==`MStUnit && (isn[9:6]==`CAS || (isn[9:6]==`MSX && isn[39:36]==`CAS))
endfunction

function IsChk;
input [2:0] unit;
input [39:0] isn;
IsChk = unit==`BUnit && (isn[9:6]==`CHK || isn[9:6]==`CHKI);
endfunction

function IsFSync;
input [2:0] unit;
input [39:0] isn;
IsFSync = unit==`FUnit && isn[9:6]==`FLT2 && isn[27:22]==`FSYNC; 
endfunction

function IsMemdb;
input [2:0] unit;
input [39:0] isn;
IsMemdb = unit==`MStUnit && isn[9:6]==`MSX && isn[39:35]==`MEMDB;
endfunction

function IsMemsb;
input [2:0] unit;
input [39:0] isn;
IsMemsb = unit==`MStUnit && isn[9:6]==`MSX && isn[39:35]==`MEMSB;
endfunction

function IsSEI;
input [2:0] unit;
input [39:0] isn;
IsSEI = unit==`BUnit && isn[9:6]==`RTI && isn[39:35]==`SEI;
endfunction

function IsLWRX;
input [2:0] unit;
input [47:0] isn;
IsLWRX = unit==`MLdUnit && (isn[9:6]==`MSL && isn[39:36]==`LDDR);
endfunction

// Aquire / release bits are only available on indexed SWC / LWR
function IsSWCX;
input [2:0] unit;
input [39:0] isn;
IsSWCX = unit==`MStUnit && (isn[9:6]==`MSX && isn[39:36]==`STDC);
endfunction

function IsJmp;
input [2:0] unit;
input [39:0] isn;
IsJmp = unit=`BUnit && isn[9:6]==`JMP;
endfunction

function IsCSR;
input [2:0] unit;
input [39:0] ins;
IsCSR = unit==`IUnit && {isn[32:31],isn[9:6]}==`CSR;
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

function IsJAL;
input [2:0] unit;
input [39:0] isn;
IsJal = unit==`BUnit && isn[9:6]==`JAL;
endfunction

function IsRet;
input [2:0] unit
input [39:0] isn;
IsRet = unit==`BUnit && isn[9:6]==`RET;
endfunction

function IsIrq;
input [2:0] unit;
input [39:0] isn;
IsIrq = unit==`BUnit && isn[9:6]==`BRK && isn[39];
endfunction

function IsBrk;
input [2:0] unit;
input [39:0] isn;
IsBrk = unit==`BUnit && isn[9:6]==`BRK;
endfunction

function IsRti;
input [2:0] unit;
input [39:0] isn;
IsRti = unit==`BUnit && isn[9:6]==`RTI && isn[39:34]==5'd0;
endfunction

function IsSync;
input [2:0] unit;
input [39:0] isn;
IsSync = (unit=`BUnit && isn[9:6]==`RTI && isn[39:34]==`SYNC) || IsRti(unit,isn);
endfunction

function IsRex;
input [2:0] unit;
input [39:0] isn;
IsRex = (unit=`BUnit && isn[9:6]==`RTI && isn[39:34]==`REX);
endfunction

function IsOddball;
input [2:0] unit;
input [39:0] instr;
IsOddball = IsRti(unit,instr) || IsSei(unit,instr) || IsCache(unit,instr)
						|| IsCSR(unit,instr) || IsRex(unit,instr) || unit==`FUnit;
endfunction
    
function IsRFW;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`IVECTOR:   IsRFW = TRUE;
`FVECTOR:   IsRFW = TRUE;
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
    casez(isn[`INSTRUCTION_S2])
    `TLB:		IsRFW = TRUE;
    `R1:
	    	case(isn[22:18])
	    	`MEMDB,`MEMSB,`SYNC,`SETWB,5'h14,5'h15:	IsRFW = FALSE;
	    	default:	IsRFW = TRUE;
	    	endcase
    `ADD:   IsRFW = TRUE;
    `SUB:   IsRFW = TRUE;
    `SEQ:   IsRFW = TRUE;
    `SLT:   IsRFW = TRUE;
    `SLTU:  IsRFW = TRUE;
    `SLE:   IsRFW = TRUE;
    `SLEU:  IsRFW = TRUE;
    `AND:   IsRFW = TRUE;
    `OR:    IsRFW = TRUE;
    `XOR:   IsRFW = TRUE;
    `NAND:	IsRFW = TRUE;
    `NOR:		IsRFW = TRUE;
    `XNOR:	IsRFW = TRUE;
    `MULU:  IsRFW = TRUE;
    `MULSU: IsRFW = TRUE;
    `MUL:   IsRFW = TRUE;
    `MULUH:  IsRFW = TRUE;
    `MULSUH: IsRFW = TRUE;
    `MULH:   IsRFW = TRUE;
    `MULF:	IsRFW = TRUE;
    `FXMUL:	IsRFW = TRUE;
    `DIVU:  IsRFW = TRUE;
    `DIVSU: IsRFW = TRUE;
    `DIV:IsRFW = TRUE;
    `MODU:  IsRFW = TRUE;
    `MODSU: IsRFW = TRUE;
    `MOD:IsRFW = TRUE;
    `MOV:	IsRFW = TRUE;
    `VMOV:	IsRFW = TRUE;
    `SHIFTR,`SHIFT31,`SHIFT63:
	    	IsRFW = TRUE;
    `MIN,`MAX:    IsRFW = TRUE;
    `SEI:	IsRFW = TRUE;
    default:    IsRFW = FALSE;
    endcase
	else if (isn[`INSTRUCTION_L2]==2'b01)
		case(isn[47:42])
		`CMOVEZ:	IsRFW = TRUE;
		`CMOVNZ:	IsRFW = TRUE;
		default:	IsRFW = FALSE;
		endcase
	else if (isn[7]==1'b1)
    casez(isn[`INSTRUCTION_S2])
    `ADD:   IsRFW = TRUE;
    `SUB:   IsRFW = TRUE;
    `AND:   IsRFW = TRUE;
    `OR:    IsRFW = TRUE;
    `XOR:   IsRFW = TRUE;
    `MOV:	IsRFW = TRUE;
    `SHIFTR,`SHIFT31,`SHIFT63:
	    	IsRFW = TRUE;
    default:    IsRFW = FALSE;
    endcase
	else
		IsRFW = FALSE;
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b10) begin
		if (IsLoad(isn))
			IsRFW = TRUE;
		else
			case({isn[31:28],isn[17:16]})
			`PUSH:	IsRFW = TRUE;
	    `CASX:  IsRFW = TRUE;
	    default:    IsRFW = FALSE;
	    endcase
	end
	else if (isn[`INSTRUCTION_L2]==2'b00) begin
		if (IsLoad(isn))
	    case({isn[31:28],isn[22:21]})
	    `LBX:   IsRFW = TRUE;
	    `LBUX:  IsRFW = TRUE;
	    `LCX:   IsRFW = TRUE;
	    `LCUX:  IsRFW = TRUE;
	    `LHX:   IsRFW = TRUE;
	    `LHUX:  IsRFW = TRUE;
	    `LWX:   IsRFW = TRUE;
	    `LVBX:  IsRFW = TRUE;
	    `LVBUX: IsRFW = TRUE;
	    `LVCX:  IsRFW = TRUE;
	    `LVCUX: IsRFW = TRUE;
	    `LVHX:  IsRFW = TRUE;
	    `LVHUX: IsRFW = TRUE;
	    `LVWX:  IsRFW = TRUE;
	    `LWX:   IsRFW = TRUE;
	    `LWRX:  IsRFW = TRUE;
	    `LVX:   IsRFW = TRUE;
	    default:	IsRFW = FALSE;
	  	endcase
	  else
			case({isn[31:28],isn[17:16]})
			`PUSH:	IsRFW = TRUE;
	    `CASX:  IsRFW = TRUE;
	    default:    IsRFW = FALSE;
	    endcase
  end
	else
		IsRFW = FALSE;
`BBc:	IsRFW = FALSE;
`BITFIELD:  IsRFW = TRUE;
`ADDI:      IsRFW = TRUE;
`SEQI:      IsRFW = TRUE;
`SLTI:      IsRFW = TRUE;
`SLTUI:     IsRFW = TRUE;
`SGTI:      IsRFW = TRUE;
`SGTUI:     IsRFW = TRUE;
`ANDI:      IsRFW = TRUE;
`ORI:       IsRFW = TRUE;
`XORI:      IsRFW = TRUE;
`MULUI:     IsRFW = TRUE;
`MULI:      IsRFW = TRUE;
`MULFI:			IsRFW = TRUE;
`DIVUI:     IsRFW = TRUE;
`DIVI:      IsRFW = TRUE;
`MODI:      IsRFW = TRUE;
`JAL:       IsRFW = TRUE;
`CALL:      IsRFW = TRUE;  
`RET:       IsRFW = TRUE; 
`LEA:       IsRFW = TRUE;
`LB:        IsRFW = TRUE;
`LC:        IsRFW = TRUE;
`LH:        IsRFW = TRUE;
`LW:        IsRFW = TRUE;
`LV:        IsRFW = TRUE;
`PUSHC:			IsRFW = TRUE;
`CAS:       IsRFW = TRUE;
`AMO:				IsRFW = TRUE;
`CSRRW:			IsRFW = TRUE;
`AUIPC:			IsRFW = TRUE;
`LUI:				IsRFW = TRUE;
default:    IsRFW = FALSE;
endcase
endfunction

/*
casez(isn[`INSTRUCTION_OP])
`R2:
	case(isn[`INSTRUCTION_S2])
	`R1:
		case(isn[22:18])
		`ABS,`CNTLZ,`CNTLO,`CNTPOP:
			case(isn[25:23])
			3'b000: fnWe = 8'h01;
			3'b001:	fnWe = 8'h03;
			3'b010:	fnWe = 8'h0F;
			3'b011:	fnWe = 8'hFF;
			default:	fnWe = 8'hFF;
			endcase
		default: fnWe = 8'hFF;
		endcase
	`SHIFT31:	fnWe = (~isn[25] & isn[21]) ? 8'hFF : 8'hFF;
	`SHIFT63:	fnWe = (~isn[25] & isn[21]) ? 8'hFF : 8'hFF;
	`SLT,`SLTU,`SLE,`SLEU,
	`ADD,`SUB,
	`AND,`OR,`XOR,
	`NAND,`NOR,`XNOR,
	`DIV,`DIVU,`DIVSU,
	`MOD,`MODU,`MODSU,
	`MUL,`MULU,`MULSU,
	`MULH,`MULUH,`MULSUH,
	`FXMUL:
		case(isn[25:23])
		3'b000: fnWe = 8'h01;
		3'b001:	fnWe = 8'h03;
		3'b010:	fnWe = 8'h0F;
		3'b011:	fnWe = 8'hFF;
		default:	fnWe = 8'hFF;
		endcase
	default: fnWe = 8'hFF;
	endcase
default:	fnWe = 8'hFF;
endcase
*/
endfunction

// Detect if a source is automatically valid
function Source1Valid;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`BRK:   Source1Valid = TRUE;
`Bcc:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BRcc:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`FBcc:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BBc:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BEQI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BNEI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CHK:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`R2:    case(isn[`INSTRUCTION_S2])
        `SHIFT31:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        `SHIFT63:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        `SHIFTR:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        default:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        endcase
`MEMNDX:	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`ADDI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SEQI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SLTI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SLTUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SGTI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SGTUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`ANDI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`ORI:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`XORI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`MULUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`AMO: 	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LEA:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LB:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LC:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LH:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LW:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LWR:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LV:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SB:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SH:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SWC:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SV:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`PUSHC: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`INC:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CAS:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`JAL:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`RET:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CSRRW: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BITFIELD: 	case(isn[31:28])
			`BFINSI:	Source1Valid = TRUE;
			default:	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
			endcase
`IVECTOR:
			Source1Valid = FALSE;
default:    Source1Valid = TRUE;
endcase
endfunction
  
function Source2Valid;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`BRK:   Source2Valid = TRUE;
`Bcc:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`BRcc:  Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`FBcc:  Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`BBc:   Source2Valid = TRUE;
`BEQI:  Source2Valid = TRUE;
`BNEI:  Source2Valid = TRUE;
`CHK:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`R2:    case(isn[`INSTRUCTION_S2])
        `R1:       Source2Valid = TRUE;
        `SHIFT31:  Source2Valid = TRUE;
        `SHIFT63:  Source2Valid = TRUE;
        default:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
        endcase
`MEMNDX:
				if (IsLoad(isn)) 
					case({isn[31:28],isn[22:21]})
        	`LVX: Source2Valid = FALSE;
        	default:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
        	endcase
        else
					case({isn[31:28],isn[17:16]})
        	`SVX: Source2Valid = FALSE;
        	default:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
        	endcase
`ADDI:  Source2Valid = TRUE;
`SEQI:  Source2Valid = TRUE;
`SLTI:  Source2Valid = TRUE;
`SLTUI: Source2Valid = TRUE;
`SGTI:  Source2Valid = TRUE;
`SGTUI: Source2Valid = TRUE;
`ANDI:  Source2Valid = TRUE;
`ORI:   Source2Valid = TRUE;
`XORI:  Source2Valid = TRUE;
`MULUI: Source2Valid = TRUE;
`LEA:   Source2Valid = TRUE;
`LB:    Source2Valid = TRUE;
`LC:    Source2Valid = TRUE;
`LH:    Source2Valid = TRUE;
`LW:    Source2Valid = TRUE;
`INC:		Source2Valid = TRUE;
`SB:    Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`SH:    Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`SWC:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`PUSHC: Source2Valid = TRUE;
`CAS:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`JAL:   Source2Valid = TRUE;
`RET:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`IVECTOR:
		    case(isn[`INSTRUCTION_S2])
            `VABS:  Source2Valid = TRUE;
            `VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP:
                Source2Valid = FALSE;
            `VADDS,`VSUBS,`VANDS,`VORS,`VXORS:
                Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
            `VBITS2V:   Source2Valid = TRUE;
            `V2BITS:    Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
            `VSHL,`VSHR,`VASR:  Source2Valid = isn[22:21]==2'd2;
            default:    Source2Valid = FALSE;
            endcase
`LV:        Source2Valid = TRUE;
`SV:        Source2Valid = FALSE;
`AMO:		Source2Valid = isn[31] || isn[`INSTRUCTION_RB]==5'd0;
default:    Source2Valid = TRUE;
endcase
endfunction

function Source3Valid;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
    case(isn[`INSTRUCTION_S2])
    `VEX:       Source3Valid = TRUE;
    default:    Source3Valid = TRUE;
    endcase
`BRcc:  Source3Valid = isn[`INSTRUCTION_RB]==5'd0;
`CHK:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
		case(isn[47:42])
    `CMOVEZ,`CMOVNZ:  Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
		default:	Source3Valid = TRUE;
		endcase
	else
    case(isn[`INSTRUCTION_S2])
    `MAJ:		Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    default:    Source3Valid = TRUE;
    endcase
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case({isn[31:28],isn[17:16]})
    `SBX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    `SCX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    `SHX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    `SWX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    `SWCX:  Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    `CASX:  Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    default:    Source3Valid = TRUE;
    endcase
  else
  	Source3Valid = TRUE;
default:    Source3Valid = TRUE;
endcase
endfunction

wire isRet = IsRet(instr);
wire isJal = IsJAL(instr);
wire isBrk = IsBrk(instr);
wire isRti = IsRti(instr);

`ifdef REGISTER_DECODE
always @(posedge clk)
`else
always @*
`endif
begin
	bus <= 144'h0;
	bus[`IB_CMP] <= 1'b0;//IsCmp(instr);
	if (IsStore(instr) & !IsPushc(instr))
		bus[`IB_CONST] <= instr[6]==1'b1 ? {{35{instr[47]}},instr[47:24],instr[17:13]} :
																				{{51{instr[31]}},instr[31:24],instr[17:13]};
	else
		bus[`IB_CONST] <= instr[6]==1'b1 ? {{35{instr[47]}},instr[47:24],instr[22:18]} :
																				{{51{instr[31]}},instr[31:24],instr[22:18]};
`ifdef SUPPORT_DCI																			
	if (instr[`INSTRUCTION_OP]==`CMPRSSD)
		bus[`IB_LN] <= 3'd2 | pred_on;
	else
`endif
		case(instr[7:6])
		2'b00:	bus[`IB_LN] <= 3'd4 | pred_on;
		2'b01:	bus[`IB_LN] <= 3'd6 | pred_on;
		default: bus[`IB_LN] <= 3'd2 | pred_on;
		endcase
//	bus[`IB_RT]		 <= fnRt(instr,ven,vl,thrd) | {thrd,7'b0};
//	bus[`IB_RC]		 <= fnRc(instr,ven,thrd) | {thrd,7'b0};
//	bus[`IB_RA]		 <= fnRa(instr,ven,vl,thrd) | {thrd,7'b0};
	bus[`IB_IMM]	 <= HasConst(instr);
//	bus[`IB_A3V]   <= Source3Valid(instr);
//	bus[`IB_A2V]   <= Source2Valid(instr);
//	bus[`IB_A1V]   <= Source1Valid(instr);
	bus[`IB_TLB]	 <= IsTLB(unit,instr);
	bus[`IB_SZ]    <= instr[`INSTRUCTION_OP]==`R2 ? instr[25:23] : 3'd3;	// 3'd3=word size
	bus[`IB_IRQ]	 <= IsIrq(unit,instr);
	bus[`IB_BRK]	 <= isBrk;
	bus[`IB_RTI]	 <= isRti;
	bus[`IB_RET]	 <= isRet;
	bus[`IB_JAL]	 <= isJal;
	bus[`IB_REX]	 <= IsRex(unit,instr);
	bus[`IB_CHK]	 <= IsChk(unit,instr);
	// IB_BT is now used to indicate when to update the branch target buffer.
	// This occurs when one of the instructions with an unknown or calculated
	// target is present.
	bus[`IB_BT]		 <= isJal | isRet | isBrk | isRti;
	bus[`IB_ALU]   <= unit==3'd2;
	bus[`IB_FPU]   <= unit==3'd3;
	bus[`IB_FC]		 <= unit==3'd1;
	bus[`IB_CANEX] <= fnCanException(unit,instr);
	bus[`IB_LOAD]	 <= unit==3'd4;
	bus[`IB_PRELOAD] <= unit==3'd4 && Rt==6'd0;
	bus[`IB_STORE]	<= unit==3'd5;
	bus[`IB_PUSH]   <= IsPush(unit,instr);
	bus[`IB_ODDBALL] <= IsOddball(instr);
	bus[`IB_MEMSZ]  <= MemSize(instr);
	bus[`IB_MEM]		<= unit==3'd4 || unit==3'd5;
	bus[`IB_MEMNDX]	<= IsMemNdx(unit,instr);
	bus[`IB_RMW]		<= IsCAS(unit,instr) || IsAMO(unit,instr) || IsInc(unit,instr);
	bus[`IB_MEMDB]	<= IsMemdb(instr);
	bus[`IB_MEMSB]	<= IsMemsb(instr);
	bus[`IB_SEI]		<= IsSEI(unit,instr);
	bus[`IB_AQ]			<= instr[40];
	bus[`IB_RL]			<= instr[39];
	bus[`IB_JMP]		<= IsJmp(unit,instr);
	bus[`IB_BR]			<= IsBranch(unit,instr);
	bus[`IB_SYNC]		<= IsSync(unit,instr)|| isBrk || isRti;
	bus[`IB_FSYNC]	<= IsFSync(unit,instr);
	bus[`IB_RFW]		<= (Rt==6'd0) ? 1'b0 : IsRFW(unit,instr);
	bus[`IB_UNIT]		<= unit;
end

endmodule

