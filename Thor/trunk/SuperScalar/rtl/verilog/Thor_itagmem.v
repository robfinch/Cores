// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
//
// Thor SuperScalar
// Instruction cache tag memory
//
// ============================================================================
//
module Thor_itagmem(wclk, wce, wr, wa, err_i, invalidate, rclk, rce, pc, hit0, hit1, err_o);
parameter AMSB=63;
input wclk;
input wce;
input wr;
input [AMSB:0] wa;
input err_i;
input invalidate;
input rclk;
input rce;
input [AMSB:0] pc;
output hit0;
output hit1;
output err_o;

reg [AMSB:12] mem [0:127];
reg [0:127] tvalid;
reg [0:127] errmem;
reg [AMSB:0] rpc,rpcp16;
wire [AMSB-11:0] tag0,tag1;

always @(posedge wclk)
	if (wce & wr) mem[wa[11:5]] <= wa[AMSB:12];
always @(posedge wclk)
	if (invalidate) begin tvalid <= 128'd0; errmem <= 128'd0; end
	else if (wce & wr) begin tvalid[wa[11:5]] <= 1'b1; errmem[wa[11:5]] <= err_i; end
always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp16 <= pc + 64'd16;
assign tag0 = {mem[rpc[11:5]],tvalid[rpc[11:5]]};
assign tag1 = {mem[rpcp16[11:5]],tvalid[rpcp16[11:5]]};

assign hit0 = tag0 == {rpc[AMSB:12],1'b1};
assign hit1 = tag1 == {rpcp16[AMSB:12],1'b1};
assign err_o = errmem[rpc[11:5]]|errmem[rpcp16[11:5]];

endmodule
