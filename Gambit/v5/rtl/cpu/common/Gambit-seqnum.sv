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
`include "Gambit-config.sv"

module seqnum(rst, clk, heads, hi_amt, iq_v, iq_sn, overflow, maxsn, tosub);
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
input rst;
input clk;
input [`QBITS] heads [0:IQ_ENTRIES-1];
input [2:0] hi_amt;
input [IQ_ENTRIES-1:0] iq_v;
input overflow;
input [`SNBITS] iq_sn [0:IQ_ENTRIES-1];
output reg [`SNBITS] maxsn;
output [`SNBITS] tosub;

integer n, j;

// Amount subtracted from sequence numbers
function [`SNBITS] sn_dec;
input [2:0] amt;
begin
	sn_dec = 1'd0;
	for (j = 0; j < IQ_ENTRIES; j = j + 1)
		if (j < amt) begin
			if (iq_v[heads[j]])
				sn_dec = iq_sn[heads[j]];
		end
end
endfunction

assign tosub = 0;//sn_dec(hi_amt);

always @*
begin
maxsn = 1'd0;
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_sn[n] > maxsn)// && iq_v[n])
		maxsn = iq_sn[n];
maxsn = overflow ? maxsn - {2'b01,{`SNBIT-2{1'b0}}} : maxsn;
//maxsn = maxsn - tosub;
end

endmodule


