// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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

`include "..\inc\Thor2020-config.sv"
`include "..\inc\Thor2020-types.sv"

module Thor2020(rst,clk,hartid,
  iicl_o,icti_o,ibte_o,icyc_o,istb_o,iack_i,isel_o,iadr_o,idat_i,
  cyc_o,stb_o,ack_i,we_o,sel_o,adr_o,dat_o,dat_i);
parameter WID=64;
parameter AMSB = `AMSB;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter RSTIP = 64'hFFFFFFFFFFFC0000;
input rst; input clk; input [WID-1:0] hartid;
output iicl_o; output [2:0] icti_o; output [1:0] ibte_o; output reg icyc_o; output reg istb_o; input iack_i; output [15:0] isel_o;
output reg [AMSB:0] iadr_o; input [127:0] idat_i;
output reg cyc_o; output reg stb_o; input ack_i; output reg we_o; output reg [7:0] sel_o; output tAddress adr_o; output tData dat_o; input tData dat_i;
parameter RR=7'd2,R2=7'd2,ADDI = 7'd4,CMPI=7'd6,ANDI=7'd8,ORI=7'd9,XORI=7'd10,ADD=7'd4,SUB=7'd5,CMP=7'd6,AND=7'd8,
OR=7'd9,XOR=7'd10,ANDCM=7'd11,NAND=7'd12,NOR=7'd13,XNOR=7'd14,ORCM=7'd15;
parameter ADDIS=7'd30,ANDIS=7'd16,ORIS=7'd17,XORIS=7'd18;
parameter LD=7'b101????,LDD=7'h53,ST=7'b110????,STB=7'h60,STH=7'h61,STW=7'h62,STD=7'h63,LOOP=7'd77,JMP=7'd78,JML=7'd79,LDI=7'd77;
parameter RET=7'd79,NOP=8'b11101010,SHL=7'd16,SHR=7'd17,ASR=7'd18,SHLI=7'd20,SHRI=7'd21,ASRI=7'd22,MFSPR=7'd32,MTSPR=7'd33;
parameter MUL=7'd24,MULU=7'd25,DIV=7'd26,DIVU=7'd27;
parameter CEQ=4'd0,CNE=4'd1,CLT=4'd4,CGE=4'd5,CLE=4'd6,CGT=4'd7,CLTU=4'd8,CGEU=4'd9,CLEU=4'd10,CGTU=4'd11,CADC=4'd12,COFL=4'd13,COD=4'd14;
parameter NOP_INSN = 32'b000_00000_00000_00000_000000_1110_1010;
reg [1:0] ol = 2'b11;
reg [3:0] state;
parameter ST_FETCH=4'd1,ST_RUN = 4'd2,ST_LD0=4'd3,ST_LD1=4'd4,ST_LD2=4'd5,ST_ST=4'd6,ST_MULDIV=4'd7,ST_ST2=4'd11,ST_ST3=4'd12;
parameter ST_LD0A=4'd8,ST_LD1A=4'd9,ST_LD2A=4'd10;
reg [127:0] ir;
reg [31:0] ip;
wire [40:0] ir0 = ir[40:0]; wire [40:0] ir1 = ir[81:41]; wire [40:0] ir2 = ir[122:82]; wire [2:0] irb = ir[125:123];
wire [6:0] opcode0 = ir0[14:8]; wire [6:0] opcode1 = ir1[14:8]; wire [6:0] opcode2 = ir2[14:8];
wire [6:0] funct70 = ir0[40:34]; wire [6:0] funct71 = ir1[40:34]; wire [6:0] funct72 = ir2[40:34];
wire isFloat0 = opcode0 >= 7'd112 && opcode0 <= 7'd121;
wire isFloat1 = opcode1 >= 7'd112 && opcode1 <= 7'd121;
wire isFloat2 = opcode2 >= 7'd112 && opcode2 <= 7'd121;
reg [2:0] ex;
wire ldstL = state==ST_ST3;
reg ld0, ld1, ld2;
reg lwr, vwr, vrd;
reg wr, rd;
reg vcyc, vstb, lcyc, lstb;
reg [7:0] vsel;
tAddress ad, la, va;
tData dati, dato;
integer n;

wire clkg = clk;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Tick counter.
//
// The tick counter is a free running counter that increments every clock cycle
// after a reset.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [63:0] tick;
always @(posedge clkg)
if (rst)
  tick <= 64'd0;
else
  tick <= tick + 2'd1;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Segment registers
//
// Segmented addresses are used only in user mode and add a clock cycle to the
// memory access time.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

tData cs, sego, sego1;

segmentRegs usgr1 (
  .rst(rst),
  .clk(clkg),
  .state(state),
  .expat(expatx),
  .po0(po0),
  .po1(po1),
  .po2(po2),
  .ir0(ir0),
  .ir1(ir1),
  .ir2(ir2),
  .s0(s0),    
  .s1(s1),
  .s2(s2),
  .cs(cs),
  .ad(ad),
  .sego(sego),
  .rg(ir2[23:21]),
  .sego1(sego1)
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [127:0] insn;
reg invall = 1'b0;
reg invline = 1'b0;
wire isROM;
wire [2:0] L1_flt;
wire L1_selpc, L1_wr, L1_nxt, L1_invline;
wire [127:0] ROM_dat, L1_dat, L2_dat;
wire L1_ihit, L2_ihit, L2_ihita;
wire L2_ld, L2_nxt;
wire [2:0] L2_cnt;
wire ivcyc, ivstb;
reg ilcyc, ilstb;
tAddress L1_adr, L2_adr;
tAddress missadr;
tAddress ivadr, iladr;
assign L2_ihit = isROM|L2_ihita;

L1_icache uic1
(
	.rst(rst),
	.clk(clkg),
	.nxt(L1_nxt),
	.wr(L1_wr),
	.wadr(L1_adr),
	.adr(L1_selpc ? ip : L1_adr),
	.i(L1_dat),
	.o(insn),
	.fi(L1_flt),
	.fault(),
	.hit(L1_ihit),
	.invall(invic),
	.invline(L1_invline),
	.missadr(missadr)
);

L2_icache uic2
(
	.rst(rst),
	.clk(clkg),
	.nxt(L2_nxt),
	.wr(L2_ld),
	.adr(L2_ld ? L2_adr : L1_adr),
	.cnt(L2_cnt),
	.exv_i(1'b0),
	.i(idat_i),
	.err_i(1'b0),
	.o(L2_dat),
	.hit(L2_ihita),
	.invall(invic),
	.invline(L1_invline)
);

ICController uicc1 (
  .rst_i(rst),
  .clk_i(clkg),
  .missadr(missadr),
  .hit(L1_ihit),
  .bstate(5'd0),  // BIDLE
  .idle(),
	.invline(invline),
	.invlineAddr(),
	.icl_ctr(),
	.thread_en(1'b0),

	.ihitL2(L2_ihit),
	.L2_ld(L2_ld),
	.L2_cnt(L2_cnt),
	.L2_adr(L2_adr),
	.L2_dat(L2_dat),
	.L2_nxt(L2_nxt),

	.L1_selpc(L1_selpc),
	.L1_adr(L1_adr),
	.L1_dat(L1_dat),
	.L1_flt(L1_flt),
	.L1_wr(L1_wr),
	.L1_invline(L1_invline),
	.ROM_dat(ROM_dat),
	.isROM(isROM),
	.icnxt(L1_nxt),
	.icwhich(),
  
	.icl_o(),
	.cti_o(icti_o),
	.bte_o(ibte_o),
	.bok_i(ibok_i),
	.cyc_o(ivcyc),
	.stb_o(ivstb),
	.ack_i(iack_i),
	.err_i(1'b0),
	.tlbmiss_i(1'b0),
	.exv_i(1'b0),
	.sel_o(isel_o),
	.adr_o(ivadr),
	.dat_i(idat_i)
);

bootrom ubr1 (
  .rst(rst),
  .clk(clkg),
  .cs(1'b1),
  .adr0(L1_adr[13:4]),
  .o0(ROM_dat),
  .adr1(),
  .o1(),
  .adr2(),
  .o2()
);

always @(posedge clkg)
if (rst) begin
  ilcyc <= 1'b0;
  icyc_o <= 1'b0;
end
else begin
  if (ol==2'b00) begin
    ilcyc <= ivcyc;
    icyc_o <= ilcyc & ivcyc;
  end
  else
    icyc_o <= ivcyc;
end

always @(posedge clkg)
if (rst) begin
  ilstb <= 1'b0;
  istb_o <= 1'b0;
end
else begin
  if (ol==2'b00) begin
    ilstb <= ivstb;
    istb_o <= ilstb & ivstb;
  end
  else
    istb_o <= ivstb;
end

always @(posedge clkg)
if (rst) begin
  iladr <= RSTIP;
  iadr_o <= RSTIP;
end
else begin
  if (ol==2'b00) begin
    iladr <= ivadr + {cs[WID-1:4],16'h0};
    iadr_o <= iladr;
  end
  else
    iadr_o <= ivadr;
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Write buffer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

assign rad = ad + {sego[WID-1:4],16'h0};
wire wr_ack;
/*
writeBuffer uwb1 (
  .rst_i(rst),
  .clk_i(clkg),
  .bstate(5'd0),
  .cyc_pending(),
  .wb_has_bus(),
  .update_iq(),
  .uid(),
  .ruid(),
  .fault(),
	.wb_v(),
	.wb_addr(),
	.wb_en_i(1'b1),
	.cwr_o(),
	.csel_o(),
	.cadr_o(),
	.cdat_o(),

	.p0_id_i(4'd0),
	.p0_rid_i(4'd0),
	.p0_wr_i(wr),
	.p0_ack_o(wr_ack),
	.p0_sel_i(8'hFF),
	.p0_adr_i(rad),
	.p0_dat_i(dato),
	.p0_hit(),
	.p0_cr(),

	.p1_id_i(4'd1),
	.p1_rid_i(4'd1),
	.p1_wr_i(1'b0),
	.p1_ack_o(),
	.p1_sel_i(8'h00),
	.p1_adr_i(32'h0),
	.p1_dat_i(64'd0),
	.p1_hit(),
	.p1_cr(),

	.p2_id_i(4'd2),
	.p2_rid_i(4'd2),
	.p2_wr_i(1'b0),
	.p2_ack_o(),
	.p2_sel_i(8'h00),
	.p2_adr_i(32'h0),
	.p2_dat_i(64'd0),
	.p2_hit(),
	.p2_cr(),

	.cyc_o(cyc_o),
	.stb_o(stb_o),
	.ack_i(ack_i),
	.err_i(1'b0),
	.tlbmiss_i(1'b0),
	.wrv_i(1'b0),
	.we_o(we_o),
	.sel_o(sel_o),
	.adr_o(adr_o),
	.dat_o(dat_o),
	.cr_o()
);
*/
always @(posedge clkg)
if (rst)
  cyc_o <= 1'b0;
else
  cyc_o <= vcyc;

always @(posedge clkg)
if (rst)
  stb_o <= 1'b0;
else
  stb_o <= vstb;

always @(posedge clkg)
if (rst)
  we_o <= 1'b0;
else
  we_o <= vwr;

wire [15:0] selsh = {8'h00,vsel} << {va[2:0],3'b0};

always @(posedge clkg)
if (rst)
  sel_o <= 1'b0;
else
  sel_o <= ldstL ? selsh[15:8] : selsh[7:0];

reg [AMSB:0] sva;
always @*
begin
  if (ol==2'b00)
    sva <= va + {sego[WID-1:4],16'h0};
  else
    sva <= va;
end

always @(posedge clkg)
if (rst)
  adr_o <= 64'd0;
else
  adr_o <= ldstL ? {sva[AMSB:3] + 2'd1,3'b0} : sva;

wire [127:0] datosh = dato << {va[2:0],3'b0};
always @(posedge clkg)
if (rst)
  dat_o <= 64'd0;
else
  dat_o <= ldstL ? datosh[127:64] : datosh[63:0];
 
always @(posedge clkg)
  dati <= ldstL ? {dat_i,64'h0} >> {va[2:0],3'b0} : dat_i >> {va[2:0],3'b0};

reg M1;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execution pattern table
// Controls which instruction slots execute during a given clock cycle.
// Execution pattern output is used as a mask along with the predicate to
// determine if the instruction executes.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [8:0] expat [0:11] =
	{
	 // Entered at slot #0, three instructions to execute
	 9'b001_010_100,	// 11 <= max break, separate cycles for each insn.
	 9'b011_100_000,	// 10 <= break after second instruction
	 9'b001_110_000,	// 01 <= break after first instruction
	 9'b111_000_000,	// 00 <= no breaks, all instructions execute in clock 1
	 
	 // Entered at slot #1, two instructions to execute
	 9'b010_100_000,  // 11
	 9'b010_100_000,  // 10
	 9'b110_000_000,  // 01
	 9'b110_000_000,  // 00
	 
	 // Entered at slot#2, only one insn to exec.
	 9'b100_000_000,  // 11 
	 9'b100_000_000,  // 10
	 9'b100_000_000,  // 01
	 9'b100_000_000   // 00
	 };
wire [8:0] expats = expat[{ip[3:2],insn[124:123]}];
reg [8:0] expatx;
wire [8:0] nexpatx = expatx << 2'd3;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [7:0] cnt0, cnt1, cnt2;
wire cntdone0;
wire cntdone1;
wire cntdone2;

muldivCnt umdc1 (rst, clk, state, p0, opcode0, funct70, cnt0, cntdone0);
muldivCnt umdc2 (rst, clk, state, p1, opcode1, funct71, cnt1, cntdone1);
muldivCnt umdc3 (rst, clk, state, p2, opcode2, funct72, cnt2, cntdone2);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Predicate logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [1:0] p [0:15];             // predicate register file
reg prfwr0, prfwr1, prfwr2, prfwrw0, prfwrw1, prfwrw2;
reg prfwr0a, prfwr1a, prfwr2a;
reg [1:0] pres0, pres1, pres2;  // predicate result busses
reg [1:0] pres0a, pres1a, pres2a;  // predicate result busses
reg [31:0] presw0, presw1, presw2;
wire po0;
wire po1;
wire po2;

function fnPcnd;
input [2:0] cnd;
input [1:0] p;
begin
	case(cnd)
	3'd0:	fnPcnd = p==2'b10;
	3'd1:	fnPcnd = 1'b1;
	3'd2:	fnPcnd = p==2'b00;
	3'd3:	fnPcnd = p!=2'b00;
	3'd4:	fnPcnd = p==2'b00 || p==2'b11;
	3'd5:	fnPcnd = p==2'b01;
	3'd6:	fnPcnd = p==2'b00 || p==2'b01;
	3'd7:	fnPcnd = p==2'b11;
	endcase
end
endfunction

always @(posedge clkg)
if (rst) begin
	for (n = 0; n < 32; n = n + 1)
		p[n] <= 2'b00;
end
else begin
	if (prfwr0) p[ir0[11:6]] <= pres0;
	if (prfwr1) p[ir1[11:6]] <= pres1;
	if (prfwr2) p[ir2[11:6]] <= pres2;
	if (prfwrw2) begin
	    p[1] <= presw2[3:2];
	    p[2] <= presw2[5:4];
	    p[3] <= presw2[7:6];
	    p[4] <= presw2[9:8];
	    p[5] <= presw2[11:10];
	    p[6] <= presw2[13:12];
	    p[7] <= presw2[15:14];
	    p[8] <= presw2[17:16];
	    p[9] <= presw2[19:18];
	    p[10] <= presw2[21:20];
	    p[11] <= presw2[23:22];
	    p[12] <= presw2[25:24];
	    p[13] <= presw2[27:26];
	    p[14] <= presw2[29:28];
	    p[15] <= presw2[31:30];
	end
	p[0] <= 2'b01;
end
assign po0 = fnPcnd(ir0[2:0],p[ir0[6:3]]);
assign po1 = fnPcnd(ir1[2:0],p[ir1[6:3]]) && ir0[40:34] != LDI && ir0[40:34] != JML;
assign po2 = fnPcnd(ir2[2:0],p[ir2[6:3]]);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Machine cycle one.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clkg)
if (rst)
  M1 <= TRUE;
else begin
  M1 <= FALSE;
  if (state==ST_RUN && nexpatx==9'd0)
    M1 <= TRUE;
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clkg)
if (rst)
  expatx <= 9'b000_000_000;
else begin
  if (state==ST_RUN && nexpatx==9'd0)
  	expatx <= expats;
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// General purpose register file
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [WID-1:0] regfile [0:63];
reg rfwr0,rfwr1,rfwr2;
reg [WID-1:0] res0, res1, res2;
always @(posedge clkg)
begin
	if (rfwr0) regfile[Rt0] <= res0;
	if (rfwr1) regfile[Rt1] <= res1;
	if (rfwr2) regfile[Rt2] <= res2;
end

wire [5:0] Ra0 = ir0[18:13]; wire [5:0] Rb0 = ir0[24:19]; wire [5:0] Rt0 = ir0[12:7];
wire [5:0] Ra1 = ir1[18:13]; wire [5:0] Rb1 = ir1[24:19]; wire [5:0] Rt1 = ir1[12:7];
wire [5:0] Ra2 = ir2[18:13]; wire [5:0] Rb2 = ir2[24:19]; wire [5:0] Rt2 = ir2[12:7];
wire [WID-1:0] a0 = Ra0==6'd0 ? 64'd0 : regfile[Ra0];
wire [WID-1:0] b0 = Rb0==6'd0 ? 64'd0 : regfile[Rb0];
wire [WID-1:0] s0 = Rt0==6'd0 ? 64'd0 : regfile[Rt0];
wire [WID-1:0] a1 = Ra1==6'd0 ? 64'd0 : regfile[Ra1];
wire [WID-1:0] b1 = Rb1==6'd0 ? 64'd0 : regfile[Rb1];
wire [WID-1:0] s1 = Rt1==6'd0 ? 64'd0 : regfile[Rt1];
wire [WID-1:0] a2 = Ra2==6'd0 ? 64'd0 : regfile[Ra2];
wire [WID-1:0] b2 = Rb2==6'd0 ? 64'd0 : regfile[Rb2];
wire [WID-1:0] s2 = Rt2==6'd0 ? 64'd0 : regfile[Rt2];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Loop counter.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [WID-1:0] lc;
always @(posedge clkg)
`ifdef SIM
if (rst)
  lc <= 64'd0;
else
`endif
begin
  if (state==ST_RUN) begin
    if (expatx[8] & po2)
      case(opcode2)
      LOOP: if (lc != 64'd0) lc <= lc - 2'd1;
      default:  ;
      endcase
    if (expatx[7] & po1)
      case(opcode1)
      LOOP: if (lc != 64'd0) lc <= lc - 2'd1;
      default:  ;
      endcase
    if (expatx[6] & po0)
      case(opcode0)
      LOOP: if (lc != 64'd0) lc <= lc - 2'd1;
      default:  ;
      endcase
    // Instructions are evaluated in order so that the last MTSPR takes
    // precedence if there are two writes to the same register.
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(ir0[40:34])
  	    MTSPR:  if (ir0[32:21]==12'h017) lc <= s0;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(ir1[40:34])
  	    MTSPR:  if (ir1[32:21]==12'h017) lc <= s1;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(ir2[40:34])
  	    MTSPR:  if (ir2[32:24]==12'h017) lc <= s2;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
  end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Link Register
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [AMSB:0] lr [0:7];

always @(posedge clkg)
// We don't really care what value is in the link register at reset, so let's
// not bother resetting it unless it's sim. Reset in sim to get rid of X's.
`ifdef SIM
if (rst) begin
  for (n = 0; n < 8; n = n + 1)
    lr[n] <= 64'hFFFFFFFFFFFC0000;
end else
`endif
begin
  if (state==ST_RUN) begin
    // Note instructions are evaluated in reverse order so that the first
    // branch encountered takes precednce.
    if (expatx[8] & po2)
  	  case(opcode2)
  	  LOOP: if (lc!=64'd0) lr[ir2[17:15]] <= ip + 5'd16;
  	  JMP:  lr[ir2[17:15]] <= ip + 5'd16;
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  LOOP: if (lc!=64'd0) lr[ir1[17:15]] <= ip + 5'd16;
  	  JMP:  lr[ir1[17:15]] <= ip + 5'd16;
    	default:  ;
      endcase
    if (expatx[6] & po0)
  	  case(opcode0)
  	  LOOP: if (lc!=64'd0) lr[ir0[17:15]] <= ip + 5'd16;
  	  JMP:  lr[ir0[17:15]] <= ip + 5'd16;
  	  JML:  lr[ir0[17:15]] <= ip + 5'd16;
    	default:  ;
      endcase

    // Instructions are evaluated in order so that the last MTSPR takes
    // precedence if there are two writes to the same register.
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(ir0[40:34])
  	    MTSPR:  if (ir0[32:24]==9'b000_000_100) lr[ir0[23:21]] <= s0;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(ir1[40:34])
  	    MTSPR:  if (ir1[32:24]==9'b000_000_100) lr[ir1[23:21]] <= s1;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(ir2[40:34])
  	    MTSPR:  if (ir2[32:24]==9'b000_000_100) lr[ir2[23:21]] <= s2;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
  end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Pointer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [AMSB:0] ip;

always @(posedge clkg)
if (rst)
  ip <= 64'hFFFFFFFFFFFC0000;
else begin
  if (state==ST_RUN) begin
  	if (nexpatx==9'd0) begin
  		ip[31:4] <= ip[31:4] + 28'd1;
  		ip[3:0] <= 4'h0;
  	end
  	if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(funct72)
    		RET:	ip <= lr[ir2[20:18]] + ir2[32:21];
  	    default: ;
  	    endcase
  	  LOOP: if (lc != 64'd0) ip <= {{41{ir2[40]}},ir2[40:21],ir2[0],ir2[21],ir2[0]} + lr[ir2[20:18]];
  	  JMP:  ip <= {{41{ir2[40]}},ir2[40:21],ir2[0],ir2[21],ir2[0]} + lr[ir2[20:18]];
    	default:  ;
      endcase
  	if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(funct71)
    		RET:	ip <= lr[ir1[20:18]] + ir1[32:21];
  	    default: ;
  	    endcase
  	  LOOP: if (lc != 64'd0) ip <= {{41{ir1[40]}},ir1[40:21],ir1[0],ir1[21],ir1[0]} + lr[ir1[20:18]];
  	  JMP:  ip <= {{41{ir1[40]}},ir1[40:21],ir1[0],ir1[21],ir1[0]} + lr[ir1[20:18]];
    	default:  ;
      endcase
  	if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(funct70)
    		RET:	ip <= lr[ir0[20:18]] + ir0[32:21];
  	    default: ;
  	    endcase
  	  LOOP: if (lc != 64'd0) ip <= {{41{ir0[40]}},ir0[40:21],ir0[0],ir0[21],ir0[0]} + lr[ir0[20:18]];
  	  JMP:  ip <= {{41{ir0[40]}},ir0[40:21],ir0[0],ir0[21],ir0[0]} + lr[ir0[20:18]];
    	JML:  ip <= {ir1,ir0[40:21],ir0[0],ir0[21],ir0[0]} + lr[ir0[20:18]];
    	default:  ;
      endcase
  end
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Register
//
// On a control transfer the ir is nopped out so that subsequent instructions
// have no effect.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clkg)
if (rst)
	ir <= {5'b0,{3{NOP_INSN}}};
else begin
  if (state==ST_RUN) begin
  	if (nexpatx==9'd0)
  		ir <= insn;
    // Note instructions are evaluated in reverse order so that the first
    // branch encountered takes precednce.
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(funct72)
    		RET:	ir[122:0] <= {3{NOP_INSN}};
    		default:  ;
    	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(funct71)
    		RET:	ir[122:0] <= {3{NOP_INSN}};
    		default:  ;
    	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(funct70)
    		RET:	ir[122:0] <= {3{NOP_INSN}};
    		default:  ;
    	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  ir[122:0] <= {3{NOP_INSN}};
  	  JML:  ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
  end
end


wire [63:0] imm0 = {{64{ir0[40]}},ir0[40:27]};
wire [63:0] imm1 = {{64{ir1[40]}},ir1[40:27]};
wire [63:0] imm2 = {{64{ir2[40]}},ir2[40:27]};

wire muli0 = opcode0==MUL; wire muli1 = opcode1==MUL; wire muli2 = opcode2==MUL;
wire mului0 = opcode0==MULU; wire mului1 = opcode1==MULU; wire mului2 = opcode2==MULU;
wire mulr0 = funct70==MUL; wire mulr1 = funct71==MUL; wire mulr2 = funct72==MUL;
wire mulur0 = funct70==MULU; wire mulur1 = funct71==MULU; wire mulur2 = funct72==MULU;
wire mul0, mulu0, div0, divu0;
wire mul1, mulu1, div1, divu1;
wire mul2, mulu2, div2, divu2;
assign mul0 = muli0|mulr0;
assign mulu0 = mului0|mulur0;
assign mul1 = muli1|mulr1;
assign mulu1 = mului1|mulur1;
assign mul2 = muli2|mulr2;
assign mulu2 = mului2|mulur2;
wire divi0 = opcode0==DIV; wire divi1 = opcode1==DIV; wire divi2 = opcode2==DIV;
wire divui0 = opcode0==DIVU; wire divui1 = opcode1==DIVU; wire divui2 = opcode2==DIVU;
wire divr0 = funct70==DIV; wire divr1 = funct71==DIV; wire divr2 = funct72==DIV;
wire divur0 = funct70==DIVU; wire divur1 = funct71==DIVU; wire divur2 = funct72==DIVU;
assign div0 = divi0|divr0;
assign divu0 = divui0|divur0;
assign div1 = divi1|divr1;
assign divu1 = divui1|divur1;
assign div2 = divi2|divr2;
assign divu2 = divui2|divur2;
wire [WID-1:0] prod0, quot0, produ0, quotu0;
wire [WID-1:0] prod1, quot1, produ1, quotu1;
wire [WID-1:0] prod2, quot2, produ2, quotu2;

Thor2020Mul umul0 (
  .CLK(clkg),
  .A(a0),
  .B(muli0 ? imm0 : b0),
  .P(prod0)
);
Thor2020Mul umul1 (
  .CLK(clkg),
  .A(a1),
  .B(muli1 ? imm1 : b1),
  .P(prod1)
);
Thor2020Mul umul2 (
  .CLK(clkg),
  .A(a2),
  .B(muli1 ? imm2 : b2),
  .P(prod2)
);
Thor2020Mulu umulu0 (
  .CLK(clkg),
  .A(a0),
  .B(mului0 ? imm0 : b0),
  .P(produ0)
);
Thor2020Mulu umulu1 (
  .CLK(clkg),
  .A(a1),
  .B(mului1 ? imm1 : b1),
  .P(produ1)
);
Thor2020Mulu umulu2 (
  .CLK(clkg),
  .A(a2),
  .B(mului1 ? imm2 : b2),
  .P(produ2)
);

divider udiv0 (
  .rst(rst),
  .clk(clkg),
  .ld(ld0),
  .abort(1'b0),
  .sgn(divr0|divi0),
  .sgnus(1'b0),
  .a(a0),
  .b(divi0 ? imm0 : b0),
  .qo(quot0),
  .ro(),
  .dvByZr(),
  .done(),
  .idle()
);

divider udiv1 (
  .rst(rst),
  .clk(clkg),
  .ld(ld1),
  .abort(1'b0),
  .sgn(divr1|divi1),
  .sgnus(1'b0),
  .a(a1),
  .b(divi1 ? imm1 : b1),
  .qo(quot1),
  .ro(),
  .dvByZr(),
  .done(),
  .idle()
);

divider udiv2 (
  .rst(rst),
  .clk(clkg),
  .ld(ld2),
  .abort(1'b0),
  .sgn(divr2|divi2),
  .sgnus(1'b0),
  .a(a2),
  .b(divi2 ? imm2 : b2),
  .qo(quot2),
  .ro(),
  .dvByZr(),
  .done(),
  .idle()
);

function [47:0] fnDisassem;
input [40:0] iri;
begin
  case(iri[14:8])
  R2:
    case(iri[40:34])
    ADD:  fnDisassem = "ADDI  ";
    AND:  fnDisassem = "ANDI  ";
    OR:   fnDisassem = "ORI   ";
    RET:  fnDisassem = "RET   ";
    LDD:  fnDisassem = "LDDX  ";
    STD:  fnDisassem = "STDX  ";
    default:  fnDisassem = "????? ";
    endcase
  ADD:  fnDisassem = "ADDI  ";
  AND:  fnDisassem = "ANDI  ";
  OR:   fnDisassem = "ORI   ";
  JMP:  fnDisassem = "JMP   ";
  LDD:  fnDisassem = "LDD   ";
  STD:  fnDisassem = "STD   ";
  default:  fnDisassem = "????? ";
  endcase
end
endfunction

function [23:0] fnDisPcnd;
input [3:0] rn;
input [2:0] cnd;
begin
  if (|rn)
    case(cnd)
    3'd0: fnDisPcnd = ".un";
    3'd1: fnDisPcnd = ".??";
    3'd2: fnDisPcnd = ".eq";
    3'd3: fnDisPcnd = ".ne";
    3'd4: fnDisPcnd = ".lt";
    3'd5: fnDisPcnd = ".ge";
    3'd6: fnDisPcnd = ".le";
    3'd7: fnDisPcnd = ".gt";
    endcase
  else
    fnDisPcnd = "   ";
end
endfunction

function [23:0] fnPreg;
input [3:0] rn;
begin
  if (|rn)
    case(rn)
    4'd0: fnPreg = " p0";
    4'd1: fnPreg = " p1";
    4'd2: fnPreg = " p2";
    4'd3: fnPreg = " p3";
    4'd4: fnPreg = " p4";
    4'd5: fnPreg = " p5";
    4'd6: fnPreg = " p6";
    4'd7: fnPreg = " p7";
    4'd8: fnPreg = " p8";
    4'd9: fnPreg = " p9";
    4'd10: fnPreg = "p10";
    4'd11: fnPreg = "p11";
    4'd12: fnPreg = "p12";
    4'd13: fnPreg = "p13";
    4'd14: fnPreg = "p14";
    4'd15: fnPreg = "p15";
    endcase
  else
    fnPreg = "   ";
end
endfunction


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clkg)
if (rst)
	state <= ST_RUN;
else begin
	case(state)
	ST_RUN: 
	  begin
  		if (expatx[8] & po2) tExecSt(ir2,ST_LD2);
  		if (expatx[7] & po1) tExecSt(ir1,ST_LD1);
  		if (expatx[6] & po0) tExecSt(ir0,ST_LD0);
		end
	ST_LD0:   state <= ST_LD0A;
	ST_LD1:   state <= ST_LD1A;
	ST_LD2:   state <= ST_LD2A;
	ST_LD0A:	if (ack_i) begin state <= ST_RUN; end
	ST_LD1A:	if (ack_i) begin state <= ST_RUN; end
	ST_LD2A:	if (ack_i) begin state <= ST_RUN; end
	ST_ST:	if (ack_i) begin state <= selsh[15:8] ? ST_ST2 : ST_RUN; end
	ST_ST2: if (~ack_i) state <= ST_ST3;
	ST_ST3: if (ack_i) state <= ST_RUN;
	ST_MULDIV:
	  if (cntdone0&cntdone1&cntdone2)
	    state <= ST_RUN;
	default:	state <= ST_RUN;
	endcase
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clkg)
if (rst) begin
	rfwr0 = 1'b0; prfwr0 = 1'b0; prfwrw0 = 1'b0;
	rfwr1 = 1'b0; prfwr1 = 1'b0; prfwrw1 = 1'b0;
	rfwr2 = 1'b0; prfwr2 = 1'b0; prfwrw2 = 1'b0;
	prfwr0a = 1'b0; prfwr1a = 1'b0; prfwr2a = 1'b0;
	vwr = 1'b0;
	rd = 1'b0;
	ld0 = 1'b0; ld1 = 1'b0; ld2 = 1'b0;
end
else begin
	rfwr0 = 1'b0; prfwr0 = 1'b0; prfwrw0 = 1'b0;
	rfwr1 = 1'b0; prfwr1 = 1'b0; prfwrw1 = 1'b0;
	rfwr2 = 1'b0; prfwr2 = 1'b0; prfwrw2 = 1'b0;
	prfwr0a = 1'b0; prfwr1a = 1'b0; prfwr2a = 1'b0;
	ld0 = 1'b0; ld1 = 1'b0; ld2 = 1'b0;
	case(state)
	ST_RUN: 
	  begin
  		if (expatx[8] & po2) tExec(ir2,a0,b0,s0,res0,pres0,pres0a,rfwr2,prfwr2,prfwr0a,ld2,presw0,prfwrw0);
  		if (expatx[7] & po1) tExec(ir1,a1,b1,s1,res1,pres1,pres1a,rfwr1,prfwr1,prfwr1a,ld1,presw1,prfwrw1);
  		if (expatx[6] & po0) tExec(ir0,a2,b2,s2,res2,pres2,pres2a,rfwr0,prfwr0,prfwr2a,ld0,presw2,prfwrw2);
  		if (ir0[40:34]==LDI) begin if (po0) begin res0 = {ir1,ir0[33:12]}; rfwr0 = 1'b1; end end
  		else if (ir1[40:34]==LDI) begin if (po1) begin res1 = {ir2,ir1[33:12]}; rfwr1 = 1'b1; end end
		end
	ST_LD0A:	if (ack_i) begin res0 = dat_i; rfwr0 = 1'b1; vrd = 1'b0; vcyc = 1'b0; vstb = 1'b0; end
	ST_LD1A:	if (ack_i) begin res1 = dat_i; rfwr1 = 1'b1; vrd = 1'b0; vcyc = 1'b0; vstb = 1'b0; end
	ST_LD2A:	if (ack_i) begin res2 = dat_i; rfwr2 = 1'b1; vrd = 1'b0; vcyc = 1'b0; vstb = 1'b0; end
	ST_ST:	if (ack_i) begin vwr = 1'b0; vcyc = selsh[15:8]!=8'h00; vstb = 1'b0; end
	ST_ST2: if (~ack_i) begin vstb = 1'b1; end
	ST_ST3:	if (ack_i) begin vwr = 1'b0; vcyc = 1'b0; vstb = 1'b0; end
	ST_MULDIV:
	  if (cntdone0&cntdone1&cntdone2) begin
	    case({mul0,mulu0,div0,divu0})
	    4'b1???:  begin res0 = prod0;  rfwr0 = 1'b1; pres0a = {res0[WID-1],|res0}; prfwr0a = ir0[0]; end
	    4'b01??:  begin res0 = produ0; rfwr0 = 1'b1; pres0a = {res0[WID-1],|res0}; prfwr0a = ir0[0]; end
	    4'b001?:  begin res0 = quot0;  rfwr0 = 1'b1; pres0a = {res0[WID-1],|res0}; prfwr0a = ir0[0]; end
	    4'b0001:  begin res0 = quot0;  rfwr0 = 1'b1; pres0a = {res0[WID-1],|res0}; prfwr0a = ir0[0]; end
	    default:  ; // hardware error, got to MULDIV state and no mul/div decoded.
	    endcase
	    case({mul1,mulu1,div1,divu1})
	    4'b1???:  begin res1 = prod1;  rfwr1 = 1'b1; pres1a = {res1[WID-1],|res1}; prfwr1a = ir1[0]; end
	    4'b01??:  begin res1 = produ1; rfwr1 = 1'b1; pres1a = {res1[WID-1],|res1}; prfwr1a = ir1[0]; end
	    4'b001?:  begin res1 = quot1;  rfwr1 = 1'b1; pres1a = {res1[WID-1],|res1}; prfwr1a = ir1[0]; end
	    4'b0001:  begin res1 = quot1;  rfwr1 = 1'b1; pres1a = {res1[WID-1],|res1}; prfwr1a = ir1[0]; end
	    default:  ;
	    endcase
	    case({mul2,mulu2,div2,divu2})
	    4'b1???:  begin res2 = prod2;  rfwr2 = 1'b1; pres2a = {res2[WID-1],|res2}; prfwr2a = ir2[0]; end
	    4'b01??:  begin res2 = produ2; rfwr2 = 1'b1; pres2a = {res2[WID-1],|res2}; prfwr2a = ir2[0]; end
	    4'b001?:  begin res2 = quot2;  rfwr2 = 1'b1; pres2a = {res2[WID-1],|res2}; prfwr2a = ir2[0]; end
	    4'b0001:  begin res2 = quot2;  rfwr2 = 1'b1; pres2a = {res2[WID-1],|res2}; prfwr2a = ir2[0]; end
	    default:  ;
	    endcase
	  end
	default:	;
	endcase
	$display("------------------------------------");
	$display("ip: %h  ir: %h", ip, ir);
	$display("%c%h %s%s %s %h %h %h %h", ir[123]?"S":"-",ir0,fnPreg(ir0[7:4]),fnDisPcnd(ir0[7:4],ir0[3:1]),fnDisassem(ir0),imm0, s0, a0, b0);
	$display("%c%h %s%s %s %h %h %h %h", ir[124]?"S":"-",ir1,fnPreg(ir1[7:4]),fnDisPcnd(ir1[7:4],ir1[3:1]),fnDisassem(ir1),imm1, s1, a1, b1);
	$display("%c%h %s%s %s %h %h %h %h", ir[125]?"S":"-",ir2,fnPreg(ir2[7:4]),fnDisPcnd(ir2[7:4],ir2[3:1]),fnDisassem(ir2),imm2, s2, a2, b2);
end

task tCmp;
input [WID-1:0] a;
input [WID-1:0] b;
output [1:0] o;
output prfwr;
reg [WID:0] sum;
begin
  if ($signed(a) < $signed(b))
    o = 2'b11;
  else if (a==b)
    o = 2'b00;
  else
    o = 2'b01;
	prfwr = 1'b1;
end
endtask

task tCmpu;
input [WID-1:0] a;
input [WID-1:0] b;
output [1:0] o;
output prfwr;
reg [WID:0] sum;
begin
  if (a < b)
    o = 2'b11;
  else if (a==b)
    o = 2'b00;
  else
    o = 2'b01;
	prfwr = 1'b1;
end
endtask

task tAlu;
input [40:0] irx;
input [6:0] op;
input [WID-1:0] a;
input [WID-1:0] b;
output [WID-1:0] res;
output rfwr;
output ld;
begin
	case(op)
	ADD:	begin res = a + b; rfwr = 1'b1; end
	SUB:	begin res = a - b; rfwr = 1'b1; end
	AND:	begin res = a & b; rfwr = 1'b1; end
	OR:		begin res = a | b; rfwr = 1'b1; end
	XOR:	begin res = a ^ b; rfwr = 1'b1; end
	ANDCM:begin res = a & ~b; rfwr = 1'b1; end
	NAND:	begin res = ~(a & b); rfwr = 1'b1; end
	NOR:	begin res = ~(a | b); rfwr = 1'b1; end
	XNOR:	begin res = ~(a ^ b); rfwr = 1'b1; end
	ORCM:	begin res = a | ~b; rfwr = 1'b1; end
	DIV:  begin ld = 1'b1; end
	DIVU: begin ld = 1'b1; end
	SHL:	begin res = a << b[5:0]; rfwr = 1'b1; end
	SHR:	begin res = a >> b[5:0]; rfwr = 1'b1;  end
	ASR:	begin res = a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; rfwr = 1'b1; end
	SHLI:	begin res = a << b[5:0]; rfwr = 1'b1; end
	SHRI:	begin res = a >> b[5:0]; rfwr = 1'b1; end
	ASRI:	begin res = a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; rfwr = 1'b1; end
	default:	;
	endcase
end endtask

task tExec;
input [40:0] irx;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] s;
output [WID-1:0] res;
output [1:0] pres;
output [1:0] presa;
output rfwr;
output prfwr;
output prfwra;
output ld;
output [31:0] presw;
output prfwrw;
reg [6:0] opcode;
reg [WID-1:0] imm;
reg Sc;
reg isFloat;
begin
	opcode = irx[14:8];
	isFloat = opcode >= 7'd112 && opcode <= 7'd121;
  case(irx[14:8])
  AND:  imm = {{50{1'b1}},irx[40:27]};
  OR:   imm = {50'd0,irx[40:27]};
  XOR:  imm = {50'd0,irx[40:27]};
  default:  imm = {{50{irx[40]}},irx[40:27]};
  endcase
  Sc = irx[33];
	casez(opcode)
	RR:
		casez(irx[40:34])
		CMP:	if (irx[20]) tCmp(a,b,pres,prfwr); else tCmpu(a,b,pres,prfwr);
		SHLI: tAlu(irx,irx[40:34],a,imm,res,rfwr,ld);
		SHRI: tAlu(irx,irx[40:34],a,imm,res,rfwr,ld);
		ASRI: tAlu(irx,irx[40:34],a,imm,res,rfwr,ld);
		MFSPR:
		  begin
  		  case(irx[32:21])
  		  12'h001:  begin res = hartid; rfwr <= 1'b1; end
  		  12'h002:  begin res = tick; rfwr <= 1'b1; end
  		  12'h020,12'h021,12'h022,12'h023,12'h024,12'h025,12'h026,12'h027:
  		    begin res = lr[irx[23:21]]; rfwr = 1'b1; end
  		  12'h016: 
  		    begin
            res[1:0] = 2'b01; res[3:2] = p[1]; res[5:4] = p[2]; res[7:6] = p[3];
            res[9:8] = p[4];  res[11:10] = p[5]; res[13:12] = p[6]; res[15:14] = p[7];
            res[17:16] = p[8]; res[19:18] = p[9]; res[21:20] = p[10]; res[23:22] = p[11];
            res[25:24] = p[12]; res[27:26] = p[13]; res[29:28] = p[14]; res[31:30] = p[15];
           end
        12'h17: begin res <= lc; rfwr <= 1'b1; end
  		  12'h060,12'h061,12'h062,12'h063,12'h064,12'h065,12'h066,12'h067:  begin res = sego1; rfwr = 1'b1; end
  		  default:  ;
  		  endcase
		  end
		MTSPR:
		  case(irx[32:21])
		  12'h016: begin presw = s[31:0]; prfwrw = 1'b1; end
		  default:  ;
		  endcase
  	LDD:		begin va = a + (b << {Sc,2'b0}); vrd = 1'b1; vcyc = 1'b1; vsel <= 8'hFF; end
  	STB:		begin va = a + b; dato = s; vwr = 1'b1; vsel <= 8'h01; vcyc = 1'b1; end
  	STH:		begin va = a + (b << Sc); dato = s; vwr = 1'b1; vsel <= 8'h03; vcyc = 1'b1; end
  	STW:		begin va = a + (b << {Sc,1'b0}); dato = s; vwr = 1'b1; vsel <= 8'h0F; vcyc = 1'b1; end
  	STD:		begin va = a + (b << {Sc,2'b0}); dato = s; vwr = 1'b1; vcyc = 1'b1; vsel <= 8'hFF; end
		default:	tAlu(irx,irx[40:34],a,b,res,rfwr,ld);
		endcase
	ADDIS:  begin res = s + {{30{irx[40]}},irx[40:21],14'd0}; rfwr <= 1'b1; end 
	ANDIS:  begin res = s & {{30{irx[40]}},irx[40:21],14'h3FFF}; rfwr <= 1'b1; end
	ORIS:   begin res = s | {{30{irx[40]}},irx[40:21],14'd0}; rfwr <= 1'b1; end
	XORIS:  begin res = s ^ {30'd0,irx[40:21],14'd0}; rfwr <= 1'b1; end
	LDD:		begin va = a + imm; vrd = 1'b1; vsel <= 8'hFF; vcyc = 1'b1; end
	STB:		begin va = a + imm; dato = s; vwr = 1'b1; vsel <= 8'h01; vcyc = 1'b1; end
	STH:		begin va = a + imm; dato = s; vwr = 1'b1; vsel <= 8'h03; vcyc = 1'b1; end
	STW:		begin va = a + imm; dato = s; vwr = 1'b1; vsel <= 8'h0F; vcyc = 1'b1; end
	STD:		begin va = a + imm; dato = s; vwr = 1'b1; vsel <= 8'hFF; vcyc = 1'b1; end
	CMPI:	if (irx[20]) tCmp(a,imm,pres,prfwr); else tCmpu(a,imm,pres,prfwr);
	default:	tAlu(irx,irx[6:0],a,imm,res,rfwr,ld);
	endcase
/*
	if (isFloat) begin
		if (&res[WID-1:WID-16] && |res[WID-17:0])
			presa = 2'b10;
		else if (res[WID-1])
			presa = 2'b11;
		else if (res[WID-2:0]=={WID-1{1'b0}})
			presa = 2'b00;
		else
			presa = 2'b01;
	end
	else
  	presa = {res[WID-1],|res};
*/
end
endtask

task tAluSt;
input [6:0] op;
begin
	case(op)
	MUL:  begin state <= ST_MULDIV; end
	MULU: begin state <= ST_MULDIV; end
	DIV:  begin state <= ST_MULDIV; end
	DIVU: begin state <= ST_MULDIV; end
	default:	;
	endcase
end endtask

task tExecSt;
input [40:0] irx;
input [5:0] st;
begin
	casez(irx[14:8])
	RR: tAluSt(irx[40:34]);
	LD:	state <= st;
	ST:	state <= ST_ST;
	default:	tAluSt(irx[6:0]);
	endcase
end
endtask

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

module muldivCnt(rst, clk, state, p, opcode, funct, cnt, done);
input rst;
input clk;
input [5:0] state;
input p;
input [6:0] opcode;
input [6:0] funct;
output reg [7:0] cnt;
output done;
parameter ST_RUN = 6'd2;
parameter ST_MULDIV = 6'd7;
parameter R2=7'd2,MUL=7'd24,MULU=7'd25,DIV=7'd26,DIVU=7'd27;

assign done = cnt[7];
always @(posedge clk)
if (rst)
  cnt <= 8'hFF;
else begin
  case(state)
  ST_RUN:
    begin
      if (p) begin
        case(opcode)
        R2:
          case(funct)
          MUL:  cnt <= 8'd0;
          MULU: cnt <= 8'd0;
          DIV:  cnt <= 8'd67;
          DIVU: cnt <= 8'd67;
          endcase
        MUL:  cnt <= 8'd0;
        MULU: cnt <= 8'd0;
        DIV:  cnt <= 8'd67;
        DIVU: cnt <= 8'd67;
        endcase
      end
    end
  ST_MULDIV:  if (!done) cnt <= cnt - 8'd1;
  endcase
end

endmodule
