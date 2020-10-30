// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
// ============================================================================
//
module bootrom128(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
parameter WID=128;
parameter BLEN = 3'b000;
//parameter FNAME = "c:\\cores5\\FT64\\trunk\\software\\boot\\boottc.ve0";
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input [17:0] adr_i;
output [WID-1:0] dat_o;
reg [WID-1:0] dat_o = 128'd0;

integer n;

reg [WID-1:0] rommem [0:10239]; // 160k
reg [13:0] radr;

initial begin
`include "d:\\cores2020\\rtf64\\v2\\software\\boot\\rtf64-rom.ve0";
//`include "d:\\cores2020\\rtf64\\v2\\software\\examples\\fibonacci.ve0";
end

wire cs = cs_i && cyc_i && stb_i;

reg rdy = 1'b0, rdy1 = 1'b0;
always @(posedge clk_i)
begin
	rdy1 <= cs;
	rdy <= rdy1 & cs;
end
always @(posedge clk_i)
	ack_o <= cs ? rdy : 1'b0;

always @(posedge clk_i)
	radr <= adr_i[17:4];

//assign dat_o = cs ? {smemH[radr],smemG[radr],smemF[radr],smemE[radr],
//				smemD[radr],smemC[radr],smemB[radr],smemA[radr]} : 64'd0;

reg [WID-1:0] dat = 128'd0;
always @(posedge clk_i)
	dat <= rommem[radr];
always @(posedge clk_i)
	dat_o <= dat;

endmodule
