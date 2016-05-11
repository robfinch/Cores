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
module Thor_dtagmem(wclk, wce, wr, wa, err_i, invalidate, invalidate_line, invalidate_lineno, 
    rclk, rce, ra, whit, rhit, err_o);
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
input [AMSB:0] ra;
output whit;
output rhit;
output err_o;

reg [AMSB:13] mem [0:255];
reg [0:255] tvalid;
reg [0:255] errmem;
reg [AMSB:0] rwa,rra;
wire [AMSB-12:0] tag,wtag;

integer n;
initial begin
	for (n = 0; n < 256; n = n + 1)
		mem[n] <= 0;
end

always @(posedge wclk)
	if (wce & wr) begin
		$display("*******************");
		$display("*******************");
		$display("Writint %h to %h ",wa[AMSB:13],wa[12:5]);
		mem[wa[12:5]] <= wa[AMSB:13];
		$display("*******************");
		$display("*******************");
	end
always @(posedge wclk)
	if (invalidate) begin tvalid <= 256'd0; errmem <= 256'd0; end
	// should set errmem to zero here
	else if (invalidate_line) tvalid[invalidate_lineno[12:5]] <= 1'b0;
	else if (wce & wr) begin tvalid[wa[12:5]] <= 1'b1; errmem[wa[12:5]] <= err_i; end
always @(posedge rclk)
	if (rce) rwa <= wa;
always @(posedge rclk)
	if (rce) rra <= ra;
assign wtag = {mem[rwa[12:5]],tvalid[rwa[12:5]]};
assign tag = {mem[rra[12:5]],tvalid[rra[12:5]]};

assign whit = wtag == {rwa[AMSB:13],1'b1};
assign rhit = tag == {rra[AMSB:13],1'b1};
assign err_o = errmem[rra[12:5]];

endmodule
