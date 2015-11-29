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
// Memory logic
//
// ============================================================================
//
//
// MEMORY
//
// update the memory queues and put data out on bus if appropriate
// Always puts data on the bus even for stores. In the case of
// stores, the data is ignored.
//
//
// dram0, dram1, dram2 are the "state machines" that keep track
// of three pipelined DRAM requests.  if any has the value "00", 
// then it can accept a request (which bumps it up to the value "01"
// at the end of the cycle).  once it hits the value "10" the request
// and the bus is acknowledged the dram request
// is finished and the dram_bus takes the value.  if it is a store, the 
// dram_bus value is not used, but the dram_v value along with the
// dram_id value signals the waiting memq entry that the store is
// completed and the instruction can commit.
//
if (tlb_state != 3'd0 && tlb_state < 3'd3)
	tlb_state <= tlb_state + 3'd1;
if (tlb_state==3'd3) begin
	dram_v <= `TRUE;
	dram_id <= tlb_id;
	dram_tgt <= tlb_tgt;
	dram_exc <= `EXC_NONE;
	dram_bus <= tlb_dato;
	tlb_op <= 4'h0;
	tlb_state <= 3'd0;
end

case(dram0)
// The first state is to translate the virtual to physical address.
3'd1:
	begin
		$display("0MEM %c:%h %h cycle started",fnIsLoad(dram0_op)?"L" : "S", dram0_addr, dram0_data);
		dram0 <= dram0 + 3'd1;
	end

// State 2:
// Check for a TLB miss on the translated address, and
// Initiate a bus transfer
3'd2:
	if (DTLBMiss) begin
		dram_v <= `TRUE;			// we are finished the memory cycle
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= `EXC_TLBMISS;	//dram0_exc;
		dram_bus <= 64'h0;
		dram0 <= 3'd0;
	end
	else begin
		if (uncached || fnIsStore(dram0_op) || fnIsLoadV(dram0_op) || dram0_op==`CAS) begin
			dram0_owns_bus <= `TRUE;
			lock_o <= dram0_op==`CAS;
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			we_o <= fnIsStore(dram0_op);
			sel_o <= fnSelect(dram0_op,pea);
			adr_o <= pea;
			dat_o <= fnDatao(dram0_op,dram0_data);
			dram0 <= dram0 + 3'd1;
		end
		else	// cached read
			dram0 <= 3'd6;
	end

// State 3:
// Wait for a memory ack
3'd3:
	if (ack_i|err_i) begin
		$display("MEM ack");
		dram_v <= dram0_op != `CAS;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= err_i ? `EXC_DBE : `EXC_NONE;//dram0_exc;
		dram_bus <= fnDatai(dram0_op,dat_i,sel_o);
		dram0_owns_bus <= `FALSE;
		wb_nack();
		dram0 <= 3'd0;
		case(dram0_op)
		`STSW:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd8;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
		`STSH:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd4;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
		`STSC:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd2;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
		`STSB:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd1;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
		`CAS:
			if (dram0_datacmp == dat_i) begin
				$display("CAS match");
				dram0_owns_bus <= `TRUE;
				cyc_o <= 1'b1;	// hold onto cyc_o
				dram0 <= dram0 + 3'd1;
			end
			else
				dram_v <= `VAL;
		endcase
	end

// State 4:
// Start a second bus transaction for the CAS instruction
3'd4:
	begin
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= fnSelect(dram0_op,pea);
		adr_o <= pea;
		dat_o <= fnDatao(dram0_op,dram0_data);
		dram0 <= dram0 + 3'd1;
	end

// State 5:
// Wait for a memory ack for the second bus transaction of a CAS
//
3'd5:
	if (ack_i|err_i) begin
		$display("MEM ack2");
		dram_v <= `VAL;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= err_i ? `EXC_DBE : `EXC_NONE;
		dram0_owns_bus <= `FALSE;
		wb_nack();
		lock_o <= 1'b0;
		dram0 <= 3'd0;
	end

// State 6:
// Wait for a data cache read hit
3'd6:
	if (rhit) begin
		$display("Read hit");
		dram_v <= `TRUE;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= `EXC_NONE;
		dram_bus <= fnDatai(dram0_op,cdat,sel_o);
		dram0 <= 3'd0;
	end
endcase

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
//
// Stores can only issue if there is no possibility of a change of program flow.
// That means no flow control operations or instructions that can cause an
// exception can be before the store.
iqentry_memissue[ head0 ] <=	iqentry_memready[ head0 ];		// first in line ... go as soon as ready

iqentry_memissue[ head1 ] <=	~iqentry_stomp[head1] && iqentry_memready[ head1 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head1][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head1]) ? !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) : TRUE)
				&& (iqentry_op[head1]!=`CAS)
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				;

iqentry_memissue[ head2 ] <=	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head2][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head2][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head2]) ?
				    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
				    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) 
				    : TRUE)
				&& (iqentry_op[head2]!=`CAS)
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMDB)
				;
//					(   !fnIsFlowCtrl(iqentry_op[head0])
//					 && !fnIsFlowCtrl(iqentry_op[head1])));

iqentry_memissue[ head3 ] <=	~iqentry_stomp[head3] && iqentry_memready[ head3 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head3][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head3][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head3][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head3]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) 
                    : TRUE)
				&& (iqentry_op[head3]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMDB)
				;
/*					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])));
*/
iqentry_memissue[ head4 ] <=	~iqentry_stomp[head4] && iqentry_memready[ head4 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				&& ~iqentry_memready[head3] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head4]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) 
                    : TRUE)
				&& (iqentry_op[head4]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMDB)
				;
/* ||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])));
*/
iqentry_memissue[ head5 ] <=	~iqentry_stomp[head5] && iqentry_memready[ head5 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				&& ~iqentry_memready[head3] 
				&& ~iqentry_memready[head4] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
					|| (iqentry_a1_v[head4] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head4][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head5]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4]) 
                    : TRUE)
				&& (iqentry_op[head5]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMDB)
				&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMDB)
				;
/*||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])));
*/
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
					|| (iqentry_a1_v[head0] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
					|| (iqentry_a1_v[head4] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head4][DBW-1:3]))
				&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
					|| (iqentry_a1_v[head5] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head5][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head6]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4]) && 
                    !fnIsFlowCtrl(iqentry_op[head5]) && !fnCanException(iqentry_op[head5]) 
                    : TRUE)
				&& (iqentry_op[head6]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMDB)
				&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMDB)
				&& !(iqentry_v[head5] && iqentry_op[head5]==`MEMDB)
				;
				/*||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])
					 && !fnIsFlowCtrl(iqentry_op[head5])));
*/
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
					|| (iqentry_a1_v[head0] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
					|| (iqentry_a1_v[head4] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head4][DBW-1:3]))
				&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
					|| (iqentry_a1_v[head5] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head5][DBW-1:3]))
				&& (!iqentry_mem[head6] || (iqentry_agen[head6] & iqentry_out[head6]) 
					|| (iqentry_a1_v[head6] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head6][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head7]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4]) && 
                    !fnIsFlowCtrl(iqentry_op[head5]) && !fnCanException(iqentry_op[head5]) && 
                    !fnIsFlowCtrl(iqentry_op[head6]) && !fnCanException(iqentry_op[head6]) 
                    : TRUE)
				&& (iqentry_op[head7]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMDB)
				&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMDB)
				&& !(iqentry_v[head5] && iqentry_op[head5]==`MEMDB)
				&& !(iqentry_v[head6] && iqentry_op[head6]==`MEMDB)
				;
				/* ||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])
					 && !fnIsFlowCtrl(iqentry_op[head5])
					 && !fnIsFlowCtrl(iqentry_op[head6])));
*/
//
// take requests that are ready and put them into DRAM slots

if (dram0 == `DRAMSLOT_AVAIL)	dram0_exc <= `EXC_NONE;

// Memory should also wait until segment registers are valid. The segment
// registers are essentially static registers while a program runs. They are
// setup by only the operating system. The system software must ensure the
// segment registers are stable before they get used. We don't bother checking
// for rf_v[].
//
for (n = 0; n < 8; n = n + 1)
	if (~iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && iqentry_op[n]==`TLB && ~iqentry_out[n] && iqentry_cmt[n]) begin
		if (tlb_state==3'd0) begin
			tlb_state <= 3'd1;
			tlb_id <= {1'b1, n[2:0]};
			tlb_op <= iqentry_a0[n][3:0];
			tlb_regno <= iqentry_a0[n][7:4];
			tlb_tgt <= iqentry_tgt[n];
			tlb_data <= iqentry_a2[n];
			iqentry_out[n] <= `TRUE;
		end
	end
	else if (~iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && ~iqentry_out[n] && iqentry_cmt[n] && ihit) begin
		if (fnIsStoreString(iqentry_op[n]))
			string_pc <= iqentry_pc[n];
		$display("issued memory cycle");
		if (dram0 == `DRAMSLOT_AVAIL) begin
			dram0 		<= 3'd1;
			dram0_id 	<= { 1'b1, n[2:0] };
			dram0_op 	<= iqentry_op[n];
			dram0_tgt 	<= iqentry_tgt[n];
			dram0_data	<= (fnIsIndexed(iqentry_op[n]) || iqentry_op[n]==`CAS) ? iqentry_a3[n] : iqentry_a2[n];
			dram0_datacmp <= iqentry_a2[n];
`ifdef SEGMENTATION
			dram0_addr	<= iqentry_a1[n][DBW-5:0] + {sregs[iqentry_a1[n][DBW-1:DBW-4]],12'h000};
`else
			dram0_addr	<= iqentry_a1[n];
`endif
			iqentry_out[n]	<= `TRUE;
		end
	end
