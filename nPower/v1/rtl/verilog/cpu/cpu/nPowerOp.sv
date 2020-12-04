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

module nPower(rst_i, clk_i);
input rst_i;
input clk_i;

integer n;
wire clk_g;
assign clk_g = clk_i;


reg [32:0] iir, dir, rir, eir, mir, wir, tir, uir, vir;

wire [4:0] iRt = iir[25:21];
wire [4:0] iRa = iir[20:16];
wire [4:0] iRb = iir[15:11];
wire [4:0] iRc = iir[10:6];

reg wwrirf;
reg d_ld, d_ldbu, d_ldwu, d_st, d_stbu, d_stwu;

reg [31:0] regfile [0:63];
initial begin
  for (n = 0; n < 64; n = n + 1)
    regfile[n] = 32'd0;
end
wire [31:0] iRfot = regfile[iRt];
wire [31:0] iRfoa = regfile[iRa];
wire [31:0] iRfob = regfile[iRb];
wire [31:0] iRfoc = regfile[iRc];
always @(posedge clk_g)
  if (wwrirf)
    regfile[wRt] <= wres;

reg [4:0] dRt,dRa,dRb,dRc;
reg [2:0] dBf;
reg illegal_insn;
reg dwrirf, dwrcrf;
reg [31:0] dimm;

reg [3:0] icnt;
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

always @(posedge clk)
begin
  tReset();
  
  tInsFetch();
  tDecode();
  tRegfetch();
  tExecute();
  tMemory();
  tWriteback();
  tTail1();
  tTail2();
  tTail3();

end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction fetch stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

task tInsFetch;
begin
if (rst_i) begin
	igoto(IFETCH1);
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
case(istate)
IFETCH1:
  begin
  	ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
    tPC();
    xlaten <= TRUE;
 		vpa_o <= HIGH;
    igoto (IFETCH2);
  end
IFETCH2:
  begin
    if (ihit1a|ihit1b|ihit1c|ihit1d)
      icnt <= 4'h8;
    else
      icnt <= 4'd0;
		if (ihitw0) begin
		  iri <= icache0[pc[pL1msb:5]];
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1a && pc[4:0] < 5'h9) begin
		  iri <= icache0[pc[pL1msb:5]];
		  igoto (IFETCH_ALIGN);
	  end
		else if (ihitw1) begin
		  iri <= icache1[pc[pL1msb:5]];
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1b && pc[4:0] < 5'h9) begin
		  iri <= icache1[pc[pL1msb:5]];
		  igoto (IFETCH_ALIGN);
	  end
		else if (ihitw2) begin
		  iri <= icache2[pc[pL1msb:5]];
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1c && pc[4:0] < 5'h9) begin
		  iri <= {1'b0,icache2[pc[pL1msb:5]]};
		  igoto (IFETCH_ALIGN);
	  end
		else if (ihitw3) begin
		  iri <= {1'b0,icache3[pc[pL1msb:5]]};
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1d && pc[4:0] < 5'h9) begin
		  iri <= {1'b0,icache3[pc[pL1msb:5]]};
		  igoto (IFETCH_ALIGN);
	  end
	  else
      igoto (IFETCH3);
  end
IFETCH2a:
  begin
    igoto(IFETCH3);
  end
IFETCH3:
  begin
		if (ihitw0 && icnt==4'h0) begin
		  iri <= icache0[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1a && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri <= icache0[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
		else if (ihitw1 && icnt==4'h0) begin
		  iri <= icache1[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1b && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri <= icache1[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
		else if (ihitw2 && icnt==4'h0) begin
		  iri <= icache2[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1c && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri <= icache2[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
		else if (ihitw3 && icnt==4'h0) begin
		  iri <= icache3[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
	  else if (ihit1d && pc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri <= icache3[pc[pL1msb:5]];
		  icaccess <= FALSE;
		  igoto (IFETCH_ALIGN);
	  end
	  else
	  begin
  		igoto (IFETCH3a);
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
IFETCH_ALIGN:
  begin
    waycnt <= waycnt + 2'd1;
    iir <= iri >> {ipc2[4:2],5'b0};
    ifetch_done <= TRUE;
    igoto (IFETCH_WAIT);
  end
IFETCH_WAIT:
  if (advance_i) begin
    dval <= TRUE;
    i_cause <= 8'h00;
		if (nmif)
			i_cause <= 32'h800000FE;
 		else if (irq_i & die)
 		  i_cause <= {24'h800000,cause_i};
		else if (mip[7] & miex[7] & die)
		  i_cause <= 32'h800000F2;
		else if (mip[3] & miex[3] & die)
		  i_cause <= 32'h800000F0;
		else if (uip[0] & gcie[ASID] & die) begin
		  i_cause <= 32'hC00000F3;
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
      pc <= pc + 3'd4;
`ifdef SUPPORT_LOOPMODE
    case(loop_mode)
    3'd0: begin dir <= iir; dpc <= ipc2; dilen <= ilenr; dbrpred <= ibrpred; end // loop mode not active
    3'd1: ;//begin ir <= rir; dpc <= rpc; dilen <= rilen; dbrpred <= rbrpred; end
    3'd2: begin dir <= eir; dpc <= expc; dilen <= eilen; dbrpred <= TRUE; pc <= pc; end
    3'd3: begin dir <= mir; dpc <= mpc; dilen <= milen; dbrpred <= TRUE; pc <= pc; end
    3'd4: begin dir <= wir; dpc <= wpc; dilen <= wilen; dbrpred <= TRUE; pc <= pc; end
    3'd5: begin dir <= tir; dpc <= tpc; dilen <= tilen; dbrpred <= TRUE; pc <= pc; end
    3'd6: begin dir <= uir; dpc <= upc; dilen <= uilen; dbrpred <= TRUE; pc <= pc; end
    3'd7: begin dir <= vir; dpc <= vpc; dilen <= vilen; dbrpred <= TRUE; pc <= pc; end
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
if (advance_d) begin
  illegal_insn <= TRUE;
  dwrirf <= FALSE;
  dwrcrf <= FALSE;
  dBf <= 3'd0;
  dRt <= dir[25:21];
  dRa <= dir[20:16];
  dRb <= dir[15:11];
  dRc <= dir[10: 6];
  d_ld <= FALSE;
  d_st <= FALSE;
  case(dcyc)
  2'd0:
    case(dir[31:26])
    `R2:
      case(dir[10:1])
      `CMP:
        begin dBf <= dir[25:23]; dwrcrf <= TRUE; illegal_insn <= FALSE; end
      `ADD,`ADDO,`SUBF,`SUBFO:
        begin dwrirf <= TRUE; dwrcrf <= dir[0]; illegal_insn <= FALSE; end
      `AND,`OR,`XOR,`NAND,`NOR,`EQV:
        begin dwrirf <= TRUE; dwrcrf <= dir[0]; illegal_insn <= FALSE; end
      endcase
    `ADDI:
      begin dwrirf <= TRUE; illegal_insn <= FALSE; end
    `ANDI:
      begin dwrirf <= TRUE; illegal_insn <= FALSE; dimm <= {16'hFFFF,dir[15:0]}; end
    `ORI,`XORI:
      begin dwrirf <= TRUE; illegal_insn <= FALSE; dimm <= {16'h0000,dir[15:0]}; end
    `LBZ,`LWZ:
      begin
        d_ld <= TRUE;
      end
    `LBZU
      begin
        d_ld <= TRUE:
        d_ldbu <= TRUE;
      end
    `LWZU:
      begin
        d_ld <= TRUE:
        d_ldzu <= TRUE;
      end
    `STB,`STW:
      begin
        d_st <= TRUE:
      end
    `STBU:
      begin
        d_st <= TRUE:
        d_stbu <= TRUE;
      end
    `STWU:
      begin
        d_st <= TRUE:
        d_stwu <= TRUE;
      end
    endcase
  2'd1:
    case(1'b1)
    d_ldbu,d_stbu:
      begin
        dir <= {1'b1,`ADDI,dRa,21'd0};
        dcyc <= 2'd0;
      end
    endcase
  endcase
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register fetch stage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

task tRegfetch;
begin
  if (advance_r) begin
    if (dRd==5'd0 && (d_ld|d_st))
      id <=32'd0;
    else if (dRd==eRt)
      id <= eres;
    else if (dRd==mRt)
      id <= mres;
    else if (dRd==wRt)
      id <= wres;

    if (dRa==5'd0 && (d_ld|d_st))
      ia <=32'd0;
    else if (dRa==eRt)
      ia <= eres;
    else if (dRa==mRt)
      ia <= mres;
    else if (dRa==wRt)
      ia <= wres;

    if (dRb==5'd0 && (d_ld|d_st))
      ib <=32'd0;
    else if (dRb==eRt)
      ib <= eres;
    else if (dRb==mRt)
      ib <= mres;
    else if (dRb==wRt)
      ib <= wres;

    if (dRc==5'd0 && (d_ld|d_st))
      ic <=32'd0;
    else if (dRc==eRt)
      ic <= eres;
    else if (dRc==mRt)
      ic <= mres;
    else if (dRc==wRt)
      ic <= wres;
  end
end
endtask

endmodule
