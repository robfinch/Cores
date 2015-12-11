`define VAL 1'b1
`define INV 1'b0

// 5,600 LUTs

module prev_tgt(clk, iqe_v, iqe_a1_s0,
	iqe_a1_s1, iqe_a1_s2, iqe_a1_s3, iqe_a1_s4, iqe_a1_s5, iqe_a1_s6, iqe_a1_s7,
	iqe_res0, iqe_res1, iqe_res2, iqe_res3, iqe_res4, iqe_res5, iqe_res6, iqe_res7,
	iqe_pt0, iqe_pt1,iqe_pt2,iqe_pt3,iqe_pt4,iqe_pt5,iqe_pt6,iqe_pt7,
	iqe_a10, iqe_a11, iqe_a12, iqe_a13, iqe_a14, iqe_a15, iqe_a16, iqe_a17, 
	iqe_a1_v
);
input clk;
input [7:0] iqe_v;
input [7:0] iqe_a1_s0;
input [7:0] iqe_a1_s1;
input [7:0] iqe_a1_s2;
input [7:0] iqe_a1_s3;
input [7:0] iqe_a1_s4;
input [7:0] iqe_a1_s5;
input [7:0] iqe_a1_s6;
input [7:0] iqe_a1_s7;
input [31:0] iqe_res0;
input [31:0] iqe_res1;
input [31:0] iqe_res2;
input [31:0] iqe_res3;
input [31:0] iqe_res4;
input [31:0] iqe_res5;
input [31:0] iqe_res6;
input [31:0] iqe_res7;
input [7:0] iqe_pt0;
input [7:0] iqe_pt1;
input [7:0] iqe_pt2;
input [7:0] iqe_pt3;
input [7:0] iqe_pt4;
input [7:0] iqe_pt5;
input [7:0] iqe_pt6;
input [7:0] iqe_pt7;
output [31:0] iqe_a10;
output [31:0] iqe_a11;
output [31:0] iqe_a12;
output [31:0] iqe_a13;
output [31:0] iqe_a14;
output [31:0] iqe_a15;
output [31:0] iqe_a16;
output [31:0] iqe_a17;
output [7:0] iqe_a1_v;

reg [7:0] iqentry_v;
reg [7:0] iqentry_a1_s [0:7];
reg [7:0] iqentry_a1_v;
wire [31:0] iqentry_res [0:7];
reg [31:0] iqentry_a1 [0:7];
reg [7:0] iqentry_prev_tgt [0:7];
assign iqentry_res[0] = iqe_res0;
assign iqentry_res[1] = iqe_res1;
assign iqentry_res[2] = iqe_res2;
assign iqentry_res[3] = iqe_res3;
assign iqentry_res[4] = iqe_res4;
assign iqentry_res[5] = iqe_res5;
assign iqentry_res[6] = iqe_res6;
assign iqentry_res[7] = iqe_res7;

assign iqe_a10 = iqentry_a1[0];
assign iqe_a11 = iqentry_a1[1];
assign iqe_a12 = iqentry_a1[2];
assign iqe_a13 = iqentry_a1[3];
assign iqe_a14 = iqentry_a1[4];
assign iqe_a15 = iqentry_a1[5];
assign iqe_a16 = iqentry_a1[6];
assign iqe_a17 = iqentry_a1[7];

assign iqe_a1_v = iqentry_a1_v;

reg [7:0] prev_tgt;

integer n;

always @(posedge clk)
begin
	iqentry_v = iqe_v;
	iqentry_a1_s[0] = iqe_a1_s0;
	iqentry_a1_s[1] = iqe_a1_s1;
	iqentry_a1_s[2] = iqe_a1_s2;
	iqentry_a1_s[3] = iqe_a1_s3;
	iqentry_a1_s[4] = iqe_a1_s4;
	iqentry_a1_s[5] = iqe_a1_s5;
	iqentry_a1_s[6] = iqe_a1_s6;
	iqentry_a1_s[7] = iqe_a1_s7;
	iqentry_prev_tgt[0] = iqe_pt0;
	iqentry_prev_tgt[1] = iqe_pt1;
	iqentry_prev_tgt[2] = iqe_pt2;
	iqentry_prev_tgt[3] = iqe_pt3;
	iqentry_prev_tgt[4] = iqe_pt4;
	iqentry_prev_tgt[5] = iqe_pt5;
	iqentry_prev_tgt[6] = iqe_pt6;
	iqentry_prev_tgt[7] = iqe_pt7;

	for (n = 0; n < 8; n = n + 1)
	begin
		prev_tgt = iqentry_a1_s[n];
		if (prev_tgt[7]) begin	// previous target was the register file
			iqentry_a1_v[n] <= `INV;
			iqentry_a1_s[n] = prev_tgt;
		end
		else if (!iqentry_v[prev_tgt[2:0]]) begin
			prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
			if (prev_tgt[7]) begin
				iqentry_a1_v[n] <= `INV;
				iqentry_a1_s[n] = prev_tgt;
			end
			else if (!iqentry_v[prev_tgt[2:0]]) begin
				prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
				if (prev_tgt[7]) begin
					iqentry_a1_v[n] <= `INV;
					iqentry_a1_s[n] = prev_tgt;
				end
				else if (!iqentry_v[prev_tgt[2:0]]) begin
					prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
					if (prev_tgt[7]) begin
						iqentry_a1_v[n] <= `INV;
						iqentry_a1_s[n] = prev_tgt;
					end
					else if (!iqentry_v[prev_tgt[2:0]]) begin
						prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
						if (prev_tgt[7]) begin
							iqentry_a1_v[n] <= `INV;
							iqentry_a1_s[n] = prev_tgt;
						end
						else if (!iqentry_v[prev_tgt[2:0]]) begin
							prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
							if (prev_tgt[7]) begin
								iqentry_a1_v[n] <= `INV;
								iqentry_a1_s[n] = prev_tgt;
							end
							else if (!iqentry_v[prev_tgt[2:0]]) begin
								prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
								if (prev_tgt[7]) begin
									iqentry_a1_v[n] <= `INV;
									iqentry_a1_s[n] = prev_tgt;
								end
								else if (!iqentry_v[prev_tgt[2:0]]) begin
									prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
									if (prev_tgt[7]) begin
										iqentry_a1_v[n] <= `INV;
										iqentry_a1_s[n] = prev_tgt;
									end
									else if (!iqentry_v[prev_tgt[2:0]])
										prev_tgt = iqentry_prev_tgt[prev_tgt[2:0]];
									else begin
										iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
										iqentry_a1_v[n] <= `VAL;
									end
								end
								else begin
									iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
									iqentry_a1_v[n] <= `VAL;
								end
							end
							else begin
								iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
								iqentry_a1_v[n] <= `VAL;
							end
						end
						else begin
							iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
							iqentry_a1_v[n] <= `VAL;
						end
					end
					else begin
						iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
						iqentry_a1_v[n] <= `VAL;
					end
				end
				else begin
					iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
					iqentry_a1_v[n] <= `VAL;
				end
			end
			else begin
				iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
				iqentry_a1_v[n] <= `VAL;
			end
		end
		else begin
			iqentry_a1[n] <= iqentry_res[prev_tgt[2:0]];
			iqentry_a1_v[n] <= `VAL;
		end
	end
end
endmodule
