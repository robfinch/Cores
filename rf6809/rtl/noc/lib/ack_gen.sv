// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2022  Robert Finch, Waterloo
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
module ack_gen(rst_i, clk_i, ce_i, i, rid_i, we_i, wid_i, o, rid_o, wid_o);
input rst_i;
input clk_i;
input ce_i;
input i;
input [3:0] rid_i;
input we_i;
input [3:0] wid_i;
output reg o;
output reg [3:0] rid_o;
output reg [3:0] wid_o;
parameter READ_STAGES = 3;
parameter WRITE_STAGES = 0;
parameter ACK_LEVEL = 1'b0;
parameter REGISTER_OUTPUT = 1'b0;

wire ro, wo;
wire [3:0] rid, wid;
generate begin : gRdy
if (READ_STAGES==0) begin
assign ro = 0;
assign rid = rid_i;
end
else begin
ready_gen #(READ_STAGES) urrdy (clk_i, ce_i, i, ro, rid_i, rid);
end
if (WRITE_STAGES==0) begin
assign wo = we_i;
assign wid = wid_i;
end
else begin
ready_gen #(WRITE_STAGES) uwrdy (clk_i, ce_i, we_i, wo, wid_i, wid);
end
if (REGISTER_OUTPUT) begin
always @(posedge clk_i)
if (rst_i)
	o <= 1'b0;
else
	o <= we_i ? wo : (i ? ro : ACK_LEVEL);
always @(posedge clk_i)
	rid_o <= rid;
always @(posedge clk_i)
	wid_o <= wid;
end
else begin
always @*
	o <= we_i ? wo : (i ? ro : ACK_LEVEL);
always @*
	rid_o <= rid;
always @*
	wid_o <= wid;
end
end
endgenerate

endmodule
