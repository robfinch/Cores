// ============================================================================
// (C) 2016 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
//
//	FAL6567.v
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
module FT6567ColorRam(wclk, wr, wa, d, rclk, ra0, o0, ra1, o1);
input wclk;
input wr;
input [11:0] wa;
input [7:0] d;
input rclk;
input [11:0] ra0;
input [11:0] ra1;
output [7:0] o0;
output [7:0] o1;

reg [7:0] mem [4095:0];

reg [11:0] rra0, rra1;

always @(posedge wclk)
  if (wr) mem[wa] <= d;
always @(posedge rclk)
  rra0 <= ra0;
always @(posedge rclk)
  rra1 <= ra1;
assign o0 = mem[rra0];
assign o1 = mem[rra1];

endmodule
