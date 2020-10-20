// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positSqrt.v
//    - posit number square root function
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

module positSqrt(clk, ce, i, o, start, done, zero, inf);
`include "positSize.sv"
localparam rs = $clog2(PSTWID-1)-1;
input clk;
input ce;
input [PSTWID-1:0] i;
output reg [PSTWID-1:0] o;
input start;
output done;
output zero;
output inf;

wire si, so;
wire [rs:0] rgmi;
wire rgsi;
wire [es-1:0] expi;
wire [PSTWID-es-1:0] sigi;
wire zeri;
wire infi;
wire inf = infi;
wire zero = zeri;

positDecompose #(PSTWID,es) u1 (
  .i(i),
  .sgn(si),
  .rgs(rgsi),
  .rgm(rgmi),
  .exp(expi),
  .sig(sigi),
  .zer(zeri),
  .inf(infi)
);

assign so = si;				// square root of positive numbers only
// Compute length of significand. This length is needed to align the
// significand input to the square root module.
//wire [rs+1:0] rgml1 = rgsi ? rgmi + 2'd2 : rgmi + 2'd1;
//wire [rs+1:0] sigl = PSTWID-rgml1-es-1;
// The length could be zero or less  
//wire [rs:0] sigl1 = sigl[rs+1] ? {rs{1'b0}} : sigl;

// Compute exponent
wire [rs+1:0] rgm1 = rgsi ? rgmi : -rgmi;
wire [rs+es+1:0] rx1 = {rgm1,expi};
// If exponent is odd, make it even. May need to shift the significand later.
wire [rs+es+1:0] rxtmp = {{2{rx1[rs+es+1]}},rx1} >> 1;   // right shift takes square root of exponent

assign sqrinf = infi;
assign sqrneg = so;
// If the exponent was made even, shift the significand left.
wire [PSTWID-1:0] sig1 = (rx1[0] ^ ~es[0]) ? {sigi,1'b0} : {1'b0,sigi};

wire ldd;
delay1 #(1) u3 (.clk(clk), .ce(ce), .i(start), .o(ldd));
wire [PSTWID*3-1:0] sqrto;

wire [rs:0] lzcnt;

// iqsrt2 left aligns the number
isqrt2 #(PSTWID*3/2) u2
(
	.rst(rst),
	.clk(clk),
	.ce(ce),
	.ld(ldd),
	// Align the input according to odd/even length
	.a({sig1,{PSTWID/2{1'b0}}}),
	.o(sqrto),
	.done(done),
	.lzcnt(lzcnt)
);

// There should not be very many leading zeros in the number as the number is
// always between 1 and 2, so the square root is between 1.0 and 1.414....
// May want to change the leading zero detect to be a little more efficient.
//positCntlz #(.PSTWID(PSTWID)) u4 (.i(sqrto[PSTWID-1:0]), .o(lzcnt));
wire [PSTWID*2-1:0] sqrt1 = sqrto[PSTWID*3-1:PSTWID];// << (lzcnt + PSTWID/2);

// Make a negative rx positive
wire [rs+es+1:0] rxtmp2c = rxtmp[rs+es+1] ? ~rxtmp + 2'd1 : rxtmp;
// Break out the exponent and regime portions
wire [es-1:0] exp = rxtmp[es-1:0];
// Take absolute value of regime portion
wire srxtmp = rxtmp[rs+es+1];
wire [rs:0] rgm = srxtmp ? -rxtmp[rs+es+1:es] : rxtmp[rs+es+1:es];
// Compute the length of the regime bit string, +1 for positive regime
wire [rs:0] rgml = srxtmp ? rxtmp2c[rs+es:es] + 2'd1: rxtmp2c[rs+es:es] + 2'd2;
// Build expanded posit number:
// trim one leading bit off the product bits
// and keep guard, round bits, and create sticky bit
wire [PSTWID*3-1+9-es:0] tmp;
generate begin : gTmp
case(es)
0: assign tmp = {{PSTWID-1{~srxtmp}},srxtmp,sqrt1[PSTWID*2-2:0],{9-es{1'b0}}};
1,2,3,4,5,6:
  assign tmp = {{PSTWID-1{~srxtmp}},srxtmp,exp,sqrt1[PSTWID*2-2:0],{9-es{1'b0}}};
default:
always @*
  begin
    $display("positSqrt: unsupported es");
    $finish;
  end
endcase
end
endgenerate
wire [PSTWID*3-1+9-es:0] tmp1 = tmp >> rgml;

// Rounding
// Guard, Round, and Sticky
wire L = tmp1[PSTWID+8], G = tmp1[PSTWID+7], R = tmp1[PSTWID+6], St = |tmp1[PSTWID+5:0],
     ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [PSTWID-1:0] rnd_ulp = {{PSTWID-1{1'b0}},ulp};

wire [PSTWID:0] tmp1_rnd_ulp = tmp1[2*PSTWID+7:PSTWID+8] + rnd_ulp;
wire [PSTWID-1:0] tmp1_rnd = (rgml < PSTWID-es-2) ? tmp1_rnd_ulp[PSTWID-1:0] : tmp1[2*PSTWID+7:PSTWID+8];

always @*
  casez({infi,sqrinf,sqrneg,zero})
  4'b1???:  o = {1'b1,{PSTWID-1{1'b0}}};
  4'b01??:  o = {1'b1,{PSTWID-1{1'b0}}};
  4'b001?:  o = {1'b1,{PSTWID-1{1'b0}}};
  4'b0001:  o = {PSTWID{1'b0}};
  default:  o = {1'b0,tmp1_rnd[PSTWID-1:1]};
  endcase

endmodule
