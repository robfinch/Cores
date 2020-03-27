// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
module bootrom(rst, clk, cs, adr0, o0, adr1, o1, adr2, o2);
parameter WID=128;
//parameter FNAME = "c:\\cores5\\FT64\\trunk\\software\\boot\\boot.ve0";
input rst;
input clk;
input cs;
input [17:0] adr0;
output [WID-1:0] o0;
input [17:0] adr1;
output [WID-1:0] o1;
input [17:0] adr2;
output [WID-1:0] o2;
reg [WID-1:0] o0 = 128'd0;
reg [WID-1:0] o1 = 128'd0;
reg [WID-1:0] o2 = 128'd0;

integer n;

(* ram_style="block" *)
reg [WID-1:0] rommem [7167:0];
reg [14:0] radr0, radr1, radr2;

initial begin
`include "d:\\cores6\\Petajon\\v1\\software\\boot\\boot.ve0";
end

always @(posedge clk)
	radr0 <= adr0[17:4];
always @(posedge clk)
	radr1 <= adr1[17:4];
always @(posedge clk)
	radr2 <= adr2[17:4];

always @*	o0 <= rommem[radr0];
always @*	o1 <= rommem[radr1];
always @*	o2 <= rommem[radr2];

endmodule
