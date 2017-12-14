// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	bootrom.v
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
module bootrom(clk_i, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
parameter pAckStyle = 1'b0;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input [15:0] adr_i;
output reg [15:0] dat_o;

reg ack1, ack2, ack3;
reg [15:0] rommem [0:32767];
reg [15:0] radr;
reg [15:0] dat;

wire cs = cs_i & cyc_i & stb_i;
 
initial begin
`include "..\..\software\bootrom\bootrom.vh"
end

always @(posedge clk_i)
    radr <= adr_i;

always @(posedge clk_i)
    dat_o <= rommem[radr[15:1]];

always @(posedge clk_i)
    ack1 <= cs;
always @(posedge clk_i)
    ack2 <= ack1 & cs;
always @(posedge clk_i)
    ack3 <= ack2 & cs;
//always @(posedge clk_i)
//    ack_o <= ack2 & cs & ~ack_o;
always @*
    ack_o <= cs_i ? ack3 : pAckStyle;

endmodule
