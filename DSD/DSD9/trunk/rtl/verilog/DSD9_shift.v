`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD9_shift.v
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
`ifndef SHL
`define R2      8'h02
`define SHL     8'h40
`define SHR     8'h42
`define ASR     8'h44
`define ROL     8'h41
`define ROR     8'h43
`define SHLI    8'h50
`define SHRI    8'h52
`define ASRI    8'h54
`define ROLI    8'h51
`define RORI    8'h53

`define HIGHWORD    95:48
`endif

module DSD9_shift(xir, a, b, res, rolo);
parameter DMSB=47;
input [39:0] xir;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output [DMSB:0] rolo;
parameter ROTATE_INSN = 1;

wire [7:0] xopcode = xir[7:0];
wire [7:0] xfunc = xir[39:32];

wire isImm = xfunc==`SHLI || xfunc==`SHRI || xfunc==`ASRI || xfunc==`ROLI || xfunc==`RORI;
wire [5:0] imm = xir[21:16];

wire [95:0] shl = {48'd0,a} << (isImm ? imm : b[5:0]);
wire [95:0] shr = {a,48'd0} >> (isImm ? imm : b[5:0]);

always @*
case(xopcode)
`R2:
	case(xfunc)
	`SHLI:	res <= shl[DMSB:0];
	`SHL:	res <= shl[DMSB:0];
	`SHRI:	res <= shr[`HIGHWORD];
	`SHR:	res <= shr[`HIGHWORD];
	`ASRI:	if (a[DMSB])
				res <= (shr[`HIGHWORD]) | ~(48'hFFFFFFFFFFFF >> imm);
			else
				res <= shr[`HIGHWORD];
	`ASR:	if (a[DMSB])
				res <= (shr[`HIGHWORD]) | ~(48'hFFFFFFFFFFFF >> b[5:0]);
			else
				res <= shr[`HIGHWORD];
    `ROL:	res <= ROTATE_INSN ? shl[31:0]|shl[`HIGHWORD] : 48'hDEADDEADDEAD;
    `ROLI:	res <= ROTATE_INSN ? shl[31:0]|shl[`HIGHWORD] : 48'hDEADDEADDEAD;
    `ROR:	res <= ROTATE_INSN ? shr[31:0]|shr[`HIGHWORD] : 48'hDEADDEADDEAD;
    `RORI:	res <= ROTATE_INSN ? shr[31:0]|shr[`HIGHWORD] : 48'hDEADDEADDEAD;
    default: res <= 48'd0;
    endcase
default:	res <= 48'd0;
endcase

endmodule

