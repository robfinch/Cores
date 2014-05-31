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
`define SEI			8'h30
`define CLI			8'h31
`define PHP			8'h32
`define PLP			8'h33
`define ICON		8'h34
`define ICOFF		8'h35
`define PROT		8'h36
`define RTI			8'h40
`define MTSPR		8'h48
`define MFSPR		8'h49
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
`define SPx		8'b00010xxx

module Table888seg(rst_i, clk_i, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, err_i, sel_o, we_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
input [8:0] vect_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg [3:0] sel_o;
output reg we_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
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
parameter PC_DELAY = 6'd28;
parameter PC_DELAY2 =6'd29;
parameter CINV1 = 6'd32;
parameter CINV2 = 6'd33;
parameter VERIFY_SEG_LOAD = 6'd34;
parameter JGR5 = 6'd36;
parameter JGR6 = 6'd37;
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
reg [39:0] pc;
reg [39:0] ibufadr;
wire ibufmiss = ibufadr != segmented_pc[39:0];
reg [39:0] ibuf;	// instruction buffer
reg isInsnCacheLoad,isCacheReset;
reg nmi_edge,nmi1;
reg hwi;			// hardware interrupt indicator
reg im;				// irq interrupt mask bit
reg pe;				// protection enabled
reg [2:0] imcd;		// mask countdown bits
wire [31:0] sr = {23'd0,im,8'h00};
reg [63:0] regfile [255:0];

reg gie;						// global interrupt enable
wire [7:0] Ra = ir[15:8];
wire [7:0] Rb = ir[23:16];
wire [7:0] Rc = ir[31:24];
reg [7:0] Rt;
reg [3:0] St,Sa;
reg wrrf;
reg [31:0] wadr, radr;
reg icacheOn;
wire uncachedArea = 1'b0;
wire ihit;
reg [2:0] ld_size, st_size;
reg isRTS,isPUSH,isPOP,isIMM1,isIMM2,isCMPI;
reg isJSRix,isJSRdrn,isJMPix,isBRK,isPLP,isRTI;
reg isShifti,isBSR,isLMR,isSMR,isLGDT,isLIDT,isSIDT,isSGDT;
reg isJSP,isJSR,isJGR;
reg [1:0] nMTSEG,nDT;
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
reg [63:0] gdt_lbound;
reg [63:0] gdt_ubound;
reg [63:0] idt_lbound;
reg [63:0] idt_ubound;
reg [31:0] seg_selector [15:0];
reg [63:0] seg_lbound [15:0];	// lower bound
reg [63:0] seg_ubound [15:0];	// upper bound
reg [2:0] seg_dpl [15:0];	// privilege level
reg [7:0] seg_acr [15:0];	// access rights
reg [19:0] seg_index;

reg [63:0] desc_w0, desc_w1;
wire [7:0] desc_acr = desc_w1[63:56];
wire [2:0] desc_dpl = desc_w0[63:61];
wire [63:0] desc_ubound = {desc_w1[55:0],8'h00};
wire [63:0] desc_lbound = {desc_w0[55:0],8'h00};
wire isCallGate = desc_acr[4:0]==5'b01100;

reg [23:0] cg_selector;
reg [39:0] cg_offset;
reg [2:0] cg_dpl;
reg [7:0] cg_acr;
reg [4:0] cg_ncopy;

wire [31:0] cs_selector = seg_selector[15];
wire [7:0] cs_acr = seg_acr[15];
wire [2:0] cpl = seg_dpl[15];
wire [2:0] dpl = seg_dpl[Sa];
wire [2:0] rpl = a[63:61];
wire [63:0] code_base = pc[31:16]==16'h0000 ? 64'd0 : {seg_lbound[15][63:8],8'h00};
wire [63:0] segmented_pc = code_base + pc;
wire pcOutOfBounds = segmented_pc > {seg_ubound[15][63:8],8'h00};

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
	.rclk(clk_i),
	.pc(segmented_pc[31:0]),
	.hit(ihit)
);

wire [1:0] debug_bits;
icache_ram u2 (
	.wclk(clk_i),
	.wr(ack_i & isInsnCacheLoad),
	.wa(adr_o[12:0]),
	.i(dat_i),
	.rclk(clk_i),
	.pc(segmented_pc[12:0]),
	.insn(insn),
	.debug_bits(debug_bits)
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
always @(dat_i or radr)
case(radr[1:0])
2'b00:	dat8 <= dat_i[7:0];
2'b01:	dat8 <= dat_i[15:8];
2'b10:	dat8 <= dat_i[23:16];
2'b11:	dat8 <= dat_i[31:24];
endcase
reg [15:0] dat16;
always @(dat_i or radr)
case(radr[1])
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
wire [63:0] seg_base = Sa==4'd0 ? 64'd0 : {seg_lbound[Sa][63:8],8'h00};
wire [63:0] ea_drn = seg_base + a + imm;
wire [63:0] ea_ndx = seg_base + a + b_scaled + imm;
wire [63:0] mr_ea = seg_base + c;
wire seg_over_drn = ea_drn[63:8] > seg_ubound[Sa][63:8];
wire seg_over_ndx = ea_ndx[63:8] > seg_ubound[Sa][63:8];

wire [63:0] gdt_adr = {gdt_lbound[63:8],8'h00} + {a[59:40],4'h0};
wire [63:0] ldt_adr = {seg_lbound[11][63:8],8'h00} + {a[59:40],4'h0};
wire gdt_seg_ubound_violation = gdt_adr[63:8] > gdt_ubound[63:8];
wire ldt_seg_ubound_violation = ldt_adr[63:8] > seg_ubound[11][63:8];

wire [63:0] sp_segd = {seg_lbound[14][63:8],8'h00} + sp;
wire [63:0] spdec_segd = {seg_lbound[14][63:8],8'h00} + sp_dec;
reg [2:0] pcpl;

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
	pe <= `FALSE;
end
else begin
tick <= tick + 64'd1;
if (nmi_i & !nmi1)
	nmi_edge <= `TRUE;
wrrf <= `FALSE;

case(state)
RESET:
	begin
		adr_o[3:2] <= 2'b11;		// The tagram checks for this
		adr_o[12:4] <= adr_o[12:4] + 9'd1;
		if (adr_o[12:4]==9'h1FF) begin
			isCacheReset <= `FALSE;
			next_state(PC_DELAY);
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
		next_state(DECODE);
		if (nmi_edge & gie & ~hasIMM) begin
			ir[7:0] <= `BRK;
			ir[39:8] <= 9'd510;
			nmi_edge <= 1'b0;
			hwi <= `TRUE;
		end
		else if (irq_i & gie & ~im & ~hasIMM) begin
			ir[7:0] <= `BRK;
			ir[39:8] <= vect_i;
			hwi <= `TRUE;
		end
		else if (pcOutOfBounds)
			bounds_violation();
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache load machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ICACHE1:
	begin
		isInsnCacheLoad <= `TRUE;
		wb_burst(6'd3,{segmented_pc[31:4],4'h0});
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
			next_state(PC_DELAY);
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction buffer load machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

IBUF1:
	begin
		wb_burst(6'd1,{segmented_pc[31:2],2'h0});
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
			ibufadr <= segmented_pc[31:0];
			case(pc[1:0])
			2'b00:	ibuf[39:32] <= dat_i[7:0];
			2'b01:	ibuf[39:24] <= dat_i[15:0];
			2'b10:	ibuf[39:16] <= dat_i[23:0];
			2'b11:	ibuf[39:8] <= dat_i;
			endcase
			next_state(IFETCH);
		end
	end

PC_DELAY:
	next_state(PC_DELAY2);
PC_DELAY2:
	next_state(IFETCH);

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
		nMTSEG <= 2'b00;
		nDT <= 2'b00;
		nJGR <= 3'b000;
		cg_loaded <= `FALSE;
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
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX:
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
		`NOP:	next_state(PC_DELAY);
		`R:
			case(func)
			`SEI:	begin im <= `TRUE; next_state(PC_DELAY); end
			`CLI:	begin imcd <= 3'b110; next_state(PC_DELAY); end
			`PROT:	begin pe <= `TRUE; next_state(PC_DELAY); end
			`ICON:	begin icacheOn <= `TRUE; next_state(PC_DELAY); end
			`ICOFF:	begin icacheOn <= `FALSE; next_state(PC_DELAY); end
			`PHP:
				begin
					wadr <= spdec_segd;
					Rt <= 8'hFF;
					wrrf <= `TRUE;
					res <= sp_dec;
					store_what <= `STW_SR;
					next_state(STORE1);
				end
			`PLP:
				begin
					isPLP <= `TRUE;
					radr <= sp_segd;
					Rt <= 8'hFF;
					wrrf <= `TRUE;
					res <= sp_inc;
					next_state(LOAD1);
				end
			`RTI:
				begin
					isRTI <= `TRUE;
					radr <= sp_segd;
					Rt <= 8'hFF;
					wrrf <= `TRUE;
					res <= sp_inc;
					next_state(LOAD1);
				end
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
			`MSO:	Sa <= Rb[3:0];
			`SSO:	St <= Rb[3:0];
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
				wadr <= sp_dec;
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_dec;
				store_what <= `STW_SR;
				next_state(STORE1);
				$stop;
			end
		`JMP:
			begin
				pc <= ir[39:8];
				if (!hasJSP)
					next_state(PC_DELAY);
				a <= {immbuf[31:0],ir[39:8]};
			end
		`BSR:
			begin
				isBSR <= `TRUE;
				wadr <= sp_dec[31:0];
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_dec;
				store_what <= `STW_PC;
				next_state(STORE1);	
			end
		`JSR:
			begin
				isJSR <= `TRUE;
				isJSP <= isJSP;
				wadr <= sp_dec[31:0];
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_dec;
				store_what <= `STW_PC;
				a <= {immbuf[31:0],ir[39:8]};
				next_state(STORE1);
			end
		`JGR:
			begin
				isJGR <= `TRUE;
				nJGR <= 3'b001;
				wadr <= sp_dec[31:0];
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_dec;
				store_what <= `STW_PC;
				a <= {ir[39:8],32'd0};
				next_state(STORE1);
			end
		`JSR_DRN:
			begin
				isJSRdrn <= `TRUE;
				wadr <= sp_dec[31:0];
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_dec;
				store_what <= `STW_PC;
				next_state(STORE1);
			end
		`RTS:
			begin
				isRTS <= `TRUE;
				radr <= sp_segd;
				next_state(LOAD1);
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_inc + ir[31:16];
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
					case(ir[25:24])
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
					case(ir[25:24])
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
					imm <= {{50{ir[39]}},ir[39:26]};
				end
				if (ir[23:16]==8'h00)
					Sa <= 4'd15;
			end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
		`SBX,`SCX,`SHX,`SWX:
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
					case(ir[25:24])
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
					case(ir[25:24])
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
					imm <= {{60{ir[39]}},ir[39:36]};
				end
				if (ir[31:24]==8'h00)
					Sa <= 4'd15;
			end
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// PUSH / POP
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`PUSH:
			begin
				isPUSH <= `TRUE;
				store_what <= `STW_A;
				ir[39:8] <= {8'h00,ir[39:16]};
				wadr <= {seg_lbound[4'd14][63:8],8'h00} + sp_dec[31:0];
				if (ir[39:8]==32'h0)
					next_state(PC_DELAY);
				else if (ir[15:8]==8'h00) begin
					pc <= pc;
					next_state(DECODE);
				end
				else begin
					pc <= pc;
					Rt <= 8'hFF;
					wrrf <= `TRUE;
					res <= sp_dec;
					next_state(STORE1);
				end
			end
		`POP:
			begin
				isPOP <= `TRUE;
				Rt <= ir[15:8];
				ir[39:8] <= {8'h00,ir[39:16]};
				radr <= sp_segd;
				if (ir[39:8]==32'h0)
					next_state(PC_DELAY);
				else if (ir[15:8]==8'h00) begin
					pc <= pc;
					next_state(DECODE);
				end
				else begin
					pc <= pc;
					sp <= sp_inc;
					next_state(LOAD1);
				end
			end
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Prefixes follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`JSP:
			begin
				isJSP <= `TRUE;
				immbuf <= ir[39:8];
				next_state(PC_DELAY);
			end
		`IMM1:
			begin
				isIMM1 <= `TRUE;
				immbuf <= {{32{ir[39]}},ir[39:8]};
				next_state(PC_DELAY);
			end
		`IMM2:
			begin
				isIMM2 <= `TRUE;
				immbuf[63:32] <= ir[39:8];
				next_state(PC_DELAY);
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
		next_state(PC_DELAY);
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
				default:	res <= 65'd0;
				endcase
			`MTSPR:
				case(ir[23:16])	// Don't use Rt!
				//`TICK:	tick <= a;
				`VBR:	vbr <= {a[31:13],13'd0};
				endcase
			`MTSEG:
				begin
					St <= ir[19:16];
					load_seg();
				end
			`MFSEG:
				begin
					res <= {seg_selector[Ra[3:0]][31:8],40'd0};
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
					if (a[63:61] < b[63:61])
						res <= {b[63:61],a[60:0]};
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
					radr <= mr_ea;
					next_state(LOAD1);
				end
			`SMR:
				begin
					isSMR <= `TRUE;
					wadr <= mr_ea;
					store_what <= `STW_A;
					next_state(STORE1);
				end
			`MSO:	res <= {seg_selector[Sa][31:8],a[39:0]};
			`SSO:	load_seg();
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
				next_state(PC_DELAY);
				if (take_branch) begin
					pc[15: 0] <= ir[31:16];
					pc[39:16] <= pc[39:16] + {{19{ir[36]}},ir[36:32]};
				end
			end
		`DBNZ:
			begin
				next_state(PC_DELAY);
				if (take_branch) begin
					pc[15: 0] <= ir[31:16];
					pc[39:16] <= pc[39:16] + {{19{ir[36]}},ir[36:32]};
				end
				res <= a - 64'd1;
			end
		// If the selector isn't changing then just continue to the next
		// instruction. Otherwise load the selector.
		`JMP:
			begin
				if (a[63:40]==cs_selector[31:8])
					next_state(PC_DELAY);
				else
					load_cs_seg();
			end
		`JMP_IX:
			begin
				isJMPix <= `TRUE;
				radr <= a + imm;
				next_state(LOAD1);
			end
		`JMP_DRN:	
			begin
				pc <= ea_drn;
				if (ea_drn[63:40]==cs_selector[31:8])
					next_state(PC_DELAY);
				else
					load_cs_seg();
			end
		`JSR_IX:
			begin
				radr <= ea_drn;
				wadr <= sp_dec[31:0];
				Rt <= 8'hFF;
				wrrf <= `TRUE;
				res <= sp_dec;
				isJSRix <= `TRUE;
				store_what <= `STW_PC;
				next_state(STORE1);
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
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SC:
			begin
				st_size <= char;
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SH:
			begin
				st_size <= half;
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SW:
			begin
				st_size <= word;
				store_what <= `STW_B;
				store_check(ea_drn);
			end
		`SGDT:
			begin
				isSGDT <= `TRUE;
				nDT <= 2'b01;
				store_what <= `STW_GDT;
				store_check(ea_drn);
			end
		`SIDT:
			begin
				isSIDT <= `TRUE;
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
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`SCX:
			begin
				st_size <= char;
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`SHX:
			begin
				st_size <= half;
				store_what <= `STW_C;
				store_check(ea_ndx);
			end
		`SWX:
			begin
				st_size <= word;
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
	begin
		wb_read(radr);
		next_state(LOAD2);
	end
LOAD2:
	begin
		if (ack_i) begin
			radr <= radr + 32'd4;
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
	begin
		wb_read(radr);
		next_state(LOAD4);
	end
LOAD4:
	begin
		if (ack_i) begin
			radr <= radr + 32'd4;
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
				cg_offset <= {dat32[7:0],res[31:0]};
				cg_dpl <= dat32[31:29];
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
					load_cs_seg();
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
					pc <= res[31:0];
					pc[39:32] <= dat32[7:0];
					a[63:32] <= dat32;
					load_cs_seg();
				end
			isRTS:
				begin
					pc <= res[31:0];// + ir[15:8];
					pc[39:32] <= dat32[7:0];
					a[63:32] <= dat32;
					load_cs_seg();
				end
			isBRK:
				begin
					if (cpl > res[31:29] && pe)
						privilege_violation();
					else begin
						if (dat32[28:24]==5'd6)	// interrupt gate sets interrupt mask
							im <= `TRUE;
						pc[39:0] <= res[27:0];
						a[63:32] <= {dat32[23:0],8'h00};
						load_cs_seg();
					end
				end
			isRTI:
				begin
					pc <= res[31:0];
					pc[39:32] <= dat32[7:0];
					Rt <= 8'hFF;
					wrrf <= `TRUE;
					res <= sp_inc;
					a[63:32] <= dat32;
					load_cs_seg();
				end
			isPOP:
				begin
					wrrf <= `TRUE;
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
						idt_lbound[31:8] <= res[31:8];
						idt_lbound[63:32] <= dat32;
						next_state(LOAD1);
					end
					else begin
						idt_ubound[31:8] <= res[31:8];
						idt_ubound[63:32] <= dat32;
						next_state(IFETCH);
					end
				end
			isLGDT:
				begin
					if (nDT==2'b01) begin
						nDT <= 2'b10;
						gdt_lbound[31:8] <= res[31:8];
						gdt_lbound[63:32] <= dat32;
						next_state(LOAD1);
					end
					else begin
						gdt_ubound[31:8] <= res[31:8];
						gdt_ubound[63:32] <= dat32;
						next_state(IFETCH);
					end
				end
			default:
				next_state(IFETCH);
			endcase
		end
		else if (err_i)
			bus_err();
	end

VERIFY_SEG_LOAD:
	begin
		// Is the segment resident in memory ?
		if (!desc_acr[7])
			segment_not_present();
		// are we trying to load a non-code segment into the code segment ?
		else if (St==4'd15 && desc_acr[4:3]!=2'b11 && pe)
			segtype_violation();
		// are we trying to load a code segment into a data segment ?
		else if (St!=4'd15 && desc_acr[4:3]==2'b11 && pe)
			segtype_violation();
		// The code privilege level must be the same or higher (numerically
		// lower) than the data descriptor privilege level.
//		// CPL <= DPL
		else if ((St!=4'd15||isCallGate) && cpl > desc_dpl && pe)	// data segment
			privilege_violation();
		else if (St==4'd15 && cpl < desc_dpl && !desc_acr[2] && !isCallGate && pe)
			privilege_violation();
//		else if (cpl >= seg_dpl[Rt[3:0]] && dat32[28:27]==2'b11)	// code segment
//			next_state(IFETCH);
		else
		begin
			if (isCallGate) begin
				cg_offset <= desc_w0[39:0];
				cg_selector <= desc_w1[23:0];
				cg_dpl <= desc_w0[63:61];
				cg_acr <= desc_w1[63:56];
				cg_ncopy <= desc_w1[28:24];
				cg_loaded <= `TRUE;
				isJGR <= `TRUE;
				a[63:40] <= desc_w1[23:0];
				if (!desc_acr[7])
					segment_not_present();
				else if ((cpl > rpl ? cpl : rpl) > desc_dpl && pe)
					privilege_violation();
				else
					load_cs_seg();
			end
			else begin
				seg_selector[St] <= a[63:32];
				seg_lbound[St] <= desc_lbound;
				seg_ubound[St] <= desc_ubound;
				if (St==4'd15 && desc_acr[2])	// conforming code segment inherits CPL
					seg_dpl[St] <= cpl;
				else
					seg_dpl[St] <= desc_dpl;
				seg_acr[St] <= desc_acr;
				if (isRTI) begin
					isRTI <= `FALSE;
					isPLP <= `TRUE;
					next_state(LOAD1);
				end
				else if (isJGR) begin
					Rt <= 8'hFB;	// 251
					wrrf <= `TRUE;
					res <= {cs_selector[31:8],pc[39:0]};
					pc[39:0] <= cg_offset;
					next_state(PC_DELAY);
				end
				else
					next_state(PC_DELAY);	// in case code segment loaded
			end
		end
	end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// STORE machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STORE1:
	begin
		case (store_what)
		`STW_A:		wb_write(st_size,wadr,a[31:0]);
		`STW_B:		wb_write(st_size,wadr,b[31:0]);
		`STW_C:		wb_write(st_size,wadr,c[31:0]);
		`STW_PC:	wb_write(word,wadr,pc[31:0]);
		`STW_SR:	wb_write(word,wadr,sr[31:0]);
		`STW_IDT:	if (nDT==2'b01)
						wb_write(word,wadr,{idt_lbound[31:8],8'h00});
					else
						wb_write(word,wadr,{idt_ubound[31:8],8'h00});
		`STW_GDT:	if (nDT==2'b01)
						wb_write(word,wadr,{gdt_lbound[31:8],8'h00});
					else
						wb_write(word,wadr,{gdt_ubound[31:8],8'h00});
		default:	next_state(RESET);	// hardware fault
		endcase
		next_state(STORE2);
	end
STORE2:
	if (ack_i) begin
		wb_nack();
		wadr <= wadr + 32'd4;
		if (st_size==word)
			next_state(STORE3);
		else
			next_state(IFETCH);
	end
	else if (err_i)
		bus_err();
STORE3:
	begin
		case (store_what)
		`STW_A:		wb_write(word,wadr,a[63:32]);
		`STW_B:		wb_write(word,wadr,b[63:32]);
		`STW_C:		wb_write(word,wadr,c[63:32]);
		`STW_PC:	wb_write(word,wadr,{cs_selector[31:8],pc[39:32]});
		`STW_SR:	wb_write(word,wadr,32'd0);
		`STW_IDT:	if (nDT==2'b01)
						wb_write(word,wadr,idt_lbound[63:32]);
					else	
						wb_write(word,wadr,idt_ubound[63:32]);
		`STW_GDT:	if (nDT==2'b01)
						wb_write(word,wadr,gdt_lbound[63:32]);
					else
						wb_write(word,wadr,gdt_ubound[63:32]);
		default:	next_state(RESET);	// hardware fault
		endcase
		next_state(STORE4);
		if (isSMR)
			ir[15:8] <= ir[15:8] + 8'd1;
	end
STORE4:
	if (ack_i) begin
		wb_nack();
		wadr <= wadr + 32'd4;
		if (isSMR) begin
			a <= rfoa;
			if (Ra>Rb || Ra==0)
				next_state(IFETCH);
			else
				next_state(STORE1);
		end
		else if (isBRK)
			begin
				if (store_what==`STW_PC) begin
					radr <= {idt_lbound[63:8],8'h00} + {ir[16:8],3'b000};
					next_state(LOAD1);
				end
				else begin
					store_what <= `STW_PC;
					wadr <= sp_dec;
					Rt <= 8'hFF;
					wrrf <= `TRUE;
					res <= sp_dec;
					next_state(STORE1);
				end
			end
		else if (isBSR)
			begin
				pc[15: 0] <= ir[31:16];
				pc[39:16] <= pc[39:16] + {{19{ir[36]}},ir[36:32]};
				next_state(PC_DELAY);
			end
		else if (isJSR)
			begin
				pc <= imm[31:0];
				pc[39:32] <= dat32[7:0];
				if (hasJSP) begin
					isJSP <= `FALSE;
					load_cs_seg();
				end
				else
					next_state(PC_DELAY);
			end
		else if (isJGR) begin
			if (a[60])
				radr <= ldt_adr;
			else
				radr <= gdt_adr;
			next_state(LOAD1);
		end
		else if (isJSRdrn)
			begin
				pc <= ea_drn[39:0];
				if (ea_drn[63:40]==cs_selector[31:8])
					next_state(PC_DELAY);
				else
					load_cs_seg();
			end
		else if (isJSRix)
			next_state(LOAD1);
		else if (isPUSH)
			next_state(DECODE);
		else if (isSIDT|isSGDT) begin
			if (nDT==2'b01) begin
				nDT <= 2'b10;
				next_state(STORE1);
			end
			else
				next_state(IFETCH);
		end
		else
			next_state(IFETCH);
	end
	else if (err_i)
		bus_err();

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Cache invalidate machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CINV1:
	begin
		adr_o <= {wadr[31:4],2'b11,2'b00};
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
	ir <= {9'd508,`BRK};
	hwi <= `TRUE;
	next_state(DECODE);
end
endtask

task bounds_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= 9'd500;
	next_state(DECODE);
end
endtask

task load_seg;
begin
	nMTSEG <= 2'b01;
	if (a[60]) begin
		radr <= ldt_adr;
		if (ldt_seg_ubound_violation && pe)
			bounds_violation();
		else
			next_state(LOAD1);
	end
	else begin
		radr <= gdt_adr;
		if (gdt_seg_ubound_violation && pe)
			bounds_violation();
		else
			next_state(LOAD1);
	end
end
endtask

task load_cs_seg;
begin
	St <= 4'd15;
	load_seg();
end
endtask

task segment_not_present;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= 9'd503;
	next_state(DECODE);
end
endtask

task privilege_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= 9'd501;
	next_state(DECODE);
end
endtask

task segtype_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[39:8] <= 9'd502;
	next_state(DECODE);
end
endtask

task load_check;
input [63:0] adr;
begin
	if (cpl <= dpl || !pe) begin
		radr <= adr;
		next_state(LOAD1);
	end
	else begin
		privilege_violation();
	end
end
endtask

task store_check;
input [63:0] adr;
begin
	if (cpl <= dpl || !pe) begin
		wadr <= adr;
		next_state(STORE1);
	end
	else begin
		privilege_violation();
	end
end
endtask

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET      ";
IFETCH:	fnStateName = "IFETCH     ";
PC_DELAY:	fnStateName = "PC_DELAY   ";
PC_DELAY2:	fnStateName = "PC_DELAY2  ";
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

always @(posedge rclk)
case(pc[3:0])
4'h0:	insn <= bundle[ 39: 0];
4'h5:	insn <= bundle[ 79:40];
4'hA:	insn <= bundle[119:80];
default:	insn <= {`ALN_VECT,8'h50};	// JMP Alignment fault
endcase

always @(posedge rclk)
case(pc[3:0])
4'h0:	debug_bits <= bundle[121:120];
4'h5:	debug_bits <= bundle[123:122];
4'hA:	debug_bits <= bundle[125:124];
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
output reg hit;

wire [31:0] tag;

syncram_512x32_1rw1r u1 (wclk, wr && wa[3:2]==2'b11, wa[12:4], {wa[31:13],12'd0,v}, rclk, pc[12:4], tag);

always @(posedge rclk)
	hit <= tag[31:13]==pc[31:13] && tag[0];

endmodule

