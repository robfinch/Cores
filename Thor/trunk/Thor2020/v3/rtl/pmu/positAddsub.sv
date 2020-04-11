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

module positAddsub(op, a, b, o);
parameter FPWID = `FPWID;
parameter es = FPWID==80 ? 3 : FPWID==64 ? 3 : FPWID==52 ? 3 : FPWID==40 ? 3 : FPWID==32 ? 2 : FPWID==20 ? 2 : FPWID==16 ? 1 : 0
localparam rs = $clog2(FPWID);
input op;
input [FPWID-1:0] a;
input [FPWID-1:0] b;
output [FPWID-1:0] o;

wire sa, sb, so;
wire rop;
wire [rs:0] rgma, rgmb, rgm1, rgm2;
wire [rs:0] rgm_dif, rgm_dif1, rgm_dif2, rgm_dif3;
wire [rs+es+1:0] diff;
wire [es-1:0] expa, expb, exp1, exp2;
wire [FPWID-es-1:0] siga, sigb, sig1, sig2;
wire zera, zerb;
wire infa, infb;
wire [FPWID-1:0] aa, bb;
wire inf = infa|infb;
wire zero = zera & zerb;

positDecompose u1 (
  .i(a),
  .sgn(sa),
  .rgm(rgma),
  .exp(expa),
  .sig(siga),
  .zer(zera),
  .inf(infa)
);

positDecompose u2 (
  .i(b),
  .sgn(sb),
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
assign rgm1 = aa_gt_bb ? rgma : rgmb;
assign rgm2 = aa_gt_bb ? rgmb : rgma;
assign exp1 = aa_gt_bb ? expa : expb;
assign exp2 = aa_gt_bb ? expb : expa;
assign sig1 = aa_gt_bb ? siga : sigb; 
assign sig2 = aa_gt_bb ? sigb : siga;

assign rgm_dif1 = rgma - rgmb;
assign rgm_dif2 = rgmb - rgma;
assign rgm_dif3 = rgma + rgmb;

assign rgm_dif = rgm1[rs] ? (rgm2[rs] ? rgm_dif1 : rgm_dif3) : rgm_dif2;
assign diff = {rgm_dif,exp1} - {{rs+1{1'b0}},exp2};
wire [rs-1:0] exp_diff = (|diff[es+rs:rs]) ? {rs{1'b1}} : diff[rs-1:0];
wire [FPWID-1-es:0] sig2s = sig2 >> exp_diff;
wire [FPWID-es:0] sig_sd = op ? sig1 + sig2s : sig1 - sig2s;
wire [1:0] sigov = sig_sd[FPWID-es:FPWID-1-es];

wire [6:0] locnt;
positCntlo u3 (.i({|sigov,sig_sd[FPWID-es-2:0]},{FPWID-es-1{1'b0}}), .o(locnt));

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

endmodule
