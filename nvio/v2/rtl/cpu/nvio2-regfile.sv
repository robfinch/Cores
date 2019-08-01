// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nvio2-regfile.sv
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

module nvio2_regfile(clk, wr, adr, i, o);
input clk;
input wr;
input [12:0] adr;
input [127:0] i;
output [127:0] o;

reg [12:0] radr;
(* ram_style = "block" *)
reg [127:0] mem [0:8191];
always @(posedge clk)
	if (wr) mem[adr] <= i;
always @(posedge clk)
	radr <= adr;
assign o = radr[5:0]==6'd0 ? 128'd0 : mem[radr];

endmodule
