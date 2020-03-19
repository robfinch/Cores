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
`include "..\inc\Gambit-types.sv"

module stompLogic(rst, clk, ce, branchmiss, misssn, iq_sn, iq_stomp);
input rst;
input clk;
input ce;
input branchmiss;
input [`SNBITS] misssn;
input Seqnum [`IQ_ENTRIES-1:0] iq_sn;
output reg [`IQ_ENTRIES-1:0] iq_stomp;
parameter TRUE = 1'b1;

integer n;
reg branchmiss2;

always @(posedge clk)
if (rst)
	iq_stomp <= 1'b0;
else begin
	if (ce) begin
		iq_stomp <= 1'b0;
		branchmiss2 <= branchmiss;
		if (branchmiss & ~branchmiss2) begin
			for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
				if (iq_sn[n] > misssn)
					iq_stomp[n] <= TRUE;
			end
		end
	end
end

endmodule
