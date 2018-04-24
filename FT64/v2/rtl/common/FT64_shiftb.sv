`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_shiftb.v
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
`define RR      6'h02
`define SHIFTB  6'h1F
`define SHL     4'h0
`define SHR     4'h1
`define ASL     4'h2
`define ASR     4'h3
`define ROL     4'h4
`define ROR     4'h5
`define SHLI    4'h8
`define SHRI    4'h9
`define ASLI    4'hA
`define ASRI    4'hB
`define ROLI    4'hC
`define RORI    4'hD
//`endif
`define HIGHWORDB    15:8

module FT64_shiftb(instr, a, b, res, ov);
parameter DMSB=7;
input [31:0] instr;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output ov;
parameter ROTATE_INSN = 1;

wire [5:0] opcode = instr[5:0];
wire [5:0] func = instr[31:26];
wire [3:0] shiftop = instr[25:22];

wire [15:0] shl = {8'd0,a} << b[2:0];
wire [15:0] shr = {a,8'd0} >> b[2:0];

assign ov = 1'b0;

always @*
case(opcode)
`RR:
    case(func)
    `SHIFTB:
        case(shiftop)
        `SHLI,`ASLI:	res <= shl[DMSB:0];
        `SHL,`ASL:	res <= shl[DMSB:0];
        `SHRI:	res <= shr[`HIGHWORDB];
        `SHR:	res <= shr[`HIGHWORDB];
        `ASRI:	if (a[DMSB])
                    res <= (shr[`HIGHWORDB]) | ~({8{1'b1}} >> b[2:0]);
                else
                    res <= shr[`HIGHWORDB];
        `ASR:	if (a[DMSB])
                    res <= (shr[`HIGHWORDB]) | ~({8{1'b1}} >> b[2:0]);
                else
                    res <= shr[`HIGHWORDB];
        `ROL:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDB] : 8'hDE;
        `ROLI:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDB] : 8'hDE;
        `ROR:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDB] : 8'hDE;
        `RORI:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDB] : 8'hDE;
        default: res <= 8'd0;
        endcase
    default:    res <= 8'd0;
    endcase
default:	res <= 8'd0;
endcase

endmodule

