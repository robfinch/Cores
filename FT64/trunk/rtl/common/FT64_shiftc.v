`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_shiftc.v
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
`define SHIFTC  6'h2F
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
`define HIGHWORDC    31:16

module FT64_shiftc(instr, a, b, res, ov);
parameter DMSB=15;
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

wire [31:0] shl = {16'd0,a} << b[3:0];
wire [31:0] shr = {a,16'd0} >> b[3:0];

assign ov = 1'b0;

always @*
case(opcode)
`RR:
    case(func)
    `SHIFTC:
        case(shiftop)
        `SHLI,`ASLI:	res <= shl[DMSB:0];
        `SHL,`ASL:	res <= shl[DMSB:0];
        `SHRI:	res <= shr[`HIGHWORDC];
        `SHR:	res <= shr[`HIGHWORDC];
        `ASRI:	if (a[DMSB])
                    res <= (shr[`HIGHWORDC]) | ~({16{1'b1}} >> b[3:0]);
                else
                    res <= shr[`HIGHWORDC];
        `ASR:	if (a[DMSB])
                    res <= (shr[`HIGHWORDC]) | ~({16{1'b1}} >> b[3:0]);
                else
                    res <= shr[`HIGHWORDC];
        `ROL:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDC] : 16'hDEAD;
        `ROLI:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDC] : 16'hDEAD;
        `ROR:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDC] : 16'hDEAD;
        `RORI:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDC] : 16'hDEAD;
        default: res <= 16'd0;
        endcase
    default:    res <= 16'd0;
    endcase
default:	res <= 16'd0;
endcase

endmodule

