// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nPower.sv
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
//`define SIM   1'b1
import nPowerPkg::*;

module nPower(rst_i, clk_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [7:0] sel_o;
output reg [AWID-1:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;

integer n;
wire clk_g = clk_i;
reg [AWID-1:0] pc [0:1];
reg [31:0] ctr;
reg [AWID-1:0] lr;
reg [2:0] Bf [0:1];

// Instruction fetch stage vars
reg [2:0] istate;
reg ival;
wire advance_i;
wire stall_i;
reg ifetch1_done, ifetch2_done, ifetch_done;
wire iaccess_pending = !ifetch1_done || !ifetch2_done;
reg [255:0] iri1, iri2;
reg [31:0] iir [0:1];
reg [1:0] icnt;
reg [1:0] waycnt = 2'd0;
reg iaccess;

// Decode stage vars
reg [1:0] dstate [0:1];
wire advance_d;
reg decode_done;
reg dval;
reg [31:0] ir [0:1];
reg [1:0] wrrf, wrcrf;
reg [1:0] wrlr, wrctr;
reg [AWID-1:0] dpc [0:1];
reg [6:0] Rd [0:1];
reg [6:0] Ra [0:1];
reg [6:0] Rb [0:1];
reg [6:0] Rc [0:1];
reg [4:0] Bt [1:0];
reg [4:0] Ba [1:0];
reg [4:0] Bb [1:0];
reg [31:0] dimm [0:1];
reg [1:0] dmod_pc;
reg [AWID-1:0] dnext_pc [0:1];
reg [1:0] illegal_insn;
reg [1:0] d_ld, d_st;
reg [1:0] d_cmp;
reg [1:0] lsu;

// Regfetch stage vars
reg [1:0] rstate;
wire advance_r;
wire stall_r;
reg regfetch_done;
reg rval;
reg [31:0] rir [0:1];
reg [1:0] rwrrf, rwrcrf;
reg [1:0] rwrlr, rwrctr;
reg [AWID-1:0] rpc [0:1];
reg [6:0] rRd [0:1];
reg [6:0] rRa [0:1];
reg [6:0] rRb [0:1];
reg [6:0] rRc [0:1];
reg [4:0] rBa [0:1];
reg [4:0] rBb [0:1];
reg [31:0] rimm [0:1];
reg [31:0] rid [0:1];
reg [31:0] ria [0:1];
reg [31:0] rib [0:1];
reg [31:0] ric [0:1];
reg [1:0] r_lsu;
reg [1:0] r_ld, r_st;
reg [1:0] r_cmp;
reg [31:0] rcr;
reg [AWID-1:0] rlr;
reg [31:0] rctr;

// Execute stage vars
reg [5:0] estate [0:1];
wire advance_e;
reg [1:0] execute_done;
reg [1:0] eval;
reg [31:0] eir [0:1];
reg [1:0] ewrrf, ewrcrf;
reg [1:0] ewrlr, ewrctr;
reg [AWID-1:0] epc [0:1];
reg [6:0] eRa [0:1];
reg [6:0] eRd [0:1];
reg [4:0] eBa [0:1];
reg [4:0] eBb [0:1];
reg [31:0] id [0:1];
reg [31:0] ia [0:1];
reg [31:0] ib [0:1];
reg [31:0] ic [0:1];
reg [31:0] imm [0:1];
reg [31:0] eres [0:1];
reg [AWID-1:0] eea [0:1];
reg [1:0] eillegal_insn;
reg [1:0] emod_pc;
reg [AWID-1:0] enext_pc [0:1];
reg [1:0] e_ld, e_st;
reg [1:0] e_lsu;
reg [1:0] e_cmp;
reg [AWID-1:0] elr;
reg [31:0] ectr;
reg [31:0] ecr [0:1];

// Memory stage vars
reg [2:0] mstate [0:1];
wire advance_m;
reg [1:0] memory_done;
reg [1:0] maccess_pending;
reg [1:0] mval;
reg [31:0] mir [0:1];
reg [6:0] mRa [0:1];
reg [6:0] mRd [0:1];
reg [1:0] mwrrf, mwrcrf;
reg [1:0] mwrlr, mwrctr;
reg [AWID-1:0] ea [0:1];
reg [31:0] mid [0:1];
reg [31:0] mres [0:1];
reg [1:0] millegal_insn;
reg [1:0] m_lsu;
reg [1:0] m_st;
reg [31:0] mcr [0:1];
reg [31:0] mctr [0:1];
reg [AWID-1:0] mlr [0:1];
reg [15:0] sel;
reg [127:0] dat, dati;
reg maccess;
reg [AWID-1:0] iadr;

// Writeback stage vars
reg [2:0] wstate;
wire advance_w;
reg [1:0] writeback_done;
reg [31:0] wwres;
reg [31:0] wres[0:1];
reg [AWID-1:0] wea [0:1];
reg [AWID-1:0] wwea;
reg [31:0] wir [0:1];
reg [6:0] wRa [0:1];
reg [6:0] wRd [0:1];
reg [6:0] wwRd;
reg wwval;
reg [1:0] wval;
reg wwwrrf;
reg wwwrcrf;
reg [1:0] wwrrf, wwrcrf;
reg [1:0] wwrlr, wwrctr;
reg wwwrlr, wwwrctr;
reg [1:0] willegal_insn;
reg [1:0] wmod_pc;
reg [AWID-1:0] wnext_pc [0:1];
reg [1:0] w_lsu;
reg [31:0] wcr [0:1];
reg [31:0] wwcr;
reg [AWID-1:0] wlr [0:1];
reg [31:0] wctr [0:1];


reg [31:0] regfile [0:63];
wire [31:0] rfod [0:1];
wire [31:0] rfoa [0:1];
wire [31:0] rfob [0:1];
wire [31:0] rfoc [0:1];
assign rfod[0] = regfile[rRd[0]];
assign rfod[1] = regfile[rRd[1]];
assign rfoa[0] = regfile[rRa[0]];
assign rfoa[1] = regfile[rRa[1]];
assign rfob[0] = regfile[rRb[0]];
assign rfob[1] = regfile[rRb[1]];
assign rfoc[0] = regfile[rRc[0]];
assign rfoc[1] = regfile[rRc[1]];
always @(posedge clk_g)
  if (wwwrrf && wwval)
    regfile[wwRd] <= wwres;

reg [31:0] cregfile;
wire [1:0] croa;
wire [1:0] crob;
wire [3:0] croi [0:1];
assign croa[0] = cregfile[rBa[0]];
assign crob[0] = cregfile[rBb[0]];
assign croa[1] = cregfile[rBa[1]];
assign crob[1] = cregfile[rBb[1]];
wire [31:0] cro = cregfile;

always @(posedge clk_g)
  if (wwwrcrf)
    cregfile <= wwcr;
always @(posedge clk_g)
  if (wwwrlr)
    lr <= wwres;
always @(posedge clk_g)
  if (wwwrctr)
    ctr <= wwres;

assign stall_i = 1'b0;
assign stall_r = ((e_ld||e_st) && ((rRd==eRd) || (rRa==eRd) || (rRb==eRd) || (rRc==eRd)) && eval && rval)
                ;
                /*
                || (e_crop && r_crop && (rBa==eBt) || (rBb==eBt) && eval && rval)
                || (r_bc && e_crop && (rBi==eBt) && eval && rval)
                ;
                */

// Pipeline advance
assign advance_w = ifetch_done & decode_done & regfetch_done & &execute_done & &memory_done & &writeback_done;
assign advance_m = advance_w;
assign advance_e = advance_m;
assign advance_r = advance_e & ~stall_r;
assign advance_d = advance_r;
assign advance_i = advance_d & ~stall_i;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [255:0] ici;
(* ram_style="distributed" *)
reg [255:0] icache0 [0:pL1CacheLines-1];
reg [255:0] icache1 [0:pL1CacheLines-1];
reg [255:0] icache2 [0:pL1CacheLines-1];
reg [255:0] icache3 [0:pL1CacheLines-1];
(* ram_style="distributed" *)
reg [AWID-1:0] ictag0 [0:pL1CacheLines-1];
reg [AWID-1:0] ictag1 [0:pL1CacheLines-1];
reg [AWID-1:0] ictag2 [0:pL1CacheLines-1];
reg [AWID-1:0] ictag3 [0:pL1CacheLines-1];
(* ram_style="distributed" *)
reg [pL1CacheLines-1:0] icvalid0;
reg [pL1CacheLines-1:0] icvalid1;
reg [pL1CacheLines-1:0] icvalid2;
reg [pL1CacheLines-1:0] icvalid3;
reg ic_invline;
reg ihit1a, ihit2a;
reg ihit1b, ihit2b;
reg ihit1c, ihit2c;
reg ihit1d, ihit2d;
always @(posedge clk_g)
  ihit1a <= ictag0[pc[0][pL1msb:5]][AWID-1:5]==pc[0][AWID-1:5] && icvalid0[pc[0][pL1msb:5]];
always @(posedge clk_g)
  ihit1b <= ictag1[pc[0][pL1msb:5]][AWID-1:5]==pc[0][AWID-1:5] && icvalid1[pc[0][pL1msb:5]];
always @(posedge clk_g)
  ihit1c <= ictag2[pc[0][pL1msb:5]][AWID-1:5]==pc[0][AWID-1:5] && icvalid2[pc[0][pL1msb:5]];
always @(posedge clk_g)
  ihit1d <= ictag3[pc[0][pL1msb:5]][AWID-1:5]==pc[0][AWID-1:5] && icvalid3[pc[0][pL1msb:5]];
always @(posedge clk_g)
  ihit2a <= ictag0[pc[1][pL1msb:5]][AWID-1:5]==pc[1][AWID-1:5] && icvalid0[pc[1][pL1msb:5]];
always @(posedge clk_g)
  ihit2b <= ictag1[pc[1][pL1msb:5]][AWID-1:5]==pc[1][AWID-1:5] && icvalid1[pc[1][pL1msb:5]];
always @(posedge clk_g)
  ihit2c <= ictag2[pc[1][pL1msb:5]][AWID-1:5]==pc[1][AWID-1:5] && icvalid2[pc[1][pL1msb:5]];
always @(posedge clk_g)
  ihit2d <= ictag3[pc[1][pL1msb:5]][AWID-1:5]==pc[1][AWID-1:5] && icvalid3[pc[1][pL1msb:5]];
wire ihit1 = ihit1a|ihit1b|ihit1c|ihit1d;
wire ihit2 = ihit2a|ihit2b|ihit2c|ihit2d;
initial begin
  icvalid0 = {pL1CacheLines{1'd0}};
  icvalid1 = {pL1CacheLines{1'd0}};
  icvalid2 = {pL1CacheLines{1'd0}};
  icvalid3 = {pL1CacheLines{1'd0}};
  for (n = 0; n < pL1CacheLines; n = n + 1) begin
    ictag0[n] = 32'd1;
    ictag1[n] = 32'd1;
    ictag2[n] = 32'd1;
    ictag3[n] = 32'd1;
  end
end

always @(posedge clk_g)
begin
  tInsFetch();
  tDecode(0);     tDecode(1);
  tRegFetch();
  tExecute(0);    tExecute(1);
  tMemory(0);     tMemory(1);
  tWriteback();

  tValid();
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tInsFetch;
if (rst_i) begin
  vpa_o <= LOW;
  cyc_o <= LOW;
  stb_o <= LOW;
  we_o <= LOW;
  sel_o <= 8'h00;
  pc[0] <= RSTPC;
  pc[1] <= RSTPC+4;
  adr_o <= RSTPC;
  iri1 <= {8{NOP_INSN}};
  iri2 <= {8{NOP_INSN}};
  ifetch_done <= FALSE;
  ifetch1_done <= FALSE;
  ifetch2_done <= TRUE;
  iaccess <= FALSE;
  igoto (IWAIT);
end
else begin
case(istate)
IFETCH1:
  begin
    if (!ifetch1_done)
      case(1'b1)
      ihit1a: begin iri1 <= icache0[pc[0][pL1msb:5]]; ifetch1_done <= TRUE; end
      ihit1b: begin iri1 <= icache1[pc[0][pL1msb:5]]; ifetch1_done <= TRUE; end
      ihit1c: begin iri1 <= icache2[pc[0][pL1msb:5]]; ifetch1_done <= TRUE; end
      ihit1d: begin iri1 <= icache3[pc[0][pL1msb:5]]; ifetch1_done <= TRUE; end
      default:  iri1 <= {8{NOP_INSN}};
      endcase
    if (!ifetch2_done)
      case(1'b1)
      ihit2a: begin iri2 <= icache0[pc[1][pL1msb:5]]; ifetch2_done <= TRUE; end
      ihit2b: begin iri2 <= icache1[pc[1][pL1msb:5]]; ifetch2_done <= TRUE; end
      ihit2c: begin iri2 <= icache2[pc[1][pL1msb:5]]; ifetch2_done <= TRUE; end
      ihit2d: begin iri2 <= icache3[pc[1][pL1msb:5]]; ifetch2_done <= TRUE; end
      default:  iri2 <= {8{NOP_INSN}};
      endcase
    if (!(ihit1 && ihit2)) begin
      icnt <= 2'd0;
      igoto (IACCESS);
    end
    else
      igoto (IALIGN);
  end
IALIGN:
  begin
    waycnt <= waycnt + 1'd1;
    iir[0] <= iri1 >> {pc[0][4:2],5'b0};
    iir[1] <= iri2 >> {pc[1][4:2],5'b0};
    ifetch_done <= TRUE;
    igoto (IWAIT);
  end
IWAIT:
  if (advance_i) begin
    ir[0] <= iir[0];
    ir[1] <= iir[1];
    if (dmod_pc[0]) begin
      pc[0] <= dnext_pc[0];
      pc[1] <= dnext_pc[0] + 3'd4;
    end
    else if (dmod_pc[1]) begin
      pc[0] <= dnext_pc[1];
      pc[1] <= dnext_pc[1] + 3'd4;
    end
    else if (emod_pc[0]) begin
      pc[0] <= enext_pc[0];
      pc[1] <= enext_pc[0] + 3'd4;
    end
    else if (emod_pc[1]) begin
      pc[0] <= enext_pc[1];
      pc[1] <= enext_pc[1] + 3'd4;
    end
    else if (wmod_pc[0]) begin
      pc[0] <= wnext_pc[0];
      pc[1] <= wnext_pc[0] + 3'd4;
    end
    else if (wmod_pc[1]) begin
      pc[0] <= wnext_pc[1];
      pc[1] <= wnext_pc[1] + 3'd4;
    end
    else begin
      pc[0] <= pc[0] + 4'd4;
      pc[1] <= pc[0] + 4'd8;
    end
    ifetch1_done <= FALSE;
    ifetch2_done <= FALSE;
    ifetch_done <= FALSE;
    dpc[0] <= pc[0];
    dpc[1] <= pc[1];
    igoto(IFETCH1);
  end
IACCESS:
  begin
    if (!maccess_pending|vpa_o) begin
      iaccess <= TRUE;
      igoto (IACCESS_CYC);
    end
    if (!iaccess) begin
      if (!ifetch1_done)
        iadr <= {pc[0][AWID-1:5],5'h0};
      else
        iadr <= {pc[1][AWID-1:5],5'h0};
    end
    else
      iadr <= {iadr[AWID-1:3],3'h0} + 4'h8;
  end
IACCESS_CYC:
  begin
    if (~ack_i) begin
      vpa_o <= HIGH;
      cyc_o <= HIGH;
      stb_o <= HIGH;
      we_o <= LOW;
      sel_o <= 8'hFF;
      adr_o <= iadr;
      igoto(IACCESS_ACK);
    end
  end
IACCESS_ACK:
  if (ack_i) begin
    icnt <= icnt + 1'd1;
    case(icnt)
    2'd0: ici[ 63:  0] <= dat_i;
    2'd1: ici[127: 64] <= dat_i;
    2'd2: ici[191:128] <= dat_i;
    2'd3: ici[255:192] <= dat_i;
    endcase
    if (icnt==2'd3) begin
      vpa_o <= LOW;
      cyc_o <= LOW;
      stb_o <= LOW;
      iaccess <= FALSE;
      igoto (IC_UPDATE);
    end
    else begin
      stb_o <= LOW;
      igoto (IACCESS);
    end
  end
IC_UPDATE:
  begin
    case (waycnt)
    2'd0: ictag0[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
    2'd1: ictag1[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
    2'd2: ictag2[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
    2'd3: ictag3[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
    endcase
    case(waycnt)
    2'd0:
      begin
        icvalid0[iadr[pL1msb:5]] <= 1'b1;
        icache0[iadr[pL1msb:5]] <= ici;
      end
    2'd1:
      begin
        icvalid1[iadr[pL1msb:5]] <= 1'b1;
        icache1[iadr[pL1msb:5]] <= ici;
      end
    2'd2:
      begin
        icvalid2[iadr[pL1msb:5]] <= 1'b1;
        icache2[iadr[pL1msb:5]] <= ici;
      end
    2'd3:
      begin
        icvalid3[iadr[pL1msb:5]] <= 1'b1;
        icache3[iadr[pL1msb:5]] <= ici;
      end
    endcase
    igoto (IFETCH1);
  end
default:
  begin
    ifetch_done <= TRUE;
    igoto (IWAIT);
  end
endcase
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tDecode;
input which;
begin
  if (rst_i) begin
    decode_done <= TRUE;
    dstate[which] <= DWAIT;
  end
  else begin
    case(dstate[which])
    DECODE:
      begin
        if (which==1'b0) begin
          decode_done <= TRUE;
          dstate[which] <= DWAIT;
        end
        illegal_insn[which] <= TRUE;
        Rd[which] <= ir[which][25:21];
        Ra[which] <= ir[which][20:16];
        Rb[which] <= ir[which][15:11];
        Rc[which] <= ir[which][10: 6];
        Bt[which] <= ir[which][25:21];
        Ba[which] <= ir[which][20:16];
        Bb[which] <= ir[which][15:11];
        lsu[which] <= FALSE;
        wrrf[which] <= FALSE;
        wrcrf[which] <= FALSE;
        dmod_pc[which] <= FALSE;
        d_cmp[which] <= FALSE;
        d_ld[which] <= FALSE;
        d_st[which] <= FALSE;
        case(ir[which][31:26])
        R2:
          case(ir[which][10:1])
          ADD: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          SUBF:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          NEG: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          CMP: begin wrcrf[which] <= TRUE; Bf[which] <= ir[which][25:23]; illegal_insn[which] <= FALSE; d_cmp[which] <= TRUE; end
          CMPL:begin wrcrf[which] <= TRUE; Bf[which] <= ir[which][25:23]; illegal_insn[which] <= FALSE; d_cmp[which] <= TRUE; end
          AND: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          OR:  begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          XOR: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          SLW: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          SRW: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          SRAW:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          SRAWI:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          EXTSB:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          EXTSH:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
          LBZX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          LHZX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          LWZX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          STBX:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
          STHX:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
          STWX:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
          LBZUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          LHZUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          LWZUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          STBUX:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
          STHUX:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
          STWUX:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
          default:  ;
          endcase
        ADDI:  begin wrrf[which] <= TRUE; dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        ADDIS: begin wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; end
        CMPI:  begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; Bf[which] <= ir[which][25:23]; illegal_insn[which] <= FALSE; wrcrf <= TRUE; d_cmp[which] <= TRUE; end
        CMPLI: begin dimm[which] <= {16'h0000,ir[which][15:0]}; Bf[which] <= ir[which][25:23]; illegal_insn[which] <= FALSE; wrcrf <= TRUE; d_cmp[which] <= TRUE; end
        ANDI:  begin wrrf[which] <= TRUE; dimm[which] <= {16'hFFFF,ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        ANDIS: begin wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'hFFFF}; illegal_insn[which] <= FALSE; end
        ORI:   begin wrrf[which] <= TRUE; dimm[which] <= {16'h0000,ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        ORIS:  begin wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; end
        XORI:  begin wrrf[which] <= TRUE; dimm[which] <= {16'h0000,ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        XORIS: begin wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; end

        B:     begin
                  illegal_insn[which] <= FALSE;
                  dmod_pc[which] <= TRUE;
                  if (ir[which][1])
                    dnext_pc[which] <= {dpc[which],ir[which][25:2],2'b00};
                  else
                    dnext_pc[which] <= dpc[which] + {{6{ir[which][25]}},ir[which][25:2],2'b00};
                  wrlr[which] <= ir[which][0];
                end
        BC:    begin wrlr[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
        CR2:
          case(ir[which][10:1])
          BCCTR: begin wrlr[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          BCLR:  begin wrlr[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          default:  ;
          endcase

        LBZ:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
        LHZ:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
        LWZ:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
        LBZU:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
        LHZU:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
        LWZU:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
        STB:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
        STH:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
        STW:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
        STBU:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
        STHU:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
        STWU:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
        default:  ;
        endcase
      end
    DWAIT:
      if (advance_d) begin
        rir[which] <= ir[which];
        rpc[which] <= dpc[which];
        rRd[which] <= Rd[which];
        rRa[which] <= Ra[which];
        rRb[which] <= Rb[which];
        rRc[which] <= Rc[which];
        rBa[which] <= Ba[which];
        rBb[which] <= Bb[which];
        rimm[which] <= dimm[which];
        r_lsu[which] <= lsu[which];
        r_ld[which] <= d_ld[which];
        r_st[which] <= d_st[which];
        rwrrf[which] <= wrrf[which];
        rwrcrf[which] <= wrcrf[which];
        if (which==1'b0)
          decode_done <= FALSE;
        dstate[which] <= DECODE;
      end
    default:
      begin
        decode_done <= TRUE;
        dstate[which] <= DWAIT;
      end
    endcase
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register Fetch Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tRegFetch;
if (rst_i) begin
  regfetch_done <= TRUE;
  rgoto(RWAIT);
end
else begin
case(rstate)
RFETCH:
  begin
    regfetch_done <= TRUE;
    rgoto(RWAIT);

    tin(0,rRd[0],rfod[0],rid[0]);
    tin(1,rRd[1],rfod[1],rid[1]);
    tin(0,rRa[0],rfoa[0],ria[0]);
    tin(1,rRa[1],rfoa[1],ria[1]);
    tin(0,rRb[0],rfob[0],rib[0]);
    tin(1,rRb[1],rfob[1],rib[1]);
    tin(0,rRc[0],rfoc[0],ric[0]);
    tin(1,rRc[1],rfoc[1],ric[1]);

    if (ewrcrf[1] & eval[1])
      rcr <= ecr[1];
    else if (ewrcrf[0] & eval[0])
      rcr <= ecr[0];
    else if (mwrcrf[1] & mval[1])
      rcr <= mcr[1];
    else if (mwrcrf[0] & mval[0])
      rcr <= mcr[0];
    else if (wwrcrf[1] & wval[1])
      rcr <= wcr[1];
    else if (wwrcrf[0] & wval[0])
      rcr <= wcr[0];
    else
      rcr <= cro;

    if (ewrlr[1] & eval[1])
      rlr <= eres[1];
    else if (ewrlr[0] & eval[0])
      rlr <= eres[0];
    else if (mwrlr[1] & mval[1])
      rlr <= mres[1];
    else if (mwrlr[0] & mval[0])
      rlr <= mres[0];
    else if (wwrlr[1] & wval[1])
      rlr <= wres[1];
    else if (wwrlr[0] & wval[0])
      rlr <= wres[0];
    else
      rlr <= lr;

    if (ewrctr[1] & eval[1])
      rctr <= eres[1];
    else if (ewrctr[0] & eval[0])
      rctr <= eres[0];
    else if (mwrctr[1] & mval[1])
      rctr <= mres[1];
    else if (mwrctr[0] & mval[0])
      rctr <= mres[0];
    else if (wwrctr[1] & wval[1])
      rctr <= wres[1];
    else if (wwrctr[0] & wval[0])
      rctr <= wres[0];
    else
      rctr <= ctr;

  end
RWAIT:
  if (advance_r) begin
    eval[0] <= rval;
    eval[1] <= rval;
    eRd[0] <= rRd[0];
    eRd[1] <= rRd[1];
    eRa[0] <= rRa[0];
    eRa[1] <= rRa[1];
    eBa[0] <= rBa[0];
    eBa[1] <= rBa[1];
    eir[0] <= rir[0];
    eir[1] <= rir[1];
    ecr[0] <= rcr;
    ecr[1] <= rcr;
    epc[0] <= rpc[0];
    epc[1] <= rpc[1];
    id[0] <= rid[0];
    id[1] <= rid[1];
    ia[0] <= ria[0];
    ia[1] <= ria[1];
    ib[0] <= rib[0];
    ib[1] <= rib[1];
    ic[0] <= ric[0];
    ic[1] <= ric[1];
    e_lsu[0] <= r_lsu[0];
    e_cmp[0] <= r_cmp[0];
    ewrrf[0] <= rwrrf[0];
    ewrcrf[0] <= rwrcrf[0];
    e_lsu[1] <= r_lsu[1];
    e_cmp[1] <= r_cmp[1];
    ewrrf[1] <= rwrrf[1];
    ewrcrf[1] <= rwrcrf[1];
    ewrlr[0] <= rwrlr[0];
    ewrlr[1] <= rwrlr[1];
    ewrctr[0] <= rwrctr[0];
    ewrctr[1] <= rwrctr[1];
		e_ld[0] <= r_ld[0];
		e_st[0] <= r_st[0];
		e_ld[1] <= r_ld[1];
		e_st[1] <= r_st[1];
		elr <= rlr;
    ectr <= rctr;
    regfetch_done <= FALSE;
    rgoto (RFETCH);
  end
  else if (advance_e) begin
    eval[0] <= FALSE;
    eval[1] <= FALSE;
    eir[0] <= NOP_INSN;
    eir[1] <= NOP_INSN;
  end
default:
  begin
    regfetch_done <= TRUE;
    rgoto(RWAIT);
  end
endcase
end
endtask

task tin;
input which;
input [6:0] Rn;
input [31:0] rfo;
output [31:0] in;
begin
  if (Rn==7'd0 && (r_ld[which]|r_st[which]) && rval)
    in <= 32'd0;
  else if (Rn==eRd[1] && eval[1])
    in <= eres[1];
  else if (Rn==eRd[0] && eval[0])
    in <= eres[0];
  else if (Rn==mRd[1] && mval[1])
    in <= mres[1];
  else if (Rn==mRd[0] && mval[0])
    in <= mres[0];
  else if (Rn==wRd[1] && wval[1])
    in <= wres[1];
  else if (Rn==wRd[0] && wval[0])
    in <= wres[0];
  else
    in <= rfo;
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tExecute;
input which;
begin
  if (rst_i) begin
    eval[which] <= FALSE;
    execute_done[which] <= TRUE;
    estate[which] <= EWAIT;
  end
  else begin
    case(estate[which])
    EXECUTE:
      begin
        estate[which] <= EFLAGS;
        case(eir[which][31:26])
        R2:
          case(eir[which][10:1])
          ADD:  eres[which] <= ia[which] + ib[which];
          SUBF: eres[which] <= ib[which] - ia[which];
          NEG:  eres[which] <= -ia[which];
          CMP:  
            begin
              case(eir[which][25:23])
              3'd0:
                begin
                  ecr[which][0] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][1] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][2] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][3] <= 1'b0;
                end
              3'd1:
                begin
                  ecr[which][4] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][5] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][6] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][7] <= 1'b0;
                end
              3'd2:
                begin
                  ecr[which][8] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][9] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][10] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][11] <= 1'b0;
                end
              3'd3:
                begin
                  ecr[which][12] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][13] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][14] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][15] <= 1'b0;
                end
              3'd4:
                begin
                  ecr[which][16] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][17] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][18] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][19] <= 1'b0;
                end
              3'd5:
                begin
                  ecr[which][20] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][21] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][22] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][23] <= 1'b0;
                end
              3'd6:
                begin
                  ecr[which][24] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][25] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][26] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][27] <= 1'b0;
                end
              3'd7:
                begin
                  ecr[which][28] <= $signed(ia[which]) <  $signed(ib[which]);
                  ecr[which][29] <= $signed(ia[which]) >  $signed(ib[which]);
                  ecr[which][30] <= $signed(ia[which]) == $signed(ib[which]);
                  ecr[which][31] <= 1'b0;
                end
              endcase
            end
          CMPL:
            begin
              case(eir[which][25:23])
              3'd0:
                begin
                  ecr[which][0] <= ia[which] <  ib[which];
                  ecr[which][1] <= ia[which] >  ib[which];
                  ecr[which][2] <= ia[which] == ib[which];
                  ecr[which][3] <= 1'b0;
                end
              3'd1:
                begin
                  ecr[which][4] <= ia[which] <  ib[which];
                  ecr[which][5] <= ia[which] >  ib[which];
                  ecr[which][6] <= ia[which] == ib[which];
                  ecr[which][7] <= 1'b0;
                end
              3'd2:
                begin
                  ecr[which][8] <= ia[which] <  ib[which];
                  ecr[which][9] <= ia[which] >  ib[which];
                  ecr[which][10] <= ia[which] == ib[which];
                  ecr[which][11] <= 1'b0;
                end
              3'd3:
                begin
                  ecr[which][12] <= ia[which] <  ib[which];
                  ecr[which][13] <= ia[which] >  ib[which];
                  ecr[which][14] <= ia[which] == ib[which];
                  ecr[which][15] <= 1'b0;
                end
              3'd4:
                begin
                  ecr[which][16] <= ia[which] <  ib[which];
                  ecr[which][17] <= ia[which] >  ib[which];
                  ecr[which][18] <= ia[which] == ib[which];
                  ecr[which][19] <= 1'b0;
                end
              3'd5:
                begin
                  ecr[which][20] <= ia[which] <  ib[which];
                  ecr[which][21] <= ia[which] >  ib[which];
                  ecr[which][22] <= ia[which] == ib[which];
                  ecr[which][23] <= 1'b0;
                end
              3'd6:
                begin
                  ecr[which][24] <= ia[which] <  ib[which];
                  ecr[which][25] <= ia[which] >  ib[which];
                  ecr[which][26] <= ia[which] == ib[which];
                  ecr[which][27] <= 1'b0;
                end
              3'd7:
                begin
                  ecr[which][28] <= ia[which] <  ib[which];
                  ecr[which][29] <= ia[which] >  ib[which];
                  ecr[which][30] <= ia[which] == ib[which];
                  ecr[which][31] <= 1'b0;
                end
              endcase
            end
          AND:  eres[which] <= ia[which] & ib[which];
          OR:   eres[which] <= ia[which] | ib[which];
          XOR:  eres[which] <= ia[which] ^ ib[which];
          EXTSB:eres[which] <= {{24{ia[which][7]}},ia[which][7:0]};
          EXTSH:eres[which] <= {{16{ia[which][15]}},ia[which][15:0]};
          SLW:  eres[which] <= ia[which] << ib[which];
          SRW:  eres[which] <= ia[which] >> ib[which];
          SRAW: eres[which] <= ia[which][31] ? {32'hFFFFFFFF,ia[which]} >> ib[which] : ia[which] >> ib[which];
          SRAWI:eres[which] <= ia[which][31] ? {32'hFFFFFFFF,ia[which]} >> eir[which][15:11] : ia[which] >> eir[which][15:11];
          LBZX,LBZUX:  begin eea[which] <= ia[which] + ib[which]; end
          LHZX,LHZUX:  begin eea[which] <= ia[which] + ib[which]; end
          LWZX,LWZUX:  begin eea[which] <= ia[which] + ib[which]; end
          STBX,STBUX:  begin eea[which] <= ia[which] + ib[which]; end
          STHX,STHUX:  begin eea[which] <= ia[which] + ib[which]; end
          STWX,STWUX:  begin eea[which] <= ia[which] + ib[which]; end
          default:  ;
          endcase
        ADDI:  eres[which] <= ia[which] + imm[which];
        CMPI:
          begin
            case(eir[which][25:23])
            3'd0:
              begin
                ecr[which][0] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][1] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][2] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][3] <= 1'b0;
              end
            3'd1:
              begin
                ecr[which][4] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][5] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][6] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][7] <= 1'b0;
              end
            3'd2:
              begin
                ecr[which][8] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][9] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][10] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][11] <= 1'b0;
              end
            3'd3:
              begin
                ecr[which][12] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][13] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][14] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][15] <= 1'b0;
              end
            3'd4:
              begin
                ecr[which][16] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][17] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][18] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][19] <= 1'b0;
              end
            3'd5:
              begin
                ecr[which][20] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][21] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][22] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][23] <= 1'b0;
              end
            3'd6:
              begin
                ecr[which][24] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][25] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][26] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][27] <= 1'b0;
              end
            3'd7:
              begin
                ecr[which][28] <= $signed(ia[which]) <  $signed(imm[which]);
                ecr[which][29] <= $signed(ia[which]) >  $signed(imm[which]);
                ecr[which][30] <= $signed(ia[which]) == $signed(imm[which]);
                ecr[which][31] <= 1'b0;
              end
            endcase
          end
        CMPLI:
          begin
            case(eir[which][25:23])
            3'd0:
              begin
                ecr[which][0] <= ia[which] <  imm[which];
                ecr[which][1] <= ia[which] >  imm[which];
                ecr[which][2] <= ia[which] == imm[which];
                ecr[which][3] <= 1'b0;
              end
            3'd1:
              begin
                ecr[which][4] <= ia[which] <  imm[which];
                ecr[which][5] <= ia[which] >  imm[which];
                ecr[which][6] <= ia[which] == imm[which];
                ecr[which][7] <= 1'b0;
              end
            3'd2:
              begin
                ecr[which][8] <= ia[which] <  imm[which];
                ecr[which][9] <= ia[which] >  imm[which];
                ecr[which][10] <= ia[which] == imm[which];
                ecr[which][11] <= 1'b0;
              end
            3'd3:
              begin
                ecr[which][12] <= ia[which] <  imm[which];
                ecr[which][13] <= ia[which] >  imm[which];
                ecr[which][14] <= ia[which] == imm[which];
                ecr[which][15] <= 1'b0;
              end
            3'd4:
              begin
                ecr[which][16] <= ia[which] <  imm[which];
                ecr[which][17] <= ia[which] >  imm[which];
                ecr[which][18] <= ia[which] == imm[which];
                ecr[which][19] <= 1'b0;
              end
            3'd5:
              begin
                ecr[which][20] <= ia[which] <  imm[which];
                ecr[which][21] <= ia[which] >  imm[which];
                ecr[which][22] <= ia[which] == imm[which];
                ecr[which][23] <= 1'b0;
              end
            3'd6:
              begin
                ecr[which][24] <= ia[which] <  imm[which];
                ecr[which][25] <= ia[which] >  imm[which];
                ecr[which][26] <= ia[which] == imm[which];
                ecr[which][27] <= 1'b0;
              end
            3'd7:
              begin
                ecr[which][28] <= ia[which] <  imm[which];
                ecr[which][29] <= ia[which] >  imm[which];
                ecr[which][30] <= ia[which] == imm[which];
                ecr[which][31] <= 1'b0;
              end
            endcase
          end
        ANDI,ANDIS: eres[which] <= ia[which] & imm[which];
        ORI,ORIS:   eres[which] <= ia[which] | imm[which];
        XORI,XORIS: eres[which] <= ia[which] ^ imm[which];
        B:  eres[which] <= epc[which] + 3'd4;
        BC: eres[which] <= epc[which] + 3'd4;
        CR2:
          case(eir[which][10:1])
          BCCTR:eres[which] <= epc[which] + 3'd4;
          BCLR: eres[which] <= epc[which] + 3'd4;
          default:  ;
          endcase
        LBZ,LBZU:  begin eea[which] <= ia[which] + imm[which]; end
        LHZ,LHZU:  begin eea[which] <= ia[which] + imm[which]; end
        LWZ,LWZU:  begin eea[which] <= ia[which] + imm[which]; end
        STB,STBU:  begin eea[which] <= ia[which] + imm[which]; end
        STH,STHU:  begin eea[which] <= ia[which] + imm[which]; end
        STW,STWU:  begin eea[which] <= ia[which] + imm[which]; end
        default:  ;
        endcase
        if (~ewrcrf[which] | e_cmp) begin
          execute_done[which] <= TRUE;
          estate[which] <= EWAIT;
        end
      end
    EFLAGS:
      begin
        if (ewrcrf[which] & ~e_cmp) begin
          ecr[which][0] <= eres[which][31];
          ecr[which][1] <= eres[which]==32'd0;
          ecr[which][2] <= ~eres[which][31] && eres[which]!=32'd0;
        end
        execute_done[which] <= TRUE;
        estate[which] <= EWAIT;
      end        
    EWAIT:
      if (advance_e) begin
        execute_done[which] <= FALSE;
        estate[which] <= EXECUTE;
        mRd[which] <= eRd[which];
        mRa[which] <= eRa[which];
        ea[which] <= eea[which];
        mid[which] <= id[which];
        mir[which] <= eir[which];
        m_lsu[which] <= e_lsu[which];
        m_st[which] <= e_st[which];
        mval[which] <= eval[which];
        mres[which] <= eres[which];
        mcr[which] <= ecr[which];
        mwrrf[which] <= ewrrf[which];
        mwrcrf[which] <= mwrcrf[which];
        mwrlr[which] <= ewrlr[which];
        mwrctr[which] <= ewrctr[which];
        mctr[which] <= ectr[which];
        mlr[which] <= elr[which];
      end
    default:
      begin
        execute_done[which] <= TRUE;
        estate[which] <= EWAIT;
      end
    endcase
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory Stage
// - shortest path 2 clock cycles
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tMemory;
input which;
begin
  if (rst_i) begin
    memory_done[which] <= TRUE;
    mstate[which] <= MWAIT;
    mval[which] <= FALSE;
  end
  else begin
    case(mstate[which])
    MEMORY1:
      begin
        memory_done[which] <= TRUE;
        mstate[which] <= MWAIT;
        case(mir[which][31:26])
        R2:
          case(mir[which][10:1])
          LBZX,LBZUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          LHZX,LHZUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          LWZX,LWZUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          STBX,STBUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          STHX,STHUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          STWX,STWUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          default:  begin mstate[which] <= MWAIT; memory_done[which] <= TRUE; end
          endcase
        LBZ,LBZU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        LHZ,LHZU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        LWZ,LWZU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        STB,STBU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        STH,STHU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        STW,STWU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        default:  begin mstate[which] <= MWAIT; memory_done[which] <= TRUE; end
        endcase
      end
    MEMORY2:
      if (!iaccess && !iaccess_pending && (which==0 || !maccess_pending[0])) begin
        maccess_pending[which] <= FALSE;
        maccess <= TRUE;
        cyc_o <= HIGH;
        stb_o <= HIGH;
        case(mir[which][31:26])
        R2:
          case(mir[which][10:1])
          LBZX,LBZUX:  begin we_o <= LOW; sel_o <= 8'h01 << ea[which][2:0]; adr_o <= ea[which]; end
          LHZX,LHZUX:  begin we_o <= LOW; sel_o <= 8'h03 << ea[which][2:0]; sel <= 16'h0003 << ea[which][2:0]; adr_o <= ea[which]; end
          LWZX,LWZUX:  begin we_o <= LOW; sel_o <= 8'h0F << ea[which][2:0]; sel <= 16'h000F << ea[which][2:0]; adr_o <= ea[which]; end
          STBX,STBUX:  begin we_o <= HIGH; sel_o <= 8'h01 << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][2:0],3'b0}; end
          STHX,STHUX:  begin we_o <= HIGH; sel_o <= 8'h03 << ea[which][2:0]; sel <= 16'h0003 << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][2:0],3'b0}; dat <= mid[which] << {ea[which][2:0],3'b0}; end
          STWX,STWUX:  begin we_o <= HIGH; sel_o <= 8'h0F << ea[which][2:0]; sel <= 16'h000F << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][2:0],3'b0}; dat <= mid[which] << {ea[which][2:0],3'b0}; end
          default:  ;
          endcase
        LBZ,LBZU:  begin we_o <= LOW; sel_o <= 8'h01 << ea[which][2:0]; adr_o <= ea[which]; end
        LHZ,LHZU:  begin we_o <= LOW; sel_o <= 8'h03 << ea[which][2:0]; sel <= 16'h0003 << ea[which][2:0]; adr_o <= ea[which]; end
        LWZ,LWZU:  begin we_o <= LOW; sel_o <= 8'h0F << ea[which][2:0]; sel <= 16'h000F << ea[which][2:0]; adr_o <= ea[which]; end
        STB,STBU:  begin we_o <= HIGH; sel_o <= 8'h01 << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][2:0],3'b0}; end
        STH,STHU:  begin we_o <= HIGH; sel_o <= 8'h03 << ea[which][2:0]; sel <= 16'h0003 << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][2:0],3'b0}; dat <= mid[which] << {ea[which][2:0],3'b0}; end
        STW,STWU:  begin we_o <= HIGH; sel_o <= 8'h0F << ea[which][2:0]; sel <= 16'h000F << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][2:0],3'b0}; dat <= mid[which] << {ea[which][2:0],3'b0}; end
        default:  ;
        endcase
        mstate[which] <= MEMORY3;
      end
    MEMORY3:
      if (ack_i) begin
        stb_o <= LOW;
        dati <= dat_i;
        case(mir[which][31:26])
        R2:
          case(mir[which][10:1])
          LBZX,LBZUX,STBX,STBUX: begin cyc_o <= LOW; we_o <= LOW; sel_o <= 8'h00; memory_done[which] <= TRUE; mstate[which] <= MWAIT; end
          LHZX,LHZUX,STHX,STHUX:
            begin
              if (ea[which][2:0]!=3'b111) begin
                cyc_o <= LOW;
                we_o <= LOW;
                sel_o <= 8'h00;
                memory_done[which] <= TRUE;
                mstate[which] <= MWAIT;
              end
              else
                mstate[which] <= MEMORY4;
            end
          LWZX,LWZUX,STWX,STWUX:  
            begin
              if (ea[which][2:0] < 3'b101) begin
                cyc_o <= LOW;
                we_o <= LOW;
                sel_o <= 8'h00;
                memory_done[which] <= TRUE;
                mstate[which] <= MWAIT;
              end
              else
                mstate[which] <= MEMORY4;
            end
          default:  ;
          endcase
        LBZ,LBZU:  begin cyc_o <= LOW; sel_o <= 8'h00; memory_done[which] <= TRUE; mstate[which] <= MWAIT; end
        LHZ,LHZU,STH,STHU:
          begin
            if (ea[which][2:0]!=3'b111) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 8'h00;
              memory_done[which] <= TRUE;
              mstate[which] <= MWAIT;
            end
            else
              mstate[which] <= MEMORY4;
          end
        LWZ,LWZU,STW,STWU:  
          begin
            if (ea[which][2:0] < 3'b101) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 8'h00;
              memory_done[which] <= TRUE;
              mstate[which] <= MWAIT;
            end
            else
              mstate[which] <= MEMORY4;
          end
        STB,STBU:  begin cyc_o <= LOW; we_o <= LOW; sel_o <= 8'h00; memory_done[which] <= TRUE; mstate[which] <= MWAIT; end
        default:  ;
        endcase
      end
    MEMORY4:
      begin
        stb_o <= HIGH;
        sel_o <= sel[15:7];
        adr_o <= {ea[which][AWID-1:3]+1'd1,3'b0};
        dat_o <= dat[127:64];
        mstate[which] <= MEMORY5;
      end
    MEMORY5:
      if (ack_i) begin
        cyc_o <= LOW;
        stb_o <= LOW;
        we_o <= LOW;
        sel_o <= 8'h00;
        dati[127:64] <= dat_i;
        if (m_st[which]) begin
          memory_done[which] <= TRUE;
          mstate[which] <= MWAIT;
        end
        else
          mstate[which] <= MALIGN;
      end
    MALIGN:
      begin
        memory_done[which] <= TRUE;
        mstate[which] <= MWAIT;
        case(mir[which][31:26])
        R2:
          case(mir[which][10:1])
          LBZX,LBZUX: mres[which] <= (dati >> {ea[which][2:0],3'b0}) & 32'h0FF;
          LHZX,LHZUX: mres[which] <= (dati >> {ea[which][2:0],3'b0}) & 32'h0FFFF;
          LWZX,LWZUX: mres[which] <= (dati >> {ea[which][2:0],3'b0}) & 32'hFFFFFFFF;
          default:  ;
          endcase
        LBZ,LBZU: mres[which] <= (dati >> {ea[which][2:0],3'b0}) & 32'h0FF;
        LHZ,LHZU: mres[which] <= (dati >> {ea[which][2:0],3'b0}) & 32'h0FFFF;
        LWZ,LWZU: mres[which] <= (dati >> {ea[which][2:0],3'b0}) & 32'hFFFFFFFF;
        default:  ;
        endcase
      end
    MWAIT:
      if (advance_m) begin
      	wRd[which] <= mRd[which];
      	wRa[which] <= mRa[which];
        wval[which] <= mval[which];
        wwval <= 1'b0;
        wres[which] <= mres[which];
        wea[which] <= ea[which];
        w_lsu[which] <= m_lsu[which];
        wwrrf[which] <= mwrrf[which];
        wwrcrf[which] <= wwrcrf[which];
        wcr[which] <= mcr[which];
        wwrlr[which] <= mwrlr[which];
        wwrctr[which] <= mwrctr[which];
        wctr[which] <= mctr[which];
        wlr[which] <= mlr[which];
        memory_done[which] <= FALSE;
        mstate[which] <= MEMORY1;
      end
    default:
      begin
        memory_done[which] <= TRUE;
        mstate[which] <= MWAIT;
      end
    endcase
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback Stage
// - shortest path 2 clock cycles
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tWriteback;
begin
  if (rst_i) begin
    wval <= 2'b00;
    writeback_done <= TRUE;
    wgoto (WWAIT);
  end
  else begin
    case(wstate)
    WRITEBACK0:
      begin
        wwRd <= wRd[0];
        wwres <= wres[0];
        wwval <= wval[0] & wwrrf[0];
        wwwrcrf <= wwrcrf[0] & wval[0];
        wwwrlr <= wwrlr[0] & wval[0];
        wwwrctr <= wwrctr[0] & wval[0];
        wwcr <= wcr[0];
        if (w_lsu[0] & wval[0])
          wgoto(WRITEBACK1);
        else if (wval[1])
          wgoto(WRITEBACK2);
        else begin
          writeback_done <= TRUE;
          wgoto(WWAIT);
        end
      end
    WRITEBACK1:
      begin
        wwRd <= wRa[0];
        wwres <= wea[0];
        wwval <= 1'b1;
        if (wval[1])
          wgoto(WRITEBACK2);
        else begin
          writeback_done <= TRUE;
          wgoto(WWAIT);
        end
      end
    WRITEBACK2:
      begin
        wwRd <= wRd[1];
        wwres <= wres[1];
        wwval <= wval[1] & wwrrf[1];
        wwwrcrf <= wwrcrf[1] & wval[1];
        wwwrlr <= wwrlr[1] & wval[1];
        wwwrctr <= wwrctr[1] & wval[1];
        wwcr <= wcr[1];
        if (w_lsu[1] & wval[1])
          wgoto(WRITEBACK3);
        else begin
          writeback_done <= TRUE;
          wgoto(WWAIT);
        end
      end
    WRITEBACK3:
      begin
        wwRd <= wRa[1];
        wwres <= wea[1];
        wwval <= 1'b1;
        writeback_done <= TRUE;
        wgoto(WWAIT);
      end
    WWAIT:
      if (advance_w) begin
        writeback_done <= FALSE;
        wgoto(WRITEBACK0);
      end
    default:
      begin
        writeback_done <= TRUE;
        wgoto (WWAIT);
      end
    endcase
  end
end
endtask

task igoto;
input [2:0] nst;
begin
  istate <= nst;
end
endtask

task rgoto;
input [1:0] nst;
begin
  rstate <= nst;
end
endtask

task wgoto;
input [2:0] nst;
begin
  wstate <= nst;
end
endtask

task tValid;
begin
  if (dmod_pc[0]) begin
    ir[0] <= NOP_INSN;
    ir[1] <= NOP_INSN;
    dval <= 2'b00;
    eval[1] <= 1'b0;
  end
  else if (dmod_pc[1]) begin
    ir[0] <= NOP_INSN;
    ir[1] <= NOP_INSN;
    dval <= 2'b00;
  end
  else if (emod_pc[0]) begin
    ir[0] <= NOP_INSN;
    ir[1] <= NOP_INSN;
    dval <= 2'b00;
    rir[0] <= NOP_INSN;
    rir[1] <= NOP_INSN;
    rval <= 2'b00;
    eir[0] <= NOP_INSN;
    eir[1] <= NOP_INSN;
    eval <= 2'b00;
  end
end
endtask

endmodule
