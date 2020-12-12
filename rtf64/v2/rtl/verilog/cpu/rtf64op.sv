// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64op.sv
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

import rtf64pkg::*;
import rtf64configpkg::*;

`ifdef CPU_B128
`define SELH    31:16
`define DATH    255:128
`endif
`ifdef CPU_B64
`define SELH    15:8
`define DATH    127:64
`endif
`ifdef CPU_B32
`define SELH    7:4
`define DATH    63:32
`endif

import fp::*;
import posit::*;

module rtf64op(hartid_i, rst_i, clk_i, wc_clk_i, div_clk_i, nmi_i, irq_i, cause_i,
	vpa_o, cyc_o, stb_o, ack_i, err_i, sel_o, we_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i);
parameter WID = 64;
parameter AWID = 32;
parameter RSTPC = 64'hFFFFFFFFFFFC0200;
parameter pL1CacheLines = 64;
localparam pL1msb = $clog2(pL1CacheLines-1)-1+5;
input [7:0] hartid_i;
input rst_i;
input clk_i;
input wc_clk_i;
input div_clk_i;
input nmi_i;
input irq_i;
input [7:0] cause_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [AWID-1:0] adr_o;
`ifdef CPU_B128
input [127:0] dat_i;
output reg [127:0] dat_o;
`endif
`ifdef CPU_B64
input [63:0] dat_i;
output reg [63:0] dat_o;
`endif
`ifdef CPU_B32
input [31:0] dat_i;
output reg [31:0] dat_o;
`endif
output reg sr_o;
output reg cr_o;
input rb_i;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter LOW = 1'b0;
parameter HIGH = 1'b1;

integer n;
genvar g;
reg [2:0] dcyc;
reg [3:0] istate;
reg [1:0] dstate;
reg [2:0] rstate;
reg [3:0] estate;
reg [5:0] mstate;
reg [1:0] wstate;
reg atni_done, exec_done;

reg dmod_pc, rmod_pc, emod_pc, mmod_pc, wmod_pc;
reg [AWID-1:0] pc, ipc, ipc2, ret_pc, dnext_pc, rnext_pc, enext_pc, mnext_pc, wnext_pc;
reg [AWID-1:0] dpc, rpc, expc, mpc, wpc, tpc, upc, vpc;
reg [3:0] dilen, rilen, eilen, milen, wilen, tilen, uilen, vilen;
reg illegal_insn;
reg [63:0] iir, ir, rir, eir, mir, wir, tir, uir, vir;
reg [255:0] iri1, iri2, ici;
reg ibrpred, dbrpred, rbrpred, ebrpred, mbrpred, wbrpred, tbrpred, ubrpred, vbrpred;
reg e_bubble, m_bubble, w_bubble, t_bubble, u_bubble, v_bubble;
reg exception = FALSE;
reg [2:0] loop_mode;
wire is_loop_mode = |loop_mode;
wire [7:0] opcode = ir[7:0];
wire [7:0] ropcode = rir[7:0];
wire [7:0] eopcode = eir[7:0];
wire [7:0] mopcode = mir[7:0];
wire [7:0] wopcode = wir[7:0];
wire [4:0] funct5 = ir[30:26];
wire [4:0] efunct5 = eir[30:26];
wire [4:0] wfunct5 = wir[30:26];
wire [2:0] mop = eir[12:10];
wire [2:0] rm3 = eir[31:29];
reg [6:0] Rd;
reg [6:0] rRd;
reg [6:0] eRd;
reg [6:0] mRd;
reg [6:0] wRd;
reg [6:0] tRd;
reg [1:0] Cd, Cs, rCd, eCd, mCd, wCd, tCd, rCs;
reg [6:0] Rs1, Rs2, Rs3;
reg [6:0] rRs1, eRs1, rRs2, eRs2, mRs1, wRs1, rRs3;
reg [4:0] Rs12; // for push
// For LDM/STM
reg [4:0] Rs1t, Rdt;
reg [1:0] S;
reg [11:0] offset;
reg [30:0] mask;
reg [2:0] i_omode, d_omode, r_omode, e_omode, m_omode, w_omode;

reg [4:0] fltreg = 5'd1;
reg [4:0] pstreg = 5'd2;
reg rad,r_rad,e_rad,m_rad,w_rad;
reg [WID-1:0] rf_Rs1, rf_Rs2, rf_Rs3, rf_Rd;
reg [WID-1:0] irfoRs1, irfoRs2, irfoRs3, irfoRd;
reg [WID-1:0] sp_Rs1, sp_Rs2, sp_Rs3, sp_Rd;
wire [WID-1:0] frfoa, frfob, frfoc;
wire [WID-1:0] prfoa, prfob, prfoc;
reg [WID-1:0] ia,ib,ic,id,imm,dimm,dimm2;
reg [18:0] limm;
reg [WID-1:0] ria,rib,ric,rid,rimm;
reg [WID-1:0] mia, wia, mid, mib, wib;
reg [WID:0] res;
reg [WID-1:0] mres, wres, tres;
reg [7:0] crres, mcrres, wcrres, tcrres;
reg pc_reload;
reg dval,rval,eval,mval,wval,tval,uval,vval;
reg wrra, wrca;
reg ewrra, ewrca;
reg mwrra, mwrca;
reg wwrra, wwrca;
reg wrirf,wrcrf,wrcrf32,wrfrf,wrprf;
reg ewrirf,ewrcrf,ewrcrf32;
reg mwrirf,mwrcrf,mwrcrf32;
reg wwrirf,wwrcrf,wwrcrf32;
reg twrirf,twrcrf,twrcrf32;
reg rwrirf;
reg rwrcrf;
reg rwrcrf32;
reg rwrra;
reg rwrca;
reg dwrsrf,rwrsrf,ewrsrf,mwrsrf,wwrsrf;
reg wwrfrf=0, wwrprf=0;
reg [3:0] ebubble_cnt;
wire memmode, UserMode, SupervisorMode, HypervisorMode, MachineMode, InterruptMode, DebugMode;
wire st_writeback = wstate==WRITEBACK || wstate==WRITEBACK2;
wire st_ifetch2 = istate==IFETCH2;
wire st_decode = dstate==DECODE;
wire st_execute = estate==EXECUTE;
reg ifetch_done, decode_done, regfetch_done, execute_done, memory_done, writeback_done;
wire stall_r;
wire stall_i;

wire advance_v = ifetch_done & decode_done & regfetch_done & execute_done & memory_done & writeback_done;
wire advance_u = advance_v;
wire advance_t = advance_u;
wire advance_w = advance_t;
wire advance_m = advance_w;
wire advance_e = advance_m;
wire advance_r = ifetch_done & decode_done & regfetch_done & ~stall_r & advance_e;
wire advance_d = advance_r;
wire advance_i = ~stall_i & advance_d;

reg [39:0] iStateNameReg;
function [39:0] iStateName;
input [5:0] istate;
begin
  case(istate)
  IFETCH1:  iStateName = "IF1  ";
  IFETCH2:  iStateName = "IF2  ";
  IFETCH3:  iStateName = "IF3  ";
  IFETCH4:  iStateName = "IF4  ";
  IFETCH_INCR:  iStateName = "INCR ";
  IFETCH_WAIT:  iStateName = "WAIT ";
  IFETCH2a:  iStateName = "IF2a ";
  IFETCH3a:  iStateName = "IF3a ";
  default:  iStateName = "???? ";
  endcase
end
endfunction

wire wr_rf = st_writeback & wwrirf & wval;

reg [WID-1:0] regfile [0:95];
always @(posedge clk_g)
  if (wr_rf)
    regfile[wRd[6:0]] <= wres[WID-1:0];
always @(posedge clk_g)
  rf_Rd <= regfile[rRd[6:0]];
always @(posedge clk_g)
  rf_Rs1 <= regfile[rRs1];
always @(posedge clk_g)
  rf_Rs2 <= regfile[rRs2];
always @(posedge clk_g)
  rf_Rs3 <= regfile[rRs3];

reg [WID-1:0] sp;
reg [WID-1:0] sp_regfile [0:7];
always @(posedge clk_g)
  sp <= sp_regfile[r_omode];
reg [AWID-1:0] ra [0:1]; // ra0 = 0-31, ra1 = 32 to 63
reg [AWID-1:0] ca [0:1];

reg [31:0] cregfile;
reg [AWID-1:0] sregfile [0:15];
initial begin
  for (n = 0; n < 16; n = n + 1)
    sregfile[n] = {AWID{1'b0}};
end
always @(posedge clk_g)
  if (wval & wwrsrf & wib[7] & st_writeback)
    sregfile[wib[3:0]] <= wia;

wire [WID:0] difi = ia - imm;
wire [WID:0] difr = ia - ib;
wire [WID-1:0] andi = ia & imm;
wire [WID-1:0] andr = ia & ib;
wire [WID-1:0] biti = andi;
wire [WID-1:0] bitr = andr;

wire [15:0] blendR1 = ia[23:16] * ic[7:0];
wire [15:0] blendG1 = ia[15: 8] * ic[7:0];
wire [15:0] blendB1 = ia[ 7: 0] * ic[7:0];
wire [15:0] blendR2 = ib[23:16] * ~ic[7:0];
wire [15:0] blendG2 = ib[15: 8] * ~ic[7:0];
wire [15:0] blendB2 = ib[ 7: 0] * ~ic[7:0];
reg [AWID-1:0] rares,rrares,erares,mrares,wrares;

wire [31:0] cd32 = cregfile;
wire [31:0] cd32w = cregfile;
wire [31:0] cds32 = cregfile;
wire [31:0] cds322 = cregfile;
always @(posedge clk_g)
  if (wval & wwrcrf && wstate==WRITEBACK2)
    case(Cd)
    2'd0: cregfile <= {cd32w[31:8],wcrres[7:0]};
    2'd1: cregfile <= {cd32w[31:16],wcrres[7:0],cd32w[7:0]};
    2'd2: cregfile <= {cd32w[31:24],wcrres[7:0],cd32w[15:0]};
    2'd3: cregfile <= {wcrres[7:0],cd32w[23:0]};
    endcase
  else if (wval & wrcrf32 & st_writeback)
    cregfile <= wres[31:0];
initial begin
  for (n = 0; n < 32; n = n + 1)
    cregfile[n] <= 32'h0;
end
wire [7:0] cd = cd32 >> {rCs,3'b0};
wire [7:0] cd2 = cds322 >> {rCs,3'b0};
wire [7:0] cds = cds32 >> {rRs1[1:0],3'b0};
reg [7:0] cdb;

always @(posedge clk_g)
  if (rRd==7'd31)
    irfoRd <= sp;
  else if (rRd[6:5]==2'b11)
    irfoRd <= 64'd0;
  else
    irfoRd <= rf_Rd;
always @(posedge clk_g)
  if (rRs1==7'd31)
    irfoRs1 <= sp;
  else if (rRs1[6:5]==2'b11)
    casez(rRs1[4:0])
    5'b0000?: irfoRs1 <= ra[rRs1[0]];
    5'b0001?: irfoRs1 <= ca[0];
    5'b00111: irfoRs1 <= epc;
    5'b100??: irfoRs1 <= cds;
    5'b11101: irfoRs1 <= cds32;
    default:  irfoRs1 <= 64'd0;
    endcase
  else
    irfoRs1 <= rf_Rs1;
always @(posedge clk_g)
  irfoRs2 <= rRs2==7'd31 ? sp : rf_Rs2;
always @(posedge clk_g)
  irfoRs3 <= rRs3==7'd31 ? sp : rf_Rs3;


// CSRs
reg [31:0] i_cause,d_cause,r_cause,e_cause,m_cause,w_cause;  // pipeline registers
reg [31:0] cause [0:7];
reg [AWID-1:0] tvec [0:7];
reg [AWID-1:0] m_badaddr, w_badaddr;
reg [AWID-1:0] badaddr [0:7];
reg [31:0] status [0:7];
wire mprv = status[5][17];
reg uie;
reg sie;
reg hie;
reg mie;
reg iie;
reg die;
reg [31:0] gcie;
reg [WID-1:0] scratch [0:7];
reg [39:0] instret;
reg [39:0] instfetch;
reg [AWID-1:0] epc;
reg [AWID-1:0] next_epc;
reg [31:0] pmStack;
reg [4:0] ASID;
reg [23:0] TaskId;
reg [5:0] gcloc;    // garbage collect lockout count
reg [2:0] mrloc;    // mret lockout
reg [31:0] uip;     // user interrupt pending
reg [4:0] regset;
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi = 1'b0;
reg [31:0] mtimecmp;
reg [31:0] mcpuid = 32'b000000_00_00000000_00010001_00100001;
reg [31:0] mimpid = 32'h01108000;
reg [WID-1:0] mscratch;
reg [AWID-1:0] mbadaddr;
reg [31:0] usema, msema;
reg [WID-1:0] sema;
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
reg [19:0] key [0:8];
// Debug
reg [AWID-1:0] dbad [0:3];
reg [63:0] dbcr;
reg [3:0] dbsr;

reg d_atni, d_exec;
reg d_lea, d_cache, d_jsr, d_rts, d_push_reg, d_push, d_pushc, d_pop, d_link, d_unlink;
reg d_cmp,d_set,d_tst,d_chk,d_mov,d_stot,d_stptr,d_setkey,d_gcclr;
reg d_shiftr, d_st, d_ld, d_ldm, d_stm, d_cbranch, d_bra, d_wha;
reg d_pushq, d_popq, d_peekq, d_statq;
reg setto, getto, decto, getzl, popto;
reg pushq, popq, peekq, statq; 
reg d_exti, d_extr, d_extur, d_extui, d_depi, d_depr, d_depii, d_flipi, d_flipr;
reg d_ffoi, d_ffor;
reg d_loop_bust;

reg r_atni, r_exec;
reg r_fltcmp, r_tst, r_chk, r_set, r_cmp;
reg r_ld, r_st, r_stptr, r_jsr, r_rts, r_pushc;
reg r_cbranch;
reg r_exti, r_extr, r_extur, r_extui, r_depi, r_depr, r_depii, r_flipi, r_flipr;
reg r_ffoi, r_ffor;
reg r_loop_bust;
reg r_gcclr;
reg r_setkey;

reg e_atni, e_exec;
reg e_chk, e_cmp, e_set, e_tst, e_fltcmp;
reg e_ld, e_st, e_stptr, e_jsr, e_rts;
reg e_cbranch;
reg e_exti, e_extr, e_extur, e_extui, e_depi, e_depr, e_depii, e_flipi, e_flipr;
reg e_ffoi, e_ffor;
reg e_loop_bust;
reg e_gcclr;
reg e_setkey;

reg m_cmp, m_set, m_tst, m_fltcmp;
reg m_ld, m_st, m_stptr;
reg m_cbranch;
reg w_cmp, w_set, w_tst, w_fltcmp;
reg m_loop_bust;
reg m_gcclr;
reg m_setkey;

reg w_stptr;
reg w_cbranch;
reg w_loop_bust;
reg w_gcclr;
reg w_setkey;

reg t_cbranch;
reg t_loop_bust;

reg u_cbranch;
reg u_loop_bust;

wire cbranch_in_pipe = 
  r_cbranch |
  e_cbranch |
  m_cbranch |
  w_cbranch |
  t_cbranch |
  u_cbranch ;

wire loop_bust =
  r_loop_bust |
  e_loop_bust |
  m_loop_bust |
  w_loop_bust |
  t_loop_bust |
  u_loop_bust ; 


// Stall instruction feed if multi-cycle decode.
assign stall_i = |dcyc;
// Stall pipe if a memory load op is taking place and the result needs to be forwarded.
assign stall_r = (e_ld || e_rts || e_atni || e_exec) && eval && rval &&
            ((rRs1==eRd) || (rRs2==eRd) || (rRs3==eRd) || (rRd==eRd) || ewrcrf || e_atni || e_exec);
  

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Return address stack predictor
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [5:0] rasp;
reg [AWID-1:0] ra_stack [0:63];
reg [AWID-1:0] ra_stack_top;

always @(posedge clk_g)
if (rst_i)
	rasp <= 6'd0;
else begin
	if (dval & d_jsr & advance_d)
		rasp <= rasp + 1'd1;
	else if (dval & d_rts & advance_d)
		rasp <= rasp - 1'd1;
end

always @(posedge clk_g)
	if (dval & d_jsr & advance_d)
		ra_stack[rasp] <= dpc + dilen;

always @(posedge clk_g)
	ra_stack_top <= ra_stack[rasp-1'd1];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_g)
  if (st_writeback)
    if (wval & wwrra)
      ra[w_rad] <= wrares;
wire [AWID-1:0] rao = ra[d_stot ? Rs2[0] : d_mov ? Rs1[0] : ir[8]];

always @(posedge clk_g)
  if (st_writeback)
    if (wval & wwrca)
      ca[0] <= wrares;
wire [AWID-1:0] cao = ca[0];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// MMU
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg maccess;
reg keyViolation;
reg [AWID-1:0] ladr;
reg wrpagemap;
wire [13:0] pagemapoa, pagemapo;
reg [16:0] pagemapa;
wire [16:0] pagemap_ndx = {ASID,ladr[25:14]};

reg memaccess;
wire [19:0] keyo, keyoa;
KeyMemory ukm1 (
  .clka(clk_g),    // input wire clka
  .ena(w_setkey),      // input wire ena
  .wea(wval & st_writeback & ~wia[31]),      // input wire [0 : 0] wea
  .addra(wia[45:32]),  // input wire [13 : 0] addra
  .dina(wia[19:0]),    // input wire [19 : 0] dina
  .douta(keyoa),  // output wire [19 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(adr_o[27:14]),  // input wire [13 : 0] addrb
  .dinb(20'h0),    // input wire [19 : 0] dinb
  .doutb(keyo)  // output wire [19 : 0] doutb
);

wire MUserMode;
wire keymem_cs = MUserMode && adr_o[31:28]==4'h0;

reg [63:0] pta;
reg icaccess;
reg [AWID-1:0] iadr;
reg xlaten;
reg tlben, tlbwr;
wire tlbmiss;
wire [3:0] tlbacr;
wire [63:0] tlbdato;

`ifdef RTF64_TLB
rtf64_TLB utlb (
  .rst_i(rst_i),
  .clk_i(clk_g),
  .asid_i(ASID),
  .umode_i(vpa_o ? UserMode : MUserMode),
  .xlaten_i(xlaten),
  .we_i(we_o),
  .ladr_i(ladr),
  .iacc_i(icaccess||(istate==IFETCH3a && (!maccess && !ack_i))),
  .iadr_i(iadr),
  .padr_o(adr_o), // ToDo: fix this for icache access
  .acr_o(tlbacr),
  .tlben_i(tlben),
  .wrtlb_i(wval & tlbwr),
  .tlbadr_i(wia[11:0]),
  .tlbdat_i(wib),
  .tlbdat_o(tlbdato),
  .tlbmiss_o(tlbmiss)
);
`endif

reg [AWID-1:0] wadr;
wire [31:0] card21o, card22o, card1o;
wire [63:0] cardmem0o;
reg [63:0] cardmem0;
always @(posedge clk_g)
  if (d_gcclr & ~ia[31] && ia[30:28]==3'd0)
    cardmem0 <= ib[63:0];
  else if (w_stptr)
    cardmem0[wadr[27:22]] <= 1'b1;
assign cardmem0o = cardmem0;

// ToDo: updates at wstage not d_stage
CardMemory2 ucard1 (
  .clka(clk_g),    // input wire clka
  .ena(w_stptr & ~wadr[9]),      // input wire ena
  .wea(w_stptr & ~wadr[9]),      // input wire [0 : 0] wea
  .addra(wadr[27:10]),  // input wire [17 : 0] addra
  .dina(1'b1),    // input wire [0 : 0] dina
  .douta(),  // output wire [0 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(w_gcclr && wia[30:28]==3'd2),      // input wire enb
  .web(st_writeback & w_gcclr & ~wia[31]),      // input wire [0 : 0] web
  .addrb(wia[15:3]),  // input wire [11 : 0] addrb
  .dinb(wib[31:0]),    // input wire [31 : 0] dinb
  .doutb(card21o)  // output wire [31 : 0] doutb
);
CardMemory2 ucard2 (
  .clka(clk_g),    // input wire clka
  .ena(w_stptr & wadr[9]),      // input wire ena
  .wea(w_stptr & wadr[9]),      // input wire [0 : 0] wea
  .addra(wadr[27:10]),  // input wire [17 : 0] addra
  .dina(1'b1),    // input wire [0 : 0] dina
  .douta(),  // output wire [0 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(w_gcclr && wia[30:28]==3'd2),      // input wire enb
  .web(st_writeback & w_gcclr & ~wia[31]),      // input wire [0 : 0] web
  .addrb(wia[15:3]),  // input wire [11 : 0] addrb
  .dinb(wib[63:32]),    // input wire [31 : 0] dinb
  .doutb(card22o)  // output wire [31 : 0] doutb
);
CardMemory1 ucard3 (
  .clka(clk_g),    // input wire clka
  .ena(w_stptr),      // input wire ena
  .wea(w_stptr),      // input wire [0 : 0] wea
  .addra(wadr[27:16]),  // input wire [11 : 0] addra
  .dina(1'b1),    // input wire [0 : 0] dina
  .douta(),  // output wire [0 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(w_gcclr && wia[30:28]==3'd1),      // input wire enb
  .web(st_writeback & w_gcclr & ~wia[31]),      // input wire [0 : 0] web
  .addrb(wia[9:3]),  // input wire [6 : 0] addrb
  .dinb(wib[31:0]),    // input wire [31 : 0] dinb
  .doutb(card1o)  // output wire [31 : 0] doutb
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// PMA Checker
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [AWID-4:0] PMA_LB [0:7];
reg [AWID-4:0] PMA_UB [0:7];
reg [15:0] PMA_AT [0:7];

initial begin
  PMA_LB[7] = 28'hFFFC000;
  PMA_UB[7] = 28'hFFFFFFF;
  PMA_AT[7] = 16'h000D;       // rom, byte addressable, cache-read-execute
  PMA_LB[6] = 28'hFFD0000;
  PMA_UB[6] = 28'hFFD1FFF;
  PMA_AT[6] = 16'h0206;       // io, (screen) byte addressable, read-write
  PMA_LB[5] = 28'hFFD2000;
  PMA_UB[5] = 28'hFFDFFFF;
  PMA_AT[5] = 16'h0206;       // io, byte addressable, read-write
  PMA_LB[4] = 28'hFFFFFFF;
  PMA_UB[4] = 28'hFFFFFFF;
  PMA_AT[4] = 16'hFF00;       // vacant
  PMA_LB[3] = 28'hFFFFFFF;
  PMA_UB[3] = 28'hFFFFFFF;
  PMA_AT[3] = 16'hFF00;       // vacant
  PMA_LB[2] = 28'hFFFFFFF;
  PMA_UB[2] = 28'hFFFFFFF;
  PMA_AT[2] = 16'hFF00;       // vacant
  PMA_LB[1] = 28'h1000000;
  PMA_UB[1] = 28'hFFCFFFF;
  PMA_AT[1] = 16'hFF00;       // vacant
  PMA_LB[0] = 28'h0000000;
  PMA_UB[0] = 28'h0FFFFFF;
  PMA_AT[0] = 16'h010F;       // ram, byte addressable, cache-read-write-execute
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Evaluate branch condition
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire takb;
rtf64_EvalBranch ueb1
(
  .inst(eir[23:0]),
  .cd(cdb),
  .id(id),
  .takb(takb)
);


perceptronPredictor upp1
(
  .rst(rst_i),
  .clk(clk_g),
  .id_i(8'h00),
  .id_o(),
  .xbr(e_cbranch),
  .xadr(expc),
  .prediction_i(ebrpred),
  .outcome(takb),
  .adr(pc),
  .prediction_o(ibrpred)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Operation mask for byte, wyde, tetra format operations.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [63:0] op_mask;
always @*
case(ir[25:23]) // Fmt
3'd0: op_mask = {64{1'b1}};
3'd1: op_mask = {32{1'b1}};
3'd2: op_mask = {16{1'b1}};
3'd3: op_mask = {8{1'b1}};
default:  op_mask = {64{1'b1}};
endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Trace
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg wr_trace, rd_trace;
reg wr_whole_address;
reg [5:0] br_hcnt;
reg [5:0] br_rcnt;
reg [63:0] br_history;
wire [63:0] trace_dout;
wire [9:0] trace_data_count;
wire trace_full;
wire trace_empty;
wire trace_valid;
reg tron;
wire [3:0] trace_match;
assign trace_match[0] = (dbad[0]==ipc && dbcr[19:16]==4'b1000 && dbcr[32]);
assign trace_match[1] = (dbad[1]==ipc && dbcr[23:20]==4'b1000 && dbcr[33]);
assign trace_match[2] = (dbad[2]==ipc && dbcr[27:24]==4'b1000 && dbcr[34]);
assign trace_match[3] = (dbad[3]==ipc && dbcr[31:28]==4'b1000 && dbcr[35]);
wire trace_on = 
  trace_match[0] ||
  trace_match[1] ||
  trace_match[2] ||
  trace_match[3]
  ;
wire trace_off = trace_full;
wire trace_compress = dbcr[36];

always @(posedge clk_g)
if (rst_i) begin
  wr_trace <= 1'b0;
  br_hcnt <= 6'd8;
  br_rcnt <= 6'd0;
  tron <= FALSE;
end
else begin
  if (trace_off)
    tron <= FALSE;
  else if (trace_on)
    tron <= TRUE;
  wr_trace <= 1'b0;
  if (tron) begin
    if (!trace_compress)
      wr_whole_address <= TRUE;
    if (wval & st_writeback & trace_compress) begin
      if (d_cbranch|d_bra) begin
        if (br_hcnt < 6'h3E) begin
          br_history[br_hcnt] <= takb;
          br_hcnt <= br_hcnt + 2'd1;
        end
        else begin
          br_rcnt <= br_rcnt + 2'd1;
          br_history[7:0] <= {br_hcnt-4'd8,2'b01};
          if (br_rcnt==6'd3) begin
            br_rcnt <= 6'd0;
            wr_whole_address <= 1'b1;
          end
          wr_trace <= 1'b1;
          br_hcnt <= 6'd8;
        end
      end
      else if (d_wha) begin
        br_history[7:0] <= {br_hcnt-4'd8,2'b01};
        br_rcnt <= 6'd0;
        wr_whole_address <= 1'b1;
        wr_trace <= 1'b1;
        br_hcnt <= 6'd8;
      end
    end
    else if (st_ifetch2) begin
      if (wr_whole_address) begin
        wr_whole_address <= 1'b0;
        br_history[63:0] <= {ipc[31:2],2'b00};
        wr_trace <= 1'b1;
      end
    end
  end
end

TraceFifo utf1 (
  .clk(clk_g),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din(br_history),                // input wire [63 : 0] din
  .wr_en(wr_trace),            // input wire wr_en
  .rd_en(rd_trace),            // input wire rd_en
  .dout(trace_dout),              // output wire [63 : 0] dout
  .full(trace_full),              // output wire full
  .empty(trace_empty),            // output wire empty
  .valid(trace_valid),            // output wire valid
  .data_count(trace_data_count)  // output wire [9 : 0] data_count
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [7:0] predecodeo;
wire [3:0] ilen = predecodeo[3:0];
reg [3:0] ilenr;
rtf64_predecoder uil1 (.i(iir[7:0]), .o(predecodeo));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [3:0] icnt;
reg [1:0] waycnt = 2'd0;
(* ram_style="distributed" *)
reg [255:0] icache0 [0:pL1CacheLines-1];
reg [255:0] icache1 [0:pL1CacheLines-1];
reg [255:0] icache2 [0:pL1CacheLines-1];
reg [255:0] icache3 [0:pL1CacheLines-1];
initial begin
  for (n = 0; n < pL1CacheLines; n = n + 1) begin
    icache0[n] = {32{`NOP_INSN}};
    icache1[n] = {32{`NOP_INSN}};
    icache2[n] = {32{`NOP_INSN}};
    icache3[n] = {32{`NOP_INSN}};
  end
end
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
  ihit1a <= ictag0[pc[pL1msb:5]][AWID-1:5]==pc[AWID-1:5] && icvalid0[pc[pL1msb:5]];
always @(posedge clk_g)
  ihit1b <= ictag1[pc[pL1msb:5]][AWID-1:5]==pc[AWID-1:5] && icvalid1[pc[pL1msb:5]];
always @(posedge clk_g)
  ihit1c <= ictag2[pc[pL1msb:5]][AWID-1:5]==pc[AWID-1:5] && icvalid2[pc[pL1msb:5]];
always @(posedge clk_g)
  ihit1d <= ictag3[pc[pL1msb:5]][AWID-1:5]==pc[AWID-1:5] && icvalid3[pc[pL1msb:5]];
always @(posedge clk_g)
  ihit2a <= ictag0[pc[pL1msb:5]+2'd1][AWID-1:5]==pc[AWID-1:5]+2'd1 && icvalid0[pc[pL1msb:5]+2'd1];
always @(posedge clk_g)
  ihit2b <= ictag1[pc[pL1msb:5]+2'd1][AWID-1:5]==pc[AWID-1:5]+2'd1 && icvalid1[pc[pL1msb:5]+2'd1];
always @(posedge clk_g)
  ihit2c <= ictag2[pc[pL1msb:5]+2'd1][AWID-1:5]==pc[AWID-1:5]+2'd1 && icvalid2[pc[pL1msb:5]+2'd1];
always @(posedge clk_g)
  ihit2d <= ictag3[pc[pL1msb:5]+2'd1][AWID-1:5]==pc[AWID-1:5]+2'd1 && icvalid3[pc[pL1msb:5]+2'd1];
wire ihitw0 = (ihit1a & ihit2a);
wire ihitw1 = (ihit1b & ihit2b);
wire ihitw2 = (ihit1c & ihit2c);
wire ihitw3 = (ihit1d & ihit2d);
wire ihit = ihitw0 | ihitw1 | ihitw2 | ihitw3;
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Compressed instruction table.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg wr_ci_tbl;
reg rd_ci;
reg [31:0] ci_tbl [0:511];
initial begin
  for (n = 0; n < 512; n = n + 1)
    ci_tbl[n] <= `NOP_INSN;
    
end
always @(posedge clk_g)
  if (wval & wr_ci_tbl)
      ci_tbl[wia[8:0]] <= wib[31:0];
wire [31:0] ci_tblo2 = ci_tbl[ia[8:0]];
wire [31:0] ci_tblo = ci_tbl[{ir[0],ir[15:8]}]; // Decode stage read

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Data cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [AWID-1:0] first_adr_o;
reg use_dc = 1'b0;
reg [3:0] dcnt = 4'd0;
reg dld = 1'b0, dload = 1'b0;
reg [311:0] dcache_in = 312'd0;
reg [311:0] dcache_ram [0:127];
reg [AWID-1:5] dcache_tag [0:127];
reg [127:0] dcache_valid;
initial begin
	dcache_valid <= 128'd0;
	for (n = 0; n < 128; n = n + 1)
		dcache_tag[n] <= {{AWID-4{1'b0}},1'b1};	
	for (n = 0; n < 128; n = n + 1)
		dcache_ram[n] <= {312{1'b0}};
end
wire [AWID-1:5] tago = dcache_tag[adr_o[11:5]];
wire dhit = tago==adr_o[AWID-1:5] && dcache_valid[adr_o[11:5]];
wire [311:0] dcache_dato1 = dcache_ram[adr_o[11:5]];
wire [WID-1:0] dcache_dato = dcache_dato1 >> {adr_o[4:0],3'b0};
reg [38:0] dc_sel;
reg [311:0] dc_dat;

generate begin : gDcacheUpdate
	for (g = 0; g < 39; g = g + 1)
		always @(posedge clk_g)
			if (dhit & we_o)
				dcache_in[g*8+7:g*8] <= dc_sel[g] ? dc_dat[g*8+7:g*8] : dcache_dato1[g*8+7:g*8];
			else if (dload)
				dcache_in[g*8+7:g*8] <= dc_dat[g*8+7:g*8];
end
endgenerate				

always @(posedge clk_g)
	dld <= (dhit & we_o) | dload;
always @(posedge clk_g)
	if (dld)
		dcache_tag[first_adr_o[11:5]] <= first_adr_o[AWID-1:5];
always @(posedge clk_g)
	if (dld)
		dcache_ram[first_adr_o[11:5]] <= dcache_in;
always @(posedge clk_g)
if (rst_i)
	dcache_valid <= 128'd0;
else begin
	if (dld)
		dcache_valid[first_adr_o[11:5]] <= 1'b1;
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire acki = ack_i;

assign omode = pmStack[3:1];
assign DebugMode = omode==3'b101;
assign InterruptMode = omode==3'b100;
assign MachineMode = omode==3'b011;
assign HypervisorMode = omode==3'b010;
assign SupervisorMode = omode==3'b001;
assign UserMode = omode==3'b000;
assign memmode = mprv ? pmStack[7:5] : omode;
wire MMachineMode = memmode==3'b011;
assign MUserMode = memmode==3'b000;

wire [7:0] selx;
modSelect usel1
(
  .opcode(mir[7:0]),
  .sel(selx)
);

reg [AWID-1:0] ea, ea_tmp;
reg [7:0] ealow;
wire [3:0] segsel = ea[AWID-1:AWID-4];

`ifdef CPU_B128
reg [31:0] sel;
reg [255:0] dat, dati;
wire [63:0] datis = use_dc ? dcache_dato : dati >> {ealow[3:0],3'b0};
`endif
`ifdef CPU_B64
reg [15:0] sel;
reg [127:0] dat, dati;
wire [63:0] datis = use_dc ? dcache_dato : dati >> {ealow[2:0],3'b0};
`endif
`ifdef CPU_B32
reg [7:0] sel;
reg [63:0] dat, dati;
wire [63:0] datis = use_dc ? dcache_dato : dati >> {ealow[1:0],3'b0};
`endif

wire ld = st_execute;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Count: leading zeros, leading ones, population.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [6:0] cntlzo, cntloo, cntpopo;

cntlz64 uclz1 (ia, cntlzo);
cntlo64 uclo1 (ia, cntloo);
cntpop64reg ucpop1 (clk_g, 1'b1, ia, cntpopo);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Shift / Bitfield
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [WID-1:0] shft_o;

rtf64_shift ushft1
(
  .ir(eir[31:0]),
  .ia(ia),
  .ib(ib),
  .id(id),
  .imm(imm),
  .cds(cds),
  .res(shft_o)
);

wire [63:0] bfo;

bitfield ubf1
( 
  .clk(clk_g),
  .ce(1'b1),
  .ir(eir),
  .d_i(e_exti|e_extui|e_flipi|e_depi|e_ffoi),
  .d_ext(e_exti|e_extr),
  .d_extu(e_extui|e_extur),
  .d_flip(e_flipi|e_flipr),
  .d_dep(e_depi|e_depr),
  .d_depi(e_depii),
  .d_ffo(e_ffoi|e_ffor),
  .a(ia),
  .b(ib),
  .c(ic),
  .d(id),
  .imm(imm),
  .o(bfo)
);

wire [WID-1:0] r1_res, r1_crres;

rtf64_r1 ur1
(
  .ir(eir[31:0]),
  .ia(ia),
  .id(id),
  .cdb(cdb),
  .res(r1_res),
  .crres(r1_crres)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide support logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg sgn;
wire [WID*2-1:0] produ = ia * ib;
wire [WID*2-1:0] prods = $signed(ia) * $signed(ib);
wire [WID*2-1:0] prodsu = $signed(ia) * ib;
wire [WID*2-1:0] produi = ia * imm;
wire [WID*2-1:0] prodsi = $signed(ia) * $signed(imm);
wire [WID*2-1:0] prodsui = $signed(ia) * imm;
wire [WID*2-1:0] produ6, prods6, prodsu6;
wire [WID*2-1:0] produi6, prodsi6, prodsui6;

delay #(.WID(WID*2),.DEP(6)) umd1 (.clk(clk_g), .ce(1'b1), .i(produ), .o(produ6));
delay #(.WID(WID*2),.DEP(6)) umd2 (.clk(clk_g), .ce(1'b1), .i(prods), .o(prods6));
delay #(.WID(WID*2),.DEP(6)) umd3 (.clk(clk_g), .ce(1'b1), .i(prodsu), .o(prodsu6));
delay #(.WID(WID*2),.DEP(6)) umd4 (.clk(clk_g), .ce(1'b1), .i(produi), .o(produi6));
delay #(.WID(WID*2),.DEP(6)) umd5 (.clk(clk_g), .ce(1'b1), .i(prodsi), .o(prodsi6));
delay #(.WID(WID*2),.DEP(6)) umd6 (.clk(clk_g), .ce(1'b1), .i(prodsui), .o(prodsui6));

wire [WID*2-1:0] div_q;
reg [WID*2-1:0] ndiv_q, sdiv_q;
reg [WID-1:0] div_r,ndiv_r,sdiv_r;
always @(posedge clk_g)
  ndiv_q <= -div_q;
always @(posedge clk_g)
  sdiv_q <= sgn ? ndiv_q : div_q;
always @(posedge clk_g)
  div_r <= ia - (ib * div_q[WID*2-1:WID]);
always @(posedge clk_g)
  ndiv_r <= (ib * div_q[WID*2-1:WID]) - ia;
always @(posedge clk_g)
  sdiv_r <= sgn ? ndiv_r : div_r;
reg ldd,ldd1,ldd2;
always @(posedge clk_g)
  ldd1 <= ldd;
always @(posedge clk_g)
  ldd2 <= ldd1;
fpdivr16 #(WID) u16 (
	.clk(div_clk_i),
	.ld(ldd|ldd1|ldd2),
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
reg d_fltcmp;
wire [4:0] fltfunct5 = ir[27:23];
wire [4:0] rfltfunct5 = rir[27:23];
wire [4:0] efltfunct5 = eir[27:23];
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
reg ld1,ld2;
wire sqrneg, sqrinf;
wire fa_inf, fa_xz, fa_vz;
wire fa_qnan, fa_snan, fa_nan;
wire fb_qnan, fb_snan, fb_nan;
wire finf, fdn;
always @(posedge clk_g)
	ld1 <= ld;
always @(posedge clk_g)
	ld2 <= ld1;
fpDecomp u12 (.i(ia), .sgn(), .exp(), .man(), .fract(), .xz(fa_xz), .mz(), .vz(fa_vz), .inf(fa_inf), .xinf(), .qnan(fa_qnan), .snan(fa_snan), .nan(fa_nan));
fpDecomp u13 (.i(ib), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(fb_qnan), .snan(fb_snan), .nan(fb_nan));
fpCompare u1 (.a(ia), .b(ib), .o(fcmp_o), .nan(cmpnan), .snan(cmpsnan));
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f u2 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(ia), .o(itof_res));
f2i u3 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .i(ia), .o(ftoi_res), .overflow());
fpAddsub u4 (.clk(clk_g), .ce(1'b1), .rm(rmq), .op(fltfunct5==`FSUB), .a(ia), .b(ib), .o(fas_o));
fpMultiply u5 (.clk(clk_g), .ce(1'b1), .a(ia), .b(ib), .o(fmul_o), .sign_exe(), .inf(), .overflow(nmul_of), .underflow(mul_uf));
fpDivide u6 (.rst(rst_i), .clk(div_clk_i), .clk4x(1'b0), .ce(1'b1), .ld(ld|ld1|ld2), .op(1'b0),
	.a(ia), .b(ib), .o(fdiv_o), .done(), .sign_exe(), .overflow(div_of), .underflow(div_uf));
fpSqrt u7 (.rst(rst_i), .clk(clk_g), .ce(1'b1), .ld(ld),
	.a(ia), .o(fsqrt_o), .done(sqrt_done), .sqrinf(sqrinf), .sqrneg(sqrneg));
fpFMA u14
(
	.clk(clk_g),
	.ce(1'b1),
	.op(opcode==FMS||opcode==FNMS),
	.rm(rmq),
	.a(opcode==`FNMA||opcode==`FNMS ? {~ia[FPWID-1],ia[FPWID-2:0]} : ia),
	.b(ib),
	.c(ic),
	.o(fma_o),
	.under(fma_uf),
	.over(),
	.inf(),
	.zero()
);

always @(posedge clk_g)
case(eopcode)
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_i <= fma_o;
`FLT2:
	case(efltfunct5)
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
case(eopcode)
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_uf <= fma_uf;
`FLT2:
	case(efltfunct5)
	`FMUL:	fnorm_uf <= mul_uf;
	`FDIV:	fnorm_uf <= div_uf;
	default:	fnorm_uf <= 1'b0;
	endcase
default:	fnorm_uf <= 1'b0;
endcase
fpNormalize u8 (.clk(clk_g), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(fnorm_uf), .under_o(norm_uf), .inexact_o(norm_nx));
fpRound u9 (.clk(clk_g), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));
fpDecompReg u10 (.clk(clk_g), .ce(1'b1), .i(fres), .sgn(), .exp(), .fract(), .xz(fdn), .vz(), .inf(finf), .nan() );

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Posit Arithmetic Logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [63:0] pas_o;
wire [63:0] pmul_o;
wire [63:0] pdiv_o;
wire [63:0] itop_o, ptoi_o, itopd, ptoid;
wire pmulz_o, pmuli_o;
wire pdivz_o, pdivi_o;

`ifdef SUPPORT_POSITS

positAddsub_rt up4
(
  .clk(clk_g),
  .ce(1'b1),
  .op(efltfunct5==`PSUB),
  .a(ia),
  .b(ib),
  .o(pas_o)
);

positMultiply up5
(
  .clk(clk_g),
  .ce(1'b1),
  .a(ia),
  .b(ib),
  .o(pmul_o),
  .zero(pmulz_o),
  .inf(pmuli_o)
);

positDivide up6
(
  .clk(div_clk_i),
  .ce(1'b1),
  .a(ia),
  .b(ib),
  .o(pdiv_o),
  .zero(pdivz_o),
  .inf(pdivi_o)
);

intToPosit uitop1(ia, itopd);
positToInt uptoi1(clk, 1'b1, ia, ptoi_o);
// Pipelining stages for conversions.
delay3 #(PSTWID) updl1 (.clk(clk_g), .ce(1'b1), .i(itopd), .o(itop_o));
`endif

wire pcmpnan = ia==64'h8000000000000000 || ib==64'h8000000000000000;
wire pinf_o = ia==64'h8000000000000000 || ib==64'h8000000000000000;
wire pseq_o = ia==ib;
wire pslt_o = $signed(ia) < $signed(ib);
wire psle_o = $signed(ia) <= $signed(ib);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Address Generator
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire inc_ma = (mstate==MEMORY5 && !acki) ||
              (mstate==MEMORY10 && !acki) ||
              (mstate==MEMORY15 && !acki);

wire [AWID-1:0] eea;
agen uag1
(
  .rst(rst_i),
  .clk(clk_g),
  .en(eval & st_execute),
  .inc_ma(1'b0),
  .inst(eir[31:0]),
  .a(ia),
  .c(ic),
  .ma(eea),
  .idle()
);

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

wire [3:0] ea_acr = sregfile[segsel][3:0];
wire [3:0] pc_acr = sregfile[pc[AWID-1:AWID-4]][3:0];
wire iaccess_pending = istate==IFETCH3 && !(((ihitw0|ihitw1|ihitw2|ihitw3) && icnt==4'h0) ||
                          ((ihit1a|ihit1b|ihit1c|ihit1d) && ipc[4:0] < 5'h9 && icnt==4'h0));

always @(posedge clk_g)
begin
  tReset();

  // Signals that reset or calc every clock cycle.
  tOne();

  if (wr_rf && wRd==7'd31)
    sp_regfile[w_omode] <= wres[WID-1:0];

  // The six stage pipeline
  tIFetch();
  tDecode();
  tRegfetch();
  tExecute();
  tMemory();
  tWriteback();

  // Trailer stages, used to support loop mode
  tTStage();
  tUStage();
  tVStage();
  
  // Invalidate portions of pipeline due to branch or exceptions.
  tInvalidate();
end

task tReset;
begin
  if (rst_i) begin
	for (n = 0; n < 8; n = n + 1) begin
	  tvec[n] <= 32'hFFFC0000;
	  status[n] <= 32'h0;
  end
	ASID <= 5'd0;
	gcie <= 32'h0;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	wrcrf32 <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
  cyc_o <= LOW;
  stb_o <= LOW;
  we_o <= LOW;
  sel_o <= 4'h0;
  dat_o <= 128'd0;
	sr_o <= 1'b0;
	cr_o <= 1'b0;

	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	pmStack <= 16'b0001_0001_1010;
	nmif <= 1'b0;
	ldd <= 1'b0;
	wrpagemap <= 1'b0;
  pagemapa <= 13'd0;
	setto <= 1'b0;
	getto <= 1'b0;
	decto <= 1'b0;
	getzl <= 1'b0;
	popto <= 1'b0;
	gcloc <= 6'd0;
	pushq <= 1'b0;
	popq <= 1'b0;
	peekq <= 1'b0;
	statq <= 1'b0;
	mrloc <= 3'd0;
	set_wfi <= 1'b0;
	next_epc <= 32'hFFFFFFFF;
	instret <= 40'd0;
	tlben <= 1'b0;
	tlbwr <= 1'b0;
	xlaten <= 1'b0;
	wr_ci_tbl <= FALSE;
	instfetch <= 40'd0;
	icaccess <= FALSE;
	maccess <= FALSE;
	rd_ci <= FALSE;
	loop_mode <= 3'd0;
	exception <= FALSE;
	uie <= 1'b0;
	sie <= 1'b0;
	hie <= 1'b0;
	mie <= 1'b0;
	iie <= 1'b0;
	die <= 1'b0;
	i_omode <= 3'd5;
	d_omode <= 3'd5;
	r_omode <= 3'd5;
	e_omode <= 3'd5;
	m_omode <= 3'd5;
	w_omode <= 3'd5;
  end
end
endtask

task tOne;
begin
if (trace_match[0]) dbsr[0] <= TRUE;
if (trace_match[1]) dbsr[1] <= TRUE;
if (trace_match[2]) dbsr[2] <= TRUE;
if (trace_match[3]) dbsr[3] <= TRUE;
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
statq <= 1'b0;
rd_trace <= 1'b0;
wr_ci_tbl <= FALSE;

`ifdef RTF64_PAGEMAP
if (state != IFETCH3 && state != IFETCH4 && state != IFETCH5) begin
  if (!UserMode)
  	adr_o <= ladr;
  else begin
  	if (ladr[AWID-1:24]=={AWID-24{1'b1}})
  		adr_o <= ladr[AWID-1:0];
  	else
  		adr_o <= {pagemapo & 14'h3FFF,ladr[13:0]};
  end
end
`endif

// Check the memory keys
keyViolation <= TRUE;
for (n = 0; n < 9; n = n + 1)
  if (keyo==key[n] || keyo==20'h0)
    keyViolation <= FALSE;

xlaten <= FALSE;
if (inc_ma)
`ifdef CPU_B128
  ea <= {ea[31:4]+2'd1,4'b00};
`endif
`ifdef CPU_B64
  ea <= {ea[31:3]+2'd1,3'b00};
`endif
`ifdef CPU_B32
  ea <= {ea[31:2]+2'd1,2'b00};
`endif
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction fetch stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tIFetch();
begin
if (rst_i) begin
	istate <= IFETCH1;
	ifetch_done <= FALSE;
	icvalid0 <= 64'd0;
	icvalid1 <= 64'd0;
	icvalid2 <= 64'd0;
	icvalid3 <= 64'd0;
	ic_invline <= 1'b0;
	pc_reload <= TRUE;
	pc <= RSTPC;
	iadr <= RSTPC;
	ipc <= {AWID{1'b0}};
	iir <= {8{`NOP}};
	dilen <= 4'd1;
	d_loop_bust <= FALSE;
	i_cause <= 32'h00;
	d_cause <= 32'h00;
end
else begin
`ifdef SIM
  iStateNameReg = iStateName(istate);
`endif
case (istate)
// It takes two clocks to read the pagemap ram, this is after the linear
// address is set, which also takes a clock cycle.
IFETCH1:
  begin
    /*
	  Rdx <= Rdx1;
	  Rs1x <= Rs1x1;
	  Rs2x <= Rs2x1;
	  Rs3x <= Rs3x1;
	  */
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
    tPC();
    xlaten <= TRUE;
 		vpa_o <= HIGH;
 		i_cause <= 8'h00;
    igoto (IFETCH2);
  end
IFETCH2:
  begin
    ipc2 <= ipc;
    if (ihit1a|ihit1b|ihit1c|ihit1d)
      icnt <= 4'h8;
    else
      icnt <= 4'd0;
		if (ihitw0) begin
		  iri1 <= icache0[pc[pL1msb:5]];
		  iri2 <= icache0[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1a && pc[4:0] < 5'h9) begin
		  iri1 <= icache0[pc[pL1msb:5]];
		  iri2 <= icache0[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
		else if (ihitw1) begin
		  iri1 <= icache1[pc[pL1msb:5]];
		  iri2 <= icache1[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1b && pc[4:0] < 5'h9) begin
		  iri1 <= icache1[pc[pL1msb:5]];
		  iri2 <= icache1[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
		else if (ihitw2) begin
		  iri1 <= icache2[pc[pL1msb:5]];
		  iri2 <= icache2[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1c && pc[4:0] < 5'h9) begin
		  iri1 <= icache2[pc[pL1msb:5]];
		  iri2 <= icache2[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
		else if (ihitw3) begin
		  iri1 <= icache3[pc[pL1msb:5]];
		  iri2 <= icache3[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1d && pc[4:0] < 5'h9) begin
		  iri1 <= icache3[pc[pL1msb:5]];
		  iri2 <= icache3[pc[pL1msb:5]+2'd1];
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else begin
`ifdef RTF64_TLB
    igoto (IFETCH2a);
`else
    igoto (IFETCH3);
`endif
    end
  end
IFETCH2a:
  begin
    igoto(IFETCH3);
  end
IFETCH3:
  begin
		if (ihitw0 && icnt==4'h0) begin
		  iri1 <= icache0[pc[pL1msb:5]];
		  iri2 <= icache0[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1a && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri1 <= icache0[pc[pL1msb:5]];
		  iri2 <= icache0[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
		else if (ihitw1 && icnt==4'h0) begin
		  iri1 <= icache1[pc[pL1msb:5]];
		  iri2 <= icache1[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1b && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri1 <= icache1[pc[pL1msb:5]];
		  iri2 <= icache1[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
		else if (ihitw2 && icnt==4'h0) begin
		  iri1 <= icache2[pc[pL1msb:5]];
		  iri2 <= icache2[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1c && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri1 <= icache2[pc[pL1msb:5]];
		  iri2 <= icache2[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
		else if (ihitw3 && icnt==4'h0) begin
		  iri1 <= icache3[pc[pL1msb:5]];
		  iri2 <= icache3[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1d && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri1 <= icache3[pc[pL1msb:5]];
		  iri2 <= icache3[pc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  igoto (INSTRUCTION_ALIGN);
	  end
	  else
	  begin
  		igoto (IFETCH3a);
`ifdef RTF64_TLB  		
  		if (tlbmiss) begin
  			i_cause <= 32'h80000004;
			  badaddr[3'd5] <= ipc2;
			  vpa_o <= FALSE;
			end
			else
`endif			
			begin
			  // First time in, set to miss address, after that increment
			  icaccess <= !maccess;
`ifdef CPU_B128
        if (!icaccess)
          iadr <= {pc[AWID-1:5],5'h0};
        else
          iadr <= {iadr[AWID-1:4],4'h0} + 5'h10;
`endif
`ifdef CPU_B64
        if (!icaccess)
          iadr <= {pc[AWID-1:5],5'h0}
        else
          iadr <= {iadr[AWID-1:3],3'h0} + 4'h8;
`endif
`ifdef CPU_B32
        if (!icaccess)
          iadr <= {pc[AWID-1:5],5'h0};
        else
          iadr <= {iadr[AWID-1:2],2'h0} + 3'h4;
`endif			
      end
	  end
  end
IFETCH3a:
  if (!maccess & ~ack_i) begin
    cyc_o <= HIGH;
		stb_o <= HIGH;
`ifdef CPU_B128
    sel_o <= 16'hFFFF;
`endif
`ifdef CPU_B64
    sel_o <= 8'hFF;
`endif
`ifdef CPU_B32
		sel_o <= 4'hF;
`endif
    igoto (IFETCH4);
  end
  else
    icaccess <= !maccess;
IFETCH4:
  begin
    if (ack_i) begin
      cyc_o <= LOW;
      stb_o <= LOW;
      vpa_o <= LOW;
      sel_o <= 1'h0;
`ifdef CPU_B128
      case(icnt[2])
      1'd0: ici[127:0] <= dat_i;
      1'd1: ici[255:128] <= dat_i;
      endcase
      igoto (IFETCH5);
`endif
`ifdef CPU_B64
      case(icnt[2:1])
      2'd0: ici[63:0] <= dat_i;
      2'd1: ici[127:64] <= dat_i;
      2'd2: ici[191:128] <= dat_i;
      2'd3; ici[255:192] <= dat_i;
      endcase
      igoto (IFETCH5);
`endif
`ifdef CPU_B32
      case(icnt[2:0])
      3'd0: ici[31:0] <= dat_i;
      3'd1: ici[63:32] <= dat_i;
      3'd2: ici[95:64] <= dat_i;
      3'd3: ici[127:96] <= dat_i;
      3'd4: ici[159:128] <= dat_i;
      3'd5: ici[191:160] <= dat_i;
      3'd6; ici[223:192] <= dat_i;
      3'd7: ici[255:224] <= dat_i;
      endcase
      igoto (IFETCH5);
`endif
    end
		tPMAPC(); // must have adr_o valid for PMA
  end
IFETCH5:
  begin
`ifdef CPU_B128
    if (icnt[2]==1'd1)
      case(waycnt)
      2'd0: ictag0[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd1: ictag1[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd2: ictag2[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd3: ictag3[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      endcase
`endif
`ifdef CPU_B64
    if (icnt[2:1]==2'd3)
      case (waycnt)
      2'd0: ictag0[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd1: ictag1[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd2: ictag2[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd3: ictag3[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      endcase
`endif
`ifdef CPU_B32
    if (icnt[2:0]==3'd7)
      case(waycnt)
      2'd0: ictag0[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd1: ictag1[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd2: ictag2[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      2'd3: ictag3[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
      endcase
`endif
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
    if (~ack_i) begin
`ifdef CPU_B128
      icnt <= icnt + 4'd4;
`endif
`ifdef CPU_B64
      icnt <= icnt + 4'd2;
`endif
`ifdef CPU_B32
      icnt <= icnt + 2'd1;
`endif
      // It takes a cycle before ihit becomes valid, so we go back to a cycle
      // before it is tested.
      igoto (IFETCH2a);
    end
  end
INSTRUCTION_ALIGN:
  begin
    waycnt <= waycnt + 2'd1;
    iir <= {iri2,iri1} >> {ipc2[4:0],3'b0};
    igoto (IFETCH_INCR);
  end
IFETCH_INCR:
  begin
    ilenr <= ilen;
    ifetch_done <= TRUE;
    igoto (IFETCH_WAIT);
  end
IFETCH_WAIT:
  if (advance_i) begin
    dval <= TRUE;
    d_omode <= i_omode;
    d_cause <= i_cause;
    // Must be before iException()
		if (nmif)
			d_cause <= 32'h800000FE;
 		else if (irq_i & die)
 		  d_cause <= {24'h800000,cause_i};
		else if (mip[7] & miex[7] & die)
		  d_cause <= 32'h800000F2;
		else if (mip[3] & miex[3] & die)
		  d_cause <= 32'h800000F0;
		else if (uip[0] & gcie[ASID] & die) begin
		  d_cause <= 32'hC00000F3;
			uip[0] <= 1'b0;
		end
		instfetch <= instfetch + 2'd1;
    if (wmod_pc)
      pc <= wnext_pc;
    else if (mmod_pc)
      pc <= mnext_pc;
    else if (emod_pc)
      pc <= enext_pc;
    else if (rmod_pc)
      pc <= rnext_pc;
    else if (dmod_pc)
      pc <= dnext_pc;
    else
      pc <= pc + ilenr;
`ifdef SUPPORT_LOOPMODE
    case(loop_mode)
    3'd0: begin ir <= iir; dpc <= ipc2; dilen <= ilenr; dbrpred <= ibrpred; end // loop mode not active
    3'd1: ;//begin ir <= rir; dpc <= rpc; dilen <= rilen; dbrpred <= rbrpred; end
    3'd2: begin ir <= eir; dpc <= expc; dilen <= eilen; dbrpred <= TRUE; pc <= pc; end
    3'd3: begin ir <= mir; dpc <= mpc; dilen <= milen; dbrpred <= TRUE; pc <= pc; end
    3'd4: begin ir <= wir; dpc <= wpc; dilen <= wilen; dbrpred <= TRUE; pc <= pc; end
    3'd5: begin ir <= tir; dpc <= tpc; dilen <= tilen; dbrpred <= TRUE; pc <= pc; end
    3'd6: begin ir <= uir; dpc <= upc; dilen <= uilen; dbrpred <= TRUE; pc <= pc; end
    3'd7: begin ir <= vir; dpc <= vpc; dilen <= vilen; dbrpred <= TRUE; pc <= pc; end
    endcase
    if (is_loop_mode) begin
      ifetch_done <= TRUE;
      igoto(IFETCH_WAIT);
    end
    else
`else
    begin ir <= iir; dpc <= ipc2; dilen <= ilenr; dbrpred <= ibrpred; end
`endif
    begin
      ifetch_done <= FALSE;
      igoto (IFETCH1);
    end
  end
endcase
end
end
endtask


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction decode stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tDecode;
begin
if (rst_i) begin
  dcyc <= 3'd0;
  dpc <= RSTPC;
  dimm2 <= 64'd0;
  Rs12 <= 5'd0;
  illegal_insn <= FALSE;
  rRs1 <= 7'd0;
  rRs2 <= 7'd0;
  rRs3 <= 7'd0;
  rRd <= 8'd0;
  rCs <= 2'b00;
  rCd <= 2'b00;
  d_cbranch <= FALSE;
  r_jsr <= FALSE;
  r_rts <= FALSE;
  r_st <= FALSE;
  r_ld <= FALSE;
  r_stptr <= FALSE;
  r_pushc <= FALSE;
	r_cmp <= FALSE;
	r_set <= FALSE;
	r_tst <= FALSE;
	r_fltcmp <= FALSE;
	r_atni <= FALSE;
	r_exec <= FALSE;
  rbrpred <= FALSE;
  r_cbranch <= FALSE;
  rnext_pc <= RSTPC;
  
  r_exti <= FALSE;
  r_extr <= FALSE;
  r_extui <= FALSE;
  r_extur <= FALSE;
  r_depi <= FALSE;
  r_depr <= FALSE;
  r_depii <= FALSE;
  r_flipi <= FALSE;
  r_flipr <= FALSE;
  r_ffoi <=  FALSE;
  r_ffor <= FALSE;
  r_setkey <= FALSE;
  r_gcclr <= FALSE;
  r_pushc <= FALSE;
  r_rad <= 1'b0;
  r_loop_bust <= FALSE;
  r_cause <= 8'h00;
 
	rilen <= 4'd1;
	dwrsrf <= FALSE;
	rwrsrf <= FALSE;
  dmod_pc <= FALSE;
  dbrpred <= FALSE;
	dstate <= DECODE_WAIT;
	decode_done <= TRUE;
	atni_done <= FALSE;
	exec_done <= FALSE;
end
else
case (dstate)
EXPAND_CI:
  begin
    ir <= ci_tblo;
    rd_ci <= TRUE;
    dgoto (DECODE);
  end
DECODE:
  begin
    illegal_insn <= TRUE;
    wrirf <= 1'b0;
    wrcrf <= FALSE;
    wrcrf32 <= 1'b0;
    wrra <= 1'b0;
    wrca <= 1'b0;
    dwrsrf <= FALSE;
    dmod_pc <= FALSE;
    if (dcyc==3'd0) begin
      d_link <= FALSE;
      d_unlink <= FALSE;
      d_push <= FALSE;
      d_pushc <= FALSE;
      d_pop <= FALSE;
      d_ldm <= FALSE;
      d_stm <= FALSE;
    end
    d_cmp <= 1'b0;
    d_set <= 1'b0;
    d_tst <= 1'b0;
    d_chk <= FALSE;
    d_mov <= 1'b0;
    d_stot <= 1'b0;
    d_stptr <= 1'b0;
    d_setkey <= 1'b0;
    d_gcclr <= 1'b0;
    d_fltcmp <= 1'b0;
    d_shiftr <= 1'b0;
    d_st <= FALSE;
    d_ld <= FALSE;
    d_depi <= FALSE;
    d_depr <= FALSE;
    d_depii <= FALSE;
    d_extr <= FALSE;
    d_exti <= FALSE;
    d_extui <= FALSE;
    d_extur <= FALSE;
    d_flipr <= FALSE;
    d_flipi <= FALSE;
    d_ffoi <= FALSE;
    d_ffor <= FALSE;
    d_cbranch <= FALSE;
    d_bra <= FALSE;
    d_wha <= FALSE;
    d_pushq <= FALSE;
    d_popq <= FALSE;
    d_peekq <= FALSE;
    d_statq <= FALSE;
    d_cache <= FALSE;
    d_jsr <= FALSE;
    d_rts <= FALSE;
    d_pushc <= FALSE;
    d_push_reg <= FALSE;
    d_atni <= FALSE;
    d_exec <= FALSE;
    d_loop_bust <= FALSE;
    rd_ci <= FALSE;
    /* Decode is faster than the slowest stage meaning it'll always transition
       to the DECODE_WAIT state. Save some hardware by not checking for
       pipeline advance here.
       
    if (advance_pipe) begin
      rir <= ir;
      rpc <= dpc;
      rilen <= dilen;
      rillegal_insn <= illegal_insn;
      if (dmod_pc)
        pc <= dnext_pc;
      decode_done <= FALSE;
      dgoto (DECODE);
    end
    else
    */
    begin
      decode_done <= TRUE;
      dgoto(DECODE_WAIT);
    end
    if (e_atni & !atni_done) begin
      atni_done <= TRUE;
      decode_done <= FALSE;
      ir <= ir + id;
      dgoto(DECODE);
    end
    if (e_exec & !exec_done) begin
      exec_done <= TRUE;
      decode_done <= FALSE;
      ir <= id;
      dgoto(DECODE);
    end
    Rd <= 7'd0;
    Rs1 <= {2'b0,ir[17:13]};
    Rs2 <= {2'b0,ir[22:18]};
    Rs3 <= {2'b0,ir[27:23]};
    Cd <= 2'd0;
    Cs <= ir[9:8];
    rad <= ir[8];
    casez(opcode)
    `CI: 
      begin
        if (!rd_ci) begin
          decode_done <= FALSE;
          dgoto(EXPAND_CI);
        end
//        else
//          dException();
      end
    `OSR2:
      case(funct5)
      `CACHE:
        begin
          d_cache <= TRUE;
          case(ir[9:8])
          2'd0: ;
          2'd1: ic_invline <= 1'b1;
          2'd2: 
            begin
              icvalid0 <= 64'd0;
              icvalid1 <= 64'd0;
              icvalid2 <= 64'd0;
              icvalid3 <= 64'd0;
            end
          3'd3: ;
          endcase
		      illegal_insn <= 1'b0;
        end
		  `PFI: 
		    begin
		      if (irq_i != 1'b0) begin
		        d_cause <= 32'h80000000|cause_i;
		        //dException(32'h80000000|cause_i,dpc);
		      end
		      illegal_insn <= 1'b0;
		    end
		  `SETKEY:  
	      if (d_omode != 3'd0) begin
	        d_setkey <= 1'b1;
	        illegal_insn <= 1'b0;
	      end
	    `GCCLR:
	      begin
	        d_gcclr <= 1'b1;
	        illegal_insn <= 1'b0;
	      end
	    `MVMAP:
	      begin
	        illegal_insn <= 1'b0;
	      end
	    `MVSEG:
	      begin
	        dwrsrf <= TRUE;
	        illegal_insn <= FALSE;
	      end
	    `TLBRW: begin illegal_insn <= 1'b0; end
	    `PUSHQ: begin d_pushq <= TRUE; illegal_insn <= FALSE; end
	    `POPQ:  begin d_popq <= TRUE; illegal_insn <= FALSE; end
	    `PEEKQ: begin d_peekq <= TRUE; illegal_insn <= FALSE; end 
	    `STATQ: begin d_statq <= TRUE; illegal_insn <= FALSE; end
	    `MVCI:  begin illegal_insn <= FALSE; end
	    `REX: illegal_insn <= FALSE;
		  default:  ;
		  endcase
    `R2:
      begin
        Rd <= {2'b0,ir[12:8]};
        Cd <= 2'b00;
        case(funct5)
        `ANDR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR2:  begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `EORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `BMMR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ADDR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `SUBR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NANDR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ENORR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `R1:
          case(ir[22:18])
          `CNTLZR1: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `CNTLOR1: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `CNTPOPR1:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `COMR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `NOTR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `NEGR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `TST1:    begin Rd <= 8'd0; Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; d_tst <= TRUE; end
          `PTRINC:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          default:  ;                                    
          endcase
        `MULR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
//        `CMPR2: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
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
        `BYTNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `WYDNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `U21NDXR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULF:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RGFR2:begin illegal_insn <= 1'b0; end
        `MOV:
          begin
            d_mov <= 1'b1;
            wrcrf <= ir[31];
            Rd <= {ir[19:18],ir[12:8]};
            case (ir[19:18])
            2'b00:  wrirf <= 1'b1;
            2'b01:  wrirf <= 1'b1;
            2'b10:  wrirf <= 1'b1;
            2'b11:  
              casez(ir[12:8])
              5'b0000?: begin rad <= ir[8]; wrra <= 1'b1; end
              5'b0001?: begin rad <= 1'b0; wrca <= 1'b1; end
              5'b100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
              5'b11101: wrcrf32 <= 1'b1;
              default:  ;
              endcase
            endcase
            Rs1 <= {ir[21:20],ir[17:13]};
            case(ir[21:20])
            2'b00:  ;
            2'b01:  ;
            2'b10:  ;
            2'b11:
              casez(ir[17:13])
              5'b0000?: rad <= ir[13];
              5'b0001?: rad <= 1'b0;
              5'b100??: Cs <= ir[14:13];
              default:  ;
              endcase
            default:  ;
            endcase
            illegal_insn <= 1'b0;
          end
        default:  ;
        endcase
      end
    `R2B:
      begin
        Rd <= {2'b0,ir[12:8]};
        Cs <= ir[19:18];
        case(funct5)
        `ANDR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR2:  begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `EORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `BMMR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ADDR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `SUBR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NANDR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ENORR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `MULR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PERMR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PTRDIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `BYTNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `WYDNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `U21NDXR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULF:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CHKR2B: begin d_chk <= TRUE; illegal_insn <= 1'b0; wrcrf <= ir[31]; end
        `RGFR2:begin illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end
    `R3A:
      begin
        Rd <= {2'b0,ir[12:8]};
        case(ir[30:28])
        `MINR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MAXR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MAJR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MUXR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ADDR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `SUBR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `FLIPR3A:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_flipr <= 1'b1; end
        default:  ;
        endcase
      end
    `R3B:
      begin
        Rd <= {2'b0,ir[12:8]};
        case(ir[30:28])
        `ANDR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR3B:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `EORR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DEPR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_depr <= 1'b1; end
        `EXTR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_extr <= 1'b1; end
        `EXTUR3B: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_extur <= 1'b1; end
        `BLENDR3B: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RGFR3B:  begin illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end

    `SHIFT:
      begin
        Rd <= {2'b0,ir[12:8]};
        Cs <= 2'd0;
        case(ir[27:24])
        `ASL:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `LSR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ROL:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ROR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ASR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ASLX: begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `LSRX: begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ASLI: begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        `LSRI: begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        `ROLI: begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        `RORI: begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        `ASRI: begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        `ASLXI:begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        `LSRXI:begin wrirf <= 1'b1; wrcrf <= ir[31]; dimm <= ir[23:18]; illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end

    `SET:
      begin
        d_set <= 1'b1;
        Cd <= ir[9:8];
        wrcrf <= 1'b1;
        illegal_insn <= 1'b0;
      end
    `SEQ: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SNE: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLT: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGE: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLE: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGT: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLTU: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGEU: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLEU: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGTU: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SAND: begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SOR:  begin d_set <= 1'b1; Cd <= ir[9:8]; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end

    `ADD: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `ADD5:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{59{ir[22]}},ir[22:18]}; wrcrf <= ir[23]; illegal_insn <= 1'b0; dcyc <= 3'd0; end
    `ADD22:begin Rd <= {2'b0,ir[12:8]}; Rs1 <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{41{ir[22]}},ir[22:13],13'd0}; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `ADD2R:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `SUBF:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `MUL,`MULU,`MULSU:
      begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `DIV,`DIVU,`DIVSU:
      begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `REM,`REMU,`REMSU:
      begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
//    `CMP: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; illegal_insn <= 1'b0; end
    `AND: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{1'b1}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `OR:  begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{1'b0}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `OR5: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= ir[22:18]; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `OR2R:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `EOR: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{1'b0}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `ADDISP10: begin Rd <= {2'b0,5'd31}; Rs1 <= {2'b0,5'd31}; wrirf <= 1'b1; dimm <= {{54{ir[14]}},ir[14:8],3'd0}; wrcrf <= ir[15]; illegal_insn <= 1'b0; end
    `BIT: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; illegal_insn <= 1'b0; end
    `BYTNDX: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `WYDNDX: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{48{ir[34]}},ir[34:32],ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `U21NDX: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{43{ir[39]}},ir[39:32],ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `MULFI:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `CHK: begin Rd <= {2'b0,ir[12:8]}; dimm <= {{51{1'b1}},ir[30:18]}; wrcrf <= ir[31]; d_chk <= TRUE; illegal_insn <= 1'b0; end

    `PERM:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `DEP: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; illegal_insn <= 1'b0; d_depi <= ~ir[30]; d_flipi <= ir[30]; wrcrf <= ir[31]; end
    `DEPI:begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; illegal_insn <= 1'b0; d_depii <= TRUE; wrcrf <= ir[31]; end
    `EXT: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; illegal_insn <= 1'b0; d_exti <= ~ir[30]; d_extui <= ir[30]; wrcrf <= ir[31]; end
    `FFO: begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; illegal_insn <= 1'b0; d_ffoi <= ~ir[30]; d_ffor <= ir[30]; wrcrf <= ir[31]; end
    `ADDUI,`ORUI,`AUIIP: begin Rd <= {2'b0,ir[12:8]}; Rs1 <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {ir[63:32],ir[30:13],ir[0],13'd0}; illegal_insn <= 1'b0; end
    `ANDUI: begin Rd <= {2'b0,ir[12:8]}; Rs1 <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= {ir[63:32],ir[30:13],ir[0],{13{1'd1}}}; illegal_insn <= 1'b0; end
    `CSR: if (d_omode >= ir[35:33]) begin Rd <= {2'b0,ir[12:8]}; wrirf <= 1'b1; dimm <= ir[17:13]; illegal_insn <= 1'b0; end
    `ATNI: begin d_atni <= TRUE; illegal_insn <= FALSE; end
    `EXEC: begin d_exec <= TRUE; illegal_insn <= FALSE; end
    // Flow Control
    `JMP:
      begin
        dmod_pc <= ir[9:8] != 2'b10 && dval;
        rad <= 1'b0;
        case(ir[9:8])
        2'b00:  dnext_pc <= {ir[39:10],2'b00};
        2'b01:  dnext_pc <= dpc + {{34{ir[39]}},ir[39:10]};
        2'b10:  ;
        2'b11:  dnext_pc <= dpc + {{34{ir[39]}},ir[39:10]};
        endcase
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
        if (dpc=={dpc[AWID-1:24],ir[31:10],2'b00})
          d_cause <= `FLT_BT;
          //dException(`FLT_BT, dpc);
        d_loop_bust <= TRUE;
      end
    `JAL:
      begin
        // Assume instruction will not crap out and write ra0,ra1 here rather
        // than at WRITEBACK.
        rares <= dpc + dilen;
        wrra <= 1'b1;
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
        if (dpc=={dpc[AWID-1:24],ir[31:10],2'b00})
          d_cause <= `FLT_BT;
          //dException(`FLT_BT, dpc);
        d_loop_bust <= TRUE;
      end
    `JSR:
      begin
        d_jsr <= TRUE;
        dmod_pc <= ir[9:8] != 2'b10 && dval;
        rad <= 1'b0;
        case(ir[9:8])
        2'b00:  dnext_pc <= {ir[39:10],2'b00};
        2'b01:  dnext_pc <= dpc + {{34{ir[39]}},ir[39:10]};
        2'b10:  ;
        2'b11:  dnext_pc <= dpc + {{34{ir[39]}},ir[39:10]};
        endcase
        Rd <= {2'b0,5'd31};
        Rs1 <= {2'b0,5'd31};
        wrirf <= 1'b1;
        d_wha <= TRUE;
        d_loop_bust <= TRUE;
        illegal_insn <= 1'b0;
//        if (dpc=={dpc[AWID-1:24],ir[31:10],2'b00})
//          tException(`FLT_BT, dpc);
      end
    `JSR18:
      begin
        d_jsr <= dval;
        dmod_pc <= dval;
        dnext_pc <= dpc + {{48{ir[23]}},ir[23:8]};
        Rd <= {2'b0,5'd31};
        Rs1 <= {2'b0,5'd31};
        wrirf <= 1'b1;
        d_wha <= TRUE;
        d_loop_bust <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTL:
      begin
        Rd <= {2'b0,5'd31};
        Rs1 <= {2'b0,5'd31};
        wrirf <= 1'b1;
        dimm <= {{50{ir[23]}},ir[23:13],3'b00};
        d_wha <= TRUE;
        d_loop_bust <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTS:
      begin
        d_rts <= dval;
        Rd <= {2'b0,5'd31};
        Rs1 <= {2'b0,5'd31};
        wrirf <= 1'b1;
        wrcrf <= ir[15];
        dimm <= {54'd0,ir[14:8],3'b00};
        d_wha <= TRUE;
        d_loop_bust <= TRUE;
        dmod_pc <= TRUE;
        dnext_pc <= ra_stack_top;
        illegal_insn <= 1'b0;
      end
    `RTX:
      begin
        d_rts <= TRUE;
        Rd <= {3'b0,5'd27};
        Rs1 <= {2'b0,5'd27};
        wrirf <= 1'b1;
        dimm <= 64'd8;
        d_wha <= TRUE;
        d_loop_bust <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTE:
      // Must be at a higher operating mode in order to return to a lower one.
      if (d_omode > 3'd0) begin
        dmod_pc <= dval;
				dnext_pc <= epc;
				d_wha <= TRUE;
        d_loop_bust <= TRUE;
				illegal_insn <= 1'b0;
      end
    `BEQI,`BBC,`BBS:
      begin
        Rd <= {3'b0,ir[12:8]};
        d_cbranch <= TRUE;
        illegal_insn <= 1'b0;
        if (dbrpred & ~is_loop_mode) begin
          dmod_pc <= dval;
          dnext_pc <= dpc + {{52{ir[31]}},ir[31:21]};
          //tLoop(dpc + {{52{ir[31]}},ir[31:21]});
        end
      end
    `BT:
      begin
        d_cbranch <= TRUE;
        illegal_insn <= 1'b0;
        if (dbrpred & ~is_loop_mode) begin
          dmod_pc <= dval;
          dnext_pc <= dpc + {{58{ir[15]}},ir[15:10]};
          //tLoop(dpc + {{58{ir[15]}},ir[15:10]});
        end
      end
    `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,`BLEU,`BGTU,`BOD,`BPS:
      begin
        if (dbrpred & ~is_loop_mode) begin
          dmod_pc <= dval;
          dnext_pc <= dpc + {{51{ir[23]}},ir[23:11]};
          if (ir[10])
            tLoop(dpc + {{51{ir[23]}},ir[23:11]});
        end
        d_cbranch <= TRUE;
        illegal_insn <= 1'b0;
      end
    `BRA:
      begin
        d_bra <= TRUE;
        if (~is_loop_mode) begin
          dmod_pc <= dval;
          dnext_pc <= dpc + {{51{ir[23]}},ir[23:11]};
          if (ir[10])
            tLoop(dpc + {{51{ir[23]}},ir[23:11]});
        end
        illegal_insn <= 1'b0;
      end
    `BEQZ,`BNEZ:
      begin
        if (dbrpred & ~is_loop_mode) begin
          dmod_pc <= dval;
          dnext_pc <= dpc + {{51{ir[23]}},ir[23:11]};
          if (ir[10])
            tLoop(dpc + {{51{ir[23]}},ir[23:11]});
        end
        Rd <= {3'b0,3'b101,ir[9:8]};
        d_cbranch <= TRUE;
        illegal_insn <= 1'b0;
      end
    `NOP: begin illegal_insn <= 1'b0; end
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Memory Ops
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    `LDBS,`LDBUS,`LDWS,`LDWUS,`LDTS,`LDTUS,`LDOS,`LDORS:
      begin
        Rd <= {3'b0,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        wrirf <= 1'b1;
        wrcrf <= ir[23];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `LEAS:
      begin
        Rd <= {3'b0,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        wrirf <= 1'b1;
        wrcrf <= ir[23];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
        d_lea <= TRUE;
      end
    `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDO,`LDOR:
      begin
        Rd <= {3'b0,ir[12:8]};
        wrirf <= 1'b1;
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    /*
    `LDOT:
      begin
        Rd[6:5] <= 2'b11;
        casez(ir[12:8])
        5'b0000?: begin rad <= ir[8]; wrra <= 1'b1; end
        5'b0001?: begin rad <= ir[8]; wrca <= 1'b1; end
        5'b100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
        5'b11101: begin wrcrf32 <= 1'b1; end
        endcase
        d_ld <= TRUE; 
        illegal_insn <= 1'b0;
      end
    */
    `FLDO:
      begin
        Rd <= {3'b01,ir[12:8]};
        wrirf <= 1'b1;
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `FLDOS:
      begin
        Rd <= {2'b01,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        wrirf <= 1'b1;
        wrcrf <= ir[23];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `PLDO:
      begin
        Rd <= {3'b10,ir[12:8]};
        wrirf <= 1'b1;
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `PLDOS:
      begin
        Rd <= {2'b10,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        wrirf <= 1'b1;
        wrcrf <= ir[23];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `LEA:  
      begin
        Rd <= {3'b0,ir[12:8]};
        wrirf <= 1'b1;
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
        d_lea <= TRUE;
      end
`ifdef SUPPORT_MCID      
    `LDM: d_ldm <= TRUE;
    `POP:
      begin
        d_pop <= TRUE;
        case(ir[14:13])
        2'b11:
          casez(ir[12:8])
          5'b0000?: begin rad <= ir[8]; wrra <= 1'b1; end
          5'b0001?: begin rad <= ir[8]; wrca <= 1'b1; end
          5'b100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
          5'b11101: begin wrcrf32 <= 1'b1; end
          endcase
        2'b00:
          begin
            wrirf <= 1'b1;
            wrcrf <= ir[15];
            Rd <= {3'b0,ir[12:8]};
            Rs1 <= {2'b0,5'd31};
          end
        2'b01:
          begin
            wrirf <= 1'b1;
            wrcrf <= ir[15];
            Rd <= {3'b01,ir[12:8]};
            Rs1 <= {2'b0,5'd31};
          end
        2'b10:
          begin
            wrirf <= 1'b1;
            wrcrf <= ir[15];
            Rd <= {3'b10,ir[12:8]};
            Rs1 <= {2'b0,5'd31};
          end
        default:
          begin
            wrirf <= 1'b1;
            wrcrf <= ir[15];
            Rd <= {3'b0,ir[12:8]};
            Rs1 <= {2'b0,5'd31};
          end
        endcase
        dimm <= 64'd0;
        d_ld <= TRUE;
        illegal_insn <= 1'b0;
      end
    `LINK:
      begin
        d_link <= TRUE;
        limm <= {ir[23:8],3'd0};
        Rd <= {3'b0,5'd31}; Rs1 <= {2'b0,5'd31}; dimm <= 64'd8; wrirf <= TRUE; dcyc <= 3'd1;
      end
    `UNLINK:
      begin
        d_unlink <= TRUE;
        Rd <= {3'b0,5'd31}; Rs1 <= {2'b0,5'd30}; wrirf <= TRUE; dcyc <= 3'd1;  // MOV SP,FP
      end
    `STM: d_stm <= TRUE;
`endif      
    `STBS,`STWS,`STTS,`STOS,`STOCS,`STOIS:  
      begin
        Rd <= {2'b0,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `STB,`STW,`STT,`STO,`STOC:  
      begin
        Rd <= {2'b0,ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `STPTR:
      begin
        Rd <= {2'b0,ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
        d_stptr <= TRUE;
      end
    /*
    `STOT:
      begin
        Rd <= {2'b11,ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
        d_stot <= TRUE;
        Cs <= ir[19:18];
      end
    */
    `FSTO:  
      begin
        Rd <= {2'b01,ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `FSTOS:  
      begin
        Rd <= {2'b01,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `PSTO:
      begin
        Rd <= {2'b10,ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `PSTOS:  
      begin
        Rd <= {2'b10,ir[12:8]};
        Rs1 <= {2'b0,5'd30|ir[13]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
`ifdef SUPPORT_MCID      
    `PUSH:
      begin
        Rd <= {2'b0,5'd31};
        Rs1 <= {2'b0,5'd31};
        dimm <= 8'h8;
        dcyc <= 3'd1;
        d_push <= TRUE;
        illegal_insn <= 1'b0;
      end
    `PUSHC:
      begin
        Rd <= {2'b0,5'd31};
        Rs1 <= {2'b0,5'd31};
        dimm <= 8'h8;
        dcyc <= 3'd1;
        d_pushc <= TRUE;
        illegal_insn <= 1'b0;
      end
`endif      
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Floating point ops
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`FMA,`FMS,`FNMA,`FNMS:
			begin
				Rd <= {3'b01,ir[12:8]};
				wrirf <= 1'b1;
				illegal_insn <= FALSE;
			end
		`FLT2:
			begin
				Rd <= {3'b01,ir[12:8]};
				case(fltfunct5)
				5'd20,5'd24,5'd28:
				  begin
				    wrirf <= 1'b1;
				  end
				`FADD,`FSUB,`FMUL,`FDIV:
				  begin
				    wrirf <= TRUE;
				    illegal_insn <= FALSE;
				  end
				`FSEQ,`FSLT,`FSLE,`FCMP:  begin Cd <= ir[9:8]; d_fltcmp <= 1'b1; wrcrf <= 1'b1; illegal_insn <= FALSE; end
				default:
				  begin
            wrirf <= 1'b1;
          end
			  endcase
			end
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Posit ops
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
`ifdef SUPPORT_POSITS    
		`PMA,`PMS,`PNMA,`PNMS:
			begin
				Rd <= {3'b10,ir[12:8]};
				wrirf <= 1'b1;
				illegal_insn <= FALSE;
			end
		`PST2:
			begin
				Rd <= {3'b10,ir[12:8]};
				case(fltfunct5)
				5'd20,5'd24,5'd28:
				  begin
				    wrirf <= 1'b1;
				  end
				`PADD,`PSUB,`PMUL,`PDIV:
				  begin
				    wrirf <= TRUE;
				    illegal_insn <= FALSE;
				  end
				`PSEQ,`PSLT,`PSLE:  begin 
				  illegal_insn <= FALSE;
				  Cd <= ir[9:8]; d_fltcmp <= 1'b1; wrcrf <= 1'b1; end
				default:
				  begin
				    dRdx <= pstreg;
            wrprf <= 1'b1;
          end
			  endcase
			end
`endif			
	  default:  ;
    endcase
  end
DECODE_WAIT:  ;
default: ;
endcase
  if (advance_d) begin
`ifdef SUPPORT_MCID
    if (d_push) begin
      case(dcyc)
      3'd0: begin ir <= {10'd0,1'd1,ir[12:8],`STOS}; dcyc <= 3'd1; end
      3'd1: begin ir <= `NOP; dcyc <= 3'd0; d_st <= FALSE; d_push <= FALSE; end
      default:  ;
      endcase
    end
    else if (d_pushc) begin
      case(dcyc)
      3'd0: begin ir <= {10'd0,1'd1,5'd0,`STOS}; dimm2 <= {{40{ir[31]}},ir[31:8]}; dcyc <= 3'd1; end
      3'd1: begin ir <= `NOP; dcyc <= 3'd0; d_st <= FALSE; d_pushc <= FALSE; end
      default:  ;
      endcase
    end
    else if (d_pop) begin
      case(dcyc)
      3'd0: begin ir <= {5'd8,5'd31,5'd31,`ADD5}; dcyc <= 3'd1; end
      3'd1: begin ir <= `NOP; dcyc <= 3'd0; d_ld <= FALSE; d_pop <= FALSE; end
      endcase
    end
    else if (d_link) begin
      case(dcyc)
      3'd0: begin ir <= {10'd0,1'd1,5'd30,`STOS}; dcyc <= 3'd1; end // STO FP,[$SP]
      3'd1: begin ir <= {5'd0,5'd31,5'd30,`OR2R}; dcyc <= 3'd2; d_st <= FALSE; end // MOV FP,SP
      3'd2:
        begin
          if (limm <= 19'h000FE)
            ir <= {-limm,`ADDISP10};
          else if ({limm,3'b0} <= 19'h00FFE)
            ir <= {-limm[10:0],3'b0,5'd31,5'd31,`ADD};
          else
            illegal_insn <= 1'b1;
          dcyc <= 3'd3;
        end
      3'd3: begin ir <= `NOP; dcyc <= 3'd0; d_link <= FALSE; end
      endcase
    end
    else if (d_unlink) begin
      case(dcyc)
      3'd0: begin ir <= {10'd0,1'd1,5'd30,`LDOS}; dcyc <= 3'd1; end // LDO FP,[SP]
      3'd1: begin ir <= {5'd8,5'd31,5'd31,`ADD5}; dcyc <= 3'd2; d_ld <= FALSE; end // ADD SP,SP,#8
      3'd2: begin ir <= `NOP; dcyc <= 3'd0; d_unlink <= FALSE; end
      default:  dcyc <= 3'd0;
      endcase
    end
    else if (d_ldm) begin
      case(dcyc)
      3'd0: begin
              Rs1t <= ir[17:13];
              Rdt <= 5'd1;
              mask <= {ir[43:18],ir[12:8]};
              S = ir[45:44];
              offset <= 12'd0;
              dcyc <= 3'd1;
            end
      3'd1: begin 
              if (mask == 31'd0) begin
                ir <= `NOP;
                dcyc <= 3'd0;
                d_ldm <= FALSE;
              end
              else begin
                ir <= mask[0] ? {1'b1,offset,Rs1t,Rdt,S==2'b10 ? `PLDO : S==2'b01 ? `FLDO : `LDO} : `NOP;
                mask <= {1'b0,mask[30:1]};
                Rdt <= Rdt + 5'd1;
                offset <= offset + 12'd8;
              end
            end
      default:  dcyc <= 3'd0;
      endcase
    end
    else if (d_stm) begin
      case(dcyc)
      3'd0: begin
              Rs1t <= ir[17:13];
              Rdt <= 5'd1;
              mask <= {ir[43:18],ir[12:8]};
              S = ir[45:44];
              offset <= 12'd0;
              dcyc <= 3'd1;
            end
      3'd1: begin 
              if (mask == 31'd0) begin
                ir <= `NOP;
                d_stm <= FALSE;
                dcyc <= 3'd0;
              end
              else begin
                ir <= mask[0] ? {1'b1,offset,Rs1t,Rdt,S==2'b10 ? `PSTO : S==2'b01 ? `FSTO : `STO} : `NOP;
                mask <= {1'b0,mask[30:1]};
                Rdt <= Rdt + 5'd1;
                offset <= offset + 12'd8;
              end
            end
      default:  dcyc <= 3'd0;
      endcase
    end
`endif
    rval <= dval;
    rimm <= dimm;
    rRs1 <= Rs1;
    rRs2 <= Rs2;
    rRs3 <= Rs3;
    rRd <= Rd;
    rCs <= Cs;
    rCd <= Cd;
    rir <= ir;
    rpc <= dpc;
    rilen <= dilen;
    rwrirf <= wrirf;
    rwrcrf <= wrcrf;
    rwrcrf32 <= wrcrf32;
    rwrra <= wrra;
    rwrca <= wrca;
    rwrsrf <= dwrsrf;
		r_cmp <= d_cmp;
		r_set <= d_set;
		r_tst <= d_tst;
		r_chk <= d_chk;
		r_fltcmp <= d_fltcmp;
    r_ld <= d_ld;
    r_st <= d_st;
    r_stptr <= d_stptr;
    r_pushc <= d_pushc;
    r_atni <= d_atni;
    r_exec <= d_exec;
    rbrpred <= dbrpred;
    r_cbranch <= d_cbranch;
    r_jsr <= d_jsr;
    r_rts <= d_rts;
    r_setkey <= d_setkey;
    r_gcclr <= d_gcclr;
    r_rad <= rad;
    rrares <= rares;
    
    r_exti <= d_exti;
    r_extr <= d_extr;
    r_extui <= d_extui;
    r_extur <= d_extur;
    r_depi <= d_depi;
    r_depr <= d_depr;
    r_depii <= d_depii;
    r_flipi <= d_flipi;
    r_flipr <= d_flipr;
    r_ffoi <= d_ffoi;
    r_ffor <= d_ffor;
    r_loop_bust <= d_loop_bust;
    if (illegal_insn)
      r_cause <= 32'd37;
    else
      r_cause <= d_cause;
    r_omode <= d_omode;

    dmod_pc <= FALSE;
    decode_done <= FALSE;
    atni_done <= FALSE;
    exec_done <= FALSE;
    dgoto (DECODE);
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register fetch stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tRegfetch;
begin
if (rst_i) begin
	rstate <= REGFETCH_WAIT;
	regfetch_done <= TRUE;
  rpc <= RSTPC;
  rmod_pc <= FALSE;
  r_cbranch <= FALSE;
  e_ld <= FALSE;
  e_st <= FALSE;
  e_stptr <= FALSE;
  e_jsr <= FALSE;
  e_rts <= FALSE;
	e_cmp <= FALSE;
	e_set <= FALSE;
	e_tst <= FALSE;
	e_chk <= FALSE;
	e_fltcmp <= FALSE;
  e_cbranch <= FALSE;
  e_exti <= FALSE;
  e_extr <= FALSE;
  e_extui <= FALSE;
  e_extur <= FALSE;
  e_depi <= FALSE;
  e_depr <= FALSE;
  e_depii <= FALSE;
  e_flipi <= FALSE;
  e_flipr <= FALSE;
  e_ffoi <= FALSE;
  e_ffor <= FALSE;
  e_setkey <= FALSE;
  e_gcclr <= FALSE;
  e_atni <= FALSE;
  e_exec <= FALSE;
  ebubble_cnt <= 4'd0;
  e_bubble <= FALSE;
  e_loop_bust <= FALSE;
  e_cause <= 8'h00;
  e_rad <= 1'b0;
	eilen <= 4'd1;
  eRd <= 7'd0;
  ewrsrf <= FALSE;
  cdb <= 8'h00;
end
else
case(rstate)
// Need a state to read Rd from block ram.

REGFETCH1:
  rgoto (REGFETCH2);

REGFETCH2:
  begin
    rmod_pc <= FALSE;
    e_bubble <= FALSE;
    case(ropcode)
    `JAL:
      begin
        rmod_pc <= rval;
        rnext_pc <= {rpc[AWID-1:24],rir[31:10],2'b00} + (rir[9] ? cao : {AWID{1'd0}});
      end
    `JMP,`JSR:
      begin
        rmod_pc <= rval && rir[9:8]==2'b10;
        case(rir[9:8])
        2'b10:  rnext_pc <= {rir[39:10],2'b00} + cao;
        default:  ;
        endcase
      end
    `JSR18:
      begin
        rmod_pc <= rval;
        rnext_pc <= rpc + {{48{rir[23]}},rir[23:8]};
      end
    default:  ;
    endcase
    ret_pc <= rao;
    regfetch_done <= TRUE;
    rgoto (REGFETCH_WAIT);
  end
/*
REGFETCH3:
  begin
    regfetch_done <= TRUE;
    rgoto (REGFETCH_WAIT);
`ifdef SIM    
    $display("RF: irfoRs1:%h Rs1=%d",irfoRs1, Rs1);
`endif
    ret_pc <= rao;
  end
*/
REGFETCH_WAIT:
  // Moved logic outside of case as it does not need to depend on the state. It
  // will use the advance_ signals.
  ;
default:
  begin
    regfetch_done <= TRUE;
    rgoto(REGFETCH_WAIT);
  end
endcase

  if (advance_r) begin
    imm <= rimm;

    if (rRs1[4:0]==5'd0 && rRs1[6:5]!=2'b11)
      ia <= {WID{1'b0}};
    else if (rRs1==eRd && eval && ewrirf)
      ia <= res;
    else if (rRs1==mRd && mval && mwrirf)
      ia <= mres;
    else if (rRs1==wRd && wval && wwrirf)
      ia <= wres;
    else
      ia <= irfoRs1;

    if (rRs2[4:0]==5'd0 && rRs2[6:5]!=2'b11)
      ib <= {WID{1'b0}};
    else if (rRs2==eRd && eval && ewrirf)
      ib <= res;
    else if (rRs2==mRd && mval && mwrirf)
      ib <= mres;
    else if (rRs2==wRd && wval && wwrirf)
      ib <= wres;
    else
      ib <= irfoRs2;

    if (rRs3[4:0]==5'd0 && rRs3[6:5]!=2'b11)
      ic <= {WID{1'b0}};
    else if (rRs3==eRd && eval && ewrirf)
      ic <= res;
    else if (rRs3==mRd && mval && mwrirf)
      ic <= mres;
    else if (rRs3==wRd && wval && wwrirf)
      ic <= wres;
    else
      ic <= irfoRs3;

		/*
    if (r_pushc)
      id <= dimm2;
    else 
    */
    if (r_jsr)
      id <= rpc + rilen;
    else if (rRd[4:0]==5'd0 && rRd[6:5]!=2'b11)
      id <= {WID{1'b0}};
    else if (rRd==eRd && eval && ewrirf)
      id <= res;
    else if (rRd==mRd && mval && mwrirf)
      id <= mres;
    else if (rRd==wRd && wval && wwrirf)
      id <= wres;
    else
    	id <= irfoRd;
    /*
      casez(rRd)
      7'b11_0000?: id <= rao;
      7'b11_0001?: id <= cao;
      7'b11_00111: id <= epc;
      7'b11_100??: id <= cd2;
      7'b11_11101: id <= cds322;
      default:  id <= irfoRd;
      endcase
		*/
    if (rCs==eCd && eval && ewrcrf)
      cdb <= crres;
    else if (rCs==mCd && mval && mwrcrf)
      cdb <= mcrres;
    else if (rCs==wCd && wval && wwrcrf)
      cdb <= wcrres;
    else
      cdb <= cd;

    eval <= rval;
    eir <= rir;
    eilen <= rilen;
    expc <= rpc;
    eRs1 <= rRs1;
    eRs2 <= rRs2;
    eRd <= rRd;
    eCd <= rCd;
    ewrirf <= rwrirf;
    ewrcrf <= rwrcrf;
    ewrcrf32 <= rwrcrf32;
    ewrra <= rwrra;
    ewrca <= rwrca;
		e_cmp <= r_cmp;
		e_set <= r_set;
		e_tst <= r_tst;
		e_chk <= r_chk;
		e_fltcmp <= r_fltcmp;
    e_ld <= r_ld;
    e_st <= r_st;
    e_stptr <= r_stptr;
    e_jsr <= r_jsr;
    e_rts <= r_rts;
    e_atni <= r_atni;
    e_exec <= r_exec;
    e_cbranch <= r_cbranch;
    e_loop_bust <= r_loop_bust;

    e_exti <= r_exti;
    e_extr <= r_extr;
    e_extui <= r_extui;
    e_extur <= r_extur;
    e_depi <= r_depi;
    e_depr <= r_depr;
    e_depii <= r_depii;
    e_flipi <= r_flipi;
    e_flipr <= r_flipr;
    e_ffoi <= r_ffoi;
    e_ffor <= r_ffor;
    e_setkey <= r_setkey;
    e_gcclr <= r_gcclr;
    e_cause <= r_cause;
    e_rad <= r_rad;

    erares <= rrares;
    ewrsrf <= rwrsrf;      
    ebrpred <= rbrpred;
    e_omode <= r_omode;
    rmod_pc <= FALSE;
    regfetch_done <= FALSE;
    rgoto (REGFETCH1);
  end
  else if (advance_e) begin
    eval <= FALSE;
    ebubble_cnt <= ebubble_cnt + 1'b1;
    e_bubble <= TRUE;
    eilen <= eilen;
    expc <= expc;
    eir <= `NOP;
    ia <= 64'd0;
    ib <= 64'd0;
    ic <= 64'd0;
    id <= 64'd0;
    cdb <= 8'd0; 
    eRs1 <= 7'd0;
    eRs2 <= 7'd0;
    eRd <= 7'd0;
    eCd <= 2'b00;
    ewrirf <= FALSE;
    ewrcrf <= FALSE;
    ewrcrf32 <= FALSE;
    ewrra <= FALSE;
    ewrca <= FALSE;
		e_cmp <= FALSE;
		e_set <= FALSE;
		e_tst <= FALSE;
		e_fltcmp <= FALSE;
    e_ld <= FALSE;
    e_st <= FALSE;
    e_stptr <= FALSE;
    e_jsr <= FALSE;
    e_rts <= FALSE;
    e_cbranch <= FALSE;
    e_exti <= FALSE;
    e_extr <= FALSE;
    e_extui <= FALSE;
    e_extur <= FALSE;
    e_depi <= FALSE;
    e_depr <= FALSE;
    e_depii <= FALSE;
    e_flipi <= FALSE;
    e_flipr <= FALSE;
    e_ffoi <= FALSE;
    e_ffor <= FALSE;
    e_setkey <= FALSE;
    e_gcclr <= FALSE;
    e_atni <= FALSE;
    e_exec <= FALSE;
    e_rad <= 1'b0;
    e_omode <= r_omode;
    ewrsrf <= FALSE;
    ebrpred <= 1'b0;
    enext_pc <= rnext_pc;
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tExecute;
begin
if (rst_i) begin
	estate <= EXECUTE_WAIT;
	execute_done <= TRUE;
  expc <= RSTPC;
  e_cbranch <= FALSE;
  emod_pc <= FALSE;
  mRd <= 8'd0;
  m_bubble <= FALSE;
  m_loop_bust <= FALSE;
  m_setkey <= FALSE;
  m_gcclr <= FALSE;
  m_stptr <= FALSE;
  m_cause <= 8'h00;
  m_rad <= 1'b0;
	milen <= 4'd1;
	mwrsrf <= FALSE;
  res <= 64'd0;
  rares <= {AWID{1'b0}};
  crres <= 8'h00;
end
else
case(estate)
EXECUTE:
  begin
	  egoto(EXECUTE_CRRES);
    res <= 64'd0;
    crres <= cdb;
    emod_pc <= FALSE;
    // Only the cases that modify estate are included here. Other cases that
    // generate results not depending on estate are included below.
    casez(eopcode)
    `R2:
      case(efunct5)
      `MULR2: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
      `MULUR2: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
      `MULSUR2: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
      `MULHR2: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
      `MULUHR2: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
      `MULSUHR2: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
      `DIVR2: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd160; end
      `DIVUR2: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd160; end
      `DIVSUR2: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd160; end
      `REMR2: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd164; end
      `REMUR2: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd164; end
      `REMSUR2: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd164; end
      `R1:
        case(eir[22:18])
        `CNTPOPR1:begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd03; end
        default:  ;                                    
        endcase
      default:  ;
      endcase
    `R3A:
      case(eir[30:28])
      `FLIPR3A:  begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end //res <= bfo;
      default:  ;
      endcase
    `R3B:
    	case(eir[30:28])
      `EXTR3B: begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end
      `EXTUR3B:  begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end
      `DEPR3B: begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end
      default:  ;
      endcase
    `MUL: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
    `MULU: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
    `MULSU: begin execute_done <= FALSE; egoto (MUL2); mathCnt <= 8'd07; end
    `DIV: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd160; end
    `DIVU: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd160; end
    `DIVSU: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd160; end
    `REM: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd164; end
    `REMU: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd164; end
    `REMSU: begin execute_done <= FALSE; egoto (MUL1); mathCnt <= 8'd164; end

    // Bitfield
    `EXT: begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end
    `DEP: begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end
    `DEPI:  begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end
    `FFO: begin execute_done <= FALSE; mathCnt <= 8'd08; estate <= FLOAT; end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    `OSR2:
      case(efunct5)
      `MVMAP: begin mathCnt <= 8'd2; egoto (PAGEMAPA); end
      `TLBRW: begin tlben <= 1'b1; tlbwr <= ia[63]; mathCnt <= 8'd2; egoto (PAGEMAPA); end
      default:  ;
      endcase

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		`FMA,`FMS,`FNMA,`FNMS:
			begin execute_done <= FALSE; mathCnt <= 45; egoto(FLOAT); end
		// The timeouts for the float operations are set conservatively. They may
		// be adjusted to lower values closer to actual time required.
		`FLT2:	// Float
			case(efltfunct5)
			`FLT1:
			  case(eRs2[4:0])
  	    `FMOV:  begin execute_done <= FALSE; mathCnt <= 8'd00; egoto(FLOAT); end	// FMOV
  	    `FTOI:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end
  	    `ITOF:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end
  	    `FS2D:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end
  	    `FD2S:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end
				`CPYSGN:  begin res <= {ib[FPWID-1],ia[FPWID-1:0]}; end
				`SGNINV:  begin res <= {~ib[FPWID-1],ia[FPWID-1:0]}; end
				`SGNAND:  begin res <= {ib[FPWID-1]&ia[FPWID-1],ia[FPWID-1:0]}; end
				`SGNOR:   begin res <= {ib[FPWID-1]|ia[FPWID-1],ia[FPWID-1:0]}; end
				`SGNEOR:  begin res <= {ib[FPWID-1]^ia[FPWID-1],ia[FPWID-1:0]}; end
				`SGNENOR: begin res <= {~(ib[FPWID-1]^ia[FPWID-1]),ia[FPWID-1:0]}; end
  	    `FCLASS:
						begin
							res[0] <= ia[FPWID-1] & fa_inf;
							res[1] <= ia[FPWID-1] & !fa_xz;
							res[2] <= ia[FPWID-1] &  fa_xz;
							res[3] <= ia[FPWID-1] &  fa_vz;
							res[4] <= ~ia[FPWID-1] &  fa_vz;
							res[5] <= ~ia[FPWID-1] &  fa_xz;
							res[6] <= ~ia[FPWID-1] & !fa_xz;
							res[7] <= ~ia[FPWID-1] & fa_inf;
							res[8] <= fa_snan;
							res[9] <= fa_qnan;
						end
        default: ;
			  endcase
			`FADD:	begin execute_done <= FALSE; mathCnt <= 8'd30; egoto(FLOAT); end	// FADD
			`FSUB:	begin execute_done <= FALSE; mathCnt <= 8'd30; egoto(FLOAT); end	// FSUB
			`FMUL:	begin execute_done <= FALSE; mathCnt <= 8'd30; egoto(FLOAT); end	// FMUL
			`FDIV:	begin execute_done <= FALSE; mathCnt <= 8'd40; egoto(FLOAT); end	// FDIV
			`FCMP:	begin execute_done <= FALSE; mathCnt <= 8'd40; egoto(FLOAT); end	// FDIV
			`FSQRT:	begin execute_done <= FALSE; mathCnt <= 8'd160; egoto(FLOAT); end	// FSQRT
			`FSLE:	begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// FSLE
		  `FSLT:	begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// FSLT
			`FSEQ:	begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// FSEQ
  	  `FMIN:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// FMIN / FMAX
  	  `FMAX:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// FMIN / FMAX
			default:	;
			endcase
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`ifdef SUPPORT_POSITS    
		`PST2:	// Posit
			case(efltfunct5)
			`PST1:
			  case(eRs2[4:0])
  	    `PTOI:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end
  	    `ITOP:  begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end
//			`PST1:
        default:  ;
			  endcase
			`PADD:	begin execute_done <= FALSE; mathCnt <= 8'd07; egoto(FLOAT); end	// PADD
			`PSUB:	begin execute_done <= FALSE; mathCnt <= 8'd07; egoto(FLOAT); end	// PSUB
			`PMUL:	begin execute_done <= FALSE; mathCnt <= 8'd15; egoto(FLOAT); end	// PMUL
			`PDIV:	begin execute_done <= FALSE; mathCnt <= 8'd21; egoto(FLOAT); end	// PDIV
			`PSLE:	begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// PSLE
		  `PSLT:	begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// PSLT
			`PSEQ:	begin execute_done <= FALSE; mathCnt <= 8'd03; egoto(FLOAT); end	// PSEQ
  	  `PMIN:  begin execute_done <= FALSE; mathCnt <= 8'd01; egoto(FLOAT); end	// PMIN / PMAX
  	  `PMAX:  begin execute_done <= FALSE; mathCnt <= 8'd01; egoto(FLOAT); end	// PMIN / PMAX
			default:	;
			endcase
`endif			
		default:  ;
    endcase
    if (!eval) begin
      emod_pc <= FALSE;
		  egoto(EXECUTE_CRRES);
    end
  end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Adjust for sign
MUL1:
	begin
		ldd <= 1'b1;
    egoto (MUL2);
		case(eopcode)
		`R2,`R2B:
	    case(eir[30:26])
	    `DIVR2,`REMR2:
  		  begin
  				sgn <= ia[WID-1] ^ ib[WID-1];	// compute output sign
  				if (ia[WID-1]) ia <= -ia;			// Make both values positive
  				if (ib[WID-1]) ib <= -ib;
  		  end
  	  default:  ;
	    endcase
		`DIV,`REM:
		  begin
				sgn <= ia[WID-1] ^ imm[WID-1];	// compute output sign
				if (ia[WID-1]) ia <= -ia;			// Make both values positive
				if (ib[WID-1]) ib <= -imm; else ib <= imm;
		  end
		`DIVU,`REMU:
		  ib <= imm;
		default:  ;
	  endcase
	end
// Capture result
MUL2:
	begin
		mathCnt <= mathCnt - 8'd1;
		if (mathCnt==8'd0) begin
		  egoto(EXECUTE_CRRES);
			case(eopcode)
			`R1:
			  case(eir[22:18])
        `CNTPOPR1:  res <= cntpopo;
        default:  ;
        endcase
			`R2,`R2B:
			  case(eir[30:26])
        `MULR2: res <= prods6[WID-1:0];
        `MULUR2: res <= produ6[WID-1:0];
        `MULSUR2: res <= prodsu6[WID-1:0];
        `MULHR2: res <= prods6[WID*2-1:WID];
        `MULUHR2: res <= produ6[WID*2-1:WID];
        `MULSUHR2: res <= prodsu6[WID*2-1:WID];
			  `DIVR2:   res <= sdiv_q[WID*2-1:WID];
			  `DIVUR2:  res <= div_q[WID*2-1:WID];
			  `DIVSUR2: res <= sdiv_q[WID*2-1:WID];
			  `REMR2:   res <= sdiv_r;
			  `REMUR2:  res <= div_r;
			  `REMSUR2: res <= sdiv_r;
			  default:  ;
			  endcase
			`MUL:  res <= prods6[WID-1:0];
			`MULU: res <= produ6[WID-1:0];
			`MULSU: res <= prodsu6[WID-1:0];
			`DIV:  res <= sdiv_q[WID*2-1:WID];
			`DIVU: res <= div_q[WID*2-1:WID];
			`DIVSU:res <= sdiv_q[WID*2-1:WID];
			`REM:  res <= sdiv_r;
			`REMU: res <= div_r;
			`REMSU:res <= sdiv_r;
			default:  ;
		  endcase
		end
	end
PAGEMAPA:
  begin
    tlbwr <= 1'b0;
    mathCnt <= mathCnt - 2'd1;
    if (mathCnt==8'd0) begin
      case(efunct5)
      `MVMAP: res <= {50'd0,pagemapoa}; 
      `TLBRW: begin tlben <= 1'b0; res <= tlbdato; end
      default:  ;
      endcase
		  egoto(EXECUTE_CRRES);
    end
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
			case(eopcode)
			// Bitfield ops
			`R3A:
			  case(eir[30:28])
			  `FLIPR3A: res <= bfo;
			  default:  ;
			  endcase
			`R3B:
			  case(eir[30:28])
        `EXTR3B: res <= bfo;
        `EXTUR3B:  res <= bfo;
        `DEPR3B: res <= bfo;
			  default:  ;
			  endcase
      `EXT: res <= bfo;
      `DEP: res <= bfo;
      `DEPI:  res <= bfo;
      `FFO: res <= bfo;

			`FMA,`FMS,`FNMA,`FNMS:
				begin
					res <= fres;
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			`FLT2:
				case(efltfunct5)
				`FADD:
					begin
						res <= fres;	// FADD
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FSUB:
					begin
						res <= fres;	// FSUB
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FMUL:
					begin
						res <= fres;	// FMUL
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FDIV:	
					begin
						res <= fres;	// FDIV
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (ib[FPWID-2:0]==1'd0)
							fdz <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FMIN:	// FMIN	
					if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
						res <= 32'h7FFFFFFF;	// canonical NaN
					else if (fa_qnan & !fb_nan)
						res <= ib;
					else if (!fa_nan & fb_qnan)
						res <= ia;
					else if (fcmp_o[1])
						res <= ia;
					else
						res <= ib;
				`FMAX:	// FMAX
					if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
						res <= 32'h7FFFFFFF;	// canonical NaN
					else if (fa_qnan & !fb_nan)
						res <= ib;
					else if (!fa_nan & fb_qnan)
						res <= ia;
					else if (fcmp_o[1])
						res <= ib;
					else
						res <= ia;
			  `FCMP:
			    begin
			      case(mop)
			      `CMP_CPY:
			        begin
    			      crres[0] <= 1'b0;
    			      crres[1] <= fcmp_o[0] & ~cmpnan;
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_AND:
			        begin
    			      crres[0] <= 1'b0;
    			      crres[1] <= cdb[1] & fcmp_o[0] & ~cmpnan;
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & finf;
    			      crres[7] <= cdb[7] & fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_OR:
			        begin
    			      crres[0] <= cdb[0];
    			      crres[1] <= cdb[1] | (fcmp_o[0] & ~cmpnan);
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | finf;
    			      crres[7] <= cdb[7] | (fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ANDCM:
			        begin
    			      crres[0] <= cdb[0];
    			      crres[1] <= cdb[1] & ~(fcmp_o[0] & ~cmpnan);
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~finf;
    			      crres[7] <= cdb[7] & ~(fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ORCM:
			        begin
    			      crres[0] <= cdb[0];
    			      crres[1] <= cdb[1] | ~(fcmp_o[0] & ~cmpnan);
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~finf;
    			      crres[7] <= cdb[7] | ~(fcmp_o[1] & ~cmpnan);
			        end
			      default:  crres <= cd;
			      endcase
			    end
				`FSLE:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= fcmp_o[2] & ~cmpnan;	// FSLE
    						crres[1] <= fcmp_o[2] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_AND:
					    begin
    						crres[0] <= cdb[0] & fcmp_o[2] & ~cmpnan;	// FSLE
    						crres[1] <= cdb[1] & fcmp_o[2] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & finf;
    			      crres[7] <= cdb[7] & fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_OR:
					    begin
    						crres[0] <= cdb[0] | (fcmp_o[2] & ~cmpnan);	// FSLE
    						crres[1] <= cdb[1] | (fcmp_o[2] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | finf;
    			      crres[7] <= cdb[7] | (fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ANDCM:
					    begin
    						crres[0] <= cdb[0] & ~(fcmp_o[2] & ~cmpnan);	// FSLE
    						crres[1] <= cdb[1] & ~(fcmp_o[2] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~finf;
    			      crres[7] <= cdb[7] & ~(fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ORCM:
					    begin
    						crres[0] <= cdb[0] | ~(fcmp_o[2] & ~cmpnan);	// FSLE
    						crres[1] <= cdb[1] | ~(fcmp_o[2] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~finf;
    			      crres[7] <= cdb[7] | ~(fcmp_o[1] & ~cmpnan);
					    end
			      default:  crres <= cdb;
					  endcase
						if (cmpnan)
							fnv <= 1'b1;
					end
			  `FSLT:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= fcmp_o[1] & ~cmpnan;	// FSLE
    						crres[1] <= fcmp_o[1] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_AND:
					    begin
    						crres[0] <= cdb[0] & fcmp_o[1] & ~cmpnan;	// FSLE
    						crres[1] <= cdb[1] & fcmp_o[1] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & finf;
    			      crres[7] <= cdb[7] & fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_OR:
					    begin
    						crres[0] <= cdb[0] | (fcmp_o[1] & ~cmpnan);	// FSLE
    						crres[1] <= cdb[1] | (fcmp_o[1] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | finf;
    			      crres[7] <= cdb[7] | (fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ANDCM:
					    begin
    						crres[0] <= cdb[0] & ~(fcmp_o[1] & ~cmpnan);	// FSLE
    						crres[1] <= cdb[1] & ~(fcmp_o[1] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~finf;
    			      crres[7] <= cdb[7] & ~(fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ORCM:
					    begin
    						crres[0] <= cdb[0] | ~(fcmp_o[1] & ~cmpnan);	// FSLE
    						crres[1] <= cdb[1] | ~(fcmp_o[1] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~finf;
    			      crres[7] <= cdb[7] | ~(fcmp_o[1] & ~cmpnan);
					    end
			      default:  crres <= cd;
					  endcase
						if (cmpnan)
							fnv <= 1'b1;
					end
				`FSEQ:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= fcmp_o[0] & ~cmpnan;	// FSEQ
    						crres[1] <= fcmp_o[0] & ~cmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_AND:
			        begin
    						crres[0] <= cdb[0] & fcmp_o[0] & ~cmpnan;	// FSEQ
    						crres[1] <= cdb[1] & fcmp_o[0] & ~cmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & finf;
    			      crres[7] <= cdb[7] & fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_OR:
			        begin
    						crres[0] <= cdb[0] | (fcmp_o[0] & ~cmpnan);	// FSEQ
    						crres[1] <= cdb[1] | (fcmp_o[0] & ~cmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | finf;
    			      crres[7] <= cdb[7] | (fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ANDCM:
			        begin
    						crres[0] <= cdb[0] & ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    						crres[1] <= cdb[1] & ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~finf;
    			      crres[7] <= cdb[7] & ~(fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ORCM:
			        begin
    						crres[0] <= cdb[0] | ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    						crres[1] <= cdb[1] | ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~finf;
    			      crres[7] <= cdb[7] | ~(fcmp_o[1] & ~cmpnan);
			        end
			      default:  crres <= cdb;
			      endcase
						if (cmpsnan)
							fnv <= 1'b1;
					end
				`FLT1:
				  case(eRs2[4:0])
					`FSQRT:
  					begin
  						res <= fres;	// FSQRT
  						if (fdn) fuf <= 1'b1;
  						if (finf) fof <= 1'b1;
  						if (ia[FPWID-2:0]==1'd0)
  							fdz <= 1'b1;
  						if (sqrinf|sqrneg)
  							fnv <= 1'b1;
  						if (norm_nx) fnx <= 1'b1;
  					end
				  `FTOI:	res <= ftoi_res;	// FCVT.W.S
				  `ITOF:	res <= itof_res;	// FCVT.S.W
  				default:	;
  				endcase // FLT1
  			default:  ;
  		  endcase   // FLT2
			`PST2:
				case(efltfunct5)
				`PST1:
				  case(eRs2[4:0])
				  `ITOP:  res <= itop_o;
				  `PTOI:  res <= ptoi_o;
				  default:  ;
				  endcase
				`PMIN:  res <= $signed(ia) < $signed(ib) ? ia : ib;
				`PMAX:  res <= $signed(ia) > $signed(ib) ? ia : ib;
				`PADD,`PSUB:
					begin
						res <= pas_o;	// FADD
						//if (fdn) fuf <= 1'b1;
						//if (finf) fof <= 1'b1;
						//if (norm_nx) fnx <= 1'b1;
					end
			  `PMUL:
			    begin
			      res <= pmul_o;
			    end
			  `PDIV:
			    begin
			      res <= pdiv_o;
			    end
				`PSEQ:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= pseq_o & ~pcmpnan;	// PSEQ
    						crres[1] <= pseq_o & ~pcmpnan;	// PSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= pinf_o;
    			      crres[7] <= 1'b0;
			        end
			      `CMP_AND:
			        begin
    						crres[0] <= cdb[0] & pseq_o & ~pcmpnan;	// FSEQ
    						crres[1] <= cdb[1] & pseq_o & ~pcmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_OR:
			        begin
    						crres[0] <= cdb[0] | (pseq_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] | (pseq_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_ANDCM:
			        begin
    						crres[0] <= cdb[0] & ~(pseq_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] & ~(pseq_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_ORCM:
			        begin
    						crres[0] <= cdb[0] | ~(pseq_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] | ~(pseq_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      default:  crres <= cdb;
			      endcase
			    end
				`PSLT:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= pslt_o & ~pcmpnan;	// PSEQ
    						crres[1] <= pslt_o & ~pcmpnan;	// PSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= pinf_o;
    			      crres[7] <= 1'b0;
			        end
			      `CMP_AND:
			        begin
    						crres[0] <= cdb[0] & pslt_o & ~pcmpnan;	// FSEQ
    						crres[1] <= cdb[1] & pslt_o & ~pcmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_OR:
			        begin
    						crres[0] <= cdb[0] | (pslt_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] | (pslt_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_ANDCM:
			        begin
    						crres[0] <= cdb[0] & ~(pslt_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] & ~(pslt_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_ORCM:
			        begin
    						crres[0] <= cdb[0] | ~(pslt_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] | ~(pslt_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      default:  crres <= cdb;
			      endcase
			    end
				`PSLE:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= psle_o & ~pcmpnan;	// PSEQ
    						crres[1] <= psle_o & ~pcmpnan;	// PSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= pinf_o;
    			      crres[7] <= 1'b0;
			        end
			      `CMP_AND:
			        begin
    						crres[0] <= cdb[0] & psle_o & ~pcmpnan;	// FSEQ
    						crres[1] <= cdb[1] & psle_o & ~pcmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cdb[6] & pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_OR:
			        begin
    						crres[0] <= cdb[0] | (psle_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] | (psle_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_ANDCM:
			        begin
    						crres[0] <= cdb[0] & ~(psle_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] & ~(psle_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] & ~pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      `CMP_ORCM:
			        begin
    						crres[0] <= cdb[0] | ~(psle_o & ~pcmpnan);	// FSEQ
    						crres[1] <= cdb[1] | ~(psle_o & ~pcmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cdb[4];
    			      crres[5] <= cdb[5];
    			      crres[6] <= cdb[6] | ~pinf_o;
    			      crres[7] <= cdb[7];
			        end
			      default:  crres <= cdb;
			      endcase
			    end
  			default:  ;
  		  endcase   // FLT2
			default:	;
			endcase     // opcode
	    egoto(EXECUTE_CRRES);
		end
	end
EXECUTE_CRRES:
  begin
    if (~e_cmp & ~e_set & ~e_tst & ~e_chk & ~e_fltcmp & ewrcrf) begin
      crres[0] <= res[64];
      crres[1] <= res[63:0]==64'd0;
      crres[2] <= 1'b0;
      crres[3] <= 1'b0;
      crres[4] <= ^res[63:0];
      crres[5] <= res[0];
      crres[6] <= res[64]^res[63];
      crres[7] <= res[63];
    end
    execute_done <= TRUE;
    adv_ex();
  end
EXECUTE_WAIT: ;
endcase

  // Results that don't depend on estate
if (estate==EXECUTE)
  casez(eopcode)
  `DBG: e_cause <= `FLT_DBG;
	`BRK:
	  case(eir[15:8])
	  8'd3: e_cause <= eir[15:8]; //eException(eir[15:8], expc);
	  8'd8: e_cause <= eir[15:8] + pmStack[3:1];  //eException(eir[15:8]+pmStack[3:1], expc);
	  default:  e_cause <= eir[15:8];//eException(eir[15:8], expc);
	  endcase
  `R2:
    case(efunct5)
    `ANDR2: res <= ia & ib;
    `ORR2:  res <= ia | ib;
    `EORR2: res <= ia ^ ib;
    `NANDR2:res <= ~(ia & ib);
    `NORR2: res <= ~(ia | ib);
    `ENORR2:res <= ~(ia ^ ib);
    `ADDR2: 
      case(eir[25:23])
      3'd0: res <= ia + ib;
      3'd1: res <= {id[63:32],ia[31:0]+ib[31:0]};
      3'd2: res <= {id[63:16],ia[15:0]+ib[15:0]};
      3'd3: res <= {id[63: 8],ia[ 7:0]+ib[ 7:0]};
      3'd5: res <= {ia[63:32]+ib[63:32],ia[31:0]+ib[31:0]};
      3'd6: res <= {ia[63:48]+ib[63:48],ia[47:32]+ib[47:32],ia[31:16]+ib[31:16],ia[15:0]+ib[15:0]};
      3'd7: res <= {ia[63:56]+ib[63:56],ia[55:48]+ib[55:48],ia[47:40]+ib[47:40],ia[39:32]+ib[39:32],ia[31:24]+ib[31:24],ia[23:16]+ib[23:16],ia[15:8]+ib[15:8],ia[7:0]+ib[7:0]};
      default: res <= ia + ib;
      endcase
    `SUBR2:
      case(eir[25:23])
      3'd0: res <= ia - ib;
      3'd1: res <= {id[63:32],ia[31:0]-ib[31:0]};
      3'd2: res <= {id[63:16],ia[15:0]-ib[15:0]};
      3'd3: res <= {id[63: 8],ia[ 7:0]-ib[ 7:0]};
      3'd5: res <= {ia[63:32]-ib[63:32],ia[31:0]-ib[31:0]};
      3'd6: res <= {ia[63:48]-ib[63:48],ia[47:32]-ib[47:32],ia[31:16]-ib[31:16],ia[15:0]-ib[15:0]};
      3'd7: res <= {ia[63:56]-ib[63:56],ia[55:48]-ib[55:48],ia[47:40]-ib[47:40],ia[39:32]-ib[39:32],ia[31:24]-ib[31:24],ia[23:16]-ib[23:16],ia[15:8]-ib[15:8],ia[7:0]-ib[7:0]};
      default: res <= ia - ib;
      endcase
    `PERMR2:
      begin
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
        res <= (ia < ib ? ib - ia : ia - ib) >> ir[24:23];
      end
    `DIFR2:
      begin
        res <= $signed(ia) < $signed(ib) ? ib - ia : ia - ib;
      end
    `BYTNDX2:
      begin
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
    `WYDNDX2:
      begin
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
    `U21NDXR2:
      begin
        if (ia[20:0]==ib[20:0])
          res <= 64'd0;
        else if (ia[41:21]==ib[20:0])
          res <= 64'd1;
        else if (ia[62:42]==ib[20:0])
          res <= 64'd2;
        else
          res <= {64{1'b1}};  // -1
      end
    `MULF:  res <= ia[23:0] * ib[15:0];
    `MOV:
      begin
        case(eir[21:20])
        2'b00:  begin res <= ia; erares <= ia; end
        2'b01:  begin res <= ia; erares <= ia; end
        2'b10:  begin res <= ia; erares <= ia; end
        2'b11:
          casez(eRs1[4:0])
          5'b0000?: begin res <= ret_pc; erares <= ret_pc; end
          5'b0001?: begin res <= cao; erares <= cao; end
          5'b00111: begin res <= epc; end
          5'b100??: begin res <= cds; erares <= cds; end
          5'b11101: begin res <= cds32; erares <= cds32; end
          default:  ;
          endcase
        endcase
      end
    `R1:
      case(eir[22:18])
      `CNTLZR1: res <= cntlzo;
      `CNTLOR1: res <= cntloo;
      `COMR1: res <= r1_res;   
      `NOTR1: res <= r1_res;
      `NEGR1: res <= r1_res;
      `TST1:  crres <= r1_crres;
      `PTRINC:  res <= r1_res;
      default:  ;                                    
      endcase
    default:  ;
    endcase
  `R2B:
    case(efunct5)
    `CHKR2B:
      begin
        if (ewrcrf)
          crres <= 8'hF3;
        if (id < ia || id >= ib) begin
          if (ewrcrf)
            crres <= 8'h00;
          else
            e_cause <= `FLT_CHK;
        end
      end
    default:  ;
    endcase
  `R3A:
    case(eir[30:28])
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
    default:  ;
    endcase
  `R3B:
  	case(eir[30:28])
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
    default:  ;
    endcase
  `ADD:   res <= ia + imm;
  `ADD5:  res <= ia + imm;
  `ADD22: res <= ia + imm;
  `ADDISP10: res <= ia + imm;
  `ADD2R: res <= ia + ib;
  `SUBF: res <= imm - ia;

  `SHIFT: res <= shft_o;

  `SET:
    begin
      case(eir[30:28])
      `SEQR2:
        case(eir[25:23])
        3'd0: setcr(ia==ib);
        3'd1: setcr(ia[31:0]==ib[31:0]);
        3'd2: setcr(ia[15:0]==ib[15:0]);
        3'd3: setcr(ia[7:0]==ib[7:0]);
        default:  setcr(ia==ib);
        endcase
      `SNER2:
        case(eir[25:23])
        3'd0: setcr(ia!=ib);
        3'd1: setcr(ia[31:0]!=ib[31:0]);
        3'd2: setcr(ia[15:0]!=ib[15:0]);
        3'd3: setcr(ia[7:0]!=ib[7:0]);
        default:  setcr(ia!=ib);
        endcase
      `SLTR2: 
        case(eir[25:23])
        3'd0: setcr($signed(ia) < $signed(ib));
        3'd1: setcr($signed(ia[31:0]) < $signed(ib[31:0]));
        3'd2: setcr($signed(ia[15:0]) < $signed(ib[15:0]));
        3'd3: setcr($signed(ia[7:0]) < $signed(ib[7:0]));
        default:  setcr($signed(ia) < $signed(ib));
        endcase
      `SGER2:
        case(eir[25:23])
        3'd0: setcr($signed(ia) >= $signed(ib));
        3'd1: setcr($signed(ia[31:0]) >= $signed(ib[31:0]));
        3'd2: setcr($signed(ia[15:0]) >= $signed(ib[15:0]));
        3'd3: setcr($signed(ia[7:0]) >= $signed(ib[7:0]));
        default:  setcr($signed(ia) >= $signed(ib));
        endcase
      `SLTUR2:
        case(eir[25:23])
        3'd0: setcr(ia <  ib);
        3'd1: setcr(ia[31:0] <  ib[31:0]);
        3'd2: setcr(ia[15:0] <  ib[15:0]);
        3'd3: setcr(ia[7:0] <  ib[7:0]);
        default:  setcr(ia <  ib);
        endcase
      `SGEUR2:
        case(eir[25:23])
        3'd0: setcr(ia >=  ib);
        3'd1: setcr(ia[31:0] >=  ib[31:0]);
        3'd2: setcr(ia[15:0] >=  ib[15:0]);
        3'd3: setcr(ia[7:0] >=  ib[7:0]);
        default:  setcr(ia >=  ib);
        endcase
      `SANDR2:
        case(eir[25:23])
        3'd0:  setcr(ia!=64'd0 && ib != 64'd0);
        3'd1:  setcr(ia[31:0]!=32'd0 && ib[31:0] != 32'd0);
        3'd2:  setcr(ia[15:0]!=16'd0 && ib[15:0] != 16'd0);
        3'd3:  setcr(ia[7:0]!=8'd0 && ib[7:0] != 8'd0);
        default:  setcr(ia!=64'd0 && ib != 64'd0);
        endcase
      `SORR2:
        case(eir[25:23])
        3'd0: setcr(ia!=64'd0 || ib != 64'd0);
        3'd1: setcr(ia[31:0]!=32'd0 || ib[31:0] != 32'd0);
        3'd2: setcr(ia[15:0]!=16'd0 || ib[15:0] != 16'd0);
        3'd3: setcr(ia[7:0]!=8'd0 || ib[7:0] != 8'd0);
        default: setcr(ia!=64'd0 || ib != 64'd0);
        endcase
      default:  ;
      endcase
    end
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
  `SAND: setcr(ia != 64'd0 && imm != 64'd0);
  `SOR: setcr(ia != 64'd0 || imm != 64'd0);

  `AND: res <= ia & imm;
  `OR:  res <= ia | imm;
  `OR5: res <= ia | imm;
  `OR2R:  res <= ia | ib;
  `EOR: res <= ia ^ imm;
  `PERM:
    begin
      res[ 7: 0] <= ia >> {eir[20:18],3'b0};
      res[15: 8] <= ia >> {eir[23:21],3'b0};
      res[23:16] <= ia >> {eir[26:24],3'b0};
      res[31:24] <= ia >> {eir[29:27],3'b0};
      res[39:32] <= ia >> {eir[34:32],eir[30],3'b0};
      res[47:40] <= ia >> {eir[38:35],3'b0};
      res[55:48] <= ia >> {eir[42:39],3'b0};
      res[63:56] <= ia >> {eir[46:43],3'b0};
    end
  `BYTNDX:
    begin
      if (ia[7:0]==imm[7:0])
        res <= 64'd0;
      else if (ia[15:8]==imm[7:0])
        res <= 64'd1;
      else if (ia[23:16]==imm[7:0])
        res <= 64'd2;
      else if (ia[31:24]==imm[7:0])
        res <= 64'd3;
      else if (ia[39:32]==imm[7:0])
        res <= 64'd4;
      else if (ia[47:40]==imm[7:0])
        res <= 64'd5;
      else if (ia[55:40]==imm[7:0])
        res <= 64'd6;
      else if (ia[63:56]==imm[7:0])
        res <= 64'd7;
      else
        res <= {64{1'b1}};  // -1
    end
  `WYDNDX:
    begin
      if (ia[15:0]==imm[15:0])
        res <= 64'd0;
      else if (ia[31:16]==imm[15:0])
        res <= 64'd1;
      else if (ia[47:32]==imm[15:0])
        res <= 64'd2;
      else if (ia[63:48]==imm[15:0])
        res <= 64'd3;
      else
        res <= {64{1'b1}};  // -1
    end
  `U21NDX:
    begin
      if (ia[20:0]==imm[20:0])
        res <= 64'd0;
      else if (ia[41:21]==imm[20:0])
        res <= 64'd1;
      else if (ia[62:42]==imm[20:0])
        res <= 64'd2;
      else
        res <= {64{1'b1}};  // -1
    end
  `MULFI:  res <= ia[23:0] * imm[15:0];
  `CHK:
    begin
      if (ewrcrf)
        crres <= 8'hF3;
      if (id < ia || id >= imm) begin
        if (ewrcrf)
          crres <= 8'h00;
        else
          e_cause <= `FLT_CHK;
      end
        //eException(32'h00000027, expc);
    end
  `ADDUI: 
    begin
      $display("ADDUI: %h=%h+%h", ia+imm,ia,imm);
      res <= ia + imm;
    end
  `ANDUI: res <= ia & imm;
  `ORUI: res <= ia | imm;
  `AUIIP: res <= dpc + imm;
  `CSR: 
    begin
      res <= 64'd0;
      case(eir[39:37])
      3'd4,3'd5,3'd6,3'd7:  ia <= Rs1[4:0];
      default:  ;
      endcase
      // For now, bits 8 to 11 of CSR# are not checked
      casez({eir[35:33],eir[29:18]})
      15'b???_0000_0000_0010:  res <= tick;
      15'b001_0000_0000_0011:  res <= pta;
      15'b???_0000_0000_0100:
        case(eir[35:33])
        3'd0: res <= {63'd0,uie};
        3'd1: res <= {62'd0,sie,uie};
        3'd2: res <= {61'd0,hie,sie,uie};
        3'd3: res <= {60'd0,mie,hie,sie,uie};
        3'd4: res <= {59'd0,iie,mie,hie,sie,uie};
        3'd5: res <= {58'd0,die,iie,mie,hie,sie,uie};
        default:	res <= 64'd0;
        endcase
      15'b001_????_0001_0000:  res <= TaskId;
      15'b001_????_0001_1111:  res <= ASID;
      15'b001_????_0010_0000:  res <= {key[2],key[1],key[0]};
      15'b001_????_0010_0001:  res <= {key[5],key[4],key[3]};
      15'b001_????_0010_0010:  res <= {key[8],key[7],key[6]};
      15'b011_0000_0000_0001:  res <= hartid_i;
      15'b011_????_0000_1100:  res <= sema;
      15'b???_????_0000_0110:  res <= cause[eir[28:26]];
      15'b???_????_0000_0111:  res <= badaddr[eir[28:26]];
      15'b???_????_0000_1001:  res <= scratch[eir[28:26]];
      15'b???_????_0011_0???:  res <= tvec[eir[28:26]];
      15'b???_????_0100_0000:  res <= pmStack;
      15'b???_????_0100_1000:  res <= epc;
      15'b101_????_0001_10??:  res <= dbad[eir[19:18]];
      15'b101_????_0001_1100:  res <= dbcr;
      15'b101_????_0001_1101:  res <= dbsr;
	    15'b???_0001_0000_0???:	 res <= sp_regfile[eir[20:18]];
      default:  ;
      endcase
    end

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Flow Control
  // Effective address for JSR/RTS set by address generator module above.
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  `JSR,`JSR18:
    begin
      res <= ia - 4'd8; // decrement sp
    end
  `RTL: 
    begin
      emod_pc <= eval;
      res <= ia + imm;
      enext_pc <= ret_pc + eir[12:9];
    end
  `RTS,`RTX: 
    begin
      res <= ia + imm + 4'd8;
    end
  `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,
  `BLEU,`BGTU,`BOD,`BPS,`BEQZ,`BNEZ:
    begin
      if (takb & !ebrpred) begin
        emod_pc <= TRUE;
        enext_pc <= expc + {{51{eir[23]}},eir[23:11]};
        if (eir[23:11]==13'd0) begin
          $display("FLT_BT");
          e_cause <= `FLT_BT;
        end
      end
      else if (!takb & ebrpred) begin
        emod_pc <= TRUE;
        enext_pc <= expc + eilen;
        if (eval)
          loop_mode <= 3'd0;
      end
    end
  `BRA: ; // BRA is always taken.
  `BEQI,`BBC,`BBS:
    begin
      if (takb & !ebrpred) begin
        emod_pc <= TRUE;
        enext_pc <= expc + {{52{eir[31]}},eir[31:21]};
        if (eir[31:21]==12'd0)
          e_cause <= `FLT_BT;
      end
      else if (!takb & ebrpred) begin
        emod_pc <= TRUE;
        enext_pc <= expc + eilen;
        if (eval)
          loop_mode <= 3'd0;
      end
    end
  `BT:
    begin
      if (takb & !ebrpred) begin
        emod_pc <= TRUE;
        enext_pc <= expc + {{58{eir[15]}},eir[15:10]};
        if (eir[15:10]==6'd0)
          e_cause <= `FLT_BT;
      end
      else if (!takb & ebrpred) begin
        emod_pc <= TRUE;
        enext_pc <= expc + eilen;
        if (eval)
          loop_mode <= 3'd0;
      end
    end

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`ifdef SUPPORT_MCID
  `PUSH:  res <= ia - imm;
  `PUSHC: res <= ia - imm;
  `LINK:  res <= ia - imm;
  `UNLINK:  res <= ia;
`endif

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  `OSR2:
    case(efunct5)
    `CACHE: ;//goto (MEMORY1);
		`WFI:
		  begin
			  set_wfi <= 1'b1;
		  end
		`SETKEY:  res <= {18'd0,ia[45:32],12'd0,keyoa};
		`GCCLR:
		  begin
		    case(ia[30:28])
		    3'd0: res <= cardmem0o;
		    3'd1: res <= {32'd0,card1o};
		    3'd2: res <= {card22o,card21o};
		    default:  ;
		    endcase
		  end
		`REX: ; // see writeback
    `MVSEG: begin res <= sregfile[ib[3:0]]; end
    `PEEKQ:
      case(ia[3:0])
      4'd15:  res <= trace_dout;
      default: ;
      endcase
    `POPQ:
      case(ia[3:0])
      4'd15:  begin rd_trace <= 1'b1; res <= trace_dout; end
      default: ;
      endcase
    `STATQ:
      case(ia[3:0])
      4'd15:  res <= {trace_empty,trace_valid,52'd0,trace_data_count};
      default: ;
      endcase
    `MVCI:  res <= ci_tblo2;
    default:  ;
    endcase
	default:  ;
  endcase

  if (advance_e) begin
    mval <= eval;
    mia <= ia;
    mid <= id;
    mib <= ib;
    mir <= eir;
    milen <= eilen;
    mpc <= expc;
    mRs1 <= eRs1;
    mRd <= eRd;
    mCd <= eCd;
    mres <= res;
    mcrres <= crres;
    mwrirf <= ewrirf;
    mwrcrf <= ewrcrf;
    mwrcrf32 <= ewrcrf32;
    mwrra <= ewrra;
    mwrca <= ewrca;
    m_setkey <= e_setkey;
    m_gcclr <= e_gcclr;
    m_stptr <= e_stptr;
    m_cbranch <= e_cbranch;
    m_cause <= e_cause;
    mbrpred <= ebrpred;
    m_loop_bust <= e_loop_bust;
    m_bubble <= e_bubble;
    m_cause <= e_cause;
    m_rad <= e_rad;
    m_omode <= e_omode;
    mrares <= erares;
    mwrsrf <= ewrsrf;
    ea <= eea;
    emod_pc <= FALSE;
    execute_done <= FALSE;
    egoto(EXECUTE);
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tMemory;
begin
if (rst_i) begin
	mstate <= MEMORY_WAIT;
	memory_done <= TRUE;
  mpc <= RSTPC;
  mres <= 64'd0;
  mmod_pc <= FALSE;
  m_cbranch <= FALSE;
  wRd <= 7'd0;
  wadr <= 64'h0;
  w_bubble <= FALSE;
  w_loop_bust <= FALSE;
  w_setkey <= FALSE;
  w_gcclr <= FALSE;
  w_stptr <= FALSE;
  w_cause <= 8'h00;
  w_rad <= 1'b0;
  wilen <= 4'd1;
  wwrsrf <= FALSE;
  dati <= 128'h0;
  dload <= FALSE;
  use_dc <= FALSE;
end
else
case(mstate)
MEMORY0:
  begin
    mmod_pc <= FALSE;
    mgoto (MEMORY1);
  end
MEMORY1:
  begin
    cr_o <= LOW;
    sr_o <= LOW;
`ifdef RTF64_TLB
    mgoto (MEMORY1a);
`else
    mgoto (MEMORY2);
`endif
    if (mopcode==`LEA || mopcode==`LEAS) begin
      mres <= ea;
      adv_mem(1'b0);
    end
    else begin
    	dcnt <= 4'd0;
      // Must have a memory op to continue.
      if (mopcode[7:4]==4'h8 || mopcode[7:4]==4'h9 || mopcode[7:4]==4'hA || mopcode[7:4]==4'hB ||
        mopcode==`JSR || mopcode==`JSR18 || mopcode==`RTS || mopcode==`RTX) begin // POP incl.
        if (iaccess_pending)
          mstate <= mstate;
        else begin
          maccess <= mval;
          tEA();
          xlaten <= mval;
          dc_sel <= {32'h0,selx} << ea[4:0];
          if (mopcode==`STOIS)
          	dc_dat <= {256'd0,{WID-14{mir[31]}},mir[31:23],mir[12:8]} << {ea[4:0],3'b0};
          else
          	dc_dat <= {256'd0,mid} << {ea[4:0],3'b0};
`ifdef CPU_B128
          sel <= {8'h00,selx} << ea[3:0];
          if (mopcode==`STOIS)
          	dat <= {{WID-14{mir[31]}},mir[31:23],mir[12:8]} << {ea[3:0],3'b0};
         	else
          	dat <= mid << {ea[3:0],3'b0};
`endif
`ifdef CPU_B64
          sel <= {8'h00,selx} << ea[2:0];
          if (mopcode==`STOIS)
          	dat <= {{WID-14{mir[31]}},mir[31:23],mir[12:8]} << {ea[2:0],3'b0};
         	else
	          dat <= mid << {ea[2:0],3'b0};
`endif
`ifdef CPU_B32
          sel <= {12'h00,selx} << ea[1:0];
          if (mopcode==`STOIS)
          	dat <= {{WID-14{mir[31]}},mir[31:23],mir[12:8]} << {ea[1:0],3'b0};
         	else
	          dat <= mid << {ea[1:0],3'b0};
`endif
          ealow <= ea[7:0];
        end
      end
      else
        adv_mem(1'b0);
    end
    if (!mval) begin
      mmod_pc <= FALSE;
      memory_done <= TRUE;
      mgoto (MEMORY_WAIT);
    end
  end
MEMORY1a:
  mgoto (MEMORY2);
// This cycle for pageram access
MEMORY2:
  begin
    mgoto (MEMORY_KEYCHK1);
  end
MEMORY_KEYCHK1:
  begin
    mgoto (MEMORY3);
    if (d_cache)
      tPMAEA();
  end
MEMORY3:
  begin
    mgoto (MEMORY4);
`ifdef RTF64_TLB
		if (tlbmiss) begin
		  m_cause <= 32'h80000004;
		  //mException(32'h80000004,mpc);
  	  m_badaddr <= ea;
  	end
    else
`endif    
    if (~d_cache) begin
      cyc_o <= HIGH;
      stb_o <= HIGH;
`ifdef CPU_B128
      sel_o <= sel[15:0];
      dat_o <= dat[127:0];
`endif
`ifdef CPU_B64
      sel_o <= sel[7:0];
      dat_o <= dat[63:0];
`endif
`ifdef CPU_B32
      sel_o <= sel[3:0];
      dat_o <= dat[31:0];
`endif
      case(mopcode)
      `JSR,`JSR18,
      `STB,`STW,`STT,`STO,/*`STOT,*/`STPTR,`FSTO,`PSTO,
      `STBS,`STWS,`STTS,`STOS,/*`STOTS,*/`STPTRS,`FSTOS,`PSTOS,`STOIS:
        we_o <= HIGH;
      `STOC,`STOCS:
        begin
          we_o <= HIGH;
          cr_o <= HIGH;
        end
      `LDOR,`LDORS:
        sr_o <= HIGH;
      default:  ;
      endcase
    end
  end
MEMORY3a:
	begin
    xlaten <= TRUE;
		tEA();
		mgoto(MEMORY3b);
	end
MEMORY3b:
	mgoto(MEMORY3c);
MEMORY3c:
	mgoto(MEMORY_KEYCHK4);
MEMORY_KEYCHK4:
	begin
		mgoto(MEMORY3d);
	end
MEMORY3d:
	begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
`ifdef CPU_B128		
		sel_o <= 16'hFFFF;
`endif
`ifdef CPU_B64
		sel_o <= 8'hFF;
`endif
`ifdef CPU_B32
		sel_o <= 4'hF;
`endif
		mgoto(MEMORY3e);
	end
MEMORY3e:
	if (acki|err_i) begin
		stb_o <= LOW;
		// Capture the first address so we know which cache row to update.
		if (dcnt==4'd0)
			first_adr_o <= adr_o;
`ifdef CPU_B128
		case(dcnt)
		4'd0:	dc_dat[127:0] <= dat_i;
		4'd1:	dc_dat[255:128] <= dat_i;
		4'd2: dc_dat[311:256] <= dat_i[55:0];
		default:	;
		endcase
		if (dcnt==4'd2) begin
			cyc_o <= LOW;
			sel_o <= 16'h0000;
			dload <= TRUE;
			mgoto(MEMORY3g);
		end
`endif
`ifdef CPU_B64
		case(dcnt)
		4'd0:	dc_dat[63:0] <= dat_i;
		4'd1:	dc_dat[127:64] <= dat_i;
		4'd2: dc_dat[191:128] <= dat_i;
		4'd3:	dc_dat[255:192] <= dat_i;
		4'd4:	dc_dat[311:256] <= dat_i[55:0];
		default:	;
		endcase
		if (dcnt==4'd4) begin
			cyc_o <= LOW;
			sel_o <= 8'h00;
			dload <= TRUE;
			mgoto(MEMORY3g);
		end
`endif
`ifdef CPU_B32
		case(dcnt)
		4'd0:	dc_dat[31:0] <= dat_i;
		4'd1:	dc_dat[63:32] <= dat_i;
		4'd2:	dc_dat[95:64] <= dat_i;
		4'd3:	dc_dat[127:96] <= dat_i;
		4'd4: dc_dat[159:128] <= dat_i;
		4'd5:	dc_dat[191:160] <= dat_i;
		4'd6:	dc_dat[223:192] <= dat_i;
		4'd7:	dc_dat[255:224] <= dat_i;
		4'd8:	dc_dat[287:256] <= dat_i;
		4'd9:	dc_dat[311:288] <= dat_i[23:0];
		default:	;
		endcase
		if (dcnt==4'd9) begin
			cyc_o <= LOW;
			sel_o <= 4'h0;
			dload <= TRUE;
			mgoto(MEMORY3g);
		end
`endif
		else
			mgoto(MEMORY3f);
	end
MEMORY3f:
	if (!acki) begin
		dcnt <= dcnt + 1'd1;
`ifdef CPU_B128		
		ea[AWID-1:4] <= ea[AWID-1:4] + 1'd1;
		ea[3:0] <= 4'h0;
`endif
`ifdef CPU_B64
		ea[AWID-1:3] <= ea[AWID-1:3] + 1'd1;
		ea[2:0] <= 3'h0;
`endif
`ifdef CPU_B32
		ea[AWID-1:2] <= ea[AWID-1:2] + 1'd1;
		ea[1:0] <= 2'h0;
`endif
		mgoto(MEMORY3a);
	end
MEMORY3g:
	begin
		ea <= ea_tmp;
		dload <= FALSE;
		mgoto(MEMORY3h);
	end
// There must be time allowed for the address to travel through the TLB, the
// Keycheck and then the data cache. This takes about five clocks.
MEMORY3h:
	begin
		tEA();
		mgoto(MEMORY3i);
	end
MEMORY3i:
	mgoto(MEMORY3j);
MEMORY3j:
	mgoto(MEMORY3k);
MEMORY3k:
	mgoto(MEMORY3l);
MEMORY3l:
	mgoto(MEMORY4);
MEMORY4:
  begin
    if (d_cache) begin
      icvalid0[adr_o[pL1msb:5]] <= 1'b0;
      icvalid1[adr_o[pL1msb:5]] <= 1'b0;
      icvalid2[adr_o[pL1msb:5]] <= 1'b0;
      icvalid3[adr_o[pL1msb:5]] <= 1'b0;
      adv_mem(1'b0);
    end
    else begin
    	// Under construction
    	if (mopcode[7:5]==3'd4 && adr_o[AWID-1:20]!={{AWID-5{1'b1}},4'hD}) begin
				if (dhit)	begin
	    		cyc_o <= LOW;
	    		stb_o <= LOW;
	    		sel_o <= 1'b0;
	    		use_dc <= TRUE;
	    		maccess <= FALSE;
	    		tPC();
					mgoto(DATA_ALIGN);
				end
				else begin
					dcnt <= 4'd0;
					stb_o <= LOW;
					ea_tmp <= ea;			// save off original address
					ea[4:0] <= 5'h0;	// align to a cache line
					mgoto(MEMORY3a);
				end
			end
    	else if (acki|err_i) begin
	      mgoto (MEMORY5);
	      stb_o <= LOW;
	      dati <= dat_i;
	      if (sel[`SELH]==1'h0) begin
	        cyc_o <= LOW;
	        we_o <= LOW;
	        sel_o <= 1'h0;
	        maccess <= FALSE;
	        set_rbi();
	        tPC();
	      end
	    end
    end
  end
MEMORY5:
  if (~acki) begin
    if (|sel[`SELH])
      mgoto (MEMORY6);
    else begin
      case(mopcode)
      `STB,`STW,`STT,`STO,/*`STOT,*/`STOC,`STPTR,`FSTO,`PSTO,
      `STBS,`STWS,`STTS,`STOS,/*`STOTS,*/`STOCS,`STPTRS,`FSTOS,`PSTOS,`STOIS:
        adv_mem(1'b0);
      `JSR,`JSR18:
        adv_mem(1'b0);
      default:
        mgoto (DATA_ALIGN);
      endcase
    end
  end
MEMORY6:
  begin
`ifdef RTF64_TLB
    mgoto (MEMORY6a);
`else
    mgoto (MEMORY7);
`endif
    xlaten <= TRUE;
    tEA();
  end
MEMORY6a:
  mgoto (MEMORY7);
MEMORY7:
  mgoto (MEMORY_KEYCHK2);
MEMORY_KEYCHK2:
  begin
    mgoto (MEMORY8);
    tPMAEA();
  end
MEMORY8:
  begin
    mgoto (MEMORY9);
`ifdef RTF64_TLB    
		if (tlbmiss) begin
		  m_cause <= 32'h80000004;
		  //mException(32'h80000004,mpc);
  	  m_badaddr <= ea;
		  cyc_o <= LOW;
		  stb_o <= LOW;
		  we_o <= 1'b0;
		  sel_o <= 1'd0;
	  end
		else
`endif
		begin
      stb_o <= HIGH;
      sel_o <= sel[`SELH];
      dat_o <= dat[`DATH];
    end
  end
MEMORY9:
  if (acki|err_i) begin
    mgoto (MEMORY10);
    stb_o <= LOW;
    dati[`DATH] <= dat_i;
`ifdef CPU_B128
    cyc_o <= LOW;
    we_o <= LOW;
    sel_o <= 1'h0;
    maccess <= FALSE;
    tPC();
`endif
`ifdef CPU_B64
    cyc_o <= LOW;
    we_o <= LOW;
    sel_o <= 1'h0;
    maccess <= FALSE;
    tPC();
`endif
`ifdef CPU_B32
    if (sel[11:8]==4'h0) begin
      cyc_o <= LOW;
      we_o <= LOW;
      sel_o <= 4'h0;
      maccess <= FALSE;
      set_rbi();
      tPC();
    end
`endif
  end
MEMORY10:
  if (~acki) begin
`ifdef CPU_B32
    ea <= {ea[31:2]+2'd1,2'b00};
    if (sel[11:8])
      mgoto (MEMORY11);
    else
`endif
    begin
      case(mopcode)
      `STB,`STW,`STT,`STO,/*`STOT,*/`STOC,`STPTR,`FSTO,`PSTO,
      `STBS,`STWS,`STTS,`STOS,/*`STOTS,*/`STOCS,`STPTRS,`FSTOS,`PSTOS,`STOIS:
        adv_mem(1'b0);
      `JSR,`JSR18:
        adv_mem(1'b0);
      default:
        mgoto (DATA_ALIGN);
      endcase
    end
  end
MEMORY11:
  begin
`ifdef RTF64_TLB
    mgoto (MEMORY11a);
`else
    mgoto (MEMORY12);
`endif
    xlaten <= TRUE;
    tEA();
  end
MEMORY11a:
  mgoto (MEMORY12);
MEMORY12:
  mgoto (MEMORY_KEYCHK3);
MEMORY_KEYCHK3:
  begin
    mgoto (MEMORY13);
    tPMAEA();
  end
MEMORY13:
  begin
    mgoto (MEMORY14);
`ifdef RTF64_TLB    
		if (tlbmiss) begin
		  m_cause <= 32'h80000004;
		  //mException(32'h80000004,mpc);
  	  m_badaddr <= ea;
		  cyc_o <= LOW;
		  stb_o <= LOW;
		  we_o <= 1'b0;
		  sel_o <= 1'd0;
	  end
		else
`endif		
		begin
      stb_o <= HIGH;
      sel_o <= sel[11:8];
      dat_o <= dat[95:64];
    end
  end
MEMORY14:
  if (acki|err_i) begin
    mgoto (MEMORY15);
    cyc_o <= LOW;
    stb_o <= LOW;
    we_o <= LOW;
    sel_o <= 4'h0;
    dati[95:64] <= dat_i;
    maccess <= FALSE;
    set_rbi();
    tPC();
  end
MEMORY15:
  if (~acki) begin
    case(mopcode)
    `STB,`STW,`STT,`STO,/*`STOT,*/`STOC,`STPTR,`FSTO,`PSTO,
    `STBS,`STWS,`STTS,`STOS,/*`STOTS,*/`STOCS,`STPTRS,`FSTOS,`PSTOS,`STOIS:
      adv_mem(1'b0);
    `JSR,`JSR18:
      adv_mem(1'b0);
    default:
      mgoto (DATA_ALIGN);
    endcase
  end
DATA_ALIGN:
  begin
    if (mwrcrf)
      mgoto(MEMORY_CRRES);  // will be overridden by default: case below
    else
      adv_mem(1'b0);
    case(mopcode)
    `LDB,`LDBS:   mres <= {{56{datis[7]}},datis[7:0]};
    `LDBU,`LDBUS: mres <= {{56{1'b0}},datis[7:0]};
    `LDW,`LDWS:   mres <= {{48{datis[15]}},datis[15:0]};
    `LDWU,`LDWUS: mres <= {{48{1'b0}},datis[15:0]};
    `LDT,`LDTS:   mres <= {{32{datis[31]}},datis[31:0]};
    `LDTU,`LDTUS:  mres <= {{32{1'b0}},datis[31:0]};
    `LDO,`LDOS:   mres <= datis[63:0];
//    `LDOT:  begin mcrres <= datis[31:0]; mrares <= datis[AWID-1:0]; adv_mem(1'b0); end
    `LDOR,`LDORS: mres <= datis[63:0];
    `FLDO,`FLDOS,`PLDO:  mres <= datis[63:0];
    `POP: mres <= datis[63:0];
    `RTS:    
      begin	// Was return address prediction correct? Note 1 stage delay.
      	if (rpc != datis[AWID-1:0] || !rval) begin
        	mmod_pc <= TRUE;
        	mnext_pc <= datis[AWID-1:0];// + {mir[12:9],2'b00};
      	end
        adv_mem(1'b0);
      end
    `RTX:
      begin
        mmod_pc <= TRUE;
        mnext_pc <= datis[63:0];
        adv_mem(1'b0);
      end
    default:  adv_mem(1'b0);
    endcase
  end
MEMORY_CRRES:
  begin
    adv_mem(1'b0);
    mcrres[0] <= 1'b0;
    mcrres[1] <= mres==64'd0;
    mcrres[2] <= 1'b0;
    mcrres[3] <= 1'b0;
    mcrres[4] <= ^mres;
    mcrres[5] <= mres[0];
    mcrres[6] <= 1'b0;
    mcrres[7] <= mres[63];
  end
MEMORY_WAIT:  ;
endcase
  if (advance_m) begin
  	use_dc <= FALSE;
    maccess <= FALSE;
    wval <= mval;
    wia <= mia;
    wib <= mib;
    wir <= mir;
    wRs1 <= mRs1;
    wRd <= mRd;
    wCd <= mCd;
    wres <= mres;
    wcrres <= mcrres;
    wpc <= mpc;
    wwrirf <= mwrirf;
    wwrcrf <= mwrcrf;
    wwrcrf32 <= mwrcrf32;
    wwrra <= mwrra;
    wwrca <= mwrca;
    wwrsrf <= mwrsrf;
    wbrpred <= mbrpred;
    wilen <= milen;
    w_loop_bust <= m_loop_bust;
    w_setkey <= m_setkey;
    w_gcclr <= m_gcclr;
    w_stptr <= m_stptr;
    w_cause <= m_cause;
    w_badaddr <= m_badaddr;
    w_omode <= m_omode;
    wrares <= mrares;
    wadr <= adr_o;
    mmod_pc <= FALSE;
    w_bubble <= m_bubble;
    w_rad <= m_rad;
    memory_done <= FALSE;
    mgoto(MEMORY0);
  end
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
task tWriteback;
begin
if (rst_i) begin
	wstate <= WRITEBACK_WAIT;
	writeback_done <= TRUE;
  wres <= 64'd0;
  wmod_pc <= FALSE;
  wpc <= RSTPC;
  w_cbranch <= FALSE;
  t_bubble <= FALSE;
  tilen <= 4'd1;
end
else
case(wstate)
WRITEBACK:
  begin
    wmod_pc <= FALSE;
    writeback_done <= TRUE;
    wgoto (WRITEBACK_WAIT);
    if (wval) begin
  		if (|w_cause) begin
  		  case({w_cause[31],w_cause[7:0]})
  		  9'h1FE:  nmif <= 1'b0;
  		  default:  ;
  		  endcase
  		  wException(w_cause, wpc);
  	  end
      else if (wval) begin
        if (wRd[6:5]==2'b11) begin
          writeback_done <= FALSE;
          wgoto (WRITEBACK2);
        end
        casez(wRd)
        7'b11_0000?: begin wrra <= 1'b1; rad <= wRd[0]; end
        7'b11_0001?: begin wrca <= 1'b1; rad <= wRd[0]; end
        7'b11_00111: epc <= wres;
        7'b11_100??: begin Cd <= wRd[1:0]; wcrres <= wres; end
        7'b11_11101: begin wrcrf32 <= 1'b1; wcrres <= wres; end
        default:  ;
        endcase
        case (wopcode)
        `R2:
          case(wfunct5)
          `MOV:
            begin
              case(wir[21:20])
              2'b00:  ;
              2'b01:  ;
              2'b10:  ;
              2'b11:
                casez(wRd[4:0])
                5'b0000?: ;
                5'b0001?: ;
                5'b00111: epc <= wres;
                5'b100??: begin Cd <= wRd[1:0]; end
                5'b11101: wrcrf32 <= 1'b1;
                default:  ;
                endcase
              endcase
            end
          default:  ;
          endcase
        `CSR: wr_csr();
        `RTE:
          begin
            i_omode <= pmStack[7:5];
    				pmStack <= {4'b1010,pmStack[31:4]};
          end
        `OSR2:
          case(wfunct5)
          `REX:
            if (wir[10:8] < w_omode) begin
              case(wir[10:8])
              3'd0:
                if (uie) begin
                  wmod_pc <= TRUE;
                  wnext_pc <= tvec[wir[10:8]];
                  badaddr[wir[10:8]] <= badaddr[w_omode];
                  cause[wir[10:8]] <= cause[w_omode];
                  pmStack[3:0] <= 4'b0;
                  i_omode <= 3'd0;
                end
              3'd1:
                if (sie) begin
                  wmod_pc <= TRUE;
                  wnext_pc <= tvec[wir[10:8]];
                  badaddr[wir[10:8]] <= badaddr[w_omode];
                  cause[wir[10:8]] <= cause[w_omode];
                  pmStack[3:0] <= 4'd2;
                  i_omode <= 3'd1;
                end
              3'd2:
                if (hie) begin
                  wmod_pc <= TRUE;
                  wnext_pc <= tvec[wir[10:8]];
                  badaddr[wir[10:8]] <= badaddr[w_omode];
                  cause[wir[10:8]] <= cause[w_omode];
                  pmStack[3:0] <= 4'd4;
                  i_omode <= 3'd2;
                end
              3'd3:
                if (mie) begin
                  wmod_pc <= TRUE;
                  wnext_pc <= tvec[wir[10:8]];
                  badaddr[wir[10:8]] <= badaddr[w_omode];
                  cause[wir[10:8]] <= cause[w_omode];
                  pmStack[3:0] <= 4'd6;
                  i_omode <= 3'd3;
                end
              3'd4:
                if (iie) begin
                  wmod_pc <= TRUE;
                  wnext_pc <= tvec[wir[10:8]];
                  badaddr[wir[10:8]] <= badaddr[w_omode];
                  cause[wir[10:8]] <= cause[w_omode];
                  pmStack[3:0] <= 4'd8;
                  i_omode <= 3'd4;
                end
              default:  ;
              endcase
            end
          `MVMAP:
            if (wRs1[4:0] != 5'd0)
              wrpagemap <= 1'b1;
          `MVCI:  wr_ci_tbl <= TRUE;
          default:  ;
          endcase
        default:  ;
        endcase
      end
    end
		instret <= instret + 2'd1;
  end
WRITEBACK2:
  begin
    /*
    if (advance_pipe) begin
      writeback_done <= FALSE;
      wgoto (WRITEBACK);
    end
    else
    */
    begin
      writeback_done <= TRUE;
      wgoto (WRITEBACK_WAIT);
    end
  end
WRITEBACK_WAIT: ;
endcase
  if (advance_w) begin
`ifdef SIM
    $display("Fetched: %d", instfetch);
    $display("Time: %d Ticks: %d", $time, tick);
    for (n = 0; n < 32; n = n + 4) begin
      $display("%d: %h  %d: %h  %d: %h  %d: %h",
         n[4:0], regfile[n],
         n[4:0]+2'd1, regfile[n+1],
         n[4:0]+2'd2, regfile[n+2],
         n[4:0]+2'd3, regfile[n+3]
      );
    end
    $display("IP: %h", ipc);
    $display("Fetch: %h", ir);
    $display("dRs1: %d  dRs2:%d  dRs3:%d  dRd:%d  dimm:%h", Rs1[4:0], Rs2[4:0], Rs3[4:0], Rd[4:0], dimm);
    $display("rir:%h cause:%h", rir, r_cause[7:0]);
    $display("ria: %h  rib:%h  ric:%h  rid:%h  rimm:%h", ria, rib, ric, rid, rimm);
    $display("rRs1: %d  rRs2:%d  rRs3:%d  rRd:%d", rRs1[4:0], rRs2[4:0], rRs3[4:0], rRd[4:0]);
    $display("eir:%h cause:%h", eir, e_cause[7:0]);
    $display("ia: %h  ib:%h  ic:%h  id:%h  imm:%h", ia, ib, ic, id, imm);
    $display("eRd=%d  eres: %h", eRd[4:0], res);
    $display("mir:%h cause:%h", mir, m_cause[7:0]);
    $display("mRd=%d  mres: %h", mRd[4:0], mres);
    $display("wir:%h cause:%h", wir, w_cause[7:0]);
    $display("wRd=%d  wres: %h", wRd[4:0], wres);
`endif
    t_bubble <= w_bubble;
    tval <= wval;
    twrirf <= wwrirf;
    twrcrf <= wwrcrf;
    twrcrf32 <= wwrcrf32;
    writeback_done <= FALSE;
    wgoto (WRITEBACK);
  end
end
endtask

task tTStage;
begin
  if (rst_i) begin
    tir <= `NOP_INSN;
    tpc <= RSTPC;
    tRd <= 8'd0;
    tCd <= 2'b00;
    tbrpred <= FALSE;
    t_cbranch <= FALSE;
    t_loop_bust <= FALSE;
    u_bubble <= FALSE;
    uilen <= 4'd1;
  end
  else if (advance_t) begin
    tir <= wir;
    tpc <= wpc;
    tRd <= wRd;
    tres <= wres;
    tCd <= wCd;
    tcrres <= wcrres;
    t_loop_bust <= w_loop_bust;
    t_cbranch <= w_cbranch;
    tbrpred <= wbrpred;
    tilen <= wilen;
    u_bubble <= t_bubble;
    uval <= tval;
  end
end
endtask

task tUStage;
begin
  if (rst_i) begin
    uir <= `NOP_INSN;
    upc <= RSTPC;
    ubrpred <= FALSE;
    u_loop_bust <= FALSE;
    u_cbranch <= FALSE;
    v_bubble <= FALSE;
    vilen <= 4'd1;
  end
  else if (advance_u) begin
    uir <= tir;
    upc <= tpc;
    ubrpred <= tbrpred;
    uilen <= tilen;
    u_loop_bust <= t_loop_bust;
    u_cbranch <= t_cbranch;
    v_bubble <= u_bubble;
    vval <= uval;
  end
end
endtask

task tVStage;
begin
  if (rst_i) begin
    vir <= `NOP_INSN;
    vpc <= RSTPC;
    vbrpred <= FALSE;
  end
  else if (advance_v) begin
    // Retire bubbles
    if (v_bubble) begin
      if (!(rstate==REGFETCH_WAIT && !advance_d & advance_w))
        ebubble_cnt <= ebubble_cnt - 1'b1;
      else
        ebubble_cnt <= ebubble_cnt;
    end
    vir <= uir;
    vpc <= upc;
    vbrpred <= ubrpred;
    vilen <= uilen;
  end
end
endtask

task set_rbi;
begin
  if (mopcode==`STOC || mopcode==`STOCS) begin
    mcrres <= 8'h00;
    mcrres[0] <= rb_i;  // carry / true/false
    mcrres[1] <= rb_i;  // zero
    mcrres[4] <= rb_i;  // parity
    mcrres[5] <= rb_i;  // odd
    mcrres[6] <= rb_i;  // overflow
    mcrres[7] <= rb_i;  // minus
  end
end
endtask

task wr_csr;
begin
  if (wRs1[4:0] != 5'd0 && wval)
  case(wir[39:37])
  3'd0: ; // read only
  3'd1,3'd5:
    casez({wir[35:33],wir[29:18]})
    15'b001_????_0000_0011:  pta <= wia;
    15'b???_????_0000_0100:
      case(wir[35:33])
      3'd0: uie <= wia[0];
      3'd1: begin uie <= wia[0]; sie <= wia[1]; end
      3'd2: begin uie <= wia[0]; sie <= wia[1]; hie <= wia[2]; end
      3'd3: begin uie <= wia[0]; sie <= wia[1]; hie <= wia[2]; mie <= wia[3]; end
      3'd4: begin uie <= wia[0]; sie <= wia[1]; hie <= wia[2]; mie <= wia[3]; iie <= wia[4]; end
      3'd5: begin uie <= wia[0]; sie <= wia[1]; hie <= wia[2]; mie <= wia[3]; iie <= wia[4]; die <= wia[5]; end
      default:  ;
      endcase
    15'b001_????_0001_0000:  TaskId <= wia;
    15'b001_????_0001_1111:  ASID <= wia;
    15'b001_????_0010_0000:  begin key[0] <= wia[19:0]; key[1] <= wia[39:20]; key[2] <= wia[59:40]; end
    15'b001_????_0010_0001:  begin key[3] <= wia[19:0]; key[4] <= wia[39:20]; key[5] <= wia[59:40]; end
    15'b001_????_0010_0010:  begin key[6] <= wia[19:0]; key[7] <= wia[39:20]; key[8] <= wia[59:40]; end
    15'b011_????_0000_1100:  sema <= wia;
    15'b???_????_0000_0110:  cause[wir[28:26]] <= wia;
    15'b???_????_0000_0111:  badaddr[wir[28:26]] <= wia;
    15'b???_????_0000_1001:  scratch[wir[28:26]] <= wia;
    15'b???_????_0011_0???:  tvec[wir[28:26]] <= wia;
    15'b???_????_0100_0000:  pmStack <= wia;
	  15'b???_????_0100_1000:	 epc <= wia;
    15'b101_????_0001_10??:  dbad[wir[19:18]] <= wia;
    15'b101_????_0001_1100:  dbcr <= wia;
    15'b101_????_0001_1101:  dbsr <= wia;
    15'b???_0001_0000_0???:	sp_regfile[wir[20:18]] <= wia;
    default:  ;
    endcase
  3'd2,3'd6:
    casez({wir[35:33],wir[29:18]})
    15'b???_????_0000_0100:
      case(wir[35:33])
      3'd0: uie <= uie | wia[0];
      3'd1: begin uie <= uie | wia[0]; sie <= sie | wia[1]; end
      3'd2: begin uie <= uie | wia[0]; sie <= sie | wia[1]; hie <= hie | wia[2]; end
      3'd3: begin uie <= uie | wia[0]; sie <= sie | wia[1]; hie <= hie | wia[2]; mie <= mie | wia[3]; end
      3'd4: begin uie <= uie | wia[0]; sie <= sie | wia[1]; hie <= hie | wia[2]; mie <= mie | wia[3]; iie <= iie | wia[4]; end
      3'd5: begin uie <= uie | wia[0]; sie <= sie | wia[1]; hie <= hie | wia[2]; mie <= mie | wia[3]; iie <= iie | wia[4]; die <= die | wia[5]; end
      default:  ;
      endcase
    15'b???_????_0100_0000:  pmStack <= pmStack | wia;
    15'b011_????_0000_1100:  sema <= sema | wia;
    15'b101_????_0001_1100:  dbcr <= dbcr | wia;
    15'b101_????_0001_1101:  dbsr <= dbsr | wia;
    default:  ;
    endcase
  3'd3,3'd7:
    casez({wir[35:33],wir[29:18]})
    15'b???_????_0000_0100:
      case(wir[35:33])
      3'd0: uie <= uie & ~wia[0];
      3'd1: begin uie <= uie & ~wia[0]; sie <= sie & ~wia[1]; end
      3'd2: begin uie <= uie & ~wia[0]; sie <= sie & ~wia[1]; hie <= hie & ~wia[2]; end
      3'd3: begin uie <= uie & ~wia[0]; sie <= sie & ~wia[1]; hie <= hie & ~wia[2]; mie <= mie & ~wia[3]; end
      3'd4: begin uie <= uie & ~wia[0]; sie <= sie & ~wia[1]; hie <= hie & ~wia[2]; mie <= mie & ~wia[3]; iie <= iie & ~wia[4]; end
      3'd5: begin uie <= uie & ~wia[0]; sie <= sie & ~wia[1]; hie <= hie & ~wia[2]; mie <= mie & ~wia[3]; iie <= iie & ~wia[4]; die <= die & ~wia[5]; end
      default:  ;
      endcase
    15'b???_????_0100_0000:  pmStack <= pmStack & ~wia;
    15'b011_????_0000_1100:  sema <= sema & ~wia;
    15'b101_????_0001_1100:  dbcr <= dbcr & ~wia;
    15'b101_????_0001_1101:  dbsr <= dbsr & ~wia;
    default:  ;
    endcase
  default:  ;
  endcase
end
endtask

task tEA;
begin
  if (MUserMode && d_st && !ea_acr[1])
  	m_cause <= 32'h80000032;
  else if (MUserMode && m_ld && !ea_acr[2])
  	m_cause <= 32'h80000033;
	if (!MUserMode || ea[AWID-1:24]=={AWID-24{1'b1}})
		ladr <= ea;
	else
		ladr <= ea[AWID-4:0] + {sregfile[segsel][AWID-1:4],`SEG_SHIFT};
end
endtask

task tPC;
begin
  if (UserMode & !pc_acr[0])
  	i_cause <= 32'h80000002;
	if (!UserMode || pc[AWID-1:24]=={AWID-24{1'b1}})
		ladr <= pc;
	else
		ladr <= pc[AWID-2:0] + {sregfile[pc[AWID-1:AWID-4]][AWID-1:4],`SEG_SHIFT};
end
endtask

task tPMAEA;
begin
  if (keyViolation && omode == 3'd0)
  	m_cause <= 32'h80000031;
  // PMA Check
  for (n = 0; n < 8; n = n + 1)
    if (adr_o[31:4] >= PMA_LB[n] && adr_o[31:4] <= PMA_UB[n]) begin
      if ((m_st && !PMA_AT[n][1]) || (m_ld && !PMA_AT[n][2]))
		  	m_cause <= 32'h8000003D;
    end
end
endtask

task tPMAPC;
begin
  // PMA Check
  // Abort cycle that has already started.
  for (n = 0; n < 8; n = n + 1)
    if (adr_o[31:4] >= PMA_LB[n] && adr_o[31:4] <= PMA_UB[n]) begin
      if (!PMA_AT[n][0]) begin
      	i_cause <= 32'h8000003D;
        cyc_o <= LOW;
    		stb_o <= LOW;
    		vpa_o <= LOW;
    		sel_o <= 4'h0;
    	end
    end
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
  crres[0] <= bool & cdb[0];
  crres[1] <= bool & cdb[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool & cdb[4];
  crres[5] <= bool & cdb[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolOr;
input bool;
begin
  crres[0] <= bool | cdb[0];
  crres[1] <= bool | cdb[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool | cdb[4];
  crres[5] <= bool | cdb[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolAndcm;
input bool;
begin
  crres[0] <= ~bool & cdb[0];
  crres[1] <= ~bool & cdb[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= ~bool & cdb[4];
  crres[5] <= ~bool & cdb[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolOrcm;
input bool;
begin
  crres[0] <= ~bool | cdb[0];
  crres[1] <= ~bool | cdb[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= ~bool | cdb[4];
  crres[5] <= ~bool | cdb[5];
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

// No need to set the whole ir here.
task tInvalidate;
begin
  if (rst_i) begin
    ir[7:0] <= `NOP_INSN;
    rir[7:0] <= `NOP_INSN;
    eir[7:0] <= `NOP_INSN;
    mir[7:0] <= `NOP_INSN;
    wir[7:0] <= `NOP_INSN;
    dval <= FALSE;
    rval <= FALSE;
    eval <= FALSE;
    mval <= FALSE;
    wval <= FALSE;
    tval <= FALSE;
    uval <= FALSE;
  end
  else begin
    if ((wmod_pc & advance_w) & wval) begin
      ir[7:0] <= `NOP_INSN;
      dval <= FALSE;
      rir[7:0] <= `NOP_INSN;
      rval <= FALSE;
      eir[7:0] <= `NOP_INSN;
      eval <= FALSE;
      mir[7:0] <= `NOP_INSN;
      mval <= FALSE;
      wir[7:0] <= `NOP_INSN;
      wval <= FALSE;
    end
  	else if ((mmod_pc & advance_m) & mval) begin
      ir[7:0] <= `NOP_INSN;
      dval <= FALSE;
      rir[7:0] <= `NOP_INSN;
      rval <= FALSE;
      eir[7:0] <= `NOP_INSN;
      eval <= FALSE;
      mir[7:0] <= `NOP_INSN;
      mval <= FALSE;
  	end
    else if ((emod_pc & advance_e) & eval) begin
      ir[7:0] <= `NOP_INSN;
      dval <= FALSE;
      rir[7:0] <= `NOP_INSN;
      rval <= FALSE;
      eir[7:0] <= `NOP_INSN;
      eval <= FALSE;
    end
    else if ((rmod_pc & advance_d) & rval) begin
      ir[7:0] <= `NOP_INSN;
      dval <= FALSE;
      rir[7:0] <= `NOP_INSN;
      rval <= FALSE;
    end
    else if ((dmod_pc & advance_d) & dval) begin
      ir[7:0] <= `NOP_INSN;
      dval <= FALSE;
    end
  end
end
endtask

task adv_ex;
begin
  execute_done <= TRUE;
  egoto(EXECUTE_WAIT);
end
endtask

task adv_mem;
input takb;
begin
  memory_done <= TRUE;
  mgoto(MEMORY_WAIT);
end
endtask

// Exception at writeback stage
task wException;
input [31:0] cse;
input [AWID-1:0] tpc;
begin
	epc <= tpc;
	i_omode <= 3'd5;
  pmStack <= {pmStack[27:0],3'b101,1'b0};
	cause[3'd5] <= cse;
  badaddr[3'd5] <= w_badaddr;
	instret <= instret + 2'd1;
`ifdef SIM  
  $display("**********************");
  $display("** Exception: %d    **", cse);
  $display("**********************");
`endif  
  wmod_pc <= TRUE;
  wnext_pc <= tvec[3'd5] + {w_omode,3'h0};
  writeback_done <= TRUE;
	exception <= TRUE;
  dgoto (WRITEBACK_WAIT);
end
endtask

// There are very few cases where loops would contain just two instructions.
// For instance there may be a timing loop consisting of a decrement operation
// then a branch. Other than that most loops would be three or more
// instructions. So, to conserve some hardware loop mode is not entered for
// loops of only two instructions. Timing loops are better done using one of 
// the timing CSR's as the cpu clock may vary or it may be stopped at some
// point.
task tLoop;
input [AWID-1:0] ad;
begin
`ifdef SUPPORT_LOOPMODE
  loop_mode <= 3'd0;
  if (!cbranch_in_pipe && !loop_bust) begin
    case(ad[AWID-1:0])  
     /*
    rpc[31:0]:
      begin
        loop_mode <= 3'd1;
        dmod_pc <= FALSE;
      end
    */
    expc[AWID-1:0]:
      if (eval) begin
        loop_mode <= 3'd2;
        dmod_pc <= FALSE;
      end
    mpc[AWID-1:0]:
      if (mval) begin
        loop_mode <= 3'd3;
        dmod_pc <= FALSE;
      end
    wpc[AWID-1:0]:
      if (wval) begin
        loop_mode <= 3'd4;
        dmod_pc <= FALSE;
      end
    tpc[AWID-1:0]:
      if (tval) begin
        loop_mode <= 3'd5;
        dmod_pc <= FALSE;
      end
    upc[AWID-1:0]:
      if (uval) begin
        loop_mode <= 3'd6;
        dmod_pc <= FALSE;
      end
    vpc[AWID-1:0]:
      if (vval) begin
        loop_mode <= 3'd7;
        dmod_pc <= FALSE;
      end
    default:
      begin
        loop_mode <= 3'd0;
      end
    endcase
  end
`else
  loop_mode <= 3'd0;
`endif
end
endtask

task igoto;
input [5:0] nst;
begin
  istate <= nst;
end
endtask

task dgoto;
input [5:0] nst;
begin
  dstate <= nst;
end
endtask

task rgoto;
input [5:0] nst;
begin
  rstate <= nst;
end
endtask

task egoto;
input [5:0] nst;
begin
  estate <= nst;
end
endtask

task mgoto;
input [5:0] nst;
begin
  mstate <= nst;
end
endtask

task wgoto;
input [5:0] nst;
begin
  wstate <= nst;
end
endtask

endmodule
