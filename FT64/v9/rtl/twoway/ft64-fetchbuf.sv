// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ft64-fetchbuf.sv
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
`include "ft64-config.sv"
`include "ft64-defines.sv"

// FETCH
//
// fetch exactly two instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
// Like to turn this into an independent module at some point.
//
module ft64_fetchbuf(rst, clk4x, clk, fcu_clk,
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i,
	cmpgrp,
	freezePC, thread_en,
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
    fetchbuf0_instr, fetchbuf1_instr, fetchbuf0_insln, fetchbuf1_insln,
    fetchbuf0_thrd, fetchbuf1_thrd,
    fetchbuf0_pc, fetchbuf1_pc,
    fetchbuf0_v, fetchbuf1_v,
    codebuf0, codebuf1,
    btgtA, btgtB, btgtC, btgtD,
    nop_fetchbuf,
    take_branch0, take_branch1,
    stompedRets,
    pred_on,
    panic
);
parameter AMSB = `AMSB;
parameter RSTPC = 64'hFFFC0100;
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
input [47:0] insn1;
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
output reg [47:0] fetchbufA_instr;
output reg [47:0] fetchbufB_instr;
output reg [47:0] fetchbufC_instr;
output reg [47:0] fetchbufD_instr;
output reg [AMSB:0] fetchbufA_pc;
output reg [AMSB:0] fetchbufB_pc;
output reg [AMSB:0] fetchbufC_pc;
output reg [AMSB:0] fetchbufD_pc;
output [47:0] fetchbuf0_instr;
output [47:0] fetchbuf1_instr;
output [AMSB:0] fetchbuf0_pc;
output [AMSB:0] fetchbuf1_pc;
output [2:0] fetchbuf0_insln;
output [2:0] fetchbuf1_insln;
output fetchbuf0_v;
output fetchbuf1_v;
input [47:0] codebuf0;
input [47:0] codebuf1;
input [AMSB:0] btgtA;
input [AMSB:0] btgtB;
input [AMSB:0] btgtC;
input [AMSB:0] btgtD;
input [3:0] nop_fetchbuf;
output take_branch0;
output take_branch1;
input [3:0] stompedRets;
input pred_on;
output reg [3:0] panic;
integer n;

//`include "FT64_decode.vh"

function IsBranch;
input [47:0] isn;
casex(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
//`BCHK:	IsBranch = TRUE;
default: IsBranch = FALSE;
endcase
endfunction

function IsJAL;
input [47:0] isn;
IsJAL = isn[`INSTRUCTION_OP]==`JAL;
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

function IsBrk;
input [47:0] isn;
IsBrk = isn[`INSTRUCTION_OP]==`BRK;
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
	2'd0:	fnInsLength = 3'd4|pred_on;
	2'd1:	fnInsLength = 3'd6|pred_on;
	default:	fnInsLength = 3'd2|pred_on;
	endcase
endfunction

wire [2:0] fetchbufA_inslen;
wire [2:0] fetchbufB_inslen;
wire [2:0] fetchbufC_inslen;
wire [2:0] fetchbufD_inslen;
FT64_InsLength uilA (fetchbufA_instr, fetchbufA_inslen, pred_on);
FT64_InsLength uilB (fetchbufB_instr, fetchbufB_inslen, pred_on);
FT64_InsLength uilC (fetchbufC_instr, fetchbufC_inslen, pred_on);
FT64_InsLength uilD (fetchbufD_instr, fetchbufD_inslen, pred_on);

wire [47:0] xinsn0;
wire [47:0] xinsn1;

ft64_iexpander ux1
(
	.cinstr(insn0[15:0]),
	.expand(xinsn0)
);
ft64_iexpander ux2
(
	.cinstr(insn1[15:0]),
	.expand(xinsn1)
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
wire [47:0] expand1 = DecompressTable[{cmpgrp,insn1[15:8]}];
`endif

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

reg [AMSB:0] branch_pcA;
reg [AMSB:0] branch_pcB;
reg [AMSB:0] branch_pcC;
reg [AMSB:0] branch_pcD;

always @*
case(fetchbufA_instr[`INSTRUCTION_OP])
`RET:		branch_pcA = retpc0;
`JMP,`CALL: branch_pcA = fetchbufA_instr[6] ? {fetchbufA_instr[39:8]} : {fetchbufA_pc[31:24],fetchbufA_instr[31:8]};
`R2:		branch_pcA = btgtA;	// RTI
`BRK,`JAL:	branch_pcA = btgtA;
default:
	begin
	branch_pcA[31:8] = fetchbufA_pc[31:8] +
		(fetchbufA_instr[7:6]==2'b01 ? {{4{fetchbufA_instr[47]}},fetchbufA_instr[47:28]} : {{20{fetchbufA_instr[31]}},fetchbufA_instr[31:28]});
	branch_pcA[7:0] = {fetchbufA_instr[27:23],fetchbufA_instr[17:16],1'b0};
	branch_pcA[63:32] = fetchbufA_pc[63:32];
	end
endcase

always @*
case(fetchbufB_instr[`INSTRUCTION_OP])
`RET:		branch_pcB = retpc1;
`JMP,`CALL: branch_pcB = fetchbufB_instr[6] ? {fetchbufB_instr[39:8]} : {fetchbufB_pc[31:24],fetchbufB_instr[31:8]};
`R2:		branch_pcB = btgtB;	// RTI
`BRK,`JAL:	branch_pcB = btgtB;
default:
	begin
	branch_pcB[31:8] = fetchbufB_pc[31:8] +
		(fetchbufB_instr[7:6]==2'b01 ? {{4{fetchbufB_instr[47]}},fetchbufB_instr[47:28]} : {{20{fetchbufB_instr[31]}},fetchbufB_instr[31:28]});
	branch_pcB[7:0] = {fetchbufB_instr[27:23],fetchbufB_instr[17:16],1'b0};
	branch_pcB[63:32] = fetchbufB_pc[63:32];
	end
endcase

always @*
case(fetchbufC_instr[`INSTRUCTION_OP])
`RET:		branch_pcC = retpc0;
`JMP,`CALL: branch_pcC = fetchbufC_instr[6] ? {fetchbufC_instr[39:8]} : {fetchbufC_pc[31:24],fetchbufC_instr[31:8]};
`R2:		branch_pcC = btgtC;	// RTI
`BRK,`JAL:	branch_pcC = btgtC;
default:
	begin
	branch_pcC[31:8] = fetchbufC_pc[31:8] +
		(fetchbufC_instr[7:6]==2'b01 ? {{4{fetchbufC_instr[47]}},fetchbufC_instr[47:28]} : {{20{fetchbufC_instr[31]}},fetchbufC_instr[31:28]});
	branch_pcC[7:0] = {fetchbufC_instr[27:23],fetchbufC_instr[17:16],1'b0};
	branch_pcC[63:32] = fetchbufC_pc[63:32];
	end
endcase

always @*
case(fetchbufD_instr[`INSTRUCTION_OP])
`RET:		branch_pcD = retpc1;
`JMP,`CALL: branch_pcD = fetchbufD_instr[6] ? {fetchbufD_instr[39:8]} : {fetchbufD_pc[31:24],fetchbufD_instr[31:8]};
`R2:		branch_pcD = btgtD;	// RTI
`BRK,`JAL:	branch_pcD = btgtD;
default:
	begin
	branch_pcD[31:8] = fetchbufD_pc[31:8] +
		(fetchbufD_instr[7:6]==2'b01 ? {{4{fetchbufD_instr[47]}},fetchbufD_instr[47:28]} : {{20{fetchbufD_instr[31]}},fetchbufD_instr[31:28]});
	branch_pcD[7:0] = {fetchbufD_instr[27:23],fetchbufD_instr[17:16],1'b0};
	branch_pcD[63:32] = fetchbufD_pc[63:32];
	end
endcase

wire take_branchA = ({fetchbufA_v, IsBranch(fetchbufA_instr), predict_takenA}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufA_instr)||IsJmp(fetchbufA_instr)||IsCall(fetchbufA_instr)||
                        IsRTI(fetchbufA_instr)|| IsBrk(fetchbufA_instr) || IsJAL(fetchbufA_instr)) &&
                        fetchbufA_v);
wire take_branchB = ({fetchbufB_v, IsBranch(fetchbufB_instr), predict_takenB}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufB_instr)|IsJmp(fetchbufB_instr)|IsCall(fetchbufB_instr) ||
                        IsRTI(fetchbufB_instr)|| IsBrk(fetchbufB_instr) || IsJAL(fetchbufB_instr)) &&
                        fetchbufB_v);
wire take_branchC = ({fetchbufC_v, IsBranch(fetchbufC_instr), predict_takenC}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufC_instr)|IsJmp(fetchbufC_instr)|IsCall(fetchbufC_instr) ||
                        IsRTI(fetchbufC_instr)|| IsBrk(fetchbufC_instr) || IsJAL(fetchbufC_instr)) &&
                        fetchbufC_v);
wire take_branchD = ({fetchbufD_v, IsBranch(fetchbufD_instr), predict_takenD}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufD_instr)|IsJmp(fetchbufD_instr)|IsCall(fetchbufD_instr) ||
                        IsRTI(fetchbufD_instr)|| IsBrk(fetchbufD_instr) || IsJAL(fetchbufD_instr)) &&
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
assign threadx = fetchbuf;

`ifdef FCU_ENH
FT64_RSB #(AMSB) ursb1
(
	.rst(rst),
	.clk(fcu_clk),
	.regLR(regLR),
	.queued1(queued1),
	.queued2(queued2),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf0_pc(fetchbuf0_pc),
	.fetchbuf0_instr(fetchbuf0_instr),
	.fetchbuf1_v(fetchbuf1_v),
	.fetchbuf1_pc(fetchbuf1_pc),
	.fetchbuf1_instr(fetchbuf1_instr),
	.stompedRets(stompedRets),
	.stompedRet(stompedRet),
	.pc(retpc0)
);

FT64_RSB #(AMSB) ursb2
(
	.rst(rst),
	.clk(fcu_clk),
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
`else
assign retpc0 = RSTPC;
assign retpc1 = RSTPC;
`endif

wire peclk, neclk;
edge_det ued1 (.rst(rst), .clk(clk4x), .ce(1'b1), .i(clk), .pe(peclk), .ne(neclk), .ee());

always @(posedge clk)
if (rst) begin
	pc0 <= RSTPC;
  pc1 <= RSTPC;
	fetchbufA_v <= 0;
	fetchbufB_v <= 0;
	fetchbufC_v <= 0;
	fetchbufD_v <= 0;
	fetchbuf <= 0;
	panic <= `PANIC_NONE;
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
		$display("***********");
		$display("Branch miss");
		$display("***********");
		if (branchmiss_thrd) begin
			pc1 <= misspc;
			fetchbufB_v <= `INV;
			fetchbufD_v <= `INV;
		end
		else begin
			pc0 <= misspc;
			if (thread_en) begin
				fetchbufA_v <= `INV;
				fetchbufC_v <= `INV;
			end
			else begin
				fetchbufA_v <= `INV;
				fetchbufB_v <= `INV;
				fetchbufC_v <= `INV;
				fetchbufD_v <= `INV;
				fetchbuf <= 1'b0;
			end
 		end
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

    // update the fetchbuf valid bits as well as fetchbuf itself
    // ... this must be based on which things are backwards branches, how many things
    // will get enqueued (0, 1, or 2), and how old the instructions are
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v})

		4'b0000: ;	// do nothing
		4'b0001: if (thread_en) FetchC();
		4'b0010: if (thread_en) FetchD();
		4'b0011: ;
		4'b0100 :
	    begin
		    if (thread_en) begin
		    	FetchC();
		    	pc1 <= branch_pcB;
		    end
		    else
		    	pc0 <= branch_pcB;
		    fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b0101:
			begin
				if (thread_en) begin
					pc1 <= branch_pcB;
					FetchC();
				end
				else
					pc0 <= branch_pcB;
				fetchbufD_v <= `INV;
				fetchbufB_v <= !(queued1|queuedNop);
			end
		4'b0110:
			begin
				if (thread_en)
					pc1 <= branch_pcB;
				else begin
					pc0 <= branch_pcB;
					fetchbufC_v <= `INV;
				end
				fetchbufB_v <= !(queued1|queuedNop);
			end
		4'b0111:
			begin
				if (thread_en) begin
					pc1 <= branch_pcB;
					fetchbufD_v <= `INV;
				end
				else begin
					pc0 <= branch_pcB;
					fetchbufC_v <= `INV;
					fetchbufD_v <= `INV;
				end
			  fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1000 :
			begin
				if (thread_en) FetchD();
		    pc0 <= branch_pcA;
		    fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1001:
			begin
				pc0 <= branch_pcA;
				if (!thread_en)
					fetchbufD_v <= `INV;
		    fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1010:
			begin
				pc0 <= branch_pcA;
				fetchbufC_v <= `INV;
				if (thread_en) FetchD();
		    fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1011:
			begin
				pc0 <= branch_pcA;
				fetchbufC_v <= `INV;
				if (!thread_en)
					fetchbufD_v <= `INV;
				fetchbufA_v <=!(queued1|queuedNop);	// if it can be queued, it will
				fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1100:
			if (thread_en) begin
				if (take_branchA && take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					FetchD();
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					FetchC();
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		    // else hardware error
		  end
		4'b1101:
			if (thread_en) begin
				if (take_branchA && take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufD_v <= `INV;
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
					FetchC();
					pc1 <= branch_pcB;
					fetchbufD_v <= `INV;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				fetchbufD_v <= `INV;
				if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		    // else hardware error
		  end
		4'b1110:
			if (thread_en) begin
				if (take_branchA && take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufC_v <= `INV;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					FetchD();
					pc0 <= branch_pcA;
					fetchbufC_v <= `INV;
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
			else begin
				fetchbufC_v <= `INV;
				if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		    // else hardware error
		  end
		4'b1111:
			begin
				if (thread_en) begin
					if (take_branchA & take_branchB) begin
						pc0 <= branch_pcA;
						pc1 <= branch_pcB;
						fetchbufC_v <= `INV;
						fetchbufD_v <= `INV;
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
					else if (take_branchA) begin
						pc0 <= branch_pcA;
						fetchbufC_v <= `INV;
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
					else if (take_branchB) begin
						pc1 <= branch_pcB;
						fetchbufD_v <= `INV;
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
				end
				else begin
					if (take_branchA) begin
						pc0 <= branch_pcA;
						fetchbufB_v <= `INV;
						fetchbufC_v <= `INV;
						fetchbufD_v <= `INV;
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued1|queuedNop);
					end
					else if (take_branchB) begin
						pc0 <= branch_pcB;
						fetchbufC_v <= `INV;
						fetchbufD_v <= `INV;
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
				end
			end
    default:    ;
	  endcase
	  else case ({fetchbufC_v, fetchbufD_v, fetchbufA_v, fetchbufB_v})

		4'b0000: ;	// do nothing
		4'b0001: if (thread_en) FetchA();
		4'b0010: if (thread_en) FetchB();
		4'b0011: ;
		4'b0100 :
	    begin
		    if (thread_en) begin
		    	FetchA();
		    	pc1 <= branch_pcD;
		    end
		    else
		    	pc0 <= branch_pcD;
		    fetchbufD_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b0101:
			begin
				if (thread_en) begin
					pc1 <= branch_pcD;
					FetchA();
				end
				else
					pc0 <= branch_pcD;
				fetchbufB_v <= `INV;
				fetchbufD_v <= !(queued1|queuedNop);
			end
		4'b0110:
			begin
				if (thread_en)
					pc1 <= branch_pcD;
				else begin
					pc0 <= branch_pcD;
					fetchbufA_v <= `INV;
				end
				fetchbufD_v <= !(queued1|queuedNop);
			end
		4'b0111:
			begin
				if (thread_en) begin
					pc1 <= branch_pcD;
					fetchbufB_v <= `INV;
				end
				else begin
					pc0 <= branch_pcD;
					fetchbufA_v <= `INV;
					fetchbufB_v <= `INV;
				end
			  fetchbufD_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1000 :
			begin
				if (thread_en) FetchB();
		    pc0 <= branch_pcC;
		    fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1001:
			begin
				pc0 <= branch_pcC;
				if (!thread_en)
					fetchbufB_v <= `INV;
		    fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1010:
			begin
				pc0 <= branch_pcC;
				fetchbufA_v <= `INV;
				if (thread_en) FetchB();
		    fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1011:
			begin
				pc0 <= branch_pcC;
				fetchbufA_v <= `INV;
				if (!thread_en)
					fetchbufB_v <= `INV;
				fetchbufC_v <=!(queued1|queuedNop);	// if it can be queued, it will
				fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		4'b1100:
			if (thread_en) begin
				if (take_branchC && take_branchD) begin
					pc0 <= branch_pcC;
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					FetchB();
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchD) begin
					FetchA();
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchD) begin
					pc0 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		    // else hardware error
		  end
		4'b1101:
			if (thread_en) begin
				if (take_branchC && take_branchD) begin
					pc0 <= branch_pcC;
					pc1 <= branch_pcD;
					fetchbufB_v <= `INV;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					FetchA();
					pc1 <= branch_pcD;
					fetchbufB_v <= `INV;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				fetchbufB_v <= `INV;
				if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchD) begin
					pc0 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		    // else hardware error
		  end
		4'b1110:
			if (thread_en) begin
				if (take_branchC && take_branchD) begin
					pc0 <= branch_pcC;
					pc1 <= branch_pcD;
					fetchbufA_v <= `INV;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					FetchB();
					pc0 <= branch_pcC;
					fetchbufA_v <= `INV;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchD) begin
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				fetchbufA_v <= `INV;
				if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchD) begin
					pc0 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		    // else hardware error
		  end
		4'b1111:
			begin
				if (thread_en) begin
					if (take_branchC & take_branchD) begin
						pc0 <= branch_pcC;
						pc1 <= branch_pcD;
						fetchbufA_v <= `INV;
						fetchbufB_v <= `INV;
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
					else if (take_branchC) begin
						pc0 <= branch_pcD;
						fetchbufA_v <= `INV;
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
					else if (take_branchD) begin
						pc1 <= branch_pcD;
						fetchbufB_v <= `INV;
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
				end
				else begin
					if (take_branchC) begin
						pc0 <= branch_pcC;
						fetchbufD_v <= `INV;
						fetchbufA_v <= `INV;
						fetchbufB_v <= `INV;
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued1|queuedNop);
					end
					else if (take_branchD) begin
						pc0 <= branch_pcD;
						fetchbufA_v <= `INV;
						fetchbufB_v <= `INV;
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
						fetchbuf <= fetchbuf + (queued2|queuedNop);
					end
				end
			end
    default:    ;
	  endcase
	end // if branchback

	else begin	// there is no branchback in the system
	    //
	    // update fetchbufX_v and fetchbuf ... relatively simple, as
	    // there are no backwards branches in the mix
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, (queued1|queuedNop), (queued2|queuedNop)})
		4'b00_00 : ;	// do nothing
		4'b00_01:	;
		4'b00_10:	;
		4'b00_11:	;
		4'b01_00: ;	// do nothing
		4'b01_01:	;
		4'b01_10,
		4'b01_11:
			begin	// enqueue fbB and flip fetchbuf
				fetchbufB_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		  end
		4'b10_00: ;	// do nothing
		4'b10_01: ;
		4'b10_10,
		4'b10_11:
			begin	// enqueue fbA and flip fetchbuf
				fetchbufA_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		  end
		4'b11_00: ;	// do nothing
		4'b11_01: ;
		4'b11_10:
			begin	// enqueue fbA but leave fetchbuf
				fetchbufA_v <= `INV;
		  end
		4'b11_11:
			begin	// enqueue both and flip fetchbuf
				fetchbufA_v <= `INV;
				fetchbufB_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		  end
		default:  panic <= `PANIC_INVALIDIQSTATE;
    endcase
    else case ({fetchbufC_v, fetchbufD_v, (queued1|queuedNop), (queued2|queuedNop)})
		4'b00_00 : ;	// do nothing
		4'b00_01: ;
		4'b00_10 : ;	// do nothing
		4'b00_11 : ;	// do nothing
		4'b01_00 : ;	// do nothing
		4'b01_01 : ;
		4'b01_10,
		4'b01_11 :
			begin	// enqueue fbD and flip fetchbuf
				fetchbufD_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		  end
		4'b10_00 : ;	// do nothing
		4'b10_01: ;
		4'b10_10,
		4'b10_11:
			begin	// enqueue fbC and flip fetchbuf
				fetchbufC_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		  end
		4'b11_00 : ;	// do nothing
		4'b11_01: ;
		4'b11_10:
			begin	// enqueue fbC but leave fetchbuf
				fetchbufC_v <= `INV;
		  end
		4'b11_11:
			begin	// enqueue both and flip fetchbuf
				fetchbufC_v <= `INV;
				fetchbufD_v <= `INV;
			  fetchbuf <= ~fetchbuf;
		  end
		default:  panic <= `PANIC_INVALIDIQSTATE;
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
assign fetchbuf0_insln = (fetchbuf == 1'b0) ? fetchbufA_inslen: fetchbufC_inslen;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
assign fetchbuf1_insln = (fetchbuf == 1'b0) ? fetchbufB_inslen: fetchbufD_inslen;
assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;
assign fetchbuf0_thrd  = 1'b0;
assign fetchbuf1_thrd  = thread_en;

reg [2:0] insln0, insln1;
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

always @*
begin
`ifdef SUPPORT_DCI
	if (insn1[5:0]==`CMPRSSD)
		insln1 <= 3'd2;
	else
`endif
	if (insn1[7:6]==2'b00 && insn1[`INSTRUCTION_OP]==`EXEC)
		insln1 <= fnInsLength(codebuf1);
	else
		insln1 <= fnInsLength(insn1);
end

reg [47:0] cinsn0, cinsn1;

always @*
begin
//`ifdef SUPPORT_DCI
//	if (insn0[5:0]==`CMPRSSD)
//		cinsn0 <= expand0;
//	else
//`endif
	if (insn0[7:6]==2'b00 && insn0[`INSTRUCTION_OP]==`EXEC)
		cinsn0 <= codebuf0;
//	else if (insn0[7])
//		cinsn0 <= xinsn0;
	else
		cinsn0 <= insn0;
end

always @*
begin
//`ifdef SUPPORT_DCI
//	if (insn1[5:0]==`CMPRSSD)
//		cinsn1 <= expand1;
//	else
//`endif
	if (insn1[7:6]==2'b00 && insn1[`INSTRUCTION_OP]==`EXEC)
		cinsn1 <= codebuf1;
//	else if (insn1[7])
//		cinsn1 <= xinsn1;
	else
		cinsn1 <= insn1;
end

task FetchA;
begin
	fetchbufA_instr <= cinsn0;
	fetchbufA_v <= `VAL;
	fetchbufA_pc <= pc0;
	if (phit && ~freezePC) begin
		if (thread_en)
			pc0 <= pc0 + insln0;
		else if (`WAYS > 1)
			pc0 <= pc0 + insln0 + insln1;
		else
			pc0 <= pc0 + insln0;
	end
end
endtask

task FetchB;
begin
	fetchbufB_instr <= cinsn1;
	fetchbufB_v <= `WAYS > 1;
	if (thread_en)
		fetchbufB_pc <= pc1;
	else
		fetchbufB_pc <= pc0 + insln0;
	if (phit & thread_en)
		pc1 <= pc1 + insln1;
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
	fetchbufC_instr <= cinsn0;
	fetchbufC_v <= `VAL;
	fetchbufC_pc <= pc0;
	if (phit && ~freezePC) begin
		if (thread_en)
			pc0 <= pc0 + insln0;
		else if (`WAYS > 1)
			pc0 <= pc0 + insln0 + insln1;
		else
			pc0 <= pc0 + insln0;
	end
end
endtask

task FetchD;
begin
	fetchbufD_instr <= cinsn1;
	fetchbufD_v <= `WAYS > 1;
	if (thread_en)
		fetchbufD_pc <= pc1;
	else
		fetchbufD_pc <= pc0 + insln0;
	if (phit & thread_en)
		pc1 <= pc1 + insln1;
end
endtask

task FetchCD;
begin
	FetchC();
	FetchD();
end
endtask

endmodule

