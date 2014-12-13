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
output [31:0] dat_o;
reg [31:0] dat_o;
output perr;
reg perr;

wire cs;
reg ack0,ack1;
always @(posedge clk_i)
begin
	ack0 <= cs;
	ack1 <= ack0 & cs;
end
assign cs = cyc_i && stb_i && adr_i[31:15]==17'b00001;
assign ack_o = cs & ack1;

reg [32:0] rommem [0:8191];
initial begin
`include "..\..\software\asm\Thorasm\bin\Bootrom4.ver"
end

wire pe_cs;
edge_det u1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee());

reg [14:2] radr;
reg [14:2] ctr;

always @(posedge clk_i)
	if (pe_cs)
		ctr <= adr_i[14:2] + 13'd1;
	else if (cs)
		ctr <= ctr + 13'd1;

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[14:2] : ctr;

always @(posedge clk_i)
	if (cs)
		dat_o <= rommem[radr][31:0];
	else
		dat_o <= 32'd0;

always @(posedge clk_i)
	if (cs)
		perr <= ^rommem[radr][31:0]!=rommem[radr][32];
	else
		perr <= 1'd0;

endmodule
