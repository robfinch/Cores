`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf2901.sv
//    - four bit slice processor element
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================

module rf2901(clk, Ra, Rb, ins, q3, ram3, q0, ram0, d, y, oen, p, g, ovr, fz, f3, c, c4);
input clk;
input [5:0] Ra;				// Register file select lines
input [5:0] Rb;
input [5:0] Rt;
input [8:0] ins;			// Instruction input
input q0_i;
output reg q0_o;
output reg q0_en;			// tri-state enable q0
input q3_i;
output reg q3_o;
output reg q3_en;			// tri-state enable q3
input ram0_i;
output reg ram0_o;
output reg ram0_en;		// tri-state enable ram0
input ram3_i;
output reg ram3_o;
output reg ram3_en;		// tri-state enable ram3
input [3:0] d;				// data bus input
output reg [3:0] y;
output reg p;					// carry propagate
output reg g;					// carry generate
output reg ovr;				// overflow
output reg fz;				// result zero
output reg f3;				// result minus
input c;							// ripple carry input
output reg c4;				// ripple carry output

wire c3a, c3b, c3c;
wire c4a, c4b, c4c;
reg [3:0] a, b;
reg [3:0] r, s, f;
reg [3:0] q;
reg [3:0] regfile [0:63];
reg [3:0] pa, pb, pc, ga, gb, gc;
reg ram0i, ram3i, ram0a, ram3a;
reg q0i, q3i, q0a, q3a;

wire ldq = ir[8:6]==3'd0 || ir[8:6]==3'd4 || ir[8:6]==3'd6;
reg [3:0] qin;

always_comb
	case(i[8:6])
	3'd0:	ramin = 'd0;
	3'd1:	ramin = 'd0;
	3'd2:	ramin = f;
	3'd3:	ramin = f;
	3'd4:	ramin = {ram3i,f[3:1]};
	3'd5:	ramin = {ram3i,f[3:1]};
	3'd6:	ramin = {f[2:0],ram0i};
	3'd7:	ramin = {f[2:0],ram0i};
	endcase
always_ff @(posedge clk)
	a = regfile[Ra];
always_ff @(posedge clk)
	b = regfile[Rb];
always_ff @(posedge clk)
	if (|i[8:7])
		regfile[Rt] <= ramin;

always_comb
	case(i[8:6])
	3'd0:	qin = f;
	3'd1:	qin = 'd0;
	3'd2:	qin = 'd0;
	3'd3:	qin = 'd0;
	3'd4:	qin = {q3i,q[3:1]};
	3'd5:	qin = 'd0;
	3'd6:	qin = {q[2:0],q0i};
	3'd7:	qin = 'd0;
	endcase
always_ff @(posedge clk)
	if (ldq)
		q <= qin;
	
always_comb
	case(i[2:0])
	3'd0:	r = a;
	3'd1:	r = a;
	3'd2:	r = 'd0;
	3'd3:	r = 'd0;
	3'd4:	r = 'd0;
	3'd5:	r = d;
	3'd6:	r = d;
	3'd7:	r = d;
	endcase

always_comb
	case(i[2:0])
	3'd0:	s = q;
	3'd1:	s = b;
	3'd2:	s = q;
	3'd3:	s = b;
	3'd4:	s = a;
	3'd5:	s = a;
	3'd6:	s = q;
	3'd7:	s = 'd0;
	endcase
	
always_comb
	case(i[5:3])
	3'b000:	f = r + s + c;
	3'b001:	f = s - r - c;
	3'b010:	f = r - s - c;
	3'b011:	f = r | s;
	3'b100:	f = r & s;
	3'b101:	f = ~r & s;
	3'b110:	f = r ^ s;
	3'b111:	f = ~(r ^ s);
	endcase
	
integer n1;	
always_comb
	for (n1 = 0; n1 < 4; n1 = n1 + 1)
	begin
		pa[n1] = r[n1] | s[n1];
		ga[n1] = r[n1] & s[n1];
		pb[n1] = ~r[n1] | s[n1];
		gb[n1] = ~r[n1] & s[n1];
		pc[n1] = r[n1] | ~s[n1];
		gc[n1] = r[n1] & ~s[n1];
	end


assign c3a = ga[2] | pa[2]&ga[1] | pa[2]&pa[1]&ga[0] | pa[2]&pa[1]&pa[0]&c;
assign c4a = pa[3]&ga[2] | pa[3]&pa[2]&ga[1] | pa[3]&pa[2]&pa[1]&ga[0] | pa[3]&pa[2]&pa[1]&pa[0]&c;
assign c3b = gb[2] | pb[2]&gb[1] | pb[2]&pb[1]&gb[0] | pb[2]&pb[1]&pb[0]&c;
assign c4b = pb[3]&gb[2] | pb[3]&pb[2]&gb[1] | pb[3]&pb[2]&pb[1]&gb[0] | pb[3]&pb[2]&pb[1]&pb[0]&c;
assign c3c = gc[2] | pc[2]&gc[1] | pc[2]&pc[1]&gc[0] | pc[2]&pc[1]&pc[0]&c;
assign c4c = pc[3]&gc[2] | pc[3]&pc[2]&gc[1] | pc[3]&pc[2]&pc[1]&gc[0] | pc[3]&pc[2]&pc[1]&pc[0]&c;

always_comb
	case(i[5:3])
	3'd0:	p = ~&pa;
	3'd1:	p = ~&pb;
	3'd2:	p = ~&pc;
	3'd3:	p = 1'b0;
	3'd4:	p = 1'b0;
	3'd5:	p = 1'b0;
	3'd6:	p = |gb;
	3'd7: p = |ga;
	endcase
always_comb
	case(i[5:3])
	3'd0:	g = ~(ga[3] | (pa[3]&ga[2]) | (pa[3]&pa[2]&ga[1]) | (pa[3]&pa[2]&pa[1]&ga[0]));
	3'd1:	g = ~(gb[3] | (pb[3]&gb[2]) | (pb[3]&pb[2]&gb[1]) | (pb[3]&pb[2]&pb[1]&gb[0]));
	3'd2:	g = ~(gc[3] | (pc[3]&gc[2]) | (pc[3]&pc[2]&gc[1]) | (pc[3]&pc[2]&pc[1]&gc[0]));
	3'd3:	g = &pa;
	3'd4:	g = ~|ga;
	3'd5:	g = &pb;
	3'd6:	g = gb[3] | (pb[3]&gb[2]) | (pb[3]&pb[2]&gb[1]) | &pb;
	3'd7: g = ga[3] | (pa[3]&ga[2]) | (pa[3]&pa[2]&ga[1]) | &pa;
	endcase
always_comb
	case(i[5:3])
	3'd0:	c4 = c4a;
	3'd1:	c4 = c4b;
	3'd2:	c4 = c4c;
	3'd3:	c4 = ~&pa | c;
	3'd4:	c4 = |ga | c;
	3'd5:	c4 = |gb | c;
	3'd6:	c4 = ~(gb[3] | (pb[3]&gb[2]) | (pb[3]&pb[2]&gb[1]) | (&pb & (gb[0]|~c)));
	3'd7:	c4 = ~(ga[3] | (pa[3]&ga[2]) | (pa[3]&pa[2]&ga[1]) | (&pa & (ga[0]|~c)));
always_comb
	case(i[5:3])
	3'd0:	ovr = c3a ^ c4a;
	3'd1:	ovr = c3b ^ c4b;
	3'd2:	ovr = c3c ^ c4c;
	3'd3:	ovr = ~&pa |c;
	3'd4:	ovr = |ga | c;
	3'd5:	ovr = |gb | c;
	3'd6:	ovr = (~pb[2] | (~gb[2]&~pb[1]) | (~gb[2]&~gb[1]&~pb[0]) | (~gb[2]&~gb[1]&~gb[0]&c)) ^
							(~pb[3] | (~gb[3]&~pb[2]) | (~gb[3]&~gb[2]&~pb[1]) | (~gb[3]&~gb[2]&~gb[1]&~pb[0]) | (~gb[3]&~gb[2]&~gb[1]&~gb[0]&c));
	3'd7:	ovr = (~pa[2] | (~ga[2]&~pa[1]) | (~ga[2]&~ga[1]&~pa[0]) | (~ga[2]&~ga[1]&~ga[0]&c)) ^
							(~pa[3] | (~ga[3]&~pa[2]) | (~ga[3]&~ga[2]&~pa[1]) | (~ga[3]&~ga[2]&~ga[1]&~pa[0]) | (~ga[3]&~ga[2]&~ga[1]&~ga[0]&c));
	endcase

always_comb
	f3 = f[3];
always_comb
	fz = ~|f;

always_comb
	y = i[8:6]==3'd2 ? a : f;

always_comb
	case(i[8:6])
	3'd0:	ram0a = 'd0;
	3'd1:	ram0a = 'd0;
	3'd2:	ram0a = 'd0;
	3'd3:	ram0a = 'd0;
	3'd4:	ram0a = f[0];
	3'd5:	ram0a = f[0];
	3'd6:	ram0a = 'd0;
	3'd7:	ram0a = 'd0;
	endcase
always_comb
	ram0i = &i[8:7] ? ram0_i : ram0a;
always_comb
	ram0_o = f[0];
always_comb
	ram0_en = (i[8:6]==3'd4 || i[8:6]==3'd5);

always_comb
	case(i[8:6])
	3'd0:	ram3a = 'd0;
	3'd1:	ram3a = 'd0;
	3'd2:	ram3a = 'd0;
	3'd3:	ram3a = 'd0;
	3'd4:	ram3a = 'd0;
	3'd5:	ram3a = 'd0;
	3'd6:	ram3a = f[3];
	3'd7:	ram3a = f[3];
	endcase
always_comb
	ram3i = (i[8:6]==3'd4 || ir[8:6]==3'd5) ? ram3_i : ram3a;
always_comb
	ram3_o = f[3];
always_comb
	ram3_en = &i[8:7];

always_comb
	case(i[8:6])
	3'd0:	q0a = 'd0;
	3'd1:	q0a = 'd0;
	3'd2:	q0a = 'd0;
	3'd3:	q0a = 'd0;
	3'd4:	q0a = q[0];
	3'd5:	q0a = q[0];
	3'd6:	q0a = 'd0;
	3'd7:	q0a = 'd0;
	endcase
always_comb
	q0i = &i[8:6]==3'd6 ? q0_i : q0a;
always_comb
	q0_o = q[0];
always_comb
	q0_en = (i[8:6]==3'd4 || i[8:6]==3'd5);

always_comb
	case(i[8:6])
	3'd0:	q3a = 'd0;
	3'd1:	q3a = 'd0;
	3'd2:	q3a = 'd0;
	3'd3:	q3a = 'd0;
	3'd4:	q3a = 'd0;
	3'd5:	q3a = 'd0;
	3'd6:	q3a = q[3];
	3'd7:	q3a = q[3];
	endcase
always_comb
	q3i = i[8:6]==3'd4 ? q3_i : q3a;
always_comb
	q3_o = q[3];
always_comb
	q3_en = &i[8:7];

endmodule
