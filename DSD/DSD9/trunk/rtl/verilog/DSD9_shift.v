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
`define SHL     8'h30
`define SHR     8'h31
`define ASL     8'h32
`define ASR     8'h33
`define ROL     8'h34
`define ROR     8'h35
`define SHLI    8'h40
`define SHRI    8'h41
`define ASLI    8'h42
`define ASRI    8'h43
`define ROLI    8'h44
`define RORI    8'h45

`define HIGHWORD    159:80
`endif

module DSD9_shift(xir, a, b, res, rolo);
parameter DMSB=79;
input [39:0] xir;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output [DMSB:0] rolo;
parameter ROTATE_INSN = 1;

wire [7:0] xopcode = xir[7:0];
wire [7:0] xfunc = xir[39:32];

wire [159:0] shl = {80'd0,a} << b[6:0];
wire [159:0] shr = {a,80'd0} >> b[6:0];

always @*
case(xopcode)
`R2:
	case(xfunc)
	`SHLI:	res <= shl[DMSB:0];
	`SHL:	res <= shl[DMSB:0];
	`SHRI:	res <= shr[`HIGHWORD];
	`SHR:	res <= shr[`HIGHWORD];
	`ASRI:	if (a[DMSB])
				res <= (shr[`HIGHWORD]) | ~({80{1'b1}} >> b[6:0]);
			else
				res <= shr[`HIGHWORD];
	`ASR:	if (a[DMSB])
				res <= (shr[`HIGHWORD]) | ~({80{1'b1}} >> b[6:0]);
			else
				res <= shr[`HIGHWORD];
    `ROL:	res <= ROTATE_INSN ? shl[79:0]|shl[`HIGHWORD] : 80'hDEADDEADDEAD;
    `ROLI:	res <= ROTATE_INSN ? shl[79:0]|shl[`HIGHWORD] : 80'hDEADDEADDEAD;
    `ROR:	res <= ROTATE_INSN ? shr[79:0]|shr[`HIGHWORD] : 80'hDEADDEADDEAD;
    `RORI:	res <= ROTATE_INSN ? shr[79:0]|shr[`HIGHWORD] : 80'hDEADDEADDEAD;
    default: res <= 80'd0;
    endcase
default:	res <= 80'd0;
endcase

endmodule

