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
`include "rtf65004-config.sv"
`define VAL		1'b1
`define INV		1'b0

module regfileSource(rst, clk, branchmiss, heads, slotv, slot_rfw,
	slot_sr_tgts,
	queuedOn,	rqueuedOn, iq_rfw, iq_Rd, Rd, rob_tails,
	iq_latestID, iq_tgt, iq_rid, iq_latest_sr_ID, rf_source, sr_source);
parameter AREGS = 32;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter RENTRIES = `RENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RBIT = 4;
input rst;
input clk;
input branchmiss;
input [`QBITS] heads [0:IQ_ENTRIES-1];
input [QSLOTS-1:0] slotv;
input [IQ_ENTRIES-1:0] slot_rfw;
input [7:0] slot_sr_tgts [0:QSLOTS-1];
input [QSLOTS-1:0] queuedOn;
input [IQ_ENTRIES-1:0] rqueuedOn;
input [IQ_ENTRIES-1:0] iq_rfw;
input [RBIT+1:0] iq_Rd [0:IQ_ENTRIES-1];
input [RBIT+1:0] Rd [0:QSLOTS-1];
input [`RBITS] rob_tails [0:QSLOTS-1];
input [AREGS-1:0] iq_latestID [0:IQ_ENTRIES-1];
input [RBIT+1:0] iq_tgt [0:IQ_ENTRIES-1];
input [`RBITS] iq_rid [0:IQ_ENTRIES-1];
input [`QBITS] iq_latest_sr_ID;
output reg [`QBITSP1] rf_source [0:AREGS-1];
output reg [`QBITSP1] sr_source;

integer n;

initial begin
for (n = 0; n <= AREGS; n = n + 1)
	rf_source[n] = 1'b0;
sr_source = 1'b0;
end

always @(posedge clk)
if (rst) begin
  for (n = 0; n <= AREGS; n = n + 1) begin
    rf_source[n] <= {`QBIT{1'b1}};
  end
  sr_source <= {`QBIT{1'b1}};
end
else begin
	if (branchmiss) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
    	if (|iq_latestID[n])
    		rf_source[ {1'b0,iq_tgt[n]} ] <= {{`QBIT{1'b0}},iq_rid[n[`QBITS]]};
			if (iq_rid[n] >= IQ_ENTRIES)
				$stop;
    end
    if (iq_latest_sr_ID != {`QBIT{1'b1}})
			sr_source <= iq_latest_sr_ID;
	end
	else begin
		// Setting the rf valid and source
		case(slotv)
		3'b000:	;
		3'b001:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[0]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
			end
		3'b010:
			if (queuedOn[1]) begin
				if (slot_rfw[1])
					rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[1]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
			end
		3'b011:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[0]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
				if (queuedOn[1]) begin
					if (slot_rfw[1])
						rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[1]};
					if (slot_sr_tgts[1]!=8'h00)
						sr_source <= {{`QBIT{1'b0}},rob_tails[1]};
				end
			end
		3'b100:
			if (queuedOn[2]) begin
				if (slot_rfw[2])
					rf_source[Rd[2]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[2]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
			end
		3'b101:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[0]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
				if (queuedOn[2]) begin
					if (slot_rfw[2])
						rf_source[Rd[2]] <= {{`QBIT{1'b0}},rob_tails[1]};
					if (slot_sr_tgts[2]!=8'h00)
						sr_source <= {{`QBIT{1'b0}},rob_tails[1]};
				end
			end
		3'b110:
			if (queuedOn[1]) begin
				if (slot_rfw[1])
					rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[1]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
				if (queuedOn[2]) begin
					if (slot_rfw[2])
						rf_source[Rd[2]] <= {{`QBIT{1'b0}},rob_tails[1]};
					if (slot_sr_tgts[2]!=8'h00)
						sr_source <= {{`QBIT{1'b0}},rob_tails[1]};
				end
			end
		3'b111:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (slot_sr_tgts[0]!=8'h00)
					sr_source <= {{`QBIT{1'b0}},rob_tails[0]};
				if (queuedOn[1]) begin
					if (slot_rfw[1]) begin
						rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[1]};
					end
					if (slot_sr_tgts[1]!=8'h00)
						sr_source <= {{`QBIT{1'b0}},rob_tails[1]};
					if (queuedOn[2]) begin
						if (slot_rfw[2]) begin
							rf_source[Rd[2]] <= {{`QBIT{1'b0}},rob_tails[2]};
						end
						if (slot_sr_tgts[2]!=8'h00)
							sr_source <= {{`QBIT{1'b0}},rob_tails[2]};
					end
				end
			end
		endcase
		for (n = 0; n < QSLOTS; n = n + 1)
			if (rob_tails[n] >= IQ_ENTRIES)
				$stop;
		for (n = 0; n < IQ_ENTRIES; n = n + 1)
			if (iq_rid[n] >= IQ_ENTRIES)
				$stop;
	end
end

endmodule
