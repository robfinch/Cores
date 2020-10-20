// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positMul.v
//    - posit number multiplier
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

`include "positConfig.sv"

module positMul(a, b, o, zero, inf);
`include "positSize.sv"
localparam rs = $clog2(PSTWID-1);
input [PSTWID-1:0] a;
input [PSTWID-1:0] b;
output reg [PSTWID-1:0] o;
output zero;
output inf;

wire sa, sb, so;
wire [rs:0] rgma, rgmb;
wire [rs+1:0] rgm1, rgm2;
wire rgsa, rgsb;
wire [es-1:0] expa, expb;
wire [PSTWID-es-1:0] siga, sigb;
wire [(PSTWID-es)*2-1:0] prod;
wire zera, zerb;
wire infa, infb;
wire [PSTWID-1:0] aa, bb;
wire inf = infa|infb;
wire zero = zera|zerb;

positDecompose #(PSTWID,es) u1 (
  .i(a),
  .sgn(sa),
  .rgs(rgsa),
  .rgm(rgma),
  .exp(expa),
  .sig(siga),
  .zer(zera),
  .inf(infa)
);

positDecompose #(PSTWID,es) u2 (
  .i(b),
  .sgn(sb),
  .rgs(rgsb),
  .rgm(rgmb),
  .exp(expb),
  .sig(sigb),
  .zer(zerb),
  .inf(infb)
);

assign so = sa ^ sb;  // compute sign
assign prod = siga * sigb;
// The product could have one or two whole digits before the point. Detect which it is
// and realign the product.
wire mo = prod[(PSTWID-es)*2-1];
wire [(PSTWID-es)*2-1:0] prod1 = mo ? prod : prod << 1'b1;  // left align product
// Convert to the real +/- regime value
assign rgm1 = rgsa ? rgma : -rgma;
assign rgm2 = rgsb ? rgmb : -rgmb;
// Compute regime and exponent, include product alignment shift.
wire [rs+es+1:0] rxtmp = {rgm1,expa} + {rgm2,expb} + mo;
// Make a negative rx positive
wire [rs+es+1:0] rxtmp2c = rxtmp[rs+es+1] ? ~rxtmp + 2'd1 : rxtmp;
// Break out the exponent and regime portions
wire [es-1:0] exp = rxtmp[es-1:0];
// Take absolute value of regime portion
wire srxtmp = rxtmp[rs+es+1];
wire [rs:0] rgm = srxtmp ? -rxtmp[rs+es+1:es] : rxtmp[rs+es+1:es];
// Compute the length of the regime bit string, +1 for positive regime
wire [rs+es+1:0] rxn = rxtmp[rs+es+1] ? rxtmp2c : rxtmp;
wire [rs:0] rgml = (~srxtmp | |(rxn[es-1:0])) ? rxtmp2c[rs+es:es] + 2'd1 : rxtmp2c[rs+es:es];
// Build expanded posit number:
// trim one leading bit off the product bits
// and keep guard, round bits, and create sticky bit
wire [PSTWID*2-1+3:0] tmp = {{PSTWID-1{~srxtmp}},srxtmp,exp,prod1[(PSTWID-es)*2-2:(PSTWID-es-2)],|prod1[(PSTWID-es-3):0]};

wire [PSTWID*3-1+3:0] tmp1 = {tmp,{PSTWID{1'b0}}} >> rgml;

// Rounding
// Guard, Round, and Sticky
wire L = tmp1[PSTWID+4], G = tmp1[PSTWID+3], R = tmp1[PSTWID+2], St = |tmp1[PSTWID+1:0],
     ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [PSTWID-1:0] rnd_ulp = {{PSTWID-1{1'b0}},ulp};

wire [PSTWID:0] tmp1_rnd_ulp = tmp1[2*PSTWID-1+3:PSTWID+3] + rnd_ulp;
wire [PSTWID-1:0] tmp1_rnd = (rgml < PSTWID-es-2) ? tmp1_rnd_ulp[PSTWID-1:0] : tmp1[2*PSTWID-1+3:PSTWID+3];

wire [PSTWID-1:0] abs_tmp = so ? -tmp1_rnd : tmp1_rnd;

always @*
  casez({zero,inf})
  2'b1?: o = {PSTWID{1'b0}};
  2'b01: o = {1'b1,{PSTWID-1{1'b0}}};
  default:  o = {so,abs_tmp[PSTWID-1:1]};
  endcase

endmodule
