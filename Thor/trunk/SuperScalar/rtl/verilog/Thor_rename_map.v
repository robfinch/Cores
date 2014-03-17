// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
// Thor Register Rename Map
//
//     The register rename map is really an array of maps to allow backout
// capability for branch misses and exceptions. Whenever a new map entry is
// added, the entire current map is copied to a new map, and the new map 
// entries inserted. The new map is then made the current map.
//
// Backout:
//     The map number used to map rename registers is stored in the ROB when
// an instruction is enqueued. When a backout occurs, the current rename map
// number is reset to the one from the ROB containing the branch.
//
// ToDo: add a valid bit
// ============================================================================
//
module Thor_rename_map(clk, nq, ndx, wr0, wr1, ra, rb, rc, rd, rra, rrb, rrc, rrd, va,vb,vc,vd, wra, wrra, wrb, wrrb);
input clk;
input nq;			// enqueue instruction
input [2:0] ndx;	// index to active map
input wr0;
input wr1;
input [5:0] ra;		// architectural register
input [5:0] rb;
input [5:0] rc;
input [5:0] rd;
output [6:0] rra;	// physical register
output [6:0] rrb;
output [6:0] rrc;
output [6:0] rrd;
output va;			// translation is valid for register
output vb;
output vc;
output vd;
input [5:0] wra;	// architectural register
input [5:0] wrb;
input [6:0] wrra;	// physical register
input [6:0] wrrb;

integer n,m;
reg [7:0] map [7:0][63:0];

assign rra = map[ndx][ra][6:0];
assign rrb = map[ndx][rb][6:0];
assign rrc = map[ndx][rc][6:0];
assign rrd = map[ndx][rd][6:0];
assign va = map[ndx][ra][7];
assign vb = map[ndx][rb][7];
assign vc = map[ndx][rc][7];
assign vd = map[ndx][rd][7];

initial begin
	for (m = 0; m < 8; m = m + 1)
		for (n = 0; n < 64; n = n + 1)
			map[m][n] <= n;
end

always @(posedge clk)
	if (nq) begin
		for (n = 0; n < 64; n = n + 1)		// copy the current rename map to a new one
			map[ndx+1][n] <= map[ndx][n];
		if (wr0 & wr1) begin				// add in new register mappings
			if (wra==wrb)
				map[ndx+1][wrb] <= {1'b1,wrrb};
			else begin
				map[ndx+1][wra] <= {1'b1,wrra};
				map[ndx+1][wrb] <= {1'b1,wrrb];
			end
		end
		else if (wr0)
			map[ndx+1][wra] <= {1'b1,wrra};
		else if (wr1)
			map[ndx+1][wrb] <= {1'b1,wrrb};
//		ndx <= ndx + 1;						// make the new map the current one for mappings
	end

endmodule
