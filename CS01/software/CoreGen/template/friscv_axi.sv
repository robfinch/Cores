// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	friscv.sv
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

`define FADD		5'd0
`define FSUB		5'd1
`define FMUL		5'd2
`define FDIV		5'd3
`define FMIN		5'd5
`define FSQRT		5'd11
`define FSGNJ		5'd16
`define FCMP		5'd20
`define FCVT2I	5'd24
`define FCVT2F	5'd26
`define FCLASS	5'd28

`define LOAD	7'd3
`define LB			3'd0
`define LH			3'd1
`define LW			3'd2
`define LBU			3'd4
`define LHU			3'd5
`define LOADF	7'd7
`define FENCE	7'd15
`define AUIPC	7'd23
`define STORE	7'd35
`define SB			3'd0
`define SH			3'd1
`define SW			3'd2
`define STOREF	7'd39
`define AMO		7'd47
`define LUI		7'd55
`define FMA		7'd67
`define FMS		7'd71
`define FNMS	7'd75
`define FNMA	7'd79
`define FLOAT	7'd83
`define Bcc		7'd99
`define BEQ			3'd0
`define BNE			3'd1
`define BLT			3'd4
`define BGE			3'd5
`define BLTU		3'd6
`define BGEU		3'd7
`define JALR	7'd103
`define JAL		7'd111
`define ECALL	32'h00000073
`define ERET	32'h10000073
`define WFI		32'h10100073
`define PFI		32'h10300073
`define CS_ILLEGALINST	2

`include "fp/fpConfig.sv"

module friscv_axi(rst_i, hartid_i, clk_i, wc_clk_i, irq_i,
	ACLK, ARESETN,
	AWID, AWADDR, AWLEN,AWSIZE,AWBURST,AWLOCK,AWPROT,AWQOS,AWREGION,AWVALID,AWREADY,
	WVALID,WREADY,WSTRB,WLAST,WDATA,BID,BRESP,BVALID,BREADY,
	ARID, ARADDR, ARLEN,ARSIZE,ARBURST,ARLOCK,ARPROT,ARQOS,ARREGION,ARVALID,ARREADY,
	RID,RRESP,RDATA,RLAST,RVALID,RREADY
);
{+RV32I}
parameter WID = 32;
{-RV32I}
{+RV64I}
parameter WID = 64;
{-RV64I}
parameter FPWID = 32;
input rst_i;
input [31:0] hartid_i;
input clk_i;
input wc_clk_i;
input [3:0] irq_i;

// System
input ACLK;
input ARESETN;
// Write address channel
output reg [3:0] AWID;			// transaction ID (we choose at least 4 bits)
output reg [31:0] AWADDR;
output reg [7:0] AWLEN;			// Burst length -1
output reg [2:0] AWSIZE;		// 010 = 4 bytes
output reg [1:0] AWBURST;		// 0 = FIXED, 1 = INCR, 2 = WRAP, 3 = reserved
output reg AWLOCK;
output reg [3:0] AWCACHE;		// 0011 = Normal, non-cachable, modifiable, bufferable
output reg [2:0] AWPROT;		// 000
output reg [3:0] AWQOS;			// transaction priority
output reg [3:0] AWREGION;	// logical region
output reg AWVALID;
input AWREADY;
// Write data channel
output reg WVALID;
input WREADY;
output reg [3:0] WSTRB;
output reg WLAST;						// indicates last burst cycle
output reg [31:0] WDATA;
// Write response
input [3:0] BID;
input [1:0] BRESP;					// 00 = OKAY, 01 = EXOKAY, 10=SLVERR, 11= DECERR
input BVALID;
output reg BREADY;
// Read address channel
output reg [3:0] ARID;
output reg [31:0] ARADDR;
output reg [7:0] ARLEN;
output reg [2:0] ARSIZE;
output reg [1:0] ARBURST;
output reg ARLOCK;
output reg [3:0] ARCACHE;
output reg [2:0] ARPROT;
output reg [3:0] ARQOS;
output reg [3:0] ARREGION;
output reg ARVALID;
input ARREADY;
// Read data channel
input [3:0] RID;
input [1:0] RRESP;
input [31:0] RDATA;
input RLAST;
input RVALID;
output reg RREADY;

parameter HIGH = 1'b1;
parameter LOW = 1'b0;
`include "fp/fpSize.sv"

wire clk_g;					// gated clock
reg [3:0] wtid, rtid;

// Nonm visible registers
reg MachineMode;
reg [31:0] ir;			// instruction register
reg [31:0] upc;			// user mode pc
reg [31:0] spc;			// system mode pc
reg [3:0] pim;			// previous interrupt mask
reg [4:0] Rd, Rs1, Rs2, Rs3;
reg [WID-1:0] ia, ib, ic;
reg [WID-1:0] uia, uib, uic;
reg [WID-1:0] sia, sib, sic;
reg [FPWID-1:0] fa, fb, fc;
reg [WID-1:0] imm, res;
reg [WID-1:0] displacement;				// branch displacement
reg [1:0] luix0;
// Decoding
wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [4:0] funct5 = ir[31:27];
wire [6:0] funct7 = ir[31:25];
wire [2:0] rm3 = ir[14:12];

reg [WID-1:0] iregfile [0:31];		// integer / system register file
reg [WID-1:0] sregfile [0:31];
{+F}
reg [FPWID-1:0] fregfile [0:31];		// floating-point register file
{-F}
reg [31:0] pc;			// generic program counter
reg [31:0] ipc;			// pc value at instruction
reg [3:0] im;				// interrupt mask
reg [2:0] rm;
reg wrirf, wrfrf;
wire [WID-1:0] irfoa = iregfile[Rs1];
wire [WID-1:0] irfob = iregfile[Rs2];
wire [WID-1:0] irfoc = iregfile[Rs3];
wire [WID-1:0] srfoa = sregfile[Rs1];
wire [WID-1:0] srfob = sregfile[Rs2];
wire [WID-1:0] srfoc = sregfile[Rs3];
{+F}
wire [FPWID-1:0] frfoa = fregfile[Rs1];
wire [FPWID-1:0] frfob = fregfile[Rs2];
wire [FPWID-1:0] frfoc = fregfile[Rs3];
{-F}
always @(posedge clk_i)
if (wrirf && state==WRITEBACK && !MachineMode)
	iregfile[Rd] <= res[WID-1:0];
always @(posedge clk_i)
if (wrirf && state==WRITEBACK &&  MachineMode)
	sregfile[Rd] <= res[WID-1:0];
{+F}
always @(posedge clk_i)
if (wrfrf && state==WRITEBACK)
	fregfile[Rd] <= res;
{-F}
reg illegal_insn;

// CSRs
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi;
reg [31:0] mtimecmp;
reg [63:0] instret;	// instructions completed.
reg [31:0] mcause;
reg [31:0] mstatus;
reg [31:0] mtvec;
reg [31:0] mscratch;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};

function [4:0] fnSelect;
input [6:0] op6;
input [2:0] fn3;
case(op6)
`LOAD:
	case(fn3)
	`LB,`LBU:	fnSelect = 5'h1;
	`LH,`LHU:	fnSelect = 5'h3;
	default:	fnSelect = 5'hF;	
	endcase
{+F}
`LOADF:
	case(FPWID)
	16:	fnSelect = 5'h03;
	24:	fnSelect = 5'h07;
	32:	fnSelect = 5'h0F;
	40:	fnSelect = 5'h1F;
	default:	fnSelect = 5'h0F;
	endcase
{-F}
`STORE:
	case(fn3)
	`SB:	fnSelect = 5'h1;
	`SH:	fnSelect = 5'h3;
	default:	fnSelect = 5'hF;
	endcase
{+F}
`STOREF:
	case(FPWID)
	16:	fnSelect = 5'h03;
	24:	fnSelect = 5'h07;
	32:	fnSelect = 5'h0F;
	40:	fnSelect = 5'h1F;
	default:	fnSelect = 5'h0F;
	endcase
{-F}
{+A}
`AMO:	fnSelect = 5'hF;
{-A}
default:	fnSelect = 5'h0;
endcase
endfunction

wire [31:0] ea = ia + imm;
reg [63:0] dati;
wire [31:0] datiL = RDATA >> {ea[1:0],3'b0};
{+F}
wire [63:0] sdat = (opcode==`STOREF ? fb : ib) << {ea[1:0],3'b0};
{-F}
{!F}
reg [63:0] sdat;
always @*
	case(opcode)
{+A}
	`AMO:
		case(funct5)
		5'd1:	sdat <= ib << {ea[1:0],3'b0};	// AMOSWAP
		5'd3:	sdat <= ib << {ea[1:0],3'b0};	// SC.W
		5'd0:	sdat <= (ib + dati) << {ea[1:0],3'b0};	// AMOADD
		5'd4:	sdat <= (ib ^ dati) << {ea[1:0],3'b0};	// AMOXOR
		5'd8:	sdat <= (ib | dati) << {ea[1:0],3'b0};	// AMOOR
		5'd12:	sdat <= (ib & dati) << {ea[1:0],3'b0};	// AMOAND
		5'd16:	sdat <= ($signed(ib) < $signed(dati) ? ib : dati) << {ea[1:0],3'b0};	// AMOMIN
		5'd20:	sdat <= ($signed(ib) > $signed(dati) ? ib : dati) << {ea[1:0],3'b0};	// AMOMAX
		5'd24:	sdat <= (ib < dati ? ib : dati) << {ea[1:0],3'b0};	// AMOMINU
		5'd28:	sdat <= (ib > dati ? ib : dati) << {ea[1:0],3'b0};	// AMOMAXU
		default:	sdat <= 1'd0;
		endcase
{-A}
	default:
		sdat <= ib << {ea[1:0],3'b0};
	endcase
{-F}
wire [7:0] ssel = fnSelect(opcode,funct3) << ea[1:0];

reg [4:0] state;
parameter IFETCH = 5'd1;
parameter IFETCH2 = 5'd2;
parameter DECODE = 5'd3;
parameter RFETCH = 5'd4;
parameter EXECUTE = 5'd5;
parameter MEMORY_READ = 5'd6;
parameter MEMORY_READ2 = 5'd7;
parameter MEMORY_READ3 = 5'd8;
parameter MEMORY_READ4 = 5'd9;
parameter FLOAT = 5'd10;
parameter WRITEBACK = 5'd11;
parameter MEMORY_WRITE = 5'd12;
parameter MEMORY_WRITE2 = 5'd13;
parameter MEMORY_WRITE3 = 5'd14;
parameter MEMORY_WRITE4 = 5'd15;
parameter MUL1 = 5'd16;
parameter MUL2 = 5'd17;

{+M}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide support logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg sgn;
wire [WID*2-1:0] prod = ia * ib;
wire [WID*2-1:0] nprod = -prod;
wire [WID*2-1:0] div_q;
wire [WID*2-1:0] ndiv_q = -div_q;
wire [WID-1:0] div_r;
wire [WID-1:0] ndiv_r = -div_r;
fpdivr16 u16
(
	.clk(clk),
	.ld(ld),
	.a(ia),
	.b(ib),
	.q(div_q),
	.r(div_r),
	.done(),
	.lzcnt()
);
{-M}
{+F}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [7:0] mathCnt;
reg [FPWID-1:0] fcmp_res, ftoi_res, itof_res, fres;
wire [2:0] rmq = rm3==3'b111 ? rm : rm3;

wire [4:0] fcmp_o;
wire [EX:0] fas_o, fmul_o, fdiv_o, fsqrt_o;
{+FMA}
wire [EX:0] fma_o;
wire fma_uf;
{-FMA}
wire mul_of, div_of;
wire mul_uf, div_uf;
wire norm_nx;
wire sqrt_done;
wire cmpnan, cmpsnan;
reg [EX:0] fnorm_i;
wire [MSB+3:0] fnorm_o;
wire ld = state==EXECUTE;
reg ld1;
wire srqneg, sqrinf;
wire fa_inf, fa_xz, fa_vz;
wire fa_qnan, fa_snan, fa_nan;
wire fb_qnan, fb_snan, fb_nan;
always @(posedge clk_g)
	ld1 <= ld;
fpDecomp #(FPWID) u12 (.i(fa), .sgn(), .exp(), .man(), .fract(), .xz(fa_xz), .mz(), .vz(fa_vz), .inf(fa_inf), .xinf(), .qnan(fa_qnan), .snan(fa_snan), .nan(fa_nan));
fpDecomp #(FPWID) u13 (.i(fb), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(fb_qnan), .snan(fb_snan), .nan(fb_nan));
fpCompare #(.FPWID(FPWID)) u1 (.a(fa), .b(fb), .o(fcmp_o), .nan(cmpnan), .snan(cmpsnan));
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f #(.FPWID(FPWID)) u2 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(ia), .o(itof_res));
f2i #(.FPWID(FPWID)) u3 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .i(fa), .o(ftoi_res), .overflow());
{+FADD}
fpAddsub #(.FPWID(FPWID)) u4 (.clk(clk_g), .ce(1'b1), .rm(rmq), .op(funct5==`FSUB), .a(fa), .b(fb), .o(fas_o));
{-FADD}
{+FMUL}
fpMul #(.FPWID(FPWID)) u5 (.clk(clk_g), .ce(1'b1), .a(fa), .b(fb), .o(fmul_o), .sign_exe(), .inf(), .overflow(nmul_of), .underflow(mul_uf));
{-FMUL}
{+FDIV}
fpDiv #(.FPWID(FPWID)) u6 (.rst(rst_i), .clk(clk_g), .clk4x(1'b0), .ce(1'b1), .ld(ld), .op(1'b0),
	.a(fa), .b(fb), .o(fdiv_o), .done(), .sign_exe(), .overflow(div_of), .underflow(div_uf));
{-FDIV}
{+FSQRT}
fpSqrt #(.FPWID(FPWID)) u7 (.rst(rst_i), .clk(clk_g), .ce(1'b1), .ld(ld),
	.a(fa), .o(fsqrt_o), .done(sqrt_done), .sqrinf(sqrinf), .sqrneg(sqrneg));
{-FSQRT}
{+FMA}
fpFMA #(.FPWID(FPWID)) u14
(
	.clk(clk),
	.ce(1'b1),
	.op(opcode==FMS||opcode==FNMS),
	.rm(rmq),
	.a(opcode==`FNMA||opcode==`FNMS ? {~fa[FPWID-1],fa[FPWID-2:0]} : fa),
	.b(fb),
	.c(fc),
	.o(fma_o),
	.under(fma_uf),
	.over(),
	.inf(),
	.zero()
);
{-FMA}

always @(posedge clk_g)
case(opcode)
{+FMA}
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_i <= fma_o;
{-FMA}
`FLOAT:
	case(funct5)
{+FADD}
	`FADD:	fnorm_i <= fas_o;
	`FSUB:	fnorm_i <= fas_o;
{-FADD}
{+FMUL}
	`FMUL:	fnorm_i <= fmul_o;
{-FMUL}
{+FDIV}
	`FDIV:	fnorm_i <= fdiv_o;
{-FDIV}
{+FSQRT}
	`FSQRT:	fnorm_i <= fsqrt_o;
{-FSQRT}
	default:	fnorm_i <= 1'd0;
	endcase
default:	fnorm_i <= 1'd0;
endcase
reg fnorm_uf;
wire norm_uf;
always @(posedge clk_g)
case(opcode)
{+FMA}
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_uf <= fma_uf;
{-FMA}
`FLOAT:
	case(funct5)
{+FMUL}
	`FMUL:	fnorm_uf <= mul_uf;
{-FMUL}
{+FDIV}
	`FDIV:	fnorm_uf <= div_uf;
{-FDIV}
	default:	fnorm_uf <= 1'b0;
	endcase
default:	fnorm_uf <= 1'b0;
endcase
fpNormalize #(.FPWID(FPWID)) u8 (.clk(clk_g), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(fnorm_uf), .under_o(norm_uf), .inexact_o(norm_nx));
fpRound #(.FPWID(FPWID)) u9 (.clk(clk_g), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));
wire finf, fdn;
fpDecompReg #(FPWID) u10 (.clk(clk_g), .ce(1'b1), .i(fres), .sgn(), .exp(), .fract(), .xz(fdn), .vz(), .inf(finf), .nan() );
{-F}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Timers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_g)
if (rst_i)
	tick <= 64'd0;
else
	tick <= tick + 2'd1;

reg [5:0] ld_time;
reg [63:0] wc_time_dat;
reg [63:0] wc_times;
assign clr_wc_time_irq = wc_time_irq_clr[5];
always @(posedge wc_clk_i)
if (rst_i) begin
	wc_time <= 1'd0;
	wc_time_irq <= 1'b0;
end
else begin
	if (|ld_time)
		wc_time <= wc_time_dat;
	else
		wc_time <= wc_time + 2'd1;
	if (mtimecmp==wc_time[31:0])
		wc_time_irq <= 1'b1;
	if (clr_wc_time_irq)
		wc_time_irq <= 1'b0;
end

always @(posedge wc_clk_i)
if (rst_i)
	wfi <= 1'b0;
else begin
	if (set_wfi)
		wfi <= 1'b1;
	if (irq_i)
		wfi <= 1'b0;
end

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

always @(posedge clk_g)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Reset
// The program counters are set at their reset values.
// System mode is activated and interrupts are masked.
// All other state is undefined.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (rst_i) begin
	state <= IFETCH;
	spc <= 32'hFFFC0000;
	upc <= 32'hFFFC0100;
	pc <= 32'hFFFC0000;
	mtvec <= 32'hFFFC0200;
	MachineMode <= 1'b1;
	im <= 4'd15;
	pim <= 4'd15;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
	cyc_o <= LOW;
	stb_o <= LOW;
	we_o <= LOW;
	adr_o <= 32'h0;
	dat_o <= 32'h0;
	luix0 <= 2'b0;
	instret <= 64'd0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	mstatus <= 6'b110110;
	// Read address channel
	ARCACHE <= 4'b0011;
	ARPROT <= 3'b000;
	ARLEN <= 8'h00;
	ARSIZE <= 3'b010;
	ARBURST <= 2'b01;
	ARLOCK <= 1'b0;
	ARQOS <= 4'h0;
	ARREGION <= 4'h0;
	// Read data channel
	RREADY <= 1'b0;
	// Write address channel
	AWCACHE <= 4'b0011;
	AWPROT <= 3'b000;
	AWLEN <= 8'd00;
	AWSIZE <= 3'b010;
	AWBURST <= 2'b01;
	AWLOCK <= 1'b0;
	AWQOS <= 4'h0;
	AWREGION <= 4'h0;
	// Write data channel
	WREADY <= 1'b0;
	WLAST <= 1'b1;
end
else begin
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
wc_time_irq_clr <= {wc_time_irq_clr,wc_time_irq};

case (state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch
// Get the instruction from the rom.
// Increment the program counter.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
IFETCH:
	begin
		illegal_insn <= 1'b1;
		luix0 <= {luix0[0],1'b0};
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
		vpa_o <= HIGH;
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'hF;
		adr_o <= pc;
		state <= IFETCH2;
 		if (irq_i > im) begin
			cyc_o <= LOW;
			mcause[31] <= 1'b1;
			mcause[3:0] <= irq_i;
			MachineMode <= 1'b1;
			pc <= spc;
			pim <= im;
			im <= 4'd15;
			mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
			state <= IFETCH;
		end
		else
			pc <= pc + 3'd4;
	end
IFETCH2:
	if (ack_i) begin
		vpa_o <= LOW;
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		adr_o <= pc;
		ir <= dat_i[31:0];
		state <= DECODE;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode Stage
// Decode the register fields, immediate values, and branch displacement.
// Determine if instruction will update register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DECODE:
	begin
		state <= RFETCH;
		if (ir==`PFI && irq_i != 4'h0) begin
			mcause[31] <= 1'b1;
			mcause[3:0] <= irq_i;
			MachineMode <= 1'b1;
			pc <= spc;
			state <= IFETCH;
		end
		// Set some sensible decode defaults
		Rs1 <= ir[19:15];
		Rs2 <= ir[24:20];
		Rs3 <= ir[31:27];
		Rd <= 5'd0;
		displacement <= 32'd0;
		// Override defaults
		case(opcode)
		`AUIPC,`LUI:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				imm <= {ir[31:12],12'd0};
				if (ir[11:7]==5'd0)
					luix0 <= 2'b11;
				wrirf <= 1'b1;
			end
		`JAL:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				imm <= {{11{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
				wrirf <= 1'b1;
			end
		`JALR:
			begin
				illegal_insn <= 1'b0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`LOAD:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
{+F}
		`LOADF:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
				wrfrf <= 1'b1;
			end
		`STOREF:
			begin
				if (luix0[1])
					imm[11:0] <= {ir[31:25],ir[11:7]};
				else
					imm <= {{20{ir[31]}},ir[31:25],ir[11:7]};
			end
{-F}
		`STORE:
			begin
				if (luix0[1])
					imm[11:0] <= {ir[31:25],ir[11:7]};
				else
					imm <= {{20{ir[31]}},ir[31:25],ir[11:7]};
			end
{+A}
		`AMO:
			begin
				Rd <= ir[11:7];
				imm <= 1'd0;
			end
{-A}
		7'd19:
			begin
				if (luix0[1])
					case(funct3)
					3'd0:	imm[11:0] <= ir[31:20];
					3'd1: imm <= imm[24:20];
					3'd2:	imm[11:0] <= ir[31:20];
					3'd3: imm[11:0] <= ir[31:20];
					3'd4: imm[11:0] <= ir[31:20];
					3'd5: imm <= imm[24:20];
					3'd6: imm[11:0] <= ir[31:20];
					3'd7: imm[11:0] <= ir[31:20];
					endcase
				else
					case(funct3)
					3'd0:	imm <= {{20{ir[31]}},ir[31:20]};
					3'd1: imm <= imm[24:20];
					3'd2:	imm <= {{20{ir[31]}},ir[31:20]};
					3'd3: imm <= {{20{ir[31]}},ir[31:20]};
					3'd4: imm <= {{20{ir[31]}},ir[31:20]};
					3'd5: imm <= imm[24:20];
					3'd6: imm <= {{20{ir[31]}},ir[31:20]};
					3'd7: imm <= {{20{ir[31]}},ir[31:20]};
					endcase
				Rd <= ir[11:7];
				wrirf <= 1'b1;
			end
		7'd51,7'd115:
			begin
				Rd <= ir[11:7];
				wrirf <= 1'b1;
			end
{+F}
{+FMA}
		`FMA,`FMS,`FNMA,`FNMS:
			begin
				Rd <= ir[11:7];
				wrfrf <= 1'b1;
			end
{-FMA}
		`FLOAT:
			begin
				Rd <= ir[11:7];
				if (funct5==5'd20 || funct5==5'd24 || funct5==5'd28)
					wrirf <= 1'b1;
				else
					wrfrf <= 1'b1;
			end
{-F}
		`Bcc:
			displacement <= {{WID-13{ir[31]}},ir[31],ir[7],ir[30:25],ir[11:8],1'b0};
		endcase
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register fetch stage
// Fetch values from register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
RFETCH:
	begin
		state <= EXECUTE;
		sia <= Rs1==5'd0 ? {WID{1'd0}} : srfoa;
		sib <= Rs2==5'd0 ? {WID{1'd0}} : srfob;
		uia <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
		uib <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
		if (MachineMode) begin
			ia <= Rs1==5'd0 ? {WID{1'd0}} : srfoa;
			ib <= Rs2==5'd0 ? {WID{1'd0}} : srfob;
		end
		else begin
			ia <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
			ib <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
		end
{+F}
		fa <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
		case(opcode)
		`FLOAT:
			case(funct5)
			`FCVT2F:
				fa <= Rs1==5'd0 ? {FPWID{1'd0}} : irfoa;
			default:	fa <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
			endcase
		default:	;
		endcase
		fb <= Rs2==5'd0 ? {FPWID{1'd0}} : frfob;
{+FMA}
		fc <= Rs3==5'd0 ? {FPWID{1'd0}} : frfoc;
{-FMA}
{-F}
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// Execute the instruction.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXECUTE:
	begin
		state <= WRITEBACK;
		case(opcode)
		`LUI:	begin res <= imm; end
		`AUIPC:	begin res <= {ipc[31:12],12'd0} + imm; end
		7'd51:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:		begin res = ia + ib; illegal_insn <= 1'b0; end
{+M}
{+MUL}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
{-MUL}
{-M}
				7'd32:	begin res = ia - ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd1:
				case(funct7)
				7'd0:	begin res <= ia << ib[4:0]; illegal_insn <= 1'b0; end
{+M}
{+MULH}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
{-MULH}
{-M}
				default:	;
				endcase
			3'd2:
				case(funct7)
				7'd0:	begin res <= $signed(ia) < $signed(ib); illegal_insn <= 1'b0; end
{+M}
{+MULHSU}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
{-MULHSU}
{-M}
				default:	;
				endcase
			3'd3:
				case(funct7)
				7'd0:	begin res <= ia < ib; illegal_insn <= 1'b0; end
{+M}
{+MULHU}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
{-MULHU}
{-M}
				default:	;
				endcase
			3'd4:
				case(funct7)
				7'd0:	begin res <= ia ^ ib; illegal_insn <= 1'b0; end
{+M}
{+DIV}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
{-DIV}
{-M}
				default:	;
				endcase
			3'd5:
				case(funct7)
				7'd0:	begin res <= ia >> ib[4:0]; illegal_insn <= 1'b0; end
{+M}
{+DIVU}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
{-DIVU}
{-M}
				7'd32:	
					begin
						if (ia[WID-1])
							res <= (ia >> ib[4:0]) | ~({WID{1'b1}} >> ib[4:0]);
						else
							res <= ia >> ib[4:0];
 						illegal_insn <= 1'b0;
 					end
				default:	;
				endcase
			3'd6:
				case(funct7)
				7'd0:	begin res <= ia | ib; illegal_insn <= 1'b0; end
{+M}
{+REM}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
{-REM}
{-M}
				default:	;
				endcase
			3'd7:
				case(funct7)
				7'd0:	begin res <= ia & ib; illegal_insn <= 1'b0; end
{+M}
{+REMU}
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
{-REMU}
{-M}
				default:	;
				endcase
			endcase	
		7'd19:
			case(funct3)
			3'd0:	begin res <= ia + imm; illegal_insn <= 1'b0; end
			3'd1:
				case(funct7)
				7'd0:	begin res <= ia << imm[4:0]; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd2:	begin res <= $signed(ia) < $signed(imm); illegal_insn <= 1'b0; end
			3'd3:	begin res <= ia < imm; illegal_insn <= 1'b0; end
			3'd4:	begin res <= ia ^ imm; illegal_insn <= 1'b0; end
			3'd5:
				case(funct7)
				7'd0:	begin res <= ia >> imm[4:0]; illegal_insn <= 1'b0; end
				7'd16:
					begin
						if (ia[WID-1])
							res <= (ia >> imm[4:0]) | ~({WID{1'b1}} >> imm[4:0]);
						else
							res <= ia >> imm[4:0];
						illegal_insn <= 1'b0;
					end
				endcase
			3'd6:	begin res <= ia | imm; illegal_insn <= 1'b0; end
			3'd7:	begin res <= ia & imm; illegal_insn <= 1'b0; end
			endcase
{+F}
{+FMA}
		`FMA,`FMS,`FNMA,`FNMS:
			begin mathCnt <= 45; state <= FLOAT; illegal_insn <= 1'b0; end
{-FMA}
		// The timeouts for the float operations are set conservatively. They may
		// be adjusted to lower values closer to actual time required.
		`FLOAT:	// Float
			case(funct5)
{+FADD}				
			`FADD:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FADD
			`FSUB:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FSUB
{-FADD}
{+FMUL}			
			`FMUL:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FMUL
{-FMUL}
{+FDIV}
			`FDIV:	begin mathCnt <= 8'd40; state <= FLOAT; illegal_insn <= 1'b0; end	// FDIV
{-FDIV}
			`FMIN:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FMIN / FMAX
{+FSQRT}
			`FSQRT:	begin mathCnt <= 8'd160; state <= FLOAT; illegal_insn <= 1'b0; end	// FSQRT
{-FSQRT}
			`FSGNJ:	
				case(funct3)
{+FSGNJ}					
				3'd0:	begin res <= {fb[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end		// FSGNJ
{-FSGNJ}
{+FSGNJN}
				3'd1:	begin res <= {~fb[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end	// FSGNJN
{-FSGNJN}
{+FSGNJX}
				3'd2:	begin res <= {fb[FPWID-1]^fa[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end	// FSGNJX
{-FSGNJX}
				default:	;
				endcase
			5'd20:
				case(funct3)
{+FLE}					
				3'd0:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLE
{-FLE}				
{+FLT}
				3'd1:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLT
{-FLT}
{+FEQ}				
				3'd2:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FEQ
{-FEQ}
				default:	;
				endcase
			5'd24:	begin mathCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.T.FT
			5'd26:	begin mathCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.FT.T
			5'd28:
				begin
					case(funct3)
					3'd0:	begin res <= fa; illegal_insn <= 1'b0; end	// FMV.X.S
{+FCLASS}					
					3'd1:
						begin
							res[0] <= fa[FPWID-1] & fa_inf;
							res[1] <= fa[FPWID-1] & !fa_xz;
							res[2] <= fa[FPWID-1] &  fa_xz;
							res[3] <= fa[FPWID-1] &  fa_vz;
							res[4] <= ~fa[FPWID-1] &  fa_vz;
							res[5] <= ~fa[FPWID-1] &  fa_xz;
							res[6] <= ~fa[FPWID-1] & !fa_xz;
							res[7] <= ~fa[FPWID-1] & fa_inf;
							res[8] <= fa_snan;
							res[9] <= fa_qnan;
							illegal_insn <= 1'b0;
						end
{-FCLASS}
					endcase
				end
			5'd30:
				case(funct3)
				3'd0:	begin res <= ia; illegal_insn <= 1'b0; end	// FMV.S.X
				default:	;
				endcase
			default:	;
			endcase
{-F}
		`JAL:
			begin
				res <= pc;
				pc <= ipc + imm;
				illegal_insn <= 1'b0;
			end
		`JALR:
			begin
				res <= pc;
				pc <= ia + imm;
				pc[0] <= 1'b0;
				illegal_insn <= 1'b0;
			end
		`Bcc:
			case(funct3)
			3'd0:	begin if (ia==ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd1: begin if (ia!=ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd4:	begin if ($signed(ia) < $signed(ib)) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd5:	begin if ($signed(ia) >= $signed(ib)) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd6:	begin if (ia < ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd7:	begin if (ia >= ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			default:	;
			endcase
		`LOAD:
			begin
				ARID <= 4'h1;
				ARADDR <= ea;
				ARVALID <= 1'b1;
				state <= MEMORY_READ;
			end
		`STORE:
			begin
				AWID <= 4'h1;
				AWADDR <= ea;
				AWVALID <= 1'b1;
				WVALID <= 1'b1;
				WSTRB <= ssel[3:0];
				WDATA <= sdat[31:0];
				case(funct3)
				3'd0,3'd1,3'd2:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY_WRITE;
			end
{+F}
		`LOADF:
			begin
				ARID <= 4'h1;
				ARADDR <= ea;
				ARVALID <= 1'b1;
				state <= MEMORY_READ;
			end
		`STOREF:
			begin
				AWID <= 4'h1;
				AWADDR <= ea;
				AWVALID <= 1'b1;
				WVALID <= 1'b1;
				WSTRB <= ssel[3:0];
				WDATA <= sdat[31:0];
				case(funct3)
				3'd2:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY_WRITE;
			end
{-F}
{+A}
		`AMO:
			begin
				if (funct5==4'd3)	begin // SC
					AWID <= 4'h1;
					AWADDR <= ea;
					AWVALID <= 1'b1;
					WVALID <= 1'b1;
					WSTRB <= ssel[3:0];
					WDATA <= sdat[31:0];
					state <= MEMORY_WRITE;
				end
				else begin
					ARID <= 4'h1;
					ARADDR <= ea;
					ARVALID <= 1'b1;
					state <= MEMORY_READ;
				end
				case(funct3)
				3'd2:	illegal_insn <= 1'b0;
				default:	;
				endcase
			end
{-A}
		7'd115:
			begin
				case(ir)
				`ECALL:
					begin
						MachineMode <= 1'b1;
						pc <= spc;
						illegal_insn <= 1'b0;
					end
				`ERET:
					begin
						MachineMode <= 1'b0;
						pc <= upc;
						im <= pim;
						mstatus[5:0] <= {2'b11,1'b0,mstatus[5:3]};
						illegal_insn <= 1'b0;
					end
				`WFI:
					set_wfi <= 1'b1;
				default:
					begin
					case(funct3)
					3'd1,3'd2,3'd3,3'd5,3'd6,3'd7:
						case({funct7,Rs2})
						12'h001:	begin res <= fscsr[4:0]; illegal_insn <= 1'b0; end
						12'h002:	begin res <= rm; illegal_insn <= 1'b0; end
						12'h003:	begin res <= fscsr; illegal_insn <= 1'b0; end
						12'h301:	begin res <= mtvec; illegal_insn <= 1'b0; end
						12'h321:	begin res <= mtimecmp; wc_time_irq_clr <= 6'h3F; illegal_insn <= 1'b0; end
						12'h340:	begin res <= mscratch; illegal_insn <= 1'b0; end
						12'h341:	begin res <= upc; illegal_insn <= 1'b0; end
						12'hC00:	begin res <= tick[31: 0]; illegal_insn <= 1'b0; end
						12'hC80:	begin res <= tick[63:32]; illegal_insn <= 1'b0; end
						12'hC01,12'h701:	begin res <= wc_times[31: 0]; illegal_insn <= 1'b0; end
						12'hC81,12'h741:	begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
						12'hC02:	begin res <= instret[31: 0]; illegal_insn <= 1'b0; end
						12'hC82:	begin res <= instret[63:32]; illegal_insn <= 1'b0; end
						12'hF00:	begin res <= 32'h0; illegal_insn <= 1'b0; end	// cpu description
						12'hF01:	begin res <= 32'h8000; illegal_insn <= 1'b0; end // implmentation id
						12'hF10:	begin res <= hartid_i; illegal_insn <= 1'b0; end
						default:	;
						endcase
					default:	;
					endcase
					case(funct3)
					3'd5,3'd6,3'd7:	ia <= {27'd0,Rs1};
					default:	;
					endcase
					end
				endcase
			end
		default:	;
		endcase
	end

{+M}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Adjust for sign
MUL1:
	begin
		case(funct3)
		3'd0,3'd1,3'd4,3'd6:							// MUL / MULH / DIV / REM
			begin
				sgn <= ia[WID-1] ^ ib[WID-1];	// compute output sign
				if (ia[WID-1]) ia <= -ia;			// Make both values positive
				if (ib[WID-1]) ib <= -ib;
				state <= MUL2;
			end
		3'd2:										// MULHSU
			begin
				sgn <= ia[WID-1];
				if (ia[WID-1]) ia <= -ia;
				state <= MUL2;
			end
		3'd3,3'd5,3'd7:	state <= MUL2;		// MULHU / DIVU / REMU
		end
		endcase
	end
// Capture result
MUL2:
	begin
		mathCnt <= mathCnt - 8'd1;
		if (mathCnt==8'd0) begin
			state <= WRITEBACK;
			case(funct3)
{+MUL}
			3'd0:	res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
{-MUL}
{+MULH}
			3'd1:	res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
{-MULH}
{+MULHSU}
			3'd2:	res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
{-MULHSU}
{+MULHU}
			3'd3:	res <= prod[WID*2-1:WID];
{-MULHU}
{+DIV}
			3'd4:	res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
{-DIV}
{+DIVU}
			3'd5: res <= div_q[WID*2-1:WID];
{-DIVU}
{+REM}
			3'd6:	res <= sgn ? ndiv_r : div_r;
{-REM}
{+REMU}
			3'd7:	res <= div_r;
{-REMU}
			endcase
		end
	end
{-M}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MEMORY_READ:
	if (ARREADY) begin
		state <= MEMORY_READ2;
	end
MEMORY_READ2:
	begin
		// Master can assert RREADY before RVALID
		RREADY <= 1'b1;
		if (RVALID && RID==4'h1) begin
			if (ssel[7:4]==4'h0) begin
				case(funct3)
				3'd0:	begin res <= {{24{datiL[7]}},datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd1: begin res <= {{16{datiL[15]}},datiL[15:0]}; illegal_insn <= 1'b0; end
				3'd2:	begin res <= RDATA; illegal_insn <= 1'b0; end
				3'd4:	begin res <= {24'd0,datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd5:	begin res <= {16'd0,datiL[15:0]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
				state <= WRITEBACK;
			end
			else begin
				ARID <= 4'h2;
				ARADDR <= {ARADDR[31:2]+2'd1,2'd0};
				state <= MEMORY_READ3;
			end
		end
	end
MEMORY_READ3:
	if (ARREADY) begin
		state <= MEMORY_READ4;
	end
MEMORY_READ4:
	begin
	RREADY <= 1'b1;
	if (RVALID && RID==4'h2) begin
		state <= WRITEBACK;
{+A}
		`AMO:
			begin
				if (funct5 != 5'd2 && funct5 != 5'd3) begin	// LR / SC
					AWID <= 4'h1;
					AWVALID <= 1'b1;
					AWADDR <= ea;
					WVALID <= 1'b1;
					WSTRB <= ssel[3:0];
					WDATA <= sdat[31:0];
					state <= MEMORY_WRITE;
				end
			end
{-A}
		`LOAD:
			begin
				case(funct3)
				3'd1: begin res[31:8] <= {{16{RDATA[7]}},RDATA[7:0]}; illegal_insn <= 1'b0; end
				3'd2:
					case(ea[1:0])
					2'd1:	begin res <= {RDATA[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
					2'd2:	begin res <= {RDATA[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
					2'd3:	begin res <= {RDATA[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				3'd5:	begin res[31:8] <= {16'd0,RDATA[7:0]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
{+F}
		`LOADF:
			begin
				case(ea[1:0])
				2'd1:	begin res <= {RDATA[15:0],dati[31:8]}; illegal_insn <= 1'b0; end
				2'd2:	begin res <= {RDATA[23:0],dati[31:16]}; illegal_insn <= 1'b0; end
				2'd3:	begin res <= {RDATA[31:0],dati[31:24]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
{-F}
	end
	end

MEMORY_WRITE:
	if (AWREADY & WREADY) begin
		AWVALID <= 1'b0;
		WVALID <= 1'b0;				
		state <= MEMORY_WRITE2;
	end
MEMORY_WRITE2:
	if (BVALID && BID==4'h1) begin
		BREADY <= 1'b1;
		if (ssel[7:4]==4'h0)
			state <= WRITEBACK;
		else begin
			AWID <= 4'h2;
			AWVALID <= 1'b1;
			AWADDR <= {AWADDR[31:2]+2'd1,2'd0};
			WVALID <= 1'b1;
			WSTRB <= ssel[7:4];
			WDATA <= sdat[63:32];
			state <= MEMORY_WRITE3;
		end
	end
{+U}
MEMORY_WRITE3:
	if (AWREADY & WREADY) begin
		AWVALID <= 1'b0;
		WVALID <= 1'b0;				
		state <= MEMORY_WRITE4;
	end
MEMORY_WRITE4:
	if (BVALID && BID==4'h2) begin
		BREADY <= 1'b1;
		state <= WRITEBACK;
	end
{-U}
{+F}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Float
// Wait for floating-point operation to complete.
// Capture results.
// Set status flags.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FLOAT:
	begin
		mathCnt <= mathCnt - 2'd1;
		if (mathCnt==8'd0) begin
			case(opcode)
{+FMA}
			`FMA,`FMS,`FNMA,`FNMS:
				begin
					res <= fres;
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
{-FMA}
			`FLOAT:
				case(funct5)
{+FADD}					
				5'd0:
					begin
						res <= fres;	// FADD
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				5'd1:
					begin
						res <= fres;	// FSUB
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
{-FADD}
{+FMUL}
				5'd2:
					begin
						res <= fres;	// FMUL
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
{-FMUL}
{+FDIV}
				5'd3:	
					begin
						res <= fres;	// FDIV
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (fb[FPWID-2:0]==1'd0)
							fdz <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
{-FDIV}
				5'd5:
					case(funct3)
{+FMIN}
					3'd0:	// FMIN	
						if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
							res <= 32'h7FFFFFFF;	// canonical NaN
						else if (fa_qnan & !fb_nan)
							res <= fb;
						else if (!fa_nan & fb_qnan)
							res <= fa;
						else if (fcmp_o[1])
							res <= fa;
						else
							res <= fb;
{-FMIN}
{+FMAX}							
					3'd1:	// FMAX
						if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
							res <= 32'h7FFFFFFF;	// canonical NaN
						else if (fa_qnan & !fb_nan)
							res <= fb;
						else if (!fa_nan & fb_qnan)
							res <= fa;
						else if (fcmp_o[1])
							res <= fb;
						else
							res <= fa;
{-FMAX}							
					default:	;
					endcase		
{+FSQRT}
				5'd11:
					begin
						res <= fres;	// FSQRT
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (fa[FPWID-2:0]==1'd0)
							fdz <= 1'b1;
						if (sqrinf|sqrneg)
							fnv <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
{-FSQRT}
				5'd20:
					case(funct3)
{+FLE}						
					3'd0:	
						begin
							res <= fcmp_o[2] & ~cmpnan;	// FLE
							if (cmpnan)
								fnv <= 1'b1;
						end
{-FLE}						
{+FLT}
					3'd1:
						begin
							res <= fcmp_o[1] & ~cmpnan;	// FLT
							if (cmpnan)
								fnv <= 1'b1;
						end
{-FLT}
{+FEQ}						
					3'd2:
						begin
							res <= fcmp_o[0] & ~cmpnan;	// FEQ
							if (cmpsnan)
								fnv <= 1'b1;
						end
{-FEQ}						
					default:	;
					endcase
				5'd24:	res <= ftoi_res;	// FCVT.W.S
				5'd26:	res <= itof_res;	// FCVT.S.W
				default:	;
				endcase
			default:	;
			endcase
			state <= WRITEBACK;
		end
	end
{-F}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback stage
// Update the register file (actual clocking above).
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WRITEBACK:
	begin
		ARVALID <= 1'b0;
		AWVALID <= 1'b0;
		RREADY <= 1'b0;	// end read cycle
		BREADY <= 1'b0;	// end write cycle
		set_wfi <= 1'b0;
		if (opcode==7'd115) begin
			case(funct3)
			3'd1,3'd5:
				if (Rs1!=5'd0)
				case({funct7,Rs2})
{+F}
				12'h001:	begin
										fnx <= ia[0];
										fuf <= ia[1];
										fof <= ia[2];
										fdz <= ia[3];
										fnv <= ia[4];
									end
				12'h002:	rm <= ia[2:0];
				12'h003:	begin
										fnx <= ia[0];
										fuf <= ia[1];
										fof <= ia[2];
										fdz <= ia[3];
										fnv <= ia[4];
										rm <= ia[7:5];
									end
{-F}
				12'h301:	begin if (MachineMode) mtvec <= {ia[31:2],2'b0}; end
				12'h321:	begin if (MachineMode) mtimecmp <= ia; wc_time_irq <= 1'b0; end
				12'h340:	begin if (MachineMode) mscratch <= ia; end
				12'h341:	begin upc <= ia; if (!MachineMode) pc <= ia; end
				endcase
{+F}
			3'd2,3'd6:
				case({funct7,Rs2})
				12'h001:	begin
										if (ia[0]) fnx <= 1'b1;
										if (ia[1]) fuf <= 1'b1;
										if (ia[2]) fof <= 1'b1;
										if (ia[3]) fdz <= 1'b1;
										if (ia[4]) fnv <= 1'b1;
									end
				12'h002:	rm <= rm | ia[2:0];
				12'h003:	begin
										if (ia[0]) fnx <= 1'b1;
										if (ia[1]) fuf <= 1'b1;
										if (ia[2]) fof <= 1'b1;
										if (ia[3]) fdz <= 1'b1;
										if (ia[4]) fnv <= 1'b1;
										rm <= rm | ia[7:5];
									end
				default: ;
				endcase
			3'd3,3'd7:
				case({funct7,Rs2})
				12'h001:	begin
										if (ia[0]) fnx <= 1'b0;
										if (ia[1]) fuf <= 1'b0;
										if (ia[2]) fof <= 1'b0;
										if (ia[3]) fdz <= 1'b0;
										if (ia[4]) fnv <= 1'b0;
									end
				12'h002:	rm <= rm & ~ia[2:0];
				12'h003:	begin
										if (ia[0]) fnx <= 1'b0;
										if (ia[1]) fuf <= 1'b0;
										if (ia[2]) fof <= 1'b0;
										if (ia[3]) fdz <= 1'b0;
										if (ia[4]) fnv <= 1'b0;
										rm <= rm & ~ia[7:5];
									end
				default: ;
				endcase
{-F}
			default:	;
			endcase
		end
		state <= IFETCH;
		instret <= instret + 2'd1;
		if (MachineMode)
			spc <= pc;
		else
			upc <= pc;
	end
endcase
end

endmodule
