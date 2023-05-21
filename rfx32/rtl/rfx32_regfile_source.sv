import rfx32pkg::*;

module rfx32_regfile_source(rst, clk, tail0, tail1, branchmiss,
	fetchbuf0_instr,
	fetchbuf1_instr,
	fetchbuf0_mem,
	fetchbuf1_mem,
	fetchbuf0_v,
	fetchbuf1_v,
	fetchbuf0_rfw,
	fetchbuf1_rfw,
	iqentry_0_latestID,
	iqentry_1_latestID,
	iqentry_2_latestID,
	iqentry_3_latestID,
	iqentry_4_latestID,
	iqentry_5_latestID,
	iqentry_6_latestID,
	iqentry_7_latestID,
	iq,
	rf_source
);
input rst;
input clk;
input [2:0] tail0;
input [2:0] tail1;
input branchmiss;
input instruction_t fetchbuf0_instr;
input instruction_t fetchbuf1_instr;
input fetchbuf0_mem;
input fetchbuf1_mem;
input fetchbuf0_v;
input fetchbuf1_v;
input fetchbuf0_rfw;
input fetchbuf1_rfw;
input [31:1] iqentry_0_latestID;
input [31:1] iqentry_1_latestID;
input [31:1] iqentry_2_latestID;
input [31:1] iqentry_3_latestID;
input [31:1] iqentry_4_latestID;
input [31:1] iqentry_5_latestID;
input [31:1] iqentry_6_latestID;
input [31:1] iqentry_7_latestID;
input iq_entry_t [7:0] iq;
output reg [4:0] rf_source [0:31];

integer nn;

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (nn = 0; nn < 32; nn = nn + 1)
		rf_source[nn] <= 'd0;
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
    /*
    if (|iqentry_8_latestID)	rf_source[ iq[8].tgt ] <= { iq[8].mem, 4'd8 };
    if (|iqentry_9_latestID)	rf_source[ iq[9].tgt  ] <= { iq[9].mem, 4'd9 };
    if (|iqentry_10_latestID)	rf_source[ iq[10].tgt ] <= { iq[10].mem, 4'd10 };
    if (|iqentry_11_latestID)	rf_source[ iq[11].tgt ] <= { iq[11].mem, 4'd11 };
    if (|iqentry_12_latestID)	rf_source[ iq[12].tgt ] <= { iq[13].mem, 4'd12 };
    if (|iqentry_13_latestID)	rf_source[ iq[13].tgt ] <= { iq[13].mem, 4'd13 };
    if (|iqentry_14_latestID)	rf_source[ iq[14].tgt ] <= { iq[14].mem, 4'd14 };
    if (|iqentry_15_latestID)	rf_source[ iq[15].tgt ] <= { iq[15].mem, 4'd15 };
    */
	end
	else begin
		case ({fetchbuf0_v, fetchbuf1_v})
		2'b00:	;
		2'b01:
			if (iq[tail0].v == INV) begin
				if (fetchbuf1_rfw)
			    rf_source[ fetchbuf1_instr.r2.Ra.num ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
			end
		2'b10:	;
		2'b11:
			if (iq[tail0].v == INV) begin
				if (fnIsBackBranch(fetchbuf0_instr)) begin
					if (iq[tail1].v == INV) begin
						//
						// if the two instructions enqueued target the same register, 
						// make sure only the second writes to rf_v and rf_source.
						// first is allowed to update rf_v and rf_source only if the
						// second has no target (BEQ or SW)
						//
						if (fetchbuf0_instr.r2.Ra.num == fetchbuf1_instr.r2.Ra.num) begin
					    if (fetchbuf1_rfw)
								rf_source[ fetchbuf1_instr.r2.Ra.num ] <= { fetchbuf1_mem, tail1 };
					    else if (fetchbuf0_rfw)
								rf_source[ fetchbuf0_instr.r2.Ra.num ] <= { fetchbuf0_mem, tail0 };
						end
						else begin
					    if (fetchbuf0_rfw)
								rf_source[ fetchbuf0_instr.r2.Ra.num ] <= { fetchbuf0_mem, tail0 };
					    if (fetchbuf1_rfw)
								rf_source[ fetchbuf1_instr.r2.Ra.num ] <= { fetchbuf1_mem, tail1 };
						end
			    end	// ends the "if IQ[tail1] is available" clause
		    	else begin	// only first instruction was enqueued
						if (fetchbuf0_rfw)
					    rf_source[ fetchbuf0_instr.r2.Ra.num ] <= {fetchbuf0_mem, tail0};
			    end
				end		
			end
		endcase
	end
end

endmodule
