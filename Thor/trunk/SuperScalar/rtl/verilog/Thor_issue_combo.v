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
    assign  iqentry_imm[0] = fnHasConst(iqentry_op[0]),
	    iqentry_imm[1] = fnHasConst(iqentry_op[1]),
	    iqentry_imm[2] = fnHasConst(iqentry_op[2]),
	    iqentry_imm[3] = fnHasConst(iqentry_op[3]),
	    iqentry_imm[4] = fnHasConst(iqentry_op[4]),
	    iqentry_imm[5] = fnHasConst(iqentry_op[5]),
	    iqentry_imm[6] = fnHasConst(iqentry_op[6]),
	    iqentry_imm[7] = fnHasConst(iqentry_op[7]);

    //
    // additional logic for ISSUE
    //
    // for the moment, we look at ALU-input buffers to allow back-to-back issue of 
    // dependent instructions ... we do not, however, look ahead for DRAM requests 
    // that will become valid in the next cycle.  instead, these have to propagate
    // their results into the IQ entry directly, at which point it becomes issue-able
    //

    // note that, for all intents & purposes, iqentry_done == iqentry_agen ... no need to duplicate

	always @*
		for (n = 0; n < 8; n = n + 1)
		begin
			iqentry_issue[n] <= (iqentry_v[n] && !iqentry_out[n] && !iqentry_agen[n]
					&& (head0 == n[2:0] || ~|iqentry_islot[n[2:0]-1] || (iqentry_islot[n[2:0]-1] == 2'b01 && ~iqentry_issue[n[2:0]-1]))
					&& (iqentry_a1_v[n] 
						|| (iqentry_a1_s[n] == alu0_sourceid && alu0_dataready)
						|| (iqentry_a1_s[n] == alu1_sourceid && alu1_dataready))
					&& (iqentry_a2_v[n] 
						|| (iqentry_mem[n] & ~iqentry_agen[0])
						|| (iqentry_a2_s[n] == alu0_sourceid && alu0_dataready)
						|| (iqentry_a2_s[n] == alu1_sourceid && alu1_dataready)));
			iqentry_islot[n[2:0]] <= (head0 == n[2:0]) ? 2'b00
					: (iqentry_islot[n[2:0]-1] == 2'b11) ? 2'b11
					: (iqentry_islot[n[2:0]-1] + {1'b0, iqentry_issue[n[2:0]-1]});
		end

    // 
    // additional logic for handling a branch miss (STOMP logic)
    //
    assign
		iqentry_stomp[0] = branchmiss && iqentry_v[0] && head0 != 3'd0 && (missid == 3'd7 || iqentry_stomp[7]),
	    iqentry_stomp[1] = branchmiss && iqentry_v[1] && head0 != 3'd1 && (missid == 3'd0 || iqentry_stomp[0]),
	    iqentry_stomp[2] = branchmiss && iqentry_v[2] && head0 != 3'd2 && (missid == 3'd1 || iqentry_stomp[1]),
	    iqentry_stomp[3] = branchmiss && iqentry_v[3] && head0 != 3'd3 && (missid == 3'd2 || iqentry_stomp[2]),
	    iqentry_stomp[4] = branchmiss && iqentry_v[4] && head0 != 3'd4 && (missid == 3'd3 || iqentry_stomp[3]),
	    iqentry_stomp[5] = branchmiss && iqentry_v[5] && head0 != 3'd5 && (missid == 3'd4 || iqentry_stomp[4]),
	    iqentry_stomp[6] = branchmiss && iqentry_v[6] && head0 != 3'd6 && (missid == 3'd5 || iqentry_stomp[5]),
	    iqentry_stomp[7] = branchmiss && iqentry_v[7] && head0 != 3'd7 && (missid == 3'd6 || iqentry_stomp[6]);


