
//1675 LUTs
module Thor_livetarget(iqentry_v,iqentry_stomp,tgt0,tgt1,tgt2,tgt3,tgt4,tgt5,tgt6,tgt7,livetarget,
	iqentry_0_livetarget,
	iqentry_1_livetarget,
	iqentry_2_livetarget,
	iqentry_3_livetarget,
	iqentry_4_livetarget,
	iqentry_5_livetarget,
	iqentry_6_livetarget,
	iqentry_7_livetarget
);
input [7:0] iqentry_v;
input [7:0] iqentry_stomp;
input [8:0] tgt0;
input [8:0] tgt1;
input [8:0] tgt2;
input [8:0] tgt3;
input [8:0] tgt4;
input [8:0] tgt5;
input [8:0] tgt6;
input [8:0] tgt7;
output [287:1] livetarget;
output [287:1] iqentry_0_livetarget;
output [287:1] iqentry_1_livetarget;
output [287:1] iqentry_2_livetarget;
output [287:1] iqentry_3_livetarget;
output [287:1] iqentry_4_livetarget;
output [287:1] iqentry_5_livetarget;
output [287:1] iqentry_6_livetarget;
output [287:1] iqentry_7_livetarget;

wire [8:0] iqentry_tgt [0:7];
assign iqentry_tgt[0] = tgt0;
assign iqentry_tgt[1] = tgt1;
assign iqentry_tgt[2] = tgt2;
assign iqentry_tgt[3] = tgt3;
assign iqentry_tgt[4] = tgt4;
assign iqentry_tgt[5] = tgt5;
assign iqentry_tgt[6] = tgt6;
assign iqentry_tgt[7] = tgt7;

wire [287:1] iq0_out;
wire [287:1] iq1_out;
wire [287:1] iq2_out;
wire [287:1] iq3_out;
wire [287:1] iq4_out;
wire [287:1] iq5_out;
wire [287:1] iq6_out;
wire [287:1] iq7_out;

reg [287:1] livetarget;

decoder9 iq0(.num(iqentry_tgt[0]), .out(iq0_out));
decoder9 iq1(.num(iqentry_tgt[1]), .out(iq1_out));
decoder9 iq2(.num(iqentry_tgt[2]), .out(iq2_out));
decoder9 iq3(.num(iqentry_tgt[3]), .out(iq3_out));
decoder9 iq4(.num(iqentry_tgt[4]), .out(iq4_out));
decoder9 iq5(.num(iqentry_tgt[5]), .out(iq5_out));
decoder9 iq6(.num(iqentry_tgt[6]), .out(iq6_out));
decoder9 iq7(.num(iqentry_tgt[7]), .out(iq7_out));

integer n;
always @*
	for (n = 1; n < 288; n = n + 1)
		livetarget[n] <= iqentry_0_livetarget[n] | iqentry_1_livetarget[n] | iqentry_2_livetarget[n] | iqentry_3_livetarget[n] |
			iqentry_4_livetarget[n] | iqentry_5_livetarget[n] | iqentry_6_livetarget[n] | iqentry_7_livetarget[n]
			;
assign 
	iqentry_0_livetarget = {288{iqentry_v[0]}} & {288{~iqentry_stomp[0]}} & iq0_out,
	iqentry_1_livetarget = {288{iqentry_v[1]}} & {288{~iqentry_stomp[1]}} & iq1_out,
	iqentry_2_livetarget = {288{iqentry_v[2]}} & {288{~iqentry_stomp[2]}} & iq2_out,
	iqentry_3_livetarget = {288{iqentry_v[3]}} & {288{~iqentry_stomp[3]}} & iq3_out,
	iqentry_4_livetarget = {288{iqentry_v[4]}} & {288{~iqentry_stomp[4]}} & iq4_out,
	iqentry_5_livetarget = {288{iqentry_v[5]}} & {288{~iqentry_stomp[5]}} & iq5_out,
	iqentry_6_livetarget = {288{iqentry_v[6]}} & {288{~iqentry_stomp[6]}} & iq6_out,
	iqentry_7_livetarget = {288{iqentry_v[7]}} & {288{~iqentry_stomp[7]}} & iq7_out;

endmodule

module decoder9 (num, out);
input [8:0] num;
output [287:1] out;

wire [287:0] out1;

assign out1 = 288'd1 << num;
assign out = out1[287:1];

endmodule
