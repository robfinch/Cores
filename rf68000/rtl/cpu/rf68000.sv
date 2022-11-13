`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2008-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf68000.sv
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================
//
// Uncomment the following to optimize for performance. Increases the core size.
//`define OPT_PERF    1'b1
`define BIG_ENDIAN	1'b1

//`define SUPPORT_RETRY	1'b1
`define SUPPORT_MUL	1'b1
`define SUPPORT_DIV	1'b1
`define SUPPORT_BCD	1'b1
`define SUPPORT_010	1'b1

//`define SUPPORT_TASK	1'b1

//`define SUPPORT_B24	1'b1		// To support 23-bit branch displacements

`define TRUE        1'b1
`define FALSE       1'b0
`define HIGH        1'b1
`define LOW         1'b0

`define RESET_VECTOR	32'h00000400
`define CSR_CORENO    32'hFFFFFFE0
`define CSR_TICK        32'hFFFFFFE4
`define CSR_ICNT				32'hFFFFFFE8
`define CSR_TASK        32'hFFFFFFFC

//`define SSP_VEC       9'd000
`define RESET_VEC       9'd001
`define BUSERR_VEC      9'd002
`define ADDRERR_VEC     9'd003
`define ILLEGAL_VEC     9'd004
`define DBZ_VEC         9'd005
`define CHK_VEC         9'd006
`define TRAPV_VEC       9'd007
`define PRIV_VEC        9'd008
`define TRACE_VEC       9'd009
`define LINE10_VEC      9'd010
`define LINE15_VEC      9'd011
`define UNINITINT_VEC   9'd015
// Vectors 24-31 for IRQ's
`define SPURIOUS_VEC		9'd024
`define IRQ_VEC         9'd024
// Vectors 32-46 for TRAPQ instruction
`define TRAP_VEC        9'd032
`define DISP_VEC				9'd064
`define USER64          9'd064
//`define NMI_TRAP        9'h1FE
`define RESET_TASK      9'h000

`define	LDB		16'b0001_xxx0xx_xxxxxx
`define LDH		16'b0010_xxx0xx_xxxxxx
`define LDW		16'b0011_xxx0xx_xxxxxx
`define	STB		16'b0001_xxx1xx_xxxxxx
`define STH		16'b0010_xxx1xx_xxxxxx
`define STW		16'b0011_xxx1xx_xxxxxx

`define DBRA	8'h50
`define DBSR	8'h51
`define DBHI	8'h52
`define DBLS	8'h53
`define DBHS	8'h54
`define DBLO	8'h55
`define DBNE	8'h56
`define DBEQ	8'h57
`define DBVC	8'h58
`define DBVS	8'h59
`define DBPL	8'h5A
`define DBMI	8'h5B
`define DBGE	8'h5C
`define DBLT	8'h5D
`define DBGT	8'h5E
`define DBLE	8'h5F

`define BRA		8'h60
`define BSR		8'h61
`define BHI		8'h62
`define BLS		8'h63
`define BHS		8'h64
`define BLO		8'h65
`define BNE		8'h66
`define BEQ		8'h67
`define BVC		8'h68
`define BVS		8'h69
`define BPL		8'h6A
`define BMI		8'h6B
`define BGE		8'h6C
`define BLT		8'h6D
`define BGT		8'h6E
`define BLE		8'h6F

// 7700 LUTs / 80MHz
// slices
// 1600 FF's
// 2 MULTS
// 8 BRAMs

module rf68000(coreno_i, rst_i, rst_o, clk_i, nmi_i, ipl_i, vpa_i,
	lock_o, cyc_o, stb_o, ack_i, err_i, rty_i, we_o, sel_o, fc_o, adr_o, dat_i, dat_o);
typedef enum logic [7:0] {
	IFETCH = 8'd1,
	DECODE,
	RETSTATE,
	FETCH_BYTE,
	FETCH_WORD,
	FETCH_LWORD,
	FETCH_LWORDa,
	STORE_BYTE,
	USTORE_BYTE,
	// 10
	STORE_WORD,
	STORE_LWORD,
	STORE_LWORDa,
	LFETCH_BYTE,
	
	FETCH_BRDISP,
	FETCH_IMM16,
	FETCH_IMM32,
	FETCH_IMM32a,
	JSR,
	JMP,
	//20
	DBRA,
	
	ADDQ,
	ADDQ2,
	ADDI,
	ADDI2,
	ADDI3,
	ADDI4,
	ADD,
	ADD1,
	
	DIV1,
	DIV2,

	// 30
	STORE_IN_DEST,
	SHIFT,
	SHIFT1,
	BIT,
	BIT1,
	BIT2,
	RTD1,
	RTD2,
	
	RTE1,
	RTE2,
	// 40
	RTE3,
	RTE4,
	RTE5,
	RTE6,
	RTE7,
	RTE8,
	RTE9,
	RTE10,
	RTE11,

	RTS1,
	// 50
	RTS2,
	
	LINK,
	UNLNK,
	UNLNK2,
	JMP_VECTOR,
	JMP_VECTOR2,
	JMP_VECTOR3,
	
	LINK1,
	LINK2,
	
	NEG,
	
	// 60
	NEGX,
	NEGX1,
	NOT,
	TAS,
	LEA,
	EXG1,

	CMP,
	CMP1,
	CMPA,
	CMPM,
	
	// 70
	CMPM1,

	AND,
	AND1,
	EOR,
	ANDI_CCR,
	ANDI_CCR2,
	ANDI_SR,
	ANDI_SRX,
	EORI_CCR,
	EORI_CCR2,
	
	//80
	EORI_SR,
	EORI_SRX,
	ORI_CCR,
	ORI_CCR2,
	ORI_SR,
	ORI_SRX,
	FETCH_NOP_BYTE,
	FETCH_NOP_WORD,
	FETCH_NOP_LWORD,
	FETCH_IMM8,
	// 90
	FETCH_D32,
	FETCH_D32a,
	FETCH_D32b,
	FETCH_D16,
	FETCH_D16a,
	FETCH_NDX,
	FETCH_NDXa,
	
	MOVE2CCR,
	MOVE2SR,
	MOVE2SRX,

	// 100
	TRAP,
	TRAP3,
	TRAP3a,
	TRAP3b,
	TRAP4,
	TRAP5,
	TRAP6,
	TRAP7,
	TRAP7a,
	TRAP8,
	
	// 110
	TRAP9,
	TRAP10,
	TRAP20,
	TRAP21,
	TRAP22,
	TRAP23,
	TRAP24,
	TRAP25,
	TRAP26,
	INTA,
	
	RETRY,
	RETRY2,

	TST,
	MUL,
	MUL1,
	STOP,
	STOP1,
	RESET,
	RESET2,
	RESET3,
	RESET4,
	RESET5,
	PEA1,
	PEA2,
	ABCD,
	ABCD1,
	SBCD,
	SBCD1,
	NBCD,
	OR,
	
	INT,
	INT2,
	INT3,
	INT4,
	
	MOVEM_Xn2D,
	MOVEM_Xn2D2,
	MOVEM_Xn2D3,
	MOVEM_Xn2D4,
	MOVEM_s2Xn,
	MOVEM_s2Xn2,
	MOVEM_s2Xn3,
	
	TASK1,
	THREAD2,
	TASK3,
	TASK4,
	
	LDT1,
	LDT2,
	LDT3,
	SDT1,
	SDT2,
	
	SUB,
	SUB1,
	MOVEP,
	MOVEP1,
	MOVEP2,
	MOVEP3,
	CHK,
	
	MOVERc2Rn,
	MOVERn2Rc,
	MOVERn2Rc2,

	FSDATA2
} state_t;

typedef enum logic [4:0] {
	FU_NONE = 5'd0,
	FU_MUL, FU_DIV,
	FU_TST,
	FU_CMP, FU_ADD, FU_SUB, FU_LOGIC, FU_ADDQ, FU_SUBQ,
	FU_ADDI, FU_ANDI_CCR, FU_ANDI_SR, FU_EORI_CCR,
	FU_ANDI_SRX, FU_EORI_SRX, FU_ORI_SRX, FU_MOVE2SRX,
	FU_EORI_SR, FU_ORI_CCR, FU_ORI_SR, FU_MOVE2CCR,
	FU_MOVE2SR
} flag_update_t;

parameter S = 1'b0;
parameter D = 1'b1;

input [31:0] coreno_i;
input rst_i;
output reg rst_o;
input clk_i;
input nmi_i;
input vpa_i;
input [2:0] ipl_i;
output lock_o;
reg lock_o;
output cyc_o;
reg cyc_o;
output stb_o;
reg stb_o;
input ack_i;
input err_i;
input rty_i;
output we_o;
reg we_o;
output [3:0] sel_o;
reg [3:0] sel_o;
output [2:0] fc_o;
reg [2:0] fc_o;
output [31:0] adr_o;
reg [31:0] adr_o;
input [31:0] dat_i;
output [31:0] dat_o;
reg [31:0] dat_o;

reg em;							// emulation mode
reg [15:0] ir;
reg [31:0] icnt;
state_t state;
state_t rstate;
state_t state_stk1;
state_t state_stk2;
state_t state_stk3;
state_t state_stk4;
state_t sz_state;
flag_update_t flag_update;
reg [31:0] d0 = 'd0;
reg [31:0] d1 = 'd0;
reg [31:0] d2 = 'd0;
reg [31:0] d3 = 'd0;
reg [31:0] d4 = 'd0;
reg [31:0] d5 = 'd0;
reg [31:0] d6 = 'd0;
reg [31:0] d7 = 'd0;
reg [31:0] a0 = 'd0;
reg [31:0] a1 = 'd0;
reg [31:0] a2 = 'd0;
reg [31:0] a3 = 'd0;
reg [31:0] a4 = 'd0;
reg [31:0] a5 = 'd0;
reg [31:0] a6 = 'd0;
reg [31:0] sp = 'd0;
reg [31:0] d0i;
reg [31:0] d1i;
reg [31:0] d2i;
reg [31:0] d3i;
reg [31:0] d4i;
reg [31:0] d5i;
reg [31:0] d6i;
reg [31:0] d7i;
reg [31:0] a0i;
reg [31:0] a1i;
reg [31:0] a2i;
reg [31:0] a3i;
reg [31:0] a4i;
reg [31:0] a5i;
reg [31:0] a6i;
reg [31:0] spi;
reg [31:0] flagsi;
reg [31:0] pci;
wire [31:0] d0o;
wire [31:0] d1o;
wire [31:0] d2o;
wire [31:0] d3o;
wire [31:0] d4o;
wire [31:0] d5o;
wire [31:0] d6o;
wire [31:0] d7o;
wire [31:0] a0o;
wire [31:0] a1o;
wire [31:0] a2o;
wire [31:0] a3o;
wire [31:0] a4o;
wire [31:0] a5o;
wire [31:0] a6o;
wire [31:0] spo;
wire [31:0] flagso;
wire [31:0] pco;
reg cf,vf,nf,zf,xf,sf,tf;
reg [2:0] im;
reg [2:0] ccr57;
reg [1:0] sr1112;
reg sr14;
wire [15:0] sr = {tf,sr14,sf,sr1112,im,ccr57,xf,nf,zf,vf,cf};
wire [31:0] srx = {sr};
reg [31:0] isr;
reg [3:0] ifmt;
reg [31:0] pc;
reg [31:0] opc;			// pc for branch references
reg [31:0] ssp,usp;
reg [31:0] disp;
reg [31:0] s,d,dd,imm,immx;
reg [31:0] bit2test;
reg wl;
reg ds;
reg [5:0] cnt;				// shift count
reg [31:0] ea;				// effective address
reg [31:0] vector;
reg [7:0] vecno;
reg [3:0] Rt;
wire [1:0] sz = ir[7:6];
reg dsix;
reg [2:0] mmm,mmmx,mmm_save='d0;
reg [2:0] rrr,rrrx;
reg [3:0] rrrr;
wire [2:0] MMM = ir[8:6];
wire [2:0] RRR = ir[11:9];
wire [2:0] QQQ = ir[11:9];
wire [2:0] DDD = ir[11:9];
wire [2:0] AAA = ir[11:9];
reg MMMRRR;
wire Anabit;
wire [31:0] sp_dec = sp - 32'd2;
reg [31:0] rfoAn;
always_comb
case(rrr)
3'd0: rfoAn <= a0;
3'd1: rfoAn <= a1;
3'd2: rfoAn <= a2;
3'd3: rfoAn <= a3;
3'd4: rfoAn <= a4;
3'd5: rfoAn <= a5;
3'd6: rfoAn <= a6;
3'd7: rfoAn <= sp;
endcase
reg [31:0] rfoAna;
always_comb
case(AAA)
3'd0: rfoAna <= a0;
3'd1: rfoAna <= a1;
3'd2: rfoAna <= a2;
3'd3: rfoAna <= a3;
3'd4: rfoAna <= a4;
3'd5: rfoAna <= a5;
3'd6: rfoAna <= a6;
3'd7: rfoAna <= sp;
endcase
//wire [31:0] rfoAn =	rrr==3'b111 ? sp : regfile[{1'b1,rrr}];
reg [31:0] rfoDn;
always_comb
case(DDD)
3'd0:   rfoDn <= d0;
3'd1:   rfoDn <= d1;
3'd2:   rfoDn <= d2;
3'd3:   rfoDn <= d3;
3'd4:   rfoDn <= d4;
3'd5:   rfoDn <= d5;
3'd6:   rfoDn <= d6;
3'd7:   rfoDn <= d7;
endcase
reg [31:0] rfoDnn;
always_comb
case(rrr)
3'd0:   rfoDnn <= d0;
3'd1:   rfoDnn <= d1;
3'd2:   rfoDnn <= d2;
3'd3:   rfoDnn <= d3;
3'd4:   rfoDnn <= d4;
3'd5:   rfoDnn <= d5;
3'd6:   rfoDnn <= d6;
3'd7:   rfoDnn <= d7;
endcase
reg [31:0] rfob;
always_comb
case({mmm[0],rrr})
4'd0:   rfob <= d0;
4'd1:   rfob <= d1;
4'd2:   rfob <= d2;
4'd3:   rfob <= d3;
4'd4:   rfob <= d4;
4'd5:   rfob <= d5;
4'd6:   rfob <= d6;
4'd7:   rfob <= d7;
4'd8:   rfob <= a0;
4'd9:   rfob <= a1;
4'd10:  rfob <= a2;
4'd11:  rfob <= a3;
4'd12:  rfob <= a4;
4'd13:  rfob <= a5;
4'd14:  rfob <= a6;
4'd15:  rfob <= sp;
endcase
reg [31:0] rfoRnn;
always_comb
case(rrrr)
4'd0:   rfoRnn <= d0;
4'd1:   rfoRnn <= d1;
4'd2:   rfoRnn <= d2;
4'd3:   rfoRnn <= d3;
4'd4:   rfoRnn <= d4;
4'd5:   rfoRnn <= d5;
4'd6:   rfoRnn <= d6;
4'd7:   rfoRnn <= d7;
4'd8:   rfoRnn <= a0;
4'd9:   rfoRnn <= a1;
4'd10:  rfoRnn <= a2;
4'd11:  rfoRnn <= a3;
4'd12:  rfoRnn <= a4;
4'd13:  rfoRnn <= a5;
4'd14:  rfoRnn <= a6;
4'd15:  rfoRnn <= sp;
endcase
//wire [31:0] rfoDn = regfile[{1'b0,DDD}];
//wire [31:0] rfoAna = AAA==3'b111 ? sp : regfile[{1'b1,AAA}];
//wire [31:0] rfob = {mmm[0],rrr}==4'b1111 ? sp : regfile[{mmm[0],rrr}];
//wire [31:0] rfoDnn = regfile[{1'b0,rrr}];
//wire [31:0] rfoRnn = rrrr==4'b1111 ? sp : regfile[rrrr];
wire signed [31:0] rfoDns = rfoDn;
wire signed [31:0] ss = s;
wire clk = clk_i;
reg rfwrL,rfwrB,rfwrW;
reg takb;
reg [8:0] resB;
reg [16:0] resW;
reg [32:0] resL;
reg [31:0] st_data;
wire [7:0] bcdaddo,bcdsubo,bcdnego;
wire bcdaddoc,bcdsuboc,bcdnegoc;
reg [31:0] bad_addr;
reg [15:0] mac_cycle_type;
reg prev_nmi;
reg pe_nmi;
reg is_nmi;
reg is_irq, is_trace, is_priv, is_illegal;
reg is_adr_err;
reg is_rst;
reg is_bus_err;
reg [4:0] rst_cnt;
reg [2:0] shift_op;
reg rtr;
reg bsr;
reg [31:0] dati_buf;	// input data from bus error
reg [31:0] dato_buf;

// CSR's
reg [31:0] tick;	// FF0

reg [31:0] vbr;		// 801
reg [31:0] sfc;		// 000
reg [31:0] dfc;		// 001

wire [16:0] lfsr_o;
lfsr17 ulfsr1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.cyc(1'b0),
	.o(lfsr_o)
);

/*
reg [31:0] cache_tag [0:7];
reg [15:0] cache_dat [0:7];

task tPushCache;
input [31:0] adr;
input [15:0] dat;
integer n;
begin
	for (n = 1; n < 8; n = n + 1) begin
		cache_tag[n] <= cache_tag[n-1];
		cache_dat[n] <= cache_dat[n-1];
	end
	cache_tag[0] <= adr;
	cache_dat[0] <= dat;
end
endtask

function fnInCache;
input [31:0] adr;
integer n;
begin
	fnInCache = 1'b0;
	for (n = 0; n < 8; n = n + 1) begin
		if (cache_tag[n]==adr) begin
			fnInCache = 1'b1;		
	end
end
endfunction

task tFindInCache;
input [31:0] adr;
output [15:0] dat;
integer n;
begin
	dat = 16'h4E71;	// NOP
	for (n = 0; n < 8; n = n + 1) begin
		if (cache_tag[n]==adr) begin
			dat = cache_dat[n];
		end
	end
end
endtask
*/

function [31:0] rbo;
input [31:0] w;
rbo = {w[7:0],w[15:8],w[23:16],w[31:24]};
endfunction

BCDAdd u1
(
	.ci(xf),
	.a(s[7:0]),
	.b(d[7:0]),
	.o(bcdaddo),
	.c(bcdaddoc)
);

BCDSub u2
(
	.ci(xf),
	.a(d[7:0]),
	.b(s[7:0]),
	.o(bcdsubo),
	.c(bcdsuboc)
);

BCDSub u3
(
	.ci(xf),
	.a(8'h00),
	.b(d[7:0]),
	.o(bcdnego),
	.c(bcdnegoc)
);

// These functions take the MSBs of the operands and results and return an
// overflow status.

// If the signs of the operands are the same, and the sign of the result does
// not match the operands sign.
function fnAddOverflow;
input r;
input a;
input b;
	fnAddOverflow = (r ^ b) & (1'b1 ^ a ^ b);
endfunction

// If the signs of the operands are different and sign of the result does not
// match the first operand.
function fnSubOverflow;
input r;
input a;
input b;
	fnSubOverflow = (r ^ a) & (a ^ b);
endfunction

reg divs;
wire dvdone;
wire dvByZr;
wire [31:0] divq;
wire [31:0] divr;

rf68000_divider udiv1
(
	.rst(rst_i),
	.clk(clk_i),
	.ld(state==DIV1),
	.abort(),
	.sgn(divs),
	.sgnus(1'b0),
	.a(d),
	.b(s),
	.qo(divq),
	.ro(divr),
	.dvByZr(dvByZr),
	.done(dvdone),
	.idle()
);

always_comb
case(ir[15:8])
`BRA:	takb = 1'b1;
`BSR:	takb = 1'b1;
`BHI:	takb = !cf & !zf;
`BLS:	takb = cf | zf;
`BHS:	takb = !cf;
`BLO:	takb =  cf;
`BNE:	takb = !zf;
`BEQ:	takb =  zf;
`BVC:	takb = !vf;
`BVS:	takb =  vf;
`BPL:	takb = !nf;
`BMI:	takb =  nf;
`BGE:	takb = (nf & vf)|(!nf & !vf);
`BLT:	takb = (nf & !vf)|(!nf & vf);
`BGT:	takb = (nf & vf & !zf)|(!nf & !vf & zf);
`BLE:	takb = zf | (nf & !vf) | (!nf & vf);
`DBRA:	takb = 1'b1;
`DBSR:	takb = 1'b0;
`DBHI:	takb = !cf & !zf;
`DBLS:	takb = cf | zf;
`DBHS:	takb = !cf;
`DBLO:	takb =  cf;
`DBNE:	takb = !zf;
`DBEQ:	takb =  zf;
`DBVC:	takb = !vf;
`DBVS:	takb =  vf;
`DBPL:	takb = !nf;
`DBMI:	takb =  nf;
`DBGE:	takb = ((nf & vf)|(!nf & !vf));
`DBLT:	takb = ((nf & !vf)|(!nf & vf));
`DBGT:	takb = ((nf & vf & !zf)|(!nf & !vf & zf));
`DBLE:	takb = (zf | (nf & !vf) | (!nf & vf));
default:	takb = 1'b1;
endcase

`ifdef BIG_ENDIAN
wire [15:0] iri = pc[1] ? {dat_i[23:16],dat_i[31:24]} : {dat_i[7:0],dat_i[15:8]};
`else
wire [15:0] iri = pc[1] ? dat_i[31:16] : dat_i[15:0];
`endif

reg [31:0] csr_rego;
always_comb
  case(ea)
  `CSR_CORENO:	csr_rego <= coreno_i;
  `CSR_TICK:		csr_rego <= tick;
  `CSR_ICNT:		csr_rego <= icnt;
  default:  		csr_rego <= 'd0;
	endcase

always_ff @(posedge clk_i)
if (rst_i) begin
	em <= 1'b0;
	lock_o <= 1'b0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'b0000;
	fc_o <= 3'b000;
	adr_o <= 32'd0;
	dat_o <= 32'd0;
	rfwrB <= 1'b0;
	rfwrW <= 1'b0;
	rfwrL <= 1'b0;
	zf <= 1'b0;
	nf <= 1'b0;
	cf <= 1'b0;
	vf <= 1'b0;
	xf <= 1'b0;
	im <= 3'b111;
	sf <= 1'b1;
	tf <= 1'b0;
	goto (RESET);
	rstate <= RESET;
	prev_nmi <= 1'b0;
	pe_nmi <= 1'b0;
  tick <= 32'd0;
  rst_cnt <= 5'd10;
  rst_o <= 1'b1;
  is_rst <= 1'b1;
	MMMRRR <= 1'b0;
	rtr <= 1'b0;
	bsr <= 1'b0;
	divs <= 1'b0;
	icnt <= 'd0;
	is_bus_err <= 1'b0;
	is_adr_err <= 1'b0;
	is_trace <= 1'b0;
	is_priv <= 1'b0;
	is_illegal <= 1'b0;
	vbr <= 'd0;
	sfc <= 'd0;
	dfc <= 'd0;
	dati_buf <= 'd0;
	dato_buf <= 'd0;
end
else begin

if (rst_cnt != 5'd0)
    rst_cnt <= rst_cnt - 5'd1;
else
    rst_o <= 1'b0;

tick <= tick + 32'd1;
prev_nmi <= nmi_i;
if (nmi_i & !prev_nmi)
	pe_nmi <= 1'b1;

// Register file update
rfwrB <= 1'b0;
rfwrW <= 1'b0;
rfwrL <= 1'b0;
if (rfwrL) begin
  case(Rt)
  4'd0:   d0 <= resL[31:0];
  4'd1:   d1 <= resL[31:0];
  4'd2:   d2 <= resL[31:0];
  4'd3:   d3 <= resL[31:0];
  4'd4:   d4 <= resL[31:0];
  4'd5:   d5 <= resL[31:0];
  4'd6:   d6 <= resL[31:0];
  4'd7:   d7 <= resL[31:0];
  4'd8:   a0 <= resL[31:0];
  4'd9:   a1 <= resL[31:0];
  4'd10:  a2 <= resL[31:0];
  4'd11:  a3 <= resL[31:0];
  4'd12:  a4 <= resL[31:0];
  4'd13:  a5 <= resL[31:0];
  4'd14:  a6 <= resL[31:0];
  4'd15:  sp <= resL[31:0];
  endcase
end
else if (rfwrW) begin
  case(Rt)
  4'd0:   d0[15:0] <= resW[15:0];
  4'd1:   d1[15:0] <= resW[15:0];
  4'd2:   d2[15:0] <= resW[15:0];
  4'd3:   d3[15:0] <= resW[15:0];
  4'd4:   d4[15:0] <= resW[15:0];
  4'd5:   d5[15:0] <= resW[15:0];
  4'd6:   d6[15:0] <= resW[15:0];
  4'd7:   d7[15:0] <= resW[15:0];
  4'd8:   a0 <= {{16{resW[15]}},resW[15:0]};
  4'd9:   a1 <= {{16{resW[15]}},resW[15:0]};
  4'd10:  a2 <= {{16{resW[15]}},resW[15:0]};
  4'd11:  a3 <= {{16{resW[15]}},resW[15:0]};
  4'd12:  a4 <= {{16{resW[15]}},resW[15:0]};
  4'd13:  a5 <= {{16{resW[15]}},resW[15:0]};
  4'd14:  a6 <= {{16{resW[15]}},resW[15:0]};
  4'd15:  sp <= {{16{resW[15]}},resW[15:0]};
  endcase
end
else if (rfwrB)
  case(Rt)
  4'd0:   d0[7:0] <= resB[7:0];
  4'd1:   d1[7:0] <= resB[7:0];
  4'd2:   d2[7:0] <= resB[7:0];
  4'd3:   d3[7:0] <= resB[7:0];
  4'd4:   d4[7:0] <= resB[7:0];
  4'd5:   d5[7:0] <= resB[7:0];
  4'd6:   d6[7:0] <= resB[7:0];
  4'd7:   d7[7:0] <= resB[7:0];
  default:    ;
  endcase

case(state)

IFETCH:
	begin
		case(flag_update)
		FU_MUL:
			begin
				cf <= 1'b0;
				vf <= 1'b0;
				nf <= resL[31];
				zf <= resL[31:0]==32'd0;
			end
		FU_TST:
			begin
				cf <= 1'b0;
				vf <= 1'b0;
				case(sz)
				2'b00:	begin zf <= d[7:0]==8'h00; nf <= d[7]; end
				2'b01:	begin zf <= d[15:0]==16'h00; nf <= d[15]; end
				2'b10:	begin zf <= d[31:0]==32'h00; nf <= d[31]; end
				default:	;
				endcase
			end
		FU_CMP:
			begin
				case(sz)
				2'b00:	begin zf <= resB[7:0]== 8'd0; nf <= resB[ 7]; cf <= resB[ 8]; vf <= fnSubOverflow(resB[7],d[7],s[7]); end
				2'b01:	begin zf <= resW[15:0]==16'd0; nf <= resW[15]; cf <= resW[16]; vf <= fnSubOverflow(resW[15],d[15],s[15]); end
				2'b10:	begin zf <= resL[31:0]==32'd0; nf <= resL[31]; cf <= resL[32]; vf <= fnSubOverflow(resL[31],d[31],s[31]); end
				2'b11:
					if (ir[8])
						begin zf <= resL[31:0]==32'd0; nf <= resL[31]; cf <= resL[32]; vf <= fnSubOverflow(resL[31],d[31],s[31]); end
					else
						begin zf <= resW[15:0]==16'd0; nf <= resW[15]; cf <= resW[16]; vf <= fnSubOverflow(resW[15],d[15],s[15]); end
				endcase
			end
		FU_ADD:
			begin
				case(sz)
				2'b00:
					begin
						rfwrB <= 1'b1;
						cf <= resB[8];
						nf <= resB[7];
						zf <= resB[7:0]==8'h00;
						vf <= fnAddOverflow(resB[7],dd[7],s[7]);
						xf <= resB[8];
					end
				2'b01:
					begin
						rfwrW <= 1'b1;
						cf <= resW[16];
						nf <= resW[15];
						zf <= resW[15:0]==16'h0000;
						vf <= fnAddOverflow(resW[15],dd[15],s[15]);
						//vf <= resW[16]!=resW[15];
						xf <= resW[16];
					end
				2'b10:
					begin
						rfwrL <= 1'b1;
						cf <= resL[32];
						nf <= resL[31];
						zf <= resL[31:0]==32'h00000000;
						vf <= resL[32]!=resL[31];
						vf <= fnAddOverflow(resL[31],dd[31],s[31]);
						xf <= resL[32];
					end
				2'b11:
					begin
						rfwrL <= 1'b1;
						Rt <= {1'b1,AAA};
						resL[31:16] <= resL[15];
					end
				endcase
			end
		FU_SUB:
			begin
				case(sz)
				2'b00:
					begin
						rfwrB <= 1'b1;
						cf <= resB[8];
						nf <= resB[7];
						zf <= resB[7:0]==8'h00;
						vf <= fnSubOverflow(resB[7],dd[7],s[7]);
						xf <= resB[8];
					end
				2'b01:
					begin
						rfwrW <= 1'b1;
						cf <= resW[16];
						nf <= resW[15];
						zf <= resW[15:0]==16'h0000;
						vf <= fnSubOverflow(resW[15],dd[15],s[15]);
						xf <= resW[16];
					end
				2'b10:
					begin
						rfwrL <= 1'b1;
						cf <= resL[32];
						nf <= resL[31];
						zf <= resL[31:0]==32'h00000000;
						vf <= fnSubOverflow(resL[31],dd[31],s[31]);
						xf <= resL[32];
					end
				2'b11:
					begin
						rfwrL <= 1'b1;
						Rt <= {1'b1,AAA};
						resL[31:16] <= resL[15];	// ????
					end
				endcase
			end
		FU_LOGIC:
			begin
				cf <= 1'b0;
				vf <= 1'b0;
				case(sz)
				2'b00:
					begin
						rfwrB <= 1'b1;
						nf <= resB[7];
						zf <= resB[7:0]==8'h00;
					end
				2'b01:
					begin
						rfwrW <= 1'b1;
						nf <= resW[15];
						zf <= resW[15:0]==16'h0000;
					end
				2'b10:
					begin
						rfwrL <= 1'b1;
						nf <= resL[31];
						zf <= resL[31:0]==32'h00000000;
					end
				endcase
			end
		FU_ADDQ:
			begin
				case(sz)
				2'b00:
					begin
						 xf <= resB[8];
						 cf <= resB[8];
						 vf <= resB[8]!=resB[7];
						vf <= fnAddOverflow(resB[7],dd[7],s[7]);
						 //zf <= resB[7:0]==8'd0;
						 nf <= resB[7];
					end
				2'b01:
					begin
						 xf <= resW[16];
						 cf <= resW[16];
						vf <= fnAddOverflow(resW[15],dd[15],s[15]);
						 //vf <= resW[16]!=resW[15];
						 zf <= resW[15:0]==16'd0;
						 nf <= resW[15];
					end
				2'b10:
					begin
						 xf <= resL[32];
						 cf <= resL[32];
						vf <= fnAddOverflow(resL[31],dd[31],s[31]);
						// vf <= resL[32]!=resL[31];
						 zf <= resL[31:0]==32'd0;
						 nf <= resL[31];
					end
				endcase
			end
		FU_SUBQ:
			begin
				case(sz)
				2'b00:
					begin
						 xf <= resB[8];
						 cf <= resB[8];
						 vf <= resB[8]!=resB[7];
						vf <= fnSubOverflow(resB[7],dd[7],s[7]);
						 //zf <= resB[7:0]==8'd0;
						 nf <= resB[7];
					end
				2'b01:
					begin
						 xf <= resW[16];
						 cf <= resW[16];
						vf <= fnSubOverflow(resW[15],dd[15],s[15]);
						 //vf <= resW[16]!=resW[15];
						 zf <= resW[15:0]==16'd0;
						 nf <= resW[15];
					end
				2'b10:
					begin
						 xf <= resL[32];
						 cf <= resL[32];
						vf <= fnSubOverflow(resL[31],dd[31],s[31]);
						// vf <= resL[32]!=resL[31];
						 zf <= resL[31:0]==32'd0;
						 nf <= resL[31];
					end
				endcase
			end
		FU_ADDI:
			begin
				case(ir[11:8])
				4'h0,4'h2,4'hA:
						begin	// ORI,ANDI,EORI
							cf <= 1'b0;
							vf <= 1'b0;
							case(sz)
							2'b00:	zf <= resB[7:0]==8'h00;
							2'b01:	zf <= resW[15:0]==16'h00;
							2'b10:	zf <= resL[31:0]==32'd0;
							endcase
							case(sz)
							2'b00:	nf <= resB[7];
							2'b01:	nf <= resW[15];
							2'b10:	nf <= resL[31];
							endcase
						end
				4'h4:	// SUBI
					begin
						case(sz)
						2'b00:
							begin
								xf <= resB[8];
								cf <= resB[8];
								vf <= fnSubOverflow(resB[7],dd[7],immx[7]);
								//vf <= resB[8]!=resB[7];
								zf <= resB[7:0]==8'd0;
								nf <= resB[7];
							end
						2'b01:
							begin
								xf <= resW[16];
								cf <= resW[16];
								vf <= fnSubOverflow(resW[15],dd[15],immx[15]);
								//vf <= resW[16]!=resW[15];
								zf <= resW[15:0]==16'd0;
								nf <= resW[15];
							end
						2'b10:
							begin
								xf <= resL[32];
								cf <= resL[32];
								vf <= fnSubOverflow(resL[31],dd[31],immx[31]);
								//vf <= resL[32]!=resL[31];
								zf <= resL[31:0]==32'd0;
								nf <= resL[31];
							end
						endcase
					end
				4'h6:	// ADDI
					begin
						case(sz)
						2'b00:
							begin
								xf <= resB[8];
								cf <= resB[8];
								vf <= fnAddOverflow(resB[7],dd[7],immx[7]);
								//vf <= resB[8]!=resB[7];
								zf <= resB[7:0]==8'd0;
								nf <= resB[7];
							end
						2'b01:
							begin
								xf <= resW[16];
								cf <= resW[16];
								vf <= fnAddOverflow(resW[15],dd[15],immx[15]);
								//vf <= resW[16]!=resW[15];
								zf <= resW[15:0]==16'd0;
								nf <= resW[15];
							end
						2'b10:
							begin
								xf <= resL[32];
								cf <= resL[32];
								vf <= fnAddOverflow(resL[31],dd[31],immx[31]);
								//vf <= resL[32]!=resL[31];
								zf <= resL[31:0]==32'd0;
								nf <= resL[31];
							end
						endcase
					end
				4'hC:	// CMPI
					begin
						case(sz)
						2'b00:
							begin
								cf <= resB[8];
								vf <= fnSubOverflow(resB[7],dd[7],immx[7]);
								zf <= resB[7:0]==8'd0;
								nf <= resB[7];
							end
						2'b01:
							begin
								cf <= resW[16];
								vf <= fnSubOverflow(resW[15],dd[15],immx[15]);
								//vf <= resW[16]!=resW[15];
								zf <= resW[15:0]==16'd0;
								nf <= resW[15];
							end
						2'b10:
							begin
								cf <= resL[32];
								vf <= fnSubOverflow(resL[31],dd[31],immx[31]);
								//vf <= resL[32]!=resL[31];
								zf <= resL[31:0]==32'd0;
								nf <= resL[31];
							end
						endcase
					end
				endcase
			end
		FU_ANDI_CCR:
			begin
				cf <= cf & imm[0];
				vf <= vf & imm[1];
				zf <= zf & imm[2];
				nf <= nf & imm[3];
				xf <= xf & imm[4];
			end
		FU_ANDI_SR:
			begin
				cf <= cf & imm[0];
				vf <= vf & imm[1];
				zf <= zf & imm[2];
				nf <= nf & imm[3];
				xf <= xf & imm[4];
				im[0] <= im[0] & imm[8];
				im[1] <= im[1] & imm[9];
				im[2] <= im[2] & imm[10];
				sf <= sf & imm[13];
				tf <= tf & imm[15];
			end
		FU_ANDI_SRX:
			begin
				cf <= cf & imm[0];
				vf <= vf & imm[1];
				zf <= zf & imm[2];
				nf <= nf & imm[3];
				xf <= xf & imm[4];
				im[0] <= im[0] & imm[8];
				im[1] <= im[1] & imm[9];
				im[2] <= im[2] & imm[10];
				sf <= sf & imm[13];
				tf <= tf & imm[15];
			end
		FU_EORI_CCR:
			begin
				cf <= cf ^ imm[0];
				vf <= vf ^ imm[1];
				zf <= zf ^ imm[2];
				nf <= nf ^ imm[3];
				xf <= xf ^ imm[4];
			end
		FU_EORI_SR:
			begin
				cf <= cf ^ imm[0];
				vf <= vf ^ imm[1];
				zf <= zf ^ imm[2];
				nf <= nf ^ imm[3];
				xf <= xf ^ imm[4];
				im[0] <= im[0] ^ imm[8];
				im[1] <= im[1] ^ imm[9];
				im[2] <= im[2] ^ imm[10];
				sf <= sf ^ imm[13];
				tf <= tf ^ imm[15];
			end
		FU_EORI_SRX:
			begin
				cf <= cf ^ imm[0];
				vf <= vf ^ imm[1];
				zf <= zf ^ imm[2];
				nf <= nf ^ imm[3];
				xf <= xf ^ imm[4];
				im[0] <= im[0] ^ imm[8];
				im[1] <= im[1] ^ imm[9];
				im[2] <= im[2] ^ imm[10];
				sf <= sf ^ imm[13];
				tf <= tf ^ imm[15];
			end
		FU_ORI_CCR:
			begin
				cf <= cf | imm[0];
				vf <= vf | imm[1];
				zf <= zf | imm[2];
				nf <= nf | imm[3];
				xf <= xf | imm[4];
			end
		FU_ORI_SR:
			begin
				cf <= cf | imm[0];
				vf <= vf | imm[1];
				zf <= zf | imm[2];
				nf <= nf | imm[3];
				xf <= xf | imm[4];
				im[0] <= im[0] | imm[8];
				im[1] <= im[1] | imm[9];
				im[2] <= im[2] | imm[10];
				sf <= sf | imm[13];
				tf <= tf | imm[15];
			end
		FU_ORI_SRX:
			begin
				cf <= cf | imm[0];
				vf <= vf | imm[1];
				zf <= zf | imm[2];
				nf <= nf | imm[3];
				xf <= xf | imm[4];
				im[0] <= im[0] | imm[8];
				im[1] <= im[1] | imm[9];
				im[2] <= im[2] | imm[10];
				sf <= sf | imm[13];
				tf <= tf | imm[15];
			end
		FU_MOVE2CCR:
			begin
				cf <= s[0];
				vf <= s[1];
				zf <= s[2];
				nf <= s[3];
				xf <= s[4];
				ccr57 <= s[7:5];
			end	
		FU_MOVE2SR:
			begin
				cf <= s[0];
				vf <= s[1];
				zf <= s[2];
				nf <= s[3];
				xf <= s[4];
				ccr57 <= s[7:5];
				im[0] <= s[8];
				im[1] <= s[9];
				im[2] <= s[10];
				sr1112 <= s[12:11];
				sf <= s[13];
				sr14 <= s[14];
				tf <= s[15];
			end
		FU_MOVE2SRX:
			begin
				cf <= s[0];
				vf <= s[1];
				zf <= s[2];
				nf <= s[3];
				xf <= s[4];
				ccr57 <= s[7:5];
				im[0] <= s[8];
				im[1] <= s[9];
				im[2] <= s[10];
				sr1112 <= s[12:11];
				sf <= s[13];
				sr14 <= s[14];
				tf <= s[15];
			end
		FU_DIV:
			begin
				cf <= 1'b0;
				nf <= divq[15];
				zf <= divq[15:0]==16'd0;
				vf <= divq[31:16] != {16{divq[15]}};
			end	
		default:	;
		endcase
		flag_update <= FU_NONE;
		MMMRRR <= 1'b0;
		rtr <= 1'b0;
		bsr <= 1'b0;
		is_illegal <= 1'b0;
		if (!cyc_o) begin
			is_nmi <= 1'b0;
			is_irq <= 1'b0;
			/*
			if (pe_nmi) begin
				pe_nmi <= 1'b0;
				is_nmi <= 1'b1;
				goto(TRAP);
			end
			else 
			*/
			if (ipl_i > im) begin
				is_irq <= 1'b1;
				gosub(TRAP);
			end
			else if (pc[0]) begin
				is_adr_err <= 1'b1;
				gosub(TRAP);
			end
			else begin
				fc_o <= {sf,2'b10};
				cyc_o <= 1'b1;
				stb_o <= 1'b1;
				sel_o <= 4'b1111;
				adr_o <= pc;
			end
		end
		else if (ack_i) begin
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 2'b00;
			ir <= iri;
			pc <= pc + 4'd2;
			opc <= pc + 4'd2;
			mmm <= iri[5:3];
			rrr <= iri[2:0];
			rrrr <= iri[3:0];
			divs <= iri[8];
			icnt <= icnt + 2'd1;
			gosub (DECODE);
		end
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
DECODE:
	case(ir[15:12])
	4'h0:
		case(ir[11:8])
		4'h0:
			case(ir[7:0])
			8'h3C:	state <= ORI_CCR;
			8'h7C:
				if (sf)	
					goto (ORI_SR);
				else
					tPrivilegeViolation();
			8'hBC:	
				if (sf)	
					goto (ORI_SRX);
				else
					tPrivilegeViolation();
			default:	state <= ADDI;	// ORI
			endcase
		4'h2:
			case(ir[7:0])
			8'h3C:	state <= ANDI_CCR;
			8'h7C:	
				if (sf)	
					goto (ANDI_SR);
				else
					tPrivilegeViolation();
			8'hBC:
				if (sf)	
					goto (ANDI_SRX);
				else
					tPrivilegeViolation();
			default:	state <= ADDI;	// ANDI
			endcase
		4'h4:	state <= ADDI;	// SUBI
		4'h6:	state <= ADDI;	// ADDI
		4'hA:
			case(ir[7:0])
			8'h3C:	state <= EORI_CCR;
			8'h7C:
				if (sf)	
					goto (EORI_SR);
				else
					tPrivilegeViolation();
			8'hBC:
				if (sf)	
					goto (EORI_SRX);
				else
					tPrivilegeViolation();
			default:	state <= ADDI;	// EORI
			endcase
		4'hC:	state <= ADDI;	// CMPI
		default:	
			if (mmm==3'b001 && ir[8]) begin
				push(MOVEP);
				fs_data(3'b101,rrr,FETCH_NOP_WORD,S);
			end
			else
				state <= BIT;
		endcase
//-----------------------------------------------------------------------------
// MOVE.B
//-----------------------------------------------------------------------------
	4'h1:	
		begin
			push(STORE_IN_DEST);
			fs_data(mmm,rrr,FETCH_BYTE,S);
		end
//-----------------------------------------------------------------------------
// MOVE.L
//-----------------------------------------------------------------------------
  4'h2:    
   	begin
			push(STORE_IN_DEST);
    	fs_data(mmm,rrr,FETCH_LWORD,S);
    end
//-----------------------------------------------------------------------------
// MOVE.W
//-----------------------------------------------------------------------------
	4'h3:
		begin
			push(STORE_IN_DEST);
			fs_data(mmm,rrr,FETCH_WORD,S);
		end
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
	4'h4:
		casez(ir[11:3])
		9'b0000?????:
			case(sz)
			2'b00:	begin push(NEGX); fs_data(mmm,rrr,FETCH_BYTE,D); end
			2'b01:	begin push(NEGX); fs_data(mmm,rrr,FETCH_WORD,D); end
			2'b10:	begin push(NEGX); fs_data(mmm,rrr,FETCH_LWORD,D); end
			2'b11:	// MOVE sr,<ea>
				if (sf) begin 
					d <= sr;
					resW <= sr;
					fs_data(mmm,rrr,STORE_WORD,S);
				end
				else
					tPrivilegeViolation();
			endcase
		9'b000110???:	// MOVE.L srx,<ea>
				if (sf) begin
					d <= srx;
					resL <= srx;
					fs_data(mmm,rrr,STORE_LWORD,S);
				end	
				else
					tPrivilegeViolation();
		9'b0010?????:
			begin		// 42xx	CLR
				cf <= 1'b0;
				vf <= 1'b0;
				zf <= 1'b1;
				nf <= 1'b0;
				d <= 'd0;
				case(sz)
				2'b00:	fs_data(mmm,rrr,STORE_BYTE,D);
				2'b01:	fs_data(mmm,rrr,STORE_WORD,D);
				2'b10:	fs_data(mmm,rrr,STORE_LWORD,D);
				default:	tIllegal();
				endcase
			end
		9'b0100?????:
			casez(sz)
			2'b00:	begin push(NEG); fs_data(mmm,rrr,FETCH_BYTE,D); end
			2'b01:	begin push(NEG); fs_data(mmm,rrr,FETCH_WORD,D); end
			2'b10:	begin push(NEG); fs_data(mmm,rrr,FETCH_LWORD,D); end
			2'b11:	// MOVE <src>,ccr
				begin
					flag_update <= FU_MOVE2CCR;
					fs_data(mmm,rrr,FETCH_WORD,S);
				end
			endcase
		9'b0110?????:
			case(sz)
			2'b00:	begin push(NOT); fs_data(mmm,rrr,FETCH_BYTE,D); end
			2'b01:	begin push(NOT); fs_data(mmm,rrr,FETCH_WORD,D); end
			2'b10:	begin push(NOT); fs_data(mmm,rrr,FETCH_LWORD,D); end
			2'b11:	
				if (sf) begin	// MOVE <src>,sr
					flag_update <= FU_MOVE2SR;
					fs_data(mmm,rrr,FETCH_WORD,S);
				end
				else
					tPrivilegeViolation();
			default:	;
			endcase
		9'b0111?????:
			case(sz)
			2'b00:	tIllegal();
			2'b01:	tIllegal();
			2'b10:	tIllegal();
			2'b11:	
				if (sf) begin	// MOVE <src>,srx
					flag_update <= FU_MOVE2SRX;
					fs_data(mmm,rrr,FETCH_LWORD,S);
				end
				else
					tPrivilegeViolation();
			default:	;
			endcase
		9'b10001?000:
			if (ir[6]) begin	// EXT.L
				cf <= 1'b0;
				vf <= 1'b0;
				nf <= rfoRnn[15];
				zf <= rfoRnn[15:0]==16'h0000;
				rfwrL <= 1'b1;
				Rt <= ir[3:0];
				resL <= {{16{rfoRnn[15]}},rfoRnn[15:0]};
				ret();
			end
			else begin	// EXT.W
				cf <= 1'b0;
				vf <= 1'b0;
				nf <= rfoRnn[7];
				zf <= rfoRnn[7:0]==8'h00;
				rfwrW <= 1'b1;
				Rt <= ir[3:0];
				resW <= {rfoRnn[31:16],{8{rfoRnn[7]}},rfoRnn[7:0]};
				ret();
			end
`ifdef SUPPORT_BCD			
		9'b100000???:	// NBCD
			begin
				push(NBCD);
				fs_data(mmm,rrr,FETCH_BYTE,D);
			end
`endif			
		9'b100001000:	// 484x		SWAP
			begin	
				cf <= 1'b0;
				vf <= 1'b0;
				zf <= rfoDnn==32'd0;
				nf <= rfoDnn[15];
				resL <= {rfoDnn[15:0],rfoDnn[31:16]};
				Rt <= {1'b0,rrr};
				rfwrL <= 1'b1;
				ret();
			end
		9'b100001???:	// PEA
			begin
				push(PEA1);
				fs_data(mmm,rrr,FETCH_NOP_LWORD,S);
			end
		9'b101011111:
			case(ir[3:0])
			4'hC:	tIllegal();	// 4AFC	Illegal
			endcase	
		9'b1010?????:	// TST / TAS
			case(sz)
			2'b00:	begin flag_update <= FU_TST; fs_data(mmm,rrr,FETCH_BYTE,D); end
			2'b01:	begin flag_update <= FU_TST; fs_data(mmm,rrr,FETCH_WORD,D); end
			2'b10:	begin flag_update <= FU_TST; fs_data(mmm,rrr,FETCH_LWORD,D); end
			2'b11:	begin push(TAS); fs_data(mmm,rrr,LFETCH_BYTE,D); end		// TAS
			endcase
		9'b11100100?:
			goto (TRAP);
		9'b111001010:
			goto (LINK);
		9'b111001011:
			begin		// UNLK
				sp <= rfoAn;
				goto (UNLNK);
			end
		9'b11100110?:
			if (ir[3]) begin
				ret();
				Rt <= {1'b1,rrr};
				rfwrL <= 1'b1;
				resL <= usp;
			end
			else begin
				ret();
				usp <= rfoAn;
			end
		9'b111001110:	// 4E70 RESET
			case(ir[2:0])
			3'b000:	
				if (sf) begin
					rst_o <= 1'b1;
					rst_cnt <= 5'd10;
					ret(); 
				end  
				else
					tPrivilegeViolation();
			3'b001:	ret();	// NOP
			3'b010: 
				if (sf)
					goto (STOP);
				else
					tPrivilegeViolation();
			3'b011: 
				if (sf)
					goto (RTE1);
				else
					tPrivilegeViolation();
			3'b101:
				begin
					ea <= sp;
					sp <= sp + 4'd4;
					ds <= S;
					call (FETCH_LWORD,RTS1);
				end
			3'b110:
				if (vf) begin
			    vecno <= `TRAPV_VEC;
    			goto (TRAP3);
				end
				else
					ret();		// 4E76 TRAPV
			3'b111:	
				begin
					rtr <= 1'b1;
					goto (RTE1); // RTR
				end
			endcase
		9'b111001111:
			case(ir[2:0])
			3'b010:		call(FETCH_IMM16,MOVERc2Rn);
			3'b011:		call(FETCH_IMM16,MOVERn2Rc);
			default:	tIllegal();
			endcase
		9'b111010???:	// JSR		
			begin
				push(JSR);
				fs_data(mmm,rrr,FETCH_LWORD,D);
			end
		9'b111011???:	// JMP
			begin
				push(JMP);
				fs_data(mmm,rrr,FETCH_LWORD,D);
			end
		9'b1?001????:
			if (ir[10])
				call(FETCH_IMM16,MOVEM_s2Xn);
			else
				call(FETCH_IMM16,MOVEM_Xn2D);
		9'b???111???:
			begin // LEA
				push(LEA);
				fs_data(mmm,rrr,FETCH_NOP_LWORD,S);
			end
		9'b???110???:
			begin	// CHK
				d <= rfoDn;
				push(CHK);
				fs_data(mmm,rrr,FETCH_WORD,S);
			end
		default:
			tIllegal();
		endcase
//***		4'hF:	state <= RTD1;	// 4Fxx = rtd

//-----------------------------------------------------------------------------
// ADDQ / SUBQ / DBRA / Scc
//-----------------------------------------------------------------------------
	4'h5:
		begin
			casez(ir[7:4])
			// When optimizing DBRA for performance, the memory access cycle to fetch
			// the displacement constant is not done, instead the PC is incremented by
			// two if not doing the DBRA. This is an extra PC increment that increases
			// the code size. It is slower, but more hardware efficient to just always
			// fetch the displacement.
			4'b1100:					// DBRA
`ifdef OPT_PERF			
				if (~takb) begin
					call(FETCH_IMM16,DBRA);
				end
				else begin
					pc <= pc + 32'd2;	// skip over displacement
					ret();
				end
`else
				call(FETCH_IMM16,DBRA);				
`endif				
			4'b11??:					// Scc
				begin
					resL <= {32{takb}};
					resW <= {16{takb}};
					resB <= {8{takb}};
					d <= {32{takb}};
					if (mmm==3'b000) begin
						rfwrB <= 1'b1;
						Rt <= {1'b0,rrr};
						ret();
					end
					else begin
						fs_data(mmm,rrr,STORE_BYTE,S);
					end
				end
			default:
				begin
					case(QQQ)
					3'd0:	begin imm <= 32'd8; immx <= 32'd8; end
					default:	begin imm <= {29'd0,QQQ}; immx <= {29'd0,QQQ}; end
					endcase
					case(sz)
					2'b00:	begin push(ADDQ); fs_data(mmm,rrr,FETCH_BYTE,D); end
					2'b01:	begin push(ADDQ); fs_data(mmm,rrr,FETCH_WORD,D); end
					2'b10:	begin push(ADDQ); fs_data(mmm,rrr,FETCH_LWORD,D); end
					default:	tIllegal();
					endcase
				end
			endcase
		end
		
//-----------------------------------------------------------------------------
// Branches
//-----------------------------------------------------------------------------
	4'h6:
		if (takb) begin
			// If branch back to self, trap
		  if (ir[7:0]==8'hFE)
		  	tBadBranchDisp();
			else
`ifdef SUPPORT_B24			
			if (ir[7:0]==8'h00 || ir[0]) begin
`else				
			if (ir[7:0]==8'h00) begin
`endif				
				if (ir[15:8]==8'h61) begin
					bsr <= 1'b1;
					call(FETCH_BRDISP,JSR);
				end
				else
					goto(FETCH_BRDISP);
			end
			else begin
				d <= pc + {{24{ir[7]}},ir[7:1],1'b0};
				opc <= pc;
				if (ir[15:8]==8'h61) begin
					bsr <= 1'b1;
					goto(JSR);
				end
				else begin
					pc <= pc + {{24{ir[7]}},ir[7:1],1'b0};
					ret();
				end
			end
		end
		else begin
`ifdef SUPPORT_B24			
			if (ir[7:0]==8'h00 || ir[0])		// skip over long displacement
`else
			if (ir[7:0]==8'h00)		// skip over long displacement
`endif			
				pc <= pc + 4'd2;
			ret();
		end

//-----------------------------------------------------------------------------
// MOVEQ
//-----------------------------------------------------------------------------
	4'h7:
		// MOVEQ only if ir[8]==0, but it is otherwise not used for the 68k.
		// So some decode and fmax is saved by not decoding ir[8]
		//if (ir[8]==1'b0) 
		begin
			vf <= 1'b0;
			cf <= 1'b0;
			nf <= ir[7];
			zf <= ir[7:0]==8'h00;
			rfwrL <= 1'b1;
			Rt <= {1'b0,ir[11:9]};
			resL <= {{24{ir[7]}},ir[7:0]};
			ret();
		end
//-----------------------------------------------------------------------------
// OR / SBCD
//-----------------------------------------------------------------------------
	4'h8:
		begin
			casez(ir[11:0])
`ifdef SUPPORT_DIV			
			12'b????_11??_????:	// DIVU / DIVS
				begin
					d <= rfoDn;
					push(DIV1);
					fs_data(mmm,rrr,FETCH_WORD,S);
				end
`endif
`ifdef SUPPORT_BCD				
			12'b???1_0000_????:	// SBCD
				if (ir[3]) begin
					push(SBCD);
					fs_data(3'b100,rrr,FETCH_BYTE,S);
				end
				else begin
					s <= rfoDnn;
					d <= rfoDn;
					state <= SBCD;
				end
`endif				
			default:	
				begin
	        case(sz)
	        2'b00:    begin push(OR); fs_data(mmm,rrr,FETCH_BYTE,ir[8]?D:S); end
	        2'b01:    begin push(OR); fs_data(mmm,rrr,FETCH_WORD,ir[8]?D:S); end
	        2'b10:    begin push(OR); fs_data(mmm,rrr,FETCH_LWORD,ir[8]?D:S); end
	        default:	;	// can't get here, picked off by DIV
					endcase
				end
			endcase
		end
//-----------------------------------------------------------------------------
// SUB / SUBA
//-----------------------------------------------------------------------------
    4'h9:
      begin
        if (ir[8])
          s <= rfoDn;
        else
          d <= rfoDn;
        case(sz)
        2'b00:    begin push(SUB); fs_data(mmm,rrr,FETCH_BYTE,ir[8]?D:S); end
        2'b01:    begin push(SUB); fs_data(mmm,rrr,FETCH_WORD,ir[8]?D:S); end
        2'b10:    begin push(SUB); fs_data(mmm,rrr,FETCH_LWORD,ir[8]?D:S); end
        2'b11:
          begin
          d <= rfoAna;
          push(SUB);
          if (ir[8]) fs_data(mmm,rrr,FETCH_LWORD,S);
          else fs_data(mmm,rrr,FETCH_WORD,S);
          end
        endcase
      end
//-----------------------------------------------------------------------------
// LDT
//-----------------------------------------------------------------------------
    4'hA:
      begin
        if (ir[11:6]==6'h0)
          state <= LDT1;
        else if (ir[11:6]==6'h1)
          state <= SDT1;
        else
        	tIllegal();
      end
//-----------------------------------------------------------------------------
// CMP / EOR
//-----------------------------------------------------------------------------
	4'hB:
		begin
			if (ir[8]) begin	// EOR
				if (mmm==001)
					case(sz)
					2'b00:	begin push(CMPM); fs_data(3'b011,rrr,FETCH_BYTE,D); end
					2'b01:	begin push(CMPM); fs_data(3'b011,rrr,FETCH_WORD,D); end
					2'b10:	begin push(CMPM); fs_data(3'b011,rrr,FETCH_LWORD,D); end
					2'b11:	begin push(CMPA); fs_data(mmm,rrr,FETCH_LWORD,S); end	// CMPA
					endcase
				else
					case(sz)
					2'b00:	begin push(EOR); fs_data(mmm,rrr,FETCH_BYTE,D); end
					2'b01:	begin push(EOR); fs_data(mmm,rrr,FETCH_WORD,D); end
					2'b10:	begin push(EOR); fs_data(mmm,rrr,FETCH_LWORD,D); end
					2'b11:	begin push(CMPA); fs_data(mmm,rrr,FETCH_LWORD,S); end	// CMPA
					endcase
			end
			else	// CMP
				case(sz)
				2'b00:	begin push(CMP); fs_data(mmm,rrr,FETCH_BYTE,S); end
				2'b01:	begin push(CMP); fs_data(mmm,rrr,FETCH_WORD,S); end
				2'b10:	begin push(CMP); fs_data(mmm,rrr,FETCH_LWORD,S); end
				2'b11:	begin push(CMPA); fs_data(mmm,rrr,FETCH_WORD,S); end	// CMPA
				endcase
		end
//-----------------------------------------------------------------------------
// AND / EXG / MULU / MULS
//-----------------------------------------------------------------------------
	4'hC:
		begin
			casez(ir[11:0])
`ifdef SUPPORT_BCD			
			12'b???1_0000_????:	// ABCD
				if (ir[3]) begin
					push(ABCD);
					fs_data(3'b100,rrr,FETCH_BYTE,S);
				end
				else begin
					s <= rfoDnn;
					d <= rfoDn;
					state <= ABCD;
				end
`endif				
			12'b????_11??_????:	// MULS / MULU
				begin
					push(MUL);
					fs_data(mmm,rrr,FETCH_WORD,S);
				end
			12'b???1_0100_0???:
			begin
				Rt <= {1'b0,DDD};
				rfwrL <= 1'b1;
				resL <= rfoRnn;
				s <= rfoDn;
				state <= EXG1;
			end
			12'b???1_0100_1???:
			begin
				Rt <= {1'b1,AAA};
				rfwrL <= 1'b1;
				resL <= rfoRnn;
				s <= rfoAna;
				state <= EXG1;
			end
			12'b???1_1000_1???:
			begin
				Rt <= {1'b0,DDD};
				rfwrL <= 1'b1;
				resL <= rfoRnn;
				s <= rfoDn;
				state <= EXG1;
			end
			default:
				case(sz)
				2'b00:	begin push(AND); fs_data(mmm,rrr,FETCH_BYTE,ir[8]?D:S); end
				2'b01:	begin push(AND); fs_data(mmm,rrr,FETCH_WORD,ir[8]?D:S); end
				2'b10:	begin push(AND); fs_data(mmm,rrr,FETCH_LWORD,ir[8]?D:S); end
				default:	;	// Can't get here, picked off by MUL
				endcase
			endcase
		end

//-----------------------------------------------------------------------------
// ADD / ADDA
//-----------------------------------------------------------------------------
	4'hD:
		begin
			if (ir[8])
				s <= rfoDn;
			else
				d <= rfoDn;
			case(sz)
			2'b00:	begin push(ADD); fs_data(mmm,rrr,FETCH_BYTE,ir[8]?D:S); end
			2'b01:	begin push(ADD); fs_data(mmm,rrr,FETCH_WORD,ir[8]?D:S); end
			2'b10:	begin push(ADD); fs_data(mmm,rrr,FETCH_LWORD,ir[8]?D:S); end
			2'b11:
				begin
				d <= rfoAna;
				push(ADD);
				if (ir[8]) fs_data(mmm,rrr,FETCH_LWORD,S);
				else fs_data(mmm,rrr,FETCH_WORD,S);
				end
			endcase
		end
//-----------------------------------------------------------------------------
// ASL / LSL / ASR / LSR / ROL / ROR / ROXL / ROXR
//-----------------------------------------------------------------------------
	4'hE:
		begin
			if (sz==2'b11) begin
				cnt <= 6'd1;	// memory shifts only by one
				shift_op <= {ir[8],ir[10:9]};
				push(SHIFT1);
				fs_data(mmm,rrr,FETCH_WORD,D);
			end
			else begin
				shift_op <= {ir[8],ir[4:3]};
				goto (SHIFT);
				if (ir[5])
					cnt <= rfoDn[5:0];
				else
					cnt <= {2'b0,~|QQQ,QQQ};
				resL <= rfoDnn;
				resB <= rfoDnn[7:0];
				resW <= rfoDnn[15:0];
			end
		end
	endcase

//-----------------------------------------------------------------------------
// BCD arithmetic
// ABCD / SBCD / NBCD
//-----------------------------------------------------------------------------
`ifdef SUPPORT_BCD
ABCD:
	begin
		if (ir[3]) begin
			push(ABCD1);
			fs_data(3'b100,RRR,FETCH_BYTE,D);
		end
		else begin
			rfwrB <= 1'b1;
			Rt <= {1'b0,RRR};
			resB <= bcdaddo;
			cf <= bcdaddoc;
			xf <= bcdaddoc;
			nf <= bcdaddo[7];
			if (bcdaddo[7:0]!=8'h00)
				zf <= 1'b0;
			ret();
		end
	end
ABCD1:
	begin
		goto (STORE_BYTE);
		d <= bcdaddo;
		cf <= bcdaddoc;
		xf <= bcdaddoc;
		nf <= bcdaddo[7];
		if (bcdaddo[7:0]!=8'h00)
			zf <= 1'b0;
	end

SBCD:
	begin
		if (ir[3]) begin
			push(SBCD1);
			fs_data(3'b100,RRR,FETCH_BYTE,D);
		end
		else begin
			rfwrB <= 1'b1;
			Rt <= {1'b0,RRR};
			resB <= bcdsubo;
			cf <= bcdsuboc;
			xf <= bcdsuboc;
			nf <= bcdsubo[7];
			if(bcdsubo[7:0]!='d0)
				zf <= 1'b0;
			ret();
		end
	end
SBCD1:
	begin
		goto (STORE_BYTE);
		d <= bcdsubo;
		cf <= bcdsuboc;
		xf <= bcdsuboc;
		nf <= bcdsubo[7];
		if(bcdsubo[7:0]!='d0)
			zf <= 1'b0;
	end

NBCD:
	begin
		if (mmm==3'b000) begin
			Rt <= {1'b0,rrr};
			rfwrB <= 1'b1;
			resB <= bcdnego;
			ret();
		end
		else
			goto (STORE_BYTE);
		d <= bcdnego;
		cf <= bcdnegoc;
		xf <= bcdnegoc;
		nf <= bcdnego[7];
		if(bcdnego[7:0]!='d0)
			zf <= 1'b0;
	end
`endif

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
STOP:
	begin
		if (!sf) begin
			vecno <= `PRIV_VEC;
			goto (TRAP3);
		end
		else
			call (FETCH_IMM16, STOP1);
	end
STOP1:
	begin
		cf <= imm[0];
		vf <= imm[1];
		zf <= imm[2];
		nf <= imm[3];
		xf <= imm[4];
		im[0] <= imm[8];
		im[1] <= imm[9];
		im[2] <= imm[10];
		sf <= imm[13];
		tf <= imm[15];
		if (ipl_i > imm[10:8] || ipl_i==3'd7)
			ret();
	end

//-----------------------------------------------------------------------------
// MUL
//-----------------------------------------------------------------------------
MUL:
	begin
		flag_update <= FU_MUL;
`ifdef SUPPORT_MUL		
		if (ir[8]) begin
			rfwrL <= 1'b1;
			Rt <= {1'b0,DDD};
			resL <= rfoDns[15:0] * ss[15:0];
		end
		else begin
			rfwrL <= 1'b1;
			Rt <= {1'b0,DDD};
			resL <= rfoDn[15:0] * s[15:0];
		end
`endif		
		ret();
	end

//-----------------------------------------------------------------------------
// DIVU / DIVS
//-----------------------------------------------------------------------------
DIV1:
	if (s[15:0]==16'd0) begin
		vecno <= `DBZ_VEC;
		goto (TRAP3);
	end
	else
		goto (DIV2);
DIV2:
	if (dvdone) begin
		flag_update <= FU_DIV;
		Rt <= {1'b0,DDD};
		resL <= {divr[15:0],divq[15:0]};
		rfwrL <= 1'b1;
		ret();
	end

//-----------------------------------------------------------------------------
// NOT
//-----------------------------------------------------------------------------
NOT:
	begin
		resB <= ~d[7:0];
		resW <= ~d[15:0];
		resL <= ~d;
		d <= ~d;
		cf <= 1'b0;
		vf <= 1'b0;
		case(sz)
		2'b00:	begin zf <= d[7:0]==8'hFF; nf <= ~d[7]; end
		2'b01:	begin zf <= d[15:0]==16'hFFFF; nf <= ~d[15]; end
		2'b10:	begin zf <= d[31:0]==32'hFFFFFFFF; nf <= ~d[31]; end
		default:	;
		endcase
		if (mmm==3'b000) begin
			Rt <= {1'b0,rrr};
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
		else if (mmm==3'b001)
			ret();
		else begin
			case(sz)
			2'b00:	begin goto(STORE_BYTE); end
			2'b01:	begin goto(STORE_WORD); end
			2'b10:	begin goto(STORE_LWORD); end
			default:	;
			endcase
		end
	end

//-----------------------------------------------------------------------------
// NEG / NEGX
//-----------------------------------------------------------------------------
NEG:
	begin
		resL <= -d;
		resW <= -d[15:0];
		resB <= -d[7:0];
		d <= -d;
		s <= d;
		dd <= 'd0;
		goto (NEGX1);
	end
NEGX:
	begin
		resL <= -d - xf;
		resW <= -d[15:0] - xf;
		resB <= -d[7:0] - xf;
		d <= -d - xf;
		s <= d + xf;
		dd <= 'd0;
		goto (NEGX1);
	end
NEGX1:
	begin
		case(sz)
		2'b00:	begin cf <= resB[8]; nf <= resB[7]; vf <= fnSubOverflow(resB[7],dd[7],s[7]); zf <= resB[7:0]==8'h00; xf <= resB[8]; end
		2'b01:	begin cf <= resW[16]; nf <= resW[15]; vf <= fnSubOverflow(resW[15],dd[15],s[15]); zf <= resW[15:0]==16'h00; xf <= resW[16]; end
		2'b10:	begin cf <= resL[32]; nf <= resL[31]; vf <= fnSubOverflow(resL[31],dd[31],s[31]); zf <= resL[31:0]==32'h00; xf <= resL[32]; end
		endcase
		if (mmm==3'b000) begin
			Rt <= {1'b0,rrr};
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
		else if (mmm==3'b001)
			ret();
		else
			case(sz)
			2'b00:	begin goto(STORE_BYTE); end
			2'b01:	begin goto(STORE_WORD); end
			2'b10:	begin goto(STORE_LWORD); end
			default:	;
			endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
TAS:
	begin
		resB <= {1'b1,d[6:0]};
		cf <= 1'b0;
		vf <= 1'b0;
		zf <= d[7:0]==8'h00;
		nf <= d[7];
		d <= {1'b1,d[6:0]};
		goto(USTORE_BYTE);
	end

//-----------------------------------------------------------------------------
// Link
//-----------------------------------------------------------------------------
LINK:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		we_o <= 1'b1;
		adr_o <= sp - 32'd4;
`ifdef BIG_ENDIAN
    dat_o <= rbo(rfoAn);
`else
		dat_o <= rfoAn;
`endif
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 2'b00;
		sp <= sp - 32'd4;
		resL <= sp - 32'd4;
		rfwrL <= 1'b1;
		Rt <= {1'b1,rrr};
		call(FETCH_IMM16,LINK2);
	end
LINK2:
	begin
		sp <= sp + imm;
		ret();		
	end

//-----------------------------------------------------------------------------
// LEA
//-----------------------------------------------------------------------------
LEA:
	begin
		Rt <= {1'b1,AAA};
		rfwrL <= 1'b1;
		resL <= ea;
		ret();
	end
	
//-----------------------------------------------------------------------------
// PEA
//-----------------------------------------------------------------------------
PEA1:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= sp - 32'd4;
`ifdef BIG_ENDIAN
    dat_o <= rbo(ea);
`else		
		dat_o <= ea;
`endif		
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'b00;
		sp <= sp - 32'd4;
		ret();
	end

//-----------------------------------------------------------------------------
// DBRA
//-----------------------------------------------------------------------------
DBRA:
`ifndef OPT_PERF
	if (~takb)
`endif
	begin
		resW <= rfoDnn - 4'd1;
		Rt <= {1'b0,rrr};
		rfwrW <= 1'b1;
		if (rfoDnn[15:0]!=0)
			pc <= opc + imm;
		ret();
	end
`ifndef OPT_PERF
	else
		ret();
`endif

//-----------------------------------------------------------------------------
// EXG
//-----------------------------------------------------------------------------
EXG1:
	begin
		casez(ir)
		16'b1100_???1_0100_0???:
		begin
			Rt <= {1'b0,rrr};
			rfwrL <= 1'b1;
			resL <= s;
		end
		16'b1100_???1_0100_1???:
		begin
			Rt <= {1'b1,rrr};
			rfwrL <= 1'b1;
			resL <= s;
		end
		16'b1100_???1_1000_1???:
		begin
			Rt <= {1'b1,rrr};
			rfwrL <= 1'b1;
			resL <= s;
		end
		default:	;
		endcase
		ret();
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
STORE_IN_DEST:
	begin
//		state <= IFETCH;	// In event of bad ir
//		ret();
		resL <= s;
		resW <= s[15:0];
		resB <= s[7:0];
		d <= s;
		case(ir[15:12])
		4'd1:	begin zf <= s[ 7:0]== 8'h00; nf <= s[7]; end
		4'd3:	begin zf <= s[15:0]==16'h00; nf <= s[15]; end
		4'd2:	begin zf <= s[31:0]==32'd0;  nf <= s[31]; end
		default:	;
		endcase
		cf <= 1'b0;
		vf <= 1'b0;
		case(ir[15:12])
		4'd1:	fs_data(MMM,RRR,STORE_BYTE,D);
		4'd2:	fs_data(MMM,RRR,STORE_LWORD,D);
		4'd3:	fs_data(MMM,RRR,STORE_WORD,D);
		default:	;	// cant get here
		endcase
	end


//-----------------------------------------------------------------------------
// Compares
//-----------------------------------------------------------------------------
CMP:
	begin
		flag_update <= FU_CMP;
		d <= rfoDn;
		case(sz)
		2'b00:	resB <= rfoDn[ 7:0] - s[ 7:0];
		2'b01:	resW <= rfoDn[15:0] - s[15:0];
		2'b10:	resL <= rfoDn[31:0] - s[31:0];
		2'b11:
			begin
				d <= rfoAna;
				if (ir[8])
					resL <= rfoAna - s;
				else
					resW <= rfoAna[15:0] - s[15:0];
			end
		endcase
		ret();
	end

CMPA:
	begin
		flag_update <= FU_CMP;
		d <= rfoAna;
		case(ir[8])
		1'b0:	resW <= rfoAna[15:0] - s[15:0];
		1'b1:	resL <= rfoAna[31:0] - s[31:0];
		endcase
		ret();
	end

CMPM:
	begin
		case(sz)
		2'd0:	fs_data(3'b011,RRR,FETCH_BYTE,S);
		2'd1:	fs_data(3'b011,RRR,FETCH_WORD,S);
		2'd2:	fs_data(3'b011,RRR,FETCH_LWORD,S);
		default:	;	// cant get here
		endcase
		goto (CMPM1);
	end
CMPM1:
	begin
		flag_update <= FU_CMP;
		case(sz)
		2'b00:	resB <= d[ 7:0] - s[ 7:0];
		2'b01:	resW <= d[15:0] - s[15:0];
		2'b10:	resL <= d[31:0] - s[31:0];
		2'b11:	;
		endcase
		ret();
	end

//-----------------------------------------------------------------------------
// Shifts
//-----------------------------------------------------------------------------
SHIFT1:
	begin
		resB <= d[7:0];
		resW <= d[15:0];
		resL <= d[31:0];
		state <= SHIFT;
	end
SHIFT:
	if (cnt!='d0) begin
		cnt <= cnt - 2'd1;
		case(shift_op)
		3'b000:	// ASR
			case(sz)
			2'b00:	begin resB <= {resB[ 7],resB[ 7:1]}; cf <= resB[0]; xf <= resB[0]; vf <= 1'b0; end
			2'b01:	begin resW <= {resW[15],resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			2'b10:	begin resL <= {resL[31],resL[31:1]}; cf <= resL[0]; xf <= resL[0]; vf <= 1'b0; end
			2'b11:	begin resW <= {resW[15],resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			endcase
		3'b001:	// LSR
			case(sz)
			2'b00:	begin resB <= {1'b0,resB[ 7:1]}; cf <= resB[0]; xf <= resB[0]; vf <= 1'b0; end
			2'b01:	begin resW <= {1'b0,resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			2'b10:	begin resL <= {1'b0,resL[31:1]}; cf <= resL[0]; xf <= resL[0]; vf <= 1'b0; end
			2'b11:	begin resW <= {1'b0,resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			endcase
		3'b010:	// ROXR
			case(sz)
			2'b00:	begin resB <= {xf,resB[ 7:1]}; cf <= resB[0]; xf <= resB[0]; vf <= 1'b0; end
			2'b01:	begin resW <= {xf,resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			2'b10:	begin resL <= {xf,resL[31:1]}; cf <= resL[0]; xf <= resL[0]; vf <= 1'b0; end
			2'b11:	begin resW <= {xf,resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			endcase
		3'b011:	// ROR
			case(sz)
			2'b00:	begin resB <= {resB[0],resB[ 7:1]}; cf <= resB[0]; xf <= resB[0]; vf <= 1'b0; end
			2'b01:	begin resW <= {resW[0],resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			2'b10:	begin resL <= {resL[0],resL[31:1]}; cf <= resL[0]; xf <= resL[0]; vf <= 1'b0; end
			2'b11:	begin resW <= {resW[0],resW[15:1]}; cf <= resW[0]; xf <= resW[0]; vf <= 1'b0; end
			endcase
		3'b100:	// ASL
			case(sz)
			2'b00:	begin resB <= {resB[ 6:0],1'b0}; cf <= resB[ 7]; xf <= resB[ 7]; vf <= resB[ 6]!=resB[ 7]; end
			2'b01:	begin resW <= {resW[14:0],1'b0}; cf <= resW[15]; xf <= resW[15]; vf <= resW[14]!=resW[15]; end
			2'b10:	begin resL <= {resL[30:0],1'b0}; cf <= resL[31]; xf <= resL[31]; vf <= resL[30]!=resL[31]; end
			2'b11:	begin resW <= {resW[14:0],1'b0}; cf <= resW[15]; xf <= resW[15]; vf <= resW[14]!=resW[15]; end
			endcase
		3'b101:	// LSL
			case(sz)
			2'b00:	begin resB <= {resB[ 6:0],1'b0}; cf <= resB[ 7]; xf <= resB[ 7]; vf <= 1'b0; end
			2'b01:	begin resW <= {resW[14:0],1'b0}; cf <= resW[15]; xf <= resW[15]; vf <= 1'b0; end
			2'b10:	begin resL <= {resL[30:0],1'b0}; cf <= resL[31]; xf <= resL[31]; vf <= 1'b0; end
			2'b11:	begin resW <= {resW[14:0],1'b0}; cf <= resW[15]; xf <= resW[15]; vf <= 1'b0; end
			endcase
		3'b110:	// ROXL
			case(sz)
			2'b00:	begin resB <= {resB[ 6:0],xf}; cf <= resB[ 7]; xf <= resB[ 7]; vf <= 1'b0; end
			2'b01:	begin resW <= {resW[14:0],xf}; cf <= resW[15]; xf <= resW[15]; vf <= 1'b0; end
			2'b10:	begin resL <= {resL[30:0],xf}; cf <= resL[31]; xf <= resL[31]; vf <= 1'b0; end
			2'b11:	begin resW <= {resW[14:0],xf}; cf <= resW[15]; xf <= resW[15]; vf <= 1'b0; end
			endcase
		3'b111: // ROL
			case(sz)
			2'b00:	begin resB <= {resB[ 6:0],resB[ 7]}; cf <= resB[ 7]; xf <= resB[ 7]; vf <= 1'b0; end
			2'b01:	begin resW <= {resW[14:0],resW[15]}; cf <= resW[15]; xf <= resW[15]; vf <= 1'b0; end
			2'b10:	begin resL <= {resL[30:0],resL[31]}; cf <= resL[31]; xf <= resL[31]; vf <= 1'b0; end
			2'b11:	begin resW <= {resW[14:0],resW[15]}; cf <= resW[15]; xf <= resW[15]; vf <= 1'b0; end
			endcase
		endcase
	end
	else begin
		case(sz)
		2'b00:	d <= resB;
		2'b01:	d <= resW;
		2'b10:	d <= resL;
		2'b11:	d <= resW;
		endcase
		Rt <= {1'b0,rrr};
		case(sz)
		2'b00:	begin zf <= resB[7:0]== 8'h00; nf <= resB[ 7]; end
		2'b01:	begin zf <= resW[15:0]==16'h00; nf <= resW[15]; end
		2'b10:	begin zf <= resL[31:0]==32'h00; nf <= resL[31]; end
		2'b11:	begin zf <= resW[15:0]==16'h00; nf <= resW[15]; end
		endcase
		case(sz)
		2'b00:	begin rfwrB <= 1'b1; ret(); end
		2'b01:	begin rfwrW <= 1'b1; ret(); end
		2'b10:	begin rfwrL <= 1'b1; ret(); end
		2'b11:	fs_data(mmm,rrr,STORE_WORD,D);	// word operations only if memory operate
		endcase
	end
	
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
ADD:
	begin
		flag_update <= FU_ADD;
		if (sz==2'b11) begin
			Rt <= {1'b1,AAA};
			if (ir[8]) begin
				ret();
				rfwrL <= 1'b1;
				resL <= rfoAna + s;
				d <= rfoAna + s;
				dd <= rfoAna;
			end
			else begin
				resL <= rfoAna[15:0] + s[15:0];
				rfwrL <= 1'b1;
				d <= rfoAna + s;
				dd <= rfoAna;
				ret();	//*** sign extend result
			end
		end
		else if (ir[8]) begin
			resB <= d[7:0] + rfoDn[7:0];
			resW <= d[15:0] + rfoDn[15:0];
			resL <= d + rfoDn;
			d <= d + rfoDn;
			s <= rfoDn;
			dd <= d;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				case(sz)
				2'b00:	rfwrB <= 1'b1;
				2'b01:	rfwrW <= 1'b1;
				2'b10:	rfwrL <= 1'b1;
				default:	;
				endcase
				ret();
			end
			else begin
				case(sz)
				2'b00:	goto(STORE_BYTE);
				2'b01:	goto(STORE_WORD);
				2'b10:	goto(STORE_LWORD);
				default:	;
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] + s[7:0];
			resW <= rfoDn[15:0] + s[15:0];
			resL <= rfoDn + s;
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
SUB:
	begin
		flag_update <= FU_SUB;
		if (sz==2'b11) begin
			Rt <= {1'b1,AAA};
			if (ir[8]) begin
				ret();
				rfwrL <= 1'b1;
				resL <= rfoAna - s;
				d <= rfoAna - s;
				dd <= rfoAna;
			end
			else begin
				resL <= rfoAna[15:0] - s[15:0];
				rfwrL <= 1'b1;
				d <= rfoAna - s;
				dd <= rfoAna;
				ret();	//*** sign extend result
			end
		end
		else if (ir[8]) begin
			resB <= d[7:0] - rfoDn[7:0];
			resW <= d[15:0] - rfoDn[15:0];
			resL <= d - rfoDn;
			d <= d - rfoDn;
			dd <= d;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				case(sz)
				2'b00:	rfwrB <= 1'b1;
				2'b01:	rfwrW <= 1'b1;
				2'b10:	rfwrL <= 1'b1;
				default:	;
				endcase
				ret();
			end
			else begin
				case(sz)
				2'b00:	goto(STORE_BYTE);
				2'b01:	goto(STORE_WORD);
				2'b10:	goto(STORE_LWORD);
				default:	;
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] - s[7:0];
			resW <= rfoDn[15:0] - s[15:0];
			resL <= rfoDn - s;
			d1 <= rfoDn;
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
AND:
	begin
		flag_update <= FU_LOGIC;
		if (ir[8]) begin
			resB <= d[7:0] & rfoDn[7:0];
			resW <= d[15:0] & rfoDn[15:0];
			resL <= d & rfoDn;
			d <= d & rfoDn;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				case(sz)
				2'b00:	rfwrB <= 1'b1;
				2'b01:	rfwrW <= 1'b1;
				2'b10:	rfwrL <= 1'b1;
				default:	;
				endcase
				ret();
			end
			else begin
				case(sz)
				2'b00:	goto(STORE_BYTE);
				2'b01:	goto(STORE_WORD);
				2'b10:	goto(STORE_LWORD);
				default:	;
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] & s[7:0];
			resW <= rfoDn[15:0] & s[15:0];
			resL <= rfoDn & s;
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
	end

//-----------------------------------------------------------------------------
// OR
//-----------------------------------------------------------------------------
OR:
	begin
		flag_update <= FU_LOGIC;
		if (ir[8]) begin
			resB <= d[7:0] | rfoDn[7:0];
			resW <= d[15:0] | rfoDn[15:0];
			resL <= d | rfoDn;
			d <= d | rfoDn;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				case(sz)
				2'b00:	rfwrB <= 1'b1;
				2'b01:	rfwrW <= 1'b1;
				2'b10:	rfwrL <= 1'b1;
				default:	;	// DIV
				endcase
				ret();
			end
			else begin
				case(sz)
				2'b00:	goto(STORE_BYTE);
				2'b01:	goto(STORE_WORD); 
				2'b10:	goto(STORE_LWORD);
				default:	;	// DIV
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] | s[7:0];
			resW <= rfoDn[15:0] | s[15:0];
			resL <= rfoDn | s;
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
	end

//-----------------------------------------------------------------------------
// EOR
//-----------------------------------------------------------------------------
EOR:
	begin
		flag_update <= FU_LOGIC;
		resB <= d[7:0] ^ rfoDn[7:0];
		resW <= d[15:0] ^ rfoDn[15:0];
		resL <= d ^ rfoDn;
		d <= d ^ rfoDn;
		if (mmm[2:1]==2'd0) begin
			Rt <= {mmm[0],rrr};
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			ret();
		end
		else begin
			case(sz)
			2'b00:	goto(STORE_BYTE);
			2'b01:	goto(STORE_WORD);
			2'b10:	goto(STORE_LWORD);
			default:	;
			endcase
		end
	end

//-----------------------------------------------------------------------------
// ADDQ / SUBQ
// Flags are not updated if the target is an address register.
//-----------------------------------------------------------------------------
ADDQ:
	begin
		if (ir[8]) begin
			if (mmm!=3'b001)
				flag_update <= FU_SUBQ;
			resL <= d - immx;
			resB <= d[7:0] - immx[7:0];
			resW <= d[15:0] - immx[15:0];
			d <= d - immx;
			dd <= d;
			s <= immx;
		end
		else begin
			if (mmm!=3'b001)
				flag_update <= FU_ADDQ;
			resL <= d + immx;
			resB <= d[7:0] + immx[7:0];
			resW <= d[15:0] + immx[15:0];
			d <= d + immx;
			dd <= d;
			s <= immx;
		end
		if (mmm==3'd0 || mmm==3'd1) begin
			ret();
			Rt <= {mmm[0],rrr};
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
		end
		else
			case(sz)
			2'b00:	goto(STORE_BYTE);
			2'b01:	goto(STORE_WORD);
			2'b10:	goto(STORE_LWORD);
			default:	;	// Scc / DBRA
			endcase
	end

//-----------------------------------------------------------------------------
// ADDI / SUBI / CMPI / ANDI / ORI / EORI
//-----------------------------------------------------------------------------
ADDI:
	case(sz)
	2'b00:	begin call(FETCH_IMM8,ADDI2); end
	2'b01:	begin call(FETCH_IMM16,ADDI2); end
	2'b10:	begin call(FETCH_IMM32,ADDI2); end
	default:	tIllegal();
	endcase
ADDI2:
	begin
	immx <= imm;
	case(sz)
	2'b00:	begin push(ADDI3); fs_data(mmm,rrr,FETCH_BYTE,D); end
	2'b01:	begin push(ADDI3); fs_data(mmm,rrr,FETCH_WORD,D); end
	2'b10:	begin push(ADDI3); fs_data(mmm,rrr,FETCH_LWORD,D); end
	default:	;	// Cant get here
	endcase
	end
ADDI3:
	begin
		flag_update <= FU_ADDI;
		dd <= d;
		s <= imm;
		// Odd numbers are BIT insns.
		case(ir[11:8])
		4'h0:	resL <= d | immx;	// ORI
		4'h2:	resL <= d & immx;	// ANDI
		4'h4:	resL <= d - immx;	// SUBI
		4'h6:	resL <= d + immx;	// ADDI
		4'hA:	resL <= d ^ immx;	// EORI
		4'hC:	resL <= d - immx;	// CMPI
		default:	;
		endcase
		case(ir[11:8])
		4'h0:	resW <= d[15:0] | immx[15:0];	// ORI
		4'h2:	resW <= d[15:0] & immx[15:0];	// ANDI
		4'h4:	resW <= d[15:0] - immx[15:0];	// SUBI
		4'h6:	resW <= d[15:0] + immx[15:0];	// ADDI
		4'hA:	resW <= d[15:0] ^ immx[15:0];	// EORI
		4'hC:	resW <= d[15:0] - immx[15:0];	// CMPI
		default:	;
		endcase
		case(ir[11:8])
		4'h0:	resB <= d[7:0] | immx[7:0];	// ORI
		4'h2:	resB <= d[7:0] & immx[7:0];	// ANDI
		4'h4:	resB <= d[7:0] - immx[7:0];	// SUBI
		4'h6:	resB <= d[7:0] + immx[7:0];	// ADDI
		4'hA:	resB <= d[7:0] ^ immx[7:0];	// EORI
		4'hC:	resB <= d[7:0] - immx[7:0];	// CMPI
		default:	;
		endcase
		case(ir[11:8])
		4'h0:	d <= d | immx;	// ORI
		4'h2:	d <= d & immx;	// ANDI
		4'h4:	d <= d - immx;	// SUBI
		4'h6:	d <= d + immx;	// ADDI
		4'hA:	d <= d ^ immx;	// EORI
		4'hC:	d <= d - immx;	// CMPI
		default:	;
		endcase
		if (ir[11:8]==4'hC)
			ret();
		else if (mmm==3'b000 || mmm==3'b001) begin
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			Rt <= {mmm[0],rrr};
			ret();
		end
		else
			case(sz)
			2'b00:	goto(STORE_BYTE);
			2'b01:	goto(STORE_WORD);
			2'b10:	goto(STORE_LWORD);
			default:	ret();
			endcase
	end

//-----------------------------------------------------------------------------
// ANDI_CCR / ANDI_SR / EORI_CCR / EORI_SR / ORI_CCR / ORI_SR
//-----------------------------------------------------------------------------
//
ANDI_CCR:
	begin flag_update <= FU_ANDI_CCR; goto(FETCH_IMM8); end
ANDI_SR:
	begin flag_update <= FU_ANDI_SR; goto(FETCH_IMM16); end
ANDI_SRX:
	begin flag_update <= FU_ANDI_SRX; goto(FETCH_IMM32); end
EORI_CCR:
	begin flag_update <= FU_EORI_CCR; goto(FETCH_IMM8); end
EORI_SR:
	begin flag_update <= FU_EORI_SR; goto(FETCH_IMM16); end
EORI_SRX:
	begin flag_update <= FU_EORI_SRX; goto(FETCH_IMM32); end
ORI_CCR:
	begin flag_update <= FU_ORI_CCR; goto(FETCH_IMM8); end
ORI_SR:
	begin flag_update <= FU_ORI_SR; goto(FETCH_IMM16); end
ORI_SRX:
	begin flag_update <= FU_ORI_SRX; goto(FETCH_IMM32); end

//-----------------------------------------------------------------------------
// Bit manipulation
//-----------------------------------------------------------------------------
BIT:
	begin
		mmm_save <= mmm;
		if (ir[11:8]==4'h8) begin
			call(FETCH_IMM8,BIT1);
		end
		else begin
			imm <= rfoDn;
			goto(BIT1);
		end
	end
BIT1:
	begin
		bit2test <= imm;
		if (mmm_save==3'b000) begin	// Dn
			goto(BIT2);
			d <= rfob;
		end
		else begin
			push(BIT2);
			// This might fetch an immediate
			// might also alter mmm
			fs_data(mmm,rrr,FETCH_BYTE,D);
		end
	end
BIT2:
	begin
		if (mmm_save==3'b000 && sz!=2'b00) begin
			rfwrL <= 1'b1;
			Rt <= {1'b0,rrr};
			ret();
		end
		else begin
			goto(STORE_BYTE);
		end
		case(sz)
		2'b00:	begin zf <= ~d[bit2test[4:0]]; ret(); end
		2'b01:	begin
					zf <= ~d[bit2test[4:0]];
					resL <= d ^  (32'd1 << bit2test[4:0]);
					resB <= d ^  (32'd1 << bit2test[4:0]);
					d <= d ^  (32'd1 << bit2test[4:0]);
				end
		2'b10:	begin
					zf <= ~d[bit2test[4:0]];
					resL <= d & ~(32'd1 << bit2test[4:0]);
					resB <= d & ~(32'd1 << bit2test[4:0]);
					d <= d & ~(32'd1 << bit2test[4:0]);
				end
		2'b11:	begin
					zf <= ~d[bit2test[4:0]];
					resL <= d |  (32'd1 << bit2test[4:0]);
					resB <= d |  (32'd1 << bit2test[4:0]);
					d <= d |  (32'd1 << bit2test[4:0]);
				end
		default:	;
		endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
CHK:
	begin
		if (d[15] || $signed(d[15:0]) > $signed(s[15:0])) begin
			vecno <= `CHK_VEC;
	    state <= TRAP3;
		end
		else
			ret();
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
FETCH_NOP_BYTE,FETCH_NOP_WORD,FETCH_NOP_LWORD:
	ret();

FETCH_BRDISP:
	begin
/*
		if (fnInCache(pc)) begin
			tFindInCache(pc,disp);
			goto (FETCH_BRDISP1);
		end
		else
*/		
		if (!cyc_o) begin
			fc_o <= {sf,2'b10};
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= 4'b1111;
			adr_o <= pc;
		end
		else if (ack_i) begin
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'b00;
			// Record 'd' for bsr
`ifdef SUPPORT_B24		
			if (ir[0])
				d <= pc + {{9{ir[7]}},ir[7:1],iri,1'b0};
			else
`endif		
				d <= pc + {{16{iri[15]}},iri};
			// Want to point PC to return after displacement, it will be stacked
			if (bsr)
				pc <= pc + 4'd2;
			// else branch
			else begin
`ifdef SUPPORT_B24			
				if (ir[0])
					pc <= pc + {{9{ir[7]}},ir[7:1],iri,1'b0};
				else
`endif			
					pc <= pc + {{16{iri[15]}},iri};
			end
			ret();
		end
	end

// Fetch 8 bit immediate
//
FETCH_IMM8:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		imm <= {{24{iri[7]}},iri[7:0]};
		if (ds==D)
			d <= {{24{iri[7]}},iri[7:0]};
		else
			s <= {{24{iri[7]}},iri[7:0]};
		pc <= pc + 32'd2;
		ret();
	end

// Fetch 16 bit immediate
//
FETCH_IMM16:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		imm <= {{16{iri[15]}},iri};
		if (ds==D)
			d <= {{16{iri[15]}},iri};
		else
			s <= {{16{iri[15]}},iri};
		pc <= pc + 32'd2;
		ret();
	end

// Fetch 32 bit immediate
//
FETCH_IMM32:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		if (pc[1]) begin
`ifdef BIG_ENDIAN
			imm[31:16] <= {dat_i[23:16],dat_i[31:24]};
			if (ds==D)
				d[31:16] <= {dat_i[23:16],dat_i[31:24]};
			else
				s[31:16] <= {dat_i[23:16],dat_i[31:24]};
`else			
      imm[15:0] <= dat_i[31:16];
      if (ds==D)
      	d[15:0] <= dat_i[31:16];
     	else
      	s[15:0] <= dat_i[31:16];
`endif      
		  pc <= pc + 32'd2;
		  goto(FETCH_IMM32a);
		end
		else begin
`ifdef BIG_ENDIAN
			imm <= rbo(dat_i);
			if (ds==D)
				d <= rbo(dat_i);
			else
				s <= rbo(dat_i);
`else
      imm <= dat_i;
      if (ds==D)
      	d <= dat_i;
      else
      	s <= dat_i;
`endif      
		  cyc_o <= 1'b0;
		  pc <= pc + 32'd4;
		  ret();
		end
	end
FETCH_IMM32a:
	if (!stb_o) begin
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
`ifdef BIG_ENDIAN
		imm[15:0] <= {dat_i[7:0],dat_i[15:8]};
		if (ds==D)
			d[15:0] <= {dat_i[7:0],dat_i[15:8]};
		else
			s[15:0] <= {dat_i[7:0],dat_i[15:8]};
`else
		imm[31:16] <= dat_i[15:0];
		if (ds==D)
			d[31:26] <= dat_i[15:0];
		else
			s[31:26] <= dat_i[15:0];
`endif
		pc <= pc + 32'd2;
		ret();
	end

// Fetch 32 bit displacement
//
FETCH_D32:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
    if (pc[1]) begin
      stb_o <= 1'b0;
      sel_o <= 4'b0000;
`ifdef BIG_ENDIAN
			disp[31:16] <= {dat_i[23:16],dat_i[31:24]};
`else
      disp[15:0] <= dat_i[31:16];
`endif        
      pc <= pc + 32'd2;
  		state <= FETCH_D32a;
		end
		else begin
	    cyc_o <= `LOW;
      stb_o <= 1'b0;
      sel_o <= 4'b0000;
`ifdef BIG_ENDIAN
			disp <= rbo(dat_i);
`else      
      disp <= dat_i;
`endif      
      pc <= pc + 32'd4;
      state <= FETCH_D32b;
		end
	end
FETCH_D32a:
	if (!stb_o) begin
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
    cyc_o <= `LOW;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
`ifdef BIG_ENDIAN
		disp[15:0] <= {dat_i[7:0],dat_i[15:8]};
`else		
		disp[31:16] <= dat_i[15:0];
`endif		
		pc <= pc + 32'd2;
		state <= FETCH_D32b;
	end
FETCH_D32b:
	begin
		ea <= ea + disp;
		ret();
	end

// Fetch 16 bit displacement
//
FETCH_D16:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b0;
		disp <= {{16{iri[15]}},iri};
		pc <= pc + 32'd2;
		state <= FETCH_D16a;
	end
FETCH_D16a:
	begin
		ea <= ea + disp;
		ret();
	end

// Fetch index word
//
FETCH_NDX:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		disp <= {{24{iri[7]}},iri[7:0]};
		mmm <= {2'b00,iri[15]};	// to get reg
		rrr <= iri[14:12];
		wl <= iri[11];
		pc <= pc + 32'd2;
		state <= FETCH_NDXa;
	end
FETCH_NDXa:
	begin
		if (wl)
			ea <= ea + rfob + disp;
		else
			ea <= ea + {{16{rfob[15]}},rfob[15:0]} + disp;
		ret();
	end

FETCH_BYTE:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		adr_o <= ea;
		sel_o <= 4'b1111;
	end
	else if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		sel_o <= 4'b0000;
		if (ds==D) begin
	    case(ea[1:0])
	    2'b00:  d <= {{24{dat_i[7]}},dat_i[7:0]};
	    2'b01:  d <= {{24{dat_i[15]}},dat_i[15:8]};
	    2'b10:  d <= {{24{dat_i[23]}},dat_i[23:16]};
	    2'b11:  d <= {{24{dat_i[31]}},dat_i[31:24]};
	    default:  ;
	    endcase
		end
		else begin
	    case(ea[1:0])
      2'b00:  s <= {{24{dat_i[7]}},dat_i[7:0]};
      2'b01:  s <= {{24{dat_i[15]}},dat_i[15:8]};
      2'b10:  s <= {{24{dat_i[23]}},dat_i[23:16]};
      2'b11:  s <= {{24{dat_i[31]}},dat_i[31:24]};
      default:    ;
      endcase
		end
		ret();
	end

// Fetch byte, but hold onto bus
//
LFETCH_BYTE:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		lock_o <= `HIGH;
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		adr_o <= ea;
		sel_o <= 4'b1111;
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 4'b0;
		if (ds==D) begin
      case(ea[1:0])
      2'b00:  d <= {{24{dat_i[7]}},dat_i[7:0]};
      2'b01:  d <= {{24{dat_i[15]}},dat_i[15:8]};
      2'b10:  d <= {{24{dat_i[23]}},dat_i[23:16]};
      2'b11:  d <= {{24{dat_i[31]}},dat_i[31:24]};
      default:    ;
      endcase
    end
    else begin
      case(ea[1:0])
      2'b00:  s <= {{24{dat_i[7]}},dat_i[7:0]};
      2'b01:  s <= {{24{dat_i[15]}},dat_i[15:8]};
      2'b10:  s <= {{24{dat_i[23]}},dat_i[23:16]};
      2'b11:  s <= {{24{dat_i[31]}},dat_i[31:24]};
      default:    ;
      endcase
    end
		ret();
	end

FETCH_WORD:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		adr_o <= ea;
		sel_o <= 4'b1111;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
`ifdef BIG_ENDIAN
		if (ds==D)
		  d <= ea[1] ? {{16{dat_i[23]}},dat_i[23:16],dat_i[31:24]} : {{16{dat_i[7]}},dat_i[7:0],dat_i[15:8]};
		else
		  s <= ea[1] ? {{16{dat_i[23]}},dat_i[23:16],dat_i[31:24]} : {{16{dat_i[7]}},dat_i[7:0],dat_i[15:8]};
`else
		if (ds==D)
		  d <= ea[1] ? {{16{dat_i[31]}},dat_i[31:16]} : {{16{dat_i[15]}},dat_i[15:0]};
		else
		  s <= ea[1] ? {{16{dat_i[31]}},dat_i[31:16]} : {{16{dat_i[15]}},dat_i[15:0]};
`endif		  
		ret();
	end

FETCH_LWORD:
  case(ea)
  `CSR_CORENO,`CSR_TICK,`CSR_ICNT:
    begin
      if (ds==D)
        d <= csr_rego;
      else
        s <= csr_rego;
      ret();
  	end
  default:
	  if (!cyc_o) begin
			fc_o <= {sf,2'b01};
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			adr_o <= ea;
			sel_o <= 4'b1111;
		end
		else if (ack_i) begin
			stb_o <= 1'b0;
			sel_o <= 4'b00;
			if (ea[1]) begin
`ifdef BIG_ENDIAN
        if (ds==D)
          d[31:16] <= {dat_i[23:16],dat_i[31:24]};
        else
          s[31:16] <= {dat_i[23:16],dat_i[31:24]};
`else			
        if (ds==D)
          d[15:0] <= dat_i[31:16];
        else
          s[15:0] <= dat_i[31:16];
`endif          
    		state <= FETCH_LWORDa;
	    end
	    else begin
        cyc_o <= `LOW;
`ifdef BIG_ENDIAN
        if (ds==D)
            d <= rbo(dat_i);
        else
            s <= rbo(dat_i);
`else        
        if (ds==D)
            d <= dat_i;
        else
            s <= dat_i;
`endif            
        ret();
	    end
	end
	endcase
FETCH_LWORDa:
	if (!stb_o) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		adr_o <= adr_o + 32'd2;
		sel_o <= 4'b1111;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
`ifdef BIG_ENDIAN
		if (ds==D)
			d[15:0] <= {dat_i[7:0],dat_i[15:8]};
		else
			s[15:0] <= {dat_i[7:0],dat_i[15:8]};
`else		
		if (ds==D)
			d[31:16] <= dat_i[15:0];
		else
			s[31:16] <= dat_i[15:0];
`endif			
		ret();
	end


STORE_BYTE:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		case(ea[1:0])
		2'b00:	sel_o <= 4'b0001;
		2'b01:	sel_o <= 4'b0010;
		2'b10:	sel_o <= 4'b0100;
		2'b11:	sel_o <= 4'b1000;
		endcase
//		dat_o <= {4{resB[7:0]}};
		dat_o <= {4{d[7:0]}};
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'b0;
		ret();
	end

// Store byte and unlock
//
USTORE_BYTE:
	if (!stb_o) begin
		fc_o <= {sf,2'b01};
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		case(ea[1:0])
		2'b00:	sel_o <= 4'b0001;
		2'b01:	sel_o <= 4'b0010;
		2'b10:	sel_o <= 4'b0100;
		2'b11:	sel_o <= 4'b1000;
		endcase
//		dat_o <= {4{resB[7:0]}};
		dat_o <= {4{d[7:0]}};
	end
	else if (ack_i) begin
		lock_o <= 1'b0;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 2'b00;
		ret();
	end

STORE_WORD:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		sel_o <= ea[1] ? 4'b1100 : 4'b0011;
`ifdef BIG_ENDIAN
//		dat_o <= {2{resW[7:0],resW[15:8]}};
		dat_o <= {2{d[7:0],d[15:8]}};
`else		
//		dat_o <= {2{resW[15:0]}};
		dat_o <= {2{d[15:0]}};
`endif		
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 2'b00;
		ret();
	end
STORE_LWORD:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		sel_o <= ea[1] ? 4'b1100 : 4'b1111;
`ifdef BIG_ENDIAN
//		dat_o <= ea[1] ? {resL[23:16],resL[31:24],resL[7:0],resL[15:8]} : rbo(resL);
		dat_o <= ea[1] ? {d[23:16],d[31:24],d[7:0],d[15:8]} : rbo(d);
`else		
//		dat_o <= ea[1] ? {resL[15:0],resL[31:16]} : resL;
		dat_o <= ea[1] ? {d[15:0],d[31:16]} : d;
`endif		
	end
	else if (ack_i) begin
    if (ea[1]) begin
      stb_o <= 1'b0;
      we_o <= 1'b0;
      sel_o <= 4'b00;
      state <= STORE_LWORDa;
		end
		else begin
	    cyc_o <= `LOW;
      stb_o <= 1'b0;
      we_o <= 1'b0;
      sel_o <= 4'b00;
      ret();
		end
	end
STORE_LWORDa:
	if (!stb_o) begin
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= adr_o + 32'd2;
		sel_o <= 4'b0011;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'b0000;
		ret();
	end

//----------------------------------------------------
//----------------------------------------------------
RESET:
  begin
    pc <= `RESET_VECTOR;
    push(IFETCH);
    goto(TRAP);
	end

//----------------------------------------------------
//----------------------------------------------------
TRAP:
  begin
    goto (TRAP3);
    /*
    if (is_nmi)
        vecno <= `NMI_VEC;
    else
    */
    case(1'b1)
    // group 0
    is_rst:
    	begin
    		is_rst <= 1'b0;
    		tf <= 1'b0;
    		sf <= 1'b1;
    		im <= 3'd7;
    		vecno <= `RESET_VEC;
    		goto(TRAP6);
    	end
    is_adr_err:
    	begin
    		isr <= srx;
    		tf <= 1'b0;
    		sf <= 1'b1;
	    	vecno <= `ADDRERR_VEC;
      	goto (TRAP3);
    	end
    is_bus_err:
    	begin
    		isr <= srx;
    		tf <= 1'b0;
    		sf <= 1'b1;
    		vecno <= `BUSERR_VEC;
      	goto (TRAP3);
    	end
    // group 1
    is_trace:
    	begin
    		isr <= srx;
    		tf <= 1'b0;
    		sf <= 1'b1;
    		vecno <= `TRACE_VEC;
      	goto (TRAP3);
    	end
    is_irq:
    	begin
    		isr <= srx;
    		tf <= 1'b0;
    		sf <= 1'b1;
      	vecno <= `IRQ_VEC + ipl_i;
      	im <= ipl_i;
      	goto (INTA);
    	end
    is_priv:
    	begin
    		isr <= srx;
    		tf <= 1'b0;
    		sf <= 1'b1;
    		vecno <= `PRIV_VEC;
      	goto (TRAP3);
    	end
    default:
      vecno <= `TRAP_VEC + ir[3:0];
    endcase
  end
INTA:
  if (!cyc_o) begin
  	fc_o <= 3'b111;
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    sel_o <= 4'b1111;
    adr_o <= {28'hFFFFFFF,ipl_i,1'b0};
  end
  else if (ack_i|err_i|vpa_i) begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    sel_o <= 4'b0;
    pc <= pc + 32'd2;
    if (err_i)
    	vecno <= `SPURIOUS_VEC;
    else if (!vpa_i)
    	vecno <= iri[7:0];
    goto (TRAP3);
  end
TRAP3:
	begin
		// If was in user mode, capture stack pointer in usp.
		if (!isr[13]) begin
			usp <= sp;
			sp <= ssp;
		end
`ifdef SUPPORT_010
		if (is_bus_err | is_adr_err)
			goto (TRAP20);
		else
`endif		
		goto (TRAP3a);
	end
// First 16 words of internal state are stored
TRAP20:
	begin
		sp <= sp - 6'd32;
		goto (TRAP21);
	end
// Next instruction input buffer.
TRAP21:
	begin
		d <= ir;
		ea <= sp - 4'd2;
		sp <= sp - 4'd2;
		call (STORE_WORD, TRAP22);
	end
TRAP22:
	begin
		d <= dati_buf;
		ea <= sp - 4'd4;
		sp <= sp - 4'd4;
		call (STORE_LWORD, TRAP23);
	end
TRAP23:
	begin
		d <= dato_buf;
		ea <= sp - 4'd4;
		sp <= sp - 4'd4;
		call (STORE_LWORD, TRAP24);
	end
// 1 word Unused
TRAP24:
	begin
		sp <= sp - 4'd2;
		goto (TRAP25);
	end
TRAP25:
	begin
		d <= bad_addr;
		ea <= sp - 4'd4;
		sp <= sp - 4'd4;
		call (STORE_LWORD, TRAP26);
	end
TRAP26:
	begin
		d <= mac_cycle_type;
		ea <= sp - 4'd2;
		sp <= sp - 4'd2;
		s <= sp - 4'd2;
		call (STORE_WORD, TRAP3a);
	end
// For the 68010 and above push the format word.
TRAP3a:
	begin
`ifdef SUPPORT_010
		if (is_bus_err|is_adr_err)
			d <= {4'b1000,2'b00,vecno,2'b00};
		else		
			d <= {4'b0000,2'b00,vecno,2'b00};
		ea <= sp - 4'd2;
		sp <= sp - 4'd2;
		call (STORE_WORD, TRAP3b);
`else		
		goto (TRAP3b);
`endif		
	end
// Push the program counter
TRAP3b:
	begin
		d <= pc;
		ea <= sp - 4'd4;
		sp <= sp - 4'd4;
		call (STORE_LWORD, TRAP4);
	end
// And the status register
TRAP4:
	begin
		d <= isr;
		ea <= sp - 4'd2;
		sp <= sp - 4'd2;
		s <= sp - 4'd2;
`ifdef SUPPORT_010
		call (STORE_WORD, TRAP7);
`else		
		call (STORE_WORD, is_bus_err|is_adr_err?TRAP8:TRAP7);
`endif		
	end
// Push IR
TRAP8:
	begin
		d <= ir;
		ea <= sp - 4'd2;
		sp <= sp - 4'd2;
		is_bus_err <= 1'b0;
		is_adr_err <= 1'b0;
		call (STORE_WORD, TRAP9);
	end
// Push bad address
TRAP9:
	begin
		d <= bad_addr;
		ea <= sp - 4'd4;
		sp <= sp - 4'd4;
		call (STORE_LWORD, TRAP10);
	end
TRAP10:
	begin
		d <= mac_cycle_type;
		ea <= sp - 4'd2;
		sp <= sp - 4'd2;
		s <= sp - 4'd2;
		call (STORE_WORD, TRAP7);
	end
// Load SP from vector table
TRAP6:
	begin
		ea <= 'd0;
		ds <= S;
		call (FETCH_LWORD, TRAP7);
	end
// Load PC from vector table.
TRAP7:
	begin
		sp <= s;
		ssp <= s;
		ea <= {vbr[31:10],vecno,2'b00};
		ds <= S;
		call (FETCH_LWORD, TRAP7a);
	end
TRAP7a:
	begin
		pc <= s;
		ret();
	end

//----------------------------------------------------
//----------------------------------------------------
/*
JMP_VECTOR:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 2'b11;
		adr_o <= vector;
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		pc[15:0] <= dat_i;
		state <= JMP_VECTOR2;
	end
JMP_VECTOR2:
	if (!stb_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 2'b11;
		adr_o <= adr_o + 32'd2;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		pc[31:16] <= dat_i;
		state <= IFETCH;
	end
*/
//----------------------------------------------------
//----------------------------------------------------
UNLNK:
	begin
		ds <= S;
		ea <= sp;
		sp <= sp + 4'd4;
		call (FETCH_LWORD,UNLNK2);
	end
UNLNK2:
	begin
		rfwrL <= 1'b1;
		Rt <= {1'b1,rrr};
		resL <= s;
		ret();
	end

//----------------------------------------------------
// JMP / JSR / BSR
//----------------------------------------------------

JMP:
	begin
		pc <= d;
		ret();
	end
JSR:
	begin
		ea <= sp - 4'd4;
		sp <= sp - 4'd4;
		d <= pc;
		pc <= d;
		goto (STORE_LWORD);
	end
/*
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= sp - 32'd4;
`ifdef BIG_ENDIAN
		dat_o <= rbo(pc);
`else		
		dat_o <= pc;
`endif		
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'b00;
		sp <= sp - 32'd4;
		pc <= d;
`ifdef SUPPORT_TASK		
`ifdef BIG_ENDIAN		
		if (d[24]) begin
			otr <= tr;
			tr <= d[29:25];
    	reg_copy_mask <= {d[7:0],d[15:8],d[16]};
			goto (THREAD2);
    end
		else
			ret();
`else    	
		if (d[0]) begin
			otr <= tr;
			tr <= d[5:1];
			reg_copy_mask <= d[31:16];
			goto (THREAD2);
		end
		else
			ret();
`endif
`else
		ret();
`endif
	end
*/

//----------------------------------------------------
// RTE / RTR
// Return from exception
//----------------------------------------------------

RTE1:
	begin
		ds <= S;
		ea <= sp;
		sp <= sp + 4'd2;
		call (FETCH_WORD,RTE2);
	end
RTE2:
	begin
		ds <= S;
		ea <= sp;
		sp <= sp + 4'd4;
		cf <= s[0];
		vf <= s[1];
		zf <= s[2];
		nf <= s[3];
		xf <= s[4];
		ccr57 <= s[7:5];
		if (!rtr) begin
			im[0] <= s[8];
			im[1] <= s[9];
			im[2] <= s[10];
			sr1112 <= s[12:11];
			sf <= s[13];
			sr14 <= s[14];
			tf <= s[15];
			//pl <= s[31:24];
		end
		call (FETCH_LWORD,RTE3);
	end
RTE3:
	begin
		pc <= s;
`ifdef SUPPORT_010
		ea <= sp;
		sp <= sp + 4'd2;
		if (!rtr)
			call (FETCH_WORD,RTE4);
		else
			ret();
`else		
		ret();
`endif		
	end
// The core might have been in supervisor mode already when the exception
// occurred. Reset the working stack pointer accordingly.
`ifdef SUPPORT_010
RTE4:
	begin
		if (s[15:12]==4'b1000) begin
			ea <= sp;
			sp <= sp + 4'd2;
			call(FETCH_WORD,RTE5);
		end
		else begin
			if (!sf) begin
				ssp <= sp;
				sp <= usp;	// switch back to user stack
			end
			ret();
		end
	end
RTE5:
	begin
		mac_cycle_type <= s;
		ea <= sp;
		sp <= sp + 4'd4;
		call(FETCH_LWORD,RTE6);
	end
RTE6:
	begin
		bad_addr <= s;
		ea <= sp;
		sp <= sp + 4'd2;
		call(FETCH_WORD,RTE7);
	end
RTE7:
	begin
		ea <= sp;
		sp <= sp + 4'd4;
		call(FETCH_LWORD,RTE8);
	end
RTE8:
	begin
		dato_buf <= s;
		ea <= sp;
		sp <= sp + 4'd4;
		call(FETCH_LWORD,RTE9);
	end
RTE9:
	begin
		dati_buf <= s;
		ea <= sp;
		sp <= sp + 4'd2;
		call(FETCH_WORD,RTE10);
	end
RTE10:
	begin
		ea <= sp;
		sp <= sp + 6'd32;
		goto (RTE11);
	end
RTE11:
	begin
		if (!sf) begin
			ssp <= sp;
			sp <= usp;	// switch back to user stack
		end
		ret();
	end
`endif
	
//----------------------------------------------------
// Return from subroutine.
//----------------------------------------------------

RTS1:
	begin
		pc <= s;
		ret();
	end

//----------------------------------------------------
MOVEM_Xn2D:
`ifdef OPT_PERF
	if (imm[15:0]!=16'h0000) begin
		push(MOVEM_Xn2D2);
		fs_data(mmm,rrr,ir[6] ? FETCH_NOP_LWORD : FETCH_NOP_WORD,D);
	end
	else
		fs_data(mmm,rrr,ir[6] ? FETCH_NOP_LWORD : FETCH_NOP_WORD,D);
`else
	begin
		push(MOVEM_Xn2D2);
		fs_data(mmm,rrr,ir[6] ? FETCH_NOP_LWORD : FETCH_NOP_WORD,D);
	end
`endif
MOVEM_Xn2D2:
	begin
		if (imm[15:0]!=16'h0000)
			state <= MOVEM_Xn2D3;
		else begin
			case(mmm)
			3'b100:	// -(An)
				begin
					Rt <= {1'b1,rrr};
					resL <= ea + (ir[6] ? 32'd4 : 32'd2);
					rfwrL <= 1'b1;
				end
			endcase
			ret();
		end
		if (mmm!=3'b100) begin
			if (imm[0]) begin
				imm[0] <= 1'b0;
				rrrr <= 4'd0;
			end
			else if (imm[1]) begin
				imm[1] <= 1'b0;
				rrrr <= 4'd1;
			end
			else if (imm[2]) begin
				imm[2] <= 1'b0;
				rrrr <= 4'd2;
			end
			else if (imm[3]) begin
				imm[3] <= 1'b0;
				rrrr <= 4'd3;
			end
			else if (imm[4]) begin
				imm[4] <= 1'b0;
				rrrr <= 4'd4;
			end
			else if (imm[5]) begin
				imm[5] <= 1'b0;
				rrrr <= 4'd5;
			end
			else if (imm[6]) begin
				imm[6] <= 1'b0;
				rrrr <= 4'd6;
			end
			else if (imm[7]) begin
				imm[7] <= 1'b0;
				rrrr <= 4'd7;
			end
			else if (imm[8]) begin
				imm[8] <= 1'b0;
				rrrr <= 4'd8;
			end
			else if (imm[9]) begin
				imm[9] <= 1'b0;
				rrrr <= 4'd9;
			end
			else if (imm[10]) begin
				imm[10] <= 1'b0;
				rrrr <= 4'd10;
			end
			else if (imm[11]) begin
				imm[11] <= 1'b0;
				rrrr <= 4'd11;
			end
			else if (imm[12]) begin
				imm[12] <= 1'b0;
				rrrr <= 4'd12;
			end
			else if (imm[13]) begin
				imm[13] <= 1'b0;
				rrrr <= 4'd13;
			end
			else if (imm[14]) begin
				imm[14] <= 1'b0;
				rrrr <= 4'd14;
			end
			else if (imm[15]) begin
				imm[15] <= 1'b0;
				rrrr <= 4'd15;
			end
		end
		else begin
			if (imm[0]) begin
				imm[0] <= 1'b0;
				rrrr <= 4'd15;
			end
			else if (imm[1]) begin
				imm[1] <= 1'b0;
				rrrr <= 4'd14;
			end
			else if (imm[2]) begin
				imm[2] <= 1'b0;
				rrrr <= 4'd13;
			end
			else if (imm[3]) begin
				imm[3] <= 1'b0;
				rrrr <= 4'd12;
			end
			else if (imm[4]) begin
				imm[4] <= 1'b0;
				rrrr <= 4'd11;
			end
			else if (imm[5]) begin
				imm[5] <= 1'b0;
				rrrr <= 4'd10;
			end
			else if (imm[6]) begin
				imm[6] <= 1'b0;
				rrrr <= 4'd9;
			end
			else if (imm[7]) begin
				imm[7] <= 1'b0;
				rrrr <= 4'd8;
			end
			else if (imm[8]) begin
				imm[8] <= 1'b0;
				rrrr <= 4'd7;
			end
			else if (imm[9]) begin
				imm[9] <= 1'b0;
				rrrr <= 4'd6;
			end
			else if (imm[10]) begin
				imm[10] <= 1'b0;
				rrrr <= 4'd5;
			end
			else if (imm[11]) begin
				imm[11] <= 1'b0;
				rrrr <= 4'd4;
			end
			else if (imm[12]) begin
				imm[12] <= 1'b0;
				rrrr <= 4'd3;
			end
			else if (imm[13]) begin
				imm[13] <= 1'b0;
				rrrr <= 4'd2;
			end
			else if (imm[14]) begin
				imm[14] <= 1'b0;
				rrrr <= 4'd1;
			end
			else if (imm[15]) begin
				imm[15] <= 1'b0;
				rrrr <= 4'd0;
			end
		end
	end
MOVEM_Xn2D3:
	begin
		resL <= rfoRnn;
		resW <= rfoRnn[15:0];
		d <= rfoRnn;
		ds <= D;
		call(ir[6] ? STORE_LWORD : STORE_WORD,MOVEM_Xn2D4);
	end
MOVEM_Xn2D4:
	begin
		case(mmm)
		3'b011:	ea <= ea + (ir[6] ? 32'd4 : 32'd2);
		3'b100:	ea <= ea - (ir[6] ? 32'd4 : 32'd2);
		default:
			ea <= ea + (ir[6] ? 32'd4 : 32'd2);
		endcase
		if (imm[15:0]!=16'h0000)
			state <= MOVEM_Xn2D3;
		else begin
			case(mmm)
			3'b011:
				begin
					Rt <= {1'b1,rrr};
					resL <= ea + (ir[6] ? 32'd4 : 32'd2);
					rfwrL <= 1'b1;
				end
			3'b100:
				begin
					Rt <= {1'b1,rrr};
					resL <= ea;
					rfwrL <= 1'b1;
				end
			endcase
			ret();
		end
		if (mmm!=3'b100) begin
			if (imm[0]) begin
				imm[0] <= 1'b0;
				rrrr <= 4'd0;
			end
			else if (imm[1]) begin
				imm[1] <= 1'b0;
				rrrr <= 4'd1;
			end
			else if (imm[2]) begin
				imm[2] <= 1'b0;
				rrrr <= 4'd2;
			end
			else if (imm[3]) begin
				imm[3] <= 1'b0;
				rrrr <= 4'd3;
			end
			else if (imm[4]) begin
				imm[4] <= 1'b0;
				rrrr <= 4'd4;
			end
			else if (imm[5]) begin
				imm[5] <= 1'b0;
				rrrr <= 4'd5;
			end
			else if (imm[6]) begin
				imm[6] <= 1'b0;
				rrrr <= 4'd6;
			end
			else if (imm[7]) begin
				imm[7] <= 1'b0;
				rrrr <= 4'd7;
			end
			else if (imm[8]) begin
				imm[8] <= 1'b0;
				rrrr <= 4'd8;
			end
			else if (imm[9]) begin
				imm[9] <= 1'b0;
				rrrr <= 4'd9;
			end
			else if (imm[10]) begin
				imm[10] <= 1'b0;
				rrrr <= 4'd10;
			end
			else if (imm[11]) begin
				imm[11] <= 1'b0;
				rrrr <= 4'd11;
			end
			else if (imm[12]) begin
				imm[12] <= 1'b0;
				rrrr <= 4'd12;
			end
			else if (imm[13]) begin
				imm[13] <= 1'b0;
				rrrr <= 4'd13;
			end
			else if (imm[14]) begin
				imm[14] <= 1'b0;
				rrrr <= 4'd14;
			end
			else if (imm[15]) begin
				imm[15] <= 1'b0;
				rrrr <= 4'd15;
			end
		end
		else begin
			if (imm[0]) begin
				imm[0] <= 1'b0;
				rrrr <= 4'd15;
			end
			else if (imm[1]) begin
				imm[1] <= 1'b0;
				rrrr <= 4'd14;
			end
			else if (imm[2]) begin
				imm[2] <= 1'b0;
				rrrr <= 4'd13;
			end
			else if (imm[3]) begin
				imm[3] <= 1'b0;
				rrrr <= 4'd12;
			end
			else if (imm[4]) begin
				imm[4] <= 1'b0;
				rrrr <= 4'd11;
			end
			else if (imm[5]) begin
				imm[5] <= 1'b0;
				rrrr <= 4'd10;
			end
			else if (imm[6]) begin
				imm[6] <= 1'b0;
				rrrr <= 4'd9;
			end
			else if (imm[7]) begin
				imm[7] <= 1'b0;
				rrrr <= 4'd8;
			end
			else if (imm[8]) begin
				imm[8] <= 1'b0;
				rrrr <= 4'd7;
			end
			else if (imm[9]) begin
				imm[9] <= 1'b0;
				rrrr <= 4'd6;
			end
			else if (imm[10]) begin
				imm[10] <= 1'b0;
				rrrr <= 4'd5;
			end
			else if (imm[11]) begin
				imm[11] <= 1'b0;
				rrrr <= 4'd4;
			end
			else if (imm[12]) begin
				imm[12] <= 1'b0;
				rrrr <= 4'd3;
			end
			else if (imm[13]) begin
				imm[13] <= 1'b0;
				rrrr <= 4'd2;
			end
			else if (imm[14]) begin
				imm[14] <= 1'b0;
				rrrr <= 4'd1;
			end
			else if (imm[15]) begin
				imm[15] <= 1'b0;
				rrrr <= 4'd0;
			end
		end
	end
	
//----------------------------------------------------
MOVEM_s2Xn:
`ifdef OPT_PERF
	if (imm[15:0]!=16'h0000) begin
		push(MOVEM_s2Xn2);
		fs_data(mmm,rrr,ir[6] ? FETCH_NOP_LWORD : FETCH_NOP_WORD,S);
	end
	else
		fs_data(mmm,rrr,ir[6] ? FETCH_NOP_LWORD : FETCH_NOP_WORD,S);
`else
	begin
		push(MOVEM_s2Xn2);
		fs_data(mmm,rrr,ir[6] ? FETCH_NOP_LWORD : FETCH_NOP_WORD,S);
	end
`endif
MOVEM_s2Xn2:
	if (imm[15:0] != 16'h0000) begin
		ds <= S;
		call(ir[6] ? FETCH_LWORD : FETCH_WORD,MOVEM_s2Xn3);
	end
	else begin
		case(mmm)
		3'b011:	// (An)+
			begin
				Rt <= {1'b1,rrr};
				resL <= ea;
				rfwrL <= 1'b1;
			end
		3'b100:	// -(An)
			begin
				Rt <= {1'b1,rrr};
				resL <= ea + (ir[6] ? 32'd4 : 32'd2);
				rfwrL <= 1'b1;
			end
		endcase
		ret();
	end
MOVEM_s2Xn3:
	begin
		case(mmm)
		3'b011:	ea <= ea + (ir[6] ? 32'd4 : 32'd2);
		3'b100:	ea <= ea - (ir[6] ? 32'd4 : 32'd2);
		default:
			ea <= ea + (ir[6] ? 32'd4 : 32'd2);
		endcase
		goto (MOVEM_s2Xn2);
		// Another bizzare gotcha. Word values moved to a data register are sign
		// extended to long-word width.
		rfwrL <= 1'b1;
		if (ir[6])
			resL <= s;
		else
			resL <= {{16{s[15]}},s[15:0]};
		if (mmm!=3'b100) begin
			if (imm[0]) begin
				imm[0] <= 1'b0;
				Rt <= 4'd0;
			end
			else if (imm[1]) begin
				imm[1] <= 1'b0;
				Rt <= 4'd1;
			end
			else if (imm[2]) begin
				imm[2] <= 1'b0;
				Rt <= 4'd2;
			end
			else if (imm[3]) begin
				imm[3] <= 1'b0;
				Rt <= 4'd3;
			end
			else if (imm[4]) begin
				imm[4] <= 1'b0;
				Rt <= 4'd4;
			end
			else if (imm[5]) begin
				imm[5] <= 1'b0;
				Rt <= 4'd5;
			end
			else if (imm[6]) begin
				imm[6] <= 1'b0;
				Rt <= 4'd6;
			end
			else if (imm[7]) begin
				imm[7] <= 1'b0;
				Rt <= 4'd7;
			end
			else if (imm[8]) begin
				imm[8] <= 1'b0;
				Rt <= 4'd8;
			end
			else if (imm[9]) begin
				imm[9] <= 1'b0;
				Rt <= 4'd9;
			end
			else if (imm[10]) begin
				imm[10] <= 1'b0;
				Rt <= 4'd10;
			end
			else if (imm[11]) begin
				imm[11] <= 1'b0;
				Rt <= 4'd11;
			end
			else if (imm[12]) begin
				imm[12] <= 1'b0;
				Rt <= 4'd12;
			end
			else if (imm[13]) begin
				imm[13] <= 1'b0;
				Rt <= 4'd13;
			end
			else if (imm[14]) begin
				imm[14] <= 1'b0;
				Rt <= 4'd14;
			end
			else if (imm[15]) begin
				imm[15] <= 1'b0;
				Rt <= 4'd15;
			end
		end
		else begin
			if (imm[0]) begin
				imm[0] <= 1'b0;
				Rt <= 4'd15;
			end
			else if (imm[1]) begin
				imm[1] <= 1'b0;
				Rt <= 4'd14;
			end
			else if (imm[2]) begin
				imm[2] <= 1'b0;
				Rt <= 4'd13;
			end
			else if (imm[3]) begin
				imm[3] <= 1'b0;
				Rt <= 4'd12;
			end
			else if (imm[4]) begin
				imm[4] <= 1'b0;
				Rt <= 4'd11;
			end
			else if (imm[5]) begin
				imm[5] <= 1'b0;
				Rt <= 4'd10;
			end
			else if (imm[6]) begin
				imm[6] <= 1'b0;
				Rt <= 4'd9;
			end
			else if (imm[7]) begin
				imm[7] <= 1'b0;
				Rt <= 4'd8;
			end
			else if (imm[8]) begin
				imm[8] <= 1'b0;
				Rt <= 4'd7;
			end
			else if (imm[9]) begin
				imm[9] <= 1'b0;
				Rt <= 4'd6;
			end
			else if (imm[10]) begin
				imm[10] <= 1'b0;
				Rt <= 4'd5;
			end
			else if (imm[11]) begin
				imm[11] <= 1'b0;
				Rt <= 4'd4;
			end
			else if (imm[12]) begin
				imm[12] <= 1'b0;
				Rt <= 4'd3;
			end
			else if (imm[13]) begin
				imm[13] <= 1'b0;
				Rt <= 4'd2;
			end
			else if (imm[14]) begin
				imm[14] <= 1'b0;
				Rt <= 4'd1;
			end
			else if (imm[15]) begin
				imm[15] <= 1'b0;
				Rt <= 4'd0;
			end
		end
	end
//----------------------------------------------------
RETSTATE:
	ret();

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
MOVEP:
	if (!cyc_o) begin
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		we_o <= ir[7];
		casez({ir[7],ea[1:0]})
		3'b0??:	sel_o <= 4'b1111;
		3'b100:	sel_o <= 4'b0001;
		3'b101:	sel_o <= 4'b0010;
		3'b110:	sel_o <= 4'b0100;
		3'b111:	sel_o <= 4'b1000;
		endcase
		adr_o <= ea;
		if (ir[6])
			dat_o <= {4{rfoDn[31:24]}};
		else
			dat_o <= {4{rfoDn[15:8]}};
	end
	else if (ack_i) begin
		stb_o <= `LOW;
		if (ir[6])
			resL[31:24] <= dat_i >> {ea[1:0],3'b0};
		else
			resW[15:8] <= dat_i >> {ea[1:0],3'b0};
		goto (MOVEP1);
	end
MOVEP1:
	if (!stb_o) begin
		stb_o <= `HIGH;
		we_o <= ir[7];
		casez({ir[7],~ea[1],ea[0]})
		3'b0??:	sel_o <= 4'b1111;
		3'b100:	sel_o <= 4'b0001;
		3'b101:	sel_o <= 4'b0010;
		3'b110:	sel_o <= 4'b0100;
		3'b111:	sel_o <= 4'b1000;
		endcase
		adr_o <= ea + 4'd2;
		if (ir[6])
			dat_o <= {4{rfoDn[23:16]}};
		else
			dat_o <= {4{rfoDn[7:0]}};
	end
	else if (ack_i) begin
		stb_o <= `LOW;
		if (ir[6])
			resL[23:16] <= dat_i >> {ea[1:0]+4'd2,3'b0};
		else
			resW[7:0] <= dat_i >> {ea[1:0]+4'd2,3'b0};
		Rt <= {1'b0,DDD};
		if (ir[6])
			goto (MOVEP2);
		else begin
			cyc_o <= `LOW;
			we_o <= `LOW;
			sel_o <= 4'h0;
			rfwrW <= ~ir[7];
			ret();
		end
	end
MOVEP2:
	if (!stb_o) begin
		stb_o <= `HIGH;
		we_o <= ir[7];
		casez({ir[7],ea[1:0]})
		3'b0??:	sel_o <= 4'b1111;
		3'b100:	sel_o <= 4'b0001;
		3'b101:	sel_o <= 4'b0010;
		3'b110:	sel_o <= 4'b0100;
		3'b111:	sel_o <= 4'b1000;
		endcase
		adr_o <= ea + 4'd4;
		dat_o <= {4{rfoDn[15:8]}};
	end
	else if (ack_i) begin
		stb_o <= `LOW;
		resL[15:8] <= dat_i >> {ea[1:0],3'b0};
		goto (MOVEP3);
	end
MOVEP3:
	if (!stb_o) begin
		stb_o <= `HIGH;
		we_o <= ir[7];
		casez({ir[7],~ea[1],ea[0]})
		3'b0??:	sel_o <= 4'b1111;
		3'b100:	sel_o <= 4'b0001;
		3'b101:	sel_o <= 4'b0010;
		3'b110:	sel_o <= 4'b0100;
		3'b111:	sel_o <= 4'b1000;
		endcase
		adr_o <= ea + 4'd6;
		dat_o <= {4{rfoDn[7:0]}};
	end
	else if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 4'h0;
		resL[7:0] <= dat_i >> {ea[1:0]+4'd2,3'b0};
		Rt <= {1'b0,DDD};
		rfwrL <= ~ir[7];
		ret();
	end


FSDATA2:
	fs_data2(mmmx,rrrx,sz_state,dsix);

// On a retry, wait some random number of cycle before retrying the bus
// operation.
`ifdef SUPPORT_RETRY
RETRY:
	begin
		cnt <= {lfsr_o[3:0] + 4'd8};
		goto (RETRY2);
	end
RETRY2:
	begin
		cnt <= cnt - 2'd1;
		if (cnt=='d0)
			goto (rstate);
	end
`endif

MOVERn2Rc:
	begin
		rrrr <= imm[15:12];
		goto (MOVERn2Rc2);
	end
MOVERn2Rc2:
	case(imm[11:0])
	12'h000:	begin sfc <= rfoRnn; ret(); end
	12'h001:	begin dfc <= rfoRnn; ret(); end
	12'h800:	begin usp <= rfoRnn; ret(); end
	12'h801:	begin vbr <= rfoRnn; ret(); end
	default:	tIllegal();
	endcase
MOVERc2Rn:
	case(imm[11:0])
	12'h000:	begin resL <= sfc; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	12'h001:	begin resL <= dfc; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	12'h800:	begin resL <= usp; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	12'h801:	begin resL <= vbr; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	12'hFE0:	begin resL <= coreno_i; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	12'hFF0:	begin resL <= tick; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	12'hFF8:	begin resL <= icnt; Rt <= imm[15:12]; rfwrL <= 1'b1; ret(); end
	default:	tIllegal();
	endcase
default:
	goto(RESET);
endcase

	// Bus error: abort current cycle and trap.
	if (cyc_o & err_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 4'h0;
		mac_cycle_type <= {state[6:0],sel_o,~we_o,1'b0,fc_o};
		bad_addr <= adr_o;
		is_bus_err <= 1'b1;
		dati_buf <= dat_i;
		dato_buf <= dat_o;
		goto (TRAP);
	end

`ifdef SUPPORT_RETRY
	// Retry: abort current cycle and retry.
	if (cyc_o & rty_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 4'h0;
		rstate <= state;
		goto (RETRY);
	end
`endif

end
	
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
task fs_data;
input [2:0] mmm;
input [2:0] rrr;
input state_t size_state;
input dsi;
begin
	ds <= dsi;
	case(mmm)
	3'd0:	begin
				if (dsi==D)
					d <= rfob;
				else
					s <= rfob;
				case(size_state)
				STORE_LWORD:
					begin
						Rt <= {mmm[0],rrr};
						rfwrL <= 1'b1;
					end
				STORE_WORD:
					begin
						Rt <= {mmm[0],rrr};
						rfwrW <= 1'b1;
					end
				STORE_BYTE:
					begin
						Rt <= {mmm[0],rrr};
						rfwrB <= 1'b1;
					end
				default:	;
				endcase
				goto(RETSTATE);
			end	// Dn
	3'd1:	begin
				if (dsi==D)
					d <= rfob;
				else
					s <= rfob;
				case(size_state)
				STORE_LWORD:
					begin
						Rt <= {mmm[0],rrr};
						rfwrL <= 1'b1;
					end
				STORE_WORD:
					begin
						Rt <= {mmm[0],rrr};
						rfwrW <= 1'b1;
					end
				STORE_BYTE:
					begin
						Rt <= {mmm[0],rrr};
						rfwrB <= 1'b1;
					end
				default:	;
				endcase
				goto(RETSTATE);
				end	// An
	3'd2:	begin	//(An)
				ea <= MMMRRR ? rfoAna : rfoAn;
				goto(size_state);
			end
	3'd3:	begin	// (An)+
				ea <= (MMMRRR ? rfoAna : rfoAn);
				Rt <= {1'b1,rrr};
				rfwrL <= 1'b1;
				case(size_state)
				LFETCH_BYTE,FETCH_BYTE,STORE_BYTE,USTORE_BYTE:	resL <= (MMMRRR ? rfoAna : rfoAn) + 4'd1;
				FETCH_WORD,STORE_WORD:	resL <= (MMMRRR ? rfoAna : rfoAn) + 4'd2;
				FETCH_LWORD,STORE_LWORD:	resL <= (MMMRRR ? rfoAna : rfoAn) + 4'd4;
				endcase
				goto(size_state);
			end
	3'd4:	begin	// -(An)
				Rt <= {1'b1,rrr};
				rfwrL <= 1'b1;
				case(size_state)
				FETCH_NOP_BYTE,LFETCH_BYTE,FETCH_BYTE,STORE_BYTE,USTORE_BYTE:	ea <= (MMMRRR ? rfoAna : rfoAn) - 4'd1;
				FETCH_NOP_WORD,FETCH_WORD,STORE_WORD:	ea <= (MMMRRR ? rfoAna : rfoAn) - 4'd2;
				FETCH_NOP_LWORD,FETCH_LWORD,STORE_LWORD:	ea <= (MMMRRR ? rfoAna : rfoAn) - 4'd4;
				endcase
				case(size_state)
				LFETCH_BYTE,FETCH_BYTE,STORE_BYTE,USTORE_BYTE:	resL <= (MMMRRR ? rfoAna : rfoAn) - 4'd1;
				FETCH_WORD,STORE_WORD:	resL <= (MMMRRR ? rfoAna : rfoAn) - 4'd2;
				FETCH_LWORD,STORE_LWORD:	resL <= (MMMRRR ? rfoAna : rfoAn) - 4'd4;
				endcase
				goto(size_state);
			end
	3'd5:	begin	// d16(An)
				ea <= (MMMRRR ? rfoAna : rfoAn);
				mmmx <= mmm;
				rrrx <= rrr;
				sz_state <= size_state;
				dsix <= dsi;
				goto (FSDATA2);
			end
	3'd6:	begin	// d8(An,Xn)
				ea <= (MMMRRR ? rfoAna : rfoAn);
				mmmx <= mmm;
				rrrx <= rrr;
				sz_state <= size_state;
				dsix <= dsi;
				goto (FSDATA2);
			end
	3'd7:	begin
				case(rrr)
				3'd0:	begin	// abs short
							ea <= 32'd0;
							mmmx <= mmm;
							rrrx <= rrr;
							sz_state <= size_state;
							dsix <= dsi;
							goto (FSDATA2);
						end
				3'd1:	begin	// abs long
							ea <= 32'd0;
							mmmx <= mmm;
							rrrx <= rrr;
							sz_state <= size_state;
							dsix <= dsi;
							goto (FSDATA2);
						end
				3'd2:	begin	// d16(PC)
							ea <= pc;
							mmmx <= mmm;
							rrrx <= rrr;
							sz_state <= size_state;
							dsix <= dsi;
							goto (FSDATA2);
						end
				3'd3:	begin	// d8(PC,Xn)
							ea <= pc;
							mmmx <= mmm;
							rrrx <= rrr;
							sz_state <= size_state;
							dsix <= dsi;
							goto (FSDATA2);
						end
				3'd4:	begin	// #i16
							goto((size_state==FETCH_LWORD||size_state==FETCH_NOP_LWORD)?FETCH_IMM32:FETCH_IMM16);
						end
				3'd5:	begin	// #i32
							state <= FETCH_IMM32;
							goto (FETCH_IMM32);
						end
				endcase
			end
		endcase
	end
endtask

task fs_data2;
input [2:0] mmm;
input [2:0] rrr;
input state_t size_state;
input dsi;
begin
	ds <= dsi;
	case(mmm)
	3'd5:	begin	// d16(An)
				ea <= (MMMRRR ? rfoAna : rfoAn);
				call(FETCH_D16,size_state);
			end
	3'd6:	begin	// d8(An,Xn)
				ea <= (MMMRRR ? rfoAna : rfoAn);
				call(FETCH_NDX,size_state);
			end
	3'd7:	begin
				case(rrr)
				3'd0:	begin	// abs short
							ea <= 32'd0;
							call(FETCH_D16,size_state);
						end
				3'd1:	begin	// abs long
							ea <= 32'd0;
							call(FETCH_D32,size_state);
						end
				3'd2:	begin	// d16(PC)
							ea <= pc;
							call(FETCH_D16,size_state);
						end
				3'd3:	begin	// d8(PC,Xn)
							ea <= pc;
							call(FETCH_NDX,size_state);
						end
				3'd4:	begin	// #i16
							goto((size_state==FETCH_LWORD||size_state==FETCH_NOP_LWORD)?FETCH_IMM32:FETCH_IMM16);
							end
				3'd5:	begin	// #i32
							state <= FETCH_IMM32;
							goto (FETCH_IMM32);
						end
				endcase
			end
		endcase
	end
endtask

task goto;
input state_t nst;
begin
	state <= nst;
end
endtask

task gosub;
input state_t tgt;
begin
	state_stk1 <= state;
	state_stk2 <= state_stk1;
	state_stk3 <= state_stk2;
	state_stk4 <= state_stk3;
	state <= tgt;
end
endtask

task call;
input state_t tgt;
input state_t retst;
begin
	state_stk1 <= retst;
	state_stk2 <= state_stk1;
	state_stk3 <= state_stk2;
	state_stk4 <= state_stk3;
	state <= tgt;
end
endtask

task push;
input state_t st;
begin
	state_stk1 <= st;
	state_stk2 <= state_stk1;
	state_stk3 <= state_stk2;
	state_stk4 <= state_stk3;
end
endtask

task tIllegal;
begin
	is_illegal <= 1'b1;
  vecno <= `ILLEGAL_VEC;
  goto (TRAP);
end
endtask

task tPrivilegeViolation;
begin
	is_priv <= 1'b1;
	vecno <= `PRIV_VEC;
	goto (TRAP);
end
endtask

task tBadBranchDisp;
begin
	isr <= srx;
	tf <= 1'b0;
	sf <= 1'b1;
	vecno <= `DISP_VEC;
	goto (TRAP3);
end
endtask

// MMMRRR needs to be set already when the STORE_IN_DEST state is entered.
// This state is entered after being popped off the state stack.
// If about to fetch the next instruction and trace is enabled, then take the
// trace trap.
task ret;
begin
	if (state_stk1==STORE_IN_DEST)
		MMMRRR <= 1'b1;
	if (state_stk1==IFETCH && tf) begin
		is_trace <= 1'b1;
		state <= TRAP;
	end
	else
		state <= state_stk1;
	state_stk1 <= state_stk2;
	state_stk2 <= state_stk3;
	state_stk3 <= state_stk4;
end
endtask

endmodule

