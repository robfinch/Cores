// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Petajon32.sv
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
`define HALT		32'h10500073
`define CS_ILLEGALINST	2

`define LOG_PGSZ	16

`include "../fpu/fpConfig.sv"

module Petajon(rst_i, hartid_i, clk_i, wc_clk_i, nmi_i, irq_i, cause_i, vpa_o, 
	cyc_o, wb_stb_o, ack_i, wb_we_o, wb_sel_o, wb_adr_o, wb_dat_i, wb_dat_o, sr_o, cr_o, rb_i,
	ACLK, ARESETN,
	AWID, AWADDR, AWLEN,AWSIZE,AWBURST,AWLOCK,AWPROT,AWQOS,AWREGION,AWVALID,AWREADY,AWCACHE,
	WVALID,WREADY,WSTRB,WLAST,WDATA,BID,BRESP,BVALID,BREADY,
	ARID, ARADDR, ARLEN,ARSIZE,ARBURST,ARLOCK,ARPROT,ARQOS,ARREGION,ARVALID,ARREADY,ARCACHE,
	RID,RRESP,RDATA,RLAST,RVALID,RREADY
	);
parameter WID = 32;
parameter FPWID = 64;
parameter ABWID = 32;
parameter RSTPC = 32'hFFFC0100;
localparam AMSB = ABWID-1;
input rst_i;
input [WID-1:0] hartid_i;
input clk_i;
input wc_clk_i;
input nmi_i;
input [2:0] irq_i;
input [7:0] cause_i;
output reg vpa_o;
output reg cyc_o;
output reg wb_stb_o;
input ack_i;
output reg wb_we_o;
output reg [FPWID/8-1:0] wb_sel_o;
output reg [AMSB:0] wb_adr_o;
input [FPWID-1:0] wb_dat_i;
output reg [FPWID-1:0] wb_dat_o;
output reg sr_o;
output reg cr_o;
input rb_i;
// System
input ACLK;
input ARESETN;
// Write address channel
output reg [3:0] AWID;			// transaction ID (we choose at least 4 bits)
output [AMSB:0] AWADDR;
output reg [7:0] AWLEN;			// Burst length -1
output reg [2:0] AWSIZE;		// 010 = 4 bytes, 011 = 8 bytes
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
output reg [WID/8-1:0] WSTRB;
output reg WLAST;						// indicates last burst cycle
output reg [WID-1:0] WDATA;
// Write response
input [3:0] BID;
input [1:0] BRESP;					// 00 = OKAY, 01 = EXOKAY, 10=SLVERR, 11= DECERR
input BVALID;
output reg BREADY;
// Read address channel
output reg [3:0] ARID;
output [AMSB:0] ARADDR;
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
input [WID-1:0] RDATA;
input RLAST;
input RVALID;
output reg RREADY;

parameter HIGH = 1'b1;
parameter LOW = 1'b0;
`include "../fpu/fpSize.sv"

wire clk_g;					// gated clock
reg lcyc;						// linear cycle
reg [AMSB:0] ladr;	// linear address

assign AWADDR = wb_adr_o;
assign ARADDR = wb_adr_o;

reg [5:0] state;
parameter IFETCH = 6'd1;
parameter IFETCH2 = 6'd2;
parameter DECODE = 6'd3;
parameter RFETCH = 6'd4;
parameter EXECUTE = 6'd5;
parameter MEMORY = 6'd6;
parameter MEMORY2 = 6'd7;
parameter MEMORY2_ACK = 6'd8;
parameter FLOAT = 6'd9;
parameter WRITEBACK = 6'd10;
parameter MEMORY_WRITE = 6'd11;
parameter MEMORY_WRITEACK = 6'd12;
parameter MEMORY_WRITE2 = 6'd13;
parameter MEMORY_WRITE2ACK = 6'd14;
parameter MUL1 = 6'd15;
parameter MUL2 = 6'd16;
parameter PAM	 = 6'd17;
parameter REGFETCH2 = 6'd18;
parameter MEMORY3 = 6'd19;
parameter MEMORY4 = 6'd20;
parameter TMO = 6'd21;
// States to allow paging lookup
parameter MEMORY1a = 6'd22;
parameter MEMORY1b = 6'd23;
parameter MEMORY2a = 6'd24;
parameter MEMORY2b = 6'd25;
parameter MEMORY_WRITE1a = 6'd26;
parameter MEMORY_WRITE1b = 6'd27;
parameter MEMORY_WRITE2a = 6'd28;
parameter MEMORY_WRITE2b = 6'd29;
parameter IFETCH3 = 6'd30;
parameter AXI_MEMORY_READ = 6'd32;
parameter AXI_MEMORY_READ2 = 6'd33;
parameter AXI_MEMORY_READ3 = 6'd34;
parameter AXI_MEMORY_READ4 = 6'd35;
parameter AXI_MEMORY_WRITE = 6'd36;
parameter AXI_MEMORY_WRITE2 = 6'd36;
parameter AXI_MEMORY_WRITE3 = 6'd37;
parameter AXI_MEMORY_WRITE4 = 6'd38;
parameter MEMORY1c = 6'd39;
parameter REGFETCH3 = 6'd40;
parameter REGFETCH4 = 6'd41;
parameter REGFETCH5 = 6'd42;

// Non visible registers
reg [15:0] ilevel;
reg [15:0] stackdepth;
reg [31:0] ir;			// instruction register
reg [AMSB:0] upc;			// user mode pc
reg [AMSB:0] spc;			// system mode pc
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
wire [4:0] Rs1 = ir[19:15];
wire [4:0] Rs2 = ir[24:20];
wire [4:0] Rs3 = ir[31:27];
reg [4:0] Rd;

reg [4:0] Dregset, Rs1regset, Rs2regset, Rs3regset;
wire [WID-1:0] irfoa, irfob, irfoc;
reg wrirf, wrfrf;

regfileRam urf1 (
  .clka(clk_g),
  .ena(state==WRITEBACK),
  .wea(wrirf),
  .addra({Dregset,Rd}),
  .dina(res),
  .clkb(clk_g),
  .enb(1'b1),
  .addrb({Rs1regset,Rs1}),
  .doutb(irfoa),
  .rstb(Rs1==5'd0)
);
regfileRam urf2 (
  .clka(clk_g),
  .ena(state==WRITEBACK),
  .wea(wrirf),
  .addra({Dregset,Rd}),
  .dina(res),
  .clkb(clk_g),
  .enb(1'b1),
  .addrb({Rs2regset,Rs2}),
  .doutb(irfob),
  .rstb(Rs2==5'd0)
);
/*
regfileRam urf3 (
  .clka(clk_g),
  .ena(state==WRITEBACK),
  .wea(wrirf),
  .addra({Dregset,Rd}),
  .dina(res),
  .clkb(clk_g),
  .enb(1'b1),
  .addrb({Rs3regset,Rs3}),
  .doutb(irfoc),
  .rstb(Rs3==5'd0)
);
*/
reg [WID-1:0] sregfile [0:15];		// segment registers
reg [5:0] ASID;
reg wrpagemap;
//wire [12:0] pagemap_ndx;
//wire [8:0] pagemapoa, pagemapo;
//wire [12:0] pagemapa = Rs2==5'd0 ? {WID{1'd0}} : {irfob[19:16],irfob[8:0]};
wire [16:0] pagemap_ndx;
wire [12:0] pagemapoa, pagemapo;
wire [16:0] pagemapa = {ib[20:16],ib[11:0]};
PagemapRam pagemap (
  .clka(clk_g),
  .ena(1'b1),
  .wea(wrpagemap),
  .addra(pagemapa),
  .dina(ia[12:0]),
  .douta(pagemapoa),
  .clkb(clk_g),
  .enb(lcyc),	// reduce power
  .web(1'b0),
  .addrb(pagemap_ndx),
  .dinb(13'h00),
  .doutb(pagemapo)
);
reg bm_set,bm_clear,bm_clearall;
wire pdone;
wire [13:0] pam_pageo;
bitmap upam1 (
	.rst(rst_i),
	.clk(clk_g),
	.set_i(bm_set),
	.clear_i(bm_clear),
	.clearall_i(bm_clearall),
	.bitno_i(ia[13:0]),
	.bitno_o(pam_pageo),
	.done(pdone)
);
reg decto, setto, getto;
wire [31:0] to_out;
wire [31:0] zl_out;
wire to_done;
Timeouter utmo1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.dec_i(decto),
	.set_i(setto),
	.qry_i(getto),
	.tid_i(ia[5:0]),
	.timeout_i(ib),
	.timeout_o(to_out),
	.zeros_o(zl_out),
	.done_o(to_done)
);
reg insrdy, rmvrdy, getrdy, qryrdy;
reg [6:0] iof_cmd;
wire rdy_done, iof_done;
wire [15:0] rdy_out;
wire [6:0] iof_out;
ReadyList url1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.insert_i(insrdy),
	.remove_i(rmvrdy),
	.get_i(getrdy),
	.qry_i(qryrdy),
	.tid_i(ia[5:0]),
	.priority_i(ib[2:0]),
	.tid_o(rdy_out),
	.done_o(rdy_done)
);
IOFocusList uiof1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.cmd_i(iof_done ? iof_cmd : 7'd0),
	.tid_i(ia[5:0]),
	.tid_o(iof_out),
	.done_o(iof_done)
);

reg [FPWID-1:0] fregfile [0:31];		// floating-point register file
reg [WID-1:0] regset;
reg [AMSB:0] pc;			// generic program counter
reg [AMSB:0] ipc;			// pc value at instruction
reg [2:0] rm;
wire [FPWID-1:0] frfoa = fregfile[Rs1];
wire [FPWID-1:0] frfob = fregfile[Rs2];
wire [FPWID-1:0] frfoc = fregfile[Rs3];
always @(posedge clk_g)
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
reg [11:0] pfi_timer;
reg [1:0] edepth;
reg [AMSB:0] mepc [0:3];
reg [31:0] mtimecmp;
reg [63:0] instret;	// instructions completed.
reg [31:0] mcpuid = 32'b100000_00_00000000_00010001_00100001;
reg [31:0] mimpid = 32'h01108000;
(* mark_debug="TRUE" *)
reg [WID-1:0] mcause;
reg [31:0] mstatus;
wire ie = mstatus[0];
wire [1:0] ol = mstatus[2:1];
reg [1:0] olr;
wire mprv = mstatus[16];
reg [AMSB:0] mtvec = 32'hFFFC0000;
reg [31:0] mtdeleg = 32'h0;
reg [31:0] mie;
reg [WID-1:0] mscratch;
reg [AMSB:0] mbadaddr;
wire [31:0] mip;
reg msip;
reg gcip;
assign mip[31:10] = 22'h0;
assign mip[9] = gcip;
assign mip[8] = 1'b0;
assign mip[6:4] = 3'b0;
assign mip[3] = msip;
assign mip[2:0] = 3'b0;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};
reg [WID-1:0] msema;
reg [AMSB:0] htvec = 32'hFFFC0000;
reg [AMSB:0] xra;

function [7:0] fnSelect;
input [6:0] op6;
input [2:0] fn3;
case(op6)
`LOAD:
	case(fn3)
	`LB,`LBU:	fnSelect = 8'h01;
	`LH,`LHU:	fnSelect = 8'h03;
	`LW,`LWU:	fnSelect = 8'h0F;
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
reg [WID-1:0] dati;
reg [WID-1:0] datiH;
wire [WID-1:0] datiL = wb_dat_i >> {ea[1:0],2'b0};
wire [127:0] sdat = (opcode==`STOREF ? fb : ib) << {ea[2:0],3'b0};
wire [7:0] ssel = fnSelect(opcode,funct3) << ea[1:0];


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
	if (irq_i|pe_nmi)
		wfi <= 1'b0;
end

wire fast_access = mprv ? mstatus[5:4]==2'b11 : ol > 2'b00;

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

reg cyc1,cyc2,cyc3;
always @(posedge clk_g)
begin
	cyc1 <= lcyc;
	cyc2 <= cyc1 & lcyc;
	cyc3 <= cyc2 & lcyc;
	cyc_o <= (fast_access ? cyc3 : cyc3) & lcyc;
end

assign pagemap_ndx = {ASID[4:0],ladr[27:16]};
wire [ABWID-1:0] ladr_mapped = {pagemapo,ladr[`LOG_PGSZ-1:0]};


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
	mepc[0] <= 32'hFFFC0200;
	mepc[1] <= 32'hFFFC0200;
	mepc[2] <= 32'hFFFC0200;
	mepc[3] <= 32'hFFFC0200;
	mtvec <= 32'hFFFC0000;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
	lcyc <= LOW;
	wb_stb_o <= LOW;
	wb_we_o <= LOW;
	ladr <= RSTPC;
	wb_dat_o <= 32'h0;
	sr_o <= 1'b0;
	cr_o <= 1'b0;
	// Read address channel
	ARCACHE <= 4'b0011;
	ARPROT <= 3'b000;
	ARLEN <= 8'h00;
	ARSIZE <= 3'b011;
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
	AWSIZE <= 3'b011;
	AWBURST <= 2'b01;
	AWLOCK <= 1'b0;
	AWQOS <= 4'h0;
	AWREGION <= 4'h0;
	// Write data channel
	WLAST <= 1'b1;
	BREADY <= 1'b0;
	instret <= 64'd0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	mstatus <= 6'b001110;
	nmif <= 1'b0;
	ldd <= 1'b0;
	wrpagemap <= 1'b0;
	bm_set <= 1'b0;
	bm_clear <= 1'b0;
	bm_clearall <= 1'b0;
	regset <= {WID{1'b0}};
	regset[9:5] <= 5'h1C;
	regset[4:0] <= 5'h1F;
	Dregset <= 5'h1C;
	Rs1regset <= 5'h1C;
	Rs2regset <= 5'h1C;
	Rs3regset <= 5'h1C;
	setto <= 1'b0;
	getto <= 1'b0;
	decto <= 1'b0;
	insrdy <= 1'b0;
	rmvrdy <= 1'b0;
	getrdy <= 1'b0;
	qryrdy <= 1'b0;
	edepth <= 2'd1;
	iof_cmd <= 7'd0;
	msema <= {WID{1'b0}};
	mcause <= {WID{1'b0}};
	pfi_timer <= 12'd0;
	ilevel <= 16'hFFFF;
	stackdepth <= 16'h0;
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
bm_set <= 1'b0;
bm_clear <= 1'b0;
bm_clearall <= 1'b0;
pfi_timer <= pfi_timer + 2'd1;

if (fast_access)
	wb_adr_o <= ladr;
else begin
	if (ladr[ABWID-1:ABWID-8]==8'hFF)
		wb_adr_o <= ladr;
	else
		wb_adr_o <= {pagemapo,ladr[`LOG_PGSZ-1:0]};
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
		case({regset[4],regset[0]})
		2'b00:	Dregset <= ASID[4:0];
		2'b01:	Dregset <= regset[9:5];
		2'b10:	Dregset <= regset[9:5] > 5'd28 ? regset[9:5]-2'd1 : ASID[4:0];
		2'b11:	Dregset <= regset[9:5];
		endcase
		case({regset[4],regset[1]})
		2'b00:	Rs1regset <= ASID[4:0];
		2'b01:	Rs1regset <= regset[9:5];
		2'b10:	Rs1regset <= regset[9:5] > 5'd28 ? regset[9:5]-2'd1 : ASID[4:0];
		2'b11:	Rs1regset <= regset[9:5];
		endcase
		case({regset[4],regset[2]})
		2'b00:	Rs2regset <= ASID[4:0];
		2'b01:	Rs2regset <= regset[9:5];
		2'b10:	Rs2regset <= regset[9:5] > 5'd28 ? regset[9:5]-2'd1 : ASID[4:0];
		2'b11:	Rs2regset <= regset[9:5];
		endcase
		case({regset[4],regset[3]})
		2'b00:	Rs3regset <= ASID[4:0];
		2'b01:	Rs3regset <= regset[9:5];
		2'b10:	Rs3regset <= regset[9:5] > 5'd28 ? regset[9:5]-2'd1 : ASID[4:0];
		2'b11:	Rs3regset <= regset[9:5];
		endcase
		state <= IFETCH2;
		if (regset[9:5]!=5'h1F) begin
			if (nmif) begin
				nmif <= 1'b0;
				lcyc <= LOW;
				mcause[WID-1] <= 1'b1;
				mcause[7:0] <= 8'd254;
				pc <= mtvec + 8'hFC;
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
				state <= IFETCH;
			end
			/*
			else if (pfi_timer[11]) begin
				pfi_timer <= 12'd0;
				lcyc <= LOW;
				mcause[WID-1] <= 1'b1;
				mcause[7:0] <= 8'd253;
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
				state <= IFETCH;
			end
			*/
	 		else if ((irq_i > ilevel[2:0]) && ie) begin
	 			ilevel <= {ilevel[12:0],irq_i};
				lcyc <= LOW;
				mcause[WID-1] <= 1'b1;
				mcause[7:0] <= cause_i;
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
				state <= IFETCH;
			end
			else if (mip[7] & mie[7] & ie) begin
				lcyc <= LOW;
				mcause[WID-1] <= 1'b1;
				mcause[7:0] <= 8'h01;	// timer IRQ
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
				state <= IFETCH;
			end
			else if (mip[3] & mie[3] & ie) begin
				lcyc <= LOW;
				mcause[WID-1] <= 1'b1;
				mcause[7:0] <= 8'h02;	// software IRQ
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
				state <= IFETCH;
			end
			else begin
				tPC();
			end
		end
		else begin
			tPC();
		end			
	end
IFETCH2:
	begin
		state <= IFETCH3;
		vpa_o <= HIGH;
		lcyc <= HIGH;
		wb_stb_o <= HIGH;
		wb_sel_o <= 8'hFF;
		if (ol==2'b00 && !(pc[31:24]==8'hFF)) begin
			if ((!sregfile[{2'b11,pc[ABWID-1:ABWID-2]}][0]) || pagemapo==12'h000) begin
				vpa_o <= LOW;
				lcyc <= LOW;
				wb_stb_o <= LOW;
				wb_sel_o <= 8'h00;
				mbadaddr <= pc;
				mcause <= 8'h01;	// instruction access fault
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
				state <= IFETCH;
			end
		end
	end
IFETCH3:
	if (ack_i) begin
		vpa_o <= LOW;
		lcyc <= LOW;
		wb_stb_o <= LOW;
		wb_sel_o <= 8'h0;
		tPC();
		ir <= wb_adr_o[2] ? wb_dat_i[63:32] : wb_dat_i[31:0];
		pc <= pc + 3'd4;
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
		if (ir==`PFI && irq_i != 1'b0) begin
			pfi_timer <= 12'd0;
			// Ignore poll if already stacked too deep.
			if (regset[6:5]!=2'b11) begin
				mcause[WID-1] <= 1'b1;
				mcause[7:0] <= cause_i;
				mepc[edepth] <= pc;
				edepth <= edepth + 2'd1;
				pc <= mtvec + {mstatus[2:1],6'h00};
				mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
				tNextRs();
			end
			state <= IFETCH;
		end
		// Set some sensible decode defaults
		Rd <= 5'd0;
		displacement <= 64'd0;
		// Override defaults
		case(opcode)
		`AUIPC,`LUI:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {ir[31:12],12'd0};
				wrirf <= 1'b1;
			end
		`JAL:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {{WID-21{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
				wrirf <= 1'b1;
			end
		`JALR:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {{WID-12{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`LOAD:
			begin
				Rd <= ir[11:7];
				imm <= {{WID-12{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`LOADF:
			begin
				Rd <= ir[11:7];
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
						case(funct7)
						7'd1:	wrirf <= 1'b1;
						7'd2:	wrirf <= 1'b1;
						7'd4:	wrirf <= 1'b1;
						7'd9:	wrirf <= 1'b1;
						7'd10:	wrirf <= 1'b1;
						7'd14:	wrirf <= 1'b1;
						7'd15:	wrirf <= 1'b1;
						7'd18:	wrirf <= 1'b1;
						7'd19:	wrirf <= 1'b1;
						default:	;
						endcase
					end
				endcase
			end
		7'd19:
			begin
				case(funct3)
				3'd0:	imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd1: imm <= WID==64 ? ir[25:20] : ir[24:20];
				3'd2:	imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd3: imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd4: imm <= {{WID-12{ir[31]}},ir[31:20]};
				3'd5: imm <= WID==64 ? ir[25:20] : ir[24:20];
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
		// LUI instructions don't need register data, so they are executed
		// right away in the regfetch stage.
		case(opcode)
		`LUI:	begin res <= imm; state <= WRITEBACK; end
		`AUIPC:	begin res <= ipc + imm; state <= WRITEBACK; end
		default:	;
		endcase
	end
REGFETCH2:
	begin
		state <= EXECUTE;
		ia <= irfoa;
		ib <= irfob;
		fa <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
		case(opcode)
		`FLOAT:
			case(funct5)
			`FCVT2F:
				fa <= irfoa;
			default:	fa <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
			endcase
		7'd13:
			case(funct3)
			3'd0:
				case(funct7)
				7'd1:	state <= REGFETCH3;
				default:	;
				endcase
			default:	;
			endcase
		7'd115:
			case(funct3)
			3'd5,3'd6,3'd7:	ia <= {59'd0,ir[19:15]};
			default:	;
			endcase
		default:	;
		endcase
		fb <= Rs2==5'd0 ? {FPWID{1'd0}} : frfob;
		fc <= Rs3==5'd0 ? {FPWID{1'd0}} : frfoc;
	end
REGFETCH3:	state <= REGFETCH4;
REGFETCH4:	state <= REGFETCH5;
REGFETCH5:	state <= EXECUTE;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// Execute the instruction.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXECUTE:
	begin
		state <= WRITEBACK;
		case(opcode)
		7'd13:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:	begin res <= sregfile[ib[3:0]]; illegal_insn <= 1'b0; end
				7'd1:	begin res <= {51'd0,pagemapoa}; if (|Rs1) wrpagemap <= 1'b1; illegal_insn <= 1'b0; end
				//7'd2:	begin res <= ia; illegal_insn <= 1'b0; end
				7'd4:	
					begin
						bm_set <= 1'b1;
						state <= PAM;
						illegal_insn <= 1'b0;
					end
				7'd5:
					begin
						bm_clear <= 1'b1;
						state <= PAM;
						illegal_insn <= 1'b0;
					end
				7'd6:
					begin
						bm_clearall <= 1'b1;
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
				7'd15:
					begin
						qryrdy <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd16,7'd17,7'd18,7'd19:
					begin
						iof_cmd <= funct7;
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
				7'd0:	begin res <= ia << imm[5:0]; illegal_insn <= 1'b0; end
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
							res <= (ia >> imm[5:0]) | ~({WID{1'b1}} >> imm[5:0]);
						else
							res <= ia >> imm[5:0];
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
				msema[1] <= 1'b0;
			end
		`JALR:
			begin
				res <= pc;
				pc <= ia + imm;
				pc[0] <= 1'b0;
				msema[1] <= 1'b0;
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
				wb_sel_o <= ssel[7:0];
				tEA();
				ARID <= 4'h1;
				state <= MEMORY;
			end
		`STORE:
			begin
				lcyc <= HIGH;
				wb_we_o <= HIGH;
				wb_sel_o <= ssel[7:0];
				tEA();
				wb_dat_o <= sdat[63:0];
				case(funct3)
				3'd0,3'd1,3'd2,3'd3:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY;
			end
		`LOADF:
			begin
				lcyc <= HIGH;
				wb_sel_o <= ssel[7:0];
				tEA();
				ARID <= 4'h1;
				state <= MEMORY;
			end
		`STOREF:
			begin
				lcyc <= HIGH;
				wb_we_o <= HIGH;
				wb_sel_o <= ssel[7:0];
				tEA();
				wb_dat_o <= sdat[63:0];
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
						if (regset[9:5] != 5'h1F) begin
							msema[1] <= 1'b0;
							pc <= mtvec + {mstatus[2:1],6'h00};
							mepc[edepth] <= pc;
							edepth <= edepth + 2'd1;
							mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
							mcause <= 4'h3;
							tNextRs();
						end
						illegal_insn <= 1'b0;
						state <= IFETCH;
						instret <= instret + 2'd1;
					end
				`ECALL:
					begin
						if (regset[9:5] != 5'h1F) begin
							msema[1] <= 1'b0;
							pc <= mtvec + {mstatus[2:1],6'h00};
							mepc[edepth] <= pc;
							edepth <= edepth + 2'd1;
							mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
							mcause <= 4'h8 + mstatus[2:1];
							tNextRs();
						end
						illegal_insn <= 1'b0;
						state <= IFETCH;
						instret <= instret + 2'd1;
					end
				// The other half of ERET is in WRITEBACK stage
				`ERET:
					begin
						msema[0] <= 1'b0;
						olr <= ol;	// mstatus change will change ol
						if (ol > 2'b00) begin
							ilevel <= {4'hF,ilevel[14:3]};
							edepth <= edepth - 2'd1;
							mstatus[11:0] <= {2'b00,1'b1,mstatus[11:3]};
							tPrevRs();
							illegal_insn <= 1'b0;
						end
					end
				`WFI:
					begin
						set_wfi <= 1'b1;
						illegal_insn <= 1'b0;
					end
				`PFI:
					begin
						pfi_timer <= 12'd0;
						illegal_insn <= 1'b0;
					end
				`HALT:
					state <= EXECUTE;
				default:
					begin
					case(funct3)
					3'd1,3'd2,3'd3,3'd5,3'd6,3'd7:
						casez(ir[31:20])
						12'h001:	begin res <= fscsr[4:0]; illegal_insn <= 1'b0; end
						12'h002:	begin res <= rm; illegal_insn <= 1'b0; end
						12'h003:	begin res <= fscsr; illegal_insn <= 1'b0; end
						12'h181:	begin res <= ASID; illegal_insn <= 1'b0; end
						12'h201:	if (ol > 2'b01) begin res <= htvec; illegal_insn <= 1'b0; end
						12'h300:	if (ol > 2'b10) begin res <= mstatus; illegal_insn <= 1'b0; end
						12'h301:	if (ol > 2'b10) begin res <= mtvec; illegal_insn <= 1'b0; end
						12'h302:	if (ol > 2'b10) begin res <= mtdeleg; illegal_insn <= 1'b0; end
						12'h304:	if (ol > 2'b10) begin res <= mie; illegal_insn <= 1'b0; end
						12'h321:	if (ol > 2'b10) begin res <= mtimecmp; wc_time_irq_clr <= 6'h3F; illegal_insn <= 1'b0; end
						12'h340:	if (ol > 2'b10) begin res <= mscratch; illegal_insn <= 1'b0; end
						12'h341:	if (ol > 2'b10) begin res <= mepc[0]; illegal_insn <= 1'b0; end
						12'h342:	if (ol > 2'b10) begin res <= mcause; illegal_insn <= 1'b0; end
						12'h343:	if (ol > 2'b10) begin res <= mbadaddr; illegal_insn <= 1'b0; end
						12'h344:	if (ol > 2'b10) begin res <= mip; illegal_insn <= 1'b0; end
						12'h701:	if (ol > 2'b10) begin res <= wc_times[31:0]; illegal_insn <= 1'b0; end
						12'h741:	if (ol > 2'b10) begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
						12'hC00:	begin res <= tick[31: 0]; illegal_insn <= 1'b0; end
						12'hC01:	begin res <= wc_times[31:0]; illegal_insn <= 1'b0; end
						12'hC02:	begin res <= instret[31: 0]; illegal_insn <= 1'b0; end
						12'hC80:	begin res <= tick[63:32]; illegal_insn <= 1'b0; end
						12'hC81:	begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
						12'hC82:	begin res <= instret[63:32]; illegal_insn <= 1'b0; end
						12'hD01:	if (ol > 2'b00) begin res <= wc_times[31:0]; illegal_insn <= 1'b0; end
						12'hE01:	if (ol > 2'b01) begin res <= wc_times[31:0]; illegal_insn <= 1'b0; end
						12'h790:	begin res <= regset; illegal_insn <= 1'b0; end
						12'h791:	begin res <= mepc[edepth-2'd1]; illegal_insn <= 1'b0; end
						12'h792:	begin res <= msema; illegal_insn <= 1'b0; end
						12'h793:	begin res <= xra; illegal_insn <= 1'b0; end
						12'h794:	begin if (ol > 2'b00) res <= ilevel; illegal_insn <= 1'b0; end
						12'h795:	begin if (ol > 2'b00) res <= stackdepth; illegal_insn <= 1'b0; end
						12'hF00:	if (ol > 2'b10) begin res <= mcpuid; illegal_insn <= 1'b0; end	// cpu description
						12'hF01:	if (ol > 2'b10) begin res <= mimpid; illegal_insn <= 1'b0; end // implmentation id
						12'hF10:	if (ol > 2'b10) begin res <= hartid_i; illegal_insn <= 1'b0; end
						default:	;
						endcase
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
	begin
		res <= {50'h0,pam_pageo};
		if (pdone)
			state <= WRITEBACK;
	end
TMO:
	begin
		getto <= 1'b0;
		setto <= 1'b0;
		insrdy <= 1'b0;
		rmvrdy <= 1'b0;
		getrdy <= 1'b0;
		qryrdy <= 1'b0;
		iof_cmd <= 7'd0;
		if (to_done&rdy_done&iof_done) begin
			illegal_insn <= 1'b0;
			case(funct7)
			7'd9:		res <= to_out;
			7'd10:	res <= zl_out;
			7'd14:	res <= {{48{rdy_out[15]}},rdy_out};
			7'd15:	res <= {{48{rdy_out[15]}},rdy_out};
			7'd18:	res <= {{57{iof_out[6]}},iof_out};
			7'd19:	res <= {{57{iof_out[6]}},iof_out};
			default:	res <= 64'd0;
			endcase
			state <= WRITEBACK;
		end
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
MEMORY:		state <= MEMORY1a;
MEMORY1a:	state <= MEMORY1b;
MEMORY1b:
	begin
		wb_stb_o <= HIGH;
		state <= MEMORY1c;
		if (ol==2'b00 && ea[ABWID-1:ABWID-8]!=8'hFF) begin
			if ((!sregfile[segsel][1] & wb_we_o) || pagemapo==12'h000) begin
				tAccessFault(8'h07);	// store access fault
			end
			else if ((!sregfile[segsel][2] & !wb_we_o) || pagemapo==12'h000) begin
				tAccessFault(8'h05);	// load access fault
			end
		end
	end
MEMORY1c:
	if (ack_i) begin
		wb_stb_o <= LOW;
		if (ssel[7:4]==4'h0) begin
			lcyc <= LOW;
			wb_we_o <= LOW;
			wb_sel_o <= 4'h0;
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
				3'd3: begin res <= wb_dat_i; illegal_insn <= 1'b0; end
				3'd4:	begin res <= {56'd0,datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd5:	begin res <= {48'd0,datiL[15:0]}; illegal_insn <= 1'b0; end
				3'd6: begin res <= {32'd0,datiL[31:0]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			`LOADF:	begin res <= wb_dat_i; illegal_insn <= 1'b0; end
			endcase
		end
		else
			state <= MEMORY2;
		dati[WID-1:0] <= wb_dat_i;
	end
// Run a second bus cycle to handle unaligned access.
MEMORY2:
	if (~ack_i) begin
		wb_sel_o <= ssel[7:4];
		ladr <= {ladr[31:2]+2'd1,2'd0};
		wb_dat_o <= sdat[63:32];
		state <= MEMORY2a;
	end
MEMORY2a:	state <= MEMORY2b;
MEMORY2b:
	begin
		wb_stb_o <= HIGH;
		state <= MEMORY2_ACK;
	end
MEMORY2_ACK:
	if (ack_i) begin
		datiH <= wb_dat_i;
		lcyc <= LOW;
		wb_stb_o <= LOW;
		wb_we_o <= LOW;
		wb_sel_o <= 4'h0;
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
				3'd1: begin res <= {{16{datiH[7]}},datiH[7:0],dati[31:24]}; illegal_insn <= 1'b0; end
				3'd2:
					case(ea[1:0])
					2'd1:	begin res <= {{32{datiH[7]}},datiH[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
					2'd2:	begin res <= {{32{datiH[15]}},datiH[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
					2'd3:	begin res <= {{32{datiH[23]}},datiH[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				3'd5:	begin res <= {16'd0,datiH[7:0],dati[31:24]}; illegal_insn <= 1'b0; end
				3'd6:
					case(ea[1:0])
					2'd1:	begin res <= {datiH[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
					2'd2:	begin res <= {datiH[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
					2'd3:	begin res <= {datiH[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				default:	;
				endcase
			end
		`LOADF:
			begin
				case(ea[1:0])
				2'd1:	begin res <= {datiH[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
				2'd2:	begin res <= {datiH[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
				2'd3:	begin res <= {datiH[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
		endcase
	end
MEMORY4:
	state <= WRITEBACK;
AXI_MEMORY_READ:
	if (ARREADY) begin
		state <= AXI_MEMORY_READ2;
	end
AXI_MEMORY_READ2:
	begin
		// Master can assert RREADY before RVALID
		RREADY <= 1'b1;
		if (RVALID && RID==4'h1) begin
			if (ssel[7:4]==4'h0) begin
				case(opcode)
				`LOAD:
					case(funct3)
					3'd0:	begin res <= {{56{datiL[7]}},datiL[7:0]}; illegal_insn <= 1'b0; end
					3'd1: begin res <= {{48{datiL[15]}},datiL[15:0]}; illegal_insn <= 1'b0; end
					3'd2:	begin res <= {{32{datiL[31]}},datiL[31:0]}; illegal_insn <= 1'b0; end
					3'd3: begin res <= RDATA; illegal_insn <= 1'b0; end
					3'd4:	begin res <= {56'd0,datiL[7:0]}; illegal_insn <= 1'b0; end
					3'd5:	begin res <= {48'd0,datiL[15:0]}; illegal_insn <= 1'b0; end
					3'd6: begin res <= {32'd0,datiL[31:0]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				`LOADF:	begin res <= RDATA; illegal_insn <= 1'b0; end
				endcase
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
				wb_adr_o <= {wb_adr_o[AMSB:2]+2'd1,2'd0};
				state <= AXI_MEMORY_READ3;
			end
		end
	end
AXI_MEMORY_READ3:
	if (ARREADY) begin
		state <= AXI_MEMORY_READ4;
	end
AXI_MEMORY_READ4:
	begin
	RREADY <= 1'b1;
	if (RVALID && RID==4'h2) begin
		state <= WRITEBACK;
		case(opcode)
		`LOAD:
			begin
				case(funct3)
				3'd1: begin res <= {{48{datiH[7]}},datiH[7:0],dati[31:24]}; illegal_insn <= 1'b0; end
				3'd2:
					case(ea[1:0])
					2'd1:	begin res <= {{32{datiH[7]}},datiH[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
					2'd2:	begin res <= {{32{datiH[15]}},datiH[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
					2'd3:	begin res <= {{32{datiH[23]}},datiH[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				3'd5:	begin res <= {16'd0,datiH[7:0],dati[31:24]}; illegal_insn <= 1'b0; end
				3'd6:
					case(ea[1:0])
					2'd1:	begin res <= {32'd0,datiH[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
					2'd2:	begin res <= {32'd0,datiH[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
					2'd3:	begin res <= {32'd0,datiH[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
					default:	;
					endcase
				default:	;
				endcase
			end
		`LOADF:
			begin
				case(ea[1:0])
				2'd1:	begin res <= {datiH[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
				2'd2:	begin res <= {datiH[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
				2'd3:	begin res <= {datiH[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
		endcase
	end
	end

AXI_MEMORY_WRITE:
	if (AWREADY & WREADY) begin
		AWVALID <= 1'b0;
		WVALID <= 1'b0;				
		state <= AXI_MEMORY_WRITE2;
	end
AXI_MEMORY_WRITE2:
	if (BVALID && BID==4'h1) begin
		BREADY <= HIGH;
		if (ssel[7:4]==4'h00)
			state <= WRITEBACK;
		else begin
			AWID <= 4'h2;
			AWVALID <= 1'b1;
			wb_adr_o <= {wb_adr_o[31:2]+2'd1,2'd0};
			WSTRB <= ssel[7:4];
			WDATA <= sdat[63:32];
			WVALID <= 1'b1;
			state <= AXI_MEMORY_WRITE3;
		end
	end
AXI_MEMORY_WRITE3:
	if (AWREADY & WREADY) begin
		AWVALID <= LOW;
		WVALID <= LOW;				
		state <= AXI_MEMORY_WRITE4;
	end
AXI_MEMORY_WRITE4:
	if (BVALID && BID==4'h2) begin
		BREADY <= HIGH;
		state <= WRITEBACK;
	end
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
							res <= 64'h7FFFFFFFFFFFFFFF;	// canonical NaN
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
		ARVALID <= LOW;
		AWVALID <= LOW;
		RREADY <= LOW;	// end read cycle
		BREADY <= LOW;	// end write cycle
		if (illegal_insn) begin
			tIllegal();
		end
		set_wfi <= 1'b0;
		if (!illegal_insn && opcode==7'd13) begin
			case(funct3)
			3'd0:
				if (Rs1 != 5'd0)
				case(funct7)
				7'd0:		sregfile[ib[3:0]] <= ia;
				7'd1:		begin res <= {51'd0,pagemapoa}; wrpagemap <= 1'b1; end
				default:	;
				endcase
			default:	;
			endcase
		end
		if (!illegal_insn && opcode==7'd115) begin
			case(ir)
			`ERET:
				if (olr > 2'b00) begin
					pc <= mepc[edepth];
				end
				else
					tIllegal();
			default:	;
			endcase
			case(funct3)
			3'd1,3'd5:
				if (Rs1!=5'd0)
				case(ir[31:20])
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
				12'h181:	begin if (ol > 2'b10) ASID <= ia; end
				12'h300:	begin if (ol > 2'b10) mstatus <= ia; end
				12'h301:	begin if (ol > 2'b10) mtvec <= {ia[31:2],2'b0}; end
				12'h304:	begin if (ol > 2'b10) mie <= ia; end
				12'h321:	begin if (ol > 2'b10) mtimecmp <= ia; end
				12'h340:	begin if (ol > 2'b10) mscratch <= ia; end
				12'h341:	begin if (ol > 2'b10) mepc[0] <= ia; end
				12'h342:	begin if (ol > 2'b10) mcause <= ia; end
				12'h343:  begin if (ol > 2'b10) mbadaddr <= ia; end
				12'h344:	begin if (ol > 2'b10) msip <= ia[3]; end
				12'h790:	begin 
										if (ol > 2'b10) begin
											regset <= ia;
										end
									end
				12'h791:	begin if (ol > 2'b10) mepc[edepth-2'd1] <= ia; end
				12'h792:	begin if (ol > 2'b10) msema <= ia; end
				12'h793:	begin if (ol > 2'b10) xra <= ia; end
				12'h794:	begin if (ol > 2'b10) ilevel <= ia; end
				12'h795:	begin if (ol > 2'b10) stackdepth <= ia; end
				default:	;
				endcase
			3'd2,3'd6:
				case(ir[31:20])
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
				12'h300:	if (ol > 2'b10) mstatus <= mstatus | ia;
				12'h304:	if (ol > 2'b10) mie <= mie | ia;
				12'h344:	if (ol > 2'b10) msip <= msip | ia[3];
				12'h790:	if (ol > 2'b10) begin
										regset <= regset | ia;
									end
				12'h792:	if (ol > 2'b10) msema <= msema | ia;
				12'h794:	if (ol > 2'b10) ilevel <= ilevel | ia;
				default: ;
				endcase
			3'd3,3'd7:
				case(ir[31:20])
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
				12'h300:	if (ol > 2'b10) mstatus <= mstatus & ~ia;
				12'h304:	if (ol > 2'b10) mie <= mie & ~ia;
				12'h344:	if (ol > 2'b10) msip <= msip & ~ia[3];
				12'h790:	if (ol > 2'b10) begin
										regset <= regset & ~ia;
									end
				12'h792:	if (ol > 2'b10) msema <= msema & ~ia;
				12'h794:	if (ol > 2'b10) ilevel <= ilevel & ~ia;
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
	if ((mprv ? mstatus[5:4]==2'b11 : ol > 2'b00) || ea[31:24]==8'hFF)
		ladr <= ea;
	else begin
		ladr <= ea[ABWID-5:0] + {sregfile[segsel][WID-1:4],{`LOG_PGSZ{1'b0}}};
	end
end
endtask

task tPC;
begin
	if (ol > 2'b00 || pc[31:24]==8'hFF)
		ladr <= pc;
	else begin
		ladr <= pc[ABWID-3:0] + {sregfile[{2'b11,pc[ABWID-1:ABWID-2]}][WID-1:4],{`LOG_PGSZ{1'b0}}};
	end
end
endtask

task tIllegal;
begin
	pc <= mtvec + {mstatus[2:1],6'h00};
	mepc[edepth] <= ipc;
	edepth <= edepth + 2'd1;
	mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
	mcause <= 4'h2;
	illegal_insn <= 1'b0;
end
endtask

task tNextRs;
begin
	stackdepth <= stackdepth + 2'd1;
	if (regset[6:5]!=2'b11) begin
		regset[6:5] <= regset[6:5] + 2'd1;
	end
end
endtask

task tPrevRs;
begin
	stackdepth <= stackdepth - 2'd1;
	if (regset[6:5]!=2'b00) begin
		regset[6:5] <= regset[6:5] - 2'd1;
	end
end
endtask

task tAccessFault;
input [7:0] caus;
begin
	mcause <= caus;
	mbadaddr <= ea;
	mepc[edepth] <= pc;
	edepth <= edepth + 2'd1;
	pc <= mtvec + {mstatus[2:1],6'h00};
	mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
	tNextRs();
	lcyc <= LOW;
	wb_stb_o <= LOW;
	wb_we_o <= LOW;
	ARVALID <= LOW;
	AWVALID <= LOW;
	WVALID <= LOW;
	state <= IFETCH;
end
endtask

endmodule
