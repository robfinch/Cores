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
`define SUPPORT_PAGING				1'b1
`define SUPPORT_ICACHE				1'b1
//`define SUPPORT_DCACHE				1'b1
`define SUPPORT_BITFIELD			1'b1
`define SUPPORT_CLKGATE				1'b1

`define FEAT_DCACHE		1'b0
`define FEAT_ICACHE		1'b1
`define FEAT_PAGING		1'b1
`define FEAT_SEG		1'b0
`define FEAT_BITFIELD	1'b1
`define FEAT_BITMAP		1'b0
`define FEAT_CLK_GATE	1'b1

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
`define MOVS		8'h0E
`define LSL			8'h10
`define LAR			8'h11
`define LSB			8'h12
`define GRAN		8'h14
`define CPUID		8'h2A
`define SEI			8'h30
`define CLI			8'h31
`define PHP			8'h32
`define PLP			8'h33
`define ICON		8'h34
`define ICOFF		8'h35
`define CLP			8'h37
`define RTI			8'h40
`define STP			8'h41
`define UNLINK		8'h42
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
`define BITFIELD	8'h03
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
`define JAL		8'h5B
`define RTS		8'h60
`define JSP		8'h61
`define LINK	8'h62
`define RTD		8'h63
`define LB		8'h80
`define LBU		8'h81
`define LC		8'h82
`define LCU		8'h83
`define LH		8'h84
`define LHU		8'h85
`define LW		8'h86
`define LWS		8'h87
`define LBX		8'h88
`define LBUX	8'h89
`define LCX		8'h8A
`define LCUX	8'h8B
`define LHX		8'h8C
`define LHUX	8'h8D
`define LWX		8'h8E
`define LEAX	8'h8F
`define LEA		8'h92
`define SB		8'hA0
`define SC		8'hA1
`define SH		8'hA2
`define SW		8'hA3
`define CINV	8'hA4
`define SWS		8'hA5
`define PUSH	8'hA6
`define POP		8'hA7
`define SBX		8'hA8
`define SCX		8'hA9
`define SHX		8'hAA
`define SWX		8'hAB
`define CINVX	8'hAC
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
`define STW_SPR	4'd8

`define TICK	8'h00
`define VBR		8'h01
`define BEAR	8'h02
`define PTA		8'h04
`define CR0		8'h05
`define CLK		8'h06
`define FAULT_PC	8'h08
`define IVNO	8'h0C
`define HISTORY	8'h0D
`define SRAND1	8'h10
`define SRAND2	8'h11
`define RAND	8'h12

module Table888mmu(
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
parameter CINV1 = 6'd32;
parameter CINV2 = 6'd33;
parameter LINK1 = 6'd34;
parameter IBUF1b = 6'd35;
parameter IBUF2b = 6'd36;
parameter IBUF3b = 6'd37;
parameter IBUF1c = 6'd38;
parameter IBUF2c = 6'd39;
parameter IBUF3c = 6'd40;
parameter LOAD5 = 6'd41;
parameter LOAD6 = 6'd42;
parameter LOAD7 = 6'd43;
parameter DIV2 = 6'd44;
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
wire [95:0] cpu_class = "Table888    ";
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
wire clk;
reg [3:0] store_what;
reg [39:0] ir;
wire [39:0] insn;
wire [7:0] opcode = ir[7:0];
wire [7:0] func = ir[39:32];
reg [PCMSB:0] pc;
wire [63:0] paged_pc;
reg [PCMSB:0] ibufadr;
wire ibufmiss = ibufadr != paged_pc[PCMSB:0];
reg [39:0] ibuf1,ibuf2,ibuf3;	// instruction buffer
wire [39:0] ibuf = (ibuf1 & ibuf2) | (ibuf1 & ibuf3) | (ibuf2 & ibuf3);
reg hist_capture;
reg [31:0] history_buf [63:0];
reg [5:0] history_ndx;
reg [5:0] history_ndx2;
reg isInsnCacheLoad,isCacheReset;
reg nmi_edge,nmi1;
reg hwi;			// hardware interrupt indicator
reg im;				// irq interrupt mask bit
wire pe;			// protection enabled
reg pv;				// privilege violation
reg [2:0] imcd;		// mask countdown bits
wire [31:0] sr = {23'd0,im,6'h00,pv,pe};
reg [63:0] regfile1 [255:0];
reg [63:0] regfile2 [255:0];
reg [63:0] regfile3 [255:0];

reg gie;						// global interrupt enable
wire [7:0] Ra = ir[15:8];
wire [7:0] Rb = ir[23:16];
wire [7:0] Rc = ir[31:24];
reg [7:0] Rt,RtPop;
reg [3:0] St,Sa;
reg [7:0] Spr;		// special purpose register read port spec
reg [7:0] Sprt;
reg wrrf,wrsrf,wrspr;
reg [31:0] rwadr,rwadr2;
wire [31:0] rwadr_o;
reg icacheOn;
wire uncachedArea = 1'b0;
wire ihit;
reg [2:0] ld_size, st_size;
reg isRTS,isPUSH,isPOP,isIMM1,isIMM2,isCMPI;
reg isJSRix,isJSRdrn,isJMPix,isBRK,isPLP,isRTI;
reg isShifti,isBSR,isLMR,isSMR;
reg isJSP,isJSR,isLWS,isLink;
reg isBM;
reg [1:0] nLD;
wire hasIMM = isIMM1|isIMM2;
reg [63:0] rfoa,rfob,rfoc;
reg [64:0] res;			// result bus
reg [63:0] a,b,c;		// operand holding registers
reg [63:0] imm;
reg [63:0] immbuf;
wire [63:0] bfo;		/// bitfield op output
reg [63:0] tick;		// tick count
reg [31:0] vbr;			// vector base register
reg [31:0] berr_addr;
reg [31:0] fault_pc;
reg [2:0] brkCnt;		// break counter for detecting multiple faults
reg cav;
wire dav;				// address is valid for mmu translation
reg [15:0] JOB;
reg [15:0] TASK;
reg [63:0] lresx [2:0];
wire [63:0] lres = (lresx[0] & lresx[1]) | (lresx[0] & lresx[2]) | (lresx[1] & lresx[2]);

assign dav=state==LOAD1||state==LOAD3||state==STORE1||state==STORE3;

wire cpnp,dpnp;
reg rst_cpnp,rst_dpnp;
reg [63:0] cr0;
reg [63:0] pta;
wire paging_en = cr0[31];
assign pe = cr0[0];
wire tmrx = cr0[4];			// triple mode redundancy execute
wire tmrw = cr0[3];			// triple mode redundancy writes
wire tmrr = cr0[2];			// triple mode redundancy reads
reg [1:0] tmrcyc;			// tmr cycle number
wire [3:0] cpl = cr0[7:4];
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
	.wclk(clk),
	.wr((ack_i & isInsnCacheLoad)|isCacheReset),
	.wa(adr_o),
	.v(!isCacheReset),
	.rclk(~clk),
	.pc(paged_pc[31:0]),
	.hit(ihit)
);

wire [1:0] debug_bits;
icache_ram u2 (
	.wclk(clk),
	.wr(ack_i & isInsnCacheLoad),
	.wa(adr_o[12:0]),
	.i(dat_i),
	.rclk(~clk),
	.pc(paged_pc[12:0]),
	.insn(insn),
	.debug_bits(debug_bits)
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
	.vcadr({32'd0,pc}),	// virtual code address to translate
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

// - - - - - - - - - - - - - - - - - -
// Combinational logic follows.
// - - - - - - - - - - - - - - - - - -

// register read ports
always @*
case(Ra)
8'h00:	rfoa <= 64'd0;
8'hFE:	rfoa <= pc[39:0];
8'hFF:	rfoa <= sp;
default:	rfoa <= (regfile1[Ra] & regfile2[Ra]) | (regfile1[Ra] & regfile3[Ra]) | (regfile2[Ra] & regfile3[Ra]);
endcase
always @*
case(Rb)
8'h00:	rfob <= 64'd0;
8'hFE:	rfob <= pc[39:0];
8'hFF:	rfob <= sp;
default:	rfob <= (regfile1[Rb] & regfile2[Rb]) | (regfile1[Rb] & regfile3[Rb]) | (regfile2[Rb] & regfile3[Rb]);
endcase
always @*
case(Rc)
8'h00:	rfoc <= 64'd0;
8'hFE:	rfoc <= pc[39:0];
8'hFF:	rfoc <= sp;
default:	rfoc <= (regfile1[Rc] & regfile2[Rc]) | (regfile1[Rc] & regfile3[Rc]) | (regfile2[Rc] & regfile3[Rc]);
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
reg ld_divider;
wire div_done;
wire [63:0] pa = a[63] ? -a : a;
wire [127:0] p1 = aa * bb;
reg [127:0] p;
wire [63:0] diff = r - bb;

// For scaled indexed address mode
wire [63:0] b_scaled = b << ir[33:32];
reg [63:0] ea;
wire [63:0] ea_drn = a + imm;
wire [63:0] ea_ndx = a + b_scaled + imm;
wire [63:0] mr_ea = c;
`ifdef SUPPORT_BITMAP_FNS
wire [63:0] ea_bm = a + {(b >> 6),3'b000} + imm;
`endif

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
	`FAULT_PC:	spro <= fault_pc;
	`IVNO:		spro <= ivno;
	`HISTORY:	spro <= history_buf[history_ndx2];
	`RAND:		spro <= rand;
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
	icacheOn <= `FALSE;
	gie <= `FALSE;
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
	tmrcyc <= 2'd0;
	hist_capture <= `TRUE;
	history_ndx <= 6'd0;
	history_ndx2 <= 6'd0;
	ld_divider <= `FALSE;
`ifdef SUPPORT_CLKGATE
	ld_clk_throttle <= `FALSE;
`endif
end
else begin
tick <= tick + 64'd1;
if (nmi_i & !nmi1)
	nmi_edge <= `TRUE;
if (nmi_i|nmi1)
	clk_en <= `TRUE;
wrrf <= `FALSE;
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
		if (rdy) begin
			if (hist_capture) begin
				history_buf[history_ndx] <= pc[31:0];
				history_ndx <= history_ndx + 1;
			end
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
			else if (!page_executable && pe)
				executable_fault();
			else if (!ihit & !uncachedArea & icacheOn) begin
				next_state(ICACHE1);
			end
			else if (ibufmiss & (uncachedArea | !icacheOn)) begin
				next_state(IBUF1);
			end
			else if (icacheOn & !uncachedArea) begin
				if (debug_bits[0] & 1'b0) begin
					ir[7:0] <= `BRK;
					ir[39:8] <= `DBG_VECT;
					hwi <= `TRUE;
				end
				else
					ir <= insn;
			end
			else
				ir <= ibuf;
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
		wb_burst(6'd1,{paged_pc[31:16],2'b00,paged_pc[15:2],2'h0});
		next_state(IBUF2);
	end
IBUF2:
	if (ack_i) begin
		cti_o <= 3'b111;
		adr_o <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	ibuf1[31:0] <= dat_i;
		2'b01:	ibuf1[23:0] <= dat_i[31:8];
		2'b10:	ibuf1[15:0] <= dat_i[31:16];
		2'b11:	ibuf1[7:0] <= dat_i[31:24];
		endcase
		next_state(IBUF3);
	end
IBUF3:
	if (ack_i) begin
		wb_nack();
		ibufadr <= paged_pc[PCMSB:0];
		case(pc[1:0])
		2'b00:	ibuf1[39:32] <= dat_i[7:0];
		2'b01:	ibuf1[39:24] <= dat_i[15:0];
		2'b10:	ibuf1[39:16] <= dat_i[23:0];
		2'b11:	ibuf1[39:8] <= dat_i;
		endcase
		next_state(tmrx ? IBUF1b : IBUF4);
	end
IBUF4:
	begin
		ibuf2 <= ibuf1;
		ibuf3 <= ibuf1;
		next_state(IFETCH);
	end

IBUF1b:
	begin
		wb_burst(6'd1,{paged_pc[31:16],2'b01,paged_pc[15:2],2'h0});
		next_state(IBUF2b);
	end
IBUF2b:
	if (ack_i) begin
		cti_o <= 3'b111;
		adr_o <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	ibuf2[31:0] <= dat_i;
		2'b01:	ibuf2[23:0] <= dat_i[31:8];
		2'b10:	ibuf2[15:0] <= dat_i[31:16];
		2'b11:	ibuf2[7:0] <= dat_i[31:24];
		endcase
		next_state(IBUF3b);
	end
IBUF3b:
	if (ack_i) begin
		wb_nack();
		case(pc[1:0])
		2'b00:	ibuf2[39:32] <= dat_i[7:0];
		2'b01:	ibuf2[39:24] <= dat_i[15:0];
		2'b10:	ibuf2[39:16] <= dat_i[23:0];
		2'b11:	ibuf2[39:8] <= dat_i;
		endcase
		next_state(IBUF1c);
	end

IBUF1c:
	begin
		wb_burst(6'd1,{paged_pc[31:16],2'b10,paged_pc[15:2],2'h0});
		next_state(IBUF2c);
	end
IBUF2c:
	if (ack_i) begin
		cti_o <= 3'b111;
		adr_o <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	ibuf3[31:0] <= dat_i;
		2'b01:	ibuf3[23:0] <= dat_i[31:8];
		2'b10:	ibuf3[15:0] <= dat_i[31:16];
		2'b11:	ibuf3[7:0] <= dat_i[31:24];
		endcase
		next_state(IBUF3c);
	end
IBUF3c:
	if (ack_i) begin
		wb_nack();
		case(pc[1:0])
		2'b00:	ibuf3[39:32] <= dat_i[7:0];
		2'b01:	ibuf3[39:24] <= dat_i[15:0];
		2'b10:	ibuf3[39:16] <= dat_i[23:0];
		2'b11:	ibuf3[39:8] <= dat_i;
		endcase
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
			pc <= pc_inc(pc);
		// Default a number of signals. These defaults may be overridden later.
		isIMM1 <= `FALSE;
		isIMM2 <= `FALSE;
		isCMPI <= `FALSE;
		isBRK <= `FALSE;
		isBSR <= `FALSE;
		isJSR <= `FALSE;
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
		isLWS <= `FALSE;
		isBM <= `FALSE;
		nLD <= 2'b00;
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
			default:	Rt <= ir[23:16];
			endcase
		`RR:	Rt <= ir[31:24];
		`LDI:	Rt <= ir[15:8];
		`DBNZ:	Rt <= ir[15:8];
		`BITFIELD:
			Rt <= ir[23:16];
		`ADDI,`ADDUI,`SUBI,`SUBUI,`CMPI,`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,
		`ANDI,`ORI,`EORI,
		`JAL:
			Rt <= ir[23:16];
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA:
			Rt <= ir[23:16];
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,`BMT:
			Rt <= ir[31:24];
		`LINK,`RTD:
			Rt <= ir[15:8];
		default:
			Rt <= 8'h00;
		endcase

		// Immediate value multiplexer
		case(opcode)
		`BRK:		imm <= hwi ? ir[39:8] : {vbr[31:13],ir[20:8]};
		`LDI:		imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : {{40{ir[39]}},ir[39:16]};
		`JSR:		imm <= ir[39:8];	// PC has only 28 bits implemented
		`JMP:		imm <= ir[39:8];
		`JSR_IX:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`JMP_IX:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`JMP_DRN:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`JSR_DRN:	imm <= hasIMM ? {immbuf[39:0],ir[39:16]} : ir[39:16];
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW,`LEA,
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`SBX,`SCX,`SHX,`SWX,`LEAX,
		`CINV,`CINVX:	;
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
			`ICON:	begin icacheOn <= `TRUE; next_state(IFETCH); end
			`ICOFF:	begin icacheOn <= `FALSE; next_state(IFETCH); end
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
			`RTI:
				begin
					hist_capture <= `TRUE;
					if (cpl == 4'd15 && pe)
						privilege_violation();
					else begin
						isRTI <= `TRUE;
						rwadr <= sp;
						update_sp(sp_inc);
						next_state(LOAD1);
					end
				end
			`MOVS,`MFSPR,`MTSPR:
					begin
						Spr <= ir[15:8];
						Sprt <= ir[23:16];
					end
			// Unimplemented instruction
			default:	;
			endcase
		`RR:
			case(func)
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
				ivno <= ir[20:12];
				hist_capture <= `FALSE;
				isBRK <= `TRUE;
				rwadr <= sp_dec;
				store_what <= `STW_SR;
				// Double fault ?
				brkCnt <= brkCnt + 3'd1;
				if (brkCnt > 3'd2)
					next_state(HANG);
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
				next_state(IFETCH);
			end
		`BSR:
			begin
				isBSR <= `TRUE;
				isWR <= `TRUE;
				rwadr <= sp_dec[31:0];
				update_sp(sp_dec);
				store_what <= `STW_PC;
				next_state(STORE1);	
			end
		`JSR:
			begin
				isJSR <= `TRUE;
				isJSP <= isJSP;
				isWR <= `TRUE;
				rwadr <= sp_dec[31:0];
				update_sp(sp_dec);
				store_what <= `STW_PC;
				a <= {immbuf[31:0],ir[39:8]};
				next_state(STORE1);
			end
		`JSR_IX,`JMP_IX:
			begin
				if (isIMM1) begin
					imm <= {{12{immbuf[27]}},immbuf[27:0],ir[39:19],3'b000};
				end
				else if (isIMM2) begin
					imm <= {immbuf[39:0],ir[39:19],3'b000};
				end
				else begin
					imm <= {{40{ir[39]}},ir[39:19],3'b000};
				end
			end
		`JSR_DRN:
			begin
				isJSRdrn <= `TRUE;
				isWR <= `TRUE;
				rwadr <= sp_dec[31:0];
				update_sp(sp_dec);
				store_what <= `STW_PC;
				next_state(STORE1);
			end
		`RTS:
			begin
				isRTS <= `TRUE;
				rwadr <= sp;
				next_state(LOAD1);
				update_sp(sp_inc + ir[31:16]);
			end
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA,
		`SB,`SC,`SH,`SW:
			begin
				if (isIMM1) begin
					imm <= {{22{immbuf[27]}},immbuf[27:0],ir[39:26]};
				end
				else if (isIMM2) begin
					imm <= {immbuf[49:0],ir[39:16]};
				end
				else begin
					imm <= {{50{ir[39]}},ir[39:26]};
				end
			end
		`CINV:
			begin
				if (isIMM1) begin
					imm <= {{22{immbuf[27]}},immbuf[27:0],ir[39:26]};
				end
				else if (isIMM2) begin
					imm <= {immbuf[49:0],ir[39:16]};
				end
				else begin
					imm <= {{50{ir[39]}},ir[39:26]};
				end
			end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX,
		`BMS,`BMC,`BMF,`BMT:
			begin
				if (isIMM1) begin
					imm <= {{32{immbuf[27]}},immbuf[27:0],ir[39:36]};
				end
				else if (isIMM2) begin
					imm <= {immbuf[59:0],ir[39:36]};
				end
				else begin
					imm <= {{60{ir[39]}},ir[39:36]};
				end
			end
		`CINVX:
			begin
				if (isIMM1) begin
					imm <= {{32{immbuf[27]}},immbuf[27:0],ir[39:36]};
				end
				else if (isIMM2) begin
					imm <= {immbuf[59:0],ir[39:36]};
				end
				else begin
					imm <= {{60{ir[39]}},ir[39:36]};
				end
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
				rwadr <= sp_dec[31:0];
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

		`POP:
			begin
				isPOP <= `TRUE;
				ir[39:8] <= {8'h00,ir[39:16]};
				RtPop <= ir[15:8];
				rwadr <= sp;
				if (ir[39:8]==32'h0)
					next_state(IFETCH);
				else if (ir[15:8]==8'h00) begin
					pc <= pc;
					next_state(DECODE);
				end
				else begin
					pc <= pc;
					update_sp(sp_inc);
					next_state(LOAD1);
				end
			end

		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Prefixes follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
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
			`MOVS:	begin
						res <= spro;
						wrspr <= `TRUE;
					end
			`MFSPR:	begin
					res <= spro;
					if (Ra==8'h0D)
						history_ndx2 <= history_ndx2 + 6'd1;
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
			`UNLINK:
				begin
					wrrf <= `TRUE;
					res <= a;						// MOV SP,BP
					ir <= {16'h0000,Ra,8'hFF,`LW};	// LW BP,[SP]
					next_state(LINK1);				// need cycle to update SP
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
		`BITFIELD:	res <= bfo;
		`LDI:	res <= imm;
		`ADDI,`ADDUI:	res <= a + imm;
		`SUBI,`SUBUI:	res <= a - imm;
		`CMPI:	res <= {nf,vf,60'd0,zf,cf};
		`ANDI:	res <= a & imm;
		`ORI:	res <= a | imm;
		`EORI:	res <= a ^ imm;
		
		`LINK:	begin
				isLink <= `TRUE;
				wrrf <= `TRUE;
				res <= a - imm;						// SUBUI SP,SP,#imm
				ir <= {16'h0000,Rb,Ra,`SW};			// SW BP,[SP]
				next_state(LINK1);					// need time to update and read reg
				end

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
				rwadr2 <= ea_drn;
				rwadr <= sp_dec[31:0];
				isWR <= `TRUE;
				update_sp(sp_dec);
				isJSRix <= `TRUE;
				store_what <= `STW_PC;
				next_state(STORE1);
			end
		`JAL:
			begin
				res <= pc;
				pc <= a + imm;
			end
		`RTD:
			begin
				pc <= b;
				res <= a + imm;
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
		`LEA:	res <= ea_drn;
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
		`LEAX:	res <= ea_ndx;
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
				ld_divider <= `TRUE;
				aa <= a;
				bb <= imm;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIVI,`MODI:
			begin
				ld_divider <= `TRUE;
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
					aa <= a[31] ? -a : a;
					bb <= b[31] ? -b : b;
					res_sgn <= a[63] ^ b[63];
					next_state(MULT1);
				end
			`DIVU,`MODU:
				begin
					ld_divider <= `TRUE;
					aa <= a;
					bb <= b;
					q <= a[62:0];
					r <= a[63];
					res_sgn <= 1'b0;
					next_state(DIV);
				end
			`DIV,`MOD:
				begin
					ld_divider <= `TRUE;
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
		isJSRix,isJMPix,isRTS:
			begin
				pc[39:2] <= lres[39:2];
				pc[1:0] <= lres[3:2];
				next_state(IFETCH);
			end
		isBRK:
			begin
				im <= `TRUE;
				pc[39:2] <= lres[39:2];
				pc[1:0] <= lres[3:2];
				next_state(IFETCH);
			end
		isRTI:
			begin
				if (nLD==2'b00) begin
					pc <= lres[39:0];
					pc[1:0] <= lres[3:2];
					update_sp(sp_inc);
					nLD <= 2'b01;
					next_state(LOAD1);
				end
				else begin
					if (lres[8]==1'b0)
						imcd <= 3'b110;
					else
						im <= 1'b1;
					next_state(IFETCH);
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
				if (lres[8]==1'b0)
					imcd <= 3'b110;
				else
					im <= 1'b1;
				next_state(IFETCH);
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
LOAD7:
	begin
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
			`STW_PC:	if (isBRK)
							wb_write(word,rwadr_o,{pc[31:2],2'b11});
						else
							wb_write(word,rwadr_o,{pc[31:2],2'b00});
			`STW_SR:	wb_write(word,rwadr_o,sr[31:0]);
			`STW_SPR:	wb_write(word,rwadr_o,spro[31:0]);
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
			`STW_PC:	wb_write(word,rwadr_o,{24'd0,pc[39:32]});
			`STW_SR:	wb_write(word,rwadr_o,32'h00);
			`STW_SPR:	wb_write(word,rwadr_o,spro[63:32]);
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
					rwadr <= {vbr[31:12],ir[20:12],3'b000};
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
	regfile1[Rt] <= res;
	regfile2[Rt] <= res;
	regfile3[Rt] <= res;
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
	adr_o <= {adr[31:16],tmrcyc,adr[15:2],2'b00};
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
	adr_o <= {adr[31:16],tmrcyc,adr[15:2],2'b00};
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
	Rt <= 8'hFF;
	wrrf <= `TRUE;
	res <= newsp;
end
endtask

task stack_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd504,4'h0};
	fault_pc <= pc;
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
	next_state(DECODE);
end
endtask

task data_read_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd499,4'h0};
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task executable_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd497,4'h0};
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task data_write_fault;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd498,4'h0};
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task privilege_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= {9'd501,4'h0};
	fault_pc <= pc;
	next_state(DECODE);
end
endtask

task load_check;
input [63:0] adr;
begin
	rwadr <= adr;
	next_state(LOAD1);
end
endtask

task store_check;
input [63:0] adr;
begin
	rwadr <= adr;
	next_state(STORE1);
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
default:		fnStateName = "UNKNOWN    ";
endcase
endfunction

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

syncram_512x32_1rw1r u1 (
  .clka(wclk), // input clka
  .wea(wr && wa[3:2]==2'b00), // input [0 : 0] wea
  .addra(wa[12:4]), // input [8 : 0] addra
  .dina(i), // input [31 : 0] dina
  .clkb(rclk), // input clkb
  .addrb(pc[12:4]), // input [8 : 0] addrb
  .doutb(o1) // output [31 : 0] doutb
);

syncram_512x32_1rw1r u2 (
  .clka(wclk), // input clka
  .wea(wr && wa[3:2]==2'b01), // input [0 : 0] wea
  .addra(wa[12:4]), // input [8 : 0] addra
  .dina(i), // input [31 : 0] dina
  .clkb(rclk), // input clkb
  .addrb(pc[12:4]), // input [8 : 0] addrb
  .doutb(o2) // output [31 : 0] doutb
);

syncram_512x32_1rw1r u3 (
  .clka(wclk), // input clka
  .wea(wr && wa[3:2]==2'b10), // input [0 : 0] wea
  .addra(wa[12:4]), // input [8 : 0] addra
  .dina(i), // input [31 : 0] dina
  .clkb(rclk), // input clkb
  .addrb(pc[12:4]), // input [8 : 0] addrb
  .doutb(o3) // output [31 : 0] doutb
);

syncram_512x32_1rw1r u4 (
  .clka(wclk), // input clka
  .wea(wr && wa[3:2]==2'b11), // input [0 : 0] wea
  .addra(wa[12:4]), // input [8 : 0] addra
  .dina(i), // input [31 : 0] dina
  .clkb(rclk), // input clkb
  .addrb(pc[12:4]), // input [8 : 0] addrb
  .doutb(o4) // output [31 : 0] doutb
);

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

syncram_512x32_1rw1r u1 (
  .clka(wclk), // input clka
  .wea(wr && wa[3:2]==2'b11), // input [0 : 0] wea
  .addra(wa[12:4]), // input [8 : 0] addra
  .dina({wa[31:13],12'd0,v}), // input [31 : 0] dina
  .clkb(rclk), // input clkb
  .addrb(pc[12:4]), // input [8 : 0] addrb
  .doutb(tag) // output [31 : 0] doutb
);

assign hit = (tag[31:13]==pc[31:13]) && tag[0];


endmodule


