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
