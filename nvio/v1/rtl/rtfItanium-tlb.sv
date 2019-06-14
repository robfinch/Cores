`include "rtfItanium-defines.sv"
`include "rtfItanium-config.sv"
//=============================================================================
//        __
//   \\__/ o\    (C) 2011-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//  
//	FT64_TLB.v
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
// The TLB contains 256 entries, that are 16 way set associative.
// The TLB is shared between the instruction and data streams.
// The code is carefully constructed to not require reset signals.
//
//=============================================================================
//
`define TLBMissPage		{DBW-13{1'b1}}

module TLB(clk, ld, done, idle, ol,
	ASID, op, regno, dati, dato,
	uncached,
	icl_i, cyc_i, we_i, vadr_i, cyc_o, we_o, padr_o,
	wrv_o, rdv_o, exv_o,
	TLBMiss, HTLBVirtPageo);
parameter DBW=80;
parameter ABW=80;
parameter ENTRIES=256;
parameter IDLE = 4'd0;
parameter ONE = 4'd1;
parameter TWO = 4'd2;
parameter READ = 4'd1;
parameter INC1 = 4'd2;
parameter INC2 = 4'd3;
parameter INC3 = 4'd4;
parameter AGE1 = 4'd5;
parameter AGE2 = 4'd6;
input clk;
input ld;
output done;
output idle;
input [1:0] ol;					// operating level
input [ABW-1:0] vadr_i;
output reg [ABW-1:0] padr_o = 80'hFFFFFFFFFFFFFFFC0100;
output uncached;

input icl_i;
input cyc_i;
input we_i;
output reg cyc_o;
output reg we_o;
output reg exv_o;
output reg wrv_o;
output reg rdv_o;
input [7:0] ASID;
input [3:0] op;
input [3:0] regno;
input [DBW-1:0] dati;
output reg [DBW-1:0] dato;
output TLBMiss;
output [DBW-1:0] HTLBVirtPageo;

integer n;

reg [1:0] state = IDLE;
assign done = state==(IDLE && !ld) || state==TWO;
assign idle = state==IDLE && !ld;

// Holding registers
// These allow the TLB to updated in a single cycle as a unit
reg [DBW-1:0] HTLBVirtPage;
assign HTLBVirtPageo = {HTLBVirtPage,13'b0};
reg [DBW-1:0] HTLBPhysPage;
reg [7:0] HTLBASID;
reg HTLBG;
reg HTLBD;
reg HTLBR, HTLBW, HTLBX, HTLBA, HTLBU, HTLBS;
reg [2:0] HTLBC;
reg [7:0] HTLBPL;
reg [2:0] HTLBPageSize;
reg HTLBValid;
reg [ABW-1:0] miss_addr;

reg TLBenabled = 1'b0;
reg [7:0] i = 8'h00;
reg [DBW-1:0] Index;
reg [3:0] Random = 4'hF;
reg [3:0] Wired = 4'd0;
reg [2:0] PageSize;
reg [15:0] Match;

reg [4:0] q;
wire doddpage;
reg [DBW-1:0] TLBVirtPage [ENTRIES-1:0];
reg [ENTRIES-1:0] TLBG;
reg [ENTRIES-1:0] TLBD;
reg [ENTRIES-1:0] TLBU;
reg [ENTRIES-1:0] TLBS;
reg [ENTRIES-1:0] TLBA;
reg [2:0] TLBC [ENTRIES-1:0];
reg [7:0] TLBASID [ENTRIES-1:0];
reg [7:0] TLBPL [ENTRIES-1:0];
reg [2:0] TLBPageSize [255:0];
reg [ENTRIES-1:0] TLBValid;
reg [DBW-1:0] imiss_addr;
reg [DBW-1:0] dmiss_addr;
reg [DBW-1:0] PageTblAddr = {DBW{1'b0}};
reg [DBW-1:0] PageTblCtrl = {DBW{1'b0}};

reg [23:0] age_lmt = 24'd20000;
reg [23:0] age_ctr = 24'd0;
wire age_tick = age_ctr < 24'd5;
reg cyc_en = 1'b1, age_en = 1'b1;
reg [3:0] ar_state = IDLE;
reg ar_wr = 1'b0;
reg [7:0] age_adr = 8'h00, ar_adr = 8'h00;
reg [32:0] count;
reg [31:0] ar_dati;
wire [31:0] ar_dato;
reg [31:0] ar_cdato;
reg getset_age;
reg doLoad = 1'b0;

/*
initial begin
	for (n = 0; n < ENTRIES; n = n + 1)
	begin
		TLBVirtPage[n] = 0;
		TLBG[n] = 0;
		TLBASID[n] = 0;
		TLBD[n] = 0;
		TLBC[n] = 0;
		TLBA[n] = 0;
		TLBR[n] = 0;
		TLBW[n] = 0;
		TLBX[n] = 0;
		TLBS[n] = 0;
		TLBU[n] = 0;
		TLBValid[n] = 0;
	end
end
*/

// Assume the instruction doesn't overlap between a mapped and unmapped area.
wire unmappedArea = vadr_i[ABW-1:ABW-8]==8'hFF || !TLBenabled;
wire m1UnmappedArea = padr_o[ABW-1:ABW-8]==8'hFF || !TLBenabled;
wire hitIOPage = vadr_i[ABW-1:ABW-12]==12'hFFD;

always @(posedge clk)
	PageSize <= TLBPageSize[ASID];

wire [ABW-1:0] vadrs = vadr_i[ABW-1:13] >> {PageSize,1'b0};
wire [DBW-1:0] TLBPhysPage_rdo;
wire [ABW-1:0] PFN;

// Toolset didn't like the simpler distributed code where the RAM was inferred.
// Resulted in combinatorial loop error message. Even though there weren't any
// combinatorial loops.

TLBPhysPageRam #(DBW) upgrm1
(
  .clk(clk),
  .we(state==TWO && (op==`TLB_WR || op==`TLB_WI)),
  .wa(i),
  .i(HTLBPhysPage),
  .ra0(i),
  .ra1({q[3:0],vadrs[3:0]}),
  .o0(TLBPhysPage_rdo),
  .o1(PFN)
);

wire tlbRo0,tlbRo1;
TLBRam #(1) uR
(
  .clk(clk),
  .we(state==TWO && (op==`TLB_WR || op==`TLB_WI)),
  .wa(i),
  .i(HTLBR),
  .ra0(i),
  .ra1({q[3:0],vadrs[3:0]}),
  .o0(tlbRo0),
  .o1(tlbRo1)
);

wire tlbWo0,tlbWo1;
TLBRam #(1) uW
(
  .clk(clk),
  .we(state==TWO && (op==`TLB_WR || op==`TLB_WI)),
  .wa(i),
  .i(HTLBW),
  .ra0(i),
  .ra1({q[3:0],vadrs[3:0]}),
  .o0(tlbWo0),
  .o1(tlbWo1)
);

wire tlbXo0,tlbXo1;
TLBRam #(1) uX
(
  .clk(clk),
  .we(state==TWO && (op==`TLB_WR || op==`TLB_WI)),
  .wa(i),
  .i(HTLBX),
  .ra0(i),
  .ra1({q[3:0],vadrs[3:0]}),
  .o0(tlbXo0),
  .o1(tlbXo1)
);

always @(posedge clk)
begin
	// age_ctr > age_lmt when counter hits -1, saves comparing to zero as well
	if (age_ctr > age_lmt)
		age_ctr <= age_lmt;
	else
		age_ctr <= age_ctr - 4'd1;
end

// Handle Random register
always @(posedge clk)
begin
	if (Random==Wired)
    Random <= 4'hF;
  else
    Random <= Random - 4'd1;
  // Why would we want to update since random changes on the next clock
  // anyways ?
  if (state==ONE) begin
    if (op==`TLB_WRREG && regno==`TLBRandom)
      Random <= dati[3:0];
  end
end

always @(posedge clk)
begin
case(state)
IDLE:
	if (ld)
		state <= ONE;
ONE:
	if (op==`TLB_RDAGE || op==`TLB_WRAGE) begin
		if (getset_age)
			state <= TWO;
	end
	else
		state <= TWO;
TWO:
	state <= IDLE;
default:
	state <= IDLE;
endcase
end

// Set index to page table
always @(posedge clk)
if (state==ONE) begin
  case(op)
  `TLB_RD,`TLB_WI:
    i <= {Index[7:4],(HTLBVirtPage >> {HTLBPageSize,1'b0}) & 4'hF};
  `TLB_WR:
    i <= {Random,(HTLBVirtPage >> {HTLBPageSize,1'b0}) & 4'hF};
  default:	i <= i;
  endcase
end

always @(posedge clk)
begin
	if (miss_addr == {DBW{1'b0}} && TLBMiss)
		miss_addr <= vadr_i;

	if (state==ONE) begin
		case(op)
		`TLB_WRREG:
			begin
			case(regno)
			`TLBWired:		Wired <= dati[2:0];
			`TLBIndex:		Index <= dati[5:0];
			//`TLBPageSize:	PageSize <= dati[2:0];
			`TLBVirtPage:	HTLBVirtPage <= dati;
			`TLBPhysPage:	HTLBPhysPage <= dati;
			`TLBASID:	begin
						HTLBValid <= |dati[2:0];
						HTLBX <= dati[0];
						HTLBW <= dati[1];
						HTLBR <= dati[2];
						HTLBC <= dati[5:3];
						HTLBA <= dati[6];
						HTLBS <= dati[7];
						HTLBU <= dati[8];
						HTLBD <= dati[9];
						HTLBG <= dati[10];
						HTLBPageSize <= dati[13:11];
						HTLBASID <= dati[23:16];
						HTLBPL <= dati[31:24];
						end
			`TLBMissAdr:	miss_addr <= dati;
			`TLBPageTblAddr:	PageTblAddr <= dati;
			`TLBPageTblCtrl:	PageTblCtrl <= dati;
			`TLBAFC:	age_lmt <= dati[23:0];
			default: ;
			endcase
			end
		`TLB_EN:
			TLBenabled <= 1'b1;
		`TLB_DIS:
			TLBenabled <= 1'b0;
		`TLB_INVALL:
			TLBValid <= 256'd0;
		default:  ;
		endcase
	end
	else if (state==TWO) begin
		case(op)
		`TLB_P:
			begin
				Index[DBW-1] <= ~|Match;
			end
		`TLB_RD:
			begin
				HTLBVirtPage <= TLBVirtPage[i];
				HTLBPhysPage <= TLBPhysPage_rdo;
				HTLBASID <= TLBASID[i];
				HTLBPL <= TLBPL[i];
				HTLBPageSize <= TLBPageSize[i];
				HTLBG <= TLBG[i];
				HTLBD <= TLBD[i];
				HTLBC <= TLBC[i];
				HTLBR <= tlbRo0;
				HTLBW <= tlbWo0;
				HTLBX <= tlbXo0;
				HTLBU <= TLBU[i];
				HTLBS <= TLBS[i];
				HTLBA <= TLBA[i];
				HTLBValid <= TLBValid[i];
			end
		`TLB_WR,`TLB_WI:
			begin
				TLBVirtPage[i] <= HTLBVirtPage;
				TLBASID[i] <= HTLBASID;
				TLBPL[i] <= HTLBPL;
				TLBPageSize[i] <= HTLBPageSize;
				TLBG[i] <= HTLBG;
				TLBD[i] <= HTLBD;
				TLBC[i] <= HTLBC;
				TLBA[i] <= HTLBA;
				TLBU[i] <= HTLBU;
				TLBS[i] <= HTLBS;
				TLBValid[i] <= HTLBValid;
			end
		default:  ;
		endcase
	end

	// Set the dirty bit on a store
	if (we_i)
		if (!m1UnmappedArea & !q[4]) begin
			TLBD[{q[3:0],vadrs[3:0]}] <= 1'b1;
		end
end

always @(posedge clk)
	case(regno)
	`TLBWired:		dato <= Wired;
	`TLBIndex:		dato <= Index;
	`TLBRandom:		dato <= Random;
	`TLBPhysPage:	dato <= HTLBPhysPage;
	`TLBVirtPage:	dato <= HTLBVirtPage;
	`TLBPageSize:	dato <= PageSize;
	`TLBASID:	begin
				dato <= {DBW{1'b0}};
				dato[0] <= HTLBX;
				dato[1] <= HTLBW;
				dato[2] <= HTLBR;
				dato[5:3] <= HTLBC;
				dato[6] <= HTLBA;
				dato[7] <= HTLBS;
				dato[8] <= HTLBU;
				dato[9] <= HTLBD;
				dato[10] <= HTLBG;
				dato[13:11] <= HTLBPageSize;
				dato[23:16] <= HTLBASID;
				dato[31:24] <= HTLBPL;
				end
	`TLBMissAdr:	dato <= miss_addr;
	`TLBPageTblAddr:	dato <= PageTblAddr;
	`TLBPageTblCtrl:	dato <= PageTblCtrl;
	`TLBPageCount:		dato <= {16'd0,ar_cdato};
	default:	dato <= {DBW{1'b0}};
	endcase

TLBAgeRam uar1(clk,ar_wr,ar_adr,ar_dati,ar_dato);

always @(posedge clk)
begin
ar_wr <= 1'b0;
getset_age <= 1'b0;
if (ld)
	doLoad <= 1'b1;
case(ar_state)
IDLE:
	begin
		if (~cyc_i)
			cyc_en <= 1'b1;
		if (~age_tick)
			age_en <= 1'b1;
		if ((ld|doLoad) && (op==`TLB_RDAGE || op==`TLB_WRAGE)) begin
			doLoad <= 1'b0;
			ar_wr <= op==`TLB_WRAGE;
			ar_adr <= i;
			ar_dati <= dati[31:0];
			ar_state <= READ;
		end
		else if (cyc_i & |Match & cyc_en) begin
			cyc_en <= 1'b0;
			ar_adr <= {q[3:0],vadrs[3:0]};
			ar_state <= INC1;
		end
		else if (age_tick & age_en) begin
			age_en <= 1'b0;
			ar_adr <= age_adr;
			age_adr <= age_adr + 4'd1;
			ar_state <= AGE1;
		end
	end
READ:
	begin
		getset_age <= 1'b1;
		ar_cdato <= ar_dato;
		ar_state <= IDLE;
	end
INC1:
	begin
		count <= ar_dato;
		ar_state <= INC2;
	end
INC2:
	begin
		count <= {count[31:8] + 4'd1,count[7:0]};
		ar_state <= INC3;
	end
INC3:
	begin
		ar_wr <= 1'b1;
		ar_dati <= {count[32] ? 24'hFFFFFF :count[31:8],count[7:0]};
		ar_state <= IDLE;
	end
AGE1:
	begin
		count <= ar_dato;
		ar_state <= AGE2;
	end
AGE2:
	begin
		ar_wr <= 1'b1;
		ar_dati <= count >> 1;
		ar_state <= IDLE;
	end
endcase
end

always @*
for (n = 0; n < 16; n = n + 1)
	Match[n[3:0]] = (vadrs[ABW-1:4]==TLBVirtPage[{n[3:0],vadrs[3:0]}]) &&
				((TLBASID[{n[3:0],vadrs[3:0]}]==ASID) || TLBG[{n[3:0],vadrs[3:0]}]) &&
				TLBValid[{n[3:0],vadrs[3:0]}];

always @*
begin
	q = 5'd31;
	for (n = 15; n >= 0; n = n - 1)
		if (Match[n]) q = n;
end

assign uncached = TLBC[{q[3:0],vadrs[3:0]}]==3'd1;// || unmappedDataArea;

assign TLBMiss = (ol!=2'b00) && TLBenabled && (!unmappedArea & (q[4] | ~TLBValid[{q[3:0],vadrs[3:0]}]) ||
					(ol!=2'b00 && hitIOPage));

always @(posedge clk)
	cyc_o <= cyc_i && (!TLBMiss || !TLBenabled || (ol == 2'b00));

always @(posedge clk)
	we_o <= we_i & ((~TLBMiss & tlbWo1) | ~TLBenabled || (ol==2'b00));

always @(posedge clk)
	wrv_o <= we_i & ~TLBMiss & ~tlbWo1 & TLBenabled && (ol != 2'b00);

always @(posedge clk)
	rdv_o <= ~we_i & ~TLBMiss & ~tlbRo1 & TLBenabled && (ol != 2'b00);

always @(posedge clk)
	exv_o <= icl_i & ~TLBMiss & ~tlbXo1 & TLBenabled && (ol != 2'b00);

always @(posedge clk)
if (TLBenabled && ol != 2'b00) begin
	case(PageSize)
	3'd0:	padr_o[ABW-1:13] <=  unmappedArea ? vadr_i[ABW-1:13] : TLBMiss ? `TLBMissPage: PFN;
	3'd1:	padr_o[ABW-1:13] <= {unmappedArea ? vadr_i[ABW-1:15] : TLBMiss ? `TLBMissPage: PFN,vadr_i[14:13]};
	3'd2:	padr_o[ABW-1:13] <= {unmappedArea ? vadr_i[ABW-1:17] : TLBMiss ? `TLBMissPage: PFN,vadr_i[16:13]};
	3'd3:	padr_o[ABW-1:13] <= {unmappedArea ? vadr_i[ABW-1:19] : TLBMiss ? `TLBMissPage: PFN,vadr_i[18:13]};
	3'd4:	padr_o[ABW-1:13] <= {unmappedArea ? vadr_i[ABW-1:21] : TLBMiss ? `TLBMissPage: PFN,vadr_i[20:13]};
	3'd5:	padr_o[ABW-1:13] <= {unmappedArea ? vadr_i[ABW-1:23] : TLBMiss ? `TLBMissPage: PFN,vadr_i[22:13]};
	default:	padr_o[ABW-1:13] <= vadr_i[ABW-1:13];
	endcase
	padr_o[12:0] <= vadr_i[12:0];
end
else
	padr_o <= vadr_i;

endmodule

module TLBRam(clk,we,wa,i,ra0,ra1,o0,o1);
parameter DBW=1;
input clk;
input we;
input [7:0] wa;
input [DBW-1:0] i;
input [7:0] ra0;
input [7:0] ra1;
output [DBW-1:0] o0;
output [DBW-1:0] o1;

reg [DBW-1:0] mem [0:255];

always @(posedge clk)
  if (we)
    mem[wa] <= i;

assign o0 = mem[ra0];
assign o1 = mem[ra1];

endmodule

module TLBPhysPageRam(clk,we,wa,i,ra0,ra1,o0,o1);
parameter DBW=64;
input clk;
input we;
input [7:0] wa;
input [DBW-1:0] i;
input [7:0] ra0;
input [7:0] ra1;
output [DBW-1:0] o0;
output [DBW-1:0] o1;

reg [DBW-1:0] mem [0:255];

always @(posedge clk)
  if (we)
    mem[wa] <= i;

assign o0 = mem[ra0];
assign o1 = mem[ra1];

endmodule

module TLBAgeRam(clk,we,a,i,o);
parameter DBW=32;
input clk;
input we;
input [7:0] a;
input [DBW-1:0] i;
output [DBW-1:0] o;

reg [DBW-1:0] mem [0:255];

always @(posedge clk)
  if (we)
    mem[a] <= i;

assign o = mem[a];

endmodule

