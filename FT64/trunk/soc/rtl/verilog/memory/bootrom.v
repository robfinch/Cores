// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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
module bootrom(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input [17:0] adr_i;
output [63:0] dat_o;
reg [63:0] dat_o;

integer n;

reg [63:0] rommem [32767:0];
reg [14:0] radr;


initial begin
`include "c:\\cores5\\FT64\\trunk\\software\\boot\\boot.ve0"
end

wire cs = cs_i && cyc_i && stb_i;

reg rdy,rdy1,rdy2;
always @(posedge clk_i)
begin
	rdy1 <= cs;
	rdy <= rdy1 & cs & adr_i[4:3]!=2'b11;
end
assign ack_o = cs ? rdy : 1'b0;


wire pe_cs;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee() );

reg [14:0] ctr;
always @(posedge clk_i)
	if (pe_cs)
		ctr <= adr_i[17:3] + 12'd1;
	else if (cs && ctr[1:0]!=2'b11)
		ctr <= ctr + 15'd1;

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[17:3] : ctr;

//assign dat_o = cs ? {smemH[radr],smemG[radr],smemF[radr],smemE[radr],
//				smemD[radr],smemC[radr],smemB[radr],smemA[radr]} : 64'd0;

always @(posedge clk_i)
	dat_o <= rommem[radr];

endmodule
