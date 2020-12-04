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
import nPower::*;

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

reg [AWID-1:0] pc [0:1];
reg [31:0] ctr;
reg [AWID-1:0] lr;
reg [31:0] ir [0:1];
reg [6:0] Rd [0:1];
reg [6:0] Ra [0:1];
reg [6:0] Rb [0:1];
reg [6:0] Rc [0:1];
reg [31:0] dimm [0:1];
reg [2:0] Bf [0:1];

// Writeback stage vars
reg [31:0] wwres;
reg [31:0] wres[0:1];
reg [6:0] wwRd;
reg wwval;
reg [1:0] wval;
reg wwwrrf;
reg [1:0] wwrrf;

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
  if (wwwrrf && wwval && (wstate==WRITEBACK0 || wstate==WRITEBACK1))
    regfile[wwRd] <= wwres;

reg [31:0] cregfile;
wire [1:0] croa;
wire [1:0] crob;
assign croa[0] = cregfile[rBa[0]];
assign crob[0] = cregfile[rBb[0]];
assign croa[1] = cregfile[rBa[1]];
assign crob[1] = cregfile[rBb[1]];

reg [2:0] istate;
reg [1:0] dstate;
reg ifetch_done, decode_done;
wire maccess_pending = FALSE;
wire advance_i = ifetch_done;

reg wrirf, wrcrf;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg ifetch1_done, ifetch2_done;
wire iaccess_pending = !ifetch1_done || !ifetch2_done;
reg [255:0] iri1, iri2;
reg [1:0] icnt;
reg [1:0] waycnt = 2'd0;
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
  tDecode(0);
  tDecode(1);
end

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
  iri1 <= {8{`NOP_INSN}};
  iri2 <= {8{`NOP_INSN}};
  ifetch_done <= FALSE;
  ifetch1_done <= FALSE;
  ifetch2_done <= TRUE;
  igoto (IWAIT);
end
else begin
case(istate)
IFETCH1:
  begin
    if (!ifetch1_done)
      case(1'b1)
      ihit1a: begin iri1 <= icache[0]; ifetch1_done <= TRUE: end
      ihit1b: begin iri1 <= icache[1]; ifetch1_done <= TRUE; end
      ihit1c: begin iri1 <= icache[2]; ifetch1_done <= TRUE; end
      ihit1d: begin iri1 <= icache[3]; ifetch1_done <= TRUE; end
      default:  iri1 <= {8{`NOP_INSN}};
      endcase
    if (!ifetch2_done)
      case(1'b1)
      ihit2a: begin iri2 <= icache[0]; ifetch2_done <= TRUE: end
      ihit2b: begin iri2 <= icache[1]; ifetch2_done <= TRUE; end
      ihit2c: begin iri2 <= icache[2]; ifetch2_done <= TRUE; end
      ihit2d: begin iri2 <= icache[3]; ifetch2_done <= TRUE; end
      default:  iri2 <= {8{`NOP_INSN}};
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
    ir[0] <= iri1 >> {pc[0][4:2],5'b0};
    ir[1] <= iri2 >> {pc[1][4:2],5'b0};
    ifetch_done <= TRUE;
    igoto (IWAIT);
  end
IWAIT:
  if (advance_i) begin
    if (d_modpc[0]) begin
      pc[0] <= dnext_pc[0];
      pc[1] <= dnext_pc[0] + 3'd4;
    end
    else if (d_modpc[1]) begin
      pc[0] <= dnext_pc[1];
      pc[1] <= dnext_pc[1] + 3'd4;
    end
    else begin
      pc[0] <= pc[0] + 4'd4;
      pc[1] <= pc[0] + 4'd8;
    end
    ifetch1_done <= FALSE;
    ifetch2_done <= FALSE;
    ifetch_done <= FALSE;
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
        iadr <= {pc1[AWID-1:5],5'h0};
      else
        iadr <= {pc2[AWID-1:5],5'h0};
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
end
endtask

task tDecode;
input which;
begin
case(dstate)
DECODE:
  begin
    decode_done <= TRUE;
    dgoto (DWAIT);
    illegal_insn[which] <= TRUE;
    Rt[which] <= dir[which][25:21];
    Ra[which] <= dir[which][20:16];
    Rb[which] <= dir[which][15:11];
    Rc[which] <= dir[which][10: 6];
    BO[which] <= dir[which][25:21];
    BI[which] <= dir[which][20:16];
    case(dir[which][31:26])
    `R2:
      case(dir[which][10:1])
      `ADD: begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `SUBF:begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `NEG: begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `CMP: begin wrcrf <= TRUE; Bf[which] <= dir[which][25:23]; illegal_insn[which] <= FALSE; end
      `AND: begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `OR:  begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `XOR: begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `SLW: begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `SRW: begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `SRAW:begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      `SRAWI:begin wrcrf <= dir[which][0]; Bf[which] <= 3'd0; illegal_insn[which] <= FALSE; end
      default:  ;
      endcase
    `ADDI:  begin dimm[which] <= {{16{dir[which][15]}},dir[which][15:0]}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `ADDIS: begin dimm[which] <= {dir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `CMPI:  begin dimm[which] <= {{16{dir[which][15]}},dir[which][15:0]}; Bf[which] <= dir[which][25:23]; illegal_insn[which] <= FALSE; wrcrf <= TRUE; end
    `ANDI:  begin dimm[which] <= {16'hFFFF,dir[which][15:0]}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `ANDIS: begin dimm[which] <= {dir[which][15:0],16'hFFFF}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `ORI:   begin dimm[which] <= {16'h0000,dir[which][15:0]}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `ORIS:  begin dimm[which] <= {dir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `XORI:  begin dimm[which] <= {16'h0000,dir[which][15:0]}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `XORIS: begin dimm[which] <= {dir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; wrirf <= TRUE; end
    `B:     begin
              illegal_insn <= FALSE;
              d_modpc <= TRUE;
              if (dir[which][1])
                dnext_pc[which] <= {pc[which],dir[which][25:2],2'b00};
              else
                dnext_pc[which] <= {pc[which] + {{6{dir[which][25]}},dir[which][25:2],2'b00};
            end
    `BC:    illegal_insn <= FALSE;
    `BCx:   illegal_insn <= FALSE;
    `BCCTR: illegal_insn <= FALSE;
    `BCLR:  illegal_insn <= FALSE;
    default:  ;
    endcase
  end
DWAIT:
  if (advance_d) begin
    decode_done <= FALSE;
  end
endcase
end

task tRegFetch;
begin
case(rstate)
RFETCH:
  begin

    if (rRd==7'd0 && (r_ld|r_st) && r_val)
      id <= 32'd0;
    else if (rRd==eRd && eval)
      id <= eres;
    else if (rRd==mRd && mval)
      id <= mres;
    else if (rRd==wRd && wval)
      id <= wres;
    else
      id <= rfod;

    if (rRa==7'd0 && (r_ld|r_st) && rval)
      ia <= 32'd0;
    else if (rRa==eRd && eval)
      ia <= eres;
    else if (rRa==mRd && mval)
      ia <= mres;
    else if (rRa==wRd && wval)
      ia <= wres;
    else
      ia <= rfoa;

    if (rRb==7'd0 && (r_ld|r_st) && rval)
      ib <= 32'd0;
    else if (rRb==eRd && eval)
      ib <= eres;
    else if (rRb==mRd && mval)
      ib <= mres;
    else if (rRb==wRd && wval)
      ib <= wres;
    else
      ib <= rfob;

    if (rRc==7'd0 && (r_ld|r_st) && rval)
      ic <= 32'd0;
    else if (rRc==eRd && eval)
      ic <= eres;
    else if (rRc==mRd && mval)
      ic <= mres;
    else if (rRc==wRd && wval)
      ic <= wres;
    else
      ic <= rfoc;

    if (ewrcrf & eval)
      cra <= ecr;
    else if (mwrcrf & mval)
      cra <= mcr;
    else if (wwrcrf & wval)
      cra <= wcr;
    else
      cra <= croa;

    if (ewrcrf & eval)
      crb <= ecr;
    else if (mwrcrf & mval)
      crb <= mcr;
    else if (wwrcrf & wval)
      crb <= wcr;
    else
      crb <= crob;

  end
RWAIT:
  if (advance_r) begin
    regfetch_done <= FALSE;
    rgoto (RFETCH);
  end
endcase
end
endtask

task tExecute;
input which;
begin
case(estate[which])
EXECUTE:
  case(eir[which][31:26])
  `ADDI:  eres[which] <= ia[which] + imm[which];
  `ANDI,`ANDIS: eres[which] <= ia[which] & imm[which];
  `ORI,`ORIS:   eres[which] <= ia[which] | imm[which];
  `XORI,`XORIS: eres[which] <= ia[which] ^ imm[which];
  endcase
endcase
end
endtask

task tWriteback;
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
    wwRes <= wres[0];
    wwval <= wval[0];
    if (wval[1])
      wgoto(WRITEBACK1);
    else begin
      writeback_done <= TRUE;
      wgoto(WWAIT);
    end
  end
WRITEBACK1:
  begin
    wwRd <= wRd[1];
    wwRes <= wres[1];
    wwval <= wval[1];
    writeback_done <= TRUE;
    wgoto(WWAIT);
  end
WWAIT:
  if (advance_w) begin
    writeback_done <= FALSE;
    wgoto(WRITEBACK0);
  end
end
endtask

task igoto;
input [2:0] nst;
begin
  istate <= nst;
end
endtask

task dgoto;
input [1:0] nst;
  dstate <= nst;
end
endtask

endmodule
