// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
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
// ack_gen.v
// - generates a acknowledge signal after a specified number of clocks.
// - separate stages for read and write
//
// ============================================================================
//
module ack_gen(clk_i, ce_i, i, we_i, o);
input clk_i;
input ce_i;
input i;
input we_i;
output reg o;
parameter READ_STAGES = 3;
parameter WRITE_STAGES = 0;
parameter ACK_LEVEL = 1'b0;
parameter REGISTER_OUTPUT = 1'b0;

wire ro, wo;
generate begin : gRdy
if (READ_STAGES==0)
assign ro = 0;
else begin
ready_gen #(READ_STAGES) urrdy (clk_i, ce_i, i, ro);
end
if (WRITE_STAGES==0)
assign wo = we_i;
else begin
ready_gen #(WRITE_STAGES) uwrdy (clk_i, ce_i, we_i, wo);
end
if (REGISTER_OUTPUT) begin
always @(posedge clk_i)
	o <= we_i ? wo : (i ? ro : ACK_LEVEL);
end
else begin
always @*
	o <= we_i ? wo : (i ? ro : ACK_LEVEL);
end
end
endgenerate

endmodule
