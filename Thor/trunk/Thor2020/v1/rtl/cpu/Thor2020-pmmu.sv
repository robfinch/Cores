// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	pmmu.v
//  - 64 bit CPU paged memory management unit
//	- 512 entry TLB, 8 way associative
//  - variable page table depth
//	- address short-cutting for larger page sizes (4MB)
//  - hardware clearing of access bit
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
`include "..\inc\Thor2020-config.sv"
`include "..\inc\Thor2020-types.sv"

`ifndef TRUE
`define TRUE    1'b1
`define FALSE   1'b0
`endif
`define _8MBPG  5

typedef struct packed
{
	logic C;				// cacheable
	logic R;				// readable
	logic W;				// writeable
	logic X;				// executable
} Access;

typedef struct packed
{
	logic [50:0] ppageno;
	logic D;
	logic U;
	logic A;
	logic [6:0] pad7;
	logic [1:0] T;
	logic P;
} PDE;

typedef struct packed
{
	logic [31:0] rc;			// reference count
	logic [7:0] sc;			  // share count
	logic U;              // OS defined
	logic S;							// shortcut
	logic [1:0] pad2;
	logic [19:0] pk;			// protection key
} PTEX;

typedef struct packed
{
	PTEX	ptex;
	PDE		pde;
} PTE;

typedef struct packed
{
	PDE	  pde2;
	PDE		pde1;
} PDEPair;

typedef union packed
{
  PDEPair pdep;
  PTE     pte;
} sDAT;

module Thor2020_pmmu
#(
parameter
	AMSB = 63,
	pAssociativity = 8,		// number of ways (parallel compares)
	pTLB_size = 64,
	S_WAIT_MISS = 0,
	S_WR_PTE0 = 1,
	S_WR_PTE0H = 2,
	S_RD_PTE0 = 3,
	S_RD_PTE0H = 4,
	S_WR_PTE1 = 5,
	S_WR_PTE1H = 6,
	S_RD_PTE1 = 7,
	S_RD_PTE1H = 8,
	S_RD_PDE2 = 9,
	S_RD_PDE3 = 10,
	S_RD_PDE4 = 11,
	S_RD_PDE5 = 12,
	S_RD_PDE6 = 13,
	S_WR_TLB_ENTRYL = 14,
	S_WR_TLB_ENTRYH = 15,
	S_RD_SETUP = 16,
	S_WR_SETUP = 17,
	S_AGE = 18,
	S_COUNT = 19,
	S_RD_PTL_START = 20
)
(
// syscon
input rst_i,
input clk_i,

input age_tick_i,			// indicates when to age reference counts

// master
output reg cyc_o,		// valid memory address
output reg stb_o,		// strobe
output reg lock_o,	// lock the bus
input      ack_i,		// acknowledge from memory system
output reg we_o,		// write enable output
output reg [15:0] sel_o,	// lane selects (always all active)
output reg [AMSB:0] padr_o,
input      sDAT dat_i,	// data input from memory
output 		 sDAT dat_o,	// data to memory

// Translation request / control
input invalidate,		// invalidate a specific entry
input invalidate_all,	// causes all entries to be invalidated
input [63:0] pta,		// page directory/table address register
input [7:0] asid_i,
output reg page_fault,
input Key [7:0] keys,

input [1:0] ol_i,		// operating level
input icl_i,				// instruction cache load
input cyc_i,
input stb_i,
output reg ack_o,
input we_i,				    // cpu is performing write cycle
input [15:0] sel_i,
input [63:0] vadr_i,	    // virtual address to translate
input [127:0] vdat_i,
output [127:0] vdat_o,

output reg cac_o,		// cachable
output reg prv_o,		// privilege violation
output reg exv_o,		// execute violation
output reg rdv_o,		// read violation
output reg wrv_o,		// write violation

input clock
);

integer nn, kk;
assign vdat_o = dat_i;
reg [8:0] tlb_wa;
reg [8:0] tlb_ra;
reg [8:0] tlb_ua;
reg [AMSB:0] tmpadr;
reg pv_o;
reg v_o;
reg r_o;
reg w_o;
reg x_o;
reg c_o;
reg a_o;
reg [2:0] nnx;
PTE pte;			// holding place for data
reg [AMSB:0] pte_adr;
reg [80:0] clock_adr;
reg [4:0] state;
reg [4:0] stkstate;
reg [2:0] cnt;	// tlb replacement counter
reg [2:0] whichSet;		// which set to update
reg dbit;				// temp dirty bit
reg miss;
reg proc;
reg [80:0] miss_adr;
wire pta_changed;
//assign ack_o = !miss||page_fault;
wire pgen = pta[11];

wire [AMSB:0] tlb_pte_adr [pAssociativity-1:0];
wire tlb_P [pAssociativity-1:0];
wire [1:0] tlb_T [pAssociativity-1:0];
wire tlb_A [pAssociativity-1:0];
wire tlb_U1 [pAssociativity-1:0];
wire [pAssociativity-1:0] tlb_D;
wire [63:19] tlb_ppageno [pAssociativity-1:0];
wire [63:19] tlb_vpageno [pAssociativity-1:0];
wire tlb_S [pAssociativity-1:0];
wire tlb_U2 [pAssociativity-1:0];
wire [7: 0] tlb_sc [pAssociativity-1:0];
wire [19: 0] tlb_pk [pAssociativity-1:0];
wire [31: 0] tlb_rc [pAssociativity-1:0];
wire [31: 0] tlb_rc1 [pAssociativity-1:0];

initial begin
	cyc_o = 1'b0;
	stb_o = 1'b0;
	we_o = 1'b0;
	sel_o = 16'h0000;
	padr_o = 64'h0;
	v_o = 1'b0;
	pv_o = 1'b0;
	w_o = 1'b0;
end

//wire wr_tlb = state==S_WR_PTL0;
reg wr_tlb;
always @(posedge clk_i)
	prv_o <= pv_o & v_o && ol_i==3'b0;
always @(posedge clk_i)
	exv_o <= icl_i & v_o & ~x_o && ol_i==3'b0;
always @(posedge clk_i)
	rdv_o <= ~icl_i & v_o & ~r_o && ol_i==3'b0;
always @(posedge clk_i)
	wrv_o <= ~icl_i & v_o & ~w_o && ol_i==3'b0;
always @(posedge clk_i)
	cac_o <= c_o & v_o;

genvar g;
generate
	for (g = 0; g < pAssociativity; g = g + 1)
	begin : genTLB
		ram_ar1w1r #(1,pTLB_size) utlbP
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pde.P),
			.o(tlb_P[g])
		);
		ram_ar1w1r #(2,pTLB_size) utlbT
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pde.T),
			.o(tlb_T[g])
		);
		ram_ar1w1r #(1,pTLB_size) utlbA
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pde.A),
			.o(tlb_A[g])
		);
		ram_ar1w1r #(1,pTLB_size) utlbU1
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pde.U),
			.o(tlb_U1[g])
		);
		ram_ar1w1r #( 1,pTLB_size) tlbD    
		(
			.clk(clk_i),
			.ce(wr_tlb?whichSet==g:nnx==g),
			.we(wr_tlb||state==S_WAIT_MISS && wr && !miss && cyc_i),
			.wa(wr_tlb?miss_adr[18:13]:vadr_i[18:13]),
			.ra(vadr_i[18:13]),
			.i(!wr_tlb),
			.o(tlb_D[g])
		);
		ram_ar1w1r #(45,pTLB_size) utlbPadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pde.ppageno),
			.o(tlb_ppageno[g])
		);
		ram_ar1w1r #(45,pTLB_size) tlbVadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pde.vpageno),
			.o(tlb_vpageno[g])
		);
		ram_ar1w1r #(1,pTLB_size) utlbS
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.ptex.S),
			.o(tlb_S[g])
		);
		ram_ar1w1r #(1,pTLB_size) utlbU2
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.ptex.U),
			.o(tlb_U2[g])
		);
		ram_ar1w1r #(13,pTLB_size) tlbPL
    (
      .clk(clk_i),
      .ce(whichSet==g),
      .we(wr_tlb),
      .wa(miss_adr[18:13]),
      .ra(vadr_i[18:13]),
      .i(pte.ptex.pl),
      .o(tlb_pl[g])
    );
		ram_ar1w1r #(13,pTLB_size) utlbSC
    (
      .clk(clk_i),
      .ce(whichSet==g),
      .we(wr_tlb),
      .wa(miss_adr[18:13]),
      .ra(vadr_i[18:13]),
      .i(pte.ptex.sc),
      .o(tlb_sc[g])
    );
		ram_ar1w1r #(13,pTLB_size) utlbPK
    (
      .clk(clk_i),
      .ce(whichSet==g),
      .we(wr_tlb),
      .wa(miss_adr[18:13]),
      .ra(vadr_i[18:13]),
      .i(pte.ptex.pk),
      .o(tlb_pk[g])
    );
		ram_ar1w2r #(26,pTLB_size) utlbRefCount
		(
			.clk(clk_i),
			.ce(wr_tlb?whichSet==g:tlb_ra[8:6]==g),
			.we(wr_tlb||state==S_COUNT||state==S_AGE),
			.wa(wr_tlb?miss_adr[18:13]:tlb_ra[5:0]),
			.ra0(vadr_i[18:13]),
			.ra1(tlb_ra),
			.i(pte.ptex.rc),
			.o0(tlb_rc[g]),
			.o1(tlb_rc1[g])
		);

		ram_ar1w1r #(AMSB+1,pTLB_size) utlbPteAdr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte_adr),
			.o(tlb_pte_adr[g])
		);
/*
		ram_ar1w1r #( 1,pTLB_size) tlbG
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[19:14]),
			.ra(vadr_i[19:14]),
			.i(pte.g),
			.o(tlb_g[g])
		);
*/
	end
endgenerate

reg [pAssociativity*pTLB_size-1:0] tlb_v;	// valid

// The following reg allows detection of when the page table address changes
change_det #(52) u1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.i(pta),
	.cd(pta_changed)
);

reg age_tick_r;
wire pe_age_rtick;
edge_det ued1(.clk(clk_i), .ce(1'b1), .i(age_tick), .pe(pe_age_tick), .ne(), .ee());

// This must be fast !!!
// Lookup the virtual address in the tlb
// Translate the address
// I/O and system BIOS addresses are not mapped
// Cxxx_xxxx_xxxx_xxxx to FFFF_FFFF_FFFF_FFFF not mapped (kernel segment)
// 0000_0000_0000_0000 to 0000_0000_0000_xxxx not mapped (kernel data segement)
always @(posedge clk_i)
if (rst_i) begin
	nack();
	v_o <= 1'b0;
	pv_o <= 1'b0;
	w_o <= 1'b0;
	wr_tlb <= 1'b0;
	padr_o <= 1'b0;
	goto(S_WAIT_MISS);
	dbit  <= 1'b0;
	whichSet <= 1'b0;
	for (nn = 0; nn < pAssociativity * pTLB_size; nn = nn + 1)
		tlb_v[nn] <= 1'b0;		// all entries are invalid on reset
  page_fault <= `FALSE;
  age_tick_r <= 1'b0;
end
else begin

	wr_tlb <= 1'b0;

	// page fault pulses
	page_fault <= `FALSE;

	if (pe_age_tick)
		age_tick_r <= 1'b1;

	// changing the address of the page table invalidates all entries
	if (invalidate_all)
		for (nn = 0; nn < pAssociativity * pTLB_size; nn = nn + 1)
			tlb_v[nn] <= 1'b0;

	// handle invalidate command
	if (invalidate)
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (vadr_i[51:19]==tlb_vpageno[nn])
				tlb_v[{nn,vadr_i[18:13]}] <= 1'b0;

	case (state)	// synopsys full_case parallel_case

	// Wait for a miss to occur. then initiate bus cycle
	// Output either the page directory address
	// or the page table address, depending on the
	// size of the app.
	S_WAIT_MISS:
		begin
			xlat();
			ack_o <= ack_i;
			dbit <= we_i;
			proc <= `FALSE;

			if (miss) begin
				ack_o <= 1'b0;
			  proc <= `TRUE;
				miss_adr <= vadr_i;

				// try and pick an empty tlb entry
				whichSet <= cnt;
				for (nn = 0; nn < pAssociativity; nn = nn + 1)
					if (!tlb_v[nn]) begin
						whichSet <= nn;
						goto(S_RD_PTL_START);
					end
					else begin
						tlb2pte(nn,0,0);
						pte_adr <= tlb_pte_adr[nn];
						goto(S_WR_TLB_ENTRYL);
					end
			end
			else if (ol_i != 3'b000) begin
				// If there's a write cycle, check to see if the
				// dirty bit is set. If the dirty bit hasn't been
				// set yet, then set it and write the dirty status
				// to memory.
				if (cyc_i && we_i && !tlb_D[nnx]) begin
					ack_o <= 1'b0;
					whichSet <= nnx;
					goto(S_RD_PTL_START);
				end
				else if (age_tick_r) begin
					age_tick_r <= 1'b0;
					miss_adr <= {tlb_ua + 3'd1,13'd0};
					tlb_ra <= tlb_ua + 3'd1;
					tlb_ua <= tlb_ua + 3'd1;
					goto(S_AGE);
				end
				else begin
					tlb_ra <= {nnx,vadr_i[18:13]};
					goto(S_COUNT);
				end
			end
		end

	S_WR_TLB_ENTRYL:
		begin
			tmpadr <= {pte_adr[AMSB:4],4'h0};
			dat_o <= pte.pde;
			call(S_WR_SETUP,S_WR_TLB_ENTRYH);
		end
	S_WR_TLB_ENTRYH:
		if (ack_i) begin
			tmpadr <= {pte_adr[AMSB:4],4'h8};
			dat_o <= pte.ptex;
			call(S_WR_SETUP,S_RD_PTL_START);
		end

	S_RD_PTL_START:
		if (~ack_i & ~cyc_o) begin
			tlb_ra <= {whichSet,miss_adr[18:13]};
			tlb_wa <= {whichSet,miss_adr[18:13]};
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 16'hFFFF;
			lock_o <= 1'b0;
			we_o  <= 1'b0;
			case(pta[10:8])
			3'd0:	state <= S_RD_PTE0;
			3'd1:	state <= S_RD_PTE1;
			3'd2:	state <= S_RD_PDE2;
			3'd3:	state <= S_RD_PDE3;
			3'd4:	state <= S_RD_PDE4;
			3'd5:	state <= S_RD_PDE5;
			3'd6:	state <= S_RD_PDE6;
			default:	;
			endcase
			// Set page table address for lookup
			case(pta[10:8])
			3'd0:	padr_o <= {pta[63:14],miss_adr[21:13],4'h0};	// 4MB translations
			3'd1:	padr_o <= {pta[63:14],miss_adr[30:22],4'h0};	// 2GB translations
			3'd2:	padr_o <= {pta[63:14],miss_adr[40:31],3'h0};	// 4TB translations
			3'd3:	padr_o <= {pta[63:14],miss_adr[50:41],3'h0};	// 128XB translations
			3'd4: padr_o <= {pta[63:14],miss_adr[60:51],3'h0};	// 128XB translations
			3'd5: padr_o <= {pta[63:14],miss_adr[70:61],3'h0};	// 128XB translations
			3'd6: padr_o <= {pta[63:14],miss_adr[80:71],3'h0};	// 128XB translations
			default:	;
			endcase
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PDE6:
		if (ack_i) begin
			nack();
			if (tmpadr[3] ? |dat_i.pdep.pde2.T : |dat_i.pdep.pde1.T) begin	// pte valid bit
				tmpadr <= tmpadr[3] ? {dat_i.pdep.pde2.ppageno,miss_adr[70:61],3'b0} : {dat_i.pdep.pde1.ppageno,miss_adr[70:61],3'b0};
				call(S_RD_SETUP,S_RD_PDE5);
			end
			else begin
				if (clock) begin
					clock_adr[80:71] <= clock_adr[80:71] + 3'h1;
					clock_adr[70:0] <= 71'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PDE5:
		if (ack_i) begin
			nack();
			if (tmpadr[3] ? |dat_i.pdep.pde2.T : |dat_i.pdep.pde1.T) begin	// pte valid bit
				tmpadr <= tmpadr[3] ? {dat_i.pdep.pde2.ppageno,miss_adr[60:51],3'b0} : {dat_i.pdep.pde1.ppageno,miss_adr[60:51],3'b0};
				call(S_RD_SETUP,S_RD_PDE4);
			end
			else begin
				if (clock) begin
					clock_adr[80:61] <= clock_adr[80:61] + 3'h1;
					clock_adr[60:0] <= 61'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PDE4:
		if (ack_i) begin
			nack();
			if (tmpadr[3] ? |dat_i.pdep.pde2.T : |dat_i.pdep.pde1.T) begin	// pte valid bit
				tmpadr <= tmpadr[3] ? {dat_i.pdep.pde2.ppageno,miss_adr[50:41],3'b0} : {dat_i.pdep.pde1.ppageno,miss_adr[50:41],3'b0};
				call(S_RD_SETUP,S_RD_PDE3);
			end
			else begin
				if (clock) begin
					clock_adr[80:51] <= clock_adr[80:51] + 3'h1;
					clock_adr[50:0] <= 51'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PDE3:
		if (ack_i) begin
			nack();
			if (tmpadr[3] ? |dat_i.pdep.pde2.T : |dat_i.pdep.pde1.T) begin	// pte valid bit
				tmpadr <= tmpadr[3] ? {dat_i.pdep.pde2.ppageno,miss_adr[40:31],3'b0} : {dat_i.pdep.pde1.ppageno,miss_adr[40:31],3'b0};
				call(S_RD_SETUP,S_RD_PDE2);
			end
			else begin
				if (clock) begin
					clock_adr[80:41] <= clock_adr[80:41] + 3'h1;
					clock_adr[40:0] <= 51'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PDE2:
		if (ack_i) begin
			nack();
			if (tmpadr[3] ? |dat_i.pdep.pde2.T : |dat_i.pdep.pde1.T) begin	// pte valid bit
				tmpadr <= tmpadr[3] ? {dat_i.pdep.pde2.ppageno,miss_adr[30:22],4'b0} : {dat_i.pdep.pde1.ppageno,miss_adr[30:22],4'b0};
				call(S_RD_SETUP,S_RD_PTE1);
			end
			else begin
				if (clock) begin
					clock_adr[80:31] <= clock_adr[80:31] + 3'h1;
					clock_adr[30:0] <= 31'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTE1:
		if (ack_i) begin
			nack();
			pte <= dat_i.pte;
			if (|dat_i.pte.pde.T) begin	// pte valid bit
  			if (dat_i.pte.ptex.S) begin
  				wr_tlb <= 1'b1;
  				pte_adr <= {padr_o[AMSB:4],4'h0};
  				tmpadr <= {tmpadr[AMSB:4],4'h0};
    			pte.pde.D <= dbit;
  				dat_o <= dat_i;
    			dat_o.pde.D <= dbit;
  				// If the tlb entry is already marked dirty don't bother with updating
  				// the pte in memory. Only write on a new dirty status.
  				if (tlb_D[tlb_ra[8:6]])
  					goto(S_WAIT_MISS);
  				else
  					call(S_WR_SETUP,S_WR_PTE1);
  			end
  			else begin
  	    	tmpadr <= {dat_i.pte.pde.ppageno,miss_adr[21:13],4'b0};
  				call(S_RD_SETUP,S_RD_PTE0);
  			end
			end
			else begin
				if (clock) begin
					clock_adr[80:22] <= clock_adr[80:22] + 4'h1;
					clock_adr[21:0] <= 22'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	S_WR_PTE1:
		if (ack_i) begin
			nack();
			wr_tlb <= 1'b1;
			tlb_v[tlb_wa] <= pte.pde.P;
			if (~pte.pde.P)
		    raise_page_fault();
			goto(S_WAIT_MISS);
		end

	//---------------------------------------------------
	// This section of the state machine performs a
	// read then write of a PTE
	//---------------------------------------------------
	// Perform a read cycle of page table level 0 entry
	S_RD_PTE0:
  	// The tlb has been updated so the page must have been accessed
    // set the accessed bit for the page table entry
    // Also set dirty bit if a write access.
		if (ack_i) begin
			nack();
			wr_tlb <= 1'b1;
			tmpadr <= {tmpadr[AMSB:4],4'h0};
			pte <= dat_i.pte;
			pte.pde.D <= dbit;
			dat_o <= dat_i;
			dat_o.pde.D <= dbit;
			// If the tlb entry is already marked dirty don't bother with updating
			// the pte in memory. Only write on a new dirty status.
			if (tlb_D[tlb_ra[8:6]])
				goto(S_WAIT_MISS);
			else
				call(S_WR_SETUP,S_WR_PTE0);
		end

	S_WR_PTE0:
		if (ack_i) begin
			nack();
			wr_tlb <= 1'b1;
			tlb_v[tlb_wa] <= pte.pde.P;
			if (~pte.pde.P)
		    raise_page_fault();
			goto(S_WAIT_MISS);
		end

	//---------------------------------------------------
	// Take care of reference counting and aging.
	//---------------------------------------------------

	S_COUNT:
		begin
			tlb2pte(nnx,1,0);
			wr_tlb <= 1'b1;
			xlat();
			ack_o <= ack_i;
			goto(S_WAIT_MISS);
		end

	S_AGE:
		begin
			tlb2pte(tlb_ra[8:6],0,1);
			wr_tlb <= 1'b1;
			xlat();
			ack_o <= ack_i;
			goto(S_WAIT_MISS);
		end

	//---------------------------------------------------
	// Subroutine: initiate read cycle
	//---------------------------------------------------
	S_RD_SETUP:
		if (~ack_i & ~cyc_o) begin
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 16'hFFFF;
			lock_o <= 1'b0;
			we_o  <= 1'b0;
			padr_o <= tmpadr;
			retrn();
		end

	//---------------------------------------------------
	// Subroutine: initiate write cycle
	//---------------------------------------------------
	S_WR_SETUP:
		if (~ack_i & ~cyc_o) begin
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 16'hFFFF;
			lock_o <= 1'b0;
			we_o  <= 1'b1;
			padr_o <= tmpadr;
			retrn();
		end

	//---------------------------------------------------
	// This state can't happen without a hardware error
	//---------------------------------------------------
	default:
		begin
			nack();
			goto(S_WAIT_MISS);
		end

	endcase
end


// This counter is used to select the tlb entry that gets
// replaced when a new entry is entered into the buffer.
// It just increments every time an entry is updated. 
always @(posedge clk_i)
if (rst_i)
	cnt <= 0;
else if (state==S_WAIT_MISS && miss) begin
	if (cnt == pAssociativity-1)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end

// Copy the tlb to a temporary pte holding register.
task tlb2pte;
input [2:0] n;
input count;
input age;
begin
  pte.ptex.rc = count ? tlb_rc1[n] + 32'h2000 : age ? {1'b0,tlb_rc1[n][31:1]} : tlb_rc[n];
  pte.ptex.sc = tlb_sc[n];
  pte.ptex.U = tlb_U2[n];
  pte.ptex.S = tlb_S[n];
  pte.ptex.pk = tlb_pn[n];	
	pte.pde.ppageno = tlb_ppageno[n];
	pte.pde.D = tlb_D[n];
	pte.pde.U = tlb_U1[n];
	pte.pde.A = tlb_A[n];
	pte.pde.T = tlb_T[n];
	pte.pde.P = tlb_P[n];
end
endtask

// Perform address translation.
task xlat;
begin
	cyc_o <= cyc_i & v_o & ~pv_o;
	stb_o <= stb_i & v_o & ~pv_o;
	we_o <= we_i & v_o & ~pv_o & w_o;
	sel_o <= sel_i & {8{~pv_o}};
	dat_o <= vdat_i;

	miss <= 1;
	nnx <= pAssociativity;
	a_o <= 1;
	v_o <= 0;
	pv_o <= 0;
	padr_o[12: 0] <= vadr_i[12: 0];
	padr_o[63:13] <= vadr_i[63:13];
	if (ol_i!=2'b0 || vadr_i[63:16]==48'h0 || vadr_i[63:20]==44'hFFFF_FFFF_FFD) begin
    miss <= 0;
    v_o <= 1;
  end
	else if (&vadr_i[63:58]) begin
		miss <= 0;
		v_o <= 1;
	end
	else begin
		if (!pgen) begin
			miss <= 0;
			v_o <= 1;
		end
		else
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (tlb_v[{nn,vadr_i[18:13]}] && vadr_i[51:19]==tlb_vpageno[nn]) begin
		    padr_o[63:13] <= tlb_ppageno[nn];
				miss <= 1'b0;
				nnx <= nn;
				a_o <= tlb_A[nn];
				v_o <= tlb_P[nn];
				pv_o <= (cyc_i & icl_i) ? pl_i != tlb_pl[nn] && ol_i==2'h0 : pl_i > tlb_pl[nn];
				if ((keys[0] != tlb_pk[nn]
					&& keys[1] != tlb_pk[nn]
					&& keys[2] != tlb_pk[nn]
					&& keys[3] != tlb_pk[nn]
					&& keys[4] != tlb_pk[nn]
					&& keys[5] != tlb_pk[nn]
					&& keys[6] != tlb_pk[nn]
					&& keys[7] != tlb_pk[nn]
					) && tlb_pk[nn] != 20'h0)
					pv_o <= ol_i == 2'b0;
			end
	end
end
endtask

task nack;
begin
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	sel_o <= 8'h00;
	lock_o <= 1'b0;
	we_o  <= 1'b0;
end
endtask

task raise_page_fault;
begin
	nack();
  if (proc)
    page_fault <= `TRUE;
  proc <= `FALSE;
  state <= S_WAIT_MISS;
end
endtask

task goto;
input [3:0] nst;
begin
	state <= nst;
end
endtask

task call;
input [3:0] nst;
input [3:0] rst;
begin
	goto(nst);
	stkstate <= rst;
end
endtask

task retrn;
begin
	state <= stkstate;
end
endtask

endmodule

