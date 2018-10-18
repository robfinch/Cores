`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_shifth.v
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
`define HIGHWORDH    63:32

module FT64_shifth(instr, a, b, res, ov);
parameter DMSB=31;
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
wire [4:0] bb = instr[29] ? instr[17:13] : b[4:0];
wire [63:0] shl = {32'd0,a} << bb;
wire [63:0] shr = {a,32'd0} >> bb;

assign ov = 1'b0;

always @*
case(opcode)
`R2:
  case(shiftop)
  `SHL,`ASL:	res <= shl[DMSB:0];
  `SHR:	res <= shr[`HIGHWORDH];
  `ASR:	if (a[DMSB])
              res <= (shr[`HIGHWORDH]) | ~({32{1'b1}} >> bb);
          else
              res <= shr[`HIGHWORDH];
  `ROL:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDH] : 32'hDEADDEAD;
  `ROR:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDH] : 32'hDEADDEAD;
  default: res <= 32'd0;
  endcase
`AMO:
	case(func)
	`AMOSHL,`AMOSHLI:	res <= shl[DMSB:0];
	`AMOSHR,`AMOSHRI:	res <= shr[`HIGHWORDH];
	`AMOASR,`AMOASRI:	if (a[DMSB])
                    		res <= (shr[`HIGHWORDH]) | ~({32{1'b1}} >> b[4:0]);
                		else
                    		res <= shr[`HIGHWORDH];
    `AMOROL:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDH] : 32'hDEADDEAD;
    `AMOROLI:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDH] : 32'hDEADDEAD;
	default:	res <= 32'd0;
	endcase
default:	res <= 32'd0;
endcase

endmodule

