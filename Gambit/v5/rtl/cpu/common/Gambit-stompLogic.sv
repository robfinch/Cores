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
//
// ============================================================================
//
`include "..\inc\Gambit-config.sv"

module stompLogic(branchmiss, misssn, iq_sn, iq_stomp);
input branchmiss;
input [`SNBITS] misssn;
input [`SNBITS] iq_sn [0:`IQ_ENTRIES-1];
output reg [`IQ_ENTRIES-1:0] iq_stomp;
parameter TRUE = 1'b1;

integer n;

always @*
begin
	iq_stomp = 1'b0;
	if (branchmiss) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (iq_sn[n] > misssn)
				iq_stomp[n] = TRUE;
		end
	end
end

endmodule
