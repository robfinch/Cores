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
module bootrom(rst_i, clk_i,
	cti_i, bok_o, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o,
	cti1_i, bok1_o, cs1_i, cyc1_i, stb1_i, ack1_o, adr1_i, dat1_o
);
parameter WID=64;
parameter BLEN = 3'b000;
//parameter FNAME = "c:\\cores5\\FT64\\trunk\\software\\boot\\boot.ve0";
input rst_i;
input clk_i;
input [2:0] cti_i;
input cs_i;
input cyc_i;
input stb_i;
output bok_o;
output reg ack_o;
input [17:0] adr_i;
output [WID-1:0] dat_o;
reg [WID-1:0] dat_o = 64'd0;
input [2:0] cti1_i;
input cs1_i;
input cyc1_i;
input stb1_i;
output bok1_o;
output reg ack1_o;
input [17:0] adr1_i;
output [WID-1:0] dat1_o;
reg [WID-1:0] dat1_o = 64'd0;

integer n;

(* ram_style="block" *)
reg [WID-1:0] rommem [14335:0];
reg [14:0] radr;
reg [14:0] radr1;
reg [14:0] ctr, ctr1;
reg [2:0] cnt, cnt1;

initial begin
`include "d:\\cores6\\Petajon\\v1\\software\\boot\\boot.ve0";
end

wire cs = cs_i && cyc_i && stb_i;
wire cs1 = cs1_i && cyc1_i && stb1_i;

reg rdy = 1'b0, rdy1 = 1'b0;
always @(posedge clk_i)
begin
	rdy1 <= cs;
	rdy <= rdy1 & cs;
end
always @(posedge clk_i)
	ack_o <= cs ? rdy : 1'b0;
assign bok_o = cs;

reg rdya = 1'b0, rdya1 = 1'b0;
always @(posedge clk_i)
begin
	rdya1 <= cs1;
	rdya <= rdya1 & cs1;
end
always @(posedge clk_i)
	ack1_o <= cs1 ? rdya : 1'b0;
assign bok1_o = cs1;

wire pe_cs;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee() );
wire pe_cs1;
edge_det u2(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs1), .pe(pe_cs1), .ne(), .ee() );

always @(posedge clk_i)
if (rst_i)
	ctr <= 3'd0;
else begin
	if (pe_cs) begin
		if (cti_i==3'b000)
			ctr <= adr_i[17:3];
		else
	    ctr <= adr_i[17:3] + 2'd1;
  end
	else if (cs && cnt < BLEN && cti_i != 3'b000)
		ctr <= ctr + 2'd1;
end

always @(posedge clk_i)
if (rst_i)
	ctr1 <= 3'd0;
else begin
	if (pe_cs1) begin
		if (cti1_i==3'b000)
			ctr1 <= adr1_i[17:3];
		else
	    ctr1 <= adr1_i[17:3] + 2'd1;
  end
	else if (cs1 && cnt1 < BLEN && cti1_i != 3'b000)
		ctr1 <= ctr1 + 2'd1;
end

always @(posedge clk_i)
if (rst_i)
	cnt <= 3'd0;
else begin
	if (pe_cs)
		cnt <= 3'b0;
	else if (cs && cnt < BLEN && cti_i != 3'b000)
		cnt <= cnt + 3'd1;
end

always @(posedge clk_i)
if (rst_i)
	cnt1 <= 3'd0;
else begin
	if (pe_cs1)
		cnt1 <= 3'b0;
	else if (cs1 && cnt1 < BLEN && cti1_i != 3'b000)
		cnt1 <= cnt1 + 3'd1;
end

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[17:3] : ctr;
always @(posedge clk_i)
	radr1 <= pe_cs1 ? adr1_i[17:3] : ctr1;

//assign dat_o = cs ? {smemH[radr],smemG[radr],smemF[radr],smemE[radr],
//				smemD[radr],smemC[radr],smemB[radr],smemA[radr]} : 64'd0;

reg [WID-1:0] dat = 64'd0;
always @(posedge clk_i)
	dat <= rommem[radr];
always @(posedge clk_i)
	dat_o <= dat;

reg [WID-1:0] dat1 = 64'd0;
always @(posedge clk_i)
	dat1 <= rommem[radr1];
always @(posedge clk_i)
	dat1_o <= dat1;

endmodule
