// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positFDPMul.sv
//    - fused dot product posit number multiplier
//    - parameterized width
//    - perform a multiplication but retain all the product bits
//      in the result in preparation for addition.
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

module positFDPMul(a, b, o, zero, inf);
input [PSTWID-1:0] a;
input [PSTWID-1:0] b;
output reg [PSTWID+es+(PSTWID-es)*2-1:0] o;
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
wire inf = infa|infb;
wire zero = zera|zerb;

positDecompose #(PSTWID) u1 (
  .i(a),
  .sgn(sa),
  .rgs(rgsa),
  .rgm(rgma),
  .exp(expa),
  .sig(siga),
  .zer(zera),
  .inf(infa)
);

positDecompose #(PSTWID) u2 (
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
wire [es-1:0] exp = |es ? rxtmp[es-1:0] : 0;
// Take absolute value of regime portion
wire srxtmp = rxtmp[rs+es+1];
wire [rs:0] rgm = srxtmp ? -rxtmp[rs+es+1:es] : rxtmp[rs+es+1:es];
// Compute the length of the regime bit string, +1 for positive regime
wire [rs+es+1:0] rxn = rxtmp[rs+es+1] ? rxtmp2c : rxtmp;
wire [rs:0] rgml;
// Build expanded posit number:
// trim one leading bit off the product bits
// and keep guard, round bits, and create sticky bit
wire [PSTWID+es+(PSTWID-es)*2-2:0] tmp;
generate begin : gTmp
if (es > 0) begin
assign rgml = (~srxtmp | |(rxn[es-1:0])) ? rxtmp2c[rs+es:es] + 2'd1 : rxtmp2c[rs+es:es];
assign tmp = {{PSTWID-1{~srxtmp}},srxtmp,exp,prod1[(PSTWID-es)*2-2:0]};
end
else begin
assign rgml = (~srxtmp) ? rxtmp2c[rs+es:es] + 2'd1 : rxtmp2c[rs+es:es];
assign tmp = {{PSTWID-1{~srxtmp}},srxtmp,prod1[(PSTWID-es)*2-2:0]};
end
end
endgenerate
wire [PSTWID+es+(PSTWID-es)*2-2:0] tmp1 = tmp << (PSTWID-rgml-1);
wire [PSTWID+es+(PSTWID-es)*2-1:0] abstmp = so ? {1'b1,-tmp1} : {1'b0,tmp1};

always @*
  casez({zero,inf})
  2'b1?: o = {PSTWID+es+(PSTWID-es)*2-2{1'b0}};
  2'b01: o = {1'b1,{PSTWID+es+(PSTWID-es)*2-2-1{1'b0}}};
  default:  o = abstmp;
  endcase

endmodule
