`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2008-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//	Verilog 1995
//
// ============================================================================
//
module routerFifo(wrst, wclk, wr, di, rrst, rclk, rd, dout, cnt);
input wrst;
input wclk;
input wr;
input [127:0] di;
input rrst;
input rclk;
input rd;
output [127:0] dout;
output [3:0] cnt;
reg [3:0] cnt;

reg [3:0] wr_ptr;
reg [3:0] rd_ptr;
reg [127:0] mem [0:15];

wire [3:0] wr_ptr_p1 = wr_ptr + 8'd1;
wire [3:0] rd_ptr_p1 = rd_ptr + 8'd1;
reg [3:0] rd_ptrs;

always @(posedge wclk)
	if (wrst)
		wr_ptr <= 4'd0;
	else if (wr) begin
		mem[wr_ptr] <= di;
		wr_ptr <= wr_ptr_p1;
	end
always @(posedge wclk)		// synchronize read pointer to wclk domain
	rd_ptrs <= rd_ptr;

always @(posedge rclk)
	if (rrst)
		rd_ptr <= 4'd0;
	else if (rd)
		rd_ptr <= rd_ptr_p1;

assign dout = mem[rd_ptr[3:0]];

always @(wr_ptr or rd_ptrs)
	if (rd_ptrs > wr_ptr)
		cnt <= wr_ptr + (5'd16 - rd_ptrs);
	else
		cnt <= wr_ptr - rd_ptrs;

endmodule
