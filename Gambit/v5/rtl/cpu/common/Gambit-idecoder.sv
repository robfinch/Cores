// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"

module idecoder(instr,predict_taken,bus);
input Instruction instr;
input predict_taken;
output reg [`IBTOP:0] bus;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
// Memory access sizes
parameter octa = 4'd0;
parameter byt = 4'd1;
parameter wyde = 4'd2;
parameter tbyt = 4'd3;
parameter tetra = 4'd4;
parameter ubyt = 4'd5;
parameter uwyde = 4'd6;
parameter utbyt = 4'd7;
parameter utetra = 4'd8;
//parameter byt = 3'd0;
//parameter word = 3'd1;

function CanException;
input Instruction isn;
case(isn.gen.opcode)
`LDR_D8,
`LDF_D8,`LDF_D22,`LDF_D35,
`STF_D8,`STF_D22,`STF_D35,
`LD_D8,`LD_D22,`LD_D35,
`LDB_D8,`LDB_D22,`LDB_D35,
`STC_D8,
`ST_D8,`ST_D22,`ST_D35,
`STB_D8,`STB_D22,`STB_D35:
	CanException = TRUE;
`DIV_3R:	CanException = TRUE;
default:	CanException = FALSE;
endcase
endfunction

function IsAlu;
input Instruction isn;
case(isn.gen.opcode)
`MTx,`MFx,
`ISOP,
`PERM_3R,`CSR,
`DIV_3R,
`ADD_3R,`ADD_RI22,`ADD_RI35,
`SUB_3R,`SUB_RI22,`SUB_RI35,
`MUL_3R,`MUL_RI22,`MUL_RI35,
`AND_3R,`AND_RI22,`AND_RI35,
`OR_3R,`OR_RI22,`OR_RI35,
`EOR_3R,`EOR_RI22,`EOR_RI35,
`ASL_3R,`ASR_3R,`ROL_3R,`ROR_3R,`LSR_3R,
`BIT_3R,`BIT_RI22,`BIT_RI35,
`CMP_3R,`CMP_RI22,`CMP_RI35,
`CMPU_3R,`CMPU_RI22,`CMPU_RI35:
	IsAlu = TRUE;
default:	IsAlu = FALSE;
endcase
endfunction

function IsAlu0;
input Instruction isn;
case (isn.gen.opcode)
`DIV_3R,`CSR:	IsAlu0 = TRUE;
default: IsAlu0 = FALSE;
endcase
endfunction

function IsFpu;
input Instruction isn;
case(isn.gen.opcode)
`FADD,`FSUB,`FCMP,`FMUL,`FDIV,
`FSEQ,`FSNE,`FSLT,`FSLE,
`FLT1:	IsFpu = TRUE;
default:	IsFpu = FALSE;
endcase
endfunction

function IsFpu0;
input Instruction isn;
case(isn.gen.opcode)
`FDIV:	IsFpu0 = TRUE;
`FLT1:
	case(isn.flt1.opcode)
	`FSQRT,`FTOI,`ITOF,`TRUNC:	IsFpu0 = TRUE;
	default:	IsFpu0 = FALSE;
	endcase
default:	IsFpu0 = FALSE;
endcase
endfunction

function HasConst8;
input Instruction isn;
case(isn.gen.opcode)
`ADD_3R,`SUB_3R,`MUL_3R,`DIV_3R,
`AND_3R,`OR_3R,`EOR_3R,
`BIT_3R,`CMP_3R,`CMPU_3R,
`ASL_3R,`ASR_3R,`ROL_3R,`ROR_3R,`LSR_3R,
`LDF_D8,`STF_D8,
`LD_D8,`ST_D8,`LDB_D8,`STB_D8:
	HasConst8 = TRUE;
default:	HasConst8 = FALSE;
endcase
endfunction

function HasFltConst;
input Instruction isn;
case(isn.gen.opcode)
`FADD,`FSUB,`FCMP,`FMUL,`FDIV,
`FSEQ,`FSNE,`FSLT,`FSLE:
	HasFltConst = isn.ri8.one;
default:	HasFltConst = FALSE;
endcase
endfunction

function HasConst22;
input Instruction isn;
case(isn.gen.opcode)
`ADD_RI22,`SUB_RI22,`MUL_RI22,
`AND_RI22,`OR_RI22,`EOR_RI22,
`BIT_RI22,`CMP_RI22,`CMPU_RI22,
`LDF_D22,`STF_D22,
`LD_D22,`ST_D22,`LDB_D22,`STB_D22:
	HasConst22 = TRUE;
default:	HasConst22 = FALSE;
endcase
endfunction

function HasConst35;
input Instruction isn;
case(isn.gen.opcode)
`ADD_RI35,`SUB_RI35,`MUL_RI35,
`AND_RI35,`OR_RI35,`EOR_RI35,
`BIT_RI35,`CMP_RI35,`CMPU_RI35,
`LDF_D35,`STF_D35,
`LD_D35,`ST_D35,`LDB_D35,`STB_D35:
	HasConst35 = TRUE;
default:	HasConst35 = FALSE;
endcase
endfunction

function IsMem;
input Instruction isn;
case(isn.gen.opcode)
`LDR_D8,
`LDF_D8,`LDF_D22,`LDF_D35,
`STF_D8,`STF_D22,`STF_D35,
`LD_D8,`LD_D22,`LD_D35,
`LDB_D8,`LDB_D22,`LDB_D35,
`STC_D8,
`ST_D8,`ST_D22,`ST_D35,
`STB_D8,`STB_D22,`STB_D35:
	IsMem = TRUE;
default:	IsMem = FALSE;
endcase
endfunction

function IsMemndx;
input Instruction isn;
case(isn.gen.opcode)
`LDR_D8,
`LDF_D8,
`STF_D8,
`LD_D8,
`LDB_D8,
`STC_D8,
`ST_D8,
`STB_D8:
	IsMemndx = ~isn.ri8.one;
default:	IsMemndx = FALSE;
endcase
endfunction

function IsFlowCtrl;
input Instruction isn;
case(isn.gen.opcode)
`JAL,`JAL_RN,`BRANCH0,`BRANCH1:
	IsFlowCtrl = TRUE;
`BRKGRP:
	IsFlowCtrl = TRUE;
`RETGRP:
	IsFlowCtrl = TRUE;
`STPGRP:
	IsFlowCtrl = TRUE;
default:	IsFlowCtrl = FALSE;
endcase
endfunction

function IsCmp;
input [51:0] isn;
case(isn[6:0])
`CMP_3R,`CMP_RI22,`CMP_RI35,
`CMPU_3R,`CMPU_RI22,`CMPU_RI35:
	IsCmp = TRUE;
default:	IsCmp = FALSE;
endcase
endfunction

function IsLoad;
input [51:0] isn;
case(isn[6:0])
`LDR_D8,
`LDF_D8,`LDF_D22,`LDF_D35,
`LD_D8,`LD_D22,`LD_D35,
`LDB_D8,`LDB_D22,`LDB_D35:
	IsLoad = TRUE;
default:
	IsLoad = FALSE;
endcase
endfunction

function IsStore;
input [51:0] isn;
case(isn[6:0])
`STC_D8,
`STF_D8,`STF_D22,`STF_D35,
`ST_D8,`ST_D22,`ST_D35,
`STB_D8,`STB_D22,`STB_D35:
	IsStore = TRUE;
default:
	IsStore = FALSE;
endcase
endfunction

function [3:0] MemSize;
input [51:0] isn;
casez(isn[6:0])
`LDB_D8,`LDB_D22,`LDB_D35,`STB_D8,`STB_D22,`STB_D35:	MemSize = byt;
default:	MemSize = tetra;
endcase
endfunction

function IsJal;
input Instruction isn;
IsJal = isn.gen.opcode==`JAL || isn.jalrn.opcode==`JAL_RN;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input Instruction insn;
reg [6:0] opcode = insn.gen.opcode;
IsBranch = opcode==`BRANCH0 || opcode==`BRANCH1;
endfunction

function IsRFW;
input Instruction isn;
case(isn.gen.opcode)
`BRKGRP:	IsRFW = FALSE;
`STPGRP:	IsRFW = FALSE;
`BRANCH0,`BRANCH1:	IsRFW = FALSE;
`STF_D8,`STF_D22,`STF_D35,
`ST_D8,`ST_D22,`ST_D35,`STC_D8,
`STB_D8,`STB_D22,`STB_D35:	IsRFW = FALSE;
default:	IsRFW = TRUE;
endcase
endfunction

always @*
begin
	bus <= 167'h0;
	bus[`IB_CMP] <= IsCmp(instr);
	bus[`IB_CONST] <= 
		HasFltConst(instr) ? {1'b0,11'd1015+instr[24:21],instr[20:17],36'b0} :
		HasConst8(instr) ? {{44{instr[24]}},instr[24:17]} :
		HasConst22(instr) ? {{30{instr[38]}},instr[38:17]} :
		{{17{instr[51]}},instr[51:17]}
		;
//	bus[`IB_CONST] <= {{58{instr[39]}},instr[39:35],instr[32:16]};
//	bus[`IB_RT]		 <= fnRd(instr,ven,vl,thrd) | {thrd,7'b0};
//	bus[`IB_RC]		 <= fnRc(instr,ven,thrd) | {thrd,7'b0};
//	bus[`IB_RA]		 <= fnRa(instr,ven,vl,thrd) | {thrd,7'b0};
//	bus[`IB_IMM]	 <= HasConst(instr);
	// IB_BT is now used to indicate when to update the branch target buffer.
	// This occurs when one of the instructions with an unknown or calculated
	// target is present.
	bus[`IB_BT]		 <= 1'b0;
	bus[`IB_ALU]   <= IsAlu(instr);
	bus[`IB_ALU0]  <= IsAlu0(instr);
	bus[`IB_FPU0]  <= IsFpu0(instr);
	bus[`IB_FPU]	 <= IsFpu(instr);
	bus[`IB_FC]		 <= IsFlowCtrl(instr);
//	bus[`IB_CANEX] <= fnCanException(instr);
	bus[`IB_LOAD]	 <= IsLoad(instr);
	bus[`IB_STORE]	<= IsStore(instr);
	bus[`IB_STORE_CR] <= instr.gen.opcode==`STC_D8;
	bus[`IB_MEMSZ]  <= MemSize(instr);
	bus[`IB_MEM]		<= IsMem(instr);
	bus[`IB_MEMNDX]	<= IsMemndx(instr);
	bus[`IB_JAL]		<= IsJal(instr);
	bus[`IB_BR]			<= IsBranch(instr);
	bus[`IB_BRKGRP] <= instr.gen.opcode==`BRKGRP;
	bus[`IB_RETGRP]	<= instr.gen.opcode==`RETGRP;
	bus[`IB_MEMSB]	<= instr.gen.opcode==`STPGRP && instr.stp.exop==`SYNCGRP && instr.raw[12:9]==`MEMSB;
	bus[`IB_MEMDB]	<= instr.gen.opcode==`STPGRP && instr.stp.exop==`SYNCGRP && instr.raw[12:9]==`MEMDB;
	bus[`IB_SYNC]		<= instr.gen.opcode==`STPGRP && instr.stp.exop==`SYNCGRP && instr.raw[12:9]==`SYNC;
	bus[`IB_FSYNC]	<= instr.gen.opcode==`STPGRP && instr.stp.exop==`SYNCGRP && instr.raw[12:9]==`FSYNC;
	bus[`IB_RFW]		<= IsRFW(instr);
	bus[`IB_CANEX]  <= CanException(instr);
end

endmodule

