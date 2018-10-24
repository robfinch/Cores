// ============================================================================
// This file is not currently used.
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_predecoder.v
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

module FT64_predecoder(clk, instr, rfw, memld);
input clk;
input [47:0] instr;
output reg rfw;
output reg memld;

function IsRFW;
input [47:0] isn;
if (isn[7]==1'b1) begin
	case({instr[15:12],instr[6]})
	5'b00000:	// NOP / ADDI
		IsRFW = instr[4:0] != 5'd0;
	5'b00010:	// SYS / ORI
		IsRFW = instr[4:0] != 5'd0;
	5'b00100:	// RET / ANDI
		IsRFW = TRUE;
	5'b00110:	// SHLI
		IsRFW = instr[4:0] != 5'd0;
	5'b01000:
		IsRFW = TRUE;
	5'b01110:
		IsRFW = FALSE;
	5'b10??0:
		IsRFW = FALSE;
	5'b11??0:
		IsRFW = FALSE;
	5'b00001:
		IsRFW = {instr[11:8],instr[5]} != 5'd0;
	5'b00011:	// ADD
		IsRFW = instr[4:0] != 5'd0;
	5'b00101:	// JALR
		IsRFW = {instr[11:8],instr[5]} != 5'd0;
	5'b01001:	// LH Rt,d[SP]
		IsRFW = instr[4:0] != 5'd0;
	5'b01011:	// LW Rt,d[SP]
		IsRFW = instr[4:0] != 5'd0;
	5'b01101:	// LH Rt,d[fP]
		IsRFW = instr[4:0] != 5'd0;
	5'b01111:	// LW Rt,d[FP]
		IsRFW = instr[4:0] != 5'd0;
	5'b10001:	// SH Rt,d[SP]
		IsRFW = FALSE;
	5'b10011:	// SW Rt,d[SP]
		IsRFW = FALSE;
	5'b10101:	// SH Rt,d[fP]
		IsRFW = FALSE;
	5'b10111:	// SW Rt,d[FP]
		IsRFW = FALSE;
	5'b11001:
		IsRFW = TRUE;
	5'b11011:	// LW
		IsRFW = TRUE;
	5'b11101:	// SH
		IsRFW = FALSE;
	5'b11111:	// SW
		IsRFW = FALSE;
	default:
		IsRFW = FALSE;
	endcase
end
else
casez(isn[`INSTRUCTION_OP])
`IVECTOR:   IsRFW = TRUE;
`FVECTOR:   IsRFW = TRUE;
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case(isn[`INSTRUCTION_S2])
	    `R1:    IsRFW = TRUE;
	    `ADD:   IsRFW = TRUE;
	    `SUB:   IsRFW = TRUE;
	    `SLT:   IsRFW = TRUE;
	    `SLTU:  IsRFW = TRUE;
	    `SLE:   IsRFW = TRUE;
        `SLEU:  IsRFW = TRUE;
	    `AND:   IsRFW = TRUE;
	    `OR:    IsRFW = TRUE;
	    `XOR:   IsRFW = TRUE;
	    `MULU:  IsRFW = TRUE;
	    `MULSU: IsRFW = TRUE;
	    `MUL:   IsRFW = TRUE;
	    `MULUH:  IsRFW = TRUE;
	    `MULSUH: IsRFW = TRUE;
	    `MULH:   IsRFW = TRUE;
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
	else
		IsRFW = FALSE;
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00) begin
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
    `LWRX:  IsRFW = TRUE;
    `LVX:   IsRFW = TRUE;
    default:	IsRFW = FALSE;
    endcase
		case({isn[31:28],isn[17:16]})
    `CASX:  IsRFW = TRUE;
    default:    IsRFW = FALSE;
    endcase
	end
	else
		IsRFW = FALSE;
`BBc:	IsRFW = FALSE;
`BITFIELD:  IsRFW = TRUE;
`ADDI:      IsRFW = TRUE;
`SLTI:      IsRFW = TRUE;
`SLTUI:     IsRFW = TRUE;
`SGTI:      IsRFW = TRUE;
`SGTUI:     IsRFW = TRUE;
`ANDI:      IsRFW = TRUE;
`ORI:       IsRFW = TRUE;
`XORI:      IsRFW = TRUE;
`MULUI:     IsRFW = TRUE;
`MULI:      IsRFW = TRUE;
`DIVUI:     IsRFW = TRUE;
`DIVI:      IsRFW = TRUE;
`MODI:      IsRFW = TRUE;
`JAL:       IsRFW = TRUE;
`CALL:      IsRFW = TRUE;  
`RET:       IsRFW = TRUE; 
`LB:        IsRFW = TRUE;
`LBU:       IsRFW = TRUE;
`Lx:        IsRFW = TRUE;
`LWR:       IsRFW = TRUE;
`LV:        IsRFW = TRUE;
`LVx:				IsRFW = TRUE;
`CAS:       IsRFW = TRUE;
`AMO:				IsRFW = TRUE;
`CSRRW:			IsRFW = TRUE;
`AUIPC:			IsRFW = TRUE;
`LUI:				IsRFW = TRUE;
default:    IsRFW = FALSE;
endcase
endfunction

function IsLoad;
input [47:0] isn;
if (isn[7]==1'b1)
	case({instr[15:12],instr[6]})
	5'b01001:	// LH Rt,d[SP]
		IsLoad = TRUE;
	5'b01011:	// LW Rt,d[SP]
		IsLoad = TRUE;
	5'b01101:	// LH Rt,d[fP]
		IsLoad = TRUE;
	5'b01111:	// LW Rt,d[FP]
		IsLoad = TRUE;
	5'b11001:
		IsLoad = TRUE;
	5'b11011:	// LW
		IsLoad = TRUE;
	default:
		IsLoad = FALSE;
	endcase
else
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
    case({isn[31:28],isn[22:21]})
    `LBX:   IsLoad = TRUE;
    `LBUX:  IsLoad = TRUE;
    `LCX:   IsLoad = TRUE;
    `LCUX:  IsLoad = TRUE;
    `LHX:   IsLoad = TRUE;
    `LHUX:  IsLoad = TRUE;
    `LWX:   IsLoad = TRUE;
    `LVBX:	IsLoad = TRUE;
    `LVBUX: IsLoad = TRUE;
    `LVCX:  IsLoad = TRUE;
    `LVCUX: IsLoad = TRUE;
    `LVHX:  IsLoad = TRUE;
    `LVHUX: IsLoad = TRUE;
    `LVWX:  IsLoad = TRUE;
    `LWRX:  IsLoad = TRUE;
    `LVX:   IsLoad = TRUE;
    default: IsLoad = FALSE;   
    endcase
	else
		IsLoad = FALSE;
`LB:    IsLoad = TRUE;
`LBU:   IsLoad = TRUE;
`Lx:    IsLoad = TRUE;
`LxU:   IsLoad = TRUE;
`LWR:   IsLoad = TRUE;
`LV:    IsLoad = TRUE;
`LVx:   IsLoad = TRUE;
default:    IsLoad = FALSE;
endcase
endfunction

always @(posedge clk)
	rfw <= IsRFW(instr);
always @(posedge clk)
	memld <= IsLoad(instr);

endmodule
