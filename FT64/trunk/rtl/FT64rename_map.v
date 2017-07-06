// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2017  Robert Finch, Waterloo
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
// Status: Untested, unused
//
// Register Rename Map
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
module FT64rename_map(clk, nq, ndx, indx0, indx1, wr0, wr1, ra, rb, rc, rd, r0, r1, 
    rra, rrb, rrc, rrd, ar0, ar1, va,vb,vc,vd, wra, wrra, wrb, wrrb
    ToFree0, ToFree1,
    );
input clk;
input nq;			// enqueue instruction
input [2:0] ndx;	// index to active map
input [2:0] indx0;
input [2:0] indx1;
input wr0;
input wr1;
input [4:0] ra;		// architectural register
input [4:0] rb;
input [4:0] rc;
input [4:0] rd;
input [5:0] r0;
input [5:0] r1;
output [5:0] rra;	// physical register
output [5:0] rrb;
output [5:0] rrc;
output [5:0] rrd;
output [4:0] ar0;
output [4:0] ar1;
output va;			// translation is valid for register
output vb;
output vc;
output vd;
input [4:0] wra;	// architectural register
input [4:0] wrb;
input [5:0] wrra;	// physical register
input [5:0] wrrb;
output [5:0] ToFree0;
output [5:0] ToFree1;

integer n,m;
reg [6:0] map [7:0][31:0];

assign rra = map[ndx][ra][5:0];
assign rrb = map[ndx][rb][5:0];
assign rrc = map[ndx][rc][5:0];
assign rrd = map[ndx][rd][5:0];
assign ToFree0 = map[ndx][wra][5:0];
assign ToFree1 = map[ndx][wrb][5:0];
assign ar0 = imap[indx0][r0];
assign ar1 = imap[indx1][r1];
assign va = map[ndx][ra][6];
assign vb = map[ndx][rb][6];
assign vc = map[ndx][rc][6];
assign vd = map[ndx][rd][6];

// Start out with a map where all the physical and architectural
// registers match.
initial begin
	for (m = 0; m < 8; m = m + 1)
		for (n = 0; n < 32; n = n + 1)
			map[m][n] <= n;
end

always @(posedge clk)
	if (nq) begin
		for (n = 0; n < 32; n = n + 1)		// copy the current rename map to a new one
			map[ndx+1][n] <= map[ndx][n];
	    if (wr1) begin
            for (n = 0; n < 32; n = n + 1)		// copy the current rename map to a new one
                map[ndx+2][n] <= map[ndx][n];
	    end
		if (wr0)
			map[ndx+1][wra] <= {1'b1,wrra};
		if (wr1) begin
		    map[ndx+2][wra] <= {1'b1,wrra};
			map[ndx+2][wrb] <= {1'b1,wrrb};
        end
//		ndx <= ndx + 1;						// make the new map the current one for mappings
	end

endmodule
