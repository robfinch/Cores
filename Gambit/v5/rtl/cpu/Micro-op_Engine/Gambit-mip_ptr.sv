// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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
// Compute pointers into micro-instruction program.
// Set which instruction a pointer points to.
// The pointers allow accessing the micro-program as a four read-port memory,
// rather than using mip1, mip1+1, etc. directly which would require more
// ports.
// ============================================================================
//
`include "..\Gambit-config.sv"
`include "..\Gambit-types.sv"

module mip_ptr(uop_prg, mip1, mip2, branchmiss, ptr, whinst);
input MicroOp uop_prg [0:`LAST_UOP];
input MicroOpPtr mip1;
input MicroOpPtr mip2;
input branchmiss;
output MicroOpPtr ptr [0:`MAX_UOPQ-1];
output reg [`MAX_UOPQ-1:0] whinst;

integer n, m;
integer a;

always @*
begin
	a = 0;
	for (n = 0; n < `MAX_UOPQ; n = n + 1) begin
		ptr[n] = mip1 + n;
		whinst[n] = 1'b0;
	end
	whinst[0] = 1'b0;
	for (n = 0; n < `MAX_UOPQ; n = n + 1) begin
		if (uop_prg[ptr[n]].fl[1] && !a) begin
			for (m = n + 1; m < `MAX_UOPQ; m = m + 1) begin
				ptr[m] = mip2 + m - n - 1;
				whinst[m] = 1'b1;
				a = 1;
			end
		end
	end
	// Point everything to NOPs on a branch miss.
	if (branchmiss) begin
		for (n = 0; n < `MAX_UOPQ; n = n + 1)
			ptr[n] = 1'd0;
	end
end

endmodule
