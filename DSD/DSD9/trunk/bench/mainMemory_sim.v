// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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
module mainMemory_sim(rst_i, clk_i, cyc_i, stb_i, wr_i, ack_o, sel_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
input wr_i;
output ack_o;
input [15:0] sel_i;
input [31:0] adr_i;
input [127:0] dat_i;
output [127:0] dat_o;
reg [127:0] dat_o;

reg ack1, ack2, ack3;
wire cs;
assign cs = cyc_i && stb_i && (adr_i[31:14]!=18'h0000) && (adr_i[31:26]==6'h0);
assign ack_o = cs ? ack3 : 1'b0;

reg [127:0] rammem [0:16383]; // 32MW = 128MB

always @(posedge clk_i)
begin
    ack1 <= cs;
    ack2 <= ack1 & cs;
    ack3 <= ack2 & cs;
end

genvar n;
generate begin
for (n = 0; n < 16; n = n + 1)
    always @(posedge clk_i)
        if (cs) begin
           if (wr_i) begin
                   if (sel_i[n])   rammem[adr_i[17:4]][n*8+7:n*8] <= dat_i[n*8+7:n*8];
           end
        end
end
endgenerate

always @(posedge clk_i)
    if (cs)
		dat_o <= rammem[adr_i[17:4]];
    else
		dat_o <= 128'd0;

endmodule
