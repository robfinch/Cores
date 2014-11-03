// ============================================================================
// Scarerob-V.v
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
`include "ScarerobV_defines.v"

module ScarerobV(
	rst_i, clk_i, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, ack_i, err_i, sel_o, we_o, adr_o, dat_i, dat_o,
	mmu_cyc_o, mmu_stb_o, mmu_ack_i, mmu_sel_o, mmu_we_o, mmu_adr_o, mmu_dat_i, mmu_dat_o
);
input rst_i;
input clk_i;
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
parameter IBUF5 = 6'd28;
parameter IBUF6 = 6'd29;
parameter CINV1 = 6'd32;
parameter CINV2 = 6'd33;
parameter LINK1 = 6'd34;
parameter LOAD5 = 6'd41;
parameter LOAD6 = 6'd42;
parameter LOAD7 = 6'd43;
parameter DIV2 = 6'd44;
parameter MOVESTK1 = 6'd48;
parameter MOVESTK2 = 6'd49;
parameter MOVESTK3 = 6'd50;
parameter MOVESTK4 = 6'd51;
parameter MOVESTK5 = 6'd52;
parameter VERIFY_SEG_LOAD = 6'd54;
parameter LOAD_CS = 6'd55;
parameter CS_DELAY = 6'd56;
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
wire [95:0] cpu_class = "ScarerobV   ";
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

reg [31:0] adr_ox;
reg [3:0] bytes_got;
reg [5:0] state;
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
reg [95:0] ir;
`ifdef TMR_CACHE
wire [39:0] insn_a,insn_b,insn_c;
wire [39:0] insn = (insn_a & insn_b) | (insn_a & insn_c) | (insn_b & insn_c);
`else
wire [39:0] insn;
`endif
wire [7:0] opcode = ir[7:0];
wire [5:0] func = opcode==`R ? ir[23:20] : ir[31:26];
reg [PCMSB:0] pc;
wire [PCMSB:0] segmented_pc;
wire [63:0] paged_pc;
reg [PCMSB:0] ibufadr;
wire ibufmiss = ibufadr != paged_pc[PCMSB:0];
reg [95:0] ibuf;		// instruction buffer
reg hist_capture;
reg [31:0] history_buf [63:0];
reg [5:0] history_ndx;
reg [5:0] history_ndx2;
reg [31:0] bithist [63:0];
reg [5:0] bithist_ndx;
reg [5:0] bithist_ndx2;
reg isInsnCacheLoad,isCacheReset;
reg [8:0] ivect;
reg nmi_edge,nmi1;
reg hwi;			// hardware interrupt indicator
reg im;				// irq interrupt mask bit
reg i_im;			// interrupt mask when interrupt occurred
reg pv;				// privilege violation
reg [2:0] imcd;		// mask countdown bits
wire [63:0] sr = {8'd0,23'd0,im,6'h00,pv,pe};
reg [63:0] regfile [63:0];
reg [63:0] spregfile [15:0];
reg [63:0] prev_ss_base;
reg [23:0] prev_ss;
reg [63:0] prev_sp;
reg mpcf;					// multi-precision carry
reg gie;						// global interrupt enable

reg [5:0] Ra;
always @(opcode,ir)
casex(opcode)
`Bcc,`LBcc:		Ra <= {3'b100,ir[10:8]};
default:		Ra <= ir[13:8];
endcase

wire [5:0] Rb = ir[19:14];
wire [5:0] Rc = ir[25:20];
reg [5:0] Rt,RtPop,RtLW;
reg [5:0] Spr;		// special purpose register read port spec
reg [5:0] Sprt;
reg [3:0] Sa,St;
reg wrrf,wrsrf,wrspr;
reg [31:0] rwadr,rwadr2;
wire [31:0] rwadr_o;
//reg icacheOn;
wire uncachedArea = 1'b0;
wire ihit;
reg [2:0] ld_size, st_size;
reg isRTS,isPUSH,isPOP,isPOPS,isIMM,isCMPI;
reg isJSRix,isJSRdrn,isJMPix,isBRK,isPLP,isRTI;
reg isShifti,isBSR,isBSR16,isBSR24,isLMR,isSMR;
reg isJSP,isJSR,isLWS,isLink,isUnlk;
reg isRTSsf,isRTSsfs,isRTSlf;
reg isLxDT,isSxDT;
reg isLW;
reg isJGR,isVERR,isVERW,isVERX,isLDWx;
reg isBM;
reg isCAS;
reg isTLS,isGS,isIO,isSegx;
reg isTrapv;

reg [31:0] stack_fifo [63:0];
reg [5:0] ncopy;

reg [2:0] nLD, nMTSEG, nJGR;
reg [1:0] nDT;
wire hasJSP = isJSP;
wire hasIMM = isIMM;
reg [63:0] rfoa,rfob,rfoc;
reg [64:0] res;			// result bus
reg [63:0] a,b,c;		// operand holding registers
reg [63:0] ca,cb;
reg [23:0] jsp_buf;		// selector prefix buffer
reg [63:0] imm;
reg [63:0] pimm;		// previous immediate
reg [63:0] immbuf;
wire [63:0] bfo;		/// bitfield op output
reg [63:0] tick;		// tick count
reg [31:0] vbr;			// vector base register
reg [31:0] berr_addr;
reg [31:0] fault_pc;
reg [23:0] fault_cs;
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

reg [31:0] gdt_base;
reg [31:0] gdt_limit,gdt_limit2;
reg [31:0] idt_base;
reg [31:0] idt_limit;

reg [23:0] seg_selector [15:0];
reg [31:0] seg_base [15:0];	// lower bound
reg [31:0] seg_limit [15:0];	// upper bound
reg [3:0] seg_dpl [15:0];	// privilege level
reg [7:0] seg_acr [15:0];	// access rights

reg [31:0] desc_h0,desc_h1,desc_h2,desc_h3;
wire [7:0] desc_acr = desc_h0[31:24];//{desc_w0[63:60],desc_w1[63:56]};
wire [3:0] desc_dpl = desc_h0[23:20];//desc_w0[63:60];
wire [31:0] desc_limit = desc_h2;//desc_w1[31:0];
wire [31:0] desc_base = desc_h1;//desc_w0[31:0];
wire isCallGate = desc_acr[4:0]==5'b01100;
wire isConforming = desc_acr[2];
wire isPresent = desc_acr[7];

reg [23:0] cg_selector;
reg [31:0] cg_offset;
reg [3:0] cg_dpl;
reg [7:0] cg_acr;
reg [4:0] cg_ncopy;

reg [23:0] cs;
wire [23:0] cs_selector = seg_selector[4'd15];
wire [39:0] cs_base = seg_base[4'd15];
wire [31:0] cs_limit = seg_limit[4'd15];
wire [7:0] cs_acr = seg_acr[4'd15];
wire [31:0] ss_base = seg_base[4'd14];
wire [31:0] ss_limit = seg_limit[4'd14];
wire [31:0] tss_base = seg_base[4'd12];
wire [23:0] ss = seg_selector[4'd14];

reg [3:0] ppl;		// previous privilege level
wire [3:0] cpl = seg_dpl[4'd15];
wire [3:0] dpl = seg_dpl[Sa];
wire [3:0] rpl = a[63:60];
assign segmented_pc = {cs_base[39:8],8'h00} + pc;
wire pcOutOfBounds = pc > cs_limit;
wire selectorIsNull = a[63:40]==24'd0;

wire [63:0] sp_inc = spregfile[cpl] + 64'd8;
wire [63:0] sp_dec = spregfile[cpl] - 64'd8;

// - - - - - - - - - - - - - - - - - -
// Convenience Functions
// - - - - - - - - - - - - - - - - - -

// amount to increment Pc by
function [3:0] pc_inc;
input [7:0] opcode;
casex(opcode)
`BRK:			pc_inc = 4'd1;
`R:				pc_inc = 4'd3;
`RR:			pc_inc = 4'd4;
`TST:			pc_inc = 4'd2;	// TST
`CMPI:			pc_inc = 4'd3;	// CMPI
`CMP:			pc_inc = 4'd3;
`ADDI:			pc_inc = 4'd4;
`ADDI4:			pc_inc = 4'd3;
`SUBI:			pc_inc = 4'd4;
`SUBI4:			pc_inc = 4'd3;
`MULI:			pc_inc = 4'd4;
`DIVI:			pc_inc = 4'd4;
`MODI:			pc_inc = 4'd4;
`ANDI,`ORI,`EORI:	pc_inc = 4'd4;
`LDI10:			pc_inc = 4'd3;
`LDI18:			pc_inc = 4'd4;
`SLTI,`SLEI,`SGTI,`SGEI,`SLOI,`SLSI,`SHII,`SHSI,`SEQI,`SNEI:
				pc_inc = 4'd4;
`MULUI:			pc_inc = 4'd4;
`DIVUI:			pc_inc = 4'd4;
`MODUI:			pc_inc = 4'd4;
`Bcc:			pc_inc = 4'd2;
`LBcc:			pc_inc = 4'd3;
`BRZ,`BRNZ,`BRMI,`BRPL,`DBNZ:
				pc_inc = 4'd3;
`JSP,`JGR:				pc_inc = 4'd4;
`JSPR,`JGRR:			pc_inc = 4'd2;
`JMP_RN,`JSR_RN:		pc_inc = 4'd2;
`JMP16,`JSR16,`BSR16:	pc_inc = 4'd3;
`JMP24,`JSR24,`BSR24:	pc_inc = 4'd4;
`JMP_IX,`JSR_IX:		pc_inc = 4'd4;
`TRAPV:			pc_inc = 4'd1;
`RTS:			pc_inc = 4'd1;
`RTI:			pc_inc = 4'd1;
8'b0110011x:	pc_inc = 4'd2;	// SWE x
`LB4,`LBU4,`LC4,`LCU4,`LH4,`LHU4,`LW4,`SB4,`SC4,`SH4,`SW4:
				pc_inc = 4'd3;
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW,`LEA,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`SBX,`SCX,`SHX,`SWX,`LEAX,
`SWS,`LWS,
`CINV,`CINVX:
				pc_inc = 4'd4;
`CAS:			pc_inc = 4'd4;
`PUSH,`POP,`PUSHS,`POPS,`PUSHC8:
				pc_inc = 4'd2;
`PUSHC16:		pc_inc = 4'd3;
`NOP:			pc_inc = 4'd1;
`CLI:			pc_inc = 4'd1;
`SEI:			pc_inc = 4'd1;
`IMM1:			pc_inc = 4'd2;
`IMM2:			pc_inc = 4'd3;
`IMM3:			pc_inc = 4'd4;
`IMM4:			pc_inc = 4'd5;
`IMM5:			pc_inc = 4'd6;
`IMM6:			pc_inc = 4'd7;
`IMM7:			pc_inc = 4'd8;
`IMM8:			pc_inc = 4'd9;
default:		pc_inc = 4'd1;
endcase
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
icache_ram u2 (
	.wclk(clk),
	.wr(ack_i && isInsnCacheLoad),
	.wa(adr_o[13:0]),
	.i(dat_i),
	.rclk(~clk),
	.pc(paged_pc[13:0]),
	.insn(insn)
);

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

Table888_bitfield u4
(
	.op(ir[39:36]),
	.a(a),
	.b(b),
	.m(ir[35:24]),
	.o(bfo),
	.masko()
);

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
6'd00:	rfoa <= 64'd0;
6'd62:	rfoa <= spregfile[cpl];
6'd63:	rfoa <= pc[39:0];
default:	rfoa <= regfile[Ra];
endcase

always @*
case(Rb)
6'd00:	rfob <= 64'd0;
6'd62:	rfob <= spregfile[cpl];
6'd63:	rfob <= pc[39:0];
default:	rfob <= regfile[Rb];
endcase

always @*
case(Rc)
6'd00:	rfoc <= 64'd0;
6'd62:	rfoc <= spregfile[cpl];
6'd63:	rfoc <= pc[39:0];
default:	rfoc <= regfile[Rc];
endcase

wire [63:0] sp = regfile[62];

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
`BRMI:	take_branch <= a[63];
`BRPL:	take_branch <= !a[63];
`DBNZ:	take_branch <= a!=64'd0;
`BEQ,`LBEQ:	take_branch <= a[1];
`BNE,`LBNE:	take_branch <= !a[1];
`BVS,`LBVS:	take_branch <= a[62];
`BVC,`LBVC:	take_branch <= !a[62];
`BMI,`LBMI:	take_branch <= a[63];
`BPL,`LBPL:	take_branch <= !a[63];
`BRA,`LBRA:	take_branch <= `TRUE;
`BRN,`LBRN:	take_branch <= `FALSE;
`BHI,`LBHI:	take_branch <= a[0] & !a[1];
`BHS,`LBHS:	take_branch <= a[0];
`BLO,`LBLO:	take_branch <= !a[0];
`BLS,`LBLS:	take_branch <= !a[0] | a[1];
`BGT,`LBGT:	take_branch <= (a[63] & a[62] & !a[1]) | (!a[63] & !a[62] & !a[1]);
`BGE,`LBGE:	take_branch <= (a[63] & a[62])|(!a[63] & !a[62]);
`BLT,`LBLT:	take_branch <= (a[63] & !a[62])|(!a[63] & a[62]);
`BLE,`LBLE:	take_branch <= a[1] | (a[63] & !a[62])|(!a[63] & a[62]);
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
wire [63:0] lea_drn = seg_base[Sa] + a + imm;
wire [63:0] lea_ndx = seg_base[Sa] + a + b + imm;
wire [63:0] ea_drn = lea_drn;
wire [63:0] ea_ndx = lea_ndx;
wire [63:0] mr_ea = c;

wire [63:0] gdt_adr = gdt_base + {a[18:0],4'h0};
wire [63:0] ldt_adr = seg_base[11] + {a[18:0],4'h0};
wire gdt_seg_limit_violation = {a[18:0],4'hF} > gdt_limit;
wire ldt_seg_limit_violation = {a[18:0],4'hF} > seg_limit[11];


assign data_readable = pmmu_data_readable;
assign data_writeable = pmmu_data_writeable;

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
	`SR:		spro <= sr;
	`FAULT_PC:	spro <= fault_pc;
	`IVNO:		spro <= ivno;
	`HISTORY:	spro <= history_buf[history_ndx2];
	`RAND:		spro <= rand;
	`BITERR_CNT:	spro <= biterr_cnt;
	`BITHIST:	spro <= bithist[bithist_ndx2];
	`PROD_HIGH:	spro <= p[127:64];
	6'h2x:		spro <= seg_selector[Sa][23:0];
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
reg clk_en;

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

//-----------------------------------------------------------------------------
// Clocked logic follows.
//-----------------------------------------------------------------------------

always @(posedge clk)
if (rst_i) begin
	clk_en <= `TRUE;
	pc <= `RST_VECT;
	ibufadr <= 32'h00000000;
	gie <= `FALSE;
	nmi_edge <= `FALSE;
	isInsnCacheLoad <= `FALSE;
	isCacheReset <= `TRUE;
	wb_nack();
	adr_o[3:2] <= 2'b11;		// The tagram checks for this
	state <= RESET;
	store_what <= `STW_NONE;
	tick <= 64'd0;
	biterr_cnt <= 64'd0;
	vbr <= 32'h00006000;
	imcd <= 3'b111;
	pv <= `FALSE;
	cr0 <= 64'h0;
	St <= 4'd0;
	rst_cpnp <= `TRUE;
	rst_dpnp <= `TRUE;
	isWR <= `FALSE;
	tmrcyc <= 2'd0;
	hist_capture <= `TRUE;
	history_ndx <= 6'd0;
	history_ndx2 <= 6'd0;
`ifdef SUPPORT_CLKGATE
	ld_clk_throttle <= `FALSE;
`endif
	isJSP <= `FALSE;
	isIMM <= `FALSE;
	isTLS <= `FALSE;
	isGS <= `FALSE;
	isIO <= `FALSE;
	isSegx <= `FALSE;
	isTrapv <= `FALSE;
end
else begin
tick <= tick + 64'd1;
if (nmi_i & !nmi1)
	nmi_edge <= `TRUE;
if (nmi_i|nmi1)
	clk_en <= `TRUE;
wrrf <= `FALSE;
wrsrf <= `FALSE;
wrspr <= `FALSE;
`ifdef SUPPORT_CLKGATE
ld_clk_throttle <= `FALSE;
`endif
rst_cpnp <= `FALSE;
rst_dpnp <= `FALSE;

case(state)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// RESET:
// - Invalidate the instruction cache
// - Initialize the segment register to a flat memory model.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
RESET:
	begin
		adr_o[3:2] <= 2'b11;		// The tagram checks for this
		adr_o[12:4] <= adr_o[12:4] + 9'd1;
		if (adr_o[12:4]==9'h1FF) begin
			isCacheReset <= `FALSE;
			next_state(IFETCH);
		end
		a[63:40] <= adr_o[7:4];
		desc_h1 <= 32'd0;		// base = 64'd0
		desc_h3 <= 32'd0;
		desc_h2 <= 32'd0;
		if (adr_o[7:4]==4'd0)
			desc_h0 <= {8'h80,24'h0};
		else if (adr_o[7:4]==4'd15) begin
			desc_h0 <= {8'h9A,24'd0};
			desc_h2 <= 32'hFFFFFFFF;
		end
		else begin
			desc_h0 <= {8'h92,24'd0};
			desc_h2 <= 32'hFFFFFFFF;
		end
		St <= adr_o[7:4];
		wrsrf <= `TRUE;
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
		ivect <= 9'd000;
		if (rdy) begin
			if (hist_capture) begin
				history_buf[history_ndx] <= pc[31:0];
				history_ndx <= history_ndx + 1;
			end
			next_state(DECODE);
			if (nmi_edge & gie & ~hasIMM) begin
				ir[7:0] <= `BRK;
				ivect <= 9'd510;
				nmi_edge <= 1'b0;
				hwi <= `TRUE;
			end
			else if (irq_i & gie & ~im & ~hasIMM) begin
				ir[7:0] <= `BRK;
				ivect <= vect_i;
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
					ir <= insn;
				end
			end
			else begin
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
	begin
		isInsnCacheLoad <= `TRUE;
		wb_burst(6'd3,{paged_pc[31:4],4'h0});
		next_state(ICACHE2);
	end
ICACHE2:
	if (ack_i) begin
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
		if (adr_o[3:2]==2'b10)
			cti_o <= 3'b111;
		if (adr_o[3:2]==2'b11) begin
			isInsnCacheLoad <= `FALSE;
			wb_nack();
			next_state(IFETCH);
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction buffer load machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

IBUF1:
	begin
		wb_read({paged_pc[31:2],2'h0});
		next_state(IBUF2);
	end
IBUF2:
	if (ack_i) begin
		wb_nack();
		adr_ox <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	begin ibuf[31:0] <= dat_i;        bytes_got <= 4'd4; end
		2'b01:	begin ibuf[23:0] <= dat_i[31: 8]; bytes_got <= 4'd3; end
		2'b10:	begin ibuf[15:0] <= dat_i[31:16]; bytes_got <= 4'd2; end
		2'b11:	begin ibuf[ 7:0] <= dat_i[31:24]; bytes_got <= 4'd1; end
		endcase
		next_state(IBUF3);
	end
IBUF3:
	begin
		if (pc_inc(opcode) > bytes_got) begin
			wb_read({adr_ox[31:2],2'b00});
			next_state(IBUF4);
		end
		else begin
			ibufadr <= paged_pc[PCMSB:0];
			next_state(IFETCH);
		end
	end
IBUF4:
	if (ack_i) begin
		wb_nack();
		adr_ox <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	begin ibuf[63:32] <= dat_i; bytes_got <= 4'd8; end
		2'b01:	begin ibuf[55:24] <= dat_i; bytes_got <= 4'd7; end
		2'b10:	begin ibuf[47:16] <= dat_i; bytes_got <= 4'd6; end
		2'b11:	begin ibuf[39: 8] <= dat_i; bytes_got <= 4'd5; end
		endcase
		next_state(IBUF5);
	end
IBUF5:
	begin
		if (pc_inc(opcode) > bytes_got) begin
			wb_read({adr_ox[31:2],2'b00});
			next_state(IBUF6);
		end
		else begin
			ibufadr <= paged_pc[PCMSB:0];
			next_state(IFETCH);
		end
	end
IBUF6:
	if (ack_i) begin
		wb_nack();
		adr_ox <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	begin ibuf[95:64] <= dat_i; bytes_got <= 4'd12; end
		2'b01:	begin ibuf[87:56] <= dat_i; bytes_got <= 4'd11; end
		2'b10:	begin ibuf[79:48] <= dat_i; bytes_got <= 4'd10; end
		2'b11:	begin ibuf[71:40] <= dat_i; bytes_got <= 4'd9; end
		endcase
		ibufadr <= paged_pc[PCMSB:0];
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
		if (!hwi)
			pc <= pc + pc_inc(opcode);
		// Default a number of signals. These defaults may be overridden later.
		isCMPI <= `FALSE;
		isBRK <= `FALSE;
		isRTS <= `FALSE;
		isPOP <= `FALSE;
		isPUSH <= `FALSE;
		isPLP <= `FALSE;
		isBSR <= `FALSE;
		isBSR16 <= `FALSE;
		isBSR24 <= `FALSE;
		isRTI <= `FALSE;
		isJGR <= `FALSE;
		isLMR <= `FALSE;
		isSMR <= `FALSE;
		isLWS <= `FALSE;
		isVERR <= `FALSE;
		isVERW <= `FALSE;
		isVERX <= `FALSE;
		isLDWx <= `FALSE;
		isLW <= `FALSE;
		isCAS <= `FALSE;
		nLD <= 3'd0;
		isShifti = func==`SLLI || func==`SRLI || func==`ROLI || func==`RORI || func==`SRAI;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		ld_size <= word;
		st_size <= word;
		
		// Set the target register
		casex(opcode)
		`TST:	Rt <= {3'b100,ir[2:0]};
		`CMPI:	Rt <= {3'b100,ir[2:0]};
		`CMP:	Rt <= {3'b100,ir[22:20]};
		`R:	
			case(ir[23:20])
			`MTSPR:	Rt <= 6'h00;	// We are writing to an SPR not the general register file
			default:	Rt <= ir[19:14];
			endcase
		`RR:	Rt <= ir[25:20];
		`LDI10,`LDI18:	Rt <= ir[13:8];
		`DBNZ:	Rt <= ir[13:8];
		`BITFIELD:
			Rt <= ir[19:14];
		`ADDI4,`SUBI4,
		`ADDI,`SUBI,`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,
		`ANDI,`ORI,`EORI,
		`SLTI,`SLEI,`SGTI,`SGEI,`SLOI,`SLSI,`SHII,`SHSI,`SEQI,`SNEI:
			Rt <= ir[19:14];
		`LB4,`LBU4,`LC4,`LCU4,`LH4,`LHU4,`LW4,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA:
			begin
			Rt <= ir[19:14];
			RtLW <= ir[19:14];
			end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX:
			Rt <= ir[25:20];
		`CAS:
			Rt <= ir[31:26];
		default:
			Rt <= 6'h00;
		endcase

		// Immediate value multiplexer
		casex(opcode)
		`ADDI4,`SUBI4:	imm <= {60'd0,ir[23:20]};
		`ADDI,`SUBI,`ANDI,`ORI,`EORI,`MULI,`DIVI,`MODI,`MULUI,`DIVUI,`MODUI:		
			imm <= hasIMM ? {immbuf[51:0],ir[31:20]} : {{52{ir[31]}},ir[31:20]};
		`LDI10,`CMPI:	imm <= hasIMM ? {immbuf[53:0],ir[23:14]} : {{54{ir[23]}},ir[23:14]};
		`LDI18:		imm <= hasIMM ? {immbuf[45:0],ir[31:14]} : {{46{ir[31]}},ir[31:14]};
		`JMP_IX,`JSR_IX:
			if (hasIMM)
				imm <= {immbuf[45:0],ir[31:14]};
			else
				imm <= ir[31:14];
		`PUSHC8:	imm <= hasIMM ? {immbuf[55:0],ir[15:8]} : {{56{ir[15]}},ir[15:8]};
		`PUSHC16:	imm <= hasIMM ? {immbuf[47:0],ir[23:8]} : {{48{ir[23]}},ir[23:8]};
		`LB4,`LBU4,`LC4,`LCU4,`LH4,`LHU4,`LW4,
		`SB4,`SC4,`SH4,`SW4:
			imm <= {60'd0,ir[23:20]};
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA,
		`SB,`SC,`SH,`SW,`CINV:
			if (hasIMM)
				imm <= {immbuf[51:0],ir[31:20]};
			else
				imm <= {{52{ir[31]}},ir[31:20]};

		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX,`CINVX:
			if (hasIMM)
				imm <= {immbuf[57:0],ir[31:26]};
			else
				imm <= {{58{ir[31]}},ir[31:26]};
		`CAS:
			if (hasIMM)
				imm <= immbuf[63:0];
			else
				imm <= 64'd0;
		default:	imm <= 64'd0;
		endcase

		if (!(isTLS|isGS|isIO|isSegx))
			set_default_seg();

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
			`CLP:	begin pv <= `FALSE; next_state(IFETCH); end
//			`PROT:	begin pe <= `TRUE; next_state(IFETCH); end
			`ICON:	begin cr0[30] <= `TRUE; next_state(IFETCH); end
			`ICOFF:	begin cr0[30] <= `FALSE; next_state(IFETCH); end
			`PHP:
				begin
					isWR <= `TRUE;
					rwadr <= sp_dec;
					update_sp(sp_dec);
					store_what <= `STW_SR;
					next_state(STORE1);
				end
			`PLP:
				begin
					isPLP <= `TRUE;
					rwadr <= sp;
					update_sp(sp_inc);
					next_state(LOAD1);
				end
			`MOVS,`MFSPR,`MTSPR:
					begin
						Spr <= ir[13:8];
						Sprt <= ir[19:14];
						Sa <= ir[11:8];
						St <= ir[17:14];
					end
			// Unimplemented instruction
			default:	;
			endcase
		`SEGT:
			casex(ir[23:20])
			`VERR:
				begin
					isVERR <= `TRUE;
					load_seg();
				end
			`VERW:
				begin
					isVERW <= `TRUE;
					load_seg();
				end
			`VERX:
				begin
					isVERX <= `TRUE;
					load_seg();
				end
			`LDWx:	begin
					isLDWx <= `TRUE;
					load_seg();
					end
			//`LSB:	Sa <= ir[11:8];
			endcase
		`RR:
			case(func)
			`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:	next_state(MULDIV);
			endcase

		`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI:	next_state(MULDIV);
		`CMPI:	isCMPI <= `TRUE;


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
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Flow Control Instructions Follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`SWE:
			begin
				ir[7:0] <= `BRK;
				ivect <= {ir[0],ir[15:8]};
				next_state(DECODE);
			end
		`SWE3:
			begin
				ir[7:0] <= `BRK;
				ivect <= 9'd3;
				next_state(DECODE);
			end
		`BRK:
			begin
				$display("*****************");
				$display("*****************");
				$display("BRK");
				$display("*****************");
				$display("*****************");
				ivno <= ivect;
				hist_capture <= `FALSE;
				isBRK <= `TRUE;
				// Double fault ?
				brkCnt <= brkCnt + 3'd1;
				if (brkCnt > 3'd2)
					next_state(HANG);
				else if ({ivect,4'h0} > idt_limit && pe)
					bounds_violation();
				else if (sp_dec < 32'd16)
					stack_fault();
				else begin
					// 1. Store the SS:SP in task state segment
					store_what <= `STW_SP;
					rwadr <= {tss_base[31:2],2'b00} + {cpl,4'h0} + 32'h200;
					next_state(STORE1);
				end
				$stop;
			end
		`RTI:
			begin
				hist_capture <= `TRUE;
				if (cpl[3] && pe)
					privilege_violation();
				else if (sp_inc > seg_limit[14])
					stack_fault();
				else begin
					isRTI <= `TRUE;
					rwadr <= ss_base + sp;
					update_sp(sp_inc);
					next_state(LOAD1);
				end
			end
		`JMP16:
			begin
				if (hasIMM)
					pc <= {immbuf[47:0],ir[23:8]};
				else
					pc <= ir[23:8];
				if (!hasJSP)
					next_state(IFETCH);
				a <= jsp_buf;
			end
		`JMP24:
			begin
				if (hasIMM)
					pc <= {immbuf[39:0],ir[31:8]};
				else
					pc <= ir[31:8];
				if (!hasJSP)
					next_state(IFETCH);
				a <= jsp_buf;
			end
		`BSR16:
			begin
				isBSR <= `TRUE;
				isBSR16 <= `TRUE;
				if (sp_dec < 32'd32)
					stack_fault();
				else begin
					isWR <= `TRUE;
					rwadr <= ss_base + sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					next_state(STORE1);	
				end
			end
		`BSR24:
			begin
				isBSR <= `TRUE;
				isBSR24 <= `TRUE;
				if (sp_dec < 32'd32)
					stack_fault();
				else begin
					isWR <= `TRUE;
					rwadr <= ss_base + sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					next_state(STORE1);	
				end
			end
		`JSR16:
			begin
				if (sp_dec < 32'd32)
					stack_fault();
				else begin
					isJSR <= `TRUE;
					isJSP <= isJSP;
					isWR <= `TRUE;
					rwadr <= ss_base + sp_dec[31:0];
					update_sp(sp_dec);
					// this should store in long format for PC > 38 bits
					store_what <= `STW_PC;
					if (hasIMM)
						imm <= {immbuf[47:0],ir[23:8]};
					else
						imm <= ir[23:8];
					next_state(STORE1);
				end
			end
		`JSR24:
			begin
				if (sp_dec < 32'd32)
					stack_fault();
				else begin
					isJSR <= `TRUE;
					isJSP <= isJSP;
					isWR <= `TRUE;
					rwadr <= ss_base + sp_dec[31:0];
					update_sp(sp_dec);
					// this should store in long format for PC > 38 bits
					store_what <= `STW_PC;
					if (hasIMM)
						imm <= {immbuf[39:0],ir[31:8]};
					else
						imm <= ir[31:8];
					next_state(STORE1);
				end
			end
		`JSR_DRN:
			begin
				if (sp_dec < 32'd32)
					stack_fault();
				else begin
					isJSRdrn <= `TRUE;
					isWR <= `TRUE;
					rwadr <= ss_base + sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					next_state(STORE1);
				end
			end
		`RTS:
			begin
				if (sp_inc + 32'd8 > seg_limit[14])
					stack_fault();
				else begin
					isRTS <= `TRUE;
					rwadr <= ss_base + sp;
					next_state(LOAD1);
					update_sp(sp_inc + 32'd8);
				end
			end
		`JGR:
			begin
				isJGR <= `TRUE;
				nJGR <= 3'b001;
				isWR <= `TRUE;
				// 1. Store the SS:SP in task state segment
				store_what <= `STW_SP;
				rwadr <= {tss_base[31:2],2'b00} + {cpl,4'h0} + 32'h200;
				next_state(STORE1);
//				a <= ir[31:8];
//				next_state(LOAD1);
			end


		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// PUSH / POP
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`PUSH:
			if (sp_dec <= 32'd32)
				stack_fault();
			else begin
				isPUSH <= `TRUE;
				store_what <= `STW_A;
				Sa <= 4'd14;
				rwadr <= ss_base + sp_dec[31:0];
				isWR <= `TRUE;
				update_sp(sp_dec);
				next_state(STORE1);
			end
		`PUSHS:
			if (sp_dec <= 32'd32)
				stack_fault();
			else begin
				isPUSH <= `TRUE;
				store_what <= `STW_SPR;
				Sa <= 4'd14;
				rwadr <= ss_base + sp_dec[31:0];
				isWR <= `TRUE;
				update_sp(sp_dec);
				next_state(STORE1);
			end

		`POP:
			begin
				if (sp > ss_limit)
					stack_fault();
				else begin
					isPOP <= `TRUE;
					RtPop <= ir[15:8];
					Sa <= 4'd14;
					rwadr <= ss_base + sp;
					update_sp(sp_inc);
					next_state(LOAD1);
				end
			end
		`POPS:
			begin
				if (sp > ss_limit)
					stack_fault();
				else begin
					isPOPS <= `TRUE;
					RtPop <= 6'd0;
					Sprt <= ir[13:8];
					Sa <= 4'd14;
					rwadr <= ss_base + sp;
					update_sp(sp_inc);
					next_state(LOAD1);
				end
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Push a constant onto the stack, used surprisingly often.
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`PUSHC8,`PUSHC16:
			if (sp_dec <= 32'd32)
				stack_fault();
			else begin
				store_what <= `STW_IMM;
				Sa <= 4'd14;
				rwadr <= ss_base + sp_dec[31:0];
				isWR <= `TRUE;
				update_sp(sp_dec);
				next_state(STORE1);
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Prefixes follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`TLS:
			begin
				isTLS <= `TRUE;
				Sa <= 4'd2;
				next_state(IFETCH);
			end
		`GS:
			begin
				isGS <= `TRUE;
				Sa <= 4'd6;
				next_state(IFETCH);
			end
		`IO:
			begin
				isIO <= `TRUE;
				Sa <= 4'd13;
				next_state(IFETCH);
			end
		`SEGX:
			begin
				isSegx <= `TRUE;
				Sa <= ir[11:8];
				next_state(IFETCH);
			end
		`TRAPV:
			begin
				isTrapv <= `TRUE;
				next_state(IFETCH);
			end
		`IMM1:
			begin
				isIMM <= `TRUE;
				immbuf <= {{56{ir[15]}},ir[15:8]};
				next_state(IFETCH);
			end
		`IMM2:
			begin
				isIMM <= `TRUE;
				immbuf <= {{48{ir[23]}},ir[23:8]};
				next_state(IFETCH);
			end
		`IMM3:
			begin
				isIMM <= `TRUE;
				immbuf <= {{40{ir[31]}},ir[31:8]};
				next_state(IFETCH);
			end
		`IMM4:
			begin
				isIMM <= `TRUE;
				immbuf <= {{32{ir[39]}},ir[39:8]};
				next_state(IFETCH);
			end
		`IMM5:
			begin
				isIMM <= `TRUE;
				immbuf <= {{24{ir[47]}},ir[47:8]};
				next_state(IFETCH);
			end
		`IMM6:
			begin
				isIMM <= `TRUE;
				immbuf <= {{16{ir[55]}},ir[55:8]};
				next_state(IFETCH);
			end
		`IMM7:
			begin
				isIMM <= `TRUE;
				immbuf <= {{8{ir[63]}},ir[63:8]};
				next_state(IFETCH);
			end
		`IMM8:
			begin
				isIMM <= `TRUE;
				immbuf <= ir[71:8];
				next_state(IFETCH);
			end
		`JSP:
			begin
				isJSP <= `TRUE;
				jsp_buf <= ir[31:8];
				next_state(IFETCH);
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
		isJSP <= `FALSE;
		isIMM <= `FALSE;
		isTLS <= `FALSE;
		isGS <= `FALSE;
		isIO <= `FALSE;
		isSegx <= `FALSE;
		isTrapv <= `FALSE;

		// This case statement execute instructions.
		casex(opcode)
		`R:
			case(func)
			`SWAP:	res <= {a[31:0],a[63:32]};
			`MOV:	res <= a;
			`NEG:	res <= -a;
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
					end
			`GRAN:
				begin
					res <= rand;
					m_z <= next_m_z;
					m_w <= next_m_w;
				end
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
			endcase
		`RR:
			case(func)
			`ADD:	res <= a + b;
			`ADC:	res <= a + b + mpcf;
			`SUB:	res <= a - b;
			`SBC:	res <= a - b - mpcf;
			`AND,`OR,`EOR,`ANDN,`NAND,`NOR,`ENOR,`ORN:		
						res <= logic_o;
			`SHLI,`SHL:	res <= shlo[63:0];
			`ROLI,`ROL: res <= shlo[127:64]|shlo[63:0];
			`RORI,`ROR:	res <= shro[127:64]|shro[63:0];
			`SHRI,`SHR:	res <= shro[127:64];
			`ASRI,`ASR:	res <= asro;
			`ARPL:
				begin
					if (a[63:60] < b[63:60])
						res <= {b[63:60],a[59:0]};
					else
						res <= a;
				end
			`SLT,`SLE,`SGT,`SGE,`SLO,`SLS,`SHI,`SHS,`SEQ,`SNE:
				res <= set_o;
			// Unimplemented instruction
			default:	res <= 65'd0;
			endcase
		`BITFIELD:	res <= bfo;
		`LDI10,`LDI18:	res <= imm;
		`ADDI:	res <= a + imm;
		`SUBI:	res <= a - imm;
		`CMPI,`CMP:	res <= {nf,vf,60'd0,zf,cf};
		`ANDI,`ORI,`EORI:	res <= logic_o;
		`SLTI,`SLEI,`SGTI,`SGEI,`SLOI,`SLSI,`SHII,`SHSI,`SEQI,`SNEI:
			res <= set_o;
		
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Flow Control Instructions Follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`Bcc:
			if (take_branch) begin
				pc <= pc + {{35{ir[15]}},ir[15:11]};
			end
		`LBcc:
			if (take_branch) begin
				pc <= pc + {{27{ir[23]}},ir[23:11]};
			end
		`BRZ,`BRNZ,`BRMI,`BRPL:
			if (take_branch) begin
				pc <= pc + {{30{ir[23]}},ir[23:14]};
			end
		`DBNZ:
			begin
				if (take_branch) begin
					pc <= pc + {{30{ir[23]}},ir[23:14]};
				end
				res <= a - 64'd1;
			end
		`JMP16,`JMP24:
			begin
				if (a[63:40]==24'd0)
					next_state(IFETCH);
				else
					load_cs_seg();
			end
		`JMP_IX:
			begin
				isJMPix <= `TRUE;
				rwadr <= ea_drn;
				next_state(LOAD1);
			end
		`JMP_DRN:	
			begin
				pc <= ea_drn;
				next_state(IFETCH);
			end
		`JSR_IX:
			begin	
				if (sp_dec <= 32'd32)
					stack_fault();
				else begin
					rwadr2 <= ea_drn;
					rwadr <= ss_base + sp_dec[31:0];
					isWR <= `TRUE;
					update_sp(sp_dec);
					isJSRix <= `TRUE;
					store_what <= `STW_PC;
					next_state(STORE1);
				end
			end
		`JGRR:
			begin
				isJGR <= `TRUE;
				nJGR <= 3'b001;
				isWR <= `TRUE;
				next_state(LOAD1);
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Loads and Stores follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`LB:
			begin
				ld_size <= byt;
				load_check(ea_drn);
			end
		`LBU:
			begin
				ld_size <= ubyte;
				load_check(ea_drn);
			end
		`LC:
			begin
				ld_size <= char;
				load_check(ea_drn);
			end
		`LCU:
			begin
				ld_size <= uchar;
				load_check(ea_drn);
			end
		`LH:
			begin
				ld_size <= half;
				load_check(ea_drn);
			end
		`LHU:
			begin
				ld_size <= uhalf;
				load_check(ea_drn);
			end
		`LW:
			begin
				isLW <= `TRUE;
				ld_size <= word;
				load_check(ea_drn);
			end
		`CAS:
			begin
				isCAS <= `TRUE;
				ld_size <= word;
				load_check(ea_drn);
			end
		`LEA:	res <= lea_drn;
		`LWS:
			begin
				isLWS <= `TRUE;
				ld_size <= word;
				load_check(ea_drn);
			end
		`LBX:
			begin
				ld_size <= byt;
				load_check(ea_ndx);
			end
		`LBUX:
			begin
				ld_size <= ubyte;
				load_check(ea_ndx);
			end
		`LCX:
			begin
				ld_size <= char;
				load_check(ea_ndx);
			end
		`LCUX:
			begin
				ld_size <= uchar;
				load_check(ea_ndx);
			end
		`LHX:
			begin
				ld_size <= half;
				load_check(ea_ndx);
			end
		`LHUX:
			begin
				ld_size <= uhalf;
				load_check(ea_ndx);
			end
		`LWX:
			begin
				ld_size <= word;
				load_check(ea_ndx);
			end
		`LEAX:	res <= lea_ndx;
		`LxDT:
			begin
				isLxDT <= `TRUE;
				nDT <= 2'b01;
				load_check(ea_drn);
			end
		`SB:
			begin
				st_size <= byt;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SC:
			begin
				st_size <= char;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SH:
			begin
				st_size <= half;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SW:
			begin
				st_size <= word;
				isWR <= `TRUE;
				store_what <= `STW_B;
				store_check(ea_drn);
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
				store_check(ea_drn);
			end
		`CINV:
			begin
				Rt <= Rb;
				store_check(ea_drn);
			end
		`SBX:
			begin
				st_size <= byt;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`SCX:
			begin
				st_size <= char;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`SHX:
			begin
				st_size <= half;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`SWX:
			begin
				st_size <= word;
				isWR <= `TRUE;
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`CINVX:
			begin
				Rt <= Rc;
				store_check(ea_ndx);
			end
	// Unimplemented opcodes handled here
		default:
			;
		endcase
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
// Memory Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// LOAD machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOAD1:
	if (drdy) begin
		if (cpl > pmmu_dpl && pe)
			privilege_violation();
		else if (data_readable || !pe) begin
			if (isCAS)
				lock_o <= `TRUE;
			wb_read(rwadr_o);
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
			wb_read(rwadr_o);
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
		if (nMTSEG==2'b01) begin
			desc_h0 <= lres[31: 0];
			desc_h1 <= lres[63:32];
			nMTSEG <= 2'b10;
			next_state(LOAD1);
		end
		else if (nMTSEG==2'b10) begin
			desc_h2 <= lres[31: 0];
			desc_h3 <= lres[63:32];
			next_state(VERIFY_SEG_LOAD);
		end
		else if (nJGR==3'b001) begin
			prev_ss_base <= ss_base;
			prev_sp <= sp;
			if (!lres[31])
				segment_not_present();
			else if (lres[23:20] < (cpl > rpl ? cpl : rpl) && pe)
				privilege_violation();
			cg_acr <= lres[31:24];
			cg_dpl <= lres[23:20];
			cg_ncopy <= lres[4:0];
			cg_selector <= lres[55:32];
			a[23:0] <= lres[55:32];
			nJGR <= 3'b010;
			next_state(LOAD1);
		end
		else if (nJGR==3'b010) begin
			cg_offset <= lres[39:0];
			nJGR <= 3'b011;
			next_state(LOAD_CS);
		end
		else begin
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
			isJSRix,isJMPix:
				begin
					pc[39:0] <= lres[39:0];
					next_state(IFETCH);
				end
			isRTS:
				begin
					casex({nLD,lres[63:62]})
					5'b00_00:	// short format
						begin
							pc[39:0] <= lres[39:0];
							next_state(IFETCH);
						end
					5'b00_01:	// short format with selector
						begin
							ppl <= cpl;
							prev_sp <= sp + 32'd16;
							prev_ss <= ss;
							pc[39:0] <= lres[37:0];
							a[23:0] <= lres[61:38];
							nLD <= 3'b010;
							next_state(LOAD_CS);
						end
					5'b00_10:	// long format load
						begin
							pc[39:0] <= lres[39:0];
							nLD <= 3'b01;
							next_state(LOAD1);
						end
					5'b01_xx:
						begin
							ppl <= cpl;
							prev_sp <= sp + 32'd16;
							prev_ss <= ss;
							a[23:0] <= lres[61:38];
							nLD <= 3'b10;
							next_state(LOAD_CS);
						end
					5'b010_xx:
						begin
							update_sp(lres);
							nLD <= 3'b11;
							next_state(LOAD1);
						end
					5'b011_xx:
						begin
							St <= 4'd14;
							a <= lres[23:0];
							load_seg();
						end
					endcase
				end
			isRTI:
				begin
					casex(nLD)
					3'b00:	// long format load
						begin
							pc[39:0] <= lres[39:0];
							if (lres[63:62]!=2'b11)
								;	// bad return address
							nLD <= 3'b01;
							next_state(LOAD1);
						end
					3'b01:
						begin
							ppl <= cpl;
							prev_sp <= sp + 32'd16;
							prev_ss <= ss;
							a[23:0] <= lres[61:38];
							if (lres[8]==1'b0)
								imcd <= 3'b110;
							else
								im <= 1'b1;
							nLD <= 3'b10;
							next_state(LOAD_CS);
						end
					3'b010:
						begin
							update_sp(lres);
							nLD <= 3'b11;
							next_state(LOAD1);
						end
					3'b011:
						begin
							St <= 4'd14;
							a <= lres[23:0];
							load_seg();
						end
					endcase
				end
			isBRK:
				begin
					case (nLD)
					// 3. Load next CS:PC for the interrupt routine
					3'b000:
						begin
							cg_dpl <= lres[23:20];
							cg_selector <= lres[55:32];
							if (~lres[56])	// TRAP bit
								im <= 1'b1;
							nLD <= nLD + 3'd1;
							next_state(LOAD1);
							// Assume ACR = 86h or 87h
						end
					// 4. Load the SS:SP for the new CPL from the task state
					3'b001:
						begin
							cg_offset <= lres[39:0];
							rwadr <= {tss_base[31:2],2'b00} + {cg_dpl,4'h0} + 32'h200;
							nLD <= nLD + 3'd1;
							next_state(LOAD1);
						end
					3'b010:
						begin
							update_sp(lres);
							nLD <= nLD + 3'd1;
							next_state(LOAD1);
						end
					3'b011:
						begin
							St <= 4'd14;
							a <= lres[23:0];
							nLD <= nLD + 3'd1;
							load_seg();
						end
					endcase
				end
			isPOP:
				begin
					wrrf <= `TRUE;
					Rt <= RtPop;
					next_state(IFETCH);
				end
			isPOPS:
				begin
					wrspr <= `TRUE;
					Rt <= 6'd0;
					next_state(IFETCH);
				end
			isLxDT:
				begin
					if (nDT==2'b01) begin
						nDT <= 2'b10;
						if (Rt[1:0]==2'b00)
							idt_base[31:0] <= lres[31:0];
						else if (Rt[1:0]==2'b01)
							gdt_base[31:0] <= lres[31:0];
						//idt_base[63:32] <= dat32;
						next_state(LOAD1);
					end
					else begin
						if (Rt[1:0]==2'b00)
							idt_limit <= {lres[31:0]};
						else if (Rt[1:0]==2'b01)
							gdt_limit2 <= {lres[31:0]};
						next_state(IFETCH);
					end
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
			default:
				next_state(IFETCH);
			endcase
		end
	end

VERIFY_SEG_LOAD:
	begin
		res <= 65'd0;
		// Is the segment resident in memory ?
		if (!isPresent && !selectorIsNull) begin
			if (isVERR|isVERW|isVERX|isLDWx)
				;
			else begin
				if (St==4'd14)
					stack_fault();
				else
					segment_not_present();
			end
		end
		// are we trying to load a non-code segment into the code segment ?
		else if ((St==4'd15||isVERX) && desc_acr[4:3]!=2'b11 && pe && !selectorIsNull) begin
			if (isVERX)
				;
			else
				segtype_violation();
		end
		// are we trying to load a code segment into a data segment ?
		else if ((St!=4'd15||isVERR||isVERW) && desc_acr[4:3]==2'b11 && pe && !selectorIsNull) begin
			if (isVERR|isVERW)
				;
			else
				segtype_violation();
		end
		// The code privilege level must be the same or higher (numerically
		// lower) than the data descriptor privilege level.
//		// CPL <= DPL
		else if ((St!=4'd15||isCallGate||isVERR||isVERW||isLDWx) && cpl > desc_dpl && pe && !selectorIsNull) begin	// data segment
			if (isVERR||isVERW||isLDWx)
				;
			else
				privilege_violation();
		end
		else if ((St==4'd15||isVERX) && cpl < desc_dpl && !isConforming && !isCallGate && pe && !selectorIsNull) begin
			if (isVERX)
				;
			else
				privilege_violation();
		end
//		else if (cpl >= seg_dpl[Rt[3:0]] && dat32[28:27]==2'b11)	// code segment
//			next_state(IFETCH);
		else
		begin
			if (isLDWx) begin
				case(ir[21:20])
				2'd0:	res <= {desc_h1,desc_h0};
				2'd1:	res <= {desc_h3,desc_h2};
				default:	res <= 64'd0;
				endcase
				next_state(IFETCH);
			end
			else if (isVERR||isVERW||isVERX) begin
				res <= !selectorIsNull;
				next_state(IFETCH);
			end
			else if (isCallGate) begin
				prev_ss_base <= ss_base;
				prev_sp <= sp;
				cg_offset <= desc_h2[31:0];
				cg_selector <= desc_h1[23:0];
				cg_dpl <= desc_h0[23:20];
				cg_acr <= desc_h0[31:24];
				cg_ncopy <= desc_h0[4:0];
				isJGR <= `TRUE;
				a[23:0] <= desc_h1[23:0];
				if (!isPresent)
					segment_not_present();
				else if ((cpl > rpl ? cpl : rpl) > desc_dpl && pe)
					privilege_violation();
				else
					next_state(LOAD_CS);
			end
			else begin
				if (St==4'd0)	// not possible to load segment #0
					next_state(IFETCH);
				else if (St==4'd15 && selectorIsNull && pe)
					segtype_violation();
				else begin
					wrsrf <= `TRUE;
					if (isJGR)
						next_state(MOVESTK1);
					else if (isBRK) begin
						// 5. Store the old CS:PC on the new SS:SP stack
						if (nLD==3'b100) begin
							isWR <= `TRUE;
							rwadr <= ss_base + sp_dec;
							store_what <= `STW_SRCS;
							update_sp(sp_dec);
							nLD <= nLD + 3'd1;
							next_state(STORE1);
						end
					end
					else begin
						if (St==4'd15) begin
							cs <= a[23:0];
							next_state(CS_DELAY);
						end
						else
							next_state(IFETCH);	// in case code segment loaded
					end
				end
			end
		end
	end
LOAD_CS:
	load_cs_seg();
CS_DELAY:
	if (isRTS|isRTI) begin
		isWR <= `TRUE;
		store_what <= `STW_PREV_SP;
		rwadr <= {tss_base[31:2],2'b00} + {ppl,4'h0} + 32'h200;
		next_state(STORE1);
	end
	else
		next_state(IFETCH);



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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// STORE machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STORE1:
	if (drdy) begin	
		if (cpl > pmmu_dpl)
			privilege_violation();
		else if (data_writeable) begin
			case (store_what)
			`STW_A:		wb_write(st_size,rwadr_o,a[31:0]);
			`STW_B:		wb_write(st_size,rwadr_o,b[31:0]);
			`STW_C:		wb_write(st_size,rwadr_o,c[31:0]);
			`STW_PREV_SP:	wb_write(st_size,rwadr_o,prev_sp[31:0]);
			`STW_PREV_SS:	wb_write(st_size,rwadr_o,{8'h00,prev_ss[23:0]});
			`STW_SP:	wb_write(st_size,rwadr_o,sp[31:0]);
			`STW_SS:	wb_write(st_size,rwadr_o,{8'h00,ss[23:0]});
			`STW_CS:	wb_write(st_size,rwadr_o,32'd0);
			`STW_PC:	wb_write(word,rwadr_o,pc[31:0]);
			`STW_SRCS,
			`STW_SR:	wb_write(word,rwadr_o,sr[31:0]);
			`STW_IDT:	if (nDT==2'b01)
							wb_write(word,rwadr_o,idt_base[31:0]);
						else
							wb_write(word,rwadr_o,idt_limit[31:0]);
			`STW_GDT:	if (nDT==2'b01)
							wb_write(word,rwadr_o,gdt_base[31:0]);
						else
							wb_write(word,rwadr_o,gdt_limit[31:0]);
			`STW_SPR:	wb_write(word,rwadr_o,spro[31:0]);
			`STW_IMM:	wb_write(word,rwadr_o,imm[31:0]);
			default:	next_state(RESET);	// hardware fault
			endcase
			next_state(STORE2);
		end
		else
			data_write_fault();
	end
	else if (dpnp)
		data_page_fault();
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
					isWR <= `FALSE;
					next_state(IFETCH);
				end
				else begin
					rwadr <= rwadr;
					next_state(STORE1);
				end
			end
			else begin
				isWR <= `FALSE;
				next_state(IFETCH);
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
			case (store_what)
			`STW_A:		wb_write(word,rwadr_o,a[63:32]);
			`STW_B:		wb_write(word,rwadr_o,b[63:32]);
			`STW_C:		wb_write(word,rwadr_o,c[63:32]);
			`STW_SRCS,
			`STW_PREV_SP:	wb_write(st_size,rwadr_o,prev_sp[63:32]);
			`STW_PREV_SS:	wb_write(st_size,rwadr_o,32'h00);
			`STW_SP:	wb_write(st_size,rwadr_o,sp[63:32]);
			`STW_SS:	wb_write(st_size,rwadr_o,32'h00);
			`STW_CS:	wb_write(word,rwadr_o,{2'b00,cs,6'b0});
			`STW_PC:	if (isBRK)
							wb_write(word,rwadr_o,{2'b11,22'd0,pc[39:32]});
						else if (hasJSP|isJGR) begin
							if (pc[39:38]==2'b00)
								wb_write(word,rwadr_o,{2'b01,cs_selector[23:0],pc[37:32]});
							else
								wb_write(word,rwadr_o,{2'b10,22'b0,pc[39:32]});
						end
						else
							wb_write(word,rwadr_o,{24'd0,pc[39:32]});
			`STW_SR:	wb_write(word,rwadr_o,32'h00);
			`STW_SPR:	wb_write(word,rwadr_o,spro[63:32]);
			`STW_IMM:	wb_write(word,rwadr_o,imm[63:32]);
			default:	next_state(RESET);	// hardware fault
			endcase
			next_state(STORE4);
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
			if (isSMR) begin
				a <= rfoa;
				if (Ra>Rb || Ra==0) begin
					isWR <= `FALSE;
					next_state(IFETCH);
				end
				else
					next_state(STORE1);
			end
/*			else if (isJGR) begin
				if (store_what==`STW_PC) begin
					pc <= cg_offset;
					cs <= cg_selector;
					isWR <= `FALSE;
					next_state(CS_DELAY);
				end
				else begin
					store_what <= `STW_PC;
					rwadr <= ss_base + sp_dec;
					update_sp(sp_dec);
					next_state(STORE1);
				end
			end */
			else if (isBRK|isJGR) begin
				// 1. First store the current SS:SP in the task state segment
				if (store_what==`STW_SP) begin
					store_what <= `STW_SS;
					next_state(STORE1);
				end
				// 2. Load the interrupt/call gate from the IDT/LDT/GDT to get the cpl
				else if (store_what==`STW_SS) begin
					if (isJGR)
						load_gate(0); 
					else
						load_gate(1);
				end
				// 6. Set new CS:PC
				else if (store_what==`STW_PC) begin
					pc <= cg_offset;
					a <= cg_selector;
					isWR <= `FALSE;
					isBRK <= `FALSE;
					isJGR <= `FALSE;
					load_cs_seg();
				end
				// 5. Store CS:PC
				else begin
					store_what <= `STW_PC;
					rwadr <= ss_base + sp_dec;
					update_sp(sp_dec);
					next_state(STORE1);
				end
			end
			else if (isBSR)	begin
				if (isBSR16)
					pc <= pc + {{24{ir[23]}},ir[23:8]};
				else
					pc <= pc + {{16{ir[31]}},ir[31:8]};
				isWR <= `FALSE;
				next_state(IFETCH);
			end
			else if (isJSR)	begin
				isWR <= `FALSE;
				pc[31:0] <= imm[31:0];
				pc[39:32] <= imm[39:32];
				next_state(IFETCH);
			end
			else if (isJSRdrn) begin
				isWR <= `FALSE;
				pc[39:0] <= a[39:0];
				next_state(IFETCH);
			end
			else if (isJSRix) begin
				isWR <= `FALSE;
				rwadr <= rwadr2;
				next_state(LOAD1);
			end
			else if (isRTS|isRTI) begin
				if (store_what==`STW_PREV_SP) begin
					store_what <= `STW_PREV_SS;
					next_state(STORE1);
				end
				else begin
					isWR <= `FALSE;
					rwadr <= {tss_base[31:2],2'b00} + {cpl,4'h0} + 32'h200;
					next_state(LOAD1);
				end
			end
			else begin
				isWR <= `FALSE;
				next_state(IFETCH);
			end
		end
	end
	else if (err_i)
		bus_err();

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Move parameters from the caller's stack to the callee's stack during
// a gate routine call.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MOVESTK1:
	begin
		ncopy <= {cg_ncopy,1'b1};
		if (cg_ncopy!=5'd0) begin
			wb_burst(ncopy,prev_ss_base + {prev_sp[31:3],3'b00});
			next_state(MOVESTK2);
		end
		else begin
			next_state(MOVESTK5);
		end
	end
MOVESTK2:
	if (ack_i) begin
		ncopy <= ncopy - 6'd1;
		adr_o <= adr_o + 32'd4;
		stack_fifo[ncopy] <= dat_i;
		if (ncopy==6'd1)
			cti_o <= 3'b111;
		if (ncopy==6'd0) begin
			wb_nack();
			ncopy <= {cg_ncopy,1'b1};
			adr_ox <= ss_base + sp_dec;
			next_state(MOVESTK3);
		end
	end
MOVESTK3:
	begin
		wb_write(half,adr_ox,stack_fifo[ncopy]);
		next_state(MOVESTK4);
	end
MOVESTK4:
	if (ack_i) begin
		ncopy <= ncopy - 6'd1;
		wb_nack();
		adr_ox <= adr_ox - 32'd4;
		if (ncopy!=6'd0)
			next_state(MOVESTK3);
		else
			next_state(MOVESTK5);
	end
MOVESTK5:
	begin
		store_what <= `STW_CS;
		rwadr <= ss_base + sp_dec;
		update_sp(sp_dec);
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
	regfile[Rt] <= res;
	if (Rt==6'd47) begin
		spregfile[cpl] <= {res[63:3],3'b000};
		gie <= `TRUE;
		Rt <= 6'h00;
	end
	if (isLMR && wrrf) begin
		if (Rt==Rb)
			Rt <= 6'h00;
		else
			Rt <= Rt + 6'd1;
	end
end

if (state==IFETCH) begin
case(ir[7:0])
`RR:
	case(ir[39:32])
	`ADD,`SUB,`ADC,`SBC:
		mpcf <= res[64];
	endcase
`ADDI,`SUBI:
	mpcf <= res[64];
endcase
end

if (wrsrf) begin
	seg_selector[St] <= a[23:0];
	seg_base[St] <=  selectorIsNull ? 32'd0 : {desc_base[27:0],4'h0};
	seg_limit[St] <= selectorIsNull ? 32'd0 : {desc_limit[27:0],4'hF};
	if (St==4'd15 && isConforming)
		;
	else
		seg_dpl[St] <= selectorIsNull ? cpl : desc_dpl;
	seg_acr[St] <= selectorIsNull ? 8'h80 : desc_acr;
end

if (wrspr) begin
	casex(Sprt)
	//`TICK:	tick <= a;
	`VBR:		vbr <= {res[31:13],13'd0};
	`PTA:		pta <= res;
	`CR0:		cr0 <= res;
	`SRAND1:	m_z <= res;
	`SRAND2:	m_w <= res;
`ifdef SUPPORT_CLKGATE
	`CLK:		begin clk_throttle_new <= res[49:0]; ld_clk_throttle <= `TRUE; end
`endif
	`SR:	begin
			if (res[8]==1'b0)
				imcd <= 3'b110;
			else
				im <= 1'b1;
			pv <= res[1];
			cr0[0] <= res[0];	// pe bit
			end
	6'h2x:
		if (ir[17:14]!=4'd0) begin	// can't move to segment reg #0
			St <= ir[17:14];
			load_seg();
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
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= {adr[31:16],adr[15:2],2'b00};
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
	adr_o <= {adr[31:16],tmrcyc,adr[15:2],2'b00};
`else
	adr_o <= {adr[31:16],adr[15:2],2'b00};
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
	ir[7:0] <= `BRK;
	ivect <= 9'd508;
	hwi <= `TRUE;
	next_state(DECODE);
end
endtask

task update_sp;
input [63:0] newsp;
begin
	Rt <= 6'h62;
	wrrf <= `TRUE;
	res <= newsp;
end
endtask

task stack_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd504;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task code_page_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd505;
	rst_cpnp <= `TRUE;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task data_page_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd506;
	rst_dpnp <= `TRUE;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task data_read_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd499;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task executable_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd497;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task data_write_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd498;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task bounds_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd500;
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task segment_not_present;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd503;
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task privilege_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd501;
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task segtype_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ivect <= 9'd502;
	fault_pc <= pc;
	fault_cs <= cs_selector;
//	fault_seg <= a[63:32];
//	fault_st <= St;
	next_state(DECODE);
end
endtask

// If a NULL selector is passed, default the fields rather than reading them
// from the descriptor table. Also set the result bus to false for the 
// verify instructions.

task load_gate;
input isIGate;
begin
	if (isIGate) begin
		rwadr <= idt_base + {ivect,4'h0};
		if ({ivect,4'h0} > idt_limit && pe)
			bounds_violation();
		else
			next_state(LOAD1);
	end
	else begin
		if (a[19]) begin
			rwadr <= ldt_adr[31:0];
			if (ldt_seg_limit_violation && pe)
				bounds_violation();
			else
				next_state(LOAD1);
		end
		else begin
	//		if (a[63:40]==24'd0) begin
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
				if (gdt_seg_limit_violation && pe)
					bounds_violation();
				else
					next_state(LOAD1);
			end
		end
	end
end
endtask

task load_seg;
begin
	nMTSEG <= 2'b01;
	load_gate(0);
end
endtask

task load_cs_seg;
begin
	St <= 4'd15;
	load_seg();
end
endtask

task load_check;
input [63:0] adr;
begin
	if (cpl > dpl && pe)
		privilege_violation();
	else if (adr > seg_limit[Sa])
		bounds_violation();
	else begin
		rwadr <= adr;
		next_state(LOAD1);
	end
end
endtask

task store_check;
input [63:0] adr;
begin
	if (cpl > dpl && pe)
		privilege_violation();
	else if (adr > seg_limit[Sa])
		bounds_violation();
	else begin
		rwadr <= adr;
		next_state(STORE1);
	end
end
endtask

task set_default_seg;
begin
	case(Ra)
	6'd59:		Sa <= 4'd12;	// task register
	6'd60:		Sa <= 4'd14;	// base pointer
	6'd62:		Sa <= 4'd14;	// stack pointer
	6'd63:		Sa <= 4'd15;	// program counter
	default:	Sa <= 4'd1;
	endcase
end
endtask

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET      ";
IFETCH:	fnStateName = "IFETCH     ";
DECODE:	fnStateName = "DECODE     ";
EXECUTE:	fnStateName = "EXECUTE   ";
RTS1:	fnStateName = "RTS1       ";
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


