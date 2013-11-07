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
		if (~commit0_tgt[8]) begin
			if (!rf_v[ commit0_tgt ]) 
				rf_v[ commit0_tgt ] <= rf_source[ commit0_tgt ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
			if (commit0_tgt != 8'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
		end
		else if (commit0_tgt[8:4]==5'h10) begin
			if (!pf_v[commit0_tgt[3:0]])
				pf_v[commit0_tgt[3:0]] <= pf_source[commit0_tgt[3:0]]==commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
		end
	end
	if (commit1_v) begin
		if (~commit1_tgt[8]) begin
			if (!rf_v[ commit1_tgt ]) 
				rf_v[ commit1_tgt ] <= rf_source[ commit1_tgt ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
			if (commit1_tgt != 8'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
		end
		else if (commit1_tgt[8:4]==5'h10) begin
			if (!pf_v[commit1_tgt[3:0]])
				pf_v[commit1_tgt[3:0]] <= pf_source[commit1_tgt[3:0]]==commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
		end
	end

    //
    // COMMIT PHASE (dequeue only ... not register-file update)
    //
    // look at head0 and head1 and let 'em write to the register file if they are ready
    //
	if (~|panic)
	case ({ iqentry_v[head0],
		iqentry_done[head0],
		iqentry_v[head1],
		iqentry_done[head1] })

	    // 4'b00_00	- neither valid; skip both
	    // 4'b00_01	- neither valid; skip both
	    // 4'b00_10	- skip head0, wait on head1
	    // 4'b00_11	- skip head0, commit head1
	    // 4'b01_00	- neither valid; skip both
	    // 4'b01_01	- neither valid; skip both
	    // 4'b01_10	- skip head0, wait on head1
	    // 4'b01_11	- skip head0, commit head1
	    // 4'b10_00	- wait on head0
	    // 4'b10_01	- wait on head0
	    // 4'b10_10	- wait on head0
	    // 4'b10_11	- wait on head0
	    // 4'b11_00	- commit head0, skip head1
	    // 4'b11_01	- commit head0, skip head1
	    // 4'b11_10	- commit head0, wait on head1
	    // 4'b11_11	- commit head0, commit head1

	    //
	    // retire 0
	    4'b10_00,
	    4'b10_01,
	    4'b10_10,
	    4'b10_11: ;

	    //
	    // retire 1
	    4'b00_10,
	    4'b01_10,
	    4'b11_10: begin
		if (iqentry_v[head0] || head0 != tail0) begin
		    iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 1;
		    head1 <= head1 + 1;
		    head2 <= head2 + 1;
		    head3 <= head3 + 1;
		    head4 <= head4 + 1;
		    head5 <= head5 + 1;
		    head6 <= head6 + 1;
		    head7 <= head7 + 1;
		    if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 1;
		end
	    end

	    //
	    // retire 2
	    default: begin
		if ((iqentry_v[head0] && iqentry_v[head1]) || (head0 != tail0 && head1 != tail0)) begin
		    iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    iqentry_v[head1] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 2;
		    head1 <= head1 + 2;
		    head2 <= head2 + 2;
		    head3 <= head3 + 2;
		    head4 <= head4 + 2;
		    head5 <= head5 + 2;
		    head6 <= head6 + 2;
		    head7 <= head7 + 2;
		    if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
		    if (iqentry_v[head1] && iqentry_exc[head1])	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 2;
		end
		else if (iqentry_v[head0] || head0 != tail0) begin
		    iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 1;
		    head1 <= head1 + 1;
		    head2 <= head2 + 1;
		    head3 <= head3 + 1;
		    head4 <= head4 + 1;
		    head5 <= head5 + 1;
		    head6 <= head6 + 1;
		    head7 <= head7 + 1;
		    if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 1;
		end
	    end
	endcase
