`include "Thor_defines.v"
//=============================================================================
//        __
//   \\__/ o\    (C) 2011,2012,2013  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//  
//	Thor_TLB.v
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
`define TLBMissPage		{DBW-12{1'b1}}

module Thor_TLB(rst, clk, km, pc, ea, ppc, pea,
	iuncached, uncached,
	m1IsStore, ASID, state, op, regno, dati, dato,
	ITLBMiss, DTLBMiss, HTLBVirtPageo);
parameter DBW=64;
input rst;
input clk;
input km;					// kernel mode
input [DBW-1:0] pc;
input [DBW-1:0] ea;
output reg [DBW-1:0] ppc;
output reg [DBW-1:0] pea;
output iuncached;
output uncached;
input m1IsStore;
input [7:0] ASID;
input [2:0] state;
input [3:0] op;
input [3:0] regno;
input [DBW-1:0] dati;
output [DBW-1:0] dato;
reg [DBW-1:0] dato;
output ITLBMiss;
output DTLBMiss;
output [DBW-1:0] HTLBVirtPageo;

integer n;

// Holding registers
// These allow the TLB to updated in a single cycle
reg [DBW-1:0] HTLBVirtPage;
assign HTLBVirtPageo = {HTLBVirtPage,12'b0};
reg [DBW-1:0] HTLBPhysPage;
reg [7:0] HTLBASID;
reg HTLBG;
reg HTLBD;
reg [2:0] HTLBC;
reg HTLBValid;

reg TLBenabled;
reg [5:0] i;
reg [DBW-1:0] Index;
reg [2:0] Random;
reg [2:0] Wired;
reg [2:0] PageSize;
reg [7:0] IMatch,DMatch;

reg [3:0] m;
reg [3:0] q;
wire doddpage;
reg [DBW-1:0] TLBVirtPage [63:0];
reg [DBW-1:0] TLBPhysPage [63:0];
reg [63:0] TLBG;
reg [63:0] TLBD;
reg [2:0] TLBC [63:0];
reg [7:0] TLBASID [63:0];
reg [63:0] TLBValid;
reg [DBW-1:0] imiss_addr;
reg [DBW-1:0] dmiss_addr;
reg [DBW-1:0] PageTblAddr;
reg [DBW-1:0] PageTblCtrl;

initial begin
	for (n = 0; n < 64; n = n + 1)
	begin
		TLBVirtPage[n] = 0;
		TLBPhysPage[n] = 0;
		TLBG[n] = 0;
		TLBASID[n] = 0;
		TLBD[n] = 0;
		TLBC[n] = 0;
		TLBValid[n] = 0;
	end
end

// Assume the instruction doesn't overlap between a mapped and unmapped area.
wire unmappedArea = pc[DBW-1:DBW-4]==4'hF || !TLBenabled;
wire unmappedDataArea = ea[DBW-1:DBW-4]==4'hF || !TLBenabled;
wire m1UnmappedDataArea = pea[DBW-1:DBW-4]==4'hF || !TLBenabled;
wire hitIOPage = ea[DBW-1:DBW-12]==12'hFFD;

always @(posedge clk)
if (rst) begin
	TLBenabled <= 1'b0;
	Random <= 3'h7;
	Wired <= 3'd0;
	PageSize <= 3'd0;
	PageTblAddr <= {DBW{1'b0}};
	PageTblCtrl <= {DBW{1'b0}};
end
else begin
	if (dmiss_addr == {DBW{1'b0}} && DTLBMiss)
		dmiss_addr <= ea;
	if (imiss_addr == {DBW{1'b0}} && ITLBMiss)
		imiss_addr <= pc;

	if (Random==Wired)
		Random <= 3'd7;
	else
		Random <= Random - 3'd1;

	if (state==3'd1) begin
		case(op)
		`TLB_RD,`TLB_WI:
			i <= {Index[5:3],(HTLBVirtPage >> {PageSize,1'b0}) & 3'h7};
		`TLB_WR:
			i <= {Random,(HTLBVirtPage >> {PageSize,1'b0}) & 3'h7};
		`TLB_WRREG:
			begin
			case(regno)
			`TLBWired:		Wired <= dati[2:0];
			`TLBIndex:		Index <= dati[5:0];
			`TLBRandom:		Random <= dati[2:0];
			`TLBPageSize:	PageSize <= dati[2:0];
			`TLBVirtPage:	HTLBVirtPage <= dati;
			`TLBPhysPage:	HTLBPhysPage <= dati;
			`TLBASID:	begin
						HTLBValid <= dati[0];
						HTLBD <= dati[1];
						HTLBC <= dati[4:2];
						HTLBASID <= dati[23:16];
						HTLBG <= dati[31];
						end
			`TLBDMissAdr:	dmiss_addr <= dati;
			`TLBIMissAdr:	imiss_addr <= dati;
			`TLBPageTblAddr:	PageTblAddr <= dati;
			`TLBPageTblCtrl:	PageTblCtrl <= dati;
			default: ;
			endcase
			end
		`TLB_EN:
			TLBenabled <= 1'b1;
		`TLB_DIS:
			TLBenabled <= 1'b0;
		`TLB_INVALL:
			TLBValid <= 64'd0;
		default:  ;
		endcase
	end
	else if (state==3'd2) begin
		case(op)
		`TLB_P:
			begin
				Index[DBW-1] <= ~|DMatch;
			end
		`TLB_RD:
			begin
				HTLBVirtPage <= TLBVirtPage[i];
				HTLBPhysPage <= TLBPhysPage[i];
				HTLBASID <= TLBASID[i];
				HTLBG <= TLBG[i];
				HTLBD <= TLBD[i];
				HTLBC <= TLBC[i];
				HTLBValid <= TLBValid[i];
			end
		`TLB_WR,`TLB_WI:
			begin
				TLBVirtPage[i] <= HTLBVirtPage;
				TLBPhysPage[i] <= HTLBPhysPage;
				TLBASID[i] <= HTLBASID;
				TLBG[i] <= HTLBG;
				TLBD[i] <= HTLBD;
				TLBC[i] <= HTLBC;
				TLBValid[i] <= HTLBValid;
			end
		default:  ;
		endcase
	end

	// Set the dirty bit on a store
	if (m1IsStore)
		if (!m1UnmappedDataArea & !q[3]) begin
			TLBD[{q[2:0],(pea[DBW-1:12]>>{PageSize,1'b0})&3'd7}] <= 1'b1;
		end
end

always @*
	case(regno)
	`TLBWired:		dato = Wired;
	`TLBIndex:		dato = Index;
	`TLBRandom:		dato = Random;
	`TLBPhysPage:	dato = HTLBPhysPage;
	`TLBVirtPage:	dato = HTLBVirtPage;
	`TLBPageSize:	dato = PageSize;
	`TLBASID:	begin
				dato = {DBW{1'b0}};
				dato[0] = HTLBValid;
				dato[1] = HTLBD;
				dato[4:2] = HTLBC;
				dato[23:16] = HTLBASID;
				dato[31] = HTLBG;
				end
	`TLBDMissAdr:	dato = dmiss_addr;
	`TLBIMissAdr:	dato = imiss_addr;
	`TLBPageTblAddr:	dato = PageTblAddr;
	`TLBPageTblCtrl:	dato = PageTblCtrl;
	default:	dato = {DBW{1'b0}};
	endcase

wire [DBW-1:0] pcs = pc[DBW-1:12] >> {PageSize,1'b0};
always @*
for (n = 0; n < 8; n = n + 1)
begin
	IMatch[n[2:0]] = (pcs[DBW-1:3]==TLBVirtPage[{n[2:0],pcs[2:0]}][DBW-1:3]) &&
				((TLBASID[{n,pcs[2:0]}]==ASID) || TLBG[{n,pcs[2:0]}]) &&
				TLBValid[{n[2:0],pcs[2:0]}];
end

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


wire [DBW-1:0] IPFN = TLBPhysPage[{m[2:0],pcs[2:0]}];
assign iuncached = TLBC[{m[2:0],pcs[2:0]}]==3'd1;

assign ITLBMiss = TLBenabled & (!unmappedArea & (m[3] | ~TLBValid[{m[2:0],pcs[2:0]}]));

always @*
begin
	ppc[11:0] = pc[11:0];
	case(PageSize)
	3'd0:	ppc[DBW-1:12] = unmappedArea ? pc[DBW-1:12] : ITLBMiss ? `TLBMissPage: IPFN;				// 4KiB
	3'd1:	ppc[DBW-1:12] = {unmappedArea ? pc[DBW-1:14] : ITLBMiss ? `TLBMissPage: IPFN,pc[13:12]};	// 16KiB
	3'd2:	ppc[DBW-1:12] = {unmappedArea ? pc[DBW-1:16] : ITLBMiss ? `TLBMissPage: IPFN,pc[15:12]};	// 64KiB
	3'd3:	ppc[DBW-1:12] = {unmappedArea ? pc[DBW-1:18] : ITLBMiss ? `TLBMissPage: IPFN,pc[17:12]};	// 256 KiB
	3'd4:	ppc[DBW-1:12] = {unmappedArea ? pc[DBW-1:20] : ITLBMiss ? `TLBMissPage: IPFN,pc[19:12]};	// 1 MiB
	default:	ppc[DBW-1:12] = pc[DBW-1:12];
	endcase
end

wire [DBW-1:0] eas = ea[DBW-1:12] >> {PageSize,1'b0};
always @(eas or ASID or q or TLBG or TLBValid)
for (n = 0; n < 8; n = n + 1)
	DMatch[n[2:0]] = (eas[DBW-1:3]==TLBVirtPage[{n,eas[2:0]}]) &&
				((TLBASID[{n,eas[2:0]}]==ASID) || TLBG[{n,eas[2:0]}]) &&
				TLBValid[{q[2:0],eas[2:0]}];
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

wire [DBW-1:0] DPFN = TLBPhysPage[{q[2:0],eas[2:0]}];
assign uncached = TLBC[{q[2:0],eas[2:0]}]==3'd1;// || unmappedDataArea;

assign DTLBMiss = TLBenabled & (!unmappedDataArea & (q[3] | ~TLBValid[{q[2:0],eas[2:0]}]) ||
					(!km && hitIOPage));

always @*
begin
	case(PageSize)
	3'd0:	pea[DBW-1:12] = unmappedDataArea ? ea[DBW-1:12] : DTLBMiss ? `TLBMissPage: DPFN;
	3'd1:	pea[DBW-1:12] = {unmappedDataArea ? ea[DBW-1:14] : DTLBMiss ? `TLBMissPage: DPFN,ea[13:12]};
	3'd2:	pea[DBW-1:12] = {unmappedDataArea ? ea[DBW-1:16] : DTLBMiss ? `TLBMissPage: DPFN,ea[15:12]};
	3'd3:	pea[DBW-1:12] = {unmappedDataArea ? ea[DBW-1:18] : DTLBMiss ? `TLBMissPage: DPFN,ea[17:12]};
	3'd4:	pea[DBW-1:12] = {unmappedDataArea ? ea[DBW-1:20] : DTLBMiss ? `TLBMissPage: DPFN,ea[19:12]};
	default:	pea[DBW-1:12] = ea[DBW-1:12];
	endcase
	pea[11:0] = ea[11:0];
end

endmodule

