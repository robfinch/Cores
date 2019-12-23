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
output MicroOpPtr ptr [0:3];
output reg [3:0] whinst;

always @*
begin
	whinst[0] = 1'b1;
	whinst[1] = 1'b1;
	whinst[2] = 1'b1;
	whinst[3] = 1'b1;
	if (~|mip1) begin		// Is the 1st macro instruction completed? (mip == 0)
		if (|mip2) begin
			ptr[0] = mip2;
			if (uop_prg[ptr[0]].fl[1]) begin
				ptr[1] = 1'd0;
				ptr[2] = 1'd0;
				ptr[3] = 1'd0;
			end
			else begin
				ptr[1] = mip2 + 1;
				if (uop_prg[ptr[1]].fl[1]) begin
					ptr[2] = 1'd0;
					ptr[3] = 1'd0;
				end
				else begin
					ptr[2] = mip2 + 2;
					if (uop_prg[ptr[2]].fl[1])
						ptr[3] = 1'd0;
					else
						ptr[3] = mip2 + 3;
				end
			end
		end
		else begin
			ptr[0] = 1'd0;
			ptr[1] = 1'd0;
			ptr[2] = 1'd0;
			ptr[3] = 1'd0;
		end
	end
	else begin
		ptr[0] = mip1;
		whinst[0] = 1'b0;
		if (uop_prg[ptr[0]].fl[1]) begin
			ptr[1] = mip2;
			if (uop_prg[ptr[1]].fl[1]) begin
				ptr[2] = 1'd0;
				ptr[3] = 1'd0;
			end
			else begin
				ptr[2] = mip2+1;
				if (uop_prg[ptr[2]].fl[1])
					ptr[3] = 1'd0;
				else
					ptr[3] = mip2+2;
			end
		end
		else begin
			ptr[1] = mip1+1;
			whinst[1] = 1'b0;
			if (uop_prg[ptr[1]].fl[1]) begin
				ptr[2] = mip2;
				if (uop_prg[ptr[2]].fl[1])
					ptr[3] = 1'd0;
				else
					ptr[3] = mip2+1;
				whinst[3:2] = 2'd3;
			end
			else begin
				ptr[2] = mip1+2;
				whinst[2] = 1'b0;
				if (uop_prg[ptr[2]].fl[1]) begin
					ptr[3] = mip2;
					whinst[3] = 1'b1;
				end
				else begin
					ptr[3] = mip1+3;
					whinst[3] = 1'b0;
				end
			end
		end
	end
	// Point everything to NOPs on a branch miss.
	if (branchmiss) begin
		ptr[0] = 1'd0;
		ptr[1] = 1'd0;
		ptr[2] = 1'd0;
		ptr[3] = 1'd0;
	end
end

endmodule
