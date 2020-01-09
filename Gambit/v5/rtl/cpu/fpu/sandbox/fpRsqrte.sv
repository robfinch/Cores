// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpRsqrte.v
//		- reciprocal square root estimate
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

`define POINT5			32'h3F000000
`define ONEPOINT5		32'h3FC00000
`define FRSQRTE_MAGIC		32'h5f3759df

module fpRsqrte(clk, ce, a, o);
parameter FPWID = 32;
localparam MSB = FPWID-1;
localparam EMSB = FPWID==128 ? 14 :
                  FPWID==96 ? 14 :
                  FPWID==80 ? 14 :
                  FPWID==64 ? 10 :
				  FPWID==52 ? 10 :
				  FPWID==48 ? 11 :
				  FPWID==44 ? 10 :
				  FPWID==42 ? 10 :
				  FPWID==40 ?  9 :
				  FPWID==32 ?  7 :
				  FPWID==24 ?  6 : 4;
localparam FMSB = FPWID==128 ? 111 :
                  FPWID==96 ? 79 :
                  FPWID==80 ? 63 :
                  FPWID==64 ? 51 :
				  FPWID==52 ? 39 :
				  FPWID==48 ? 34 :
				  FPWID==44 ? 31 :
				  FPWID==42 ? 29 :
				  FPWID==40 ? 28 :
				  FPWID==32 ? 22 :
				  FPWID==24 ? 15 : 9;
input clk;
input ce;
input [FPWID-1:0] a;
output reg [FPWID-1:0] o;

// An implementation of the approximation used in the Quake game.

wire [31:0] x2, x2yy, x2yy1p5;
wire [31:0] y, yy;

fpMulnr #(32) u1 (clk, ce, a, `POINT5, x2);
assign y = `FRSQRTE_MAGIC - a[31:1];
fpMulnr #(32) u2 (clk, ce, y, y, yy);
fpMulnr #(32) u3 (clk, ce, x2, yy, x2yy);
fpAddsubnr #(32) u4 (clk, ce, 3'd0, 1'b1, `ONEPOINT5, x2yy, x2yy1p5);
fpMulnr #(32) u5 (clk, ce, y, x2yy1p5, o);

endmodule
