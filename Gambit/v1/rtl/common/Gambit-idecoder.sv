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
`include ".\rtf65004-config.sv"
`include ".\rtf65004-defines.sv"

module idecoder(instr,predict_taken,bus);
input [23:0] instr;
input predict_taken;
output reg [`IBTOP:0] bus;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tbyt = 3'd2;

function IsAlu;
input [23:0] isn;
case(isn[23:16])
`UO_NOP,
`UO_LDIB,`UO_ADDW,`UO_ADDB,
`UO_ADCB,`UO_SBCB,`UO_CMPB,
`UO_ANDB,`UO_BITB,`UO_ORB,`UO_EORB,
`UO_ASLB,`UO_LSRB,`UO_RORB,`UO_ROLB,
`UO_SEC,`UO_CLC,`UO_SEI,`UO_CLI,`UO_CLV,
`UO_SED,`UO_CLD,`UO_SEB,`UO_CLB,
`UO_MOV,`UO_XCE:
	IsAlu = TRUE;
default:	IsAlu = FALSE;
endcase
endfunction

function IsMem;
input [23:0] isn;
case(isn[23:16])
`UO_LDBW,`UO_LDWW,`UO_STBW,`UO_STWW,`UO_STJ,
`UO_LDB,`UO_LDW,`UO_STB,`UO_STW:
	IsMem = TRUE;
default:
	IsMem = FALSE;
endcase
endfunction

function IsFcu;
input [23:0] isn;
case(isn[23:16])
`UO_BEQ,`UO_BNE,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BMI,`UO_BPL,`UO_BRA,
`UO_JSI,`UO_JMP,`UO_JML:
	IsFcu = TRUE;
default:	IsFcu = FALSE;
endcase
endfunction

function IsCmp;
input [23:0] isn;
case(isn[23:16])
`UO_CMPB:	IsCmp = TRUE;
default:	IsCmp = FALSE;
endcase
endfunction

function IsLoad;
input [23:0] isn;
case(isn[23:16])
`UO_LDB,`UO_LDW,`UO_LDBW,`UO_LDWW:
	IsLoad = TRUE;
default:
	IsLoad = FALSE;
endcase
endfunction

function IsStore;
input [23:0] isn;
case(isn[23:16])
`UO_STB,`UO_STW,`UO_STBW,`UO_STWW,`UO_STJ:
	IsStore = TRUE;
default:
	IsStore = FALSE;
endcase
endfunction


function [2:0] MemSize;
input [23:0] isn;
casez(isn[23:16])
`UO_LDB,`UO_LDBW:	MemSize = byt;
`UO_LDW,`UO_LDWW:	MemSize = wyde;
`UO_STB,`UO_STBW:	MemSize = byt;
`UO_STW,`UO_STWW:	MemSize = wyde;
`UO_STJ:					MemSize = tbyt;
default:	MemSize = byt;
endcase
endfunction

function IsSei;
input [23:0] isn;
IsSei = isn[23:16]==`UO_SEI;
endfunction

function IsJmp;
input [23:0] isn;
IsJmp = isn[23:0]==`UO_JMP;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [23:0] isn;
case(isn[23:16])
`UO_BEQ,`UO_BNE,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BMI,`UO_BPL,`UO_BRA:
	IsBranch = TRUE;
default:
	IsBranch = FALSE;
endcase
endfunction

function IsRFW;
input [23:0] isn;
case(isn[23:16])
`UO_LDB,`UO_LDW,`UO_LDBW,`UO_LDWW,
`UO_ADDB,`UO_ADDW,`UO_ADCB,`UO_SBCB,
`UO_ANDB,`UO_ORB,`UO_EORB,
`UO_ASLB,`UO_LSRB,`UO_ROLB,`UO_RORB,
`UO_MOV:
	IsRFW = TRUE;
default:
	IsRFW = FALSE;
endcase
endfunction

function fnNeedSr;
input [23:0] isn;
fnNeedSr = TRUE;
/*
case(isn[23:16])
`UO_STB,`UO_STBW:
	fnNeedSr = isn[5:3]==`UO_SR;
`UO_ADCB,`UO_SBCB,`UO_ROLB,`UO_RORB:	// carry input
	fnNeedSr = TRUE;
`UO_BEQ,`UO_BNE,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BMI,`UO_BPL:
	fnNeedSr = TRUE;
default:
	fnNeedSr = FALSE;
endcase
*/
endfunction

function fnWrap;
input [23:0] isn;
case(isn[23:16])
`UO_LDBW,`UO_STBW,`UO_LDWW,`UO_STWW:	fnWrap = TRUE;
default:	fnWrap = FALSE;
endcase
endfunction

always @*
begin
	bus <= 167'h0;
	bus[`IB_CMP] <= IsCmp(instr);
//	bus[`IB_CONST] <= {{58{instr[39]}},instr[39:35],instr[32:16]};
//	bus[`IB_RT]		 <= fnRd(instr,ven,vl,thrd) | {thrd,7'b0};
//	bus[`IB_RC]		 <= fnRc(instr,ven,thrd) | {thrd,7'b0};
//	bus[`IB_RA]		 <= fnRa(instr,ven,vl,thrd) | {thrd,7'b0};
	bus[`IB_SRC1]		 <= instr[7:4];
	bus[`IB_SRC2]		 <= instr[3:0];
	bus[`IB_DST]		 <= instr[11:8];
//	bus[`IB_IMM]	 <= HasConst(instr);
	// IB_BT is now used to indicate when to update the branch target buffer.
	// This occurs when one of the instructions with an unknown or calculated
	// target is present.
	bus[`IB_BT]		 <= 1'b0;
	bus[`IB_ALU]   <= IsAlu(instr);
	bus[`IB_FC]		 <= IsFcu(instr);
//	bus[`IB_CANEX] <= fnCanException(instr);
	bus[`IB_LOAD]	 <= IsLoad(instr);
	bus[`IB_STORE]	<= IsStore(instr);
	bus[`IB_MEMSZ]  <= MemSize(instr);
	bus[`IB_MEM]		<= IsMem(instr);
	bus[`IB_SEI]		<= IsSei(instr);
	bus[`IB_JMP]		<= IsJmp(instr);
	bus[`IB_BR]			<= IsBranch(instr);
	bus[`IB_RFW]		<= IsRFW(instr);
	bus[`IB_NEED_SR]	<= fnNeedSr(instr);
	bus[`IB_WRAP]		<= fnWrap(instr);
end

endmodule

