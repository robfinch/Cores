// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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

`include "..\cpu\nvio3-config.sv"
`include "..\cpu\nvio3-defines.sv"

module fpFMAUnit(rst, clk, ce, ld, instr, rm, csr_i, v_i, v_o,
	tag_i, tag_o, a, b, c, o, zero, inf, pos, neg, exc, idle);
parameter FPWID=80;
input rst;
input clk;
input ce;
input ld;
input [39:0] instr;
input [2:0] rm;
input [31:0] csr_i;
input v_i;
output reg v_o;
input [`RBITS] tag_i;
output reg [`RBITS] tag_o;
input [FPWID+3:0] a;
input [FPWID+3:0] b;
input [FPWID+3:0] c;
output reg [FPWID+3:0] o;
output reg zero;
output reg inf;
output reg pos;
output reg neg;
output reg [`XBITS] exc; 
output reg idle;
parameter PIPELINE_DELAY = 6'd28;

wire [4:0] func5 = instr[`FUNCT5];
reg fms;
wire nma = func5==`FNMA || func5==`FNMS;
reg [FPWID+3:0] aa, bb, cc;
reg [2:0] rmr;
wire [22:0] csr;
wire [FPWID+3:0] fma_out;
wire fma_inf;

wire overflow;
wire underflow;
wire inexact;
reg [2:0] cnt;
wire v;
wire [`RBITS] tag;
reg [`RBITS] tagi;
reg vi;
reg [31:0] csri;


always @(posedge clk)
if (rst) begin
	idle <= 1'b1;
	cnt <= 3'd0;
end
else begin
	if (ld) begin
		idle <= 1'b0;
		cnt <= 3'd0;
		aa <= {a[FPWID+3] ^ nma,a[FPWID+2:0]};
		bb <= b;
		cc <= c;
		rmr <= rm;
		fms <= func5==`FMS || func5==`FNMS;
		tagi <= tag_i;
		vi <= v_i;
		csri <= csr_i;
	end
	else if (ce) begin
		cnt <= cnt + 2'd1;
		if (cnt==3'd5) begin
			cnt <= 3'd0;
			idle <= 1'b1;
		end
	end
end


fpFMAnr #(FPWID+4) u1
(
	.clk(clk),
	.ce(ce),
	.op(fms),
	.rm(rmr),
	.a(aa),
	.b(bb),
	.c(cc),
	.o(fma_out),
	.inf(fma_inf),
	.overflow(overflow),
	.underflow(underflow),
	.inexact(inexact)
);


wire res_zero = fma_out[FPWID+2:0]==1'd0;
vtdl #(.FPWID(1),.DEP(64)) u3 (.clk(clk), .ce(ce), .a(PIPELINE_DELAY), .d(vi), .q(v));
vtdl #(.FPWID(`RBIT),.DEP(64)) u4 (.clk(clk), .ce(ce), .a(PIPELINE_DELAY), .d(tagi), .q(tag));
vtdl #(.FPWID(32),.DEP(64)) u5 (.clk(clk), .ce(ce), .a(PIPELINE_DELAY), .d(csri), .q(csr));
always @(posedge clk)
begin
	v_o <= 1'b0;
	if (cnt==3'd5) begin
		tag_o <= tag;
		v_o <= v;
	end
end


always @(posedge clk)
if (cnt==3'd5) begin
	if (v) begin
		if (overflow & csr[25])
			exc <= `FPX_OVER;
		else if (underflow & csr[26])
			exc <= `FPX_UNDER;
		else if (inexact & csr[28])
			exc <= `FPX_INEXACT;
		o <= fma_out;
		inf <= fma_inf;
		zero <= res_zero;
		pos <= ~o[FPWID+3] & ~res_zero;	// positive
		neg <=  o[FPWID+3] & ~res_zero;	// negative
	end
	else
		exc <= `FLT_NONE;
end

endmodule
