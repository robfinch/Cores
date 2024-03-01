// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf8088.sv
//	- 8088 compatible CPU
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
//
//  Verilog 
//  Webpack 9.2i xc3s1000 4-ft256
//  2550 slices / 4900 LUTs / 61 MHz
//  650 ff's / 2 MULTs
//
//  Webpack 14.3  xc6slx45 3-csg324
//  884 ff's 5064 LUTs / 79.788 MHz
// ============================================================================

import const_pkg::*;
import fta_bus_pkg::*;
import rf8088_pkg::*;

`include "cycle_types.v"

module rtf8088(rst_i, clk_i, nmi_i, irq_i, csip, bundle, ihit, ftam_req, ftam_resp);

input rst_i;
input clk_i;
input nmi_i;	
input irq_i;
output [31:0] csip;
input [127:0] bundle;
input ihit;

output fta_cmd_request128_t ftam_req;
input fta_cmd_response128_t ftam_resp;

reg    mio_o;
wire   busy_i;

reg [1:0] seg_sel;			// segment selection	0=ES,1=SS,2=CS (or none), 3=DS

e_8088state state;			// machine state
e_8088state substate;
reg hasFetchedModrm;
reg hasFetchedDisp8;
reg hasFetchedDisp16;
reg hasFetchedData;
reg hasStoredData;
reg hasFetchedVector;

reg [15:0] res;				// result bus
wire pres;					// parity result
wire reszw;					// zero word
wire reszb;					// zero byte
wire resnb;					// negative byte
wire resnw;					// negative word
wire resn;
wire resz;

reg [2:0] cyc_type;			// type of bus sycle
reg w;						// 0=8 bit, 1=16 bit
reg d;
reg v;						// 1=count in cl, 0 = count is one
reg [1:0] mod;
reg [2:0] rrr;
reg [2:0] rm;
reg sxi;
reg [2:0] sreg;
reg [1:0] sreg2;
reg [2:0] sreg3;
reg [2:0] TTT;
reg [7:0] lock_insn;
reg [7:0] prefix1;
reg [7:0] prefix2;
reg [7:0] int_num;			// interrupt number to execute
reg [15:0] seg_reg;			// segment register value for memory access
reg [15:0] data16;			// caches data
reg [15:0] disp16;			// caches displacement
reg [15:0] offset;			// caches offset
reg [15:0] selector;		// caches selector
reg [`AMSB:0] ea;				// effective address
reg [39:0] desc;			// buffer for sescriptor
reg [6:0] cnt;				// counter
reg [1:0] S43;
reg wrregs;
reg wrsregs;
wire take_br;
reg [3:0] shftamt;
reg ld_div16,ld_div32;		// load divider
reg div_sign;
reg read_code;
reg [31:0] xlat_adr;
reg bus_cycle_started;
reg [7:0] dat_i;
reg ack_i;
reg rty_i;
reg cyc_done;

reg nmi_armed;
reg rst_nmi;				// reset the nmi flag
wire pe_nmi;				// indicates positive edge on nmi signal

wire RESET = rst_i;
wire CLK = clk_i;
wire NMI = nmi_i;

`include "REGFILE.v"	
`include "CONTROL_LOGIC.v"
`include "which_seg.v"
evaluate_branch u4 (ir,cx,zf,cf,sf,vf,pf,take_br);
`include "c:\cores\bcxa6\rtl\verilog\eight_bit\ALU.v"
nmi_detector u6 (RESET, CLK, NMI, rst_nmi, pe_nmi);

always_comb
	ack_i = ftam_resp.ack;
always_comb
	rty_i = ftam_resp.rty;
always_comb
	dat_i = ftam_resp.dat >> {ea[3:0],3'd0};

always @(posedge CLK)
	if (RESET) begin
		pf <= 1'b0;
		cf <= 1'b0;
		df <= 1'b0;
		vf <= 1'b0;
		zf <= 1'b0;
		ie <= 1'b0;
		hasFetchedModrm <= 1'b0;
		cs <= `CS_RESET;
		ip <= 16'hFFF0;
		ftam_req <= {`bits(fta_cmd_request128_t){1'b0}};
		ir <= `NOP;
		prefix1 <= 8'h00;
		prefix2 <= 8'h00;
		rst_nmi <= 1'b1;
		wrregs <= 1'b0;
		wrsregs <= 1'b0;
		ld_div16 <= 1'b0;
		ld_div32 <= 1'b0;
		read_code <= 1'b0;
		bus_cycle_started <= FALSE;
		cyc_done <= TRUE;
		tGoto(IFETCH);
	end
	else begin
		rst_nmi <= 1'b0;
		wrregs <= 1'b0;
		wrsregs <= 1'b0;
		ld_div16 <= 1'b0;
		ld_div32 <= 1'b0;

		tWriteback();

		case(state)
`include "IFETCH.sv"
`include "DECODE.sv"
`include "DECODER2.sv"
`include "XLAT.sv"
`include "REGFETCHA.sv"
`include "EACALC.sv"
`include "CMPSB.sv"
`include "CMPSW.sv"
`include "MOVS.sv"
`include "LODS.sv"
`include "STOS.sv"
`include "SCASB.sv"
`include "SCASW.sv"
`include "EXECUTE.sv"
`include "FETCH_DATA.sv"
`include "FETCH_DISP8.sv"
`include "FETCH_DISP16.sv"
`include "FETCH_IMMEDIATE.sv"
`include "FETCH_OFFSET_AND_SEGMENT.sv"
`include "MOV_I2BYTREG.sv"
`include "STORE_DATA.sv"
`include "BRANCH.sv"
`include "CALL.sv"
`include "CALLF.sv"
`include "CALL_IN.sv"

`include "INTA.v"
`include "INT.v"
`include "FETCH_STK_ADJ.v"
`include "RETPOP.v"
`include "RETFPOP.v"
`include "IRET.v"
`include "JUMP_VECTOR.v"
`include "PUSH.v"
`include "POP.v"
`include "INB.v"
`include "INW.v"
`include "OUTB.v"
`include "OUTW.v"
`include "INSB.v"
`include "OUTSB.v"
`include "XCHG_MEM.v"
`include "DIVIDE.v"

			default:
				state <= IFETCH;
			endcase
		end

`include "wb_task.v"

task tWriteback;
begin
	if (wrregs)
		case({w,rrr})
		4'b0000:	ax[7:0] <= res[7:0];
		4'b0001:	cx[7:0] <= res[7:0];
		4'b0010:	dx[7:0] <= res[7:0];
		4'b0011:	bx[7:0] <= res[7:0];
		4'b0100:	ax[15:8] <= res[7:0];
		4'b0101:	cx[15:8] <= res[7:0];
		4'b0110:	dx[15:8] <= res[7:0];
		4'b0111:	bx[15:8] <= res[7:0];
		4'b1000:	ax <= res;
		4'b1001:	cx <= res;
		4'b1010:	dx <= res;
		4'b1011:	begin bx <= res; $display("BX <- %h", res); end
		4'b1100:	sp <= res;
		4'b1101:	bp <= res;
		4'b1110:	si <= res;
		4'b1111:	di <= res;
		endcase

	// Write to segment register
	//
	if (wrsregs)
		case(rrr)
		3'd0:	es <= res;
		3'd1:	cs <= res;
		3'd2:	ss <= res;
		3'd3:	ds <= res;
		default:	;
		endcase
	end
endtask

task tGoto;
input e_8088state nst;
begin
	state <= nst;
end
endtask

task tCodeRead;
begin
	bundle <= {8'h90,bundle[127:8]};
end
endtask

task tClearBus;
begin
	ftam_req.cyc <= LOW;
	ftam_req.stb <= LOW;
	ftam_req.we <= LOW;
	ftam_req.sel <= 16'h0;
end
endtask

task tRead;
input [19:0] ad;
begin
	ea <= ad;
	ftam_req.blen <= 6'd0;
	ftam_req.bte <= fta_bus_pkg::LINEAR;
	ftam_req.cti <= fta_bus_pkg::CLASSIC;
	ftam_req.cyc <= HIGH;
	ftam_req.stb <= HIGH;
	ftam_req.sel <= 16'h0001 << ad[3:0];
	ftam_req.we <= LOW;
	ftam_req.adr <= {12'd0,ad};
end
endtask

task tWrite;
input [19:0] ad;
input [7:0] dat;
begin
	ea <= ad;
	ftam_req.blen <= 6'd0;
	ftam_req.bte <= fta_bus_pkg::LINEAR;
	ftam_req.cti <= fta_bus_pkg::CLASSIC;
	ftam_req.cyc <= HIGH;
	ftam_req.stb <= HIGH;
	ftam_req.sel <= 16'h0001 << ad[3:0];
	ftam_req.we <= HIGH;
	ftam_req.adr <= {12'd0,ad};
	ftam_req.data1 <= {16{dat}};
end
endtask

endmodule
