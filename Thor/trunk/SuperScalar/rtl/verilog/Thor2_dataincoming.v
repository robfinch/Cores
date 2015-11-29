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
// Data Incoming logic
//
// ============================================================================
//
//
// DATAINCOMING
//
// wait for operand/s to appear on alu busses and puts them into 
// the iqentry_a1 and iqentry_a2 slots (if appropriate)
// as well as the appropriate iqentry_res slots (and setting valid bits)
//
//
// put results into the appropriate instruction entries
//
if (alu0_v) begin
	$display("0results to iq[%d]=%h", alu0_id[2:0],alu0_bus);
	if (|alu0_exc) begin
		iqentry_op [alu0_id[2:0] ] <= `INT;
		iqentry_cond [alu0_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[alu0_id[2:0]] <= `FALSE;
		iqentry_rfw[alu0_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu0_id[2:0]] <= alu0_exc;
		iqentry_a1 [alu0_id[2:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [alu0_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [alu0_id[2:0]] <= `TRUE;
		iqentry_a3_v [alu0_id[2:0]] <= `TRUE;
		iqentry_out [alu0_id[2:0]] <= `FALSE;
		iqentry_agen [alu0_id[2:0]] <= `FALSE;
		iqentry_tgt[alu0_id[2:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		if ((alu0_op==`RR && (alu0_fn==`MUL || alu0_fn==`MULU)) || alu0_op==`MULI || alu0_op==`MULUI) begin
			if (alu0_mult_done) begin
				iqentry_res	[ alu0_id[2:0] ] <= alu0_prod[63:0];
				iqentry_done[alu0_id[2:0]] <= `TRUE;
				iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
			end
		end
		else if ((alu0_op==`RR && (alu0_fn==`DIV || alu0_fn==`DIVU)) || alu0_op==`DIVI || alu0_op==`DIVUI) begin
			if (alu0_div_done) begin
				iqentry_res	[ alu0_id[2:0] ] <= alu0_divq;
				iqentry_done[alu0_id[2:0]] <= `TRUE;
				iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
			end
		end
		else begin
			iqentry_res	[ alu0_id[2:0] ] <= alu0_bus;
			iqentry_done[ alu0_id[2:0] ] <= !fnIsMem(iqentry_op[ alu0_id[2:0] ]) || !alu0_cmt;
			iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
		end
		iqentry_cmt [ alu0_id[2:0] ] <= alu0_cmt;
		iqentry_agen[ alu0_id[2:0] ] <= `TRUE;
	end
end

if (alu1_v) begin
	$display("1results to iq[%d]=%h", alu1_id[2:0],alu1_bus);
	if (|alu1_exc) begin
		iqentry_op [alu1_id[2:0] ] <= `INT;
		iqentry_cond [alu1_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[alu1_id[2:0]] <= `FALSE;
		iqentry_rfw[alu1_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu1_id[2:0]] <= alu1_exc;
		iqentry_a1 [alu1_id[2:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [alu1_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [alu1_id[2:0]] <= `TRUE;
		iqentry_a3_v [alu1_id[2:0]] <= `TRUE;
		iqentry_out [alu1_id[2:0]] <= `FALSE;
		iqentry_agen [alu1_id[2:0]] <= `FALSE;
		iqentry_tgt[alu1_id[2:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		if ((alu1_op==`RR && (alu1_fn==`MUL || alu1_fn==`MULU)) || alu1_op==`MULI || alu1_op==`MULUI) begin
			if (alu1_mult_done) begin
				iqentry_res	[ alu1_id[2:0] ] <= alu1_prod[63:0];
				iqentry_done[alu1_id[2:0]] <= `TRUE;
				iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
			end
		end
		else if ((alu1_op==`RR && (alu1_fn==`DIV || alu1_fn==`DIVU)) || alu1_op==`DIVI || alu1_op==`DIVUI) begin
			if (alu1_div_done) begin
				iqentry_res	[ alu1_id[2:0] ] <= alu1_divq;
				iqentry_done[alu1_id[2:0]] <= `TRUE;
				iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
			end
		end
		else begin
			iqentry_res	[ alu1_id[2:0] ] <= alu1_bus;
			iqentry_done[ alu1_id[2:0] ] <= !fnIsMem(iqentry_op[ alu1_id[2:0] ]) || !alu1_cmt;
			iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
		end
		iqentry_cmt [ alu1_id[2:0] ] <= alu1_cmt;
		iqentry_agen[ alu1_id[2:0] ] <= `TRUE;
	end
end

`ifdef FLOATING_POINT
if (fp0_v) begin
	$display("0results to iq[%d]=%h", alu0_id[2:0],alu0_bus);
	if (|fp0_exc) begin
		iqentry_op [alu0_id[2:0] ] <= `INT;
		iqentry_cond [alu0_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[alu0_id[2:0]] <= `FALSE;
		iqentry_rfw[alu0_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu0_id[2:0]] <= fp0_exc;
		iqentry_a1 [alu0_id[2:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [alu0_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [alu0_id[2:0]] <= `TRUE;
		iqentry_a3_v [alu0_id[2:0]] <= `TRUE;
		iqentry_out [alu0_id[2:0]] <= `FALSE;
		iqentry_agen [alu0_id[2:0]] <= `FALSE;
		iqentry_tgt[alu0_id[2:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		iqentry_res	[ alu0_id[2:0] ] <= fp0_bus;
		iqentry_done[ alu0_id[2:0] ] <= fp0_done || !fp0_cmt;
		iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
		iqentry_cmt [ alu0_id[2:0] ] <= fp0_cmt;
		iqentry_agen[ alu0_id[2:0] ] <= `TRUE;
	end
end
`endif

if (dram_v && iqentry_v[ dram_id[2:0] ] && iqentry_mem[ dram_id[2:0] ] ) begin	// if data for stomped instruction, ignore
	$display("2results to iq[%d]=%h", dram_id[2:0],dram_bus);
	iqentry_res	[ dram_id[2:0] ] <= dram_bus;
	// If an exception occurred, stuff an interrupt instruction into the queue
	// slot. The instruction will re-issue as an ALU operation.
	if (|dram_exc) begin
		iqentry_op [dram_id[2:0] ] <= `INT;
		iqentry_cond [dram_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[dram_id[2:0]] <= `FALSE;		// It's no longer a memory op
		iqentry_rfw[dram_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [dram_id[2:0]] <= dram_exc==`EXC_DBE ? 8'hFB : 8'hF8;
		iqentry_a1 [dram_id[2:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [dram_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [dram_id[2:0]] <= `TRUE;
		iqentry_a3_v [dram_id[2:0]] <= `TRUE;
		iqentry_out [dram_id[2:0]] <= `FALSE;
		iqentry_agen [dram_id[2:0]] <= `FALSE;
		iqentry_tgt[dram_id[2:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		iqentry_done[ dram_id[2:0] ] <= `TRUE;
		if (iqentry_op[dram_id[2:0]]==`STSW && lc==64'd0) begin
			string_pc <= 64'd0;
		end
	end
end

// What if there's a databus error during the store ?
// set the IQ entry == DONE as soon as the SW is let loose to the memory system
//
/*if (dram0 == 2'd1 && fnIsStore(dram0_op)) begin
	if ((alu0_v && dram0_id[2:0] == alu0_id[2:0]) || (alu1_v && dram0_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram0_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram0_id[2:0]] <= `TRUE;
	iqentry_out[ dram0_id[2:0] ] <= `FALSE;
end
if (dram1 == 2'd1 && fnIsStore(dram1_op)) begin
	if ((alu0_v && dram1_id[2:0] == alu0_id[2:0]) || (alu1_v && dram1_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram1_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram1_id[2:0]] <= `TRUE;
	iqentry_out[ dram1_id[2:0] ] <= `FALSE;
end
if (dram2 == 2'd1 && fnIsStore(dram2_op)) begin
	if ((alu0_v && dram2_id[2:0] == alu0_id[2:0]) || (alu1_v && dram2_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram2_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram2_id[2:0]] <= `TRUE;
	iqentry_out[ dram2_id[2:0] ] <= `FALSE;
end
*/
//
// see if anybody else wants the results ... look at lots of buses:
//  - alu0_bus
//  - alu1_bus
//  - alu2_bus
//  - alu3_bus
//  - fp0_bus
//  - dram_bus
//  - commit0_bus
//  - commit1_bus
//  - commit2_bus
//  - commit3_bus
//

for (n = 0; n < 16; n = n + 1)
begin
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_pred[n] <= alu0_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a1[n] <= alu0_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a2[n] <= alu0_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a3[n] <= alu0_bus;
		iqentry_a3_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_pred[n] <= alu1_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a1[n] <= alu1_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a2[n] <= alu1_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a3[n] <= alu1_bus;
		iqentry_a3_v[n] <= `VAL;
	end

	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu2_id && iqentry_v[n] == `VAL && alu2_v == `VAL) begin
		iqentry_pred[n] <= alu2_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == alu2_id && iqentry_v[n] == `VAL && alu2_v == `VAL) begin
		iqentry_a1[n] <= alu2_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == alu2_id && iqentry_v[n] == `VAL && alu2_v == `VAL) begin
		iqentry_a2[n] <= alu2_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == alu2_id && iqentry_v[n] == `VAL && alu2_v == `VAL) begin
		iqentry_a3[n] <= alu2_bus;
		iqentry_a3_v[n] <= `VAL;
	end

	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu3_id && iqentry_v[n] == `VAL && alu3_v == `VAL) begin
		iqentry_pred[n] <= alu3_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == alu3_id && iqentry_v[n] == `VAL && alu3_v == `VAL) begin
		iqentry_a1[n] <= alu3_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == alu3_id && iqentry_v[n] == `VAL && alu3_v == `VAL) begin
		iqentry_a2[n] <= alu3_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == alu3_id && iqentry_v[n] == `VAL && alu3_v == `VAL) begin
		iqentry_a3[n] <= alu3_bus;
		iqentry_a3_v[n] <= `VAL;
	end
`ifdef FLOATING_POINT
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_pred[n] <= fp0_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a1[n] <= fp0_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a2[n] <= fp0_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a3[n] <= fp0_bus;
		iqentry_a3_v[n] <= `VAL;
	end
`endif
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_pred[n] <= dram_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_a1[n] <= dram_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_a2[n] <= dram_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_a3[n] <= dram_bus;
		iqentry_a3_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_pred[n] <= commit0_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a1[n] <= commit0_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a2[n] <= commit0_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a3[n] <= commit0_bus;
		iqentry_a3_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_pred[n] <= commit1_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a1[n] <= commit1_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a2[n] <= commit1_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a3[n] <= commit1_bus;
		iqentry_a3_v[n] <= `VAL;
	end

	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_pred[n] <= commit2_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_a1[n] <= commit2_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_a2[n] <= commit2_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_a3[n] <= commit2_bus;
		iqentry_a3_v[n] <= `VAL;
	end

	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit3_id && iqentry_v[n] == `VAL && commit3_v == `VAL) begin
		iqentry_pred[n] <= commit3_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == commit3_id && iqentry_v[n] == `VAL && commit3_v == `VAL) begin
		iqentry_a1[n] <= commit3_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == commit3_id && iqentry_v[n] == `VAL && commit3_v == `VAL) begin
		iqentry_a2[n] <= commit3_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == commit3_id && iqentry_v[n] == `VAL && commit3_v == `VAL) begin
		iqentry_a3[n] <= commit3_bus;
		iqentry_a3_v[n] <= `VAL;
	end
end
