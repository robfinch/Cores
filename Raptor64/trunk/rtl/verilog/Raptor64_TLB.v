`include "Raptor64_opcodes.v"
`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2011,2012  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//  
//	Raptor64_TLB.v
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
//
// TLB
// The TLB contains 64 entries, that are 8 way set associative.
// The TLB is dual ported and shared between the instruction and data streams.
//
//=============================================================================
//
`define TLBMissPage		51'h7FFF_FFFF_FFFF_F

module Raptor64_TLB(rst, clk, pc, ea, ppc, pea,
	m1IsStore, ASID,
	wTlbp, wTlbrd, wTlbwr, wTlbwi,
	xTlbrd, xTlbwr, xTlbwi,
	wr, wregno, dati, xregno, dato, ITLBMiss, DTLBMiss, HTLBVirtPageo);
input rst;
input clk;
input [63:0] pc;
input [63:0] ea;
output [63:0] ppc;
output [63:0] pea;
input m1IsStore;
input [7:0] ASID;
input wTlbp;
input wTlbrd;
input wTlbwr;
input wTlbwi;
input xTlbrd;
input xTlbwr;
input xTlbwi;
input wr;
input [5:0] wregno;
input [63:0] dati;
input [5:0] xregno;
output [63:0] dato;
reg [63:0] dato;
output ITLBMiss;
output DTLBMiss;
output [63:0] HTLBVirtPageo;

integer n;

// Holding registers
// These allow the TLB to updated in a single cycle
reg [24:13] HTLBPageMask;
reg [63:13] HTLBVirtPage;
assign HTLBVirtPageo = {HTLBVirtPage,13'b0};
reg [63:13] HTLBPhysPage0;
reg [63:13] HTLBPhysPage1;
reg [7:0] HTLBASID;
reg HTLBG;
reg HTLBD0;
reg [2:0] HTLBC0;
reg HTLBValid0;
reg HTLBD1;
reg [2:0] HTLBC1;
reg HTLBValid1;

reg [5:0] i;
reg [63:0] Index;
reg [2:0] Random;
reg [2:0] Wired;
reg [7:0] IMatch,DMatch;

reg [3:0] m;
reg [3:0] q;
wire doddpage;
reg [24:13] TLBPageMask [63:0];
reg [63:13] TLBVirtPage [63:0];
reg [63:13] TLBPhysPage0 [63:0];
reg [63:13] TLBPhysPage1 [63:0];
reg [63:0] TLBG;
reg [63:0] TLBD0;
reg [63:0] TLBD1;
reg [2:0] TLBC0 [63:0];
reg [2:0] TLBC1 [63:0];
reg [7:0] TLBASID [63:0];
reg [63:0] TLBValid0;
reg [63:0] TLBValid1;
initial begin
	for (n = 0; n < 64; n = n + 1)
	begin
		TLBPageMask[n] = 0;
		TLBVirtPage[n] = 0;
		TLBPhysPage0[n] = 0;
		TLBPhysPage1[n] = 0;
		TLBG[n] = 0;
		TLBASID[n] = 0;
		TLBASID[n] = 0;
		TLBD0[n] = 0;
		TLBD1[n] = 0;
		TLBC0[n] = 0;
		TLBC1[n] = 0;
		TLBValid0[n] = 0;
		TLBValid1[n] = 0;
	end
end

wire unmappedArea = pc[63:52]==12'hFFD || pc[63:52]==12'hFFE || pc[63:52]==12'hFFF;
wire unmappedDataArea = ea[63:52]==12'hFFD || ea[63:52]==12'hFFE || ea[63:52]==12'hFFF || ea[63:52]==12'h000;
wire m1UnmappedDataArea = pea[63:52]==12'hFFD || pea[63:52]==12'hFFE || pea[63:52]==12'hFFF || pea[63:52]==12'h000;

always @(posedge clk)
if (rst) begin
	Random <= 3'h7;
	Wired <= 3'd0;
end
else begin
	if (Random==Wired)
		Random <= 3'd7;
	else
		Random <= Random - 3'd1;

	if (xTlbrd|xTlbwi)
		i <= {Index[5:3],HTLBVirtPage[15:13]};
	if (xTlbwr)
		i <= {Random,HTLBVirtPage[15:13]};
	if (wr) begin
		case(wregno)
		`TLBWired:		Wired <= dati[2:0];
		`TLBIndex:		Index <= dati[5:0];
		`TLBRandom:	Random <= dati[2:0];
		`TLBPageMask:	HTLBPageMask <= dati[24:13];
		`TLBVirtPage:	HTLBVirtPage <= dati[63:13];
		`TLBPhysPage0:	HTLBPhysPage0 <= dati[63:13];
		`TLBPhysPage1:	HTLBPhysPage1 <= dati[63:13];
		`TLBASID:	begin
					HTLBValid0 <= dati[0];
					HTLBD0 <= dati[1];
					HTLBC0 <= dati[4:2];
					HTLBValid1 <= dati[8];
					HTLBD1 <= dati[9];
					HTLBC1 <= dati[12:10];
					HTLBASID <= dati[23:16];
					HTLBG <= dati[32];
					end
		endcase
	end
	if (wTlbp)
		begin
			Index[63] <= ~|DMatch;
		end
	if (wTlbrd) begin
		HTLBPageMask <= TLBPageMask[i];
		HTLBVirtPage <= TLBVirtPage[i];
		HTLBPhysPage0 <= TLBPhysPage0[i];
		HTLBPhysPage1 <= TLBPhysPage1[i];
		HTLBASID <= TLBASID[i];
		HTLBG <= TLBG[i];
		HTLBD0 <= TLBD0[i];
		HTLBC0 <= TLBC0[i];
		HTLBValid0 <= TLBValid0[i];
		HTLBD1 <= TLBD1[i];
		HTLBC1 <= TLBC1[i];
		HTLBValid1 <= TLBValid1[i];
	end
	else if (wTlbwi|wTlbwr) begin
		TLBVirtPage[i] <= HTLBVirtPage;
		TLBPhysPage0[i] <= HTLBPhysPage0;
		TLBPhysPage1[i] <= HTLBPhysPage1;
		TLBASID[i] <= HTLBASID;
		TLBG[i] <= HTLBG;
		TLBD0[i] <= HTLBD0;
		TLBC0[i] <= HTLBC0;
		TLBValid0[i] <= HTLBValid0;
		TLBD1[i] <= HTLBD1;
		TLBC1[i] <= HTLBC1;
		TLBValid1[i] <= HTLBValid1;
	end
	// Set the dirty bit on a store
	if (m1IsStore)
		if (!m1UnmappedDataArea & !q[3]) begin
			if (doddpage)
				TLBD1[{q[2:0],pea[15:13]}] <= 1'b1;
			else
				TLBD0[{q[2:0],pea[15:13]}] <= 1'b1;
		end
end

always @*
	case(xregno)
	`TLBWired:		dato = Wired;
	`TLBIndex:		dato = Index;
	`TLBRandom:		dato = Random;
	`TLBPhysPage0:	dato = {HTLBPhysPage0,13'd0};
	`TLBPhysPage1:	dato = {HTLBPhysPage1,13'd0};
	`TLBVirtPage:	dato = {HTLBVirtPage,13'd0};
	`TLBPageMask:	dato = {HTLBPageMask,13'd0};
	`TLBASID:	begin
				dato = 64'd0;
				dato[0] = HTLBValid0;
				dato[1] = HTLBD0;
				dato[4:2] = HTLBC0;
				dato[8] = HTLBValid1;
				dato[9] = HTLBD1;
				dato[12:10] = HTLBC1;
				dato[23:16] = HTLBASID;
				dato[32] = HTLBG;
				end
	default:	dato = 64'd0;
	endcase

always @*
for (n = 0; n < 8; n = n + 1)
	IMatch[n[2:0]] = ((pc[63:13]|TLBPageMask[{n[2:0],pc[15:13]}])==(TLBVirtPage[{n[2:0],pc[15:13]}]|TLBPageMask[{n[2:0],pc[15:13]}])) &&
				((TLBASID[{n,pc[15:13]}]==ASID) || TLBG[{n,pc[15:13]}]);
always @(IMatch)
if (IMatch[0]) m <= 4'd0;
else if (IMatch[1]) m <= 4'd1;
else if (IMatch[2]) m <= 4'd2;
else if (IMatch[3]) m <= 4'd3;
else if (IMatch[4]) m <= 4'd4;
else if (IMatch[5]) m <= 4'd5;
else if (IMatch[6]) m <= 4'd6;
else if (IMatch[7]) m <= 4'd7;
else m <= 4'd15;

wire ioddpage = |({TLBPageMask[{m[2:0],pc[15:13]}]+19'd1,13'd0}&pc);
wire [63:13] IPFN = ioddpage ? TLBPhysPage1[{m[2:0],pc[15:13]}] : TLBPhysPage0[{m[2:0],pc[15:13]}];

assign ITLBMiss = !unmappedArea & (m[3] | (ioddpage ? ~TLBValid1[{m[2:0],pc[15:13]}] : ~TLBValid0[{m[2:0],pc[15:13]}]));

assign ppc[63:13] = unmappedArea ? pc[63:13] : ITLBMiss ? `TLBMissPage: IPFN;
assign ppc[12:0] = pc[12:0];

always @(ea)
for (n = 0; n < 8; n = n + 1)
	DMatch[n[2:0]] = ((ea[63:13]|TLBPageMask[{n,ea[15:13]}])==(TLBVirtPage[{n,ea[15:13]}]|TLBPageMask[{n,ea[15:13]}])) &&
				((TLBASID[{n,ea[15:13]}]==ASID) || TLBG[{n,ea[15:13]}]);
always @(DMatch)
if (DMatch[0]) q <= 4'd0;
else if (DMatch[1]) q <= 4'd1;
else if (DMatch[2]) q <= 4'd2;
else if (DMatch[3]) q <= 4'd3;
else if (DMatch[4]) q <= 4'd4;
else if (DMatch[5]) q <= 4'd5;
else if (DMatch[6]) q <= 4'd6;
else if (DMatch[7]) q <= 4'd7;
else q <= 4'd15;

assign doddpage = |({TLBPageMask[{q[2:0],ea[15:13]}]+19'd1,13'd0}&ea);
wire [63:13] DPFN = doddpage ? TLBPhysPage1[{q[2:0],ea[15:13]}] : TLBPhysPage0[{q[2:0],ea[15:13]}];

assign DTLBMiss = !unmappedDataArea & (q[3] | (doddpage ? ~TLBValid1[{q[2:0],ea[15:13]}] : ~TLBValid1[{q[2:0],ea[15:13]}]));

assign pea[63:13] = unmappedDataArea ? ea[63:13] : DTLBMiss ? `TLBMissPage: DPFN;
assign pea[12:0] = ea[12:0];

endmodule

