// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
// ============================================================================
//
`include "nvio-config.sv"

module memissueLogic (heads, iq_v, iq_memready, iq_out, iq_done, iq_mem, iq_agen, 
	iq_load, iq_store, iq_fc, iq_aq, iq_rl, iq_ma, iq_memsb, iq_memdb, iq_stomp, iq_canex, 
	wb_v, inwb0, inwb1, sple,
	memissue, issue_count);
parameter QENTRIES = `QENTRIES;
parameter AMSB = 79;
input [`QBITS] heads [0:QENTRIES-1];
input [QENTRIES-1:0] iq_v;
input [QENTRIES-1:0] iq_memready;
input [QENTRIES-1:0] iq_out;
input [QENTRIES-1:0] iq_done;
input [QENTRIES-1:0] iq_mem;
input [QENTRIES-1:0] iq_agen;
input [QENTRIES-1:0] iq_load;
input [QENTRIES-1:0] iq_store;
input [QENTRIES-1:0] iq_fc;
input [QENTRIES-1:0] iq_aq;
input [QENTRIES-1:0] iq_rl;
input [QENTRIES-1:0] iq_memsb;
input [QENTRIES-1:0] iq_memdb;
input [QENTRIES-1:0] iq_stomp;
input [QENTRIES-1:0] iq_canex;
input [7:0] wb_v;
input inwb0;
input inwb1;
input sple;
input [AMSB:0] iq_ma [0:QENTRIES-1];
output reg [QENTRIES-1:0] memissue = 1'd0;
output reg [1:0] issue_count;

generate begin : gMemIssue
always @*
begin
	issue_count = 0;
	 memissue[ heads[0] ] =	iq_memready[ heads[0] ] && !(iq_load[heads[0]] && inwb0);		// first in line ... go as soon as ready
	 if (memissue[heads[0]])
	 	issue_count = issue_count + 1;

	 memissue[ heads[1] ] =	~iq_stomp[heads[1]] && iq_memready[ heads[1] ]		// addr and data are valid
					&& issue_count < `NUM_MEM
					// ... and no preceding instruction is ready to go
					//&& ~iq_memready[heads[0]]
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[1]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[1]] ? iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]] : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[1]] && (inwb1 || iq_store[heads[0]]))
					// ... and, if it is a store, there is no chance of it being undone
					&& ((iq_load[heads[1]] && sple) ||
					   !(iq_fc[heads[0]]||iq_canex[heads[0]]));
	 if (memissue[heads[1]])
	 	issue_count = issue_count + 1;

	 memissue[ heads[2] ] =	~iq_stomp[heads[2]] && iq_memready[ heads[2] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]])  || iq_done[heads[0]]
						|| ((iq_ma[heads[2]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]])  || iq_done[heads[1]]
						|| ((iq_ma[heads[2]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[2]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[2]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
            && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[2]] && sple) ||
					      !(iq_fc[heads[0]]||iq_canex[heads[0]])
					   && !(iq_fc[heads[1]]||iq_canex[heads[1]]));
	 if (memissue[heads[2]])
	 	issue_count = issue_count + 1;
					        
	 memissue[ heads[3] ] =	~iq_stomp[heads[3]] && iq_memready[ heads[3] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]])  || iq_done[heads[0]]
						|| ((iq_ma[heads[3]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]])  || iq_done[heads[1]]
						|| ((iq_ma[heads[3]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]])  || iq_done[heads[2]]
						|| ((iq_ma[heads[3]][AMSB:5] != iq_ma[heads[2]][AMSB:5] || iq_out[heads[2]] || iq_done[heads[2]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[3]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[3]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    // ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[3]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]]));
	 if (memissue[heads[3]])
	 	issue_count = issue_count + 1;

	if (QENTRIES > 4) begin
	 memissue[ heads[4] ] =	~iq_stomp[heads[4]] && iq_memready[ heads[4] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]])  || iq_done[heads[0]]
						|| ((iq_ma[heads[4]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]])  || iq_done[heads[1]]
						|| ((iq_ma[heads[4]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]])  || iq_done[heads[2]]
						|| ((iq_ma[heads[4]][AMSB:5] != iq_ma[heads[2]][AMSB:5] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]])  || iq_done[heads[3]]
						|| ((iq_ma[heads[4]][AMSB:5] != iq_ma[heads[3]][AMSB:5] || iq_out[heads[3]] || iq_done[heads[3]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[4]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[4]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
    				&& (!(iq_v[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[4]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]]));
	 if (memissue[heads[4]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 5) begin
	 memissue[ heads[5] ] =	~iq_stomp[heads[5]] && iq_memready[ heads[5] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]] 
						|| ((iq_ma[heads[5]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]] 
						|| ((iq_ma[heads[5]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[5]][AMSB:5] != iq_ma[heads[2]][AMSB:5] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[5]][AMSB:5] != iq_ma[heads[3]][AMSB:5] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[5]][AMSB:5] != iq_ma[heads[4]][AMSB:5] || iq_out[heads[4]] || iq_done[heads[4]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[5]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[5]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[5]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]]));
	 if (memissue[heads[5]])
	 	issue_count = issue_count + 1;
	end

`ifdef FULL_ISSUE_LOGIC
if (QENTRIES > 6) begin
 memissue[ heads[6] ] =	~iq_stomp[heads[6]] && iq_memready[ heads[6] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]] 
						|| ((iq_ma[heads[6]][AMSB:5] != iq_ma[heads[0]][AMSB:5])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]] 
						|| ((iq_ma[heads[6]][AMSB:5] != iq_ma[heads[1]][AMSB:5])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[6]][AMSB:5] != iq_ma[heads[2]][AMSB:5])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[6]][AMSB:5] != iq_ma[heads[3]][AMSB:5])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[6]][AMSB:5] != iq_ma[heads[4]][AMSB:5])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[6]][AMSB:5] != iq_ma[heads[5]][AMSB:5])))
					&& (iq_rl[heads[6]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[6]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[6]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]]));
	 if (memissue[heads[6]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 7) begin
	memissue[ heads[7] ] =	~iq_stomp[heads[7]] && iq_memready[ heads[7] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					//&& ~iq_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]]
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[2]][AMSB:5] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[3]][AMSB:5] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[4]][AMSB:5] || iq_out[heads[4]] || iq_done[heads[4]])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[5]][AMSB:5] || iq_out[heads[5]] || iq_done[heads[5]])))
					&& (!iq_mem[heads[6]] || (iq_agen[heads[6]] & iq_out[heads[6]]) || iq_done[heads[6]] 
						|| ((iq_ma[heads[7]][AMSB:5] != iq_ma[heads[6]][AMSB:5] || iq_out[heads[6]] || iq_done[heads[6]])))
					&& (iq_rl[heads[7]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
										 && (iq_done[heads[6]] || !iq_v[heads[6]] || !iq_mem[heads[6]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					&& !(iq_aq[heads[6]] && iq_v[heads[6]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[7]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]] || iq_store[heads[6]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
                    && (!(iq_memsb[heads[6]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]]))
                    		)
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
                    && (!(iq_memdb[heads[6]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[7]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]])
                       && !(iq_fc[heads[6]]||iq_canex[heads[6]]));
	 if (memissue[heads[7]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 8) begin
	memissue[ heads[8] ] =	~iq_stomp[heads[8]] && iq_memready[ heads[8] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					//&& ~iq_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]]
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[2]][AMSB:5] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[3]][AMSB:5] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[4]][AMSB:5] || iq_out[heads[4]] || iq_done[heads[4]])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[5]][AMSB:5] || iq_out[heads[5]] || iq_done[heads[5]])))
					&& (!iq_mem[heads[6]] || (iq_agen[heads[6]] & iq_out[heads[6]]) || iq_done[heads[6]] 
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[6]][AMSB:5] || iq_out[heads[6]] || iq_done[heads[6]])))
					&& (!iq_mem[heads[7]] || (iq_agen[heads[7]] & iq_out[heads[7]]) || iq_done[heads[7]] 
						|| ((iq_ma[heads[8]][AMSB:5] != iq_ma[heads[7]][AMSB:5] || iq_out[heads[7]] || iq_done[heads[7]])))
					&& (iq_rl[heads[8]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
										 && (iq_done[heads[6]] || !iq_v[heads[6]] || !iq_mem[heads[6]])
										 && (iq_done[heads[7]] || !iq_v[heads[7]] || !iq_mem[heads[7]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					&& !(iq_aq[heads[6]] && iq_v[heads[6]])
					&& !(iq_aq[heads[7]] && iq_v[heads[7]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[8]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]] || iq_store[heads[6]] || iq_store[heads[7]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
                    && (!(iq_memsb[heads[6]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]]))
                    		)
                    && (!(iq_memsb[heads[7]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]])
                    		&&   (iq_done[heads[6]] || !iq_v[heads[6]])
                    		)
                    		)
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
                    && (!(iq_memdb[heads[6]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]]))
                     		)
                    && (!(iq_memdb[heads[7]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]])
                     		&& (!iq_mem[heads[6]] || iq_done[heads[6]] || !iq_v[heads[6]])
                     		)
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[8]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]])
                       && !(iq_fc[heads[6]]||iq_canex[heads[6]])
                       && !(iq_fc[heads[7]]||iq_canex[heads[7]])
                       );
	 if (memissue[heads[8]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 9) begin
	memissue[ heads[9] ] =	~iq_stomp[heads[9]] && iq_memready[ heads[9] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					//&& ~iq_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[0]][AMSB:5] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]]
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[1]][AMSB:5] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[2]][AMSB:5] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[3]][AMSB:5] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[4]][AMSB:5] || iq_out[heads[4]] || iq_done[heads[4]])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[5]][AMSB:5] || iq_out[heads[5]] || iq_done[heads[5]])))
					&& (!iq_mem[heads[6]] || (iq_agen[heads[6]] & iq_out[heads[6]]) || iq_done[heads[6]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[6]][AMSB:5] || iq_out[heads[6]] || iq_done[heads[6]])))
					&& (!iq_mem[heads[7]] || (iq_agen[heads[7]] & iq_out[heads[7]]) || iq_done[heads[7]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[7]][AMSB:5] || iq_out[heads[7]] || iq_done[heads[7]])))
					&& (!iq_mem[heads[8]] || (iq_agen[heads[8]] & iq_out[heads[8]]) || iq_done[heads[8]] 
						|| ((iq_ma[heads[9]][AMSB:5] != iq_ma[heads[8]][AMSB:5] || iq_out[heads[8]] || iq_done[heads[8]])))
					&& (iq_rl[heads[9]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
										 && (iq_done[heads[6]] || !iq_v[heads[6]] || !iq_mem[heads[6]])
										 && (iq_done[heads[7]] || !iq_v[heads[7]] || !iq_mem[heads[7]])
										 && (iq_done[heads[8]] || !iq_v[heads[8]] || !iq_mem[heads[8]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					&& !(iq_aq[heads[6]] && iq_v[heads[6]])
					&& !(iq_aq[heads[7]] && iq_v[heads[7]])
					&& !(iq_aq[heads[8]] && iq_v[heads[8]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[9]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]] || iq_store[heads[6]] || iq_store[heads[7]]
						|| iq_store[heads[8]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
                    && (!(iq_memsb[heads[6]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]]))
                    		)
                    && (!(iq_memsb[heads[7]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]])
                    		&&   (iq_done[heads[6]] || !iq_v[heads[6]]))
                    		)
                    && (!(iq_memsb[heads[8]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]])
                    		&&   (iq_done[heads[6]] || !iq_v[heads[6]])
                    		&&   (iq_done[heads[7]] || !iq_v[heads[7]])
                    		)
                    		)
    				&& (!(iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
                    && (!(iq_memdb[heads[6]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]]))
                     		)
                    && (!(iq_memdb[heads[7]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]])
                     		&& (!iq_mem[heads[6]] || iq_done[heads[6]] || !iq_v[heads[6]]))
                     		)
                    && (!(iq_memdb[heads[8]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]])
                     		&& (!iq_mem[heads[6]] || iq_done[heads[6]] || !iq_v[heads[6]])
                     		&& (!iq_mem[heads[7]] || iq_done[heads[7]] || !iq_v[heads[7]])
                     		)
                     		)
					// ... and, if it is a store, there is no chance of it being undone
					&& ((iq_load[heads[9]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]])
                       && !(iq_fc[heads[6]]||iq_canex[heads[6]])
                       && !(iq_fc[heads[7]]||iq_canex[heads[7]])
                       && !(iq_fc[heads[8]]||iq_canex[heads[8]])
                       );
	 if (memissue[heads[9]])
	 	issue_count = issue_count + 1;
	end
end
end
endgenerate
`endif

endmodule
