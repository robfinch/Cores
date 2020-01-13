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
//	- address short-cutting for larger page sizes (8MB)
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
`ifndef TRUE
`define TRUE    1'b1
`define FALSE   1'b0
`endif
`define _8MBPG  5

typedef struct packed
{
	logic [12:0] pad13;
	logic [38:0] pageno;
	logic [25:0] rc;			// reference count
	logic [7:0] asid;
	logic g;
	logic pad1;
	logic [7:0] pl;
	logic D;
	logic U;
	logic S;
	logic A;
	logic C;
	logic R;
	logic W;
	logic X;
} PTE;

module Gambit_pmmu
#(
parameter
	AMSB = 31,
	pAssociativity = 8,		// number of ways (parallel compares)
	pTLB_size = 64,
	S_WAIT_MISS = 0,
	S_WR_PTL0 = 1,
	S_WR_PTL0H = 2,
	S_RD_PTL0 = 3,
	S_RD_PTL0H = 4,
	S_RD_PTL1 = 5,
	S_RD_PTL1H = 6,
	S_RD_PTL2 = 7,
	S_RD_PTL3 = 8,
	S_RD_PTL3_ACK = 9,
	S_RD_PTL = 12,
	S_WR_PTL = 13,
	S_AGE = 14,
	S_COUNT = 15
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
output reg [7:0] sel_o,	// lane selects (always all active)
output reg [AMSB:0] padr_o,
input      PTE dat_i,	// data input from memory
output 		 PTE dat_o,	// data to memory

// Translation request / control
input invalidate,		// invalidate a specific entry
input invalidate_all,	// causes all entries to be invalidated
input [51:0] pta,		// page directory/table address register
output reg page_fault,

input [7:0] asid_i,
input [7:0] pl_i,
input [2:0] ol_i,		// operating level
input icl_i,				// instruction cache load
input cyc_i,
input stb_i,
output reg ack_o,
input we_i,				    // cpu is performing write cycle
input [7:0] sel_i,
input [51:0] vadr_i,	    // virtual address to translate

output reg cac_o,		// cachable
output reg prv_o,		// privilege violation
output reg exv_o,		// execute violation
output reg rdv_o,		// read violation
output reg wrv_o,		// write violation

input clock
);

integer nn;
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
reg [AMSB-4:0] pte_adr;
reg [AMSB:0] clock_adr;
reg [3:0] state;
reg [3:0] stkstate;
reg [2:0] cnt;	// tlb replacement counter
reg [2:0] whichSet;		// which set to update
reg dbit;				// temp dirty bit
reg miss;
reg proc;
reg [51:0] miss_adr;
wire pta_changed;
//assign ack_o = !miss||page_fault;
wire pgen = pta[11];

wire [AMSB:0] tlb_pte_adr [pAssociativity-1:0];
wire [pAssociativity-1:0] tlb_d;
wire [ 6: 0] tlb_flags [pAssociativity-1:0];
wire [ 7: 0] tlb_pl [pAssociativity-1:0];
wire [ 7: 0] tlb_asid [pAssociativity-1:0];
wire [25: 0] tlb_refcount [pAssociativity-1:0];
wire tlb_g [pAssociativity-1:0];
wire [51:19] tlb_vadr  [pAssociativity-1:0];
wire [38:0] tlb_tadr  [pAssociativity-1:0];

initial begin
	cyc_o = 1'b0;
	stb_o = 1'b0;
	we_o = 1'b0;
	sel_o = 8'h00;
	padr_o = 52'h0;
	v_o = 1'b0;
	pv_o = 1'b0;
	w_o = 1'b0;
end

//wire wr_tlb = state==S_WR_PTL0;
reg wr_tlb;
always @(posedge clk_i)
	prv_o <= pv_o & v_o && ol_i!=3'b0;
always @(posedge clk_i)
	exv_o <= icl_i & v_o & ~x_o && ol_i!=3'b0;
always @(posedge clk_i)
	rdv_o <= ~icl_i & v_o & ~r_o && ol_i!=3'b0;
always @(posedge clk_i)
	wrv_o <= ~icl_i & v_o & ~w_o && ol_i!=3'b0;
always @(posedge clk_i)
	cac_o <= c_o & v_o;

genvar g;
generate
	for (g = 0; g < pAssociativity; g = g + 1)
	begin : genTLB
		ram_ar1w1r #(33,pTLB_size) tlbVadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(miss_adr[51:19]),
			.o(tlb_vadr[g])
		);
		ram_ar1w1r #(AMSB+1,pTLB_size) tlbPteAdr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte_adr),
			.o(tlb_pte_adr[g])
		);
		ram_ar1w1r #( 7,pTLB_size) tlbFlag
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte[6:0]),
			.o(tlb_flags[g])
		);
		ram_ar1w1r #(8,pTLB_size) tlbPL
    (
      .clk(clk_i),
      .ce(whichSet==g),
      .we(wr_tlb),
      .wa(miss_adr[18:13]),
      .ra(vadr_i[18:13]),
      .i(pte.pl),
      .o(tlb_pl[g])
    );
		ram_ar1w1r #( 1,pTLB_size) tlbG
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.g),
			.o(tlb_g[g])
		);
		ram_ar1w1r #(8,pTLB_size) tlbASID
    (
      .clk(clk_i),
      .ce(whichSet==g),
      .we(wr_tlb),
      .wa(miss_adr[18:13]),
      .ra(vadr_i[18:13]),
      .i(pte.asid),
      .o(tlb_asid[g])
    );
		ram_ar1w1r #(26,pTLB_size) tlbRefCount0
    (
      .clk(clk_i),
      .ce(whichSet==g),
      .we(wr_tlb),
      .wa(miss_adr[18:13]),
      .ra(vadr_i[18:13]),
      .i(pte.rc),
      .o(tlb_refcount[g])
    );
		ram_ar1w1r #(26,pTLB_size) tlbRefCount1
		(
			.clk(clk_i),
			.ce(wr_tlb?whichSet==g:nnx==g),
			.we(wr_tlb||state==S_WAIT_MISS && !miss && cyc_i),
			.wa(wr_tlb?miss_adr[18:13]:vadr_i[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.rc),
			.o(tlb_refcount[g])
		);
		ram_ar1w1r #(39,pTLB_size) tlbTadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte.pageno),
			.o(tlb_tadr[g])
		);
		ram_ar1w1r #( 1,pTLB_size) tlbD    
		(
			.clk(clk_i),
			.ce(wr_tlb?whichSet==g:nnx==g),
			.we(wr_tlb||state==S_WAIT_MISS && wr && !miss && cyc_i),
			.wa(wr_tlb?miss_adr[18:13]:vadr_i[18:13]),
			.ra(vadr_i[18:13]),
			.i(!wr_tlb),
			.o(tlb_d[g])
		);
	end
endgenerate

reg [pAssociativity*pTLB_size-1:0] tlb_v;	// valid

// The following reg allows detection of when the page table address changes
change_det #(48) u1
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

	cyc_o <= cyc_i & v_o & ~pv_o;
	stb_o <= stb_i & v_o & ~pv_o;
	we_o <= we_i & v_o & ~pv_o & w_o;
	sel_o <= sel_i & {8{~pv_o}};

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
			if (vadr_i[51:19]==tlb_vadr[nn] && (tlb_g[nn] || tlb_asid[nn]==asid_i))
				tlb_v[{nn,vadr_i[18:13]}] <= 1'b0;

	case (state)	// synopsys full_case parallel_case

	// Wait for a miss to occur. then initiate bus cycle
	// Output either the page directory address
	// or the page table address, depending on the
	// size of the app.
	S_WAIT_MISS:
		begin
			goto(S_WAIT_MISS);
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
					if (!tlb_v[{nn,vadr_i[18:13]}])
						whichSet <= nn;
				goto(S_RD_PTL3);
			end
			// If there's a write cycle, check to see if the
			// dirty bit is set. If the dirty bit hasn't been
			// set yet, then set it and write the dirty status
			// to memory.
			else if (cyc_i && we_i && !tlb_d[nnx]) begin
				ack_o <= 1'b0;
				miss_adr <= vadr_i;
				whichSet <= nnx;
				goto(S_RD_PTL3);
			end
			else if (age_tick_r) begin
				age_tick_r <= 1'b0;
				tlb_wa <= tlb_ua + 3'd1;
				tlb_ra <= tlb_ua + 3'd1;
				tlb_ua <= tlb_ua + 3'd1;
				goto(S_AGE);
			end
			else begin
				tlb_wa <= {nnx,vadr_i[18:13]};
				tlb_ra <= {nnx,vadr_i[18:13]};
				goto(S_COUNT);
			end
		end

	S_RD_PTL3:
		if (~ack_i & ~cyc_o) begin
			tlb_ra <= {whichSet,miss_adr[18:13]};
			tlb_wa <= {whichSet,miss_adr[18:13]};
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 8'hFF;
			lock_o <= 1'b0;
			we_o  <= 1'b0;
			case(pta[9:8])
			2'd0:	state <= S_RD_PTL0;
			2'd1:	state <= S_RD_PTL1;
			2'd2:	state <= S_RD_PTL2;
			2'd3:	state <= S_RD_PTL3_ACK;
			default:	;
			endcase
			// Set page table address for lookup
			case(pta[9:8])
			2'b00:	padr_o <= {pta[51:13],miss_adr[22:13],3'h0};	// 8MB translations
			2'b01:	padr_o <= {pta[51:13],miss_adr[32:23],3'h0};	// 8GB translations
			2'b10:	padr_o <= {pta[51:13],miss_adr[42:33],3'h0};	// 8TB translations
			2'b11:	padr_o <= {pta[51:13],1'b0,miss_adr[51:43],3'h0};	// 8XB translations
			default:	;
			endcase
		end
	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL3_ACK:
		if (ack_i) begin
			nack();
			if (|dat_i[2:0]) begin	// pte valid bit
				tmpadr <= {dat_i.pageno,miss_adr[42:33],3'h0};
				call(S_RD_PTL,S_RD_PTL2);
			end
			else begin
				if (clock) begin
					clock_adr[51:43] <= clock_adr[51:43] + 3'h1;
					clock_adr[42:0] <= 43'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
				// not a valid translation
				// OS messed up ?
			end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL2:
		if (ack_i) begin
			nack();
			if (|dat_i[2:0]) begin	// pte valid bit
				tmpadr <= {dat_i.pageno,miss_adr[32:23],3'b0};
				call(S_RD_PTL,S_RD_PTL1);
			end
			else begin
				if (clock) begin
					clock_adr[51:33] <= clock_adr[51:33] + 3'h1;
					clock_adr[32:0] <= 33'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL1:
		if (ack_i) begin
			nack();
			if (|dat_i[2:0]) begin	// pte valid bit
		    // Shortcut 8MiB page ?
		    if (dat_i.S) begin
	        pte <= dat_i;
    			dat_o <= dat_i|{dbit,2'b00,~clock,4'b0};
    			dat_o.A <= ~clock;
					call(S_WR_PTL,S_WR_PTL0);
		    end
		    else begin
			    tmpadr <= {dat_i.pageno,miss_adr[22:13],3'b0};
					call(S_RD_PTL,S_RD_PTL0);
				end
			end
			else begin
				if (clock) begin
					clock_adr[51:23] <= clock_adr[51:23] + 4'h1;
					clock_adr[22:0] <= 23'h0;
					goto (S_WAIT_MISS);
				end
				else
		  	  raise_page_fault();
		  end
		end

	//---------------------------------------------------
	// This section of the state machine performs a
	// read then write of a PTE
	//---------------------------------------------------
	// Perform a read cycle of page table level 0 entry
	S_RD_PTL0:
  	// The tlb has been updated so the page must have been accessed
    // set the accessed bit for the page table entry
    // Also set dirty bit if a write access.
		if (ack_i) begin
			nack();
			wr_tlb <= 1'b1;
			pte_adr <= padr_o[AMSB:4];
			dat_o <= dat_i|{dbit,2'b00,1'b1,4'b0};	// This line will only set bits
			pte <= dat_i|{dbit,2'b00,1'b1,4'b0};
			// If the tlb entry is already marked dirty don't bother with updating
			// the pte in memory. Only write on a new dirty status.
			if (tlb_d[tlb_ra[8:6]])
				goto(S_WAIT_MISS);
			else
				call(S_WR_PTL,S_WR_PTL0);
		end

	S_WR_PTL0:
		if (ack_i) begin
			wr_tlb <= 1'b1;
			nack();
			tlb_v[tlb_wa] <= |pte[2:0];
			if (~|pte[2:0])
		    raise_page_fault();
			goto(S_WAIT_MISS);
		end

	//---------------------------------------------------
	// Take care of reference counting and aging.
	//---------------------------------------------------

	S_COUNT:
		begin
			pte[6:0] <= tlb_flags[tlb_ra[8:6]];
			pte.D <= tlb_d[tlb_ra[8:6]];
			pte.pl <= tlb_pl[tlb_ra[8:6]];
			pte.g <= tlb_g[tlb_ra[8:6]];
			pte.asid <= tlb_asid[tlb_ra[8:6]];
			pte.rc <= {tlb_refcount[tlb_ra[8:6]][25:13] + 4'd1,tlb_refcount[tlb_ra[8:6]][12:0]};
			pte.pageno <= tlb_tadr[tlb_ra[8:6]];
			wr_tlb <= 1'b1;
			xlat();
			ack_o <= ack_i;
			goto(S_WAIT_MISS);
		end

	S_AGE:
		begin
			pte[6:0] <= tlb_flags[tlb_ra[8:6]];
			pte.D <= tlb_d[tlb_ra[8:6]];
			pte.pl <= tlb_pl[tlb_ra[8:6]];
			pte.g <= tlb_g[tlb_ra[8:6]];
			pte.asid <= tlb_asid[tlb_ra[8:6]];
			pte.rc <= {1'b0,tlb_refcount[tlb_ra[8:6]][25:1]};
			pte.pageno <= tlb_tadr[tlb_ra[8:6]];
			wr_tlb <= 1'b1;
			xlat();
			ack_o <= ack_i;
			goto(S_WAIT_MISS);
		end

	//---------------------------------------------------
	// Subroutine: initiate read cycle
	//---------------------------------------------------
	S_RD_PTL:
		if (~ack_i & ~cyc_o) begin
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 8'hFF;
			lock_o <= 1'b0;
			we_o  <= 1'b0;
			padr_o <= tmpadr;
			retrn();
		end

	//---------------------------------------------------
	// Subroutine: initiate write cycle
	//---------------------------------------------------
	S_WR_PTL:
		if (~ack_i & ~cyc_o) begin
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 8'hFF;
			lock_o <= 1'b0;
			we_o  <= 1'b1;
			// Address comes from a previous read address
//			m_adr_o <= tmpadr;
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

task xlat;
begin
	miss <= 1;
	nnx <= pAssociativity;
	a_o <= 1;
	c_o <= 1;
	r_o <= 1;
	x_o <= 1;
	w_o <= 1;
	v_o <= 0;
	pv_o <= 0;
	padr_o[12: 0] <= vadr_i[12: 0];
	padr_o[51:13] <= vadr_i[51:13];
	if (ol_i==3'b0 || vadr_i[51:16]==36'h0 || vadr_i[51:20]==32'hF_FFFF_FFD) begin
    miss <= 0;
    c_o <= vadr_i[51:20]!=32'hF_FFFF_FFD;
    v_o <= 1;
  end
	else if (&vadr_i[51:46]) begin
		miss <= 0;
		c_o <= vadr_i[45:44]==2'b00;	// C000_0000_0000 to CFFF_FFFF_FFFF is cacheable
		v_o <= 1;
	end
	else begin
		if (!pgen) begin
			miss <= 0;
			v_o <= 1;
		end
		else
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (tlb_v[{nn,vadr_i[18:13]}] && vadr_i[51:19]==tlb_vadr[nn]) begin
			    if (tlb_flags[nn][`_8MBPG])
				    padr_o[51:13] <= {tlb_tadr[nn][39:10],vadr_i[22:13]};
			    else
				    padr_o[51:13] <= tlb_tadr[nn];
				miss <= 1'b0;
				nnx <= nn;
				a_o <= tlb_flags[nn][4];
				c_o <= tlb_flags[nn][3];
				r_o <= tlb_flags[nn][2];
				w_o <= tlb_flags[nn][1];
				x_o <= tlb_flags[nn][0];
				v_o <= tlb_flags[nn][2]|tlb_flags[nn][1]|tlb_flags[nn][0];
				pv_o <= (cyc_i & icl_i) ? pl_i != tlb_pl[nn] && pl_i!=8'h00 : pl_i > tlb_pl[nn];
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

