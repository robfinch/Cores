`include "positConfig.sv"
// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positDecompose.sv
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
// ============================================================================
//
// Decompose a posit number.
module positDecompose(i, sgn, rgm, exp, sig, zer, inf);
parameter FPWID = `FPWID;
parameter es = FPWID==80 ? 3 : FPWID==64 ? 3 : FPWID==52 ? 3 : FPWID==40 ? 3 : FPWID==32 ? 2 : FPWID==20 ? 2 : FPWID==16 ? 1 : 0
input [FPWID-1:0] i;
output sgn;
output [$clog2(FPWID):0] rgm;
output [es-1:0] exp;
output [FPWID-es-1:0] sig;
output zer;
output inf;

integer n;
wire [6:0] lzcnt;
wire [6:0] locnt;


assign sgn = i[FPWID-1];
assign inf = ~|i[FPWID-2:0] & i[FPWID-1];
assign zer = ~|i;
wire [FPWID-1:0] ii = sgn ? -i : i;

wire [6:0] lzcnt, locnt;

positCntlz #(FPWID,es) u1 (.i(ii[FPWID-2:0]), .o(lzcnt));
positCntlo #(FPWID,es) u2 (.i(ii[FPWID-2:0]), .o(locnt));

assign rgm = ii[FPWID-2] ? locnt - 1 : -lzcnt;
wire [FPWID-1:0] tmp = ii << rgm;
assign exp = |es ? tmp[FPWID-2:FPWID-1-es] : 0;
assign sig = {1'b1,tmp[FPWID-2-es:0]};

endmodule

// Decompose posit number and register outputs.
module positDecomposeReg(clk, ce, i, sgn, rgm, exp, sig, zer, inf);
parameter FPWID = `FPWID;
parameter es = FPWID==80 ? 3 : FPWID==64 ? 3 : FPWID==52 ? 3 : FPWID==40 ? 3 : FPWID==32 ? 2 : FPWID==20 ? 2 : FPWID==16 ? 1 : 0
input clk;
input ce;
input [FPWID-1:0] i;
output reg sgn;
output reg [$clog2(FPWID):0] rgm;
output reg [es-1:0] exp;
output reg [FPWID-es-1:0] sig;
output reg zer;
output reg inf;

wire isgn;
wire [$clog2(FPWID):0] irgm;
wire [es-1:0] iexp;
wire [FPWID-es-1:0] isig;
wire izer;
wire iinf;

positDecompose #(FPWID) u1 (i, isgn, irgm, iexp, isig, iinf);

always @(posedge clk)
if (ce) begin
  sgn = isgn;
  rgm = irgm;
  exp = iexp;
  sig = isig;
  inf = iinf;
end

endmodule

