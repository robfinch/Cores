`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
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
// ============================================================================
//
module bootrom(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input [16:0] adr_i;
output [127:0] dat_o;
reg [127:0] dat_o;

wire cs;
reg ack1,ack2,ack3;
assign cs = cs_i && cyc_i && stb_i;
assign ack_o = cs ? ack3 : 1'b0;

reg [127:0] rommem[0:5119];
reg [12:0] radr;
initial begin
`include "C:\Cores4\DSD\DSD9\trunk\software\bootrom\source\bootrom.ve0"
end

always @(posedge clk_i)
    ack1 <= cs;
always @(posedge clk_i)
    ack2 <= ack1 & cs;
always @(posedge clk_i)
    ack3 <= ack2 & cs;

always @(posedge clk_i)
    radr <= adr_i[16:4];

always @(posedge clk_i)
    dat_o <= rommem[radr];

endmodule
