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
`include "positConfig.sv"

// Decompose a posit number.
module positDecompose(i, sgn, rgs, rgm, exp, sig, zer, inf);
`include "positSize.sv"
localparam rs = $clog2(PSTWID-1);
input [PSTWID-1:0] i;
output sgn;                       // sign of number
output rgs;                       // sign of regime
output [rs:0] rgm;   // regime (absolute value)
output [es-1:0] exp;              // exponent
output [PSTWID-1-es:0] sig;       // significand
output zer;                       // number is zero
output inf;                       // number is infinite

wire [rs-1:0] lzcnt;
wire [rs-1:0] locnt;


assign sgn = i[PSTWID-1];
assign inf = ~|i[PSTWID-2:0] & i[PSTWID-1];
assign zer = ~|i;
wire [PSTWID-1:0] ii = sgn ? -i : i;
assign rgs = ii[PSTWID-2];

positCntlz #(PSTWID) u1 (.i(ii[PSTWID-2:0]), .o(lzcnt));
positCntlo #(PSTWID) u2 (.i(ii[PSTWID-2:0]), .o(locnt));

assign rgm = rgs ? locnt - 1 : lzcnt;
wire [rs:0] shamt = rgs ? locnt + 2'd1 : lzcnt + 2'd1;
wire [PSTWID-1:0] tmp = ii << shamt;
assign exp = |es ? tmp[PSTWID-2:PSTWID-1-es] : 0;
assign sig = {~zer,tmp[PSTWID-2-es:0]};

endmodule

// Decompose posit number and register outputs.
module positDecomposeReg(clk, ce, i, sgn, rgs, rgm, exp, sig, zer, inf);
`include "positSize.sv"
input clk;
input ce;
input [PSTWID-1:0] i;
output reg sgn;
output reg rgs;
output reg [$clog2(PSTWID)-1:0] rgm;
output reg [es-1:0] exp;
output reg [PSTWID-es-1:0] sig;
output reg zer;
output reg inf;

wire isgn;
wire irgs;
wire [$clog2(PSTWID)-1:0] irgm;
wire [es-1:0] iexp;
wire [PSTWID-es-1:0] isig;
wire izer;
wire iinf;

positDecompose #(PSTWID) u1 (i, isgn, irgs, irgm, iexp, isig, iinf);

always @(posedge clk)
if (ce) begin
  sgn = isgn;
  rgs = irgs;
  rgm = irgm;
  exp = iexp;
  sig = isig;
  inf = iinf;
end

endmodule

