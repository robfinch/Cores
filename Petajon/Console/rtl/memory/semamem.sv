// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	semamem.sv
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
// Sixty-four semaphores occupy a 2kB block of memory
//
// Address
// 0b0nnnnnnaaaa		read: decrement by aaaa, write increment by aaaa
// 0b1nnnnnn----	  read: peek value, write absolute data
// ============================================================================

module semamem(rst, clk, 
	cs0, cyc0, stb0, ack0, wr0, ad0, i0, o0,
	cs1, cyc1, stb1, ack1, wr1, ad1, i1, o1
);
input rst;
input clk;
input cs0;
input cyc0;
input stb0;
output reg ack0;
input wr0;
input [10:0] ad0;
input [7:0] i0;
output [7:0] o0;
input cs1;
input cyc1;
input stb1;
output reg ack1;
input wr1;
input [10:0] ad1;
input [7:0] i1;
output [7:0] o1;

reg wr;
reg [10:0] ad;
reg [7:0] i;
wire sel0 = cs0 & cyc0 & stb0;
wire sel1 = cs1 & cyc1 & stb1;

always @(posedge clk)
begin
	if (sel0)
		wr <= wr0;
	else if (sel1)
		wr <= wr1;
	else
		wr <= 1'b0;
end
always @(posedge clk)
begin
	if (sel0)
		ad <= ad0;
	else if (sel1)
		ad <= ad1;
	else
		ad <= ad;
end
always @(posedge clk)
begin
	if (sel0)
		i <= i0;
	else if (sel1)
		i <= i1;
	else
		i <= i;
end
always @(posedge clk)
begin
	if (sel0)
		ack0 <= sel0;
	else if (sel1)
		ack1 <= sel1;
	else begin
		ack0 <= 1'b0;
		ack1 <= 1'b0;
	end
end

reg [7:0] mem [0:63];
reg [7:0] memi;
wire [7:0] memo = mem[ad[9:4]];
wire [8:0] memopi = memo + ad[3:0];
wire [8:0] memomi = memo - ad[3:0];
assign o0 = memo;
assign o1 = memo;

wire pe_cs;
edge_det ued1 (.rst(rst), .clk(clk), .ce(1'b1), .i(cs & cyc & stb), .pe(pe_cs), .ne(), .ee());
always @(posedge clk)
if (pe_cs)
	mem[ad[9:4]] <= memi;

always @*
begin
	casez({ad,wr})
	12'b0??????????0:	memi <= memomi[8] ? 8'h00 : memomi[7:0];
	12'b0??????????1:	memi <= memopi[8] ? 8'hFF : memopi[7:0];
	12'b1??????????0:	memi <= memo;
	12'b1??????????1:	memi <= i;
	endcase
end

endmodule

