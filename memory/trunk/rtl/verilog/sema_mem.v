`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//  
//	sema_mem.v
//  - semaphoric memory
//  - 1024 8-bit semaphores
//  - the semaphore is incremented (store) or decremented (load) by a
//    constant found on the low order four address bits.
//
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
//
//=============================================================================
//
module sema_mem(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [31:0] adr_i;
input [7:0] dat_i;
output [7:0] dat_o;
reg [7:0] dat_o;

reg ack,ack1,ack2,ack3;

wire cs = cyc_i && stb_i && (adr_i[31:16]==16'hFFDB);
assign ack_o = ack & cs;
wire pe_ack1,pe_cs;
wire [7:0] rd,wd;
reg [7:0] rrd;

reg [7:0] mem [0:1023];
reg [15:6] radr;

edge_det u1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(ack1), .pe(pe_ack1), .ne(), .ee());
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee());

wire wr = (cs && (adr_i[5:2]!=4'h0) && ack1 && ~ack2) || (pe_cs && we_i && (adr_i[5:2]==4'h0));

// Compute saturated sum and difference
wire [8:0] sum1 = rd + adr_i[5:2];
wire [7:0] sum = sum1[8] ? 8'hFF : sum1;
wire [8:0] dif1 = rd - adr_i[5:2];
wire [7:0] dif = dif1[8] ? 8'h00 : dif1;
assign wd = we_i ? sum : dif;
assign rd = mem[radr];

always @(posedge clk_i)
begin
	ack1 <= cs;
	ack2 <= ack1 & cs;
	ack3 <= ack2 & cs;
	ack <= ack3 & cs;
end

always @(posedge clk_i)
	if (wr)
		mem[adr_i[15:6]] <= ack1 ? wd : dat_i;
always @(posedge clk_i) radr <= adr_i[15:6];		// register read address
always @(posedge clk_i)								// read the pre-update data
	if (pe_ack1) rrd <= mem[radr];

always @(posedge clk_i)
	dat_o <= cs ? rrd : 8'h0;

endmodule

