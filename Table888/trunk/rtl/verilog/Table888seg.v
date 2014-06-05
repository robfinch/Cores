// ============================================================================
// Table888seg.v
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
//`define SUPPORT_BITMAP_FNS		1'b1

`define TRUE	1'b1
`define FALSE	1'b0

`define RST_VECT	32'h0000FFF0
`define NMI_VECT	32'h0000FFE0
`define IRQ_VECT	32'h0000FFD0
`define DBG_VECT	32'h0000FFC0
`define ALN_VECT	32'h0000FFB0

`define BRK		8'h00
`define R		8'h01
`define SWAP		8'h03
`define MOV			8'h04
`define NEG			8'h05
`define COM			8'h06
`define NOT			8'h07
`define SXB			8'h08
`define SXC			8'h09
`define SXH			8'h0A
`define MTSEG		8'h0C
`define MFSEG		8'h0D
`define MTSEGI		8'h0E
`define MFSEGI		8'h0F
`define LSL			8'h10
`define LAR			8'h11
`define LSB			8'h12
`define GRAN		8'h14
`define SEI			8'h30
`define CLI			8'h31
`define PHP			8'h32
`define PLP			8'h33
`define ICON		8'h34
`define ICOFF		8'h35
`define PROT		8'h36
`define CLP			8'h37
`define RTI			8'h40
`define MTSPR		8'h48
`define MFSPR		8'h49
`define VERR		8'h80
`define VERW		8'h81
`define VERX		8'h82
`define MRK1		8'hF0
`define MRK2		8'hF1
`define MRK3		8'hF2
`define MRK4		8'hF3
`define RR		8'h02
`define ADD			8'h04
`define SUB			8'h05
`define CMP			8'h06
`define MUL			8'h07
`define DIV			8'h08
`define MOD			8'h09
`define ADDU		8'h14
`define SUBU		8'h15
`define MULU		8'h17
`define DIVU		8'h18
`define MODU		8'h19
`define AND			8'h20
`define OR			8'h21
`define EOR			8'h22
`define ANDN		8'h23
`define NAND		8'h24
`define NOR			8'h25
`define ENOR		8'h26
`define ORN			8'h27
`define MSO			8'h28
`define SSO			8'h29
`define SMR			8'h30
`define LMR			8'h31
`define ARPL		8'h38
`define SHLI		8'h50
`define ROLI		8'h51
`define SHRI		8'h52
`define RORI		8'h53
`define ASRI		8'h54
`define SHL			8'h40
`define ROL			8'h41
`define SHR			8'h42
`define ROR			8'h43
`define ASR			8'h44
`define ADDI	8'h04
`define SUBI	8'h05
`define CMPI	8'h06
`define MULI	8'h07
`define DIVI	8'h08
`define MODI	8'h09
`define ANDI	8'h0C
`define ORI		8'h0D
`define EORI	8'h0F
`define ADDUI	8'h14
`define SUBUI	8'h15
`define LDI		8'h16
`define MULUI	8'h17
`define DIVUI	8'h18
`define MODUI	8'h19
`define BEQ		8'h40
`define BNE		8'h41
`define BVS		8'h42
`define BVC		8'h43
`define BMI		8'h44
`define BPL		8'h45
`define BRA		8'h46
`define BRN		8'h47
`define BGT		8'h48
`define BLE		8'h49
`define BGE		8'h4A
`define BLT		8'h4B
`define BHI		8'h4C
`define BLS		8'h4D
`define BHS		8'h4E
`define BLO		8'h4F
`define JMP		8'h50
`define JSR		8'h51
`define JMP_IX	8'h52
`define JSR_IX	8'h53
`define JMP_DRN	8'h54
`define JSR_DRN	8'h55
`define BSR		8'h56
`define JGR		8'h57
`define BRZ		8'h58
`define BRNZ	8'h59
`define DBNZ	8'h5A
`define RTS		8'h60
`define JSP		8'h61
`define LB		8'h80
`define LBU		8'h81
`define LC		8'h82
`define LCU		8'h83
`define LH		8'h84
`define LHU		8'h85
`define LW		8'h86
`define LBX		8'h88
`define LBUX	8'h89
`define LCX		8'h8A
`define LCUX	8'h8B
`define LHX		8'h8C
`define LHUX	8'h8D
`define LWX		8'h8E
`define LIDT	8'h90
`define LGDT	8'h91
`define SB		8'hA0
`define SC		8'hA1
`define SH		8'hA2
`define SW		8'hA3
`define CINV	8'hA4
`define PUSH	8'hA6
`define POP		8'hA7
`define SBX		8'hA8
`define SCX		8'hA9
`define SHX		8'hAA
`define SWX		8'hAB
`define CINVX	8'hAC
`define SIDT	8'hB0
`define SGDT	8'hB1
`define BMS		8'hB4
`define BMC		8'hB5
`define BMF		8'hB6
`define BMT		8'hB7

`define NOP		8'hEA

`define IMM1	8'hFD
`define IMM2	8'hFE

`define STW_NONE	4'd0
`define STW_SR	4'd1
`define STW_PC	4'd2
`define STW_A	4'd3
`define STW_B	4'd4
`define STW_C	4'd5
`define STW_IDT	4'd6
`define STW_GDT	4'd7

`define TICK	8'h00
`define VBR		8'h01
`define BEAR	8'h02
`define PTA		8'h04
`define CR0		8'h05
`define FAULT_PC	8'h08
`define FAULT_CS	8'h09
`define SRAND1	8'h10
`define SRAND2	8'h11
`define RAND	8'h12

module Table888seg(
	rst_i, clk_i, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, ack_i, err_i, sel_o, we_o, adr_o, dat_i, dat_o,
	mmu_cyc_o, mmu_stb_o, mmu_ack_i, mmu_sel_o, mmu_we_o, mmu_adr_o, mmu_dat_i, mmu_dat_o);
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
output reg [31:0] adr_o;
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
parameter CINV1 = 6'd32;
parameter CINV2 = 6'd33;
parameter VERIFY_SEG_LOAD = 6'd34;
parameter LOAD_CS = 6'd36;
parameter HANG = 6'd37;
parameter JGR7 = 6'd38;
parameter JGR8 = 6'd39;
parameter JGR9 = 6'd40;
parameter JGR10 = 6'd41;
parameter JGR11 = 6'd42;
parameter JGR12 = 6'd43;
parameter JGR13 = 6'd44;
parameter JGR14 = 6'd45;
parameter JGR15 = 6'd46;
parameter JGR16 = 6'd47;

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

reg [5:0] state;
reg [3:0] store_what;
reg [39:0] ir;
wire [39:0] insn;
wire [7:0] opcode = ir[7:0];
wire [7:0] func = ir[39:32];
reg [PCMSB:0] pc;
wire [63:0] segmented_pc;
wire [63:0] paged_pc;
reg [PCMSB:0] ibufadr;
wire ibufmiss = ibufadr != paged_pc[PCMSB:0];
reg [39:0] ibuf;	// instruction buffer
reg isInsnCacheLoad,isCacheReset;
reg nmi_edge,nmi1;
reg hwi;			// hardware interrupt indicator
reg im;				// irq interrupt mask bit
wire pe;			// protection enabled
reg pv;				// privilege violation
reg [2:0] imcd;		// mask countdown bits
wire [31:0] sr = {23'd0,im,6'h00,pv,pe};
reg [63:0] regfile [255:0];

reg gie;						// global interrupt enable
wire [7:0] Ra = ir[15:8];
wire [7:0] Rb = ir[23:16];
wire [7:0] Rc = ir[31:24];
reg [7:0] Rt,RtPop;
reg [3:0] St,Sa;
reg wrrf;
reg [31:0] rwadr,rwadr2;
wire [31:0] rwadr_o;
reg icacheOn;
wire uncachedArea = 1'b0;
wire ihit;
reg [2:0] ld_size, st_size;
reg isRTS,isPUSH,isPOP,isIMM1,isIMM2,isCMPI;
reg isJSRix,isJSRdrn,isJMPix,isBRK,isPLP,isRTI;
reg isShifti,isBSR,isLMR,isSMR,isLGDT,isLIDT,isSIDT,isSGDT;
reg isJSP,isJSR,isJGR,isVERR,isVERW,isVERX,isLSL,isLAR,isLSB;
reg isBM;
reg [1:0] nMTSEG,nDT,nLD;
reg [2:0] nJGR;
wire hasIMM = isIMM1|isIMM2;
wire hasJSP = isJSP;
reg [63:0] rfoa,rfob,rfoc;
reg [64:0] res;			// result bus
reg [63:0] a,b,c;		// operand holding registers
reg [63:0] imm;
reg [63:0] immbuf;
reg [63:0] tick;		// tick count
reg [31:0] vbr;			// vector base register
reg [31:0] berr_addr;
reg [31:0] fault_pc;
reg [31:0] fault_cs;
reg [2:0] brkCnt;		// break counter for detecting multiple faults
reg [63:0] gdt_base;
reg [63:0] gdt_limit,gdt_limit2;
reg [63:0] idt_base;
reg [63:0] idt_limit,idt_limit2;
reg [31:0] seg_selector [15:0];
reg [63:0] seg_base [15:0];	// lower bound
reg [63:0] seg_limit [15:0];	// upper bound
reg [3:0] seg_dpl [15:0];	// privilege level
reg [7:0] seg_acr [15:0];	// access rights
reg cav,dav;				// address is valid for mmu translation
reg [63:0] desc_w0, desc_w1;
wire [7:0] desc_acr = desc_w1[63:56];
wire [3:0] desc_dpl = desc_w0[63:60];
wire [63:0] desc_limit = desc_w1[55:0];
wire [63:0] desc_base = desc_w0[59:0];
wire isCallGate = desc_acr[4:0]==5'b01100;
wire isConforming = desc_acr[2];
wire isPresent = desc_acr[7];

reg [23:0] cg_selector;
reg [59:0] cg_offset;
reg [3:0] cg_dpl;
reg [7:0] cg_acr;
reg [4:0] cg_ncopy;

wire [31:0] cs_selector = seg_selector[15];
wire [7:0] cs_acr = seg_acr[15];
wire [3:0] cpl = seg_dpl[15];
wire [3:0] dpl = seg_dpl[Sa];
wire [3:0] rpl = a[63:60];
assign segmented_pc = seg_base[15] + pc;
wire pcOutOfBounds = segmented_pc > seg_limit[15];
wire selectorIsNull = a[63:40]==24'd0;

wire cpnp,dpnp;
reg rst_cpnp,rst_dpnp;
reg [63:0] cr0;
reg [63:0] pta;
wire paging_en = cr0[31];
assign pe = cr0[0];
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

reg [63:0] sp;	// stack pointer
wire [63:0] sp_inc = sp + 64'd8;
wire [63:0] sp_dec = sp - 64'd8;

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
	.wclk(clk_i),
	.wr((ack_i & isInsnCacheLoad)|isCacheReset),
	.wa(adr_o),
	.v(!isCacheReset),
	.rclk(~clk_i),
	.pc(segmented_pc[31:0]),
	.hit(ihit)
);

wire [1:0] debug_bits;
icache_ram u2 (
	.wclk(clk_i),
	.wr(ack_i & isInsnCacheLoad),
	.wa(adr_o[12:0]),
	.i(dat_i),
	.rclk(~clk_i),
	.pc(segmented_pc[12:0]),
	.insn(insn),
	.debug_bits(debug_bits)
);

Table888_pmmu u3
(
	// syscon
	.rst_i(rst_i),
	.clk_i(clk_i),

	// master
	.soc_o(),			// start of cycle
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
	.dav(1'b1),					// data address is valid
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

// - - - - - - - - - - - - - - - - - -
// Combinational logic follows.
// - - - - - - - - - - - - - - - - - -

// register read ports
always @*
case(Ra)
8'h00:	rfoa <= 64'd0;
8'hFE:	rfoa <= pc[39:0];
8'hFF:	rfoa <= sp;
default:	rfoa <= regfile[Ra];
endcase
always @*
case(Rb)
8'h00:	rfob <= 64'd0;
8'hFE:	rfob <= pc[39:0];
8'hFF:	rfob <= sp;
default:	rfob <= regfile[Rb];
endcase
always @*
case(Rc)
8'h00:	rfoc <= 64'd0;
8'hFE:	rfoc <= pc[39:0];
8'hFF:	rfoc <= sp;
default:	rfoc <= regfile[Rc];
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
wire [63:0] pa = a[63] ? -a : a;
wire [127:0] p1 = aa * bb;
reg [127:0] p;
wire [63:0] diff = r - bb;

// For scaled indexed address mode
wire [63:0] b_scaled = b << ir[33:32];
reg [63:0] ea;
wire [63:0] seg_bas = seg_base[Sa];
wire [63:0] ea_drn1 = a + imm;
wire [63:0] ea_ndx1 = a + b_scaled + imm;
wire [63:0] ea_drn = seg_bas + ea_drn1;
wire [63:0] ea_ndx = seg_bas + ea_ndx1;
wire [63:0] mr_ea = seg_bas + c;
`ifdef SUPPORT_BITMAP_FNS
wire [63:0] ea_bm1 = a + {(b >> 6),3'b000} + imm;
wire [63:0] ea_bm = seg_bas + ea_bm1;
`endif

wire [63:0] gdt_adr = gdt_base + {a[59:40],4'h0};
wire [63:0] ldt_adr = seg_base[11] + {a[59:40],4'h0};
wire gdt_seg_limit_violation = gdt_adr > gdt_limit;
wire ldt_seg_limit_violation = ldt_adr > seg_limit[11];

wire [63:0] sp_segd = seg_base[14] + sp;
wire [63:0] spdec_segd = seg_base[14] + sp_dec;
reg [2:0] pcpl;
assign data_readable = pmmu_data_readable;
assign data_writeable = pmmu_data_writeable && seg_acr[Sa][1];

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

//wire [10:0] bias = 11'h3FF;				// bias amount (eg 127)
//wire [10:0] xl = rand[62:53];
//wire sgn = 1'b0;								// floating point: always generate a positive number
//wire [10:0] exp = xl > bias-1 ? bias-1 : xl;	// 2^-1 otherwise number could be over 1
//wire [52:0] man = rand[52:0];					// a leading '1' will be assumed
//wire [63:0] randfd = {sgn,exp,man};
reg [63:0] rando;


// - - - - - - - - - - - - - - - - - -
// Clocked logic follows.
// - - - - - - - - - - - - - - - - - -

always @(posedge clk_i)
if (rst_i) begin
	pc <= `RST_VECT;
	ibufadr <= 32'h00000000;
	icacheOn <= `FALSE;
	gie <= `FALSE;
	nmi1 <= `FALSE;
	nmi_edge <= `FALSE;
	isInsnCacheLoad <= `FALSE;
	isCacheReset <= `TRUE;
	wb_nack();
	adr_o[3:2] <= 2'b11;		// The tagram checks for this
	state <= RESET;
	store_what <= `STW_NONE;
	tick <= 64'd0;
	vbr <= 32'h00006000;
	imcd <= 3'b111;
	pv <= `FALSE;
	cr0 <= 64'd0;
	St <= 4'd0;
	rst_cpnp <= `TRUE;
	rst_dpnp <= `TRUE;
	isWR <= `FALSE;
end
else begin
tick <= tick + 64'd1;
if (nmi_i & !nmi1)
	nmi_edge <= `TRUE;
wrrf <= `FALSE;
rst_cpnp <= `FALSE;
rst_dpnp <= `FALSE;

gdt_limit <= gdt_base + gdt_limit2;
idt_limit <= idt_base + idt_limit2;

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
		seg_selector[St] <= {St,8'h00};
		seg_base[St] <= 64'h0;
		seg_limit[St] <= 64'hFFFFFFFFFFFFFFFF;
		seg_dpl[St] <= 4'h0;
		seg_acr[St] <= 8'h92;
		case(St)
		4'd0:	seg_limit[St] <= 64'h0;
		4'd15:	seg_acr[St] <= 8'h9A;
		default:	;	
		endcase
		St <= adr_o[7:4];
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
		if (rdy)
			next_state(DECODE);
		if (nmi_edge & gie & ~hasIMM) begin
			ir[7:0] <= `BRK;
			ir[39:8] <= {9'd510,4'h0};
			nmi_edge <= 1'b0;
			hwi <= `TRUE;
		end
		else if (irq_i & gie & ~im & ~hasIMM) begin
			ir[7:0] <= `BRK;
			ir[39:8] <= {vect_i,4'h0};
			hwi <= `TRUE;
		end
		else if (pcOutOfBounds)
			bounds_violation();
		else if (cpnp)
			code_page_fault();
		else if (!page_executable)
			executable_fault();
		else if (!ihit & !uncachedArea & icacheOn & rdy) begin
			next_state(ICACHE1);
		end
		else if (ibufmiss & (uncachedArea | !icacheOn) & rdy) begin
			next_state(IBUF1);
		end
		else if (icacheOn & !uncachedArea & rdy) begin
			if (debug_bits[0] & 1'b0) begin
				ir[7:0] <= `BRK;
				ir[39:8] <= `DBG_VECT;
				hwi <= `TRUE;
			end
			else
				ir <= insn;
		end
		else if (rdy)
			ir <= ibuf;
		if (imcd != 3'b111 && rdy) begin
			imcd <= {imcd,1'b0};
			if (imcd[2]==1'b0) begin
				im <= `FALSE;
				imcd <= 3'b111;
			end
		end
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
		wb_burst(6'd1,{paged_pc[31:2],2'h0});
		next_state(IBUF2);
	end
IBUF2:
	begin
		if (ack_i) begin
			cti_o <= 3'b111;
			adr_o <= adr_o + 32'd4;
			case(pc[1:0])
			2'b00:	ibuf[31:0] <= dat_i;
			2'b01:	ibuf[23:0] <= dat_i[31:8];
			2'b10:	ibuf[15:0] <= dat_i[31:16];
			2'b11:	ibuf[7:0] <= dat_i[31:24];
			endcase
			next_state(IBUF3);
		end
	end
IBUF3:
	begin
		if (ack_i) begin
			wb_nack();
			ibufadr <= paged_pc[PCMSB:0];
			case(pc[1:0])
			2'b00:	ibuf[39:32] <= dat_i[7:0];
			2'b01:	ibuf[39:24] <= dat_i[15:0];
			2'b10:	ibuf[39:16] <= dat_i[23:0];
			2'b11:	ibuf[39:8] <= dat_i;
			endcase
			next_state(IFETCH);
		end
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
			pc <= pc_inc(pc);
		// Default a number of signals. These defaults may be overridden later.
		isIMM1 <= `FALSE;
		isIMM2 <= `FALSE;
		isCMPI <= `FALSE;
		isBRK <= `FALSE;
		isBSR <= `FALSE;
		isJSR <= `FALSE;
		isJGR <= `FALSE;
		isJSRdrn <= `FALSE;
		isJSRix <= `FALSE;
		isJMPix <= `FALSE;
		isRTS <= `FALSE;
		isPOP <= `FALSE;
		isPUSH <= `FALSE;
		isPLP <= `FALSE;
		isRTI <= `FALSE;
		isLMR <= `FALSE;
		isSMR <= `FALSE;
		isJSP <= `FALSE;
		isLIDT <= `FALSE;
		isLGDT <= `FALSE;
		isSIDT <= `FALSE;
		isSGDT <= `FALSE;
		isVERR <= `FALSE;
		isVERW <= `FALSE;
		isVERX <= `FALSE;
		isLSL <= `FALSE;
		isLSB <= `FALSE;
		isBM <= `FALSE;
		nMTSEG <= 2'b00;
		nDT <= 2'b00;
		nLD <= 2'b00;
		nJGR <= 3'b000;
		isShifti = func==`SHLI || func==`SHRI || func==`ROLI || func==`RORI || func==`ASRI;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		ld_size <= word;
		st_size <= word;
		
		// Set the target register
		case(opcode)
		`R:	
			case(func)
			`MTSPR:	Rt <= 8'h00;	// We are writing to an SPR not the general register file
			`MTSEG:	Rt <= 8'h00;
			default:	Rt <= ir[23:16];
			endcase
		`RR:	Rt <= ir[31:24];
		`LDI:	Rt <= ir[15:8];
		`DBNZ:	Rt <= ir[15:8];
		`ADDI,`ADDUI,`SUBI,`SUBUI,`CMPI,`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,
		`ANDI,`ORI,`EORI:
			Rt <= ir[23:16];
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
			Rt <= ir[23:16];
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`BMT:
			Rt <= ir[31:24];
		default:
			Rt <= 8'h00;
		endcase

		// Immediate value multiplexer
		case(opcode)
		`BRK:		imm <= hwi ? ir[39:8] : {vbr[31:13],ir[20:8]};
		`LDI:		imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : {{40{ir[39]}},ir[39:16]};
		`JSR:		imm <= hasJSP ? {immbuf[31:0],ir[39:8]} : {cs_selector,ir[39:8]};	// PC has only 28 bits implemented
		`JMP:		imm <= hasJSP ? {immbuf[31:0],ir[39:8]} : {cs_selector,ir[39:8]};
		`JSR_IX:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`JMP_IX:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`JMP_DRN:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`JSR_DRN:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW,
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`SBX,`SCX,`SHX,`SWX,
		`CINV,`CINVX,`LIDT,`LGDT,`SIDT,`SGDT:	;
		default:
			if (hasIMM)
				imm <= {immbuf[47:0],ir[39:24]};
			else
				imm <= {{48{ir[39]}},ir[39:24]};
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
			`ICON:	begin icacheOn <= `TRUE; next_state(IFETCH); end
			`ICOFF:	begin icacheOn <= `FALSE; next_state(IFETCH); end
			`PHP:
				begin
					if (sp_dec < seg_base[14] + 32'd32)
						stack_fault();
					else begin
						isWR <= `TRUE;
						rwadr <= spdec_segd;
						update_sp(sp_dec);
						store_what <= `STW_SR;
						next_state(STORE1);
					end
				end
			`PLP:
				begin
					if (sp_inc > seg_limit[14])
						stack_fault();
					else begin
						isPLP <= `TRUE;
						rwadr <= sp_segd;
						update_sp(sp_inc);
						next_state(LOAD1);
					end
				end
			`RTI:
				begin
					if (cpl == 4'd15 && pe)
						privilege_violation();
					else if (sp_inc > seg_limit[14])
						stack_fault();
					else begin
						isRTI <= `TRUE;
						rwadr <= sp_segd;
						update_sp(sp_inc);
						next_state(LOAD1);
					end
				end
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
			`LSL:	begin
					isLSL <= `TRUE;
					load_seg();
					end
			`LAR:
				begin
					isLAR <= `TRUE;
					load_seg();
				end
			//`LSB:	begin
					//isLSB <= `TRUE;
					//load_seg();
			//		end
			`LSB:	Sa <= ir[11:8];
			`MFSEG:	Sa <= ir[11:8];
			// Unimplemented instruction
			default:	;
			endcase
		`RR:
			case(func)
			`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:	next_state(MULDIV);
			`LMR,`SMR:
					case(Rc)
					8'd252:		Sa <= 4'd12;	// task register
					8'd253:		Sa <= 4'd14;	// base pointer
					8'd254:		Sa <= 4'd15;	// instruction pointer
					8'd255:		Sa <= 4'd14;	// stack pointer
					default:	Sa <= 4'd1;
					endcase
			endcase

		`MULI,`MULUI,`DIVI,`DIVUI,`MOD,`MODU:	next_state(MULDIV);
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
				isBRK <= `TRUE;
				rwadr <= sp_dec;
				store_what <= `STW_SR;
				// Double fault ?
				brkCnt <= brkCnt + 3'd1;
				if (brkCnt > 3'd2)
					next_state(HANG);
				else if (idt_base + {ir[20:12],3'b000} > idt_limit && pe)
					bounds_violation();
				else if (sp_dec < seg_base[14] + 32'd16)
					stack_fault();
				else begin
					isWR <= `TRUE;
					update_sp(sp_dec);
					next_state(STORE1);
				end
				$stop;
			end
		`JMP:
			begin
				pc <= ir[39:8];
				if (!hasJSP)
					next_state(IFETCH);
				a <= {immbuf[31:0],ir[39:8]};
			end
		`BSR:
			begin
				if (sp_dec < seg_base[14] + 32'd32)
					stack_fault();
				else begin
					isBSR <= `TRUE;
					isWR <= `TRUE;
					rwadr <= sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					next_state(STORE1);	
				end
			end
		`JSR:
			begin
				if (sp_dec < seg_base[14] + 32'd32)
					stack_fault();
				else begin
					isJSR <= `TRUE;
					isJSP <= isJSP;
					isWR <= `TRUE;
					rwadr <= sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					a <= {immbuf[31:0],ir[39:8]};
					next_state(STORE1);
				end
			end
		`JSR_IX,`JMP_IX:
			begin
				if (isIMM1) begin
					Sa <= immbuf[31:28];
					imm <= {{12{immbuf[27]}},immbuf[27:0],ir[39:19],3'b000};
				end
				else if (isIMM2) begin
					Sa <= immbuf[63:60];
					imm <= {immbuf[39:0],ir[39:19],3'b000};
				end
				else begin
					set_default_seg(ir[17:16]);
					imm <= {{40{ir[39]}},ir[39:19],3'b000};
				end
			end
		`JGR:
			begin
				if (sp_dec < seg_base[14] + 32'd32)
					stack_fault();
				else begin
					isJGR <= `TRUE;
					nJGR <= 3'b001;
					isWR <= `TRUE;
					rwadr <= sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					a <= {ir[39:8],32'd0};
					next_state(STORE1);
				end
			end
		`JSR_DRN:
			begin
				if (sp_dec < seg_base[14] + 32'd32)
					stack_fault();
				else begin
					isJSRdrn <= `TRUE;
					isWR <= `TRUE;
					rwadr <= sp_dec[31:0];
					update_sp(sp_dec);
					store_what <= `STW_PC;
					next_state(STORE1);
				end
			end
		`RTS:
			begin
				if (sp_inc + ir[31:16] > seg_limit[14])
					stack_fault();
				else begin
					isRTS <= `TRUE;
					rwadr <= sp_segd;
					next_state(LOAD1);
					update_sp(sp_inc + ir[31:16]);
				end
			end
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LIDT,`LGDT,
		`SB,`SC,`SH,`SW,`SIDT,`SGDT:
			begin
				if (isIMM1) begin
					Sa <= immbuf[31:28];
					imm <= {{22{immbuf[27]}},immbuf[27:0],ir[39:26]};
				end
				else if (isIMM2) begin
					Sa <= immbuf[63:60];
					imm <= {immbuf[49:0],ir[39:16]};
				end
				else begin
					set_default_seg(ir[25:24]);
					imm <= {{50{ir[39]}},ir[39:26]};
				end
			end
		`CINV:
			begin
				if (isIMM1) begin
					Sa <= immbuf[31:28];
					imm <= {{22{immbuf[27]}},immbuf[27:0],ir[39:26]};
				end
				else if (isIMM2) begin
					Sa <= immbuf[63:60];
					imm <= {immbuf[49:0],ir[39:16]};
				end
				else begin
					set_default_seg(ir[25:24]);
					imm <= {{50{ir[39]}},ir[39:26]};
				end
				if (ir[23:16]==8'h00)
					Sa <= 4'd15;
			end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
		`SBX,`SCX,`SHX,`SWX,
		`BMS,`BMC,`BMF,`BMT:
			begin
				if (isIMM1) begin
					Sa <= immbuf[31:28];
					imm <= {{32{immbuf[27]}},immbuf[27:0],ir[39:36]};
				end
				else if (isIMM2) begin
					Sa <= immbuf[63:60];
					imm <= {immbuf[59:0],ir[39:36]};
				end
				else begin
					set_default_seg(ir[35:34]);
					imm <= {{60{ir[39]}},ir[39:36]};
				end
			end
		`CINVX:
			begin
				if (isIMM1) begin
					Sa <= immbuf[31:28];
					imm <= {{32{immbuf[27]}},immbuf[27:0],ir[39:36]};
				end
				else if (isIMM2) begin
					Sa <= immbuf[63:60];
					imm <= {immbuf[59:0],ir[39:36]};
				end
				else begin
					set_default_seg(ir[35:34]);
					imm <= {{60{ir[39]}},ir[39:36]};
				end
				if (ir[31:24]==8'h00)
					Sa <= 4'd15;
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// PUSH / POP
		// !isPUSH limits the test to the first word pushed, make
		// sure there is enough room to push four words (32 bytes)
		// plus a fault handler address.
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`PUSH:
			begin
				isPUSH <= `TRUE;
				store_what <= `STW_A;
				ir[39:8] <= {8'h00,ir[39:16]};
				rwadr <= {seg_base[4'd14][63:8],8'h00} + sp_dec[31:0];
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
					if (cpl > seg_dpl[14])
						privilege_violation();
					else if (sp_dec < seg_base[14] + 32'd64 && !isPUSH)
						stack_fault();
					else begin
						isWR <= `TRUE;
						update_sp(sp_dec);
						next_state(STORE1);
					end
				end
			end

		`POP:
			begin
				isPOP <= `TRUE;
				ir[39:8] <= {8'h00,ir[39:16]};
				RtPop <= ir[15:8];
				rwadr <= sp_segd;
				if (ir[39:8]==32'h0)
					next_state(IFETCH);
				else if (ir[15:8]==8'h00) begin
					pc <= pc;
					next_state(DECODE);
				end
				else begin
					pc <= pc;
					if (cpl > seg_dpl[14])
						privilege_violation();
					else if (sp_inc > seg_limit[14])
						stack_fault();
					else begin
						update_sp(sp_inc);
						next_state(LOAD1);
					end
				end
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Prefixes follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`JSP:
			begin
				isJSP <= `TRUE;
				immbuf <= ir[39:8];
				next_state(IFETCH);
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
			`NEG:	res <= -a;
			`COM:	res <= ~a;
			`NOT:	res <= ~|a;
			`SXB:	res <= {{56{a[7]}},a[7:0]};
			`SXC:	res <= {{48{a[15]}},a[15:0]};
			`SXH:	res <= {{32{a[31]}},a[31:0]};
			`MFSPR:
				casex(Ra)
				`TICK:	res <= tick;
				`VBR:	res <= vbr;
				`BEAR:	res <= berr_addr;
				`PTA:	res <= pta;
				`CR0:	res <= cr0;
				`FAULT_PC:	res <= fault_pc;
				`FAULT_CS:	res <= fault_cs;
				`RAND:		res <= rand;
				default:	res <= 65'd0;
				endcase
			`MTSPR:
				case(ir[23:16])	// Don't use Rt!
				//`TICK:	tick <= a;
				`VBR:	vbr <= {a[31:13],13'd0};
				`PTA:		pta <= a;
				`CR0:		cr0 <= a;
				`SRAND1:	m_z <= a;
				`SRAND2:	m_w <= a;
				endcase
			`MTSEG:
				if (ir[19:16]!=4'd0) begin	// can't move to segment reg #0
					St <= ir[19:16];
					load_seg();
				end
			`MFSEG:
				begin
					res <= {seg_selector[Sa][31:8],40'd0};
				end
			`LSB:	res <= seg_base[Sa];
			`GRAN:
				begin
					res <= rand;
					m_z <= next_m_z;
					m_w <= next_m_w;
				end
			endcase
		`RR:
			case(func)
			`ADD,`ADDU:	res <= a + b;
			`SUB,`SUBU:	res <= a - b;
			`CMP:		res <= {nf,vf,60'd0,zf,cf};
			`AND:		res <= a & b;
			`OR:		res <= a | b;
			`EOR:		res <= a ^ b;
			`ANDN:		res <= a & ~b;
			`NAND:		res <= ~(a & b);
			`NOR:		res <= ~(a | b);
			`ENOR:		res <= ~(a ^ b);
			`ORN:		res <= a | ~b;
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
			// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
			// LMR / SMR
			// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
			`LMR:
				begin
					isLMR <= `TRUE;
					Rt <= Ra;
					rwadr <= mr_ea;
					next_state(LOAD1);
				end
			`SMR:
				begin
					isSMR <= `TRUE;
					isWR <= `TRUE;
					rwadr <= mr_ea;
					store_what <= `STW_A;
					next_state(STORE1);
				end
			// Unimplemented instruction
			default:	res <= 65'd0;
			endcase
		`LDI:	res <= imm;
		`ADDI,`ADDUI:	res <= a + imm;
		`SUBI,`SUBUI:	res <= a - imm;
		`CMPI:	res <= {nf,vf,60'd0,zf,cf};
		`ANDI:	res <= a & imm;
		`ORI:	res <= a | imm;
		`EORI:	res <= a ^ imm;

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Flow Control Instructions Follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`BEQ,`BNE,`BVS,`BVC,`BMI,`BPL,`BRA,`BRN,`BGT,`BGE,`BLT,`BLE,`BHI,`BHS,`BLO,`BLS,
		`BRZ,`BRNZ:
			begin
				next_state(IFETCH);
				if (take_branch) begin
					pc[15: 0] <= ir[31:16];
					pc[PCMSB:16] <= pc[PCMSB:16] + {{PCMSB-20{ir[36]}},ir[36:32]};
				end
			end
		`DBNZ:
			begin
				next_state(IFETCH);
				if (take_branch) begin
					pc[15: 0] <= ir[31:16];
					pc[PCMSB:16] <= pc[PCMSB:16] + {{PCMSB-20{ir[36]}},ir[36:32]};
				end
				res <= a - 64'd1;
			end
		`JMP:
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
				if (ea_drn[63:40]==cs_selector[31:8])
					next_state(IFETCH);
				else
					load_cs_seg();
			end
		`JSR_IX:
			begin	
				if (sp_dec <= seg_base[14] + 32'd32)
					stack_fault();
				else begin
					rwadr2 <= ea_drn;
					rwadr <= sp_dec[31:0];
					isWR <= `TRUE;
					update_sp(sp_dec);
					isJSRix <= `TRUE;
					store_what <= `STW_PC;
					next_state(STORE1);
				end
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
`ifdef SUPPORT_BITMAP_FNS
		`BMS,`BMC,`BMF,`BMT:
			begin
				isBM <= `TRUE;
				load_check(ea_bm);
			end
`endif
		`LGDT:
			begin
				isLGDT <= `TRUE;
				nDT <= 2'b01;
				load_check(ea_drn);
			end
		`LIDT:
			begin
				isLIDT <= `TRUE;
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
			end
		`SGDT:
			begin
				isSGDT <= `TRUE;
				isWR <= `TRUE;
				nDT <= 2'b01;
				store_what <= `STW_GDT;
				store_check(ea_drn);
			end
		`SIDT:
			begin
				isSIDT <= `TRUE;
				isWR <= `TRUE;
				nDT <= 2'b01;
				store_what <= `STW_IDT;
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
				bb <= b;
				res_sgn <= 1'b0;
				next_state(MULT1);
			end
		`MULI:
			begin
				aa <= a[63] ? -a : a;
				bb <= b[63] ? -b : b;
				res_sgn <= a[63] ^ b[63];
				next_state(MULT1);
			end
		`DIVUI,`MODUI:
			begin
				aa <= a;
				bb <= b;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIVI,`MODI:
			begin
				aa <= a[63] ? -a : a;
				bb <= b[63] ? -b : b;
				q <= pa[62:0];
				r <= pa[63];
				res_sgn <= a[63] ^ b[63];
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
					aa <= a[31] ? -a : a;
					bb <= b[31] ? -b : b;
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
		if (cpl > pmmu_dpl)
			privilege_violation();
		else if (data_readable) begin
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
				res[31:0] <= dat32;
				next_state(LOAD3);
			end
			else begin
				case(ld_size)
				uhalf:	res <= {32'd0,dat32};
				half:	res <= {{32{dat32[31]}},dat32};
				uchar:	res <= {48'd0,dat16};
				char:	res <= {{48{dat16[15]}},dat16};
				ubyte:	res <= {56'd0,dat8};
				byt:	res <= {{56{dat8[7]}},dat8};
				default:	res[31:0] <= dat32;
				endcase
				next_state(IFETCH);
			end
			if (nMTSEG==2'b01)
				desc_w0[31:0] <= dat32;
			else if (nMTSEG==2'b10)
				desc_w1[31:0] <= dat32;
		end
		else if (err_i)
			bus_err();
	end
LOAD3:
	if (drdy) begin
		if (cpl > pmmu_dpl)
			privilege_violation();
		else if (data_readable) begin
			wb_read(rwadr_o);
			next_state(LOAD4);
		end
		else
			data_read_fault();
	end
	else if (dpnp)
		data_page_fault();
LOAD4:
	begin
		if (ack_i) begin
			rwadr <= rwadr + 32'd4;
			wb_nack();
			res[63:32] <= dat32;
			if (nMTSEG==2'b01) begin
				desc_w0[63:32] <= dat32;
				nMTSEG <= 2'b10;
				next_state(LOAD1);
			end
			else if (nMTSEG==2'b10) begin
				desc_w1[63:32] <= dat32;
				next_state(VERIFY_SEG_LOAD);
			end
			else if (nJGR==3'b001) begin
				cg_offset <= {dat32[27:0],res[31:0]};
				cg_dpl <= dat32[31:28];
				nJGR <= 3'b010;
			end
			else if (nJGR==3'b010) begin
				//cg_selector <= res[23:0];
				cg_selector <= res[23:0];
				cg_acr <= dat32[31:24];
				cg_ncopy <= res[28:24];
				a[63:40] <= res[23:0];
				if (!dat32[31])
					segment_not_present();
				else if (cg_dpl < (cpl > rpl ? cpl : rpl) && pe)
					privilege_violation();
				else
					next_state(LOAD_CS);
			end
			else
			case(1'b1)
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
					if (nLD==2'b00) begin
						pc <= res[31:0];
						pc[39:32] <= dat32[7:0];
						pc[1:0] <= res[3:2];
						a[63:32] <= dat32;
						if (res[1:0]==2'b11) begin
							nLD <= 2'b01;
							next_state(LOAD1);
						end
						else if (dat32[31:8]!=24'd0 && res[1:0]==2'b01)
							next_state(LOAD_CS);
						else
							next_state(IFETCH);
					end
					else begin
						a[63:32] <= dat32;
						next_state(LOAD_CS);
					end
				end
			isRTS:
				begin
					casex({nLD,res[1:0]})
					4'b00_00:	// short format
						begin
							pc[31:0] <= res[31:0];
							pc[39:32] <= dat32[7:0];
							pc[1:0] <= res[3:2];
							next_state(IFETCH);
						end
					4'b00_01:	// short format with selector
						begin
							pc[31:0] <= res[31:0];
							pc[39:32] <= dat32[7:0];
							a[63:32] <= dat32;
							next_state(LOAD_CS);
						end
					4'b00_11:	// long format load
						begin
							pc[31:0] <= res[31:0];
							pc[39:32] <= dat32[27:0];
							pc[1:0] <= res[3:2];
							nLD <= 2'b01;
							next_state(LOAD1);
						end
					4'b01_xx:
						begin
							a[63:32] <= dat32;
							next_state(LOAD_CS);
						end
					endcase
				end
			isBRK:
				begin
					if (cpl > res[31:28] && pe)
						privilege_violation();
					else begin
						if (dat32[28:24]==5'd6)	// interrupt gate sets interrupt mask
							im <= `TRUE;
						pc[39:0] <= res[27:0];
						a[63:32] <= {dat32[23:0],8'h00};
						next_state(LOAD_CS);
					end
				end
			isRTI:
				begin
					if (nLD==2'b00) begin
						pc <= res[31:0];
						pc[39:32] <= dat32[7:0];
						pc[1:0] <= res[3:2];
						update_sp(sp_inc);
						nLD <= 2'b01;
						next_state(LOAD1);
					end
					else begin
						if (res[8]==1'b0)
							imcd <= 3'b110;
						else
							im <= 1'b1;
						a[63:32] <= dat32;
						next_state(LOAD_CS);
					end
				end
			isPOP:
				begin
					wrrf <= `TRUE;
					Rt <= RtPop;
					next_state(DECODE);
				end
			isPLP:
				begin
					if (res[8]==1'b0)
						imcd <= 3'b110;
					else
						im <= 1'b1;
					next_state(IFETCH);
				end
			isLIDT:
				begin
					if (nDT==2'b01) begin
						nDT <= 2'b10;
						idt_base[31:0] <= res[31:0];
						idt_base[63:32] <= dat32;
						next_state(LOAD1);
					end
					else begin
						idt_limit2 <= {dat32,res[31:0]};
						next_state(IFETCH);
					end
				end
			isLGDT:
				begin
					if (nDT==2'b01) begin
						nDT <= 2'b10;
						gdt_base[31:0] <= res[31:0];
						gdt_base[63:32] <= dat32;
						next_state(LOAD1);
					end
					else begin
						gdt_limit2 <= {dat32,res[31:0]};
						next_state(IFETCH);
					end
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
					`BMS:	a <= {dat32,res[31:0]} | ( 64'd1 << b[5:0] );
					`BMC:	a <= {dat32,res[31:0]} & ~( 64'd1 << b[5:0] );
					`BMF:	a <= {dat32,res[31:0]} ^ ( 64'd1 << b[5:0] );
					`BMT:	res <= ({dat32,res[31:0]} >> b[5:0]) & 64'd1;
					endcase
				end
`endif
			default:
				next_state(IFETCH);
			endcase
		end
		else if (err_i)
			bus_err();
	end

VERIFY_SEG_LOAD:
	begin
		res <= 65'd0;
		// Is the segment resident in memory ?
		if (!isPresent && !selectorIsNull) begin
			if (isVERR|isVERW|isVERX|isLSL|isLAR|isLSB)
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
		else if ((St!=4'd15||isCallGate||isVERR||isVERW||isLSL||isLAR||isLSB) && cpl > desc_dpl && pe && !selectorIsNull) begin	// data segment
			if (isVERR||isVERW||isLSL||isLAR||isLSB)
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
				cg_offset <= desc_w0[59:0];
				cg_selector <= desc_w1[23:0];
				cg_dpl <= desc_w0[63:60];
				cg_acr <= desc_w1[63:56];
				cg_ncopy <= desc_w1[28:24];
				isJGR <= `TRUE;
				a[63:40] <= desc_w1[23:0];
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
					seg_selector[St] <= a[63:32];
					seg_base[St] <=  selectorIsNull ? 64'd0 : desc_base;
					seg_limit[St] <= selectorIsNull ? 64'd0 : desc_base + desc_limit;
					if (St==4'd15 && isConforming)	// conforming code segment inherits CPL
						seg_dpl[St] <= cpl;
					else
						seg_dpl[St] <= selectorIsNull ? cpl : desc_dpl;
					seg_acr[St] <= selectorIsNull ? 8'h80 : desc_acr;
					if (isJGR)
						pc[39:0] <= cg_offset[39:0];
					next_state(IFETCH);	// in case code segment loaded
				end
			end
		end
	end
LOAD_CS:
	load_cs_seg();

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
			`STW_PC:	if (isBRK)	// || (hasJSP && pc[59:40]!=20'd0))
							wb_write(word,rwadr_o,{pc[31:2],2'b11});
						else if (hasJSP)
							wb_write(word,rwadr_o,{pc[31:2],2'b01});
						else
							wb_write(word,rwadr_o,{pc[31:2],2'b00});
			`STW_SR:	wb_write(word,rwadr_o,sr[31:0]);
			`STW_IDT:	if (nDT==2'b01)
							wb_write(word,rwadr_o,idt_base[31:0]);
						else
							wb_write(word,rwadr_o,idt_limit2[31:0]);
			`STW_GDT:	if (nDT==2'b01)
							wb_write(word,rwadr_o,gdt_base[31:0]);
						else
							wb_write(word,rwadr_o,gdt_limit2[31:0]);
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
		if (st_size==word) begin
			next_state(STORE3);
		end
		else begin
			isWR <= `FALSE;
			next_state(IFETCH);
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
			`STW_PC:	if (isBRK)	// || (hasJSP && pc[59:40]!=20'd0))
							wb_write(word,rwadr_o,pc[39:32]);
						else if (hasJSP)
							wb_write(word,rwadr_o,{cs_selector[31:8],pc[39:32]});
						else
							wb_write(word,rwadr_o,{24'd0,pc[39:32]});
			`STW_SR:	wb_write(word,rwadr_o,{cs_selector[31:8],8'h00});
			`STW_IDT:	if (nDT==2'b01)
							wb_write(word,rwadr_o,idt_base[63:32]);
						else	
							wb_write(word,rwadr_o,idt_limit2[63:32]);
			`STW_GDT:	if (nDT==2'b01)
							wb_write(word,rwadr_o,gdt_base[63:32]);
						else
							wb_write(word,rwadr_o,gdt_limit2[63:32]);
			default:	next_state(RESET);	// hardware fault
			endcase
			next_state(STORE4);
			if (isSMR)
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
		if (isSMR) begin
			a <= rfoa;
			if (Ra>Rb || Ra==0) begin
				isWR <= `FALSE;
				next_state(IFETCH);
			end
			else
				next_state(STORE1);
		end
		else if (isBRK) begin
			if (store_what==`STW_PC) begin
				rwadr <= idt_base + {ir[20:12],3'b000};
				isWR <= `FALSE;
				next_state(LOAD1);
			end
			else begin
				store_what <= `STW_PC;
				rwadr <= sp_dec;
				update_sp(sp_dec);
				next_state(STORE1);
			end
		end
		else if (isBSR)	begin
			pc[15: 0] <= ir[31:16];
			pc[39:16] <= pc[39:16] + {{19{ir[36]}},ir[36:32]};
			isWR <= `FALSE;
			next_state(IFETCH);
		end
		else if (isJSR)
			begin
				isWR <= `FALSE;
				pc[31:0] <= imm[31:0];
				pc[39:32] <= imm[39:32];
				if (hasJSP) begin
					isJSP <= `FALSE;
					load_cs_seg();
				end
				else
					next_state(IFETCH);
			end
		else if (isJGR) begin
			isWR <= `FALSE;
			if (a[59])
				rwadr <= ldt_adr;
			else
				rwadr <= gdt_adr;
			next_state(LOAD1);
		end
		else if (isJSRdrn)
			begin
				isWR <= `FALSE;
				pc[39:0] <= a[39:0];
				load_cs_seg();
			end
		else if (isJSRix) begin
			isWR <= `FALSE;
			rwadr <= rwadr2;
			next_state(LOAD1);
		end
		else if (isPUSH)
			next_state(DECODE);
		else if (isSIDT|isSGDT) begin
			if (nDT==2'b01) begin
				nDT <= 2'b10;
				next_state(STORE1);
			end
			else begin
				isWR <= `FALSE;
				next_state(IFETCH);
			end
		end
		else begin
			isWR <= `FALSE;
			next_state(IFETCH);
		end
	end
	else if (err_i)
		bus_err();

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
	adr_o <= {adr[31:2],2'b00};
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
	adr_o <= {adr[31:2],2'b00};
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
input [31:0] adr;
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
	Rt <= 8'hFF;
	wrrf <= `TRUE;
	res <= newsp;
end
endtask

task bounds_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd500,4'h0};
	next_state(DECODE);
end
endtask

// If a NULL selector is passed, default the fields rather than reading them
// from the descriptor table. Also set the result bus to false for the 
// verify instructions.

task load_seg;
begin
	nMTSEG <= 2'b01;
	if (a[59]) begin
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
endtask

task load_cs_seg;
begin
	St <= 4'd15;
	load_seg();
end
endtask

task stack_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd504,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task code_page_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd505,4'h0};
	rst_cpnp <= `TRUE;
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task data_page_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd506,4'h0};
	rst_dpnp <= `TRUE;
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task data_read_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd499,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task executable_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd497,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task data_write_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd498,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task segment_not_present;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd503,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task privilege_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd501,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
end
endtask

task segtype_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd502,4'h0};
	fault_pc <= pc;
	fault_cs <= cs_selector;
	next_state(DECODE);
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
input [1:0] cd;
begin
	case(cd)
	2'b00:
		case(Ra)
		8'd252:		Sa <= 4'd12;	// task register
		8'd253:		Sa <= 4'd14;	// base pointer
		8'd254:		Sa <= 4'd15;	// instruction pointer
		8'd255:		Sa <= 4'd14;	// stack pointer
		default:	Sa <= 4'd1;
		endcase
	2'b01:	Sa <= 4'd3;
	2'b10:	Sa <= 4'd5;
	2'b11:	Sa <= 4'd14;
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
STORE1:	fnStateName = "STORE1     ";
STORE2:	fnStateName = "STORE2     ";
STORE3:	fnStateName = "STORE3     ";
STORE4:	fnStateName = "STORE4     ";
IBUF1:		fnStateName = "IBUF1 ";
IBUF2:		fnStateName = "IBUF2 ";
IBUF3:		fnStateName = "IBUF3 ";
ICACHE1:		fnStateName = "ICACHE1    ";
ICACHE2:		fnStateName = "ICACHE2    ";
CINV1:			fnStateName = "CINV1      ";
CINV2:			fnStateName = "CINV2      ";
LOAD_CS:		fnStateName = "LOAD_CS    ";
VERIFY_SEG_LOAD:	fnStateName = "VER_SEG_LOAD ";
default:		fnStateName = "UNKNOWN    ";
endcase
endfunction

endmodule

module syncram_512x32_1rw1r(wclk, wr, wa, i, rclk, ra, o);
input wclk;
input wr;
input [8:0] wa;
input [31:0] i;
input rclk;
input [8:0] ra;
output [31:0] o;

reg [31:0] mem [511:0];
reg [8:0] rra;

always @(posedge wclk)
	if (wr)
		mem[wa] <= i;
always @(posedge rclk)
	rra <= ra;
assign o = mem[rra];

endmodule

module icache_ram(wclk, wr, wa, i, rclk, pc, insn, debug_bits);
input wclk;
input wr;
input [12:0] wa;
input [31:0] i;
input rclk;
input [12:0] pc;
output reg [39:0] insn;
output reg [1:0] debug_bits;

wire [31:0] o1,o2,o3,o4;

syncram_512x32_1rw1r u1 (wclk, wr && wa[3:2]==2'b00, wa[12:4], i, rclk, pc[12:4], o1);
syncram_512x32_1rw1r u2 (wclk, wr && wa[3:2]==2'b01, wa[12:4], i, rclk, pc[12:4], o2);
syncram_512x32_1rw1r u3 (wclk, wr && wa[3:2]==2'b10, wa[12:4], i, rclk, pc[12:4], o3);
syncram_512x32_1rw1r u4 (wclk, wr && wa[3:2]==2'b11, wa[12:4], i, rclk, pc[12:4], o4);

wire [127:0] bundle = {o4,o3,o2,o1};

always @(pc or bundle)
case(pc[3:0])
4'd0:	insn <= bundle[39:0];
4'd5:	insn <= bundle[79:40];
4'd10:	insn <= bundle[119:80];
default:	insn <= {`ALN_VECT,`BRK};
endcase

always @(pc or bundle)
case(pc[3:0])
4'd0:	debug_bits <= bundle[121:120];
4'd5:	debug_bits <= bundle[123:122];
4'd10:	debug_bits <= bundle[125:124];
default:	debug_bits <= 2'b00;
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

wire [31:0] tag;

syncram_512x32_1rw1r u1 (wclk, wr && wa[3:2]==2'b11, wa[12:4], {wa[31:13],12'd0,v}, rclk, pc[12:4], tag);

assign hit = tag[31:13]==pc[31:13] && tag[0];


endmodule

