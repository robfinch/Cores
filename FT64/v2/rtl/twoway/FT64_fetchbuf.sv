// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_fetchbuf.sv
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
`include "FT64_defines.vh"

// FETCH
//
// fetch exactly two instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
// Like to turn this into an independent module at some point.
//
module FT64_fetchbuf(rst, clk4x, clk, 
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i,
	hirq, thread_en,
	regLR,
    insn0, insn1, phit,
    threadx,
    branchmiss, misspc, branchmiss_thrd, predict_taken0, predict_taken1,
    predict_takenA, predict_takenB, predict_takenC, predict_takenD,
    queued1, queued2, queuedNop,
    pc0, pc1, fetchbuf, fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v,
    fetchbufA_instr, fetchbufA_pc,
    fetchbufB_instr, fetchbufB_pc,
    fetchbufC_instr, fetchbufC_pc,
    fetchbufD_instr, fetchbufD_pc,
    fetchbuf0_instr, fetchbuf1_instr,
    fetchbuf0_thrd, fetchbuf1_thrd,
    fetchbuf0_pc, fetchbuf1_pc,
    fetchbuf0_v, fetchbuf1_v,
    codebuf0, codebuf1,
    btgtA, btgtB, btgtC, btgtD,
    nop_fetchbuf,
    take_branch0, take_branch1,
    stompedRets
);
parameter AMSB = 31;
parameter RSTPC = 32'hFFFC0100;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk4x;
input clk;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [15:0] adr_i;
input [31:0] dat_i;
input hirq;
input thread_en;
input [4:0] regLR;
input [31:0] insn0;
input [31:0] insn1;
input phit;
output threadx;
input branchmiss;
input [AMSB:0] misspc;
input branchmiss_thrd;
output predict_taken0;
output predict_taken1;
input predict_takenA;
input predict_takenB;
input predict_takenC;
input predict_takenD;
input queued1;
input queued2;
input queuedNop;
output reg [AMSB:0] pc0;
output reg [AMSB:0] pc1;
output reg fetchbuf;
output reg fetchbufA_v;
output reg fetchbufB_v;
output reg fetchbufC_v;
output reg fetchbufD_v;
output fetchbuf0_thrd;
output fetchbuf1_thrd;
output reg [31:0] fetchbufA_instr;
output reg [31:0] fetchbufB_instr;
output reg [31:0] fetchbufC_instr;
output reg [31:0] fetchbufD_instr;
output reg [AMSB:0] fetchbufA_pc;
output reg [AMSB:0] fetchbufB_pc;
output reg [AMSB:0] fetchbufC_pc;
output reg [AMSB:0] fetchbufD_pc;
output [31:0] fetchbuf0_instr;
output [31:0] fetchbuf1_instr;
output [AMSB:0] fetchbuf0_pc;
output [AMSB:0] fetchbuf1_pc;
output fetchbuf0_v;
output fetchbuf1_v;
input [31:0] codebuf0;
input [31:0] codebuf1;
input [AMSB:0] btgtA;
input [AMSB:0] btgtB;
input [AMSB:0] btgtC;
input [AMSB:0] btgtD;
input [3:0] nop_fetchbuf;
output take_branch0;
output take_branch1;
input [3:0] stompedRets;

integer n;

//`include "FT64_decode.vh"

function IsBranch;
input [31:0] isn;
case(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`PBcc:  IsBranch = TRUE;
`BccR:  IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`PBBc:  IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
`PBEQI: IsBranch = TRUE;
default: IsBranch = FALSE;
endcase
endfunction

function IsJmp;
input [31:0] isn;
IsJmp = isn[`INSTRUCTION_OP]==`JMP;
endfunction

function IsCall;
input [31:0] isn;
IsCall = isn[`INSTRUCTION_OP]==`CALL;
endfunction

function IsRet;
input [31:0] isn;
IsRet = isn[`INSTRUCTION_OP]==`RET;
endfunction

function IsBrk;
input [31:0] isn;
IsBrk = isn[`INSTRUCTION_OP]==`BRK;
endfunction

function IsRTI;
input [31:0] isn;
IsRTI = isn[`INSTRUCTION_OP]==`RR && isn[`INSTRUCTION_S2]==`RTI;
endfunction

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg thread;
reg stompedRet;
reg ret0Counted, ret1Counted;
wire [AMSB:0] retpc0, retpc1;

reg did_branchback0;
reg did_branchback1;

assign predict_taken0 = (fetchbuf==1'b0) ? predict_takenA : predict_takenC;
assign predict_taken1 = (fetchbuf==1'b0) ? predict_takenB : predict_takenD;

wire [AMSB:0] branch_pcA = IsRet(fetchbufA_instr) ? retpc0 :
                         IsJmp(fetchbufA_instr) | IsCall(fetchbufA_instr) ? {fetchbufA_pc[31:28],fetchbufA_instr[31:6],2'b00} :
                         ((IsRTI(fetchbufA_instr) || fetchbufA_instr[`INSTRUCTION_OP]==`BccR || fetchbufA_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufA_instr[`INSTRUCTION_OP]==`JAL) ? btgtA : 
                         fetchbufA_pc + {{19{fetchbufA_instr[`INSTRUCTION_SB]}},fetchbufA_instr[31:21],2'b00} + 64'd4);
wire [AMSB:0] branch_pcB = IsRet(fetchbufB_instr) ? (thread_en ? retpc1 : retpc0) :
                         IsJmp(fetchbufB_instr) | IsCall(fetchbufB_instr) ? {fetchbufB_pc[31:28],fetchbufB_instr[31:6],2'b00} :
                         ((IsRTI(fetchbufB_instr) || fetchbufB_instr[`INSTRUCTION_OP]==`BccR || fetchbufB_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufB_instr[`INSTRUCTION_OP]==`JAL) ? btgtB : 
                         fetchbufB_pc + {{19{fetchbufB_instr[`INSTRUCTION_SB]}},fetchbufB_instr[31:21],2'b00} + 64'd4);
wire [AMSB:0] branch_pcC = IsRet(fetchbufC_instr) ? retpc0 :
                         IsJmp(fetchbufC_instr) | IsCall(fetchbufC_instr) ? {fetchbufC_pc[31:28],fetchbufC_instr[31:6],2'b00} :
                         ((IsRTI(fetchbufC_instr) || fetchbufC_instr[`INSTRUCTION_OP]==`BccR || fetchbufC_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufC_instr[`INSTRUCTION_OP]==`JAL) ? btgtC : 
                         fetchbufC_pc + {{19{fetchbufC_instr[`INSTRUCTION_SB]}},fetchbufC_instr[31:21],2'b00} + 64'd4);
wire [AMSB:0] branch_pcD = IsRet(fetchbufD_instr) ? (thread_en ? retpc1 : retpc0) :
                         IsJmp(fetchbufD_instr) | IsCall(fetchbufD_instr) ? {fetchbufD_pc[31:28],fetchbufD_instr[31:6],2'b00} : 
                         ((IsRTI(fetchbufD_instr) || fetchbufD_instr[`INSTRUCTION_OP]==`BccR ||fetchbufD_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufD_instr[`INSTRUCTION_OP]==`JAL) ? btgtD : 
                         fetchbufD_pc + {{19{fetchbufD_instr[`INSTRUCTION_SB]}},fetchbufD_instr[31:21],2'b00} + 64'd4);
                         
wire take_branchA = ({fetchbufA_v, IsBranch(fetchbufA_instr), predict_takenA}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufA_instr)||IsJmp(fetchbufA_instr)||IsCall(fetchbufA_instr)||
                        IsRTI(fetchbufA_instr)|| fetchbufA_instr[`INSTRUCTION_OP]==`BRK || fetchbufA_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufA_v);
wire take_branchB = ({fetchbufB_v, IsBranch(fetchbufB_instr), predict_takenB}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufB_instr)|IsJmp(fetchbufB_instr)|IsCall(fetchbufB_instr) ||
                        IsRTI(fetchbufB_instr)|| fetchbufB_instr[`INSTRUCTION_OP]==`BRK || fetchbufB_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufB_v);
wire take_branchC = ({fetchbufC_v, IsBranch(fetchbufC_instr), predict_takenC}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufC_instr)|IsJmp(fetchbufC_instr)|IsCall(fetchbufC_instr) ||
                        IsRTI(fetchbufC_instr)|| fetchbufC_instr[`INSTRUCTION_OP]==`BRK || fetchbufC_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufC_v);
wire take_branchD = ({fetchbufD_v, IsBranch(fetchbufD_instr), predict_takenD}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufD_instr)|IsJmp(fetchbufD_instr)|IsCall(fetchbufD_instr) ||
                        IsRTI(fetchbufD_instr)|| fetchbufD_instr[`INSTRUCTION_OP]==`BRK || fetchbufD_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufD_v);

assign take_branch0 = fetchbuf==1'b0 ? take_branchA : take_branchC;
assign take_branch1 = fetchbuf==1'b0 ? take_branchB : take_branchD;
wire take_branch = take_branch0 || take_branch1;
/*
always @*
begin
	pc0 <= thread_en ? (fetchbuf ? pc0b : pc0a) : pc0a;
	pc1 <= thread_en ? (fetchbuf ? pc1b : pc1a) : pc1a;
end
*/
assign threadx = thread_en ? fetchbuf : 1'b0;

FT64_RSB #(AMSB) ursb1
(
	.rst(rst),
	.clk(clk),
	.regLR(regLR),
	.queued1(queued1),
	.queued2(queued2),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf0_pc(fetchbuf0_pc),
	.fetchbuf0_instr(fetchbuf0_instr),
	.fetchbuf1_v(fetchbuf1_v),
	.fetchbuf1_pc(fetchbuf1_pc),
	.fetchbuf1_instr(fetchbuf1_instr),
	.stompedRets(thread_en ? stompedRets : stompedRets[3:1]),
	.stompedRet(stompedRet),
	.pc(retpc0)
);

FT64_RSB #(AMSB) ursb2
(
	.rst(rst),
	.clk(clk),
	.regLR(regLR),
	.queued1(queued1),
	.queued2(1'b0),
	.fetchbuf0_v(fetchbuf1_v),
	.fetchbuf0_pc(fetchbuf1_pc),
	.fetchbuf0_instr(fetchbuf1_instr),
	.fetchbuf1_v(1'b0),
	.fetchbuf1_pc(32'h00000000),
	.fetchbuf1_instr(`NOP_INSN),
	.stompedRets(stompedRets[3:1]),
	.stompedRet(stompedRet),
	.pc(retpc1)
);

wire peclk, neclk;
edge_det ued1 (.rst(rst), .clk(clk4x), .ce(1'b1), .i(clk), .pe(peclk), .ne(neclk), .ee());

always @(posedge clk)
if (rst) begin
	pc0 <= RSTPC;
	pc1 <= RSTPC + 32'd4;
	fetchbufA_v <= 0;
	fetchbufB_v <= 0;
	fetchbufC_v <= 0;
	fetchbufD_v <= 0;
	fetchbuf <= 0;
end
else begin
	
	did_branchback0 <= take_branch0;
	did_branchback1 <= take_branch1;

	stompedRet = FALSE;

	begin

	// On a branch miss with threading enabled all fectch buffers are
	// invalidated even though the data in the fetch buffer would be valid
	// for the thread that isn't in a branchmiss state. This is done to
	// keep things simple. For the thread that doesn't miss the current
	// data for the fetch buffer needs to be retrieved again, so the pc
	// for that thread is assigned the current fetchbuf pc.
	// For the thread that misses the pc is simply assigned the misspc.
	if (branchmiss) begin
		if (thread_en) begin
			if (branchmiss_thrd) begin
     			pc0 <= fetchbuf0_pc;
				pc1 <= misspc;
			end
			else begin
				pc0 <= misspc;
     			pc1 <= fetchbuf1_pc;
     		end
		end
		else begin
			pc0 <= misspc;
     		pc1 <= misspc + 32'd4;
    	end
		fetchbufA_v <= `INV;
		fetchbufB_v <= `INV;
		fetchbufC_v <= `INV;
		fetchbufD_v <= `INV;
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
	// Some of the testing for valid branch conditions has been removed. In real
	// hardware it isn't needed, and just increases the size of the core. It's
	// assumed that the hardware is working.
	// The risk is an error will occur during simulation and go missed.
	else if (take_branch) begin

	    // update the fetchbuf valid bits as well as fetchbuf itself
	    // ... this must be based on which things are backwards branches, how many things
	    // will get enqueued (0, 1, or 2), and how old the instructions are
	    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v})

		4'b0000	: ;	// do nothing
//		4'b0001	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b0010	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b0011	: panic <= `PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

		// because the first instruction has been enqueued, 
		// we must have noted this in the previous cycle.
		// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
		// this looks like the following:
		//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, stomped on fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
		4'b0100 :
		    begin
			    FetchCD();
			     fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		// Can occur with threading enabled
		4'b0101:
			fetchbufB_v <= !(queued1|queuedNop);

//		4'b0101	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b0110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, but not fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufB_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b0111 :
			begin
			    fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
		//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufA_v appropriately
		4'b1000 :
			begin
			    FetchCD();
			     fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

//		4'b1001	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b1010	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
		//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbA, but fetched from backwards target
		//   cycle 3 - where we are now ... set fetchbufA_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1011 :
			begin
			     fetchbufA_v <=!(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		// if fbB has the branchback, can't immediately tell which of the following scenarios it is:
		//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
		//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
		// or
		//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - could not enqueue fbA or fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
		// if fbA has the branchback, then it is scenario 1.
		// if fbB has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
		4'b1100 : begin
			if(thread_en) begin
				if (take_branchA && take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else 
			begin
				if (take_branchA) begin
				    // has to be first scenario
					pc0 <= branch_pcA;
					pc1 <= branch_pcA + 4;
				    fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
		     		fetchbufB_v <= `INV;		// stomp on it
				     if (IsRet(fetchbufB_instr))
				     	stompedRet = `TRUE;
				    	if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
				    if (did_branchback0) begin
				    FetchCD();
					 fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					 fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					  fetchbuf <= fetchbuf + (queued2|queuedNop);
				    end
				    else begin
					 	pc0 <= branch_pcB;
					 	pc1 <= branch_pcB + 4;
					 fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					 fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				    end
				end
			end
//			else panic <= `PANIC_BRANCHBACK;
		    end

//		4'b1101	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b1110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued neither fbA nor fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufX_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1111 :
			begin
			     fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
			     fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued2|queuedNop);
			end
        default:    ;
	    endcase
	    else case ({fetchbufC_v, fetchbufD_v, fetchbufA_v, fetchbufB_v})

		4'b0000	: ; // do nothing
//		4'b0001	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b0010	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b0011	: panic <= `PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

		// because the first instruction has been enqueued, 
		// we must have noted this in the previous cycle.
		// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
		// this looks like the following:
		//   cycle 0 - fetched a INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued fbC, stomped on fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
		4'b0100 :
			begin
			    FetchAB();
			     fetchbufD_v <= !(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		4'b0101:
			fetchbufD_v <= !(queued1|queuedNop);
			
//		4'b0101	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b0110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued fbC, but not fbD, recognized branchback in fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbD, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufD_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b0111 :
			begin
			     fetchbufD_v <= !(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbC holding a branchback
		//   cycle 1 - stomped on fbD, but could not enqueue fbC, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufC_v appropriately
		4'b1000 :
			begin
			    FetchAB();
			     fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

//		4'b1001	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b1010	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbC holding a branchback
		//   cycle 1 - stomped on fbD, but could not enqueue fbC, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbC, but fetched from backwards target
		//   cycle 3 - where we are now ... set fetchbufC_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1011 :
			begin
			     fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		// if fbD has the branchback, can't immediately tell which of the following scenarios it is:
		//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
		//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
		// or
		//   cycle 0 - fetched a INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - could not enqueue fbC or fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
		// if fbC has the branchback, then it is scenario 1.
		// if fbD has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
		4'b1100 : begin
			
			if(thread_en) begin
				if (take_branchC & take_branchD) begin
					pc0 <= branch_pcC;
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
				    if ((queued2|queuedNop))   fetchbuf <= 1'b0;
				end
				else if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
				    if ((queued2|queuedNop))   fetchbuf <= 1'b0;
				end
				else if (take_branchD) begin
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
				    if ((queued2|queuedNop))   fetchbuf <= 1'b0;
				end
			end
			else
			begin
				if (take_branchC) begin
					 pc0 <= branch_pcC;
					 pc1 <= branch_pcC + 4;
				     fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				     fetchbufD_v <= `INV;		// stomp on it
				     if (IsRet(fetchbufD_instr))
				     	stompedRet = `TRUE;
				    if ((queued1|queuedNop))   fetchbuf <= 1'b0;
				end
				else if (take_branchD) begin
				    if (did_branchback1) begin
				    FetchAB();
					 fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					 fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					 fetchbuf <= fetchbuf + (queued2|queuedNop);
				    end
				    else begin
						 pc0 <= branch_pcD;
						 pc1 <= branch_pcD + 4;
					 fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					 fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b0;
				    end
				end
			end
//			else panic <= `PANIC_BRANCHBACK;
		    end

//		4'b1101	: panic <= `PANIC_INVALIDFBSTATE;
//		4'b1110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued neither fbC nor fbD, recognized branchback in fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbD, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufX_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1111 :
			begin
			     fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
			     fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
			      fetchbuf <= fetchbuf + (queued2|queuedNop);
			end
	    default:   ;
	    endcase

	end // if branchback

	else begin	// there is no branchback in the system
	    //
	    // update fetchbufX_v and fetchbuf ... relatively simple, as
	    // there are no backwards branches in the mix
	    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, (queued1|queuedNop), (queued2|queuedNop)})
		4'b00_00 : ;	// do nothing
//		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b00_10 : ;	// do nothing
		4'b00_11 : ;	// do nothing
		4'b01_00 : ;	// do nothing
//		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11 : begin	// enqueue fbB and flip fetchbuf
			 fetchbufB_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		    end

		4'b10_00 : ;	// do nothing
//		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11 : begin	// enqueue fbA and flip fetchbuf
			 fetchbufA_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		    end

		4'b11_00 : ;	// do nothing
//		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b11_10 : begin	// enqueue fbA but leave fetchbuf
			 fetchbufA_v <= `INV;
		    end

		4'b11_11 : begin	// enqueue both and flip fetchbuf
			 fetchbufA_v <= `INV;
			 fetchbufB_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		    end
		default:  ;
	    endcase
	    else case ({fetchbufC_v, fetchbufD_v, (queued1|queuedNop), (queued2|queuedNop)})
		4'b00_00 : ;	// do nothing
//		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b00_10 : ;	// do nothing
		4'b00_11 : ;	// do nothing
		4'b01_00 : ;	// do nothing
//		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11 : begin	// enqueue fbD and flip fetchbuf
			 fetchbufD_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		    end

		4'b10_00 : ;	// do nothing
//		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11 : begin	// enqueue fbC and flip fetchbuf
			 fetchbufC_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		    end

		4'b11_00 : ;	// do nothing
//		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b11_10 : begin	// enqueue fbC but leave fetchbuf
			 fetchbufC_v <= `INV;
		    end

		4'b11_11 : begin	// enqueue both and flip fetchbuf
			 fetchbufC_v <= `INV;
			 fetchbufD_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		    end
		default:  ;
	    endcase
	    //
	    // get data iff the fetch buffers are empty
	    //
	    if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
	        FetchAB();
	        // fetchbuf steering logic correction
	        if (fetchbufC_v==`INV && fetchbufD_v==`INV && phit)
	              fetchbuf <= 1'b0;
	    end
	    else if (fetchbufC_v == `INV && fetchbufD_v == `INV)
		    FetchCD();
	end
    //
    // get data iff the fetch buffers are empty
    //
    if (fetchbufA_v == `INV && fetchbufB_v == `INV && fetchbufC_v==`INV && fetchbufD_v==`INV) begin
        FetchAB();
         fetchbuf <= 1'b0;
    end
	end
	
	// The fetchbuffer is invalidated at the end of a vector instruction
	// queue.
	if (nop_fetchbuf[0])  fetchbufA_v <= `INV;
	if (nop_fetchbuf[1])  fetchbufB_v <= `INV;
	if (nop_fetchbuf[2])  fetchbufC_v <= `INV;
	if (nop_fetchbuf[3])  fetchbufD_v <= `INV;
end

assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;
assign fetchbuf0_thrd  = 1'b0;
assign fetchbuf1_thrd  = thread_en ? 1'b1 : 1'b0;

task FetchA;
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
         fetchbufA_instr <= codebuf0;
    else
         fetchbufA_instr <= insn0;
    fetchbufA_v <= `VAL;
    fetchbufA_pc <= pc0;
    if (phit && ~hirq) begin
    	if (thread_en)
    		pc0 <= pc0 + 32'd4;
    	else
    		pc0 <= pc0 + 32'd8;
    end
end
endtask

task FetchB;
begin
    if (insn1[`INSTRUCTION_OP]==`EXEC)
         fetchbufB_instr <= codebuf1;
    else
         fetchbufB_instr <= insn1;
    fetchbufB_v <= `VAL;
    fetchbufB_pc <= pc1;
    if (phit && (~hirq || thread_en)) begin
    	if (thread_en)
    		pc1 <= pc1 + 32'd4;
    	else
    		pc1 <= pc1 + 32'd8;
    end
end
endtask


task FetchAB;
begin
	FetchA();
	FetchB();
end
endtask

task FetchC;
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
         fetchbufC_instr <= codebuf0;
    else
         fetchbufC_instr <= insn0;
    fetchbufC_v <= `VAL;
    fetchbufC_pc <= pc0;
    if (phit && ~hirq) begin
    	if (thread_en)
    		pc0 <= pc0 + 32'd4;
    	else
    		pc0 <= pc0 + 32'd8;
	end
end
endtask

task FetchD;
begin
    if (insn1[`INSTRUCTION_OP]==`EXEC)
         fetchbufD_instr <= codebuf1;
    else
         fetchbufD_instr <= insn1;
    fetchbufD_v <= `VAL;
    fetchbufD_pc <= pc1;
    if (phit && (~hirq || thread_en)) begin
    	if (thread_en)
    		pc1 <= pc1 + 32'd4;
    	else
    		pc1 <= pc1 + 32'd8;
    end
end
endtask

task FetchCD;
begin
	FetchC();
	FetchD();
end
endtask

endmodule
