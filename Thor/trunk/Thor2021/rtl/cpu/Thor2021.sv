// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021oo.sv
// Thor2021 processor implementation.
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
`define SIM   1'b1
import Thor2021_pkg::*;
import fp::*;

module Thor2021oo(hartid_i, rst_i, clk_i, clk2x_i, clk4x_i, wc_clk_i,
	nmi_i, irq_i, cause_i,
	vpa_o, vda_o, bte_o, cti_o, bok_i, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o,
	dat_i, dat_o, sr_o, cr_o, rb_i);
input [63:0] hartid_i;
input rst_i;
input clk_i;
input clk2x_i;
input clk4x_i;
input wc_clk_i;
input nmi_i;
input [2:0] irq_i;
input [7:0] cause_i;
output vpa_o;
output vda_o;
output [1:0] bte_o;
output [2:0] cti_o;
input bok_i;
output cyc_o;
output stb_o;
input ack_i;
output we_o;
output [15:0] sel_o;
output [31:0] adr_o;
input [127:0] dat_i;
output [127:0] dat_o;
output sr_o;		// set memory reservation
output cr_o;		// clear memory reservation
input rb_i;					// input memory still reserved bit

wire [567:0] ic_line;
Address ip;

reg [63:0] gdt;

sInstAlignOut iaout;

// CSRs
reg [63:0] cr0;
wire dce;
reg [7:0] asid;
reg [20:0] keys [0:7];

Thor2021_ialign uialgn
(
	.ip(ip),
	.cacheline(ic_line),
	.o0(iaout),
	.o1(),
	.o2()
);

Thor2021_gselectPredictor ugspred
(
	.rst(rst_i),
	.clk(clk_g),
	.en(),
	.xisBranch(),
	.xip(),
	.takb(),
	.ip(ip),
	.predict_taken()
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Branch target buffer.
//
// Access to the branch target buffer must be within one clock cycle, so it
// is composed of LUT ram.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Thor2021_btb ubtb
(
	.rst(rst_i),
	.clk(clk_g),
	.clk2x(clk2x_i),
	.clk4x(clk4x_i),
	.wr0(),
	.wadr0(),
	.wdat0(),
	.valid0(),
	.wr1(1'b0),
	.wadr1(64'd0),
	.wdat1(64'd0),
	.valid1(1'b0),
	.wr2(1'b0),
	.wadr2(64'd0),
	.wdat2(64'd0),
	.valid2(1'b0),
	.rclk(~clk_g),
	.pcA(ip),
	.btgtA(ip_tgtA),
	.pcB(64'd0),
	.btgtB(),
	.pcC(64'd0),
	.btgtC(),
	.hitA(),
	.hitB(),
	.hitC(),
	.npcA(ip+iaout.len),
	.npcB(64'd0),
	.npcC(64'd0)
);

Thor2021_biu umemc
(
	.rst(rst_i),
	.clk(clk_g),
	.tlbclk(clk2x_i),
	.UserMode,
	.MUserMode,
	.omode,
	.ASID(asid),
	.ea_seg(),
	.bounds_chk(),
	.pe(),
	.sregfile(),
	.cs(),
	.ip(ip),
	.ihit(),
	.ifStall(),
	.ic_line(ic_line),
	.fifoToCtrl_i(),
	.fifoToCtrl_full_o(),
	.fifoFromCtrl_o(),
	.fifoFromCtrl_rd(),
	.fifoFromCtrl_empty(),
	.fifoFromCtrl_v(),
	.bok_i(bok_i),
	.bte_o(bte_o),
	.cti_o(cti_o),
	.vpa_o(vpa_o),
	.vda_o(vda_o),
	.cyc_o(cyc_o),
	.stb_o(stb_o),
	.ack_i(ack_i),
	.we_o(we_o),
	.sel_o(sel_o),
	.adr_o(adr_o),
	.dat_i(dat_i),
	.dat_o(dat_o),
	.sr_o(sr_o),
	.cr_o(cr_o),
	.rb_i(rb_i),
	.dce(),
	.keys(keys),
	.arange(),
	.gdt(gdt),
	.ldt()
);

Value argA[QSLOTS-1:0];
Value argB[QSLOTS-1:0];
Value argC[QSLOTS-1:0];
Value argD[QSLOTS-1:0];

// link registers are never argA
integer n1;
always_comb
for (n1 = 0; n1 < QSLOTS; n1 = n1 + 1)
	casez(Ra[n1])
	8'b00??????:	argA[n1] <= gp_rfoa[n1];
	8'b01??????:	argA[n1] <= vc_rfoa[n1];
	8'b1000???0:	argA[n1] <= ca_rfoa[n1][63:0];
	8'b1000???1:	argA[n1] <= {32'd0,ca_rfoa[n1][95:64]};
	8'b1001????:	argA[n1] <= sel_rfoa[n1];
	8'b10100???:	argA[n1] <= vm_rfoa[n1];
	8'b10101000:	argA[n1] <= vl_regx;			// for move
	default:			argA[n1] <= 64'd0;
	endcase

integer n2;
always_comb
for (n2 = 0; n2 < QSLOTS; n2 = n2 + 1)
	casez(Rb[n2])
	8'b00??????:	argB[n2] <= gp_rfoa[n2];
	8'b01??????:	argB[n2] <= vc_rfoa[n2];
	8'b10100???:	argB[n2] <= vm_rfoa[n2];
	default:			argB[n2] <= 64'd0;
	endcase
	
integer n3;
always_comb
for (n3 = 0; n3 < QSLOTS; n3 = n3 + 1)
	casez(Rc[n3])
	8'b00??????:	argB[n3] <= gp_rfoa[n3];
	8'b01??????:	argB[n3] <= vc_rfoa[n3];
	8'b10100???:	argB[n3] <= vm_rfoa[n3];
	default:			argB[n3] <= 64'd0;
	endcase
	
integer n4;
always_comb
for (n4 = 0; n4 < QSLOTS; n4 = n4 + 1)
	casez(Rc[n4])
	8'b00??????:	argB[n4] <= gp_rfoa[n4];
	8'b01??????:	argB[n4] <= vc_rfoa[n4];
	default:			argB[n4] <= 64'd0;
	endcase
	

`ifdef SIM
	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("%b %h #", ip_mask, ip);
	$display("%b %h #", ip_mask, ipd);
    $display ("--------------------------------------------------------------------- Regfile: %d ---------------------------------------------------------------------", rgs);
	for (n=0; n < 32; n=n+4) begin
	    $display("%d: %h %d %o   %d: %h %d %o   %d: %h %d %o   %d: %h %d %o#",
	       n[4:0]+0, urf1.mem[{rgs,n[4:2],2'b00}], regIsValid[n+0], rf_source[n+0],
	       n[4:0]+1, urf1.mem[{rgs,n[4:2],2'b01}], regIsValid[n+1], rf_source[n+1],
	       n[4:0]+2, urf1.mem[{rgs,n[4:2],2'b10}], regIsValid[n+2], rf_source[n+2],
	       n[4:0]+3, urf1.mem[{rgs,n[4:2],2'b11}], regIsValid[n+3], rf_source[n+3]
	       );
	end
`ifdef FCU_ENH
	$display("Call Stack:");
	for (n = 0; n < 16; n = n + 4)
		$display("%c%d: %h   %c%d: %h   %c%d: %h   %c%d: %h",
			ursb1.rasp==n+0 ?">" : " ", n[4:0]+0, ursb1.ras[n+0],
			ursb1.rasp==n+1 ?">" : " ", n[4:0]+1, ursb1.ras[n+1],
			ursb1.rasp==n+2 ?">" : " ", n[4:0]+2, ursb1.ras[n+2],
			ursb1.rasp==n+3 ?">" : " ", n[4:0]+3, ursb1.ras[n+3]
		);
	$display("\n");
`endif
//    $display("Return address stack:");
//    for (n = 0; n < 16; n = n + 1)
//        $display("%d %h", rasp+n[3:0], ras[rasp+n[3:0]]);
	$display("TakeBr:%d #", take_branch);//, backpc);
	$display("Insn%d: %h", 0, insnx[0]);
	$display ("------------------------------------------------------------------------ Dispatch Buffer -----------------------------------------------------------------------");
	for (i=0; i<QENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c %d %d %c%c %c %c%h %d,%d %h %h %d %d %d %h %d %d %d %h %d %d %d %h %o %h#",
		 (i[`QBITS]==heads[0])?"C":".",
		 (i[`QBITS]==tails[0])?"Q":".",
		  i[`QBITS],
		  iq_state[i]==IQS_INVALID ? "-" :
		  iq_state[i]==IQS_QUEUED ? "Q" :
		  iq_state[i]==IQS_OUT ? "O"  :
		  iq_state[i]==IQS_AGEN ? "A"  :
		  iq_state[i]==IQS_MEM ? "M"  :
		  iq_state[i]==IQS_DONE ? "D"  :
		  iq_state[i]==IQS_CMT ? "C"  : "?",
//		 iq_v[i] ? "v" : "-",
		 iq_done[i]?"d":"-",
		 iq_out[i]?"o":"-",
		 iq_bt[i],
		 iq_memissue[i],
		 iq_agen[i] ? "a": "-",
		 iq_alu0_issue[i]?"0":iq_alu1_issue[i]?"1":"-",
		 iq_stomp[i]?"s":"-",
		iq_fc[i] ? "F" : iq_mem[i] ? "M" : (iq_alu[i]==1'b1) ? "a" : iq_fpu[i] ? "f" : "O", 
		iq_instr[i], iq_tgt[i][5:0], iq_tgt[i][5:0],
		iq_argI[i],
		iq_argA[i], iq_rs1[i], iq_argA_v[i], iq_argA_s[i],
		iq_argB[i], iq_rs2[i], iq_argB_v[i], iq_argB_s[i],
		iq_argC[i], iq_rs3[i], iq_argC_v[i], iq_argC_s[i],
		iq_ip[i],
		iq_sn[i],
		iq_br_tag[i]
		);
	$display ("------------- Reorder Buffer ------------");
	for (i = 0; i < RENTRIES; i = i + 1)
	$display("%c%c %d(%d): %c %h %d %h#",
		 (i[`RBITS]==rob_heads[0])?"C":".",
		 (i[`RBITS]==rob_tails[0])?"Q":".",
		  i[`RBITS],
		  rob_id[i],
		  rob_state[i]==RS_INVALID ? "-" :
		  rob_state[i]==RS_ASSIGNED ? "A"  :
		  rob_state[i]==RS_CMT ? "C"  : "D",
		  rob_exc[i],
		  rob_tgt[i],
		  rob_res[i]
		);
    $display("DRAM");
	$display("%d %h %h %c%h %o #",
	    dram0, dram0_addr, dram0_data, (IsFlowCtrl(dram0_instr) ? 98 : (IsMem(dram0_instr)) ? 109 : 97), 
	    dram0_instr, dram0_id);
	  if (`NUM_MEM > 1)
	$display("%d %h %h %c%h %o #",
	    dram1, dram1_addr, dram1_data, (IsFlowCtrl(dram1_instr) ? 98 : (IsMem(dram1_instr)) ? 109 : 97), 
	    dram1_instr, dram1_id);
	$display("%d %h %o #", dramA_v, dramA_bus, dramA_id);
	if (`NUM_MEM > 1)
	$display("%d %h %o #", dramB_v, dramB_bus, dramB_id);
    $display("ALU");
	$display("%d %h %h %h %c%h %o %h #",
		alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
		 (IsFlowCtrl(alu0_instr) ? 98 : IsMem(alu0_instr) ? 109 : 97),
		alu0_instr, alu0_sourceid, alu0_ip);
	$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
	if (`NUM_ALU > 1) begin
		$display("%d %h %h %h %c%h %o %h #",
			alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
		 	(IsFlowCtrl(alu1_instr) ? 98 : IsMem(alu1_instr) ? 109 : 97),
			alu1_instr, alu1_sourceid, alu1_ip);
		$display("%d %h %o 0 #", alu1_v, alu1_bus, alu1_id);
	end
	$display("FCU");
	$display("%d %h %h %h %h %c%c #", fcu_v, fcu_bus, fcu_argI, fcu_argA, fcu_argB, fcu_takb?"T":"-", fcu_pt?"T":"-");
	$display("%c %h %h %h %h #", fcu_branchmiss?"m":" ", fcu_sourceid, fcu_missip, fcu_nextip, fcu_brdisp); 
    $display("Commit");
	$display("0: %c %h %o %d #", commit0_v?"v":" ", commit0_bus, commit0_id, commit0_tgt[5:0]);
	$display("1: %c %h %o %d #", commit1_v?"v":" ", commit1_bus, commit1_id, commit1_tgt[5:0]);
    $display("instructions committed: %d valid committed: %d ticks: %d ", CC, I, tick);
  $display("Write Buffer:");
  for (n = `WB_DEPTH-1; n >= 0; n = n - 1)
  	$display("%c adr: %h dat: %h", wb_v[n]?" ":"*", wb_addr[n], uwb1.wb_data[n]);
    //$display("Write merges: %d", wb_merges);
`endif	// SIM

	$display("");

	if (|panic) begin
    $display("");
    $display("-----------------------------------------------------------------");
    $display("-----------------------------------------------------------------");
    $display("---------------     PANIC:%s     -----------------", message[panic]);
    $display("-----------------------------------------------------------------");
    $display("-----------------------------------------------------------------");
    $display("");
    $display("instructions committed: %d", I);
    $display("total execution cycles: %d", $time / 10);
    $display("");
	end
	if (|panic && ~outstanding_stores) begin
    $finish;
	end

end	// clock domwain

// ============================================================================
// ============================================================================
// Start of Tasks
// ============================================================================
// ============================================================================

task setargs;
input [`QBITS] nn;
input [`RBITSP1] id;
input v;
input Value bus;
begin
  if (rob[nn].argA_v == INV && rob[nn].argA_s[`RBITSP1] == id && rob[nn].v == VAL && v == VAL) begin
		rob[nn].argA <= bus;
		rob[nn].argA_v <= VAL;
  end
  if (rob[nn].argB_v == INV && rob[nn].argB_s[`RBITSP1] == id && rob[nn].v == VAL && v == VAL) begin
		rob[nn].argB <= bus;
		rob[nn].argB_v <= VAL;
  end
  if (rob[nn].argC_v == INV && rob[nn].argC_s[`RBITSP1] == id && rob[nn].v == VAL && v == VAL) begin
		rob[nn].argC <= bus;
		rob[nn].argC_v <= VAL;
  end
end
endtask


// Important to use the correct assignment type for the following, otherwise
// The read won't happen until the clock cycle.
task tReadCSR;
output Value res;
input [15:0] regno;
begin
	if (regno[13:12] <= omode) begin
		casez(regno[13:0])
		CSR_SCRATCH:	res.val = scratch[regno[13:12]];
		CSR_MCR0:	res.val = cr0|(dce << 5'd30);
		CSR_MHARTID: res.val = hartid_i;
		CSR_KEYTBL:	res.val = keytbl;
		CSR_KEYS:	 res.val = keys[regno[2:0]];
		CSR_SEMA: res.val = sema;
		CSR_FSTAT:	res.val = fpscr;
		CSR_ASID:	res.val = ASID;
		CSR_BADADDR:	res.val = badaddr[regno[13:12]];
		CSR_TICK:	res.val = tick;
		CSR_CAUSE:	res.val = cause[regno[13:12]];
		CSR_MTVEC:	res.val = tvec[regno[1:0]];
		CSR_MPMSTACK:	res.val = pmStack;
		CSR_MVSTEP:	res.val = estep;
		CSR_MVTMP:	res.val = vtmp;
		CSR_MSP:	res.val = msp;
		CSR_TIME:	res.val = wc_time;
		CSR_MSTATUS:	res.val = status[3];
		CSR_MTCBPTR:	res.val = tcbptr;
		CSR_MSTUFF0:	res.val = stuff0;
		CSR_MSTUFF1:	res.val = stuff1;
		CSR_MGDT:	res.val = gdt;
		CSR_MLDT:	res.val = ldt;
		default:	res.val = 64'd0;
		endcase
	end
	else
		res = 64'd0;
end
endtask

task tWriteCSR;
input Value val;
input [15:0] regno;
begin
	if (regno[13:12] <= omode) begin
		casez(regno[13:0])
		CSR_SCRATCH:	scratch[regno[13:12]] <= val;
		CSR_MCR0:		begin cr0 <= val; dce <= val[30]; end
		CSR_SEMA:		sema <= val;
		CSR_KEYTBL:	keytbl <= val;
		CSR_KEYS:		keys[regno[2:0]] <= val;
		CSR_FSTAT:	fpscr <= val;
		CSR_ASID: 	ASID <= val;
		CSR_BADADDR:	badaddr[regno[13:12]] <= val;
		CSR_CAUSE:	cause[regno[13:12]] <= val;
		CSR_MTVEC:	tvec[regno[1:0]] <= val;
		CSR_MPMSTACK:	pmStack <= val;
		CSR_MVSTEP:	estep <= val;
		CSR_MVTMP:	begin new_vtmp <= val; ld_vtmp <= TRUE; end
		CSR_MSP:	msp <= val;
		CSR_MTIME:	begin wc_time_dat <= val; ld_time <= TRUE; end
		CSR_MSTATUS:	status[3] <= val.val;
		CSR_MTCBPTR:	tcbptr <= val;
		CSR_MSTUFF0:	stuff0 <= val;
		CSR_MSTUFF1:	stuff1 <= val;
		CSR_MGDT:	gdt <= val;
		CSR_MLDT:	ldt <= val[31:0];
		default:	;
		endcase
	end
end
endtask

task tSetbitCSR;
input Value val;
input [15:0] regno;
begin
	if (regno[13:12] <= omode) begin
		casez(regno[13:0])
		CSR_MCR0:			cr0[val[5:0]] <= 1'b1;
		CSR_SEMA:			sema[val[5:0]] <= 1'b1;
		CSR_MPMSTACK:	pmStack <= pmStack | val;
		CSR_MSTATUS:	status[3] <= status[3] | val;
		default:	;
		endcase
	end
end
endtask

task tClrbitCSR;
input Value val;
input [15:0] regno;
begin
	if (regno[13:12] <= omode) begin
		casez(regno[13:0])
		CSR_MCR0:			cr0[val[5:0]] <= 1'b0;
		CSR_SEMA:			sema[val[5:0]] <= 1'b0;
		CSR_MPMSTACK:	pmStack <= pmStack & ~val;
		CSR_MSTATUS:	status[3] <= status[3] & ~val;
		default:	;
		endcase
	end
end
endtask

endmodule

module decoder8 (num, out);
input [7:0] num;
output [255:1] out;

wire [255:0] out1;

assign out1 = 256'd1 << num;
assign out = out1[255:1];

endmodule
