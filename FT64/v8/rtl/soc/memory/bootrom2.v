// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// bootrom2.v
// - bootrom without pipelined burst mode
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
module bootrom2(clk_i, cti_i, bok_o, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
parameter WID=64;
//parameter FNAME = "c:\\cores5\\FT64\\trunk\\software\\boot\\boottc.ve0";
input clk_i;
input [2:0] cti_i;
input cs_i;
input cyc_i;
input stb_i;
output bok_o;
output ack_o;
input [17:0] adr_i;
output [WID-1:0] dat_o;
reg [WID-1:0] dat_o;

integer n;

reg [WID-1:0] rommem [24577:0];
reg [14:0] radr;
reg [14:0] ctr;
reg [2:0] cnt;

initial begin
`include "d:\\cores5\\FT64\\v7\\software\\boot\\boottc.ve0";
end

wire cs = cs_i && cyc_i && stb_i;

ack_gen #(
	.READ_STAGES(4),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs),
	.we_i(1'b0),
	.o(ack_o)
);

assign bok_o = 1'b0;

always @(posedge clk_i)
	radr <= adr_i[17:3];

reg [WID-1:0] dat;
always @(posedge clk_i)
	dat <= rommem[radr];
always @(posedge clk_i)
	dat_o <= dat;

endmodule
