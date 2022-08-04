`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007,2012-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	IntCtrl.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// Contains
//	8 event timers
//	2 date-time trackers	(1 earth, 1 mars)
//	vector pull interrupt control
// ============================================================================
//
//
module IntCtrl(sysclk, ph2, rw, vpa, vda, vpb, wa0to6, wa12to15, ba, smemru, smemwu, memru, memwu, iordu, iowru,
	irq1, irq2, irq3, irq4, irq5, irq6, irq7, irq9, irq10, irq11, irq12, irq14, irq15, irq );
input sysclk;
input ph2;
input rw;
input vpa;
input vda;
input vpb;
input [6:0] wa0to6;
input [3:0] wa12to15;
inout tri [7:0] ba;
output smemru;
output smemwu;
output memru;
output memwu;
output iordu;
output iowru;
input irq1;
input irq2;
input irq3;
input irq4;
input irq5;
input irq6;
input irq7;
input irq9;
input irq10;
input irq11;
input irq12;
input irq14;
input irq15;
output irq;

wire irq0;
wire clk50, clk100;
wire locked;
wire rst;
reg [7:0] ba100a, ba100b, ba100c;
reg [7:0] vec;

wire [15:0] ad = {wa12to15,5'd0,wa0to6};
reg [23:0] rstcnt = 24'h0;
always_ff @(posedge sysclk)
	rstcnt <= rstcnt + 2'd1;
wire xrst = ~rstcnt[15];

IntCtrlClkwiz ucw1
(
  // Clock out ports
  .clk100(clk100),
  .clk50(clk50),
  // Status and control signals
  .reset(xrst),
  .locked(locked),
 // Clock in ports
  .sysclk(sysclk)
);

reg [7:0] ba100;
reg [9:0] vech;
assign rst = !locked;
wire vpda = vda|vpa;
wire ne_ph2;
edge_det ed1 (.rst(rst), .ce(1'b1), .clk(clk100), .i(ph2), .pe(), .ne(ne_ph2), .ee());

always_ff @(posedge clk100)
begin
	if (ne_ph2)
		ba100 <= ba;
end

assign iordu = ~(ph2 &&  rw && vda && ba100==8'hD0);	// $D0xxxx
assign iowru = ~(ph2 && ~rw && vda && ba100==8'hD0);
assign smemru = ~(ph2 &&  rw && vpda && ba100[7:4]==4'h0 && {ba100[3:0],ad[15:12]}!=8'h0F);
assign smemwu = ~(ph2 && ~rw && vpda && ba100[7:4]==4'h0);
assign memru = ~(ph2 &&  rw && vpda && ~iordu);
assign memwu = ~(ph2 && ~rw && vpda && ~iowru);
wire csTimer1 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd0;
wire csTimer2 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd1;
wire csTimer3 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd2;
wire csTimer4 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd3;
wire csTimer5 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd4;
wire csTimer6 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd5;
wire csTimer7 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd6;
wire csTimer8 = {ba100,ad[15:12]}==12'hD10 && vda && ad[6:4]==3'd7;
wire csIRQ = {ba100,ad[15:12]}==12'hD20 && vda && ad[6:4]==3'd0;
wire csDatetime = {ba100,ad[15:12]}==12'hD30 && vda && ad[6]==1'b0;
wire csMarsDatetime = {ba100,ad[15:12]}==12'hD30 && vda && ad[6]==1'b1;

wire [7:0] tmr1do;
wire [7:0] tmr2do;
wire [7:0] tmr3do;
wire [7:0] tmr4do;
wire [7:0] tmr5do;
wire [7:0] tmr6do;
wire [7:0] tmr7do;
wire [7:0] tmr8do;
wire [7:0] tmrirq;

timer utmr1 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer1),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr1do),
	.irq(tmrirq[0])
);

timer utmr2 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer2),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr2do),
	.irq(tmrirq[1])
);

timer utmr3 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer3),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr3do),
	.irq(tmrirq[2])
);

timer utmr4 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer4),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr4do),
	.irq(tmrirq[3])
);

timer utmr5 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer5),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr5do),
	.irq(tmrirq[4])
);

timer utmr6 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer6),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr6do),
	.irq(tmrirq[5])
);

timer utmr7 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer7),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr7do),
	.irq(tmrirq[6])
);

timer utmr8 (
	.rst(rst),
	.clk(clk50),
	.ph2(ph2),
	.cs(csTimer8),
	.rw(rw),
	.ad(ad[2:0]),
	.dbi(ba),
	.dbo(tmr8do),
	.irq(tmrirq[7])
);

// Create 100 Hz Time of Day clock
reg [23:0] todcnt;
reg tod;
wire [7:0] dtdato,mdtdato;

always_ff @(posedge clk50)
if (rst) begin
	todcnt <= 24'd250000;
	tod <= 1'b0;
end
else begin
	todcnt <= todcnt - 2'd1;
	if (todcnt==24'd1) begin
		todcnt <= 24'd250000;
		tod <= ~tod;
	end
end

rfDatetimeSbi8 #(.pMars(1'b0)) udt1 (
	.rst_i(rst),
	.ph2_i(ph2),
	.cs_i(csDatetime),
	.rw_i(rw),
	.adr_i(ad[4:0]),
	.dat_i(ba),
	.dat_o(dtdato),
	.tod(tod),
	.alarm(irq8a)
);


rfDatetimeSbi8 #(.pMars(1'b1)) udt2 (
	.rst_i(rst),
	.ph2_i(ph2),
	.cs_i(csMarsDatetime),
	.rw_i(rw),
	.adr_i(ad[4:0]),
	.dat_i(ba),
	.dat_o(mdtdato),
	.tod(tod),
	.alarm(irq8m)
);

wire irq8 = irq8a & irq8m;

always_ff @(negedge ph2)
if (rst)
	vech <= 10'b1111_1111_00;
else begin
	if (csIRQ & ~rw)
		vech <= {2'b11,ba};
end

assign irq0 = ~|tmrirq;

always_ff @(posedge ph2)
begin
	case(ad[3:1])
	3'd2:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h40};	// COP
	3'd3:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h44}; // BRK
	3'd4:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h48};	// ABORT
	3'd5:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h4C};	// NMI
	3'd6: vec <= ad[0] ? vech[9:2] : {vech[1],7'h50}; // RESET
	3'd7:	// xxxE or xxxF
		case(1'b0)
		irq0: vec <= ad[0] ? vech[9:2] : {vech[1],7'h00};
		irq1:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h04};
		irq2:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h08};
		irq3: vec <= ad[0] ? vech[9:2] : {vech[1],7'h0C};
		irq4: vec <= ad[0] ? vech[9:2] : {vech[1],7'h10};
		irq5:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h14};
		irq6:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h18};
		irq7: vec <= ad[0] ? vech[9:2] : {vech[1],7'h1C};
		irq10:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h28};
		irq11:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h2C};
		irq12:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h30};
		irq14:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h38};
		irq15:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h3C};
		default:	vec <= ad[0] ? vech[9:2] : {vech[1],7'h44};
		endcase
	default: vec <= ad[0] ? vech[9:2] : {vech[1],7'h44}; // BRK
	endcase
end

assign ba = (csTimer1 & rw & ph2) ? tmr1do : 8'bz;
assign ba = (csTimer2 & rw & ph2) ? tmr2do : 8'bz;
assign ba = (csTimer3 & rw & ph2) ? tmr3do : 8'bz;
assign ba = (csTimer4 & rw & ph2) ? tmr4do : 8'bz;
assign ba = (csTimer5 & rw & ph2) ? tmr5do : 8'bz;
assign ba = (csTimer6 & rw & ph2) ? tmr6do : 8'bz;
assign ba = (csTimer7 & rw & ph2) ? tmr7do : 8'bz;
assign ba = (csTimer8 & rw & ph2) ? tmr8do : 8'bz;
assign ba = (~vpb & rw & ph2) ? vec : 8'bz;
assign ba = (csDatetime & rw & ph2) ? dtdato : 8'bz;
assign ba = (csMarsDatetime & rw & ph2) ? mdtdato : 8'bz;

assign irq = irq0 & irq1 & irq2 & irq3 & irq4 & irq5 & irq6 & irq7 &
							irq8 & irq9 & irq10 & irq11 & irq12 & irq14 & irq15;

endmodule
