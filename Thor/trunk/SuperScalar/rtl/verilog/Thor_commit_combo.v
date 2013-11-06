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
// Commit combinational logic
//
// ============================================================================
//
    //
    // additional COMMIT logic
    //

    assign commit0_v = ({iqentry_v[head0], iqentry_done[head0]} == 2'b11 && ~|panic && iqentry_cmt[head0]);
    assign commit1_v = ({iqentry_v[head0], iqentry_done[head0]} != 2'b10 
			&& {iqentry_v[head1], iqentry_done[head1]} == 2'b11 && ~|panic && iqentry_cmt[head1]);

    assign commit0_id = {iqentry_mem[head0], head0};	// if a memory op, it has a DRAM-bus id
    assign commit1_id = {iqentry_mem[head1], head1};	// if a memory op, it has a DRAM-bus id

    assign commit0_tgt = iqentry_tgt[head0];
    assign commit1_tgt = iqentry_tgt[head1];

    assign commit0_bus = iqentry_res[head0];
    assign commit1_bus = iqentry_res[head1];

