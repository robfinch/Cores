// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
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
module scratchram(rst_i, clk_i, cs_i, cyc_i, stb_i, wr_i, ack_o, sel_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
input wr_i;
output ack_o;
input [15:0] sel_i;
input [13:0] adr_i;
input [127:0] dat_i;
output [127:0] dat_o;

reg ack1,ack2,ack3;
wire cs;
assign cs = cyc_i & stb_i & cs_i;
assign ack_o = cs ? (wr_i ? 1'b1 : ack3) : 1'b0;

wire [9:0] addra = adr_i[13:4];

always @(posedge clk_i)
    ack1 <= cs;
always @(posedge clk_i)
    ack2 <= ack1 & cs;
always @(posedge clk_i)
    ack3 <= ack2 & cs;

scratchram_mem1 u1 (
  .clka(clk_i),    // input wire clka
  .ena(cs),  // input wire ena
  .wea(sel_i),    // input wire [15 : 0] wea
  .addra(addra),  // input wire [9 : 0] addra
  .dina(dat_i),    // input wire [127 : 0] dina
  .douta(dat_o)  // output wire [127 : 0] doutb
);

endmodule
