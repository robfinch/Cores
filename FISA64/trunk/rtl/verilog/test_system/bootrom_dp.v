`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
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
module bootrom_dp(rst_i, clk_i, cyc_i, stb_i, ack_o, adr_i, dat_o, perr,
p1_clk_i, p1_cyc_i, p1_stb_i, p1_ack_o, p1_adr_i, p1_dat_o, p1_perr
);
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input [31:0] adr_i;
output [63:0] dat_o;
reg [63:0] dat_o;
output perr;
reg perr;
input p1_clk_i;
input p1_cyc_i;
input p1_stb_i;
output p1_ack_o;
input [31:0] p1_adr_i;
output [63:0] p1_dat_o;
reg [63:0] p1_dat_o;
output p1_perr;
reg p1_perr;

wire cs,p1_cs;
reg ack0,ack1,p1_ack0,p1_ack1;
always @(posedge clk_i)
begin
	ack0 <= cs;
	ack1 <= ack0 & cs;
end
always @(posedge p1_clk_i)
begin
	p1_ack0 <= p1_cs;
	p1_ack1 <= p1_ack0 & p1_cs;
end
assign cs = cyc_i && stb_i && adr_i[31:16]==17'b00001;
assign ack_o = cs & ack1;
assign p1_cs = p1_cyc_i && p1_stb_i && p1_adr_i[31:16]==17'b00001;
assign p1_ack_o = p1_cs & p1_ack1;

reg [64:0] rommem [0:8191];
initial begin
`include "..\..\software\source\bootrom.ver"
end

reg [15:3] radr,p1_radr;

always @(posedge clk_i)
	radr <= adr_i[15:3];
always @(posedge p1_clk_i)
	p1_radr <= p1_adr_i[15:3];

reg [63:0] dat1;
always @(posedge clk_i)
	if (cs)
		dat_o <= rommem[radr][63:0];
	else
		dat_o <= 64'd0;
//always @(negedge clk_i)
//	dat_o <= dat1;
reg [63:0] p1_dat1;
always @(posedge p1_clk_i)
	if (p1_cs)
		p1_dat_o <= rommem[p1_radr][63:0];
	else
		p1_dat_o <= 64'd0;

always @(posedge clk_i)
	if (cs)
		perr <= ^rommem[radr][63:0]!=rommem[radr][64];
	else
		perr <= 1'd0;

always @(posedge p1_clk_i)
	if (p1_cs)
		p1_perr <= ^rommem[p1_radr][63:0]!=rommem[p1_radr][64];
	else
		p1_perr <= 1'd0;

endmodule
