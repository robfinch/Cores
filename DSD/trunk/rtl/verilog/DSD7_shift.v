`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_shift.v
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
`define R2      6'h0C
`define SHL     6'h10
`define SHR     6'h11
`define ASR     6'h12
`define ROL     6'h13
`define ROR     6'h14
`define SHLI    6'h18
`define SHRI    6'h19
`define ASRI    6'h1A
`define ROLI    6'h1B
`define RORI    6'h1C

module DSD7_shift(xir, a, b, res, rolo);
input [31:0] xir;
input [31:0] a;
input [31:0] b;
output [31:0] res;
reg [31:0] res;
output [31:0] rolo;
parameter ROTATE_INSN = 1;

wire [5:0] xopcode = xir[5:0];
wire [5:0] xfunc = xir[31:26];

wire isImm = xfunc==`SHLI || xfunc==`SHRI || xfunc==`ASRI || xfunc==`ROLI || xfunc==`RORI;
wire [4:0] imm = xir[15:11];

wire [63:0] shl = {32'd0,a} << (isImm ? imm : b[4:0]);
wire [63:0] shr = {a,32'd0} >> (isImm ? imm : b[4:0]);

always @*
case(xopcode)
`R2:
	case(xfunc)
	`SHLI:	res <= shl[31:0];
	`SHL:	res <= shl[31:0];
	`SHRI:	res <= shr[63:32];
	`SHR:	res <= shr[63:32];
	`ASRI:	if (a[31])
				res <= (shr[63:32]) | ~(32'hFFFFFFFF >> imm);
			else
				res <= shr[63:32];
	`ASR:	if (a[31])
				res <= (shr[63:32]) | ~(32'hFFFFFFFF >> b[4:0]);
			else
				res <= shr[63:32];
    `ROL:	res <= ROTATE_INSN ? shl[31:0]|shl[63:32] : 32'hDEADDEAD;
    `ROLI:	res <= ROTATE_INSN ? shl[31:0]|shl[63:32] : 32'hDEADDEAD;
    `ROR:	res <= ROTATE_INSN ? shr[31:0]|shr[63:32] : 32'hDEADDEAD;
    `RORI:	res <= ROTATE_INSN ? shr[31:0]|shr[63:32] : 32'hDEADDEAD;
    default: res <= 32'd0;
    endcase
default:	res <= 32'd0;
endcase

endmodule

