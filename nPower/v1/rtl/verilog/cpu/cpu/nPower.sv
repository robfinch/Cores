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

module nPower(rst_i, clk_i, nmi_i, irq_i, icause_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
input [7:0] icause_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [AWID-1:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o = 128'd0;

integer n, j;
wire clk_g = clk_i;
reg [AWID-1:0] pc [0:1];
reg [31:0] ctr = 32'd0;
reg [AWID-1:0] lr = 32'd0;
reg smt = 1'b0;

// Instruction fetch stage vars
reg [3:0] istate;
reg [7:0] icause [0:1];
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
reg [7:0] dcause [0:1];
wire advance_d;
reg [1:0] decode_done;
reg [1:0] dval;
reg [31:0] ir [0:1];
reg [1:0] wrrf, wrcrf, rdcrf;
reg [1:0] wrlr, wrctr, rdlr, rdctr;
reg [1:0] wrxer, rdxer;
reg [AWID-1:0] dpc [0:1];
reg [5:0] Rd [0:1];
reg [5:0] Ra [0:1];
reg [5:0] Rb [0:1];
reg [5:0] Rc [0:1];
reg [4:0] Bt [1:0];
reg [4:0] Ba [1:0];
reg [4:0] Bb [1:0];
reg [31:0] dimm [0:1];
reg [1:0] dmod_pc;
reg [AWID-1:0] dnext_pc [0:1];
reg [1:0] illegal_insn;
reg [1:0] d_addi;
reg [1:0] d_ld, d_st;
reg [1:0] d_cmp;
reg [1:0] d_bc;
reg [1:0] d_sync;
reg [1:0] d_multicycle;
reg [1:0] lsu;

// Regfetch stage vars
reg [1:0] rstate;
reg [7:0] rcause [0:1];
wire advance_r;
wire [1:0] stall_r;
reg rdone;
reg [1:0] regfetch_done;
reg [1:0] rval;
reg [31:0] rir [0:1];
reg [1:0] rwrrf, rwrcrf, rrdcrf;
reg [1:0] rwrlr, rwrctr, rrdlr, rrdctr;
reg [1:0] rwrxer, rrdxer;
reg [AWID-1:0] rpc [0:1];
reg [5:0] rRd [0:1];
reg [5:0] rRa [0:1];
reg [5:0] rRb [0:1];
reg [5:0] rRc [0:1];
reg [4:0] rBa [0:1];
reg [4:0] rBb [0:1];
reg [31:0] rimm [0:1];
reg [31:0] rid [0:1];
reg [31:0] ria [0:1];
reg [31:0] rib [0:1];
reg [31:0] ric [0:1];
reg [1:0] r_lsu;
reg [1:0] r_ra0;
reg [1:0] r_ld, r_st;
reg [1:0] r_cmp;
reg [1:0] r_bc;
reg [1:0] r_sync;
reg [1:0] r_multicycle;
reg [31:0] rcr;
reg [AWID-1:0] rlr;
reg [31:0] rctr;
reg [31:0] rxer;

// Execute stage vars
reg [2:0] estate [0:1];
wire advance_e;
reg [1:0] execute_done;
reg [1:0] eval;
reg [31:0] eir [0:1];
reg [1:0] ewrrf, ewrcrf;
reg [1:0] ewrlr, ewrctr;
reg [1:0] ewrxer;
reg [AWID-1:0] epc [0:1];
reg [5:0] eRa [0:1];
reg [5:0] eRd [0:1];
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
reg [1:0] e_ra0;
reg [1:0] e_ld, e_st;
reg [1:0] e_lsu;
reg [1:0] e_cmp;
reg [1:0] e_bc;
reg [1:0] e_sync;
reg [1:0] e_multicycle;
reg [AWID-1:0] elr [0:1];
reg [31:0] ectr [0:1];
reg [31:0] ecr [0:1];
reg [31:0] exer [0:1];
reg [1:0] etrap;
reg [7:0] ecause [0:1];

// Memory stage vars
reg [2:0] mstate [0:1];
wire advance_m;
reg [AWID-1:0] mpc [0:1];
reg [1:0] memory_done;
reg [1:0] maccess_pending;
reg [1:0] mval;
reg [31:0] mir [0:1];
reg [5:0] mRa [0:1];
reg [5:0] mRd [0:1];
reg [1:0] mwrrf, mwrcrf;
reg [1:0] mwrlr, mwrctr;
reg [1:0] mwrxer;
reg [AWID-1:0] ea [0:1];
reg [31:0] mid [0:1];
reg [31:0] mia [0:1];
reg [31:0] mres [0:1];
reg [1:0] millegal_insn;
reg [1:0] m_lsu;
reg [1:0] m_st;
reg [1:0] m_sync;
reg [31:0] mcr [0:1];
reg [31:0] mctr [0:1];
reg [31:0] mxer [0:1];
reg [AWID-1:0] mlr [0:1];
reg [31:0] sel;
reg [255:0] dat = 256'd0, dati = 256'd0;
reg maccess;
reg [AWID-1:0] iadr;
reg [7:0] mcause [0:1];

// Writeback stage vars
reg [2:0] wstate;
wire advance_w;
reg writeback_done;
reg [AWID-1:0] wpc [0:1];
reg [31:0] wia [0:1];
reg [31:0] wwres;
reg [31:0] wres[0:1];
reg [AWID-1:0] wea [0:1];
reg [AWID-1:0] wwea;
reg [31:0] wir [0:1];
reg [5:0] wRa [0:1];
reg [5:0] wRd [0:1];
reg [5:0] wwRd;
reg wwval;
reg [1:0] wval;
reg wwwrrf;
reg wwwrcrf;
reg [1:0] wwrrf, wwrcrf;
reg [1:0] wwrlr, wwrctr;
reg [1:0] wwrxer;
reg wwwrlr, wwwrctr;
reg wwwrxer;
reg [1:0] willegal_insn;
reg [1:0] wmod_pc;
reg [AWID-1:0] wnext_pc [0:1];
reg [1:0] w_lsu;
reg [1:0] w_sync;
reg [31:0] wcr [0:1];
reg [31:0] wwcr;
reg [AWID-1:0] wlr [0:1];
reg [31:0] wctr [0:1];
reg [31:0] wxer [0:1];
reg [31:0] wwxer;
reg [7:0] wcause [0:1];

reg [31:0] tick;
reg [31:0] inst_ctr;
reg [31:0] inst_ctr2;
reg [31:0] stall_ctr;

reg [1:0] tval;
reg [1:0] twrrf;
reg [5:0] tRd [0:1];
reg [31:0] tres [0:1];

reg [31:0] msr;
wire ribo = msr[0];
wire le = msr[0];			// 1 = little endian, 0 = big endian operation
wire ri = msr[1];			// 1 = recoverable exception, 0 = not recoverable
// 2-3 reserved
wire dr = msr[4];			// 1 = translate data address
wire iar = msr[5];		// 1 = translate instruction address
wire ip = msr[6];			// exception prefix 1 = F's, 0 = 0's
// 7 reserved
wire fe1 = msr[8];		// bit 1 of floating point exception mode
wire be = msr[9];			// 0 = branch normally, 1 = trace branches (generate exceptions after branch)
wire se = msr[10];		// single step
wire fe0 = msr[11];		// bit 0 of floating point exception mode
wire mce = msr[12];		// 1 = machine check exceptions enabled, 0 = disabled
wire fp = msr[13];		// 1 = floating point can be executed, 0 = cannot execute fp instructions (fp available)
wire pr = msr[14];		// privilege level, 1=user, 0=supervisor
wire ee = msr[15];
wire ile = msr[16];		// 1 = Exception little endian mode, bit copied to msr[0] on exception
// 17 reserved
wire pow = msr[18];		// 0 power management disabled, 1 = power reduced mode
// 19 to 31 reserved

reg [31:0] srr0, srr1;
reg [31:0] xer = 32'd0;
reg [31:0] regfile [0:63];
initial begin
	for (n = 0; n < 64; n = n + 1)
		regfile[n] <= 32'd0;
end
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

reg [31:0] cregfile = 0;
wire [1:0] croa;
wire [1:0] crob;
assign croa[0] = cregfile[rBa[0]];
assign crob[0] = cregfile[rBb[0]];
assign croa[1] = cregfile[rBa[1]];
assign crob[1] = cregfile[rBb[1]];
wire [31:0] cro = cregfile;

always @(posedge clk_g)
  if (wwwrxer)
    xer <= wwxer;
always @(posedge clk_g)
  if (wwwrcrf)
    cregfile <= wwcr;
always @(posedge clk_g)
  if (wwwrlr)
    lr <= wwres;
always @(posedge clk_g)
  if (wwwrctr)
    ctr <= wwres;
    
reg [31:0] sprg [0:3];

// If there is a sync in the pipeline stall the following stages until the sync clears.
assign stall_i = |d_sync | |r_sync | |e_sync | |m_sync | |w_sync;
assign stall_r[0] = ((e_ld[0]||e_st[0]) && ((rRd[0]==eRd[0] && r_st[0]) || (rRa[0]==eRd[0]) || (rRb[0]==eRd[0]) || (rRc[0]==eRd[0])) && eval[0] && rval[0]) ||
								 	  ((e_ld[1]||e_st[1]) && ((rRd[0]==eRd[1] && r_st[0]) || (rRa[0]==eRd[1]) || (rRb[0]==eRd[1]) || (rRc[0]==eRd[1])) && eval[1] && rval[1]) ||
                		((e_st[0] & e_lsu[0]) && ((rRd[0]==eRa[0]) || (rRa[0]==eRa[0]) || (rRb[0]==eRa[0]) || (rRc[0]==eRa[0])) && eval[0] && rval[0]) ||
								 	  ((e_st[1] & e_lsu[1]) && ((rRd[0]==eRa[1]) || (rRa[0]==eRa[1]) || (rRb[0]==eRa[1]) || (rRc[0]==eRa[1])) && eval[1] && rval[1]) //||
								 	  /*
								 	  ((rrdlr[0] & ewrlr[0]) || (rrdctr[0] & ewrctr[0]) || (rrdxer[0] & ewrxer[0]) || (rrdcrf[0] & ewrcrf[0]) && rval[0] && eval[0]) ||
								 	  ((rrdlr[0] & ewrlr[1]) || (rrdctr[0] & ewrctr[1]) || (rrdxer[0] & ewrxer[1]) || (rrdcrf[0] & ewrcrf[1]) && rval[0] && eval[1])
								 	  */
                		;
assign stall_r[1] = stall_r[0] ||
										((rRd[1]==rRd[0] || rRa[1]==rRd[0] || rRb[1]==rRd[0] || rRc[1]==rRd[0]) && rval[0] && rval[1] && rwrrf[0]) ||
								 		((e_ld[0]||e_st[0]) && ((rRd[1]==eRd[0] && r_st[1]) || (rRa[1]==eRd[0]) || (rRb[1]==eRd[0]) || (rRc[1]==eRd[0])) && eval[0] && rval[1]) ||
								 	 	((e_ld[1]||e_st[1]) && ((rRd[1]==eRd[1] && r_st[1]) || (rRa[1]==eRd[1]) || (rRb[1]==eRd[1]) || (rRc[1]==eRd[1])) && eval[1] && rval[1]) ||
								 		((e_st[0] & e_lsu[0]) && ((rRd[1]==eRa[0]) || (rRa[1]==eRa[0]) || (rRb[1]==eRa[0]) || (rRc[1]==eRa[0])) && eval[0] && rval[1]) ||
								 	 	((e_st[1] & e_lsu[1]) && ((rRd[1]==eRa[1]) || (rRa[1]==eRa[1]) || (rRb[1]==eRa[1]) || (rRc[1]==eRa[1])) && eval[1] && rval[1]) ||
								 	  //((rrdlr[1] & ewrlr[0]) || (rrdctr[1] & ewrctr[0]) || (rrdxer[1] & ewrxer[0]) || (rrdcrf[1] & ewrcrf[0]) && rval[1] && eval[0]) ||
								 	  //((rrdlr[1] & ewrlr[1]) || (rrdctr[1] & ewrctr[1]) || (rrdxer[1] & ewrxer[1]) || (rrdcrf[1] & ewrcrf[1]) && rval[1] && eval[1]) ||
								 	  ((rrdlr[1] & rwrlr[0]) || (rrdctr[1] & rwrctr[0]) || (rrdxer[1] & rwrxer[0]) || (rrdcrf[1] & rwrcrf[0]) && rval[1] && rval[0])
                	  ;
                /*
                || (e_crop && r_crop && (rBa==eBt) || (rBb==eBt) && eval && rval)
                || (r_bc && e_crop && (rBi==eBt) && eval && rval)
                ;
                */

// Pipeline advance
assign advance_w = ifetch_done & &decode_done & &regfetch_done & &execute_done & &memory_done & &writeback_done;
assign advance_m = advance_w & ~(|w_sync);
assign advance_e = advance_m & ~(|m_sync | |w_sync);
assign advance_r = advance_e & ~stall_r[0] & ~(|e_sync | |m_sync | |w_sync);
assign advance_d = advance_r & ~|stall_r & ~(|r_sync | |e_sync | |m_sync | |w_sync);
assign advance_i = advance_d & ~stall_i;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage combo logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [63:0] shli [0:1];
wire [31:0] roli [0:1];
wire [63:0] shlr [0:1];
wire [31:0] rolr [0:1];
assign shli[0] = {32'h0,ia[0]} << eir[0][15:11];
assign shli[1] = {32'h0,ia[1]} << eir[1][15:11];
assign shlr[0] = {32'h0,ia[0]} << ib[0][4:0];
assign shlr[1] = {32'h0,ia[1]} << ib[1][4:0];
assign roli[0] = shli[0][63:32]|shli[0][31:0];
assign roli[1] = shli[1][63:32]|shli[1][31:0];
assign rolr[0] = shlr[0][63:32]|shlr[0][31:0];
assign rolr[1] = shlr[1][63:32]|shlr[1][31:0];
wire [4:0] mb [0:1];
wire [4:0] me [0:1];
assign mb[0] = eir[0][10:6];
assign me[0] = eir[0][ 5:1];
assign mb[1] = eir[1][10:6];
assign me[1] = eir[1][ 5:1];
reg [31:0] rlwimi_o [0:1];
reg [31:0] rlwinm_o [0:1];
reg [31:0] rlwnm_o  [0:1];

always @*
begin
  for (j = 0; j < 2; j = j + 1) begin
    for (n = 0; n < 32; n = n + 1) begin
      if (n >= mb[j] && n <= me[j])
        rlwimi_o[j][n] <= roli[j][n];
      else
        rlwimi_o[j][n] <= id[j][n];
    end
  end
end

always @*
begin
  for (j = 0; j < 2; j = j + 1) begin
    for (n = 0; n < 32; n = n + 1) begin
      if (n >= mb[j] && n <= me[j])
        rlwinm_o[j][n] <= roli[j][n];
      else
        rlwinm_o[j][n] <= 1'b0;
    end
  end
end

always @*
begin
  for (j = 0; j < 2; j = j + 1) begin
    for (n = 0; n < 32; n = n + 1) begin
      if (n >= mb[j] && n <= me[j])
        rlwnm_o[j][n] <= rolr[j][n];
      else
        rlwnm_o[j][n] <= 1'b0;
    end
  end
end

wire [63:0] prodr [0:1];
wire [63:0] prodi [0:1];
assign prodr[0] = $signed(ia[0]) * $signed(ib[0]);
assign prodr[1] = $signed(ia[1]) * $signed(ib[1]);
assign prodi[0] = $signed(ia[0]) * $signed(imm[0]);
assign prodi[1] = $signed(ia[1]) * $signed(imm[1]);

wire [31:0] cntlzo [1:0];

cntlz32 uclz1 (
	.i(ia[0]),
	.o(cntlzo[0])
);

cntlz32 uclz2 (
	.i(ia[1]),
	.o(cntlzo[1])
);

reg [1:0] alu_ld;
reg [1:0] div_sign;
wire [1:0] div_done;
wire [127:0] divo1 [0:1];
wire [63:0] divo [0:1];

divr2 #(.FPWID(32)) udv1
(
	.clk4x(clk_g),
	.ld(alu_ld[0]),
	.a(ia[0]),
	.b(ib[0]),
	.q(divo[0]),
	.r(),
	.done(div_done[0]),
	.lzcnt()
);

divr2 #(.FPWID(32)) udv2
(
	.clk4x(clk_g),
	.ld(alu_ld[1]),
	.a(ia[1]),
	.b(ib[1]),
	.q(divo[1]),
	.r(),
	.done(div_done[1]),
	.lzcnt()
);

/* Include this with a huge FPGA for better performance
assign divo[0] = divo1[0][95:64]; 
assign divo[1] = divo1[1][95:64]; 
DivGoldschmidt  #(.FPWID(64),.WHOLE(32),.POINTS(32)) udgs1
(
	.rst(rst_i),
	.clk(clk_g),
	.ld(alu_ld[0]),
	.a({ia[0],32'd0}),
	.b({ib[0],32'd0}),
	.q(divo1[0]),
	.done(div_done[0]),
	.lzcnt()
);

DivGoldschmidt  #(.FPWID(64),.WHOLE(32),.POINTS(32)) udgs2
(
	.rst(rst_i),
	.clk(clk_g),
	.ld(alu_ld[1]),
	.a({ia[1],32'd0}),
	.b({ib[1],32'd0}),
	.q(divo1[1]),
	.done(div_done[1]),
	.lzcnt()
);
*/

wire [4:0] trp [0:1];
wire [4:0] trpr [0:1];

assign trp[0][0] = $signed(ia[0]) < $signed(imm[0]);
assign trp[0][1] = $signed(ia[0]) > $signed(imm[0]);
assign trp[0][2] = ia[0] == imm[0];
assign trp[0][3] = ia[0] < imm[0];
assign trp[0][4] = ia[0] > imm[0];

assign trp[1][0] = $signed(ia[1]) < $signed(imm[1]);
assign trp[1][1] = $signed(ia[1]) > $signed(imm[1]);
assign trp[1][2] = ia[1] == imm[1];
assign trp[1][3] = ia[1] < imm[1];
assign trp[1][4] = ia[1] > imm[1];

assign trpr[0][0] = $signed(ia[0]) < $signed(ib[0]);
assign trpr[0][1] = $signed(ia[0]) > $signed(ib[0]);
assign trpr[0][2] = ia[0] == ib[0];
assign trpr[0][3] = ia[0] < ib[0];
assign trpr[0][4] = ia[0] > ib[0];

assign trpr[1][0] = $signed(ia[1]) < $signed(ib[1]);
assign trpr[1][1] = $signed(ia[1]) > $signed(ib[1]);
assign trpr[1][2] = ia[1] == ib[1];
assign trpr[1][3] = ia[1] < ib[1];
assign trpr[1][4] = ia[1] > ib[1];

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
reg [AWID-1:5] ictag0 [0:pL1CacheLines-1];
reg [AWID-1:5] ictag1 [0:pL1CacheLines-1];
reg [AWID-1:5] ictag2 [0:pL1CacheLines-1];
reg [AWID-1:5] ictag3 [0:pL1CacheLines-1];
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
always @*	//(posedge clk_g)
  ihit1a <= ictag0[pc[0][pL1msb:5]]==pc[0][AWID-1:5] && icvalid0[pc[0][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit1b <= ictag1[pc[0][pL1msb:5]]==pc[0][AWID-1:5] && icvalid1[pc[0][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit1c <= ictag2[pc[0][pL1msb:5]]==pc[0][AWID-1:5] && icvalid2[pc[0][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit1d <= ictag3[pc[0][pL1msb:5]]==pc[0][AWID-1:5] && icvalid3[pc[0][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit2a <= ictag0[pc[1][pL1msb:5]]==pc[1][AWID-1:5] && icvalid0[pc[1][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit2b <= ictag1[pc[1][pL1msb:5]]==pc[1][AWID-1:5] && icvalid1[pc[1][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit2c <= ictag2[pc[1][pL1msb:5]]==pc[1][AWID-1:5] && icvalid2[pc[1][pL1msb:5]];
always @*	//(posedge clk_g)
  ihit2d <= ictag3[pc[1][pL1msb:5]]==pc[1][AWID-1:5] && icvalid3[pc[1][pL1msb:5]];
wire ihit1 = ihit1a|ihit1b|ihit1c|ihit1d;
wire ihit2 = ihit2a|ihit2b|ihit2c|ihit2d;
initial begin
  icvalid0 = {pL1CacheLines{1'd0}};
  icvalid1 = {pL1CacheLines{1'd0}};
  icvalid2 = {pL1CacheLines{1'd0}};
  icvalid3 = {pL1CacheLines{1'd0}};
  for (n = 0; n < pL1CacheLines; n = n + 1) begin
  	if (RIBO) begin
	  	icache0[n] <= {8{{NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]}}};
	  	icache1[n] <= {8{{NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]}}};
	  	icache2[n] <= {8{{NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]}}};
	  	icache3[n] <= {8{{NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]}}};
  	end
  	else begin
	  	icache0[n] <= {8{NOP_INSN}};
	  	icache1[n] <= {8{NOP_INSN}};
	  	icache2[n] <= {8{NOP_INSN}};
	  	icache3[n] <= {8{NOP_INSN}};
  	end
    ictag0[n] = 32'd1;
    ictag1[n] = 32'd1;
    ictag2[n] = 32'd1;
    ictag3[n] = 32'd1;
  end
end


reg [1:0] takb;
wire [1:0] ibrpred;
reg [1:0] dbrpred, rbrpred, ebrpred;

perceptronPredictor upp1
(
  .rst(rst_i),
  .clk(clk_g),
  .id_i(8'h00),
  .id_o(),
  .xbr(e_bc[0] & advance_e),
  .xadr(epc[0]),
  .prediction_i(ebrpred[0]),
  .outcome(takb[0]),
  .adr(pc[0]),
  .prediction_o(ibrpred[0])
);

perceptronPredictor upp2
(
  .rst(rst_i),
  .clk(clk_g),
  .id_i(8'h00),
  .id_o(),
  .xbr(e_bc[1] & advance_e),
  .xadr(epc[1]),
  .prediction_i(ebrpred[1]),
  .outcome(takb[1]),
  .adr(pc[1]),
  .prediction_o(ibrpred[1])
);


always @(posedge clk_g)
if (rst_i)
	tick <= 32'd0;
else
	tick <= tick + 1'd1;

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
  pc[1] <= RSTPC+3'd4;
  adr_o <= RSTPC;
  iadr <= RSTPC;
  iri1 <= {8{NOP_INSN}};
  iri2 <= {8{NOP_INSN}};
  ifetch_done <= FALSE;
  ifetch1_done <= FALSE;
  ifetch2_done <= FALSE;
  iaccess <= FALSE;
  inst_ctr <= 32'd0;
  inst_ctr2 <= 32'd0;
  msr <= 32'd1;		// little endian mode
  igoto (IFETCH1);
end
else begin
case(istate)

IFETCH0:
	igoto (IFETCH1);
/*
IFETCH0a:
  if (!(ihit1 && ihit2)) begin
    icnt <= 2'd0;
    igoto (IACCESS);
  end
  else
		igoto (IFETCH0b);
IFETCH0b:
	igoto (IFETCH1);
*/
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
    if (!(ifetch1_done && ifetch2_done))
    	igoto (IFETCH1);
    else if (!(ihit1 && ihit2)) begin
      icnt <= 2'd0;
      igoto (IACCESS);
    end
    else begin
	    ifetch_done <= TRUE;
  	  igoto (IWAIT);
    end
  end
IWAIT:
  if (advance_i) begin
  	dval <= 2'b11;
  	if (RIBO) begin
	    ir[0] <= {iir[0][7:0],iir[0][15:8],iir[0][23:16],iir[0][31:24]};
	    ir[1] <= {iir[1][7:0],iir[1][15:8],iir[1][23:16],iir[1][31:24]};
	  end
	  else begin
	  	ir[0] <= iir[0];
	  	ir[1] <= iir[1];
	  end
	  if (smt) begin
			// PC[0]
	    if (wmod_pc[0])
	      pc[0] <= wnext_pc[0];
	    else if (emod_pc[0])
	      pc[0] <= enext_pc[0];
	    else if (dmod_pc[0])
	      pc[0] <= dnext_pc[0];
	    else
	      pc[0] <= pc[0] + 4'd4;
			// PC[1]
	    if (wmod_pc[1])
	      pc[1] <= wnext_pc[1];
	    else if (emod_pc[1])
	      pc[1] <= enext_pc[1];
	    else if (dmod_pc[1])
	      pc[1] <= dnext_pc[1];
	    else
	      pc[1] <= pc[1] + 4'd4;
		end
		else begin
	    if (wmod_pc[0]) begin
	      pc[0] <= wnext_pc[0];
	      pc[1] <= wnext_pc[0] + 3'd4;
	      if (be) dcause[0] <= FLT_TRACE;
	    end
	    else if (wmod_pc[1]) begin
	      pc[0] <= wnext_pc[1];
	      pc[1] <= wnext_pc[1] + 3'd4;
	      if (be) dcause[0] <= FLT_TRACE;
	    end
	    else if (emod_pc[0]) begin
	      pc[0] <= enext_pc[0];
	      pc[1] <= enext_pc[0] + 3'd4;
	      if (be) dcause[0] <= FLT_TRACE;
	    end
	    else if (emod_pc[1]) begin
	      pc[0] <= enext_pc[1];
	      pc[1] <= enext_pc[1] + 3'd4;
	      if (be) dcause[0] <= FLT_TRACE;
	    end
	    else if (dmod_pc[0]) begin
	      pc[0] <= dnext_pc[0];
	      pc[1] <= dnext_pc[0] + 3'd4;
	      if (be) dcause[0] <= FLT_TRACE;
	    end
	    else if (dmod_pc[1]) begin
	      pc[0] <= dnext_pc[1];
	      pc[1] <= dnext_pc[1] + 3'd4;
	      if (be) dcause[0] <= FLT_TRACE;
	    end
	    else begin
	      pc[0] <= pc[0] + 4'd8;
	      pc[1] <= pc[0] + 4'd12;
	    end
  	end
    ifetch1_done <= FALSE;
    ifetch2_done <= FALSE;
    ifetch_done <= FALSE;
    dpc[0] <= pc[0];
    dpc[1] <= pc[1];
    dbrpred <= ibrpred;
    if (irq_i & ee) begin
    	dcause[0] <= icause_i|8'h80;
    	dcause[1] <= icause_i|8'h80;
  	end
  	else begin
    	dcause[0] <= FLT_NONE;
    	dcause[1] <= FLT_NONE;
  	end  
    igoto(IFETCH1);
  end
  else if (advance_d)
  	d_sync <= 2'b00;
IACCESS:
  begin
    if (maccess_pending==2'b00||vpa_o) begin
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
      iadr <= {iadr[AWID-1:4],4'h0} + 5'h10;
  end
IACCESS_CYC:
  begin
    if (~ack_i) begin
      vpa_o <= HIGH;
      cyc_o <= HIGH;
      stb_o <= HIGH;
      we_o <= LOW;
      sel_o <= 16'hFFFF;
      adr_o <= iadr;
      igoto(IACCESS_ACK);
    end
  end
IACCESS_ACK:
  if (ack_i) begin
    icnt <= icnt + 1'd1;
    case(icnt)
    2'd0: ici[127:  0] <= dat_i;
    2'd1: ici[255:128] <= dat_i;
    endcase
    if (icnt==2'd1) begin
      vpa_o <= LOW;
      cyc_o <= LOW;
      stb_o <= LOW;
      iaccess <= FALSE;
      igoto (IC_UPDATE);
    end
    else begin
      stb_o <= LOW;
      iadr <= {iadr[AWID-1:4],4'h0} + 5'h10;
      igoto (IACCESS_CYC);
    end
  end
IC_UPDATE:
  begin
    case (waycnt)
    2'd0: ictag0[iadr[pL1msb:5]] <= iadr[AWID-1:5];
    2'd1: ictag1[iadr[pL1msb:5]] <= iadr[AWID-1:5];
    2'd2: ictag2[iadr[pL1msb:5]] <= iadr[AWID-1:5];
    2'd3: ictag3[iadr[pL1msb:5]] <= iadr[AWID-1:5];
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
    igoto (ICU1);
  end
ICU1:
  igoto(IFETCH1);
ICU2:
  igoto(IFETCH0);
default:
  begin
    //ifetch_done <= TRUE;
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
    rRd[which] <= 6'd0;
    rRa[which] <= 6'd0;
    rRb[which] <= 6'd0;
    rRc[which] <= 6'd0;
    rimm[which] <= 32'd0;
    Rd[which] <= 6'd0;
    Ra[which] <= 6'd0;
    Rb[which] <= 6'd0;
    Rc[which] <= 6'd0;
    dimm[which] <= 32'd0;
    d_ld[which] <= FALSE;
    d_st[which] <= FALSE;
    d_addi[which] <= FALSE;
    d_cmp[which] <= FALSE;
    d_bc[which] <= FALSE;
    d_multicycle[which] <= FALSE;
    dbrpred[which] <= FALSE;
    rbrpred[which] <= FALSE;
    r_ld[which] <= FALSE;
    r_st[which] <= FALSE;
    r_ra0[which] <= FALSE;
    r_lsu[which] <= FALSE;
    r_cmp[which] <= FALSE;
    r_sync[which] <= FALSE;
    r_bc[which] <= FALSE;
    r_multicycle[which] <= FALSE;
    rcr[which] <= 32'd0;
    rctr[which] <= 32'd0;
    rlr[which] <= 32'd0;
    rxer[which] <= 32'd0;
    rwrcrf[which] <= FALSE;
    rwrctr[which] <= FALSE;
    rwrlr[which] <= FALSE;
    rwrrf[which] <= FALSE;
    rwrxer[which] <= FALSE;
    wrctr[which] <= FALSE;
    wrlr[which] <= FALSE;
    wwcr[which] <= FALSE;
    rrdxer[which] <= FALSE;
    rrdcrf[which] <= FALSE;
    rrdctr[which] <= FALSE;
    rrdlr[which] <= FALSE;
    rdxer[which] <= FALSE;
    rdcrf[which] <= FALSE;
    rdctr[which] <= FALSE;
    rdlr[which] <= FALSE;
    wwea[which] <= FALSE;
    wwrctr[which] <= FALSE;
    wrrf[which] <= FALSE;
    wrcrf[which] <= FALSE;
    wrxer[which] <= FALSE;
    lsu[which] <= FALSE;
    rpc[which] <= RSTPC;
    dval[which] <= 1'b0;
    decode_done[which] <= TRUE;
    dstate[which] <= DWAIT;
    illegal_insn[which] <= FALSE;
    dnext_pc[which] <= RSTPC;
    rcause[which] <= FLT_NONE;
  end
  else begin
    case(dstate[which])
    DECODE:
      begin
        decode_done[which] <= TRUE;
       	dstate[which] <= DWAIT;
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
        wrxer[which] <= FALSE;
        wrlr[which] <= FALSE;
        wrctr[which] <= FALSE;
        rdxer[which] <= FALSE;
        rdcrf[which] <= FALSE;
        rdctr[which] <= FALSE;
        rdlr[which] <= FALSE;
        dmod_pc[which] <= FALSE;
        d_bc[which] <= FALSE;
        d_cmp[which] <= FALSE;
        d_ld[which] <= FALSE;
        d_st[which] <= FALSE;
        d_addi[which] <= FALSE;
		    d_multicycle[which] <= FALSE;
        dimm[which] <= 32'd0;
		    dnext_pc[which] <= RSTPC;
        case(ir[which][31:26])
        R2:
          case(ir[which][10:1])
          ADD,ADDO,ADDC,ADDCO,ADDE,ADDEO,ADDME,ADDMEO,ADDZE,ADDZEO:
          	begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          SUBFME,SUBFMEO,SUBFZE,SUBFZEO,SUBFC,SUBFCO,SUBFE,SUBFEO:
          	begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          SUBF,SUBFO:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          NEG: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          CMP: begin wrcrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_cmp[which] <= TRUE; end
          CMPL:begin wrcrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_cmp[which] <= TRUE; end
          MULLW: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          MULLWO: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; wrxer[which] <= TRUE; illegal_insn[which] <= FALSE; end
          DIVW:		begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; d_multicycle[which] <= TRUE; end
          DIVWO:	begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; wrxer[which] <= TRUE; illegal_insn[which] <= FALSE; d_multicycle[which] <= TRUE; end
          DIVWU:	begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; d_multicycle[which] <= TRUE; end
          DIVWUO: begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; wrxer[which] <= TRUE; illegal_insn[which] <= FALSE; d_multicycle[which] <= TRUE; end
          AND,ANDC,OR,ORC,XOR,NAND,NOR,EQV,SLW,SRW,SRAW:
          	begin
          		Ra[which] <= ir[which][25:21];
          		Rd[which] <= ir[which][20:16];
          		wrrf[which] <= TRUE;
          		wrcrf[which] <= ir[which][0];
          		illegal_insn[which] <= FALSE;
          	end
          SRAWI:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          EXTSB:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          EXTSH:begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          CNTLZW:	begin wrrf[which] <= TRUE; wrcrf[which] <= ir[which][0]; illegal_insn[which] <= FALSE; end
          LBZX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          LHZX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          LHAX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          LWZX:   begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
          STBX:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
          STHX:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
          STWX:   begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
          LBZUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          LHZUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          LHAUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          LWZUX:  begin wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE; end
          STBUX:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
          STHUX:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
          STWUX:  begin illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
          MCRXR:  begin wrcrf[which] <= TRUE; wrxer[which] <= TRUE; illegal_insn <= FALSE; end
          MFCR:   begin wrrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          MTCRF:  begin wrcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          MFSPR:
          	begin
              case(eir[which][20:11])
              10'd32:	rdxer[which] <= TRUE;
              10'd256:	rdlr[which] <= TRUE;
              10'd288:	rdctr[which] <= TRUE;
            	endcase
          		wrrf[which] <= TRUE;
          		illegal_insn[which] <= FALSE;
          	end
          MTSPR:
            begin
              case(eir[which][20:11])
              10'd32:   begin wrxer[which] <= TRUE; illegal_insn[which] <= FALSE; end
              10'd256:  begin wrlr[which] <= TRUE; illegal_insn[which] <= FALSE; end
              10'd288:  begin wrctr[which] <= TRUE; illegal_insn[which] <= FALSE; end
              default:  ;
              endcase
            end
          SYNC:
          	begin
          		// force a flush of the incoming instruction.
          		dmod_pc[which] <= TRUE;
          		dnext_pc[which] <= dpc[which] + 3'd4;
          		d_sync[which] <= TRUE;
          		illegal_insn[which] <= FALSE;
          	end
	        TW:	 begin illegal_insn[which] <= FALSE; end
          default:  ;
          endcase
        ADDI:
        	begin
        		d_addi[which] <= TRUE;
        		wrrf[which] <= TRUE;
        		dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]};
        		illegal_insn[which] <= FALSE;
        	end
        ADDIC:
        	begin
        		wrrf[which] <= TRUE;
        		dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]};
        		illegal_insn[which] <= FALSE;
        	end
        ADDICD:
        	begin
        		wrrf[which] <= TRUE;
        		wrcrf[which] <= TRUE;
        		dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]};
        		illegal_insn[which] <= FALSE;
        	end
        ADDIS:
        	begin
        		d_addi[which] <= TRUE;
        		wrrf[which] <= TRUE;
        		dimm[which] <= {ir[which][15:0],16'h0000};
        		illegal_insn[which] <= FALSE;
        	end
        SUBFIC:
        	begin
        		wrrf[which] <= TRUE;
        		dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]};
        		illegal_insn[which] <= FALSE;
        	end
        CMPI:  begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; wrcrf[which] <= TRUE; d_cmp[which] <= TRUE; end
        CMPLI: begin dimm[which] <= {16'h0000,ir[which][15:0]}; illegal_insn[which] <= FALSE; wrcrf[which] <= TRUE; d_cmp[which] <= TRUE; end
        MULLI: begin wrrf[which] <= TRUE; dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        ANDI:  begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= {16'hFFFF,ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        ANDIS: begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'hFFFF}; illegal_insn[which] <= FALSE; end
        ORI:   begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= {16'h0000,ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        ORIS:  begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; end
        XORI:  begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= {16'h0000,ir[which][15:0]}; illegal_insn[which] <= FALSE; end
        XORIS: begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= {ir[which][15:0],16'h0000}; illegal_insn[which] <= FALSE; end
        RLWIMI:begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= ir[which][15:11]; illegal_insn[which] <= FALSE; end
        RLWINM:begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; dimm[which] <= ir[which][15:11]; illegal_insn[which] <= FALSE; end
        RLWNM: begin Ra[which] <= ir[which][25:21]; Rd[which] <= ir[which][20:16]; wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
        TWI:	 begin illegal_insn[which] <= FALSE; end
				SC:		 begin illegal_insn[which] <= ~ir[which][1]; end
        B:     begin
                  illegal_insn[which] <= FALSE;
                  dmod_pc[which] <= dval[which];
                  if (ir[which][1])
                    dnext_pc[which] <= {dpc[which],ir[which][25:2],2'b00};
                  else
                    dnext_pc[which] <= dpc[which] + {{6{ir[which][25]}},ir[which][25:2],2'b00};
                  wrlr[which] <= ir[which][0];
                end
        BC:
        	begin
        		d_bc[which] <= TRUE;
        		wrlr[which] <= ir[which][0];
        		rdcrf[which] <= TRUE;
        		if (dbrpred[which]) begin
        			dmod_pc[which] <= dval[which];
    					if (eir[which][1])
    						dnext_pc[which] <= {{16{ir[which][15]}},ir[which][15:2],2'b00};
    					else
    						dnext_pc[which] <= dpc[which] + {{16{ir[which][15]}},ir[which][15:2],2'b00};
        		end
        		illegal_insn[which] <= FALSE;
        	end
        CR2:
          case(ir[which][10:1])
          BCCTR:
          	begin
      				wrlr[which] <= ir[which][0];
      				rdctr[which] <= TRUE;
      				rdcrf[which] <= TRUE;
      				illegal_insn[which] <= FALSE;
      			end
          BCLR:
          	begin
          		wrlr[which] <= ir[which][0];
          		rdlr[which] <= TRUE;
          		rdcrf[which] <= TRUE;
          		illegal_insn[which] <= FALSE;
          	end
          CRAND: begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CROR:  begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CRXOR: begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CRNAND:begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CRNOR: begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CREQV: begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CRANDC:begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          CRORC: begin wrcrf[which] <= TRUE; rdcrf[which] <= TRUE; illegal_insn[which] <= FALSE; end
          RFI:
          	begin
          		if (dval[which]) begin
          			dmod_pc[which] <= TRUE;
          			dnext_pc[which] <= srr1;
          		end
          	end
          default:  ;
          endcase

        LBZ,LHZ,LHA,LWZ:  
        	begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; end
        LBZU,LHZU,LHAU,LWZU:
        	begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; wrrf[which] <= TRUE; illegal_insn[which] <= FALSE; d_ld[which] <= TRUE; lsu[which] <= TRUE;	end
        STB:   begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
        STH:   begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
        STW:   begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; d_st[which] <= TRUE; end
        STBU:  begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
        STHU:  begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
        STWU:  begin dimm[which] <= {{16{ir[which][15]}},ir[which][15:0]}; illegal_insn[which] <= FALSE; d_st[which] <= TRUE; lsu[which] <= TRUE; end
        default:  ;
        endcase
      end
    DWAIT:
      if (advance_d) begin
      	rval <= dval;
        rir[which] <= ir[which];
        rpc[which] <= dpc[which];
        rRd[which] <= Rd[which];
        rRa[which] <= Ra[which];
        rRb[which] <= Rb[which];
        rRc[which] <= Rc[which];
        rBa[which] <= Ba[which];
        rBb[which] <= Bb[which];
        rrdlr[which] <= rdlr[which];
        rrdctr[which] <= rdctr[which];
        rrdxer[which] <= rdxer[which];
        rrdcrf[which] <= rdcrf[which];
        rwrlr[which] <= wrlr[which];
        rwrctr[which] <= wrctr[which];
        rimm[which] <= dimm[which];
        r_lsu[which] <= lsu[which];
        r_ld[which] <= d_ld[which];
        r_st[which] <= d_st[which];
        r_cmp[which] <= d_cmp[which];
        if (d_ld[which]|d_st[which]|d_addi[which])
        	r_ra0[which] <= ir[which][20:16]==5'd0;
        r_sync[which] <= d_sync[which];
        r_bc[which] <= d_bc[which];
        r_multicycle[which] <= d_multicycle[which];
        rwrrf[which] <= wrrf[which];
        rwrcrf[which] <= wrcrf[which];
        rwrxer[which] <= wrxer[which];
        rbrpred[which] <= dbrpred[which];
        rcause[which] <= dcause[which];
        decode_done[which] <= FALSE;
        dstate[which] <= DECODE;
      end
      else if (advance_r)
      	r_sync[which] <= FALSE;
    default:
      begin
        decode_done[which] <= TRUE;
        dstate[which] <= DWAIT;
      end
    endcase
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register Fetch Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire fwd  = rRa[0]==eRd[1] && eval[1] && ewrrf[1];
wire fwd3 = rRa[0]==eRd[0] && eval[0] && ewrrf[0];

task tRegFetch;
if (rst_i) begin
  e_ld <= 2'b00;
  e_st <= 2'b00;
  e_ra0 <= 2'b00;
  e_lsu <= 2'b00;
  e_bc <= 2'b00;
  e_sync <= 2'b00;
  e_multicycle <= 2'b00;
  eRd[0] <= 6'd0;
  eRd[1] <= 6'd0;
  eRa[0] <= 6'd0;
  eRa[1] <= 6'd0;
  eres[0] <= 32'd0;
  eres[1] <= 32'd0;
  id[0] <= 32'd0;
  id[1] <= 32'd0;
  ia[0] <= 32'd0;
  ia[1] <= 32'd0;
  ib[0] <= 32'd0;
  ib[1] <= 32'd0;
  ic[0] <= 32'd0;
  ic[1] <= 32'd0;
  rid[0] <= 32'd0;
  rid[1] <= 32'd0;
  ria[0] <= 32'd0;
  ria[1] <= 32'd0;
  rib[0] <= 32'd0;
  rib[1] <= 32'd0;
  ric[0] <= 32'd0;
  ric[1] <= 32'd0;
  rimm[0] <= 32'd0;
  rimm[1] <= 32'd0;
  imm[0] <= 32'd0;
  imm[1] <= 32'd0;
  ectr[0] <= 32'd0;
  ectr[1] <= 32'd0;
  ecr[0] <= 32'd0;
  ecr[1] <= 32'd0;
  exer[0] <= 32'd0;
  exer[1] <= 32'd0;
  elr[0] <= 32'd0;
  elr[1] <= 32'd0;
  eillegal_insn <= 2'b00;
  ewrcrf <= 2'b00;
  ewrlr <= 2'b00;
  ewrctr <= 2'b00;
  ewrrf <= 2'b00;
  ewrxer <= 2'b00;
  rval <= 2'b00;
  ebrpred <= 2'b00;
  ecause[0] <= FLT_NONE;
  ecause[1] <= FLT_NONE;
  regfetch_done[0] <= TRUE;
  regfetch_done[1] <= TRUE;
  stall_ctr <= 32'd0;
  rgoto(RWAIT);
end
else begin
case(rstate)
RFETCH:
  begin
  	// Register fetch bypassing needs the output of the execute, memory and
  	// writeback stages. The output is available only when they are done.
/*  	
  	regfetch_done[0] <= &execute_done & &memory_done & writeback_done;
  	regfetch_done[1] <= &execute_done & &memory_done & writeback_done;
    if (&execute_done & &memory_done & writeback_done)
    	rgoto(RWAIT);
*/
  	regfetch_done <= 2'b11;
   	rgoto(RWAIT);

//    tin(0,rRd[0],rfod[0],rid[0]);
//    tin(1,rRd[1],rfod[1],rid[1]);
//    tin(0,rRa[0],rfoa[0],ria[0]);
//    tin(1,rRa[1],rfoa[1],ria[1]);
//    tin(0,rRb[0],rfob[0],rib[0]);
//    tin(1,rRb[1],rfob[1],rib[1]);
//    tin(0,rRc[0],rfoc[0],ric[0]);
//    tin(1,rRc[1],rfoc[1],ric[1]);

/*
		if (smt) begin
		end
		else begin
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

	    if (ewrxer[1] & eval[1])
	      rxer <= exer[1];
	    else if (ewrcrf[0] & eval[0])
	      rxer <= exer[0];
	    else if (mwrcrf[1] & mval[1])
	      rxer <= mxer[1];
	    else if (mwrcrf[0] & mval[0])
	      rxer <= mxer[0];
	    else if (wwrcrf[1] & wval[1])
	      rxer <= wxer[1];
	    else if (wwrcrf[0] & wval[0])
	      rxer <= wxer[0];
	    else
	      rxer <= xer;

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
*/
  end
RWAIT:
	if (advance_r) begin
    regfetch_done <= 2'b00;
    rgoto (RFETCH);
  end
default:
  begin
    regfetch_done <= 2'b11;
    rgoto(RWAIT);
  end
endcase
  if (advance_r) begin
  	if (stall_r[0]&stall_r[1])
  		stall_ctr <= stall_ctr + 2'd2;
  	else if (stall_r[0]|stall_r[1])
  		stall_ctr <= stall_ctr + 1'd1;

	  if (rRa[0]==6'd0 && r_ra0[0] && rval[0])
	    ia[0] <= 32'd0;
	  else if (rRa[0]==eRd[1] && eval[1] && ewrrf[1])
	    ia[0] <= eres[1];
	  else if (rRa[0]==eRa[1] && eval[1] && e_lsu[1])
	    ia[0] <= eea[1];
	  else if (rRa[0]==eRd[0] && eval[0] && ewrrf[0])
	    ia[0] <= eres[0];
	  else if (rRa[0]==eRa[0] && eval[0] && e_lsu[0])
	    ia[0] <= eea[0];
	  else if (rRa[0]==mRd[1] && mval[1] && mwrrf[1])
	    ia[0] <= mres[1];
	  else if (rRa[0]==mRa[1] && mval[1] && m_lsu[1])
	    ia[0] <= ea[1];
	  else if (rRa[0]==mRd[0] && mval[0] && mwrrf[0])
	    ia[0] <= mres[0];
	  else if (rRa[0]==mRa[0] && mval[0] && m_lsu[0])
	    ia[0] <= ea[0];
	  else if (rRa[0]==wRd[1] && wval[1] && wwrrf[1])
	    ia[0] <= wres[1];
	  else if (rRa[0]==wRa[1] && wval[1] && w_lsu[1])
	    ia[0] <= wea[1];
	  else if (rRa[0]==wRd[0] && wval[0] && wwrrf[0])
	    ia[0] <= wres[0];
	  else if (rRa[0]==wRa[0] && wval[0] && w_lsu[0])
	    ia[0] <= wea[0];
/*	    
	  else if (rRa[0]==tRd[0] && tval[0] && twrrf[0])
	    ia[0] <= tres[0];
	  else if (rRa[0]==tRd[1] && tval[1] && twrrf[1])
	    ia[0] <= tres[1];
*/
	  else
	    ia[0] <= rfoa[0];

	  if (rRa[1]==6'd0 && r_ra0[1] && rval[1])
	    ia[1] <= 32'd0;
	  else if (rRa[1]==eRd[1] && eval[1] && ewrrf[1])
	    ia[1] <= eres[1];
	  else if (rRa[1]==eRa[1] && eval[1] && e_lsu[1])
	    ia[1] <= eea[1];
	  else if (rRa[1]==eRd[0] && eval[0] && ewrrf[0])
	    ia[1] <= eres[0];
	  else if (rRa[1]==eRa[0] && eval[0] && e_lsu[0])
	    ia[1] <= eea[0];
	  else if (rRa[1]==mRd[1] && mval[1] && mwrrf[1])
	    ia[1] <= mres[1];
	  else if (rRa[1]==mRa[1] && mval[1] && m_lsu[1])
	    ia[1] <= ea[1];
	  else if (rRa[1]==mRd[0] && mval[0] && mwrrf[0])
	    ia[1] <= mres[0];
	  else if (rRa[1]==mRa[0] && mval[0] && m_lsu[0])
	    ia[1] <= ea[0];
	  else if (rRa[1]==wRd[1] && wval[1] && wwrrf[1])
	    ia[1] <= wres[1];
	  else if (rRa[1]==wRa[1] && wval[1] && w_lsu[1])
	    ia[1] <= wea[1];
	  else if (rRa[1]==wRd[0] && wval[0] && wwrrf[0])
	    ia[1] <= wres[0];
	  else if (rRa[1]==wRa[0] && wval[0] && w_lsu[0])
	    ia[1] <= wea[0];
/*	    
	  else if (rRa[1]==tRd[0] && tval[0] && twrrf[0])
	    ia[1] <= tres[0];
	  else if (rRa[1]==tRd[1] && tval[1] && twrrf[1])
	    ia[1] <= tres[1];
*/	    
	  else
	    ia[1] <= rfoa[1];

	  if (rRb[0]==eRd[1] && eval[1] && ewrrf[1])
	    ib[0] <= eres[1];
	  else if (rRb[0]==eRa[1] && eval[1] && e_lsu[1])
	    ib[0] <= eea[1];
	  else if (rRb[0]==eRd[0] && eval[0] && ewrrf[0])
	    ib[0] <= eres[0];
	  else if (rRb[0]==eRa[0] && eval[0] && e_lsu[0])
	    ib[0] <= eea[0];
	  else if (rRb[0]==mRd[1] && mval[1] && mwrrf[1])
	    ib[0] <= mres[1];
	  else if (rRb[0]==mRa[1] && mval[1] && m_lsu[1])
	    ib[0] <= ea[1];
	  else if (rRb[0]==mRd[0] && mval[0] && mwrrf[0])
	    ib[0] <= mres[0];
	  else if (rRb[0]==mRa[0] && mval[0] && m_lsu[0])
	    ib[0] <= ea[0];
	  else if (rRb[0]==wRd[1] && wval[1] && wwrrf[1])
	    ib[0] <= wres[1];
	  else if (rRb[0]==wRa[1] && wval[1] && w_lsu[1])
	    ib[0] <= wea[1];
	  else if (rRb[0]==wRd[0] && wval[0] && wwrrf[0])
	    ib[0] <= wres[0];
	  else if (rRb[0]==wRa[0] && wval[0] && w_lsu[0])
	    ib[0] <= wea[0];
	  else
	    ib[0] <= rfob[0];

	  if (rRb[1]==eRd[1] && eval[1] && ewrrf[1])
	    ib[1] <= eres[1];
	  else if (rRb[1]==eRa[1] && eval[1] && e_lsu[1])
	    ib[1] <= eea[1];
	  else if (rRb[1]==eRd[0] && eval[0] && ewrrf[0])
	    ib[1] <= eres[0];
	  else if (rRb[1]==eRa[0] && eval[0] && e_lsu[0])
	    ib[1] <= eea[0];
	  else if (rRb[1]==mRd[1] && mval[1] && mwrrf[1])
	    ib[1] <= mres[1];
	  else if (rRb[1]==mRa[1] && mval[1] && m_lsu[1])
	    ib[1] <= ea[1];
	  else if (rRb[1]==mRd[0] && mval[0] && mwrrf[0])
	    ib[1] <= mres[0];
	  else if (rRb[1]==mRa[0] && mval[0] && m_lsu[0])
	    ib[1] <= ea[0];
	  else if (rRb[1]==wRd[1] && wval[1] && wwrrf[1])
	    ib[1] <= wres[1];
	  else if (rRb[1]==wRa[1] && wval[1] && w_lsu[1])
	    ib[1] <= wea[1];
	  else if (rRb[1]==wRd[0] && wval[0] && wwrrf[0])
	    ib[1] <= wres[0];
	  else if (rRb[1]==wRa[0] && wval[0] && w_lsu[0])
	    ib[1] <= wea[0];
	  else
	    ib[1] <= rfob[1];

	  if (rRc[0]==eRd[1] && eval[1] && ewrrf[1])
	    ic[0] <= eres[1];
	  else if (rRc[0]==eRa[1] && eval[1] && e_lsu[1])
	    ic[0] <= eea[1];
	  else if (rRc[0]==eRd[0] && eval[0] && ewrrf[0])
	    ic[0] <= eres[0];
	  else if (rRc[0]==eRa[0] && eval[0] && e_lsu[0])
	    ic[0] <= eea[0];
	  else if (rRc[0]==mRd[1] && mval[1] && mwrrf[1])
	    ic[0] <= mres[1];
	  else if (rRc[0]==mRa[1] && mval[1] && m_lsu[1])
	    ic[0] <= ea[1];
	  else if (rRc[0]==mRd[0] && mval[0] && mwrrf[0])
	    ic[0] <= mres[0];
	  else if (rRc[0]==mRa[0] && mval[0] && m_lsu[0])
	    ic[0] <= ea[0];
	  else if (rRc[0]==wRd[1] && wval[1] && wwrrf[1])
	    ic[0] <= wres[1];
	  else if (rRc[0]==wRa[1] && wval[1] && w_lsu[1])
	    ic[0] <= wea[1];
	  else if (rRc[0]==wRd[0] && wval[0] && wwrrf[0])
	    ic[0] <= wres[0];
	  else if (rRc[0]==wRa[0] && wval[0] && w_lsu[0])
	    ic[0] <= wea[0];
	  else
	    ic[0] <= rfoc[0];

	  if (rRc[1]==eRd[1] && eval[1] && ewrrf[1])
	    ic[1] <= eres[1];
	  else if (rRc[1]==eRa[1] && eval[1] && e_lsu[1])
	    ic[1] <= eea[1];
	  else if (rRc[1]==eRd[0] && eval[0] && ewrrf[0])
	    ic[1] <= eres[0];
	  else if (rRc[1]==eRa[0] && eval[0] && e_lsu[0])
	    ic[1] <= eea[0];
	  else if (rRc[1]==mRd[1] && mval[1] && mwrrf[1])
	    ic[1] <= mres[1];
	  else if (rRc[1]==mRa[1] && mval[1] && m_lsu[1])
	    ic[1] <= ea[1];
	  else if (rRc[1]==mRd[0] && mval[0] && mwrrf[0])
	    ic[1] <= mres[0];
	  else if (rRc[1]==mRa[0] && mval[0] && m_lsu[0])
	    ic[1] <= ea[0];
	  else if (rRc[1]==wRd[1] && wval[1] && wwrrf[1])
	    ic[1] <= wres[1];
	  else if (rRc[1]==wRa[1] && wval[1] && w_lsu[1])
	    ic[1] <= wea[1];
	  else if (rRc[1]==wRd[0] && wval[0] && wwrrf[0])
	    ic[1] <= wres[0];
	  else if (rRc[1]==wRa[0] && wval[0] && w_lsu[0])
	    ic[1] <= wea[0];
	  else
	    ic[1] <= rfoc[1];

	  if (rRd[0]==eRd[1] && eval[1] && ewrrf[1])
	    id[0] <= eres[1];
	  else if (rRd[0]==eRa[1] && eval[1] && e_lsu[1])
	    id[0] <= eea[1];
	  else if (rRd[0]==eRd[0] && eval[0] && ewrrf[0])
	    id[0] <= eres[0];
	  else if (rRd[0]==eRa[0] && eval[0] && e_lsu[0])
	    id[0] <= eea[0];
	  else if (rRd[0]==mRd[1] && mval[1] && mwrrf[1])
	    id[0] <= mres[1];
	  else if (rRd[0]==mRa[1] && mval[1] && m_lsu[1])
	    id[0] <= ea[1];
	  else if (rRd[0]==mRd[0] && mval[0] && mwrrf[0])
	    id[0] <= mres[0];
	  else if (rRd[0]==mRa[0] && mval[0] && m_lsu[0])
	    id[0] <= ea[0];
	  else if (rRd[0]==wRd[1] && wval[1] && wwrrf[1])
	    id[0] <= wres[1];
	  else if (rRd[0]==wRa[1] && wval[1] && w_lsu[1])
	    id[0] <= wea[1];
	  else if (rRd[0]==wRd[0] && wval[0] && wwrrf[0])
	    id[0] <= wres[0];
	  else if (rRd[0]==wRa[0] && wval[0] && w_lsu[0])
	    id[0] <= wea[0];
	  else
	    id[0] <= rfod[0];

	  if (rRd[1]==eRd[1] && eval[1] && ewrrf[1])
	    id[1] <= eres[1];
	  else if (rRd[1]==eRa[1] && eval[1] && e_lsu[1])
	    id[1] <= eea[1];
	  else if (rRd[1]==eRd[0] && eval[0] && ewrrf[0])
	    id[1] <= eres[0];
	  else if (rRd[1]==eRa[0] && eval[0] && e_lsu[0])
	    id[1] <= eea[0];
	  else if (rRd[1]==mRd[1] && mval[1] && mwrrf[1])
	    id[1] <= mres[1];
	  else if (rRd[1]==mRa[1] && mval[1] && m_lsu[1])
	    id[1] <= ea[1];
	  else if (rRd[1]==mRd[0] && mval[0] && mwrrf[0])
	    id[1] <= mres[0];
	  else if (rRd[1]==mRa[0] && mval[0] && m_lsu[0])
	    id[1] <= ea[0];
	  else if (rRd[1]==wRd[1] && wval[1] && wwrrf[1])
	    id[1] <= wres[1];
	  else if (rRd[1]==wRa[1] && wval[1] && w_lsu[1])
	    id[1] <= wea[1];
	  else if (rRd[1]==wRd[0] && wval[0] && wwrrf[0])
	    id[1] <= wres[0];
	  else if (rRd[1]==wRa[0] && wval[0] && w_lsu[0])
	    id[1] <= wea[0];
	  else
	    id[1] <= rfod[1];

		if (smt) begin
		end
		else begin
	    if (ewrcrf[1] & eval[1])
	      ecr[0] <= ecr[1];
	    else if (ewrcrf[0] & eval[0])
	      ecr[0] <= ecr[0];
	    else if (mwrcrf[1] & mval[1])
	      ecr[0] <= mcr[1];
	    else if (mwrcrf[0] & mval[0])
	      ecr[0] <= mcr[0];
	    else if (wwrcrf[1] & wval[1])
	      ecr[0] <= wcr[1];
	    else if (wwrcrf[0] & wval[0])
	      ecr[0] <= wcr[0];
	    else //if (rrdcrf[0])
	      ecr[0] <= cro;

	    if (ewrcrf[1] & eval[1])
	      ecr[1] <= ecr[1];
	    else if (ewrcrf[0] & eval[0])
	      ecr[1] <= ecr[0];
	    else if (mwrcrf[1] & mval[1])
	      ecr[1] <= mcr[1];
	    else if (mwrcrf[0] & mval[0])
	      ecr[1] <= mcr[0];
	    else if (wwrcrf[1] & wval[1])
	      ecr[1] <= wcr[1];
	    else if (wwrcrf[0] & wval[0])
	      ecr[1] <= wcr[0];
	    else //if (rrdcrf[1])
	      ecr[1] <= cro;

	    if (ewrxer[1] & eval[1])
	      exer[0] <= exer[1];
	    else if (ewrcrf[0] & eval[0])
	      exer[0] <= exer[0];
	    else if (mwrcrf[1] & mval[1])
	      exer[0] <= mxer[1];
	    else if (mwrcrf[0] & mval[0])
	      exer[0] <= mxer[0];
	    else if (wwrcrf[1] & wval[1])
	      exer[0] <= wxer[1];
	    else if (wwrcrf[0] & wval[0])
	      exer[0] <= wxer[0];
	    else
	      exer[0] <= xer;

	    if (ewrxer[1] & eval[1])
	      exer[1] <= exer[1];
	    else if (ewrcrf[0] & eval[0])
	      exer[1] <= exer[0];
	    else if (mwrcrf[1] & mval[1])
	      exer[1] <= mxer[1];
	    else if (mwrcrf[0] & mval[0])
	      exer[1] <= mxer[0];
	    else if (wwrcrf[1] & wval[1])
	      exer[1] <= wxer[1];
	    else if (wwrcrf[0] & wval[0])
	      exer[1] <= wxer[0];
	    else
	      exer[1] <= xer;

	    if (ewrlr[1] & eval[1])
	      elr[0] <= eres[1];
	    else if (ewrlr[0] & eval[0])
	      elr[0] <= eres[0];
	    else if (mwrlr[1] & mval[1])
	      elr[0] <= mres[1];
	    else if (mwrlr[0] & mval[0])
	      elr[0] <= mres[0];
	    else if (wwrlr[1] & wval[1])
	      elr[0] <= wres[1];
	    else if (wwrlr[0] & wval[0])
	      elr[0] <= wres[0];
	    else
	      elr[0] <= lr;

	    if (ewrlr[1] & eval[1])
	      elr[1] <= eres[1];
	    else if (ewrlr[0] & eval[0])
	      elr[1] <= eres[0];
	    else if (mwrlr[1] & mval[1])
	      elr[1] <= mres[1];
	    else if (mwrlr[0] & mval[0])
	      elr[1] <= mres[0];
	    else if (wwrlr[1] & wval[1])
	      elr[1] <= wres[1];
	    else if (wwrlr[0] & wval[0])
	      elr[1] <= wres[0];
	    else
	      elr[1] <= lr;

	    if (ewrctr[1] & eval[1])
	      ectr[0] <= eres[1];
	    else if (ewrctr[0] & eval[0])
	      ectr[0] <= eres[0];
	    else if (mwrctr[1] & mval[1])
	      ectr[0] <= mres[1];
	    else if (mwrctr[0] & mval[0])
	      ectr[0] <= mres[0];
	    else if (wwrctr[1] & wval[1])
	      ectr[0] <= wres[1];
	    else if (wwrctr[0] & wval[0])
	      ectr[0] <= wres[0];
	    else
	      ectr[0] <= ctr;

	    if (ewrctr[1] & eval[1])
	      ectr[1] <= eres[1];
	    else if (ewrctr[0] & eval[0])
	      ectr[1] <= eres[0];
	    else if (mwrctr[1] & mval[1])
	      ectr[1] <= mres[1];
	    else if (mwrctr[0] & mval[0])
	      ectr[1] <= mres[0];
	    else if (wwrctr[1] & wval[1])
	      ectr[1] <= wres[1];
	    else if (wwrctr[0] & wval[0])
	      ectr[1] <= wres[0];
	    else
	      ectr[1] <= ctr;

		end

  	if (stall_r[1]) begin
	    eval[1] <= FALSE;
	    eir[1] <= NOP_INSN;
	    eRd[1] <= 6'd0;
	    rval[0] <= FALSE;
	    rir[0] <= NOP_INSN;
  	end
  	else begin
    	eval[1] <= rval[1];
	    eir[1] <= rir[1];
	    eRd[1] <= rRd[1];
  	end
    eir[0] <= rir[0];
  	eval[0] <= rval[0];
    imm[0] <= rimm[0];
    imm[1] <= rimm[1];
    eRd[0] <= rRd[0];
    eRa[0] <= rRa[0];
    eRa[1] <= rRa[1];
//    ecr[0] <= rcr;
//    ecr[1] <= rcr;
    epc[0] <= rpc[0];
    epc[1] <= rpc[1];
    
//    id[0] <= rid[0];
//    id[1] <= rid[1];
//    ia[0] <= ria[0];
//    ia[1] <= ria[1];
//    ib[0] <= rib[0];
//    ib[1] <= rib[1];
//    ic[0] <= ric[0];
//    ic[1] <= ric[1];
    
    e_lsu[0] <= r_lsu[0];
    e_cmp[0] <= r_cmp[0];
    ewrrf[0] <= rwrrf[0];
    ewrcrf[0] <= rwrcrf[0];
    ewrxer[0] <= rwrxer[0];
    e_lsu[1] <= r_lsu[1];
    e_cmp[1] <= r_cmp[1];
    e_bc <= d_bc;
    ewrrf[1] <= rwrrf[1];
    ewrcrf[1] <= rwrcrf[1];
    ewrxer[1] <= rwrxer[1];
    ewrlr[0] <= rwrlr[0];
    ewrlr[1] <= rwrlr[1];
    ewrctr[0] <= rwrctr[0];
    ewrctr[1] <= rwrctr[1];
		e_ld[0] <= r_ld[0];
		e_st[0] <= r_st[0];
		e_ld[1] <= r_ld[1];
		e_st[1] <= r_st[1];
		e_sync <= r_sync;
		e_multicycle <= r_multicycle;
		ebrpred <= rbrpred;
		ecause[0] <= rcause[0];
		ecause[1] <= rcause[1];
//		elr[0] <= rlr;
//    ectr[0] <= rctr;
//		elr[1] <= rlr;
//    ectr[1] <= rctr;
//    exer[0] <= rxer;
//    exer[1] <= rxer;
  end
  else if (advance_e) begin
    eval[0] <= FALSE;
    eval[1] <= FALSE;
    eir[0] <= NOP_INSN;
    eir[1] <= NOP_INSN;
    e_sync <= 2'b00;
  end
end
endtask

task tin;
input which;
input [5:0] Rn;
input [31:0] rfo;
output [31:0] in;
begin
	if (smt) begin
	  if (Rn==6'd0 && (r_ld[which]|r_st[which]) && rval[which])
	    in = 32'd0;
	  else if (Rn==eRd[which] && eval[which] && ewrrf[which])
	    in = eres[which];
	  else if (Rn==mRd[which] && mval[which] && mwrrf[which])
	    in = mres[which];
	  else if (Rn==wRd[which] && wval[which] && wwrrf[which])
	    in = wres[which];
	  else
	    in = rfo;
	end
	else begin
	  if (Rn==6'd0 && (r_ld[which]|r_st[which]) && rval[which])
	    in = 32'd0;
	  else if (Rn==eRd[1] && eval[1] && ewrrf[1])
	    in = eres[1];
	  else if (Rn==eRa[1] && eval[1] && e_lsu[1])
	    in = eea[1];
	  else if (Rn==eRd[0] && eval[0] && ewrrf[0])
	    in = eres[0];
	  else if (Rn==eRa[0] && eval[0] && e_lsu[0])
	    in = eea[0];
	  else if (Rn==mRd[1] && mval[1] && mwrrf[1])
	    in = mres[1];
	  else if (Rn==mRa[1] && mval[1] && m_lsu[1])
	    in = ea[1];
	  else if (Rn==mRd[0] && mval[0] && mwrrf[0])
	    in = mres[0];
	  else if (Rn==mRa[0] && mval[0] && m_lsu[0])
	    in = ea[0];
	  else if (Rn==wRd[1] && wval[1] && wwrrf[1])
	    in = wres[1];
	  else if (Rn==wRa[1] && wval[1] && w_lsu[1])
	    in = wea[1];
	  else if (Rn==wRd[0] && wval[0] && wwrrf[0])
	    in = wres[0];
	  else if (Rn==wRa[0] && wval[0] && w_lsu[0])
	    in = wea[0];
	  else
	    in = rfo;
  end
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
    eea[which] <= 32'd0;
    mpc[which] <= RSTPC;
    mRd[which] <= 6'd0;
    mRa[which] <= 6'd0;
    mres[which] <= 32'd0;
    m_lsu[which] <= FALSE;
    m_sync[which] <= FALSE;
    mcr[which] <= 32'd0;
    mctr[which] <= 32'd0;
    mlr[which] <= 32'd0;
    mxer[which] <= 32'd0;
    mwrcrf[which] <= FALSE;
    mwrlr[which] <= FALSE;
    mwrctr[which] <= FALSE;
    mwrrf[which] <= FALSE;
    mwrxer[which] <= FALSE;
    mia[which] <= 32'd0;
    ecause[which] <= 8'h00;
    mcause[which] <= 8'h00;
		etrap[which] <= FALSE;
    takb[which] <= FALSE;
    millegal_insn[which] <= FALSE;
  end
  else begin
  	alu_ld[which] <= FALSE;
    case(estate[which])
    EXECUTE:
      begin
        estate[which] <= EFLAGS;
        emod_pc[which] <= FALSE;
		    takb[which] <= FALSE;
				etrap[which] <= FALSE;
		   	ecause[which] <= 8'h00;
        case(eir[which][31:26])
        R2:
          case(eir[which][10:1])
          ADD,ADDO,ADDC,ADDCO:
          	eres[which] <= ia[which] + ib[which];
          ADDME,ADDMEO:
          	eres[which] <= ia[which] - 32'd1 + exer[which][30];
          ADDZE,ADDZEO:
          	eres[which] <= ia[which] + exer[which][30];
          ADDE,ADDEO:	eres[which] <= ia[which] + ib[which] + exer[which][30];
          SUBF: eres[which] <= ib[which] - ia[which];
          SUBFO: eres[which] <= ib[which] - ia[which];
          SUBFME,SUBFMEO:
          	eres[which] <= -32'd1 - ia[which] - ~exer[which][30];
          SUBFZE,SUBFZEO:
          	eres[which] <= -ia[which] - ~exer[which][30];
          SUBFC,SUBFCO:
          	eres[which] <= ib[which] - ia[which];
          SUBFE,SUBFEO:
          	eres[which] <= ib[which] - ia[which] - ~exer[which][30];
          	
          MULLW:  eres[which] <= prodr[which][31:0];
          MULLWO: eres[which] <= prodr[which][31:0];
          DIVW:		estate[which] <= EDIV1;
          DIVWU:	begin alu_ld[which] <= TRUE; estate[which] <= EDIV2; div_sign[which] <= 1'b0; end
          DIVWO:	estate[which] <= EDIV1;
          DIVWUO:	begin alu_ld[which] <= TRUE; estate[which] <= EDIV2; div_sign[which] <= 1'b0; end
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
          ANDC: eres[which] <= ia[which] & ~ib[which];
          OR:   eres[which] <= ia[which] | ib[which];
          ORC:  eres[which] <= ia[which] | ~ib[which];
          XOR:  eres[which] <= ia[which] ^ ib[which];
          NAND: eres[which] <= ~(ia[which] & ib[which]);
          NOR:  eres[which] <= ~(ia[which] | ib[which]);
          EQV:  eres[which] <= ~(ia[which] ^ ib[which]);
          EXTSB:eres[which] <= {{24{ia[which][7]}},ia[which][7:0]};
          EXTSH:eres[which] <= {{16{ia[which][15]}},ia[which][15:0]};
          SLW:  eres[which] <= ia[which] << ib[which];
          SRW:  eres[which] <= ia[which] >> ib[which];
          SRAW: eres[which] <= ia[which][31] ? {32'hFFFFFFFF,ia[which]} >> ib[which] : ia[which] >> ib[which];
          SRAWI:eres[which] <= ia[which][31] ? {32'hFFFFFFFF,ia[which]} >> eir[which][15:11] : ia[which] >> eir[which][15:11];
          CNTLZW:	eres[which] <= cntlzo[which];
          LBZX,LBZUX:  begin eea[which] <= ia[which] + ib[which]; end
          LHZX,LHZUX:  begin eea[which] <= ia[which] + ib[which]; end
          LHAX,LHAUX:  begin eea[which] <= ia[which] + ib[which]; end
          LWZX,LWZUX:  begin eea[which] <= ia[which] + ib[which]; end
          STBX,STBUX:  begin eea[which] <= ia[which] + ib[which]; end
          STHX,STHUX:  begin eea[which] <= ia[which] + ib[which]; end
          STWX,STWUX:  begin eea[which] <= ia[which] + ib[which]; end
          MCRXR:
            case(eir[which][25:23])
            3'd0: begin ecr[which][3:0] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd1: begin ecr[which][7:4] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd2: begin ecr[which][11:8] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd3: begin ecr[which][15:12] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd4: begin ecr[which][19:16] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd5: begin ecr[which][23:20] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd6: begin ecr[which][27:24] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            3'd7: begin ecr[which][31:28] <= exer[which][3:0]; exer[which][3:0] <= 4'd0; end
            endcase
          MFCR: eres[which] <= ecr[which];
          MTCRF: 
            begin
              if (eir[which][12]) ecr[which][3:0] <= ia[which][3:0];
              if (eir[which][13]) ecr[which][7:4] <= ia[which][7:4];
              if (eir[which][14]) ecr[which][11:8] <= ia[which][11:8];
              if (eir[which][15]) ecr[which][15:12] <= ia[which][15:12];
              if (eir[which][16]) ecr[which][19:16] <= ia[which][19:16];
              if (eir[which][17]) ecr[which][23:20] <= ia[which][23:20];
              if (eir[which][18]) ecr[which][27:24] <= ia[which][27:24];
              if (eir[which][19]) ecr[which][31:28] <= ia[which][31:28];
            end
          MFMSR:	eres[which] <= msr;
          MFSPR:
            case(eir[which][20:11])
            10'd32:   eres[which] <= exer[which];
            10'd26:		eres[which] <= srr0;
            10'd27:		eres[which] <= srr1;
            10'd256:  eres[which] <= elr[which];
            10'd272,10'd273,10'd274,10'd275:
            					eres[which] <= sprg[eir[which][12:11]];	
            10'd287:	eres[which] <= 32'h04408000;	// processor / version
            10'd288:  eres[which] <= ectr[which];
            default:  ;
            endcase
          MTSPR:
            case(eir[which][20:11])
            10'd32:   exer[which] <= ia[which];
            10'd256:  elr[which] <= ia[which];
            10'd288:  ectr[which] <= ia[which];
            default:  ;
            endcase
					TW:
						case(eir[which][25:21])
						5'd1:	etrap[which] <=  trpr[which][4];							// gtu
						5'd2: etrap[which] <=  trpr[which][3];							// ltu
						5'd4: etrap[which] <=  trpr[which][2];							// eq
						5'd5:	etrap[which] <=  trpr[which][4]|trpr[which][2];	// geu
						5'd6: etrap[which] <=  trpr[which][3]|trpr[which][2];	// leu
						5'd8:	etrap[which] <=  trpr[which][1];							// gt
						5'd12:etrap[which] <= ~trpr[which][0];							// nlt / ge
						5'd16:etrap[which] <=  trpr[which][0];							// lt
						5'd20:etrap[which] <= ~trpr[which][1];							// ngt
						5'd24:etrap[which] <= ~trpr[which][2];							// ne
						5'd31:etrap[which] <=  TRUE;
						endcase
          default:  ;
          endcase
        ADDI,ADDIC,ADDICD:
        	eres[which] <= ia[which] + imm[which];
        ADDIS: eres[which] <= ia[which] + imm[which];
        SUBFIC:	eres[which] <= imm[which] - ia[which];
        MULLI: eres[which] <= prodi[which][31:0];
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
        RLWIMI:     eres[which] <= rlwimi_o[which];
        RLWINM:     eres[which] <= rlwinm_o[which];
        RLWNM:      eres[which] <= rlwnm_o[which];

				TWI:
					begin
						case(eir[which][25:21])
						5'd1:	etrap[which] <=  trp[which][4];							// gtu
						5'd2: etrap[which] <=  trp[which][3];							// ltu
						5'd4: etrap[which] <=  trp[which][2];							// eq
						5'd5:	etrap[which] <=  trp[which][4]|trp[which][2];	// geu
						5'd6: etrap[which] <=  trp[which][3]|trp[which][2];	// leu
						5'd8:	etrap[which] <=  trp[which][1];							// gt
						5'd12:etrap[which] <= ~trp[which][0];							// nlt / ge
						5'd16:etrap[which] <=  trp[which][0];							// lt
						5'd20:etrap[which] <= ~trp[which][1];							// ngt
						5'd24:etrap[which] <= ~trp[which][2];							// ne
						5'd31:etrap[which] <=  TRUE;
						endcase
					end
        B:  eres[which] <= epc[which] + 3'd4;
        BC: 
        	begin
        		eres[which] <= epc[which] + 3'd4;
        		casez(eir[which][25:21])
        		5'b0?00?:
        			begin
        				ectr[which] <= ectr[which] - 1'd1;
        				if (~ebrpred && (ectr[which] - 1'd1 != 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24])) begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					if (eir[which][1])
        						enext_pc[which] <= {{16{eir[which][15]}},eir[which][15:2],2'b00};
        					else
        						enext_pc[which] <= epc[which] + {{16{eir[which][15]}},eir[which][15:2],2'b00};
        				end
        				else if (ebrpred && !(ectr[which] - 1'd1 != 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24])) begin
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= epc[which] + 3'd4;
        				end
        			end
        		5'b0?01?:
        			begin
        				ectr[which] <= ectr[which] - 1'd1;
        				if (~ebrpred && (ectr[which] - 1'd1 == 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24])) begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					if (eir[which][1])
        						enext_pc[which] <= {{16{eir[which][15]}},eir[which][15:2],2'b00};
        					else
        						enext_pc[which] <= epc[which] + {{16{eir[which][15]}},eir[which][15:2],2'b00};
        				end
        				else if (ebrpred && !(ectr[which] - 1'd1 == 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24])) begin
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= epc[which] + 3'd4;
        				end
        			end
        		5'b0?1??:
        			begin
        				if (~ebrpred && (ecr[which][eir[which][20:16]]==eir[which][24])) begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					if (eir[which][1])
        						enext_pc[which] <= {{16{eir[which][15]}},eir[which][15:2],2'b00};
        					else
        						enext_pc[which] <= epc[which] + {{16{eir[which][15]}},eir[which][15:2],2'b00};
        				end
        				else if (ebrpred && !(ecr[which][eir[which][20:16]]==eir[which][24])) begin
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= epc[which] + 3'd4;
        				end
        			end
        		5'b1?00?:
        			begin
        				ectr[which] <= ectr[which] - 1'd1;
        				if (~ebrpred && (ectr[which] - 1'd1 != 32'd0)) begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					if (eir[which][1])
        						enext_pc[which] <= {{16{eir[which][15]}},eir[which][15:2],2'b00};
        					else
        						enext_pc[which] <= epc[which] + {{16{eir[which][15]}},eir[which][15:2],2'b00};
        				end
        				else if (ebrpred && !(ectr[which] - 1'd1 != 32'd0)) begin
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= epc[which] + 3'd4;
        				end
        			end
        		5'b1?01?:
        			begin
        				ectr[which] <= ectr[which] - 1'd1;
        				if (~ebrpred && (ectr[which] - 1'd1 == 32'd0)) begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					if (eir[which][1])
        						enext_pc[which] <= {{16{eir[which][15]}},eir[which][15:2],2'b00};
        					else
        						enext_pc[which] <= epc[which] + {{16{eir[which][15]}},eir[which][15:2],2'b00};
        				end
        				else if (ebrpred && !(ectr[which] - 1'd1 == 32'd0)) begin
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= epc[which] + 3'd4;
        				end
        			end
        		endcase
        	end
        CR2:
          case(eir[which][10:1])
          BCCTR:
          	begin
	          	eres[which] <= epc[which] + 3'd4;
	        		casez(eir[which][25:21])
	        		5'b0?00?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 != 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24]) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= ectr[which];
	        				end
	        			end
	        		5'b0?01?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 == 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24]) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= ectr[which];
	        				end
	        			end
	        		5'b0?1??:
	        			begin
	        				if (ecr[which][eir[which][20:16]]==eir[which][24]) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= ectr[which];
	        				end
	        			end
	        		5'b1?00?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 != 32'd0) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= ectr[which];
	        				end
	        			end
	        		5'b1?01?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 == 32'd0) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= ectr[which];
	        				end
	        			end
	        		5'b10100:
	        			begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= ectr[which];
	        			end
	        		endcase
          	end
          BCLR:
          	begin
	          	eres[which] <= epc[which] + 3'd4;
	        		casez(eir[which][25:21])
	        		5'b0?00?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 != 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24]) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= elr[which];
	        				end
	        			end
	        		5'b0?01?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 == 32'd0 && ecr[which][eir[which][20:16]]==eir[which][24]) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= elr[which];
	        				end
	        			end
	        		5'b0?1??:
	        			begin
	        				if (ecr[which][eir[which][20:16]]==eir[which][24]) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= elr[which];
	        				end
	        			end
	        		5'b1?00?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 != 32'd0) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= elr[which];
	        				end
	        			end
	        		5'b1?01?:
	        			begin
	        				ectr[which] <= ectr[which] - 1'd1;
	        				if (ectr[which] - 1'd1 == 32'd0) begin
	        					takb[which] <= eval[which];
	        					emod_pc[which] <= eval[which];
        						enext_pc[which] <= elr[which];
	        				end
	        			end
	        		5'b10100:
	        			begin
        					takb[which] <= eval[which];
        					emod_pc[which] <= eval[which];
        					enext_pc[which] <= elr[which];
	        			end
	        		endcase
          	end
          CRAND: ecr[which][eir[which][25:21]] <=  ecr[which][eir[which][20:16]] & ecr[which][eir[which][15:11]];
          CROR:  ecr[which][eir[which][25:21]] <=  ecr[which][eir[which][20:16]] | ecr[which][eir[which][15:11]];
          CRXOR: ecr[which][eir[which][25:21]] <=  ecr[which][eir[which][20:16]] ^ ecr[which][eir[which][15:11]];
          CRNAND:ecr[which][eir[which][25:21]] <= ~(ecr[which][eir[which][20:16]] & ecr[which][eir[which][15:11]]);
          CRNOR: ecr[which][eir[which][25:21]] <= ~(ecr[which][eir[which][20:16]] | ecr[which][eir[which][15:11]]);
          CREQV: ecr[which][eir[which][25:21]] <= ~(ecr[which][eir[which][20:16]] ^ ecr[which][eir[which][15:11]]);
          CRANDC:ecr[which][eir[which][25:21]] <=  ecr[which][eir[which][20:16]] & ~ecr[which][eir[which][15:11]];
          CRORC: ecr[which][eir[which][25:21]] <=  ecr[which][eir[which][20:16]] | ~ecr[which][eir[which][15:11]];
          default:  ;
          endcase
        LBZ,LBZU:  begin eea[which] <= ia[which] + imm[which]; end
        LHZ,LHZU:  begin eea[which] <= ia[which] + imm[which]; end
        LHA,LHAU:  begin eea[which] <= ia[which] + imm[which]; end
        LWZ,LWZU:  begin eea[which] <= ia[which] + imm[which]; end
        STB,STBU:  begin eea[which] <= ia[which] + imm[which]; end
        STH,STHU:  begin eea[which] <= ia[which] + imm[which]; end
        STW,STWU:  begin eea[which] <= ia[which] + imm[which]; end
        default:  ;
        endcase
        if ((!ewrcrf[which] && !e_multicycle[which]) | e_cmp[which]) begin
          execute_done[which] <= TRUE;
          estate[which] <= EWAIT;
        end
      end
    EFLAGS:
      begin
        case(eir[which][31:26])
        R2:
          case(eir[which][10:1])
          ADDO:
          	begin
          		exer[which][31] <= exer[which][31] | (eres[which][31] ^ ib[which][31]) & (1'b1 ^ ia[which][31] ^ ib[which][31]);
          		exer[which][30] <= (eres[which][31] ^ ib[which][31]) & (1'b1 ^ ia[which][31] ^ ib[which][31]);
          		exer[which][20] <= (eres[which][31] ^ ib[which][31]) & (1'b1 ^ ia[which][31] ^ ib[which][31]);
          	end
         	ADDC:
         		begin
         			// (a&b)|(a&~s)|(b&~s)
         			exer[which][29] <= (ia[which][31]&ib[which][31])|(ia[which][31]&~eres[which][31])|(ib[which][31]&~eres[which][31]);
         			exer[which][19] <= (ia[which][31]&ib[which][31])|(ia[which][31]&~eres[which][31])|(ib[which][31]&~eres[which][31]);
         		end
         	ADDCO,ADDEO,ADDMEO,ADDZEO:
         		begin
          		exer[which][31] <= exer[which][31] | (eres[which][31] ^ ib[which][31]) & (1'b1 ^ ia[which][31] ^ ib[which][31]);
          		exer[which][30] <= (eres[which][31] ^ ib[which][31]) & (1'b1 ^ ia[which][31] ^ ib[which][31]);
          		exer[which][20] <= (eres[which][31] ^ ib[which][31]) & (1'b1 ^ ia[which][31] ^ ib[which][31]);
         			exer[which][29] <= (ia[which][31]&ib[which][31])|(ia[which][31]&~eres[which][31])|(ib[which][31]&~eres[which][31]);
         			exer[which][19] <= (ia[which][31]&ib[which][31])|(ia[which][31]&~eres[which][31])|(ib[which][31]&~eres[which][31]);
         		end
          SUBFO:
          	begin
          		exer[which][31] <= exer[which][31] | (1'b1^ eres[which][31] ^ ia[which][31]) & (ia[which][31] ^ ib[which][31]);
          		exer[which][30] <= (1'b1^ eres[which][31] ^ ia[which][31]) & (ia[which][31] ^ ib[which][31]);
          		exer[which][20] <= (1'b1^ eres[which][31] ^ ia[which][31]) & (ia[which][31] ^ ib[which][31]);
          	end
          SUBFC:
          	begin
	       			exer[which][29] <= (~ib[which][31]&ia[which][31])|(eres[which][31]&~ib[which][31])|(eres[which][31]&ia[which][31]);
  	     			exer[which][19] <= (~ib[which][31]&ia[which][31])|(eres[which][31]&~ib[which][31])|(eres[which][31]&ia[which][31]);
          	end
          SUBFCO,SUBFEO,SUBFMEO,SUBFZEO:
          	begin
          		exer[which][31] <= exer[which][31] | (1'b1^ eres[which][31] ^ ia[which][31]) & (ia[which][31] ^ ib[which][31]);
          		exer[which][30] <= (1'b1^ eres[which][31] ^ ia[which][31]) & (ia[which][31] ^ ib[which][31]);
          		exer[which][20] <= (1'b1^ eres[which][31] ^ ia[which][31]) & (ia[which][31] ^ ib[which][31]);
	       			exer[which][29] <= (~ib[which][31]&ia[which][31])|(eres[which][31]&~ib[which][31])|(eres[which][31]&ia[which][31]);
  	     			exer[which][19] <= (~ib[which][31]&ia[which][31])|(eres[which][31]&~ib[which][31])|(eres[which][31]&ia[which][31]);
          	end
          MULLWO:
          	begin
              exer[which][31] <= exer[which][31] | (prodr[which][63:32] != {32{prodr[which][31]}}); // summary overflow
              exer[which][30] <= (prodr[which][63:32] != {32{prodr[which][31]}}); // overflow
              exer[which][20] <= (prodr[which][63:32] != {32{prodr[which][31]}}); // overflow
          	end
          default:	;
          endcase
        ADDIC,ADDICD:
       		begin
       			exer[which][29] <= (ia[which][31]&imm[which][31])|(ia[which][31]&~eres[which][31])|(imm[which][31]&~eres[which][31]);
       			exer[which][19] <= (ia[which][31]&imm[which][31])|(ia[which][31]&~eres[which][31])|(imm[which][31]&~eres[which][31]);
       		end
       	SUBFIC:
       		begin
       			// (~a&b)|(s&~a)|(s&b)
       			exer[which][29] <= (~imm[which][31]&ia[which][31])|(eres[which][31]&~imm[which][31])|(eres[which][31]&ia[which][31]);
       			exer[which][19] <= (~imm[which][31]&ia[which][31])|(eres[which][31]&~imm[which][31])|(eres[which][31]&ia[which][31]);
       		end
        default:	;
				endcase      	
        if (ewrcrf[which] & ~e_cmp[which]) begin
          ecr[which][0] <= eres[which][31];
          ecr[which][1] <= eres[which]==32'd0;
          ecr[which][2] <= ~eres[which][31] && eres[which]!=32'd0;
	        case(eir[which][31:26])
	        R2:
	          case(eir[which][10:1])
	          ADDO,ADDCO,ADDEO,ADDMEO,ADDZEO:	
	          	begin
	          		ecr[which][3] <= (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
	          	end
	          SUBFO:
	          	begin
	          		ecr[which][3] <= (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
	          	end
	          MULLWO:
	          	begin
	              ecr[which][3] <= prodr[which][63:32] != {32{prodr[which][31]}};
	            end
	          default:  ;
	          endcase
	        default:	;
	        endcase
        end
        execute_done[which] <= TRUE;
        estate[which] <= EWAIT;
      end        
    EDIV1:
    	begin
    		alu_ld[which] <= TRUE;
    		div_sign[which] <= ia[which][31] ^ ib[which][31];
    		if (ia[which][31]) ia[which] <= -ia[which];
    		if (ib[which][31]) ib[which] <= -ib[which];
    		estate[which] <= EDIV2;
    	end
    // Wait a cycle for done to go inactive
    EDIV2:
    	begin
    		estate[which] <= EDIV3;
   	 	end
   	EDIV3:
    	begin
    		if (div_done[which]) begin
    			if (div_sign[which])
    				eres[which] <= -(divo[which][63:32]);
    			else
    				eres[which] <= divo[which][63:32];
    			if (ewrcrf[which])
    				estate[which] <= EFLAGS;
    			else begin
    				execute_done[which] <= TRUE;
    				estate[which] <= EWAIT;
    			end
    		end
   	 	end
    EWAIT:
      if (advance_e) begin
        execute_done[which] <= FALSE;
        estate[which] <= EXECUTE;
        mpc[which] <= epc[which];
        mRd[which] <= eRd[which];
        mRa[which] <= eRa[which];
        ea[which] <= eea[which];
        mid[which] <= id[which];
        mir[which] <= eir[which];
        m_lsu[which] <= e_lsu[which];
        m_st[which] <= e_st[which];
        m_sync[which] <= e_sync[which];
	      mval[which] <= eval[which];
	      mia[which] <= ia[which];
        mres[which] <= eres[which];
        mcr[which] <= ecr[which];
        mwrrf[which] <= ewrrf[which];
        mwrcrf[which] <= ewrcrf[which];
        mwrxer[which] <= ewrxer[which];
        mwrlr[which] <= ewrlr[which];
        mwrctr[which] <= ewrctr[which];
        mctr[which] <= ectr[which];
        mlr[which] <= elr[which];
        mxer[which] <= exer[which];
        // Hardware interrupt takes priority.
        if (ecause[which] & 8'h80)
        	mcause[which] <= ecause[which];
        else if (etrap[which])
        	mcause[which] <= FLT_PROGRAM;
        else
        	mcause[which] <= ecause[which];
      end
      else if (advance_m) begin
      	mval[which] <= FALSE;
      	mwrlr[which] <= FALSE;
      	m_sync[which] <= FALSE;
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
    maccess <= FALSE;
    maccess_pending[which] <= FALSE;
    memory_done[which] <= TRUE;
    mstate[which] <= MWAIT;
    mval[which] <= FALSE;
    ea[which] <= 32'd0;
    sel <= 32'h0;
    wwRd <= 6'd0;
    wpc[which] <= RSTPC;
    wRd[which] <= 6'd0;
    wRa[which] <= 6'd0;
    w_lsu[which] <= FALSE;
    w_sync[which] <= FALSE;
    wia[which] <= 32'd0;
    wres[which] <= 32'd0;
    wcr[which] <= 32'd0;
    wctr[which] <= 32'd0;
    wlr[which] <= 32'd0;
    wnext_pc[which] <= RSTPC;
    wwrcrf[which] <= FALSE;
    wwrctr[which] <= FALSE;
    wwrlr[which] <= FALSE;
    wwrxer[which] <= FALSE;
    wwrrf[which] <= FALSE;
    wwwrcrf <= FALSE;
    wwwrlr <= FALSE;
    wwwrxer <= FALSE;
    wwwrrf <= FALSE;
    wwxer <= 32'd0;
    wcause[which] <= 8'h00;
    willegal_insn <= FALSE;
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
          LHAX,LHAUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          LWZX,LWZUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          STBX,STBUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          STHX,STHUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          STWX,STWUX:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
          default:  begin mstate[which] <= MWAIT; memory_done[which] <= TRUE; end
          endcase
        LBZ,LBZU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        LHZ,LHZU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        LHA,LHAU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        LWZ,LWZU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        STB,STBU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        STH,STHU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        STW,STWU:  begin maccess_pending[which] <= TRUE; mstate[which] <= MEMORY2; memory_done[which] <= FALSE; end
        default:  begin mstate[which] <= MWAIT; memory_done[which] <= TRUE; end
        endcase
      end
    MEMORY2:
      if (!iaccess && !maccess && (which==0 || !maccess_pending[0])) begin
        maccess_pending[which] <= FALSE;
        maccess <= TRUE;
        cyc_o <= HIGH;
        stb_o <= HIGH;
        case(mir[which][31:26])
        R2:
          case(mir[which][10:1])
          LBZX,LBZUX:  begin we_o <= LOW; sel_o <= 16'h0001 << ea[which][2:0]; adr_o <= ea[which]; end
          LHZX,LHZUX:  begin we_o <= LOW; sel_o <= 16'h0003 << ea[which][2:0]; sel <= 16'h0003 << ea[which][3:0]; adr_o <= ea[which]; end
          LHAX,LHAUX:  begin we_o <= LOW; sel_o <= 16'h0003 << ea[which][2:0]; sel <= 16'h0003 << ea[which][3:0]; adr_o <= ea[which]; end
          LWZX,LWZUX:  begin we_o <= LOW; sel_o <= 16'h000F << ea[which][2:0]; sel <= 16'h000F << ea[which][3:0]; adr_o <= ea[which]; end
          STBX,STBUX:  begin we_o <= HIGH; sel_o <= 16'h0001 << ea[which][2:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][3:0],3'b0}; end
          STHX,STHUX:  begin we_o <= HIGH; sel_o <= 16'h0003 << ea[which][2:0]; sel <= 16'h0003 << ea[which][3:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][3:0],3'b0}; dat <= mid[which] << {ea[which][3:0],3'b0}; end
          STWX,STWUX:  begin we_o <= HIGH; sel_o <= 16'h000F << ea[which][2:0]; sel <= 16'h000F << ea[which][3:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][3:0],3'b0}; dat <= mid[which] << {ea[which][3:0],3'b0}; end
          default:  ;
          endcase
        LBZ,LBZU:  begin we_o <= LOW; sel_o <= 16'h0001 << ea[which][3:0]; adr_o <= ea[which]; end
        LHZ,LHZU:  begin we_o <= LOW; sel_o <= 16'h0003 << ea[which][3:0]; sel <= 16'h0003 << ea[which][3:0]; adr_o <= ea[which]; end
        LHA,LHAU:  begin we_o <= LOW; sel_o <= 16'h0003 << ea[which][3:0]; sel <= 16'h0003 << ea[which][3:0]; adr_o <= ea[which]; end
        LWZ,LWZU:  begin we_o <= LOW; sel_o <= 16'h000F << ea[which][3:0]; sel <= 16'h000F << ea[which][3:0]; adr_o <= ea[which]; end
        STB,STBU:  begin we_o <= HIGH; sel_o <= 16'h0001 << ea[which][3:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][3:0],3'b0}; end
        STH,STHU:  begin we_o <= HIGH; sel_o <= 16'h0003 << ea[which][3:0]; sel <= 16'h0003 << ea[which][3:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][3:0],3'b0}; dat <= mid[which] << {ea[which][3:0],3'b0}; end
        STW,STWU:  begin we_o <= HIGH; sel_o <= 16'h000F << ea[which][3:0]; sel <= 16'h000F << ea[which][3:0]; adr_o <= ea[which]; dat_o <= mid[which] << {ea[which][3:0],3'b0}; dat <= mid[which] << {ea[which][3:0],3'b0}; end
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
          LBZX,LBZUX,STBX,STBUX:
          	begin
          		cyc_o <= LOW;
          		we_o <= LOW;
          		sel_o <= 8'h00;
        			maccess <= FALSE;
          		mstate[which] <= MALIGN;
          	end
          LHZX,LHZUX,LHAX,LHAUX,STHX,STHUX:
            begin
              if (ea[which][3:0]!=4'b1111) begin
                cyc_o <= LOW;
                we_o <= LOW;
                sel_o <= 16'h0000;
				        maccess <= FALSE;
                mstate[which] <= MALIGN;
              end
              else
                mstate[which] <= MEMORY4;
            end
          LWZX,LWZUX,STWX,STWUX:  
            begin
              if (ea[which][3:0] < 4'b1101) begin
                cyc_o <= LOW;
                we_o <= LOW;
                sel_o <= 16'h0000;
				        maccess <= FALSE;
                mstate[which] <= MALIGN;
              end
              else
                mstate[which] <= MEMORY4;
            end
          default:  ;
          endcase
        LBZ,LBZU:
        	begin
        		cyc_o <= LOW;
        		sel_o <= 8'h00;
		        maccess <= FALSE;
        		mstate[which] <= MALIGN;
        	end
        LHZ,LHZU,LHA,LHAU:
          begin
            if (ea[which][3:0]!=4'b1111) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 16'h0000;
			        maccess <= FALSE;
              mstate[which] <= MALIGN;
            end
            else
              mstate[which] <= MEMORY4;
          end
        STH,STHU:
          begin
            if (ea[which][3:0]!=4'b1111) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 16'h0000;
			        memory_done[which] <= TRUE;
			        mstate[which] <= MWAIT;
			        maccess <= FALSE;
            end
            else
              mstate[which] <= MEMORY4;
          end
        LWZ,LWZU:  
          begin
            if (ea[which][3:0] < 4'b1101) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 16'h0000;
			        maccess <= FALSE;
              mstate[which] <= MALIGN;
            end
            else
              mstate[which] <= MEMORY4;
          end
        STW,STWU:  
          begin
            if (ea[which][3:0] < 4'b1101) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 16'h0000;
			        memory_done[which] <= TRUE;
			        mstate[which] <= MWAIT;
			        maccess <= FALSE;
            end
            else
              mstate[which] <= MEMORY4;
          end
        STB,STBU:
        	begin
        		cyc_o <= LOW;
        		we_o <= LOW;
        		sel_o <= 16'h0000;
		        memory_done[which] <= TRUE;
		        mstate[which] <= MWAIT;
		        maccess <= FALSE;
        	end
        default:  ;
        endcase
      end
    MEMORY4:
      begin
        stb_o <= HIGH;
        sel_o <= sel[31:16];
        adr_o <= {ea[which][AWID-1:4]+1'd1,4'b0};
        dat_o <= dat[255:128];
        mstate[which] <= MEMORY5;
      end
    MEMORY5:
      if (ack_i) begin
        cyc_o <= LOW;
        stb_o <= LOW;
        we_o <= LOW;
        sel_o <= 8'h00;
        dati[255:128] <= dat_i;
        maccess <= FALSE;
        mstate[which] <= MALIGN;
      end
    MALIGN:
      begin
        memory_done[which] <= TRUE;
        mstate[which] <= MWAIT;
        case(mir[which][31:26])
        R2:
          case(mir[which][10:1])
          LBZX,LBZUX: mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'h0FF;
          LHZX,LHZUX: mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'h0FFFF;
          LHAX,LHAUX: begin mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'h0FFFF; memory_done[which] <= FALSE; mstate[which] <= MSX; end
          LWZX,LWZUX: mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'hFFFFFFFF;
          default:  ;
          endcase
        LBZ,LBZU: mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'h0FF;
        LHZ,LHZU: mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'h0FFFF;
        LHA,LHAU: begin mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'h0FFFF; memory_done[which] <= FALSE; mstate[which] <= MSX; end
        LWZ,LWZU: mres[which] <= (dati >> {ea[which][3:0],3'b0}) & 32'hFFFFFFFF;
        default:  ;
        endcase
        /*
        if (m_st[which] & m_lsu[which]) begin
        	mwrrf[which] <= TRUE;
        	mRd[which] <= mRa[which];
        	mres[which] <= ea[which];
        end
        */
      end
    // Currently only LHAxx instructions need sign extend
    MSX:
    	begin
    		mres[which] <= {{16{mres[which][15]}},mres[which][15:0]};
    		memory_done[which] <= TRUE;
    		mstate[which] <= MWAIT;
    	end
    MWAIT:
      if (advance_m) begin
      	wpc[which] <= mpc[which];
      	wRd[which] <= mRd[which];
      	wRa[which] <= mRa[which];
        wval[which] <= mval[which];
        wwval <= 1'b0;
        wia[which] <= mia[which];
       	wres[which] <= mres[which];
        wea[which] <= ea[which];
        w_lsu[which] <= m_lsu[which];
        w_sync[which] <= m_sync[which];
        wwrrf[which] <= mwrrf[which];
        wwrcrf[which] <= wwrcrf[which];
        wcr[which] <= mcr[which];
        wwrlr[which] <= mwrlr[which];
        wwrctr[which] <= mwrctr[which];
        wwrxer[which] <= mwrxer[which];
        wctr[which] <= mctr[which];
        wlr[which] <= mlr[which];
        wxer[which] <= mxer[which];
        memory_done[which] <= FALSE;
        mstate[which] <= MEMORY1;
        wcause[which] <= mcause[which];
      end
      else if (advance_w) begin
      	wval[which] <= FALSE;
      	w_sync[which] <= FALSE;
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

wire w_write1 = wwrrf[1] | wwrcrf[1] | wwrlr[1] | wwrctr[1] | wwrxer[1] | |wcause[1];

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
  	wmod_pc <= FALSE;
  	if (wcause[0]) begin
			srr0 <= wpc[0];
			srr1 <= msr;
  		wmod_pc[0] <= TRUE;
  		if (wcause[0][7])
  			wnext_pc[0] <= {FLT_EXTERNAL,8'h00};
  		else
  			wnext_pc[0] <= {wcause[0],8'h00};
  	end
    case(wstate)
    WRITEBACK0:
      begin
      	if (wval[0])
      		case(wir[0][31:26])
      		SC:
      			begin
      				srr0 <= wpc[0] + 3'd4;
      				srr1 <= msr;
      				wmod_pc[0] <= TRUE;
      				wnext_pc[0] <= {FLT_SYSTEM_CALL,8'h00};
      			end
      		R2:
      			case(wir[0][10:1])
      			MTMSR:	msr <= wia[0];
	    			default:	;
						endcase      		
      		CR2:
      			case(wir[0][10:1])
      			RFI:	msr <= srr0;
		    		default:	;
      			endcase
          MTSPR:
            case(wir[0][20:11])
            10'd26:		srr0 <= wia[0];
            10'd27:	  srr1 <= wia[0];
            10'd272,10'd273,10'd274,10'd275:
            					sprg[wir[0][12:11]] <= wia[0];
            10'd256:  lr <= wia[0];
            10'd288:  ctr <= wia[0];
            default:  ;
            endcase
	    		default:	;
      		endcase
      	if (wval[0] & wval[1])
      		inst_ctr <= inst_ctr + 2'd2;
      	else if (wval[0]|wval[1])
      		inst_ctr <= inst_ctr + 1'd1;
      	inst_ctr2 <= inst_ctr2 + 2'd2;
        wwRd <= wRd[0];
        wwres <= wres[0];
        wwval <= wval[0] & wwrrf[0];
        wwwrrf <= wwrrf[0] & wval[0];
        wwwrcrf <= wwrcrf[0] & wval[0];
        wwwrlr <= wwrlr[0] & wval[0];
        wwwrctr <= wwrctr[0] & wval[0];
        wwwrxer <= wwrxer[0] & wval[0];
        wwcr <= wcr[0];
        wwxer <= wxer[0];
        if (w_lsu[0] & wval[0])
        	wgoto(WRITEBACK1);
        else if (wval[1] & w_write1)
          wgoto(WRITEBACK2);
        else if (wval[1] & w_lsu[1])
        	wgoto(WRITEBACK3);
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
        wwwrrf <= 1'b1;
        if (wval[1] & w_write1)
          wgoto(WRITEBACK2);
        else if (wval[1] & w_lsu[1])
        	wgoto(WRITEBACK3);
        else begin
	        writeback_done <= TRUE;
  	      wgoto(WWAIT);
	      end
      end
    WRITEBACK2:
      begin
		  	if (wcause[1]) begin
  				srr0 <= wpc[1];
  				srr1 <= msr;
		  		wmod_pc[1] <= TRUE;
		  		if (wcause[1][7])
		  			wnext_pc[1] <= {FLT_EXTERNAL,8'h00};
		  		else
		  			wnext_pc[1] <= {wcause[1],8'h00};
		  	end
    		case(wir[1][31:26])
    		SC:
    			begin
    				srr0 <= wpc[1] + 3'd4;
    				srr1 <= msr;
    				wmod_pc[1] <= TRUE;
    				wnext_pc[1] <= {FLT_SYSTEM_CALL,8'h00};
    			end
    		R2:
    			case(wir[1][10:1])
    			MTMSR:	msr <= wia[1];
    			default:	;
					endcase      		
    		CR2:
    			case(wir[1][10:1])
    			RFI:	msr <= srr0;
    			default:	;
    			endcase
        MTSPR:
          case(wir[1][20:11])
          10'd26:		srr0 <= wia[1];
          10'd27:	  srr1 <= wia[1];
          10'd272,10'd273,10'd274,10'd275:
          					sprg[wir[1]][12:11] <= wia[1];
          10'd256:  lr <= wia[1];
          10'd288:  ctr <= wia[1];
          default:  ;
          endcase
    		default:	;
    		endcase
        wwRd <= wRd[1];
        wwres <= wres[1];
        wwval <= wval[1] & wwrrf[1];
        wwwrrf <= wwrrf[1] & wval[1];
        wwwrcrf <= wwrcrf[1] & wval[1];
        wwwrlr <= wwrlr[1] & wval[1];
        wwwrctr <= wwrctr[1] & wval[1];
        wwwrxer <= wwrxer[1] & wval[1];
        wwcr <= wcr[1];
        wwxer <= wxer[1];
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
        wwwrrf <= 1'b1;
        writeback_done <= TRUE;
        wgoto(WWAIT);
      end
    WWAIT:
    	begin
`ifdef SIM    	
		  	$display("=================================================================");
		  	$display("Time: %d  Tick:%d  Inst. Count Valid: %d  IPC:%f", $time, tick, inst_ctr, $itor(inst_ctr)/$itor(tick));
		  	$display("Inst. Count Total: %d  IPC:%f", inst_ctr2, $itor(inst_ctr2)/$itor(tick));
		  	$display("Stalls: %d  SPC:%f", stall_ctr, $itor(stall_ctr)/$itor(tick));
		  	$display("pc0: %h pc1:%h", pc[0], pc[1]);
		  	$display("Regfile");
		  	for (n = 0; n < 32; n = n + 4)
		  		$display("r%d: %h  r%d:%h  r%d:%h  r%d:%h",
		  			n[4:0]+0, regfile[n],
		  			n[4:0]+1, regfile[n+1],
		  			n[4:0]+2, regfile[n+2],
		  			n[4:0]+3, regfile[n+3]);
		  	$display("lr: %h ctr: %h", lr, ctr);
		  	$display("0: iir: %h ir:%h  rir:%h  eir:%h  mir:%h  wir:%h", iir[0], ir[0], rir[0], eir[0], mir[0], wir[0]);
		  	$display("1: iir: %h ir:%h  rir:%h  eir:%h  mir:%h  wir:%h", iir[1], ir[1], rir[1], eir[1], mir[1], wir[1]);
		  	$display("0: dimm:%h  rimm:%h", dimm[0], rimm[0]);
		  	$display("1: dimm:%h  rimm:%h", dimm[1], rimm[1]);
		  	$display("0: rRa:%d rRb:%d rRc:%d,rRd:%d", rRa[0], rRb[0], rRc[0], rRd[0]);
		  	$display("1: rRa:%d rRb:%d rRc:%d,rRd:%d", rRa[1], rRb[1], rRc[1], rRd[1]);
		  	$display("0: rid:%h  ria:%h  rib:%h  ric:%h  rimm:%h", rid[0], ria[0], rib[0], ric[0], rimm[0]);
		  	$display("1: rid:%h  ria:%h  rib:%h  ric:%h  rimm:%h", rid[1], ria[1], rib[1], ric[1], rimm[1]);
		  	$display("0: id:%h  ia:%h  ib:%h  ic:%h  imm:%h", id[0], ia[0], ib[0], ic[0], imm[0]);
		  	$display("1: id:%h  ia:%h  ib:%h  ic:%h  imm:%h", id[1], ia[1], ib[1], ic[1], imm[1]);
		  	$display("dval:%b rval:%b eval:%b mval:%b wval:%b", dval, rval, eval, mval, wval);
		  	$display("0: eRd:%d eres:%h%c%c eea:%h", eRd[0], eres[0], eval[0] ? "v" : " ", ewrrf[0] ? "w" : " ", eea[0]);
		  	$display("1: eRd:%d eres:%h%c%c eea:%h", eRd[1], eres[1], eval[1] ? "v" : " ", ewrrf[1] ? "w" : " ", eea[1]);
		  	$display("0: mRd:%d mres:%h%c%c", mRd[0], mres[0], mval[0] ? "v" : " ", mwrrf[0] ? "w" : " ");
		  	$display("1: mRd:%d mres:%h%c%c", mRd[1], mres[1], mval[1] ? "v" : " ", mwrrf[1] ? "w" : " ");
		  	$display("0: wRd:%d wres:%h%c%c", wRd[0], wres[0], wval[0] ? "v" : " ", wwrrf[0] ? "w" : " ");
		  	$display("1: wRd:%d wres:%h%c%c", wRd[1], wres[1], wval[1] ? "v" : " ", wwrrf[1] ? "w" : " ");
`endif		  	
	      if (advance_w) begin
	        writeback_done <= FALSE;
	        tval[0] <= wval[0];
	        tval[1] <= wval[1];
	        twrrf[0] <= wwrrf[0];
	        twrrf[1] <= wwrrf[1];
	        tRd[0] <= wRd[0];
	        tRd[1] <= wRd[1];
	        tres[0] <= wres[0];
	        tres[1] <= wres[1];
	        wgoto(WRITEBACK0);
	      end
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
	if (rst_i) begin
		if (RIBO) begin
			iir[0] <= {NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]};
			iir[1] <= {NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]};
		end
		else begin
			iir[0] <= NOP_INSN;
    	iir[1] <= NOP_INSN;
  	end
		ir[0] <= NOP_INSN;
    ir[1] <= NOP_INSN;
    dval <= 2'b00;
    rir[0] <= NOP_INSN;
    rir[1] <= NOP_INSN;
    rval <= 1'b0;
    eir[0] <= NOP_INSN;
    eir[1] <= NOP_INSN;
    eval <= 2'b00;
    mir[0] <= NOP_INSN;
    mir[1] <= NOP_INSN;
    mval <= 2'b00;
    wir[0] <= NOP_INSN;
    wir[1] <= NOP_INSN;
    wval <= 2'b00;
	end
	else if (smt) begin
	  if (wmod_pc[0] & wval[0] & advance_w) begin
	    ir[0] <= NOP_INSN;
	    dval[0] <= 1'b0;
	    rir[0] <= NOP_INSN;
	    rval[0] <= 1'b0;
	    eir[0] <= NOP_INSN;
	    eval[0] <= 1'b0;
	    mir[0] <= NOP_INSN;
	    mval[0] <= 1'b0;
	    wir[0] <= NOP_INSN;
	    wval[0] <= 1'b0;
	  end
	  if (emod_pc[0] & eval[0] & advance_e) begin
	    ir[0] <= NOP_INSN;
	    dval[0] <= 1'b0;
	    rir[0] <= NOP_INSN;
	    rval[0] <= 1'b0;
	    eir[0] <= NOP_INSN;
	    eval[0] <= 1'b0;
	  end
	  else if (dmod_pc[0] & dval[0] & advance_d) begin
	    ir[0] <= NOP_INSN;
	    dval[0] <= 1'b0;
	  end
	  if (wmod_pc[1] & wval[1] & advance_w) begin
	    ir[1] <= NOP_INSN;
	    dval[1] <= 1'b0;
	    rir[1] <= NOP_INSN;
	    rval[1] <= 1'b0;
	    eir[1] <= NOP_INSN;
	    eval[1] <= 1'b0;
	    mir[1] <= NOP_INSN;
	    mval[1] <= 1'b0;
	    wir[1] <= NOP_INSN;
	    wval[1] <= 1'b0;
	  end
	  if (emod_pc[1] & eval[1] & advance_e) begin
	    ir[1] <= NOP_INSN;
	    dval[1] <= 1'b0;
	    rir[1] <= NOP_INSN;
	    rval[1] <= 1'b0;
	    eir[1] <= NOP_INSN;
	    eval[1] <= 1'b0;
	  end
	  else if (dmod_pc[1] & dval[1] & advance_d) begin
	    ir[1] <= NOP_INSN;
	    dval[1] <= 1'b0;
	  end
	end
	else begin
	  if (wmod_pc[0] & wval[0] & advance_w) begin
	    ir[0] <= NOP_INSN;
	    ir[1] <= NOP_INSN;
	    dval <= 2'b00;
	    rir[0] <= NOP_INSN;
	    rir[1] <= NOP_INSN;
	    rval <= 2'b00;
	    eir[0] <= NOP_INSN;
	    eir[1] <= NOP_INSN;
	    eval <= 2'b00;
	    mir[0] <= NOP_INSN;
	    mir[1] <= NOP_INSN;
	    mval <= 2'b00;
	    wir[0] <= NOP_INSN;
	    wir[1] <= NOP_INSN;
	    wval <= 2'b00;
	  end
	  else if (wmod_pc[1] & wval[1] & advance_w) begin
	    ir[0] <= NOP_INSN;
	    ir[1] <= NOP_INSN;
	    dval <= 2'b00;
	    rir[0] <= NOP_INSN;
	    rir[1] <= NOP_INSN;
	    rval <= 2'b00;
	    eir[0] <= NOP_INSN;
	    eir[1] <= NOP_INSN;
	    eval <= 2'b00;
	    mir[0] <= NOP_INSN;
	    mir[1] <= NOP_INSN;
	    mval <= 2'b00;
	    wir[0] <= NOP_INSN;
	    wir[1] <= NOP_INSN;
	    wval <= 2'b00;
	  end
	  else if (emod_pc[0] & eval[0] & advance_e) begin
	    ir[0] <= NOP_INSN;
	    ir[1] <= NOP_INSN;
	    dval <= 2'b00;
	    rir[0] <= NOP_INSN;
	    rir[1] <= NOP_INSN;
	    rval <= 2'b00;
	    eir[0] <= NOP_INSN;
	    eir[1] <= NOP_INSN;
	    eval <= 2'b00;
	    mir[1] <= NOP_INSN;
	    mval[1] <= 1'b0;
	  end
	  else if (emod_pc[1] & eval[1] & advance_e) begin
	    ir[0] <= NOP_INSN;
	    ir[1] <= NOP_INSN;
	    dval <= 2'b00;
	    rir[0] <= NOP_INSN;
	    rir[1] <= NOP_INSN;
	    rval <= 1'b0;
	    eir[0] <= NOP_INSN;
	    eir[1] <= NOP_INSN;
	    eval <= 2'b00;
	  end
	  else if (dmod_pc[0] & dval[0] & advance_d) begin
	    ir[0] <= NOP_INSN;
	    ir[1] <= NOP_INSN;
	    dval <= 2'b00;
	    rir[1] <= NOP_INSN;
	    rval[1] <= 1'b0;
	  end
	  else if (dmod_pc[1] & dval[1] & advance_d) begin
	    ir[0] <= NOP_INSN;
	    ir[1] <= NOP_INSN;
	    dval <= 2'b00;
	  end
	end
end
endtask

endmodule
