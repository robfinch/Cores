// ============================================================================
// Table888mmu.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
`include "Table888_defines.v"

module Table888mmu(
	rst_i, clk_i, clk_o, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, ack_i, err_i, sel_o, we_o, adr_o, dat_i, dat_o,
	mmu_cyc_o, mmu_stb_o, mmu_ack_i, mmu_sel_o, mmu_we_o, mmu_adr_o, mmu_dat_i, mmu_dat_o
);
input rst_i;
input clk_i;
output clk_o;
input nmi_i;
input irq_i;
input [8:0] vect_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg lock_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg [3:0] sel_o;
output reg we_o;
output reg [33:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

output mmu_cyc_o;
output mmu_stb_o;
input mmu_ack_i;
output [3:0] mmu_sel_o;
output mmu_we_o;
output [31:0] mmu_adr_o;
input [31:0] mmu_dat_i;
output [31:0] mmu_dat_o;

parameter RACK	= 16'd0;
parameter BOX	= 16'd0;
parameter BOARD = 16'd0;
parameter CHIP	= 16'd0;
parameter CORE	= 16'd0;
parameter PCMSB = 39;

// - - - - - - - - - - - - - - - - - -
// Machine states
// - - - - - - - - - - - - - - - - - -
parameter RESET = 6'd0;
parameter IFETCH = 6'd1;
parameter DECODE = 6'd2;
parameter EXECUTE = 6'd3;
parameter LOAD1 = 6'd4;
parameter LOAD2 = 6'd5;
parameter LOAD3 = 6'd6;
parameter LOAD4 = 6'd7;
parameter RTS1 = 6'd8;
parameter STORE1 = 6'd9;
parameter STORE2 = 6'd10;
parameter STORE3 = 6'd11;
parameter STORE4 = 6'd12;
parameter MULDIV = 6'd13;
parameter MULT1 = 6'd14;
parameter MULT2 = 6'd15;
parameter MULT3 = 6'd16;
parameter DIV = 6'd17;
parameter FIX_SIGN = 6'd18;
parameter MD_RES = 6'd19;
parameter ICACHE1 = 6'd20;
parameter ICACHE2 = 6'd21;
parameter IBUF1 = 6'd24;
parameter IBUF2 = 6'd25;
parameter IBUF3 = 6'd26;
parameter IBUF4 = 6'd27;
parameter LOADSEG = 6'd28;
parameter JGR2 = 6'd29;
parameter POP1 = 6'd30;
parameter PUSH1 = 6'd31;
parameter CINV1 = 6'd33;
parameter CINV2 = 6'd34;
parameter LINK1 = 6'd35;
parameter FLT1 = 6'd36;
parameter FLT2 = 6'd37;
parameter LOAD5 = 6'd41;
parameter LOAD6 = 6'd42;
parameter LOAD7 = 6'd43;
parameter DIV2 = 6'd44;
parameter RESET2 = 6'd45;
parameter RESET3 = 6'd46;
parameter CS_LOAD = 6'd54;
parameter SA_DELAY = 6'd56;
parameter SA_DELAY2 = 6'd57;
parameter OVERFLOW_TEST = 6'd58;
parameter VERIFY_DESC = 6'd59;
parameter JGR_STORE_SSSP = 6'd62;
parameter HANG = 6'd63;

// - - - - - - - - - - - - - - - - - -
// codes for load/store sizes
// - - - - - - - - - - - - - - - - - -
parameter word = 3'b110;
parameter half = 3'b101;
parameter uhalf = 3'b100;
parameter char = 3'b011;
parameter uchar = 3'b010;
parameter byt = 3'b001;
parameter ubyte = 3'b000;

wire [95:0] manufacturer = "Finitron    ";
wire [95:0] cpu_class = "Table888mmu ";
wire [95:0] cpu_name = "            ";
wire [63:0] features = {
	`FEAT_CLK_GATE,
	`FEAT_BITMAP,	// bitmap instructions
	`FEAT_BITFIELD,	// bitfield instructions
	`FEAT_DCACHE,	// DCACHE
	`FEAT_ICACHE,	// ICACHE
	`FEAT_PAGING,	// paging
	`FEAT_SEG	// segmentation
};
wire [63:0] model_no = "B       ";
wire [63:0] serial_no = "00000001";

reg [5:0] state;
reg [5:0] ret_state,ret_state2;
reg [3:0] jgr_state;
wire clk;
reg [63:0] cr0;
reg [63:0] pta;
wire paging_en = cr0[31];
`ifdef SUPPORT_ICACHE
wire cache_en = cr0[30];
`else
wire cache_en = 1'b0;		// Fixing this bit at zero should cause synthesis to strip out the i-cache code
`endif
wire pe = cr0[0];			// protection enable
`ifdef TMR
wire tmrb = cr0[9];			// bypass useless loads (biterr count not valid)
wire tmrx = cr0[8];			// triple mode redundancy execute
wire tmrw = cr0[7];			// triple mode redundancy writes
wire tmrr = cr0[6];			// triple mode redundancy reads
`else
wire tmrb = 1'b0;
wire tmrx = 1'b0;
wire tmrw = 1'b0;
wire tmrr = 1'b0;
`endif
reg [1:0] tmrcyc;			// tmr cycle number
reg [4:0] store_what;
reg [1:0] fmt;				// PC format to store
reg [39:0] ir;
`ifdef TMR_CACHE
wire [39:0] insn_a,insn_b,insn_c;
wire [39:0] insn = (insn_a & insn_b) | (insn_a & insn_c) | (insn_b & insn_c);
`else
wire [39:0] insn;
`endif
wire [7:0] opcode = ir[7:0];
wire [7:0] func = ir[39:32];
reg [PCMSB:0] pc,opc,prev_pc;
wire [PCMSB:0] segmented_pc;
wire [63:0] paged_pc;
reg [PCMSB:0] ibufadr;
wire ibufmiss = ibufadr != paged_pc[PCMSB:0];
reg [39:0] ibufx [3:0];		// instruction buffer
wire [39:0] ibuf = (ibufx[0] & ibufx[1]) | (ibufx[0] & ibufx[2]) | (ibufx[1] & ibufx[2]);
reg hist_capture;
reg [31:0] history_buf [63:0];
reg [5:0] history_ndx;
reg [5:0] history_ndx2;
reg [31:0] bithist [63:0];
reg [5:0] bithist_ndx;
reg [5:0] bithist_ndx2;
reg isInsnCacheLoad,isCacheReset;
reg isDescCacheLoad,isDescCacheReset;
reg nmi_edge,nmi1;
reg hwi;			// hardware interrupt indicator
reg im;				// irq interrupt mask bit
reg im2;			// pending irq mask
reg pv;				// privilege violation
reg [2:0] imcd;		// mask countdown bits
wire [31:0] sr = {23'd0,im,6'h00,pv,pe};
`ifdef TMR_REG
reg [63:0] regfile1 [255:0];
reg [63:0] regfile2 [255:0];
reg [63:0] regfile3 [255:0];
`else
reg [63:0] regfile [255:0];
`endif
reg [23:0] sregs [15:0];
reg [23:0] srfo;
reg [23:0] cs,ss,prev_cs;
reg [3:0] Sa,St;
always @(Sa,cs,ss)
case(Sa)
4'd14:	srfo <= ss;
4'd15:	srfo <= cs;
default:	srfo <= sregs[Sa];
endcase
reg mpcf;					// multi-precision carry
reg gie;						// global interrupt enable
wire [7:0] Ra = ir[15:8];
wire [7:0] Rb = ir[23:16];
wire [7:0] Rc = ir[31:24];
reg [7:0] Rt,RtPop,RtLW;
reg [7:0] Spr;		// special purpose register read port spec
reg [7:0] Sprt;
reg wrrf,wrsrf,wrspr;
reg [31:0] rwadr,rwadr2;
wire [31:0] rwadr_o;
//reg icacheOn;
wire uncachedArea = 1'b0;
wire ihit;
reg [2:0] ld_size, st_size;
reg swapSSSP;
reg isIndexed;
reg isRTS,isRTS2,isPUSH,isPOP,isIMM1,isIMM2,isCMPI;
reg isJSRix,isJSRdrn,isJMPix,isJMPix2,isBRK,isBRK2,isPLP,isRTI,isRTI2,isJGR,isJMP,isJMPdrn;
reg isShifti,isBSR,isLMR,isSMR;
reg isJSP,isJSR,isLWS,isLink,isUnlk;
reg isLSB,isLAR,isLSL,isVERR,isVERW,isVERX;
reg isLdDesc,isMTSEG;
reg isLFT,isSFT;
reg isLW;
reg isBM;
reg isCAS;
reg [2:0] nLD;
reg [23:0] jspbuf;
wire hasIMM = isIMM1|isIMM2;
wire hasJSP = isJSP;
wire hasPrefix = hasIMM | hasJSP;
reg [63:0] rfoa,rfob,rfoc;
reg [64:0] res;			// result bus
reg [63:0] res2;
reg [63:0] a,b,c;		// operand holding registers
reg [63:0] ca,cb;
reg [63:0] imm;
reg [63:0] pimm;		// previous immediate
reg [63:0] immbuf;
wire [63:0] bfo;		/// bitfield op output
reg [63:0] tick;		// tick count
reg [31:0] vbr;			// vector base register
reg [31:0] berr_addr;
reg [31:0] fault_pc;
reg [23:0] fault_cs;
reg [23:0] ocs;
reg [2:0] brkCnt;		// break counter for detecting multiple faults
reg cav;
wire dav;				// address is valid for mmu translation
reg [15:0] JOB;
reg [15:0] TASK;
reg [63:0] lresx [2:0];
wire [63:0] lres = (lresx[0] & lresx[1]) | (lresx[0] & lresx[2]) | (lresx[1] & lresx[2]);
reg [63:0] biterr_cnt;

assign dav=state==LOAD1||state==LOAD3||state==STORE1||state==STORE3;

wire cpnp,dpnp;
reg rst_cpnp,rst_dpnp;
wire [3:0] rpl = a[23:20];
wire [3:0] cpl = cs[23:20];
reg [3:0] ppl;
wire [63:0] cpte;
wire [63:0] dpte;
wire drdy;
wire data_readable;
wire data_writeable;
wire pmmu_data_readable;
wire pmmu_data_writeable;
wire page_executable;
reg isWR;
wire [3:0] pmmu_cpl;
wire [3:0] pmmu_dpl;
reg [31:0] ivno;
wire [63:0] logic_o;
wire [63:0] set_o;

reg [63:0] sp;	// stack pointer
reg [63:0] prev_sp;
wire [63:0] sp_inc = sp + 64'd8;
wire [63:0] sp_inc2 = sp + 64'd16;
wire [63:0] sp_dec = sp - 64'd8;
wire [63:0] sp_dec2 = sp - 64'd16;
`ifdef SUPPORT_STKCHECK
wire [2:0] nstk = (ir[39:32]!=8'h00) +
				  (ir[31:24]!=8'h00) +
				  (ir[23:16]!=8'h00) +
				  (ir[15: 8]!=8'h00);
`endif
// - - - - - - - - - - - - - - - - - -
// Convenience Functions
// - - - - - - - - - - - - - - - - - -

function [31:0] pc_inc;
input [31:0] pc;
begin
	case(pc[3:0])
	4'd0:	pc_inc = {pc[31:4],4'd5};
	4'd5:	pc_inc = {pc[31:4],4'd10};
	4'd10:	pc_inc = {pc[31:4],4'd0} + 32'd16;
	default:	pc_inc = `ALN_VECT;
	endcase
end
endfunction

// Overflow:
// Add: the signs of the inputs are the same, and the sign of the
// sum is different
// Sub: the signs of the inputs are different, and the sign of
// the sum is the same as B
function overflow;
input op;
input a;
input b;
input s;
begin
overflow = (op ^ s ^ b) & (~op ^ a ^ b);
end
endfunction

// - - - - - - - - - - - - - - - - - -
// Instanced Modules
// - - - - - - - - - - - - - - - - - -

icache_tagram u1 (
	.wclk(clk),
	.wr((ack_i & isInsnCacheLoad)|isCacheReset),
	.wa({adr_o[33:18],adr_o[15:0]}),
	.v(!isCacheReset),
	.rclk(~clk),
	.pc(paged_pc[31:0]),
	.hit(ihit)
);

wire [1:0] debug_bits;
`ifdef TMR_CACHE
icache_ram u2a (
	.wclk(clk),
	.wr(ack_i && isInsnCacheLoad && (adr_o[17:16]==2'b00 || !tmrx)),
	.wa(adr_o[13:0]),
	.i(dat_i),
	.rclk(~clk),
	.pc(paged_pc[13:0]),
	.insn(insn_a)
);
icache_ram u2b (
	.wclk(clk),
	.wr(ack_i && isInsnCacheLoad && (adr_o[17:16]==2'b01 || !tmrx)),
	.wa(adr_o[13:0]),
	.i(dat_i),
	.rclk(~clk),
	.pc(paged_pc[13:0]),
	.insn(insn_b)
);
icache_ram u2c (
	.wclk(clk),
	.wr(ack_i && isInsnCacheLoad && (adr_o[17:16]==2'b00 || adr_o[17:16]==2'b10 || !tmrx)),
	.wa(adr_o[13:0]),
	.i(dat_i),
	.rclk(~clk),
	.pc(paged_pc[13:0]),
	.insn(insn_c)
);
`else
icache_ram u2 (
	.wclk(clk),
	.wr(ack_i && isInsnCacheLoad),
	.wa(adr_o[13:0]),
	.i(dat_i),
	.rclk(~clk),
	.pc(paged_pc[13:0]),
	.insn(insn)
);
`endif

reg [63:0] ldt_reg;
reg [63:0] gdt_reg;
wire [31:0] ldt_base = ldt_reg[31:0];
wire [31:0] gdt_base = gdt_reg[31:0];
wire [19:0] ldt_entries = ldt_reg[63:44];
wire [19:0] gdt_entries = gdt_reg[63:44];
reg [31:0] desc_addr;
reg [127:0] desc_data;
wire [63:0] desc_base = desc_data[63:0];
wire [51:0] desc_limit = desc_data[115:64];
wire [11:0] desc_acr = desc_data[127:116];
wire [3:0] desc_dpl = desc_acr[3:0];
wire isCallGate = desc_acr[8:4]==5'b01100;
wire isConforming = desc_acr[6];
wire isPresent = desc_acr[11];
wire selectorIsNull = a[23:0]==24'd0;

reg [23:0] cg_selector;
reg [39:0] cg_offset;
reg [11:0] cg_acr;
wire [3:0] cg_dpl = cg_acr[3:0];
reg [4:0] cg_ncopy;
reg [5:0] ncopy;
reg [31:0] stack_fifo [31:0];

reg [127:0] desc_cache [15:0];
wire [127:0] cs_desc = desc_cache[15];
wire [127:0] ss_desc = desc_cache[14];
wire [127:0] srfo_desc = desc_cache[Sa];
wire [31:0] cs_base = cs_desc[31:0];
wire [31:0] cs_limit = cs_desc[95:64];
wire [11:0] cs_acr = cs_desc[127:116];
wire [31:0] ss_base = ss_desc[31:0];
wire [25:0] ss_lower_limit = ss_desc[89:64];
wire [25:0] ss_upper_limit = ss_desc[115:90];
wire [31:0] seg_base = srfo_desc[31:0];
wire [31:0] seg_limit = srfo_desc[95:64];
wire [11:0] seg_acr = srfo_desc[127:116];
//wire is_stack_seg = seg_acr[11:4]==8'h96;
wire [3:0] seg_dpl = seg_acr[3:0];
reg [31:0] prev_ss_base;

assign segmented_pc = {cs_base,12'h000} + pc;

Table888_pmmu u3
(
	// syscon
	.rst_i(rst_i),
	.clk_i(clk),

	// master
	.soc_o(mmu_soc_o),	// start of cycle
	.cyc_o(mmu_cyc_o),	// bus cycle active
	.stb_o(mmu_stb_o),
	.lock_o(),			// lock the bus
	.ack_i(mmu_ack_i),	// acknowledge from memory system
	.wr_o(mmu_we_o),	// write enable output
	.byt_o(mmu_sel_o),	// lane selects (always all active)
	.adr_o(mmu_adr_o),
	.dat_i(mmu_dat_i),	// data input from memory
	.dat_o(mmu_dat_o),	// data to memory

	// Translation request / control
	.paging_en(paging_en),
	.invalidate(),		// invalidate a specific entry
	.invalidate_all(),	// causes all entries to be invalidated
	.pta(pta),		// page directory/table address register
	.rst_cpnp(rst_cpnp),	// reset the pnp bit
	.rst_dpnp(rst_dpnp),
	.cpnp(cpnp),			// page not present
	.dpnp(dpnp),
	.cpte(cpte),	// holding place for data
	.dpte(dpte),

	.cav(1'b1),			// code address valid
	.vcadr({32'd0,segmented_pc}),	// virtual code address to translate
	.tcadr(paged_pc),	// translated code address
	.rdy(rdy),				// address translation is ready
	.p(pmmu_cpl),		// privilege (0= supervisor)
	.c(),
	.r(),
	.w(),
	.x(page_executable),	// cacheable, read, write and execute attributes
	.v(),			// translation is valid

	.wr(isWR),			// cpu is performing write cycle
	.dav(dav),					// data address is valid
	.vdadr({32'd0,rwadr}),		// virtual data address to translate
	.tdadr(rwadr_o),		// translated data address
	.drdy(drdy),			// address translation is ready
	.dp(pmmu_dpl),
	.dc(),
	.dr(pmmu_data_readable),
	.dw(pmmu_data_writeable),
	.dx(),
	.dv()
);

reg flt_cyc;
reg flt_wr;
reg [31:0] flt_adr;
reg [31:0] flt_dati;
wire [31:0] flt_dato;
wire [95:0] FAC1o;

wire flt_ack;
reg ldFAC;

Table888Float u_flt
(
	.rst_i(rst_i),
	.clk_i(clk),
	.cyc_i(flt_cyc),
	.stb_i(flt_cyc),
	.ack_o(flt_ack),
	.we_i(flt_wr),
	.adr_i(flt_adr),
	.dat_i(flt_dati),
	.dat_o(flt_dato),
	.ldFAC(ldFAC),
	.FAC1_i(desc_data[95:0]),
	.FAC1_o(FAC1o)
);

`ifdef SUPPORT_BITFIELD
Table888_bitfield u4
(
	.op(ir[39:36]),
	.a(a),
	.b(b),
	.m(ir[35:24]),
	.o(bfo),
	.masko()
);
`endif

Table888_logic u5
(
	.xIR(ir),
	.a(a),
	.b(b),
	.imm(imm),
	.o(logic_o)
);

Table888_set u6
(
	.xIR(ir),
	.a(a),
	.b(b),
	.imm(imm),
	.o(set_o)
);

// - - - - - - - - - - - - - - - - - -
// Combinational logic follows.
// - - - - - - - - - - - - - - - - - -
// register read ports
always @*
casex(Ra)
8'h00:	rfoa <= 64'd0;
8'hFE:	rfoa <= pc[39:0];
8'hFF:	rfoa <= sp;
`ifdef TMR_REG
default:	rfoa <= (regfile1[Ra] & regfile2[Ra]) | (regfile1[Ra] & regfile3[Ra]) | (regfile2[Ra] & regfile3[Ra]);
`else
default:	rfoa <= regfile[Ra];
`endif
endcase
always @*
case(Rb)
8'h00:	rfob <= 64'd0;
8'hFE:	rfob <= pc[39:0];
8'hFF:	rfob <= sp;
`ifdef TMR_REG
default:	rfob <= (regfile1[Rb] & regfile2[Rb]) | (regfile1[Rb] & regfile3[Rb]) | (regfile2[Rb] & regfile3[Rb]);
`else
default:	rfob <= regfile[Rb];
`endif
endcase
always @*
case(Rc)
8'h00:	rfoc <= 64'd0;
8'hFE:	rfoc <= pc[39:0];
8'hFF:	rfoc <= sp;
`ifdef TMR_REG
default:	rfoc <= (regfile1[Rc] & regfile2[Rc]) | (regfile1[Rc] & regfile3[Rc]) | (regfile2[Rc] & regfile3[Rc]);
`else
default:	rfoc <= regfile[Rc];
`endif
endcase

// Data input multiplexers
reg [7:0] dat8;
always @(dat_i or rwadr)
case(rwadr[1:0])
2'b00:	dat8 <= dat_i[7:0];
2'b01:	dat8 <= dat_i[15:8];
2'b10:	dat8 <= dat_i[23:16];
2'b11:	dat8 <= dat_i[31:24];
endcase
reg [15:0] dat16;
always @(dat_i or rwadr)
case(rwadr[1])
1'b0:	dat16 <= dat_i[15:0];
1'b1:	dat16 <= dat_i[31:16];
endcase
wire [31:0] dat32 = dat_i;


// Generate result flags for compare instructions
wire [64:0] cmp_res = a - (isCMPI ? imm : b);
reg nf,vf,cf,zf;
always @(cmp_res or a or b or imm or isCMPI)
begin
	cf <= ~cmp_res[64];
	nf <= cmp_res[63];
	vf <= overflow(1,a[63],isCMPI ? imm[63] : b[63], cmp_res[63]);
	zf <= cmp_res[63:0]==64'd0;
end

// Evaluate branches
// 
reg take_branch;
always @(a or opcode)
case(opcode)
`BRZ:	take_branch <= a==64'd0;
`BRNZ:	take_branch <= a!=64'd0;
`DBNZ:	take_branch <= a!=64'd0;
`BEQ:	take_branch <= a[1];
`BNE:	take_branch <= !a[1];
`BVS:	take_branch <= a[62];
`BVC:	take_branch <= !a[62];
`BMI:	take_branch <= a[63];
`BPL:	take_branch <= !a[63];
`BRA:	take_branch <= `TRUE;
`BRN:	take_branch <= `FALSE;
`BHI:	take_branch <= a[0] & !a[1];
`BHS:	take_branch <= a[0];
`BLO:	take_branch <= !a[0];
`BLS:	take_branch <= !a[0] | a[1];
`BGT:	take_branch <= (a[63] & a[62] & !a[1]) | (!a[63] & !a[62] & !a[1]);
`BGE:	take_branch <= (a[63] & a[62])|(!a[63] & !a[62]);
`BLT:	take_branch <= (a[63] & !a[62])|(!a[63] & a[62]);
`BLE:	take_branch <= a[1] | (a[63] & !a[62])|(!a[63] & a[62]);
default:	take_branch <= `FALSE;
endcase

// Shifts
wire [5:0] shamt = isShifti ? Rb[5:0] : b[5:0];
wire [127:0] shlo = {64'd0,a} << shamt;
wire [127:0] shro = {a,64'd0} >> shamt;
wire signed [63:0] as = a;
wire signed [63:0] asro = as >> shamt;

// Multiply / Divide / Modulus
reg [6:0] cnt;
reg res_sgn;
reg [63:0] aa, bb;
reg [63:0] q, r;
wire div_done;
wire [63:0] pa = a[63] ? -a : a;
wire [127:0] p1 = aa * bb;
reg [127:0] p;
wire [63:0] diff = r - bb;
// currency: 72.24 (21.7:7.2)

reg [63:0] ea;
wire [63:0] lea_drn = a + imm;
wire [63:0] lea_ndx = a + (b << ir[33:32]) + imm;
wire [63:0] ea_drn = lea_drn;
wire [63:0] ea_ndx = lea_ndx;
always @(isIndexed,ea_drn,ea_ndx)
if (isIndexed)
	ea <= ea_ndx;
else
	ea <= ea_drn;

wire [63:0] mr_ea = c;
`ifdef SUPPORT_BITMAP_FNS
wire [63:0] ea_bm = a + {(b >> 6),3'b000} + imm;
`endif
wire [63:0] gdt_adr = {gdt_base,12'h000} + {a[18:0],4'h0};
wire [63:0] ldt_adr = {ldt_base,12'h000} + {a[18:0],4'h0};
wire gdt_seg_limit_violation = a[18:0] > gdt_entries;
wire ldt_seg_limit_violation = a[18:0] > ldt_entries;

assign data_readable = pmmu_data_readable;
assign data_writeable = pmmu_data_writeable;

`ifdef SUPPORT_RNG
//-----------------------------------------------------------------------------
// Random number register:
//
// Uses George Marsaglia's multiply method.
//-----------------------------------------------------------------------------
reg [63:0] m_z;
reg [63:0] m_w;
reg [63:0] next_m_z;
reg [63:0] next_m_w;

always @(m_z or m_w)
begin
	next_m_z <= (36'd3696936969 * m_z[31:0]) + m_z[63:32];
	next_m_w <= (36'd1800018000 * m_w[31:0]) + m_w[63:32];
end

wire [63:0] rand = {m_z[31:0],32'd0} + m_w;
`endif

//-----------------------------------------------------------------------------
// Special Purpose Register File Read
//-----------------------------------------------------------------------------

reg [63:0] spro;
always @*
	casex(Spr)
	`TICK:	spro <= tick;
	`VBR:	spro <= vbr;
	`BEAR:	spro <= berr_addr;
	`PTA:	spro <= pta;
	`CR0:	spro <= cr0;
`ifdef SUPPORT_CLKGATE
	`CLK:	spro <= clk_throttle_new;
`endif
	`FAULT_PC:	spro <= fault_pc;
	`FAULT_CS:	spro <= fault_cs;
	`IVNO:		spro <= ivno;
	`HISTORY:	spro <= history_buf[history_ndx2];
`ifdef SUPPORT_RNG
	`RAND:		spro <= rand;
`endif
	`BITERR_CNT:	spro <= biterr_cnt;
	`BITHIST:	spro <= bithist[bithist_ndx2];
	`PROD_HIGH:	spro <= p[127:64];
	`LDT_REG:	spro <= ldt_reg;
	`GDT_REG:	spro <= gdt_reg;
	`SEGx:		spro <= srfo;
	default:	spro <= 65'd0;
	endcase

//-----------------------------------------------------------------------------
// Clock control
// - reset or NMI reenables the clock
// - this circuit must be under the clk_i domain
//-----------------------------------------------------------------------------
//
`ifdef SUPPORT_CLKGATE
reg cpu_clk_en;
reg [49:0] clk_throttle;
reg [49:0] clk_throttle_new;
reg ld_clk_throttle;

BUFGCE u20 (.CE(cpu_clk_en), .I(clk_i), .O(clk) );

reg lct1;
always @(posedge clk_i)
if (rst_i) begin
	cpu_clk_en <= 1'b1;
	nmi1 <= 1'b0;
	lct1 <= 1'b0;
	clk_throttle <= 50'h3FFFFFFFFFFFF;	// 100% power
end
else begin
	nmi1 <= nmi_i;
	lct1 <= ld_clk_throttle;
	if (ld_clk_throttle && !lct1)
		clk_throttle <= clk_throttle_new;
	else
		clk_throttle <= {clk_throttle[48:0],clk_throttle[49]};
	if (nmi_i)
		clk_throttle <= 50'h3FFFFFFFFFFFF;
	cpu_clk_en <= clk_throttle[49];
end
`else
assign clk = clk_i;
`endif
assign clk_o = clk;

//-----------------------------------------------------------------------------
// Clocked logic follows.
//-----------------------------------------------------------------------------

always @(posedge clk)
if (rst_i) begin
	cs <= 24'd1;
	pc <= `RST_VECT;
	ibufadr <= 32'h00000000;
	gie <= `FALSE;
	nmi_edge <= `FALSE;
	isInsnCacheLoad <= `FALSE;
	isDescCacheLoad <= `FALSE;
	isCacheReset <= `TRUE;
	isDescCacheReset <= `TRUE;
	wb_nack();
	adr_o[3:2] <= 2'b11;		// The tagram checks for this
	state <= RESET;
	store_what <= `STW_NONE;
	tick <= 64'd0;
	biterr_cnt <= 64'd0;
	vbr <= 32'h00006000;
	imcd <= 3'b111;
	pv <= `FALSE;
	cr0 <= 64'h00000000;		// turn on i-cache
	St <= 4'd0;
	rst_cpnp <= `TRUE;
	rst_dpnp <= `TRUE;
	isWR <= `FALSE;
	isJSP <= `FALSE;
	tmrcyc <= 2'd0;
	hist_capture <= `TRUE;
	history_ndx <= 6'd0;
	history_ndx2 <= 6'd0;
`ifdef SUPPORT_CLKGATE
	ld_clk_throttle <= `FALSE;
`endif
	ldt_reg <= 64'h7FFFF00000000002;
	gdt_reg <= 64'h7FFFF00000000001;
end
else begin
tick <= tick + 64'd1;
if (nmi_i & !nmi1)
	nmi_edge <= `TRUE;
wrrf <= `FALSE;
wrspr <= `FALSE;
`ifdef SUPPORT_CLKGATE
ld_clk_throttle <= `FALSE;
`endif
rst_cpnp <= `FALSE;
rst_dpnp <= `FALSE;
ldFAC <= 1'b0;
case(state)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// RESET:
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// - Invalidate the instruction cache
RESET:
	begin
		adr_o[3:2] <= 2'b11;		// The tagram checks for this
		adr_o[12:4] <= adr_o[12:4] + 9'd1;
		if (adr_o[12:4]==9'h1FF) begin
			adr_o[12:0] <= 13'd0;
			isCacheReset <= `FALSE;
			St <= 4'd0;
			next_state(RESET2);
		end
	end
// - reset the descriptor cache
// - Flat Model:
//   - base address of zero
//   - limit to the max
RESET2:
	begin
		St <= St + 4'd1;
		case(St)
		4'd14:	desc_cache[St] <= {12'h960,52'hFFFFFFC000000,64'h000000000000000};
		4'd15:	desc_cache[St] <= {12'h9A0,52'hFFFFFFFFFFFFF,64'h000000000000000};
		default:	desc_cache[St] <= {12'h920,52'hFFFFFFFFFFFFF,64'h000000000000000};
		endcase
		if (St==4'd15)
			next_state(IFETCH);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// IFETCH Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
IFETCH:
	begin
		hwi <= `FALSE;
		brkCnt <= 3'd0;
		tmrcyc <= 2'b00;
		if (rdy) begin
			if (hist_capture) begin
				history_buf[history_ndx] <= pc[31:0];
				history_ndx <= history_ndx + 1;
			end
			next_state(DECODE);
			if (nmi_edge & gie & ~hasPrefix) begin
				ir[7:0] <= `BRK;
				ir[39:8] <= {9'd510,4'h0};
				nmi_edge <= 1'b0;
				hwi <= `TRUE;
			end
			else if (irq_i & gie & ~im & ~hasPrefix) begin
				ir[7:0] <= `BRK;
				ir[39:8] <= {vect_i,4'h0};
				hwi <= `TRUE;
			end
			else if (!page_executable && pe)
				executable_fault();
			else if (!ihit & !uncachedArea & cache_en) begin
				next_state(ICACHE1);
			end
			else if (ibufmiss & (uncachedArea | !cache_en)) begin
				next_state(IBUF1);
			end
			else if (cache_en & !uncachedArea) begin
				begin
`ifdef TMR_CACHE
					if (tmrx && (insn_a!=insn_b || insn_a != insn_c || insn_b != insn_c))
						biterr_cnt <= biterr_cnt + 64'd1;
`endif
					ir <= insn;
				end
			end
			else begin
`ifdef TMRX
				if (tmrx && (ibufx[0]!=ibufx[1] || ibufx[0] != ibufx[2] || ibufx[1] != ibufx[2])) begin
					biterr_cnt <= biterr_cnt + 64'd1;
					bithist[bithist_ndx] <= pc;
					bithist_ndx <= bithist_ndx + 6'd1;
				end
`endif
				ir <= ibuf;
			end
			if (imcd != 3'b111) begin
				imcd <= {imcd,1'b0};
				if (imcd[2]==1'b0) begin
					im <= `FALSE;
					imcd <= 3'b111;
				end
			end
		end
		else if (cpnp)
			code_page_fault();
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache load machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ICACHE1:
`ifdef TMR
	begin
		isInsnCacheLoad <= `TRUE;
		wb_burst(6'd3,{paged_pc[31:16],tmrcyc,paged_pc[15:4],4'h0});
		next_state(ICACHE2);
	end
`else
	begin
		isInsnCacheLoad <= `TRUE;
		wb_burst(6'd3,{paged_pc[31:16],paged_pc[15:4],4'h0});
		next_state(ICACHE2);
	end
`endif
ICACHE2:
	if (ack_i) begin
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
		if (adr_o[3:2]==2'b10)
			cti_o <= 3'b111;
		if (adr_o[3:2]==2'b11) begin
			isInsnCacheLoad <= `FALSE;
			wb_nack();
			if (tmrx && tmrcyc != 2'b10) begin
				tmrcyc <= tmrcyc + 2'd1;
				next_state(ICACHE1);
			end
			else begin
				tmrcyc <= 2'b00;
				next_state(IFETCH);
			end
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction buffer load machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

IBUF1:
`ifdef TMR_BYPASS
	// Don't bother with the third load if the first two will win.
	if ((tmrcyc==2'b10) && (ibufx[0]==ibufx[1]) && tmrb) begin
		ibufx[2] <= ibufx[0];
		tmrcyc <= 2'b00;
		next_state(IFETCH);
	end
	else
`endif
`ifdef TMR
	begin
		wb_burst(6'd1,{paged_pc[31:16],tmrcyc,paged_pc[15:2],2'h0});
		next_state(IBUF2);
	end
`else
	begin
		wb_burst(6'd1,{paged_pc[31:16],paged_pc[15:2],2'h0});
		next_state(IBUF2);
	end
`endif
IBUF2:
	if (ack_i) begin
		cti_o <= 3'b111;
		adr_o <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	ibufx[tmrcyc][31:0] <= dat_i;
		2'b01:	ibufx[tmrcyc][23:0] <= dat_i[31:8];
		2'b10:	ibufx[tmrcyc][15:0] <= dat_i[31:16];
		2'b11:	ibufx[tmrcyc][7:0] <= dat_i[31:24];
		endcase
		next_state(IBUF3);
	end
IBUF3:
	if (ack_i) begin
		wb_nack();
		ibufadr <= paged_pc[PCMSB:0];
		case(pc[1:0])
		2'b00:	ibufx[tmrcyc][39:32] <= dat_i[7:0];
		2'b01:	ibufx[tmrcyc][39:24] <= dat_i[15:0];
		2'b10:	ibufx[tmrcyc][39:16] <= dat_i[23:0];
		2'b11:	ibufx[tmrcyc][39:8] <= dat_i;
		endcase
		if (tmrx)
			tmrcyc <= tmrcyc + 2'd1;
		if (tmrcyc==2'b10) begin
			tmrcyc <= 2'b00;
			next_state(IFETCH);
		end
		else if (tmrx)
			next_state(IBUF1);
		else
			next_state(IBUF4);
	end
// Set the buffers to be consistent for non-TMRX mode
IBUF4:
	begin
		ibufx[1] <= ibufx[0];
		ibufx[2] <= ibufx[0];
		next_state(IFETCH);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// DECODE Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
DECODE:
	begin
		next_state(EXECUTE);
		// OCS:OPC track the instruction's address which may be inherited
		// from the address of a prefix instruction. These are used to set
		// the fault cs:pc to allow the faulted instruction including any
		// prefix to be re-executed.
		if (!hasPrefix) begin
			opc <= pc;
			ocs <= cs;
		end
		if (!hwi) begin
			pc <= pc_inc(pc);
			if (pc[3:0] != 4'd0 && pc[3:0]!=4'd5 && pc[3:0]!=4'd10) begin
				fault_pc <= pc;
				fault_cs <= cs;
			end
		end
		// Default a number of signals. These defaults may be overridden later.
		isIMM1 <= `FALSE;
		isIMM2 <= `FALSE;
		isCMPI <= `FALSE;
		isBRK <= `FALSE;
		isBRK2 <= `FALSE;
		isBSR <= `FALSE;
		isJSR <= `FALSE;
		isJSP <= `FALSE;
		isJGR <= `FALSE;
		isJMP <= `FALSE;
		isJMPdrn <= `FALSE;
		isJSRdrn <= `FALSE;
		isJSRix <= `FALSE;
		isJMPix <= `FALSE;
		isJMPix2 <= `FALSE;
		isRTS <= `FALSE;
		isRTS2 <= `FALSE;
		isPOP <= `FALSE;
		isPUSH <= `FALSE;
		isPLP <= `FALSE;
		isRTI <= `FALSE;
		isRTI2 <= `FALSE;
		isLMR <= `FALSE;
		isSMR <= `FALSE;
		isLWS <= `FALSE;
		isBM <= `FALSE;
		isLFT <= `FALSE;
		isSFT <= `FALSE;
		isLW <= `FALSE;
		isCAS <= `FALSE;
		isMTSEG <= `FALSE;
		isIndexed <= `FALSE;
		jgr_state <= `JGR_NONE;
		nLD <= 3'b00;
		tmrcyc <= 2'b00;
		isShifti = func==`SHLI || func==`SHRI || func==`ROLI || func==`RORI || func==`ASRI;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		ld_size <= word;
		st_size <= word;
		Sa <= 4'b00;		// default: use code segment
		
		// Set the target register
		case(opcode)
		`R:	
			case(func)
			`MTSPR:	Rt <= 8'h00;	// We are writing to an SPR not the general register file
			default:	Rt <= ir[23:16];
			endcase
		`RR:	Rt <= ir[31:24];
		`LDI:	Rt <= ir[15:8];
		`DBNZ:	Rt <= ir[15:8];
		`BITFIELD:
			Rt <= ir[23:16];
		`ADDI,`ADDUI,`SUBI,`SUBUI,`CMPI,`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,
		`ANDI,`ORI,`EORI,
		`SLTI,`SLEI,`SGTI,`SGEI,`SLOI,`SLSI,`SHII,`SHSI,`SEQI,`SNEI,
		`JAL:
			Rt <= ir[23:16];
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA:
			begin
			Rt <= ir[23:16];
			RtLW <= ir[23:16];
			end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,`BMT:
			Rt <= ir[31:24];
		`CAS:
			Rt <= ir[39:32];
		`LINK,`UNLK,`RTD:
			Rt <= ir[15:8];
		default:
			Rt <= 8'h00;
		endcase

		// Set segment register selection for memory ops
		case(opcode)
		`R:
			case(func)
			`MFSPR:	Sa <= Ra[3:0];
			default:	Sa <= 4'd1;	// defaults to data segment
			endcase
		`LMR:	Sa <= ir[35:32];
		`SMR:	Sa <= ir[35:32];
		`CINV,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
		`SB,`SC,`SH,`SW:
				Sa <= ir[27:24];
		`CINVX,
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
		`SBX,`SCX,`SHX,`SWX,
		`BMS,`BMC,`BMF,`BMT:
				Sa <= ir[37:34];
		`CAS:	Sa <= 4'd13;	// volatile data segment; ToDo: fix seg selection Sa
		`JGR:	Sa <= 4'd14;
		`JSR_IX,`JMP_IX:	Sa <= ir[19:16];
		default:	Sa <= 4'd1;	// defaults to data segment
		endcase
		
		// The only segment register updateable outside of the MTSPR
		// instruction is the code segment. So we set it to default
		// here rahter than "all over the place".
		// It won't be updated unless the wrspr signal is active.
		if (opcode==`R && func==`MTSPR && ir[23:20]==4'h2)
			St <= ir[19:16];
		else
			St <= 4'd15;

		// Set special purpose target register. Once again updated 
		// only when wrspr is active.
		Spr <= ir[15:8];
		Sprt <= ir[23:16];

		// Immediate value multiplexer
		case(opcode)
		`BRK:		imm <= hwi ? ir[39:8] : {vbr[31:0],ir[20:8]};
		`JSP,`JGR:	imm <= ir[39:16];
		`JSR_IX,`JMP_IX:
					imm <= hasIMM ? {immbuf[43:0],ir[39:20]} : {{44{ir[39]}},ir[39:20]};
		`LDI:		imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : {{40{ir[39]}},ir[39:16]};
		`JMP_DRN:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : {{40{ir[39]}},ir[39:16]};
		`JSR_DRN:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : {{40{ir[39]}},ir[39:16]};
		`PUSHC,`JMP,`JSR:
					imm <= hasIMM ? {immbuf[31:0],ir[39:8]} : {{32{ir[39]}},ir[39:8]};
		`PEA,`CINV,
		`LFT,`SFT,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA,
		`SB,`SC,`SH,`SW:
					imm <= hasIMM ? {immbuf[51:0],ir[39:28]} : {{52{ir[39]}},ir[39:28]};
		`JSRX,
		`LMR,`SMR,
		`PEAX,`CINVX,
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX,
		`BMS,`BMC,`BMF,`BMT,
		`CAS:		imm <= hasIMM ? immbuf[63:0] : 64'd0;
		default:	imm <= hasIMM ? {immbuf[47:0],ir[39:24]} : {{48{ir[39]}},ir[39:24]};
		endcase

		// This case statement decodes all instructions.
		case(opcode)
		`NOP:	next_state(IFETCH);
		`R:
			case(func)
			`MRK1:	next_state(IFETCH);
			`MRK2:	next_state(IFETCH);
			`MRK3:	next_state(IFETCH);
			`MRK4:	next_state(IFETCH);
			`STP:	begin clk_throttle_new <= 50'd0; ld_clk_throttle <= `TRUE; end
			`SEI:	begin 
						if (cpl > 0 && pe)
							privilege_violation();
						else begin
							im <= `TRUE;
							next_state(IFETCH);
						end
					end
			`CLI:	begin
						if (cpl > 0 && pe)
							privilege_violation();
						else begin
							imcd <= 3'b110;
							next_state(IFETCH);
						end
					end
			`CLP:	begin pv <= `FALSE; next_state(IFETCH); end
//			`PROT:	begin pe <= `TRUE; next_state(IFETCH); end
			`ICON:	begin cr0[30] <= `TRUE; next_state(IFETCH); end
			`ICOFF:	begin cr0[30] <= `FALSE; next_state(IFETCH); end
			`PHP:
				begin
					store_what <= `STW_SR;
					push1();
				end
			`PLP:
				begin
					isPLP <= `TRUE;
					pop1();
				end
			`RTI:
				begin
					hist_capture <= `TRUE;
					if (cpl[3] && pe)
						privilege_violation();
					else begin
						isRTI <= `TRUE;
						isRTI2 <= `TRUE;
						pop2();
					end
				end

			// It generates less hardware to give load_seg it's own state
			// and step to that state rather than calling the load_seg macro.
			// The cost is an additional clock cycle.
			`VERR:
				begin
					isVERR <= `TRUE;
					ret_state <= IFETCH;
					next_state(LOADSEG);
				end
			`VERW:
				begin
					isVERW <= `TRUE;
					ret_state <= IFETCH;
					next_state(LOADSEG);
				end
			`VERX:
				begin
					isVERX <= `TRUE;
					ret_state <= IFETCH;
					next_state(LOADSEG);
				end
			`LSL:	begin
					isLSL <= `TRUE;
					ret_state <= IFETCH;
					next_state(LOADSEG);
					end
			`LAR:
				begin
					isLAR <= `TRUE;
					ret_state <= IFETCH;
					next_state(LOADSEG);
				end
			`LSB:	begin
					isLSB <= `TRUE;
					ret_state <= IFETCH;
					next_state(LOADSEG);
					end
			`FIX2FLT:	flt_op1(`CMD_FIX2FLT);
			`FLT2FIX:	flt_op1(`CMD_FLT2FIX);
			`FLTSTAT:	flt_op1(`CMD_STAT);
			`FMOV:		flt_op1(`CMD_MOVE);

			// Unimplemented instruction
			default:	;
			endcase
		`RR:
			case(func)
			`FADD:	flt_op2(`CMD_ADD);
			`FSUB:	flt_op2(`CMD_SUB);
			`FCMP:	flt_op2(`CMD_CMP);
			`FMUL:	flt_op2(`CMD_MUL);
			`FDIV:	flt_op2(`CMD_DIV);
			`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:	next_state(MULDIV);
			endcase

		`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI:	next_state(MULDIV);
		`CMPI:	isCMPI <= `TRUE;


		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Flow Control Instructions Follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`BRK:
			begin
				$display("*****************");
				$display("*****************");
				$display("BRK");
				$display("*****************");
				$display("*****************");
				rwadr <= {vbr[31:0],ir[20:12],4'h0};
				ivno <= ir[20:12];
				hist_capture <= `FALSE;
				isBRK <= `TRUE;
				isBRK2 <= `TRUE;
				ppl <= cpl;
				prev_pc <= pc;
				prev_cs <= cs;
				prev_sp <= sp;
				prev_ss_base <= ss_base;
				// Double fault ?
				brkCnt <= brkCnt + 3'd1;
				if (brkCnt > 3'd2)
					next_state(HANG);
				else begin
					next_state(LOAD1);
				end
				$stop;
			end
		`JMP:
			begin
				isJMP <= `TRUE;
				pc <= ir[39:8];		// should prepend immbuf in case of constant extension
				cg_offset <= ir[39:8];	// Only useful for JSP
				cg_ncopy <= 5'd0;
				a <= 64'd0;
				if (!hasJSP)
					next_state(IFETCH);
				// Rule is can only transfer to code at the same priv level.
				// Should check that CPL==RPL or privilege violation
				// if (cpl != jspbuf[23:20])
				//     privilege_violation();
			end
		`JMP_DRN:
			begin
				isJMPdrn <= `TRUE;
			end
		`BSR:
			begin
				isBSR <= `TRUE;
				store_what <= `STW_PC;
				fmt <= 2'b00;
				push2();
			end
		`JSR:
			begin
				isJSR <= `TRUE;
				isJSP <= isJSP;
				a <= 64'd0;
				// We could test if the high-order bits of the PC are zero
				// here, but we know they are in the sample.
				// if (hasJSP && pc[63:48]!=16'd0)
				//     store_what <= `STW_CS;
				// else
				if (!hasJSP) begin
					store_what <= `STW_PC;
					fmt <= 2'b00;
					//ea <= ir[39:8];
					push2();
				end
			end
		// The difference between JSR and JSR_DN is only that JSR sets
		// 'a' to zero.
		`JSR_DRN:
			begin
				isJSR <= `TRUE;
				isJSP <= isJSP;
				if (!hasJSP) begin
					store_what <= `STW_PC;
					fmt <= 2'b00;
				    push2();
				end
			end
		// The only difference between JSR_DRN and JSRX is that the 
		// indexed flag is set.
		`JSRX:
			begin
				isJSR <= `TRUE;
				isJSP <= isJSP;
				isIndexed <= `TRUE;
				if (!hasJSP) begin
					store_what <= `STW_PC;
					fmt <= 2'b00;
				    push2();
				end
			end
		`RTS:
			begin
				isRTS <= `TRUE;
				isRTS2 <= `TRUE;
				ppl <= cpl;
				rwadr <= {ss_base,12'h000} + sp;
`ifdef SUPPORT_STKCHECK
				if (sp_inc2 + ir[31:16] > {ss_upper_limit,12'hFFF} && pe)
					bounds_violation();
				else
`endif
				begin
					next_state(LOAD1);
					update_sp(sp_inc2 + ir[31:16]);
				end
			end
		`LFT:	isLFT <= `TRUE;
		`SFT:	begin isSFT <= `TRUE; flt_op1(`CMD_READREG); end
		`PEAX,`CINVX,
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX,
		`BMS,`BMC,`BMF,`BMT:
				isIndexed <= `TRUE;

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// PUSH / POP
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		
		// PUSH needs to capture the output of rfoa in the decode stage.
		`PUSH:
			begin
				isPUSH <= `TRUE;
				store_what <= `STW_A;
				rwadr <= {ss_base,12'h000} + sp_dec[31:0];
`ifdef SUPPORT_STKCHECK
				if (sp_dec[31:0] < {ss_lower_limit,12'h000} + {nstk,3'b000})
					stack_fault();
				else
`endif
				begin
					ir[39:8] <= {8'h00,ir[39:16]};
					if (ir[39:8]==32'h0) begin
						isWR <= `FALSE;
						next_state(IFETCH);
					end
					else if (ir[15:8]==8'h00) begin
						pc <= pc;
						next_state(DECODE);
					end
					else begin
						pc <= pc;
						isWR <= `TRUE;
						update_sp(sp_dec);
						next_state(STORE1);
					end
				end
			end

		`POP:
			begin
				isPOP <= `TRUE;
				next_state(POP1);
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Push a constant onto the stack, used surprisingly often.
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`PUSHC:
			begin
				store_what <= `STW_IMM;
				push1();
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Prefixes follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`JSP:
			begin
				isJSP <= `TRUE;
			end
		`IMM1:
			begin
				isIMM1 <= `TRUE;
				immbuf <= {{32{ir[39]}},ir[39:8]};
				next_state(IFETCH);
			end
		`IMM2:
			begin
				isIMM2 <= `TRUE;
				immbuf[63:32] <= ir[39:8];
				next_state(IFETCH);
			end
		
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Mystery Operations
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`EXEC:
			begin
				ir <= rfoa;
				next_state(DECODE);
			end
		`MYST_R:
			begin
				ir[7:0] <= 8'h01;
				ir[23:16] <= ir[31:24];
				ir[39:32] <= rfob;
				next_state(DECODE);
			end
		`MYST_RR:
			begin
				ir[7:0] <= 8'h02;
				ir[31:24] <= ir[39:32];
				ir[39:32] <= rfoc;
				next_state(DECODE);
			end
		endcase
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// EXECUTE Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
EXECUTE:
	begin
		next_state(IFETCH);

		// This case statement execute instructions.
		case(opcode)
		`R:
			case(func)
			`SWAP:	res <= {a[31:0],a[63:32]};
			`MOV:	res <= a;
			`NEG:	begin
					res <= -a;
					$stop;
					end
			`COM:	res <= ~a;
			`NOT:	res <= ~|a;
			`SXB:	res <= {{56{a[7]}},a[7:0]};
			`SXC:	res <= {{48{a[15]}},a[15:0]};
			`SXH:	res <= {{32{a[31]}},a[31:0]};
			`MOVS:	begin
						res <= spro;
						wrspr <= `TRUE;
					end
			`MFSPR:	begin
					res <= spro;
					if (Ra==8'h0D)
						history_ndx2 <= history_ndx2 + 6'd1;
					if (Ra==8'h0F)
						bithist_ndx2 <= bithist_ndx2 + 6'd1;
					end
			`MTSPR:	begin
						res <= a;
						wrspr <= `TRUE;
						ret_state <= IFETCH;
						// We allow MTSPR cs,Rn for now which will likely hang 
						// the program if someone wants to be an idiot. The
						// issue is reducing the complexity of the processor.
						if (Sprt[7:4]==4'h2) begin
							isMTSEG <= `TRUE;
							next_state(LOADSEG);
/*
							if (Sprt[3:0] != 4'd15) begin	// Can't MTSPR cs,Rn
								isMTSEG <= `TRUE;
								load_seg();
							end
							else
								illegal_insn();
*/
						end
					end
`ifdef SUPPORT_RNG
			`GRAN:
				begin
					res <= rand;
					m_z <= next_m_z;
					m_w <= next_m_w;
				end
`endif
`ifdef SUPPORT_CPUID
			`CPUID:
				begin
					case(a[3:0])
					4'd0:	res <= manufacturer[63: 0];
					4'd1:	res <= manufacturer[95:64];
					4'd2:	res <= cpu_class[63:0];
					4'd3:	res <= cpu_class[95:64];
					4'd4:	res <= cpu_name[63:0];
					4'd5:	res <= cpu_name[95:64];
					4'd6:	res <= model_no;
					4'd7:	res <= serial_no;
					4'd8:	res <= features;
					4'd12:	res <= {RACK,BOX,BOARD,CHIP};
					4'd13:	res <= {CORE,48'h0000};
					default:	res <= 65'd0;
					endcase
				end
`endif
			endcase
		`RR:
			case(func)
			`ADD:	begin
					res <= a + b;
`ifdef SUPPORT_OVERFLOW
					next_state(OVERFLOW_TEST);
`endif
					end
			`ADDU:	res <= a + b;
			`SUB:	begin
					res <= a - b;
`ifdef SUPPORT_OVERFLOW
					next_state(OVERFLOW_TEST);
`endif
					end
			`SUBU:	res <= a - b;
`ifdef SUPPORT_MPC
			`ADC:		res <= a + b + mpcf;
			`SBC:		res <= a - b - mpcf;
`endif
			`CMP:		res <= {nf,vf,60'd0,zf,cf};
			`AND,`OR,`EOR,`ANDN,`NAND,`NOR,`ENOR,`ORN:		
						res <= logic_o;
			`SHLI,`SHL:	res <= shlo[63:0];
			`ROLI,`ROL: res <= shlo[127:64]|shlo[63:0];
			`RORI,`ROR:	res <= shro[127:64]|shro[63:0];
			`SHRI,`SHR:	res <= shro[127:64];
			`ASRI,`ASR:	res <= asro;
/*
			`ARPL:
				begin
					if (a[63:60] < b[63:60])
						res <= {b[63:60],a[59:0]};
					else
						res <= a;
				end
*/
			`SLT,`SLE,`SGT,`SGE,`SLO,`SLS,`SHI,`SHS,`SEQ,`SNE:
				res <= set_o;
			// Unimplemented instruction
			default:	res <= 65'd0;
			endcase
		`BITFIELD:	res <= bfo;
		`LDI:	res <= imm;
		`ADDI,`ADDUI:	res <= a + imm;
		`SUBI,`SUBUI:	res <= a - imm;
		`CMPI:	res <= {nf,vf,60'd0,zf,cf};
		`ANDI,`ORI,`EORI:	res <= logic_o;
		`SLTI,`SLEI,`SGTI,`SGEI,`SLOI,`SLSI,`SHII,`SHSI,`SEQI,`SNEI:
			res <= set_o;
		
		`LINK:	begin
				isLink <= `TRUE;
				wrrf <= `TRUE;
				res <= a - imm;						// SUBUI SP,SP,#imm
				ir <= {16'h0000,Rb,Ra,`SW};			// SW BP,[SP]
				next_state(LINK1);					// need time to update and read reg
				end
		`UNLK:
			begin
				isUnlk <= `TRUE;
				pimm <= imm;
				wrrf <= `TRUE;
				res <= b;							// MOV SP,BP
				ir <= {16'h0000,Rb,Ra,`LW};			// LW BP,[SP]
				next_state(LINK1);					// need cycle to update SP
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Flow Control Instructions Follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`BEQ,`BNE,`BVS,`BVC,`BMI,`BPL,`BRA,`BRN,`BGT,`BGE,`BLT,`BLE,`BHI,`BHS,`BLO,`BLS,
		`BRZ,`BRNZ,`DBNZ:
			begin
				next_state(IFETCH);
				if (take_branch) begin
					pc[11: 0] <= ir[27:16];
					pc[PCMSB:12] <= pc[PCMSB:12] + {{PCMSB-20{ir[36]}},ir[36:28]};
				end
				res <= a - 64'd1;	// for DBNZ (it won't update for other branches)
			end
		// For indirect jump we fall through into the RTS code. Both
		// instructions operate the same way, differing in only the source
		// address of the address to transfer control to.
		`JMP_IX:
			begin
				isRTS <= `TRUE;
				isRTS2 <= `TRUE;
				ppl <= cpl;
				load_check(ea);
			end
		`JMP_DRN:	
			begin
				if (hasJSP) begin
					isJGR <= `TRUE;
					next_state(LOADSEG);
					a <= jspbuf;
					ppl <= cpl;
					prev_sp <= sp;
					prev_ss_base <= ss_base;
					prev_pc <= pc;
					prev_cs <= cs;
					cg_ncopy <= 5'd0;
					cg_offset <= ea;
					jgr_state <= `JGR_LOAD_CALLGATE;
					//store_what <= `STW_CSPC;
				end
				else begin
					pc <= ea;
					next_state(IFETCH);
				end
			end
		`JSR_IX:
			begin	
				isJSRix <= `TRUE;
				prev_pc <= pc;
				prev_cs <= cs;
				prev_sp <= sp;
				prev_ss_base <= ss_base;
				ppl <= cpl;
				load_check(ea);
			end
/*
		`JAL:
			begin
				res <= pc;
				pc <= ea;
			end
		`RTD:
			begin
				pc <= b;
				res <= a + imm;
			end
*/
		`JSP:
			begin
				isJSP <= `TRUE;
				jspbuf <= a[23:0] | imm[23:0];
			end
		`JSR,`JMP,`JSR_DRN,`JSRX:
			begin
				//if (cpl != jspbuf[23:20])
				//	privilege_violation();
				//else
					next_state(LOADSEG);
				isJGR <= `TRUE;
				a <= jspbuf;
				ppl <= cpl;
				prev_sp <= sp;
				prev_ss_base <= ss_base;
				prev_pc <= pc;
				prev_cs <= cs;
				cg_ncopy <= 5'd0;
				cg_offset <= ea;
				jgr_state <= `JGR_LOAD_CALLGATE;
			end
		`JGR:
			begin
				isJGR <= `TRUE;
				next_state(LOADSEG);
				jspbuf <= a[23:0] | imm[23:0];
				a <= a[23:0] | imm[23:0];
				ppl <= cpl;
				prev_sp <= sp;
				prev_ss_base <= ss_base;
				prev_pc <= pc;
				prev_cs <= cs;
				jgr_state <= `JGR_LOAD_CALLGATE;
//				if (sp_dec < seg_base[14] + 32'd32)
//					stack_fault();
//				else begin
//					isWR <= `TRUE;
//					rwadr <= {seg_base,12'h000} + sp_dec[31:0];
//					update_sp(sp_dec);
//					store_what <= `STW_CS;
//					next_state(STORE1);
//				end
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// LMR / SMR
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`LMR:
			begin
				isLMR <= `TRUE;
				Rt <= Ra;
				rwadr <= {seg_base,12'h000} + mr_ea;
				next_state(LOAD1);
			end
		`SMR:
			begin
				isSMR <= `TRUE;
				isWR <= `TRUE;
				rwadr <= {seg_base,12'h000} + mr_ea;
				store_what <= `STW_A;
				next_state(STORE1);
			end
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Loads and Stores follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`LB,`LBX:
			begin
				ld_size <= byt;
				load_check(ea);
			end
		`LBU,`LBUX:
			begin
				ld_size <= ubyte;
				load_check(ea);
			end
		`LC,`LCX:
			begin
				ld_size <= char;
				load_check(ea);
			end
		`LCU,`LCUX:
			begin
				ld_size <= uchar;
				load_check(ea);
			end
		`LH,`LHX:
			begin
				ld_size <= half;
				load_check(ea);
			end
		`LHU,`LHUX:
			begin
				ld_size <= uhalf;
				load_check(ea);
			end
		`LW,`LWX:
			begin
				isLW <= `TRUE;
				ld_size <= word;
				load_check(ea);
				if (isUnlk)
					update_sp(sp + pimm);	// ADDUI SP,SP,#locs
				isUnlk <= `FALSE;
			end
		`LFT:
			begin
				ld_size <= word;
				load_check(ea);
			end
		`CAS:
			begin
				isCAS <= `TRUE;
				ld_size <= word;
				load_check(ea);
			end
		`LEA,`LEAX:	res <= ea;
		`LWS:
			begin
				isLWS <= `TRUE;
				ld_size <= word;
				load_check(ea);
			end
`ifdef SUPPORT_BITMAP_FNS
		`BMS,`BMC,`BMF,`BMT:
			begin
				isBM <= `TRUE;
				load_check(ea_bm);
			end
`endif
		`SB:
			begin
				st_size <= byt;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea);
			end
		`SC:
			begin
				st_size <= char;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea);
			end
		`SH:
			begin
				st_size <= half;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea);
			end
		`SW:
			begin
				st_size <= word;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea);
				if (isLink) begin		// MOV BP,SP
					Rt <= Rb;
					res <= a;
				end
				isLink <= `FALSE;
			end
		`SWS:
			begin
				st_size <= word;
				isWR <= `TRUE;
				store_what <= `STW_SPR;
				store_check(ea);
			end
		`CINV:
			begin
				Rt <= Rb;
				cache_check(ea);
			end
		`SBX:
			begin
				st_size <= byt;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea);
			end
		`SCX:
			begin
				st_size <= char;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea);
			end
		`SHX:
			begin
				st_size <= half;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea);
			end
		`SWX:
			begin
				st_size <= word;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea);
			end
		`CINVX:
			begin
				Rt <= Rc;
				cache_check(ea);
			end
		`PEA,`PEAX:
			begin
				store_what <= `STW_IMM;
				imm <= ea;
				push1();
			end

	// Unimplemented opcodes handled here
		default:
			;
		endcase
	end

`ifdef SUPPORT_OVERFLOW
// Check for overflow
OVERFLOW_TEST:
	begin
		next_state(IFETCH);
		case(opcode)
		`RR:
			case(func)
			`ADD:	if (overflow(0,a[63],b[63],res[63]))
						overflow_trap();
			`SUB:	if (overflow(1,a[63],b[63],res[63]))
						overflow_trap();
			`MUL:	if (p[127:64] != {64{p[63]}})
						overflow_trap();
			`MULU:	if (p[127:64] != 64'd0)
						overflow_trap();
			endcase
		endcase
	end
`endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

POP1:
	begin
		ir[39:8] <= {8'h00,ir[39:16]};
		RtPop <= ir[15:8];
		if (ir[39:8]==32'h0)
			next_state(IFETCH);
		else if (ir[15:8]==8'h00)
			next_state(POP1);
		else
			pop1();
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOADSEG:
	begin
		load_seg();
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 7'd64;
		case(opcode)
		`MULUI:
			begin
				aa <= a;
				bb <= imm;
				res_sgn <= 1'b0;
				next_state(MULT1);
			end
		`MULI:
			begin
				aa <= a[63] ? -a : a;
				bb <= imm[63] ? ~imm+64'd1 : imm;
				res_sgn <= a[63] ^ imm[63];
				next_state(MULT1);
			end
		`DIVUI,`MODUI:
			begin
				aa <= a;
				bb <= imm;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIVI,`MODI:
			begin
				aa <= a[63] ? ~a+64'd1 : a;
				bb <= imm[63] ? ~imm+64'd1 : imm;
				q <= pa[62:0];
				r <= pa[63];
				res_sgn <= a[63] ^ imm[63];
				next_state(DIV);
			end
		`RR:
			case(func)
			`MULU:
				begin
					aa <= a;
					bb <= b;
					res_sgn <= 1'b0;
					next_state(MULT1);
				end
			`MUL:
				begin
					aa <= a[63] ? -a : a;
					bb <= b[63] ? -b : b;
					res_sgn <= a[63] ^ b[63];
					next_state(MULT1);
				end
			`DIVU,`MODU:
				begin
					aa <= a;
					bb <= b;
					q <= a[62:0];
					r <= a[63];
					res_sgn <= 1'b0;
					next_state(DIV);
				end
			`DIV,`MOD:
				begin
					aa <= a[63] ? -a : a;
					bb <= b[63] ? -b : b;
					q <= pa[62:0];
					r <= pa[63];
					res_sgn <= a[63] ^ b[63];
//					if (b==64'd0)
//						divide_by_zero();
//					else
						next_state(DIV);
				end
			default:
				state <= IFETCH;
			endcase
		endcase
	end
// Three wait states for the multiply to take effect. These are needed at
// higher clock frequencies. The multipler is a multi-cycle path that
// requires a timing constraint.
MULT1:	state <= MULT2;
MULT2:	state <= MULT3;
MULT3:	begin
			p <= p1;
			next_state(res_sgn ? FIX_SIGN : MD_RES);
		end
DIV:
	begin
		q <= {q[62:0],~diff[63]};
		if (cnt==7'd0) begin
			next_state(res_sgn ? FIX_SIGN : MD_RES);
			if (diff[63])
				r <= r[62:0];
			else
				r <= diff[62:0];
		end
		else begin
			if (diff[63])
				r <= {r[62:0],q[63]};
			else
				r <= {diff[62:0],q[63]};
		end
		cnt <= cnt - 7'd1;
	end

FIX_SIGN:
	begin
		next_state(MD_RES);
		if (res_sgn) begin
			p <= -p;
			q <= -q;
			r <= -r;
		end
	end

MD_RES:
	begin
		if (opcode==`MULI || opcode==`MULUI || (opcode==`RR && (func==`MUL || func==`MULU)))
			res <= p[63:0];
		else if (opcode==`DIVI || opcode==`DIVUI || (opcode==`RR && (func==`DIV || func==`DIVU)))
			res <= q[63:0];
		else
			res <= r[63:0];
		next_state(IFETCH);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
FLT1:
	if (flt_ack) begin
		flt_cyc <= 1'b0;
		flt_wr <= 1'b0;
		res <= flt_dato;
		if (opcode==`R && func==`FLTSTAT)
			wrrf <= `TRUE;
		else if (opcode==`RR && func==`FCMP) begin
			wrrf <= `TRUE;
			res <= {flt_dato[6],61'b0,flt_dato[5],1'b0};
		end
		else
			Rt <= 8'h00;
		if (isSFT) begin
			st_size <= word;
			isWR <= `TRUE;
			store_what <= `STW_FACL;
			store_check(ea);
		end
		else
			next_state(IFETCH);
	end

// After a load FAC to write data to the target FP reg.
FLT2:
	begin
		flt_cyc <= 1'b1;
		flt_wr <= 1'b1;
		flt_adr <= 32'hFFDEA210;
		flt_dati <= {ir[23:16],8'h00,8'h00,`CMD_WRITEREG};
		next_state(FLT1);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Memory Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// LOAD machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOAD1:
`ifdef TMR_BYPASS
	// bypass "useless" load in TMR mode.
	if (lresx[0]==lresx[1] && tmrcyc==2'b10 && tmrb) begin
		if (ld_size==word)
			next_state(LOAD5);
		else
			next_state(LOAD7);
		lresx[2] <= lresx[0];
	end
	else
`endif
	if (drdy) begin
		if (cpl > pmmu_dpl && pe)
			privilege_violation();
		else if (data_readable || !pe) begin
			if (isCAS)
				lock_o <= `TRUE;
			wb_read(ld_size,rwadr_o);
			next_state(LOAD2);
		end
		else
			data_read_fault();
	end
	else if (dpnp)
		data_page_fault();
LOAD2:
	begin
		if (ack_i) begin
			rwadr <= rwadr + 32'd4;
			wb_nack();
			if (ld_size==word) begin
				lresx[tmrcyc][31:0] <= dat32;
				next_state(LOAD3);
			end
			else begin
				case(ld_size)
				uhalf:	lresx[tmrcyc] <= {32'd0,dat32};
				half:	lresx[tmrcyc] <= {{32{dat32[31]}},dat32};
				uchar:	lresx[tmrcyc] <= {48'd0,dat16};
				char:	lresx[tmrcyc] <= {{48{dat16[15]}},dat16};
				ubyte:	lresx[tmrcyc] <= {56'd0,dat8};
				byt:	lresx[tmrcyc] <= {{56{dat8[7]}},dat8};
				default:	lresx[tmrcyc][31:0] <= dat32;
				endcase
				if (tmrr) begin
					tmrcyc <= tmrcyc + 2'd1;
					if (tmrcyc==2'd2) begin
						tmrcyc <= 2'd0;
						next_state(LOAD7);
					end
					else begin
						rwadr <= rwadr;
						next_state(LOAD1);
					end
				end
				else
					next_state(LOAD6);
			end
		end
		else if (err_i)
			bus_err();
	end
LOAD3:
	if (drdy) begin
		if (cpl > pmmu_dpl && pe)
			privilege_violation();
		else if (data_readable || !pe) begin
			wb_read(word,rwadr_o);
			next_state(LOAD4);
		end
		else
			data_read_fault();
	end
	else if (dpnp)
		data_page_fault();
LOAD4:
	if (ack_i) begin
		rwadr <= rwadr + 32'd4;
		wb_nack();
		lresx[tmrcyc][63:32] <= dat32;
		if (tmrr) begin
			tmrcyc <= tmrcyc + 2'd1;
			if (tmrcyc==2'd2) begin
				tmrcyc <= 2'd0;
				next_state(LOAD5);
			end
			else begin
				rwadr <= rwadr - 32'd4;
				next_state(LOAD1);
			end
		end
		else begin
			next_state(LOAD5);
			lresx[1] <= {dat32,lresx[0][31:0]};
			lresx[2] <= {dat32,lresx[0][31:0]};
		end
	end
	else if (err_i)
		bus_err();
LOAD5:
	begin
		// Accumulate bit errs for TMR mode
		if (lresx[0]!=lresx[1] || lresx[0]!=lresx[2] || lresx[1] != lresx[2]) begin
			biterr_cnt <= biterr_cnt + 64'd1;
			bithist[bithist_ndx] <= pc;
			bithist_ndx <= bithist_ndx + 6'd1;
		end
		// This fudge needed for the UNLK instruction. There are three target
		// registers specified during the execution of UNLK.
		if (isLW)
			Rt <= RtLW;
		res <= lres;
		case(1'b1)
		isLWS:
			begin
				wrspr <= `TRUE;
				next_state(IFETCH);
			end
		isLMR:
			begin
				wrrf <= `TRUE;
				if (Rt==Rb)
					next_state(IFETCH);
				else
					next_state(LOAD1);
			end
		isLFT:
			begin
				if (nLD==2'b00) begin
					nLD <= nLD + 2'd1;
					desc_data <= lres;
					next_state(LOAD1);
				end
				else begin
					ldFAC <= 1'b1;
					nLD <= 2'b00;
					desc_data[127:64] <= lres;
					next_state(FLT2);
				end
			end
		isRTS:
			begin
				if (nLD==2'b00) begin
					nLD <= nLD + 2'd1;
					pc[39:2] <= lres[39:2];
					pc[1:0] <= lres[3:2];
					cg_offset[39:2] <= lres[39:2];
					cg_offset[1:0] <= lres[3:2];
					cg_ncopy <= 5'd0;
					case(lres[1:0])
					2'b00:	// Short format, no segment info
						next_state(IFETCH);
					2'b01:	// FAR return/jump - short format
						begin
							a <= lres[63:40];
							isRTS <= `FALSE;
							isJGR <= `TRUE;
							next_state(CS_LOAD);
						end
					2'b10:	// FAR return/jump - long format
						next_state(LOAD1);
					2'b11:	// interrupt return
						begin
							isRTS <= `FALSE;
							isRTS2 <= `FALSE;
							isRTI <= `TRUE;
							isRTI2 <= `TRUE;
							next_state(LOAD1);
						end
					endcase
				end
				// FAR return/jump - long format
				else begin
					nLD <= 2'b00;
					a <= lres[23:0];
					isRTS <= `FALSE;
					isJGR <= `TRUE;
					next_state(CS_LOAD);
				end
			end
		// Almost the same as an RTS
		isJSRix:
			begin
				if (nLD==2'b00) begin
					nLD <= nLD + 2'd1;
					pc[39:2] <= lres[39:2];
					pc[1:0] <= lres[3:2];
					cg_offset[39:2] <= lres[39:2];
					cg_offset[1:0] <= lres[3:2];
					cg_ncopy <= 5'd0;
					// Short format, no segment info
					if (lres[1:0]==2'b00) begin
						rwadr <= {ss_base,12'h000} + sp_dec2;
						store_what <= `STW_PREV_PC;
						fmt <= 2'b00;
						if (sp_dec2 < {ss_lower_limit,12'h000})
							stack_fault();
						else begin
							update_sp(sp_dec2);
							next_state(STORE1);
						end
					end
					// FAR jump - short format
					else if (lres[1:0]==2'b01) begin
						a <= lres[23:0];
						isJGR <= `TRUE;
						isJSRix <= `FALSE;
						next_state(CS_LOAD);
					end
					else begin
						next_state(LOAD1);
					end
				end
				// FAR jump - long format
				else begin
					nLD <= 2'b00;
					a <= lres[23:0];
					isJGR <= `TRUE;
					isJSRix <= `FALSE;
					next_state(CS_LOAD);
				end
			end
		// Could check for a gate type here, 86x or 87x, but that'd
		// be more hardware, so we'll just assume it's okay.
		isBRK:
			begin
				if (nLD==2'b00) begin
					nLD <= nLD + 2'd1;
					pc[39:2] <= lres[39:2];
					pc[1:0] <= lres[3:2];
					cg_offset[39:2] <= lres[39:2];
					cg_offset[1:0] <= lres[3:2];
					cg_ncopy <= 5'd0;
					next_state(LOAD1);
				end
				else begin
					isBRK <= `FALSE;
					isJGR <= `TRUE;
					nLD <= 2'b00;
					if (!lres[56])
						im2 <= 1'b1;
					else
						im2 <= im;
					a <= lres[23:0];
					next_state(CS_LOAD);
				end
			end
		// Could check for a bad return address format.
		// Currently just assumes the format is correct.
		isRTI:
			begin
				if (nLD==2'b00) begin
					pc[39:2] <= lres[39:2];
					pc[1:0] <= lres[3:2];
					cg_offset[39:2] <= lres[39:2];
					cg_offset[1:0] <= lres[3:2];
					cg_ncopy <= 5'd0;
					nLD <= nLD + 2'd1;
					next_state(LOAD1);
				end
				else begin
					nLD <= 2'b00;
					isRTI <= `FALSE;
					isJGR <= `TRUE;
					if (lres[40]==1'b0)
						imcd <= 3'b110;
					else
						im <= 1'b1;
					a <= lres[23:0];
					next_state(CS_LOAD);
				end
			end
		isPOP:
			begin
				wrrf <= `TRUE;
				Rt <= RtPop;
				next_state(POP1);
			end
		isPLP:
			begin
				if (lres[8]==1'b0)
					imcd <= 3'b110;
				else
					im <= 1'b1;
				next_state(IFETCH);
			end
		isCAS:
			begin
				if (b==lres) begin
					st_size <= word;
					isWR <= `TRUE;
					store_what <= `STW_C;
					store_check(ea_drn);
				end
				else begin
				    lock_o <= `FALSE;
					next_state(IFETCH);
				end
			end
		isMTSEG:
			begin
				if (nLD==2'd0) begin
					nLD <= nLD + 2'd1;
					desc_data[63:0] <= lres;
					next_state(LOAD1);
				end
				else begin
					nLD <= 2'd0;
					desc_data[127:64] <= lres;
					next_state(VERIFY_DESC);
				end
			end
		isJGR:
			begin
				case(jgr_state)
				`JGR_LOAD_CALLGATE:
					begin
						if (nLD==2'b00) begin
							desc_data[63:0] <= lres;
							nLD <= nLD + 2'd1;
							next_state(LOAD1);
						end
						else begin
							nLD <= 2'd0;
							desc_data[127:64] <= lres;
							jgr_state <= `JGR_LOAD_CS;
							next_state(VERIFY_DESC);
						end
					end
				`JGR_LOAD_CS:
					begin
						if (nLD==2'b00) begin
							desc_data[63:0] <= lres;
							nLD <= nLD + 2'd1;
							next_state(LOAD1);
						end
						else begin
							nLD <= 2'd0;
							desc_data[127:64] <= lres;
							St <= 4'd15;
							next_state(VERIFY_DESC);
						end
					end
				`JGR_LOAD_FIFO:
					begin
						ncopy <= ncopy - 6'd1;
						stack_fifo[ncopy] <= lres;
						if (ncopy==6'd0) begin
							Sa <= 4'd12;	// TSS
							next_state(JGR_STORE_SSSP);
						end
						else
							next_state(LOAD1);
					end
				`JGR_LOAD_SP:
					begin
						sp <= lres;
						jgr_state <= `JGR_LOAD_SS;
						next_state(LOAD1);
					end
				`JGR_LOAD_SS:
					begin
						Sprt <= 8'h2E;
						wrspr <= `TRUE;
//						ss <= lres[23:0];
						a <= lres[23:0];
						St <= 4'd14;
						next_state(LOADSEG);
						jgr_state <= `JGR_LOAD_SS_DESC;
					end
				`JGR_LOAD_SS_DESC:
						if (nLD==2'b00) begin
							desc_data[63:0] <= lres;
							nLD <= nLD + 2'd1;
							next_state(LOAD1);
						end
						else begin
							nLD <= 2'd0;
							desc_data[127:64] <= lres;
							St <= 4'd14;
							next_state(VERIFY_DESC);
						end
				endcase
			end
/*
Bitmap functions make the processor about 5% larger and have limited
usefullness. Usually one would want to manipulate bitmaps a word-at-a
time for performance reasons. Other functions like count leadings ones
or zero maybe more valuable.
*/
`ifdef SUPPORT_BITMAP_FNS
		isBM:
			begin
				store_what <= `STW_A;
				if (ir[7:0]!=`BMT)
					store_check(rwadr - 32'd4);
				case(ir[7:0])
				`BMS:	a <= {lres} | ( 64'd1 << b[5:0] );
				`BMC:	a <= {lres} & ~( 64'd1 << b[5:0] );
				`BMF:	a <= {lres} ^ ( 64'd1 << b[5:0] );
				`BMT:	res <= ({lres} >> b[5:0]) & 64'd1;
				endcase
			end
`endif
		default:
			next_state(IFETCH);
		endcase
	end

// If not triple mode redundant and less than a word in size, cause the TMR
// logic to work out to the value loaded.
LOAD6:
	begin
		lresx[1] <= lresx[0];
		lresx[2] <= lresx[0];
		next_state(LOAD7);
	end

// After a triple mode load of less than a word size has completed, the loaded
// value is placed on the result bus.
// Accumulate the bit errs.
LOAD7:
	begin
		if (lresx[0]!=lresx[1] || lresx[0]!=lresx[2] || lresx[1] != lresx[2]) begin
			biterr_cnt <= biterr_cnt + 64'd1;
			bithist[bithist_ndx] <= pc;
			bithist_ndx <= bithist_ndx + 6'd1;
		end
		res <= lres;
		next_state(IFETCH);
	end

// This state used after a code segment change to load the segment information.
CS_LOAD:
	begin
		ret_state <= IFETCH;
		jgr_state <= `JGR_LOAD_CS;
		St <= 4'd15;
		next_state(LOADSEG);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// STORE machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STORE1:
	begin
	if (drdy) begin	
		if (cpl > pmmu_dpl)
			privilege_violation();
		else if (data_writeable) begin
			next_state(STORE2);
			case (store_what)
			`STW_A:		wb_write(st_size,rwadr_o,a[31:0]);
			`STW_B:		wb_write(st_size,rwadr_o,b[31:0]);
			`STW_C:		wb_write(st_size,rwadr_o,c[31:0]);
			`STW_PC:	wb_write(word,rwadr_o,{pc[31:2],fmt});
			`STW_SR:	wb_write(word,rwadr_o,sr);
			`STW_SPR:	wb_write(word,rwadr_o,spro[31:0]);
			`STW_IMM:	wb_write(word,rwadr_o,imm[31:0]);
			`STW_SP:	wb_write(word,rwadr_o,sp[31:0]);
			`STW_SS:	wb_write(word,rwadr_o,{8'h00,ss});
			`STW_PREV_PC:	wb_write(word,rwadr_o,{prev_pc[31:2],fmt});
			`STW_PREV_CSSR:	wb_write(word,rwadr_o,{8'h00,prev_cs});
			`STW_STK_FIFO:	wb_write(half,rwadr_o,stack_fifo[ncopy]);
			`STW_FACL:	wb_write(word,rwadr_o,FAC1o[31:0]);
			`STW_FACH:	wb_write(half,rwadr_o,FAC1o[95:64]);
			default:	next_state(RESET);	// hardware fault
			endcase
		end
		else
			data_write_fault();
	end
	else if (dpnp)
		data_page_fault();
	end
STORE2:
	if (ack_i) begin
		wb_nack();
		rwadr <= rwadr + 32'd4;
		if (st_size==word)
			next_state(STORE3);
		else begin
			if (tmrw) begin
				tmrcyc <= tmrcyc + 2'd1;
				if (tmrcyc==2'd2) begin
					tmrcyc <= 2'd0;
					if (store_what==`STW_STK_FIFO) begin
						ncopy <= ncopy - 6'd1;
						if (ncopy != 6'd0)
							next_state(STORE1);
						else begin
							isWR <= `FALSE;
							rwadr <= {ss_base,12'h000} + {sp_dec2[31:3],3'b00};
							store_what <= `STW_PREV_PC;
							fmt <= 2'b10;
							update_sp(sp_dec2);
							next_state(STORE1);
						end
					end
					else begin
						isWR <= `FALSE;
						next_state(IFETCH);
					end
				end
				else begin
					rwadr <= rwadr;
					next_state(STORE1);
				end
			end
			else begin
				if (store_what==`STW_STK_FIFO) begin
					ncopy <= ncopy - 6'd1;
					if (ncopy != 6'd0)
						next_state(STORE1);
					else begin
						isWR <= `FALSE;
						rwadr <= {ss_base,12'h000} + {sp_dec2[31:3],3'b00};
						store_what <= `STW_PREV_PC;
						fmt <= 2'b10;
						update_sp(sp_dec2);
						next_state(STORE1);
					end
				end
				else begin
					isWR <= `FALSE;
					next_state(IFETCH);
				end
			end
		end
	end
	else if (err_i)
		bus_err();
STORE3:
	if (drdy) begin
		if (cpl > pmmu_dpl)
			privilege_violation();
		else if (data_writeable) begin
			next_state(STORE4);
			case (store_what)
			`STW_A:		wb_write(word,rwadr_o,a[63:32]);
			`STW_B:		wb_write(word,rwadr_o,b[63:32]);
			`STW_C:		wb_write(word,rwadr_o,c[63:32]);
			`STW_PC:	wb_write(word,rwadr_o,{cs,pc[39:32]});
			`STW_SR:	wb_write(word,rwadr_o,32'd0);
			`STW_SPR:	wb_write(word,rwadr_o,spro[63:32]);
			`STW_IMM:	wb_write(word,rwadr_o,imm[63:32]);
			`STW_SP:	wb_write(word,rwadr_o,sp[63:32]);
			`STW_SS:	wb_write(word,rwadr_o,32'h0);
			`STW_PREV_PC:	wb_write(word,rwadr_o,prev_pc[39:32]);
			`STW_PREV_CSSR:	wb_write(word,rwadr_o,sr);
			`STW_FACL:	wb_write(word,rwadr_o,FAC1o[63:32]);
			default:	next_state(RESET);	// hardware fault
			endcase
			if (isSMR && (!tmrw || (tmrw && tmrcyc==2'b10)))
				ir[15:8] <= ir[15:8] + 8'd1;
		end
		else
			data_write_fault();
	end
	else if (dpnp)
		data_page_fault();
STORE4:
	if (ack_i) begin
		wb_nack();
		rwadr <= rwadr + 32'd4;
		if (tmrw) begin
			tmrcyc <= tmrcyc + 2'd1;
			if (tmrcyc==2'd2)
				tmrcyc <= 2'd0;
			else begin
				rwadr <= rwadr - 32'd4;
				next_state(STORE1);
			end
		end
		if (!tmrw || tmrcyc==2'd2) begin
		    lock_o <= `FALSE;
			if (isSFT) begin
				store_what <= `STW_FACH;
				st_size <= half;
				next_state(STORE1);
			end
			else if (isSMR) begin
				a <= rfoa;
				if (Ra>Rb || Ra==0) begin
					isWR <= `FALSE;
					next_state(IFETCH);
				end
				else
					next_state(STORE1);
			end
			else if (isBSR)	begin
				pc[11: 0] <= ir[27:16];
				pc[39:12] <= pc[39:12] + {{16{ir[39]}},ir[39:28]};
				isWR <= `FALSE;
				next_state(IFETCH);
			end
			else if (isJGR) begin
				case(store_what)
				`STW_SP:
					begin
						store_what <= `STW_SS;
						next_state(STORE1);
					end
				`STW_SS:
					begin
						jgr_state <= `JGR_LOAD_SP;
						rwadr <= {seg_base,12'h000} + 32'h800 + {cpl,4'h0};
						next_state(LOAD1);
					end
				`STW_PREV_PC:
					begin
						store_what <= `STW_PREV_CSSR;
						next_state(STORE1);
					end
				`STW_PREV_CSSR:
					begin
						if (isBRK2)
							im <= im2;
						next_state(IFETCH);
					end
				endcase
/*
				else if (store_what==`STW_CS) begin
					store_what <= `STW_PC;
					next_state(STORE1);
				end
*/
/*
				else begin
					isWR <= `FALSE;
					if (a[19])
						rwadr <= ldt_adr;
					else
						rwadr <= gdt_adr;
					next_state(LOAD1);
				end
*/
			end
			else if (isJSR)	begin
				isWR <= `FALSE;
				/*
				if (hasJSP) begin
					
					if (nLD==3'b000) begin
						nLD <= nLD + 3'd1;
						rwadr <= {seg_base,12'h000} + 32'h800 + {cpl,4'h0};
						store_what <= `STW_SP;
						next_state(STORE1);
					end
					if (rpl <= cpl) begin
						pc[31:0] <= imm[31:0];
						pc[39:32] <= imm[39:32];
						a <= jspbuf;
						jgr_state <= `JGR_LOAD_CS;
						next_state(CS_LOAD);
					end
					else
						privilege_violation();
				end
				else*/ begin
					pc <= ea;
					next_state(IFETCH);
				end
			end
			else if (isJSRix) begin
				isWR <= `FALSE;
				//rwadr <= rwadr2;
				//next_state(LOAD1);
				next_state(IFETCH);
			end
			else if (isPUSH)
				next_state(DECODE);
			else begin
				isWR <= `FALSE;
				next_state(IFETCH);
			end
		end
	end
	else if (err_i)
		bus_err();

JGR_STORE_SSSP:
	begin
		isWR <= `TRUE;
		rwadr <= {seg_base,12'h000} + 32'h800 + {ppl,4'h0};
		store_what <= `STW_SP;
		next_state(STORE1);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Cache invalidate machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CINV1:
	begin
		adr_o <= {rwadr[31:4],2'b11,2'b00};
		if (Rt==8'h00)
			isCacheReset <= `TRUE;
		// else reset data cache
		Rt <= 8'h00;
		next_state(CINV2);
	end
CINV2:
	begin
		isCacheReset <= `FALSE;
		next_state(IFETCH);
	end

HANG:
	next_state(HANG);
LINK1:
	next_state(DECODE);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Perform protection checks on the loaded descriptor.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

VERIFY_DESC:
	begin
		res <= 65'd0;
/*
		// Is the segment resident in memory ?
		if (!isPresent && !selectorIsNull) begin
			if (isLAR|isLSL)
				res <= 65'hFFFFFFFFFFFFFFFF;
			else if (isVERR|isVERW|isVERX|isLSB)
				;
			else begin
				if (St==4'd14)
					stack_fault();
				else
					segment_not_present();
			end
		end
		// are we trying to load a non-code segment into the code segment ?
		else if ((St==4'd15||isVERX) && !(isLAR|isLSL|isLSB|isVERW|isVERR) && desc_acr[8:7]!=2'b11 && pe && !selectorIsNull) begin
			if (isVERX)
				;
			else
				segtype_violation();
		end
		// are we trying to load a code segment into a data segment ?
		else if ((St!=4'd15||isVERR||isVERW) && !(isVERX|isLAR|isLSL|isLSB) && desc_acr[8:7]==2'b11 && pe && !selectorIsNull) begin
			if (isVERR|isVERW)
				;
			else
				segtype_violation();
		end
		// are we trying to load a non-stack segment into a stack segment ?
		else if ((St==4'd14||isVERR||isVERW) && !(isVERX|isLAR|isLSL|isLSB) && desc_acr[6]!=1'b1 && pe && !selectorIsNull) begin
			if (isVERR|isVERW)
				;
			else
				segtype_violation();
		end
		// The code privilege level must be the same or higher (numerically
		// lower) than the data descriptor privilege level.
//		// CPL <= DPL
		else if ((St!=4'd15||isCallGate||isVERR||isVERW||isLSL||isLAR||isLSB) && cpl > desc_dpl && pe && !selectorIsNull) begin	// data segment
			if (isLAR|isLSL)
				res <= 65'hFFFFFFFFFFFFFFFF;
			else if (isVERR||isVERW||isLSB)
				;
			else
				privilege_violation();
		end
		else if ((St==4'd15||isVERX) && !(isVERR|isVERW|isLAR|isLSB|isLSL) && cpl < desc_dpl && !isConforming && !isCallGate && pe && !selectorIsNull) begin
			if (isVERX)
				;
			else
				privilege_violation();
		end
		else
*/
		begin
			if (isLSB) begin
				res <= desc_base;
				next_state(IFETCH);
			end
			else if (isLAR) begin
				res <= desc_acr;
				next_state(IFETCH);
			end
			else if (isLSL) begin
				res <= desc_limit;
				next_state(IFETCH);
			end
			else if (isVERR||isVERW||isVERX) begin
				res <= !selectorIsNull;
				next_state(IFETCH);
			end
			else if (isCallGate) begin
				cg_offset <= desc_data[63:0];
				cg_selector <= desc_data[87:64];
				cg_acr <= desc_data[127:116];
				cg_ncopy <= desc_data[92:88];
				isJGR <= `TRUE;
				a[23:0] <= desc_data[87:64];
				if (!isPresent)
					segment_not_present();
				else if ((cpl > rpl ? cpl : rpl) > desc_dpl && pe)
					privilege_violation();
				else begin
					next_state(CS_LOAD);
				end
			end
			else begin
				if (St==4'd0)	// not possible to load segment #0
					next_state(IFETCH);
				else if (St==4'd15 && selectorIsNull && pe)
					segtype_violation();
				else begin
					$display("Updating descriptor cache[%d] = %h", St, desc_data);
					desc_cache[St] <= desc_data;
					Sprt <= {4'h2,St};
					wrspr <= `TRUE;
					if (isJGR) begin
						if (jgr_state==`JGR_LOAD_SS_DESC) begin
							if (isJMP|isJMPdrn|isRTS2|isRTI2)
								next_state(IFETCH);
							else if (cg_ncopy==5'd0) begin
								rwadr <= {ss_base,12'h000} + {sp_dec2[31:3],3'b00};
								store_what <= `STW_PREV_PC;
								if (isBRK2)
									fmt <= 2'b11;
								else
									fmt <= 2'b10;
								// should check for a stack fault
								update_sp(sp_dec2);
								next_state(STORE1);
							end
							else begin
								jgr_state <= `JGR_STORE_FIFO;
								ncopy <= {cg_ncopy,1'b1};
								rwadr <= {ss_base,12'h000} + {sp[31:3],3'b00} - {cg_ncopy,3'd0};
								// should check for a stack fault
								update_sp(sp - {cg_ncopy,3'd0});
								store_what <= `STW_STK_FIFO;
								next_state(STORE1);
							end
						end
						else begin
							pc[39:0] <= cg_offset[39:0];
							ncopy <= {cg_ncopy,1'b1};
							if (cg_ncopy!=5'd0) begin
								jgr_state <= `JGR_LOAD_FIFO;
								rwadr <= {ss_base,12'h000} + {sp[31:3],3'b00};
								next_state(LOAD1);
							end
							else begin
								Sa <= 4'd12;	// TSS segment
								next_state(JGR_STORE_SSSP);
							end
						end
					end
					else
						next_state(ret_state);
				end
			end
		end
	end

endcase


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// WRITEBACK Stage
// - This stage updates the register file and is overlapped with the 
//   instruction fetch stage.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Update the register file
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (state==IFETCH || wrrf) begin
	$display("writing regfile[%h]=%h",Rt,res);
`ifdef TMR_REG
	regfile1[Rt] <= res[63:0];
	regfile2[Rt] <= res[63:0];
	regfile3[Rt] <= res[63:0];
`else
	regfile[Rt] <= res[63:0];
`endif
//	Rt <= 8'h00;
	if (Rt==8'hFF) begin
		sp <= {res[63:3],3'b000};
		gie <= `TRUE;
		Rt <= 8'h00;
	end
	if (isLMR && wrrf) begin
		if (Rt==Rb)
			Rt <= 8'h00;
		else
			Rt <= Rt + 8'd1;
	end
end

`ifdef SUPPORT_MPC
if (state==IFETCH) begin
case(ir[7:0])
`RR:
	case(ir[39:32])
	`ADD,`SUB,`ADDU,`SUBU,`ADC,`SBC:
		mpcf <= res[64];
	endcase
`ADDI,`ADDUI,`SUBI,`SUBUI:
	mpcf <= res[64];
endcase
end
`endif

if (wrspr) begin
	casex(Sprt)
	//`TICK:	tick <= res;
	`VBR:		vbr <= res;
	`PTA:		pta <= res;
	`CR0:		cr0 <= res;
`ifdef SUPPORT_RNG
	`SRAND1:	m_z <= res;
	`SRAND2:	m_w <= res;
`endif
`ifdef SUPPORT_CLKGATE
	`CLK:		begin clk_throttle_new <= res[49:0]; ld_clk_throttle <= `TRUE; end
`endif
	`LDT_REG:	ldt_reg <= res;
	`GDT_REG:	gdt_reg <= res;
	`SEGx:		begin
					if (St != 4'd15)
						sregs[St] <= a[23:0];
					else
						cs <= a[23:0];
					if (St==4'd14)
						ss <= a[23:0];
				end
	endcase
end

end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Support tasks
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

task next_state;
input [5:0] nxt;
begin
	state <= nxt;
end
endtask

// the read task always reads a whole half-word
task wb_read;
input [2:0] size;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	case(size)
	word,half,uhalf:	sel_o <= 4'hF;
	char,uchar:			sel_o <= adr[1] ? 4'b1100 : 4'b0011;
	byt,ubyte:
		case(adr[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
	endcase
`ifdef TMR
	adr_o <= {adr[31:16],tmrcyc,adr[15:0]};
`else
	adr_o <= {adr[31:16],adr[15:0]};
`endif
end
endtask

task wb_write;
input [2:0] size;
input [31:0] adr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
`ifdef TMR
	adr_o <= {adr[31:16],tmrcyc,adr[15:0]};
`else
	adr_o <= {adr[31:16],adr[15:0]};
`endif
	case(size)
	word,half,uhalf:
		begin
			sel_o <= 4'hF;
			dat_o <= dat;
		end
	char,uchar:
		begin
			sel_o <= adr[1] ? 4'b1100 : 4'b0011;
			dat_o <= {2{dat[15:0]}};
		end
	byt,ubyte:
		begin
			case(adr[1:0])
			2'b00:	begin sel_o <= 4'b0001; dat_o <= {4{dat[7:0]}}; end
			2'b01:	begin sel_o <= 4'b0010; dat_o <= {4{dat[7:0]}}; end
			2'b10:	begin sel_o <= 4'b0100; dat_o <= {4{dat[7:0]}}; end
			2'b11:	begin sel_o <= 4'b1000; dat_o <= {4{dat[7:0]}}; end
			endcase
		end
	endcase
end
endtask

task wb_burst;
input [5:0] bl;
input [33:0] adr;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b001;
	bl_o <= bl;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= adr;
end
endtask

// NACK cycle for bus acknowledge
task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'h0;
	adr_o <= 32'h0;
	dat_o <= 32'h0;
end
endtask

task bus_err;
begin
	berr_addr <= adr_o;
	ir <= {9'd508,4'h0,`BRK};
	hwi <= `TRUE;
	next_state(DECODE);
end
endtask

task update_sp;
input [63:0] newsp;
begin
// This check would add a lot of code and is likely unnecessary - stack
// checking is done at the source.
//	if (newsp < {ss_lower_limit,12'h000} || newsp > {ss_upper_limit,12'hFFF})
//		stack_fault();
//	else
	begin
		Rt <= 8'hFF;
		wrrf <= `TRUE;
		res <= newsp;
	end
end
endtask

task push1;
begin
`ifdef SUPPORT_STKCHECK
	if (sp_dec[31:0] < {ss_lower_limit,12'h000})
		stack_fault();
	else
`endif
	begin
		rwadr <= {ss_base,12'h000} + sp_dec[31:0];
		isWR <= `TRUE;
		update_sp(sp_dec);
		next_state(STORE1);
	end
end
endtask

task push2;
begin
`ifdef SUPPORT_STKCHECK
	if (sp_dec2[31:0] < {ss_lower_limit,12'h000})
		stack_fault();
	else
`endif
	begin
		rwadr <= {ss_base,12'h000} + sp_dec2[31:0];
		isWR <= `TRUE;
		update_sp(sp_dec2);
		next_state(STORE1);
	end
end
endtask

task pop1;
begin
`ifdef SUPPORT_STKCHECK
	if (sp > {ss_upper_limit,12'hFFF})
		stack_fault();
	else
`endif
	begin
		rwadr <= {ss_base,12'h000} + sp;
		update_sp(sp_inc);
		next_state(LOAD1);
	end
end
endtask

task pop2;
begin
`ifdef SUPPORT_STKCHECK
	if (sp > {ss_upper_limit,12'hFFF})
		stack_fault();
	else
`endif
	begin
		rwadr <= {ss_base,12'h000} + sp;
		update_sp(sp_inc2);
		next_state(LOAD1);
	end
end
endtask

task stack_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd504,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task code_page_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd505,4'h0};
	rst_cpnp <= `TRUE;
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task data_page_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd506,4'h0};
	rst_dpnp <= `TRUE;
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task data_read_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd499,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task executable_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd497,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task data_write_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd498,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task segment_not_present;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd503,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task segtype_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd502,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
//	fault_seg <= a[63:32];
//	fault_st <= St;
	next_state(DECODE);
end
endtask

task privilege_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd501,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task bounds_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd500,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task divide_by_zero;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd488,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task overflow_trap;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd489,4'h0};
	fault_pc <= opc;
	fault_cs <= ocs;
	next_state(DECODE);
end
endtask

task load_check;
input [63:0] adr;
begin
`ifdef SUPPORT_LSCHECK
	if (adr > {seg_limit,12'hFFF} && pe)
		bounds_violation();
	else
`endif
	begin
		rwadr <= {seg_base,12'h000} + adr;
		next_state(LOAD1);
	end
end
endtask

task store_check;
input [63:0] adr;
begin
`ifdef SUPPORT_LSCHECK
	if (adr > {seg_limit,12'hFFF} && pe)
		bounds_violation();
	else
`endif
	begin
		rwadr <= {seg_base,12'h000} + adr;
		next_state(STORE1);
	end
end
endtask

task cache_check;
input [63:0] adr;
begin
	rwadr <= {seg_base,12'h000} + adr;
	next_state(CINV1);
end
endtask

// If a NULL selector is passed, default the fields rather than reading them
// from the descriptor table. Also set the result bus to false for the 
// verify instructions.

task load_seg;
begin
	if (a[19]) begin
		rwadr <= ldt_adr[31:0];
		if (ldt_seg_limit_violation && pe) begin
			if (isLSL|isLAR|isLSB) begin
				res <= 65'hFFFFFFFFFFFFFFFF;
				next_state(IFETCH);
			end
			else
				bounds_violation();
		end
		else
			next_state(LOAD1);
	end
	else begin
//		if (a[23:0]==24'd0) begin
//			if (St==4'd15)
//				segtype_violation();
//			else begin
//				seg_selector[St] <= a[63:32];
//				seg_base[St] <= 64'd0;
//				seg_limit[St] <= 64'd0;
//				seg_dpl[St] <= cpl;
//				seg_acr[St] <= 8'h80;	// present, type zero
//				res <= 64'd0;
//				next_state(IFETCH);
//			end
//		end
//		else
		begin
			rwadr <= gdt_adr[31:0];
			if (gdt_seg_limit_violation && pe) begin
				if (isLSL|isLAR|isLSB) begin
					res <= 65'hFFFFFFFFFFFFFFFF;
					next_state(IFETCH);
				end
				else
					bounds_violation();
			end
			else
				next_state(LOAD1);
		end
	end
end
endtask

task flt_op1;
input [7:0] op;
begin
	flt_cyc <= 1'b1;
	flt_wr <= 1'b1;
	flt_adr <= 32'hFFDEA210;
	flt_dati <= {ir[23:16],8'h00,ir[15:8],op};
	next_state(FLT1);
end
endtask

task flt_op2;
input [7:0] op;
begin
	flt_cyc <= 1'b1;
	flt_wr <= 1'b1;
	flt_adr <= 32'hFFDEA210;
	flt_dati <= {ir[31:8],op};
	next_state(FLT1);
end
endtask

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET      ";
RESET2:	fnStateName = "RESET2     ";
IFETCH:	fnStateName = "IFETCH     ";
DECODE:	fnStateName = "DECODE     ";
EXECUTE:	fnStateName = "EXECUTE   ";
RTS1:	fnStateName = "RTS1       ";
LOADSEG:	fnStateName = "LOADSEG     ";
MULDIV:	fnStateName = "MULDIV    ";
MULT1:	fnStateName = "MULT1   ";
MULT2:	fnStateName = "MULT2   ";
MULT3:	fnStateName = "MULT3   ";
DIV:	fnStateName = "DIV     ";
FIX_SIGN:	fnStateName = "FIX_SIGN   ";
MD_RES:	fnStateName = "MD_RES    ";
LOAD1:	fnStateName = "LOAD1   ";
LOAD2:	fnStateName = "LOAD2  ";
LOAD3:	fnStateName = "LOAD3  ";
LOAD4:	fnStateName = "LOAD4  ";
LOAD5:	fnStateName = "LOAD5  ";
LOAD6:	fnStateName = "LOAD6  ";
LOAD7:	fnStateName = "LOAD7  ";
STORE1:	fnStateName = "STORE1     ";
STORE2:	fnStateName = "STORE2     ";
STORE3:	fnStateName = "STORE3     ";
STORE4:	fnStateName = "STORE4     ";
VERIFY_DESC:	fnStateName = "VERIFY_DESC ";
IBUF1:		fnStateName = "IBUF1 ";
IBUF2:		fnStateName = "IBUF2 ";
IBUF3:		fnStateName = "IBUF3 ";
IBUF4:		fnStateName = "IBUF4 ";
ICACHE1:		fnStateName = "ICACHE1    ";
ICACHE2:		fnStateName = "ICACHE2    ";
CINV1:			fnStateName = "CINV1      ";
CINV2:			fnStateName = "CINV2      ";
default:		fnStateName = "UNKNOWN    ";
endcase
endfunction

endmodule


// The cache ram doesn't implement byte #15 which is never used.

module icache_ram(wclk, wr, wa, i, rclk, pc, insn);
input wclk;
input wr;
input [13:0] wa;
input [31:0] i;
input rclk;
input [13:0] pc;
output reg [39:0] insn;

reg [119:0] ram [0:1023];	// should be 7 RAMS
always @(posedge wclk)
	case(wa[3:2])
	2'd0:	ram[wa[13:4]][31: 0] <= i;
	2'd1:	ram[wa[13:4]][63:32] <= i;
	2'd2:	ram[wa[13:4]][95:64] <= i;
	2'd3:	ram[wa[13:4]][119:96] <= i[23:0];
	endcase

reg [13:0] rra;
always @(posedge rclk)
	rra <= pc;
wire [119:0] bundle = ram[rra[13:4]];

always @(rra or bundle)
case(rra[3:2])
2'd0:	insn <= bundle[39: 0];
2'd1:	insn <= bundle[79:40];
2'd2:	insn <= bundle[119:80];
2'd3:	insn <= {`ALN_VECT,`BRK};
endcase

endmodule

module icache_tagram(wclk, wr, wa, v, rclk, pc, hit);
input wclk;
input wr;
input [31:0] wa;
input v;
input rclk;
input [31:0] pc;
output hit;

reg [18:0] ram [0:1023];
reg [31:0] rra;
wire [18:0] tag;

always @(posedge wclk)
	if (wr && (wa[3:2]==2'b11))
		ram[wa[13:4]] <= {wa[31:14],v};
always @(posedge rclk)
	rra <= pc;
assign tag = ram[rra[13:4]];

assign hit = (tag[18:1]==rra[31:14]) && tag[0];

endmodule

