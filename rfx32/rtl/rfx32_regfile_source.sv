import rfx32pkg::*;

module rfx32_regfile_source(rst, clk, branchmiss,
	iqentry_0_latestID,
	iqentry_1_latestID,
	iqentry_2_latestID,
	iqentry_3_latestID,
	iqentry_4_latestID,
	iqentry_5_latestID,
	iqentry_6_latestID,
	iqentry_7_latestID,
	iqentry_8_latestID,
	iqentry_9_latestID,
	iqentry_10_latestID,
	iqentry_11_latestID,
	iqentry_12_latestID,
	iqentry_13_latestID,
	iqentry_14_latestID,
	iqentry_15_latestID,
	iq,
	rf_source
);
input rst;
input clk;
input branchmiss;
input [15:1] iqentry_0_latestID;
input [15:1] iqentry_1_latestID;
input [15:1] iqentry_2_latestID;
input [15:1] iqentry_3_latestID;
input [15:1] iqentry_4_latestID;
input [15:1] iqentry_5_latestID;
input [15:1] iqentry_6_latestID;
input [15:1] iqentry_7_latestID;
input [15:1] iqentry_8_latestID;
input [15:1] iqentry_9_latestID;
input [15:1] iqentry_10_latestID;
input [15:1] iqentry_11_latestID;
input [15:1] iqentry_12_latestID;
input [15:1] iqentry_13_latestID;
input [15:1] iqentry_14_latestID;
input [15:1] iqentry_15_latestID;
input iq_entry_t [7:0] iq;
output reg [4:0] rf_source [0:15];

always_ff @(posedge clk, posedge rst)
if (rst) begin
	rf_source[0] <= 'd0;
	rf_source[1] <= 'd0;
	rf_source[2] <= 'd0;
	rf_source[3] <= 'd0;
	rf_source[4] <= 'd0;
	rf_source[5] <= 'd0;
	rf_source[6] <= 'd0;
	rf_source[7] <= 'd0;
	rf_source[8] <= 'd0;
	rf_source[9] <= 'd0;
	rf_source[10] <= 'd0;
	rf_source[11] <= 'd0;
	rf_source[12] <= 'd0;
	rf_source[13] <= 'd0;
	rf_source[14] <= 'd0;
	rf_source[15] <= 'd0;
end
else begin
	if (branchmiss) begin
    if (|iqentry_0_latestID)	rf_source[ iq[0].tgt ] <= { iq[0].mem, 4'd0 };
    if (|iqentry_1_latestID)	rf_source[ iq[1].tgt ] <= { iq[1].mem, 4'd1 };
    if (|iqentry_2_latestID)	rf_source[ iq[2].tgt ] <= { iq[2].mem, 4'd2 };
    if (|iqentry_3_latestID)	rf_source[ iq[3].tgt ] <= { iq[3].mem, 4'd3 };
    if (|iqentry_4_latestID)	rf_source[ iq[4].tgt ] <= { iq[4].mem, 4'd4 };
    if (|iqentry_5_latestID)	rf_source[ iq[5].tgt ] <= { iq[5].mem, 4'd5 };
    if (|iqentry_6_latestID)	rf_source[ iq[6].tgt ] <= { iq[6].mem, 4'd6 };
    if (|iqentry_7_latestID)	rf_source[ iq[7].tgt ] <= { iq[7].mem, 4'd7 };
    if (|iqentry_8_latestID)	rf_source[ iq[8].tgt ] <= { iq[8].mem, 4'd8 };
    if (|iqentry_9_latestID)	rf_source[ iq[9].tgt  ] <= { iq[9].mem, 4'd9 };
    if (|iqentry_10_latestID)	rf_source[ iq[10].tgt ] <= { iq[10].mem, 4'd10 };
    if (|iqentry_11_latestID)	rf_source[ iq[11].tgt ] <= { iq[11].mem, 4'd11 };
    if (|iqentry_12_latestID)	rf_source[ iq[12].tgt ] <= { iq[13].mem, 4'd12 };
    if (|iqentry_13_latestID)	rf_source[ iq[13].tgt ] <= { iq[13].mem, 4'd13 };
    if (|iqentry_14_latestID)	rf_source[ iq[14].tgt ] <= { iq[14].mem, 4'd14 };
    if (|iqentry_15_latestID)	rf_source[ iq[15].tgt ] <= { iq[15].mem, 4'd15 };
	end
end

endmodule
