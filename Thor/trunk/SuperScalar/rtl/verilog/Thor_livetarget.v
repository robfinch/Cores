// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
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
//
// Thor SuperScalar
// Live Target logic
//
// ============================================================================
//
//1675 LUTs
module Thor_livetarget(iqentry_v,iqentry_stomp,iqentry_cmt,tgt0,tgt1,tgt2,tgt3,tgt4,tgt5,tgt6,tgt7,livetarget,
	iqentry_0_livetarget,
	iqentry_1_livetarget,
	iqentry_2_livetarget,
	iqentry_3_livetarget,
	iqentry_4_livetarget,
	iqentry_5_livetarget,
	iqentry_6_livetarget,
	iqentry_7_livetarget
);
parameter NREGS = 111;
input [7:0] iqentry_v;
input [7:0] iqentry_stomp;
input [7:0] iqentry_cmt;
input [6:0] tgt0;
input [6:0] tgt1;
input [6:0] tgt2;
input [6:0] tgt3;
input [6:0] tgt4;
input [6:0] tgt5;
input [6:0] tgt6;
input [6:0] tgt7;
output [NREGS:1] livetarget;
output [NREGS:1] iqentry_0_livetarget;
output [NREGS:1] iqentry_1_livetarget;
output [NREGS:1] iqentry_2_livetarget;
output [NREGS:1] iqentry_3_livetarget;
output [NREGS:1] iqentry_4_livetarget;
output [NREGS:1] iqentry_5_livetarget;
output [NREGS:1] iqentry_6_livetarget;
output [NREGS:1] iqentry_7_livetarget;

wire [6:0] iqentry_tgt [0:7];
assign iqentry_tgt[0] = tgt0;
assign iqentry_tgt[1] = tgt1;
assign iqentry_tgt[2] = tgt2;
assign iqentry_tgt[3] = tgt3;
assign iqentry_tgt[4] = tgt4;
assign iqentry_tgt[5] = tgt5;
assign iqentry_tgt[6] = tgt6;
assign iqentry_tgt[7] = tgt7;

wire [NREGS:1] iq0_out;
wire [NREGS:1] iq1_out;
wire [NREGS:1] iq2_out;
wire [NREGS:1] iq3_out;
wire [NREGS:1] iq4_out;
wire [NREGS:1] iq5_out;
wire [NREGS:1] iq6_out;
wire [NREGS:1] iq7_out;

reg [NREGS:1] livetarget;

decoder7 iq0(.num(iqentry_tgt[0]), .out(iq0_out));
decoder7 iq1(.num(iqentry_tgt[1]), .out(iq1_out));
decoder7 iq2(.num(iqentry_tgt[2]), .out(iq2_out));
decoder7 iq3(.num(iqentry_tgt[3]), .out(iq3_out));
decoder7 iq4(.num(iqentry_tgt[4]), .out(iq4_out));
decoder7 iq5(.num(iqentry_tgt[5]), .out(iq5_out));
decoder7 iq6(.num(iqentry_tgt[6]), .out(iq6_out));
decoder7 iq7(.num(iqentry_tgt[7]), .out(iq7_out));

integer n;
always @*
	for (n = 1; n < NREGS+1; n = n + 1)
		livetarget[n] <= iqentry_0_livetarget[n] | iqentry_1_livetarget[n] | iqentry_2_livetarget[n] | iqentry_3_livetarget[n] |
			iqentry_4_livetarget[n] | iqentry_5_livetarget[n] | iqentry_6_livetarget[n] | iqentry_7_livetarget[n]
			;
assign 
	iqentry_0_livetarget = {NREGS{iqentry_v[0]}} & {NREGS{~iqentry_stomp[0]}} & iq0_out,
	iqentry_1_livetarget = {NREGS{iqentry_v[1]}} & {NREGS{~iqentry_stomp[1]}} & iq1_out,
	iqentry_2_livetarget = {NREGS{iqentry_v[2]}} & {NREGS{~iqentry_stomp[2]}} & iq2_out,
	iqentry_3_livetarget = {NREGS{iqentry_v[3]}} & {NREGS{~iqentry_stomp[3]}} & iq3_out,
	iqentry_4_livetarget = {NREGS{iqentry_v[4]}} & {NREGS{~iqentry_stomp[4]}} & iq4_out,
	iqentry_5_livetarget = {NREGS{iqentry_v[5]}} & {NREGS{~iqentry_stomp[5]}} & iq5_out,
	iqentry_6_livetarget = {NREGS{iqentry_v[6]}} & {NREGS{~iqentry_stomp[6]}} & iq6_out,
	iqentry_7_livetarget = {NREGS{iqentry_v[7]}} & {NREGS{~iqentry_stomp[7]}} & iq7_out;

endmodule

module decoder7 (num, out);
input [6:0] num;
output [127:1] out;

wire [127:0] out1;

assign out1 = 127'd1 << num;
assign out = out1[127:1];

endmodule
