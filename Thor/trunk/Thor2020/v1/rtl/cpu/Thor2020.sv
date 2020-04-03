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
`include "..\inc\Thor2020-const.sv"
`include "..\inc\Thor2020-types.sv"
`include "..\fpu\fpConfig.sv"

module Thor2020(rst,clk,hartid,
  iicl_o,icti_o,ibte_o,icyc_o,istb_o,iack_i,isel_o,iadr_o,idat_i,
  cyc_o,stb_o,ack_i,we_o,sel_o,adr_o,dat_o,dat_i);
parameter WID=64;
parameter FPWID=80;
parameter AMSB = `AMSB;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter RSTIP = 64'hFFFFFFFFFFFC0000;
`include "..\fpu\fpSize.sv"
input rst; input clk; input [WID-1:0] hartid;
output iicl_o; output [2:0] icti_o; output [1:0] ibte_o; output reg icyc_o; output reg istb_o; input iack_i; output [15:0] isel_o;
output reg [AMSB:0] iadr_o; input [127:0] idat_i;
output reg cyc_o; output reg stb_o; input ack_i; output reg we_o; output reg [15:0] sel_o; output tAddress adr_o; output reg [127:0] dat_o; input [127:0] dat_i;
parameter RR=7'd2,R2=7'd2,ADDI = 7'd4,CMPI=7'd6,ANDI=7'd8,ORI=7'd9,XORI=7'd10,ADD=7'd4,SUB=7'd5,CMP=7'b0100???,AND=7'd8,
OR=7'd9,XOR=7'd10,ANDCM=7'd11,NAND=7'd12,NOR=7'd13,XNOR=7'd14,ORCM=7'd15;
parameter ADDIS=7'd30,ANDIS=7'd16,ORIS=7'd17,XORIS=7'd18;
parameter LD=7'b101????,LDD=7'h53,ST=7'b110????,STB=7'h60,STH=7'h61,STW=7'h62,STD=7'h63;
parameter JMP_CTOP=7'd73,JMP_CEXIT=7'd74,JMP_WTOP=7'd75,JMP_WEXIT=7'd76,LOOP=7'd76,JMP=7'd72,JML=7'd79,LDI=7'd77;
parameter RET=7'd79,NOP=8'b11101010,SHL=7'd16,SHR=7'd17,ASR=7'd18,SHLI=7'd20,SHRI=7'd21,ASRI=7'd22,MFSPR=7'd32,MTSPR=7'd33;
parameter MUL=7'd24,MULU=7'd25,DIV=7'd26,DIVU=7'd27;
parameter CEQ=7'd40,CNE=7'd41,CLT=7'd32,CGE=7'd33,CLE=7'd34,CGT=7'd35,CLTU=7'd36,CGEU=7'd37,CLEU=7'd38,CGTU=7'd39;
parameter NOP_INSN = 32'b000_00000_00000_00000_000000_1110_1010;
parameter FMADD=7'd112,FMSUB=7'd113,FNMADD=7'd114,FNMSUB=7'd115;
reg [1:0] ol = 2'b11;
reg [4:0] state;
parameter ST_FETCH=5'd1,ST_RUN = 5'd2,ST_LD0=5'd3,ST_LD1=5'd4,ST_LD2=5'd5,ST_ST1=5'd6,ST_MULDIV=5'd7,ST_ST2=5'd11,ST_ST3=5'd12;
parameter ST_LD0A=5'd8,ST_LD1A=5'd9,ST_LD2A=5'd10,ST_FMADD=5'd13,ST_ST4=5'd14,ST_ST5=5'd15;
parameter ST_LD3=5'd16,ST_LD4=5'd17,ST_LD5=5'd18,ST_LD6=5'd19,ST_LD7=5'd20;
reg [127:0] ir;
reg [31:0] ip;
wire [40:0] ir0 = ir[40:0]; wire [40:0] ir1 = ir[81:41]; wire [40:0] ir2 = ir[122:82]; wire [2:0] irb = ir[125:123];
wire [6:0] opcode0 = ir0[40:34]; wire [6:0] opcode1 = ir1[40:34]; wire [6:0] opcode2 = ir2[40:34];
wire [6:0] funct70 = ir0[33:27]; wire [6:0] funct71 = ir1[33:27]; wire [6:0] funct72 = ir2[33:27];
reg [6:0] ldopcode, ldfunc;
wire [5:0] Ra0 = ir0[`cRA]; wire [5:0] Rb0 = ir0[`cRB]; wire [5:0] Rc0 = ir0[`cRC]; wire [5:0] Rt0 = ir0[`cRT];
wire [5:0] Ra1 = ir1[`cRA]; wire [5:0] Rb1 = ir1[`cRB]; wire [5:0] Rc2 = ir1[`cRC]; wire [5:0] Rt1 = ir1[`cRT];
wire [5:0] Ra2 = ir2[`cRA]; wire [5:0] Rb2 = ir2[`cRB]; wire [5:0] Rc1 = ir2[`cRC]; wire [5:0] Rt2 = ir2[`cRT];
reg [5:0] xRt0, xRt1, xRt2;
reg [63:0] fpstat;
wire [2:0] fprm = fpstat[31:29];
wire isFloat0 = opcode0 >= 7'd112 && opcode0 <= 7'd121;
wire isFloat1 = opcode1 >= 7'd112 && opcode1 <= 7'd121;
wire isFloat2 = opcode2 >= 7'd112 && opcode2 <= 7'd121;
wire [6:0] fltfunc0 = ir0[30:24];
wire [6:0] fltfunc1 = ir1[30:24];
wire [6:0] fltfunc2 = ir2[30:24];
wire [5:0] fltfunc0a = ir0[23:18];
wire [5:0] fltfunc1a = ir1[23:18];
wire [5:0] fltfunc2a = ir2[23:18];
wire fmadd0 = opcode0==FMADD; wire fmsub0 = opcode0==FMSUB;
wire fnmadd0 = opcode0==FNMADD; wire fnmsub0 = opcode0==FNMSUB;
wire fmadd1 = opcode1==FMADD; wire fmsub1 = opcode1==FMSUB;
wire fnmadd1 = opcode1==FNMADD; wire fnmsub1 = opcode1==FNMSUB;
wire fmadd2 = opcode2==FMADD; wire fmsub2 = opcode2==FMSUB;
wire fnmadd2 = opcode2==FNMADD; wire fnmsub2 = opcode2==FNMSUB;
wire fdiv0 = opcode0==`cFLOAT2 && fltfunc0==`cFDIV;
wire fdiv1 = opcode1==`cFLOAT2 && fltfunc1==`cFDIV;
wire fdiv2 = opcode2==`cFLOAT2 && fltfunc2==`cFDIV;
wire fcvt0 = opcode0==`cFLOAT2 && fltfunc0==`cFLOAT1 && (fltfunc0a==`cF2I || fltfunc0a==`cI2F || fltfunc0a==`cFTRUNC);
wire fcvt1 = opcode1==`cFLOAT2 && fltfunc1==`cFLOAT1 && (fltfunc1a==`cF2I || fltfunc1a==`cI2F || fltfunc1a==`cFTRUNC);
wire fcvt2 = opcode2==`cFLOAT2 && fltfunc2==`cFLOAT1 && (fltfunc2a==`cF2I || fltfunc2a==`cI2F || fltfunc2a==`cFTRUNC);
wire ftrunc0 = opcode0==`cFLOAT2 && fltfunc0==`cFLOAT1 && fltfunc0a==`cFTRUNC;
wire ftrunc1 = opcode1==`cFLOAT2 && fltfunc1==`cFLOAT1 && fltfunc1a==`cFTRUNC;
wire ftrunc2 = opcode2==`cFLOAT2 && fltfunc2==`cFLOAT1 && fltfunc2a==`cFTRUNC;
reg [2:0] ex;
wire ldstL = state==ST_ST3;
wire ldst5 = state==ST_ST5;
reg ld0, ld1, ld2;
reg lwr, vwwr, vwrd, vwr;
reg wr, rd;
reg vwcyc, vwstb, lwcyc, lwstb;
reg vrcyc, vrstb, lrcyc, lrstb;
reg [9:0] vwsel, vrsel;
reg [7:0] rsel;
tAddress wadr0, lwa, vwa, vra, radr0, radr;
tData dati, wdat;
reg [79:0] vwdat;
reg rack;
wire po0;
wire po1;
wire po2;
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

tData cs, rsego, wsego, sego1;

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
  .rad(vra),
  .rsego(rsego),
  .wad(vwa),
  .wsego(wsego),
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
wire [511:0] ROM_dat, L1_dat, L2_dat;
wire L1_ihit, L2_ihit, L2_ihita;
wire L2_ld, L2_nxt;
wire [2:0] L2_cnt;
wire ic_idle;
wire ivcyc, ivstb;
reg ilcyc, ilstb;
tAddress L1_adr, L2_adr;
tAddress missadr;
tAddress ivadr, iladr;
assign L2_ihit = isROM|L2_ihita;

wire ihit = L1_ihit & ic_idle;

wire [511:0] d0ROM_dat;
wire [511:0] d1ROM_dat;

wire [2:0] d0cti;
wire [1:0] d0bte;
wire d0cyc, d0stb, d0err_i, d0wrv_i, d0rdv_i;
reg d0ack_i;
wire [7:0] d0sel;
tAddress d0adr;
wire [2:0] d1cti;
wire [1:0] d1bte;
wire d1cyc, d1stb, d1err_i, d1wrv_i, d1rdv_i;
reg d1ack_i;
wire [7:0] d1sel;
tAddress d1adr;

wire d0isROM, d1isROM;
wire d0L1_wr, d0L2_ld;
wire d1L1_wr, d1L2_ld;
tAddress d0L1_adr, d0L2_adr;
tAddress d1L1_adr, d1L2_adr;
wire d0L2_rhit, d0L2_whit;
wire d0L2_rhita, d1L2_rhita;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_rhit, d1L2_whit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [63:0] d0L1_sel, d0L2_sel;
wire [63:0] d1L1_sel, d1L2_sel;
wire [511:0] d0L1_dat, d0L2_rdat, d0L2_wdat;
wire [511:0] d1L1_dat, d1L2_rdat, d1L2_wdat;
wire d0L1_dhit;
wire d0L1_selpc;
wire d1L1_selpc, d1L2_selpc;
wire d0L1_invline,d1L1_invline;
//reg [255:0] dcbuf;

reg preload;
reg [1:0] dccnt;
reg [3:0] dcwait = 4'd3;
reg [3:0] dcwait_ctr = 4'd3;
wire dhit0, dhit1;
wire dhit0a, dhit1a;
wire dhit00, dhit10;
wire dhit01, dhit11;
tAddress dcadr;
wire [127:0] dcdat;
wire dcwr;
wire [15:0] dcsel;
assign d0L2_rhit = d0isROM|d0L2_rhita;
assign d1L2_rhit = d1isROM|d1L2_rhita;

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
  .idle(ic_idle),
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
  .adr0(L1_adr[17:0]),
  .o0(ROM_dat),
  .adr1(18'h0),
  .o1(),
  .adr2(18'h0),
  .o2()
);

reg StoreAck1, isStore;
tData dc0_out, dc1_out;
wire whit0, whit1, whit2;
reg dram0_load, dram1_load;

wire wr_dcache0 = dcwr;
wire wr_dcache1 = dcwr;
//wire rd_dcache0 = !dram0_unc & dram0_load;
//wire rd_dcache1 = !dram1_unc & dram1_load;

DCController udcc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(radr),
	.rd(lrcyc),
	.wr(dcwr),
	.wsel(dcsel),
	.wadr(dcadr),
	.wdat(dcdat),
	.bstate(bstate),
	.state(),
	.invline(invdcl),
	.invlineAddr(invlineAddr),
	.icl_ctr(),
	.isROM(d0isROM),
	.ROM_dat(d0ROM_dat),
	.dL2_rhit(d0L2_rhit),
	.dL2_rdat(d0L2_rdat),
	.dL2_whit(d0L2_whit),
	.dL2_ld(d0L2_ld),
	.dL2_wsel(d0L2_sel),
	.dL2_wadr(d0L2_adr),
	.dL2_wdat(d0L2_wdat),
	.dL2_nxt(d0L2_nxt),
	.dL1_hit(d0L1_dhit),
	.dL1_selpc(d0L1_selpc),
	.dL1_sel(d0L1_sel),
	.dL1_adr(d0L1_adr),
	.dL1_dat(d0L1_dat),
	.dL1_wr(d0L1_wr),
	.dL1_invline(d0L1_invline),
	.dcnxt(d0L1_nxt),
	.dcwhich(),
	.dcl_o(),
	.cti_o(d0cti),
	.bte_o(d0bte),
	.bok_i(1'b0),
	.cyc_o(d0cyc),
	.stb_o(d0stb),
	.ack_i(d0ack_i),
	.err_i(d0err_i),
	.wrv_i(d0wrv_i),
	.rdv_i(d0rdv_i),
	.sel_o(d0sel),
	.adr_o(d0adr),
	.dat_i(dat_i)
);

L1_dcache udc1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L1_nxt),
	.wr(d0L1_wr),
	.sel(d0L1_sel),
	.adr(d0L1_selpc ? radr : d0L1_adr),
	.i({5'd0,d0L1_dat}),
	.o(dc0_out),
	.fault(),
	.hit(d0L1_dhit),
	.invall(1'b0),//invdc),
	.invline(1'b0)//d0L1_invline)
);

L2_dcache udc2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L2_nxt),
	.wr(d0L2_ld),
	.wadr(d0L2_adr),
	.radr(d0L1_adr),
	.sel(d0L2_sel),
	.tlbmiss_i(1'b0),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d0L2_wdat),
	.err_i(1'b0),
	.o(d0L2_rdat),
	.rhit(d0L2_rhita),
	.whit(d0L2_whit),
	.invall(1'b0),//invdc),
	.invline(1'b0)//d0L1_invline)
);

// For now the second data cache isn't really wired up.
DCController udcc2
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(radr),
	.rd(lrcyc),
	.wr(dcwr),
	.wsel(dcsel),
	.wadr(dcadr),
	.wdat(dcdat),
	.bstate(bstate),
	.state(),
	.invline(invdcl),
	.invlineAddr(invlineAddr),
	.icl_ctr(),
	.isROM(d1isROM),
	.ROM_dat(d1ROM_dat),
	.dL2_rhit(d1L2_rhit),
	.dL2_rdat(d1L2_rdat),
	.dL2_whit(d1L2_whit),
	.dL2_ld(d1L2_ld),
	.dL2_wsel(d1L2_sel),
	.dL2_wadr(d1L2_adr),
	.dL2_wdat(d1L2_wdat),
	.dL2_nxt(d1L2_nxt),
	.dL1_hit(d1L1_dhit),
	.dL1_selpc(d1L1_selpc),
	.dL1_sel(d1L1_sel),
	.dL1_adr(d1L1_adr),
	.dL1_dat(d1L1_dat),
	.dL1_wr(d1L1_wr),
	.dL1_invline(d1L1_invline),
	.dcnxt(d1L1_nxt),
	.dcwhich(),
	.dcl_o(),
	.cti_o(d1cti),
	.bte_o(d1bte),
	.bok_i(1'b0),
	.cyc_o(d1cyc),
	.stb_o(d1stb),
	.ack_i(d1ack_i),
	.err_i(d1err_i),
	.wrv_i(d1wrv_i),
	.rdv_i(d1rdv_i),
	.sel_o(d1sel),
	.adr_o(d1adr),
	.dat_i(dat_i)
);

L1_dcache udc3
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L1_nxt),
	.wr(d1L1_wr),
	.sel(d1L1_sel),
	.adr(d1L1_selpc ? radr : d1L1_adr),
	.i({5'd0,d1L1_dat}),
	.o(dc1_out),
	.fault(),
	.hit(d1L1_dhit),
	.invall(1'b0),//invdc),
	.invline(1'b0)//d1L1_invline)
);

L2_dcache udc4
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L2_nxt),
	.wr(d1L2_ld),
	.wadr(d1L2_adr),
	.radr(d1L1_adr),
	.sel(d1L2_sel),
	.tlbmiss_i(1'b0),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d1L2_wdat),
	.err_i(1'b0),
	.o(d1L2_rdat),
	.rhit(d1L2_rhita),
	.whit(d1L2_whit),
	.invall(1'b0),//invdc),
	.invline(1'b0)//d1L1_invline)
);

//tData aligned_data = fnDatiAlign(mem0_addr,xdati);
tData rdat0, rdat1;
//assign rdat0 = fnDataExtend(dram0_instr,dram0_unc ? aligned_data : dc0_out);
//assign rdat1 = fnDataExtend(dram1_instr,dram1_unc ? aligned_data : dc1_out);
assign dhit0a = d0L1_dhit;
assign dhit1a = d1L1_dhit;

wire [7:0] wb_fault;
wire wb_q0_done, wb_q1_done;
wire wb_has_bus;
assign dhit0 = dhit0a;// && !wb_hit0;
assign dhit1 = dhit1a;// && !wb_hit1;

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

wire wcyc, wstb, wwe;
reg wack;
wire [15:0] wsel;
wire wport;
tAddress wadr;
wire [127:0] wdat;
reg wwr0;
wire wack0;
reg [9:0] wsel0;
tAddress wadr0;
reg [79:0] wdat0;

wire wr_ack;

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
	.cwr_o(dcwr),
	.csel_o(dcsel),
	.cadr_o(dcadr),
	.cdat_o(dcdat),

	.p0_id_i(4'd0),
	.p0_rid_i(4'd0),
	.p0_wr_i(wwr0),
	.p0_ack_o(wack0),
	.p0_sel_i(wsel0),
	.p0_adr_i(wadr0),
	.p0_dat_i(wdat0),
	.p0_hit(),
	.p0_cr(),

	.p1_id_i(4'd1),
	.p1_rid_i(4'd1),
	.p1_wr_i(vwr1),
	.p1_ack_o(wack1),
	.p1_sel_i(vsel1),
	.p1_adr_i(ad1),
	.p1_dat_i(dato1),
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

  .port(wport),
	.cyc_o(wcyc),
	.stb_o(wstb),
	.ack_i(wack),
	.err_i(1'b0),
	.tlbmiss_i(1'b0),
	.wrv_i(1'b0),
	.we_o(wwe),
	.sel_o(wsel),
	.adr_o(wadr),
	.dat_o(wdat),
	.cr_o()
);

reg wcyc, wstb, rcyc, rstb;
wire ne_wcyc, ne_d0cyc, ne_d1cyc, ne_rcyc;
edge_det edw (.rst(rst), .clk(clkg), .ce(1'b1), .i(wcyc), .pe(), .ne(ne_wcyc), .ee());
edge_det edd0 (.rst(rst), .clk(clkg), .ce(1'b1), .i(d0cyc), .pe(), .ne(ne_d0cyc), .ee());
edge_det edd1 (.rst(rst), .clk(clkg), .ce(1'b1), .i(d1cyc), .pe(), .ne(ne_d1cyc), .ee());
edge_det edr (.rst(rst), .clk(clkg), .ce(1'b1), .i(rcyc), .pe(), .ne(ne_rcyc), .ee());

reg [1:0] psel;
always @(posedge clk)
if (rst)
  psel = 2'd0;
else begin
  if (!(wcyc|d0cyc|d1cyc|rcyc))
    psel = 2'd0;
  else begin
    case(psel)
    2'd0: 
      if (ne_wcyc|~wcyc) begin
        if (d0cyc)
          psel = 2'd1;
        else if (d1cyc)
          psel = 2'd2;
        else if (rcyc)
          psel = 2'd3;
      end
    2'd1:
      if (ne_d0cyc|~d0cyc) begin
        if (d1cyc)
          psel = 2'd2;
        else if (rcyc)
          psel = 2'd3;
        else if (wcyc)
          psel = 2'd0;
      end
    2'd2:
      if (ne_d1cyc|~d1cyc) begin
        if (wcyc)
          psel = 2'd0;
        else if (d1cyc)
          psel = 2'd2;
        else if (rcyc)
          psel = 2'd3;
      end
    2'd3:
      if (ne_rcyc|~rcyc) begin
        if (wcyc)
          psel = 2'd0;
        else if (d1cyc)
          psel = 2'd2;
        else if (d0cyc)
          psel = 2'd1;
      end
    endcase
  end
end

always @*
if (rst)
  cyc_o <= 1'b0;
else begin
  case(psel)
  2'd0: cyc_o = wcyc;
  2'd1: cyc_o = d0cyc;
  2'd2: cyc_o = d1cyc;
  2'd3: cyc_o = rcyc;
  endcase
end

always @*
if (rst)
  stb_o <= 1'b0;
else begin
  case(psel)
  2'd0: stb_o = wstb;
  2'd1: stb_o = d0stb;
  2'd2: stb_o = d1stb;
  2'd3: stb_o = rstb;
  endcase
end

always @*
if (rst) begin
  wack = 1'b0;
  d0ack_i = 1'b0;
  d1ack_i = 1'b0;
  rack = 1'b0;
end
else begin
  case(psel)
  2'd0: wack = ack_i;
  2'd1: d0ack_i = ack_i;
  2'd2: d1ack_i = ack_i;
  2'd3: rack = ack_i;
  endcase
end

always @*
if (rst)
  we_o <= 1'b0;
else begin
  case(psel)
  2'd0: we_o = wwe;
  2'd1: we_o = 1'b0;
  2'd2: we_o = 1'b0;
  2'd3: we_o = 1'b0;
  endcase
end

always @*
if (rst)
  sel_o <= 8'b0;
else begin
  case(psel)
  2'd0: sel_o = wsel;
  2'd1: sel_o = d0sel;
  2'd2: sel_o = d1sel;
  2'd3: sel_o = rsel;
  endcase
end

always @*
if (rst)
  adr_o <= 64'h0;
else begin
  case(psel)
  2'd0: adr_o = wadr;
  2'd1: adr_o = d0adr;
  2'd2: adr_o = d1adr;
  2'd3: adr_o = radr;
  endcase
end

always @*
if (rst)
  dat_o <= 128'h0;
else begin
  case(psel)
  2'd0: dat_o = wdat;
  // not used, d0, d1 are read only
  default:  dat_o = 128'h0;
  endcase
end

wire [31:0] wselsh = {9'h00,vwsel} << {vwa[3:0],3'b0};
wire [31:0] rselsh = {9'h00,vrsel} << {vra[3:0],3'b0};

always @(posedge clkg)
if (rst)
  rsel <= 1'b0;
else
  rsel <= ldstL ? rselsh[31:16] : rselsh[15:0];
always @(posedge clkg)
if (rst)
  wsel0 <= 1'b0;
else
  wsel0 <= ldstL ? wselsh[31:16] : wselsh[15:0];

tAddress svwa;
always @*
begin
  if (ol==2'b00)
    svwa <= vwa + {wsego[WID-1:4],16'h0};
  else
    svwa <= vwa;
end
tAddress svra;
always @*
begin
  if (ol==2'b00)
    svra <= vra + {rsego[WID-1:4],16'h0};
  else
    svra <= vra;
end

always @(posedge clkg)
if (rst)
  radr <= 64'd0;
else
  radr <= ldstL ? {svra[AMSB:4] + 2'd1,4'b0} : svra;
always @(posedge clkg)
if (rst)
  wadr0 <= 64'd0;
else
  wadr0 <= ldstL ? {svwa[AMSB:4] + 2'd1,4'b0} : svwa;
wire [255:0] vdatosh = vwdat << {vwa[3:0],3'b0};
always @(posedge clkg)
if (rst)
  wdat0 <= 128'd0;
else
  wdat0 <= ldstL ? vdatosh[255:128] : vdatosh[127:0];
always @(posedge clkg)
if (rst)
  wwr0 <= 1'b0;
else
  wwr0 <= vwr & vwstb;
always @(posedge clkg)
if (rst)
  lrcyc <= 1'b0;
else
  lrcyc <= vrcyc;

wire [255:0] datosh = wdat << {vwa[3:0],3'b0};
/*
always @(posedge clkg)
if (rst)
  dat_o <= 64'd0;
else
  dat_o <= p0_ldst5 ? {56'd0,datosh[135:128]} : p0_ldstL ? datosh[127:64] : datosh[63:0];
*/
tData dati0, dati1, dati2;
always @(posedge clkg)
  if (state==ST_LD1) begin
    if (d0L1_dhit)
      dati0 <= dc0_out;
    else if (rack)
      dati0 <= dat_i;
  end
always @(posedge clkg)
  if (state==ST_LD3) begin
    if (d0L1_dhit)
      dati1 <= dc0_out;
    else if (rack)
      dati1 <= dat_i;
  end
always @(posedge clkg)
  if (state==ST_LD5) begin
    if (d0L1_dhit)
      dati2 <= dc0_out;
    else if (rack)
      dati2 <= dat_i;
  end
always @(posedge clkg)
  if (state==ST_LD6)
    dati <= {dati2,dati1,dati0} >> {vra[2:0],3'b0};


tFloat datid;
F40ToF80 ufsd1(dati, datid);

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

muldivCnt umdc1 (rst, clk, state, po0, opcode0, funct70, fltfunc0, cnt0, cntdone0);
muldivCnt umdc2 (rst, clk, state, po1, opcode1, funct71, fltfunc1, cnt1, cntdone1);
muldivCnt umdc3 (rst, clk, state, po2, opcode2, funct72, fltfunc2, cnt2, cntdone2);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Predicate logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [63:0] p;                   // predicate register file
reg [1:0] prfwr0, prfwr1, prfwr2;
reg prfwrw0, prfwrw1, prfwrw2;
reg pres0, pres1, pres2;  // predicate result busses
reg [63:0] presw0, presw1, presw2;

/*
always @(posedge clkg)
if (rst) begin
	for (n = 0; n < 64; n = n + 1)
		p[n] <= 1'b0;
	p[0] <= 1'b1;
end
else begin
  case(prfwr0)
  2'b01: p[ir0[11:6]] <= pres0;
`ifdef SLOW
  2'b10: p[ir0[11:6]] <= p[ir0[11:6]] | pres0;
  2'b11: p[ir0[11:6]] <= p[ir0[11:6]] & pres0;
`endif
  default:  ;
  endcase
  case(prfwr1)
  2'b01: p[ir1[11:6]] <= pres1;
`ifdef SLOW
  2'b10: p[ir1[11:6]] <= p[ir1[11:6]] | pres1;
  2'b11: p[ir1[11:6]] <= p[ir1[11:6]] & pres1;
`endif
  default:  ;
  endcase
  case(prfwr2)
  2'b01: p[ir2[11:6]] <= pres2;
`ifdef SLOW
  2'b10: p[ir2[11:6]] <= p[ir2[11:6]] | pres2;
  2'b11: p[ir2[11:6]] <= p[ir2[11:6]] & pres2;
`endif
  default:  ;
  endcase
	if (prfwrw2) begin
	  for (n = 1; n < 64; n = n + 1)
	    p[n] <= presw2[n];
	end
	p[0] <= 1'b1;
end
*/
assign po0 = p[ir0[5:0]];
assign po1 = p[ir1[5:0]] && opcode0 != LDI && opcode0 != JML;
assign po2 = p[ir2[5:0]];


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
  if (state==ST_RUN && ihit && nexpatx==9'd0)
  	expatx <= expats;
  else
    expatx <= expatx << 2'd3;
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// General purpose register file
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [WID-1:0] regfile [0:63];
reg rfwr0,rfwr1,rfwr2;
reg [WID-1:0] res0, res1, res2;
`ifdef SIM
initial begin
  for (n = 0; n < 64; n = n + 1)
    regfile[n] = 0;
end
`endif
/*
always @(posedge clkg)
begin
	if (rfwr0) regfile[xRt0] <= res0;
	if (rfwr1) regfile[xRt1] <= res1;
	if (rfwr2) regfile[xRt2] <= res2;
end
*/
reg [FPWID-1:0] fpregfile [0:63];
reg fprfwr0,fprfwr1,fprfwr2;
reg [FPWID-1:0] fpres0, fpres1, fpres2;
always @(posedge clkg)
begin
	if (fprfwr0) fpregfile[xRt0] <= fpres0;
	if (fprfwr1) fpregfile[xRt1] <= fpres1;
	if (fprfwr2) fpregfile[xRt2] <= fpres2;
end


reg [WID-1:0] a0, fpa0;
reg [WID-1:0] b0, fpb0;
reg [WID-1:0] c0, fpc0;
reg [WID-1:0] s0, fps0;
reg [WID-1:0] a1, fpa1;
reg [WID-1:0] b1, fpb1;
reg [WID-1:0] c1, fpc1;
reg [WID-1:0] s1, fps1;
reg [WID-1:0] a2, fpa2;
reg [WID-1:0] b2, fpb2;
reg [WID-1:0] c2, fpc2;
reg [WID-1:0] s2, fps2;
assign a0 = Ra0==6'd0 ? 64'd0 : regfile[Ra0];
assign b0 = Rb0==6'd0 ? 64'd0 : regfile[Rb0];
assign s0 = Rt0==6'd0 ? 64'd0 : regfile[Rt0];
assign a1 = Ra1==6'd0 ? 64'd0 : regfile[Ra1];
assign b1 = Rb1==6'd0 ? 64'd0 : regfile[Rb1];
assign s1 = Rt1==6'd0 ? 64'd0 : regfile[Rt1];
assign a2 = Ra2==6'd0 ? 64'd0 : regfile[Ra2];
assign b2 = Rb2==6'd0 ? 64'd0 : regfile[Rb2];
assign s2 = Rt2==6'd0 ? 64'd0 : regfile[Rt2];
/*
assign a0 = Ra0==6'd0 ? 64'd0 : Ra0==xRt2 ? res2 : Ra0==xRt1 ? res1 : Ra0==xRt0 ? res0 : regfile[Ra0];
assign b0 = Rb0==6'd0 ? 64'd0 : Rb0==xRt2 ? res2 : Rb0==xRt1 ? res1 : Rb0==xRt0 ? res0 : regfile[Rb0];
assign s0 = Rt0==6'd0 ? 64'd0 : Rt0==xRt2 ? res2 : Rt0==xRt1 ? res1 : Rt0==xRt0 ? res0 : regfile[Rt0];
assign a1 = Ra1==6'd0 ? 64'd0 : Ra1==xRt2 ? res2 : Ra1==xRt1 ? res1 : Ra1==xRt0 ? res0 : regfile[Ra1];
assign b1 = Rb1==6'd0 ? 64'd0 : Rb1==xRt2 ? res2 : Rb1==xRt1 ? res1 : Rb1==xRt0 ? res0 : regfile[Rb1];
assign s1 = Rt1==6'd0 ? 64'd0 : Rt1==xRt2 ? res2 : Rt1==xRt1 ? res1 : Rt1==xRt0 ? res0 : regfile[Rt1];
assign a2 = Ra2==6'd0 ? 64'd0 : Ra2==xRt2 ? res2 : Ra2==xRt1 ? res1 : Ra2==xRt0 ? res0 : regfile[Ra2];
assign b2 = Rb2==6'd0 ? 64'd0 : Rb2==xRt2 ? res2 : Rb2==xRt1 ? res1 : Rb2==xRt0 ? res0 : regfile[Rb2];
assign s2 = Rt2==6'd0 ? 64'd0 : Rt2==xRt2 ? res2 : Rt2==xRt1 ? res1 : Rt2==xRt0 ? res0 : regfile[Rt2];
*/
`ifdef SLOW
assign c0 = Rc0==6'd0 ? 64'd0 : regfile[Rc0];
assign c1 = Rc1==6'd0 ? 64'd0 : regfile[Rc1];
assign c2 = Rc2==6'd0 ? 64'd0 : regfile[Rc2];

assign fpa0 = Ra0==6'd0 ? 80'd0 : fpregfile[Ra0];
assign fpb0 = Rb0==6'd0 ? 80'd0 : fpregfile[Rb0];
assign fps0 = Rt0==6'd0 ? 80'd0 : fpregfile[Rt0];
assign fpa1 = Ra1==6'd0 ? 80'd0 : fpregfile[Ra1];
assign fpb1 = Rb1==6'd0 ? 80'd0 : fpregfile[Rb1];
assign fps1 = Rt1==6'd0 ? 80'd0 : fpregfile[Rt1];
assign fpa2 = Ra2==6'd0 ? 80'd0 : fpregfile[Ra2];
assign fpb2 = Rb2==6'd0 ? 80'd0 : fpregfile[Rb2];
assign fps2 = Rt2==6'd0 ? 80'd0 : fpregfile[Rt2];

assign fpc0 = Rc0==6'd0 ? 80'd0 : fpregfile[Rc0];
assign fpc1 = Rc1==6'd0 ? 80'd0 : fpregfile[Rc1];
assign fpc2 = Rc2==6'd0 ? 80'd0 : fpregfile[Rc2];
`endif

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
    if (expatx[8])
      case(opcode2)
      LOOP: if (lc != 64'd0) lc <= lc - 2'd1;
      JMP_CTOP: if (po0 && lc != 64'd0) lc <= lc - 2'd1;
      default:  ;
      endcase
    if (expatx[7])
      case(opcode1)
      LOOP: if (lc != 64'd0) lc <= lc - 2'd1;
      JMP_CTOP: if (po1 && lc != 64'd0) lc <= lc - 2'd1;
      default:  ;
      endcase
    if (expatx[6])
      case(opcode0)
      LOOP: if (lc != 64'd0) lc <= lc - 2'd1;
      JMP_CTOP: if (po2 && lc != 64'd0) lc <= lc - 2'd1;
      default:  ;
      endcase
    // Instructions are evaluated in order so that the last MTSPR takes
    // precedence if there are two writes to the same register.
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(funct70)
  	    MTSPR:  if (ir0[`cSPR]==12'h017) lc <= s0;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(funct71)
  	    MTSPR:  if (ir1[`cSPR]==12'h017) lc <= s1;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(funct72)
  	    MTSPR:  if (ir2[`cSPR]==12'h017) lc <= s2;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
  end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Link Register
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function fnIpPlus5;
input [AMSB:0] p;
case(p[3:0])
4'h0: fnIpPlus5 = {p[AMSB:4],4'h5};
4'h5: fnIpPlus5 = {p[AMSB:4],4'hA};
4'hA: fnIpPlus5 = {p[AMSB:4]+2'd1,4'h0};
default:  ;
endcase
endfunction

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
    // branch encountered takes precedence.
    if (expatx[8])
  	  case(opcode2)
  	  LOOP: if (lc!=64'd0) lr[ir2[14:12]] <= fnIpPlus5(ip);
  	  JMP:  if (po2) lr[ir2[17:15]] <= fnIpPlus5(ip);
    	default:  ;
      endcase
    if (expatx[7])
  	  case(opcode1)
  	  LOOP: if (lc!=64'd0) lr[ir1[14:12]] <= fnIpPlus5(ip);
  	  JMP:  if (po1) lr[ir1[17:15]] <= fnIpPlus5(ip);
    	default:  ;
      endcase
    if (expatx[6])
  	  case(opcode0)
  	  LOOP: if (lc!=64'd0) lr[ir0[14:12]] <= fnIpPlus5(ip);
  	  JMP:  if (po0) lr[ir0[17:15]] <= fnIpPlus5(ip);
  	  JML:  if (po0) lr[ir0[17:15]] <= {ip[AMSB:4],4'hA};  // JML is aligned at 128-bit boundary
    	default:  ;
      endcase

    // Instructions are evaluated in order so that the last MTSPR takes
    // precedence if there are two writes to the same register.
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(funct70)
  	    MTSPR:  if (ir0[23:15]==9'b000_000_100) lr[ir0[14:12]] <= s0;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(funct71)
  	    MTSPR:  if (ir1[23:15]==9'b000_000_100) lr[ir1[14:12]] <= s1;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(funct72)
  	    MTSPR:  if (ir2[23:15]==9'b000_000_100) lr[ir2[14:12]] <= s2;
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
reg [AMSB:0] brdisp0;
reg [AMSB:0] brdisp1;
reg [AMSB:0] brdisp2;
assign brdisp0 = {{40{ir0[33]}},ir0[33:12],ir0[13:12]};
assign brdisp1 = {{40{ir1[33]}},ir1[33:12],ir1[13:12]};
assign brdisp2 = {{40{ir2[33]}},ir2[33:12],ir2[13:12]};

always @(posedge clkg)
if (rst)
  ip <= 64'hFFFFFFFFFFFC0000;
else begin
  if (state==ST_RUN && ihit) begin
  	if (nexpatx==9'd0) begin
  		ip[31:4] <= ip[31:4] + 28'd1;
  		ip[3:0] <= 4'h0;
  	end
  	if (expatx[8])
  	  case(opcode2)
  	  R2:
  	    case(funct72)
    		RET:	if (po2) ip <= lr[ir2[20:18]] + ir2[32:21];
  	    default: ;
  	    endcase
  	  LOOP: if (lc != 64'd0) ip <= brdisp2 + lr[ir2[17:15]];
  	  JMP:  if (po2) ip <= brdisp2 + lr[ir2[17:15]];
    	default:  ;
      endcase
  	if (expatx[7])
  	  case(opcode1)
  	  R2:
  	    case(funct71)
    		RET:	if (po1) ip <= lr[ir1[20:18]] + ir1[32:21];
  	    default: ;
  	    endcase
  	  LOOP: if (lc != 64'd0) ip <= brdisp1 + lr[ir1[17:15]];
  	  JMP:  if (po1) ip <= brdisp1 + lr[ir1[17:15]];
    	default:  ;
      endcase
  	if (expatx[6])
  	  case(opcode0)
  	  R2:
  	    case(funct70)
    		RET:	if (po0) ip <= lr[ir0[20:18]] + ir0[32:21];
  	    default: ;
  	    endcase
  	  LOOP: if (lc != 64'd0) ip <= brdisp0 + lr[ir0[17:15]];
  	  JMP:  if (po0) ip <= brdisp0 + lr[ir0[17:15]];
    	JML:  if (po0) ip <= {ir1,brdisp0[23:0]} + lr[ir0[17:15]];
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
  begin
  	if (nexpatx==9'd0)
  		ir <= insn;
  end
  if (state==ST_RUN && ihit) begin
    // Note instructions are evaluated in reverse order so that the first
    // branch encountered takes precednce.
    if (expatx[8])
  	  case(opcode2)
  	  R2:
  	    if (po2)
    	    case(funct72)
      		RET:	ir[122:0] <= {3{NOP_INSN}};
      		default:  ;
      	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  if (po2) ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
    if (expatx[7])
  	  case(opcode1)
  	  R2:
  	    if (po1)
    	    case(funct71)
      		RET:	ir[122:0] <= {3{NOP_INSN}};
      		default:  ;
      	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  if (po1) ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
    if (expatx[6])
  	  case(opcode0)
  	  R2:
  	    if (po0)
    	    case(funct70)
      		RET:	ir[122:0] <= {3{NOP_INSN}};
      		default:  ;
      	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  if (po0) ir[122:0] <= {3{NOP_INSN}};
  	  JML:  if (po0) ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
  end
end


wire [63:0] imm0 = {{64{ir0[33]}},ir0[33:18]};
wire [63:0] imm1 = {{64{ir1[33]}},ir1[33:18]};
wire [63:0] imm2 = {{64{ir2[33]}},ir2[33:18]};

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

tFloat fmao0, fmao1, fmao2;
wire [2:0] fprm0 = ir0[33:31]==3'b111 ? fprm : ir0[33:31];
wire [2:0] fprm1 = ir1[33:31]==3'b111 ? fprm : ir1[33:31];
wire [2:0] fprm2 = ir2[33:31]==3'b111 ? fprm : ir2[33:31];

fpFMAnr #(FPWID) ufma1
(
  .clk(clkg),
  .ce(1'b1),
  .op(opcode1[0]),
  .rm(fprm1),
  // Flip MSB for negate for FNMADD / FNMSUB
  .a(fpa1 ^ {{FPWID-1{1'b0}},opcode1[1]} << (FPWID-1)),
  .b(fpb1),
  .c(fpc1),
  .o(fmao1),
  .inf(),
  .zero(),
  .overflow(),
  .underflow(),
  .inexact()
);

fpFMAnr #(FPWID) ufma2
(
  .clk(clkg),
  .ce(1'b1),
  .op(opcode2[0]),
  .rm(fprm2),
  // Flip MSB for negate for FNMADD / FNMSUB
  .a(fpa2 ^ {{FPWID-1{1'b0}},opcode2[1]} << (FPWID-1)),
  .b(fpb2),
  .c(fpc2),
  .o(fmao2),
  .inf(),
  .zero(),
  .overflow(),
  .underflow(),
  .inexact()
);


wire fpcmpo0, fpcmpo1, fpcmpo2;
wire nanxab0, nanxab1, nanxab2;
fpCompare #(FPWID) ufpcmp0 (.a(fpa0), .b(fpb0), .o(fpcmpo0), .nan(), .snan());
fpCompare #(FPWID) ufpcmp1 (.a(fpa1), .b(fpb1), .o(fpcmpo1), .nan(), .snan() );
fpCompare #(FPWID) ufpcmp2 (.a(fpa2), .b(fpb2), .o(fpcmpo2), .nan(), .snan() );
wire fpa0_xz, fpa0_vz, fpa0_inf, fpa0_qnan, fpa0_snan, fpa0_nan, fpa0_xinf;
wire fpa1_xz, fpa1_vz, fpa1_inf, fpa1_qnan, fpa1_snan, fpa1_nan, fpa1_xinf;
wire fpa2_xz, fpa2_vz, fpa2_inf, fpa2_qnan, fpa2_snan, fpa2_nan, fpa2_xinf;
fpDecomp #(FPWID) ufpdc0 (.i(fpa0), .sgn(), .exp(), .man(), .fract(), .xz(fpa0_xz), .mz(), .vz(fpa0_vz), .inf(fpa0_inf), .xinf(fpa0_xinf), .qnan(fpa0_qnan), .snan(fpa0_snan), .nan(fpa0_nan));
fpDecomp #(FPWID) ufpdc1 (.i(fpa1), .sgn(), .exp(), .man(), .fract(), .xz(fpa1_xz), .mz(), .vz(fpa1_vz), .inf(fpa1_inf), .xinf(fpa1_xinf), .qnan(fpa1_qnan), .snan(fpa1_snan), .nan(fpa1_nan));
fpDecomp #(FPWID) ufpdc2 (.i(fpa2), .sgn(), .exp(), .man(), .fract(), .xz(fpa2_xz), .mz(), .vz(fpa2_vz), .inf(fpa2_inf), .xinf(fpa2_xinf), .qnan(fpa2_qnan), .snan(fpa2_snan), .nan(fpa2_nan));
tFloat trunco0,trunco1,trunco2;
tFloat i2fo0,i2fo1,i2fo2;
i2f #(FPWID)  ui2fs0 (.clk(clk), .ce(1'b1), .rm(fprm0), .i(a0[WID-1:0]), .o(i2fo0) );
i2f #(FPWID)  ui2fs1 (.clk(clk), .ce(1'b1), .rm(fprm1), .i(a1[WID-1:0]), .o(i2fo1) );
i2f #(FPWID)  ui2fs2 (.clk(clk), .ce(1'b1), .rm(fprm2), .i(a2[WID-1:0]), .o(i2fo2) );
f2i #(FPWID)  uf2is0 (.clk(clk), .ce(1'b1), .i(fpa0), .o(f2io0) );
f2i #(FPWID)  uf2is1 (.clk(clk), .ce(1'b1), .i(fpa1), .o(f2io1) );
f2i #(FPWID)  uf2is2 (.clk(clk), .ce(1'b1), .i(fpa2), .o(f2io2) );
fpTrunc #(FPWID) urho1 (.clk(clk), .ce(1'b1), .i(fpa0), .o(trunco0), .overflow());
fpTrunc #(FPWID) urho2 (.clk(clk), .ce(1'b1), .i(fpa1), .o(trunco1), .overflow());
fpTrunc #(FPWID) urho3 (.clk(clk), .ce(1'b1), .i(fpa2), .o(trunco2), .overflow());
reg fpdivld;
tFloat fpdivo0, fpdivo1, fpdivo2;
`ifdef SLOW
fpDivnr #(FPWID) ufpdiv0 (
  .rst(rst),
  .clk(clkg),
  .clk4x(1'b0),
  .ce(1'b1),
  .ld(fpdivld),
  .op(1'b0),
  .a(fpa0),
  .b(fpb0),
  .o(fpdivo0),
  .rm(),
  .done(),
  .sign_exe(),
  .inf(),
  .overflow(),
  .underflow()
);
fpDivnr #(FPWID) ufpdiv1 (
  .rst(rst),
  .clk(clkg),
  .clk4x(1'b0),
  .ce(1'b1),
  .ld(fpdivld),
  .op(1'b0),
  .a(fpa1),
  .b(fpb1),
  .o(fpdivo1),
  .rm(),
  .done(),
  .sign_exe(),
  .inf(),
  .overflow(),
  .underflow()
);
fpDivnr #(FPWID) ufpdiv2 (
  .rst(rst),
  .clk(clkg),
  .clk4x(1'b0),
  .ce(1'b1),
  .ld(fpdivld),
  .op(1'b0),
  .a(fpa2),
  .b(fpb2),
  .o(fpdivo2),
  .rm(),
  .done(),
  .sign_exe(),
  .inf(),
  .overflow(),
  .underflow()
);
`endif

function [47:0] fnDisassem;
input [40:0] iri;
begin
  case(iri[40:34])
  R2:
    case(iri[33:27])
    ADD:  fnDisassem = "ADDI  ";
    AND:  fnDisassem = "ANDI  ";
    OR:   fnDisassem = "ORI   ";
    CEQ:  fnDisassem = "CEQ   ";
    CNE:  fnDisassem = "CNE   ";
    RET:  fnDisassem = "RET   ";
    LDD:  fnDisassem = "LDDX  ";
    STD:  fnDisassem = "STDX  ";
    default:  fnDisassem = "????? ";
    endcase
  ADD:  fnDisassem = "ADDI  ";
  AND:  fnDisassem = "ANDI  ";
  OR:   fnDisassem = "ORI   ";
  ORIS: fnDisassem = "ORIS  ";
  CEQ:  fnDisassem = "CEQI  ";
  CNE:  fnDisassem = "CNEI  ";
  JMP:  fnDisassem = "JMP   ";
  LDD:  fnDisassem = "LDD   ";
  STD:  fnDisassem = "STD   ";
  default:  fnDisassem = "????? ";
  endcase
end
endfunction

function [23:0] fnPreg;
input [5:0] rn;
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
    4'd16:  fnPreg = "p16";
    4'd17:  fnPreg = "p17";
    4'd18:  fnPreg = "p18";
    4'd19:  fnPreg = "p19";
    4'd20:  fnPreg = "p20";
    4'd21:  fnPreg = "p21";
    4'd22:  fnPreg = "p22";
    4'd23:  fnPreg = "p23";
    4'd24:  fnPreg = "p24";
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
	//ST_FETCH: state <= ST_RUN;
	ST_RUN: 
	  if (ihit) begin
  		if (expatx[8] & po2) tExecSt(ir2,ST_LD2);
  		if (expatx[7] & po1) tExecSt(ir1,ST_LD1);
  		if (expatx[6] & po0) tExecSt(ir0,ST_LD0);
		end
	ST_LD1: if (rcyc ? rack : d0L1_dhit) state <= ST_LD2;
`ifdef SLOW
	ST_LD2: if (rcyc ? ~rack : 1'b1) state <= ST_LD6;
`else
	ST_LD2: if (rcyc ? ~rack : 1'b1) state <= selsh[31:16] ? ST_LD3 : ST_LD6;
	ST_LD3: if (rcyc ? rack : d0L1_dhit) state <= ST_LD6;
`endif
	ST_LD6: state <= ST_LD7;
	ST_LD7: state <= ST_RUN;
`ifdef SLOW
	ST_ST1:	if (wack) begin state <= |wselsh[31:16] ? ST_ST2 : ST_RUN; end
	ST_ST2: if (~wack) state <= ST_ST3;
	ST_ST3: if (wack) state <= ST_RUN;
`else
	ST_ST1:	if (wack) begin state <= ST_RUN; end
`endif
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
	rfwr0 = 1'b0; prfwr0 = 2'b00; prfwrw0 = 1'b0;
	rfwr1 = 1'b0; prfwr1 = 2'b00; prfwrw1 = 1'b0;
	rfwr2 = 1'b0; prfwr2 = 2'b00; prfwrw2 = 1'b0;
	vwcyc = 1'b0; vwstb = 1'b0;
	vrcyc = 1'b0; vrstb = 1'b0;
	vwr = 1'b0;
	rd = 1'b0;
	ld0 = 1'b0; ld1 = 1'b0; ld2 = 1'b0;
	for (n = 0; n < 64; n = n + 1)
	  p[n] = 1'b0;
	p[0] = 1'b1;
end
else begin
	rfwr0 = 1'b0; prfwr0 = 2'b00; prfwrw0 = 1'b0;
	rfwr1 = 1'b0; prfwr1 = 2'b00; prfwrw1 = 1'b0;
	rfwr2 = 1'b0; prfwr2 = 2'b00; prfwrw2 = 1'b0;
	ld0 = 1'b0; ld1 = 1'b0; ld2 = 1'b0;
	case(state)
	ST_RUN: 
	  if (ihit) begin
  		if (expatx[6]) 
  		  begin
  		    xRt0 = Rt0;
  		    case(opcode0)
  		    `cFLOAT2: if (po0) tFloat2(2'b00,ir0,fpa0,fpb0,fpres0,fprfwr0,res0,rfwr0,pres0,prfwr0);
  		    default:  
  		      tExec(ir0,a0,b0,c0,s0,po0,res0,pres0,rfwr0,prfwr0,ld0,presw0,prfwrw0);
  		    endcase
  		  end
  		if (expatx[7])
  		  begin
  		    xRt1 = Rt1;
  		    case(opcode1)
  		    `cFLOAT2: if (po1) tFloat2(2'b01,ir1,fpa1,fpb1,fpres1,fprfwr1,res1,rfwr1,pres1,prfwr1);
  		    default:
  		      tExec(ir1,a1,b1,c1,s1,po1,res1,pres1,rfwr1,prfwr1,ld1,presw1,prfwrw1);
  		    endcase
  		  end
  		if (expatx[8])
  		  begin
  		    xRt2 = Rt2;
  		    case(opcode2)
  		    `cFLOAT2: if (po2) tFloat2(2'b10,ir2,fpa2,fpb2,fpres2,fprfwr2,res2,rfwr2,pres2,prfwr2);
  		    default:
  		      tExec(ir2,a2,b2,c2,s2,po2,res2,pres2,rfwr2,prfwr2,ld2,presw2,prfwrw2);
  		    endcase
  		  end
  		if (opcode0==LDI) begin if (po0) begin regfile[Rt0] = {ir1,ir0[33:12]}; rfwr0 = 1'b1; end end
  		else if (opcode1==LDI) begin if (po1) begin regfile[Rt1] = {ir2,ir1[33:12]}; rfwr1 = 1'b1; end end
		end
	ST_LD1: if (rcyc ? rack : d0L1_dhit) begin vrcyc = |rselsh[31:16]; vrstb = 1'b0; end
	ST_LD2: if (rcyc ? ~rack : 1'b1) vrstb = 1'b1;
	ST_LD3: if (rcyc ? rack : d0L1_dhit) begin vrcyc = 1'b0; vrstb = 1'b0; end
  ST_LD7:
    case(ldopcode)
    `cR2:
      case(ldfunc)
`ifdef SLOW        
      `cLDB:  begin regfile[Rt0] = {{56{dati[7]}},dati[7:0]}; rfwr0 = 1'b1; end
      `cLDH:  begin regfile[Rt0] = {{48{dati[15]}},dati[15:0]}; rfwr0 = 1'b1; end
      `cLDW:  begin regfile[Rt0] = {{32{dati[31]}},dati[31:0]}; rfwr0 = 1'b1; end
      `cLDBU: begin regfile[Rt0] = {56'd0,dati[7:0]}; rfwr0 = 1'b1; end
      `cLDHU: begin regfile[Rt0] = {48'd0,dati[15:0]}; rfwr0 = 1'b1; end
      `cLDWU: begin regfile[Rt0] = {32'd0,dati[31:0]}; rfwr0 = 1'b1; end
      `cLDFS: begin fpregfile[Rt0] = datid; fprfwr0 = 1'b1; end
`endif
      `cLDD:  begin regfile[Rt0] = dati; rfwr0 = 1'b1; end
      `cLDFD: begin fpregfile[Rt0] = dati; fprfwr0 = 1'b1; end
      endcase
`ifdef SLOW      
    `cLDB:  begin regfile[Rt0] = {{56{dati[7]}},dati[7:0]}; rfwr0 = 1'b1; end
    `cLDH:  begin regfile[Rt0] = {{48{dati[15]}},dati[15:0]}; rfwr0 = 1'b1; end
    `cLDW:  begin regfile[Rt0] = {{32{dati[31]}},dati[31:0]}; rfwr0 = 1'b1; end
    `cLDBU: begin regfile[Rt0] = {56'd0,dati[7:0]}; rfwr0 = 1'b1; end
    `cLDHU: begin regfile[Rt0] = {48'd0,dati[15:0]}; rfwr0 = 1'b1; end
    `cLDWU: begin regfile[Rt0] = {32'd0,dati[31:0]}; rfwr0 = 1'b1; end
    `cLDFS: begin fpregfile[Rt0] = datid; fprfwr0 = 1'b1; end
`endif
    `cLDD:  begin regfile[Rt0] = dati; rfwr0 = 1'b1; end
    `cLDFD: begin fpregfile[Rt0] = dati; fprfwr0 = 1'b1; end
    endcase
	ST_ST1:	if ( wack) begin vwr = |wselsh[31:16]; vwcyc = |wselsh[31:16]; vwstb = 1'b0; end
`ifdef SLOW
	ST_ST2: if (~wack) begin vwstb = 1'b1; end
	ST_ST3:	if ( wack) begin vwr = 1'b0; vwcyc = 1'b0; vwstb = 1'b0; end
`endif
	ST_MULDIV:
	  if (cntdone0&cntdone1&cntdone2) begin
	    case({mul0,mulu0,div0,divu0,fmadd0|fmsub0|fnmadd0|fnmsub0,fcvt0,ftrunc0,fdiv0})
	    8'b1???????:  begin regfile[Rt0] = prod0;  rfwr0 = 1'b1;  end
	    8'b01??????:  begin regfile[Rt0] = produ0; rfwr0 = 1'b1; end
	    8'b001?????:  begin regfile[Rt0] = quot0;  rfwr0 = 1'b1; end
	    8'b0001????:  begin regfile[Rt0] = quot0;  rfwr0 = 1'b1; end
	    8'b00001???:  begin fpregfile[Rt0] = fmao0; fprfwr0 = 1'b1; end
	    8'b000001??:  begin
	                  case(ir0[23:18])
	                  `cI2F: fprfwr0 = 1'b1;
	                  `cF2I: rfwr0 = 1'b1;
	                  endcase
	                end
	    8'b0000001?: begin fpregfile[Rt0] = trunco0; fprfwr0 = 1'b1; end
	    8'b00000001: begin fpregfile[Rt0] = fpdivo0; fprfwr0 = 1'b1; end
	    default:  ; // hardware error, got to MULDIV state and no mul/div decoded.
	    endcase
	    case({mul1,mulu1,div1,divu1,fmadd1|fmsub1|fnmadd1|fnmsub1,fcvt1,ftrunc1,fdiv1})
	    8'b1???????:  begin regfile[Rt1] = prod1;  rfwr1 = 1'b1; end
	    8'b01??????:  begin regfile[Rt1] = produ1; rfwr1 = 1'b1; end
	    8'b001?????:  begin regfile[Rt1] = quot1;  rfwr1 = 1'b1; end
	    8'b0001????:  begin regfile[Rt1] = quot1;  rfwr1 = 1'b1; end
	    8'b00001???:  begin fpregfile[Rt1] = fmao1; fprfwr1 = 1'b1; end
	    8'b000001??:  begin
	                  case(ir1[23:18])
	                  `cI2F: fprfwr1 = 1'b1;
	                  `cF2I: rfwr1 = 1'b1;
	                  endcase
	                end
	    8'b0000001?: begin fpregfile[Rt1] = trunco1; fprfwr1 = 1'b1; end
	    8'b00000001: begin fpregfile[Rt1] = fpdivo1; fprfwr1 = 1'b1; end
	    default:  ;
	    endcase
	    case({mul2,mulu2,div2,divu2,fmadd2|fmsub2|fnmadd2|fnmsub2,fcvt2,ftrunc2,fdiv2})
	    8'b1???????:  begin regfile[Rt2] = prod2;  rfwr2 = 1'b1; end
	    8'b01??????:  begin regfile[Rt2] = produ2; rfwr2 = 1'b1; end
	    8'b001?????:  begin regfile[Rt2] = quot2;  rfwr2 = 1'b1; end
	    8'b0001????:  begin regfile[Rt2] = quot2;  rfwr2 = 1'b1; end
	    8'b00001???: begin fpregfile[Rt2] = fmao2; fprfwr2 = 1'b1; end
	    8'b000001??:  begin
	                  case(ir2[23:18])
	                  `cI2F: fprfwr2 = 1'b1;
	                  `cF2I: rfwr2 = 1'b1;
	                  endcase
	                end
	    8'b0000001?: begin fpregfile[Rt2] = trunco2; fprfwr2 = 1'b1; end
	    8'b00000001: begin fpregfile[Rt2] = fpdivo2; fprfwr2 = 1'b1; end
	    default:  ;
	    endcase
	  end
	default:	;
	endcase
	$display("------------------------------------");
	$display("ip: %h  ir: %h", ip, ir);
	$display("%c%h %s %s %h %h %h %h: %d %d %d %d", ir[123]?"S":"-",ir0,fnPreg(ir0[5:0]),fnDisassem(ir0),imm0, s0, a0, b0, Rt0, Ra0, Rb0, Rc0);
	$display("%c%h %s %s %h %h %h %h: %d %d %d %d", ir[124]?"S":"-",ir1,fnPreg(ir1[5:0]),fnDisassem(ir1),imm1, s1, a1, b1, Rt1, Ra1, Rb1, Rc1);
	$display("%c%h %s %s %h %h %h %h: %d %d %d %d", ir[125]?"S":"-",ir2,fnPreg(ir2[5:0]),fnDisassem(ir2),imm2, s2, a2, b2, Rt2, Ra2, Rb2, Rc2);
end

task tCmp;
input [5:0] Rt;
input [6:0] opcode;
input [2:0] op3;
input [WID-1:0] a;
input [WID-1:0] b;
input pi;
output [1:0] prfwr;
reg [WID:0] sum;
reg o;
begin
  case(opcode)
  `cCLT:  o = $signed(a) <  $signed(b);
  `cCGE:  o = $signed(a) >= $signed(b);
  `cCLE:  o = $signed(a) <= $signed(b);
  `cCGT:  o = $signed(a) >  $signed(b);
  `cCLTU: o = a <  b;
  `cCGEU: o = a >= b;
  `cCLEU: o = a <= b;
  `cCGTU: o = a >  b;
  `cCEQ:  o = a == b;
  `cCNE:  o = a != b;
`ifdef SLOW
  `cINTERSECT:  o = |(a & b);
  `cUNION:      o = |(a | b);
  `cDISJOINT:   o = |(a ^ b);
`endif
  default:  o = 1'b0;
  endcase
  case(op3)
  3'd0: if (pi) p[Rt] = o;
`ifdef SLOW
  3'b1:
    if (pi & o)
      p[Rt] = o;
    else
      p[Rt] = 1'b0;
  3'd2: if (pi &  o) p[Rt] = p[Rt] | o;
  3'd3: if (pi &  o) p[Rt] = p[Rt] & o;
  3'd4: if (pi & ~o) p[Rt] = p[Rt] | o;
  3'd5: if (pi & ~o) p[Rt] = p[Rt] & o;
`endif
  default:  ;
  endcase
  p[0] = 1'b1;
/*
  case(op3)
  3'd0: prfwr = pi ? 2'b01 : 2'b00;
`ifdef SLOW
  3'b1:
    if (pi & o)
      prfwr = 2'b01;
    else begin
      o = 1'b0;
      prfwr = 2'b01;
    end
  3'd2: prfwr = (pi & o) ? 2'b10 : 2'b00;
  3'd3: prfwr = (pi & o) ? 2'b11 : 2'b00;
  3'd4: prfwr = o ? 2'b00 : pi ? 2'b10 : 2'b00;
  3'd5: prfwr = o ? 2'b00 : pi ? 2'b11 : 2'b00;
`endif
  default:  prfwr = 2'b00;
  endcase
*/
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
reg [5:0] Rt;
begin
  Rt = irx[11:6];
	case(op)
	`cADD:	begin regfile[Rt] = a + b; rfwr = 1'b1; end
	`cSUB:	begin regfile[Rt] = a - b; rfwr = 1'b1; end
	`cAND:	begin regfile[Rt] = a & b; rfwr = 1'b1; end
	`cOR:		begin regfile[Rt] = a | b; rfwr = 1'b1; end
	`cEOR:	begin regfile[Rt] = a ^ b; rfwr = 1'b1; end
	`cANDCM:begin regfile[Rt] = a & ~b; rfwr = 1'b1; end
	`cNAND:	begin regfile[Rt] = ~(a & b); rfwr = 1'b1; end
	`cNOR:	begin regfile[Rt] = ~(a | b); rfwr = 1'b1; end
	`cENOR:	begin regfile[Rt] = ~(a ^ b); rfwr = 1'b1; end
	`cORCM:	begin regfile[Rt] = a | ~b; rfwr = 1'b1; end
	`cDIV:  begin ld = 1'b1; end
	`cDIVU: begin ld = 1'b1; end
	SHL:	begin regfile[Rt] = a << b[5:0]; rfwr = 1'b1; end
	SHR:	begin regfile[Rt] = a >> b[5:0]; rfwr = 1'b1;  end
	ASR:	begin regfile[Rt] = a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; rfwr = 1'b1; end
	SHLI:	begin regfile[Rt] = a << b[5:0]; rfwr = 1'b1; end
	SHRI:	begin regfile[Rt] = a >> b[5:0]; rfwr = 1'b1; end
	ASRI:	begin regfile[Rt] = a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; rfwr = 1'b1; end
	default:	;
	endcase
end endtask

task tExec;
input [40:0] irx;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] c;
input [WID-1:0] s;
input po;
output [WID-1:0] res;
output [1:0] pres;
output rfwr;
output [1:0] prfwr;
output ld;
output [31:0] presw;
output prfwrw;
reg [5:0] Rt;
reg [6:0] opcode;
reg [WID-1:0] imm;
reg Sc;
reg isFloat;
reg [WID*2-1:0] res1;
begin
  rfwr = 1'b0;
  Rt = irx[11:6];
	opcode = irx[40:34];
	isFloat = opcode >= 7'd112 && opcode <= 7'd121;
  casez(opcode)
  `cAND:  imm = {{50{1'b1}},irx[33:18]};
  `cOR:   imm = {50'd0,irx[33:18]};
  `cEOR:  imm = {50'd0,irx[33:18]};
  `cSHLP: imm = {58'd0,irx[29:24]};
  `cSHRP: imm = {58'd0,irx[29:24]};
  CMPI: imm = {{53{irx[30]}},irx[30:18]};
  default:  imm = {{50{irx[33]}},irx[33:18]};
  endcase
  Sc = irx[24];
	casez(opcode)
	RR:
		casez(irx[33:27])
		CMP:	tCmp(Rt,irx[33:27],irx[26:24],a,b,po,prfwr);
`ifdef SLOW
		`cSHLP: if (po) begin res1 = {a,b} << (irx[33] ? imm[5:0] : c[5:0]); regfile[Rt] = res1[127:64]; rfwr = 1'b1; end
		`cSHRP: if (po) begin regfile[Rt] = {b,a} >> (irx[33] ? imm[5:0] : c[5:0]); rfwr = 1'b1; end
`else
		`cSHLP: if (po) begin res1 = {a,b} << imm[5:0]; regfile[Rt] = res1[127:64]; rfwr = 1'b1; end
		`cSHRP: if (po) begin regfile[Rt] = {b,a} >> imm[5:0]; rfwr = 1'b1; end
`endif
		ASRI: if (po) tAlu(irx,opcode,a,imm,res,rfwr,ld);
		MFSPR:
		  if (po) begin
  		  case(irx[23:12])
  		  12'h001:  begin regfile[Rt] = hartid; rfwr = 1'b1; end
  		  12'h002:  begin regfile[Rt] = tick; rfwr = 1'b1; end
  		  12'h020,12'h021,12'h022,12'h023,12'h024,12'h025,12'h026,12'h027:
  		    begin regfile[Rt] = lr[irx[23:21]]; rfwr = 1'b1; end
  		  12'h016: 
  		    begin
  		      for (n = 1; n < 64; n = n + 1)
  		        regfile[Rt][n] = p[n];
  		      regfile[Rt][0] = 1'b1;
          end
        12'h17: begin regfile[Rt] <= lc; rfwr = 1'b1; end
  		  12'h060,12'h061,12'h062,12'h063,12'h064,12'h065,12'h066,12'h067:  begin regfile[Rt] = sego1; rfwr = 1'b1; end
  		  default:  ;
  		  endcase
		  end
		MTSPR:
		  if (po) 
  		  case(irx[23:12])
  		  12'h016:
  		    begin
         	  for (n = 1; n < 64; n = n + 1)
         	    p[n] <= s[n];
         	  p[0] = 1'b1;
  		    end
  		    //presw = s[31:0]; prfwrw = 1'b1; end
  		  default:  ;
  		  endcase
`ifdef SLOW
  	`cLDB:	if (po) begin vra = a + b; vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h001; ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDH:	if (po) begin vra = a + (b << Sc); vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h003;  ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDW:	if (po) begin vra = a + (b << {Sc,1'b0}); vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h00F;  ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDBU:	if (po) begin vra = a + b; vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h001; ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDHU:	if (po) begin vra = a + (b << Sc); vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h003;  ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDWU:	if (po) begin vra = a + (b << {Sc,1'b0}); vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h00F;  ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDFS:	if (po) begin vra = a + Sc ? {b,3'b0} + {b,1'b0} : b; vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h01F;  ldopcode = opcode; ldfunc = irx[33:27]; end
`endif
  	`cLDD:	if (po) begin vra = a + (b << {Sc,2'b0}); vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h0FF;  ldopcode = opcode; ldfunc = irx[33:27]; end
  	`cLDFD:	if (po) begin vra = a + Sc ? {b,3'b0} + {b,1'b0} : b; vrcyc = 1'b1; vrstb = 1'b1; vrsel <= 10'h3FF;  ldopcode = opcode; ldfunc = irx[33:27]; end
`ifdef SLOW
  	`cSTB:	if (po) begin vwa = a + b; vwdat = s; vwr = 1'b1; vwsel <= 10'h001; vwcyc = 1'b1; vwstb = 1'b1; end
  	`cSTH:	if (po) begin vwa = a + (b << Sc); vwdat = s; vwr = 1'b1; vwsel <= 10'h003; vwcyc = 1'b1; vwstb = 1'b1; end
  	`cSTW:	if (po) begin vwa = a + (b << {Sc,1'b0}); vwdat = s; vwr = 1'b1; vwsel <= 10'h00F; vwcyc = 1'b1; vwstb = 1'b1; end
`endif
  	`cSTD:	if (po) begin vwa = a + (b << {Sc,2'b0}); vwdat = s; vwr = 1'b1; vwcyc = 1'b1; vwsel <= 10'h0FF; vwstb = 1'b1; end
  	`cSTFD:	if (po) begin vwa = a + Sc ? {b,3'b0} + {b,1'b0} : b; vwdat = s; vwr = 1'b1; vwcyc = 1'b1; vwstb = 1'b1; vwsel <= 10'h0FF; end
		default:	if (po) tAlu(irx,irx[33:27],a,b,res,rfwr,ld);
		endcase
	ADDIS:  if (po) begin regfile[Rt] = s + {{30{irx[33]}},irx[33:12],16'd0}; rfwr = 1'b1; end 
	ANDIS:  if (po) begin regfile[Rt] = s & {{30{1'b1}},irx[33:12],16'h3FFF}; rfwr = 1'b1; end
	ORIS:   if (po) begin regfile[Rt] = s | {30'd0,irx[33:12],16'd0}; rfwr = 1'b1; end
	XORIS:  if (po) begin regfile[Rt] = s ^ {30'd0,irx[33:12],16'd0}; rfwr = 1'b1; end
`ifdef SLOW
	`cLDB:	if (po) begin vra = a + imm; vrsel = 10'h001; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDH:  if (po) begin vra = a + imm; vrsel = 10'h003; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDW:  if (po) begin vra = a + imm; vrsel = 10'h00F; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDBU: if (po) begin vra = a + imm; vrsel = 10'h001; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDHU: if (po) begin vra = a + imm; vrsel = 10'h003; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDWU:	if (po) begin vra = a + imm; vrsel = 10'h00F; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDFS: if (po) begin vra = a + imm; vrsel = 10'h01F; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
`endif
	`cLDD:  if (po) begin vra = a + imm; vrsel = 10'h0FF; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
	`cLDFD: if (po) begin vra = a + imm; vrsel = 10'h3FF; vrcyc = 1'b1; vrstb = 1'b1; ldopcode = opcode; end
`ifdef SLOW
	`cSTB:	if (po) begin vwa = a + imm; vwdat = s; vwr = 1'b1; vwsel = 10'h001; vwcyc = 1'b1; vwstb = 1'b1; end
	`cSTH:	if (po) begin vwa = a + imm; vwdat = s; vwr = 1'b1; vwsel = 10'h003; vwcyc = 1'b1; vwstb = 1'b1; end
	`cSTW:	if (po) begin vwa = a + imm; vwdat = s; vwr = 1'b1; vwsel = 10'h00F; vwcyc = 1'b1; vwstb = 1'b1; end
`endif
	`cSTD:	if (po) begin vwa = a + imm; vwdat = s; vwr = 1'b1; vwsel = 10'h0FF; vwcyc = 1'b1; vwstb = 1'b1; end
	`cSTFD: if (po) begin vwa = a + imm; vwdat = s; vwr = 1'b1; vwsel = 10'h3FF; vwcyc = 1'b1; vwstb = 1'b1; end
	CMPI:   tCmp(Rt,opcode,irx[33:31],a,imm,po,prfwr);
	`cFDIV: if (po) begin fpdivld = 1'b1; end
	default:	if (po) tAlu(irx,opcode,a,imm,res,rfwr,ld);
	endcase
end
endtask

task tFloat2;
input [1:0] which;
input [40:0] irx;
input tFloat fpa;
input tFloat fpb;
output tFloat fpres;
output fprfwr;
output [WID-1:0] res;
output rfwr;
output pres;
output prfwr;
reg [5:0] Rt;
reg fpa_nan;
reg fpa_xinf;
reg fpa_inf;
reg fpa_xz;
reg fpa_vz;
reg fpa_qnan;
reg fpa_snan;
begin
  Rt = irx[11:6];
  fpa_nan = &fpa.exp & |fpa.man;
  fpa_xinf = &fpa.exp;
  fpa_inf = &fpa.exp & ~|fpa.man;
  fpa_xz = ~|fpa.exp;
  fpa_vz = ~|fpa.exp & ~|fpa.man;
  fpa_qnan = &fpa.exp & fpa.man[FMSB];
  fpa_snan = &fpa.exp & ~fpa.man[FMSB] & |fpa.man;
  case(irx[30:24])
  `cFCLT,`cFCGE,`cFCLE,`cFCGT,`cFCEQ,`cFCNE,`cFCUN: 
    case(which)
    2'd0: begin pres = fpcmpo0; prfwr = 1'b1; end
    2'd1: begin pres = fpcmpo1; prfwr = 1'b1; end
    2'd2: begin pres = fpcmpo2; prfwr = 1'b1; end
    endcase
	`cFSGNJ:	
		case(ir[34:31])
		3'd0:	begin fpregfile[Rt] = {fpb[FPWID-1],fpa[FPWID-1:0]}; fprfwr = 1'b1; end		// FSGNJ
		3'd1:	begin fpregfile[Rt] = {~fpb[FPWID-1],fpa[FPWID-1:0]}; fprfwr = 1'b1; end	// FSGNJN
		3'd2:	begin fpregfile[Rt] = {fpb[FPWID-1]^fpa[FPWID-1],fpa[FPWID-1:0]}; fprfwr = 1'b1; end	// FSGNJX
		default:	;
		endcase
	`cFLOAT1:
	  case(ir[23:18])
    `cFMOV:   begin fpregfile[Rt] = fpa; fprfwr = 1'b1; end
    `cFSIGN:  begin fpregfile[Rt] = (fpa[FPWID-2:0]==0) ? 0 : {fpa[FPWID-1],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}}; fprfwr = 1'b1; end
    `cFMAN:   begin fpregfile[Rt] = {fpa[FPWID-1],1'b0,{EMSB{1'b1}},fpa[FMSB:0]}; fprfwr = 1'b1; end
    `cFISNAN:	begin fpregfile[Rt] = {fpa_nan}; end
    `cFFINITE:	begin fpregfile[Rt] = {!fpa_xinf}; end
    //`cUNORD:		begin fpres0 = {nanxab}; end
  	`cFCLASS:
  		begin
  			regfile[Rt][0] = fpa[FPWID-1] & fpa_inf;
  			regfile[Rt][1] = fpa[FPWID-1] & !fpa_xz;
  			regfile[Rt][2] = fpa[FPWID-1] &  fpa_xz;
  			regfile[Rt][3] = fpa[FPWID-1] &  fpa_vz;
  			regfile[Rt][4] = ~fpa[FPWID-1] &  fpa_vz;
  			regfile[Rt][5] = ~fpa[FPWID-1] &  fpa_xz;
  			regfile[Rt][6] = ~fpa[FPWID-1] & !fpa_xz;
  			regfile[Rt][7] = ~fpa[FPWID-1] & fpa_inf;
  			regfile[Rt][8] = fpa_snan;
  			regfile[Rt][9] = fpa_qnan;
  			rfwr = 1'b1;
  		end
    `cI2F:
      case(which)
      2'd0: begin fpregfile[Rt] = i2fo0; end
      2'd1: begin fpregfile[Rt] = i2fo1; end
      2'd2: begin fpregfile[Rt] = i2fo2; end
      endcase
    `cF2I:
      case(which)
      2'd0: begin regfile[Rt] = f2io0; end
      2'd1: begin regfile[Rt] = f2io1; end
      2'd2: begin regfile[Rt] = f2io2; end
      endcase
  	`cFTRUNC:
  	  case(which)
  	  2'd0: begin fpregfile[Rt] = trunco0; end
  	  2'd1: begin fpregfile[Rt] = trunco1; end
  	  2'd2: begin fpregfile[Rt] = trunco2; end
  	  endcase
  	endcase
	endcase
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
	`cFMADD:  begin state <= ST_MULDIV; end
	`cFMSUB:  begin state <= ST_MULDIV; end
	`cFNMADD:  begin state <= ST_MULDIV; end
	`cFNMSUB:  begin state <= ST_MULDIV; end
	`cLDB,`cLDH,`cLDW,`cLDD,`cLDBU,`cLDHU,`cLDWU,`cLDFS,`cLDFD:  state <= ST_LD1;
	default:	;
	endcase
end endtask

task tFpuSt;
input [40:0] irx;
begin
	casez(irx[40:34])
	`cFLOAT2:
	  case(irx[30:24])
  	`cFDIV: begin state <= ST_MULDIV; end
	  `cFLOAT1:
	    case(irx[23:18])
	    `cI2F,`cF2I,`cFTRUNC: state <= ST_MULDIV;
	    default:  ;
	    endcase
	  endcase
  endcase
end
endtask

task tExecSt;
input [40:0] irx;
input [5:0] st;
begin
	casez(irx[40:34])
	RR: tAluSt(irx[33:27]);
	STD:	state <= ST_ST1;
	default:	
	  begin
	    tAluSt(irx[40:34]);
	    tFpuSt(irx);	    
	  end
	endcase
end
endtask

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

module muldivCnt(rst, clk, state, p, opcode, funct, fltfunc, cnt, done);
input rst;
input clk;
input [5:0] state;
input p;
input [6:0] opcode;
input [6:0] funct;
input [6:0] fltfunc;
output reg [7:0] cnt;
output done;
parameter ST_RUN = 6'd2;
parameter ST_MULDIV = 6'd7;
parameter R2=7'd2,MUL=7'd24,MULU=7'd25,DIV=7'd26,DIVU=7'd27;
parameter FMADD=7'd112,FMSUB=7'd113,FNMADD=7'd114,FNMSUB=7'd115;

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
        `cFMADD:  cnt <= 8'd25;
        `cFMSUB:  cnt <= 8'd25;
        `cFNMADD:  cnt <= 8'd25;
        `cFNMSUB:  cnt <= 8'd25;
        `cFLOAT2:
          case(fltfunc)
          `cFDIV: cnt <= 8'd40;
          `cFLOAT1: cnt <= 8'd1;
          `cFTRUNC: cnt <= 8'd1;
          endcase
        endcase
      end
    end
  ST_MULDIV:  if (!done) cnt <= cnt - 8'd1;
  endcase
end

endmodule
