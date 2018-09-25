// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_fetchbuf_x1.v
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
//
`include "FT64_config.vh"
`include "FT64_defines.vh"

// FETCH
//
// fetch exactly one instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
//
module FT64_fetchbuf_x1(rst, clk4x, clk, fcu_clk,
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i,
	cmpgrp,
	freezePC, thread_en,
	regLR,
    insn0, phit,
    threadx,
    branchmiss, misspc, branchmiss_thrd, predict_taken0,
    predict_takenA, predict_takenB,
    queued1, queuedNop,
    pc0, fetchbuf, fetchbufA_v, fetchbufB_v,
    fetchbufA_instr, fetchbufA_pc,
    fetchbufB_instr, fetchbufB_pc,
    fetchbuf0_instr, fetchbuf0_insln,
    fetchbuf0_thrd,
    fetchbuf0_pc,
    fetchbuf0_v,
    codebuf0,
    btgtA, btgtB,
    nop_fetchbuf,
    take_branch0,
    stompedRets,
    panic
);
parameter AMSB = `AMSB;
parameter RSTPC = 32'hFFFC0100;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk4x;
input clk;
input fcu_clk;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [15:0] adr_i;
input [47:0] dat_i;
input [2:0] cmpgrp;
input freezePC;
input thread_en;
input [4:0] regLR;
input [47:0] insn0;
input phit;
output threadx;
input branchmiss;
input [AMSB:0] misspc;
input branchmiss_thrd;
output predict_taken0;
input predict_takenA;
input predict_takenB;
input queued1;
input queuedNop;
output reg [AMSB:0] pc0;
output reg fetchbuf;
output reg fetchbufA_v;
output reg fetchbufB_v;
output fetchbuf0_thrd;
output reg [47:0] fetchbufA_instr;
output reg [47:0] fetchbufB_instr;
output reg [AMSB:0] fetchbufA_pc;
output reg [AMSB:0] fetchbufB_pc;
output [47:0] fetchbuf0_instr;
output [AMSB:0] fetchbuf0_pc;
output [2:0] fetchbuf0_insln;
output fetchbuf0_v;
input [47:0] codebuf0;
input [AMSB:0] btgtA;
input [AMSB:0] btgtB;
input [3:0] nop_fetchbuf;
output take_branch0;
input [3:0] stompedRets;
output reg [3:0] panic;
integer n;

//`include "FT64_decode.vh"

function IsBranch;
input [47:0] isn;
casex(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
`BCHK:	IsBranch = TRUE;
default: IsBranch = FALSE;
endcase
endfunction

function IsJmp;
input [47:0] isn;
IsJmp = isn[`INSTRUCTION_OP]==`JMP;
endfunction

function IsCall;
input [47:0] isn;
IsCall = isn[`INSTRUCTION_OP]==`CALL;
endfunction

function IsRet;
input [47:0] isn;
IsRet = isn[`INSTRUCTION_OP]==`RET;
endfunction

function IsRTI;
input [47:0] isn;
IsRTI = isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_S2]==`RTI;
endfunction

function [2:0] fnInsLength;
input [47:0] ins;
`ifdef SUPPORT_DCI
if (ins[`INSTRUCTION_OP]==`CMPRSSD)
	fnInsLength = 3'd2;
else
`endif
	case(ins[7:6])
	2'd0:	fnInsLength = 3'd4;
	2'd1:	fnInsLength = 3'd6;
	default:	fnInsLength = 3'd2;
	endcase
endfunction

wire [2:0] fetchbufA_inslen;
wire [2:0] fetchbufB_inslen;
FT64_InsLength uilA (fetchbufA_instr, fetchbufA_inslen);
FT64_InsLength uilB (fetchbufB_instr, fetchbufB_inslen);

wire [47:0] xinsn0;

FT64_iexpander ux1
(
	.cinstr(insn0[15:0]),
	.expand(xinsn0)
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Table of decompressed instructions.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
assign ack_o = cs_i & cyc_i & stb_i;
`ifdef SUPPORT_DCI
reg [47:0] DecompressTable [0:2047];
always @(posedge clk)
	if (cs_i & cyc_i & stb_i & we_i)
		DecompressTable[adr_i[12:3]] <= dat_i[47:0];
wire [47:0] expand0 = DecompressTable[{cmpgrp,insn0[15:8]}];
`endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg thread;
reg stompedRet;
reg ret0Counted;
wire [AMSB:0] retpc0;

reg did_branchback0;

assign predict_taken0 = (fetchbuf==1'b0) ? predict_takenA : predict_takenB;

reg [AMSB:0] branch_pcA;
reg [AMSB:0] branch_pcB;

always @*
case(fetchbufA_instr[`INSTRUCTION_OP])
`RET:		branch_pcA = retpc0;
`JMP,`CALL: branch_pcA = fetchbufA_instr[6] ? {fetchbufA_instr[39:8],1'b0} : {fetchbufA_pc[31:25],fetchbufA_instr[31:8],1'b0};
`R2:		branch_pcA = btgtA;	// RTI
`BRK,`JAL:	branch_pcA = btgtA;
default:	branch_pcA = fetchbufA_pc + {{20{fetchbufA_instr[31]}},fetchbufA_instr[31:21],1'b0} + fetchbufA_inslen;
endcase

always @*
case(fetchbufB_instr[`INSTRUCTION_OP])
`RET:		branch_pcB = retpc0;
`JMP,`CALL: branch_pcB = fetchbufB_instr[6] ? {fetchbufB_instr[39:8],1'b0} : {fetchbufB_pc[31:25],fetchbufB_instr[31:8],1'b0};
`R2:		branch_pcB = btgtB;	// RTI
`BRK,`JAL:	branch_pcB = btgtB;
default:	branch_pcB = fetchbufB_pc + {{20{fetchbufB_instr[31]}},fetchbufB_instr[31:21],1'b0} + fetchbufB_inslen;
endcase

wire take_branchA = ({fetchbufA_v, IsBranch(fetchbufA_instr), predict_takenA}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufA_instr)||IsJmp(fetchbufA_instr)||IsCall(fetchbufA_instr)||
                        IsRTI(fetchbufA_instr)|| fetchbufA_instr[`INSTRUCTION_OP]==`BRK || fetchbufA_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufA_v);
wire take_branchB = ({fetchbufB_v, IsBranch(fetchbufB_instr), predict_takenB}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufB_instr)|IsJmp(fetchbufB_instr)|IsCall(fetchbufB_instr) ||
                        IsRTI(fetchbufB_instr)|| fetchbufB_instr[`INSTRUCTION_OP]==`BRK || fetchbufB_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufB_v);

wire take_branch = fetchbuf==1'b0 ? take_branchA : take_branchB;
assign take_branch0 = take_branch;

/*
always @*
begin
	pc0 <= thread_en ? (fetchbuf ? pc0b : pc0a) : pc0a;
	pc1 <= thread_en ? (fetchbuf ? pc1b : pc1a) : pc1a;
end
*/
assign threadx = fetchbuf;

`ifdef FCU_ENH
FT64_RSB #(AMSB) ursb1
(
	.rst(rst),
	.clk(fcu_clk),
	.regLR(regLR),
	.queued1(queued1),
	.queued2(1'b0),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf0_pc(fetchbuf0_pc),
	.fetchbuf0_instr(fetchbuf0_instr),
	.fetchbuf1_v(1'b0),
	.fetchbuf1_pc(RSTPC),
	.fetchbuf1_instr(`NOP_INSN),
	.stompedRets(stompedRets),
	.stompedRet(stompedRet),
	.pc(retpc0)
);

`else
assign retpc0 = RSTPC;
assign retpc1 = RSTPC;
`endif

wire peclk, neclk;
edge_det ued1 (.rst(rst), .clk(clk4x), .ce(1'b1), .i(clk), .pe(peclk), .ne(neclk), .ee());

always @(posedge clk)
if (rst) begin
	pc0 <= RSTPC;
	fetchbufA_v <= 0;
	fetchbufB_v <= 0;
	fetchbuf <= 0;
	panic <= `PANIC_NONE;
end
else begin
	
	did_branchback0 <= take_branch0;

	begin

	// On a branch miss with threading enabled all fectch buffers are
	// invalidated even though the data in the fetch buffer would be valid
	// for the thread that isn't in a branchmiss state. This is done to
	// keep things simple. For the thread that doesn't miss the current
	// data for the fetch buffer needs to be retrieved again, so the pc
	// for that thread is assigned the current fetchbuf pc.
	// For the thread that misses the pc is simply assigned the misspc.
	if (branchmiss) begin
		$display("***********");
		$display("Branch miss");
		$display("***********");
		pc0 <= misspc;
		fetchbufA_v <= `INV;
		fetchbufB_v <= `INV;
		fetchbuf <= 1'b0;
	     $display("********************");
	     $display("********************");
	     $display("********************");
	     $display("Branch miss");
	     $display("misspc=%h", misspc);
	     $display("********************");
	     $display("********************");
	     $display("********************");
	end
	else if (take_branch) begin
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v})
		2'b00: ;	// do nothing
//		2'b01	: panic <= `PANIC_INVALIDFBSTATE;
		2'b10:
			begin
				pc0 <= branch_pcA;
			  fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
			  fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		2'b11:
			begin
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufB_v <= `INV;
	      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
    default:    ;
	  endcase
    else case ({fetchbufB_v, fetchbufA_v})
		2'b00: ; // do nothing
		2'b10:
			begin
				pc0 <= branch_pcB;
			  fetchbufB_v <= !(queued1|queuedNop);
			  fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		2'b11:
			begin
				pc0 <= branch_pcB;
				fetchbufB_v <= !(queued1|queuedNop);
				fetchbufA_v <= `INV;
	      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
    default:    ;
    endcase

	end // if branchback

	else begin	// there is no branchback in the system
    // update fetchbufX_v and fetchbuf ... relatively simple, as
    // there are no backwards branches in the mix
	  if (fetchbuf == 1'b0) case ({fetchbufA_v, (queued1|queuedNop)})
		2'b00: ;	// do nothing
		2'b10: ;
		2'b11: begin fetchbufA_v <= `INV; fetchbuf <= ~fetchbuf; end
		default:  panic <= `PANIC_INVALIDIQSTATE;
		endcase
	  else case ({fetchbufB_v, (queued1|queuedNop)})
		2'b00: ;	// do nothing
		2'b10: ;
		2'b11: begin fetchbufB_v <= `INV; fetchbuf <= ~fetchbuf; end
		default:  panic <= `PANIC_INVALIDIQSTATE;
		endcase
    //
    // get data iff the fetch buffers are empty
    //
    if (fetchbufA_v == `INV) begin
        FetchA();
        // fetchbuf steering logic correction
        if (fetchbufB_v==`INV && phit)
          fetchbuf <= 1'b0;
    end
    else if (fetchbufB_v == `INV)
	    FetchB();
	end
  //
  // get data iff the fetch buffers are empty
  //
  if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
  	FetchA();
    fetchbuf <= 1'b0;
  end
end
	
	// The fetchbuffer is invalidated at the end of a vector instruction
	// queue.
	if (nop_fetchbuf[0])  fetchbufA_v <= `INV;
	if (nop_fetchbuf[1])  fetchbufB_v <= `INV;
end

assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufB_instr;
assign fetchbuf0_insln = (fetchbuf == 1'b0) ? fetchbufA_inslen: fetchbufB_inslen;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufB_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufB_pc   ;
assign fetchbuf0_thrd  = 1'b0;

reg [2:0] insln0;
always @*
begin
`ifdef SUPPORT_DCI
	if (insn0[5:0]==`CMPRSSD)
		insln0 <= 3'd2;
	else
`endif
	if (insn0[7:6]==2'b00 && insn0[`INSTRUCTION_OP]==`EXEC)
		insln0 <= fnInsLength(codebuf0);
	else
		insln0 <= fnInsLength(insn0);
end

reg [47:0] cinsn0;

always @*
begin
`ifdef SUPPORT_DCI
	if (insn0[5:0]==`CMPRSSD)
		cinsn0 <= expand0;
	else
`endif
	if (insn0[7:6]==2'b00 && insn0[`INSTRUCTION_OP]==`EXEC)
		cinsn0 <= codebuf0;
	else if (insn0[7])
		cinsn0 <= xinsn0;
	else
		cinsn0 <= insn0;
end

task FetchA;
begin
	fetchbufA_instr <= cinsn0;
	fetchbufA_v <= `VAL;
	fetchbufA_pc <= pc0;
	if (phit && ~freezePC)
		pc0 <= pc0 + insln0;
end
endtask

task FetchB;
begin
	fetchbufB_instr <= cinsn0;
	fetchbufB_v <= `VAL;
	fetchbufB_pc <= pc0;
	if (phit && ~freezePC)
		pc0 <= pc0 + insln0;
end
endtask

endmodule

