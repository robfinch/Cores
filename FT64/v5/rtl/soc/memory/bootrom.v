// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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
module bootrom(rst_i, clk_i, cti_i, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
parameter WID=64;
//parameter FNAME = "c:\\cores5\\FT64\\trunk\\software\\boot\\boot.ve0";
input rst_i;
input clk_i;
input [2:0] cti_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input [17:0] adr_i;
output [WID-1:0] dat_o;
reg [WID-1:0] dat_o;

integer n;

reg [WID-1:0] rommem [32767:0];
reg [14:0] radr;
reg [2:0] cnt;

initial begin
`include "d:\\cores5\\FT64\\v5\\software\\boot\\boottc.ve0";
end

wire cs = cs_i && cyc_i && stb_i;

reg rdy,rdy1,rdy2;
always @(posedge clk_i)
begin
	rdy1 <= cs;
	rdy <= rdy1 & cs & cnt!=3'b101;
end
assign ack_o = cs ? rdy : 1'b0;


wire pe_cs;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee() );

reg [14:0] ctr;
always @(posedge clk_i)
	if (pe_cs) begin
		if (cti_i==3'b000)
			ctr[1:0] <= adr_i[4:3];
		else
	    	ctr[1:0] <= adr_i[4:3] + 2'd1;
		ctr[14:2] <= adr_i[17:5];
		cnt <= 3'b00;
    end
	else if (cs && cnt!=3'b100 && cti_i != 3'b000) begin
		ctr <= ctr + 2'd1;
		cnt <= cnt + 3'd1;
	end

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[17:3] : ctr;

//assign dat_o = cs ? {smemH[radr],smemG[radr],smemF[radr],smemE[radr],
//				smemD[radr],smemC[radr],smemB[radr],smemA[radr]} : 64'd0;

always @(posedge clk_i)
	dat_o <= rommem[radr];

endmodule
