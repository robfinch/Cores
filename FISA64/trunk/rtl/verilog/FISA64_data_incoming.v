// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2015  Robert Finch, Stratford
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
// SuperScalar
// Data Incoming logic
//
// ============================================================================
//
//
// DATAINCOMING
//
// wait for operand/s to appear on alu busses and puts them into 
// the iqentry_a and iqentry_b slots (if appropriate)
// as well as the appropriate iqentry_res slots (and setting valid bits)
//
//
// put results into the appropriate instruction entries
//
if (alu0_v) begin
	$display("0results to iq[%d]=%h", alu0_id[3:0],alu0_bus);
	if (|alu0_exc) begin
		iqentry_op [alu0_id[3:0] ] <= `INT;
		iqentry_cond [alu0_id[3:0]] <= 4'd1;		// always execute
		iqentry_mem[alu0_id[3:0]] <= `FALSE;
		iqentry_rfw[alu0_id[3:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu0_id[3:0]] <= alu0_exc;
		iqentry_a [alu0_id[3:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_av [alu0_id[3:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_bv [alu0_id[3:0]] <= `TRUE;
		iqentry_cv [alu0_id[3:0]] <= `TRUE;
		iqentry_out [alu0_id[3:0]] <= `FALSE;
		iqentry_agen [alu0_id[3:0]] <= `FALSE;
		iqentry_tgt[alu0_id[3:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		if ((alu0_op==`RR && (alu0_fn==`MUL || alu0_fn==`MULU)) || alu0_op==`MULI || alu0_op==`MULUI) begin
			if (alu0_mult_done) begin
				iqentry_res	[ alu0_id[3:0] ] <= alu0_prod[63:0];
				iqentry_done[alu0_id[3:0]] <= `TRUE;
				iqentry_out	[ alu0_id[3:0] ] <= `FALSE;
			end
		end
		else if ((alu0_op==`RR && (alu0_fn==`DIV || alu0_fn==`DIVU)) || alu0_op==`DIVI || alu0_op==`DIVUI) begin
			if (alu0_div_done) begin
				iqentry_res	[ alu0_id[3:0] ] <= alu0_divq;
				iqentry_done[alu0_id[3:0]] <= `TRUE;
				iqentry_out	[ alu0_id[3:0] ] <= `FALSE;
			end
		end
		else begin
			iqentry_res	[ alu0_id[3:0] ] <= alu0_bus;
			iqentry_done[ alu0_id[3:0] ] <= !fnIsMem(iqentry_op[ alu0_id[3:0] ]) || !alu0_cmt;
			iqentry_out	[ alu0_id[3:0] ] <= `FALSE;
		end
		iqentry_cmt [ alu0_id[3:0] ] <= alu0_cmt;
		iqentry_agen[ alu0_id[3:0] ] <= `TRUE;
	end
end

if (alu1_v) begin
	$display("1results to iq[%d]=%h", alu1_id[3:0],alu1_bus);
	if (|alu1_exc) begin
		iqentry_op [alu1_id[3:0] ] <= `INT;
		iqentry_cond [alu1_id[3:0]] <= 4'd1;		// always execute
		iqentry_mem[alu1_id[3:0]] <= `FALSE;
		iqentry_rfw[alu1_id[3:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu1_id[3:0]] <= alu1_exc;
		iqentry_a [alu1_id[3:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_av [alu1_id[3:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_bv [alu1_id[3:0]] <= `TRUE;
		iqentry_cv [alu1_id[3:0]] <= `TRUE;
		iqentry_out [alu1_id[3:0]] <= `FALSE;
		iqentry_agen [alu1_id[3:0]] <= `FALSE;
		iqentry_tgt[alu1_id[3:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		if ((alu1_op==`RR && (alu1_fn==`MUL || alu1_fn==`MULU)) || alu1_op==`MULI || alu1_op==`MULUI) begin
			if (alu1_mult_done) begin
				iqentry_res	[ alu1_id[3:0] ] <= alu1_prod[63:0];
				iqentry_done[alu1_id[3:0]] <= `TRUE;
				iqentry_out	[ alu1_id[3:0] ] <= `FALSE;
			end
		end
		else if ((alu1_op==`RR && (alu1_fn==`DIV || alu1_fn==`DIVU)) || alu1_op==`DIVI || alu1_op==`DIVUI) begin
			if (alu1_div_done) begin
				iqentry_res	[ alu1_id[3:0] ] <= alu1_divq;
				iqentry_done[alu1_id[3:0]] <= `TRUE;
				iqentry_out	[ alu1_id[3:0] ] <= `FALSE;
			end
		end
		else begin
			iqentry_res	[ alu1_id[3:0] ] <= alu1_bus;
			iqentry_done[ alu1_id[3:0] ] <= !fnIsMem(iqentry_op[ alu1_id[3:0] ]) || !alu1_cmt;
			iqentry_out	[ alu1_id[3:0] ] <= `FALSE;
		end
		iqentry_cmt [ alu1_id[3:0] ] <= alu1_cmt;
		iqentry_agen[ alu1_id[3:0] ] <= `TRUE;
	end
end

`ifdef FLOATING_POINT
if (fp0_v) begin
	$display("0results to iq[%d]=%h", alu0_id[3:0],alu0_bus);
	if (|fp0_exc) begin
		iqentry_op [alu0_id[3:0] ] <= `INT;
		iqentry_cond [alu0_id[3:0]] <= 4'd1;		// always execute
		iqentry_mem[alu0_id[3:0]] <= `FALSE;
		iqentry_rfw[alu0_id[3:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu0_id[3:0]] <= fp0_exc;
		iqentry_a [alu0_id[3:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_av [alu0_id[3:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_bv [alu0_id[3:0]] <= `TRUE;
		iqentry_cv [alu0_id[3:0]] <= `TRUE;
		iqentry_out [alu0_id[3:0]] <= `FALSE;
		iqentry_agen [alu0_id[3:0]] <= `FALSE;
		iqentry_tgt[alu0_id[3:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		iqentry_res	[ alu0_id[3:0] ] <= fp0_bus;
		iqentry_done[ alu0_id[3:0] ] <= fp0_done || !fp0_cmt;
		iqentry_out	[ alu0_id[3:0] ] <= `FALSE;
		iqentry_cmt [ alu0_id[3:0] ] <= fp0_cmt;
		iqentry_agen[ alu0_id[3:0] ] <= `TRUE;
	end
end
`endif

if (dram_v && iqentry_v[ dram_id[3:0] ] && iqentry_mem[ dram_id[3:0] ] ) begin	// if data for stomped instruction, ignore
	$display("2results to iq[%d]=%h", dram_id[3:0],dram_bus);
	iqentry_res	[ dram_id[3:0] ] <= dram_bus;
	// If an exception occurred, stuff an interrupt instruction into the queue
	// slot. The instruction will re-issue as an ALU operation.
	if (|dram_exc) begin
		iqentry_op [dram_id[3:0] ] <= `INT;
		iqentry_cond [dram_id[3:0]] <= 4'd1;		// always execute
		iqentry_mem[dram_id[3:0]] <= `FALSE;		// It's no longer a memory op
		iqentry_rfw[dram_id[3:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [dram_id[3:0]] <= dram_exc==`EXC_DBE ? 8'hFB : 8'hF8;
		iqentry_a [dram_id[3:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_av [dram_id[3:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_bv [dram_id[3:0]] <= `TRUE;
		iqentry_cv [dram_id[3:0]] <= `TRUE;
		iqentry_out [dram_id[3:0]] <= `FALSE;
		iqentry_agen [dram_id[3:0]] <= `FALSE;
		iqentry_tgt[dram_id[3:0]] <= {1'b1,4'h1,4'hE};	// Target IPC
	end
	else begin
		iqentry_done[ dram_id[3:0] ] <= `TRUE;
		if (iqentry_op[dram_id[3:0]]==`STSW && lc==64'd0) begin
			string_pc <= 64'd0;
		end
	end
end

// What if there's a databus error during the store ?
// set the IQ entry == DONE as soon as the SW is let loose to the memory system
//
/*if (dram0 == 2'd1 && fnIsStore(dram0_op)) begin
	if ((alu0_v && dram0_id[3:0] == alu0_id[3:0]) || (alu1_v && dram0_id[3:0] == alu1_id[3:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram0_id[3:0] ] <= `TRUE;
	iqentry_cmt [ dram0_id[3:0]] <= `TRUE;
	iqentry_out[ dram0_id[3:0] ] <= `FALSE;
end
if (dram1 == 2'd1 && fnIsStore(dram1_op)) begin
	if ((alu0_v && dram1_id[3:0] == alu0_id[3:0]) || (alu1_v && dram1_id[3:0] == alu1_id[3:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram1_id[3:0] ] <= `TRUE;
	iqentry_cmt [ dram1_id[3:0]] <= `TRUE;
	iqentry_out[ dram1_id[3:0] ] <= `FALSE;
end
if (dram2 == 2'd1 && fnIsStore(dram2_op)) begin
	if ((alu0_v && dram2_id[3:0] == alu0_id[3:0]) || (alu1_v && dram2_id[3:0] == alu1_id[3:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram2_id[3:0] ] <= `TRUE;
	iqentry_cmt [ dram2_id[3:0]] <= `TRUE;
	iqentry_out[ dram2_id[3:0] ] <= `FALSE;
end
*/
//
// see if anybody else wants the results ... look at lots of buses:
//  - alu0_bus
//  - alu1_bus
//  - fp0_bus
//  - dram0_bus
//  - dram1_bus
//  - commit0_bus
//  - commit1_bus
//  - commit2_bus
//

for (n = 0; n < 16; n = n + 1)
begin
	if (iqentry_av[n] == `INV && iqentry_as[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a[n] <= alu0_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_b[n] <= alu0_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_c[n] <= alu0_bus;
		iqentry_cv[n] <= `VAL;
	end
	if (iqentry_av[n] == `INV && iqentry_as[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a[n] <= alu1_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_b[n] <= alu1_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_c[n] <= alu1_bus;
		iqentry_cv[n] <= `VAL;
	end
`ifdef FLOATING_POINT
	if (iqentry_av[n] == `INV && iqentry_as[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a[n] <= fp0_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_b[n] <= fp0_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_c[n] <= fp0_bus;
		iqentry_cv[n] <= `VAL;
	end
`endif
	if (iqentry_av[n] == `INV && iqentry_as[n] == dram0_id && iqentry_v[n] == `VAL && dram0_v == `VAL) begin
		iqentry_a[n] <= dram0_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == dram0_id && iqentry_v[n] == `VAL && dram0_v == `VAL) begin
		iqentry_b[n] <= dram0_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == dram0_id && iqentry_v[n] == `VAL && dram0_v == `VAL) begin
		iqentry_c[n] <= dram0_bus;
		iqentry_cv[n] <= `VAL;
	end
	if (iqentry_av[n] == `INV && iqentry_as[n] == dram1_id && iqentry_v[n] == `VAL && dram1_v == `VAL) begin
		iqentry_a[n] <= dram1_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == dram1_id && iqentry_v[n] == `VAL && dram1_v == `VAL) begin
		iqentry_b[n] <= dram1_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == dram1_id && iqentry_v[n] == `VAL && dram1_v == `VAL) begin
		iqentry_c[n] <= dram1_bus;
		iqentry_cv[n] <= `VAL;
	end
	if (iqentry_av[n] == `INV && iqentry_as[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a[n] <= commit0_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_b[n] <= commit0_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_c[n] <= commit0_bus;
		iqentry_cv[n] <= `VAL;
	end
	if (iqentry_av[n] == `INV && iqentry_as[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a[n] <= commit1_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_b[n] <= commit1_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_c[n] <= commit1_bus;
		iqentry_cv[n] <= `VAL;
	end
	if (iqentry_av[n] == `INV && iqentry_as[n] == commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_a[n] <= commit2_bus;
		iqentry_av[n] <= `VAL;
	end
	if (iqentry_bv[n] == `INV && iqentry_bs[n] == commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_b[n] <= commit2_bus;
		iqentry_bv[n] <= `VAL;
	end
	if (iqentry_cv[n] == `INV && iqentry_cs[n] == commit2_id && iqentry_v[n] == `VAL && commit2_v == `VAL) begin
		iqentry_c[n] <= commit2_bus;
		iqentry_cv[n] <= `VAL;
	end
end
