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
`define OPT_PERF    1'b1
`define BIG_ENDIAN	1'b1

//`define SUPPORT_MUL	1'b1
//`define SUPPORT_DIV	1'b1

`define TRUE        1'b1
`define FALSE       1'b0
`define HIGH        1'b1
`define LOW         1'b0
`define BIG_ENDIAN  1'b1

`define RESET_VECTOR	32'h00000400
`define CSR_CORENUM     32'hFFFFFFE0
`define CSR_TICK        32'hFFFFFFE4
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
`define IRQ_VEC         9'd024
// Vectors 32-46 for TRAPQ instruction
`define TRAP_VEC        9'd032
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

`define RTS		8'h4E

// 7700 LUTs / 80MHz
// slices
// 1600 FF's
// 2 MULTS
// 8 BRAMs

module rf68000(rst_i, rst_o, clk_i, nmi_i, ipl_i, lock_o, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, fc_o, adr_o, dat_i, dat_o);
parameter IFETCH = 8'd1;
parameter DECODE = 8'd2;
parameter FETCH_BYTE = 8'd20;
parameter FETCH_WORD = 8'd21;
parameter FETCH_LWORD = 8'd22;
parameter FETCH_LWORDa = 8'd23;
parameter STORE_BYTE = 8'd24;
parameter USTORE_BYTE = 8'd25;
parameter STORE_WORD = 8'd26;
parameter STORE_LWORD = 8'd27;
parameter STORE_LWORDa = 8'd28;
parameter LFETCH_BYTE = 8'd29;

parameter FETCH_BRDISP= 8'd30;
parameter FETCH_BRDISPa = 8'd31;
parameter FETCH_IMM16 = 8'd32;
parameter FETCH_IMM32 = 8'd33;
parameter FETCH_IMM32a = 8'd34;
parameter JSR1 = 8'd35;
parameter JSR2 = 8'd36;
parameter JSR3 = 8'd144;
parameter JMP1 = 8'd37;
parameter DBRA = 8'd38;

parameter ADDQ = 8'd40;
parameter ADDQ2 = 8'd41;
parameter ADDI = 8'd44;
parameter ADDI2 = 8'd45;
parameter ADDI3 = 8'd46;
parameter ADDI4 = 8'd47;
parameter ADD = 8'd48;
parameter ADD1 = 8'd49;

parameter STORE_IN_DEST = 8'd50;
parameter SHIFT = 8'd51;
parameter SHIFT1 = 8'd52;
parameter BIT = 8'd54;
parameter BIT1 = 8'd55;
parameter BIT2 = 8'd56;
parameter RTD1 = 8'd57;
parameter RTD2 = 8'd58;

parameter RTE1 = 8'd60;
parameter RTE2 = 8'd61;
parameter RTE3 = 8'd62;
parameter RTE4 = 8'd145;
parameter RTS1 = 8'd146;
parameter RTS2 = 8'd147;
parameter RTS3 = 8'd148;

parameter LINK = 8'd63;
parameter UNLNK	= 8'd64;
parameter UNLNK2 = 8'd65;
parameter JMP_VECTOR = 8'd67;
parameter JMP_VECTOR2 = 8'd68;
parameter JMP_VECTOR3 = 8'd143;
parameter LINK1 = 8'd69;
parameter LINK2 = 8'd66;

parameter NEG = 8'd67;
parameter NEGX = 8'd68;
parameter NEGX1 = 8'd69;
parameter NOT = 8'd70;
parameter TAS = 8'd71;
parameter LEA = 8'd72;
parameter EXG1 = 8'd73;
parameter CMP = 8'd75;
parameter CMP1 = 8'd76;
parameter AND = 8'd80;
parameter AND1 = 8'd81;
parameter EOR = 8'd82;
parameter ANDI_CCR = 8'd83;
parameter ANDI_CCR2 = 8'd84;
parameter ANDI_SR = 8'd85;
parameter ANDI_SR2 = 8'd86;
parameter EORI_CCR = 8'd90;
parameter EORI_CCR2 = 8'd91;
parameter EORI_SR = 8'd92;
parameter EORI_SR2 = 8'd93;
parameter ORI_CCR = 8'd94;
parameter ORI_CCR2 = 8'd95;
parameter ORI_SR = 8'd96;
parameter ORI_SR2 = 8'd97;
parameter FETCH_NOP = 8'd99;
parameter FETCH_IMM8 = 8'd100;
parameter FETCH_D32 = 8'd102;
parameter FETCH_D32a = 8'd103;
parameter FETCH_D32b = 8'd104;
parameter FETCH_D16 = 8'd105;
parameter FETCH_D16a = 8'd106;
parameter FETCH_NDX = 8'd107;
parameter FETCH_NDXa = 8'd108;
parameter MOVE2CCR = 8'd110;
parameter MOVE2SR = 8'd112;
parameter ILLEGAL = 8'd114;
parameter ILLEGAL2 = 8'd115;
parameter ILLEGAL3 = 8'd116;
parameter ILLEGAL4 = 8'd140;
parameter TRAP = 8'd117;
parameter TRAP2 = 8'd118;
parameter TRAP3 = 8'd119;
parameter TRAP4 = 8'd141;
parameter TRAPV = 8'd120;
parameter TRAPV2 = 8'd121;
parameter TRAPV3 = 8'd122;
parameter TRAPV4 = 8'd142;
parameter TST = 8'd123;
parameter MUL = 8'd124;
parameter MUL1 = 8'd125;
parameter STOP = 8'd126;
parameter STOP1 = 8'd127;
parameter RESET = 8'd128;
parameter RESET2 = 8'd129;
parameter RESET3 = 8'd130;
parameter RESET4 = 8'd131;
parameter RESET5 = 8'd139;
parameter PEA1 = 8'd132;
parameter PEA2 = 8'd133;
parameter ABCD = 8'd134;
parameter ABCD1 = 8'd135;
parameter SBCD = 8'd136;
parameter SBCD1 = 8'd137;
parameter OR = 8'd138;

parameter INT = 8'd151;
parameter INT2 = 8'd152;
parameter INT3 = 8'd153;
parameter INT4 = 8'd154;

parameter MOVEM_Xn2D = 8'd160;
parameter MOVEM_Xn2D2 = 8'd161;
parameter MOVEM_Xn2D3 = 8'd162;
parameter MOVEM_Xn2D4 = 8'd163;
parameter MOVEM_s2Xn = 8'd164;
parameter MOVEM_s2Xn2 = 8'd165;
parameter MOVEM_s2Xn3 = 8'd166;

parameter TASK1 = 8'd171;
parameter TASK2 = 8'd172;
parameter TASK3 = 8'd173;
parameter TASK4 = 8'd174;

parameter LDT1 = 8'd175;
parameter LDT2 = 8'd176;
parameter LDT3 = 8'd177;
parameter SDT1 = 8'd178;
parameter SDT2 = 8'd179;

parameter SUB = 8'd180;
parameter SUB1 = 8'd181;
 
parameter S = 1'b0;
parameter D = 1'b1;

input rst_i;
output reg rst_o;
input clk_i;
input nmi_i;
input [2:0] ipl_i;
output lock_o;
reg lock_o;
output cyc_o;
reg cyc_o;
output stb_o;
reg stb_o;
input ack_i;
input err_i;
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
reg [7:0] state;
reg [7:0] state2;
reg [7:0] ret_state;
reg [8:0] tr, otr;
reg fork_task;
reg [31:0] d0;
reg [31:0] d1;
reg [31:0] d2;
reg [31:0] d3;
reg [31:0] d4;
reg [31:0] d5;
reg [31:0] d6;
reg [31:0] d7;
reg [31:0] a0;
reg [31:0] a1;
reg [31:0] a2;
reg [31:0] a3;
reg [31:0] a4;
reg [31:0] a5;
reg [31:0] a6;
reg [31:0] sp;
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
wire [15:0] sr = {tf,1'b0,sf,2'b00,im,3'b000,xf,nf,zf,vf,cf};
reg [31:0] pc;
reg [31:0] ssp,usp;
reg [31:0] disp;
reg [31:0] s,d,imm;
reg wl;
reg ds;
reg [5:0] cnt;				// shift count
reg [31:0] ea;				// effective address
reg [31:0] vector;
reg [8:0] vecno;
reg [3:0] Rt;
wire [1:0] sz = ir[7:6];
reg [2:0] mmm;
reg [2:0] rrr;
reg [3:0] rrrr;
wire [2:0] MMM = ir[8:6];
wire [2:0] RRR = ir[11:9];
wire [2:0] QQQ = ir[11:9];
wire [2:0] DDD = ir[11:9];
wire [2:0] AAA = ir[11:9];
wire Anabit;
wire [31:0] sp_dec = sp - 32'd2;
reg [31:0] rfoAn;
always @*
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
always @*
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
always @*
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
always @*
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
always @*
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
always @*
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
wire [7:0] bcdaddo,bcdsubo,bcdnego;
wire bcdaddoc,bcdsuboc,bcdnegoc;
reg prev_nmi;
reg pe_nmi;
reg is_nmi;
reg is_irq;
reg [4:0] rst_cnt;
// CSR's
reg [31:0] tick;

reg task_mem_wr;

function [31:0] rbo;
input [31:0] w;
rbo = {w[7:0],w[15:8],w[23:16],w[31:24]};
endfunction

task_mem utm1
(
  .clk(clk_i),
  .wr(task_mem_wr),
  .wa(tr),
  .d0i(d0i),
  .d1i(d1i),
  .d2i(d2i),
  .d3i(d3i),
  .d4i(d4i),
  .d5i(d5i),
  .d6i(d6i),
  .d7i(d7i),
  .a0i(a0i),
  .a1i(a1i),
  .a2i(a2i),
  .a3i(a3i),
  .a4i(a4i),
  .a5i(a5i),
  .a6i(a6i),
  .spi(spi),
  .flagsi(sri),
  .pci(pci),
  .ra(tr),
  .d0o(d0o),
  .d1o(d1o),
  .d2o(d2o),
  .d3o(d3o),
  .d4o(d4o),
  .d5o(d5o),
  .d6o(d6o),
  .d7o(d7o),
  .a0o(a0o),
  .a1o(a1o),
  .a2o(a2o),
  .a3o(a3o),
  .a4o(a4o),
  .a5o(a5o),
  .a6o(a6o),
  .spo(spo),
  .flagso(flagso),
  .pco(pco)
);

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
`DBRA:	takb = 1'b0;
`DBSR:	takb = 1'b0;
`DBHI:	takb = !(!cf & !zf);
`DBLS:	takb = !(cf | zf);
`DBHS:	takb = cf;
`DBLO:	takb = !cf;
`DBNE:	takb = zf;
`DBEQ:	takb = !zf;
`DBVC:	takb = vf;
`DBVS:	takb = !vf;
`DBPL:	takb = nf;
`DBMI:	takb = !nf;
`DBGE:	takb = !((nf & vf)|(!nf & !vf));
`DBLT:	takb = !((nf & !vf)|(!nf & vf));
`DBGT:	takb = !((nf & vf & !zf)|(!nf & !vf & zf));
`DBLE:	takb = !(zf | (nf & !vf) | (!nf & vf));
default:	takb = 1'b1;
endcase

`ifdef BIG_ENDIAN
wire [15:0] iri = pc[1] ? {dat_i[23:16],dat_i[31:24]} : {dat_i[15:8],dat_i[7:0]};
`else
wire [15:0] iri = pc[1] ? dat_i[31:16] : dat_i[15:0];
`endif

always @(posedge clk_i)
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
	state <= RESET;
	prev_nmi <= 1'b0;
	pe_nmi <= 1'b0;
    task_mem_wr <= `FALSE;
    tick <= 32'd0;
    rst_cnt <= 5'd10;
    rst_o <= 1'b1;
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
task_mem_wr <= `FALSE;

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
	if (!cyc_o) begin
		is_nmi <= 1'b0;
		is_irq <= 1'b0;
		if (pe_nmi) begin
			pe_nmi <= 1'b0;
			is_nmi <= 1'b1;
			state <= TRAP;
		end
		else if (ipl_i > im) begin
			is_irq <= 1'b1;
			state <= TRAP;
		end
		else begin
			fc_o <= {sf,2'b10};
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			sel_o <= pc[1] ? 4'b1100 : 4'b0011;
			adr_o <= pc;
		end
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		ir <= iri;
		pc <= pc + 32'd2;
		mmm <= iri[5:3];
		rrr <= iri[2:0];
		rrrr <= iri[3:0];
		state <= DECODE;
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
			8'h7C:	state <= ORI_SR;
			default:	state <= ADDI;	// ORI
			endcase
		4'h2:
			case(ir[7:0])
			8'h3C:	state <= ANDI_CCR;
			8'h7C:	state <= ANDI_SR;
			default:	state <= ADDI;	// ANDI
			endcase
		4'h4:	state <= ADDI;	// SUBI
		4'h6:	state <= ADDI;	// ADDI
		4'hA:
			case(ir[7:0])
			8'h3C:	state <= EORI_CCR;
			8'h7C:	state <= EORI_SR;
			default:	state <= ADDI;	// EORI
			endcase
		4'hC:	state <= ADDI;	// CMPI
		default:	state <= BIT;
		endcase
//-----------------------------------------------------------------------------
// MOVE.B
//-----------------------------------------------------------------------------
	4'h1:	fs_data(mmm,rrr,FETCH_BYTE,STORE_IN_DEST,S);
//-----------------------------------------------------------------------------
// MOVE.L
//-----------------------------------------------------------------------------
    4'h2:    fs_data(mmm,rrr,FETCH_LWORD,STORE_IN_DEST,S);
//-----------------------------------------------------------------------------
// MOVE.W
//-----------------------------------------------------------------------------
	4'h3:	fs_data(mmm,rrr,FETCH_WORD,STORE_IN_DEST,S);
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
	4'h4:
		casez(ir[11:8])
		4'h0:	case(sz)
				2'b00:	fs_data(mmm,rrr,FETCH_BYTE,NEGX,D);
				2'b01:	fs_data(mmm,rrr,FETCH_WORD,NEGX,D);
				2'b10:	fs_data(mmm,rrr,FETCH_LWORD,NEGX,D);
				endcase
		4'bxxx1:
			if (sz==2'b11)	// LEA
				fs_data(mmm,rrr,FETCH_NOP,LEA,S);
				
		4'h2:	begin		// 42xx	CLR
					cf <= 1'b0;
					vf <= 1'b0;
					zf <= 1'b1;
					nf <= 1'b0;
					resL <= 32'd0;
					resW <= 16'd0;
					resB <= 8'd0;
					case(sz)
					2'b00:	fs_data(mmm,rrr,STORE_BYTE,IFETCH,D);
					2'b01:	fs_data(mmm,rrr,STORE_WORD,IFETCH,D);
					2'b10:	fs_data(mmm,rrr,STORE_LWORD,IFETCH,D);
					endcase
				end
		4'h4:
				begin
					casez(ir[7:4])
					4'b00??:	fs_data(mmm,rrr,FETCH_BYTE,NEG,D);
					4'b01??:	fs_data(mmm,rrr,FETCH_WORD,NEG,D);
					4'b10??:	fs_data(mmm,rrr,FETCH_LWORD,NEG,D);
					4'b11??:	// MOVE <src>,ccr
						begin
							fs_data(mmm,rrr,FETCH_WORD,MOVE2CCR,S);
						end
					endcase
				end
		4'h6:
				begin
					casez(ir[7:4])
					4'b11??:	// MOVE <src>,sr
						begin
							fs_data(mmm,rrr,FETCH_WORD,MOVE2SR,S);
						end
					default:
						case(sz)
						2'b00:	fs_data(mmm,rrr,FETCH_BYTE,NOT,D);
						2'b01:	fs_data(mmm,rrr,FETCH_WORD,NOT,D);
						2'b10:	fs_data(mmm,rrr,FETCH_LWORD,NOT,D);
						default:	;
						endcase
					endcase
				end
		4'h8:
				begin
					casez(ir[7:4])
					4'b00??:		// NBCD
						fs_data(mmm,rrr,FETCH_BYTE,ABCD1,D);
					4'h4:	begin	// 484x		SWAP
								cf <= 1'b0;
								vf <= 1'b0;
								zf <= rfoRnn==32'd0;
								nf <= rfoRnn[15];
								resL <= {rfoRnn[15:0],rfoRnn[31:16]};
								Rt <= {1'b0,rrr};
								rfwrL <= 1'b1;
							end
					4'b01??:		// PEA
						state <= PEA1;
					4'h8:	if (!ir[3]) begin	// 488x		EXT.W
								cf <= 1'b0;
								vf <= 1'b0;
								nf <= rfoRnn[7];
								zf <= rfoRnn[7:0]==8'h00;
								rfwrW <= 1'b1;
								Rt <= ir[3:0];
								resW <= {rfoRnn[31:16],{8{rfoRnn[7]}},rfoRnn[7:0]};
							end
							else begin
								state <= FETCH_IMM16;
								ret_state <= MOVEM_Xn2D;
							end
					4'hC:	if (!ir[3]) begin	// 48Cx		EXT.L
								cf <= 1'b0;
								vf <= 1'b0;
								nf <= rfoRnn[15];
								zf <= rfoRnn[15:0]==16'h0000;
								rfwrL <= 1'b1;
								Rt <= ir[3:0];
								resL <= {{16{rfoRnn[15]}},rfoRnn[15:0]};
							end
							else begin
								state <= FETCH_IMM16;
								ret_state <= MOVEM_Xn2D;
							end
					endcase
				end
		4'hA:
				case(ir[7:4])
				4'hF:
					case(ir[3:0])
					4'hC:	state <= ILLEGAL;	// 4AFC	Illegal
					endcase	
				default:		// 4Axx	TST
					case(sz)
					2'b00:	fs_data(mmm,rrr,FETCH_BYTE,TST,D);
					2'b01:	fs_data(mmm,rrr,FETCH_WORD,TST,D);
					2'b10:	fs_data(mmm,rrr,FETCH_LWORD,TST,D);
					2'b11:	fs_data(mmm,rrr,LFETCH_BYTE,TAS,D);		// TAS
					endcase
				endcase
		4'hC:	begin
				state <= FETCH_IMM16;
				ret_state <= MOVEM_s2Xn;
				end
		4'hE:
				casez(ir[7:4])
				4'h4:	state <= TRAP;							// TRAP
				4'h5:
						begin
							if (ir[3]) begin		// UNLK
								sp <= rfoAn;
								state <= UNLNK;
							end
							else begin
								state <= LINK;
							end
						end
				4'h6:	// MOVE usp
					begin
						if (ir[3]) begin
							state <= IFETCH;
							Rt <= {1'b1,rrr};
							rfwrL <= 1'b1;
							resL <= usp;
						end
						else begin
							state <= IFETCH;
							usp <= rfoAn;
						end
					end
				4'h7:
					case(ir[3:0])
					4'h0:   begin state <= IFETCH; rst_o <= 1'b1; rst_cnt <= 5'd10; end  // 4E70 RESET
					4'h1:	state <= IFETCH;					// 4E71	NOP
					4'h2:	state <= STOP;						// 4E72 STOP
					4'h3:	state <= RTE1;						// 4E73 RTE
					4'h5:	state <= RTS1;						// 4E75 RTS
					4'h6:	state <= vf ? TRAPV : IFETCH;		// 4E76 TRAPV
					endcase
				4'b10??:	fs_data(mmm,rrr,FETCH_LWORD,JSR1,D);	// JSR
				4'b11??:	fs_data(mmm,rrr,FETCH_LWORD,JMP1,D);	// JMP
				endcase
		endcase
//***		4'hF:	state <= RTD1;	// 4Fxx = rtd

//-----------------------------------------------------------------------------
// ADDQ / SUBQ / DBRA / Scc
//-----------------------------------------------------------------------------
	4'h5:
		begin
			casez(ir[7:4])
			4'b1100:					// DBRA
				if (takb) begin
					state <= FETCH_IMM16;
					ret_state <= DBRA;
				end
				else begin
					pc <= pc + 32'd2;	// skip over displacement
					state <= IFETCH;
				end
			4'b11??:					// Scc
				begin
					resL <= {32{!takb}};
					resW <= {16{!takb}};
					resB <= {8{!takb}};
					if (mmm==3'b000) begin
						rfwrB <= 1'b1;
						Rt <= {1'b0,rrr};
						state <= IFETCH;
					end
					else begin
						fs_data(mmm,rrr,STORE_BYTE,IFETCH,D);
					end
				end
			default:
				begin
					case(QQQ)
					3'd0:	imm <= 32'd8;
					default:	imm <= {29'd0,QQQ};
					endcase
					case(sz)
					2'b00:	fs_data(mmm,rrr,FETCH_BYTE,ADDQ,D);
					2'b01:	fs_data(mmm,rrr,FETCH_WORD,ADDQ,D);
					2'b10:	fs_data(mmm,rrr,FETCH_LWORD,ADDQ,D);
					endcase
				end
			endcase
		end
		
//-----------------------------------------------------------------------------
// Branches
//-----------------------------------------------------------------------------
	4'h6:
		if (takb) begin
			if (ir[7:0]==8'h00)
				state <= FETCH_BRDISP;
			else begin
				pc <= pc + {{23{ir[7]}},ir[7:0],1'b0};
				state <= IFETCH;
			end
		end
		else begin
			if (ir[7:0]==8'h00)		// skip over long displacement
				pc <= pc + 48'd2;
			state <= IFETCH;
		end

//-----------------------------------------------------------------------------
// MOVEQ
//-----------------------------------------------------------------------------
	4'h7:
		if (ir[8]==1'b0) begin	// MOVEQ
			vf <= 1'b0;
			cf <= 1'b0;
			nf <= ir[7];
			zf <= ir[7:0]==8'h00;
			rfwrL <= 1'b1;
			Rt <= {1'b0,ir[11:9]};
			resL <= {{24{ir[7]}},ir[7:0]};
			state <= IFETCH;
		end
//-----------------------------------------------------------------------------
// OR / SBCD
//-----------------------------------------------------------------------------
	4'h8:
		begin
			casez(ir)
`ifdef SUPPORT_DIV			
			16'b1000_????_11??_????:	// DIVU / DIVS
				;
`endif				
			16'b1000_???1_0000_????:	// SBCD
				if (ir[3])
					fs_data(3'b100,rrr,FETCH_BYTE,SBCD,S);
				else begin
					s <= rfoDnn;
					d <= rfoDn;
					state <= SBCD;
				end
			default:	state <= ADD;	// OR
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
        2'b00:    fs_data(mmm,rrr,FETCH_BYTE,SUB,ir[8]?D:S);
        2'b01:    fs_data(mmm,rrr,FETCH_WORD,SUB,ir[8]?D:S);
        2'b10:    fs_data(mmm,rrr,FETCH_LWORD,SUB,ir[8]?D:S);
        2'b11:
          begin
          d <= rfoAna;
          if (ir[8]) fs_data(mmm,rrr,FETCH_LWORD,SUB,S);
          else fs_data(mmm,rrr,FETCH_WORD,SUB,S);
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
          state <= ILLEGAL;
      end
//-----------------------------------------------------------------------------
// CMP / EOR
//-----------------------------------------------------------------------------
	4'hB:
		begin
			if (ir[8]) begin	// EOR
				case(sz)
				2'b00:	fs_data(mmm,rrr,FETCH_BYTE,EOR,D);
				2'b01:	fs_data(mmm,rrr,FETCH_WORD,EOR,D);
				2'b10:	fs_data(mmm,rrr,FETCH_LWORD,EOR,D);
				endcase
			end
			else	// CMP
				case(sz)
				2'b00:	fs_data(mmm,rrr,FETCH_BYTE,CMP,S);
				2'b01:	fs_data(mmm,rrr,FETCH_WORD,CMP,S);
				2'b10:	fs_data(mmm,rrr,FETCH_LWORD,CMP,S);
				endcase
		end
//-----------------------------------------------------------------------------
// AND / EXG / MULU / MULS
//-----------------------------------------------------------------------------
	4'hC:
		begin
			casez(ir)
			16'b1100_???1_0000_????:	// ABCD
				if (ir[3])
					fs_data(3'b100,rrr,FETCH_BYTE,ABCD,S);
				else begin
					s <= rfoDnn;
					d <= rfoDn;
					state <= ABCD;
				end
			16'b1100_????_11??_????:	// MULS / MULU
				fs_data(mmm,rrr,FETCH_WORD,MUL,S);
			16'b1100_???1_0100_0???:
			begin
				Rt <= {1'b0,DDD};
				rfwrL <= 1'b1;
				resL <= rfoRnn;
				s <= rfoDn;
				state <= EXG1;
			end
			16'b1100_???1_0100_1???:
			begin
				Rt <= {1'b1,AAA};
				rfwrL <= 1'b1;
				resL <= rfoRnn;
				s <= rfoAna;
				state <= EXG1;
			end
			16'b1100_???1_1000_1???:
			begin
				Rt <= {1'b0,DDD};
				rfwrL <= 1'b1;
				resL <= rfoRnn;
				s <= rfoDn;
				state <= EXG1;
			end
			default:
				case(sz)
				2'b00:	fs_data(mmm,rrr,FETCH_BYTE,AND,ir[8]?D:S);
				2'b01:	fs_data(mmm,rrr,FETCH_WORD,AND,ir[8]?D:S);
				2'b10:	fs_data(mmm,rrr,FETCH_LWORD,AND,ir[8]?D:S);
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
			2'b00:	fs_data(mmm,rrr,FETCH_BYTE,ADD,ir[8]?D:S);
			2'b01:	fs_data(mmm,rrr,FETCH_WORD,ADD,ir[8]?D:S);
			2'b10:	fs_data(mmm,rrr,FETCH_LWORD,ADD,ir[8]?D:S);
			2'b11:
				begin
				d <= rfoAna;
				if (ir[8]) fs_data(mmm,rrr,FETCH_LWORD,ADD,S);
				else fs_data(mmm,rrr,FETCH_WORD,ADD,S);
				end
			endcase
		end
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
	4'hE:
		begin
			if (sz==2'b11)
				fs_data(mmm,rrr,FETCH_WORD,SHIFT1,D);
			else begin
				state <= SHIFT;
				if (ir[5])
					cnt <= {QQQ==3'b0,QQQ};
				else
					cnt <= rfoDn[4:0];
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
ABCD:
	begin
		if (ir[3])
			fs_data(3'b100,RRR,FETCH_BYTE,ABCD1,D);
		else begin
			state <= IFETCH;
			rfwrB <= 1'b1;
			Rt <= {1'b0,RRR};
			resB <= bcdaddo;
			cf <= bcdaddoc;
			xf <= bcdaddoc;
			nf <= bcdaddo[7];
		end
	end
ABCD1:
	begin
		state <= STORE_BYTE;
		ret_state <= IFETCH;
		resB <= bcdaddo;
		cf <= bcdaddoc;
		xf <= bcdaddoc;
		nf <= bcdaddo[7];
	end

SBCD:
	begin
		if (ir[3])
			fs_data(3'b100,RRR,FETCH_BYTE,SBCD1,D);
		else begin
			state <= IFETCH;
			rfwrB <= 1'b1;
			Rt <= {1'b0,RRR};
			resB <= bcdsubo;
			cf <= bcdsuboc;
			xf <= bcdsuboc;
			nf <= bcdsubo[7];
		end
	end
SBCD1:
	begin
		state <= STORE_BYTE;
		ret_state <= IFETCH;
		resB <= bcdsubo;
		cf <= bcdsuboc;
		xf <= bcdsuboc;
		nf <= bcdsubo[7];
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
STOP:
	begin
		state <= FETCH_IMM16;
		ret_state <= STOP1;
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
		if (ipl_i!=3'b111)
			state <= IFETCH;
	end

//-----------------------------------------------------------------------------
// MUL
//-----------------------------------------------------------------------------
MUL:
	begin
		state <= MUL1;
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
	end
MUL1:
	begin
		state <= IFETCH;
		cf <= 1'b0;
		vf <= 1'b0;
		nf <= resL[31];
		zf <= resL[31:0]==32'd0;
	end

//-----------------------------------------------------------------------------
// NOT
//-----------------------------------------------------------------------------
NOT:
	begin
		resB <= ~d[7:0];
		resW <= ~d[15:0];
		resL <= ~d;
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
			state <= IFETCH;
		end
		else if (mmm==3'b001)
			state <= IFETCH;
		else begin
			case(sz)
			2'b00:	begin state <= STORE_BYTE; ret_state <= IFETCH; end
			2'b01:	begin state <= STORE_WORD; ret_state <= IFETCH; end
			2'b10:	begin state <= STORE_LWORD; ret_state <= IFETCH; end
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
		state <= NEGX1;
	end
NEGX:
	begin
		resL <= -d - xf;
		resW <= -d[15:0] - xf;
		resB <= -d[7:0] - xf;
		state <= NEGX1;
	end
NEGX1:
	begin
		case(sz)
		2'b00:	begin cf <= resB[8]; nf <= resB[7]; vf <= resB[8]!=resB[7]; zf <= resB[7:0]==8'h00; xf <= resB[8]; end
		2'b01:	begin cf <= resW[16]; nf <= resW[15]; vf <= resW[16]!=resW[15]; zf <= resW[15:0]==16'h00; xf <= resW[16]; end
		2'b10:	begin cf <= resL[32]; nf <= resL[31]; vf <= resL[32]!=resL[31]; zf <= resL[31:0]==32'h00; xf <= resL[32]; end
		endcase
		if (mmm==3'b000) begin
			Rt <= {1'b0,rrr};
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			default:	;
			endcase
			state <= IFETCH;
		end
		else if (mmm==3'b001)
			state <= IFETCH;
		else
			case(sz)
			2'b00:	begin state <= STORE_BYTE; ret_state <= IFETCH; end
			2'b01:	begin state <= STORE_WORD; ret_state <= IFETCH; end
			2'b10:	begin state <= STORE_LWORD; ret_state <= IFETCH; end
			endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
TST:
	begin
		state <= IFETCH;
		cf <= 1'b0;
		vf <= 1'b0;
		case(sz)
		2'b00:	begin zf <= d[7:0]==8'h00; nf <= d[7]; end
		2'b01:	begin zf <= d[15:0]==16'h00; nf <= d[15]; end
		2'b10:	begin zf <= d[31:0]==32'h00; nf <= d[31]; end
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
		state <= USTORE_BYTE;
		ret_state <= IFETCH;
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
		state <= FETCH_IMM16;
		ret_state <= LINK2;
	end
LINK2:
	begin
		sp <= sp + imm;
		state <= IFETCH;		
	end

//-----------------------------------------------------------------------------
// LEA
//-----------------------------------------------------------------------------
LEA:
	begin
		Rt <= {1'b1,AAA};
		rfwrL <= 1'b1;
		resL <= ea;
		state <= IFETCH;
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
		state <= IFETCH;
	end

//-----------------------------------------------------------------------------
// DBRA
//-----------------------------------------------------------------------------
DBRA:
	begin
		resL <= rfoDnn - 32'd1;
		Rt <= {1'b0,rrr};
		rfwrL <= 1'b1;
		if (rfoDnn!=0)
			pc <= pc + {imm,1'b0};
		state <= IFETCH;
	end

//-----------------------------------------------------------------------------
// EXG
//-----------------------------------------------------------------------------
EXG1:
	begin
		state <= IFETCH;
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
		endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
STORE_IN_DEST:
	begin
		state <= IFETCH;	// In event of bad ir
		resL <= s;
		resW <= s[15:0];
		resB <= s[7:0];
		case(ir[15:12])
		4'd1:	begin zf <= s[ 7:0]== 8'h00; nf <= s[7]; end
		4'd2:	begin zf <= s[15:0]==16'h00; nf <= s[15]; end
		4'd3:	begin zf <= s[31:0]==32'd0;  nf <= s[31]; end
		endcase
		cf <= 1'b0;
		vf <= 1'b0;
		case(ir[15:12])
		4'd1:	fs_data(MMM,RRR,STORE_BYTE,IFETCH,D);
		4'd2:	fs_data(MMM,RRR,STORE_WORD,IFETCH,D);
		4'd3:	fs_data(MMM,RRR,STORE_LWORD,IFETCH,D);
		endcase
	end


//-----------------------------------------------------------------------------
// Compares
//-----------------------------------------------------------------------------
CMP:
	begin
		state <= CMP1;
		case(sz)
		2'b00:	resB <= rfoDn[ 7:0] - s[ 7:0];
		2'b01:	resW <= rfoDn[15:0] - s[15:0];
		2'b10:	resL <= rfoDn[31:0] - s[31:0];
		2'b11:
			begin
				if (ir[8])
					resL <= rfoAna - s;
				else
					resW <= rfoAna[15:0] - s[15:0];
			end
		endcase
	end
CMP1:
	begin
		state <= IFETCH;
		case(sz)
		2'b00:	begin zf <= resB[7:0]== 8'd0; nf <= resB[ 7]; cf <= resB[ 8]; vf <= resB[ 8]!=resB[ 7]; end
		2'b01:	begin zf <= resW[15:0]==16'd0; nf <= resW[15]; cf <= resW[16]; vf <= resW[16]!=resW[15]; end
		2'b10:	begin zf <= resL[31:0]==32'd0; nf <= resL[31]; cf <= resL[32]; vf <= resL[32]!=resL[31]; end
		2'b11:
			if (ir[8])
				begin zf <= resL[31:0]==32'd0; nf <= resL[31]; cf <= resL[32]; vf <= resL[32]!=resL[31]; end
			else
				begin zf <= resW[15:0]==16'd0; nf <= resW[15]; cf <= resW[16]; vf <= resW[16]!=resW[15]; end
		endcase
	end

//-----------------------------------------------------------------------------
// Shifts
// ToDo: ROXL,ROXR
//-----------------------------------------------------------------------------
SHIFT1:
	begin
		resB <= d[7:0];
		resW <= d[15:0];
		resL <= d[31:0];
		state <= SHIFT;
	end
SHIFT:
	if (cnt!=5'd0) begin
		cnt <= cnt - 5'd1;
		case({ir[8],ir[4:3]})
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
		Rt <= {1'b0,rrr};
		case(sz)
		2'b00:	begin zf <= resB[7:0]== 8'h00; nf <= resB[ 7]; end
		2'b01:	begin zf <= resW[15:0]==16'h00; nf <= resW[15]; end
		2'b10:	begin zf <= resL[31:0]==32'h00; nf <= resL[31]; end
		2'b11:	begin zf <= resW[15:0]==16'h00; nf <= resW[15]; end
		endcase
		case(sz)
		2'b00:	begin rfwrB <= 1'b1; state <= IFETCH; end
		2'b01:	begin rfwrW <= 1'b1; state <= IFETCH; end
		2'b10:	begin rfwrL <= 1'b1; state <= IFETCH; end
		2'b11:	fs_data(mmm,rrr,STORE_WORD,IFETCH,D);	/// ?????
		endcase
	end
	
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
ADD:
	begin
		if (sz==2'b11) begin
			Rt <= {1'b1,AAA};
			if (ir[8]) begin
				state <= IFETCH;
				rfwrL <= 1'b1;
				resL <= rfoAna + s;
			end
			else begin
				resL <= rfoAna[15:0] + s[15:0];
				state <= ADD1;	//*** sign extend result
			end
		end
		else if (ir[8]) begin
			resB <= d[7:0] + rfoDn[7:0];
			resW <= d[15:0] + rfoDn[15:0];
			resL <= d + rfoDn;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				state <= ADD1;
			end
			else begin
				case(sz)
				2'b00:	begin state <= STORE_BYTE; ret_state <= ADD1; end
				2'b01:	begin state <= STORE_WORD; ret_state <= ADD1; end
				2'b10:	begin state <= STORE_LWORD; ret_state <= ADD1; end
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] + s[7:0];
			resW <= rfoDn[15:0] + s[15:0];
			resL <= rfoDn + s;
			state <= ADD1;
		end
	end
ADD1:
	begin
		state <= IFETCH;
		case(sz)
		2'b00:
			begin
				rfwrB <= 1'b1;
				cf <= resB[8];
				nf <= resB[7];
				zf <= resB[7:0]==8'h00;
				vf <= resB[8]!=resB[7];
				xf <= resB[8];
			end
		2'b01:
			begin
				rfwrW <= 1'b1;
				cf <= resW[16];
				nf <= resW[15];
				zf <= resW[15:0]==16'h0000;
				vf <= resW[16]!=resW[15];
				xf <= resW[16];
			end
		2'b10:
			begin
				rfwrL <= 1'b1;
				cf <= resL[32];
				nf <= resL[31];
				zf <= resL[31:0]==32'h00000000;
				vf <= resL[32]!=resL[31];
				xf <= resL[32];
			end
		2'b11:
			begin
				state <= IFETCH;
				rfwrL <= 1'b1;
				Rt <= {1'b1,AAA};
				resL[31:16] <= resL[15];
			end
		endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
SUB:
	begin
		if (sz==2'b11) begin
			Rt <= {1'b1,AAA};
			if (ir[8]) begin
				state <= IFETCH;
				rfwrL <= 1'b1;
				resL <= rfoAna - s;
			end
			else begin
				resL <= rfoAna[15:0] - s[15:0];
				state <= SUB1;	//*** sign extend result
			end
		end
		else if (ir[8]) begin
			resB <= d[7:0] - rfoDn[7:0];
			resW <= d[15:0] - rfoDn[15:0];
			resL <= d - rfoDn;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				state <= SUB1;
			end
			else begin
				case(sz)
				2'b00:	begin state <= STORE_BYTE; ret_state <= SUB1; end
				2'b01:	begin state <= STORE_WORD; ret_state <= SUB1; end
				2'b10:	begin state <= STORE_LWORD; ret_state <= SUB1; end
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] - s[7:0];
			resW <= rfoDn[15:0] - s[15:0];
			resL <= rfoDn - s;
			state <= SUB1;
		end
	end
SUB1:
	begin
		state <= IFETCH;
		case(sz)
		2'b00:
			begin
				rfwrB <= 1'b1;
				cf <= resB[8];
				nf <= resB[7];
				zf <= resB[7:0]==8'h00;
				vf <= resB[8]!=resB[7];
				xf <= resB[8];
			end
		2'b01:
			begin
				rfwrW <= 1'b1;
				cf <= resW[16];
				nf <= resW[15];
				zf <= resW[15:0]==16'h0000;
				vf <= resW[16]!=resW[15];
				xf <= resW[16];
			end
		2'b10:
			begin
				rfwrL <= 1'b1;
				cf <= resL[32];
				nf <= resL[31];
				zf <= resL[31:0]==32'h00000000;
				vf <= resL[32]!=resL[31];
				xf <= resL[32];
			end
		2'b11:
			begin
				state <= IFETCH;
				rfwrL <= 1'b1;
				Rt <= {1'b1,AAA};
				resL[31:16] <= resL[15];
			end
		endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
AND:
	begin
		if (ir[8]) begin
			resB <= d[7:0] & rfoDn[7:0];
			resW <= d[15:0] & rfoDn[15:0];
			resL <= d & rfoDn;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				state <= AND1;
			end
			else begin
				case(sz)
				2'b00:	begin state <= STORE_BYTE; ret_state <= AND1; end
				2'b01:	begin state <= STORE_WORD; ret_state <= AND1; end
				2'b10:	begin state <= STORE_LWORD; ret_state <= AND1; end
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] & s[7:0];
			resW <= rfoDn[15:0] & s[15:0];
			resL <= rfoDn & s;
			state <= AND1;
		end
	end
AND1:
	begin
		state <= IFETCH;
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

//-----------------------------------------------------------------------------
// OR
//-----------------------------------------------------------------------------
OR:
	begin
		if (ir[8]) begin
			resB <= d[7:0] | rfoDn[7:0];
			resW <= d[15:0] | rfoDn[15:0];
			resL <= d | rfoDn;
			if (mmm==3'd0 || mmm==3'd1) begin
				Rt <= {mmm[0],rrr};
				state <= AND1;
			end
			else begin
				case(sz)
				2'b00:	begin state <= STORE_BYTE; ret_state <= AND1; end
				2'b01:	begin state <= STORE_WORD; ret_state <= AND1; end
				2'b10:	begin state <= STORE_LWORD; ret_state <= AND1; end
				endcase
			end
		end
		else begin
			Rt <= {1'b0,DDD};
			resB <= rfoDn[7:0] | s[7:0];
			resW <= rfoDn[15:0] | s[15:0];
			resL <= rfoDn | s;
			state <= AND1;
		end
	end

//-----------------------------------------------------------------------------
// EOR
//-----------------------------------------------------------------------------
EOR:
	begin
		resB <= d[7:0] ^ rfoDn[7:0];
		resW <= d[15:0] ^ rfoDn[15:0];
		resL <= d ^ rfoDn;
		if (mmm[2:1]==2'd0) begin
			Rt <= {mmm[0],rrr};
			state <= AND1;
		end
		else begin
			case(sz)
			2'b00:	begin state <= STORE_BYTE; ret_state <= AND1; end
			2'b01:	begin state <= STORE_WORD; ret_state <= AND1; end
			2'b10:	begin state <= STORE_LWORD; ret_state <= AND1; end
			endcase
		end
	end

//-----------------------------------------------------------------------------
// ADDQ / SUBQ
//-----------------------------------------------------------------------------
ADDQ:
	begin
		if (ir[8]) begin
			resL <= d - imm;
			resB <= d[7:0] - imm[7:0];
			resW <= d[15:0] - imm[15:0];
		end
		else begin
			resL <= d + imm;
			resB <= d[7:0] + imm[7:0];
			resW <= d[15:0] + imm[15:0];
		end
		if (mmm==3'd0 || mmm==3'd1) begin
			state <= ADDQ2;
			Rt <= {mmm[0],rrr};
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			endcase
		end
		else
			case(sz)
			2'b00:	begin state <= STORE_BYTE; ret_state <= ADDQ2; end
			2'b01:	begin state <= STORE_WORD; ret_state <= ADDQ2; end
			2'b10:	begin state <= STORE_LWORD; ret_state <= ADDQ2; end
			default:	;	// Scc / DBRA
			endcase
	end
ADDQ2:
	begin
		state <= IFETCH;
		case(sz)
		2'b00:
			begin
				 xf <= resB[8];
				 cf <= resB[8];
				 vf <= resB[8]!=resB[7];
				 zf <= resB[7:0]==8'd0;
				 nf <= resB[7];
			end
		2'b01:
			begin
				 xf <= resW[16];
				 cf <= resW[16];
				 vf <= resW[16]!=resW[15];
				 zf <= resW[15:0]==16'd0;
				 nf <= resW[15];
			end
		2'b10:
			begin
				 xf <= resL[32];
				 cf <= resL[32];
				 vf <= resL[32]!=resL[31];
				 zf <= resL[31:0]==32'd0;
				 nf <= resL[31];
			end
		endcase
	end

//-----------------------------------------------------------------------------
// ADDI / SUBI / CMPI / ANDI / ORI / EORI
//-----------------------------------------------------------------------------
ADDI:
	case(sz)
	2'b00:	begin state <= FETCH_IMM8; ret_state <= ADDI2; end
	2'b01:	begin state <= FETCH_IMM16; ret_state <= ADDI2; end
	2'b10:	begin state <= FETCH_IMM32; ret_state <= ADDI2; end
	endcase
ADDI2:
	begin
	case(sz)
	2'b00:	fs_data(mmm,rrr,FETCH_BYTE,ADDI3,D);
	2'b01:	fs_data(mmm,rrr,FETCH_WORD,ADDI3,D);
	2'b10:	fs_data(mmm,rrr,FETCH_LWORD,ADDI3,D);
	endcase
	end
ADDI3:
	begin
		case(ir[11:8])
		4'h0:	resL <= d | imm;	// ORI
		4'h2:	resL <= d & imm;	// ANDI
		4'h4:	resL <= d - imm;	// SUBI
		4'h6:	resL <= d + imm;	// ADDI
		4'hA:	resL <= d ^ imm;	// EORI
		4'hC:	resL <= d - imm;	// CMPI
		endcase
		case(ir[11:8])
		4'h0:	resW <= d[15:0] | imm[15:0];	// ORI
		4'h2:	resW <= d[15:0] & imm[15:0];	// ANDI
		4'h4:	resW <= d[15:0] - imm[15:0];	// SUBI
		4'h6:	resW <= d[15:0] + imm[15:0];	// ADDI
		4'hA:	resW <= d[15:0] ^ imm[15:0];	// EORI
		4'hC:	resW <= d[15:0] - imm[15:0];	// CMPI
		endcase
		case(ir[11:8])
		4'h0:	resB <= d[7:0] | imm[7:0];	// ORI
		4'h2:	resB <= d[7:0] & imm[7:0];	// ANDI
		4'h4:	resB <= d[7:0] - imm[7:0];	// SUBI
		4'h6:	resB <= d[7:0] + imm[7:0];	// ADDI
		4'hA:	resB <= d[7:0] ^ imm[7:0];	// EORI
		4'hC:	resB <= d[7:0] - imm[7:0];	// CMPI
		endcase
		if (mmm==3'b000 || mmm==3'b001) begin
			case(sz)
			2'b00:	rfwrB <= 1'b1;
			2'b01:	rfwrW <= 1'b1;
			2'b10:	rfwrL <= 1'b1;
			endcase
			Rt <= {mmm[0],rrr};
			state <= ADDI4;
		end
		else
			case(sz)
			2'b00:	begin state <= STORE_BYTE; ret_state <= ADDI4; end
			2'b01:	begin state <= STORE_WORD; ret_state <= ADDI4; end
			2'b10:	begin state <= STORE_LWORD; ret_state <= ADDI4; end
			endcase
	end
ADDI4:
	begin
		state <= IFETCH;
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
		4'h4,4'h6:	// SUBI,ADDI
			begin
				case(sz)
				2'b00:
					begin
						xf <= resB[8];
						cf <= resB[8];
						vf <= resB[8]!=resB[7];
						zf <= resB[7:0]==8'd0;
						nf <= resB[7];
					end
				2'b01:
					begin
						xf <= resW[16];
						cf <= resW[16];
						vf <= resW[16]!=resW[15];
						zf <= resW[15:0]==16'd0;
						nf <= resW[15];
					end
				2'b10:
					begin
						xf <= resL[32];
						cf <= resL[32];
						vf <= resL[32]!=resL[31];
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
						vf <= resB[8]!=resB[7];
						zf <= resB[7:0]==8'd0;
						nf <= resB[7];
					end
				2'b01:
					begin
						cf <= resW[16];
						vf <= resW[16]!=resW[15];
						zf <= resW[15:0]==16'd0;
						nf <= resW[15];
					end
				2'b10:
					begin
						cf <= resL[32];
						vf <= resL[32]!=resL[31];
						zf <= resL[31:0]==32'd0;
						nf <= resL[31];
					end
				endcase
			end
		endcase
	end

//-----------------------------------------------------------------------------
// ANDI_CCR / ANDI_SR / EORI_CCR / EORI_SR / ORI_CCR / ORI_SR
//-----------------------------------------------------------------------------
//
ANDI_CCR:
	begin state <= FETCH_IMM8; ret_state <= ANDI_CCR2; end
ANDI_CCR2:
	begin
		cf <= cf & imm[0];
		vf <= vf & imm[1];
		zf <= zf & imm[2];
		nf <= nf & imm[3];
		xf <= xf & imm[4];
		state <= IFETCH;
	end
ANDI_SR:
	begin state <= FETCH_IMM16; ret_state <= ANDI_SR2; end
ANDI_SR2:
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
		state <= IFETCH;
	end
EORI_CCR:
	begin state <= FETCH_IMM8; ret_state <= EORI_CCR2; end
EORI_CCR2:
	begin
		cf <= cf ^ imm[0];
		vf <= vf ^ imm[1];
		zf <= zf ^ imm[2];
		nf <= nf ^ imm[3];
		xf <= xf ^ imm[4];
		state <= IFETCH;
	end
EORI_SR:
	begin state <= FETCH_IMM16; ret_state <= EORI_SR2; end
EORI_SR2:
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
		state <= IFETCH;
	end
ORI_CCR:
	begin state <= FETCH_IMM8; ret_state <= ORI_CCR2; end
ORI_CCR2:
	begin
		cf <= cf | imm[0];
		vf <= vf | imm[1];
		zf <= zf | imm[2];
		nf <= nf | imm[3];
		xf <= xf | imm[4];
		state <= IFETCH;
	end
ORI_SR:
	begin state <= FETCH_IMM16; ret_state <= ORI_SR2; end
ORI_SR2:
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
		state <= IFETCH;
	end

//-----------------------------------------------------------------------------
// Bit manipulation
//-----------------------------------------------------------------------------
BIT:
	begin
		if (ir[11:8]==4'h8) begin
			state <= FETCH_IMM8;
			ret_state <= BIT1;
		end
		else begin
			imm <= rfoDn;
			state <= BIT1;
		end
	end
BIT1:
	begin
		if (mmm==3'b000) begin	// Dn
			state <= BIT2;
			d <= rfob;
		end
		else
			fs_data(mmm,rrr,FETCH_BYTE,BIT2,D);
	end
BIT2:
	begin
		case(sz)
		2'b00:	begin zf <= ~d[imm[4:0]]; state <= IFETCH; end
		2'b01:	begin
					zf <= ~d[imm[4:0]];
					resL <= d ^  (32'd1 << imm[4:0]);
					resB <= d ^  (32'd1 << imm[4:0]);
				end
		2'b10:	begin
					zf <= ~d[imm[4:0]];
					resL <= d & ~(32'd1 << imm[4:0]);
					resB <= d & ~(32'd1 << imm[4:0]);
				end
		2'b11:	begin
					zf <= ~d[imm[4:0]];
					resL <= d |  (32'd1 << imm[4:0]);
					resB <= d |  (32'd1 << imm[4:0]);
				end
		endcase
		if (mmm==3'b000 && sz!=2'b00) begin
			rfwrL <= 1'b1;
			Rt <= {1'b0,rrr};
			state <= IFETCH;
		end
		else begin
			state <= STORE_BYTE;
			ret_state <= IFETCH;
		end
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
FETCH_NOP:
	state <= ret_state;

FETCH_BRDISP:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b0011;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		disp <= {{16{iri[15]}},iri};
		state <= FETCH_BRDISPa;
	end
FETCH_BRDISPa:
	begin
		pc <= pc + {disp[30:0],1'b0};
		state <= IFETCH;
	end

// Fetch 8 bit immediate
//
FETCH_IMM8:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b0011;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		imm <= {{24{iri[7]}},iri[7:0]};
		pc <= pc + 32'd2;
		state <= ret_state;
	end

// Fetch 16 bit immediate
//
FETCH_IMM16:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b0011;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		imm <= {{16{iri[15]}},iri};
		pc <= pc + 32'd2;
		state <= ret_state;
	end

// Fetch 32 bit immediate
//
FETCH_IMM32:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 4'b00;
		if (pc[1]) begin
`ifdef BIG_ENDIAN
			imm[31:16] <= {dat_i[23:16],dat_i[31:24]};
`else			
      imm[15:0] <= dat_i[31:16];
`endif      
		  pc <= pc + 32'd2;
		  state <= FETCH_IMM32a;
		end
		else begin
`ifdef BIG_ENDIAN
			imm <= rbo(dat_i);
`else
      imm <= dat_i;
`endif      
		  cyc_o <= 1'b0;
		  pc <= pc + 32'd4;
		  state <= ret_state;
		end
	end
FETCH_IMM32a:
	if (!stb_o) begin
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b0011;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
`ifdef BIG_ENDIAN
		imm[15:0] <= {dat_i[7:0],dat_i[15:8]};
`else
		imm[31:16] <= dat_i[15:0];
`endif
		pc <= pc + 32'd2;
		state <= ret_state;
	end

// Fetch 32 bit displacement
//
FETCH_D32:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b1111;
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
		sel_o <= 4'b0011;
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
		state <= state2;
	end

// Fetch 16 bit displacement
//
FETCH_D16:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b0011;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		disp <= {{16{iri[15]}},iri};
		pc <= pc + 32'd2;
		state <= FETCH_D16a;
	end
FETCH_D16a:
	begin
		ea <= ea + disp;
		state <= state2;
	end

// Fetch index word
//
FETCH_NDX:
	if (!cyc_o) begin
		fc_o <= {sf,2'b10};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= pc[1] ? 4'b1100 : 4'b0011;
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
		state <= state2;
	end

FETCH_BYTE:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		adr_o <= ea;
		sel_o <= 4'b0001 << ea[1:0];
	end
	else if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		sel_o <= 4'b0000;
		if (ds==D) begin
	    case(sel_o)
	    4'b0001:  d <= {{24{dat_i[7]}},dat_i[7:0]};
	    4'b0010:  d <= {{24{dat_i[15]}},dat_i[15:8]};
	    4'b0100:  d <= {{24{dat_i[23]}},dat_i[23:16]};
	    4'b1000:  d <= {{24{dat_i[31]}},dat_i[31:24]};
	    default:  ;
	    endcase
		end
		else begin
	    case(sel_o)
      4'b0001:  s <= {{24{dat_i[7]}},dat_i[7:0]};
      4'b0010:  s <= {{24{dat_i[15]}},dat_i[15:8]};
      4'b0100:  s <= {{24{dat_i[23]}},dat_i[23:16]};
      4'b1000:  s <= {{24{dat_i[31]}},dat_i[31:24]};
      default:    ;
      endcase
		end
		state <= ret_state;
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
		sel_o <= 4'b0001 << ea[1:0];
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		if (ds==D) begin
      case(sel_o)
      4'b0001:  d <= {{24{dat_i[7]}},dat_i[7:0]};
      4'b0010:  d <= {{24{dat_i[15]}},dat_i[15:8]};
      4'b0100:  d <= {{24{dat_i[23]}},dat_i[23:16]};
      4'b1000:  d <= {{24{dat_i[31]}},dat_i[31:24]};
      default:    ;
      endcase
    end
    else begin
      case(sel_o)
      4'b0001:  s <= {{24{dat_i[7]}},dat_i[7:0]};
      4'b0010:  s <= {{24{dat_i[15]}},dat_i[15:8]};
      4'b0100:  s <= {{24{dat_i[23]}},dat_i[23:16]};
      4'b1000:  s <= {{24{dat_i[31]}},dat_i[31:24]};
      default:    ;
      endcase
    end
		state <= ret_state;
	end

FETCH_WORD:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		adr_o <= ea;
		sel_o <= ea[1] ? 4'b1100 : 4'b0011;
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
		state <= ret_state;
	end

FETCH_LWORD:
    case(ea)
    `CSR_TICK:
      begin
        if (ds==D)
          d <= tick;
        else
          s <= tick;
        state <= ret_state;
      end
    `CSR_TASK:
      begin
        if (ds==D)
          d <= tr;
        else
          s <= tr;
        state <= ret_state;
      end
    default:
  if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		adr_o <= ea;
		sel_o <= ea[1] ? 4'b1100 : 4'b1111;
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
        state <= ret_state;
	    end
	end
	endcase
FETCH_LWORDa:
	if (!stb_o) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		adr_o <= adr_o + 32'd2;
		sel_o <= 4'b0011;
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
		state <= ret_state;
	end


STORE_BYTE:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		sel_o <= 4'b0001 << ea[1:0];
		dat_o <= {4{resB[7:0]}};
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 2'b00;
		state <= ret_state;
	end

// Store byte and unlock
//
USTORE_BYTE:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		sel_o <= 4'b0001 << ea[1:0];
		dat_o <= {4{resB[7:0]}};
	end
	else if (ack_i) begin
		lock_o <= 1'b0;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 2'b00;
		state <= ret_state;
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
		dat_o <= {2{resW[7:0],resW[15:8]}};
`else		
		dat_o <= {2{resW[15:0]}};
`endif		
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 2'b00;
		state <= ret_state;
	end
STORE_LWORD:
    case(ea)
    `CSR_TASK:
      begin
        set_regs();
        fork_task <= resW[15];
        task_mem_wr <= 1'b1;
        state <= TASK1;
      end
    default:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		sel_o <= ea[1] ? 4'b1100 : 4'b1111;
`ifdef BIG_ENDIAN
		dat_o <= ea[1] ? {resL[23:16],resL[31:24],resL[7:0],resL[15:8]} : rbo(resL);
`else		
		dat_o <= ea[1] ? {resL[15:0],resL[31:16]} : resL;
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
      state <= ret_state;
		end
	end
	endcase
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
		state <= ret_state;
	end

//----------------------------------------------------
// Move to CCR
//----------------------------------------------------
MOVE2CCR:
	begin
		cf <= s[0];
		vf <= s[1];
		zf <= s[2];
		nf <= s[3];
		xf <= s[4];
		state <= IFETCH;
	end	

MOVE2SR:
	begin
		cf <= s[0];
		vf <= s[1];
		zf <= s[2];
		nf <= s[3];
		xf <= s[4];
		im[0] <= s[8];
		im[1] <= s[9];
		im[2] <= s[10];
		sf <= s[13];
		tf <= s[15];
		state <= IFETCH;
	end	

//----------------------------------------------------
//----------------------------------------------------
RESET:
  begin
    tr <= `RESET_TASK;
    pc <= `RESET_VECTOR;
		state <= IFETCH;
	end

//----------------------------------------------------
//----------------------------------------------------
ILLEGAL:
  begin
    set_regs();
    task_mem_wr <= `TRUE;
    vecno <= `ILLEGAL_VEC;
    state <= TRAP3;
  end


//----------------------------------------------------
//----------------------------------------------------
TRAP:
  begin
    set_regs();
    task_mem_wr <= `TRUE;
    state <= TRAP3;
    /*
    if (is_nmi)
        vecno <= `NMI_VEC;
    else
    */
    if (is_irq) begin
      vecno <= `IRQ_VEC + ipl_i;
      im <= ipl_i;
    end
    else begin
      if (ir[3:0]==4'hF)
        state <= TRAP2;
      else
        vecno <= `TRAP_VEC + ir[3:0];
    end
  end
TRAP2:
  if (!cyc_o) begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    sel_o <= pc[1] ? 4'b1100: 4'b0011;
    adr_o <= pc;
  end
  else if (ack_i) begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    sel_o <= 4'b0;
    pc <= pc + 32'd2;
    vecno <= iri[8:0];
    state <= TRAP3;
  end
TRAP3:
  if (!cyc_o) begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    sel_o <= vecno[0] ? 4'b1100 : 4'b0011;
    adr_o <= {vecno,1'b0};
  end
  else if (ack_i) begin
    otr <= tr;
    tr <= vecno[0] ? dat_i[24:16] : dat_i[8:0];
    state <= TASK2;        
  end

//----------------------------------------------------
//----------------------------------------------------
TRAPV:
  begin
    set_regs();
    task_mem_wr <= `TRUE;
    vecno <= `TRAPV_VEC;
    state <= TRAP3;
  end
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
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= sp;
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 2'b00;
		rfwrL <= 1'b1;
		Rt <= {1'b1,rrr};
`ifdef BIG_ENDIAN
		resL <= rbo(dat_i);
`else
		resL <= dat_i;
`endif		
		sp <= sp + 32'd4;
		state <= IFETCH;
	end

//----------------------------------------------------
//----------------------------------------------------
JMP1:
	begin
		pc <= d;
		state <= IFETCH;
	end
JSR1:
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
		state <= IFETCH;
	end

//----------------------------------------------------
// Return from exception
//----------------------------------------------------
//
RTE1:
	if (!cyc_o) begin
		fc_o <= {1'b1,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= sp;
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		sel_o <= 4'b0000;
		sp <= sp + 32'd4;
`ifdef BIG_ENDIAN
		cf <= dat_i[8];
		vf <= dat_i[9];
		zf <= dat_i[10];
		nf <= dat_i[11];
		xf <= dat_i[12];
		im[0] <= dat_i[0];
		im[1] <= dat_i[1];
		im[2] <= dat_i[2];
		sf <= dat_i[5];
		tf <= dat_i[7];
`else		
		cf <= dat_i[0];
		vf <= dat_i[1];
		zf <= dat_i[2];
		nf <= dat_i[3];
		xf <= dat_i[4];
		im[0] <= dat_i[8];
		im[1] <= dat_i[9];
		im[2] <= dat_i[10];
		sf <= dat_i[13];
		tf <= dat_i[15];
`endif		
		state <= RTE2;
	end
RTE2:
	if (!stb_o) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= sp;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 2'b00;
`ifdef BIG_ENDIAN
		pc <= rbo(dat_i);
`else		
		pc <= dat_i;
`endif		
		sp <= sp + 32'd4;
		state <= IFETCH;
	end

	
//----------------------------------------------------
// Return from subroutine.
//----------------------------------------------------
//
RTS1:
	if (!cyc_o) begin
		fc_o <= {sf,2'b01};
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= sp;
	end
	else if (ack_i) begin
    cyc_o <= `LOW;
		stb_o <= 1'b0;
		sel_o <= 4'b00;
`ifdef BIG_ENDIAN
		pc <= rbo(dat_i);
`else		
		pc <= dat_i;
`endif		
		sp <= sp + 32'd4;
		state <= IFETCH;
	end

//----------------------------------------------------
MOVEM_Xn2D:
`ifdef OPT_PERF
	if (imm[15:0]!=16'h0000)
		fs_data(mmm,rrr,FETCH_NOP,MOVEM_Xn2D2,D);
	else
		fs_data(mmm,rrr,FETCH_NOP,IFETCH,D);
`else
	fs_data(mmm,rrr,FETCH_NOP,MOVEM_Xn2D2,D);
`endif
MOVEM_Xn2D2:
	begin
		if (imm[15:0]!=16'h0000)
			state <= MOVEM_Xn2D3;
		else
			state <= IFETCH;
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
MOVEM_Xn2D3:
	begin
		resL <= rfoRnn;
		resW <= rfoRnn[15:0];
		state <= ir[10] ? STORE_LWORD : STORE_WORD;
		ret_state <= MOVEM_Xn2D4;
	end
MOVEM_Xn2D4:
	begin
		ea <= ea + (ir[10] ? 32'd4 : 32'd2);
		if (imm[15:0]!=16'h0000)
			state <= MOVEM_Xn2D3;
		else
			state <= IFETCH;
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
	
//----------------------------------------------------
MOVEM_s2Xn:
`ifdef OPT_PERF
	if (imm[15:0]!=16'h0000)
		fs_data(mmm,rrr,FETCH_NOP,MOVEM_s2Xn2,S);
	else
		fs_data(mmm,rrr,FETCH_NOP,IFETCH,S);
`else
	fs_data(mmm,rrr,FETCH_NOP,MOVEM_s2Xn2,S);
`endif
MOVEM_s2Xn2:
	if (imm[15:0] != 16'h0000) begin
		state <= ir[10] ? FETCH_LWORD : FETCH_WORD;
		ret_state <= MOVEM_s2Xn3;
	end
	else
		state <= IFETCH;
MOVEM_s2Xn3:
	begin
		ea <= ea + (ir[10] ? 32'd4 : 32'd2);
		state <= MOVEM_s2Xn2;
		rfwrL <=  ir[10];
		rfwrW <= !ir[10];
		resL <= d;
		resW <= d[15:0];
		if (imm[0]) begin
			Rt <= 4'd0;
			imm[0] <= 1'b0;
		end
		else if (imm[1]) begin
			Rt <= 4'd1;
			imm[1] <= 1'b0;
		end
		else if (imm[2]) begin
			Rt <= 4'd2;
			imm[2] <= 1'b0;
		end
		else if (imm[3]) begin
			Rt <= 4'd3;
			imm[3] <= 1'b0;
		end
		else if (imm[4]) begin
			Rt <= 4'd4;
			imm[4] <= 1'b0;
		end
		else if (imm[5]) begin
			Rt <= 4'd5;
			imm[5] <= 1'b0;
		end
		else if (imm[6]) begin
			Rt <= 4'd6;
			imm[6] <= 1'b0;
		end
		else if (imm[7]) begin
			Rt <= 4'd7;
			imm[7] <= 1'b0;
		end
		else if (imm[8]) begin
			Rt <= 4'd8;
			imm[8] <= 1'b0;
		end
		else if (imm[9]) begin
			Rt <= 4'd9;
			imm[9] <= 1'b0;
		end
		else if (imm[10]) begin
			Rt <= 4'd10;
			imm[10] <= 1'b0;
		end
		else if (imm[11]) begin
			Rt <= 4'd11;
			imm[11] <= 1'b0;
		end
		else if (imm[12]) begin
			Rt <= 4'd12;
			imm[12] <= 1'b0;
		end
		else if (imm[13]) begin
			Rt <= 4'd13;
			imm[13] <= 1'b0;
		end
		else if (imm[14]) begin
			Rt <= 4'd14;
			imm[14] <= 1'b0;
		end
		else if (imm[15]) begin
			Rt <= 4'd15;
			imm[15] <= 1'b0;
		end
	end
//----------------------------------------------------
TASK1:
  begin
    otr <= tr;
    tr <= resW[7:0];
    state <= fork_task ? TASK4: TASK2;
  end
TASK2:
  state <= TASK3;
TASK3:
  begin
    d0 <= d0o;
    d1 <= d1o;
    d2 <= d2o;
    d3 <= d3o;
    d4 <= d4o;
    d5 <= d5o;
    d6 <= d6o;
    d7 <= d7o;
    a0 <= a0o;
    a1 <= a1o;
    a2 <= a2o;
    a3 <= a3o;
    a4 <= a4o;
    a5 <= a5o;
    a6 <= a6o;
    sp <= spo;
    cf <= flagso[0];
    vf <= flagso[1];
    zf <= flagso[2];
    nf <= flagso[3];
    xf <= flagso[4];
    im <= flagso[10:8];
    sf <= flagso[11];
    tf <= flagso[13];
    pc <= pco;
    state <= TASK4;
  end
TASK4:
  if (!cyc_o) begin
		fc_o <= {3'b101};
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    we_o <= `HIGH;
    sel_o <= 4'b1111;
    adr_o <= sp - 32'd4;
`ifdef BIG_ENDIAN
		dat_o <= rbo(otr);
`else    
    dat_o <= otr;
`endif    
  end
  else if (ack_i) begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    we_o <= `LOW;
    sel_o <= 4'b00;
    sp <= sp - 32'd4;
    state <= IFETCH;
  end
//----------------------------------------------------
LDT1:
  begin
    cnt <= 6'd0;
    otr <= tr;
    fs_data(mmm,rrr,FETCH_NOP,LDT2,S);
  end
LDT2:
    if (!stb_o) begin
      fc_o <= 3'b101;
      cyc_o <= `HIGH;
      stb_o <= `HIGH;
      we_o <= `LOW;
      sel_o <= 4'b1111;
      adr_o <= ea;
    end
    else if (ack_i) begin
      stb_o <= `LOW;
      cnt <= cnt + 6'd1;
      ea <= ea + 32'd4;
      if (cnt >= 6'd17) begin
        cyc_o <= `LOW;
        sel_o <= 4'b00;
        task_mem_wr <= `TRUE;
        tr <= d0[8:0];
        state <= LDT3;
      end
`ifdef BIG_ENDIAN
      case(cnt)
      6'd0:   d0i <= rbo(dat_i);
      6'd1:   d1i <= rbo(dat_i);
      6'd2:   d2i <= rbo(dat_i);
      6'd3:   d3i <= rbo(dat_i);
      6'd4:   d4i <= rbo(dat_i);
      6'd5:   d5i <= rbo(dat_i);
      6'd6:   d6i <= rbo(dat_i);
      6'd7:   d7i <= rbo(dat_i);
      6'd8:   a0i <= rbo(dat_i);
      6'd9:   a1i <= rbo(dat_i);
      6'd10:  a2i <= rbo(dat_i);
      6'd11:  a3i <= rbo(dat_i);
      6'd12:  a4i <= rbo(dat_i);
      6'd13:  a5i <= rbo(dat_i);
      6'd14:  a6i <= rbo(dat_i);
      6'd15:  spi <= rbo(dat_i);
      6'd16:  flagsi <= rbo(dat_i);
      6'd17:  pci <= rbo(dat_i);
      default:	;
      endcase
`else      
      case(cnt)
      6'd0:   d0i <= dat_i;
      6'd1:   d1i <= dat_i;
      6'd2:   d2i <= dat_i;
      6'd3:   d3i <= dat_i;
      6'd4:   d4i <= dat_i;
      6'd5:   d5i <= dat_i;
      6'd6:   d6i <= dat_i;
      6'd7:   d7i <= dat_i;
      6'd8:   a0i <= dat_i;
      6'd9:   a1i <= dat_i;
      6'd10:  a2i <= dat_i;
      6'd11:  a3i <= dat_i;
      6'd12:  a4i <= dat_i;
      6'd13:  a5i <= dat_i;
      6'd14:  a6i <= dat_i;
      6'd15:  spi <= dat_i;
      6'd16:  flagsi <= dat_i;
      6'd17:  pci <= dat_i;
      default:	;
      endcase
`endif      
    end
LDT3:
  begin
    tr <= otr;
    state <= IFETCH;
  end
//----------------------------------------------------
SDT1:
  begin
    cnt <= 6'd0;
    otr <= tr;
    tr <= d0;
    fs_data(mmm,rrr,FETCH_NOP,SDT2,D);
  end
SDT2:
  if (!stb_o) begin
    fc_o <= 3'b101;
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    we_o <= `HIGH;
    sel_o <= 4'b1111;
    adr_o <= ea;
`ifdef BIG_ENDIAN
    case(cnt)
    6'd0:   dat_o <= rbo(d0o);
    6'd1:   dat_o <= rbo(d1o);
    6'd2:   dat_o <= rbo(d2o);
    6'd3:   dat_o <= rbo(d3o);
    6'd4:   dat_o <= rbo(d4o);
    6'd5:   dat_o <= rbo(d5o);
    6'd6:   dat_o <= rbo(d6o);
    6'd7:   dat_o <= rbo(d7o);
    6'd8:   dat_o <= rbo(a0o);
    6'd9:   dat_o <= rbo(a1o);
    6'd10:  dat_o <= rbo(a2o);
    6'd11:  dat_o <= rbo(a3o);
    6'd12:  dat_o <= rbo(a4o);
    6'd13:  dat_o <= rbo(a5o);
    6'd14:  dat_o <= rbo(a6o);
    6'd15:  dat_o <= rbo(spo);
    6'd16:  dat_o <= rbo(flagso);
    6'd17:  dat_o <= rbo(pco);
    default:	;
    endcase
`else      
    case(cnt)
    6'd0:   dat_o <= d0o;
    6'd1:   dat_o <= d1o;
    6'd2:   dat_o <= d2o;
    6'd3:   dat_o <= d3o;
    6'd4:   dat_o <= d4o;
    6'd5:   dat_o <= d5o;
    6'd6:   dat_o <= d6o;
    6'd7:   dat_o <= d7o;
    6'd8:   dat_o <= a0o;
    6'd9:   dat_o <= a1o;
    6'd10:  dat_o <= a2o;
    6'd11:  dat_o <= a3o;
    6'd12:  dat_o <= a4o;
    6'd13:  dat_o <= a5o;
    6'd14:  dat_o <= a6o;
    6'd15:  dat_o <= spo;
    6'd16:  dat_o <= flagso;
    6'd17:  dat_o <= pco;
    default:	;
    endcase
`endif      
  end
  else if (ack_i) begin
    stb_o <= `LOW;
    we_o <= `LOW;
    cnt <= cnt + 6'd1;
    ea <= ea + 32'd4;
    if (cnt >= 6'd17) begin
      cyc_o <= `LOW;
      sel_o <= 4'b00;
      tr <= otr;
      state <= IFETCH;
    end
  end
endcase
end
	
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
task fs_data;
input [2:0] mmm;
input [2:0] rrr;
input [7:0] size_state;
input [7:0] return_state;
input dsi;
begin
	ds <= dsi;
	case(mmm)
	3'd0:	begin
				if (dsi==D)
					d <= rfob;
				else
					s <= rfob;
				state <= return_state;
			end	// Dn
	3'd1:	begin
				if (dsi==D)
					d <= rfob;
				else
					s <= rfob;
				state <= return_state; end	// An
	3'd2:	begin	//(An)
				ea <= rfoAn;
				state <= size_state;
				ret_state <= return_state;
			end
	3'd3:	begin	// (An)+
				ea <= rfoAn;
				Rt <= {1'b1,rrr};
				rfwrL <= 1'b1;
				case(size_state)
				LFETCH_BYTE,FETCH_BYTE,STORE_BYTE,USTORE_BYTE:	resL <= rfoAn + 44'd1;
				FETCH_WORD,STORE_WORD:	resL <= rfoAn + 44'd2;
				FETCH_LWORD,STORE_LWORD:	resL <= rfoAn + 44'd4;
				endcase
				state <= size_state;
				ret_state <= return_state;
			end
	3'd4:	begin	// -(An)
				Rt <= {1'b1,rrr};
				rfwrL <= 1'b1;
				case(size_state)
				LFETCH_BYTE,FETCH_BYTE,STORE_BYTE,USTORE_BYTE:	ea <= rfoAn - 32'd1;
				FETCH_WORD,STORE_WORD:	ea <= rfoAn - 32'd2;
				FETCH_LWORD,STORE_LWORD:	ea <= rfoAn - 32'd4;
				endcase
				case(size_state)
				LFETCH_BYTE,FETCH_BYTE,STORE_BYTE,USTORE_BYTE:	resL <= rfoAn - 32'd1;
				FETCH_WORD,STORE_WORD:	resL <= rfoAn - 32'd2;
				FETCH_LWORD,STORE_LWORD:	resL <= rfoAn - 32'd4;
				endcase
				state <= size_state;
				ret_state <= return_state;
			end
	3'd5:	begin	// d16(An)
				ea <= rfoAn;
				state <= FETCH_D16;
				state2 <= size_state;
				ret_state <= return_state;
			end
	3'd6:	begin	// d8(An,Xn)
				ea <= rfoAn;
				state <= FETCH_NDX;
				state2 <= size_state;
				ret_state <= return_state;
			end
	3'd7:	begin
				case(rrr)
				3'd0:	begin	// abs short
							ea <= 32'd0;
							state <= FETCH_D16;
							state2 <= size_state;
							ret_state <= return_state;
						end
				3'd1:	begin	// abs long
							ea <= 32'd0;
							state <= FETCH_D32;
							state2 <= size_state;
							ret_state <= return_state;
						end
				3'd2:	begin	// d16(PC)
							ea <= pc;
							state <= FETCH_D16;
							state2 <= size_state;
							ret_state <= return_state;
						end
				3'd3:	begin	// d8(PC,Xn)
							ea <= pc;
							state <= FETCH_NDX;
							state2 <= size_state;
							ret_state <= return_state;
						end
				3'd4:	begin	// #i16
							state <= FETCH_IMM16;
							ret_state <= return_state;
						end
				3'd5:	begin	// #i32
							state <= FETCH_IMM32;
							ret_state <= return_state;
						end
				endcase
			end
		endcase
	end
endtask

task set_regs;
begin
  d0i <= d0;
  d1i <= d1;
  d2i <= d2;
  d3i <= d3;
  d4i <= d4;
  d5i <= d5;
  d6i <= d6;
  d7i <= d7;
  a0i <= a0;
  a1i <= a1;
  a2i <= a2;
  a3i <= a3;
  a4i <= a4;
  a5i <= a5;
  a6i <= a6;
  spi <= sp;
  flagsi <= sr;
  pci <= pc;
end
endtask

endmodule

module task_mem(clk, wr, wa,
  d0i,d1i,d2i,d3i,d4i,d5i,d6i,d7i,
  a0i,a1i,a2i,a3i,a4i,a5i,a6i,spi,
  flagsi,pci,
  ra,
  d0o,d1o,d2o,d3o,d4o,d5o,d6o,d7o,
  a0o,a1o,a2o,a3o,a4o,a5o,a6o,spo,
  flagso,pco
);
input clk;
input wr;
input [8:0] wa;
input [31:0] d0i;
input [31:0] d1i;
input [31:0] d2i;
input [31:0] d3i;
input [31:0] d4i;
input [31:0] d5i;
input [31:0] d6i;
input [31:0] d7i;
input [31:0] a0i;
input [31:0] a1i;
input [31:0] a2i;
input [31:0] a3i;
input [31:0] a4i;
input [31:0] a5i;
input [31:0] a6i;
input [31:0] spi;
input [31:0] flagsi;
input [31:0] pci;
input [8:0] ra;
output [31:0] d0o;
output [31:0] d1o;
output [31:0] d2o;
output [31:0] d3o;
output [31:0] d4o;
output [31:0] d5o;
output [31:0] d6o;
output [31:0] d7o;
output [31:0] a0o;
output [31:0] a1o;
output [31:0] a2o;
output [31:0] a3o;
output [31:0] a4o;
output [31:0] a5o;
output [31:0] a6o;
output [31:0] spo;
output [31:0] flagso;
output [31:0] pco;

reg [575:0] mem [0:15];
reg [8:0] rra;

always_ff @(posedge clk)
  if (wr)
    mem[wa] <= {
      d0i,d1i,d2i,d3i,d4i,d5i,d6i,d7i,
      a0i,a1i,a2i,a3i,a4i,a5i,a6i,spi,
      flagsi,pci
    };
always_ff @(posedge clk)
  rra <= ra;

assign {
  d0o,d1o,d2o,d3o,d4o,d5o,d6o,d7o,
  a0o,a1o,a2o,a3o,a4o,a5o,a6o,spo,
  flagso,pco } = mem[rra];

endmodule
