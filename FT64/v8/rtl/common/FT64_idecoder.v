// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_idecoder.v
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
`include ".\FT64_config.vh"
`include ".\FT64_defines.vh"

module FT64_idecoder(clk,idv_i,id_i,instr,vl,ven,thrd,predict_taken,Rt,bus,id_o,idv_o,debug_on,pred_on);
input clk;
input idv_i;
input [4:0] id_i;
input [47:0] instr;
input [7:0] vl;
input [5:0] ven;
input thrd;
input predict_taken;
input [4:0] Rt;
output reg [143:0] bus;
output reg [4:0] id_o;
output reg idv_o;
input debug_on;
input pred_on;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter octa = 3'd3;
parameter hexi = 3'd4;

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

wire iAlu;
mIsALU uialu1
(
	.instr(instr),
	.IsALU(iAlu)
);

function IsTLB;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
  case(isn[`INSTRUCTION_S2])
  `TLB:   IsTLB = TRUE;
  default:    IsTLB = FALSE;
  endcase
default:    IsTLB = FALSE;
endcase
endfunction

reg IsALU;
always @*
case(instr[`INSTRUCTION_OP])
`R2:
	if (instr[`INSTRUCTION_L2]==2'b00)
		case(instr[`INSTRUCTION_S2])
		`VMOV:		IsALU = TRUE;
    `RTI:       IsALU = FALSE;
    default:    IsALU = TRUE;
    endcase
  else
  	IsALU = TRUE;
`BRK:   IsALU = FALSE;
`Bcc:   IsALU = FALSE;
`BRcc:  IsALU = FALSE;
`FBcc:  IsALU = FALSE;
`BBc:   IsALU = FALSE;
`BEQI:  IsALU = FALSE;
`BNEI:  IsALU = FALSE;
`CHK:   IsALU = FALSE;
`JAL:   IsALU = FALSE;
`JMP:	IsALU = FALSE;
`CALL:  IsALU = FALSE;
`RET:   IsALU = FALSE;
`FVECTOR:
	case(instr[`INSTRUCTION_S2])
  `VSHL,`VSHR,`VASR:  IsALU = TRUE;
  default:    IsALU = FALSE;  // Integer
  endcase
`IVECTOR:
	case(instr[`INSTRUCTION_S2])
  `VSHL,`VSHR,`VASR:  IsALU = TRUE;
  default:    IsALU = TRUE;  // Integer
  endcase
`FLOAT:		IsALU = FALSE;            
default:    IsALU = TRUE;
endcase

function IsAlu0Only;
input [47:0] isn;
begin
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`INSTRUCTION_S2])
		`TLB:				IsAlu0Only = TRUE;
		`R1:        IsAlu0Only = TRUE;
		`SHIFTR,`SHIFT31,`SHIFT63:
			IsAlu0Only = !(instr[25:23]==`SHL || instr[25:23]==`ASL);
		`PTRDIF,
		`MULU,`MULSU,`MUL,
		`MULUH,`MULSUH,`MULH,
		`MODU,`MODSU,`MOD: IsAlu0Only = TRUE;
		`DIVU,`DIVSU,`DIV: IsAlu0Only = TRUE;
		`MIN,`MAX:  IsAlu0Only = TRUE;
		default:    IsAlu0Only = FALSE;
		endcase
	else
		IsAlu0Only = FALSE;
`MLX,`MSX:	IsAlu0Only = TRUE;
`IVECTOR,`FVECTOR:
	case(isn[`INSTRUCTION_S2])
	`VSHL,`VSHR,`VASR:  IsAlu0Only = TRUE;
	default: IsAlu0Only = FALSE;
	endcase
`BITFIELD:  IsAlu0Only = TRUE;
`MULUI,`MULI,
`DIVUI,`DIVI,
`MODI:   IsAlu0Only = TRUE;
`CSRRW: IsAlu0Only = TRUE;
default:    IsAlu0Only = FALSE;
endcase
end
endfunction

function IsFPU;
input [47:0] isn;
begin
case(isn[`INSTRUCTION_OP])
`FLOAT: IsFPU = TRUE;
`FVECTOR:
		    case(isn[`INSTRUCTION_S2])
            `VSHL,`VSHR,`VASR:  IsFPU = FALSE;
            default:    IsFPU = TRUE;
            endcase
default:    IsFPU = FALSE;
endcase
end
endfunction

reg IsFlowCtrl;
always @*
case(instr[`INSTRUCTION_OP])
`BRK:    IsFlowCtrl <= TRUE;
`R2:    case(instr[`INSTRUCTION_S2])
        `RTI:   IsFlowCtrl <= TRUE;
        default:    IsFlowCtrl <= FALSE;
        endcase
`Bcc:   IsFlowCtrl <= TRUE;
`BRcc:  IsFlowCtrl <= TRUE;
`FBcc:  IsFlowCtrl <= TRUE;
`BBc:		IsFlowCtrl <= TRUE;
`BEQI:  IsFlowCtrl <= TRUE;
`BNEI:  IsFlowCtrl <= TRUE;
`CHK:   IsFlowCtrl <= TRUE;
`JAL:   IsFlowCtrl <= TRUE;
`JMP:		IsFlowCtrl <= TRUE;
`CALL:  IsFlowCtrl <= TRUE;
`RET:   IsFlowCtrl <= TRUE;
default:    IsFlowCtrl <= FALSE;
endcase

//function IsFlowCtrl;
//input [47:0] isn;
//begin
//case(isn[`INSTRUCTION_OP])
//`BRK:    IsFlowCtrl = TRUE;
//`RR:    case(isn[`INSTRUCTION_S2])
//        `RTI:   IsFlowCtrl = TRUE;
//        default:    IsFlowCtrl = FALSE;
//        endcase
//`Bcc:   IsFlowCtrl = TRUE;
//`BBc:		IsFlowCtrl = TRUE;
//`BEQI:  IsFlowCtrl = TRUE;
//`CHK:   IsFlowCtrl = TRUE;
//`JAL:   IsFlowCtrl = TRUE;
//`JMP:		IsFlowCtrl = TRUE;
//`CALL:  IsFlowCtrl = TRUE;
//`RET:   IsFlowCtrl = TRUE;
//default:    IsFlowCtrl = FALSE;
//endcase
//end
//endfunction

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
input [47:0] isn;
begin
// ToDo add debug_on as input
`ifdef SUPPORT_DBG
if (debug_on)
    fnCanException = `TRUE;
else
`endif
case(isn[`INSTRUCTION_OP])
`FLOAT:
    case(isn[`INSTRUCTION_S2])
    `FDIV,`FMUL,`FADD,`FSUB,`FTX:
        fnCanException = `TRUE;
    default:    fnCanException = `FALSE;
    endcase
`DIVI,`MODI,`MULI:
    fnCanException = `TRUE;
`R2:
    case(isn[`INSTRUCTION_S2])
    `MUL,
    `DIV,`MULSU,`DIVSU,
    `MOD,`MODSU:
       fnCanException = TRUE;
    `RTI:   fnCanException = TRUE;
    default:    fnCanException = FALSE;
    endcase
// Had branches that could exception if looping to self. But in a tight loop
// it affects store performance.
// -> A branch may only exception if it loops back to itself.
`Bcc,`FBcc,`BBc,`BEQI,`BNEI:	fnCanException = isn[7] ? brdisp == 11'h7FF : brdisp == 11'h7FE;
`CHK:	fnCanException = TRUE;
default:
// Stores can stil exception if there is a write buffer, but we allow following
// stores to be issued by ignoring the fact they can exception because the stores
// can be undone by invalidating the write buffer.
`ifdef HAS_WB
    fnCanException = IsMem && !IsStore(isn);
`else
    fnCanException = IsMem;
`endif
endcase
end
endfunction

function IsLoad;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MLX:		IsLoad = TRUE;
`LB:    IsLoad = TRUE;
`LC:    IsLoad = TRUE;
`LH:    IsLoad = TRUE;
`LW:    IsLoad = TRUE;
`LV:    IsLoad = TRUE;
default:    IsLoad = FALSE;
endcase
endfunction

function IsMov2Seg;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[6])
		IsMov2Seg = isn[47:42]==`MOV2SEG;
	else
    case(isn[`INSTRUCTION_S2])
		`MOV2SEG:	IsMov2Seg = TRUE;
		`RTI:			IsMov2Seg = TRUE;
		default:	IsMov2Seg = FALSE;
		endcase
`RET:
	IsMov2Seg = TRUE;
default:	IsMov2Seg = FALSE;
endcase
endfunction

function IsVolatileLoad;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[6])
		IsVolatileLoad = isn[47:42]==`MOV2SEG;
	else
		IsVolatileLoad = isn[31:26]==`MOV2SEG;
`MLX:
	if (isn[`INSTRUCTION_L2]==2'b00)
    case(isn[`MLXOP])
    `LWRX:	IsVolatileLoad = TRUE;
    `LVBX:	IsVolatileLoad = TRUE;
    `LVBUX:	IsVolatileLoad = TRUE;
    `LVCX:	IsVolatileLoad = TRUE;
    `LVCUX:	IsVolatileLoad = TRUE;
    `LVHX:	IsVolatileLoad = TRUE;
    `LVHUX:	IsVolatileLoad = TRUE;
    `LVWX:	IsVolatileLoad = TRUE;
    default: IsVolatileLoad = FALSE;   
    endcase
	else
		IsVolatileLoad = FALSE;
`LWR:	IsVolatileLoad = TRUE;
default:    IsVolatileLoad = FALSE;
endcase
endfunction

function IsStore;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MSX:
	if (isn[`INSTRUCTION_L2]==2'b10) begin
		case({isn[31:28],isn[17:16]})
		`PUSH:	IsStore = TRUE;
    default:    IsStore = FALSE;
		endcase
	end
	else if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`MSXOP])
		`PUSH:	IsStore = TRUE;
    `SBX:   IsStore = TRUE;
    `SCX:   IsStore = TRUE;
    `SHX:   IsStore = TRUE;
    `SWX:   IsStore = TRUE;
    `SWCX:  IsStore = TRUE;
    `SVX:   IsStore = TRUE;
    `CASX:  IsStore = TRUE;
    `INC:	IsStore = TRUE;
    default:    IsStore = FALSE;
    endcase
	else
		IsStore = FALSE;
`PUSHC:	IsStore = TRUE;
`SB:    IsStore = TRUE;
`SH:    IsStore = TRUE;
`SWC:   IsStore = TRUE;
`INC:	IsStore = TRUE;
`SV:    IsStore = TRUE;
`CAS:   IsStore = TRUE;
`AMO:	IsStore = TRUE;
default:    IsStore = FALSE;
endcase
endfunction

function IsPush;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MSX:
	if (isn[`INSTRUCTION_L2]==2'b10) begin
		case(isn[`MSXOP])
		`PUSH:	IsPush = TRUE;
    default:    IsPush = FALSE;
		endcase
	end
	else if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`MSXOP])
		`PUSH:	IsPush = TRUE;
    default:    IsPush = FALSE;
    endcase
	else
		IsPush = FALSE;
`PUSHC:	IsPush = TRUE;
default:    IsPush = FALSE;
endcase
endfunction

function IsPushc;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`PUSHC:	IsPushc = TRUE;
default:    IsPushc = FALSE;
endcase
endfunction

//function [0:0] IsMem;
reg IsMem;
always @*
//input [47:0] isn;
case(instr[`INSTRUCTION_OP])
`R2:
	if (instr[6])
		IsMem = instr[47:42]==`MOV2SEG;
	else
    case(instr[`INSTRUCTION_S2])
		`MOV2SEG:	IsMem = TRUE;
		//`RTI:			IsMem = TRUE;
		default:	IsMem = FALSE;
		endcase
`MLX,`MSX:	IsMem = TRUE;
`AMO:		IsMem = TRUE;
`LB:    IsMem = TRUE;
`LC:    IsMem = TRUE;
`LH:    IsMem = TRUE;
`LW:    IsMem = TRUE;
`LV,`SV:    IsMem = TRUE;
`INC:		IsMem = TRUE;
`PUSHC:	IsMem = TRUE;
`SB:    IsMem = TRUE;
`SH:    IsMem = TRUE;
`SWC:   IsMem = TRUE;
`CAS:   IsMem = TRUE;
//`RET:		IsMem = TRUE;???
default:    IsMem = FALSE;
endcase
//endfunction

function IsMemNdx;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MLX,`MSX:	IsMemNdx = TRUE;
default:    IsMemNdx = FALSE;
endcase
endfunction

function [2:0] MemSize;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MLX:
	if (isn[`INSTRUCTION_L2]==2'b00) begin
    case(isn[`MLXOP])
    `LVBX,`LVBUX:	MemSize = byt;
    `LBX,`LBUX:   MemSize = byt;
    `LVCX,`LVCUX:			 MemSize = wyde;
    `LCX,`LCUX:   MemSize = wyde;
    `LVHX,`LVHUX:		MemSize = tetra;
    `LHX:   MemSize = tetra;
    `LHUX: MemSize = tetra;
    `LVWX:			 MemSize = octa;
    `LWX:   MemSize = octa;
    `LWRX: MemSize = octa;
    `LVX:   MemSize = octa;
    default: MemSize = octa;
  	endcase
  else
  	MemSize = octa;
`MSX:
	case(isn[`MSXOP])
  `SBX:   MemSize = byt;
  `SCX:   MemSize = wyde;
  `SHX:   MemSize = tetra;
  `SWX:   MemSize = octa;
  `SWCX: MemSize = octa;
  `SVX:   MemSize = octa;
  default: MemSize = octa;   
	endcase
`LB:  MemSize = byt;
`LC:	MemSize = wyde;
`LH:	MemSize = tetra;
`LW:  MemSize = octa;
`LV:    MemSize = octa;
`AMO:
	case(isn[23:21])
	3'd0:	MemSize = byt;
	3'd1:	MemSize = wyde;
	3'd2:	MemSize = tetra;
	3'd3:	MemSize = octa;
	default:	MemSize = octa;
	endcase
`SB:	MemSize = isn[23] ? wyde : byt;
`SH:	MemSize = isn[23] ? octa : tetra;
`SWC:  MemSize = octa;
`SV:    MemSize = octa;
`PUSHC:	MemSize = octa;
default:    MemSize = octa;
endcase
endfunction

function IsCAS;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MSX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`MSXOP])
    `CASX:   IsCAS = TRUE;
    default:    IsCAS = FALSE;
    endcase
	else
		IsCAS = FALSE;
`CAS:       IsCAS = TRUE;
default:    IsCAS = FALSE;
endcase
endfunction

function IsAMO;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`AMO:       IsAMO = TRUE;
default:    IsAMO = FALSE;
endcase
endfunction

function IsInc;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MLX:
   	if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`MLXOP])
    `INCX:   IsInc = TRUE;
    default:    IsInc = FALSE;
    endcase
	else
		IsInc = FALSE;
`INC:    IsInc = TRUE;
default:    IsInc = FALSE;
endcase
endfunction

function IsFSync;
input [47:0] isn;
IsFSync = (isn[`INSTRUCTION_OP]==`FLOAT && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`FSYNC); 
endfunction

function IsMemdb;
input [47:0] isn;
IsMemdb = (isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`R1 && isn[22:18]==`MEMDB); 
endfunction

function IsMemsb;
input [47:0] isn;
IsMemsb = (isn[`INSTRUCTION_OP]==`RR && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`R1 && isn[22:18]==`MEMSB); 
endfunction

function IsSEI;
input [47:0] isn;
IsSEI = (isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`SEI); 
endfunction

function IsShift48;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
    case(isn[47:42])
    `SHIFTR: IsShift48 = TRUE;
    default: IsShift48 = FALSE;
    endcase
  else
  	IsShift48 = FALSE;
default: IsShift48 = FALSE;
endcase
endfunction

function IsShift;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
    case(isn[31:26])
    `SHIFTR: IsShift = TRUE;
    `SHIFT31: IsShift = TRUE;
    `SHIFT63: IsShift = TRUE;
    default: IsShift = FALSE;
    endcase
  else
  	IsShift = FALSE;
default: IsShift = FALSE;
endcase
endfunction

function IsLWRX;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MLX:
	if (isn[`INSTRUCTION_L2]==2'b00)
    case(isn[`MLXOP])
    `LWRX:   IsLWRX = TRUE;
    default:    IsLWRX = FALSE;
    endcase
	else
		IsLWRX = FALSE;
default:    IsLWRX = FALSE;
endcase
endfunction

// Aquire / release bits are only available on indexed SWC / LWR
function IsSWCX;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MSX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`MSXOP])
    `SWCX:   IsSWCX = TRUE;
    default:    IsSWCX = FALSE;
    endcase
	else
		IsSWCX = FALSE;
default:    IsSWCX = FALSE;
endcase
endfunction

function IsJmp;
input [47:0] isn;
IsJmp = isn[`INSTRUCTION_OP]==`JMP;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`FBcc:  IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
`BNEI:  IsBranch = TRUE;
`CHK:   IsBranch = TRUE;
default:    IsBranch = FALSE;
endcase
endfunction

function IsJAL;
input [47:0] isn;
IsJAL = isn[`INSTRUCTION_OP]==`JAL;
endfunction

function IsRet;
input [47:0] isn;
IsRet = isn[`INSTRUCTION_OP]==`RET;
endfunction

function IsIrq;
input [47:0] isn;
IsIrq = isn[`INSTRUCTION_OP]==`BRK && isn[25:21]==5'h0;
endfunction

function IsBrk;
input [47:0] isn;
IsBrk = isn[`INSTRUCTION_OP]==`BRK;
endfunction

function IsRti;
input [47:0] isn;
IsRti = isn[`INSTRUCTION_OP]==`RR && isn[`INSTRUCTION_S2]==`RTI;
endfunction

function IsSync;
input [47:0] isn;
IsSync = (isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`R1 && isn[22:18]==`SYNC) || IsRti(isn) || IsMov2Seg(isn);
endfunction

// Has an extendable 14-bit constant
function HasConst;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`ADDI:  HasConst = TRUE;
`SEQI:  HasConst = TRUE;
`SLTI:  HasConst = TRUE;
`SLTUI: HasConst = TRUE;
`SGTI:  HasConst = TRUE;
`SGTUI: HasConst = TRUE;
`ANDI:  HasConst = TRUE;
`ORI:   HasConst = TRUE;
`XORI:  HasConst = TRUE;
`MULUI: HasConst = TRUE;
`MULI:  HasConst = TRUE;
`MULFI:	HasConst = TRUE;
`DIVUI: HasConst = TRUE;
`DIVI:  HasConst = TRUE;
`MODI:  HasConst = TRUE;
`LEA:   HasConst = TRUE;
`LB:    HasConst = TRUE;
`LC:    HasConst = TRUE;
`LH:    HasConst = TRUE;
`LW:    HasConst = TRUE;
`LV:    HasConst = TRUE;
`SB:  	HasConst = TRUE;
`SH:  	HasConst = TRUE;
`SWC:   HasConst = TRUE;
`INC:		HasConst = TRUE;
`SV:    HasConst = TRUE;
`CAS:   HasConst = TRUE;
`JAL:   HasConst = TRUE;
`CALL:  HasConst = TRUE;
`RET:   HasConst = TRUE;
`PUSHC:	HasConst = TRUE;
default:    HasConst = FALSE;
endcase
endfunction

function IsOddball;
input [47:0] instr;
//if (|iqentry_exc[head])
//    IsOddball = TRUE;
//else
case(instr[`INSTRUCTION_OP])
`BRK:   IsOddball = TRUE;
`IVECTOR:
    case(instr[`INSTRUCTION_S2])
    `VSxx:  IsOddball = TRUE;
    default:    IsOddball = FALSE;
    endcase
`RR:
    case(instr[`INSTRUCTION_S2])
    `VMOV:  IsOddball = TRUE;
    `SEI,`RTI: IsOddball = TRUE;
    default:    IsOddball = FALSE;
    endcase
`MEMNDX:
		case({instr[31:28],instr[17:16]})
    `CACHEX:  IsOddball = TRUE;
    default:    IsOddball = FALSE;
    endcase
`CSRRW,`REX,`CACHE,`FLOAT:  IsOddball = TRUE;
default:    IsOddball = FALSE;
endcase
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
`MLX:	IsRFW = TRUE;
`MSX:
	if (isn[`INSTRUCTION_L2]==2'b10) begin
		case(isn[`MSXOP])
		`PUSH:	IsRFW = TRUE;
    `CASX:  IsRFW = TRUE;
    default:    IsRFW = FALSE;
    endcase
	end
	else if (isn[`INSTRUCTION_L2]==2'b00) begin
		case(isn[`MSXOP])
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

// Determines which lanes of the target register get updated.
function [7:0] fnWe;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`R2:
	case(isn[`INSTRUCTION_S2])
	`CMP:	fnWe = 8'h00;			// CMP sets predicate registers so doesn't update general register file.
	default: fnWe = 8'hFF;	
	endcase
default: fnWe = 8'hFF;
endcase
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
`MLX,`MSX:	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
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
`MLX:
	case(isn[`MLXOP])
	`LVX: Source2Valid = FALSE;
	default:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
	endcase
`MSX:
	case(isn[`MSXOP])
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
`MSX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case(isn[`MSXOP])
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
	bus[`IB_LOADSEG] <= IsMov2Seg(instr);
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
	bus[`IB_TLB]	 <= IsTLB(instr);
	bus[`IB_SZ]    <= instr[`INSTRUCTION_OP]==`R2 ? instr[25:23] : 3'd3;	// 3'd3=word size
	bus[`IB_IRQ]	 <= IsIrq(instr);
	bus[`IB_BRK]	 <= isBrk;
	bus[`IB_RTI]	 <= isRti;
	bus[`IB_RET]	 <= isRet;
	bus[`IB_JAL]	 <= isJal;
	// IB_BT is now used to indicate when to update the branch target buffer.
	// This occurs when one of the instructions with an unknown or calculated
	// target is present.
	bus[`IB_BT]		 <= isJal | isRet | isBrk | isRti;
	bus[`IB_ALU]   <= IsALU;
	bus[`IB_ALU0]  <= IsAlu0Only(instr);
	bus[`IB_FPU]   <= IsFPU(instr);
	bus[`IB_FC]		 <= IsFlowCtrl;
	bus[`IB_CANEX] <= fnCanException(instr);
	bus[`IB_LOADV] <= IsVolatileLoad(instr);
	bus[`IB_LOAD]	 <= IsLoad(instr);
	bus[`IB_PRELOAD] <=   IsLoad(instr) && Rt==5'd0;
	bus[`IB_STORE]	<= IsStore(instr);
	bus[`IB_PUSH]   <= IsPush(instr);
	bus[`IB_ODDBALL] <= IsOddball(instr);
	bus[`IB_MEMSZ]  <= MemSize(instr);
	bus[`IB_MEM]		<= IsMem;
	bus[`IB_MEMNDX]	<= IsMemNdx(instr);
	bus[`IB_RMW]		<= IsCAS(instr) || IsAMO(instr) || IsInc(instr);
	bus[`IB_MEMDB]	<= IsMemdb(instr);
	bus[`IB_MEMSB]	<= IsMemsb(instr);
	bus[`IB_SHFT]   <= IsShift48(instr);//|IsShift(instr);
	bus[`IB_SEI]		<= IsSEI(instr);
	bus[`IB_AQ]			<= (IsAMO(instr)|IsLWRX(instr)|IsSWCX(instr)) & instr[25];
	bus[`IB_RL]			<= (IsAMO(instr)|IsLWRX(instr)|IsSWCX(instr)) & instr[24];
	bus[`IB_JMP]		<= IsJmp(instr);
	bus[`IB_BR]			<= IsBranch(instr);
	bus[`IB_SYNC]		<= IsSync(instr)||IsBrk(instr)||IsRti(instr);
	bus[`IB_FSYNC]	<= IsFSync(instr);
	bus[`IB_RFW]		<= (Rt==5'd0) ? 1'b0 : IsRFW(instr);// && !IsCmp(instr);
	bus[`IB_PRFW]   <= 1'b0;//IsCmp(instr);
	bus[`IB_WE]			<= fnWe(instr);
	id_o <= id_i;
	idv_o <= idv_i;
end

endmodule

module mIsALU(instr, IsALU);
input [47:0] instr;
output reg IsALU;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

always @*
casez(instr[`INSTRUCTION_OP])
`R2:
  if (instr[`INSTRUCTION_L2]==2'b00)
		case(instr[`INSTRUCTION_S2])
		`VMOV:		IsALU = TRUE;
    `RTI:       IsALU = FALSE;
    default:    IsALU = TRUE;
    endcase
    else
    	IsALU = TRUE;
`BRK:   IsALU = FALSE;
`Bcc:   IsALU = FALSE;
`BRcc:	IsALU = FALSE;
`FBcc:  IsALU = FALSE;
`BBc:   IsALU = FALSE;
`BEQI:  IsALU = FALSE;
`BNEI:  IsALU = FALSE;
`CHK:   IsALU = FALSE;
`JAL:   IsALU = FALSE;
`JMP:	IsALU = FALSE;
`CALL:  IsALU = FALSE;
`RET:   IsALU = FALSE;
`FVECTOR:
	case(instr[`INSTRUCTION_S2])
  `VSHL,`VSHR,`VASR:  IsALU = TRUE;
  default:    IsALU = FALSE;  // Integer
  endcase
`IVECTOR:
	case(instr[`INSTRUCTION_S2])
  `VSHL,`VSHR,`VASR:  IsALU = TRUE;
  default:    IsALU = TRUE;  // Integer
  endcase
`FLOAT:		IsALU = FALSE;            
default:    IsALU = TRUE;
endcase

endmodule
