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
`include "rtf65004-config.sv"
`include "rtf65004-defines.sv"

module tailptrs(rst_i, clk_i, branchmiss, iq_stomp, queuedCnt, iq_tails, 
	rqueuedCnt, rob_tails, iq_rid);
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
input rst_i;
input clk_i;
input branchmiss;
input [IQ_ENTRIES-1:0] iq_stomp;
input [2:0] queuedCnt;
output reg [`QBITS] iq_tails [0:QSLOTS-1];
input [2:0] rqueuedCnt;
output reg [`RBITS] rob_tails [0:RSLOTS-1];
input [`RBITS] iq_rid [0:IQ_ENTRIES-1];

integer n, j;

always @(posedge clk_i)
if (rst_i) begin
	for (n = 0; n < QSLOTS; n = n + 1)
		iq_tails[n] <= n;
end
else begin
	if (!branchmiss) begin
		for (n = 0; n < QSLOTS; n = n + 1)
   		iq_tails[n] <= (iq_tails[n]+queuedCnt) % IQ_ENTRIES;
	end
	else begin	// if branchmiss
		for (n = IQ_ENTRIES-1; n >= 0; n = n - 1)
			// (IQ_ENTRIES-1) is needed to ensure that n increments forwards so that the modulus is
			// a positive number.
			if (iq_stomp[n] & ~iq_stomp[(n+(IQ_ENTRIES-1))%IQ_ENTRIES]) begin
				for (j = 0; j < QSLOTS; j = j + 1)
					iq_tails[j] <= (n + j) % IQ_ENTRIES;
			end
	end
end

always @(posedge clk_i)
if (rst_i) begin
	for (n = 0; n < RSLOTS; n = n + 1)
		rob_tails[n] <= n;
end
else begin
	if (!branchmiss) begin
		for (n = 0; n < RSLOTS; n = n + 1)
			rob_tails[n] <= (rob_tails[n] + rqueuedCnt) % RENTRIES;	
	end
	else begin
		for (n = IQ_ENTRIES-1; n >= 0; n = n - 1)
			// (IQ_ENTRIES-1) is needed to ensure that n increments forwards so that the modulus is
			// a positive number.
			if (iq_stomp[n] & ~iq_stomp[(n+(IQ_ENTRIES-1))%IQ_ENTRIES]) begin
				for (j = 0; j < RSLOTS; j = j + 1)
					rob_tails[j] <= (iq_rid[n] + j) % RENTRIES;
			end
	end
end

endmodule
