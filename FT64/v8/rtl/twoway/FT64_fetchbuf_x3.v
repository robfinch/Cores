// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_fetchbuf_x3.v
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
// fetch exactly three instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
//
module FT64_fetchbuf_x3(rst, clk4x, clk, fcu_clk,
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i,
	hirq, thread_en,
	regLR,
    insn0, insn1, insn2,
    phit,
    threadx,
    branchmiss, misspc, branchmiss_thrd,
    predict_taken0, predict_taken1, predict_taken2,
    predict_takenA, predict_takenB, predict_takenC, predict_takenD, predict_takenE, predict_takenF,
    queued1, queued2, queued3, queuedNop,
    pc0, pc1, pc2,
    fetchbuf, fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v, fetchbufE_v, fetchbufF_v,
    fetchbufA_instr, fetchbufA_pc,
    fetchbufB_instr, fetchbufB_pc,
    fetchbufC_instr, fetchbufC_pc,
    fetchbufD_instr, fetchbufD_pc,
    fetchbufE_instr, fetchbufE_pc,
    fetchbufF_instr, fetchbufF_pc,
    fetchbuf0_instr, fetchbuf1_instr, fetchbuf2_instr,
    fetchbuf0_insln, fetchbuf1_insln, fetchbuf2_insln,
    fetchbuf0_thrd, fetchbuf1_thrd, fetchbuf2_thrd,
    fetchbuf0_pc, fetchbuf1_pc, fetchbuf2_pc,
    fetchbuf0_v, fetchbuf1_v, fetchbuf2_v,
    codebuf0, codebuf1, codebuf2,
    btgtA, btgtB, btgtC, btgtD, btgtE, btgtF,
    nop_fetchbuf,
    take_branch0, take_branch1, take_branch2,
    stompedRets
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
input [31:0] dat_i;
input hirq;
input thread_en;
input [4:0] regLR;
input [47:0] insn0;
input [47:0] insn1;
input [47:0] insn2;
input phit;
output threadx;
input branchmiss;
input [AMSB:0] misspc;
input branchmiss_thrd;
output predict_taken0;
output predict_taken1;
output predict_taken2;
input predict_takenA;
input predict_takenB;
input predict_takenC;
input predict_takenD;
input predict_takenE;
input predict_takenF;
input queued1;
input queued2;
input queued3;
input queuedNop;
output reg [AMSB:0] pc0;
output reg [AMSB:0] pc1;
output reg [AMSB:0] pc2;
output reg fetchbuf;
output reg fetchbufA_v;
output reg fetchbufB_v;
output reg fetchbufC_v;
output reg fetchbufD_v;
output reg fetchbufE_v;
output reg fetchbufF_v;
output fetchbuf0_thrd;
output fetchbuf1_thrd;
output fetchbuf2_thrd;
output reg [47:0] fetchbufA_instr;
output reg [47:0] fetchbufB_instr;
output reg [47:0] fetchbufC_instr;
output reg [47:0] fetchbufD_instr;
output reg [47:0] fetchbufE_instr;
output reg [47:0] fetchbufF_instr;
output reg [AMSB:0] fetchbufA_pc;
output reg [AMSB:0] fetchbufB_pc;
output reg [AMSB:0] fetchbufC_pc;
output reg [AMSB:0] fetchbufD_pc;
output reg [AMSB:0] fetchbufE_pc;
output reg [AMSB:0] fetchbufF_pc;
output [47:0] fetchbuf0_instr;
output [47:0] fetchbuf1_instr;
output [47:0] fetchbuf2_instr;
output [AMSB:0] fetchbuf0_pc;
output [AMSB:0] fetchbuf1_pc;
output [AMSB:0] fetchbuf2_pc;
output reg [3:0] fetchbuf0_insln;
output reg [3:0] fetchbuf1_insln;
output reg [3:0] fetchbuf2_insln;
output fetchbuf0_v;
output fetchbuf1_v;
output fetchbuf2_v;
input [47:0] codebuf0;
input [47:0] codebuf1;
input [47:0] codebuf2;
input [AMSB:0] btgtA;
input [AMSB:0] btgtB;
input [AMSB:0] btgtC;
input [AMSB:0] btgtD;
input [AMSB:0] btgtE;
input [AMSB:0] btgtF;
input [3:0] nop_fetchbuf;
output take_branch0;
output take_branch1;
output take_branch2;
input [3:0] stompedRets;

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

function [3:0] fnInsLength;
input [47:0] ins;
case(ins[7:6])
2'd0:	fnInsLength = 4'd4;
2'd1:	fnInsLength = 4'd6;
default:	fnInsLength = 4'd2;
endcase
endfunction


wire [47:0] xinsn0;
wire [47:0] xinsn1;
wire [47:0] xinsn2;

FT64_iexpander ux1
(
	.cinstr(insn0[15:0]),
	.expand(xinsn0)
);
FT64_iexpander ux2
(
	.cinstr(insn1[15:0]),
	.expand(xinsn1)
);
FT64_iexpander ux2
(
	.cinstr(insn2[15:0]),
	.expand(xinsn2)
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Table of decompressed instructions.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
assign ack_o = cs_i & cyc_i & stb_i;
`ifdef SUPPORT_DCI
reg [47:0] DecompressTable [0:1023];
always @(posedge clk)
	if (cs_i & cyc_i & stb_i & we_i)
		DecompressTable[adr_i[11:2]] <= dat_i;
wire [47:0] expand0 = DecompressTable[insn0[15:6]];
wire [47:0] expand1 = DecompressTable[insn1[15:6]];
wire [47:0] expand2 = DecompressTable[insn2[15:6]];
`endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg thread;
reg stompedRet;
reg ret0Counted, ret1Counted;
wire [AMSB:0] retpc0, retpc1, retpc2;

reg did_branchback0;
reg did_branchback1;
reg did_branchback2;

assign predict_taken0 = (fetchbuf==1'b0) ? predict_takenA : predict_takenD;
assign predict_taken1 = (fetchbuf==1'b0) ? predict_takenB : predict_takenE;
assign predict_taken2 = (fetchbuf==1'b0) ? predict_takenC : predict_takenF;

reg [AMSB:0] branch_pcA;
reg [AMSB:0] branch_pcB;
reg [AMSB:0] branch_pcC;
reg [AMSB:0] branch_pcD;
reg [AMSB:0] branch_pcE;
reg [AMSB:0] branch_pcF;

always @*
case(fetchbufA_instr[`INSTRUCTION_OP])
`RET:		branch_pcA = retpc0;
`JMP,`CALL: branch_pcA = fetchbufA_instr[6] ? {fetchbufA_instr[39:8],1'b0} : {fetchbufA_pc[31:25],fetchbufA_instr[31:8],1'b0};
`R2:		branch_pcA = btgtA;	// RTI
`BRK,`JAL:	branch_pcA = btgtA;
default:
	begin
	branch_pcA[31:8] = fetchbufA_pc[31:8] + {{20{fetchbufA_instr[31]}},fetchbufA_instr[31:28]};
	branch_pcA[7:0] = {fetchbufA_instr[27:23],fetchbufA_instr[17:16],1'b0};
	end
endcase

always @*
case(fetchbufB_instr[`INSTRUCTION_OP])
`RET:		branch_pcB = retpc0;
`JMP,`CALL: branch_pcB = fetchbufB_instr[6] ? {fetchbufB_instr[39:8],1'b0} : {fetchbufB_pc[31:25],fetchbufB_instr[31:8],1'b0};
`R2:		branch_pcB = btgtB;	// RTI
`BRK,`JAL:	branch_pcB = btgtB;
default:
	begin
	branch_pcB[31:8] = fetchbufB_pc[31:8] + {{20{fetchbufB_instr[31]}},fetchbufB_instr[31:28]};
	branch_pcB[7:0] = {fetchbufB_instr[27:23],fetchbufB_instr[17:16],1'b0};
	end
endcase

always @*
case(fetchbufC_instr[`INSTRUCTION_OP])
`RET:		branch_pcC = retpc2;
`JMP,`CALL: branch_pcC = fetchbufC_instr[6] ? {fetchbufC_instr[39:8],1'b0} : {fetchbufC_pc[31:25],fetchbufC_instr[31:8],1'b0};
`R2:		branch_pcC = btgtC;	// RTI
`BRK,`JAL:	branch_pcC = btgtC;
default:
	begin
	branch_pcC[31:8] = fetchbufC_pc[31:8] + {{20{fetchbufC_instr[31]}},fetchbufC_instr[31:28]};
	branch_pcC[7:0] = {fetchbufC_instr[27:23],fetchbufC_instr[17:16],1'b0};
	end
endcase

always @*
case(fetchbufD_instr[`INSTRUCTION_OP])
`RET:		branch_pcD = retpc0;
`JMP,`CALL: branch_pcD = fetchbufD_instr[6] ? {fetchbufD_instr[39:8],1'b0} : {fetchbufD_pc[31:25],fetchbufD_instr[31:8],1'b0};
`R2:		branch_pcD = btgtD;	// RTI
`BRK,`JAL:	branch_pcD = btgtD;
default:
	begin
	branch_pcD[31:8] = fetchbufD_pc[31:8] + {{20{fetchbufD_instr[31]}},fetchbufD_instr[31:28]};
	branch_pcD[7:0] = {fetchbufD_instr[27:23],fetchbufD_instr[17:16],1'b0};
	end
endcase

always @*
case(fetchbufE_instr[`INSTRUCTION_OP])
`RET:		branch_pcE = retpc1;
`JMP,`CALL: branch_pcE = fetchbufE_instr[6] ? {fetchbufE_instr[39:8],1'b0} : {fetchbufE_pc[31:25],fetchbufE_instr[31:8],1'b0};
`R2:		branch_pcE = btgtE;	// RTI
`BRK,`JAL:	branch_pcE = btgtE;
default:
	begin
	branch_pcE[31:8] = fetchbufE_pc[31:8] + {{20{fetchbufE_instr[31]}},fetchbufE_instr[31:28]};
	branch_pcE[7:0] = {fetchbufE_instr[27:23],fetchbufE_instr[17:16],1'b0};
	end
endcase

always @*
case(fetchbufF_instr[`INSTRUCTION_OP])
`RET:		branch_pcF = retpc2;
`JMP,`CALL: branch_pcF = fetchbufF_instr[6] ? {fetchbufF_instr[39:8],1'b0} : {fetchbufF_pc[31:25],fetchbufF_instr[31:8],1'b0};
`R2:		branch_pcF = btgtF;	// RTI
`BRK,`JAL:	branch_pcF = btgtF;
default:
	begin
	branch_pcF[31:8] = fetchbufF_pc[31:8] + {{20{fetchbufF_instr[31]}},fetchbufF_instr[31:28]};
	branch_pcF[7:0] = {fetchbufF_instr[27:23],fetchbufF_instr[17:16],1'b0};
	end
endcase

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
wire take_branchE = ({fetchbufE_v, IsBranch(fetchbufE_instr), predict_takenE}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufE_instr)|IsJmp(fetchbufE_instr)|IsCall(fetchbufE_instr) ||
                        IsRTI(fetchbufE_instr)|| fetchbufE_instr[`INSTRUCTION_OP]==`BRK || fetchbufE_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufE_v);
wire take_branchF = ({fetchbufF_v, IsBranch(fetchbufF_instr), predict_takenF}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufF_instr)|IsJmp(fetchbufF_instr)|IsCall(fetchbufF_instr) ||
                        IsRTI(fetchbufF_instr)|| fetchbufF_instr[`INSTRUCTION_OP]==`BRK || fetchbufF_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufF_v);

assign take_branch0 = fetchbuf==1'b0 ? take_branchA : take_branchD;
assign take_branch1 = fetchbuf==1'b0 ? take_branchB : take_branchE;
assign take_branch2 = fetchbuf==1'b0 ? take_branchC : take_branchF;
wire take_branch = take_branch0 || take_branch1 || take_branch2;
/*
always @*
begin
	pc0 <= thread_en ? (fetchbuf ? pc0b : pc0a) : pc0a;
	pc1 <= thread_en ? (fetchbuf ? pc1b : pc1a) : pc1a;
end
*/
assign threadx = fetchbuf;

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
	.stompedRets(stompedRets),
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

FT64_RSB #(AMSB) ursb2
(
	.rst(rst),
	.clk(clk),
	.regLR(regLR),
	.queued1(queued1),
	.queued2(1'b0),
	.fetchbuf0_v(fetchbuf2_v),
	.fetchbuf0_pc(fetchbuf2_pc),
	.fetchbuf0_instr(fetchbuf2_instr),
	.fetchbuf1_v(1'b0),
	.fetchbuf1_pc(32'h00000000),
	.fetchbuf1_instr(`NOP_INSN),
	.stompedRets(stompedRets[3:1]),
	.stompedRet(stompedRet),
	.pc(retpc2)
);

wire peclk, neclk;
edge_det ued1 (.rst(rst), .clk(clk4x), .ce(1'b1), .i(clk), .pe(peclk), .ne(neclk), .ee());

always @(posedge clk)
if (rst) begin
	pc0 <= RSTPC;
`ifdef SUPPORT_SMT
  pc1 <= RSTPC;
  pc2 <= RSTPC;
`endif
	fetchbufA_v <= 0;
	fetchbufB_v <= 0;
	fetchbufC_v <= 0;
	fetchbufD_v <= 0;
	fetchbufE_v <= 0;
	fetchbufF_v <= 0;
	fetchbuf <= 0;
end
else begin
	
	did_branchback0 <= take_branch0;
	did_branchback1 <= take_branch1;
	did_branchback2 <= take_branch2;

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
		case(branchmiss_thrd)
		2'b00:
			begin
				pc0 <= misspc;
				if (thread_en) begin
					fetchbufA_v <= `INV;
					fetchbufD_v <= `INV;
				end
				else begin
					fetchbufA_v <= `INV;
					fetchbufB_v <= `INV;
					fetchbufC_v <= `INV;
					fetchbufD_v <= `INV;
					fetchbufE_v <= `INV;
					fetchbufF_v <= `INV;
					fetchbuf <= 1'b0;
				end
			end
		2'b01:
			begin
				pc1 <= misspc;
				fetchbufB_v <= `INV;
				fetchbufE_v <= `INV;
			end
		2'b10:
			begin
				pc2 <= misspc;
				fetchbufD_v <= `INV;
				fetchbufF_v <= `INV;
			end	
		default:
			begin
				$display("Illegal thread value.");
				$stop;
			end
		endcase
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
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v, fetchbufE_v, fetchbufF_v})

		// These cases should not happen because one of A,B, or C is a branch.
		6'b000000: ;	// do nothing
		6'b000001: ;	// panic <= `PANIC_INVALIDFBSTATE;
		6'b000010: ;
		6'b000011: ;
		6'b000100: ;
		6'b000101: ;
		6'b000110: ;
		6'b000111: ;

		6'b001000:
			// Here we know that C is a branch because take_branch is true.
			// A, B queued but C didn't
    	if (thread_en) begin
	    	FetchDE();						// no point to fetching F, pc2 is changing
	    	pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
	  	end
	  	else begin
	    	pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
	  	end

		// Here A, B queued and DEF were fetched
		6'b001001:
			if (thread_en) begin
				FetchDE();
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b001010:
			if (thread_en) begin
				FetchD();
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b001011:
			if (thread_en) begin
				FetchD();
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b001100:
			if (thread_en) begin
				FetchE();
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b001101:
			if (thread_en) begin
				FetchE();
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b001110:
			if (thread_en) begin
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b001111:
			if (thread_en) begin
				pc2 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010000:
			if (thread_en) begin
				FetchDF();
				pc1 <= branch_pcB;
		    fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		  else begin
		    pc0 <= branch_pcB;
		    fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
		    fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010001:
			if (thread_en) begin
				FetchD();
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010010:
			if (thread_en) begin
				FetchDF();
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010011:
			if (thread_en) begin
				FetchD();
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbufE_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010100:
			if (thread_en) begin
				FetchF();
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010101:
			if (thread_en) begin
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010110:
			if (thread_en) begin
				FetchF();
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbufE_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b010111:
			if (thread_en) begin
				FetchF();
				pc1 <= branch_pcB;
	    	fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
	    	fetchbufE_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
			else begin
				pc0 <= branch_pcC;
	    	fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
	    	fetchbuf <= fetchbuf + (queued1|queuedNop);
			end
		6'b011000:
			if (thread_en) begin
				if (take_branchB && take_branchC) begin
					pc1 <= branch_pcB;
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc1 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else begin	// C must branch
					pc0 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		  end
		// Here there is something already fetched into DEF, so don't overwrite it.
		6'b011001:
			if (thread_en) begin
				FetchD();
				if (take_branchB && take_branchC) begin
					pc1 <= branch_pcB;
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					fetchbufF_v <= `INV;
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc1 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					FetchE();
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					fetchbufF_v <= `INV;
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= `INV;
					fetchbufF_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else begin	// C must branch
					pc0 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					fetchbufF_v <= `INV;
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		  end

		6'b011010:
			if (thread_en) begin
				FetchD();
				if (take_branchB && take_branchC) begin
					pc1 <= branch_pcB;
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					fetchbufE_v <= `INV;
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					FetchF();
					pc1 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					fetchbufE_v <= `INV;
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= `INV;
					fetchbufE_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else begin	// C must branch
					pc0 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					fetchbufE_v <= `INV;
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
		    end
		  end

		6'b011011,
		6'b011100,
		6'b011101,
		6'b011110,
		6'b011111:
			if (thread_en) begin
				if (take_branchB && take_branchC) begin
					pc1 <= branch_pcB;
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchB) begin
					pc1 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				if (take_branchB) begin
					pc0 <= branch_pcB;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= `INV;	// stomp on C
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufB_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				// B or C must be a branch or there is a hardware error
			end
		6'b100000:
			if (thread_en) begin
				FetchEF();	// Don't fetch D, pc0 is changing
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
			else begin
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
		6'b100001,
		6'b100010,
		6'b100011,
		6'b100100,
		6'b100101,
		6'b100110,
		6'b100111:
			if (thread_en) begin
				FetchDEF();
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
			else begin
				FetchDEF();
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
		6'b101000:
			if (thread_en) begin
				FetchDEF();
				if (take_branchA & take_branchC) begin
					pc0 <= branch_pcA;
					pc2 <= branch_pcC;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				FetchDEF();
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufC_v <= `INV;
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
		6'b101001,
		6'b101010,
		6'b101011,
		6'b101100,
		6'b101101,
		6'b101110,
		6'b101111:
			if (thread_en) begin
				if (take_branchA & take_branchC) begin
					pc0 <= branch_pcA;
					pc2 <= branch_pcC;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufC_v <= `INV;
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
		6'b110000:
			if (thread_en) begin
				FetchDEF();
				if (take_branchA & take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				FetchDEF();
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufB_v <= `INV;
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end
		6'b110001:
			if (thread_en) begin
				if (take_branchA & take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else if (take_branchC) begin
					pc2 <= branch_pcC;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufC_v <= !(queued2|queuedNop);
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
			end
			else begin
				pc0 <= branch_pcA;
				fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbufB_v <= `INV;
				if ((queued1|queuedNop))   fetchbuf <= 1'b1;
			end

		

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, but not fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufB_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		6'b001011:
			begin
			  fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
				fetchbuf <= fetchbuf + (queued1|queuedNop);
			end

		6'b010000:
		    begin
			    FetchDEF();
			    fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
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
`ifdef SUPPORT_SMT
				if (take_branchA && take_branchB) begin
					pc0 <= branch_pcA;
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else
`endif
				if (take_branchA) begin
					pc0 <= branch_pcA;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
`ifdef SUPPORT_SMT
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
`else
					fetchbufB_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
`endif
				end
`ifdef SUPPORT_SMT
				else if (take_branchB) begin
					pc1 <= branch_pcB;
					fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
`else
				else begin
					if (did_branchback0) begin
						FetchCD();
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
`ifdef SUPPORT_SMT
						if ((queued2|queuedNop))   fetchbuf <= 1'b1;
`else
						fetchbuf <= fetchbuf + ((queued2|queuedNop));
`endif
					end
					else begin
						pc0 <= branch_pcB;
						fetchbufA_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufB_v <= !(queued2|queuedNop);	// if it can be queued, it will
						if ((queued2|queuedNop))   fetchbuf <= 1'b1;
					end
				end
`endif
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
`ifdef SUPPORT_SMT
				if (take_branchC && take_branchD) begin
					pc0 <= branch_pcC;
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
				else
`endif
				if (take_branchC) begin
					pc0 <= branch_pcC;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
`ifdef SUPPORT_SMT
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
`else
					fetchbufD_v <= `INV;
					if ((queued1|queuedNop))   fetchbuf <= 1'b1;
`endif
				end
`ifdef SUPPORT_SMT
				else if (take_branchD) begin
					pc1 <= branch_pcD;
					fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
					fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
					if ((queued2|queuedNop))   fetchbuf <= 1'b1;
				end
`else
				else begin
					if (did_branchback1) begin
						FetchAB();
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
`ifdef SUPPORT_SMT
						if ((queued2|queuedNop))   fetchbuf <= 1'b1;
`else
						fetchbuf <= fetchbuf + ((queued2|queuedNop));
`endif
					end
					else begin
						pc0 <= branch_pcD;
						fetchbufC_v <= !(queued1|queuedNop);	// if it can be queued, it will
						fetchbufD_v <= !(queued2|queuedNop);	// if it can be queued, it will
						if ((queued2|queuedNop))   fetchbuf <= 1'b1;
					end
				end
`endif
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
`ifdef SUPPORT_SMT
assign fetchbuf1_thrd  = 1'b1;
`else
assign fetchbuf1_thrd  = 1'b0;
`endif

`ifndef SUPPORT_SMT
always @*
	pc1 <= pc0 + fetchbuf0_insln;
`endif

always @*
begin
	if (insn0[7:6]==2'b00 && insn0[`INSTRUCTION_OP]==`EXEC)
		fetchbuf0_insln <= fnInsLength(codebuf0);
	else
		fetchbuf0_insln <= fnInsLength(insn0);
end

always @*
begin
	if (insn1[7:6]==2'b00 && insn1[`INSTRUCTION_OP]==`EXEC)
		fetchbuf1_insln <= fnInsLength(codebuf1);
	else
		fetchbuf1_insln <= fnInsLength(insn1);
end

reg [47:0] cinsn0, cinsn1;

always @*
begin
	if (insn0[7:6]==2'b00 && insn0[`INSTRUCTION_OP]==`EXEC)
		cinsn0 <= codebuf0;
	else if (insn0[7])
		cinsn0 <= xinsn0;
	else
		cinsn0 <= insn0;
end

always @*
begin
	if (insn1[7:6]==2'b00 && insn1[`INSTRUCTION_OP]==`EXEC)
		cinsn1 <= codebuf1;
	else if (insn1[7])
		cinsn1 <= xinsn1;
	else
		cinsn1 <= insn1;
end

always @*
begin
	if (insn2[7:6]==2'b00 && insn2[`INSTRUCTION_OP]==`EXEC)
		cinsn2 <= codebuf2;
	else if (insn2[7])
		cinsn2 <= xinsn2;
	else
		cinsn2 <= insn2;
end


task FetchA;
begin
	fetchbufA_instr <= cinsn0;
	fetchbufA_v <= `VAL;
	fetchbufA_pc <= pc0;
	if (phit && ~hirq) begin
		if (thread_en)
			pc0 <= pc0 + fetchbuf0_insln;
		else
			pc0 <= pc0 + fetchbuf0_insln + fetchbuf1_insln;
	end
end
endtask

task FetchB;
begin
	fetchbufB_instr <= cinsn1;
	fetchbufB_v <= `VAL;
	if (thread_en) begin
		fetchbufB_pc <= pc1;
		if (phit)
			pc1 <= pc1 + fetchbuf1_insln;
	end
	else
		fetchbufB_pc <= pc0 + fetchbuf0_insln;
end
endtask

task FetchC;
begin
	fetchbufC_instr <= cinsn2;
	fetchbufC_v <= `VAL;
	if (thread_en) begin
		fetchbufC_pc <= pc2;
		if (phit)
			pc2 <= pc2 + fetchbuf2_insln;
	end
	else
		fetchbufC_pc <= pc0 + fetchbuf0_insln + fetchbuf1_insln;
end
endtask

task FetchAB;
begin
	FetchA();
	FetchB();
end
endtask

task FetchAC;
begin
	FetchA();
	FetchC();
end
endtask

task FetchBC;
begin
	FetchB();
	FetchC();
end
endtask

task FetchABC;
begin
	FetchA();
	FetchB();
	FetchC();
end
endtask


task FetchD;
begin
	fetchbufD_instr <= cinsn0;
	fetchbufD_v <= `VAL;
	fetchbufD_pc <= pc0;
	if (phit && ~hirq) begin
		if (thread_en)
			pc0 <= pc0 + fetchbuf0_insln;
		else
			pc0 <= pc0 + fetchbuf0_insln + fetchbuf1_insln;
	end
end
endtask

task FetchE;
begin
	fetchbufE_instr <= cinsn1;
	fetchbufE_v <= `VAL;
	if (thread_en) begin
		fetchbufB_pc <= pc1;
		if (phit)
			pc1 <= pc1 + fetchbuf1_insln;
	end
	else
		fetchbufE_pc <= pc0 + fetchbuf0_insln;
end
endtask

task FetchF;
begin
	fetchbufF_instr <= cinsn2;
	fetchbufF_v <= `VAL;
	if (thread_en) begin
		fetchbufF_pc <= pc2;
		if (phit)
			pc2 <= pc2 + fetchbuf2_insln;
	end
	else
		fetchbufF_pc <= pc0 + fetchbuf0_insln + fetchbuf1_insln;
end
endtask

task FetchDE;
begin
	FetchD();
	FetchE();
end
endtask

task FetchDF;
begin
	FetchD();
	FetchF();
end
endtask

task FetchEF;
begin
	FetchE();
	FetchF();
end
endtask

task FetchDEF;
begin
	FetchD();
	FetchE();
	FetchF();
end
endtask


endmodule

