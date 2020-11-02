// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positMultiply.sv
//    - posit number multiplier, pipelined with latency of 13
//    - can issue every other clock cycle
//    - parameterized width
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
// ============================================================================

import posit::*;

module positMultiply(clk, ce, a, b, o, zero, inf);
input clk;
input ce;
input [PSTWID-1:0] a;
input [PSTWID-1:0] b;
output reg [PSTWID-1:0] o;
output reg zero;
output reg inf;

wire sa, sb, so;
wire [rs-1:0] rgma, rgmb;
wire rgsa, rgsb;
wire [es-1:0] expa, expb;
wire [PSTWID-es-1:0] siga, sigb;
wire zera, zerb;
wire infa, infb;
wire [PSTWID-1:0] aa, bb;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

positDecomposeReg #(PSTWID) u1 (
  .clk(clk),
  .ce(ce),
  .i(a),
  .sgn(sa),
  .rgs(rgsa),
  .rgm(rgma),
  .exp(expa),
  .sig(siga),
  .zer(zera),
  .inf(infa)
);

positDecomposeReg #(PSTWID) u2 (
  .clk(clk),
  .ce(ce),
  .i(b),
  .sgn(sb),
  .rgs(rgsb),
  .rgm(rgmb),
  .exp(expb),
  .sig(sigb),
  .zer(zerb),
  .inf(infb)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #2
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [rs+1:0] rgm1, rgm2;
reg [es-1:0] expa2, expb2;
reg so2;
reg inf2;
reg zero2;
reg [(PSTWID-es)*2-1:0] prod2;

always @(posedge clk)
  if (ce) prod2 <= siga * sigb;
always @(posedge clk)
  if (ce) so2 <= sa ^ sb;  // compute sign
always @(posedge clk)
  if (ce) inf2 <= infa|infb;
always @(posedge clk)
  if (ce) zero2 <= zera|zerb;
// Convert to the real +/- regime value
always @(posedge clk)
  if (ce) rgm1 <= rgsa ? rgma : -rgma;
always @(posedge clk)
  if (ce) rgm2 <= rgsb ? rgmb : -rgmb;
always @(posedge clk)
  if (ce) expa2 <= expa;
always @(posedge clk)
  if (ce) expb2 <= expb;

// The product could have one or two whole digits before the point. Detect which it is
// and realign the product.
wire mo = prod2[(PSTWID-es)*2-1];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #3
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [(PSTWID-es)*2-1:0] prod3;
reg [rs+es+1:0] rxtmp;

always @(posedge clk)
  if (ce) prod3 <= mo ? prod2 : {prod2,1'b0};  // left align product

// Compute regime and exponent, include product alignment shift.
always @(posedge clk)
  if (ce) rxtmp <= {rgm1,expa2} + {rgm2,expb2} + mo;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #4
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [rs+es+1:0] rxtmp2c;
reg [es-1:0] exp;
reg [(PSTWID-es)*2-1:0] prod4;
reg [rs+es+1:0] rxtmp4;
reg srxtmp;

// Make a negative rx positive
always @(posedge clk)
  if (ce) rxtmp2c <= rxtmp[rs+es+1] ? ~rxtmp + 2'd1 : rxtmp;

always @(posedge clk)
  if (ce) prod4 <= prod3;
always @(posedge clk)
  if (ce) rxtmp4 <= rxtmp;  
// Break out the exponent and regime portions
always @(posedge clk)
  if (ce) exp <= rxtmp[es-1:0];
// Take absolute value of regime portion
always @(posedge clk)
  if (ce) srxtmp <= rxtmp[rs+es+1];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #5
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [rs:0] rgm;
reg [rs+es+1:0] rxn;
reg [rs+es+1:0] rxtmp2c5;
reg [(PSTWID-es)*2-1:0] prod5;
reg [es-1:0] exp5;
reg srxtmp5;

always @(posedge clk)
  if (ce) rgm = srxtmp ? -rxtmp4[rs+es+1:es] : rxtmp4[rs+es+1:es];

// Compute the length of the regime bit string, +1 for positive regime
always @(posedge clk)
  if (ce) rxn <= rxtmp4[rs+es+1] ? rxtmp2c : rxtmp4;

always @(posedge clk)
  if (ce) prod5 <= prod4;
always @(posedge clk)
  if (ce) exp5 <= exp;
always @(posedge clk)
  if (ce) srxtmp5 <= srxtmp;
always @(posedge clk)
  if (ce) rxtmp2c5 <= rxtmp2c;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #6
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [rs:0] rgml;
reg [PSTWID*2-1+3:0] tmp;

always @(posedge clk)
  if (ce) rgml <= (~srxtmp5 | |(rxn[es-1:0])) ? rxtmp2c5[rs+es:es] + 2'd1 : rxtmp2c5[rs+es:es];

// Build expanded posit number:
// trim one leading bit off the product bits
// and keep guard, round bits, and create sticky bit
always @(posedge clk)
  if (ce) tmp <= {{PSTWID-1{~srxtmp5}},srxtmp5,exp5,prod5[(PSTWID-es)*2-2:(PSTWID-es-2)],|prod5[(PSTWID-es-3):0]};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #7
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [PSTWID*3-1+3:0] tmp7;
reg [rs:0] rgml7;

always @(posedge clk)
  if (ce) tmp7 <= {tmp,{PSTWID{1'b0}}} >> rgml;
always @(posedge clk)
  if (ce) rgml7 <= rgml;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #8
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Rounding
// Guard, Round, and Sticky
reg L, G, R, St;
reg [PSTWID*3-1+3:0] tmp8;
reg [rs:0] rgml8;

always @(posedge clk)
  if (ce) rgml8 <= rgml7;
always @(posedge clk)
  if (ce) L <= tmp7[PSTWID+4];
always @(posedge clk)
  if (ce) G <= tmp7[PSTWID+3];
always @(posedge clk)
  if (ce) R <= tmp7[PSTWID+2];
always @(posedge clk)
  if (ce) St <= |tmp7[PSTWID+1:0];
always @(posedge clk)
  if (ce) tmp8 <= tmp7;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #9
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg ulp;
wire [PSTWID-1:0] rnd_ulp;
reg [PSTWID*3-1+3:0] tmp9;
reg [rs:0] rgml9;

always @(posedge clk)
  if (ce) ulp <= ((G & (R | St)) | (L & G & ~(R | St)));
always @(posedge clk)
  if (ce) tmp9 <= tmp8;
always @(posedge clk)
  if (ce) rgml9 <= rgml8;
assign rnd_ulp = {{PSTWID-1{1'b0}},ulp};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #10
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [PSTWID:0] tmp10_rnd_ulp;
reg [PSTWID*3-1+3:0] tmp10;
reg [rs:0] rgml10;

always @(posedge clk)
  if (ce) tmp10 <= tmp9;
always @(posedge clk)
  if (ce) tmp10_rnd_ulp <= tmp9[2*PSTWID-1+3:PSTWID+3] + rnd_ulp;
always @(posedge clk)
  if (ce) rgml10 <= rgml9;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #11
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [PSTWID-1:0] tmp11_rnd;

always @(posedge clk)
  if (ce) tmp11_rnd <= (rgml10 < PSTWID-es-2) ? tmp10_rnd_ulp[PSTWID-1:0] : tmp10[2*PSTWID-1+3:PSTWID+3];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #12
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [PSTWID-1:0] abs_tmp;
wire so11;
reg so12;
delay #(.WID(1),.DEP(9)) udly1 (.clk(clk), .ce(ce), .i(so2), .o(so11));

always @(posedge clk)
  if (ce) abs_tmp <= so11 ? -tmp11_rnd : tmp11_rnd;
always @(posedge clk)
  if (ce) so12 <= so11;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #13
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
wire zero12, inf12;

delay #(.WID(1),.DEP(10)) udly2 (.clk(clk), .ce(ce), .i(zero2), .o(zero12));
delay #(.WID(1),.DEP(10)) udly3 (.clk(clk), .ce(ce), .i(inf2), .o(inf12));

always @(posedge clk)
  if (ce) zero <= zero12;
always @(posedge clk)
  if (ce) inf <= inf12;
  
always @(posedge clk)
  if (ce)
    casez({zero12,inf12})
    2'b1?: o <= {PSTWID{1'b0}};
    2'b01: o <= {1'b1,{PSTWID-1{1'b0}}};
    default:  o <= {so12,abs_tmp[PSTWID-1:1]};
    endcase

endmodule
