// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positAddsub.v
//    - posit number adder/subtracter
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

module positAddsub(op, a, b, o);
`include "positSize.sv"
localparam rs = $clog2(PSTWID-1)-1;
input op;
input [PSTWID-1:0] a;
input [PSTWID-1:0] b;
output reg [PSTWID-1:0] o;

wire sa, sb;
reg so;
wire rop;
wire [rs:0] rgma, rgmb, rgm1, rgm2, argm1, argm2;
wire rgsa, rgsb, rgs1, rgs2;
wire [rs+es+1:0] diff;
wire [es-1:0] expa, expb, exp1, exp2;
wire [PSTWID-es-1:0] siga, sigb, sig1, sig2;
wire zera, zerb;
wire infa, infb;
wire [PSTWID-1:0] aa, bb;
wire inf = infa|infb;
wire zero = zera & zerb;

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

assign aa = sa ? -a : a;
assign bb = sb ? -b : b;

wire aa_gt_bb = aa >= bb;
// Determine op really wanted
assign rop = sa ^ sb ^ op;
// Sort operand components
assign rgs1 = aa_gt_bb ? rgsa : rgsb;
assign rgs2 = aa_gt_bb ? rgsb : rgsa;
assign rgm1 = aa_gt_bb ? rgma : rgmb;
assign rgm2 = aa_gt_bb ? rgmb : rgma;
assign exp1 = aa_gt_bb ? expa : expb;
assign exp2 = aa_gt_bb ? expb : expa;
assign sig1 = aa_gt_bb ? siga : sigb; 
assign sig2 = aa_gt_bb ? sigb : siga;

assign argm1 = rgs1 ? rgm1 : -rgm1;
assign argm2 = rgs2 ? rgm2 : -rgm2;

assign diff = {argm1,exp1} - {argm2,exp2};
wire [rs-1:0] exp_diff = (|diff[es+rs:rs]) ? {rs{1'b1}} : diff[rs-1:0];
wire [PSTWID*2-1:0] sig2s = {sig2,{PSTWID{1'b0}}} >> exp_diff;
wire [PSTWID*2-1:0] sig1s = {sig1,{PSTWID{1'b0}}};
wire [PSTWID*2:0] sig_sd = rop ? sig1s - sig2s : sig1s + sig2s;
wire [1:0] sigov = sig_sd[PSTWID*2:PSTWID*2-1];

wire [$clog2(PSTWID-1):0] lzcnt;
wire [PSTWID-1:0] sigi = {|sigov,sig_sd[PSTWID*2-2:PSTWID]};
generate begin : gClz
  case(PSTWID)
  16: cntlz16 u1 (.i({sigi}), .o(lzcnt));
  20: cntlz24 u1 (.i({sigi,4'hF}), .o(lzcnt));
  32: cntlz32 u1 (.i({sigi}), .o(lzcnt));
  40: cntlz48 u1 (.i({sigi,8'hFF}), .o(lzcnt));
  52: cntlz64 u1 (.i({sigi,12'hFFF}), .o(lzcnt));
  64: cntlz64 u1 (.i({sigi}), .o(lzcnt));
  80: cntlz80 u1 (.i({sigi}), .o(lzcnt));
  default:  ;
  endcase
end
endgenerate

//positCntlz #(.PSTWID(PSTWID)) u3 (.i({|sigov,sig_sd[PSTWID-2:0]}), .o(lzcnt));
wire [PSTWID*2-1:0] sig_ls = sig_sd[PSTWID*2-1:0] << lzcnt;

wire [rs:0] absrgm1 = rgs1 ? rgm1 : -rgm1;  // rgs1 = 1 = positive
wire [es+rs+1:0] rxtmp;
wire [es+rs+1:0] rxtmp1;
wire srxtmp1;
wire [es+rs:0] abs_rxtmp;
wire [(es==0 ? 0 : es-1):0] expo;
wire [rs:0] rgmo;
generate begin : gEsz
if (es > 0) begin
assign rxtmp = {absrgm1,exp1} - {{es+1{1'b0}},lzcnt-es};
assign rxtmp1 = rxtmp + sigov[1]; // add in overflow if any
assign srxtmp1 = rxtmp1[es+rs+1];
assign abs_rxtmp = srxtmp1 ? -rxtmp1 : rxtmp1;

assign expo = (srxtmp1 & |abs_rxtmp[es-1:0]) ? rxtmp1[es-1:0] : abs_rxtmp[es-1:0];
assign rgmo = (~srxtmp1 || (srxtmp1 & |abs_rxtmp[es-1:0])) ? abs_rxtmp[es+rs:es] + 1'b1 : abs_rxtmp[es+rs:es];
end
else begin
assign rxtmp = absrgm1 - {{1{1'b0}},lzcnt};
assign rxtmp1 = rxtmp + sigov[1]; // add in overflow if any
assign srxtmp1 = rxtmp1[rs+1];
assign abs_rxtmp = srxtmp1 ? -rxtmp1 : rxtmp1;
assign expo = 1'b0;
assign rgmo = (~srxtmp1) ? abs_rxtmp[rs:0] + 1'b1 : abs_rxtmp[rs:0];
end
end
endgenerate

// Exponent and Significand Packing
reg [2*PSTWID-1+3:0] tmp;
always @*
case(es)
0:  tmp = { {PSTWID{~srxtmp1}}, srxtmp1, sig_ls[PSTWID*2-2:PSTWID-2], |sig_ls[PSTWID-3:0]};
1:  tmp = { {PSTWID{~srxtmp1}}, srxtmp1, expo, sig_ls[PSTWID*2-2:PSTWID-1], |sig_ls[PSTWID-2:0]};
2:  tmp = { {PSTWID{~srxtmp1}}, srxtmp1, expo, sig_ls[PSTWID*2-2:PSTWID], |sig_ls[PSTWID-1:0]};
default:  tmp = { {PSTWID{~srxtmp1}}, srxtmp1, expo, sig_ls[PSTWID*2-2:PSTWID+es-2], |sig_ls[PSTWID-1+es-2:0]};
endcase

wire [3*PSTWID-1+3:0] tmp1 = {tmp,{PSTWID{1'b0}}} >> rgmo;

// Rounding
// Gaurd, Round, and Sticky
wire L = tmp1[PSTWID+4], G = tmp1[PSTWID+3], R = tmp1[PSTWID+2], St = |tmp1[PSTWID+1:0],
     ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [PSTWID-1:0] rnd_ulp = {{PSTWID-1{1'b0}},ulp};

wire [PSTWID:0] tmp1_rnd_ulp = tmp1[2*PSTWID-1+3:PSTWID+3] + rnd_ulp;
wire [PSTWID-1:0] tmp1_rnd = (rgmo < PSTWID-es-2) ? tmp1_rnd_ulp[PSTWID-1:0] : tmp1[2*PSTWID-1+3:PSTWID+3];

// Compute output sign
always @*
	casez ({zero,sa,op,sb})
	4'b0000: so = 1'b0;			// + + + = +
	4'b0001: so = !aa_gt_bb;	// + + - = sign of larger
	4'b0010: so = !aa_gt_bb;	// + - + = sign of larger
	4'b0011: so = 1'b0;			// + - - = +
	4'b0100: so = aa_gt_bb;	// - + + = sign of larger
	4'b0101: so = 1'b1;			// - + - = -
	4'b0110: so = 1'b1;			// - - + = -
	4'b0111: so = aa_gt_bb;	// - - - = sign of larger
	4'b1???: so = 1'b0;
	endcase

wire [PSTWID-1:0] abs_tmp = so ? -tmp1_rnd : tmp1_rnd;

always @*
  casez({zero,inf,sig_ls[PSTWID]})
  3'b1??: o = {PSTWID{1'b0}};
  3'b01?: o = {1'b1,{PSTWID-1{1'b0}}};
  3'b001: o = {PSTWID{1'b0}};
  default:  o = {so, abs_tmp[PSTWID-1:1]};
  endcase

endmodule
