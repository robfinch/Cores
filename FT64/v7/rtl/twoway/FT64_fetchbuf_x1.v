// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
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
	freezePC, thread_en, pred_on,
	regLR,
  insn0, phit,
  threadx,
  branchmiss, misspc, branchmiss_thrd, predict_taken0,
  predict_takenA, predict_takenB,
  queued1, queuedNop,
  pc0, fetchbuf, fetchbufA_v, fetchbufB_v,
  fetchbufA_instr, fetchbufA_pc, fetchbufA_pbyte,
  fetchbufB_instr, fetchbufB_pc, fetchbufB_pbyte,
  fetchbuf0_instr, fetchbuf0_insln,
  fetchbuf0_thrd,
  fetchbuf0_pc,
  fetchbuf0_v,
  fetchbuf0_pbyte,
  codebuf0,
  btgtA, btgtB,
  nop_fetchbuf,
  take_branch0,
  stompedRets,
  panic
);
parameter AMSB = `AMSB;
parameter RSTPC = 64'hFFFFFFFFFFFC0100;
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
input [55:0] dat_i;
input [2:0] cmpgrp;
input freezePC;
input thread_en;
input pred_on;
input [4:0] regLR;
input [55:0] insn0;
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
output reg [7:0] fetchbufA_pbyte;
output reg [47:0] fetchbufB_instr;
output reg [7:0] fetchbufB_pbyte;
output reg [AMSB:0] fetchbufA_pc;
output reg [AMSB:0] fetchbufB_pc;
output [47:0] fetchbuf0_instr;
output [AMSB:0] fetchbuf0_pc;
output [2:0] fetchbuf0_insln;
output fetchbuf0_v;
output [7:0] fetchbuf0_pbyte;
input [55:0] codebuf0;
input [AMSB:0] btgtA;
input [AMSB:0] btgtB;
input [3:0] nop_fetchbuf;
output take_branch0;
input [3:0] stompedRets;
output reg [3:0] panic;
integer n;

reg [55:0] cinsn0;

wire iclk = clk;
//BUFH ucb1 (.I(clk), .O(iclk));

//`include "FT64_decode.vh"

function IsBranch;
input [47:0] isn;
casex(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`BLcc:  IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
`BNEI:  IsBranch = TRUE;
`BCHK:	IsBranch = TRUE;
default: IsBranch = FALSE;
endcase
endfunction

function IsJAL;
input [47:0] isn;
IsJAL = isn[`INSTRUCTION_OP]==`JAL;
endfunction

function IsJmp;
input [47:0] isn;
IsJmp = isn[`INSTRUCTION_OP]==`JMP && isn[7]==1'b0;
endfunction

function IsCall;
input [47:0] isn;
IsCall = isn[`INSTRUCTION_OP]==`CALL && isn[7]==1'b0;
endfunction

function IsRet;
input [47:0] isn;
IsRet = isn[`INSTRUCTION_OP]==`RET;
endfunction

function IsBrk;
input [47:0] isn;
IsBrk = isn[`INSTRUCTION_OP]==`BRK;
endfunction

function IsRTI;
input [47:0] isn;
IsRTI = isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_S2]==`RTI;
endfunction

function IsExec;
input [47:0] isn;
if (isn[7:6]==2'b00)
	case(isn[`INSTRUCTION_OP])
	`R2:
		case(isn[`INSTRUCTION_S2])
		`R1:
			case(isn[22:18])
			`EXEC:	IsExec = TRUE;
			default:	IsExec = FALSE;
			endcase
		default:	IsExec = FALSE;
		endcase
	default:	IsExec = FALSE;
	endcase
else
	IsExec = FALSE;
endfunction

function [2:0] fnInsLength;
input [47:0] ins;
`ifdef SUPPORT_DCI
if (ins[`INSTRUCTION_OP]==`CMPRSSD)
	fnInsLength = 3'd2 | pred_on;
else
`endif
	case(ins[7:6])
	2'd0:	fnInsLength = 3'd4 | pred_on;
	2'd1:	fnInsLength = 3'd6 | pred_on;
	default:	fnInsLength = 3'd2 | pred_on;
	endcase
endfunction

wire [2:0] fetchbufA_inslen;
wire [2:0] fetchbufB_inslen;
FT64_InsLength uilA (fetchbufA_instr, fetchbufA_inslen, pred_on);
FT64_InsLength uilB (fetchbufB_instr, fetchbufB_inslen, pred_on);

wire [47:0] xinsn0;

FT64_iexpander ux1
(
	.cinstr(pred_on ? insn0[23:8] : insn0[15:0]),
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
wire [47:0] expand0 = DecompressTable[{cmpgrp,pred_on ? insn0[23:16]:insn0[15:8]}];
`endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg thread;
reg stompedRet;
reg ret0Counted;
wire [AMSB:0] retpc0;

assign predict_taken0 = (fetchbuf==1'b0) ? ({fetchbufA_v, IsBranch(fetchbufA_instr), predict_takenA}  == {`VAL, `TRUE, `TRUE})
																				 : ({fetchbufB_v, IsBranch(fetchbufB_instr), predict_takenB}  == {`VAL, `TRUE, `TRUE});

reg [AMSB:0] branch_pcA;
reg [AMSB:0] branch_pcB;

always @*
begin
case(fetchbufA_instr[`INSTRUCTION_OP])
`RET:		branch_pcA = retpc0;
`JMP,`CALL:
	begin
`ifdef JMP40
	branch_pcA[39:0] = fetchbufA_instr[6] ? {fetchbufA_instr[47:8]} : {fetchbufA_pc[39:24],fetchbufA_instr[31:8]};
`else
	branch_pcA[39:0] = {fetchbufA_pc[39:24],fetchbufA_instr[31:8]};
`endif
	branch_pcA[63:40] = fetchbufA_pc[63:40];
	end
`R2:		branch_pcA = btgtA;	// RTI
`BRK,`JAL:	branch_pcA = btgtA;
default:
	begin
	branch_pcA[31:0] = fetchbufA_pc[31:0] +
		((fetchbufA_instr[7:6]==2'b01) ? {{4{fetchbufA_instr[47]}},fetchbufA_instr[47:23],fetchbufA_instr[17:16],1'b0} : {{20{fetchbufA_instr[31]}},fetchbufA_instr[31:23],fetchbufA_instr[17:16],1'b0});
	branch_pcA[63:32] = fetchbufA_pc[63:32];
	end
endcase
end

always @*
begin
case(fetchbufB_instr[`INSTRUCTION_OP])
`RET:		branch_pcB = retpc0;
`JMP,`CALL: 
	begin
`ifdef JMP40
		branch_pcB[39:0] = fetchbufB_instr[6] ? {fetchbufB_instr[47:8]} : {fetchbufB_pc[39:24],fetchbufB_instr[31:8]};
`else
		branch_pcB[39:0] = {fetchbufB_pc[39:24],fetchbufB_instr[31:8]};
`endif
		branch_pcB[63:40] = fetchbufB_pc[63:40];
	end
`R2:		branch_pcB = btgtB;	// RTI
`BRK,`JAL:	branch_pcB = btgtB;
default:
	begin
	branch_pcB[31:0] = fetchbufB_pc[31:0] +
		((fetchbufB_instr[7:6]==2'b01) ? {{4{fetchbufB_instr[47]}},fetchbufB_instr[47:23],fetchbufB_instr[17:16],1'b0} : {{20{fetchbufB_instr[31]}},fetchbufB_instr[31:23],fetchbufB_instr[17:16],1'b0});
	branch_pcB[63:32] = fetchbufB_pc[63:32];
	end
endcase
end

wire take_branchA = ({fetchbufA_v, IsBranch(fetchbufA_instr), predict_takenA}  == {`VAL, `TRUE, `TRUE}) || ((
`ifdef FCU_ENH
                           IsRet(fetchbufA_instr)
                        || IsRTI(fetchbufA_instr)|| IsBrk(fetchbufA_instr) || IsJAL(fetchbufA_instr) ||
`endif                      
                           IsJmp(fetchbufA_instr)||IsCall(fetchbufA_instr)) &&
                        fetchbufA_v);
wire take_branchB = ({fetchbufB_v, IsBranch(fetchbufB_instr), predict_takenB}  == {`VAL, `TRUE, `TRUE}) || ((
`ifdef FCU_ENH
                           IsRet(fetchbufB_instr)
                        || IsRTI(fetchbufB_instr)|| IsBrk(fetchbufB_instr) || IsJAL(fetchbufB_instr) ||
`endif                        
                           IsJmp(fetchbufB_instr)||IsCall(fetchbufB_instr)) &&
                        fetchbufB_v);

wire take_branch = (fetchbuf==1'b0) ? take_branchA : take_branchB;
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

reg did_branch;

always @(posedge iclk)
if (rst) begin
	pc0 <= RSTPC;
	fetchbufA_v <= 1'b0;
	fetchbufB_v <= 1'b0;
	fetchbuf <= 1'b0;
	panic <= `PANIC_NONE;
	did_branch <= 1'b0;
end
else begin
	
	did_branch <= take_branch & ~branchmiss;

	begin

	// On a branch miss with threading enabled all fectch buffers are
	// invalidated even though the data in the fetch buffer would be valid
	// for the thread that isn't in a branchmiss state. This is done to
	// keep things simple. For the thread that doesn't miss the current
	// data for the fetch buffer needs to be retrieved again, so the pc
	// for that thread is assigned the current fetchbuf pc.
	// For the thread that misses the pc is simply assigned the misspc.
	if (branchmiss) begin
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
//	else if (cinsn0[`INSTRUCTION_OP]==`CALL || cinsn0[`INSTRUCTION_OP]==`JMP) begin
//		pc0[31:0] = cinsn0[6] ? {cinsn0[47:8]} : {pc0[31:24],cinsn0[31:8]};
//		fetchbufA_v <= `INV;
//		fetchbufB_v <= `INV;
//		fetchbuf <= 1'b0;
//	end
	else if (take_branch) begin
    if (fetchbuf == 1'b0) begin
    	// In this case fetchbufA must be valid, or take_branch wouldn't be.
    	case(fetchbufB_v)
    	1'b0:
    		begin
					pc0 <= branch_pcA;
				  fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				  fetchbuf <= (queued1|queuedNop);
    		end
    	1'b1:
  			if (did_branch) begin
				  fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				  fetchbuf <= (queued1|queuedNop);
				  FetchB();
  			end
  			else
  			begin
					pc0 <= branch_pcA;
				  fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= `INV;
				  fetchbuf <= (queued1|queuedNop);
  			end
    	endcase
		end
    else begin
    	case(fetchbufA_v)
    	1'b0:
    		begin
					pc0 <= branch_pcB;
				  fetchbufB_v <= !(queued1|queuedNop);
				  fetchbuf <= !(queued1|queuedNop);
				end
			1'b1:
				if (did_branch) begin
				  fetchbufB_v <= !(queued1|queuedNop);
				  fetchbuf <= ~(queued1|queuedNop);
				  FetchA();
				end
				else
				begin
					pc0 <= branch_pcB;
				  fetchbufB_v <= !(queued1|queuedNop);
					fetchbufA_v <= `INV;
				  fetchbuf <= !(queued1|queuedNop);
				end
			endcase
		end
	end // if branch

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
    else if (fetchbufB_v == `INV) begin
	    FetchB();
	  end
	end
  //
  // get data iff the fetch buffers are empty
  //
  if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
  	FetchA();
    fetchbuf <= 1'b0;
  end
//  // Steer fetchbuf to the valid buffer.
//  else if (fetchbufB_v == `INV)
//  	fetchbuf <= 1'b0;
//  else if (fetchbufA_v == `INV)
//		fetchbuf <= 1'b1;
//  else if (fetchbufA_v == `INV) begin
//  	FetchA();
//	end
//	else if (fetchbufB_v == `INV) begin
//		FetchB();
//	end
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
assign fetchbuf0_pbyte = (fetchbuf == 1'b0) ? fetchbufA_pbyte : fetchbufB_pbyte;

reg [2:0] insln0;
always @*
begin
`ifdef SUPPORT_DCI
	if (insn0[5:0]==`CMPRSSD)
		insln0 <= 3'd2 | pred_on;
	else
`endif
	if (IsExec(insn0))
		insln0 <= fnInsLength(codebuf0);	//???? should be 4?
	else
		insln0 <= fnInsLength(insn0);
end


always @*
begin
`ifdef SUPPORT_DCI
	if (insn0[13:8]==`CMPRSSD && pred_on)
		cinsn0 <= expand0;
	else if (insn0[5:0]==`CMPRSSD && !pred_on)
		cinsn0 <= expand0;
	else
`endif
	if (IsExec(insn0) && !pred_on)
		cinsn0 <= codebuf0;
	else if (IsExec(insn0[55:8]) && pred_on)
		cinsn0 <= codebuf0;
	else if (insn0[15] & pred_on)
		cinsn0 <= {xinsn0,insn0[7:0]};
	else if (insn0[7] & ~pred_on)
		cinsn0 <= xinsn0;
	else
		cinsn0 <= insn0;
end

task FetchA;
begin
	fetchbufA_instr <= pred_on ? cinsn0[55:8] : cinsn0[47:0];
	fetchbufA_pbyte = cinsn0[7:0];
	fetchbufA_v <= `VAL;
	fetchbufA_pc <= pc0;
	if (phit && ~freezePC)
		pc0 <= pc0 + insln0;
	else
		pc0 <= pc0;
end
endtask

task FetchB;
begin
	fetchbufB_instr <= pred_on ? cinsn0[55:8] : cinsn0[47:0];
	fetchbufB_pbyte = cinsn0[7:0];
	fetchbufB_v <= `VAL;
	fetchbufB_pc <= pc0;
	if (phit && ~freezePC)
		pc0 <= pc0 + insln0;
	else
		pc0 <= pc0;
end
endtask

endmodule
