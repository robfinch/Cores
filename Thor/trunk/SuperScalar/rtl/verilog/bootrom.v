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
parameter DBW=64;
parameter MAGIC1=32'hAAAAAAAA;
parameter MAGIC2=32'h55555555;
input rst_i;
input clk_i;
input [2:0] cti_i;
input cyc_i;
input stb_i;
output ack_o;
input [31:0] adr_i;
output [DBW-1:0] dat_o;
reg [DBW-1:0] dat_o;
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

reg [DBW:0] rommem0 [0:8191];
reg [DBW:0] rommem1 [0:8191];
reg [DBW:0] rommem2 [0:8191];
initial begin
if (DBW==32) begin
`include "..\..\software\A64\bin\boot.ve0"
`include "..\..\software\A64\bin\boot.ve1"
`include "..\..\software\A64\bin\boot.ve2"
end
else begin
`include "..\..\software\a64\bin\boot.ve0"
`include "..\..\software\A64\bin\boot.ve1"
`include "..\..\software\A64\bin\boot.ve2"
end
end

wire pe_cs;
edge_det u1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee());
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(pe_cs), .pe(), .ne(ne_cs), .ee());

reg [14:2] radr;
reg [14:2] ctr;

always @(posedge clk_i)
	if (pe_cs) begin
		if (DBW==32)
			ctr <= adr_i[14:2] + 13'd1;
		else
			ctr <= adr_i[14:3] + 13'd1;
	end
	else if (cs)
		ctr <= ctr + 13'd1;

always @(posedge clk_i)
	if (DBW==32)
		radr <= pe_cs ? adr_i[14:2] : ctr;
	else
		radr <= pe_cs ? adr_i[14:3] : ctr;

wire [31:0] d0 = rommem0[radr][DBW-1:0];
wire [31:0] d1 = rommem1[radr][DBW-1:0]^MAGIC1;
wire [31:0] d2 = rommem2[radr][DBW-1:0]^MAGIC2;
wire [31:0] d4 = (d0&d1)|(d0&d2)|(d1&d2);

always @(posedge clk_i)
	if (cs) begin
		dat_o <= d4;
		$display("br read: %h %h", radr,d4); 
	end
	else
		dat_o <= {DBW{1'b0}};

always @(posedge clk_i)
	if (cs)
		perr <= ^rommem0[radr][DBW-1:0]!=rommem0[radr][DBW];
	else
		perr <= 1'd0;

endmodule
