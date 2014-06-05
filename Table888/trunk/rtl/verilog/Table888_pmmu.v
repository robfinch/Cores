// ============================================================================
//        __
//   \\__/ o\    (C) 2007,2013,2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// Table888_pmmu.v - mmu
//  - 64 bit CPU paged memory management unit
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
//	mmu.v
//		Remaps (translates) a virtual address to a real address.
//
//	Webpack 14.7  xc6slx45-3csg324	
// ============================================================================
//
module Table888_pmmu
#(
parameter
	pAssociativity = 8,		// number of ways (parallel compares)
	pTLB_size = 64,
	S_WAIT_MISS = 0,
	S_WR_TLB = 1,
	S_WR_PTL0 = 2,
	S_RD_PTL0b = 3,
	S_RD_PTL0 = 4,
	S_RD_PTL1 = 5,
	S_RD_PTL1b = 6,
	S_RD_PTL2 = 7,
	S_RD_PTL2b = 8,
	S_RD_PTL3 = 9,
	S_RD_PTL3b = 10,
	S_RD_PTL4 = 11,
	S_RD_PTL4b = 12,
	S_RD_PTL5 = 13,
	S_RD_PTL5b = 14,
	S_RD_PTL5_ACK = 15
)
(
// syscon
input rst_i,
input clk_i,

// master
output reg soc_o,		// start of cycle
output reg cyc_o,		// bus cycle active
output reg stb_o,
output reg lock_o,		// lock the bus
input      ack_i,		// acknowledge from memory system
output reg wr_o,		// write enable output
output reg [ 3:0] byt_o,	// lane selects (always all active)
output reg [31:0] adr_o,
input      [31:0] dat_i,	// data input from memory
output reg [31:0] dat_o,	// data to memory

// Translation request / control
input paging_en,		// paging is enabled
input invalidate,		// invalidate a specific entry
input invalidate_all,	// causes all entries to be invalidated
input [63:0] pta,		// page directory/table address register
input rst_cpnp,			// reset the pnp bit
input rst_dpnp,
output reg cpnp,		// page not present
output reg dpnp,
output reg [63:0] cpte,	// holding place for data
output reg [63:0] dpte,

input cav,				// code address valid
input [63:0] vcadr,		// virtual code address to translate
output reg [63:0] tcadr,	// translated code address
output reg rdy,				// address translation is ready
output reg [3:0] p,		// privilege (0= supervisor)
output reg c,r,w,x,		// cacheable, read, write and execute attributes
output reg v,			// translation is valid

input wr,				// cpu is performing write cycle
input dav,				// data address valid
input [63:0] vdadr,		// virtual data address to translate
output reg [63:0] tdadr,	// translated data address
output reg drdy,			// address translation is ready
output reg [3:0] dp,
output reg dc,dr,dw,dx,
output reg dv
);

integer nn;
reg [2:0] nnx;
reg [2:0] nnxd;
reg [3:0] state;
reg [1:0] cnt;	// tlb replacement counter
reg [1:0] whichSet;		// which set to update
reg dbit;				// temp dirty bit
reg miss,missc,missd;
reg [63:0] miss_adr;
wire pta_changed;
reg [63:0] pte;
reg [31:0] adrx;

wire [pAssociativity-1:0] tlb_dd;
wire [ 7: 0] tlb_cflags [pAssociativity-1:0];
wire [ 7: 0] tlb_dflags [pAssociativity-1:0];
wire [63:18] tlb_vcadr  [pAssociativity-1:0];
wire [63:12] tlb_tcadr  [pAssociativity-1:0];
wire [63:18] tlb_vdadr  [pAssociativity-1:0];
wire [63:12] tlb_tdadr  [pAssociativity-1:0];

wire wr_tlb = state==S_WR_TLB;

genvar g;
generate
	for (g = 0; g < pAssociativity; g = g + 1)
	begin : genTLB
		ram_ar1w2r #(46,pTLB_size) tlbVadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[17:12]),
			.ra0(vcadr[17:12]),
			.ra1(vdadr[17:12]),
			.i(miss_adr [63:18]),
			.o0(tlb_vcadr[g]),
			.o1(tlb_vdadr[g])
		);
		ram_ar1w2r #(52,pTLB_size) tlbTadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[17:12]),
			.ra0(vcadr[17:12]),
			.ra1(vdadr[17:12]),
			.i(pte[63:12]),
			.o0(tlb_tcadr[g]),
			.o1(tlb_tdadr[g])
		);
		ram_ar1w2r #( 8,pTLB_size) tlbFlag
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[17:12]),
			.ra0(vcadr[17:12]),
			.ra1(vdadr[17:12]),
			.i(pte[ 7: 0]),
			.o0(tlb_cflags[g]),
			.o1(tlb_dflags[g])
		);

		ram_ar1w1r #( 1,pTLB_size) tlbD
		(
			.clk(clk_i),
			.ce(wr_tlb?whichSet==g:nnxd==g),
			.we(wr_tlb||(state==S_WAIT_MISS && wr && !missd)),
			.wa(wr_tlb?miss_adr[17:12]:vdadr[17:12]),
			.ra(vdadr[17:12]),
			.i(!wr_tlb),
			.o(tlb_dd[g])
		);

	end
endgenerate

reg [pAssociativity*pTLB_size-1:0] tlb_v;	// valid

// The following reg allows detection of when the page table address changes
change_det u1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.i(pta),
	.cd(pta_changed)
);

// This must be fast !!!
// Lookup the virtual address in the tlb
// Translate the address
always @*
begin
	rdy <= 0;
	missc <= cav;
	missd <= dav;
	drdy <= 1'b0;
	nnx <= pAssociativity;
	p <= 4'd0;
	c <= 1;
	r <= 1;
	x <= 1;
	w <= 1;
	v <= 0;
	tcadr[11: 0] <= vcadr[11: 0];
	tcadr[63:12] <= vcadr[63:12];
	if (!paging_en || vcadr[31:16]==16'h0000) begin
		rdy <= 1;
		missc <= 0;
		c <= 1;
		v <= 1;
	end
	else begin
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (tlb_v[{nn,vcadr[17:12]}] && vcadr[63:18]==tlb_vcadr[nn]) begin
				tcadr[63:12] <= tlb_tcadr[nn];
				missc <= 1'b0;
				rdy <= 1'b1;
				nnx <= nn;
				p <= tlb_cflags[nn][7:4];
				c <= tlb_cflags[nn][3];
				r <= tlb_cflags[nn][2];
				x <= tlb_cflags[nn][1];
				w <= tlb_cflags[nn][0];
				v <= tlb_cflags[nn][2]|tlb_cflags[nn][1]|tlb_cflags[nn][0];
			end
	end
	// The first 64k of data memory is unmapped
	nnxd <= 3'd0;
	dp <= 4'd0;
	dc <= 1;
	dr <= 1;
	dx <= 1;
	dw <= 1;
	dv <= 0;
	tdadr[11: 0] <= vdadr[11: 0];
	tdadr[63:12] <= vdadr[63:12];
	if (!paging_en || vdadr[31:28]==4'd0 || vdadr[31:20]==12'hFFD) begin
		drdy <= 1'b1;
		missd <= 0;
		dc <= 0;
		dv <= 1;
	end
	else begin
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (tlb_v[{nn,vdadr[17:12]}] && vdadr[63:18]==tlb_vdadr[nn]) begin
				tdadr[63:12] <= tlb_tdadr[nn];
				missd <= 1'b0;
				drdy <= 1'b1;
				nnxd <= nn;
				dp <= tlb_dflags[nn][7:4];
				dc <= tlb_dflags[nn][3];
				dr <= tlb_dflags[nn][2];
				dx <= tlb_dflags[nn][1];
				dw <= tlb_dflags[nn][0];
				dv <= tlb_dflags[nn][2]|tlb_dflags[nn][1]|tlb_dflags[nn][0];
			end
	end
end


// The following state machine loads the tlb buffer on a
// miss.
always @(posedge clk_i)
if (rst_i) begin
	wb_nack();
	state <= S_WAIT_MISS;
	dbit  <= 0;
	whichSet <= 0;
	for (nn = 0; nn < pAssociativity * pTLB_size; nn = nn + 1)
		tlb_v[nn] <= 0;		// all entries are invalid on reset
	cpnp <= 1'b0;
	dpnp <= 1'b0;
end
else begin

	soc_o <= 0;
	// changing the address of the page table invalidates all entries
	if (invalidate_all || pta_changed)
		for (nn = 0; nn < pAssociativity * pTLB_size; nn = nn + 1)
			tlb_v[nn] <= 0;

	// handle invalidate command
	if (invalidate)
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (vcadr[63:18]==tlb_vcadr[nn])
				tlb_v[{nn,vcadr[17:12]}] <= 0;

	if (rst_cpnp)
		cpnp <= 1'b0;
	if (rst_dpnp)
		dpnp <= 1'b0;

	case (state)	// synopsys full_case parallel_case

	// Wait for a miss to occur. then initiate bus cycle
	// Output either the page directory address
	// or the page table address, depending on the
	// size of the app.
	S_WAIT_MISS:
		begin
			state <= S_WAIT_MISS;
			dbit <= wr;

			if (!cpnp && !dpnp && paging_en) begin
				if (missd) begin
					miss_adr <= vdadr;
					// try and pick an empty tlb entry
					whichSet <= cnt;
					for (nn = 0; nn < pAssociativity; nn = nn + 1)
						if (!tlb_v[{nn,vdadr[17:12]}])
							whichSet <= nn;
					choose_state();
				end
				else if (missc) begin
					miss_adr <= vcadr;
					// try and pick an empty tlb entry
					whichSet <= cnt;
					for (nn = 0; nn < pAssociativity; nn = nn + 1)
						if (!tlb_v[{nn,vcadr[17:12]}])
							whichSet <= nn;
					choose_state();
				end
				// If there's a write cycle, check to see if the
				// dirty bit is set. If the dirty bit hasn't been
				// set yet, then set it and write the dirty status
				// to memory.
				else if (wr && !tlb_dd[nnxd]) begin
					miss_adr <= vdadr;
					whichSet <= nnxd;
					choose_state();
				end
			end
		end

	S_RD_PTL5:	wb_reada({pte[31:12],miss_adr[63:57],3'b0}, S_RD_PTL5b);
	S_RD_PTL5b:	wb_readb(S_RD_PTL4);
	S_RD_PTL4:	wb_reada({pte[31:12],miss_adr[56:48],3'b0}, S_RD_PTL4b);
	S_RD_PTL4b:	wb_readb(S_RD_PTL3);
	S_RD_PTL3:	wb_reada({pte[31:12],miss_adr[47:39],3'b0}, S_RD_PTL3b);
	S_RD_PTL3b:	wb_readb(S_RD_PTL2);
	S_RD_PTL2:	wb_reada({pte[31:12],miss_adr[38:30],3'b0}, S_RD_PTL2b);
	S_RD_PTL2b:	wb_readb(S_RD_PTL1);
	S_RD_PTL1:	wb_reada({pte[31:12],miss_adr[29:21],3'b0}, S_RD_PTL1b);
	S_RD_PTL1b:	wb_readb(S_RD_PTL0);
	S_RD_PTL0:	wb_reada({pte[31:12],miss_adr[20:12],3'b0}, S_WR_PTL0);
	S_RD_PTL0b:	wb_readb(S_WR_TLB);
	S_WR_TLB:
		begin
			tlb_v[{whichSet,miss_adr[17:12]}] <= |pte[2:0];
			state <= S_WAIT_MISS;
			$display("WR_TLB: whichset=%d missadr=%h pte=%h", whichSet, miss_adr, pte);
		end

	// The tlb has been updated so the page must have been accessed
	// set the accessed bit for the page table entry
	// Also set dirty bit if a write access.
	S_WR_PTL0:
		if (!cyc_o) begin
			cyc_o <= 1;
			stb_o <= 1;
			wr_o  <= 1;
			byt_o <= 4'hF;
			adr_o <= {pte[31:12],miss_adr[20:12],3'b0};
			dat_o <= pte[31:0]|{1'b1,dbit,8'b0};
		end
		else if (ack_i) begin
			wb_nack();
			adrx <= adr_o + 32'd4;
			state <= S_RD_PTL0b;
		end

	//---------------------------------------------------
	// This state can't happen without a hardware error
	//---------------------------------------------------
	default:
		begin
			wb_nack();
			state <= S_WAIT_MISS;
		end

	endcase
end


// This counter is used to select the tlb entry that gets
// replaced when a new entry is entered into the buffer.
// It just increments every time an entry is updated. 
always @(posedge clk_i)
if (rst_i)
	cnt <= 0;
else if (state==S_WAIT_MISS && (missd|missc)) begin
	if (cnt == pAssociativity-1)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end

task wb_nack;
begin
	lock_o <= 1'b0;
	soc_o <= 1'b0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	wr_o <= 1'b0;
	byt_o <= 4'd0;
	adr_o <= 32'd0;
	dat_o <= 32'd0;
end
endtask

task wb_reada;
input [31:0] adr;
input [5:0] nxt;
begin
	if (!cyc_o) begin
		soc_o <= 1;
		cyc_o <= 1;
		stb_o <= 1;
		byt_o <= 4'hF;
		adr_o <= adr;
		lock_o <= 0;
	end
	else if (ack_i) begin
		wb_nack();
		adrx <= adr_o + 32'd4;
		pte[31:0] <= dat_i;
		state <= nxt;
	end
end
endtask

task wb_readb;
input [5:0] nxt;
begin
	if (!cyc_o) begin
		cyc_o <= 1;
		stb_o <= 1;
		byt_o <= 4'hF;
		adr_o <= adrx;
	end
	else if (ack_i) begin
		wb_nack();
		pte[63:32] <= dat_i;
		if (|pte[2:0])
			state <= nxt;
		else begin
			cpnp <= missc;
			dpnp <= missd;
			if (missc) cpte <= {dat_i,pte[31:0]};
			if (missd) dpte <= {dat_i,pte[31:0]};
			state <= S_WAIT_MISS;
		end
	end
end
endtask

task choose_state;
begin
	case(pta[2:0])
	3'd0:	state <= S_RD_PTL0;
	3'd1:	state <= S_RD_PTL1;
	3'd2:	state <= S_RD_PTL2;
	3'd3:	state <= S_RD_PTL3;
	3'd4:	state <= S_RD_PTL4;
	3'd5:	state <= S_RD_PTL5;
	default:	;
	endcase
	// Set page table address for lookup
	case(pta[2:0])
	3'b000:	pte <= {pta[31:12],miss_adr[20:12],3'b0};	// 2MB translations
	3'b001:	pte <= {pta[31:12],miss_adr[29:21],3'b0};	// 1GB translations
	3'b010:	pte <= {pta[31:12],miss_adr[38:30],3'b0};	// 512GB translations
	3'b011:	pte <= {pta[31:12],miss_adr[47:39],3'b0};	// 256TB translations
	3'b100:	pte <= {pta[31:12],miss_adr[56:48],3'b0};	// 128XB translations
	3'b101:	pte <= {pta[31:12],2'b00,miss_adr[63:57],3'b0};	//  translations
	default:	;
	endcase
end
endtask

endmodule

