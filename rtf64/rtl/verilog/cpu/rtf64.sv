// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64.sv
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

`define BRK   8'h00
`define R3A   8'h01
`define R2    8'h02
`define R3B   8'h03
`define ADD   8'h04
`define SUB   8'h05
`define SUBF  8'h05
`define MUL   8'h06
`define CMP   8'h07
`define CMP_CPY   3'd0
`define CMP_AND   3'd1
`define CMP_OR    3'd2
`define CMP_ANDCM 3'd3
`define CMP_ORCM  3'd4
`define AND   8'h08
`define OR    8'h09
`define EOR   8'h0A
`define BIT   8'h0B
`define SHIFT 8'h0C
`define SET   8'h0D
`define MULU  8'h0E
`define CSR   8'h0F
`define DIV   8'h10
`define DIVU  8'h11
`define DIVSU 8'h12
`define R2B   8'h13
`define MULSU 8'h16
`define PERM  8'h17
`define REM   8'h18
`define REMU  8'h19
`define BYTNDX  8'h1A
`define WYDNDX  8'h1B
`define EXT   8'h1C
`define DEP   8'h1D
`define DEPI  8'h1E
`define REMSU 8'h21
`define SEQ   8'h26
`define SNE   8'h27
`define SLT   8'h28
`define SGE   8'h29
`define SLE   8'h2A
`define SGT   8'h2B
`define SLTU  8'h2C
`define SGEU  8'h2D
`define SLEU  8'h2E
`define SGTU  8'h2F
`define JSR   8'h30
`define JMP   8'h31
`define RTS   8'h34
`define RTE   8'h35
`define BEQ   8'h36
`define BNE   8'h37
`define BMI   8'h38
`define BPL   8'h39
`define BLE   8'h3A
`define BGT   8'h3B
`define BLTU  8'h3C
`define BGEU  8'h3D
`define BLEU  8'h3E
`define BGTU  8'h3F
`define BVS   8'h40
`define BVC   8'h41
`define BOD   8'h42
`define BPS   8'h44
`define BCS   8'h3C
`define BCC   8'h3D
`define LMI   8'b01001???
`define LUI   8'b010100??
`define AUIPC 8'b010101??
`define GCSUB 8'h75
`define OSR2  8'h7A
`define CACHE 8'h7B
`define REX     5'h08
`define LDB   8'h80
`define LDBU  8'h81
`define LDW   8'h82
`define LDWU  8'h83
`define LDT   8'h84   
`define LDTU  8'h85
`define LDO   8'h86
`define LDOR  8'h87
`define LDX   8'h8F
`define STB   8'hA0
`define STW   8'hA1
`define STT   8'hA2
`define STO   8'hA3
`define STOC  8'hA4
`define STPTR 8'hA5
`define STX   8'hAF

// Shift operations
`define ASL   4'h0
`define LSR   4'h1
`define ROL   4'h2
`define ROR   4'h3
`define ASR   4'h5
`define ASLI  4'h8
`define LSRI  4'h9
`define ROLI  4'hA
`define RORI  4'hB
`define ASRI  4'hC
// 1r operations
`define CNTLZR1 5'h00
`define CNTLOR1 5'h01
`define CNTPOPR1  5'h02
`define COMR1   5'h03
`define NOTR1   5'h04
`define NEGR1   5'h05

// 2r operations
`define ANDR2   5'h00
`define ORR2    5'h01
`define EORR2   5'h02
`define BMMR2   5'h03
`define ADDR2   5'h04
`define SUBR2   5'h05
`define MULR2   5'h06
`define CMPR2   5'h07
`define NANDR2  5'h08
`define NORR2   5'h09
`define ENORR2  5'h0A
`define BITR2   5'h0B
`define R1      5'h0C
`define MOV     5'h0D
`define MULUR2  5'h0E
`define MULHR2  5'h0F
`define DIVR2   5'h10
`define DIVUR2  5'h11
`define DIVSUR2 5'h12
`define REMR2   5'h13
`define REMUR2  5'h14
`define REMSUR2 5'h15
`define MULSUR2 5'h16
`define PERMR2  5'h17
`define PTRDIFR2  5'h18
`define DIFR2   5'h19
`define BYTNDX  5'h1A
`define WYDNDX  5'h1B
`define MULSUHR2 5'h1D
`define MULUHR2 5'h1E
`define RGFR2   5'h1F

// 2r set operations
`define SEQR2   3'd0
`define SNER2   3'd1
`define SLTR2   3'd4
`define SGER2   3'd5
`define SLTUR2  3'd6
`define SGEUR2  3'd7

// 3r operations
`define MINR3A 3'h0
`define MAXR3A 3'h1
`define MAJR3A 3'h2
`define MUXR3A 3'h3
`define ADDR3A 3'h4
`define SUBR3A 3'h5
`define FLIPR3A  3'h7
`define ANDR3B 3'h0
`define ORR3B  3'h1
`define EORR3B 3'h2
`define DEPR3B   3'h3
`define EXTR3B   3'h4
`define EXTUR3B  3'h5
`define BLENDR3B 3'h6
`define RGFR3B   3'h7

// 2r Loads
`define LDBX   5'd0
`define LDBUX  5'd1
`define LDWX   5'd2
`define LDWUX  5'd3
`define LDTX   5'd4
`define LDTUX  5'd5
`define LDOX   5'd6
`define LDORX 5'd7

// 2r Stores
`define STBX    5'd0
`define STWX    5'd1
`define STTX    5'd2
`define STOX    5'd3
`define STOCX   5'd4
`define STPTRX  5'd5

`define FLOAT   8'hF2
`define FMA     8'hF4
`define FMS     8'hF5
`define FNMA    8'hF6
`define FNMS    8'hF7
`define FMIN    8'hF8
`define FMAX    8'hF9
`define FADD      5'h04
`define FSUB      5'h05
`define FMUL      5'h08
`define FDIV      5'h09
`define FCMP      5'h10
`define FSQRT     5'h0D

`define SEG_SHIFT   14'd0

`include "../fpu/fpConfig.sv"

module rtf64(hartid_i, rst_i, clk_i, wc_clk_i, nmi_i, irq_i, cause_i, vpa_o, cyc_o, stb_o, ack_i, sel_o, we_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i);
parameter WID = 64;
parameter AWID = 32;
parameter FPWID = 64;
parameter RSTPC = 32'hFFFC0100;
input [7:0] hartid_i;
input rst_i;
input clk_i;
input wc_clk_i;
input nmi_i;
input irq_i;
input [7:0] cause_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
output reg sr_o;
output reg cr_o;
input rb_i;

parameter LOW = 1'b0;
parameter HIGH = 1'b1;

integer n;
reg [5:0] state;
parameter IFETCH1 = 6'd1;
parameter IFETCH2 = 6'd2;
parameter IFETCH3 = 6'd3;
parameter IFETCH4 = 6'd4;
parameter DECODE = 6'd5;
parameter REGFETCH1 = 6'd6;
parameter REGFETCH2 = 6'd7;
parameter EXECUTE = 6'd8;
parameter WRITEBACK = 6'd9;
parameter MEMORY1 = 6'd11;
parameter MEMORY2 = 6'd12;
parameter MEMORY3 = 6'd13;
parameter MEMORY4 = 6'd14;
parameter MEMORY5 = 6'd15;
parameter MEMORY6 = 6'd16;
parameter MEMORY7 = 6'd17;
parameter MEMORY8 = 6'd18;
parameter MEMORY9 = 6'd19;
parameter MEMORY10 = 6'd20;
parameter MEMORY11 = 6'd21;
parameter MEMORY12 = 6'd22;
parameter MEMORY13 = 6'd23;
parameter MEMORY14 = 6'd24;
parameter MEMORY15 = 6'd25;
parameter MUL1 = 6'd26;
parameter MUL2 = 6'd27;
parameter PAM	 = 6'd28;
parameter TMO = 6'd29;
parameter PAGEMAPA = 6'd30;
parameter CSR1 = 6'd31;
parameter CSR2 = 6'd32;
parameter DATA_ALIGN = 6'd33;

`include "../fpu/fpSize.sv"

reg [31:0] pc, ipc, ret_pc;
reg [31:0] ra [0:63]; // ra0 = 0-31, ra1 = 32 to 63
reg illegal_insn;
reg [31:0] ir;
wire [7:0] opcode = ir[7:0];
wire [2:0] mop = ir[12:10];
wire [2:0] rm3 = ir[31:29];
reg [4:0] Rd;
reg [1:0] Cd;
wire [4:0] Rs1 = ir[17:13];
wire [4:0] Rs2 = ir[22:18];
wire [4:0] Rd3 = ir[27:23];
reg [4:0] Rdx, Rs1x, Rs2x, Rs3x;
reg [4:0] Rdx1, Rs1x1, Rs2x1, Rs3x1;
wire [63:0] irfoRs1, irfoRs2, irfoRs3, irfoRd;
reg [63:0] ia,ib,ic,id,imm;
reg [63:0] fa, fb, fc;
reg [64:0] res;
reg [7:0] crres;
reg wrirf,wrcrf,wrcrf32,wrfrf;
wire memmode, UserMode, SupervisorMode, HypervisorMode, MachineMode, InterruptMode, DebugMode;

// It takes 6 block rams to get triple output ports with 32 sets of 32 regs.

regfile64 uirfRs1 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrirf),      // input wire [0 : 0] wea
  .addra({Rdx,Rd}),  // input wire [9 : 0] addra
  .dina(res[63:0]),    // input wire [63 : 0] dina
  .douta(irfoRd),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs1x,Rs1}),  // input wire [9 : 0] addrb
  .dinb(64'd0),    // input wire [63 : 0] dinb
  .doutb(irfoRs1)  // output wire [63 : 0] doutb
);

regfile64 uirfRs2 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrirf),      // input wire [0 : 0] wea
  .addra({Rdx,Rd}),  // input wire [9 : 0] addra
  .dina(res[63:0]),    // input wire [63 : 0] dina
  .douta(),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs2x,Rs2}),  // input wire [9 : 0] addrb
  .dinb(64'd0),    // input wire [63 : 0] dinb
  .doutb(irfoRs2)  // output wire [63 : 0] doutb
);

regfile64 uirfRs3 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrirf),      // input wire [0 : 0] wea
  .addra({Rdx,Rd}),  // input wire [9 : 0] addra
  .dina(res[63:0]),    // input wire [63 : 0] dina
  .douta(),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs3x,Rs3}),  // input wire [9 : 0] addrb
  .dinb(64'd0),    // input wire [63 : 0] dinb
  .doutb(irfoRs3)  // output wire [63 : 0] doutb
);

reg [31:0] cregfile [0:31];
reg [31:0] sregfile [0:15];
wire [64:0] difi = ia - imm;
wire [64:0] difr = ia - ib;
wire [63:0] andi = ia & imm;
wire [63:0] andr = ia & ib;
wire [63:0] biti = andi;
wire [63:0] bitr = andr;

wire [15:0] blendR1 = ia[23:16] * ic[7:0];
wire [15:0] blendG1 = ia[15: 8] * ic[7:0];
wire [15:0] blendB1 = ia[ 7: 0] * ic[7:0];
wire [15:0] blendR2 = ib[23:16] * ~ic[7:0];
wire [15:0] blendG2 = ib[15: 8] * ~ic[7:0];
wire [15:0] blendB2 = ib[ 7: 0] * ~ic[7:0];

wire [31:0] cd32 = cregfile[Rdx];
wire [31:0] cds32 = cregfile[Rs1x];
always @(posedge clk_g)
  if (state==WRITEBACK)
    if (wrcrf)
      case(Cd)
      2'd0: cregfile[Rdx] <= {cd32[31:8],crres[7:0]};
      2'd1: cregfile[Rdx] <= {cd32[31:16],crres[7:0],cd32[7:0]};
      2'd2: cregfile[Rdx] <= {cd32[31:24],crres[7:0],cd32[15:0]};
      2'd3: cregfile[Rdx] <= {crres[7:0],cd32[23:0]};
      endcase
    else if (wrcrf32)
      cregfile[Rdx] <= res[31:0];
wire [7:0] cd = cd32 >> {Cd,3'b0};
wire [7:0] cds = cds32 >> {Rs1[1:0],3'b0};

// CSRs
reg [7:0] cause [0:7];
reg [31:0] tvec [0:7];
reg [31:0] badaddr [0:7];
reg [31:0] status [0:7];
wire mprv = status[5][17];
wire uie = status[5][0];
wire sie = status[5][1];
wire hie = status[5][2];
wire mie = status[5][3];
wire iie = status[5][4];
wire die = status[5][5];
reg [31:0] gcie;
reg [63:0] scratch [0:7];
reg [39:0] instret;
reg [31:0] epc [0:31];
reg [31:0] next_epc;
reg [31:0] pmStack;
reg [31:0] rsStack;
reg [4:0] rprv;
reg [4:0] ASID;
reg [23:0] TaskId;
reg [5:0] gcloc;    // garbage collect lockout count
reg [2:0] mrloc;    // mret lockout
reg [31:0] uip;     // user interrupt pending
reg [4:0] regset;
reg [31:0] rsStack;
wire [4:0] crs = rsStack[4:0];
reg [31:0] pmStack;
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi = 1'b0;
reg [31:0] mtimecmp;
reg [63:0] instret;	// instructions completed.
reg [31:0] mcpuid = 32'b000000_00_00000000_00010001_00100001;
reg [31:0] mimpid = 32'h01108000;
reg [31:0] uip;
reg [31:0] mscratch;
reg [31:0] mbadaddr;
reg [31:0] usema, msema;
wire [31:0] mip;
reg msip, ugip;
assign mip[31:8] = 24'h0;
assign mip[7] = 1'b0;
assign mip[6:4] = 3'b0;
assign mip[3] = msip;
assign mip[2:1] = 2'b0;
assign mip[0] = ugip;
reg [2:0] rm;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};
reg [15:0] mtid;      // task id
wire ie = pmStack[0];
reg [31:0] miex;
// Debug
reg [31:0] dbadr [0:3];
reg [63:0] dbcr;
reg [3:0] dbsr;

reg setto, getto, decto, getzl, popto;
reg pushq, popq, peekq; 

reg [31:0] ladr;
reg wrpagemap;
wire [13:0] pagemapoa, pagemapo;
reg [16:0] pagemapa;
wire [16:0] pagemap_ndx = {ASID,ladr[25:14]};

// 131072 x14 bit entries
PagemapRam upageram (
  .clka(clk_g),   // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrpgmap),      // input wire [0 : 0] wea
  .addra({ib[20:16],ib[11:0]}),  // input wire [16 : 0] addra
  .dina(ia[13:0]),    // input wire [13 : 0] dina
  .douta(pagemapoa),  // output wire [13 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(pagemap_ndx),  // input wire [16 : 0] addrb
  .dinb(14'd0),    // input wire [13 : 0] dinb
  .doutb(pagemapo)  // output wire [13 : 0] doutb
);

wire [2:0] omode = pmStack[3:1];
assign DebugMode = omode==3'b101;
assign InterruptMode = omode==3'b100;
assign MachineMode = omode==3'b011;
assign HypervisorMode = omode==3'b010;
assign SupervisorMode = omode==3'b001;
assign UserMode = omode==3'b000;
assign memmode = mprv ? pmStack[7:5] : omode;
wire MMachineMode = memmode==3'b011;
wire MUserMode = memmode==3'b000;

function [7:0] fnSelect;
input [7:0] opcode;
case(opcode)
`LDB,`LDBU:	fnSelect = 8'h01;
`LDW,`LDWU:	fnSelect = 8'h03;
`LDT,`LDTU:	fnSelect = 8'h0F;
`LDO,`LDOR:	fnSelect = 8'hFF;
`STB:	fnSelect = 8'h01;
`STW:	fnSelect = 8'h03;
`STT:	fnSelect = 8'h0F;
`STO:	fnSelect = 8'hFF;
`STOC:	fnSelect = 8'hFF;
`STPTR:	fnSelect = 8'hFF;
default:	fnSelect = 8'h00;
endcase
endfunction

reg [15:0] sel;
reg [95:0] dat, dati;
reg [31:0] ea;
wire [3:0] segsel = ea[31:28];

wire [63:0] datis = dati >> {ea[1:0],3'b0};

reg d_cmp,d_set,d_mov;
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
reg [7:0] mathCnt;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [4:0] funct5 = ir[27:23];
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

wire pe_nmi;
reg nmif;
edge_det u17 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(nmi_i), .pe(pe_nmi), .ne(), .ee() );

always @(posedge wc_clk_i)
if (rst_i)
	wfi <= 1'b0;
else begin
	if (irq_i|pe_nmi)
		wfi <= 1'b0;
	else if (set_wfi)
		wfi <= 1'b1;
end

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

always @(posedge clk_g)
if (rst_i) begin
	state <= IFETCH1;
	pc <= RSTPC;
	for (n = 0; n < 8; n = n + 1) begin
	  tvec[n] <= 32'hFFFC0000;
	  status[n] <= 32'h0;
  end
	ASID <= 5'd0;
	gcie <= 32'h0;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	wrcrf <= 1'b0;
	wrcrf32 <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
  cyc_o <= LOW;
  stb_o <= LOW;
  we_o <= LOW;
  sel_o <= 4'h0;
  adr_o <= 32'd0;
  dat_o <= 32'd0;
	sr_o <= 1'b0;
	cr_o <= 1'b0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	pmStack <= 12'b001001001110;
	nmif <= 1'b0;
	ldd <= 1'b0;
	wrpagemap <= 1'b0;
  pagemapa <= 13'd0;
  ia <= 64'd0;
	setto <= 1'b0;
	getto <= 1'b0;
	decto <= 1'b0;
	getzl <= 1'b0;
	popto <= 1'b0;
	gcloc <= 6'd0;
	pushq <= 1'b0;
	popq <= 1'b0;
	peekq <= 1'b0;
	mrloc <= 3'd0;
	rprv <= 5'd0;
	Rdx <= 5'd29;
	Rs1x <= 5'd29;
	Rs2x <= 5'd29;
	Rs3x <= 5'd29;
	Rdx1 <= 5'd29;
	Rs1x1 <= 5'd29;
	Rs2x1 <= 5'd29;
	Rs3x1 <= 5'd29;
	rsStack <= 32'hFFFFFFFD;
	set_wfi <= 1'b0;
	next_epc <= 32'hFFFFFFFF;
	instret <= 40'd0;
end
else begin

decto <= 1'b0;
popto <= 1'b0;
ldd <= 1'b0;
wrpagemap <= 1'b0;
if (pe_nmi)
	nmif <= 1'b1;
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
if (wc_time_irq==1'b0)
	wc_time_irq_clr <= 1'd0;
pushq <= 1'b0;
popq <= 1'b0;
peekq <= 1'b0;

if (!UserMode)
	adr_o <= ladr;
else begin
	if (ladr[31:24]==8'hFF)
		adr_o <= ladr;
	else
		adr_o <= {pagemapo & 14'h3FFF,ladr[13:0]};
end

case (state)
// It takes two clocks to read the pagemap ram, this is after the linear
// address is set, which also takes a clock cycle.
IFETCH1:
  begin
    wrirf <= 1'b0;
    wrcrf32 <= 1'b0;
    d_cmp <= 1'b0;
    d_mov <= 1'b0;
	  Rdx <= Rdx1;
	  Rs1x <= Rs1x1;
	  Rs2x <= Rs2x1;
	  Rs3x <= Rs3x1;
		illegal_insn <= 1'b1;
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
    tPC();
		if (nmif) begin
			nmif <= 1'b0;
			tException(32'h800000FE,pc);
			pc <= tvec[3'd5] + 8'hFC;
		end
 		else if (irq_i & die) begin
			tException({24'h800000,cause_i},pc);
		end
		else if (mip[7] & miex[7] & die) begin
			tException(32'h80000001,pc);  // timer IRQ
		end
		else if (mip[3] & miex[3] & die) begin
			tException(32'h80000002, pc); // software IRQ
		end
		else if (uip[0] & gcie[ASID] & die) begin
			tException(32'h80000003, pc); // garbage collect IRQ
			uip[0] <= 1'b0;
		end
		else
			pc <= pc + 3'd4;
    goto (IFETCH2);    
  end
IFETCH2:
  begin
    wrcrf <= 1'b0;
    goto (IFETCH3);
  end
IFETCH3:
  begin
    cyc_o <= HIGH;
		stb_o <= HIGH;
		vpa_o <= HIGH;
		sel_o <= 4'hF;
		goto (IFETCH4);
  end
IFETCH4:
  if (ack_i) begin
    cyc_o <= LOW;
    stb_o <= LOW;
    vpa_o <= LOW;
    sel_o <= 4'h0;
    ir <= dat_i;
    goto (DECODE);
  end
DECODE:
  begin
    goto (REGFETCH1);
    Rd <= 5'd0;
    Cd <= ir[9:8];
    casez(opcode)
    `R2:
      begin
        Rd <= ir[12:8];
        Cd <= 2'b00;
        case(ir[31:26])
        `ANDR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR2:  begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `EORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `BMMR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ADDR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `SUBR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NANDR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ENORR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `BITR2: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1;  illegal_insn <= 1'b0; end
        `R1:
          case(ir[22:18])
          `CNTLZR1: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `CNTLOR1: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `CNTPOPR1:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `COMR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `NOTR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `NEGR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          default:  ;                                    
          endcase
        `MULR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CMPR2: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `MULUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PERMR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PTRDIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `BYTNDX:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `WYDNDX:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RGFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MOV:
          begin
            d_mov <= 1'b1;
            wrcrf <= ir[31];
            case(ir[19:18])
            2'b00:  wrirf <= 1'b1;
            2'b01:  wrfrf <= 1'b1;
            2'b10:  ;
            2'b11:
              casez(ir[12:8])
              5'b0000?: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
              5'b11101: wrcrf32 <= 1'b1;
              default:  ;
              endcase
            endcase
            illegal_insn <= 1'b0;
          end
        default:  ;
        endcase
      end
    `R3A:
      begin
        Rd <= ir[12:8];
        case(ir[30:28])
        `MINR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MAXR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MAJR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MUXR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ADDR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `SUBR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `FLIPR3A:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end
    `R3B:
      begin
        Rd <= ir[12:8];
        case(ir[30:28])
        `ANDR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR3B:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `EORR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DEPR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `EXTR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `EXTUR3B: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `BLENDR3B: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RGFR3B:  begin illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end
    `SHIFT:
      begin
        Rd <= ir[12:8];
        case(ir[27:24])
        `ASL:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `LSR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ROL:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ROR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ASR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ASLI: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `LSRI: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ROLI: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RORI: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ASRI: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end

    `SET:
      begin
        d_set <= 1'b1;
        Cd <= ir[9:8];
        case(ir[30:28])
        `SEQR2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SNER2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SLTR2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SGER2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SLTUR2:begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SGEUR2:begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        default:  ;
      endcase
      end
    `SEQ: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SNE: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLT: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGE: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLE: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGT: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLTU: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGEU: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLEU: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGTU: begin d_set <= 1'b1; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end

    `ADD: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `SUBF:begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `MUL: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `CMP: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `AND: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{1'b1}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `OR:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{1'b0}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `EOR: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{1'b0}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `BIT: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `LUI: begin Rd <= ir[8] ? 5'd1 : 5'd2; wrirf <= 1'b1; illegal_insn <= 1'b0; end
    `LMI: begin Rd <= ir[8] ? 5'd1 : 5'd2; wrirf <= 1'b1; illegal_insn <= 1'b0; end
    `AUIPC: begin Rd <= ir[9] ? 5'd1 : 5'd2; wrirf <= 1'b1; illegal_insn <= 1'b0; end
    `CSR: if (omode >= ir[28:26]) begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= ir[17:13]; illegal_insn <= 1'b0; end
    // Flow Control
    `JMP: begin pc <= {pc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); illegal_insn <= 1'b0; end
    `JSR:
      begin
        // Assume instruction will not crap out and write ra0,ra1 here rather
        // than at WRITEBACK.
        ra[{ir[8],rprv[0] ? rsStack[9:5] : crs}] <= ipc;
        wrirf <= 1'b1;
        pc <= {ipc[AWID-1:24],ir[31:10],2'b00};
        res <= ipc;
        illegal_insn <= 1'b0;
      end
    `RTS:
      begin
        Rd = 5'd31;
        wrirf <= 1'b1;
        imm <= {{51{ir[31]}},ir[30:21],3'b00};
        illegal_insn <= 1'b0;
      end
    `RTE:
      // Must be at a higher operating mode in order to return to a lower one.
      if (rsStack[4:0] > rsStack[9:5] && rsStack[4:0] > 5'd25) begin
			  rsStack <= {5'd31,rsStack[29:5]};
			  rprv <= 5'h0;
			  Rdx1 <= rsStack[9:5];
			  Rs1x1 <= rsStack[9:5];
			  Rs2x1 <= rsStack[9:5];
			  Rs3x1 <= rsStack[9:5];
				pc <= epc[rsStack[4:0]];
				illegal_insn <= 1'b0;
      end
    `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,`BLEU,`BGTU,`BOD,`BPS:
      illegal_insn <= 1'b0;
    // Memory Ops
    `LDB:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDBU: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDW:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDWU: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDT:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDTU: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDO:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `LDOR: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `STB:  begin imm <= {{50{ir[31]}},ir[31:23],ir[12:8]}; illegal_insn <= 1'b0; end
    `STW:  begin imm <= {{50{ir[31]}},ir[31:23],ir[12:8]}; illegal_insn <= 1'b0; end
    `STT:  begin imm <= {{50{ir[31]}},ir[31:23],ir[12:8]}; illegal_insn <= 1'b0; end
    `STO:  begin imm <= {{50{ir[31]}},ir[31:23],ir[12:8]}; illegal_insn <= 1'b0; end
    `STOC: begin imm <= {{50{ir[31]}},ir[31:23],ir[12:8]}; illegal_insn <= 1'b0; end
    `STPTR: begin imm <= {{50{ir[31]}},ir[31:23],ir[12:8]}; illegal_insn <= 1'b0; end
    `LDX:
      case(ir[22:18])
      `LDBX:   begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDBUX:  begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDWX:   begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDWUX:  begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDTX:   begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDTUX:  begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDOX:   begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      `LDORX:  begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
      default:  ;
      endcase
    `STX:
      case(ir[12:8])
      `STBX: illegal_insn <= 1'b0;
      `STWX: illegal_insn <= 1'b0;
      `STTX: illegal_insn <= 1'b0;
      `STOX: illegal_insn <= 1'b0;
      `STOCX: illegal_insn <= 1'b0;
      `STPTRX: illegal_insn <= 1'b0;
      default:  ;
      endcase
    endcase
  end
// Need a state to read Rd from block ram.
REGFETCH1:
  goto (REGFETCH2);
REGFETCH2:
  begin
    goto (EXECUTE);
    ia <= Rs1==5'd0 ? 64'd0 : irfoRs1;
    ib <= Rs2==5'd0 ? 64'd0 : irfoRs2;
    ic <= Rs3==5'd0 ? 64'd0 : irfoRs3;
    id <= Rd==5'd0 ? 64'd0 : irfoRd;
    ret_pc <= ra[{d_mov ? Rs1[0] : ir[8],rprv ? rsStack[9:5] : crs}];
  end
EXECUTE:
  begin
    goto (WRITEBACK);
    res <= 64'd0;
    casez(opcode)
    `R2:
      case(ir[31:26])
      `ANDR2: res <= ia & ib;
      `ORR2:  res <= ia | ib;
      `EORR2: res <= ia ^ ib;
      `NANDR2:res <= ~(ia & ib);
      `NORR2: res <= ~(ia | ib);
      `ENORR2:res <= ~(ia ^ ib);
      `BITR2:
        case(mop)
        `CMP_CPY:
          begin
            crres[0] <= 1'b0;
            crres[1] <= bitr==64'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= ^bitr;
            crres[5] <= bitr[0];
            crres[6] <= 1'b0;
            crres[7] <= bitr[63];
          end
        `CMP_AND:
          begin
            crres[0] <= 1'b0;
            crres[1] <= cd && bitr==64'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd & ^bitr;
            crres[5] <= cd & bitr[0];
            crres[6] <= 1'b0;
            crres[7] <= cd & bitr[63];
          end
        `CMP_OR:
          begin
            crres[0] <= 1'b0;
            crres[1] <= cd || bitr==64'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd | ^bitr;
            crres[5] <= cd | bitr[0];
            crres[6] <= 1'b0;
            crres[7] <= cd | bitr[63];
          end
        `CMP_ANDCM:
          begin
            crres[0] <= 1'b0;
            crres[1] <= cd && !(bitr==64'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd & ~^bitr;
            crres[5] <= cd & ~bitr[0];
            crres[6] <= 1'b0;
            crres[7] <= cd & ~bitr[63];
          end
        `CMP_ORCM:
          begin
            crres[0] <= 1'b0;
            crres[1] <= cd || !(bitr==64'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd | ~^bitr;
            crres[5] <= cd | ~bitr[0];
            crres[6] <= 1'b0;
            crres[7] <= cd | ~bitr[63];
          end
        default:  ;
        endcase
      `MULR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `CMPR2:
        begin
          d_cmp <= 1'b1;
          case(mop)
          `CMP_CPY:
            begin
              crres[0] <= difr[64];
              crres[1] <= ~|difr[63:0];
              crres[2] <= 1'b0;
              crres[3] <= 1'b0;
              crres[4] <= ^difr[63:0];
              crres[5] <= difr[0];
              crres[6] <= difr[64]^difr[63];
              crres[7] <= difr[63];
            end
          `CMP_AND:
            begin
              crres[0] <= cd[0] & difr[64];
              crres[1] <= cd[1] & ~|difr[63:0];
              crres[2] <= 1'b0;
              crres[3] <= 1'b0;
              crres[4] <= cd[4] & ^difr[63:0];
              crres[5] <= cd[5] & difr[0];
              crres[6] <= cd[6] & difr[64]^difr[63];
              crres[7] <= cd[7] & difr[63];
            end
          `CMP_OR:
            begin
              crres[0] <= cd[0] | difr[64];
              crres[1] <= cd[1] | ~|difr[63:0];
              crres[2] <= 1'b0;
              crres[3] <= 1'b0;
              crres[4] <= cd[4] | ^difr[63:0];
              crres[5] <= cd[5] | difr[0];
              crres[6] <= cd[6] | difr[64]^difr[63];
              crres[7] <= cd[7] | difr[63];
            end
          `CMP_ANDCM:
            begin
              crres[0] <= cd[0] & ~difr[64];
              crres[1] <= cd[1] & |difr[63:0];
              crres[2] <= 1'b0;
              crres[3] <= 1'b0;
              crres[4] <= cd[4] & ~^difr[63:0];
              crres[5] <= cd[5] & ~difr[0];
              crres[6] <= cd[6] & ~(difr[64]^difr[63]);
              crres[7] <= cd[7] & ~difr[63];
            end
          `CMP_ORCM:
            begin
              crres[0] <= cd[0] | ~difr[64];
              crres[1] <= cd[1] | |difr[63:0];
              crres[2] <= 1'b0;
              crres[3] <= 1'b0;
              crres[4] <= cd[4] | ~^difr[63:0];
              crres[5] <= cd[5] | ~difr[0];
              crres[6] <= cd[6] | ~(difr[64]^difr[63]);
              crres[7] <= cd[7] | ~difr[63];
            end
          default:  crres[7:0] <= 8'h00;
          endcase
        end
      `MULUR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULSUR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULHR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULUHR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULSUHR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `DIVR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `DIVUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `DIVSUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `REMR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `REMUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `REMSUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `PERMR2:
        begin
          wrirf <= 1'b1;
          wrcrf <= ir[31];
          illegal_insn <= 1'b0;
          res[ 7: 0] <= ia >> {ib[2:0],3'b0};
          res[15: 8] <= ia >> {ib[5:3],3'b0};
          res[23:16] <= ia >> {ib[8:6],3'b0};
          res[31:24] <= ia >> {ib[11:9],3'b0};
          res[39:32] <= ia >> {ib[14:12],3'b0};
          res[47:40] <= ia >> {ib[17:15],3'b0};
          res[55:48] <= ia >> {ib[20:18],3'b0};
          res[63:56] <= ia >> {ib[23:21],3'b0};
        end
      `PTRDIFR2:
        begin
          wrirf <= 1'b1;
          wrcrf <= ir[31];
          res <= (ia - ib) >> ir[24:23];
          illegal_insn <= 1'b0;
        end
      `DIFR2:
        begin
          wrirf <= 1'b1;
          wrcrf <= ir[31];
          res <= $signed(ia) < $signed(ib) ? ib - ia : ia - ib;
          illegal_insn <= 1'b0;
        end
      `BYTNDX:
        begin
          wrirf <= 1'b1;
          wrcrf <= ir[31];
          illegal_insn <= 1'b0;
          if (ia[7:0]==ib[7:0])
            res <= 64'd0;
          else if (ia[15:8]==ib[7:0])
            res <= 64'd1;
          else if (ia[23:16]==ib[7:0])
            res <= 64'd2;
          else if (ia[31:24]==ib[7:0])
            res <= 64'd3;
          else if (ia[39:32]==ib[7:0])
            res <= 64'd4;
          else if (ia[47:40]==ib[7:0])
            res <= 64'd5;
          else if (ia[55:40]==ib[7:0])
            res <= 64'd6;
          else if (ia[63:56]==ib[7:0])
            res <= 64'd7;
          else
            res <= {64{1'b1}};  // -1
        end
      `WYDNDX:
        begin
          wrirf <= 1'b1;
          wrcrf <= ir[31];
          illegal_insn <= 1'b0;
          if (ia[15:0]==ib[15:0])
            res <= 64'd0;
          else if (ia[31:16]==ib[15:0])
            res <= 64'd1;
          else if (ia[47:32]==ib[15:0])
            res <= 64'd2;
          else if (ia[63:48]==ib[15:0])
            res <= 64'd3;
          else
            res <= {64{1'b1}};  // -1
        end
      `MOV:
        begin
          case(ir[21:20])
          2'b00:  res <= ia;
          2'b01:  ;
          2'b10:  ;
          2'b11:
            casez(Rs1)
            5'b0000?: res <= ret_pc;
            5'b00111: res <= epc[rprv[1] ? rsStack[9:5] : rsStack[4:0]];
            5'b100??: res <= cds;
            5'b11101: res <= cds32;
            default:  ;
            endcase
          endcase
        end
      endcase
    `R3A:
      case(ir[30:28])
      `MINR3A:
        if (ia < ib && ia < ic)
          res <= ia;
        else if (ib < ic)
          res <= ib;
        else
          res <= ic;      
      `MAXR3A:
        if (ia > ib && ia > ic)
          res <= ia;
        else if (ib > ic)
          res <= ib;
        else
          res <= ic;      
      `MAJR3A: res <= (ia & ib) | (ia & ic) | (ib & ic);
      `MUXR3A:
        for (n = 0; n < 64; n = n + 1)
          res[n] <= ia[n] ? ib[n] : ic[n];
      `ADDR3A: res <= ia + ib + ic;
      `SUBR3A: res <= ia - ib - ic;
      endcase
    `R3B:
    	case(ir[30:28])
      `ANDR3B: res <= ia & ib & ic;
      `ORR3B:  res <= ia | ib | ic;
      `EORR3B: res <= ia ^ ib ^ ic;
      `BLENDR3B:
        begin
          res[ 7: 0] <= blendG1[15:8] + blendG2[15:8];
          res[15: 8] <= blendB1[15:8] + blendB2[15:8];
          res[23:16] <= blendR1[15:8] + blendR2[15:8];
          res[63:24] <= ia[63:24];
        end
      endcase
    `ADD: res <= ia + imm;
    `SUBF: res <= imm - ia;
    `MUL: res <= $signed(ia) * $signed(imm);
    `CMP:
      begin
        d_cmp <= 1'b1;
        case(mop)
        `CMP_CPY:
          begin
            crres[0] <= difi[64];
            crres[1] <= ~|difi[63:0];
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= ^difi[63:0];
            crres[5] <= difi[0];
            crres[6] <= difi[64]^difi[63];
            crres[7] <= difi[63];
          end
        `CMP_AND:
          begin
            crres[0] <= cd[0] & difi[64];
            crres[1] <= cd[1] & ~|difi[63:0];
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd[4] & ^difi[63:0];
            crres[5] <= cd[5] & difi[0];
            crres[6] <= cd[6] & difi[64]^difi[63];
            crres[7] <= cd[7] & difi[63];
          end
        `CMP_OR:
          begin
            crres[0] <= cd[0] | difi[64];
            crres[1] <= cd[1] | ~|difi[63:0];
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd[4] | ^difi[63:0];
            crres[5] <= cd[5] | difi[0];
            crres[6] <= cd[6] | difi[64]^difi[63];
            crres[7] <= cd[7] | difi[63];
          end
        `CMP_ANDCM:
          begin
            crres[0] <= cd[0] & ~difi[64];
            crres[1] <= cd[1] & |difi[63:0];
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd[4] & ~^difi[63:0];
            crres[5] <= cd[5] & ~difi[0];
            crres[6] <= cd[6] & ~(difi[64]^difi[63]);
            crres[7] <= cd[7] & ~difi[63];
          end
        `CMP_ORCM:
          begin
            crres[0] <= cd[0] | ~difi[64];
            crres[1] <= cd[1] | |difi[63:0];
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cd[4] | ~^difi[63:0];
            crres[5] <= cd[5] | ~difi[0];
            crres[6] <= cd[6] | ~(difi[64]^difi[63]);
            crres[7] <= cd[7] | ~difi[63];
          end
        default:  crres[7:0] <= 8'h00;
        endcase
      end
    `SET:
      begin
        case(ir[30:28])
        `SEQR2: setcr(ia==ib);
        `SNER2: setcr(ia!=ib);
        `SLTR2: setcr($signed(ia) < $signed(ib));
        `SGER2: setcr($signed(ia) >= $signed(ib));
        `SLTUR2: setcr(ia <  ib);
        `SGEUR2: setcr(ia >= ib);
        default:  ;
        endcase
      end
    `BIT:
      case(mop)
      `CMP_CPY:
        begin
          crres[0] <= 1'b0;
          crres[1] <= biti==64'd0;
          crres[2] <= 1'b0;
          crres[3] <= 1'b0;
          crres[4] <= ^biti;
          crres[5] <= biti[0];
          crres[6] <= 1'b0;
          crres[7] <= biti[63];
        end
      `CMP_AND:
        begin
          crres[0] <= 1'b0;
          crres[1] <= cd && biti==64'd0;
          crres[2] <= 1'b0;
          crres[3] <= 1'b0;
          crres[4] <= cd & ^biti;
          crres[5] <= cd & biti[0];
          crres[6] <= 1'b0;
          crres[7] <= cd & biti[63];
        end
      `CMP_OR:
        begin
          crres[0] <= 1'b0;
          crres[1] <= cd || biti==64'd0;
          crres[2] <= 1'b0;
          crres[3] <= 1'b0;
          crres[4] <= cd | ^biti;
          crres[5] <= cd | biti[0];
          crres[6] <= 1'b0;
          crres[7] <= cd | biti[63];
        end
      `CMP_ANDCM:
        begin
          crres[0] <= 1'b0;
          crres[1] <= cd && !(biti==64'd0);
          crres[2] <= 1'b0;
          crres[3] <= 1'b0;
          crres[4] <= cd & ~^biti;
          crres[5] <= cd & ~biti[0];
          crres[6] <= 1'b0;
          crres[7] <= cd & ~biti[63];
        end
      `CMP_ORCM:
        begin
          crres[0] <= 1'b0;
          crres[1] <= cd || !(biti==64'd0);
          crres[2] <= 1'b0;
          crres[3] <= 1'b0;
          crres[4] <= cd | ~^biti;
          crres[5] <= cd | ~biti[0];
          crres[6] <= 1'b0;
          crres[7] <= cd | ~biti[63];
        end
      default:  ;
      endcase
    `SEQ: setcr(ia==imm);
    `SNE: setcr(ia!=imm);
    `SLT: setcr($signed(ia) < $signed(imm));
    `SGE: setcr($signed(ia) >= $signed(imm));
    `SLE: setcr($signed(ia) <= $signed(imm));
    `SGT: setcr($signed(ia) > $signed(imm));
    `SLTU: setcr(ia <  imm);
    `SGEU: setcr(ia >= imm);
    `SLEU: setcr(ia <= imm);
    `SGTU: setcr(ia >  imm);
    `AND: res <= ia & imm;
    `OR:  res <= ia | imm;
    `EOR: res <= ia ^ imm;
    `LUI: res <= {ir[31:9],ir[1:0],id[38:0]};
    `LMI: res <= {{25{ir[31]}},ir[31:9],ir[2:0],13'd0};
    `AUIPC: res <= ipc + {{26{ir[31]}},ir[31:9],ir[1:0],13'd0};
    `CSR:
      begin
        res <= 64'd0;
        wrirf <= 1'b1;
        case(ir[31:29])
        3'd4,3'd5,3'd6,3'd7:  ia <= Rs1;
        default:  ;
        endcase
        casez(ir[28:18])
        11'b???_0000_0010:  res <= tick;
        11'b001_0001_0000:  res <= TaskId;
        11'b001_0001_1111:  res <= ASID;
        11'b011_0000_0001:  res <= hartid_i;
        11'b???_0000_0110:  res <= cause[ir[28:26]];
        11'b???_0000_0111:  res <= badaddr[ir[28:26]];
        11'b???_0000_1001:  res <= scratch[ir[28:26]];
        11'b???_0011_0???:  res <= tvec[ir[28:26]];
        11'b???_0100_0000:  res <= pmStack;
        11'b???_0100_0011:  res <= rsStack;
        11'b???_0100_1000:  res <= epc[rprv[4] ? rsStack[9:5] : rsStack[4:0]];
        11'b101_0001_10??:  res <= dbadr[ir[19:18]];
        11'b101_0001_1100:  res <= dbcr;
        11'b101_0001_1101:  res <= dbsr;
        default:  ;
        endcase
      end
    `RTS: 
      begin
        res <= ia + imm;
        pc <= ret_pc + {ir[12:9],2'b00};
      end
    `BEQ: begin if ( cd[1]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BNE: begin if (~cd[1]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BMI: begin if ( cd[7]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BPL: begin if (~cd[7]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BVS: begin if ( cd[6]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BVC: begin if (~cd[6]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BCS: begin if ( cd[0]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BCC: begin if (~cd[0]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BLE: begin if ( cd[1] | cd[7]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BGT: begin if (~(cd[1] | cd[7])) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BLEU: begin if ( cd[1] | cd[0]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BGTU: begin if (~(cd[1] | cd[0])) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BOD: begin if ( cd[5]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BPS: begin if ( cd[4]) pc <= {ipc[AWID-1:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `OSR2:
      case(ir[30:26])
      `REX:
        if (ir[10:8] < omode) begin
          illegal_insn <= 1'b0;
          case(ir[10:8])
          3'd0:
            if (uie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'b0;
              rsStack[4:0] <= 5'd26;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd1:
            if (sie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd2;
              rsStack[4:0] <= 5'd27;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd2:
            if (hie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd4;
              rsStack[4:0] <= 5'd28;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd3:
            if (mie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd6;
              rsStack[4:0] <= 5'd29;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd4:
            if (iie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd8;
              rsStack[4:0] <= 5'd30;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          default:  ;
          endcase
        end
      endcase
    // Memory Ops
    `LDB:  begin ea <= ia + imm; goto (MEMORY1); end
    `LDBU: begin ea <= ia + imm; goto (MEMORY1); end
    `LDW:  begin ea <= ia + imm; goto (MEMORY1); end
    `LDWU: begin ea <= ia + imm; goto (MEMORY1); end
    `LDT:  begin ea <= ia + imm; goto (MEMORY1); end
    `LDTU: begin ea <= ia + imm; goto (MEMORY1); end
    `LDO:  begin ea <= ia + imm; goto (MEMORY1); end
    `LDOR: begin ea <= ia + imm; goto (MEMORY1); end
    `LDX:
      case(ir[22:18])
      `LDBX:    begin ea <= ia + ic; goto (MEMORY1); end
      `LDBUX:   begin ea <= ia + ic; goto (MEMORY1); end
      `LDWX:    begin ea <= ia + ic << (ir[28] ? 2'd1 : 2'd0); goto (MEMORY1); end
      `LDWUX:   begin ea <= ia + ic << (ir[28] ? 2'd1 : 2'd0); goto (MEMORY1); end
      `LDTX:    begin ea <= ia + ic << (ir[28] ? 2'd2 : 2'd0); goto (MEMORY1); end
      `LDTUX:   begin ea <= ia + ic << (ir[28] ? 2'd2 : 2'd0); goto (MEMORY1); end
      `LDOX:    begin ea <= ia + ic << (ir[28] ? 2'd3 : 2'd0); goto (MEMORY1); end
      `LDORX:   begin ea <= ia + ic << (ir[28] ? 2'd3 : 2'd0); goto (MEMORY1); end
      default:  ;
      endcase
    `STB:  begin ea <= ia + imm; goto (MEMORY1); end
    `STW:  begin ea <= ia + imm; goto (MEMORY1); end
    `STT:  begin ea <= ia + imm; goto (MEMORY1); end
    `STO:  begin ea <= ia + imm; goto (MEMORY1); end
    `STOC: begin ea <= ia + imm; goto (MEMORY1); end
    `STPTR: begin ea <= ia + imm; goto (MEMORY1); end
    `STX:
      case(ir[12:8])
      `STBX:    begin ea <= ia + ic; goto (MEMORY1); end
      `STWX:    begin ea <= ia + ic << (ir[28] ? 2'd1 : 2'd0); goto (MEMORY1); end
      `STTX:    begin ea <= ia + ic << (ir[28] ? 2'd2 : 2'd0); goto (MEMORY1); end
      `STOX:    begin ea <= ia + ic << (ir[28] ? 2'd3 : 2'd0); goto (MEMORY1); end
      `STOCX:   begin ea <= ia + ic << (ir[28] ? 2'd3 : 2'd0); goto (MEMORY1); end
      `STPTRX:  begin ea <= ia + ic << (ir[28] ? 2'd3 : 2'd0); goto (MEMORY1); end
      default:  ;
      endcase
    endcase
  end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Adjust for sign
MUL1:
	begin
		ldd <= 1'b1;
    goto (MUL2);
		case(opcode)
		`R2:
	    case(ir[30:26])
	    `MULR2,`DIVR2,`REMR2,`MULHR2:
  		  begin
  				sgn <= ia[WID-1] ^ ib[WID-1];	// compute output sign
  				if (ia[WID-1]) ia <= -ia;			// Make both values positive
  				if (ib[WID-1]) ib <= -ib;
  		  end
  		`MULSUR2,`MULSUHR2:
  			begin
  				sgn <= ia[WID-1];
  				if (ia[WID-1]) ia <= -ia;
  				goto (MUL2);
  			end
  	  default:  ;
	    endcase
		`MUL,`DIV,`REM:
		  begin
				sgn <= ia[WID-1] ^ imm[WID-1];	// compute output sign
				if (ia[WID-1]) ia <= -ia;			// Make both values positive
				if (ib[WID-1]) ib <= -imm; else ib <= imm;
		  end
		`MULU,`DIVU,`REMU:
		  ib <= imm;
		default:  ;
	  endcase
	end
// Capture result
MUL2:
	begin
		mathCnt <= mathCnt - 8'd1;
		if (mathCnt==8'd0) begin
			state <= WRITEBACK;
			case(opcode)
			`R2:
			  case(ir[30:26])
			  `MULR2:   res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			  `MULUR2:  res <= prod[WID-1:0];
			  `MULSUR2: res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			  `MULHR2:  res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			  `MULUHR2: res <= prod[WID*2-1:WID];
			  `MULSUHR2:res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			  `DIVR2:   res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			  `DIVUR2:  res <= div_q[WID*2-1:WID];
			  `DIVSUR2: res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			  `REMR2:   res <= sgn ? ndiv_r : div_r;
			  `REMUR2:  res <= div_r;
			  `REMSUR2: res <= sgn ? ndiv_r : div_r;
			  default:  ;
			  endcase
			`MUL,`MULSU:  res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			`MULU: res <= prod[WID-1:0];
			`DIV:  res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			`DIVU: res <= div_q[WID*2-1:WID];
			`DIVSU:res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			`REM:  res <= sgn ? ndiv_r : div_r;
			`REMU: res <= div_r;
			`REMSU:res <= sgn ? ndiv_r : div_r;
			default:  ;
		  endcase
		end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MEMORY1:
  begin
    goto (MEMORY2);
    tEA();
    sel <= fnSelect(opcode) << ea[1:0];
    dat <= ib << {ea[1:0],3'b0};
  end
// This cycle for pageram access
MEMORY2:
  begin
    goto (MEMORY3);
  end
MEMORY3:
  begin
    goto (MEMORY4);
    cyc_o <= HIGH;
    stb_o <= HIGH;
    sel_o <= sel[3:0];
    dat_o <= dat[31:0];
    case(opcode)
    `STB,`STW,`STT,`STO,`STOC,`STPTR:
      we_o <= HIGH;
    default:  ;
    endcase
  end
MEMORY4:
  if (ack_i) begin
    goto (MEMORY5);
    stb_o <= LOW;
    dati <= {64'd0,dat_i};
    if (sel[7:4]==4'h0) begin
      cyc_o <= LOW;
      we_o <= LOW;
      sel_o <= 4'h0;
    end
  end
MEMORY5:
  if (~ack_i) begin
    ea <= {ea[31:2]+2'd1,2'b00};
    if (sel[7:4])
      goto (MEMORY6);
    else begin
      case(opcode)
      `STB,`STW,`STT,`STO,`STOC,`STPTR:
        goto (IFETCH1);
      default:
        goto (DATA_ALIGN);
      endcase
    end
  end
MEMORY6:
  begin
    goto (MEMORY7);
    tEA();
  end
MEMORY7:
  goto (MEMORY8);
MEMORY8:
  begin
    goto (MEMORY9);
    stb_o <= HIGH;
    sel_o <= sel[7:4];
    dat_o <= dat[63:31];
  end
MEMORY9:
  if (ack_i) begin
    goto (MEMORY10);
    stb_o <= LOW;
    dati[63:32] <= dat_i;
    if (sel[11:8]==4'h0) begin
      cyc_o <= LOW;
      we_o <= LOW;
      sel_o <= 4'h0;
    end
  end
MEMORY10:
  if (~ack_i) begin
    ea <= {ea[31:2]+2'd1,2'b00};
    if (sel[11:8])
      goto (MEMORY11);
    else begin
      case(opcode)
      `STB,`STW,`STT,`STO,`STOC,`STPTR:
        goto (IFETCH1);
      default:
        goto (DATA_ALIGN);
      endcase
    end
  end
MEMORY11:
  begin
    goto (MEMORY12);
    tEA();
  end
MEMORY12:
  goto (MEMORY13);
MEMORY13:
  begin
    goto (MEMORY14);
    stb_o <= HIGH;
    sel_o <= sel[11:8];
    dat_o <= dat[95:64];
  end
MEMORY14:
  if (ack_i) begin
    goto (MEMORY15);
    cyc_o <= LOW;
    stb_o <= LOW;
    we_o <= LOW;
    sel_o <= 4'h0;
    dati[95:64] <= dat_i;
  end
MEMORY15:
  if (~ack_i) begin
    ea <= {ea[31:2]+2'd1,2'b00};
    case(opcode)
    `STB,`STW,`STT,`STO,`STOC,`STPTR:
      goto (IFETCH1);
    default:
      goto (DATA_ALIGN);
    endcase
  end
DATA_ALIGN:
  begin
    goto (WRITEBACK);
    case(opcode)
    `LDB:   res <= {{56{datis[7]}},datis[7:0]};
    `LDBU:  res <= {{56{1'b0}},datis[7:0]};
    `LDW:   res <= {{48{datis[15]}},datis[15:0]};
    `LDWU:  res <= {{48{1'b0}},datis[15:0]};
    `LDT:   res <= {{32{datis[31]}},datis[31:0]};
    `LDTU:  res <= {{32{1'b0}},datis[31:0]};
    `LDO:   res <= datis[63:0];
    `LDOR:  res <= datis[63:0];
    default:  ;
    endcase
  end
WRITEBACK:
  begin
    // Compares and sets already update crres
    if (~d_cmp & ~d_set & ~illegal_insn & wrcrf) begin
      crres[0] <= res[64];
      crres[1] <= res[63:0]==64'd0;
      crres[2] <= 1'b0;
      crres[3] <= 1'b0;
      crres[4] <= ^res[63:0];
      crres[5] <= res[0];
      crres[6] <= res[64]^res[63];
      crres[7] <= res[63];
    end
		if (illegal_insn)
		  tException(32'd2, ipc);
    else
    case (opcode)
    `R2:
      case(ir[30:26])
      `MOV:
        begin
          case(ir[21:20])
          2'b00:  ;
          2'b01:  ;
          2'b10:  ;
          2'b11:
            casez(Rd)
            5'b0000?: ra[{ir[8],rprv[0] ? rsStack[9:5] : crs}] <= res;
            5'b00111: epc[rprv[1] ? rsStack[9:5] : rsStack[4:0]] <= res;
            default:  ;
            endcase
          endcase
        end
      default:  ;
      endcase
    `CSR:
      begin
        if (Rs1 != 5'd0)
        case(ir[31:29])
        3'd0: ; // read only
        3'd1,3'd5:
          casez(ir[28:18])
          11'b001_0001_0000:  TaskId <= ia;
          11'b001_0001_1111:  ASID <= ia;
          11'b???_0000_0110:  cause[ir[28:26]] <= ia;
          11'b???_0000_0111:  badaddr[ir[28:26]] <= ia;
          11'b???_0000_1001:  scratch[ir[28:26]] <= ia;
          11'b???_0011_0???:  tvec[ir[28:26]] <= ia;
          11'b???_0100_0000:  pmStack <= ia;
          11'b???_0100_0011:  rsStack <= ia;
				  11'b???_0100_1000:	epc[rprv[4] ? rsStack[9:5] : rsStack[4:0]] <= ia;
				  11'b???_0001_1100:
				    begin
  			      rprv <= ia[4:0];
  			      Rdx1  <= ia[0] ? rsStack[9:5] : rsStack[4:0];
  			      Rs1x1 <= ia[1] ? rsStack[9:5] : rsStack[4:0];
  			      Rs2x1 <= ia[2] ? rsStack[9:5] : rsStack[4:0];
  			      Rs3x1 <= ia[3] ? rsStack[9:5] : rsStack[4:0];
  			    end
          11'b101_0001_10??:  dbadr[ir[19:18]] <= ia;
          11'b101_0001_1100:  dbcr <= ia;
          11'b101_0001_1101:  dbsr <= ia;
          default:  ;
          endcase
        3'd2,3'd6:
          casez(ir[28:18])
          11'b???_0100_0000:  pmStack <= pmStack | ia;
          11'b???_0100_0011:  rsStack <= rsStack | ia;
          11'b101_0001_1100:  dbcr <= dbcr | ia;
          11'b101_0001_1101:  dbsr <= dbsr | ia;
          default:  ;
          endcase
        3'd3,3'd7:
          casez(ir[28:18])
          11'b???_0100_0000:  pmStack <= pmStack & ~ia;
          11'b???_0100_0011:  rsStack <= rsStack & ~ia;
          11'b101_0001_1100:  dbcr <= dbcr & ~ia;
          11'b101_0001_1101:  dbsr <= dbsr & ~ia;
          default:  ;
          endcase
        endcase
      end
    `RTE:
      begin
				pmStack <= {4'b1010,pmStack[31:4]};
      end
    `OSR2:
      case(ir[30:26])
      `REX:
        epc[crs] <= next_epc;
      default:  ;
      endcase
    endcase
		instret <= instret + 2'd1;
    goto (IFETCH1);
  end
endcase
end

task tEA;
begin
	if (!MUserMode || ea[AWID-1:24]=={AWID-24{1'b1}})
		ladr <= ea;
	else
		ladr <= ea[AWID-4:0] + {sregfile[segsel][AWID-1:4],`SEG_SHIFT};
end
endtask

task tPC;
begin
	if (!UserMode || pc[AWID-1:24]=={AWID-24{1'b1}})
		ladr <= pc;
	else
		ladr <= pc[AWID-2:0] + {sregfile[{2'b11,pc[AWID-1:AWID-2]}][AWID-1:4],`SEG_SHIFT};
end
endtask

task setbool;
input bool;
begin
  crres[0] <= bool;
  crres[1] <= bool;
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool;
  crres[5] <= bool;
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolAnd;
input bool;
begin
  crres[0] <= bool & cd[0];
  crres[1] <= bool & cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool & cd[4];
  crres[5] <= bool & cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolOr;
input bool;
begin
  crres[0] <= bool | cd[0];
  crres[1] <= bool | cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool | cd[4];
  crres[5] <= bool | cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolAndcm;
input bool;
begin
  crres[0] <= bool & ~cd[0];
  crres[1] <= bool & ~cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool & ~cd[4];
  crres[5] <= bool & ~cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolOrcm;
input bool;
begin
  crres[0] <= bool | ~cd[0];
  crres[1] <= bool | ~cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool | ~cd[4];
  crres[5] <= bool | ~cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setcr;
input bool;
begin
  case (mop)
  `CMP_CPY: setbool(bool);
  `CMP_AND: setboolAnd(bool);
  `CMP_OR:  setboolOr(bool);
  `CMP_ANDCM: setboolAndcm(bool);
  `CMP_ORCM:  setboolOrcm(bool);
  default:  ;
  endcase
end
endtask

task tException;
input [31:0] cse;
input [31:0] tpc;
begin
	pc <= tvec[3'd5] + {omode,6'h00};
	epc[5'd31] <= tpc;
	pmStack <= {pmStack[27:0],3'b101,1'b0};
	cause[3'd5] <= cse;
	illegal_insn <= 1'b0;
	instret <= instret + 2'd1;
  rprv <= 5'h0;
  Rdx1 <= 5'd31;
  Rs1x1 <= 5'd31;
  Rs2x1 <= 5'd31;
  Rs3x1 <= 5'd31;
  rsStack <= {rsStack[24:0],5'd31};
	goto (IFETCH1);
end
endtask

task goto;
input [5:0] nst;
begin
  state <= nst;
end
endtask

endmodule
