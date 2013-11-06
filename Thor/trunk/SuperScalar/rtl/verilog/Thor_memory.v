// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
// Instruction fetch logic
//
// ============================================================================
//
    //
    // MEMORY
    //
    // update the memory queues and put data out on bus if appropriate
    //
	//
	// dram0, dram1, dram2 are the "state machines" that keep track
	// of three pipelined DRAM requests.  if any has the value "00", 
	// then it can accept a request (which bumps it up to the value "01"
	// at the end of the cycle).  once it hits the value "11" the request
	// is finished and the dram_bus takes the value.  if it is a store, the 
	// dram_bus value is not used, but the dram_v value along with the
	// dram_id value signals the waiting memq entry that the store is
	// completed and the instruction can commit.
	//

	if (dram0 != `DRAMSLOT_AVAIL)	dram0 <= dram0 + 2'd1;
	if (dram1 != `DRAMSLOT_AVAIL)	dram1 <= dram1 + 2'd1;
	if (dram2 != `DRAMSLOT_AVAIL)	dram2 <= dram2 + 2'd1;

	casex ({dram0, dram1, dram2})
	    // not particularly portable ...
	    6'b1111xx,
	    6'b11xx11,
	    6'bxx1111:	panic <= `PANIC_IDENTICALDRAMS;

	    default: begin
		//
		// grab requests that have finished and put them on the dram_bus
		if (dram0 == `DRAMREQ_READY) begin
		    dram_v <= (dram0_op == `LW);
		    dram_id <= dram0_id;
		    dram_tgt <= dram0_tgt;
		    dram_exc <= dram0_exc;
		    if (dram0_op == `LW) 	dram_bus <= m[ dram0_addr ];
		    else if (dram0_op == `SW) 	m[ dram0_addr ] <= dram0_data;
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram0_op == `SW) 	$display("m[%h] <- %h", dram0_addr, dram0_data);
		end
		else if (dram1 == `DRAMREQ_READY) begin
		    dram_v <= (dram1_op == `LW);
		    dram_id <= dram1_id;
		    dram_tgt <= dram1_tgt;
		    dram_exc <= dram1_exc;
		    if (dram1_op == `LW) 	dram_bus <= m[ dram1_addr ];
		    else if (dram1_op == `SW) 	m[ dram1_addr ] <= dram1_data;
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram1_op == `SW) 	$display("m[%h] <- %h", dram1_addr, dram1_data);
		end
		else if (dram2 == `DRAMREQ_READY) begin
		    dram_v <= (dram2_op == `LW);
		    dram_id <= dram2_id;
		    dram_tgt <= dram2_tgt;
		    dram_exc <= dram2_exc;
		    if (dram2_op == `LW) 	dram_bus <= m[ dram2_addr ];
		    else if (dram2_op == `SW) 	m[ dram2_addr ] <= dram2_data;
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram2_op == `SW) 	$display("m[%h] <- %h", dram2_addr, dram2_data);
		end
		else begin
		    dram_v <= `INV;
		end
	    end
	endcase

	//
	// determine if the instructions ready to issue can, in fact, issue.
	// "ready" means that the instruction has valid operands but has not gone yet
	iqentry_memissue[ head0 ] <=	iqentry_memready[ head0 ];		// first in line ... go as soon as ready

	iqentry_memissue[ head1 ] <=	~iqentry_stomp[head1] && iqentry_memready[ head1 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head1] != iqentry_a1[head0]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head1]) || !fnIsFlowCtrl(iqentry_op[head0]));

	iqentry_memissue[ head2 ] <=	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head2] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head2] != iqentry_a1[head1]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head2]) ||
					    (   !fnIsFlowCtrl(iqentry_op[head0])
					     && !fnIsFlowCtrl(iqentry_op[head1])));

	iqentry_memissue[ head3 ] <=	~iqentry_stomp[head3] && iqentry_memready[ head3 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head3] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head3] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head3] != iqentry_a1[head2]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head3]) ||
					    (   !fnIsFlowCtrl(iqentry_op[head0])
					     && !fnIsFlowCtrl(iqentry_op[head1])
					     && !fnIsFlowCtrl(iqentry_op[head2])));

	iqentry_memissue[ head4 ] <=	~iqentry_stomp[head4] && iqentry_memready[ head4 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head4] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head4] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head4] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head4] != iqentry_a1[head3]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head4]) ||
					    (   !fnIsFlowCtrl(iqentry_op[head0])
					     && !fnIsFlowCtrl(iqentry_op[head1])
					     && !fnIsFlowCtrl(iqentry_op[head2])
					     && !fnIsFlowCtrl(iqentry_op[head3])));

	iqentry_memissue[ head5 ] <=	~iqentry_stomp[head5] && iqentry_memready[ head5 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					&& ~iqentry_memready[head4] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head5] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head5] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head5] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head5] != iqentry_a1[head3]))
					&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
						|| (iqentry_a1_v[head4] && iqentry_a1[head5] != iqentry_a1[head4]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head5])||
					    (   !fnIsFlowCtrl(iqentry_op[head0])
					     && !fnIsFlowCtrl(iqentry_op[head1])
					     && !fnIsFlowCtrl(iqentry_op[head2])
					     && !fnIsFlowCtrl(iqentry_op[head3])
					     && !fnIsFlowCtrl(iqentry_op[head4])));

	iqentry_memissue[ head6 ] <=	~iqentry_stomp[head6] && iqentry_memready[ head6 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					&& ~iqentry_memready[head4] 
					&& ~iqentry_memready[head5] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head6] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head6] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head6] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head6] != iqentry_a1[head3]))
					&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
						|| (iqentry_a1_v[head4] && iqentry_a1[head6] != iqentry_a1[head4]))
					&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
						|| (iqentry_a1_v[head5] && iqentry_a1[head6] != iqentry_a1[head5]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head6])||
					    (   !fnIsFlowCtrl(iqentry_op[head0])
					     && !fnIsFlowCtrl(iqentry_op[head1])
					     && !fnIsFlowCtrl(iqentry_op[head2])
					     && !fnIsFlowCtrl(iqentry_op[head3])
					     && !fnIsFlowCtrl(iqentry_op[head4])
					     && !fnIsFlowCtrl(iqentry_op[head5])));

	iqentry_memissue[ head7 ] <=	~iqentry_stomp[head7] && iqentry_memready[ head7 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					&& ~iqentry_memready[head4] 
					&& ~iqentry_memready[head5] 
					&& ~iqentry_memready[head6] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head7] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head7] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head7] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head7] != iqentry_a1[head3]))
					&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
						|| (iqentry_a1_v[head4] && iqentry_a1[head7] != iqentry_a1[head4]))
					&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
						|| (iqentry_a1_v[head5] && iqentry_a1[head7] != iqentry_a1[head5]))
					&& (!iqentry_mem[head6] || (iqentry_agen[head6] & iqentry_out[head6]) 
						|| (iqentry_a1_v[head6] && iqentry_a1[head7] != iqentry_a1[head6]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (!fnIsStore(iqentry_op[head7]) ||
					    (   !fnIsFlowCtrl(iqentry_op[head0])
					     && !fnIsFlowCtrl(iqentry_op[head1])
					     && !fnIsFlowCtrl(iqentry_op[head2])
					     && !fnIsFlowCtrl(iqentry_op[head3])
					     && !fnIsFlowCtrl(iqentry_op[head4])
					     && !fnIsFlowCtrl(iqentry_op[head5])
					     && !fnIsFlowCtrl(iqentry_op[head6])));

	//
	// take requests that are ready and put them into DRAM slots

	if (dram0 == `DRAMSLOT_AVAIL)	dram0_exc <= `EXC_NONE;
	if (dram1 == `DRAMSLOT_AVAIL)	dram1_exc <= `EXC_NONE;
	if (dram2 == `DRAMSLOT_AVAIL)	dram2_exc <= `EXC_NONE;

	for (n = 0; n < 8; n = n + 1)
		if (~iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && ~iqentry_out[n] && iqentry_cmt[n]) begin
			if (dram0 == `DRAMSLOT_AVAIL) begin
				dram0 		<= 2'd1;
				dram0_id 	<= { 1'b1, n[2:0] };
				dram0_op 	<= iqentry_op[n];
				dram0_tgt 	<= iqentry_tgt[n];
				dram0_data	<= iqentry_a2[n];
				dram0_addr	<= iqentry_a1[n];
				iqentry_out[n]	<= `TRUE;
			end
			else if (dram1 == `DRAMSLOT_AVAIL) begin
				dram1 		<= 2'd1;
				dram1_id 	<= { 1'b1, n[2:0] };
				dram1_op 	<= iqentry_op[n];
				dram1_tgt 	<= iqentry_tgt[n];
				dram1_data	<= iqentry_a2[n];
				dram1_addr	<= iqentry_a1[n];
				iqentry_out[n]	<= `TRUE;
			end
			else if (dram2 == `DRAMSLOT_AVAIL) begin
				dram2 		<= 2'd1;
				dram2_id 	<= { 1'b1, n[2:0] };
				dram2_op 	<= iqentry_op[n];
				dram2_tgt 	<= iqentry_tgt[n];
				dram2_data	<= iqentry_a2[n];
				dram2_addr	<= iqentry_a1[n];
				iqentry_out[n]	<= `TRUE;
			end
		end

