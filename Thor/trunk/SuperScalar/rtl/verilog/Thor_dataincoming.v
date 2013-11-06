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
	    iqentry_res	[ alu0_id[2:0] ] <= alu0_bus;
	    iqentry_exc	[ alu0_id[2:0] ] <= alu0_exc;
	    iqentry_done[ alu0_id[2:0] ] <= !fnIsMem(iqentry_op[ alu0_id[2:0] ]) || !alu0_cmt;
		iqentry_cmt [ alu0_id[2:0] ] <= alu0_cmt;
	    iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
	    iqentry_agen[ alu0_id[2:0] ] <= `TRUE;
	end
	if (alu1_v) begin
	    iqentry_res	[ alu1_id[2:0] ] <= alu1_bus;
	    iqentry_exc	[ alu1_id[2:0] ] <= alu1_exc;
	    iqentry_done[ alu1_id[2:0] ] <= !fnIsMem(iqentry_op[ alu1_id[2:0] ]) || !alu1_cmt;
		iqentry_cmt [ alu1_id[2:0] ] <= alu1_cmt;
	    iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
	    iqentry_agen[ alu1_id[2:0] ] <= `TRUE;
	end
	if (dram_v && iqentry_v[ dram_id[2:0] ] && iqentry_mem[ dram_id[2:0] ] ) begin	// if data for stomped instruction, ignore
	    iqentry_res	[ dram_id[2:0] ] <= dram_bus;
	    iqentry_exc	[ dram_id[2:0] ] <= dram_exc;
	    iqentry_done[ dram_id[2:0] ] <= `TRUE;
		iqentry_cmt [ dram_id[2:0] ] <= `TRUE;
	end

	//
	// set the IQ entry == DONE as soon as the SW is let loose to the memory system
	//
	if (dram0 == 2'd1 && fnIsStore(dram0_op)) begin
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

	//
	// see if anybody else wants the results ... look at lots of buses:
	//  - alu0_bus
	//  - alu1_bus
	//  - dram_bus
	//  - commit0_bus
	//  - commit1_bus
	//

	for (n = 0; n < 8; n = n + 1)
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
	end
