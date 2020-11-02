// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positToInt.sv
//    - posit number to integer convertor
//    - can issue every clock cycle
//    - parameterized width
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

import posit::*;

module positToInt(clk, ce, i, o);
input clk;
input ce;
input [PSTWID-1:0] i;
output reg [PSTWID-1:0] o;

localparam N = PSTWID;
localparam Bs = $clog2(PSTWID-1);

wire sgn;
wire rgs;
wire [Bs-1:0] rgm;
wire [es-1:0] exp;
wire [N-es-1:0] sig;
wire zer;
wire inf;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

positDecomposeReg #(.PSTWID(PSTWID)) u1 (
  .clk(clk),
  .ce(ce),
  .i(i),
  .sgn(sgn),
  .rgs(rgs),
  .rgm(rgm),
  .exp(exp),
  .sig(sig),
  .zer(zer),
  .inf(inf)
 );

wire [N-1:0] m = {sig,{es{1'b0}}};
wire isZero = zer;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #2
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [15:0] argm2;
reg [es-1:0] exp2;
reg [N-1:0] m2;
always @(posedge clk)
  if (ce) exp2 <= exp;
always @(posedge clk)
  if (ce) m2 <= m;
always @(posedge clk)
  if (ce) argm2 <= rgs ? rgm : -rgm;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #3
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [15:0] ex3;
reg [N-1:0] m3;
always @(posedge clk)
  if (ce) ex3 <= (argm2 << es) + exp2;
always @(posedge clk)
  if (ce) m3 <= m2;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #4
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg exv4;
reg [15:0] ex4;
reg [N*2-1:0] mo4;
always @(posedge clk)
  if (ce) exv4 <= ~ex3[15] && ex3 > PSTWID-1;
always @(posedge clk)
  if (ce) ex4 <= ex3;
always @(posedge clk)
  if (ce) mo4 = {m3,{N{1'b0}}} >> (PSTWID-ex3-1);
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #5
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [15:0] ex5;
reg [N*2-1:0] mo5;
reg L, G, R, St;
always @(posedge clk)
  if (ce) ex5 <= ex4;
always @(posedge clk)
  if (ce) mo5 = mo4;
always @(posedge clk)
  if (ce) L <= mo4[N];
always @(posedge clk)
  if (ce) G <= mo4[N-1];
always @(posedge clk)
  if (ce) R <= mo4[N-2];
always @(posedge clk)
  if (ce) St <= |mo4[N-3:0];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #6
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// If regime+exp == -1 then the value is 0.5 or greater, so round up.
// If the regime+exp < -1 then the values is 0.25 or less, do not round up.
// Otherwise use rounding rules.
reg [N*2-1:0] mo6;
reg ulp;
always @(posedge clk)
  if (ce) mo6 = mo5;
always @(posedge clk)
  if (ce) ulp <= (~ex5[15] && ((G & (R | St)) | (L & G & ~(R | St)))) ||
              (ex5==16'hFFFF);
wire [PSTWID-1:0] rnd_ulp = {{PSTWID-1{1'b0}},ulp};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #7
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [PSTWID-1:0] tmp7;
wire rgs6;
delay #(.WID(1), .DEP(5)) ud1 (.clk(clk), .ce(ce), .i(rgs), .o(rgs6));

always @(posedge clk)
  if (ce) tmp7 <= ~rgs6 ? rnd_ulp : mo6[N*2-1:N] + rnd_ulp;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #8
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
wire isZero7, inf7, sgn7, exv7;
delay #(.WID(1), .DEP(6)) ud2 (.clk(clk), .ce(ce), .i(isZero), .o(isZero7));
delay #(.WID(1), .DEP(6)) ud3 (.clk(clk), .ce(ce), .i(inf), .o(inf7));
delay #(.WID(1), .DEP(6)) ud4 (.clk(clk), .ce(ce), .i(sgn), .o(sgn7));
delay #(.WID(1), .DEP(3)) ud5 (.clk(clk), .ce(ce), .i(exv4), .o(exv7));

always @(posedge clk)
if (ce)
casez({isZero7,inf7|exv7,sgn7})    // exponent all ones or exponent overflow?
// convert to +0.0 zero-in zero-out (the sign will always be plus)
3'b1??:  o <= {PSTWID{1'b0}};
// Infinity in or exponent overflow in conversion = infinity out
3'b01?:  o <= {1'b1,{PSTWID-1{1'b0}}};
3'b001:  o <= ~tmp7 + 2'd1;
3'b000:  o <= tmp7;
endcase

endmodule
