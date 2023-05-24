import rfx32pkg::*;

module rfx32_ifetch(rst, clk, hit, irq, branchback, backpc, branchmiss, misspc,
	pc, inst0, inst1, iq, tail0, tail1,
	fetchbuf, fetchbuf0_instr, fetchbuf0_v, fetchbuf0_pc, 
	fetchbuf1_instr, fetchbuf1_v, fetchbuf1_pc);
input rst;
input clk;
input hit;
input irq;
input branchback;
input address_t backpc;
input branchmiss;
input address_t misspc;
output address_t pc;
input instruction_t inst0;
input instruction_t inst1;
input iq_entry_t [7:0] iq;
input [2:0] tail0;
input [2:0] tail1;
output reg fetchbuf;
output instruction_t fetchbuf0_instr;
output reg fetchbuf0_v;
output address_t fetchbuf0_pc;
output instruction_t fetchbuf1_instr;
output reg fetchbuf1_v;
output address_t fetchbuf1_pc;

reg [3:0] panic;
reg did_branchback;
reg fetchbufA_v;
reg fetchbufB_v;
reg fetchbufC_v;
reg fetchbufD_v;

instruction_t fetchbufA_instr;
instruction_t fetchbufB_instr;
instruction_t fetchbufC_instr;
instruction_t fetchbufD_instr;
address_t fetchbufA_pc;
address_t fetchbufB_pc;
address_t fetchbufC_pc;
address_t fetchbufD_pc;

always_ff @(posedge clk, posedge rst)
if (rst) begin
	pc <= 32'hFFFD0000;
	did_branchback <= 'd0;
	fetchbuf <= 'd0;
	fetchbufA_v <= INV;
	fetchbufB_v <= INV;
	fetchbufC_v <= INV;
	fetchbufD_v <= INV;
	fetchbufA_pc <= 'd0;
	fetchbufA_instr <= 'd0;
	fetchbufB_pc <= 'd0;
	fetchbufB_instr <= 'd0;
	fetchbufC_pc <= 'd0;
	fetchbufC_instr <= 'd0;
	fetchbufD_pc <= 'd0;
	fetchbufD_instr <= 'd0;
end
else begin

	did_branchback <= branchback;

	if (branchmiss) begin
    pc <= misspc;
    fetchbuf <= 1'b0;
    fetchbufA_v <= INV;
    fetchbufB_v <= INV;
    fetchbufC_v <= INV;
    fetchbufD_v <= INV;
	end
	else if (branchback) begin

    // update the fetchbuf valid bits as well as fetchbuf itself
    // ... this must be based on which things are backwards branches, how many things
    // will get enqueued (0, 1, or 2), and how old the instructions are
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v})

		4'b0000	: ;	// do nothing
		4'b0001	: panic <= PANIC_INVALIDFBSTATE;
		4'b0010	: panic <= PANIC_INVALIDFBSTATE;
		4'b0011	: panic <= PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

		// because the first instruction has been enqueued, 
		// we must have noted this in the previous cycle.
		// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
		// this looks like the following:
		//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, stomped on fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
		4'b0100: 
			begin
				if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
					tFetchCD();
			    fetchbufB_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
		  end

		4'b0101: panic <= PANIC_INVALIDFBSTATE;
		4'b0110: panic <= PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, but not fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufB_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b0111:
			begin
				if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
			    fetchbufB_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufC_v, fnIsBackBranch(fetchbufC_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufB_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufB_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
		//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufA_v appropriately
		4'b1000:
			begin
				if ({fetchbufA_v, fnIsBackBranch(fetchbufA_instr)} == {VAL, TRUE}) begin
					tFetchCD();
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		4'b1001: panic <= PANIC_INVALIDFBSTATE;
		4'b1010: panic <= PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
		//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbA, but fetched from backwards target
		//   cycle 3 - where we are now ... set fetchbufA_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1011:
			begin
				if ({fetchbufA_v, fnIsBackBranch(fetchbufA_instr)} == {VAL, TRUE}) begin
				    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
				    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufC_v, fnIsBackBranch(fetchbufC_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		// if fbB has the branchback, can't immediately tell which of the following scenarios it is:
		//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
		//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
		// or
		//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - could not enqueue fbA or fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
		// if fbA has the branchback, then it is scenario 1.
		// if fbB has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
		4'b1100:
			begin
				if ({fetchbufA_v, fnIsBackBranch(fetchbufA_instr)} == {VAL, TRUE}) begin
			    // has to be first scenario
			    pc <= backpc;
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufB_v <= INV;		// stomp on it
			    if (~iq[tail0].v)	fetchbuf <= 1'b0;
				end
				else if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
			    if (did_branchback) begin
			    	tFetchCD();
						fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
						fetchbufB_v <= iq[tail1].v;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
			    end
			    else begin
						pc <= backpc;
						fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
						fetchbufB_v <= iq[tail1].v;	// if it can be queued, it will
						if (~iq[tail0].v & ~iq[tail1].v)	fetchbuf <= 1'b0;
			    end
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		4'b1101: panic <= PANIC_INVALIDFBSTATE;
		4'b1110: panic <= PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued neither fbA nor fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufX_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1111:
			begin
				if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufB_v <= iq[tail1].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
				end
				else if ({fetchbufC_v, fnIsBackBranch(fetchbufC_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufB_v <= iq[tail1].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
				end
				else if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufB_v <= iq[tail1].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
				end
				else panic <= PANIC_BRANCHBACK;
	    end

	  endcase
    else case ({fetchbufC_v, fetchbufD_v, fetchbufA_v, fetchbufB_v})

		4'b0000: ; // do nothing
		4'b0001: panic <= PANIC_INVALIDFBSTATE;
		4'b0010: panic <= PANIC_INVALIDFBSTATE;
		4'b0011: panic <= PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

		// because the first instruction has been enqueued, 
		// we must have noted this in the previous cycle.
		// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
		// this looks like the following:
		//   cycle 0 - fetched a INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued fbC, stomped on fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
		4'b0100:
			begin
				if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
					tFetchAB();
			    fetchbufD_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		4'b0101: panic <= PANIC_INVALIDFBSTATE;
		4'b0110: panic <= PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued fbC, but not fbD, recognized branchback in fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbD, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufD_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b0111:
			begin
				if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
			    fetchbufD_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufA_v, fnIsBackBranch(fetchbufA_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufD_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufD_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbC holding a branchback
		//   cycle 1 - stomped on fbD, but could not enqueue fbC, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufC_v appropriately
		4'b1000:
			begin
				if ({fetchbufC_v, fnIsBackBranch(fetchbufC_instr)} == {VAL, TRUE}) begin
					tFetchAB();
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		4'b1001: panic <= PANIC_INVALIDFBSTATE;
		4'b1010: panic <= PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbC holding a branchback
		//   cycle 1 - stomped on fbD, but could not enqueue fbC, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbC, but fetched from backwards target
		//   cycle 3 - where we are now ... set fetchbufC_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1011:
			begin
				if ({fetchbufC_v, fnIsBackBranch(fetchbufC_instr)} == {VAL, TRUE}) begin
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufA_v, fnIsBackBranch(fetchbufA_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iq[tail0].v;
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		// if fbD has the branchback, can't immediately tell which of the following scenarios it is:
		//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
		//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
		// or
		//   cycle 0 - fetched a INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - could not enqueue fbC or fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
		// if fbC has the branchback, then it is scenario 1.
		// if fbD has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
		4'b1100:
			begin
				if ({fetchbufC_v, fnIsBackBranch(fetchbufC_instr)} == {VAL, TRUE}) begin
			    // has to be first scenario
			    pc <= backpc;
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufD_v <= INV;		// stomp on it
			    if (~iq[tail0].v)	fetchbuf <= 1'b0;
				end
				else if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
			    if (did_branchback) begin
			    	tFetchAB();
						fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
						fetchbufD_v <= iq[tail1].v;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
			    end
			    else begin
						pc <= backpc;
						fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
						fetchbufD_v <= iq[tail1].v;	// if it can be queued, it will
						if (~iq[tail0].v & ~iq[tail1].v)	fetchbuf <= 1'b0;
			    end
				end
				else panic <= PANIC_BRANCHBACK;
	    end

		4'b1101: panic <= PANIC_INVALIDFBSTATE;
		4'b1110: panic <= PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued neither fbC nor fbD, recognized branchback in fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbD, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufX_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1111:
			begin
				if ({fetchbufD_v, fnIsBackBranch(fetchbufD_instr)} == {VAL, TRUE}) begin
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufD_v <= iq[tail1].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
				end
				else if ({fetchbufA_v, fnIsBackBranch(fetchbufA_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufD_v <= iq[tail1].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
				end
				else if ({fetchbufB_v, fnIsBackBranch(fetchbufB_instr)} == {VAL, TRUE}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iq[tail0].v;	// if it can be queued, it will
			    fetchbufD_v <= iq[tail1].v;	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iq[tail0].v & ~iq[tail1].v);
				end
				else panic <= PANIC_BRANCHBACK;
	    end
    endcase

	end // if branchback

	else begin	// there is no branchback in the system
    //
    // update fetchbufX_v and fetchbuf ... relatively simple, as
    // there are no backwards branches in the mix
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, ~iq[tail0].v, ~iq[tail1].v})
		4'b00_00: ;	// do nothing
		4'b00_01: panic <= PANIC_INVALIDIQSTATE;
		4'b00_10: ;	// do nothing
		4'b00_11: ;	// do nothing
		4'b01_00: ;	// do nothing
		4'b01_01: panic <= PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11:
			begin	// enqueue fbB and flip fetchbuf
				fetchbufB_v <= INV;
				fetchbuf <= ~fetchbuf;
		  end

		4'b10_00: ;	// do nothing
		4'b10_01: panic <= PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11:
			begin	// enqueue fbA and flip fetchbuf
				fetchbufA_v <= INV;
				fetchbuf <= ~fetchbuf;
		  end

		4'b11_00: ;	// do nothing
		4'b11_01: panic <= PANIC_INVALIDIQSTATE;

		4'b11_10:
			begin	// enqueue fbA but leave fetchbuf
				fetchbufA_v <= INV;
		  end

		4'b11_11:
			begin	// enqueue both and flip fetchbuf
				fetchbufA_v <= INV;
				fetchbufB_v <= INV;
				fetchbuf <= ~fetchbuf;
		  end
	  endcase
	  else case ({fetchbufC_v, fetchbufD_v, ~iq[tail0].v, ~iq[tail1].v})
		4'b00_00: ;	// do nothing
		4'b00_01: panic <= PANIC_INVALIDIQSTATE;
		4'b00_10: ;	// do nothing
		4'b00_11: ;	// do nothing
		4'b01_00: ;	// do nothing
		4'b01_01: panic <= PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11:
			begin	// enqueue fbD and flip fetchbuf
				fetchbufD_v <= INV;
				fetchbuf <= ~fetchbuf;
		  end

		4'b10_00: ;	// do nothing
		4'b10_01: panic <= PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11:
			begin	// enqueue fbC and flip fetchbuf
				fetchbufC_v <= INV;
				fetchbuf <= ~fetchbuf;
		  end

		4'b11_00: ;	// do nothing
		4'b11_01: panic <= PANIC_INVALIDIQSTATE;

		4'b11_10:
			begin	// enqueue fbC but leave fetchbuf
				fetchbufC_v <= INV;
		  end

		4'b11_11:
			begin	// enqueue both and flip fetchbuf
				fetchbufC_v <= INV;
				fetchbufD_v <= INV;
				fetchbuf <= ~fetchbuf;
		  end
	  endcase
	    //
	    // get data iff the fetch buffers are empty
	    //
	  if (fetchbufA_v == INV && fetchbufB_v == INV) begin
	  	tFetchAB();
      // fetchbuf steering logic correction
      if (fetchbufC_v==INV && fetchbufD_v==INV && hit)
        fetchbuf <= 1'b0;
    end
    else if (fetchbufC_v == INV && fetchbufD_v == INV)
    	tFetchCD();
	end
end

always_comb
	fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
always_comb
	fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
always_comb
	fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
always_comb
	fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
always_comb
	fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
always_comb
	fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;

task tFetchAB;
begin
  fetchbufA_instr <= inst0;
  fetchbufA_v <= VAL;
  fetchbufA_pc <= pc;
  fetchbufB_instr <= inst1;
  fetchbufB_v <= VAL;
  fetchbufB_pc <= pc + 4'd4;
  if (hit & ~irq)
	  pc <= pc + 4'd8;
end
endtask

task tFetchCD;
begin
  fetchbufC_instr <= inst0;
  fetchbufC_v <= VAL;
  fetchbufC_pc <= pc;
  fetchbufD_instr <= inst1;
  fetchbufD_v <= VAL;
  fetchbufD_pc <= pc + 4'd4;
  if (hit & ~irq)
  	pc <= pc + 4'd8;
end
endtask

endmodule
