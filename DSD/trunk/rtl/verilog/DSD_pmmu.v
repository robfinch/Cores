// ============================================================================
// (C) 2007-2016 Robert Finch
// All Rights Reserved.
// robfinch<remove>@opencores.ca
//
// DSD_mmu
//  - 64 bit CPU memory management unit
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
// ============================================================================
//
`ifndef TRUE
`define TRUE    1'b1
`define FALSE   1'b0
`endif
`define _8MBPG  5

module DSD_pmmu
#(
parameter
	pAssociativity = 8,		// number of ways (parallel compares)
	pTLB_size = 64,
	S_WAIT_MISS = 0,
	S_WR_PTL0 = 1,
	S_RD_PTL0 = 2,
	S_RD_PTL1 = 3,
	S_RD_PTL2 = 4,
	S_RD_PTL3 = 5,
	S_RD_PTL4 = 6,
	S_RD_PTL5 = 7,
	S_RD_PTL5_ACK = 8
)
(
// syscon
input rst_i,
input clk_i,

// master
output reg m_va_o,		// valid memory address
output reg m_lock_o,	// lock the bus
input      m_rdy_i,		// acknowledge from memory system
output reg m_wr_o,		// write enable output
output reg [ 7:0] m_byt_o,	// lane selects (always all active)
output reg [47:0] m_adr_o,
input      [63:0] m_dat_i,	// data input from memory
output reg [63:0] m_dat_o,	// data to memory

// Translation request / control
input invalidate,		// invalidate a specific entry
input invalidate_all,	// causes all entries to be invalidated
input [47:0] pta,		// page directory/table address register
output reg page_fault,

input [7:0] pl,

input vpa_i,
input vda_i,
input [7:0] sel_i,
input wr_i,				    // cpu is performing write cycle
input [63:0] vadr_i,	    // virtual address to translate
output reg [47:0] padr_o,	// translated address
output rdy_o,               // address translation is ready
output reg a_o,c_o,r_o,w_o,x_o,	// supervisor, cacheable, read, write and execute attributes
output reg v_o,			// translation is valid
output reg pv_o,
output vda_o,
output vpa_o,
output [7:0] sel_o,
output wr_o
);

integer nn;
reg [2:0] nnx;
reg [50:0] pte;			// holding place for data
reg [3:0] state;
reg [2:0] cnt;	// tlb replacement counter
reg [2:0] whichSet;		// which set to update
reg dbit;				// temp dirty bit
reg miss;
reg proc;
reg [63:0] miss_adr;
wire pta_changed;
assign rdy_o = !miss||page_fault;
wire pgen = pta[11];

wire [pAssociativity-1:0] tlb_d;
wire [ 5: 0] tlb_flags [pAssociativity-1:0];
wire [ 7: 0] tlb_pl [pAssociativity-1:0];
wire [63:19] tlb_vadr  [pAssociativity-1:0];
wire [34:0] tlb_tadr  [pAssociativity-1:0];

wire wr_tlb = state==S_WR_PTL0;
assign vpa_o = vpa_i & v_o & ~pv_o;
assign vda_o = vda_i & v_o & ~pv_o;
assign wr_o = wr_i & v_o & ~pv_o;
assign sel_o = sel_i & {8{v_o}} & {8{~pv_o}};

genvar g;
generate
	for (g = 0; g < pAssociativity; g = g + 1)
	begin : genTLB
		ram_ar1w1r #(45,pTLB_size) tlbVadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(miss_adr [63:19]),
			.o(tlb_vadr[g])
		);
		ram_ar1w1r #(35,pTLB_size) tlbTadr
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte[50:16]),
			.o(tlb_tadr[g])
		);
		ram_ar1w1r #( 6,pTLB_size) tlbFlag
		(
			.clk(clk_i),
			.ce(whichSet==g),
			.we(wr_tlb),
			.wa(miss_adr[18:13]),
			.ra(vadr_i[18:13]),
			.i(pte[ 5: 0]),
			.o(tlb_flags[g])
		);
		ram_ar1w1r #(8,pTLB_size) tlbPL
        (
            .clk(clk_i),
            .ce(whichSet==g),
            .we(wr_tlb),
            .wa(miss_adr[18:13]),
            .ra(vadr_i[18:13]),
            .i(pte[ 15: 8]),
            .o(tlb_pl[g])
        );
		ram_ar1w1r #( 1,pTLB_size) tlbD    
		(
			.clk(clk_i),
			.ce(wr_tlb?whichSet==g:nnx==g),
			.we(wr_tlb||state==S_WAIT_MISS && wr && !miss && vda_i),
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

// This must be fast !!!
// Lookup the virtual address in the tlb
// Translate the address
// I/O and system BIOS addresses are not mapped
// Cxxx_xxxx_xxxx_xxxx to FFFF_FFFF_FFFF_FFFF not mapped (kernel segment)
// 0000_0000_0000_0000 to 0000_0000_0000_xxxx not mapped (kernel data segement)
always @*
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
	padr_o[47:13] <= vadr_i[47:13];
	if (vadr_i[63:16]==48'h0 || vadr_i[63:20]==44'hFFFF_FFFF_FFD) begin
        miss <= 0;
        c_o <= 1;
        v_o <= 1;
    end
	else if (&vadr_i[47:46]) begin
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
			if (tlb_v[{nn,vadr_i[18:13]}] && vadr_i[63:19]==tlb_vadr[nn]) begin
			    if (tlb_flags[nn][`_8MBPG])
				    padr_o[47:13] <= {tlb_tadr[nn][34:10],vadr_i[22:13]};
			    else
				    padr_o[47:13] <= tlb_tadr[nn];
				miss <= 1'b0;
				nnx <= nn;
				a_o <= tlb_flags[nn][4];
				c_o <= tlb_flags[nn][3];
				r_o <= tlb_flags[nn][2];
				x_o <= tlb_flags[nn][1];
				w_o <= tlb_flags[nn][0];
				v_o <= tlb_flags[nn][2]|tlb_flags[nn][1]|tlb_flags[nn][0];
				pv_o <= vpa_i ? pl != tlb_pl[nn] && pl!=8'h00 : pl > tlb_pl[nn];
			end
	end
end


// The following state machine loads the tlb buffer on a
// miss.
always @(posedge clk_i)
if (rst_i) begin
	m_va_o <= 0;
	m_byt_o <= 8'h00;
	m_lock_o <= 0;
	m_wr_o  <= 0;
	m_adr_o <= 0;
	state <= S_WAIT_MISS;
	dbit  <= 0;
	whichSet <= 0;
	for (nn = 0; nn < pAssociativity * pTLB_size; nn = nn + 1)
		tlb_v[nn] <= 0;		// all entries are invalid on reset
    page_fault <= `FALSE;
end
else begin

    // page fault pulses
    page_fault <= `FALSE;

	// changing the address of the page table invalidates all entries
	if (invalidate_all || pta_changed)
		for (nn = 0; nn < pAssociativity * pTLB_size; nn = nn + 1)
			tlb_v[nn] <= 0;

	// handle invalidate command
	if (invalidate)
		for (nn = 0; nn < pAssociativity; nn = nn + 1)
			if (vadr_i[63:19]==tlb_vadr[nn])
				tlb_v[{nn,vadr_i[18:13]}] <= 0;

	case (state)	// synopsys full_case parallel_case

	// Wait for a miss to occur. then initiate bus cycle
	// Output either the page directory address
	// or the page table address, depending on the
	// size of the app.
	S_WAIT_MISS:
		begin
			state <= S_WAIT_MISS;
			dbit <= wr_i;
			proc <= `FALSE;

			if (miss) begin
			    proc <= `TRUE;
				miss_adr <= vadr_i;
				// try and pick an empty tlb entry
				whichSet <= cnt;
				for (nn = 0; nn < pAssociativity; nn = nn + 1)
					if (!tlb_v[{nn,vadr_i[18:13]}])
						whichSet <= nn;
				state <= S_RD_PTL5;
			end
			// If there's a write cycle, check to see if the
			// dirty bit is set. If the dirty bit hasn't been
			// set yet, then set it and write the dirty status
			// to memory.
			else if (vda_i && wr_i && !tlb_d[nnx]) begin
				miss_adr <= vadr_i;
				whichSet <= nnx;
				state <= S_RD_PTL5;
			end
		end

	S_RD_PTL5:
		begin
			m_va_o <= 1;
			m_byt_o <= 8'hFF;
			m_lock_o <= 0;
			m_wr_o  <= 0;
			case(pta[10:8])
			3'd0:	state <= S_RD_PTL0;
			3'd1:	state <= S_RD_PTL1;
			3'd2:	state <= S_RD_PTL2;
			3'd3:	state <= S_RD_PTL3;
			3'd4:	state <= S_RD_PTL4;
			3'd5:	state <= S_RD_PTL5_ACK;
			default:	;
			endcase
			// Set page table address for lookup
			case(pta[10:8])
			3'b000:	m_adr_o <= {pta[47:13],miss_adr[22:13],3'b0};	// 8MB translations
			3'b001:	m_adr_o <= {pta[47:13],miss_adr[32:23],3'b0};	// 8GB translations
			3'b010:	m_adr_o <= {pta[47:13],miss_adr[42:33],3'b0};	// 8TB translations
			3'b011:	m_adr_o <= {pta[47:13],miss_adr[52:43],3'b0};	// 8XB translations
			3'b100:	m_adr_o <= {pta[47:13],miss_adr[62:53],3'b0};	//     translations
			3'b101:	m_adr_o <= {pta[47:13],9'b00,miss_adr[63],3'b0};	//  translations
			default:	;
			endcase
		end
	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL5_ACK:
		if (m_rdy_i) begin
			if (|m_dat_i[2:0]) begin	// pte valid bit
				m_adr_o <= {m_dat_i[50:16],miss_adr[62:53],3'b0};
				state <= S_RD_PTL4;
			end
			else
			    raise_page_fault();
				// not a valid translation
				// OS messed up ?
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL4:
		if (m_rdy_i) begin
			if (|m_dat_i[2:0]) begin	// pte valid bit
				m_adr_o <= {m_dat_i[50:16],miss_adr[52:43],3'b0};
				state <= S_RD_PTL3;
			end
			else
			    raise_page_fault();
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL3:
		if (m_rdy_i) begin
			if (|m_dat_i[2:0]) begin	// pte valid bit
				m_adr_o <= {m_dat_i[50:16],miss_adr[42:33],3'b0};
				state <= S_RD_PTL2;
			end
			else
			    raise_page_fault();
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL2:
		if (m_rdy_i) begin
			if (|m_dat_i[2:0]) begin	// pte valid bit
				m_adr_o <= {m_dat_i[50:16],miss_adr[32:23],3'b0};
				state <= S_RD_PTL1;
			end
		    else
		        raise_page_fault();
		end

	// Wait for ack from system
	// Setup to access page table
	// If app uses a page directory, now address the page table
	S_RD_PTL1:
		if (m_rdy_i) begin
			if (|m_dat_i[2:0]) begin	// pte valid bit
			    // Shortcut 8MiB page ?
			    if (m_dat_i[`_8MBPG]) begin
			        pte <= m_dat_i[50:0];
			        m_wr_o <= 1;
        			m_dat_o <= m_dat_i|{dbit,2'b00,1'b1,4'b0};
                    state <= S_WR_PTL0;
			    end
			    else begin
				    m_adr_o <= {m_dat_i[50:16],miss_adr[22:13],3'b0};
				    state <= S_RD_PTL0;
				end
			end
			else
			    raise_page_fault();
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
		if (m_rdy_i) begin
			pte   <= m_dat_i[50:0];
			m_wr_o  <= 1;
			m_dat_o <= m_dat_i|{dbit,2'b00,1'b1,4'b0};
			state <= S_WR_PTL0;
		end

	S_WR_PTL0:
		if (m_rdy_i) begin
			m_va_o <= 0;
			m_byt_o <= 8'h00;
			m_lock_o <= 0;
			m_wr_o  <= 0;
			tlb_v[{whichSet,miss_adr[18:13]}] <= |pte[2:0];
			if (~|pte[2:0]) begin
			 if (proc)
			     page_fault <= `TRUE;
			end
			state <= S_WAIT_MISS;
		end

	//---------------------------------------------------
	// This state can't happen without a hardware error
	//---------------------------------------------------
	default:
		begin
			m_va_o <= 0;
			m_byt_o <= 8'h00;
			m_lock_o <= 0;
			m_wr_o  <= 0;
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
else if (state==S_WAIT_MISS && miss) begin
	if (cnt == pAssociativity-1)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end

task raise_page_fault;
begin
    m_va_o <= `FALSE;
    m_byt_o <= 8'h00;
    if (proc)
        page_fault <= `TRUE;
    proc <= `FALSE;
    state <= S_WAIT_MISS;
end
endtask

endmodule

