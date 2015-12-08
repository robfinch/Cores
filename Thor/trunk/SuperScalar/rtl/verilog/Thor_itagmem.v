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
module Thor_itagmem(wclk, wce, wr, wa, err_i, invalidate, invalidate_line, invalidate_lineno, 
    rclk, rce, pc, hit0, hit1, err_o);
parameter AMSB=63;
input wclk;
input wce;
input wr;
input [AMSB:0] wa;
input err_i;
input invalidate;
input invalidate_line;
input [AMSB:0] invalidate_lineno;
input rclk;
input rce;
input [AMSB:0] pc;
output hit0;
output hit1;
output err_o;

reg [AMSB:15] mem [0:1023];
reg [0:1023] tvalid;
reg [0:1023] errmem;
reg [AMSB:0] rpc,rpcp16;
wire [AMSB-13:0] tag0,tag1;

integer n;
initial begin
	for (n = 0; n < 1024; n = n + 1)
		mem[n] <= 0;
end

always @(posedge wclk)
	if (wce & wr) mem[wa[14:5]] <= wa[AMSB:15];
always @(posedge wclk)
	if (invalidate) begin tvalid <= 1024'd0; errmem <= 1024'd0; end
	else if (invalidate_line) tvalid[invalidate_lineno[14:5]] <= 1'b0;
	else if (wce & wr) begin tvalid[wa[14:5]] <= 1'b1; errmem[wa[14:5]] <= err_i; end
always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp16 <= pc + 64'd16;
assign tag0 = {mem[rpc[14:5]],tvalid[rpc[14:5]]};
assign tag1 = {mem[rpcp16[14:5]],tvalid[rpcp16[14:5]]};

assign hit0 = tag0 == {rpc[AMSB:15],1'b1};
assign hit1 = tag1 == {rpcp16[AMSB:15],1'b1};
assign err_o = errmem[rpc[14:5]]|errmem[rpcp16[14:5]];

endmodule
