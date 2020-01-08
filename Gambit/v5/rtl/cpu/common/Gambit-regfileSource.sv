// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
// 18854
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"
`define VAL		1'b1
`define INV		1'b0

module regfileSource(rst, clk, ce, branchmiss, slot_rfw,
	queuedOn,	rqueuedOn, iq_rfw, Rd, rob_tails, brk, slot_jmp, take_branch,
	iq_latestID, iq_tgt, iq_rid, rf_source);
parameter AREGS = 128;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter RENTRIES = `RENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RBIT = 5;
input rst;
input clk;
input ce;
input branchmiss;
input [QSLOTS-1:0] slot_rfw;
input [QSLOTS-1:0] queuedOn;
input [IQ_ENTRIES-1:0] rqueuedOn;
input [IQ_ENTRIES-1:0] iq_rfw;
input RegTag Rd [0:QSLOTS-1];
input Rid rob_tails [0:QSLOTS*2-1];
input [QSLOTS-1:0] brk;
input [QSLOTS-1:0] slot_jmp;
input [QSLOTS-1:0] take_branch;
input RegTagBitmap iq_latestID [0:IQ_ENTRIES-1];
input RegTag iq_tgt [0:IQ_ENTRIES-1];
input Rid iq_rid [0:IQ_ENTRIES-1];
output Rid rf_source [0:AREGS-1];

integer n;
reg branchmiss2, branchmiss3, branchmiss4;
always @(posedge clk)
	branchmiss2 <= branchmiss;
always @(posedge clk)
	branchmiss3 <= branchmiss2;
always @(posedge clk)
	branchmiss4 <= branchmiss3;

initial begin
for (n = 0; n < AREGS; n = n + 1)
	rf_source[n] = 1'b0;
end

always @(posedge clk)
if (rst) begin
  for (n = 0; n < AREGS; n = n + 1) begin
    rf_source[n] <= {`QBIT{1'b1}};
  end
end
else begin
	if (branchmiss3 & ~branchmiss4) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
    	if (|iq_latestID[n])
    		rf_source[ iq_tgt[n] ] <= {{`QBIT{1'b0}},iq_rid[n]};
			if (iq_rid[n] >= IQ_ENTRIES)
				$stop;
    end
	end
	else if (ce) begin
		if (queuedOn[0]) begin
			if (slot_rfw[0])
				rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
	      if (!brk[0]) begin
	        if (!(slot_jmp[0]|take_branch[0])) begin
						if (queuedOn[1]) begin
							if (slot_rfw[1])
								rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[1]};
						end
					end
				end
		end
		else if (queuedOn[1]) begin
			if (slot_rfw[1])
				rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[0]};
		end
	end
end

endmodule
