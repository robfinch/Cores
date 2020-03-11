// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	mutex.sv
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
// If the mutex is unlocked (bit 1 = 0) any requester can write to it.
// Bit 1 of the write data should be set to lock the mutex.
// 
// ============================================================================

module mutex(rst, clk,
	cs0, cyc0, stb0, ack0, wr0, ad0, i0, o0,
	cs1, cyc1, stb1, ack1, wr1, ad1, i1, o1
);
input rst;
input clk;
input cs0;
input cyc0;
input stb0;
output ack0;
input wr0;
input [7:0] ad0;
input [63:0] i0;
output reg [63:0] o0;
input cs1;
input cyc1;
input stb1;
output ack1;
input wr1;
input [7:0] ad1;
input [63:0] i1;
output reg [63:0] o1;

wire sel0 = cs0 & cyc0 & stb0;
wire sel1 = cs1 & cyc1 & stb1;

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag0
(
	.clk_i(clk),
	.ce_i(1'b1),
	.i(sel0 && ch==4'd0),
	.we_i(sel0 && wr0 && ch==4'd0),
	.o(ack0)
);

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(clk),
	.ce_i(1'b1),
	.i(cs1 && ch==4'd1),
	.we_i(cs1 && wr1 && ch==4'd1),
	.o(ack1)
);

integer n;
reg [3:0] ch;
reg wr;
reg [7:0] ad;
reg [63:0] memi;
reg [63:0] mem [0:31];

initial begin
	for (n = 0; n < 32; n = n + 1)
		mem[n] <= 64'd0;
end

reg [2:0] state;
parameter IDLE = 3'd0;
parameter ACTIVE = 3'd1;
always @(posedge clk)
if (rst)
	state <= IDLE;
else begin
case (state)
IDLE:
	if (sel0)
		state <= ACTIVE;
	else if (sel1)
		state <= ACTIVE;
ACTIVE:
	if (!sel0 && ch==4'd0)
		state <= IDLE;
	else if (!sel1 && ch==4'd1)
		state <= IDLE;
	else if (!sel0 && !sel1)
		state <= IDLE;
default:
	state <= IDLE;
endcase
end

always @(posedge clk)
begin
case(state)
IDLE:
	if (sel0)
		ch <= 4'd0;
	else if (sel1)
		ch <= 4'd1;
	else
		ch <= 4'd15;
endcase
end
always @(posedge clk)
begin
	if (ch==4'd0)
		wr <= wr0;
	else if (ch==4'd1)
		wr <= wr1;
	else
		wr <= 1'b0;
end
always @(posedge clk)
begin
	if (ch==4'd0)
		ad <= ad0;
	else if (ch==4'd1)
		ad <= ad1;
	else
		ad <= ad;
end
always @(posedge clk)
begin
	if (ch==4'd0)
		memi <= i0;
	else if (ch==4'd1)
		memi <= i1;
	else
		memi <= memi;
end
always @(posedge clk)
begin
	if (ch==4'd0)
		o0 <= mem[ad[7:3]];
	else if (ch==4'd1)
		o1 <= mem[ad[7:3]];
	else begin
		o0 <= 32'd0;
		o1 <= 32'd0;
	end
end

always @(posedge clk)
	if (wr && mem[ad[7:3]][0]==1'b0)
		mem[ad[7:3]] <= memi;
	else if (wr && mem[ad[7:3]][16:1]==memi[16:1] && ch==memi[20:17])
		mem[ad[7:3]] <= memi;

endmodule
