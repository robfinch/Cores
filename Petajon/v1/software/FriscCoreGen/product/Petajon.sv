// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	petajon_wb.sv
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
`define LD			3'd3
`define LBU			3'd4
`define LHU			3'd5
`define LWU			3'd6
`define LOADF	7'd7
`define FENCE	7'd15
`define AUIPC	7'd23
`define STORE	7'd35
`define SB			3'd0
`define SH			3'd1
`define SW			3'd2
`define SD			3'd3
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
`define EBREAK	32'h00100073
`define ECALL		32'h00000073
`define ERET		32'h10000073
`define WFI			32'h10100073
`define PFI			32'h10300073
`define CS_ILLEGALINST	2

`include "../fpu/fpConfig.sv"

module petajon_wb(rst_i, hartid_i, clk_i, wc_clk_i, nmi_i, irq_i, cause_i, vpa_o, 
	cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i
	);
parameter WID = 64;
parameter FPWID = 64;
parameter AWID = 32;
parameter RSTPC = 32'hFFFC0100;
localparam AMSB = AWID-1;
input rst_i;
input [WID-1:0] hartid_i;
input clk_i;
input wc_clk_i;
input nmi_i;
input irq_i;
input [7:0] cause_i;
output reg vpa_o;
output cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [FPWID/8-1:0] sel_o;
output reg [AMSB:0] adr_o;
input [FPWID-1:0] dat_i;
output reg [FPWID-1:0] dat_o;
output reg sr_o;
output reg cr_o;
input rb_i;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
`include "../fpu/fpSize.sv"

wire clk_g;					// gated clock
reg lcyc;						// linear cycle
reg [AMSB:0] ladr;	// linear address

// Non visible registers
reg MachineMode;
reg [31:0] ir;			// instruction register
reg [31:0] upc;			// user mode pc
reg [31:0] spc;			// system mode pc
reg [4:0] Rd, Rs1, Rs2, Rs3;
reg [WID-1:0] ia, ib, ic;
reg [FPWID-1:0] fa, fb, fc;
reg [WID-1:0] imm, res;
reg [WID-1:0] displacement;				// branch displacement
// Decoding
wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [4:0] funct5 = ir[31:27];
wire [6:0] funct7 = ir[31:25];
wire [2:0] rm3 = ir[14:12];

reg [WID-1:0] iregfile [0:127];		// integer / system register file
reg [WID-1:0] sregfile [0:15];		// segment registers
reg [3:0] ASID;
reg wrpagemap;
//wire [12:0] pagemap_ndx;
//wire [8:0] pagemapoa, pagemapo;
//wire [12:0] pagemapa = Rs2==5'd0 ? {WID{1'd0}} : {irfob[19:16],irfob[8:0]};
wire [18:0] pagemap_ndx;
wire [12:0] pagemapoa, pagemapo;
wire [18:0] pagemapa = Rs2==5'd0 ? {WID{1'd0}} : {irfob[21:16],irfob[12:0]};
PagemapRam pagemap (
  .clka(clk_g),
  .ena(1'b1),
  .wea(wrpagemap),
  .addra(pagemapa),
  .dina(ia[12:0]),
  .douta(pagemapoa),
  .clkb(clk_g),
  .enb(1'b1),
  .web(1'b0),
  .addrb(pagemap_ndx),
  .dinb(13'h00),
  .doutb(pagemapo)
);
reg palloc,pfree,pfreeall;
wire pdone;
wire [12:0] pam_pageo;
PAM upam1 (
	.rst(rst_i),
	.clk(clk_g),
	.alloc_i(palloc),
	.free_i(pfree),
	.freeall_i(pfreeall),
	.pageno_i(ia[12:0]),
	.pageno_o(pam_pageo),
	.done(pdone)
);
reg decto, setto, getto;
wire [31:0] to_out;
wire [15:0] zl_out;
wire to_done;
Timeouter utmo1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.dec_i(decto),
	.set_i(setto),
	.qry_i(getto),
	.tid_i(ia[3:0]),
	.timeout_i(ib),
	.timeout_o(to_out),
	.zeros_o(zl_out),
	.done_o(to_done)
);
reg insrdy, rmvrdy, getrdy;
wire rdy_done;
wire [4:0] rdy_out;
ReadyList url1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.insert_i(insrdy),
	.remove_i(rmvrdy),
	.get_i(getrdy),
	.tid_i(ia[3:0]),
	.priority_i(ib[2:0]),
	.tid_o(rdy_out),
	.done_o(rdy_done)
);

reg [FPWID-1:0] fregfile [0:31];		// floating-point register file
reg [31:0] regset;
reg [1:0] Dregset, Rs1regset, Rs2regset, Rs3regset;
reg [AMSB:0] pc;			// generic program counter
reg [AMSB:0] ipc;			// pc value at instruction
reg [2:0] rm;
reg wrirf, wrfrf;
wire [WID-1:0] irfoa = iregfile[{Rs1regset,Rs1}];
wire [WID-1:0] irfob = iregfile[{Rs2regset,Rs2}];
wire [WID-1:0] irfoc = iregfile[{Rs3regset,Rs3}];
wire [FPWID-1:0] frfoa = fregfile[Rs1];
wire [FPWID-1:0] frfob = fregfile[Rs2];
wire [FPWID-1:0] frfoc = fregfile[Rs3];
always @(posedge clk_i)
if (wrirf && state==WRITEBACK)
	iregfile[{Dregset,Rd}] <= res[WID-1:0];
always @(posedge clk_i)
if (wrfrf && state==WRITEBACK)
	fregfile[Rd] <= res;
reg illegal_insn;

// CSRs
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi;
reg [AMSB:0] mepc;
reg [31:0] mtimecmp;
reg [63:0] instret;	// instructions completed.
reg [31:0] mcpuid = 32'b100000_00_00000000_00010001_00100001;
reg [31:0] mimpid = 32'h01108000;
reg [63:0] mcause;
reg [31:0] mstatus;
reg [AMSB:0] mtvec = 32'hFFFC0000;
reg [31:0] mtdeleg = 32'h0;
reg [31:0] mie;
reg [63:0] mscratch;
reg [AMSB:0] mbadaddr;
wire [31:0] mip;
reg msip;
assign mip[31:8] = 24'h0;
assign mip[6:4] = 3'b0;
assign mip[3] = msip;
assign mip[2:0] = 3'b0;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};
wire ie = mstatus[0];

function [7:0] fnSelect;
input [6:0] op6;
input [2:0] fn3;
case(op6)
`LOAD:
	case(fn3)
	`LB,`LBU:	fnSelect = 8'h01;
	`LH,`LHU:	fnSelect = 8'h03;
	`LW,`LWU:	fnSelect = 8'h0F;
	`LD:			fnSelect = 8'hFF;
	default:	fnSelect = 8'h0F;	
	endcase
`LOADF:
	case(FPWID)
	16:	fnSelect = 8'h03;
	24:	fnSelect = 8'h07;
	32:	fnSelect = 8'h0F;
	40:	fnSelect = 8'h1F;
	64:	fnSelect = 8'hFF;
	default:	fnSelect = 8'h0F;
	endcase
`STORE:
	case(fn3)
	`SB:	fnSelect = 8'h01;
	`SH:	fnSelect = 8'h03;
	`SW:	fnSelect = 8'h0F;
	`SD:	fnSelect = 8'hFF;
	default:	fnSelect = 8'h0F;
	endcase
`STOREF:
	case(FPWID)
	16:	fnSelect = 8'h03;
	24:	fnSelect = 8'h07;
	32:	fnSelect = 8'h0F;
	40:	fnSelect = 8'h1F;
	64:	fnSelect = 8'hFF;
	default:	fnSelect = 8'h0F;
	endcase
default:	fnSelect = 8'h00;
endcase
endfunction

wire [AMSB:0] ea = ia + imm;
wire [3:0] segsel = ea[31:28];
reg [63:0] dati;
reg [63:0] datiH;
wire [63:0] datiL = dat_i >> {ea[2:0],3'b0};
wire [127:0] sdat = (opcode==`STOREF ? fb : ib) << {ea[2:0],3'b0};
wire [15:0] ssel = fnSelect(opcode,funct3) << ea[2:0];

reg [4:0] state;
parameter IFETCH = 5'd1;
parameter IFETCH2 = 5'd2;
parameter DECODE = 5'd3;
parameter RFETCH = 5'd4;
parameter EXECUTE = 5'd5;
parameter MEMORY = 5'd6;
parameter MEMORY2 = 5'd7;
parameter MEMORY2_ACK = 5'd8;
parameter FLOAT = 5'd9;
parameter WRITEBACK = 5'd10;
parameter MEMORY_WRITE = 5'd11;
parameter MEMORY_WRITEACK = 5'd12;
parameter MEMORY_WRITE2 = 5'd13;
parameter MEMORY_WRITE2ACK = 5'd14;
parameter MUL1 = 5'd15;
parameter MUL2 = 5'd16;
parameter PAM	 = 5'd17;
parameter REGFETCH2 = 5'd18;
parameter MEMORY3 = 5'd19;
parameter MEMORY4 = 5'd20;
parameter TMO = 5'd21;
// States to allow paging lookup
parameter MEMORY1a = 5'd22;
parameter MEMORY1b = 5'd23;
parameter MEMORY2a = 5'd24;
parameter MEMORY2b = 5'd25;
parameter MEMORY_WRITE1a = 5'd26;
parameter MEMORY_WRITE1b = 5'd27;
parameter MEMORY_WRITE2a = 5'd28;
parameter MEMORY_WRITE2b = 5'd29;

wire ld = state==EXECUTE;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide support logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg sgn;
wire [WID*2-1:0] prod = ia * ib;
wire [WID*2-1:0] nprod = -prod;
wire [WID*2-1:0] div_q;
wire [WID*2-1:0] ndiv_q = -div_q;
wire [WID-1:0] div_r = ia - (ib * div_q[WID*2-1:WID]);
wire [WID-1:0] ndiv_r = -div_r;
reg ldd;
fpdivr16 #(WID) u16 (
	.clk(clk_g),
	.ld(ldd),
	.a(ia),
	.b(ib),
	.q(div_q),
	.r(),
	.done()
);
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [7:0] mathCnt;
reg [FPWID-1:0] fcmp_res, ftoi_res, itof_res, fres;
wire [2:0] rmq = rm3==3'b111 ? rm : rm3;

wire [4:0] fcmp_o;
wire [EX:0] fas_o, fmul_o, fdiv_o, fsqrt_o;
wire [EX:0] fma_o;
wire fma_uf;
wire mul_of, div_of;
wire mul_uf, div_uf;
wire norm_nx;
wire sqrt_done;
wire cmpnan, cmpsnan;
reg [EX:0] fnorm_i;
wire [MSB+3:0] fnorm_o;
reg ld1;
wire sqrneg, sqrinf;
wire fa_inf, fa_xz, fa_vz;
wire fa_qnan, fa_snan, fa_nan;
wire fb_qnan, fb_snan, fb_nan;
wire finf, fdn;
always @(posedge clk_g)
	ld1 <= ld;
fpDecomp #(FPWID) u12 (.i(fa), .sgn(), .exp(), .man(), .fract(), .xz(fa_xz), .mz(), .vz(fa_vz), .inf(fa_inf), .xinf(), .qnan(fa_qnan), .snan(fa_snan), .nan(fa_nan));
fpDecomp #(FPWID) u13 (.i(fb), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(fb_qnan), .snan(fb_snan), .nan(fb_nan));
fpCompare #(.FPWID(FPWID)) u1 (.a(fa), .b(fb), .o(fcmp_o), .nan(cmpnan), .snan(cmpsnan));
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f #(.FPWID(FPWID)) u2 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(ia), .o(itof_res));
f2i #(.FPWID(FPWID)) u3 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .i(fa), .o(ftoi_res), .overflow());
fpAddsub #(.FPWID(FPWID)) u4 (.clk(clk_g), .ce(1'b1), .rm(rmq), .op(funct5==`FSUB), .a(fa), .b(fb), .o(fas_o));
fpMul #(.FPWID(FPWID)) u5 (.clk(clk_g), .ce(1'b1), .a(fa), .b(fb), .o(fmul_o), .sign_exe(), .inf(), .overflow(nmul_of), .underflow(mul_uf));
fpDiv #(.FPWID(FPWID)) u6 (.rst(rst_i), .clk(clk_g), .clk4x(1'b0), .ce(1'b1), .ld(ld), .op(1'b0),
	.a(fa), .b(fb), .o(fdiv_o), .done(), .sign_exe(), .overflow(div_of), .underflow(div_uf));
fpSqrt #(.FPWID(FPWID)) u7 (.rst(rst_i), .clk(clk_g), .ce(1'b1), .ld(ld),
	.a(fa), .o(fsqrt_o), .done(sqrt_done), .sqrinf(sqrinf), .sqrneg(sqrneg));
fpFMA #(.FPWID(FPWID)) u14
(
	.clk(clk_g),
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

always @(posedge clk_g)
case(opcode)
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_i <= fma_o;
`FLOAT:
	case(funct5)
	`FADD:	fnorm_i <= fas_o;
	`FSUB:	fnorm_i <= fas_o;
	`FMUL:	fnorm_i <= fmul_o;
	`FDIV:	fnorm_i <= fdiv_o;
	`FSQRT:	fnorm_i <= fsqrt_o;
	default:	fnorm_i <= 1'd0;
	endcase
default:	fnorm_i <= 1'd0;
endcase
reg fnorm_uf;
wire norm_uf;
always @(posedge clk_g)
case(opcode)
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_uf <= fma_uf;
`FLOAT:
	case(funct5)
	`FMUL:	fnorm_uf <= mul_uf;
	`FDIV:	fnorm_uf <= div_uf;
	default:	fnorm_uf <= 1'b0;
	endcase
default:	fnorm_uf <= 1'b0;
endcase
fpNormalize #(.FPWID(FPWID)) u8 (.clk(clk_g), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(fnorm_uf), .under_o(norm_uf), .inexact_o(norm_nx));
fpRound #(.FPWID(FPWID)) u9 (.clk(clk_g), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));
fpDecompReg #(FPWID) u10 (.clk(clk_g), .ce(1'b1), .i(fres), .sgn(), .exp(), .fract(), .xz(fdn), .vz(), .inf(finf), .nan() );

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

assign mip[7] = wc_time_irq;

wire pe_nmi;
reg nmif;
edge_det u17 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(nmi_i), .pe(pe_nmi), .ne(), .ee() );

always @(posedge wc_clk_i)
if (rst_i)
	wfi <= 1'b0;
else begin
	if (set_wfi)
		wfi <= 1'b1;
	if (|irq_i|pe_nmi)
		wfi <= 1'b0;
end

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

delay2 #(1) udly1 (.clk(clk_g), .ce(1'b1), .i(lcyc), .o(cyc_o));
assign pagemap_ndx = {ASID,ladr[28:16]};

always @(posedge clk_g)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Reset
// The program counters are set at their reset values.
// System mode is activated and interrupts are masked.
// All other state is undefined.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (rst_i) begin
	state <= IFETCH;
	pc <= RSTPC;
	mepc <= 32'hFFFC0200;
	mtvec <= 32'hFFFC0000;
	MachineMode <= 1'b1;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
	lcyc <= LOW;
	stb_o <= LOW;
	we_o <= LOW;
	ladr <= RSTPC;
	dat_o <= 32'h0;
	sr_o <= 1'b0;
	cr_o <= 1'b0;
	instret <= 64'd0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	mstatus <= 6'b001110;
	nmif <= 1'b0;
	ldd <= 1'b0;
	wrpagemap <= 1'b0;
	palloc <= 1'b0;
	pfree <= 1'b0;
	pfreeall <= 1'b0;
	regset <= 32'h0000001F;
	Dregset <= 2'd1;
	Rs1regset <= 2'd1;
	Rs2regset <= 2'd1;
	Rs3regset <= 2'd1;
	setto <= 1'b0;
	getto <= 1'b0;
	decto <= 1'b0;
	insrdy <= 1'b0;
	rmvrdy <= 1'b0;
	getrdy <= 1'b0;
end
else begin
decto <= 1'b0;
ldd <= 1'b0;
wrpagemap <= 1'b0;
if (pe_nmi)
	nmif <= 1'b1;
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
if (wc_time_irq==1'b0)
	wc_time_irq_clr <= 1'd0;
palloc <= 1'b0;
pfree <= 1'b0;
pfreeall <= 1'b0;

if (MachineMode)
	adr_o <= ladr;
else begin
	if (ladr[31:24]==8'hFF)
		adr_o <= ladr;
	else
		adr_o <= {pagemapo,ladr[15:0]};
end

case (state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch
// Get the instruction from the rom.
// Increment the program counter.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
IFETCH:
	begin
		illegal_insn <= 1'b1;
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
		vpa_o <= HIGH;
		lcyc <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'hF;
		tPC();
		state <= IFETCH2;
		if (regset[5:4]!=2'd3) begin
			if (nmif) begin
				nmif <= 1'b0;
				lcyc <= LOW;
				mcause[63] <= 1'b1;
				mcause[7:0] <= 8'd254;
				MachineMode <= 1'b1;
				mepc <= pc;
				pc <= mtvec + 8'hFC;
				mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
				regset <= {regset[25:4],regset[5:4]+2'd1,regset[3:0]};
				state <= IFETCH;
			end
	 		else if (irq_i & ie) begin
				lcyc <= LOW;
				mcause[63] <= 1'b1;
				mcause[7:0] <= cause_i;
				MachineMode <= 1'b1;
				mepc <= pc;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
				regset <= {regset[25:4],regset[5:4]+2'd1,regset[3:0]};
				state <= IFETCH;
			end
			else if (mip[7] & mie[7] & ie) begin
				lcyc <= LOW;
				mcause[63] <= 1'b1;
				mcause[7:0] <= 8'h01;	// timer IRQ
				MachineMode <= 1'b1;
				mepc <= pc;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
				regset <= {regset[25:4],regset[5:4]+2'd1,regset[3:0]};
				state <= IFETCH;
			end
			else if (mip[3] & mie[3] & ie) begin
				lcyc <= LOW;
				mcause[63] <= 1'b1;
				mcause[7:0] <= 8'h02;	// software IRQ
				MachineMode <= 1'b1;
				mepc <= pc;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
				regset <= {regset[25:4],regset[5:4]+2'd1,regset[3:0]};
				state <= IFETCH;
			end
			else
				pc <= pc + 3'd4;
		end
		else
			pc <= pc + 3'd4;
	end
IFETCH2:
	if (ack_i) begin
		vpa_o <= LOW;
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		tPC();
		ir <= adr_o[2] ? dat_i[63:32] : dat_i[31:0];
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
			mepc <= ipc;
			pc <= mtvec + {mstatus[2:1],6'h00};
			mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
			state <= IFETCH;
		end
		// Set some sensible decode defaults
		Rs1 <= ir[19:15];
		Rs2 <= ir[24:20];
		Rs3 <= ir[31:27];
		Rd <= 5'd0;
		displacement <= 64'd0;
		// Override defaults
		case(opcode)
		`AUIPC,`LUI:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				imm <= {{WID-32{ir[31]}},ir[31:12],12'd0};
				wrirf <= 1'b1;
			end
		`JAL:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				imm <= {{WID-21{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
				wrirf <= 1'b1;
			end
		`JALR:
			begin
				illegal_insn <= 1'b0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				imm <= {{WID-12{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`LOAD:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				imm <= {{WID-12{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`LOADF:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				imm <= {{WID-12{ir[31]}},ir[31:20]};
				wrfrf <= 1'b1;
			end
		`STOREF:
			begin
				imm <= {{WID-12{ir[31]}},ir[31:25],ir[11:7]};
			end
		`STORE:
			begin
				imm <= {{WID-12{ir[31]}},ir[31:25],ir[11:7]};
			end
		7'd13:
			begin
				Rd <= ir[11:7];
				case (funct3)
				3'd0:	
					begin
						wrirf <= 1'b1;
						case(funct7)
						7'd4:	wrirf <= 1'b1;
						default:	;
						endcase
					end
				endcase
			end
		7'd19:
			begin
				case(funct3)
				3'd0:	imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd1: imm <= ir[24:20];
				3'd2:	imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd3: imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd4: imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd5: imm <= ir[24:20];
				3'd6: imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd7: imm <= {{WID-12{ir[31]}},ir[31:20]};
				endcase
				Rd <= ir[11:7];
				wrirf <= 1'b1;
			end
		7'd51,7'd115:
			begin
				Rd <= ir[11:7];
				wrirf <= 1'b1;
			end
		`FMA,`FMS,`FNMA,`FNMS:
			begin
				Rd <= ir[11:7];
				wrfrf <= 1'b1;
			end
		`FLOAT:
			begin
				Rd <= ir[11:7];
				if (funct5==5'd20 || funct5==5'd24 || funct5==5'd28)
					wrirf <= 1'b1;
				else
					wrfrf <= 1'b1;
			end
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
		state <= REGFETCH2;
		ia <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
		ib <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
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
		fc <= Rs3==5'd0 ? {FPWID{1'd0}} : frfoc;
	end
REGFETCH2:
	state <= EXECUTE;

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
		7'd13:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:	begin res <= sregfile[ib[3:0]]; illegal_insn <= 1'b0; end
				7'd1:	begin res <= pagemapoa; illegal_insn <= 1'b0; end
				7'd2:	begin res <= ia; illegal_insn <= 1'b0; end
				7'd4:	
					begin
						palloc <= 1'b1;
						state <= PAM;
						illegal_insn <= 1'b0;
					end
				7'd5:
					begin
						pfree <= 1'b1;
						state <= PAM;
						illegal_insn <= 1'b0;
					end
				7'd6:
					begin
						pfreeall <= 1'b1;
						state <= PAM;
						illegal_insn <= 1'b0;
					end
				7'd8:
					begin
						setto <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd9:
					begin
						getto <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd10:	// GETZL
					begin
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd11:
					begin
						decto <= 1'b1;
						illegal_insn <= 1'b0;
						state <= IFETCH;
					end
				7'd12:
					begin
						insrdy <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd13:
					begin
						rmvrdy <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd14:
					begin
						getrdy <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				default:	;
				endcase
			default:	;
			endcase
		7'd51:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:		begin res <= ia + ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				7'd32:	begin res <= ia - ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd1:
				case(funct7)
				7'd0:	begin res <= ia << ib[4:0]; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd2:
				case(funct7)
				7'd0:	begin res <= $signed(ia) < $signed(ib); illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd3:
				case(funct7)
				7'd0:	begin res <= ia < ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd4:
				case(funct7)
				7'd0:	begin res <= ia ^ ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd5:
				case(funct7)
				7'd0:	begin res <= ia >> ib[4:0]; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
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
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd7:
				case(funct7)
				7'd0:	begin res <= ia & ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
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
		`FMA,`FMS,`FNMA,`FNMS:
			begin mathCnt <= 45; state <= FLOAT; illegal_insn <= 1'b0; end
		// The timeouts for the float operations are set conservatively. They may
		// be adjusted to lower values closer to actual time required.
		`FLOAT:	// Float
			case(funct5)
			`FADD:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FADD
			`FSUB:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FSUB
			`FMUL:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FMUL
			`FDIV:	begin mathCnt <= 8'd40; state <= FLOAT; illegal_insn <= 1'b0; end	// FDIV
			`FMIN:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FMIN / FMAX
			`FSQRT:	begin mathCnt <= 8'd160; state <= FLOAT; illegal_insn <= 1'b0; end	// FSQRT
			`FSGNJ:	
				case(funct3)
				3'd0:	begin res <= {fb[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end		// FSGNJ
				3'd1:	begin res <= {~fb[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end	// FSGNJN
				3'd2:	begin res <= {fb[FPWID-1]^fa[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end	// FSGNJX
				default:	;
				endcase
			5'd20:
				case(funct3)
				3'd0:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLE
				3'd1:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLT
				3'd2:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FEQ
				default:	;
				endcase
			5'd24:	begin mathCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.T.FT
			5'd26:	begin mathCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.FT.T
			5'd28:
				begin
					case(funct3)
					3'd0:	begin res <= fa; illegal_insn <= 1'b0; end	// FMV.X.S
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
					endcase
				end
			5'd30:
				case(funct3)
				3'd0:	begin res <= ia; illegal_insn <= 1'b0; end	// FMV.S.X
				default:	;
				endcase
			default:	;
			endcase
		`JAL:
			begin
				res <= pc;
				pc <= ipc + imm;
				pc[0] <= 1'b0;
			end
		`JALR:
			begin
				res <= pc;
				pc <= ia + imm;
				pc[0] <= 1'b0;
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
				lcyc <= HIGH;
				sel_o <= ssel[7:0];
				tEA();
				state <= MEMORY;
			end
		`STORE:
			begin
				lcyc <= HIGH;
				we_o <= HIGH;
				sel_o <= ssel[7:0];
				tEA();
				dat_o <= sdat[63:0];
				case(funct3)
				3'd0,3'd1,3'd2,3'd3:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY;
			end
		`LOADF:
			begin
				lcyc <= HIGH;
				sel_o <= ssel[7:0];
				tEA();
				state <= MEMORY;
			end
		`STOREF:
			begin
				lcyc <= HIGH;
				we_o <= HIGH;
				sel_o <= ssel[7:0];
				tEA();
				dat_o <= sdat[63:0];
				case(funct3)
				3'd2,3'd3:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY;
			end
		7'd115:
			begin
				case(ir)
				`EBREAK:
					begin
						MachineMode <= 1'b1;
						pc <= mtvec + {mstatus[2:1],6'h00};
						mepc <= pc;
						mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
						mcause <= 4'h3;
						regset <= {regset[25:4],regset[5:4]+2'd1,regset[3:0]};
						illegal_insn <= 1'b0;
						state <= IFETCH;
						instret <= instret + 2'd1;
					end
				`ECALL:
					begin
						MachineMode <= 1'b1;
						pc <= mtvec + {mstatus[2:1],6'h00};
						mepc <= pc;
						mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
						mcause <= 4'h8 + mstatus[2:1];
						regset <= {regset[25:4],regset[5:4]+2'd1,regset[3:0]};
						illegal_insn <= 1'b0;
						state <= IFETCH;
						instret <= instret + 2'd1;
					end
				`ERET:
					if (MachineMode) begin
						MachineMode <= 1'b0;
						pc <= mepc;
						mstatus[5:0] <= {2'b00,1'b1,mstatus[5:3]};
						regset <= {2'b00,regset[25:6],regset[3:0]};
						illegal_insn <= 1'b0;
						state <= IFETCH;
						instret <= instret + 2'd1;
					end
				`WFI:
					set_wfi <= 1'b1;
				default:
					begin
					case(funct3)
					3'd1,3'd2,3'd3,3'd5,3'd6,3'd7:
						casez({funct7,Rs2})
						12'h001:	begin res <= fscsr[4:0]; illegal_insn <= 1'b0; end
						12'h002:	begin res <= rm; illegal_insn <= 1'b0; end
						12'h003:	begin res <= fscsr; illegal_insn <= 1'b0; end
						12'h181:	begin res <= ASID; illegal_insn <= 1'b0; end
						12'h300:	begin res <= mstatus; illegal_insn <= 1'b0; end
						12'h301:	begin res <= mtvec; illegal_insn <= 1'b0; end
						12'h302:	begin res <= mtdeleg; illegal_insn <= 1'b0; end
						12'h304:	begin res <= mie; illegal_insn <= 1'b0; end
						12'h321:	begin res <= mtimecmp; wc_time_irq_clr <= 6'h3F; illegal_insn <= 1'b0; end
						12'h340:	begin res <= mscratch; illegal_insn <= 1'b0; end
						12'h341:	begin res <= mepc; illegal_insn <= 1'b0; end
						12'h342:	begin res <= mcause; illegal_insn <= 1'b0; end
						12'h343:	begin res <= mbadaddr; illegal_insn <= 1'b0; end
						12'h344:	begin res <= mip; illegal_insn <= 1'b0; end
						12'h780:	begin res <= regset; illegal_insn <= 1'b0; end
						12'hC00:	begin res <= tick[63: 0]; illegal_insn <= 1'b0; end
//						12'hC80:	begin res <= tick[63:32]; illegal_insn <= 1'b0; end
						12'hC01,12'h701,12'hB01:	begin res <= wc_times[63: 0]; illegal_insn <= 1'b0; end
						12'hC81,12'h741,12'hB81:	begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
						12'hC02:	begin res <= instret[63: 0]; illegal_insn <= 1'b0; end
//						12'hC82:	begin res <= instret[63:32]; illegal_insn <= 1'b0; end
						12'hF00:	begin res <= mcpuid; illegal_insn <= 1'b0; end	// cpu description
						12'hF01:	begin res <= mimpid; illegal_insn <= 1'b0; end // implmentation id
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
PAM:
	if (pdone) begin
		res <= {51'h0,pam_pageo};
		state <= WRITEBACK;
	end
TMO:
	if (to_done&rdy_done) begin
		illegal_insn <= 1'b0;
		case({getto,getrdy})
		2'b10:	res <= to_out;
		2'b01:	res <= {{59{rdy_out[4]}},rdy_out};
		default:	res <= {48'd0,zl_out};
		endcase
		state <= WRITEBACK;
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Adjust for sign
MUL1:
	begin
		ldd <= 1'b1;
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
		endcase
	end
// Capture result
MUL2:
	begin
		mathCnt <= mathCnt - 8'd1;
		if (mathCnt==8'd0) begin
			state <= WRITEBACK;
			case(funct3)
			3'd0:	res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			3'd1:	res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			3'd2:	res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			3'd3:	res <= prod[WID*2-1:WID];
			3'd4:	res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			3'd5: res <= div_q[WID*2-1:WID];
			3'd6:	res <= sgn ? ndiv_r : div_r;
			3'd7:	res <= div_r;
			endcase
		end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MEMORY:
	state <= MEMORY1a;
MEMORY1a:
	begin
		stb_o <= HIGH;
		state <= MEMORY1b;
	end
MEMORY1b:
	if (ack_i) begin
		stb_o <= LOW;
		if (ssel[15:8]==8'h00) begin
			lcyc <= LOW;
			we_o <= LOW;
			sel_o <= 4'h0;
			sr_o <= 1'b0;
			cr_o <= 1'b0;
			tPC();
			state <= WRITEBACK;
			case(opcode)
			`LOAD:
				case(funct3)
				3'd0:	begin res <= {{56{datiL[7]}},datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd1: begin res <= {{48{datiL[15]}},datiL[15:0]}; illegal_insn <= 1'b0; end
				3'd2:	begin res <= {{32{datiL[31]}},datiL[31:0]}; illegal_insn <= 1'b0; end
				3'd3: begin res <= dat_i; illegal_insn <= 1'b0; end
				3'd4:	begin res <= {56'd0,datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd5:	begin res <= {48'd0,datiL[15:0]}; illegal_insn <= 1'b0; end
				3'd6: begin res <= {32'd0,datiL[31:0]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			`LOADF:	begin res <= dat_i; illegal_insn <= 1'b0; end
			endcase
		end
		else
			state <= MEMORY2;
		dati[63:0] <= dat_i;
	end
// Run a second bus cycle to handle unaligned access.
MEMORY2:
	if (~ack_i) begin
		sel_o <= ssel[15:8];
		ladr <= {ladr[31:3]+2'd1,3'd0};
		dat_o <= sdat[127:64];
		state <= MEMORY2a;
	end
MEMORY2a:
	state <= MEMORY2b;
MEMORY2b:
	begin
		stb_o <= HIGH;
		state <= MEMORY2_ACK;
	end
MEMORY2_ACK:
	if (ack_i) begin
		datiH <= dat_i;
		lcyc <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 8'h0;
		sr_o <= 1'b0;
		cr_o <= 1'b0;
		state <= MEMORY3;
		case(opcode)
		endcase
	end
MEMORY3:
	if (~ack_i) begin
		tPC();
		state <= MEMORY4;
		case(opcode)
		`LOAD:
			begin
				case(funct3)
				3'd1: begin res <= {{48{datiH[7]}},datiH[7:0],dati[63:56]}; illegal_insn <= 1'b0; end
				3'd2:
					case(ea[2:0])
					3'd5:	begin res <= {{32{datiH[7]}},datiH[7:0],dati[63:40]}; illegal_insn <= 1'b0; end
					3'd6:	begin res <= {{32{datiH[15]}},datiH[15:0],dati[63:48]}; illegal_insn <= 1'b0; end
					3'd7:	begin res <= {{32{datiH[23]}},datiH[23:0],dati[63:56]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				3'd3:
					case(ea[2:0])
					3'd1:	begin res <= {datiH[7:0],dati[63:8]}; illegal_insn <= 1'b0; end
					3'd2:	begin res <= {datiH[15:0],dati[63:16]}; illegal_insn <= 1'b0; end
					3'd3:	begin res <= {datiH[23:0],dati[63:24]}; illegal_insn <= 1'b0; end
					3'd4:	begin res <= {datiH[31:0],dati[63:32]}; illegal_insn <= 1'b0; end
					3'd5:	begin res <= {datiH[39:0],dati[63:40]}; illegal_insn <= 1'b0; end
					3'd6:	begin res <= {datiH[47:0],dati[63:48]}; illegal_insn <= 1'b0; end
					3'd7:	begin res <= {datiH[55:0],dati[63:56]}; illegal_insn <= 1'b0; end
					endcase
				3'd5:	begin res <= {16'd0,datiH[7:0],dati[31:24]}; illegal_insn <= 1'b0; end
				3'd6:
					case(ea[2:0])
					3'd5:	begin res <= {32'd0,datiH[7:0],dati[63:40]}; illegal_insn <= 1'b0; end
					3'd6:	begin res <= {32'd0,datiH[15:0],dati[63:48]}; illegal_insn <= 1'b0; end
					3'd7:	begin res <= {32'd0,datiH[23:0],dati[63:56]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				default:	;
				endcase
			end
		`LOADF:
			begin
				case(ea[2:0])
				3'd1:	begin res <= {datiH[7:0],dati[63:8]}; illegal_insn <= 1'b0; end
				3'd2:	begin res <= {datiH[15:0],dati[63:16]}; illegal_insn <= 1'b0; end
				3'd3:	begin res <= {datiH[23:0],dati[63:24]}; illegal_insn <= 1'b0; end
				3'd4:	begin res <= {datiH[31:0],dati[63:32]}; illegal_insn <= 1'b0; end
				3'd5:	begin res <= {datiH[39:0],dati[63:40]}; illegal_insn <= 1'b0; end
				3'd6:	begin res <= {datiH[47:0],dati[63:48]}; illegal_insn <= 1'b0; end
				3'd7:	begin res <= {datiH[55:0],dati[63:56]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
		endcase
	end
MEMORY4:
	state <= WRITEBACK;
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
			`FMA,`FMS,`FNMA,`FNMS:
				begin
					res <= fres;
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			`FLOAT:
				case(funct5)
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
				5'd2:
					begin
						res <= fres;	// FMUL
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				5'd3:	
					begin
						res <= fres;	// FDIV
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (fb[FPWID-2:0]==1'd0)
							fdz <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				5'd5:
					case(funct3)
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
					3'd1:	// FMAX
						if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
							res <= 64'h7FFFFFFFFFFFFFFF;	// canonical NaN
						else if (fa_qnan & !fb_nan)
							res <= fb;
						else if (!fa_nan & fb_qnan)
							res <= fa;
						else if (fcmp_o[1])
							res <= fb;
						else
							res <= fa;
					default:	;
					endcase		
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
				5'd20:
					case(funct3)
					3'd0:	
						begin
							res <= fcmp_o[2] & ~cmpnan;	// FLE
							if (cmpnan)
								fnv <= 1'b1;
						end
					3'd1:
						begin
							res <= fcmp_o[1] & ~cmpnan;	// FLT
							if (cmpnan)
								fnv <= 1'b1;
						end
					3'd2:
						begin
							res <= fcmp_o[0] & ~cmpnan;	// FEQ
							if (cmpsnan)
								fnv <= 1'b1;
						end
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
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback stage
// Update the register file (actual clocking above).
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WRITEBACK:
	begin
		getto <= 1'b0;
		setto <= 1'b0;
		insrdy <= 1'b0;
		rmvrdy <= 1'b0;
		getrdy <= 1'b0;
		if (illegal_insn) begin
			MachineMode <= 1'b1;
			pc <= mtvec + {mstatus[2:1],6'h00};
			mepc <= ipc;
			mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
			mcause <= 4'h2;
			illegal_insn <= 1'b0;
		end
		set_wfi <= 1'b0;
		if (!illegal_insn && opcode==7'd13) begin
			case(funct3)
			3'd0:
				if (Rs1 != 5'd0)
				case(funct7)
				7'd0:		sregfile[ib[3:0]] <= ia;
				7'd1:		wrpagemap <= 1'b1;
				default:	;
				endcase
			default:	;
			endcase
		end
		if (!illegal_insn && opcode==7'd115) begin
			case(funct3)
			3'd1,3'd5:
				if (Rs1!=5'd0)
				casez({funct7,Rs2})
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
				12'h181:	begin if (MachineMode) ASID <= ia; end
				12'h300:	begin if (MachineMode) mstatus <= ia; end
				12'h301:	begin if (MachineMode) mtvec <= {ia[31:2],2'b0}; end
				12'h304:	begin if (MachineMode) mie <= ia; end
				12'h321:	begin if (MachineMode) mtimecmp <= ia; end
				12'h340:	begin if (MachineMode) mscratch <= ia; end
				12'h341:	begin if (MachineMode) mepc <= ia; end
				12'h342:	begin if (MachineMode) mcause <= ia; end
				12'h343:  begin if (MachineMode) mbadaddr <= ia; end
				12'h344:	begin if (MachineMode) msip <= ia[3]; end
				12'h780:	begin 
										if (MachineMode) begin
											regset <= ia[3:0];
											if (ia[0]==1'b0)
												Dregset <= regset[7:6];
											else
												Dregset <= regset[5:4];
											if (ia[1]==1'b0)
												Rs1regset <= regset[7:6];
											else
												Rs1regset <= regset[5:4];
											if (ia[2]==1'b0)
												Rs2regset <= regset[7:6];
											else
												Rs2regset <= regset[5:4];
											if (ia[3]==1'b0)
												Rs3regset <= regset[7:6];
											else
												Rs3regset <= regset[5:4];
										end
									end
				default:	;
				endcase
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
				12'h304:	if (MachineMode) mie <= mie | ia;
				12'h344:	if (MachineMode) msip <= msip | ia[3];
				12'h800:	if (MachineMode) regset <= regset | ia[3:0];
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
				12'h304:	if (MachineMode) mie <= mie & ~ia;
				12'h344:	if (MachineMode) msip <= msip & ~ia[3];
				12'h800:	if (MachineMode) regset <= regset & ~ia[3:0];
				default: ;
				endcase
			default:	;
			endcase
		end
		state <= IFETCH;
		instret <= instret + 2'd1;
	end
endcase
end

task tEA;
begin
	if (MachineMode || ea[31:24]==8'hFF)
		ladr <= ea;
	else
		ladr <= ea[27:0] + {sregfile[segsel][WID-1:4],16'd0};
end
endtask

task tPC;
begin
	if (MachineMode || pc[31:24]==8'hFF)
		ladr <= pc;
	else
		ladr <= pc[29:0] + {sregfile[{2'b11,pc[31:30]}][WID-1:4],16'd0};
end
endtask

endmodule
