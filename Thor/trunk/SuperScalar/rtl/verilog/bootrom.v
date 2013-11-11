`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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
module bootrom(rst_i, clk_i, cti_i, cyc_i, stb_i, ack_o, adr_i, dat_o, perr);
input rst_i;
input clk_i;
input [2:0] cti_i;
input cyc_i;
input stb_i;
output ack_o;
input [31:0] adr_i;
output [63:0] dat_o;
reg [63:0] dat_o;
output perr;
reg perr;

wire ne_cs;
wire cs;
reg ack0,ack1,ack2,ack3;
always @(posedge clk_i)
begin
	if (ne_cs)
		ack0 <= cs;
	else if (!cs)
		ack0 <= 1'b0;
	ack1 <= ack0 & cs;
	ack2 <= ack1 & cs;
	ack3 <= ack2 & cs;
end
assign cs = cyc_i && stb_i && adr_i[31:16]==16'hFFFF;
assign ack_o = cs & ack0;

reg [64:0] rommem [0:8191];
initial begin
`include "..\..\software\asm\Thorasm\bin\bootrom.ver"
end

wire pe_cs;
edge_det u1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee());
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(pe_cs), .pe(), .ne(ne_cs), .ee());

reg [15:3] radr;
reg [15:3] ctr;

always @(posedge clk_i)
	if (pe_cs)
		ctr <= adr_i[15:3] + 13'd1;
	else if (cs)
		ctr <= ctr + 13'd1;

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[15:3] : ctr;

always @(posedge clk_i)
	if (cs)
		dat_o <= rommem[radr][63:0];
	else
		dat_o <= 64'd0;

always @(posedge clk_i)
	if (cs)
		perr <= ^rommem[radr][63:0]!=rommem[radr][64];
	else
		perr <= 1'd0;

endmodule
