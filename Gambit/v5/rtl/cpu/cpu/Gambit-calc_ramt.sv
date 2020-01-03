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
//
// ============================================================================
//
`include "..\inc\Gambit-config.sv"

module calc_ramt(hi_amt, rob_heads, rob_tails, rob_v, r_amt);
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
parameter RS_INVALID = 2'd0;
input [3:0] hi_amt;
input [`RBITS] rob_tails [0:RSLOTS-1];
input [`RBITS] rob_heads [0:RENTRIES-1];
input [RENTRIES-1:0] rob_v;
output reg [3:0] r_amt;

reg [3:0] nxtrb;
always @*
begin
	// Amount to increment reorder buffer pointer by
	r_amt = hi_amt;

	// Now search ahead for invalid entries that can be skipped over.
	nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
	if (rob_v[nxtrb[`RBITS]]==`INV && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
		r_amt = r_amt + 4'd1;
		nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
		if (rob_v[nxtrb[`RBITS]]==`INV && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
			r_amt = r_amt + 4'd1;
			nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
			if (rob_v[nxtrb[`RBITS]]==`INV && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
				r_amt = r_amt + 4'd1;
				nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
				if (rob_v[nxtrb[`RBITS]]==`INV && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
					r_amt = r_amt + 4'd1;
					nxtrb = rob_heads[0] + r_amt;
				end
			end
		end
	end
end

endmodule
