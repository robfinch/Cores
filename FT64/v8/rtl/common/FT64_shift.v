`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_shift.v
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
//
// ============================================================================
//
//`ifndef SHL
`define IVECTOR  6'h01
`define VSHL        6'h0C
`define VSHR        6'h0D
`define VASR        6'h0E
`define RR      6'h02
`define SHIFTR  6'h2F
`define SHIFT31	6'h0F
`define SHIFT63	6'h1F
`define AMO		6'h2F
`define AMOSHL		6'h0C
`define AMOSHR		6'h0D
`define AMOASR		6'h0E
`define AMOROL		6'h0F
`define AMOSHLI		6'h2C
`define AMOSHRI		6'h2D
`define AMOASRI		6'h2E
`define AMOROLI		6'h2F
`define SHL     3'h0
`define SHR     3'h1
`define ASL     3'h2
`define ASR     3'h3
`define ROL     3'h4
`define ROR     3'h5
//`endif
`define HIGHWORD    127:64

module FT64_shift(instr, a, b, res, ov);
parameter DMSB=63;
parameter SUP_VECTOR = 1;
input [47:0] instr;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output ov;
parameter ROTATE_INSN = 1;

wire [5:0] opcode = instr[5:0];
wire [5:0] func = instr[31:26];
wire [2:0] shiftop = instr[25:23];

wire [127:0] shl = {64'd0,a} << b[5:0];
wire [127:0] shr = {a,64'd0} >> b[5:0];

assign ov = shl[127:64] != {64{a[63]}};

always @*
case(opcode)
`IVECTOR:
    if (SUP_VECTOR)
        case(func)
        `VSHL:      res <= shl[DMSB:0];
        `VSHR:      res <= shr[`HIGHWORD]; 
        `VASR:	    if (a[DMSB])
                        res <= (shr[`HIGHWORD]) | ~({64{1'b1}} >> b[5:0]);
                    else
                        res <= shr[`HIGHWORD];
        default:    res <= 64'd0;
        endcase
    else
        res <= 64'd0;
`RR:
    case(func)
    `SHIFTR:
        case(shiftop)
        `SHL,`ASL:	res <= shl[DMSB:0];
        `SHR:	res <= shr[`HIGHWORD];
        `ASR:	if (a[DMSB])
                    res <= (shr[`HIGHWORD]) | ~({64{1'b1}} >> b[5:0]);
                else
                    res <= shr[`HIGHWORD];
        `ROL:	res <= ROTATE_INSN ? shl[63:0]|shl[`HIGHWORD] : 64'hDEADDEADDEAD;
        `ROR:	res <= ROTATE_INSN ? shr[63:0]|shr[`HIGHWORD] : 64'hDEADDEADDEAD;
        default: res <= 64'd0;
        endcase
    `SHIFT31,
    `SHIFT63:
        case(shiftop)
        `SHL,`ASL:res <= shl[DMSB:0];
        `SHR:	res <= shr[`HIGHWORD];
        `ASR:	if (a[DMSB])
                    res <= (shr[`HIGHWORD]) | ~({64{1'b1}} >> b[5:0]);
                else
                    res <= shr[`HIGHWORD];
        `ROL:	res <= ROTATE_INSN ? shl[63:0]|shl[`HIGHWORD] : 64'hDEADDEADDEAD;
        `ROR:	res <= ROTATE_INSN ? shr[63:0]|shr[`HIGHWORD] : 64'hDEADDEADDEAD;
        default: res <= 64'd0;
        endcase
    default:    res <= 64'd0;
    endcase
`AMO:
	case(func)
	`AMOSHL,`AMOSHLI:	res <= shl[DMSB:0];
	`AMOSHR,`AMOSHRI:	res <= shr[`HIGHWORD];
	`AMOASR,`AMOASRI:	if (a[DMSB])
                    		res <= (shr[`HIGHWORD]) | ~({64{1'b1}} >> b[5:0]);
                		else
                    		res <= shr[`HIGHWORD];
    `AMOROL:	res <= ROTATE_INSN ? shl[63:0]|shl[`HIGHWORD] : 64'hDEADDEADDEAD;
    `AMOROLI:	res <= ROTATE_INSN ? shl[63:0]|shl[`HIGHWORD] : 64'hDEADDEADDEAD;
	default:	res <= 64'd0;
	endcase
default:	res <= 64'd0;
endcase

endmodule

