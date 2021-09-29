// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nPowerSIO.sv
// - Scalar In Order
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

module nPowerSIO(rst_i, clk_i, nmi_i, irq_i, icause_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
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
output reg [3:0] sel_o;
output reg [AWID-1:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o = 32'd0;

wire clk_g;
assign clk_g = clk_i;

reg [5:0] state;
reg [31:0] pc;

// Instruction fetch stage vars
reg [3:0] istate;

reg [31:0] ipc;
reg [7:0] icause [0:1];
reg [31:0] ir,iir;
reg [31:0] lr, ctr;
reg ival;
wire advance_i;
wire stall_i;
reg ifetch_done;
reg iaccess;
wire iaccess_pending = !ifetch_done;

// Decode stage vars
reg [1:0] dstate;
reg [7:0] dcause;
wire advance_d;
reg decode_done;
reg dval;
reg wrrf, wrcrf, rdcrf;
reg wrlr, wrctr, rdlr, rdctr;
reg wrxer, rdxer;
reg [AWID-1:0] dpc;
reg [5:0] Rd;
reg [5:0] Ra;
reg [5:0] Rb;
reg [5:0] Rc;
reg [4:0] Bt;
reg [4:0] Ba;
reg [4:0] Bb;
reg [31:0] dimm;
reg dmod_pc;
reg [AWID-1:0] dnext_pc;
reg illegal_insn;
reg d_addi;
reg d_ld, d_st;
reg d_cmp;
reg d_bc;
reg d_sync;
reg d_multicycle;
reg lsu;

// Regfetch stage vars
reg [1:0] rstate;
reg [7:0] rcause;
wire advance_r;
wire stall_r;
reg rdone;
reg regfetch_done;
reg rval;
reg [31:0] rir;
reg rwrrf, rwrcrf, rrdcrf;
reg rwrlr, rwrctr, rrdlr, rrdctr;
reg rwrxer, rrdxer;
reg [AWID-1:0] rpc;
reg [5:0] rRd;
reg [5:0] rRa;
reg [5:0] rRb;
reg [5:0] rRc;
reg [4:0] rBa;
reg [4:0] rBb;
reg [31:0] rimm;
reg [31:0] rid;
reg [31:0] ria;
reg [31:0] rib;
reg [31:0] ric;
reg r_lsu;
reg r_ra0;
reg r_ld, r_st;
reg r_cmp;
reg r_bc;
reg r_sync;
reg r_multicycle;
reg [31:0] rcr;
reg [AWID-1:0] rlr;
reg [31:0] rctr;
reg [31:0] rxer;

// Execute stage vars
reg [2:0] estate;
wire advance_e;
reg execute_done;
reg eval;
reg [31:0] eir;
reg ewrrf, ewrcrf;
reg ewrlr, ewrctr;
reg ewrxer;
reg [AWID-1:0] epc;
reg [5:0] eRa;
reg [5:0] eRd;
reg [31:0] id;
reg [31:0] ia;
reg [31:0] ib;
reg [31:0] ic;
reg [31:0] imm;
reg [31:0] eres, eres2;
reg [AWID-1:0] eea;
reg eillegal_insn;
reg emod_pc;
reg [AWID-1:0] enext_pc;
reg e_ra0;
reg e_ld, e_st;
reg e_lsu;
reg e_cmp;
reg e_bc;
reg e_sync;
reg e_multicycle;
reg [AWID-1:0] elr;
reg [31:0] ectr;
reg [31:0] ecr;
reg [31:0] exer;
reg [1:0] etrap;
reg [7:0] ecause;
reg takb;

// Memory stage vars
reg [2:0] mstate;
wire advance_m;
reg [AWID-1:0] mpc;
reg memory_done;
reg maccess_pending;
reg mval;
reg [31:0] mir;
reg [5:0] mRa;
reg [5:0] mRd;
reg [1:0] mwrrf, mwrcrf;
reg [1:0] mwrlr, mwrctr;
reg [1:0] mwrxer;
reg [AWID-1:0] ea;
reg [31:0] mid;
reg [31:0] mia;
reg [31:0] mres, mres2;
reg millegal_insn;
reg m_lsu;
reg m_st;
reg m_sync;
reg [31:0] mcr;
reg [31:0] mctr;
reg [31:0] mxer;
reg [AWID-1:0] mlr;
reg [7:0] sel;
reg [63:0] dat = 64'd0, dati = 64'd0;
reg maccess;
reg [AWID-1:0] iadr;
reg [7:0] mcause;

// Writeback stage vars
reg [2:0] wstate;
wire advance_w;
reg writeback_done;
reg [AWID-1:0] wpc;
reg [31:0] wia;
reg [31:0] wwres;
reg [31:0] wres,wres2;
reg [AWID-1:0] wea;
reg [AWID-1:0] wwea;
reg [31:0] wir;
reg [5:0] wRa;
reg [5:0] wRd;
reg [5:0] wwRd;
reg wwval;
reg wval;
reg wwwrrf;
reg wwwrcrf;
reg wwrrf, wwrcrf;
reg wwrlr, wwrctr;
reg wwrxer;
reg wwwrlr, wwwrctr;
reg wwwrxer;
reg willegal_insn;
reg wmod_pc;
reg [AWID-1:0] wnext_pc;
reg w_lsu;
reg w_sync;
reg [31:0] wcr;
reg [31:0] wwcr;
reg [AWID-1:0] wlr;
reg [31:0] wctr;
reg [31:0] wxer;
reg [31:0] wwxer;
reg [7:0] wcause;


reg [31:0] tick;
reg [31:0] inst_ctr;
reg [31:0] inst_ctr2;
reg [31:0] stall_ctr;

reg [1:0] tval;
reg [1:0] twrrf;
reg [5:0] tRd;
reg [31:0] tres;

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
integer n;
initial begin
	for (n = 0; n < 64; n = n + 1)
		regfile[n] <= 32'd0;
end
wire [31:0] rfod;
wire [31:0] rfoa;
wire [31:0] rfob;
wire [31:0] rfoc;
assign rfod = regfile[rRd];
assign rfoa = regfile[rRa];
assign rfob = regfile[rRb];
assign rfoc = regfile[rRc];
always @(posedge clk_g)
  if (wwwrrf && wwval)
    regfile[wwRd] <= wwres;

reg [31:0] cregfile = 0;
wire croa;
wire crob;
assign croa = cregfile[rBa];
assign crob = cregfile[rBb];
wire [31:0] cro = cregfile;

always @(posedge clk_g)
  if (wwwrxer)
    xer <= wwxer;
always @(posedge clk_g)
  if (wwwrcrf)
    cregfile <= wwcr;
    
reg [31:0] sprg [0:3];


// If there is a sync in the pipeline stall the following stages until the sync clears.
assign stall_i = |d_sync | |r_sync | |e_sync | |m_sync | |w_sync;
assign stall_r = 	((e_ld||e_st) && ((rRd==eRd && r_st) || (rRa==eRd) || (rRb==eRd) || (rRc==eRd)) && eval && rval) ||
              		((e_st & e_lsu) && ((rRd==eRa) || (rRa==eRa) || (rRb==eRa) || (rRc==eRa)) && eval && rval)
								 	  /*
								 	  ((rrdlr[0] & ewrlr[0]) || (rrdctr[0] & ewrctr[0]) || (rrdxer[0] & ewrxer[0]) || (rrdcrf[0] & ewrcrf[0]) && rval[0] && eval[0]) ||
								 	  ((rrdlr[0] & ewrlr[1]) || (rrdctr[0] & ewrctr[1]) || (rrdxer[0] & ewrxer[1]) || (rrdcrf[0] & ewrcrf[1]) && rval[0] && eval[1])
								 	  */
                		;
// Pipeline advance
assign advance_w = ifetch_done & &decode_done & &regfetch_done & &execute_done & &memory_done & &writeback_done;
assign advance_m = advance_w & ~(|w_sync);
assign advance_e = advance_m & ~(|m_sync | |w_sync);
assign advance_r = advance_e & ~stall_r & ~(|e_sync | |m_sync | |w_sync);
assign advance_d = advance_r & ~stall_r & ~(|r_sync | |e_sync | |m_sync | |w_sync);
assign advance_i = advance_d & ~stall_i;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage combo logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [63:0] shli;
wire [31:0] roli;
wire [63:0] shlr;
wire [31:0] rolr;
assign shli = {32'h0,ia} << ir[15:11];
assign shlr = {32'h0,ia} << ib[4:0];
assign roli = shli[63:32]|shli[31:0];
assign rolr = shlr[63:32]|shlr[31:0];
wire [4:0] mb;
wire [4:0] me;
assign mb = ir[10:6];
assign me = ir[ 5:1];
reg [31:0] rlwimi_o;
reg [31:0] rlwinm_o;
reg [31:0] rlwnm_o;

integer n1;
always_comb
begin
  for (n1 = 0; n1 < 32; n1 = n1 + 1) begin
    if (n1 >= mb && n1 <= me)
      rlwimi_o[n1] = roli[n1];
    else
      rlwimi_o[n1] = id[n1];
  end
end

integer n2;
always_comb
begin
  for (n2 = 0; n2 < 32; n2 = n2 + 1) begin
    if (n2 >= mb && n2 <= me)
      rlwinm_o[n2] <= roli[n2];
    else
      rlwinm_o[n2] <= 1'b0;
  end
end

integer n3;
always_comb
begin
  for (n3 = 0; n3 < 32; n3 = n3 + 1) begin
    if (n3 >= mb && n3 <= me)
      rlwnm_o[n3] <= rolr[n3];
    else
      rlwnm_o[n3] <= 1'b0;
  end
end

wire [63:0] prodr;
wire [63:0] prodi;
assign prodr = $signed(ia) * $signed(ib);
assign prodi = $signed(ia) * $signed(imm);

wire [31:0] cntlzo;

cntlz32 uclz1 (
	.i(ia),
	.o(cntlzo)
);

reg alu_ld;
reg div_sign;
wire div_done;
wire [127:0] divo1;
wire [63:0] divo;

divr2 #(.FPWID(32)) udv1
(
	.clk4x(clk_g),
	.ld(alu_ld),
	.a(ia),
	.b(ib),
	.q(divo),
	.r(),
	.done(div_done),
	.lzcnt()
);

wire [4:0] trp;
wire [4:0] trpr;

assign trp[0] = $signed(ia) < $signed(imm);
assign trp[1] = $signed(ia) > $signed(imm);
assign trp[2] = ia == imm;
assign trp[3] = ia < imm;
assign trp[4] = ia > imm;

assign trpr[0] = $signed(ia) < $signed(ib);
assign trpr[1] = $signed(ia) > $signed(ib);
assign trpr[2] = ia == ib;
assign trpr[3] = ia < ib;
assign trpr[4] = ia > ib;

wire pe_advance_r;
edge_det uedar (.rst(rst_i), .clk(clk_g), .ce(1'b1), .i(advance_r), .pe(pe_advance_r), .ne(), .ee());

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [255:0] ici, iri;
reg [2:0] icnt;
reg [1:0] waycnt;
(* ram_style="block" *)
reg [255:0] icache0 [0:pL1CacheLines-1];
reg [255:0] icache1 [0:pL1CacheLines-1];
reg [255:0] icache2 [0:pL1CacheLines-1];
reg [255:0] icache3 [0:pL1CacheLines-1];
wire [255:0] ic0 = icache0[pc[pL1msb:5]];
wire [255:0] ic1 = icache1[pc[pL1msb:5]];
wire [255:0] ic2 = icache2[pc[pL1msb:5]];
wire [255:0] ic3 = icache3[pc[pL1msb:5]];
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
reg ihit1a;
reg ihit1b;
reg ihit1c;
reg ihit1d;
always @*	//(posedge clk_g)
  ihit1a = ictag0[pc[pL1msb:5]]==pc[AWID-1:5] && icvalid0[pc[pL1msb:5]];
always @*	//(posedge clk_g)
  ihit1b = ictag1[pc[pL1msb:5]]==pc[AWID-1:5] && icvalid1[pc[pL1msb:5]];
always @*	//(posedge clk_g)
  ihit1c = ictag2[pc[pL1msb:5]]==pc[AWID-1:5] && icvalid2[pc[pL1msb:5]];
always @*	//(posedge clk_g)
  ihit1d = ictag3[pc[pL1msb:5]]==pc[AWID-1:5] && icvalid3[pc[pL1msb:5]];
wire ihit = ihit1a|ihit1b|ihit1c|ihit1d;
initial begin
  icvalid0 = {pL1CacheLines{1'd0}};
  icvalid1 = {pL1CacheLines{1'd0}};
  icvalid2 = {pL1CacheLines{1'd0}};
  icvalid3 = {pL1CacheLines{1'd0}};
  for (n = 0; n < pL1CacheLines; n = n + 1) begin
  /*
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
  	*/
    ictag0[n] = 32'd1;
    ictag1[n] = 32'd1;
    ictag2[n] = 32'd1;
    ictag3[n] = 32'd1;
  end
end

always_ff @(posedge clk_g)
begin
  tInsFetch();
  tDecode();
  tRegFetch();
  tExecute();
  tMemory();
  tWriteback();

  tValid();
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

task tInsFetch;
begin
	if (rst_i) begin
		ifetch_done <= FALSE;
		wb_nack();
	  pc <= RSTPC;
	  inst_ctr <= 32'd0;
	  msr <= 32'd1;		// little endian mode
	  iaccess <= FALSE;
	  waycnt <= 2'd0;
		igoto (IFETCH1);
	end
	else begin
	case(istate)
IFETCH1:
  begin
    if (!ifetch_done)
      case(1'b1)
      ihit1a: begin iri <= ic0; end
      ihit1b: begin iri <= ic1; end
      ihit1c: begin iri <= ic2; end
      ihit1d: begin iri <= ic3; end
      default:  iri <= {8{NOP_INSN}};
      endcase
    if (!ihit) begin
      icnt <= 3'd0;
      igoto (IACCESS);
    end
    else
      igoto (IALIGN);
  end
IALIGN:
  begin
    iir <= iri >> {pc[4:2],5'b0};
    ifetch_done <= TRUE;
 	  igoto (IWAIT);
    ipc <= pc;
    pc <= pc + 4'd4;
  end
/*
	IFETCH1:
		if (!ack_i) begin
			iaccess <= TRUE;
			vpa_o <= HIGH;
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'hF;
			adr_o <= pc;
			igoto (IACK);
		end
	IACK:
		if (ack_i) begin
		  iaccess <= FALSE;
			wb_nack();
			iir <= dat_i;
			ifetch_done <= TRUE;
			igoto (IWAIT);
		end
*/
	IWAIT:
		begin
	    if (wmod_pc) begin
	      pc <= wnext_pc;
	      if (be) dcause <= FLT_TRACE;
	    end
	    else if (emod_pc) begin
	      pc <= enext_pc;
	      if (be) dcause <= FLT_TRACE;
	    end
	    else if (dmod_pc) begin
	      pc <= dnext_pc;
	      if (be) dcause <= FLT_TRACE;
	    end
			if (advance_i) begin
		  	dval <= 1'b1;
				ifetch_done <= FALSE;
		  	if (RIBO)
			    ir <= {iir[7:0],iir[15:8],iir[23:16],iir[31:24]};
			  else
			  	ir <= iir;
		    if (irq_i & ee)
		    	dcause <= icause_i|8'h80;
		  	else
		    	dcause <= FLT_NONE;
		    dpc <= ipc;
		    igoto(IFETCH1);
			end
		  else if (advance_d) begin
	  		d_sync <= 2'b00;
	  		ir <= NOP_INSN;
	  		dval <= FALSE;
	  	end
  	end
	IACCESS:
	  begin
	    if (maccess_pending==2'b00||vpa_o) begin
	      iaccess <= TRUE;
	      igoto (IACCESS_CYC);
	    end
	    if (!iaccess) begin
	      if (!ifetch_done)
	        iadr <= {pc[AWID-1:5],5'h0};
	    end
	    else
	      iadr <= {iadr[AWID-1:4],4'h0} + 5'h10;
	  end
	IACCESS_CYC:
    if (~ack_i) begin
      vpa_o <= HIGH;
      cyc_o <= HIGH;
      stb_o <= HIGH;
      we_o <= LOW;
      sel_o <= 4'hF;
      adr_o <= iadr;
      igoto(IACCESS_ACK);
    end
	IACCESS_ACK:
	  if (ack_i) begin
	    icnt <= icnt + 1'd1;
	    case(icnt)
	    3'd0: ici[31: 0] <= dat_i;
	    3'd1: ici[63:32] <= dat_i;
	    3'd2:	ici[95:64] <= dat_i;
	    3'd3:	ici[127:96] <= dat_i;
	    3'd4:	ici[159:128] <= dat_i;
	    3'd5: ici[191:160] <= dat_i;
	    3'd6:	ici[223:192] <= dat_i;
	    3'd7:	ici[255:224] <= dat_i;
	    endcase
	    if (icnt==3'd7) begin
	    	wb_nack();
	      iaccess <= FALSE;
	      igoto (IC_UPDATE);
	    end
	    else begin
	      stb_o <= LOW;
	      iadr <= {iadr[AWID-1:2],2'h0} + 3'h4;
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
		begin
    	waycnt <= waycnt + 1'd1;
	  	igoto(IFETCH1);
		end
	ICU2:
	  igoto(IFETCH0);
  default:
  	begin
  		ifetch_done <= FALSE;
  		igoto (IFETCH1);
  	end
	endcase
	end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

task tDecode;
begin
  if (rst_i) begin
    rRd <= 6'd0;
    rRa <= 6'd0;
    rRb <= 6'd0;
    rRc <= 6'd0;
    rimm <= 32'd0;
    Rd <= 6'd0;
    Ra <= 6'd0;
    Rb <= 6'd0;
    Rc <= 6'd0;
    dimm <= 32'd0;
    d_ld <= FALSE;
    d_st <= FALSE;
    d_addi <= FALSE;
    d_cmp <= FALSE;
    d_bc <= FALSE;
    d_multicycle <= FALSE;
    r_ld <= FALSE;
    r_st <= FALSE;
    r_ra0 <= FALSE;
    r_lsu <= FALSE;
    r_cmp <= FALSE;
    r_sync <= FALSE;
    r_bc <= FALSE;
    r_multicycle <= FALSE;
    rcr <= 32'd0;
    rctr <= 32'd0;
    rlr <= 32'd0;
    rxer <= 32'd0;
    rwrcrf <= FALSE;
    rwrctr <= FALSE;
    rwrlr <= FALSE;
    rwrrf <= FALSE;
    rwrxer <= FALSE;
    wrctr <= FALSE;
    wrlr <= FALSE;
    wwcr <= FALSE;
    rrdxer <= FALSE;
    rrdcrf <= FALSE;
    rrdctr <= FALSE;
    rrdlr <= FALSE;
    rdxer <= FALSE;
    rdcrf <= FALSE;
    rdctr <= FALSE;
    rdlr <= FALSE;
    wwea <= FALSE;
    wwrctr <= FALSE;
    wrrf <= FALSE;
    wrcrf <= FALSE;
    wrxer <= FALSE;
    lsu <= FALSE;
    rpc <= RSTPC;
    dval <= 1'b0;
    decode_done <= TRUE;
    dstate <= DWAIT;
    illegal_insn <= FALSE;
    dnext_pc <= RSTPC;
    rcause <= FLT_NONE;
	end
	else begin
    case(dstate)
    DECODE:
      begin
        decode_done <= TRUE;
       	dstate <= DWAIT;
        illegal_insn <= TRUE;
        Rd <= ir[25:21];
        Ra <= ir[20:16];
        Rb <= ir[15:11];
        Rc <= ir[10: 6];
        Bt <= ir[25:21];
        Ba <= ir[20:16];
        Bb <= ir[15:11];
        lsu <= FALSE;
        wrrf <= FALSE;
        wrcrf <= FALSE;
        wrxer <= FALSE;
        wrlr <= FALSE;
        wrctr <= FALSE;
        rdxer <= FALSE;
        rdcrf <= FALSE;
        rdctr <= FALSE;
        rdlr <= FALSE;
        dmod_pc <= FALSE;
        d_bc <= FALSE;
        d_cmp <= FALSE;
        d_ld <= FALSE;
        d_st <= FALSE;
        d_addi <= FALSE;
		    d_multicycle <= FALSE;
        dimm <= 32'd0;
		    dnext_pc <= RSTPC;
        case(ir[31:26])
        R2:
          case(ir[10:1])
          ADD,ADDO,ADDC,ADDCO,ADDE,ADDEO,ADDME,ADDMEO,ADDZE,ADDZEO:
          	begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          SUBFME,SUBFMEO,SUBFZE,SUBFZEO,SUBFC,SUBFCO,SUBFE,SUBFEO:
          	begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          SUBF,SUBFO:begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          NEG: begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          CMP: begin wrcrf <= TRUE; illegal_insn <= FALSE; d_cmp <= TRUE; end
          CMPL:begin wrcrf <= TRUE; illegal_insn <= FALSE; d_cmp <= TRUE; end
          MULLW: begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          MULLWO: begin wrrf <= TRUE; wrcrf <= ir[0]; wrxer <= TRUE; illegal_insn <= FALSE; end
          DIVW:		begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; d_multicycle <= TRUE; end
          DIVWO:	begin wrrf <= TRUE; wrcrf <= ir[0]; wrxer <= TRUE; illegal_insn <= FALSE; d_multicycle <= TRUE; end
          DIVWU:	begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; d_multicycle <= TRUE; end
          DIVWUO: begin wrrf <= TRUE; wrcrf <= ir[0]; wrxer <= TRUE; illegal_insn <= FALSE; d_multicycle <= TRUE; end
          AND,ANDC,OR,ORC,XOR,NAND,NOR,EQV,SLW,SRW,SRAW:
          	begin
          		Ra <= ir[25:21];
          		Rd <= ir[20:16];
          		wrrf <= TRUE;
          		wrcrf <= ir[0];
          		illegal_insn <= FALSE;
          	end
          SRAWI:begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          EXTSB:begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          EXTSH:begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          CNTLZW:	begin wrrf <= TRUE; wrcrf <= ir[0]; illegal_insn <= FALSE; end
          LBZX:   begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; end
          LHZX:   begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; end
          LHAX:   begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; end
          LWZX:   begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; end
          STBX:   begin illegal_insn <= FALSE; d_st <= TRUE; end
          STHX:   begin illegal_insn <= FALSE; d_st <= TRUE; end
          STWX:   begin illegal_insn <= FALSE; d_st <= TRUE; end
          LBZUX:  begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; lsu <= TRUE; end
          LHZUX:  begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; lsu <= TRUE; end
          LHAUX:  begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; lsu <= TRUE; end
          LWZUX:  begin wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; lsu <= TRUE; end
          STBUX:  begin illegal_insn <= FALSE; d_st <= TRUE; lsu <= TRUE; end
          STHUX:  begin illegal_insn <= FALSE; d_st <= TRUE; lsu <= TRUE; end
          STWUX:  begin illegal_insn <= FALSE; d_st <= TRUE; lsu <= TRUE; end
          MCRXR:  begin wrcrf <= TRUE; wrxer <= TRUE; illegal_insn <= FALSE; end
          MFCR:   begin wrrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          MTCRF:  begin wrcrf <= TRUE; illegal_insn <= FALSE; end
          MFSPR:
          	begin
              case(eir[20:11])
              10'd32:	rdxer <= TRUE;
              10'd256:	rdlr <= TRUE;
              10'd288:	rdctr <= TRUE;
            	endcase
          		wrrf <= TRUE;
          		illegal_insn <= FALSE;
          	end
          MTSPR:
            begin
              case(eir[20:11])
              10'd32:   begin wrxer <= TRUE; illegal_insn <= FALSE; end
              10'd256:  begin wrlr <= TRUE; illegal_insn <= FALSE; end
              10'd288:  begin wrctr <= TRUE; illegal_insn <= FALSE; end
              default:  ;
              endcase
            end
          SYNC:
          	begin
          		// force a flush of the incoming instruction.
          		dmod_pc <= TRUE;
          		dnext_pc <= dpc + 3'd4;
          		d_sync <= TRUE;
          		illegal_insn <= FALSE;
          	end
	        TW:	 begin illegal_insn <= FALSE; end
          default:  ;
          endcase
        ADDI:
        	begin
        		d_addi <= TRUE;
        		wrrf <= TRUE;
        		dimm <= {{16{ir[15]}},ir[15:0]};
        		illegal_insn <= FALSE;
        	end
        ADDIC:
        	begin
        		wrrf <= TRUE;
        		dimm <= {{16{ir[15]}},ir[15:0]};
        		illegal_insn <= FALSE;
        	end
        ADDICD:
        	begin
        		wrrf <= TRUE;
        		wrcrf <= TRUE;
        		dimm <= {{16{ir[15]}},ir[15:0]};
        		illegal_insn <= FALSE;
        	end
        ADDIS:
        	begin
        		d_addi <= TRUE;
        		wrrf <= TRUE;
        		dimm <= {ir[15:0],16'h0000};
        		illegal_insn <= FALSE;
        	end
        SUBFIC:
        	begin
        		wrrf <= TRUE;
        		dimm <= {{16{ir[15]}},ir[15:0]};
        		illegal_insn <= FALSE;
        	end
        CMPI:  begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; wrcrf <= TRUE; d_cmp <= TRUE; end
        CMPLI: begin dimm <= {16'h0000,ir[15:0]}; illegal_insn <= FALSE; wrcrf <= TRUE; d_cmp <= TRUE; end
        MULLI: begin wrrf <= TRUE; dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; end
        ANDI:  begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= {16'hFFFF,ir[15:0]}; illegal_insn <= FALSE; end
        ANDIS: begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= {ir[15:0],16'hFFFF}; illegal_insn <= FALSE; end
        ORI:   begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= {16'h0000,ir[15:0]}; illegal_insn <= FALSE; end
        ORIS:  begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= {ir[15:0],16'h0000}; illegal_insn <= FALSE; end
        XORI:  begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= {16'h0000,ir[15:0]}; illegal_insn <= FALSE; end
        XORIS: begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= {ir[15:0],16'h0000}; illegal_insn <= FALSE; end
        RLWIMI:begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= ir[15:11]; illegal_insn <= FALSE; end
        RLWINM:begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; dimm <= ir[15:11]; illegal_insn <= FALSE; end
        RLWNM: begin Ra <= ir[25:21]; Rd <= ir[20:16]; wrrf <= TRUE; illegal_insn <= FALSE; end
        TWI:	 begin illegal_insn <= FALSE; end
				SC:		 begin illegal_insn <= ~ir[1]; end
        B:     begin
                  illegal_insn <= FALSE;
                  dmod_pc <= dval;
                  if (ir[1])
                    dnext_pc <= {dpc,ir[25:2],2'b00};
                  else
                    dnext_pc <= dpc + {{6{ir[25]}},ir[25:2],2'b00};
                  wrlr <= ir[0];
                end
        BC:
        	begin
        		d_bc <= TRUE;
        		wrlr <= ir[0];
        		rdcrf <= TRUE;
        		illegal_insn <= FALSE;
        	end
        CR2:
          case(ir[10:1])
          BCCTR:
          	begin
      				wrlr <= ir[0];
      				rdctr <= TRUE;
      				rdcrf <= TRUE;
      				illegal_insn <= FALSE;
      			end
          BCLR:
          	begin
          		wrlr <= ir[0];
          		rdlr <= TRUE;
          		rdcrf <= TRUE;
          		illegal_insn <= FALSE;
          	end
          CRAND: begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CROR:  begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CRXOR: begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CRNAND:begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CRNOR: begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CREQV: begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CRANDC:begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          CRORC: begin wrcrf <= TRUE; rdcrf <= TRUE; illegal_insn <= FALSE; end
          RFI:
          	begin
          		if (dval) begin
          			dmod_pc <= TRUE;
          			dnext_pc <= srr1;
          		end
          	end
          default:  ;
          endcase

        LBZ,LHZ,LHA,LWZ:  
        	begin dimm <= {{16{ir[15]}},ir[15:0]}; wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; end
        LBZU,LHZU,LHAU,LWZU:
        	begin dimm <= {{16{ir[15]}},ir[15:0]}; wrrf <= TRUE; illegal_insn <= FALSE; d_ld <= TRUE; lsu <= TRUE;	end
        STB:   begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; d_st <= TRUE; end
        STH:   begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; d_st <= TRUE; end
        STW:   begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; d_st <= TRUE; end
        STBU:  begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; d_st <= TRUE; lsu <= TRUE; end
        STHU:  begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; d_st <= TRUE; lsu <= TRUE; end
        STWU:  begin dimm <= {{16{ir[15]}},ir[15:0]}; illegal_insn <= FALSE; d_st <= TRUE; lsu <= TRUE; end
        default:  ;
        endcase
      end
    DWAIT:
      if (advance_d) begin
      	rval <= dval;
        rir <= ir;
        rpc <= dpc;
        rRd <= Rd;
        rRa <= Ra;
        rRb <= Rb;
        rRc <= Rc;
        rBa <= Ba;
        rBb <= Bb;
        rrdlr <= rdlr;
        rrdctr <= rdctr;
        rrdxer <= rdxer;
        rrdcrf <= rdcrf;
        rwrlr <= wrlr;
        rwrctr <= wrctr;
        rimm <= dimm;
        r_lsu <= lsu;
        r_ld <= d_ld;
        r_st <= d_st;
        r_cmp <= d_cmp;
        if (d_ld|d_st|d_addi)
        	r_ra0 <= ir[20:16]==5'd0;
        r_sync <= d_sync;
        r_bc <= d_bc;
        r_multicycle <= d_multicycle;
        rwrrf <= wrrf;
        rwrcrf <= wrcrf;
        rwrxer <= wrxer;
        rcause <= dcause;
        decode_done <= FALSE;
        dstate <= DECODE;
      end
      else if (advance_r) begin
      	r_sync <= FALSE;
      	rir <= NOP_INSN;
      end
    default:
      begin
        decode_done <= TRUE;
        dstate <= DWAIT;
      end
    endcase
	end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register Fetch Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire fwd3 = rRa==eRd && eval && ewrrf;

task tRegFetch;
if (rst_i) begin
  e_ld <= 1'b0;
  e_st <= 1'b0;
  e_ra0 <= 1'b0;
  e_lsu <= 1'b0;
  e_bc <= 1'b0;
  e_sync <= 1'b0;
  e_multicycle <= 1'b0;
  eRd <= 6'd0;
  eRa <= 6'd0;
  eres <= 32'd0;
  id <= 32'd0;
  ia <= 32'd0;
  ib <= 32'd0;
  ic <= 32'd0;
  rid <= 32'd0;
  ria <= 32'd0;
  rib <= 32'd0;
  ric <= 32'd0;
  rimm <= 32'd0;
  imm <= 32'd0;
  ectr <= 32'd0;
  ecr <= 32'd0;
  exer <= 32'd0;
  elr <= 32'd0;
  eillegal_insn <= 1'b0;
  ewrcrf <= 1'b0;
  ewrlr <= 1'b0;
  ewrctr <= 1'b0;
  ewrrf <= 1'b0;
  ewrxer <= 1'b0;
  rval <= 1'b0;
  ecause <= FLT_NONE;
  regfetch_done <= TRUE;
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
  	regfetch_done <= 1'b1;
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
  	if (stall_r)
  		stall_ctr <= stall_ctr + 2'd1;

    regfetch_done <= 1'b0;
    rgoto (RFETCH);
  end
default:
  begin
    regfetch_done <= 1'b1;
    rgoto(RWAIT);
  end
endcase
  if (advance_r) begin
	  if (rRa==6'd0 && r_ra0 && rval)
	    ia <= 32'd0;
	  else if (rRa==eRd && eval && ewrrf)
	    ia <= eres;
	  else if (rRa==eRa && eval && e_lsu)
	    ia <= eea;
	  else if (rRa==mRd && mval && mwrrf)
	    ia <= mres;
	  else if (rRa==mRa && mval && m_lsu)
	    ia <= ea;
	  else if (rRa==wRd && wval && wwrrf)
	    ia <= wres;
	  else if (rRa==wRa && wval && w_lsu)
	    ia <= wea;
/*	    
	  else if (rRa[0]==tRd[0] && tval[0] && twrrf[0])
	    ia[0] <= tres[0];
	  else if (rRa[0]==tRd[1] && tval[1] && twrrf[1])
	    ia[0] <= tres[1];
*/
	  else
	    ia <= rfoa;

	  if (rRb==eRd && eval && ewrrf)
	    ib <= eres;
	  else if (rRb==eRa && eval && e_lsu)
	    ib <= eea;
	  else if (rRb==mRd && mval && mwrrf)
	    ib <= mres;
	  else if (rRb==mRa && mval && m_lsu)
	    ib <= ea;
	  else if (rRb==wRd && wval && wwrrf)
	    ib <= wres;
	  else if (rRb==wRa && wval && w_lsu)
	    ib <= wea;
	  else
	    ib <= rfob;

	  if (rRc==eRd && eval && ewrrf)
	    ic <= eres;
	  else if (rRc==eRa && eval && e_lsu)
	    ic <= eea;
	  else if (rRc==mRd && mval && mwrrf)
	    ic <= mres;
	  else if (rRc==mRa && mval && m_lsu)
	    ic <= ea;
	  else if (rRc==wRd && wval && wwrrf)
	    ic <= wres;
	  else if (rRc==wRa && wval && w_lsu)
	    ic <= wea;
	  else
	    ic <= rfoc;

	  if (rRd==eRd && eval && ewrrf)
	    id <= eres;
	  else if (rRd==eRa && eval && e_lsu)
	    id <= eea;
	  else if (rRd==mRd && mval && mwrrf)
	    id <= mres;
	  else if (rRd==mRa && mval && m_lsu)
	    id <= ea;
	  else if (rRd==wRd && wval && wwrrf)
	    id <= wres;
	  else if (rRd==wRa && wval && w_lsu)
	    id <= wea;
	  else
	    id <= rfod;

    if (ewrcrf & eval)
      ecr <= ecr;
    else if (mwrcrf & mval)
      ecr <= mcr;
    else if (wwrcrf & wval)
      ecr <= wcr;
    else //if (rrdcrf)
      ecr <= cro;

    if (ewrcrf & eval)
      exer <= exer;
    else if (mwrcrf & mval)
      exer <= mxer;
    else if (wwrcrf & wval)
      exer <= wxer;
    else
      exer <= xer;

    if (ewrlr & eval)
      elr <= eres;
    else if (mwrlr & mval)
      elr <= mres;
    else if (wwrlr & wval)
      elr <= wres;
    else
      elr <= lr;

    if (ewrctr & eval)
      ectr <= eres;
    else if (mwrctr & mval)
      ectr <= mres;
    else if (wwrctr & wval)
      ectr <= wres;
    else
      ectr <= ctr;

    eir <= rir;
  	eval <= rval;
    imm <= rimm;
    eRd <= rRd;
    eRa <= rRa;
//    ecr <= rcr;
    epc <= rpc;
    
//    id <= rid;
//    ia <= ria;
//    ib <= rib;
//    ic <= ric;
    
    e_lsu <= r_lsu;
    e_cmp <= r_cmp;
    ewrrf <= rwrrf;
    ewrcrf <= rwrcrf;
    ewrxer <= rwrxer;
    e_bc <= d_bc;
    ewrlr <= rwrlr;
    ewrctr <= rwrctr;
		e_ld <= r_ld;
		e_st <= r_st;
		e_sync <= r_sync;
		e_multicycle <= r_multicycle;
		ecause <= rcause;
//		elr <= rlr;
//    ectr <= rctr;
//    exer <= rxer;
  end
  else if (advance_e) begin
    eval <= FALSE;
    eir <= NOP_INSN;
    e_sync <= 1'b0;
  end
end
endtask

task tin;
input [5:0] Rn;
input [31:0] rfo;
output [31:0] in;
begin
  if (Rn==6'd0 && (r_ld|r_st) && rval)
    in = 32'd0;
  else if (Rn==eRd && eval && ewrrf)
    in = eres;
  else if (Rn==eRa && eval && e_lsu)
    in = eea;
  else if (Rn==mRd && mval && mwrrf)
    in = mres;
  else if (Rn==mRa && mval && m_lsu)
    in = ea;
  else if (Rn==wRd && wval && wwrrf)
    in = wres;
  else if (Rn==wRa && wval && w_lsu)
    in = wea;
  else
    in = rfo;
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute Stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tExecute;
begin
  if (rst_i) begin
    eval <= FALSE;
    execute_done <= TRUE;
    estate <= EWAIT;
    eea <= 32'd0;
    mpc <= RSTPC;
    mRd <= 6'd0;
    mRa <= 6'd0;
    mres <= 32'd0;
    m_lsu <= FALSE;
    m_sync <= FALSE;
    mcr <= 32'd0;
    mctr <= 32'd0;
    mlr <= 32'd0;
    mxer <= 32'd0;
    mwrcrf <= FALSE;
    mwrlr <= FALSE;
    mwrctr <= FALSE;
    mwrrf <= FALSE;
    mwrxer <= FALSE;
    mia <= 32'd0;
    ecause <= 8'h00;
    mcause <= 8'h00;
		etrap <= FALSE;
    takb <= FALSE;
    millegal_insn <= FALSE;
  end
  else begin
  	alu_ld <= FALSE;
    case(estate)
    EXECUTE:
      begin
        estate <= EFLAGS;
        emod_pc <= FALSE;
		    takb <= FALSE;
				etrap <= FALSE;
		   	ecause <= 8'h00;
        case(eir[31:26])
        R2:
          case(eir[10:1])
          ADD,ADDO,ADDC,ADDCO:
          	eres <= ia + ib;
          ADDME,ADDMEO:
          	eres <= ia - 32'd1 + exer[30];
          ADDZE,ADDZEO:
          	eres <= ia + exer[30];
          ADDE,ADDEO:	eres <= ia + ib + exer[30];
          SUBF: eres <= ib - ia;
          SUBFO: eres <= ib - ia;
          SUBFME,SUBFMEO:
          	eres <= -32'd1 - ia - ~exer[30];
          SUBFZE,SUBFZEO:
          	eres <= -ia - ~exer[30];
          SUBFC,SUBFCO:
          	eres <= ib - ia;
          SUBFE,SUBFEO:
          	eres <= ib - ia - ~exer[30];
          	
          MULLW:  eres <= prodr[31:0];
          MULLWO: eres <= prodr[31:0];
          DIVW:		begin estate <= EDIV1; eir <= eir; end
          DIVWU:	begin alu_ld <= TRUE; estate <= EDIV2; div_sign <= 1'b0; eir <= eir; end
          DIVWO:	begin estate <= EDIV1; eir <= eir; end
          DIVWUO:	begin alu_ld <= TRUE; estate <= EDIV2; div_sign <= 1'b0; eir <= eir; end
          NEG:  eres <= -ia;
          CMP:  
            begin
              case(eir[25:23])
              3'd0:
                begin
                  ecr[0] <= $signed(ia) <  $signed(ib);
                  ecr[1] <= $signed(ia) >  $signed(ib);
                  ecr[2] <= $signed(ia) == $signed(ib);
                  ecr[3] <= 1'b0;
                end
              3'd1:
                begin
                  ecr[4] <= $signed(ia) <  $signed(ib);
                  ecr[5] <= $signed(ia) >  $signed(ib);
                  ecr[6] <= $signed(ia) == $signed(ib);
                  ecr[7] <= 1'b0;
                end
              3'd2:
                begin
                  ecr[8] <= $signed(ia) <  $signed(ib);
                  ecr[9] <= $signed(ia) >  $signed(ib);
                  ecr[10] <= $signed(ia) == $signed(ib);
                  ecr[11] <= 1'b0;
                end
              3'd3:
                begin
                  ecr[12] <= $signed(ia) <  $signed(ib);
                  ecr[13] <= $signed(ia) >  $signed(ib);
                  ecr[14] <= $signed(ia) == $signed(ib);
                  ecr[15] <= 1'b0;
                end
              3'd4:
                begin
                  ecr[16] <= $signed(ia) <  $signed(ib);
                  ecr[17] <= $signed(ia) >  $signed(ib);
                  ecr[18] <= $signed(ia) == $signed(ib);
                  ecr[19] <= 1'b0;
                end
              3'd5:
                begin
                  ecr[20] <= $signed(ia) <  $signed(ib);
                  ecr[21] <= $signed(ia) >  $signed(ib);
                  ecr[22] <= $signed(ia) == $signed(ib);
                  ecr[23] <= 1'b0;
                end
              3'd6:
                begin
                  ecr[24] <= $signed(ia) <  $signed(ib);
                  ecr[25] <= $signed(ia) >  $signed(ib);
                  ecr[26] <= $signed(ia) == $signed(ib);
                  ecr[27] <= 1'b0;
                end
              3'd7:
                begin
                  ecr[28] <= $signed(ia) <  $signed(ib);
                  ecr[29] <= $signed(ia) >  $signed(ib);
                  ecr[30] <= $signed(ia) == $signed(ib);
                  ecr[31] <= 1'b0;
                end
              endcase
            end
          CMPL:
            begin
              case(eir[25:23])
              3'd0:
                begin
                  ecr[0] <= ia <  ib;
                  ecr[1] <= ia >  ib;
                  ecr[2] <= ia == ib;
                  ecr[3] <= 1'b0;
                end
              3'd1:
                begin
                  ecr[4] <= ia <  ib;
                  ecr[5] <= ia >  ib;
                  ecr[6] <= ia == ib;
                  ecr[7] <= 1'b0;
                end
              3'd2:
                begin
                  ecr[8] <= ia <  ib;
                  ecr[9] <= ia >  ib;
                  ecr[10] <= ia == ib;
                  ecr[11] <= 1'b0;
                end
              3'd3:
                begin
                  ecr[12] <= ia <  ib;
                  ecr[13] <= ia >  ib;
                  ecr[14] <= ia == ib;
                  ecr[15] <= 1'b0;
                end
              3'd4:
                begin
                  ecr[16] <= ia <  ib;
                  ecr[17] <= ia >  ib;
                  ecr[18] <= ia == ib;
                  ecr[19] <= 1'b0;
                end
              3'd5:
                begin
                  ecr[20] <= ia <  ib;
                  ecr[21] <= ia >  ib;
                  ecr[22] <= ia == ib;
                  ecr[23] <= 1'b0;
                end
              3'd6:
                begin
                  ecr[24] <= ia <  ib;
                  ecr[25] <= ia >  ib;
                  ecr[26] <= ia == ib;
                  ecr[27] <= 1'b0;
                end
              3'd7:
                begin
                  ecr[28] <= ia <  ib;
                  ecr[29] <= ia >  ib;
                  ecr[30] <= ia == ib;
                  ecr[31] <= 1'b0;
                end
              endcase
            end
          AND:  eres <= ia & ib;
          ANDC: eres <= ia & ~ib;
          OR:   eres <= ia | ib;
          ORC:  eres <= ia | ~ib;
          XOR:  eres <= ia ^ ib;
          NAND: eres <= ~(ia & ib);
          NOR:  eres <= ~(ia | ib);
          EQV:  eres <= ~(ia ^ ib);
          EXTSB:eres <= {{24{ia[7]}},ia[7:0]};
          EXTSH:eres <= {{16{ia[15]}},ia[15:0]};
          SLW:  eres <= ia << ib;
          SRW:  eres <= ia >> ib;
          SRAW: eres <= ia[31] ? {32'hFFFFFFFF,ia} >> ib : ia >> ib;
          SRAWI:eres <= ia[31] ? {32'hFFFFFFFF,ia} >> eir[15:11] : ia >> eir[15:11];
          CNTLZW:	eres <= cntlzo;
          LBZX,LBZUX:  begin eea <= ia + ib; end
          LHZX,LHZUX:  begin eea <= ia + ib; end
          LHAX,LHAUX:  begin eea <= ia + ib; end
          LWZX,LWZUX:  begin eea <= ia + ib; end
          STBX,STBUX:  begin eea <= ia + ib; end
          STHX,STHUX:  begin eea <= ia + ib; end
          STWX,STWUX:  begin eea <= ia + ib; end
          MCRXR:
            case(eir[25:23])
            3'd0: begin ecr[3:0] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd1: begin ecr[7:4] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd2: begin ecr[11:8] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd3: begin ecr[15:12] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd4: begin ecr[19:16] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd5: begin ecr[23:20] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd6: begin ecr[27:24] <= exer[3:0]; exer[3:0] <= 4'd0; end
            3'd7: begin ecr[31:28] <= exer[3:0]; exer[3:0] <= 4'd0; end
            endcase
          MFCR: eres <= ecr;
          MTCRF: 
            begin
              if (eir[12]) ecr[3:0] <= ia[3:0];
              if (eir[13]) ecr[7:4] <= ia[7:4];
              if (eir[14]) ecr[11:8] <= ia[11:8];
              if (eir[15]) ecr[15:12] <= ia[15:12];
              if (eir[16]) ecr[19:16] <= ia[19:16];
              if (eir[17]) ecr[23:20] <= ia[23:20];
              if (eir[18]) ecr[27:24] <= ia[27:24];
              if (eir[19]) ecr[31:28] <= ia[31:28];
            end
          MFMSR:	eres <= msr;
          MFSPR:
            case(eir[20:11])
            10'd32:   eres <= exer;
            10'd26:		eres <= srr0;
            10'd27:		eres <= srr1;
            10'd256:  eres <= elr;
            10'd272,10'd273,10'd274,10'd275:
            					eres <= sprg[eir[12:11]];	
            10'd287:	eres <= 32'h04408000;	// processor / version
            10'd288:  eres <= ectr;
            default:  ;
            endcase
          MTSPR:
            case(eir[20:11])
            10'd32:   exer <= ia;
            10'd256:  elr <= ia;
            10'd288:  ectr <= ia;
            default:  ;
            endcase
					TW:
						case(eir[25:21])
						5'd1:	etrap <=  trpr[4];							// gtu
						5'd2: etrap <=  trpr[3];							// ltu
						5'd4: etrap <=  trpr[2];							// eq
						5'd5:	etrap <=  trpr[4]|trpr[2];	// geu
						5'd6: etrap <=  trpr[3]|trpr[2];	// leu
						5'd8:	etrap <=  trpr[1];							// gt
						5'd12:etrap <= ~trpr[0];							// nlt / ge
						5'd16:etrap <=  trpr[0];							// lt
						5'd20:etrap <= ~trpr[1];							// ngt
						5'd24:etrap <= ~trpr[2];							// ne
						5'd31:etrap <=  TRUE;
						endcase
          default:  ;
          endcase
        ADDI,ADDIC,ADDICD:
        	eres <= ia + imm;
        ADDIS: eres <= ia + imm;
        SUBFIC:	eres <= imm - ia;
        MULLI: eres <= prodi[31:0];
        CMPI:
          begin
            case(eir[25:23])
            3'd0:
              begin
                ecr[0] <= $signed(ia) <  $signed(imm);
                ecr[1] <= $signed(ia) >  $signed(imm);
                ecr[2] <= $signed(ia) == $signed(imm);
                ecr[3] <= 1'b0;
              end
            3'd1:
              begin
                ecr[4] <= $signed(ia) <  $signed(imm);
                ecr[5] <= $signed(ia) >  $signed(imm);
                ecr[6] <= $signed(ia) == $signed(imm);
                ecr[7] <= 1'b0;
              end
            3'd2:
              begin
                ecr[8] <= $signed(ia) <  $signed(imm);
                ecr[9] <= $signed(ia) >  $signed(imm);
                ecr[10] <= $signed(ia) == $signed(imm);
                ecr[11] <= 1'b0;
              end
            3'd3:
              begin
                ecr[12] <= $signed(ia) <  $signed(imm);
                ecr[13] <= $signed(ia) >  $signed(imm);
                ecr[14] <= $signed(ia) == $signed(imm);
                ecr[15] <= 1'b0;
              end
            3'd4:
              begin
                ecr[16] <= $signed(ia) <  $signed(imm);
                ecr[17] <= $signed(ia) >  $signed(imm);
                ecr[18] <= $signed(ia) == $signed(imm);
                ecr[19] <= 1'b0;
              end
            3'd5:
              begin
                ecr[20] <= $signed(ia) <  $signed(imm);
                ecr[21] <= $signed(ia) >  $signed(imm);
                ecr[22] <= $signed(ia) == $signed(imm);
                ecr[23] <= 1'b0;
              end
            3'd6:
              begin
                ecr[24] <= $signed(ia) <  $signed(imm);
                ecr[25] <= $signed(ia) >  $signed(imm);
                ecr[26] <= $signed(ia) == $signed(imm);
                ecr[27] <= 1'b0;
              end
            3'd7:
              begin
                ecr[28] <= $signed(ia) <  $signed(imm);
                ecr[29] <= $signed(ia) >  $signed(imm);
                ecr[30] <= $signed(ia) == $signed(imm);
                ecr[31] <= 1'b0;
              end
            endcase
          end
        CMPLI:
          begin
            case(eir[25:23])
            3'd0:
              begin
                ecr[0] <= ia <  imm;
                ecr[1] <= ia >  imm;
                ecr[2] <= ia == imm;
                ecr[3] <= 1'b0;
              end
            3'd1:
              begin
                ecr[4] <= ia <  imm;
                ecr[5] <= ia >  imm;
                ecr[6] <= ia == imm;
                ecr[7] <= 1'b0;
              end
            3'd2:
              begin
                ecr[8] <= ia <  imm;
                ecr[9] <= ia >  imm;
                ecr[10] <= ia == imm;
                ecr[11] <= 1'b0;
              end
            3'd3:
              begin
                ecr[12] <= ia <  imm;
                ecr[13] <= ia >  imm;
                ecr[14] <= ia == imm;
                ecr[15] <= 1'b0;
              end
            3'd4:
              begin
                ecr[16] <= ia <  imm;
                ecr[17] <= ia >  imm;
                ecr[18] <= ia == imm;
                ecr[19] <= 1'b0;
              end
            3'd5:
              begin
                ecr[20] <= ia <  imm;
                ecr[21] <= ia >  imm;
                ecr[22] <= ia == imm;
                ecr[23] <= 1'b0;
              end
            3'd6:
              begin
                ecr[24] <= ia <  imm;
                ecr[25] <= ia >  imm;
                ecr[26] <= ia == imm;
                ecr[27] <= 1'b0;
              end
            3'd7:
              begin
                ecr[28] <= ia <  imm;
                ecr[29] <= ia >  imm;
                ecr[30] <= ia == imm;
                ecr[31] <= 1'b0;
              end
            endcase
          end
        ANDI,ANDIS: eres <= ia & imm;
        ORI,ORIS:   eres <= ia | imm;
        XORI,XORIS: eres <= ia ^ imm;
        RLWIMI:     eres <= rlwimi_o;
        RLWINM:     eres <= rlwinm_o;
        RLWNM:      eres <= rlwnm_o;

				TWI:
					begin
						case(eir[25:21])
						5'd1:	etrap <=  trp[4];							// gtu
						5'd2: etrap <=  trp[3];							// ltu
						5'd4: etrap <=  trp[2];							// eq
						5'd5:	etrap <=  trp[4]|trp[2];	// geu
						5'd6: etrap <=  trp[3]|trp[2];	// leu
						5'd8:	etrap <=  trp[1];							// gt
						5'd12:etrap <= ~trp[0];							// nlt / ge
						5'd16:etrap <=  trp[0];							// lt
						5'd20:etrap <= ~trp[1];							// ngt
						5'd24:etrap <= ~trp[2];							// ne
						5'd31:etrap <=  TRUE;
						endcase
					end
        B:  eres <= epc + 3'd4;
        BC: 
        	begin
        		eres <= epc + 3'd4;
        		casez(eir[25:21])
        		5'b0?00?:
        			begin
        				ectr <= ectr - 1'd1;
        				if ((ectr - 1'd1 != 32'd0 && ecr[eir[20:16]]==eir[24])) begin
        					takb <= eval;
        					emod_pc <= eval;
        					if (eir[1])
        						enext_pc <= {{16{eir[15]}},eir[15:2],2'b00};
        					else
        						enext_pc <= epc + {{16{eir[15]}},eir[15:2],2'b00};
        				end
        			end
        		5'b0?01?:
        			begin
        				ectr <= ectr - 1'd1;
        				if ((ectr - 1'd1 == 32'd0 && ecr[eir[20:16]]==eir[24])) begin
        					takb <= eval;
        					emod_pc <= eval;
        					if (eir[1])
        						enext_pc <= {{16{eir[15]}},eir[15:2],2'b00};
        					else
        						enext_pc <= epc + {{16{eir[15]}},eir[15:2],2'b00};
        				end
        			end
        		5'b0?1??:
        			begin
        				if ((ecr[eir[20:16]]==eir[24])) begin
        					takb <= eval;
        					emod_pc <= eval;
        					if (eir[1])
        						enext_pc <= {{16{eir[15]}},eir[15:2],2'b00};
        					else
        						enext_pc <= epc + {{16{eir[15]}},eir[15:2],2'b00};
        				end
        			end
        		5'b1?00?:
        			begin
        				ectr <= ectr - 1'd1;
        				if ((ectr - 1'd1 != 32'd0)) begin
        					takb <= eval;
        					emod_pc <= eval;
        					if (eir[1])
        						enext_pc <= {{16{eir[15]}},eir[15:2],2'b00};
        					else
        						enext_pc <= epc + {{16{eir[15]}},eir[15:2],2'b00};
        				end
        			end
        		5'b1?01?:
        			begin
        				ectr <= ectr - 1'd1;
        				if ((ectr - 1'd1 == 32'd0)) begin
        					takb <= eval;
        					emod_pc <= eval;
        					if (eir[1])
        						enext_pc <= {{16{eir[15]}},eir[15:2],2'b00};
        					else
        						enext_pc <= epc + {{16{eir[15]}},eir[15:2],2'b00};
        				end
        			end
        		endcase
        	end
        CR2:
          case(eir[10:1])
          BCCTR:
          	begin
	          	eres <= epc + 3'd4;
	        		casez(eir[25:21])
	        		5'b0?00?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 != 32'd0 && ecr[eir[20:16]]==eir[24]) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= ectr;
	        				end
	        			end
	        		5'b0?01?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 == 32'd0 && ecr[eir[20:16]]==eir[24]) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= ectr;
	        				end
	        			end
	        		5'b0?1??:
	        			begin
	        				if (ecr[eir[20:16]]==eir[24]) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= ectr;
	        				end
	        			end
	        		5'b1?00?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 != 32'd0) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= ectr;
	        				end
	        			end
	        		5'b1?01?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 == 32'd0) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= ectr;
	        				end
	        			end
	        		5'b10100:
	        			begin
        					takb <= eval;
        					emod_pc <= eval;
        					enext_pc <= ectr;
	        			end
	        		endcase
          	end
          BCLR:
          	begin
	          	eres <= epc + 3'd4;
	        		casez(eir[25:21])
	        		5'b0?00?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 != 32'd0 && ecr[eir[20:16]]==eir[24]) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= elr;
	        				end
	        			end
	        		5'b0?01?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 == 32'd0 && ecr[eir[20:16]]==eir[24]) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= elr;
	        				end
	        			end
	        		5'b0?1??:
	        			begin
	        				if (ecr[eir[20:16]]==eir[24]) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= elr;
	        				end
	        			end
	        		5'b1?00?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 != 32'd0) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= elr;
	        				end
	        			end
	        		5'b1?01?:
	        			begin
	        				ectr <= ectr - 1'd1;
	        				if (ectr - 1'd1 == 32'd0) begin
	        					takb <= eval;
	        					emod_pc <= eval;
        						enext_pc <= elr;
	        				end
	        			end
	        		5'b10100:
	        			begin
        					takb <= eval;
        					emod_pc <= eval;
        					enext_pc <= elr;
	        			end
	        		endcase
          	end
          CRAND: ecr[eir[25:21]] <=  ecr[eir[20:16]] & ecr[eir[15:11]];
          CROR:  ecr[eir[25:21]] <=  ecr[eir[20:16]] | ecr[eir[15:11]];
          CRXOR: ecr[eir[25:21]] <=  ecr[eir[20:16]] ^ ecr[eir[15:11]];
          CRNAND:ecr[eir[25:21]] <= ~(ecr[eir[20:16]] & ecr[eir[15:11]]);
          CRNOR: ecr[eir[25:21]] <= ~(ecr[eir[20:16]] | ecr[eir[15:11]]);
          CREQV: ecr[eir[25:21]] <= ~(ecr[eir[20:16]] ^ ecr[eir[15:11]]);
          CRANDC:ecr[eir[25:21]] <=  ecr[eir[20:16]] & ~ecr[eir[15:11]];
          CRORC: ecr[eir[25:21]] <=  ecr[eir[20:16]] | ~ecr[eir[15:11]];
          default:  ;
          endcase
        LBZ,LBZU:  begin eea <= ia + imm; end
        LHZ,LHZU:  begin eea <= ia + imm; end
        LHA,LHAU:  begin eea <= ia + imm; end
        LWZ,LWZU:  begin eea <= ia + imm; end
        STB,STBU:  begin eea <= ia + imm; end
        STH,STHU:  begin eea <= ia + imm; end
        STW,STWU:  begin eea <= ia + imm; end
        default:  ;
        endcase
        if ((!ewrcrf && !e_multicycle) | e_cmp) begin
          execute_done <= TRUE;
          estate <= EWAIT;
        end
      end
    EFLAGS:
      begin
        case(eir[31:26])
        R2:
          case(eir[10:1])
          ADDO:
          	begin
          		exer[31] <= exer[31] | (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
          		exer[30] <= (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
          		exer[20] <= (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
          	end
         	ADDC:
         		begin
         			// (a&b)|(a&~s)|(b&~s)
         			exer[29] <= (ia[31]&ib[31])|(ia[31]&~eres[31])|(ib[31]&~eres[31]);
         			exer[19] <= (ia[31]&ib[31])|(ia[31]&~eres[31])|(ib[31]&~eres[31]);
         		end
         	ADDCO,ADDEO,ADDMEO,ADDZEO:
         		begin
          		exer[31] <= exer[31] | (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
          		exer[30] <= (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
          		exer[20] <= (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
         			exer[29] <= (ia[31]&ib[31])|(ia[31]&~eres[31])|(ib[31]&~eres[31]);
         			exer[19] <= (ia[31]&ib[31])|(ia[31]&~eres[31])|(ib[31]&~eres[31]);
         		end
          SUBFO:
          	begin
          		exer[31] <= exer[31] | (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
          		exer[30] <= (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
          		exer[20] <= (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
          	end
          SUBFC:
          	begin
	       			exer[29] <= (~ib[31]&ia[31])|(eres[31]&~ib[31])|(eres[31]&ia[31]);
  	     			exer[19] <= (~ib[31]&ia[31])|(eres[31]&~ib[31])|(eres[31]&ia[31]);
          	end
          SUBFCO,SUBFEO,SUBFMEO,SUBFZEO:
          	begin
          		exer[31] <= exer[31] | (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
          		exer[30] <= (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
          		exer[20] <= (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
	       			exer[29] <= (~ib[31]&ia[31])|(eres[31]&~ib[31])|(eres[31]&ia[31]);
  	     			exer[19] <= (~ib[31]&ia[31])|(eres[31]&~ib[31])|(eres[31]&ia[31]);
          	end
          MULLWO:
          	begin
              exer[31] <= exer[31] | (prodr[63:32] != {32{prodr[31]}}); // summary overflow
              exer[30] <= (prodr[63:32] != {32{prodr[31]}}); // overflow
              exer[20] <= (prodr[63:32] != {32{prodr[31]}}); // overflow
          	end
          default:	;
          endcase
        ADDIC,ADDICD:
       		begin
       			exer[29] <= (ia[31]&imm[31])|(ia[31]&~eres[31])|(imm[31]&~eres[31]);
       			exer[19] <= (ia[31]&imm[31])|(ia[31]&~eres[31])|(imm[31]&~eres[31]);
       		end
       	SUBFIC:
       		begin
       			// (~a&b)|(s&~a)|(s&b)
       			exer[29] <= (~imm[31]&ia[31])|(eres[31]&~imm[31])|(eres[31]&ia[31]);
       			exer[19] <= (~imm[31]&ia[31])|(eres[31]&~imm[31])|(eres[31]&ia[31]);
       		end
        default:	;
				endcase      	
        if (ewrcrf & ~e_cmp) begin
          ecr[0] <= eres[31];
          ecr[1] <= eres==32'd0;
          ecr[2] <= ~eres[31] && eres!=32'd0;
	        case(eir[31:26])
	        R2:
	          case(eir[10:1])
	          ADDO,ADDCO,ADDEO,ADDMEO,ADDZEO:	
	          	begin
	          		ecr[3] <= (eres[31] ^ ib[31]) & (1'b1 ^ ia[31] ^ ib[31]);
	          	end
	          SUBFO:
	          	begin
	          		ecr[3] <= (1'b1^ eres[31] ^ ia[31]) & (ia[31] ^ ib[31]);
	          	end
	          MULLWO:
	          	begin
	              ecr[3] <= prodr[63:32] != {32{prodr[31]}};
	            end
	          default:  ;
	          endcase
	        default:	;
	        endcase
        end
        execute_done <= TRUE;
        estate <= EWAIT;
      end        
    EDIV1:
    	begin
    		alu_ld <= TRUE;
    		div_sign <= ia[31] ^ ib[31];
    		if (ia[31]) ia <= -ia;
    		if (ib[31]) ib <= -ib;
    		estate <= EDIV2;
    	end
    // Wait a cycle for done to go inactive
    EDIV2:
    	begin
    		estate <= EDIV3;
   	 	end
   	EDIV3:
    	begin
    		if (div_done) begin
    			if (div_sign)
    				eres <= -(divo[63:32]);
    			else
    				eres <= divo[63:32];
    			if (ewrcrf)
    				estate <= EFLAGS;
    			else begin
    				execute_done <= TRUE;
    				estate <= EWAIT;
    			end
    		end
   	 	end
    EWAIT:
      if (advance_e) begin
        execute_done <= FALSE;
        estate <= EXECUTE;
        mpc <= epc;
        mRd <= eRd;
        mRa <= eRa;
        ea <= eea;
        mid <= id;
        mir <= eir;
        m_lsu <= e_lsu;
        m_st <= e_st;
        m_sync <= e_sync;
	      mval <= eval;
	      mia <= ia;
        mres <= eres;
        eres2 <= eres;
        mcr <= ecr;
        mwrrf <= ewrrf;
        mwrcrf <= ewrcrf;
        mwrxer <= ewrxer;
        mwrlr <= ewrlr;
        mwrctr <= ewrctr;
        mctr <= ectr;
        mlr <= elr;
        mxer <= exer;
        // Hardware interrupt takes priority.
        if (ecause & 8'h80)
        	mcause <= ecause;
        else if (etrap)
        	mcause <= FLT_PROGRAM;
        else
        	mcause <= ecause;
      end
      else if (advance_m) begin
      	mval <= FALSE;
      	mwrlr <= FALSE;
      	m_sync <= FALSE;
      	mir <= NOP_INSN;
      end
    default:
      begin
        execute_done <= TRUE;
        estate <= EWAIT;
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
begin
  if (rst_i) begin
    maccess <= FALSE;
    maccess_pending <= FALSE;
    memory_done <= TRUE;
    mstate <= MWAIT;
    mval <= FALSE;
    ea <= 32'd0;
    sel <= 32'h0;
    wwRd <= 6'd0;
    wpc <= RSTPC;
    wRd <= 6'd0;
    wRa <= 6'd0;
    w_lsu <= FALSE;
    w_sync <= FALSE;
    wia <= 32'd0;
    wres <= 32'd0;
    wcr <= 32'd0;
    wctr <= 32'd0;
    wlr <= 32'd0;
    wnext_pc <= RSTPC;
    wwrcrf <= FALSE;
    wwrctr <= FALSE;
    wwrlr <= FALSE;
    wwrxer <= FALSE;
    wwrrf <= FALSE;
    wwwrcrf <= FALSE;
    wwwrlr <= FALSE;
    wwwrxer <= FALSE;
    wwwrrf <= FALSE;
    wwxer <= 32'd0;
    wcause <= 8'h00;
    willegal_insn <= FALSE;
  end
  else begin
    case(mstate)
    MEMORY1:
      begin
        memory_done <= TRUE;
        mstate <= MWAIT;
        case(mir[31:26])
        R2:
          case(mir[10:1])
          LBZX,LBZUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          LHZX,LHZUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          LHAX,LHAUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          LWZX,LWZUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          STBX,STBUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          STHX,STHUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          STWX,STWUX:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
          default:  begin mstate <= MWAIT; memory_done <= TRUE; end
          endcase
        LBZ,LBZU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        LHZ,LHZU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        LHA,LHAU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        LWZ,LWZU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        STB,STBU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        STH,STHU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        STW,STWU:  begin maccess_pending <= TRUE; mstate <= MEMORY2; memory_done <= FALSE; end
        default:  begin mstate <= MWAIT; memory_done <= TRUE; end
        endcase
      end
    MEMORY2:
      if (!iaccess && !maccess) begin
        maccess_pending <= FALSE;
        maccess <= TRUE;
        cyc_o <= HIGH;
        stb_o <= HIGH;
        case(mir[31:26])
        R2:
          case(mir[10:1])
          LBZX,LBZUX:  begin we_o <= LOW; sel_o <= 4'h1 << ea[1:0]; adr_o <= ea; end
          LHZX,LHZUX:  begin we_o <= LOW; sel_o <= 4'h3 << ea[1:0]; sel <= 4'h3 << ea[1:0]; adr_o <= ea; end
          LHAX,LHAUX:  begin we_o <= LOW; sel_o <= 4'h3 << ea[1:0]; sel <= 4'h3 << ea[1:0]; adr_o <= ea; end
          LWZX,LWZUX:  begin we_o <= LOW; sel_o <= 4'hF << ea[1:0]; sel <= 4'hF << ea[1:0]; adr_o <= ea; end
          STBX,STBUX:  begin we_o <= HIGH; sel_o <= 4'h1 << ea[1:0]; adr_o <= ea; dat_o <= mid << {ea[1:0],3'b0}; end
          STHX,STHUX:  begin we_o <= HIGH; sel_o <= 4'h3 << ea[1:0]; sel <= 4'h3 << ea[1:0]; adr_o <= ea; dat_o <= mid << {ea[1:0],3'b0}; dat <= mid << {ea[1:0],3'b0}; end
          STWX,STWUX:  begin we_o <= HIGH; sel_o <= 4'hF << ea[1:0]; sel <= 4'hF << ea[1:0]; adr_o <= ea; dat_o <= mid << {ea[1:0],3'b0}; dat <= mid << {ea[1:0],3'b0}; end
          default:  ;
          endcase
        LBZ,LBZU:  begin we_o <= LOW; sel_o <= 4'h1 << ea[1:0]; adr_o <= ea; end
        LHZ,LHZU:  begin we_o <= LOW; sel_o <= 4'h3 << ea[1:0]; sel <= 4'h3 << ea[3:0]; adr_o <= ea; end
        LHA,LHAU:  begin we_o <= LOW; sel_o <= 4'h3 << ea[1:0]; sel <= 4'h3 << ea[3:0]; adr_o <= ea; end
        LWZ,LWZU:  begin we_o <= LOW; sel_o <= 4'hF << ea[1:0]; sel <= 4'hF << ea[3:0]; adr_o <= ea; end
        STB,STBU:  begin we_o <= HIGH; sel_o <= 4'h1 << ea[1:0]; adr_o <= ea; dat_o <= mid << {ea[1:0],3'b0}; end
        STH,STHU:  begin we_o <= HIGH; sel_o <= 4'h3 << ea[1:0]; sel <= 4'h3 << ea[3:0]; adr_o <= ea; dat_o <= mid << {ea[1:0],3'b0}; dat <= mid << {ea[1:0],3'b0}; end
        STW,STWU:  begin we_o <= HIGH; sel_o <= 4'hF << ea[1:0]; sel <= 4'hF << ea[3:0]; adr_o <= ea; dat_o <= mid << {ea[1:0],3'b0}; dat <= mid << {ea[1:0],3'b0}; end
        default:  ;
        endcase
        mstate <= MEMORY3;
      end
    MEMORY3:
      if (ack_i) begin
        stb_o <= LOW;
        dati <= dat_i;
        case(mir[31:26])
        R2:
          case(mir[10:1])
          LBZX,LBZUX,STBX,STBUX:
          	begin
          		cyc_o <= LOW;
          		we_o <= LOW;
          		sel_o <= 8'h00;
        			maccess <= FALSE;
          		mstate <= MALIGN;
          	end
          LHZX,LHZUX,LHAX,LHAUX,STHX,STHUX:
            begin
              if (ea[1:0]!=2'b11) begin
                cyc_o <= LOW;
                we_o <= LOW;
                sel_o <= 4'h0;
				        maccess <= FALSE;
                mstate <= MALIGN;
              end
              else
                mstate <= MEMORY4;
            end
          LWZX,LWZUX,STWX,STWUX:  
            begin
              if (ea[1:0]==2'd0) begin
                cyc_o <= LOW;
                we_o <= LOW;
                sel_o <= 4'h0;
				        maccess <= FALSE;
                mstate <= MALIGN;
              end
              else
                mstate <= MEMORY4;
            end
          default:  ;
          endcase
        LBZ,LBZU:
        	begin
        		cyc_o <= LOW;
        		sel_o <= 8'h00;
		        maccess <= FALSE;
        		mstate <= MALIGN;
        	end
        LHZ,LHZU,LHA,LHAU:
          begin
            if (ea[1:0]!=2'd3) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 4'h0;
			        maccess <= FALSE;
              mstate <= MALIGN;
            end
            else
              mstate <= MEMORY4;
          end
        STH,STHU:
          begin
            if (ea[1:0]!=2'd3) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 4'h0;
			        memory_done <= TRUE;
			        mstate <= MWAIT;
			        maccess <= FALSE;
            end
            else
              mstate <= MEMORY4;
          end
        LWZ,LWZU:  
          begin
            if (ea[1:0] == 2'd0) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 4'h0;
			        maccess <= FALSE;
              mstate <= MALIGN;
            end
            else
              mstate <= MEMORY4;
          end
        STW,STWU:  
          begin
            if (ea[1:0] == 2'd0) begin
              cyc_o <= LOW;
              we_o <= LOW;
              sel_o <= 4'h0;
			        memory_done <= TRUE;
			        mstate <= MWAIT;
			        maccess <= FALSE;
            end
            else
              mstate <= MEMORY4;
          end
        STB,STBU:
        	begin
        		cyc_o <= LOW;
        		we_o <= LOW;
        		sel_o <= 4'h0;
		        memory_done <= TRUE;
		        mstate <= MWAIT;
		        maccess <= FALSE;
        	end
        default:  ;
        endcase
      end
    MEMORY4:
      begin
        stb_o <= HIGH;
        sel_o <= sel[7:4];
        adr_o <= {ea[AWID-1:2]+1'd1,2'b0};
        dat_o <= dat[63:32];
        mstate <= MEMORY5;
      end
    MEMORY5:
      if (ack_i) begin
        cyc_o <= LOW;
        stb_o <= LOW;
        we_o <= LOW;
        sel_o <= 4'h0;
        dati[63:32] <= dat_i;
        maccess <= FALSE;
        mstate <= MALIGN;
      end
    MALIGN:
      begin
        memory_done <= TRUE;
        mstate <= MWAIT;
        case(mir[31:26])
        R2:
          case(mir[10:1])
          LBZX,LBZUX: mres <= (dati >> {ea[1:0],3'b0}) & 32'h0FF;
          LHZX,LHZUX: mres <= (dati >> {ea[1:0],3'b0}) & 32'h0FFFF;
          LHAX,LHAUX: begin mres <= (dati >> {ea[1:0],3'b0}) & 32'h0FFFF; memory_done <= FALSE; mstate <= MSX; end
          LWZX,LWZUX: mres <= (dati >> {ea[1:0],3'b0}) & 32'hFFFFFFFF;
          default:  ;
          endcase
        LBZ,LBZU: mres <= (dati >> {ea[1:0],3'b0}) & 32'h0FF;
        LHZ,LHZU: mres <= (dati >> {ea[1:0],3'b0}) & 32'h0FFFF;
        LHA,LHAU: begin mres <= (dati >> {ea[1:0],3'b0}) & 32'h0FFFF; memory_done <= FALSE; mstate <= MSX; end
        LWZ,LWZU: mres <= (dati >> {ea[1:0],3'b0}) & 32'hFFFFFFFF;
        default:  ;
        endcase
        /*
        if (m_st & m_lsu) begin
        	mwrrf <= TRUE;
        	mRd <= mRa;
        	mres <= ea;
        end
        */
      end
    // Currently only LHAxx instructions need sign extend
    MSX:
    	begin
    		mres <= {{16{mres[15]}},mres[15:0]};
    		memory_done <= TRUE;
    		mstate <= MWAIT;
    	end
    MWAIT:
      if (advance_m) begin
      	wpc <= mpc;
      	wRd <= mRd;
      	wRa <= mRa;
        wval <= mval;
        wwval <= 1'b0;
        wia <= mia;
       	wres <= mres;
       	mres2 <= mres;
        wea <= ea;
        w_lsu <= m_lsu;
        w_sync <= m_sync;
        wwrrf <= mwrrf;
        wwrcrf <= wwrcrf;
        wcr <= mcr;
        wwrlr <= mwrlr;
        wwrctr <= mwrctr;
        wwrxer <= mwrxer;
        wctr <= mctr;
        wlr <= mlr;
        wxer <= mxer;
        memory_done <= FALSE;
        mstate <= MEMORY1;
        wcause <= mcause;
      end
      else if (advance_w) begin
      	wir <= NOP_INSN;
      	wval <= FALSE;
      	w_sync <= FALSE;
    	end
    default:
      begin
        memory_done <= TRUE;
        mstate <= MWAIT;
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
    wval <= 1'b0;
    writeback_done <= TRUE;
    wgoto (WWAIT);
  end
  else begin
	  if (wwwrlr)
	    lr <= wwres;
	  if (wwwrctr)
	    ctr <= wwres;
		wwval <= 1'b0;
		wwwrrf <= 1'b0;
  	wmod_pc <= FALSE;
  	if (wcause) begin
			srr0 <= wpc;
			srr1 <= msr;
  		wmod_pc <= TRUE;
  		if (wcause[7])
  			wnext_pc <= {FLT_EXTERNAL,8'h00};
  		else
  			wnext_pc <= {wcause,8'h00};
  	end
    case(wstate)
    WRITEBACK0:
      begin
      	if (wval)
      		case(wir[31:26])
      		SC:
      			begin
      				srr0 <= wpc + 3'd4;
      				srr1 <= msr;
      				wmod_pc <= TRUE;
      				wnext_pc <= {FLT_SYSTEM_CALL,8'h00};
      			end
      		R2:
      			case(wir[10:1])
      			MTMSR:	msr <= wia;
	          MTSPR:
	            case(wir[20:11])
	            10'd26:		srr0 <= wia;
	            10'd27:	  srr1 <= wia;
	            10'd272,10'd273,10'd274,10'd275:
	            					sprg[wir[12:11]] <= wia;
	            10'd256:  lr <= wia;
	            10'd288:  ctr <= wia;
	            default:  ;
	            endcase
	    			default:	;
						endcase      		
      		CR2:
      			case(wir[10:1])
      			RFI:	msr <= srr0;
		    		default:	;
      			endcase
	    		default:	;
      		endcase
      	if (wval)
      		inst_ctr <= inst_ctr + 1'd1;
      	inst_ctr2 <= inst_ctr2 + 2'd2;
        wwRd <= wRd;
        wwres <= wres;
        wwval <= wval & wwrrf;
        wwwrrf <= wwrrf & wval;
        wwwrcrf <= wwrcrf & wval;
        wwwrlr <= wwrlr & wval;
        wwwrctr <= wwrctr & wval;
        wwwrxer <= wwrxer & wval;
        wwcr <= wcr;
        wwxer <= wxer;
        if (w_lsu & wval)
        	wgoto(WRITEBACK1);
        else begin
	        writeback_done <= TRUE;
  	      wgoto(WWAIT);
	      end
      end
    WRITEBACK1:
      begin
        wwRd <= wRa;
        wwres <= wea;
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
		  	$display("pc0: %h pc1:%h", pc, pc[1]);
		  	$display("Regfile");
		  	for (n = 0; n < 32; n = n + 4)
		  		$display("r%d: %h  r%d:%h  r%d:%h  r%d:%h",
		  			n[4:0]+0, regfile[n],
		  			n[4:0]+1, regfile[n+1],
		  			n[4:0]+2, regfile[n+2],
		  			n[4:0]+3, regfile[n+3]);
		  	$display("lr: %h ctr: %h", lr, ctr);
		  	$display("iir: %h ir:%h  rir:%h  eir:%h  mir:%h  wir:%h", iir, ir, rir, eir, mir, wir);
		  	$display("dimm:%h  rimm:%h", dimm, rimm);
		  	$display("rRa:%d rRb:%d rRc:%d,rRd:%d", rRa, rRb, rRc, rRd);
		  	$display("rid:%h  ria:%h  rib:%h  ric:%h  rimm:%h", rid, ria, rib, ric, rimm);
		  	$display("id:%h  ia:%h  ib:%h  ic:%h  imm:%h", id, ia, ib, ic, imm);
		  	$display("dval:%b rval:%b eval:%b mval:%b wval:%b", dval, rval, eval, mval, wval);
		  	$display("eRd:%d eres:%h%c%c eea:%h", eRd, eres, eval ? "v" : " ", ewrrf ? "w" : " ", eea);
		  	$display("mRd:%d mres:%h%c%c", mRd, mres, mval ? "v" : " ", mwrrf ? "w" : " ");
		  	$display("wRd:%d wres:%h%c%c", wRd, wres, wval ? "v" : " ", wwrrf ? "w" : " ");
`endif		  	
	      if (advance_w) begin
	        writeback_done <= FALSE;
	        tval <= wval;
	        twrrf <= wwrrf;
	        tRd <= wRd;
	        tres <= wres;
	        wres2 <= wres;
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
input [3:0] nst;
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

task goto;
input [5:0] nst;
begin
	state <= nst;
end
endtask

task tValid;
begin
	if (rst_i) begin
		if (RIBO) begin
			iir <= {NOP_INSN[7:0],NOP_INSN[15:8],NOP_INSN[23:16],NOP_INSN[31:24]};
		end
		else begin
			iir <= NOP_INSN;
  	end
		ir <= NOP_INSN;
    dval <= 1'b0;
    rir <= NOP_INSN;
    rval <= 1'b0;
    eir <= NOP_INSN;
    eval <= 1'b0;
    mir <= NOP_INSN;
    mval <= 1'b0;
    wir <= NOP_INSN;
    wval <= 1'b0;
	end
	else
	begin
	  if (wmod_pc & wval & advance_w) begin
	    ir <= NOP_INSN;
	    dval <= 1'b00;
	    rir <= NOP_INSN;
	    rval <= 1'b0;
	    eir <= NOP_INSN;
	    eval <= 1'b0;
	    mir <= NOP_INSN;
	    mval <= 1'b0;
	    wir <= NOP_INSN;
	    wval <= 1'b0;
	  end
	  else if (emod_pc & eval & advance_e) begin
	    ir <= NOP_INSN;
	    dval <= 1'b0;
	    rir <= NOP_INSN;
	    rval <= 1'b0;
	    eir <= NOP_INSN;
	    eval <= 1'b0;
	  end
	  else if (dmod_pc & dval & advance_d) begin
	    ir <= NOP_INSN;
	    dval <= 1'b0;
	  end
	end
end
endtask

task wb_nack;
begin
	vpa_o <= LOW;
	cyc_o <= LOW;
	stb_o <= LOW;
	sel_o <= 4'h0;
	we_o <= LOW;
	adr_o <= 32'h0;
	dat_o <= 32'h0;
end
endtask

endmodule
