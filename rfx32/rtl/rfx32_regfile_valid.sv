import rfx32pkg::*;

module rfx32_regfile_valid(rst, clk, branchmiss, livetarget, tail0, tail1,
	fetchbuf0_v, fetchbuf1_v, fetchbuf0_rfw, fetchbuf1_rfw, fetchbuf0_instr, fetchbuf1_instr,
	iq, iqentry_source,
	commit0_v, commit1_v, commit0_tgt, commit1_tgt, commit0_id, commit1_id,
	rf_source, rf_v);
input rst;
input clk;
input branchmiss;
input [31:1] livetarget;
input [2:0] tail0;
input [2:0] tail1;
input fetchbuf0_v;
input fetchbuf1_v;
input fetchbuf0_rfw;
input fetchbuf1_rfw;
input instruction_t fetchbuf0_instr;
input instruction_t fetchbuf1_instr;
input iq_entry_t [7:0] iq;
input [7:0] iqentry_source;
input commit0_v;
input commit1_v;
input [4:0] commit0_tgt;
input [4:0] commit1_tgt;
input [4:0] commit0_id;
input [4:0] commit1_id;
input [4:0] rf_source [0:31];
output reg [31:0] rf_v;

integer n, n1;

initial begin
	for (n = 0; n < 16; n = n + 1)
	  rf_v[n] = 1'b1;
end

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (n1 = 0; n1 < 32; n1 = n1 + 1)
	  rf_v[n1] = 1'b1;
end
else begin

	if (branchmiss) begin
		for (n1 = 1; n1 < 32; n1 = n1 + 1)
		  if (rf_v[n1] == INV && ~livetarget[n1])	rf_v[n1] = VAL;
	end
	//
	// COMMIT PHASE (register-file update only ... dequeue is elsewhere)
	//
	// look at head0 and head1 and let 'em write the register file if they are ready
	//
	// why is it happening here and not in another phase?
	// want to emulate a pass-through register file ... i.e. if we are reading
	// out of r3 while writing to r3, the value read is the value written.
	// requires BLOCKING assignments, so that we can read from rf[i] later.
	//
	if (commit0_v) begin
    if (!rf_v[ commit0_tgt ]) 
			rf_v[ commit0_tgt ] = rf_source[ commit0_tgt ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
	end
	if (commit1_v) begin
    if (!rf_v[ commit1_tgt ]) 
			rf_v[ commit1_tgt ] = rf_source[ commit1_tgt ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
	end

	rf_v[0] = 1;

	if (!branchmiss) begin	
		case ({fetchbuf0_v, fetchbuf1_v})
    2'b00: ; // do nothing
    2'b01:
    	if (iq[tail0].v == INV) begin
				if (fetchbuf1_rfw)
			    rf_v[ fetchbuf1_instr.r2.Ra.num ] = INV;
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
								rf_v[ fetchbuf1_instr.r2.Ra.num ] = INV;
					    else if (fetchbuf0_rfw)
								rf_v[ fetchbuf0_instr.r2.Ra.num ] = INV;
						end
						else begin
					    if (fetchbuf0_rfw)
								rf_v[ fetchbuf0_instr.r2.Ra.num ] = INV;
					    if (fetchbuf1_rfw)
								rf_v[ fetchbuf1_instr.r2.Ra.num ] = INV;
						end
			    end	// ends the "if IQ[tail1] is available" clause
		    	else begin	// only first instruction was enqueued
						if (fetchbuf0_rfw)
					    rf_v[ fetchbuf0_instr.r2.Ra.num ] = INV;
			    end
				end		
			end
  	endcase
  end
	rf_v[0] = 1;
end

endmodule
