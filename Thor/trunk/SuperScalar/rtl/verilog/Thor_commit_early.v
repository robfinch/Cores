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
// Commit logic
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
		if (!rf_v[ commit0_tgt ]) begin 
			rf_v[ commit0_tgt ] = rf_source[ commit0_tgt ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
			$display("regv[%d]<=%d", commit0_tgt, rf_v[commit0_tgt]);
		end
		if (commit0_tgt != 9'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
end
if (commit1_v) begin
		if (!rf_v[ commit1_tgt ]) begin 
			rf_v[ commit1_tgt ] = rf_source[ commit1_tgt ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
			$display("regv[%d]<=%d", commit1_tgt, rf_v[commit1_tgt]);
	    end
		if (commit1_tgt != 9'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
end
