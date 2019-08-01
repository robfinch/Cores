// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nvio2.sv
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

`include "nvio2-defines.sv"
`include "../fp/fpConfig.sv"

module nvio2(hartid_i, rst_i, wc_clk_i, clk_i, nmi_i, irq_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter WID=128;
parameter FPWID = 128;
input rst_i;
input wc_clk_i;
input clk_i;
input [31:0] hartid_i;
input nmi_i;
input irq_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [31:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
parameter RSTIP = 32'hFFFC0200;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
`include "../fp/fpSize.sv"

reg [7:0] state;
parameter IDLE = 8'd0;
parameter IFETCH = 8'd1;
parameter IFETCH2 = 8'd2;
parameter IFETCH3 = 8'd3;
parameter IFETCH4 = 8'd4;
parameter DECODE = 8'd5;
parameter REGFETCH = 8'd6;
parameter EXECUTE = 8'd7;
parameter WRITEBACK = 8'd8;
parameter LOAD = 8'd9;
parameter LOAD1 = 8'd10;
parameter LOAD2 = 8'd11;
parameter LOAD3 = 8'd12;
parameter LOAD4 = 8'd13;
parameter LOAD5 = 8'd14;
parameter LOAD6 = 8'd15;
parameter STORE = 8'd17;
parameter STORE1 = 8'd18;
parameter STORE2 = 8'd19;
parameter STORE3 = 8'd20;
parameter STORE4 = 8'd21;
parameter STORE5 = 8'd22;
parameter STORE6 = 8'd23;
parameter MULDIV1 = 8'd25;
parameter FLOAT = 8'd26;
parameter REGFETCH2 = 8'd30;
parameter REGFETCH3 = 8'd31;
parameter REGFETCH4 = 8'd32;
parameter REGFETCH5 = 8'd33;

integer n;
wire clk_g;
reg nmi;
reg MachineMode;
reg [39:0] ir;
reg illegal_insn;
reg [31:0] ip;
reg [31:0] iip;				// ip of instruction being processed
reg [31:0] sel;
reg [6:0] opcode;
reg [6:0] fpopcode;
reg [5:0] funct;
reg [2:0] funct3;
reg [4:0] fltFunct5;
reg [2:0] rm3;
reg [3:0] cond4;
reg [2:0] cond3;
reg [1:0] cond2;
reg [31:0] btgt;			// branch target
reg [6:0] bitno;
reg [11:0] csrno;
reg [2:0] csrop;
reg [6:0] shamt;			// shift amount
reg isVecInsn;
reg [5:0] Rs1, Rs2, Rs3, Rd;
reg [5:0] regset;
reg [12:0] Rn;
reg wrrf;
reg [7:0] acnt;

wire [127:0] rfo;
nvio2_regfile urf1 (.clk(clk_g), .wr(wrrf), .adr(Rn), .i(res), .o(rfo));
reg [63:0] Vm [0:7];	// vector mask registers
reg Vmp;							// vector mask predicate
reg [63:0] Vma, Vmb;

/*
(* ram_style="distributed" *)
reg [127:0] regfile [0:127];
wire [127:0] rfoa = regfile[Rs1];
wire [127:0] rfob = regfile[Rs2];
wire [127:0] rfoc = regfile[Rs3];
always @(posedge clk_i)
	if (wrrf)
		regfile[Rd] <= res;
*/
reg [127:0] a, b, c, res, imm;
reg resp, ap, bp;

reg [7:0] vl;
reg [5:0] vens, vent;
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi;
reg [31:0] mtimecmp;
reg [63:0] instret;
reg [63:0] mtick;
reg [127:0] mscratch;
reg [127:0] mstatus;
reg [31:0] mtvec;
reg [31:0] meip;
reg [31:0] mcause;
reg [127:0] cmdparm [0:7];
reg [2:0] rm;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};

function [15:0] fnSelect;
input [39:0] ins;
case(ins[6:0])
`LDB,`LDBU,`STB:	fnSelect = 16'h0001;
`LDW,`LDWU,`STW:	fnSelect = 16'h0003;
`LDT,`LDTU,`STT:	fnSelect = 16'h000F;
`LDO,`LDOU,`STO:	fnSelect = 16'h00FF;
`LDH,`LDHR,`STH,`STHC:	fnSelect = 16'hFFFF;
`LDFS,`STFS:			fnSelect = 16'h000F;
`LDFD,`STFD:			fnSelect = 16'h00FF;
`LDFQ,`STFQ:			fnSelect = 16'hFFFF;
`MLX:
	case(ins[39:34])
	`LDBX,`LDBUX:	fnSelect = 16'h0001;
	`LDWX,`LDWUX:	fnSelect = 16'h0003;
	`LDTX,`LDTUX:	fnSelect = 16'h000F;
	`LDOX,`LDOUX:	fnSelect = 16'h00FF;
	`LDHX,`LDHRX:	fnSelect = 16'hFFFF;
	`LDFSX:				fnSelect = 16'h000F;
	`LDFDX:				fnSelect = 16'h00FF;
	`LDFQX:				fnSelect = 16'hFFFF;
	default:	fnSelect = 16'h0000;
	endcase
`MSX:
	case(ins[39:34])
	`STBX:	fnSelect = 16'h0001;
	`STWX:	fnSelect = 16'h0003;
	`STTX:	fnSelect = 16'h000F;
	`STOX:	fnSelect = 16'h00FF;
	`STHX:	fnSelect = 16'hFFFF;	
	`STFSX:	fnSelect = 16'h000F;
	`STFDX:	fnSelect = 16'h00FF;
	`STFQX:	fnSelect = 16'hFFFF;
	default:	fnSelect = 16'h0000;
	endcase
default:	fnSelect = 16'h0000;
endcase
endfunction

reg [2:0] Sc;
reg [31:0] sel;
reg [31:0] ea;

reg [255:0] wdat;
reg [255:0] dil;
wire [127:0] dati = dat_i >> {adr_o[3:0],3'b0};

wire isVCmprss = opcode==`VEC2 && Rs3==`VEC1 && Rs2==`VCMPRSS;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide support logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire mulss = opcode==`MULI || (opcode==`R3 && funct==`MUL);
wire [255:0] mulo;
mult128x128 umul1 (.clk(clk_i), .ce(1'b1), .ss(mulss), .su(1'b0), .a(a), .b(b), .p(mulo));

reg sgn, ld;
wire [WID*2-1:0] div_q;
wire [WID*2-1:0] ndiv_q = -div_q;
wire [WID-1:0] div_r;
wire [WID-1:0] ndiv_r = -div_r;
divr16 #(WID) u16 (
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.ld(ld),
	.a(a),
	.b(b),
	.q(div_q),
	.r(div_r),
	.done()
);

wire [255:0] shlo = a << b[6:0];
wire [255:0] shro = {a,128'd0} >> b[6:0];
wire [127:0] rolo = shlo[255:128] | shlo[127:0];
wire [127:0] roro = shro[255:128] | shro[127:0];

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
wire a_inf, a_xz, a_vz;
wire a_qnan, a_snan, a_nan;
wire b_qnan, b_snan, b_nan;
wire finf, fdn;
always @(posedge clk_g)
	ld1 <= ld;
fpDecomp #(FPWID) u12 (.i(a), .sgn(), .exp(), .man(), .fract(), .xz(a_xz), .mz(), .vz(a_vz), .inf(a_inf), .xinf(), .qnan(a_qnan), .snan(a_snan), .nan(a_nan));
fpDecomp #(FPWID) u13 (.i(b), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(b_qnan), .snan(b_snan), .nan(b_nan));
fpCompare #(.FPWID(FPWID)) u1 (.a(a), .b(b), .o(fcmp_o), .nan(cmpnan), .snan(cmpsnan));
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f #(.FPWID(FPWID)) u2 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(ia), .o(itof_res));
f2i #(.FPWID(FPWID)) u3 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .i(a), .o(ftoi_res), .overflow());
fpAddsub #(.FPWID(FPWID)) u4 (.clk(clk_g), .ce(1'b1), .rm(rmq), .op((fpopcode==`FLT2 || fpopcode==`FLT2I)&& fltFunct5==`FSUB), .a(a), .b(b), .o(fas_o));
fpMul #(.FPWID(FPWID)) u5 (.clk(clk_g), .ce(1'b1), .a(a), .b(b), .o(fmul_o), .sign_exe(), .inf(), .overflow(nmul_of), .underflow(mul_uf));
fpDiv #(.FPWID(FPWID)) u6 (.rst(rst_i), .clk(clk_g), .clk4x(1'b0), .ce(1'b1), .ld(ld), .op(1'b0),
	.a(a), .b(b), .o(fdiv_o), .done(), .sign_exe(), .overflow(div_of), .underflow(div_uf));
fpSqrt #(.FPWID(FPWID)) u7 (.rst(rst_i), .clk(clk_g), .ce(1'b1), .ld(ld),
	.a(a), .o(fsqrt_o), .done(sqrt_done), .sqrinf(sqrinf), .sqrneg(sqrneg));
wire fms = fpopcode==`FLT3 && (funct3==`FMS || funct3==`FNMS);
wire fna = fpopcode==`FLT3 && (funct3==`FNMA || funct3==`FNMS);
fpFMA #(.FPWID(FPWID)) u14
(
	.clk(clk),
	.ce(1'b1),
	.op(fms),
	.rm(rmq),
	.a(fna ? {~a[FPWID-1],a[FPWID-2:0]} : a),
	.b(b),
	.c(c),
	.o(fma_o),
	.under(fma_uf),
	.over(),
	.inf(),
	.zero()
);

always @(posedge clk_g)
case(fpopcode)
`FLT3:
	case(funct3)
	`FMA,`FMS,`FNMA,`FNMS:
		fnorm_i <= fma_o;
	default:	;
	endcase
`FLT2,`FLT2I:
	case(fltFunct5)
	`FADD:	fnorm_i <= fas_o;
	`FSUB:	fnorm_i <= fas_o;
	`FMUL:	fnorm_i <= fmul_o;
	`FDIV:	fnorm_i <= fdiv_o;
	default:	;
	endcase
`FLT1:
	case(fltFunct5)
	`FSQRT:	fnorm_i <= fsqrt_o;
	default:	fnorm_i <= 1'd0;
	endcase
default:	fnorm_i <= 1'd0;
endcase
reg fnorm_uf;
wire norm_uf;
always @(posedge clk_g)
case(fpopcode)
`FLT1:
	case(funct3)
	`FMA,`FMS,`FNMA,`FNMS:
		fnorm_uf <= fma_uf;
	default:	;
	endcase
`FLT2,`FLT2I:
	case(fltFunct5)
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
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [6:0] Vpop;
cntpop64 upopcnt1 (
	.i(Vma),
	.o(Vpop)
);

wire v2bits = opcode==`VEC2 && Rs3==6'h01 && Rs2==`V2BITS;
wire bits2v = opcode==`VEC2 && Rs3==6'h01 && Rs2==`BITS2V;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Timers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_g)
if (rst_i)
	mtick <= 64'd0;
else
	mtick <= mtick + 2'd1;

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
	if (set_wfi)
		wfi <= 1'b1;
	if (|irq_i|pe_nmi)
		wfi <= 1'b0;
end

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Main state machine
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_g)
if (rst_i) begin
	MachineMode <= 1'b1;
	wrrf <= 1'b0;
	ip <= RSTIP;
	mtvec <= 32'hFFFC0000;
	illegal_insn <= 1'b0;
	instret = 64'd0;
	vl <= 8'd0;
	vent <= 6'd0;
	vens <= 6'd0;
	regset <= 6'd0;
	state <= IFETCH;
end
else begin
wrrf <= 1'b0;
ld <= 1'b0;
case(state)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Instruction fetch.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
IFETCH:
	begin
		nmi <= nmi_i;
		res <= 128'd0;
		if (~ack_i) begin
			illegal_insn <= 1'b1;
			vpa_o <= HIGH;
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 16'h1F << ip[3:0];
			sel <= 32'h1F << ip[3:0];
			adr_o <= ip;
			ip <= ip + 4'd5;
			iip <= ip;
			goto (IFETCH2);
		end
	end
IFETCH2:
	if (ack_i) begin
		stb_o <= LOW;
		ir <= dati;
		if (|sel[31:16]) begin
			goto(IFETCH3);
		end
		else begin
			vpa_o <= LOW;
			cyc_o <= LOW;
			sel_o <= 16'h0;
			goto(DECODE);
		end
	end
IFETCH3:
	begin
		stb_o <= HIGH;
		sel_o <= sel[31:16];
		adr_o <= {adr_o[31:4]+2'd1,4'h0};
		goto (IFETCH4);
	end
IFETCH4:
	if (ack_i) begin
		vpa_o <= LOW;
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 16'h0;
		case(sel[31:16])
		16'h0001:	ir[39:32] <= dat_i[7:0];
		16'h0003:	ir[39:24] <= dat_i[15:0];
		16'h0007: ir[39:16] <= dat_i[23:0];
		16'h000F: ir[39:8] <= dat_i[31:0];
		default:	ir <= `FLT_IFETCH;
		endcase
		goto (DECODE);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
DECODE:
	begin
		goto (REGFETCH);
		opcode <= ir[6:0];
		funct <= ir[39:34];
		case(ir[6:0])
		`STB,`STW,`STT,`STO,`STH,`STHC,`MSX,
		`STFS,`STFD,`STFQ:
			Rd <= 7'd0;
		`Bcc,`FBcc,`BBc,`BEQI,`BNEI,`BRG,`NOP,`BMISC1:
			Rd <= 7'd0;
		`CALL:
			Rd <= {6'd61};
		`BMISC2:
			case(ir[39:36])
			`SEI:	Rd <= {ir[12:7]};
			default:	Rd <= 7'd0;
			endcase
		`LILD,`LIAS1,`LIAS2,`LIAS3:
			Rd <= {ir[7] ? 6'd54 : 6'd53};
		default:
			Rd <= {ir[12:7]};
		endcase
		case(ir[6:0])
		`LILD,`LIAS1,`LIAS2,`LIAS3:
			Rs1 <= {ir[7] ? 6'd54 : 6'd53};
		default:
			Rs1 <= {ir[18:13]};
		endcase
		Rs2 <= {ir[24:19]};
		Rs3 <= {ir[30:25]};
		case(ir[6:0])
		`MLX:	imm <= {{122{ir[24]}},ir[29:24]};
		`MSX:	imm <= {{122{ir[5]}},ir[5:0]};
		`CHKI,
		`STB,`STW,`STT,`STO,`STH,`STHC,
		`STFS,`STFD,`STFQ:
			imm <= {{107{ir[39]}},ir[39:25],ir[5:0]};
		`LILD:	imm <= {{96{ir[39]}},ir[39],ir[18:8],ir[38:19]};
		`LIAS1:	imm <= {{64{ir[39]}},ir[39],ir[18:8],ir[38:19],32'h0};
		`LIAS2:	imm <= {{32{ir[39]}},ir[39],ir[18:8],ir[38:19],64'h0};
		`LIAS3:	imm <= {ir[39],ir[18:8],ir[38:19],96'h0};
		`BEQI,`BNEI:	imm <= {{119{ir[24]}},ir[24:19],ir[9:7]};
		`RET:		imm <= {109'd0,ir[39:25],4'h0};
		`CSR:		imm <= {ir[34:31],ir[18:13]};
		default:	imm <= {{107{ir[39]}},ir[39:19]};
		endcase
		Sc <= ir[33:31];
		cond4 <= ir[10:7];
		cond3 <= ir[9:7];
		cond2 <= ir[8:7];
		btgt <= {{17{ir[39]}},ir[39:25]};
		bitno <= {ir[24:19],ir[9]};
		csrno <= ir[30:19];
		csrop <= ir[39:37];
		funct3 <= ir[39:37];
		fltFunct5 <= ir[29:25];
		rm3 <= ir[33:31];
		shamt <= ir[25:19];
		isVecInsn <= ir[6:0]==7'h39 || ir[6:0]==7'h3A || ir[6:0]==7'h3B;
		if (ir[7:0]==8'hE7) begin
			ip <= iip + 2'd1;
			goto (IFETCH);
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Fetch register values. Done serially since there are a large number of
// registers and we don't want to replicate the register file to increase the
// number of available ports.
// There is a two cycle read latency for the register file. Access is
// pipelined here. The register is specified then two cycles later the value
// latched. In the meantime new register specs are taking place.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
REGFETCH:	// <= a vector instruction loops back to here
	begin
		case(opcode)
		`MLX:	Vmp <= Vm[ir[21:19]][vens];
		`MSX:	Vmp <= Vm[ir[9:7]][vens];
		`AMO:	Vmp <= Vm[ir[27:25]][vens];
		default:	Vmp <= Vm[ir[39:37]][vens];
		endcase
		Rn <= {isVecInsn & ~bits2v,isVecInsn & ~bits2v ? vens : regset,Rs1};
		Vma <= Vm[Rs1[2:0]];
		Vmb <= Vm[Rs2[2:0]];
		goto (REGFETCH2);
	end
REGFETCH2:
	begin
		Rn <= {isVecInsn,isVecInsn ? vens : regset,Rs2};
		goto (REGFETCH3);
	end
REGFETCH3:
	begin
		case(opcode)
		`CSR:
			casez(csrop)
			3'b1??:		a <= imm;
			default:	a <= rfo;
			endcase
		default:	a <= rfo;
		endcase
		Rn <= {isVecInsn,isVecInsn ? vens : regset,Rs3};
		goto (REGFETCH4);
	end
REGFETCH4:
	begin
		case(opcode)
		`MULI,`MULUI,`DIVI,`DIVUI:	b <= imm;
		`R3:
			case(funct)
			`SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI:
				b <= shamt;
			default:	b <= rfo;
			endcase
		default:
			b <= rfo;
		endcase
		Rn <= {isVecInsn & ~v2bits,isVecInsn & ~v2bits ? vent : regset,Rd};
		goto (REGFETCH5);
	end
REGFETCH5:
	begin
		c <= rfo;
		goto (EXECUTE);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
EXECUTE:
	begin
		goto (IFETCH);
		fpopcode <= opcode;
		case(opcode)
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		// Memory
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		`LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDO,`LDOU,`LDH,`LDHR,
		`LDFS,`LDFD,`LDFQ:
			begin
				ea <= a + imm;
				illegal_insn <= 1'b0;
				goto (LOAD);
			end
		`MLX:
			begin
				ea <= a + (c << Sc) + imm;
				illegal_insn <= 1'b0;
				goto (LOAD);
			end
		`STB,`STW,`STT,`STO,`STH,`STHC,
		`STFS,`STFD,`STFQ:
			begin
				ea <= a + imm;
				illegal_insn <= 1'b0;
				goto (STORE);
			end
		`MSX:
			begin
				ea <= a + (c << Sc) + imm;
				illegal_insn <= 1'b0;
				goto (STORE);
			end
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		// Integer
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		`LILD:	begin res <= imm; wrrf <= 1'b1; illegal_insn <= 1'b0; end
		`LIAS1,`LIAS2,`LIAS3:
			begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0;end
		`MULI:	begin
							sgn <= a[127] ^ b[127];
							if (a[127]) a <= -a;
							if (b[127]) b <= -b;
							illegal_insn <= 1'b0;
							ld <= 1'b1;
							acnt <= 8'd20;
							goto (MULDIV1);
						end
		`MULUI:	begin
							sgn <= 1'b0;
						 	illegal_insn <= 1'b0;
							ld <= 1'b1;
						 	acnt <= 8'd20;
						 	goto (MULDIV1);
						end
		`DIVI,`MODI:
						begin
							sgn <= a[127] ^ b[127];
							if (a[127]) a <= -a;
							if (b[127]) b <= -b;
							illegal_insn <= 1'b0;
							ld <= 1'b1;
							acnt <= 8'd36;
							goto (MULDIV1);
						end
		`DIVUI,`MODUI:
						begin
							sgn <= 1'b0;
							illegal_insn <= 1'b0;
							ld <= 1'b1;
							acnt <= 8'd36;
							goto (MULDIV1);
						end
		`ADDI:	begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`LEA:		begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= 1'b1; end
		`ANDI:	begin res <= a & imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`ORI:		begin res <= a | imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`XORI:	begin res <= a ^ imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`DIF:		begin res <= $signed(a) > $signed(imm) ? a - imm : imm - a; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SLTI:	begin res <= $signed(a) < $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SLEI:	begin res <= $signed(a) <= $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SGTI:	begin res <= $signed(a) > $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SGEI:	begin res <= $signed(a) >= $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SLTUI:	begin res <= a < imm; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SLEUI:	begin res <= a <= imm; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SGTUI:	begin res <= a > imm; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SGEUI:	begin res <= a >= imm; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SEQI:	begin res <= a == imm; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`SNEI:	begin res <= a != imm; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
		`CMPI:	begin res <= $signed(a) < $signed(imm) ? -128'd1 : a==imm ? 128'd0 : 128'd1; illegal_insn <= 1'b0; wrrf <= 1'b1; end
		`CMPUI:	begin res <= a < imm ? -128'd1 : a==imm ? 128'd0 : 128'd1; illegal_insn <= 1'b0; wrrf <= 1'b1; end
		`R3:
			case(funct)
			`ADD:	begin res <= a + b; illegal_insn <= 1'b0; resp <= ap ^ bp; wrrf <= 1'b1; end
			`SUB:	begin res <= a - b; illegal_insn <= 1'b0; resp <= ap ^ bp; wrrf <= 1'b1; end
			`AND:	begin res <= a & b; illegal_insn <= 1'b0; resp <= ap | bp; wrrf <= 1'b1; end
			`OR:	begin res <= a | b; illegal_insn <= 1'b0; resp <= ap | bp; wrrf <= 1'b1; end
			`XOR:	begin res <= a ^ b; illegal_insn <= 1'b0; resp <= ap | bp; wrrf <= 1'b1; end
			`SLT:	begin res <= $signed(a) < $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SLE:	begin res <= $signed(a) <= $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SGT:	begin res <= $signed(a) > $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SGE:	begin res <= $signed(a) >= $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SLTU:	begin res <= a < b; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SLEU:	begin res <= a <= b; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SGTU:	begin res <= a > b; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SGEU:	begin res <= a >= b; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SEQ:	begin res <= a == b; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`SNE:	begin res <= a != b; illegal_insn <= 1'b0; resp <= 1'b0; wrrf <= 1'b1; end
			`CMP:	begin res <= $signed(a) < $signed(b) ? -128'd1 : a==b ? 128'd0 : 128'd1; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			`CMPU:	begin res <= a < b ? -128'd1 : a==b ? 128'd0 : 128'd1; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			`SHL,`SHLI:		begin res <= shlo[127:0]; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			`ASL,`ASLI:		begin res <= shlo[127:0]; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			`SHR,`SHRI:		begin res <= shro[255:128]; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			`ASR,`ASRI:
				begin
					if (a[WID-1])
						res <= shro[255:128] | ~({WID{1'b1}} >> b[6:0]);
					else
						res <= shro[255:128];
				end
			`ROL,`ROLI:	begin res <= rolo; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			`ROR,`RORI:	begin res <= roro; illegal_insn <= 1'b0; wrrf <= 1'b1; end
			default:	;
			endcase
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		// Floating-point
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		`FLT3:
			case(funct3)
			`FMA,`FMS,`FNMA,`FNMS:
				begin
					mathCnt <= 8'd45;
					goto (FLOAT);
					illegal_insn <= 1'b0;
				end
			// The timeouts for the float operations are set conservatively. They may
			// be adjusted to lower values closer to actual time required.
			`FLT2,`FLT2I:	// Float
				case(Rs3)
				`FADD:	begin mathCnt <= 8'd30; goto (FLOAT); illegal_insn <= 1'b0; end	// FADD
				`FSUB:	begin mathCnt <= 8'd30; goto (FLOAT); illegal_insn <= 1'b0; end	// FSUB
				`FMUL:	begin mathCnt <= 8'd30; goto (FLOAT); illegal_insn <= 1'b0; end	// FMUL
				`FDIV:	begin mathCnt <= 8'd40; goto (FLOAT); illegal_insn <= 1'b0; end	// FDIV
				`FMAX:	begin mathCnt <= 8'd03; goto (FLOAT); illegal_insn <= 1'b0; end	// FMAX
				`FMIN:	begin mathCnt <= 8'd03; goto (FLOAT); illegal_insn <= 1'b0; end	// FMIN
				`FSLE:	begin mathCnt <= 8'd03; goto (FLOAT); illegal_insn <= 1'b0; end	// FSLE
				`FSLT:	begin mathCnt <= 8'd03; goto (FLOAT); illegal_insn <= 1'b0; end	// FSLT
				`FSEQ:	begin mathCnt <= 8'd03; goto (FLOAT); illegal_insn <= 1'b0; end	// FSEQ
				`FSNE:	begin mathCnt <= 8'd03; goto (FLOAT); illegal_insn <= 1'b0; end	// FSEQ
				`FLT1:
					case(fltFunct5)
					`FSQRT:	begin mathCnt <= 8'd160; goto (FLOAT); illegal_insn <= 1'b0; end	// FSQRT
					`FSGNOP:	
						case(funct3)
						3'd0:	begin res <= {b[FPWID-1],a[FPWID-1:0]}; illegal_insn <= 1'b0; wrrf <= 1'b1; end		// FSGNCPY
						3'd1:	begin res <= {~b[FPWID-1],a[FPWID-1:0]}; illegal_insn <= 1'b0; wrrf <= 1'b1; end	// FSGNINV
						3'd6:	begin res <= {b[FPWID-1]^a[FPWID-1],a[FPWID-1:0]}; illegal_insn <= 1'b0; wrrf <= 1'b1; end	// FSGNXOR
						default:	;
						endcase
					`FCVTI2F:	begin mathCnt <= 8'd05; goto (FLOAT); illegal_insn <= 1'b0; end
					`FCVTF2I:	begin mathCnt <= 8'd05; goto (FLOAT); illegal_insn <= 1'b0; end
					`FCVTSQ:	begin mathCnt <= 8'd05; goto (FLOAT); illegal_insn <= 1'b0; end
					`FCVTQS:	begin mathCnt <= 8'd05; goto (FLOAT); illegal_insn <= 1'b0; end
					`FCVTDQ:	begin mathCnt <= 8'd05; goto (FLOAT); illegal_insn <= 1'b0; end
					`FCVTQD:	begin mathCnt <= 8'd05; goto (FLOAT); illegal_insn <= 1'b0; end
					`FCLASS:
						begin
							res[0] <= a[FPWID-1] & a_inf;
							res[1] <= a[FPWID-1] & !a_xz;
							res[2] <= a[FPWID-1] &  a_xz;
							res[3] <= a[FPWID-1] &  a_vz;
							res[4] <= ~a[FPWID-1] &  a_vz;
							res[5] <= ~a[FPWID-1] &  a_xz;
							res[6] <= ~a[FPWID-1] & !a_xz;
							res[7] <= ~a[FPWID-1] & a_inf;
							res[8] <= a_snan;
							res[9] <= a_qnan;
							wrrf <= 1'b1;
							illegal_insn <= 1'b0;
						end
					default:	;
					endcase
				default:	;
				endcase
			default:	;
			endcase

		`CSR:
			begin
				casez(csrno)
				12'h001:  begin res <= hartid_i; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h002:	begin res <= mtick; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h006:	begin res <= mcause; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h009:	begin res <= mscratch; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'b0000_0011_1???:	begin res <= cmdparm[csrno[2:0]]; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h044:	begin res <= mstatus; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'hFE1:	begin res <= instret; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				endcase
				case(csrop[1:0])
				2'd0:	;
				2'd1:
					casez(csrno)
					12'h006:	mcause <= a;
					12'h009:	mscratch <= a;
					12'b0000_0011_1???:	cmdparm[csrno[2:0]] <= a;
					12'h044:	mstatus <= a;
					endcase
				2'd2:	
					casez(csrno)
					12'h044:	mstatus <= mstatus | a;
					default:	;
					endcase
				2'd3:
					casez(csrno)
					12'h044:	mstatus <= mstatus & ~a;
					default:	;
					endcase
				endcase
			end

		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		// Flow control (branch unit)
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		`Bcc:
			case(cond3)
			`BEQ:	begin if (a==b) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`BNE:	begin if (a!=b) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`BLT:	begin if ($signed(a) < $signed(b)) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`BGE:	begin if ($signed(a) >= $signed(b)) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`BLTU:	begin if (a < b) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`BGEU:	begin if (a >= b) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			default:	;
			endcase
		`FBcc:
			case(cond3)
			`FBEQ:	begin if ( fcmp_o[0] & ~cmpnan) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`FBNE:	begin if (~fcmp_o[0] & ~cmpnan) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`FBLT:	begin if ( fcmp_o[1] & ~cmpnan) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`FBLE:	begin if ( fcmp_o[2] & ~cmpnan) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			`FBUN:	begin if ( cmpnan) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			default:	;
			endcase
		`BRG:
			case(cond4)
			`BREQ:	begin if (a==b) begin ip <= c; end illegal_insn <= 1'b0; end
			`BRNE:	begin if (a!=b) begin ip <= c; end illegal_insn <= 1'b0; end
			`BRLT:	begin if ($signed(a) < $signed(b)) begin ip <= c; end illegal_insn <= 1'b0; end
			`BRGE:	begin if ($signed(a) >= $signed(b)) begin ip <= c; end illegal_insn <= 1'b0; end
			default:	;
			endcase
		`BBc:
			case(cond2)
			2'd0:	begin if ( a[bitno]) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			2'd1:	begin if (!a[bitno]) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			default:	;
			endcase
		`BEQI:	begin if (a==imm) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
		`BNEI:	begin if (a!=imm) begin ip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
		`JAL:		begin ip <= a + imm; res <= ip; illegal_insn <= 1'b0; wrrf <= 1'b1; end
		`JMP:		begin ip <= ir[38:7]; illegal_insn <= 1'b0; end
		`CALL:	begin ip <= ir[38:7]; illegal_insn <= 1'b0; res <= ip; wrrf <= 1'b1; end
		`RET:		begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= 1'b1; end

		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		// Vector
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
		`VFMA,`VFMS,`VFNMA,`VFNMS:
			begin
				illegal_insn <= 1'b0;
				if (Vmp) begin
					mathCnt <= 8'd45;
					goto (FLOAT);
				end
			end
		`VEC2:
			if (Rs3[5:0]==`VEC1) begin
				case(Rs2[5:0])
				`VCMPRSS:	begin res <= a; wrrf <= Vmp; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
			else begin
				if (rm3==3'd6) begin
					case(Rs3)
					6'h01:
						case(Rs2)
						`V2BITS:
							begin 
								res[vent] <= Vmp ? a[0] : 1'b0;
								if (vent+2'd1==vl)
									wrrf <= 1'b1;
								illegal_insn <= 1'b0;
							end
						`BITS2V:
							begin
								res <= Vmp ? a[vens] : 1'b0;
								wrrf <= Vmp;
								illegal_insn <= 1'b0;
							end
						`VMAND:	begin Vm[Rd[2:0]] <= Vma & Vmb; illegal_insn <= 1'b0; end
						`VMOR:	begin Vm[Rd[2:0]] <= Vma | Vmb; illegal_insn <= 1'b0; end
						`VMXOR:	begin Vm[Rd[2:0]] <= Vma ^ Vmb; illegal_insn <= 1'b0; end
						`VMXNOR:	begin Vm[Rd[2:0]] <= ~(Vma ^ Vmb); illegal_insn <= 1'b0; end
						`VMFIRST:
							begin
								res <= 8'd64;
								for (n = 64; n >= 0; n = n - 1) begin
									if (Vma[n])
										res <= n;
								end
								wrrf <= 1'b1;
								illegal_insn <= 1'b0;
							end
						`VMLAST:
							begin
								res <= 8'd0;
								for (n = 0; n < 64; n = n + 1) begin
									if (Vma[n])
										res <= n;
								end
								wrrf <= 1'b1;
								illegal_insn <= 1'b0;
							end
						`VMPOP:	begin res <= Vpop; wrrf <= 1'b1; illegal_insn <= 1'b0; end
						`VMFILL:
							begin
								for (n = 0; n < 64; n = n + 1)
									Vm[Rd[2:0]][n] <= n < a[6:0];
								illegal_insn <= 1'b0;
							end
						endcase
					`ADD:	begin res <= a + b; wrrf <= Vmp; illegal_insn <= 1'b0; resp <= ap ^ bp; end
					`SUB:	begin res <= a - b; wrrf <= Vmp; illegal_insn <= 1'b0; resp <= ap ^ bp; end
					`AND:	begin res <= a & b; wrrf <= Vmp; illegal_insn <= 1'b0; resp <= ap | bp; end
					`OR:	begin res <= a | b; wrrf <= Vmp; illegal_insn <= 1'b0; resp <= ap | bp; end
					`XOR:	begin res <= a ^ b; wrrf <= Vmp; illegal_insn <= 1'b0; resp <= ap | bp; end
					`SLT:	begin if (Vmp) Vm[Rd[2:0]][vent] <= $signed(a) < $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; end
					`SLE:	begin if (Vmp) Vm[Rd[2:0]][vent] <= $signed(a) <= $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; end
					`SGT:	begin if (Vmp) Vm[Rd[2:0]][vent] <= $signed(a) > $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; end
					`SGE:	begin if (Vmp) Vm[Rd[2:0]][vent] <= $signed(a) >= $signed(b); illegal_insn <= 1'b0; resp <= 1'b0; end
					`SLTU:	begin if (Vmp) Vm[Rd[2:0]][vent] <= a < b; illegal_insn <= 1'b0; resp <= 1'b0; end
					`SLEU:	begin if (Vmp) Vm[Rd[2:0]][vent] <= a <= b; illegal_insn <= 1'b0; resp <= 1'b0; end
					`SGTU:	begin if (Vmp) Vm[Rd[2:0]][vent] <= a > b; illegal_insn <= 1'b0; resp <= 1'b0; end
					`SGEU:	begin if (Vmp) Vm[Rd[2:0]][vent] <= a >= b; illegal_insn <= 1'b0; resp <= 1'b0; end
					`SEQ:	begin if (Vmp) Vm[Rd[2:0]][vent] <= a == b; illegal_insn <= 1'b0; resp <= 1'b0; end
					`SNE:	begin if (Vmp) Vm[Rd[2:0]][vent] <= a != b; illegal_insn <= 1'b0; resp <= 1'b0; end
					`CMP:	begin res <= $signed(a) < $signed(b) ? -128'd1 : a==b ? 128'd0 : 128'd1;  wrrf <= Vmp; illegal_insn <= 1'b0; end
					`CMPU:	begin res <= a < b ? -128'd1 : a==b ? 128'd0 : 128'd1; wrrf <= Vmp; illegal_insn <= 1'b0; end
					`SHL,`SHLI:		begin res <= shlo[127:0]; wrrf <= Vmp; illegal_insn <= 1'b0; end
					`ASL,`ASLI:		begin res <= shlo[127:0]; wrrf <= Vmp; illegal_insn <= 1'b0; end
					`SHR,`SHRI:		begin res <= shro[255:128]; wrrf <= Vmp; illegal_insn <= 1'b0; end
					`ASR,`ASRI:
						begin
							if (a[WID-1])
								res <= shro[255:128] | ~({WID{1'b1}} >> b[6:0]);
							else
								res <= shro[255:128];
							wrrf <= Vmp;
							illegal_insn <= 1'b0;
						end
					`ROL,`ROLI:	begin res <= rolo; illegal_insn <= 1'b0; wrrf <= Vmp; end
					`ROR,`RORI:	begin res <= roro; illegal_insn <= 1'b0; wrrf <= Vmp; end
					default:	;
					endcase
				end
				else begin
					case(Rs3)
					`FADD:	begin if (Vmp) begin mathCnt <= 8'd30; goto (FLOAT); end illegal_insn <= 1'b0; end	// FADD
					`FSUB:	begin if (Vmp) begin mathCnt <= 8'd30; goto (FLOAT); end illegal_insn <= 1'b0; end	// FSUB
					`FMUL:	begin if (Vmp) begin mathCnt <= 8'd30; goto (FLOAT); end illegal_insn <= 1'b0; end	// FMUL
					`FDIV:	begin if (Vmp) begin mathCnt <= 8'd40; goto (FLOAT); end illegal_insn <= 1'b0; end	// FDIV
					`FMAX:	begin if (Vmp) begin mathCnt <= 8'd03; goto (FLOAT); end illegal_insn <= 1'b0; end	// FMAX
					`FMIN:	begin if (Vmp) begin mathCnt <= 8'd03; goto (FLOAT); end illegal_insn <= 1'b0; end	// FMIN
					`FSLE:	begin if (Vmp) begin mathCnt <= 8'd03; goto (FLOAT); end illegal_insn <= 1'b0; end	// FSLE
					`FSLT:	begin if (Vmp) begin mathCnt <= 8'd03; goto (FLOAT); end illegal_insn <= 1'b0; end	// FSLT
					`FSEQ:	begin if (Vmp) begin mathCnt <= 8'd03; goto (FLOAT); end illegal_insn <= 1'b0; end	// FSEQ
					`FSNE:	begin if (Vmp) begin mathCnt <= 8'd03; goto (FLOAT); end illegal_insn <= 1'b0; end	// FSEQ
					`FLT1:
						case(Rs2)
						`FSQRT:	begin if (Vmp) begin mathCnt <= 8'd160; goto (FLOAT); end illegal_insn <= 1'b0; end	// FSQRT
						`FSGNOP:	
							case(funct3)
							3'd0:	begin res <= {b[FPWID-1],a[FPWID-1:0]}; illegal_insn <= 1'b0; wrrf <= Vmp; end		// FSGNCPY
							3'd1:	begin res <= {~b[FPWID-1],a[FPWID-1:0]}; illegal_insn <= 1'b0; wrrf <= Vmp; end	// FSGNINV
							3'd6:	begin res <= {b[FPWID-1]^a[FPWID-1],a[FPWID-1:0]}; illegal_insn <= 1'b0; wrrf <= Vmp; end	// FSGNXOR
							default:	;
							endcase
						`FCVTI2F:	begin if (Vmp) begin mathCnt <= 8'd05; goto (FLOAT); end illegal_insn <= 1'b0; end
						`FCVTF2I:	begin if (Vmp) begin mathCnt <= 8'd05; goto (FLOAT); end illegal_insn <= 1'b0; end
						`FCVTSQ:	begin if (Vmp) begin mathCnt <= 8'd05; goto (FLOAT); end illegal_insn <= 1'b0; end
						`FCVTQS:	begin if (Vmp) begin mathCnt <= 8'd05; goto (FLOAT); end illegal_insn <= 1'b0; end
						`FCVTDQ:	begin if (Vmp) begin mathCnt <= 8'd05; goto (FLOAT); end illegal_insn <= 1'b0; end
						`FCVTQD:	begin if (Vmp) begin mathCnt <= 8'd05; goto (FLOAT); end illegal_insn <= 1'b0; end
						`FCLASS:
							begin
								res[0] <= a[FPWID-1] & a_inf;
								res[1] <= a[FPWID-1] & !a_xz;
								res[2] <= a[FPWID-1] &  a_xz;
								res[3] <= a[FPWID-1] &  a_vz;
								res[4] <= ~a[FPWID-1] &  a_vz;
								res[5] <= ~a[FPWID-1] &  a_xz;
								res[6] <= ~a[FPWID-1] & !a_xz;
								res[7] <= ~a[FPWID-1] & a_inf;
								res[8] <= a_snan;
								res[9] <= a_qnan;
								wrrf <= Vmp;
								illegal_insn <= 1'b0;
							end
						default:	;
						endcase
					default:	;
					endcase
				end
			end
		endcase
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
MULDIV1:
	begin
		acnt <= acnt - 2'd1;
		if (acnt==8'd0) begin
			goto (IFETCH);
			case(opcode)
			`MULI,`MULUI:		begin res <= mulo[127:0]; wrrf <= 1'b1; end
			`DIVI:	begin res <= sgn ? ndiv_q : div_q; wrrf <= 1'b1; end
			`MODI:	begin res <= sgn ? ndiv_r : div_q; wrrf <= 1'b1; end
			`DIVUI:	begin res <= div_q; wrrf <= 1'b1; end
			`MODUI:	begin res <= div_r; wrrf <= 1'b1; end
			//`MULHI,`MULUHI:	res <= mulo[255:128];
			`R3:
				case(funct)
				`MUL,`MULU:		begin res <= mulo[127:0]; wrrf <= 1'b1; end
				`MULH,`MULUH:	begin res <= mulo[255:128]; wrrf <= 1'b1; end
				`DIV:		begin res <= sgn ? ndiv_q : div_q; wrrf <= 1'b1; end
				`MOD:		begin res <= sgn ? ndiv_r : div_r; wrrf <= 1'b1; end
				`DIVU:	begin res <= div_q; wrrf <= 1'b1; end
				`MODU:	begin res <= div_r; wrrf <= 1'b1; end
				default:			res <= 128'd0;
				endcase
			default:	res <= mulo[127:0];
			endcase
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LOAD:
	begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= fnSelect(ir) << ea[3:0];
		sel <= fnSelect(ir) << ea[3:0];
		adr_o <= ea;
		goto (LOAD1);
	end
LOAD1:
	if (ack_i) begin
		stb_o <= LOW;
		dil[127:0] <= dat_i;
		if (|sel[31:16]) begin
			goto (LOAD2);
		end
		else begin
			cyc_o <= LOW;
			sel_o <= 16'h0;
			goto (LOAD4);
		end
	end
// Run a second bus cycle for data that crosses a 128-bit boundary.
LOAD2:
	if (~ack_i) begin
		stb_o <= HIGH;
		sel_o <= sel[31:16];
		adr_o <= {adr_o[31:4]+2'd1,4'h0};
		goto (LOAD3);
	end
LOAD3:
	if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 16'h0;
		dil[255:128] <= dat_i;
		goto (LOAD4);
	end
LOAD4:
	begin
		dil <= dil >> {ea[3:0],3'b0};
		goto (LOAD5);
	end
LOAD5:
	begin
		goto (IFETCH);
		case(opcode)
		`LDB:		begin res <= {{120{dil[7]}},dil[7:0]}; wrrf <= 1'b1; end
		`LDBU:	begin res <= {120'd0,dil[7:0]}; wrrf <= 1'b1; end
		`LDW:		begin res <= {{112{dil[15]}},dil[15:0]}; wrrf <= 1'b1; end
		`LDWU:	begin res <= {112'd0,dil[15:0]}; wrrf <= 1'b1; end
		`LDT:		begin res <= {{96{dil[31]}},dil[31:0]}; wrrf <= 1'b1; end
		`LDTU:	begin res <= {96'd0,dil[31:0]}; wrrf <= 1'b1; end
		`LDO:		begin res <= {{64{dil[63]}},dil[63:0]}; wrrf <= 1'b1; end
		`LDOU:	begin res <= {64'd0,dil[63:0]}; wrrf <= 1'b1; end
		`LDH:		begin res <= dil[127:0]; wrrf <= 1'b1; end
		`LDHR:	begin res <= dil[127:0]; wrrf <= 1'b1; end
		`LDFS:	begin a <= dil[31:0]; mathCnt <= 8'd5; fltFunct5 <= `FCVTSQ; fpopcode <= `FLT1; goto (LOAD6); end
		`LDFD:	begin a <= dil[63:0]; mathCnt <= 8'd5; fltFunct5 <= `FCVTDQ; fpopcode <= `FLT1; goto (LOAD6); end
		`LDFQ:	begin res <= dil[127:0]; wrrf <= 1'b1; end
		`MLX:
			case(ir[39:35])
			`LDBX:	begin res <= {{120{dil[7]}},dil[7:0]}; wrrf <= 1'b1; end
			`LDBUX:	begin res <= {120'd0,dil[7:0]}; wrrf <= 1'b1; end
			`LDWX:	begin res <= {{112{dil[15]}},dil[15:0]}; wrrf <= 1'b1; end
			`LDWUX:	begin res <= {112'd0,dil[15:0]}; wrrf <= 1'b1; end
			`LDTX:	begin res <= {{96{dil[31]}},dil[31:0]}; wrrf <= 1'b1; end
			`LDTUX:	begin res <= {96'd0,dil[31:0]}; wrrf <= 1'b1; end
			`LDOX:	begin res <= {{64{dil[63]}},dil[63:0]}; wrrf <= 1'b1; end
			`LDOUX:	begin res <= {64'd0,dil[63:0]}; wrrf <= 1'b1; end
			`LDHX:	begin res <= dil[127:0]; wrrf <= 1'b1; end
			`LDHRX:	begin res <= dil[127:0]; wrrf <= 1'b1; end
			`LDFSX:	begin a <= dil[31:0]; mathCnt <= 8'd5; fltFunct5 <= `FCVTSQ; fpopcode <= `FLT1; goto (LOAD6); end
			`LDFDX:	begin a <= dil[63:0]; mathCnt <= 8'd5; fltFunct5 <= `FCVTDQ; fpopcode <= `FLT1; goto (LOAD6); end
			`LDFQX:	begin res <= dil[127:0]; wrrf <= 1'b1; end
			endcase
		default:	;
		endcase
	end
LOAD6:
	begin
		mathCnt <= mathCnt - 2'd1;
		if (mathCnt==8'd0) begin
			wrrf <= 1'b1;
			res <= fres;
			goto (IFETCH);
		end
	end

STORE:
	begin
		sel <= fnSelect(ir) << ea[3:0];
		wdat <= b << {ea[3:0],3'b0};
		case(opcode)
		`STFS:
			begin
				a <= b;
				fltFunct5 <= `FCVTQS;
				fpopcode <= `FLT1; 
				goto (STORE1);
			end
		`STFD:
			begin
				a <= b;
				fltFunct5 <= `FCVTQD;
				fpopcode <= `FLT1; 
				goto (STORE1);
			end
		`MSX:
			case(ir[39:35])
			`STFSX:
				begin
					a <= b;
					fltFunct5 <= `FCVTQS;
					fpopcode <= `FLT1; 
					goto (STORE1);
				end
			`STFDX:
				begin
					a <= b;
					fltFunct5 <= `FCVTQD;
					fpopcode <= `FLT1; 
					goto (STORE1);
				end
			endcase
		default:	goto (STORE3);
		endcase
	end
STORE1:
	begin
		mathCnt <= mathCnt - 2'd1;
		if (mathCnt==8'd0) begin
			b <= fres;
			goto (STORE2);
		end
	end
STORE2:
	begin
		wdat <= b << {ea[3:0],3'b0};
		goto (STORE3);
	end
STORE3:
	begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= sel[15:0];
		adr_o <= ea;
		dat_o <= wdat[127:0];
		goto (STORE4);
	end
STORE4:
	if (ack_i) begin
		stb_o <= LOW;
		if (|sel[31:16]) begin
			goto (STORE5);
		end
		else begin
			cyc_o <= LOW;
			sel_o <= 16'h0;
			we_o <= LOW;
			goto (IFETCH);
		end
	end
// Run a second bus cycle for data that crosses a 128-bit boundary.
STORE5:
	if (~ack_i) begin
		stb_o <= HIGH;
		sel_o <= sel[31:16];
		adr_o <= {adr_o[31:4]+2'd1,4'h0};
		dat_o <= wdat[255:128];
		goto (STORE6);
	end
STORE6:
	if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 16'h0;
		goto (IFETCH);
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
			case(fpopcode)
			`VFMA,`VFMS,`VFNMA,`VFNMS:
				begin
					wrrf <= 1'b1;
					res <= fres;
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			`FLT3:
				case(funct3)
				`FMA,`FMS,`FNMA,`FNMS:
					begin
						wrrf <= 1'b1;
						res <= fres;
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FLT2,`FLT2I:
					case(fltFunct5)
					`FADD:
						begin
							wrrf <= 1'b1;
							res <= fres;	// FADD
							if (fdn) fuf <= 1'b1;
							if (finf) fof <= 1'b1;
							if (norm_nx) fnx <= 1'b1;
						end
					`FSUB:
						begin
							wrrf <= 1'b1;
							res <= fres;	// FSUB
							if (fdn) fuf <= 1'b1;
							if (finf) fof <= 1'b1;
							if (norm_nx) fnx <= 1'b1;
						end
					`FMUL:
						begin
							wrrf <= 1'b1;
							res <= fres;	// FMUL
							if (fdn) fuf <= 1'b1;
							if (finf) fof <= 1'b1;
							if (norm_nx) fnx <= 1'b1;
						end
					`FDIV:	
						begin
							wrrf <= 1'b1;
							res <= fres;	// FDIV
							if (fdn) fuf <= 1'b1;
							if (finf) fof <= 1'b1;
							if (b[FPWID-2:0]==1'd0)
								fdz <= 1'b1;
							if (norm_nx) fnx <= 1'b1;
						end
					`FMIN:
						begin
							wrrf <= 1'b1;
							if ((a_snan|b_snan)||(a_qnan&b_qnan))
								res <= 32'h7FFFFFFF;	// canonical NaN
							else if (a_qnan & !b_nan)
								res <= b;
							else if (!a_nan & b_qnan)
								res <= a;
							else if (fcmp_o[1])
								res <= a;
							else
								res <= b;
						end
					`FMAX:	// FMAX
						begin
							wrrf <= 1'b1;
							if ((a_snan|b_snan)||(a_qnan&b_qnan))
								res <= 32'h7FFFFFFF;	// canonical NaN
							else if (a_qnan & !b_nan)
								res <= b;
							else if (!a_nan & b_qnan)
								res <= a;
							else if (fcmp_o[1])
								res <= b;
							else
								res <= a;
						end
					`FSLE:	
						begin
							wrrf <= 1'b1;
							res <= fcmp_o[2] & ~cmpnan;	// FLE
							if (cmpnan)
								fnv <= 1'b1;
						end
					`FSLT:
						begin
							wrrf <= 1'b1;
							res <= fcmp_o[1] & ~cmpnan;	// FLT
							if (cmpnan)
								fnv <= 1'b1;
						end
					`FSEQ:
						begin
							wrrf <= 1'b1;
							res <= fcmp_o[0] & ~cmpnan;	// FEQ
							if (cmpsnan)
								fnv <= 1'b1;
						end
					`FLT1:
						case(fltFunct5)
						`FSQRT:
							begin
								wrrf <= 1'b1;
								res <= fres;
								if (fdn) fuf <= 1'b1;
								if (finf) fof <= 1'b1;
								if (a[FPWID-2:0]==1'd0)
									fdz <= 1'b1;
								if (sqrinf|sqrneg)
									fnv <= 1'b1;
								if (norm_nx) fnx <= 1'b1;
							end
						`FCVTF2I:	begin res <= ftoi_res; wrrf <= 1'b1; end
						`FCVTI2F:	begin res <= itof_res; wrrf <= 1'b1; end
						default:	;
						endcase
					default:	;
					endcase
				default:	;
				endcase
			default:	;
			endcase
			goto (IFETCH);
		end
	end

default:	goto(IFETCH);
endcase
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Support tasks
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

// Check for interrupts.
// Check for the previous instruction being invalid.

task goto;
input [7:0] nst;
begin
state <= nst;
if (nst==IFETCH) begin
	if (nmi_i & !nmi) begin
		illegal_insn <= 1'b0;
		regset <= 6'd0;
		MachineMode <= 1'b1;
		mcause <= 32'h8000000F;
		meip <= iip;
		ip <= mtvec + 9'h1FF;	// 65 * ol
		mstatus[11:0] <= {mstatus[8:0],3'b110};
	end
	else if (irq_i & mstatus[0]) begin
		illegal_insn <= 1'b0;
		regset <= 6'd0;
		MachineMode <= 1'b1;
		mcause <= 32'h80000003;
		meip <= iip;
		ip <= mtvec + {mstatus[2:1],4'd0,mstatus[2:1]};	// 65 * ol
		mstatus[11:0] <= {mstatus[8:0],3'b110};
	end
	else if (illegal_insn) begin
		illegal_insn <= 1'b0;
		regset <= 6'd0;
		MachineMode <= 1'b1;
		mcause <= 32'h2;
		meip <= iip;
		ip <= mtvec + {mstatus[2:1],4'd0,mstatus[2:1]};	// 65 * ol
		mstatus[11:0] <= {mstatus[8:0],3'b110};
	end
	else if (isVecInsn) begin
		if (vens + 2'd1 < vl) begin
			vens <= vens + 2'd1;
			if (isVCmprss) begin
				if (Vmp)
					vent <= vent + 2'd1;
			end
			else
				vent <= vent + 2'd1;
			state <= REGFETCH;
		end
		else begin
			vens <= 6'd0;
			vent <= 6'd0;
		end
	end
	else
		instret <= instret + 2'd1;
end
end
endtask

endmodule
