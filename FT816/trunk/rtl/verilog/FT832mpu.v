`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT832mpu.v
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

module FT832mpu(rst, clk, clko, phi11, phi12, phi81, phi82, rdy, e, mx, nmi, irq, abort, be, vpa, vda, mlb, vpb,
    rw, ad, db, cs0, cs1, cs2, cs3, cs4, cs5, cs6, ct0, ct1, ct2);
parameter pIOAddress = 32'h0000B000;
parameter pZPAddress = 32'h00000010;
input rst;
input clk;
output clko;
output phi11;
output phi12;
output phi81;
output phi82;
input rdy;
output e;
output mx;
input nmi;
input irq;
input abort;
input be;
output vpa;
output vda;
output mlb;
output vpb;
output tri rw;
output tri [31:0] ad;
inout tri [7:0] db;
output cs0;
output cs1;
output cs2;
output cs3;
output cs4;
output cs5;
output cs6;
input ct0;
input ct1;
input ct2;

wire ivda;
wire [4:0] cycle;
reg [15:0] dec_cs0;
reg [15:0] dec_cs1;
reg [15:0] dec_cs2;
reg [15:0] dec_cs3;
reg [8:0] dec_cs4;
reg [8:0] dec_cs5;
reg [7:0] mh1, mh8, mh32;
reg isRegEnabled;
reg cntIrq0,cntIrqEn0;
reg cntIrq1,cntIrqEn1;
reg cntIrq2,cntIrqEn2;
reg cntUp0,cntUp1,cntUp2;
reg [23:0] cntLimit0;
reg [23:0] realCnt0;
reg autoCnt0,cntTrig0;
reg [23:0] cntLimit1;
reg [23:0] realCnt1;
reg autoCnt1,cntTrig1;
reg [23:0] cntLimit2;
reg [23:0] realCnt2;
reg autoCnt2,cntTrig2;
reg [1:0] cntSrc0,cntSrc1,cntSrc2;
reg [7:0] zp_shadow [15:0];

reg phi1d;
always @(posedge clko)
	phi1d <= phi11;

wire match_cs0 = ad[31:8]==dec_cs0;
wire match_cs1 = ad[31:8]==dec_cs1;
wire match_cs2 = ad[31:8]==dec_cs2;
wire match_cs3 = ad[31:8]==dec_cs3;
wire match_cs4 = ad[31:15]==dec_cs4;
wire match_cs5 = ad[31:15]==dec_cs5;

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


wire iirq = !((cntIrqEn0 & cntIrq0) || 
			(cntIrqEn1 & cntIrq1) || 
			(cntIrqEn2 & cntIrq2)) &&
			irq
			;

reg [7:0] shadow_ram [31:0];

always @(posedge clko)
if (~rst) begin
	isRegEnabled <= `TRUE;
	dec_cs0 <= 16'h00D0;
	dec_cs1 <= 16'h00D1;
	dec_cs2 <= 16'h00D2;
	dec_cs3 <= 16'h00D3;
	dec_cs4 <= 9'h001;
	dec_cs5 <= 9'h002;
	mh1 <= 8'h0F;
	mh8 <= 8'h30;
	mh32 <= 8'h00;
	cntIrqEn0 <= 1'b0;
	cntIrqEn1 <= 1'b0;
	cntIrqEn2 <= 1'b0;
	cntIrq0 <= 1'b0;
	cntIrq1 <= 1'b0;
	cntIrq2 <= 1'b0;
	cntSrc0 <= 2'b00;
	cntSrc1 <= 2'b00;
	cntSrc2 <= 2'b00;
	cntTrig0 <= 1'b0;
	cntTrig1 <= 1'b0;
	cntTrig2 <= 1'b0;
	cntUp0 <= 1'b1;
	cntUp1 <= 1'b1;
	cntUp2 <= 1'b1;
end
else begin
	cntTrig0 <= 1'b0;
	cntTrig1 <= 1'b0;
	cntTrig2 <= 1'b0;
	if (cntSrc0==2'b01 || cntTrig0 || (cntSrc0==2'b10 && ct0))
		realCnt0 <= cntUp0 ? realCnt0 + 24'd1 : realCnt0 - 24'd1;
	if (cntSrc1==2'b01 || cntTrig1 || (cntSrc1==2'b10 && ct1))
		realCnt1 <= cntUp1 ? realCnt1 + 24'd1 : realCnt1 - 24'd1;
	if (cntSrc2==2'b01 || cntTrig2 || (cntSrc2==2'b10 && ct2))
		realCnt2 <= cntUp2 ? realCnt2 + 24'd1 : realCnt2 - 24'd1;
	if (((cntUp0 && realCnt0==cntLimit0) || (!cntUp0 && realCnt0==24'd0)) && cntIrqEn0)
		cntIrq0 <= 1'b1;
	if (((cntUp0 && realCnt0==cntLimit0) || (!cntUp0 && realCnt0==24'd0)))
		realCnt0 <= cntUp0 ? 24'd0 : cntLimit0;
	if (((cntUp1 && realCnt1==cntLimit1) || (!cntUp1 && realCnt1==24'd0)) && cntIrqEn1)
		cntIrq1 <= 1'b1;
	if (((cntUp1 && realCnt1==cntLimit1) || (!cntUp1 && realCnt1==24'd0)))
		realCnt1 <= cntUp1 ? 24'd0 : cntLimit1;
	if (((cntUp2 && realCnt2==cntLimit2) || (!cntUp2 && realCnt2==24'd0)) && cntIrqEn2)
		cntIrq2 <= 1'b1;
	if (((cntUp2 && realCnt2==cntLimit2) || (!cntUp2 && realCnt2==24'd0)))
		realCnt2 <= cntUp2 ? 24'd0 : cntLimit2;
	if (ivda && ad[31:8]==pIOAddress[31:8] && isRegEnabled && ~rw) begin
		shadow_ram[ad[4:0]] <= db;
		case(ad[4:0])
		5'h00:	dec_cs0[7:0] <= db;
		5'h01:	dec_cs0[15:8] <= db;
		5'h02:	dec_cs1[7:0] <= db;
		5'h03:	dec_cs1[15:8] <= db;
		5'h04:	dec_cs2[7:0] <= db;
		5'h05:	dec_cs2[15:8] <= db;
		5'h06:	dec_cs3[7:0] <= db;
		5'h07:	dec_cs3[15:8] <= db;
		5'h08:	dec_cs4[7:0] <= db;
		5'h09:	dec_cs4[8] <= db[0];
		5'h0A:	dec_cs5[7:0] <= db;
		5'h0B:	dec_cs5[8] <= db[0];
		5'h0C:	mh1 <= db;
		5'h0D:	mh8 <= db;
		5'h0E:	mh32 <= db;
		5'h0F:	if (db==8'hE0)
					isRegEnabled <= `FALSE;
		5'h10:	cntLimit0[7:0] <= db;
		5'h11:	cntLimit0[15:8] <= db;
		5'h12:	cntLimit0[23:16] <= db;
		5'h13:	begin
				cntIrqEn0 <= db[0];
				cntIrq0 <= 1'b0;
				cntSrc0 <= db[3:2];
				cntUp0 <= db[4];
				end
		5'h14:	cntLimit1[7:0] <= db;
		5'h15:	cntLimit1[15:8] <= db;
		5'h16:	cntLimit1[23:16] <= db;
		5'h17:	begin
				cntIrqEn1 <= db[0];
				cntIrq1 <= 1'b0;
				cntSrc1 <= db[3:2];
				cntUp1 <= db[4];
				end
		5'h18:	cntLimit2[7:0] <= db;
		5'h19:	cntLimit2[15:8] <= db;
		5'h1A:	cntLimit2[23:16] <= db;
		5'h1B:	begin
				cntIrqEn2 <= db[0];
				cntIrq2 <= 1'b0;
				cntSrc2 <= db[3:2];
				cntUp2 <= db[4];
				end
		5'h1C:	cntTrig0 <= 1'b1;
		5'h1D:	cntTrig1 <= 1'b1;
		5'h1E:	cntTrig2 <= 1'b1;
		endcase
	end
	if (ivda && ad[31:4]==pZPAddress[31:4] && ~rw) begin
		zp_shadow[ad[3:0]] <= db;
		case(ad[3:0])
		4'h0:	realCnt0[7:0] <= db;
		4'h1:	realCnt0[15:8] <= db;
		4'h2:	realCnt0[23:16] <= db;
		4'h4:	realCnt1[7:0] <= db;
		4'h5:	realCnt1[15:8] <= db;
		4'h6:	realCnt1[23:16] <= db;
		4'h8:	realCnt2[7:0] <= db;
		4'h9:	realCnt2[15:8] <= db;
		4'hA:	realCnt2[23:16] <= db;
		endcase
	end
end

reg [7:0] dbo1;
always @(ad or realCnt0 or realCnt1 or realCnt2)
case(ad[3:0])
4'h0:	dbo1 <= realCnt0[7:0];
4'h1:	dbo1 <= realCnt0[15:8];
4'h2:	dbo1 <= realCnt0[23:16];
4'h4:	dbo1 <= realCnt1[7:0];
4'h5:	dbo1 <= realCnt1[15:8];
4'h6:	dbo1 <= realCnt1[23:16];
4'h8:	dbo1 <= realCnt2[7:0];
4'h9:	dbo1 <= realCnt2[15:8];
4'hA:	dbo1 <= realCnt2[23:16];
default:	dbo1 <= zp_shadow[ad[3:0]];
endcase

wire cs_mpu = (ivda && ad[31:4]==pZPAddress[31:4]) || (ivda && ad[31:8]==pIOAddress[31:8]);
assign db = (ivda && ad[31:4]==pZPAddress[31:4] && rw) ? dbo1 : {8{1'bz}};
assign db =	(ivda && ad[31:8]==pIOAddress[31:8] && rw) ? (
	ad[4:0]==5'h1F ? {cntIrq2,cntIrq1,cntIrq0} :
	shadow_ram[ad[4:0]] ) :
	{8{1'bz}};
assign vda = !cs_mpu & ivda;

reg trig1;
reg trig8;
always @(posedge clko)
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
assign cs1 = !((trig1 & match_cs1 & mh1[1]) | (trig8 & match_cs1 & mh8[1]) | (match_cs1 & mh32[1]));
assign cs2 = !((trig1 & match_cs2 & mh1[2]) | (trig8 & match_cs2 & mh8[2]) | (match_cs2 & mh32[2]));
assign cs3 = !((trig1 & match_cs3 & mh1[3]) | (trig8 & match_cs3 & mh8[3]) | (match_cs3 & mh32[3]));
assign cs4 = !((trig1 & match_cs4 & mh1[4]) | (trig8 & match_cs4 & mh8[4]) | (match_cs4 & mh32[4]));
assign cs5 = !((trig1 & match_cs5 & mh1[5]) | (trig8 & match_cs5 & mh8[5]) | (match_cs5 & mh32[5]));
assign cs6 = !(!(match_cs0 | match_cs1 | match_cs2 | match_cs3 | match_cs4 | match_cs5) & (vda | vpa));

wire rdy832 = (vda|vpa) ? (
			  dec_match1 ? trig1 && (cycle==5'd30) && rdy :
			  dec_match8 ? trig8 && (cycle==5'd30 || cycle==5'd22 || cycle==5'd14 || cycle==5'd6) && rdy :
				rdy) : 1'b1;

FT832 u1
(
	.rst(rst),
	.clk(clk),
	.clko(clko),
	.nmi(nmi),
	.irq(iirq),
	.abort(abort),
	.e(e),
	.mx(mx),
	.cyc(cycle),
	.phi11(phi11),
	.phi12(phi12),
	.phi81(phi81),
	.phi82(phi82),
	.mlb(mlb),
	.vpb(vpb),
	.rdy(rdy832),
	.be(be),
	.vpa(vpa),
	.vda(ivda),
	.rw(rw),
	.ad(ad),
	.db(db),
	.err_i(1'b0),
	.rty_i(1'b0)
);

endmodule
