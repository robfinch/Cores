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
// Commit combinational logic
//
// ============================================================================
//
// The processor does not support writing more than one register in the same register
// group at the same time for anything other than the general purpose
// registers. It is possible for the processor to write to different groups
// at the same time.
//assign limit_cmt = (iqentry_rfw[head0] && iqentry_rfw[head1] && iqentry_tgt[head0][8]==1'b1 && iqentry_tgt[head1][8]==1'b1);
assign limit_cmt = 1'b0;
//assign committing2 = (iqentry_v[head0] && iqentry_v[head1] && !limit_cmt) || (head0 != tail0 && head1 != tail0);

assign commit0_v = ({iqentry_v[head0], iqentry_done[head0]} == 2'b11 && ~|panic && iqentry_cmt[head0]);
assign commit1_v = ({iqentry_v[head0], iqentry_done[head0]} != 2'b10 
		&& {iqentry_v[head1], iqentry_done[head1]} == 2'b11 && ~|panic && iqentry_cmt[head1] && !limit_cmt);
assign commit2_v = ({iqentry_v[head0], iqentry_done[head0]} != 2'b10 &&
					{iqentry_v[head1], iqentry_done[head1]} != 2'b10 &&
		&& {iqentry_v[head2], iqentry_done[head2]} == 2'b11 && ~|panic && iqentry_cmt[head2] && !limit_cmt);

assign commit0_id = {iqentry_mem[head0], head0};	// if a memory op, it has a DRAM-bus id
assign commit1_id = {iqentry_mem[head1], head1};	// if a memory op, it has a DRAM-bus id
assign commit2_id = {iqentry_mem[head2], head2};	// if a memory op, it has a DRAM-bus id

assign commit0_tgt = iqentry_tgt[head0];
assign commit1_tgt = iqentry_tgt[head1];
assign commit2_tgt = iqentry_tgt[head2];

assign commit0_bus = iqentry_res[head0];
assign commit1_bus = iqentry_res[head1];
assign commit2_bus = iqentry_res[head2];

assign int_commit = (iqentry_op[head0]==`BRK && commit0_v) ||
					(commit0_v && iqentry_op[head1]==`BRK && commit1_v) ||
					(commit0_v && commit1_v && iqentry_op[head2]==`BRK && commit2_v)
					;
//assign sys_commit = (iqentry_op[head0]==`SYS && commit0_v) || (commit0_v && iqentry_op[head1]==`SYS && commit1_v);

