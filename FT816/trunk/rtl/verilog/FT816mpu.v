`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT816.v
//  - 16 bit CPU
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
`define TRUE 	1'b1
`define FALSE	1'b0

module FT816mpu(rst, clk, phi11, phi12, phi81, phi82, rdy, e, mx, nmi, irq, be, vpa, vda, mlb, vpb, rw, ad, db, cs0, cs1, cs2, cs3, cs4, cs5, cs6);
input rst;
input clk;
output phi11;
output phi12;
output phi81;
output phi82;
input rdy;
output e;
output mx;
input nmi;
input irq;
input be;
output vpa;
output vda;
output mlb;
output vpb;
output tri rw;
output tri [23:0] ad;
inout tri [7:0] db;
output cs0;
output cs1;
output cs2;
output cs3;
output cs4;
output cs5;
output cs6;

wire [4:0] cycle;
reg [15:0] dec_cs0;
reg [15:0] dec_cs1;
reg [15:0] dec_cs2;
reg [15:0] dec_cs3;
reg [8:0] dec_cs4;
reg [8:0] dec_cs5;
reg [7:0] mh1, mh8, mh32;
reg isRegEnabled;

reg phi1d;
always @(posedge clk)
	phi1d <= phi11;

wire match_cs0 = ad[23:8]==dec_cs0;
wire match_cs1 = ad[23:8]==dec_cs1;
wire match_cs2 = ad[23:8]==dec_cs2;
wire match_cs3 = ad[23:8]==dec_cs3;
wire match_cs4 = ad[23:15]==dec_cs4;
wire match_cs5 = ad[23:15]==dec_cs5;

wire dec_match1 = (match_cs0 & mh1[0]) |
				  (match_cs1 & mh1[1]) |
				  (match_cs2 & mh1[2]) |
				  (match_cs3 & mh1[3]) |
				  (match_cs4 & mh1[4]) |
				  (match_cs5 & mh1[5])
				  ;
wire dec_match8 = (match_cs0 & mh8[0]) |
				  (match_cs1 & mh8[1]) |
				  (match_cs2 & mh8[2]) |
				  (match_cs3 & mh8[3]) |
				  (match_cs4 & mh8[4]) |
				  (match_cs5 & mh8[5])
				  ;
wire dec_match32 = (match_cs0 & mh32[0]) |
				  (match_cs1 & mh32[1]) |
				  (match_cs2 & mh32[2]) |
				  (match_cs3 & mh32[3]) |
				  (match_cs4 & mh32[4]) |
				  (match_cs5 & mh32[5])
				  ;


always @(posedge clk)
if (rst) begin
	isRegEnabled <= `TRUE;
	dec_cs0 <= 16'h00D0;
	dec_cs1 <= 16'h00D1;
	dec_cs2 <= 16'h00D2;
	dec_cs3 <= 16'h00D3;
	dec_cs4 <= 9'h01;
	dec_cs5 <= 9'h02;
	mh1 <= 8'h0F;
	mh8 <= 8'h30;
	mh32 <= 8'h00;
end
else begin
	if (vda && ad[23:8]==16'hF0 && isRegEnabled && ~rw) begin
		case(ad[3:0])
		4'h0:	dec_cs0[7:0] <= db;
		4'h1:	dec_cs0[15:8] <= db;
		4'h2:	dec_cs1[7:0] <= db;
		4'h3:	dec_cs1[15:8] <= db;
		4'h4:	dec_cs2[7:0] <= db;
		4'h5:	dec_cs2[15:8] <= db;
		4'h6:	dec_cs3[7:0] <= db;
		4'h7:	dec_cs3[15:8] <= db;
		4'h8:	dec_cs4[7:0] <= db;
		4'h9:	dec_cs4[8] <= db[0];
		4'hA:	dec_cs5[7:0] <= db;
		4'hB:	dec_cs5[8] <= db[0];
		4'hC:	mh1 <= db;
		4'hD:	mh8 <= db;
		4'hE:	mh32 <= db;
		4'hF:	if (db==8'hE0)
					isRegEnabled <= `FALSE;
		endcase
	end
end

reg trig1;
reg trig8;
always @(posedge clk)
begin
	if (cycle==5'd0 & dec_match1 & (vpa | vda))
		trig1 <= `TRUE;
	if (cycle==5'd30 && rdy)
		trig1 <= `FALSE;
	if ((cycle==5'd0 || cycle==5'd8 || cycle==5'd16 || cycle==5'd24) & dec_match8 & (vpa | vda))
		trig8 <= `TRUE;
	if ((cycle==5'd6 || cycle==5'd14 || cycle==5'd22 || cycle==5'd30) && rdy)
		trig8 <= `FALSE;
end

assign cs0 = !((trig1 & match_cs0 & mh1[0]) | (trig8 & match_cs0 & mh8[0]) | (match_cs0 & mh32[0]));
assign cs1 = !((trig1 & match_cs1 & mh1[1]) | (trig8 & match_cs1 & mh8[1]) | (match_cs0 & mh32[1]));
assign cs2 = !((trig1 & match_cs2 & mh1[2]) | (trig8 & match_cs2 & mh8[2]) | (match_cs0 & mh32[2]));
assign cs3 = !((trig1 & match_cs3 & mh1[3]) | (trig8 & match_cs3 & mh8[3]) | (match_cs0 & mh32[3]));
assign cs4 = !((trig1 & match_cs4 & mh1[4]) | (trig8 & match_cs4 & mh8[4]) | (match_cs0 & mh32[4]));
assign cs5 = !((trig1 & match_cs5 & mh1[5]) | (trig8 & match_cs5 & mh8[5]) | (match_cs0 & mh32[5]));
assign cs6 = !(match_cs0 & match_cs1 & match_cs2 & match_cs3 & match_cs4 & match_cs5 & (vda | vpa));

wire rdy816 = (vda|vpa) ? (
			  dec_match1 ? trig1 && (cycle==5'd30) && rdy :
			  dec_match8 ? trig8 && (cycle==5'd30 || cycle==5'd22 || cycle==5'd14 || cycle==5'd6) && rdy :
				rdy) : 1'b1;

FT816 u1
(
	.rst(rst),
	.clk(clk),
	.nmi(nmi),
	.irq(irq),
	.e(e),
	.mx(mx),
	.cyc(cycle),
	.phi11(phi11),
	.phi12(phi12),
	.phi81(phi81),
	.phi82(phi82),
	.mlb(mlb),
	.vpb(vpb),
	.rdy(rdy816),
	.be(be),
	.vpa(vpa),
	.vda(vda),
	.rw(rw),
	.ad(ad),
	.db(db),
	.err_i(1'b0),
	.rty_i(1'b0)
);

endmodule
