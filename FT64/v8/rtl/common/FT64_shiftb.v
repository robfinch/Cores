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
`define R2      6'h02
`define SHL     3'h0
`define SHR     3'h1
`define ASL     3'h2
`define ASR     3'h3
`define ROL     3'h4
`define ROR     3'h5
//`endif
`define HIGHWORDB    15:8

module FT64_shiftb(instr, a, b, res, ov);
parameter DMSB=7;
input [47:0] instr;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output ov;
parameter ROTATE_INSN = 1;

wire [5:0] opcode = instr[5:0];
wire [3:0] shiftop = instr[35:33];
wire [2:0] bb = instr[29] ? instr[15:13] : b[2:0];

wire [15:0] shl = {8'd0,a} << bb[2:0];
wire [15:0] shr = {a,8'd0} >> bb[2:0];

assign ov = 1'b0;

always @*
case(opcode)
`R2:
	if (instr[7:6]==2'b01)
    case(shiftop)
    `SHL,`ASL:	res <= shl[DMSB:0];
    `SHR:	res <= shr[`HIGHWORDB];
    `ASR:	if (a[DMSB])
                res <= (shr[`HIGHWORDB]) | ~({8{1'b1}} >> bb[2:0]);
            else
                res <= shr[`HIGHWORDB];
    `ROL:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDB] : 8'hDE;
    `ROR:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDB] : 8'hDE;
    default: res <= 8'd0;
    endcase
default:	res <= 8'd0;
endcase

endmodule

