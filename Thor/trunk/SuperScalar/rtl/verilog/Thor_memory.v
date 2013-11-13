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

casex ({dram0, dram1, dram2})
	// not particularly portable ...
	9'b01x01xxxx,
	9'b01xxxx01x,
	9'bxxx01x01x:
		if (!rst_i) begin
			$display("dramx=%b",{dram0, dram1, dram2});
			panic <= `PANIC_IDENTICALDRAMS;
		end

	default: begin
	//
	// grab requests that have finished and put them on the dram_bus
	if (dram0 == 3'd3 && (ack_i|err_i|DTLBMiss)) begin
		$display("0WISHBONE ack");
		dram_v <= fnIsMem(dram0_op);
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= err_i ? `EXC_DBE : DTLBMiss ? `EXC_TLBMISS : `EXC_NONE;//dram0_exc;
		dram_bus <= fnDatai(dram0_op,dat_i,sel_o);
		case(dram0_op)
		`STSW:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd8;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
			else
				dram0 <= 3'd0;
		`STSH:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd4;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
			else
				dram0 <= 3'd0;
		`STSC:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd2;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
			else
				dram0 <= 3'd0;
		`STSB:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + 64'd1;
				lc <= lc - 64'd1;
				dram0 <= 3'd1;
			end
			else
				dram0 <= 3'd0;
		default:
			dram0 <= 3'd0;
		endcase
		wb_nack();
	end
	else if (dram1 == 3'd3 && (ack_i|err_i|DTLBMiss)) begin
		$display("1WISHBONE ack");
		dram_v <= fnIsMem(dram1_op);
		dram_id <= dram1_id;
		dram_tgt <= dram1_tgt;
		dram_exc <= err_i ? `EXC_DBE : DTLBMiss ? `EXC_TLBMISS : `EXC_NONE;//dram0_exc;
		dram_bus <= fnDatai(dram1_op,dat_i,sel_o);
		case(dram1_op)
		`STSW:
			if (lc != 0 && !int_pending) begin
				dram1_addr <= dram1_addr + 64'd8;
				lc <= lc - 64'd1;
				dram1 <= 3'd1;
			end
			else
				dram1 <= 3'd0;
		`STSH:
			if (lc != 0 && !int_pending) begin
				dram1_addr <= dram1_addr + 64'd4;
				lc <= lc - 64'd1;
				dram1 <= 3'd1;
			end
			else
				dram1 <= 3'd0;
		`STSC:
			if (lc != 0 && !int_pending) begin
				dram1_addr <= dram1_addr + 64'd2;
				lc <= lc - 64'd1;
				dram1 <= 3'd1;
			end
			else
				dram1 <= 3'd0;
		`STSB:
			if (lc != 0 && !int_pending) begin
				dram1_addr <= dram1_addr + 64'd1;
				lc <= lc - 64'd1;
				dram1 <= 3'd1;
			end
			else
				dram1 <= 3'd0;
		default:
			dram1 <= 3'd0;
		endcase
		wb_nack();
	end
	else if (dram2 == 3'd3 && (ack_i|err_i|DTLBMiss)) begin
		$display("2WISHBONE ack");
		dram_v <= fnIsMem(dram2_op);
		dram_id <= dram2_id;
		dram_tgt <= dram2_tgt;
		dram_exc <= err_i ? `EXC_DBE : DTLBMiss ? `EXC_TLBMISS : `EXC_NONE;//dram0_exc;
		dram_bus <= fnDatai(dram2_op,dat_i,sel_o);
		case(dram2_op)
		`STSW:
			if (lc != 0 && !int_pending) begin
				dram2_addr <= dram2_addr + 64'd8;
				lc <= lc - 64'd1;
				dram2 <= 3'd1;
			end
			else
				dram2 <= 3'd0;
		`STSH:
			if (lc != 0 && !int_pending) begin
				dram2_addr <= dram2_addr + 64'd4;
				lc <= lc - 64'd1;
				dram2 <= 3'd1;
			end
			else
				dram2 <= 3'd0;
		`STSC:
			if (lc != 0 && !int_pending) begin
				dram2_addr <= dram2_addr + 64'd2;
				lc <= lc - 64'd1;
				dram2 <= 3'd1;
			end
			else
				dram2 <= 3'd0;
		`STSB:
			if (lc != 0 && !int_pending) begin
				dram2_addr <= dram2_addr + 64'd1;
				lc <= lc - 64'd1;
				dram2 <= 3'd1;
			end
			else
				dram2 <= 3'd0;
		default:
			dram2 <= 3'd0;
		endcase
		wb_nack();
	end
	else if (tlb_state==3'd3) begin
		$display("tlb state 2");
		dram_v <= `TRUE;
		dram_id <= tlb_id;
		dram_tgt <= tlb_tgt;
		dram_exc <= `EXC_NONE;
		dram_bus <= tlb_dato;
		tlb_op <= 4'h0;
		tlb_state <= 3'd0;
	end
	else begin
		dram_v <= `INV;
	end
	end
endcase
if (dram0==3'd1 && !cyc_o) begin
	$display("0WISHBONE %c:%h %h cycle started",fnIsLoad(dram0_op)?"L" : "S", dram0_addr, dram0_data);
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	pwe <= fnIsStore(dram0_op);
	sel_o <= fnSelect(dram0_op,dram0_addr);
	vadr <= dram0_addr;
	dat_o <= fnDatao(dram0_op,dram0_data);
	dram0 <= 3'd2;
end
else if (dram1==3'd1 && !cyc_o) begin
	$display("1WISHBONE %c:%h %h cycle started",fnIsLoad(dram1_op)?"L" : "S", dram1_addr, dram1_data);
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	pwe <= fnIsStore(dram1_op);
	sel_o <= fnSelect(dram1_op,dram1_addr);
	vadr <= dram1_addr;
	dat_o <= fnDatao(dram1_op,dram1_data);
	dram1 <= 3'd2;
end
else if (dram2==3'd1 && !cyc_o) begin
	$display("2WISHBONE %c:%h %h cycle started",fnIsLoad(dram2_op)?"L" : "S", dram2_addr, dram2_data);
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	pwe <= fnIsStore(dram2_op);
	sel_o <= fnSelect(dram2_op,dram2_addr);
	vadr <= dram2_addr;
	dat_o <= fnDatao(dram2_op,dram2_data);
	dram2 <= 3'd2;
end
if (dram0==3'd2) begin
	if (!DTLBMiss) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= fnIsStore(dram0_op);
		sel_o <= fnSelect(dram0_op,pea);
		adr_o <= pea;
		dat_o <= fnDatao(dram0_op,dram0_data);
	end
	else if (miss_addr=={DBW{1'b0}})
		miss_addr <= pea;
	dram0 <= 3'd3;
end
if (dram1==3'd2) begin
	if (!DTLBMiss) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= fnIsStore(dram1_op);
		sel_o <= fnSelect(dram1_op,pea);
		adr_o <= pea;
		dat_o <= fnDatao(dram1_op,dram1_data);
	end
	else if (miss_addr=={DBW{1'b0}})
		miss_addr <= pea;
	dram1 <= 3'd3;
end
if (dram2==3'd2) begin
	if (!DTLBMiss) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= fnIsStore(dram2_op);
		sel_o <= fnSelect(dram2_op,pea);
		adr_o <= pea;
		dat_o <= fnDatao(dram2_op,dram2_data);
	end
	else if (miss_addr=={DBW{1'b0}})
		miss_addr <= pea;
	dram2 <= 3'd3;
end

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
//
// Stores can only issue if they are at the head of the queue, guarenteeing that they
// will not need to be undone due to a prior exception. Checking for a flow-control
// op isn't good enough once exceptions are present in the processor. The exception
// could become active at an unknown time in a previous queue slot. Eg. divide by
// zero, arithmetic overflow, etc.
iqentry_memissue[ head0 ] <=	iqentry_memready[ head0 ];		// first in line ... go as soon as ready

iqentry_memissue[ head1 ] <=	~iqentry_stomp[head1] && iqentry_memready[ head1 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head1] != iqentry_a1[head0]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (!fnIsStore(iqentry_op[head1]));// || !fnIsFlowCtrl(iqentry_op[head0]));

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
				&& (!fnIsStore(iqentry_op[head2]));// ||
//					(   !fnIsFlowCtrl(iqentry_op[head0])
//					 && !fnIsFlowCtrl(iqentry_op[head1])));

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
				&& (!fnIsStore(iqentry_op[head3]));/* ||
					(   !fnIsFlowCtrl(iqentry_op[head0])
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
					|| (iqentry_a1_v[head0] && iqentry_a1[head4] != iqentry_a1[head0]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head4] != iqentry_a1[head1]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head4] != iqentry_a1[head2]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head4] != iqentry_a1[head3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (!fnIsStore(iqentry_op[head4]));/* ||
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
				&& (!fnIsStore(iqentry_op[head5]));/*||
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
				&& (!fnIsStore(iqentry_op[head6]));/*||
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
				&& (!fnIsStore(iqentry_op[head7]));/* ||
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
if (dram1 == `DRAMSLOT_AVAIL)	dram1_exc <= `EXC_NONE;
if (dram2 == `DRAMSLOT_AVAIL)	dram2_exc <= `EXC_NONE;

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
	else if (~iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && ~iqentry_out[n] && iqentry_cmt[n]) begin
		if (fnIsStoreString(iqentry_op[n]))
			string_pc <= iqentry_pc[n];
		$display("issued memory cycle");
		if (dram0 == `DRAMSLOT_AVAIL) begin
			dram0 		<= 3'd1;
			dram0_id 	<= { 1'b1, n[2:0] };
			dram0_op 	<= iqentry_op[n];
			dram0_tgt 	<= iqentry_tgt[n];
			dram0_data	<= fnIsIndexed(iqentry_op[n]) ? iqentry_a3[n] : iqentry_a2[n];
`ifdef SEGMENTATION
			dram0_addr	<= iqentry_a1[n] + {sregs[iqentry_a1[n][DBW-1:DBW-4]],12'h000};
`else
			dram0_addr	<= iqentry_a1[n];
`endif
			iqentry_out[n]	<= `TRUE;
		end
		else if (dram1 == `DRAMSLOT_AVAIL) begin
			dram1 		<= 3'd1;
			dram1_id 	<= { 1'b1, n[2:0] };
			dram1_op 	<= iqentry_op[n];
			dram1_tgt 	<= iqentry_tgt[n];
			dram1_data	<= fnIsIndexed(iqentry_op[n]) ? iqentry_a3[n] : iqentry_a2[n];
`ifdef SEGMENTATION
			dram1_addr	<= iqentry_a1[n] + {sregs[iqentry_a1[n][DBW-1:DBW-4]],12'h000};
`else
			dram1_addr	<= iqentry_a1[n];
`endif
			iqentry_out[n]	<= `TRUE;
		end
		else if (dram2 == `DRAMSLOT_AVAIL) begin
			dram2 		<= 3'd1;
			dram2_id 	<= { 1'b1, n[2:0] };
			dram2_op 	<= iqentry_op[n];
			dram2_tgt 	<= iqentry_tgt[n];
			dram2_data	<= fnIsIndexed(iqentry_op[n]) ? iqentry_a3[n] : iqentry_a2[n];
`ifdef SEGMENTATION
			dram2_addr	<= iqentry_a1[n] + {sregs[iqentry_a1[n][DBW-1:DBW-4]],12'h000};
`else
			dram2_addr	<= iqentry_a1[n];
`endif
			iqentry_out[n]	<= `TRUE;
		end
	end
