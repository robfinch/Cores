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
`define R2      6'h02
`define SHL     3'h0
`define SHR     3'h1
`define ASL     3'h2
`define ASR     3'h3
`define ROL     3'h4
`define ROR     3'h5
//`endif
`define HIGHWORDC    31:16

module FT64_shiftc(instr, a, b, res, ov);
parameter DMSB=15;
input [47:0] instr;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output ov;
parameter ROTATE_INSN = 1;

wire [5:0] opcode = instr[5:0];
wire [5:0] func = instr[31:26];
wire [3:0] shiftop = instr[35:33];
wire [3:0] bb = instr[29] ? instr[16:13] : b[3:0];
wire [31:0] shl = {16'd0,a} << bb;
wire [31:0] shr = {a,16'd0} >> bb;

assign ov = 1'b0;

always @*
case(opcode)
`RR:
  case(shiftop)
  `SHL,`ASL:	res <= shl[DMSB:0];
  `SHR:	res <= shr[`HIGHWORDC];
  `ASR:	if (a[DMSB])
              res <= (shr[`HIGHWORDC]) | ~({16{1'b1}} >> bb);
          else
              res <= shr[`HIGHWORDC];
  `ROL:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDC] : 16'hDEAD;
  `ROR:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDC] : 16'hDEAD;
  default: res <= 16'd0;
  endcase
default:	res <= 16'd0;
endcase

endmodule

