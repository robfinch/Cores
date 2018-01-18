// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_fetchbuf4.v
//  - fetch four instructions from memory
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
// Approx 4000 (3905) LUTs
// ============================================================================
//
`include "FT64_defines.vh"

module FT64_fetchbuf4(rst, clk,
    insn0, insn1, insn2, insn3, phit, 
    branchmiss, misspc,
    predict_taken0, predict_taken1, predict_taken2, predict_taken3,
    predict_takenA, predict_takenB, predict_takenC, predict_takenD,
    predict_takenE, predict_takenF, predict_takenG, predict_takenH,
    queued1, queued2, queued3, queued4, queuedNop,
    pc0, pc1, pc2, pc3,
    fetchbuf,
    fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v,
    fetchbufE_v, fetchbufF_v, fetchbufG_v, fetchbufH_v,
    fetchbufA_instr, fetchbufA_pc,
    fetchbufB_instr, fetchbufB_pc,
    fetchbufC_instr, fetchbufC_pc,
    fetchbufD_instr, fetchbufD_pc,
    fetchbufE_instr, fetchbufE_pc,
    fetchbufF_instr, fetchbufF_pc,
    fetchbufG_instr, fetchbufG_pc,
    fetchbufH_instr, fetchbufH_pc,
    fetchbuf0_instr, fetchbuf1_instr,
    fetchbuf2_instr, fetchbuf3_instr,
    fetchbuf0_pc, fetchbuf1_pc, fetchbuf2_pc, fetchbuf3_pc,
    fetchbuf0_v, fetchbuf1_v, fetchbuf2_v, fetchbuf3_v,
    codebuf0, codebuf1,
    codebuf2, codebuf3,
    btgtA, btgtB, btgtC, btgtD,
    btgtE, btgtF, btgtG, btgtH,
    inv_fetchbuf
);
parameter RSTPC = 32'hFFFC0100;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input [31:0] insn0;
input [31:0] insn1;
input [31:0] insn2;
input [31:0] insn3;
input phit;
input branchmiss;
input [31:0] misspc;
output predict_taken0;
output predict_taken1;
output predict_taken2;
output predict_taken3;
input predict_takenA;
input predict_takenB;
input predict_takenC;
input predict_takenD;
input predict_takenE;
input predict_takenF;
input predict_takenG;
input predict_takenH;
input queued1;
input queued2;
input queued3;
input queued4;
input queuedNop;
output reg [31:0] pc0;
output reg [31:0] pc1;
output reg [31:0] pc2;
output reg [31:0] pc3;
output reg fetchbuf;
output reg fetchbufA_v;
output reg fetchbufB_v;
output reg fetchbufC_v;
output reg fetchbufD_v;
output reg fetchbufE_v;
output reg fetchbufF_v;
output reg fetchbufG_v;
output reg fetchbufH_v;
output reg [31:0] fetchbufA_instr;
output reg [31:0] fetchbufB_instr;
output reg [31:0] fetchbufC_instr;
output reg [31:0] fetchbufD_instr;
output reg [31:0] fetchbufE_instr;
output reg [31:0] fetchbufF_instr;
output reg [31:0] fetchbufG_instr;
output reg [31:0] fetchbufH_instr;
output reg [31:0] fetchbufA_pc;
output reg [31:0] fetchbufB_pc;
output reg [31:0] fetchbufC_pc;
output reg [31:0] fetchbufD_pc;
output reg [31:0] fetchbufE_pc;
output reg [31:0] fetchbufF_pc;
output reg [31:0] fetchbufG_pc;
output reg [31:0] fetchbufH_pc;
output [31:0] fetchbuf0_instr;
output [31:0] fetchbuf1_instr;
output [31:0] fetchbuf2_instr;
output [31:0] fetchbuf3_instr;
output [31:0] fetchbuf0_pc;
output [31:0] fetchbuf1_pc;
output [31:0] fetchbuf2_pc;
output [31:0] fetchbuf3_pc;
output fetchbuf0_v;
output fetchbuf1_v;
output fetchbuf2_v;
output fetchbuf3_v;
input [31:0] codebuf0;
input [31:0] codebuf1;
input [31:0] codebuf2;
input [31:0] codebuf3;
input [31:0] btgtA;
input [31:0] btgtB;
input [31:0] btgtC;
input [31:0] btgtD;
input [31:0] btgtE;
input [31:0] btgtF;
input [31:0] btgtG;
input [31:0] btgtH;
input [7:0] inv_fetchbuf;

integer n;

//`include "FT64_decode.vh"

function IsBranch;
input [31:0] isn;
casex(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`BccR:  IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
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

function IsRTE;
input [31:0] isn;
IsRTE = isn[`INSTRUCTION_OP]==`RR && isn[`INSTRUCTION_S2]==`RTE;
endfunction

reg [31:0] ras [0:15];
reg [3:0] rasp;
wire [31:0] retpc = ras[rasp];

reg did_branchback0;
reg did_branchback1;

assign predict_taken0 = (fetchbuf==1'b0) ? predict_takenA : predict_takenE;
assign predict_taken1 = (fetchbuf==1'b0) ? predict_takenB : predict_takenF;
assign predict_taken2 = (fetchbuf==1'b0) ? predict_takenC : predict_takenG;
assign predict_taken3 = (fetchbuf==1'b0) ? predict_takenD : predict_takenH;

wire [31:0] branch_pcA = IsRet(fetchbufA_instr) ? retpc :
                         IsJmp(fetchbufA_instr) | IsCall(fetchbufA_instr) ? {fetchbufA_pc[31:28],fetchbufA_instr[31:6],2'b00} :
                         ((IsRTE(fetchbufA_instr) || fetchbufA_instr[`INSTRUCTION_OP]==`BccR || fetchbufA_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufA_instr[`INSTRUCTION_OP]==`JAL) ? btgtA : 
                         fetchbufA_pc + {{19{fetchbufA_instr[`INSTRUCTION_SB]}},fetchbufA_instr[31:22],fetchbufA_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcB = IsRet(fetchbufB_instr) ? retpc :
                         IsJmp(fetchbufB_instr) | IsCall(fetchbufB_instr) ? {fetchbufB_pc[31:28],fetchbufB_instr[31:6],2'b00} :
                         ((IsRTE(fetchbufB_instr) || fetchbufB_instr[`INSTRUCTION_OP]==`BccR || fetchbufB_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufB_instr[`INSTRUCTION_OP]==`JAL) ? btgtB : 
                         fetchbufB_pc + {{19{fetchbufB_instr[`INSTRUCTION_SB]}},fetchbufB_instr[31:22],fetchbufB_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcC = IsRet(fetchbufC_instr) ? retpc :
                         IsJmp(fetchbufC_instr) | IsCall(fetchbufC_instr) ? {fetchbufC_pc[31:28],fetchbufC_instr[31:6],2'b00} :
                         ((IsRTE(fetchbufC_instr) || fetchbufC_instr[`INSTRUCTION_OP]==`BccR || fetchbufC_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufC_instr[`INSTRUCTION_OP]==`JAL) ? btgtC : 
                         fetchbufC_pc + {{19{fetchbufC_instr[`INSTRUCTION_SB]}},fetchbufC_instr[31:22],fetchbufC_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcD = IsRet(fetchbufD_instr) ? retpc :
                         IsJmp(fetchbufD_instr) | IsCall(fetchbufD_instr) ? {fetchbufD_pc[31:28],fetchbufD_instr[31:6],2'b00} : 
                         ((IsRTE(fetchbufD_instr) || fetchbufD_instr[`INSTRUCTION_OP]==`BccR ||fetchbufD_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufD_instr[`INSTRUCTION_OP]==`JAL) ? btgtD : 
                         fetchbufD_pc + {{19{fetchbufD_instr[`INSTRUCTION_SB]}},fetchbufD_instr[31:22],fetchbufD_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcE = IsRet(fetchbufE_instr) ? retpc :
                         IsJmp(fetchbufE_instr) | IsCall(fetchbufE_instr) ? {fetchbufE_pc[31:28],fetchbufE_instr[31:6],2'b00} : 
                         ((IsRTE(fetchbufE_instr) || fetchbufE_instr[`INSTRUCTION_OP]==`BccR ||fetchbufE_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufE_instr[`INSTRUCTION_OP]==`JAL) ? btgtE : 
                         fetchbufE_pc + {{19{fetchbufE_instr[`INSTRUCTION_SB]}},fetchbufE_instr[31:22],fetchbufE_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcF = IsRet(fetchbufF_instr) ? retpc :
                         IsJmp(fetchbufF_instr) | IsCall(fetchbufF_instr) ? {fetchbufF_pc[31:28],fetchbufF_instr[31:6],2'b00} : 
                         ((IsRTE(fetchbufF_instr) || fetchbufF_instr[`INSTRUCTION_OP]==`BccR ||fetchbufF_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufF_instr[`INSTRUCTION_OP]==`JAL) ? btgtF : 
                         fetchbufF_pc + {{19{fetchbufF_instr[`INSTRUCTION_SB]}},fetchbufF_instr[31:22],fetchbufF_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcG = IsRet(fetchbufG_instr) ? retpc :
                         IsJmp(fetchbufG_instr) | IsCall(fetchbufG_instr) ? {fetchbufG_pc[31:28],fetchbufG_instr[31:6],2'b00} : 
                         ((IsRTE(fetchbufG_instr) || fetchbufG_instr[`INSTRUCTION_OP]==`BccR ||fetchbufG_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufG_instr[`INSTRUCTION_OP]==`JAL) ? btgtG : 
                         fetchbufG_pc + {{19{fetchbufG_instr[`INSTRUCTION_SB]}},fetchbufG_instr[31:22],fetchbufG_instr[0],2'b00} + 64'd4);
wire [31:0] branch_pcH = IsRet(fetchbufH_instr) ? retpc :
                         IsJmp(fetchbufH_instr) | IsCall(fetchbufH_instr) ? {fetchbufH_pc[31:28],fetchbufH_instr[31:6],2'b00} : 
                         ((IsRTE(fetchbufH_instr) || fetchbufH_instr[`INSTRUCTION_OP]==`BccR ||fetchbufH_instr[`INSTRUCTION_OP]==`BRK ||
                         fetchbufH_instr[`INSTRUCTION_OP]==`JAL) ? btgtH : 
                         fetchbufH_pc + {{19{fetchbufH_instr[`INSTRUCTION_SB]}},fetchbufH_instr[31:22],fetchbufH_instr[0],2'b00} + 64'd4);
              
wire take_branchA = ({fetchbufA_v, IsBranch(fetchbufA_instr), predict_takenA}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufA_instr)|IsJmp(fetchbufA_instr)|IsCall(fetchbufA_instr)|
                        IsRTE(fetchbufA_instr)|| fetchbufA_instr[`INSTRUCTION_OP]==`BRK || fetchbufA_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufA_v);
wire take_branchB = ({fetchbufB_v, IsBranch(fetchbufB_instr), predict_takenB}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufB_instr)|IsJmp(fetchbufB_instr)|IsCall(fetchbufB_instr) ||
                        IsRTE(fetchbufB_instr)|| fetchbufB_instr[`INSTRUCTION_OP]==`BRK || fetchbufB_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufB_v);
wire take_branchC = ({fetchbufC_v, IsBranch(fetchbufC_instr), predict_takenC}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufC_instr)|IsJmp(fetchbufC_instr)|IsCall(fetchbufC_instr) ||
                        IsRTE(fetchbufC_instr)|| fetchbufC_instr[`INSTRUCTION_OP]==`BRK || fetchbufC_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufC_v);
wire take_branchD = ({fetchbufD_v, IsBranch(fetchbufD_instr), predict_takenD}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufD_instr)|IsJmp(fetchbufD_instr)|IsCall(fetchbufD_instr) ||
                        IsRTE(fetchbufD_instr)|| fetchbufD_instr[`INSTRUCTION_OP]==`BRK || fetchbufD_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufD_v);
wire take_branchE = ({fetchbufE_v, IsBranch(fetchbufE_instr), predict_takenE}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufE_instr)|IsJmp(fetchbufE_instr)|IsCall(fetchbufE_instr) ||
                        IsRTE(fetchbufE_instr)|| fetchbufE_instr[`INSTRUCTION_OP]==`BRK || fetchbufE_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufE_v);
wire take_branchF = ({fetchbufF_v, IsBranch(fetchbufF_instr), predict_takenF}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufF_instr)|IsJmp(fetchbufF_instr)|IsCall(fetchbufF_instr) ||
                        IsRTE(fetchbufF_instr)|| fetchbufF_instr[`INSTRUCTION_OP]==`BRK || fetchbufF_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufF_v);
wire take_branchG = ({fetchbufG_v, IsBranch(fetchbufG_instr), predict_takenG}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufG_instr)|IsJmp(fetchbufG_instr)|IsCall(fetchbufG_instr) ||
                        IsRTE(fetchbufG_instr)|| fetchbufG_instr[`INSTRUCTION_OP]==`BRK || fetchbufG_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufG_v);
wire take_branchH = ({fetchbufH_v, IsBranch(fetchbufH_instr), predict_takenH}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRet(fetchbufH_instr)|IsJmp(fetchbufH_instr)|IsCall(fetchbufH_instr) ||
                        IsRTE(fetchbufH_instr)|| fetchbufH_instr[`INSTRUCTION_OP]==`BRK || fetchbufH_instr[`INSTRUCTION_OP]==`JAL) &&
                        fetchbufH_v);

wire take_branch0 = take_branchA | take_branchB | take_branchC | takebranch_D;
wire take_branch1 = take_branchE | take_branchF | take_branchG | takebranch_H;


// Return address stack predictor is updated during the fetch stage on the 
// assumption that previous flow controls (branches) predicted correctly.
// Otherwise many small routines wouldn't predict the return address
// correctly because they hit the RET before the CALL reaches the 
// commit stage.
always @(posedge clk)
if (rst) begin
    for (n = 0; n < 16; n = n + 1)
        ras[n] <= RSTPC;
    rasp <= 4'd0;
end
else begin
    if (fetchbuf3_v)
        case(fetchbuf3_instr[`INSTRUCTION_OP])
        `CALL:
            begin
                ras[((rasp-6'd1)&15)] <= fetchbuf3_pc + 32'd4;
                rasp <= rasp - 6'd1;
            end
        `RET:   rasp <= rasp + 6'd1;
        endcase
    if (fetchbuf2_v)
        case(fetchbuf2_instr[`INSTRUCTION_OP])
        `CALL:
            begin
                ras[((rasp-6'd1)&15)] <= fetchbuf2_pc + 32'd4;
                rasp <= rasp - 6'd1;
            end
        `RET:   rasp <= rasp + 6'd1;
        endcase
    if (fetchbuf1_v)
        case(fetchbuf1_instr[`INSTRUCTION_OP])
        `CALL:
            begin
                ras[((rasp-6'd1)&15)] <= fetchbuf1_pc + 32'd4;
                rasp <= rasp - 6'd1;
            end
        `RET:   rasp <= rasp + 6'd1;
        endcase
    if (fetchbuf0_v)
        case(fetchbuf0_instr[`INSTRUCTION_OP])
        `CALL:
            begin
                ras[((rasp-6'd1)&15)] <= fetchbuf0_pc + 32'd4;
                rasp <= rasp - 6'd1;
            end
        `RET:   rasp <= rasp + 6'd1;
        endcase
end

reg [2:0] nqopen;
always @*
if (queued4|queuedNop)
	nqopen = 3'd4;
else if (queued3|queuedNop)
	nqopen = 3'd3;
else if (queued2|queuedNop)
	nqopen = 3'd2;
else if (queued1|queuedNop)
	nqopen = 3'd1;
else
	nqopen = 3'd0;

always @(posedge clk)
if (rst) begin
	pc0 <= RSTPC;
    pc1 <= RSTPC + 32'd4;
    pc2 <= RSTPC + 32'd8;
    pc3 <= RSTPC + 32'd12;
    fetchbufA_v <= 0;
    fetchbufB_v <= 0;
    fetchbufC_v <= 0;
    fetchbufD_v <= 0;
    fetchbufE_v <= 0;
    fetchbufF_v <= 0;
    fetchbufG_v <= 0;
    fetchbufH_v <= 0;
    fetchbuf <= 0;
end
else begin

	did_branchback0 <= take_branch0;
	did_branchback1 <= take_branch1;

	if (branchmiss) begin
		
	    pc0 <= misspc;
	    pc1 <= misspc + 32'd4;
	    pc2 <= misspc + 32'd8;
	    pc3 <= misspc + 32'd12;
	    
	    fetchbuf <= 1'b0;
	    fetchbufA_v <= `INV;
	    fetchbufB_v <= `INV;
	    fetchbufC_v <= `INV;
	    fetchbufD_v <= `INV;
	    fetchbufE_v <= `INV;
	    fetchbufF_v <= `INV;
	    fetchbufG_v <= `INV;
	    fetchbufH_v <= `INV;
	end
	// Some of the testing for valid branch conditions has been removed. In real
	// hardware it isn't needed, and just increases the size of the core. It's
	// assumed that the hardware is working.
	// The risk is an error will occur during simulation and go missed.
	else if (take_branch) begin
	    if (fetchbuf == 1'b0) begin
			if ({fetchbufE_v,fetchbufF_v,fetchbufG_v,fetchbufH_v}==4'h0) begin
				case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v})
				4'b0000: ;	// do nothing
				4'b0001:
				    begin
					    FetchEFGH();
					    fetchbufD_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0010:
				    begin
					    FetchEFGH();
					    fetchbufC_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0011:
				    begin
					    FetchEFGH();
					    fetchbufC_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufD_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0100:
				    begin
					    FetchEFGH();
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b0101:
				    begin
					    FetchEFGH();
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufD_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0110:
				    begin
					    FetchEFGH();
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0111:
				    begin
					    FetchEFGH();
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbufD_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1000:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b1001:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufD_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1010:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1011:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbufD_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1100:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1101:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= nqopen < 3'd2;
					    fetchbufD_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1110:
				    begin
					    FetchEFGH();
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= nqopen < 3'd2;
					    fetchbufC_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1111:
					if (take_branchA) begin
					    // has to be first scenario
					    pc0 <= branch_pcA;
					    pc1 <= branch_pcA + 32'd4;
					    pc2 <= branch_pcA + 32'd8;
					    pc3 <= branch_pcA + 32'd12;
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= `INV;		// stomp on it
					    fetchbufC_v <= `INV;		// stomp on it
					    fetchbufD_v <= `INV;		// stomp on it
					    if (nqopen >= 3'd1)	fetchbuf <= 1'b0;
					end
					else if (take_branchB) begin
					    if (did_branchback0) begin
					    FetchEFGH();
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					    end
					    else begin
					    pc0 <= branch_pcB;
					    pc1 <= branch_pcB + 32'd4;
					    pc2 <= branch_pcB + 32'd8;
					    pc3 <= branch_pcB + 32'd12;
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					    end
					end
					else if (take_branchC) begin
					    if (did_branchback0) begin
					    FetchEFGH();
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufC_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					    end
					    else begin
					    pc0 <= branch_pcC;
					    pc1 <= branch_pcC + 32'd4;
					    pc2 <= branch_pcC + 32'd8;
					    pc3 <= branch_pcC + 32'd12;
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufC_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					    end
					end
					else if (take_branchD) begin
					    if (did_branchback0) begin
					    FetchEFGH();
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufC_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbufD_v <= nqopen < 3'd4;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd4);
					    end
					    else begin
					    pc0 <= branch_pcD;
					    pc1 <= branch_pcD + 32'd4;
					    pc2 <= branch_pcD + 32'd8;
					    pc3 <= branch_pcD + 32'd12;
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufC_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbufD_v <= nqopen < 3'd4;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd4);
					    end
					end
				endcase
			end
			else begin	// something in fetchbuf E to H
				case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v})
				4'b0000: ;	// do nothing
				4'b0001:
				    begin
					    fetchbufD_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0010:
				    begin
					    fetchbufC_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0011:
				    begin
					    fetchbufC_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufD_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0100:
				    begin
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b0101:
				    begin
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufD_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0110:
				    begin
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0111:
				    begin
					    fetchbufB_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbufD_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1000:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b1001:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufD_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1010:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1011:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufC_v <= nqopen < 3'd2;
					    fetchbufD_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1100:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1101:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= nqopen < 3'd2;
					    fetchbufD_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1110:
				    begin
					    fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufB_v <= nqopen < 3'd2;
					    fetchbufC_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1111:
					begin
						fetchbufA_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufB_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufC_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbufD_v <= nqopen < 3'd4;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd4);
					end
				endcase
			end
		end
	    else begin
			if ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v}==4'h0) begin
				case ({fetchbufE_v, fetchbufF_v, fetchbufG_v, fetchbufH_v})
				4'b0000: ;	// do nothing
				4'b0001:
				    begin
					    FetchABCD();
					    fetchbufH_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0010:
				    begin
					    FetchABCD();
					    fetchbufG_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0011:
				    begin
					    FetchABCD();
					    fetchbufG_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufH_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0100:
				    begin
					    FetchABCD();
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b0101:
				    begin
					    FetchABCD();
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufH_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0110:
				    begin
					    FetchABCD();
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0111:
				    begin
					    FetchABCD();
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbufH_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1000:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b1001:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufH_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1010:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1011:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbufH_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1100:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1101:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= nqopen < 3'd2;
					    fetchbufH_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1110:
				    begin
					    FetchABCD();
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= nqopen < 3'd2;
					    fetchbufG_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1111:
					if (take_branchE) begin
					    // has to be first scenario
					    pc0 <= branch_pcE;
					    pc1 <= branch_pcE + 32'd4;
					    pc2 <= branch_pcE + 32'd8;
					    pc3 <= branch_pcE + 32'd12;
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= `INV;		// stomp on it
					    fetchbufG_v <= `INV;		// stomp on it
					    fetchbufH_v <= `INV;		// stomp on it
					    if (nqopen >= 3'd1)	fetchbuf <= 1'b0;
					end
					else if (take_branchF) begin
					    if (did_branchback0) begin
					    FetchABCD();
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					    end
					    else begin
					    pc0 <= branch_pcF;
					    pc1 <= branch_pcF + 32'd4;
					    pc2 <= branch_pcF + 32'd8;
					    pc3 <= branch_pcF + 32'd12;
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					    end
					end
					else if (take_branchG) begin
					    if (did_branchback0) begin
					    FetchABCD();
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufG_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					    end
					    else begin
					    pc0 <= branch_pcG;
					    pc1 <= branch_pcG + 32'd4;
					    pc2 <= branch_pcG + 32'd8;
					    pc3 <= branch_pcG + 32'd12;
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufG_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					    end
					end
					else if (take_branchH) begin
					    if (did_branchback0) begin
					    FetchABCD();
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufG_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbufH_v <= nqopen < 3'd4;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd4);
					    end
					    else begin
					    pc0 <= branch_pcH;
					    pc1 <= branch_pcH + 32'd4;
					    pc2 <= branch_pcH + 32'd8;
					    pc3 <= branch_pcH + 32'd12;
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufG_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbufH_v <= nqopen < 3'd4;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd4);
					    end
					end
				endcase
			end
			else begin	// something in fetchbuf A to D
				case ({fetchbufE_v, fetchbufF_v, fetchbufG_v, fetchbufH_v})
				4'b0000: ;	// do nothing
				4'b0001:
				    begin
					    fetchbufH_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0010:
				    begin
					    fetchbufG_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen > 3'd0);
					end
				4'b0011:
				    begin
					    fetchbufG_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufH_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0100:
				    begin
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b0101:
				    begin
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufH_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0110:
				    begin
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b0111:
				    begin
					    fetchbufF_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbufH_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1000:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbuf <= fetchbuf + (nqopen >= 3'd1);
					end
				4'b1001:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufH_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1010:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1011:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufG_v <= nqopen < 3'd2;
					    fetchbufH_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1100:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= nqopen < 3'd2;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd2);
					end
				4'b1101:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= nqopen < 3'd2;
					    fetchbufH_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1110:
				    begin
					    fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
					    fetchbufF_v <= nqopen < 3'd2;
					    fetchbufG_v <= nqopen < 3'd3;
					    fetchbuf <= fetchbuf + (nqopen >= 3'd3);
					end
				4'b1111:
					begin
						fetchbufE_v <= nqopen < 3'd1;	// if it can be queued, it will
						fetchbufF_v <= nqopen < 3'd2;	// if it can be queued, it will
						fetchbufG_v <= nqopen < 3'd3;	// if it can be queued, it will
						fetchbufH_v <= nqopen < 3'd4;	// if it can be queued, it will
						fetchbuf <= fetchbuf + (nqopen >= 3'd4);
					end
				endcase
			end
		end
	end // if branchback

	else begin	// there is no branchback in the system
	    //
	    // update fetchbufX_v and fetchbuf ... relatively simple, as
	    // there are no backwards branches in the mix
	    if (fetchbuf == 1'b0)
	    case ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v})
	    4'b0000:	;	// do nothing
	    4'b0001:	if (nqopen > 3'd0) begin
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b0010:	if (nqopen > 3'd0) begin
	    				fetchbufC_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b0011:	if (nqopen > 3'd1) begin
	    				fetchbufC_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufC_v <= `INV;
	    			end
	    4'b0100:	if (nqopen > 3'd0) begin
	    				fetchbufB_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b0101:	if (nqopen > 3'd1) begin
	    				fetchbufB_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufB_v <= `INV;
	    			end
	    4'b0110:	if (nqopen > 3'd1) begin
	    				fetchbufB_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufB_v <= `INV;
	    			end
	    4'b0111:
	    			if (nqopen > 3'd2) begin
	    				fetchbufB_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufB_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufB_v <= `INV;
	    			end
	    4'b1000:	if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b1001:	if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    			end
	    4'b1010:	if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    			end
	    4'b1011:
	    			if (nqopen > 3'd2) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufC_v <= `INV;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufB_v <= `INV;
	    			end
	    4'b1100:	if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    			end
	    4'b1101:
	    			if (nqopen > 3'd2) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    			end
	    4'b1110:
	    			if (nqopen > 3'd2) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    			end
	    4'b1111:
	    			if (nqopen > 3'd3) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    				fetchbufC_v <= `INV;
	    				fetchbufD_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd2) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    				fetchbufC_v <= `INV;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufA_v <= `INV;
	    				fetchbufB_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufA_v <= `INV;
	    			end
		default:  ;
	    endcase
	    else
	    case ({fetchbufE_v,fetchbufF_v,fetchbufG_v,fetchbufH_v})
	    4'b0000:	;	// do nothing
	    4'b0001:	if (nqopen > 3'd0) begin
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b0010:	if (nqopen > 3'd0) begin
	    				fetchbufG_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b0011:	if (nqopen > 3'd1) begin
	    				fetchbufG_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufG_v <= `INV;
	    			end
	    4'b0100:	if (nqopen > 3'd0) begin
	    				fetchbufF_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b0101:	if (nqopen > 3'd1) begin
	    				fetchbufF_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufF_v <= `INV;
	    			end
	    4'b0110:	if (nqopen > 3'd1) begin
	    				fetchbufF_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufF_v <= `INV;
	    			end
	    4'b0111:
	    			if (nqopen > 3'd2) begin
	    				fetchbufF_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufF_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufF_v <= `INV;
	    			end
	    4'b1000:	if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    4'b1001:	if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
	    4'b1010:	if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
	    4'b1011:
	    			if (nqopen > 3'd2) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufG_v <= `INV;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
	    4'b1100:	if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
	    4'b1101:
	    			if (nqopen > 3'd2) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
	    4'b1110:
	    			if (nqopen > 3'd2) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
	    4'b1111:
	    			if (nqopen > 3'd3) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    				fetchbufG_v <= `INV;
	    				fetchbufH_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd2) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    				fetchbufG_v <= `INV;
	    			end
	    			else if (nqopen > 3'd1) begin
	    				fetchbufE_v <= `INV;
	    				fetchbufF_v <= `INV;
	    				fetchbuf <= ~fetchbuf;
	    			end
	    			else if (nqopen > 3'd0) begin
	    				fetchbufE_v <= `INV;
	    			end
		default:  ;
	    endcase

	    //
	    // Get data iff the fetch buffers are empty
	    // After a branch miss the fetchbuf buffer should only be valid for
	    // instructions coming after the branch. The branch might have been
	    // into the middle of a cache line. We don't want to execute
	    // instructions coming before the branch target.
	    //
	    if ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v}==4'h0) begin
            FetchABCD();
            // fetchbuf steering logic correction
            if ({fetchbufE_v,fetchbufF_v,fetchbufG_v,fetchbufH_v}==4'h0 && phit)
                fetchbuf <= 1'b0;
	    end
	    else if ({fetchbufE_v,fetchbufF_v,fetchbufG_v,fetchbufH_v}==4'h0)
    	    FetchEFGH();
	end
	if (inv_fetchbuf[0]) fetchbufA_instr <= `NOP_INSN;
	if (inv_fetchbuf[1]) fetchbufB_instr <= `NOP_INSN;
	if (inv_fetchbuf[2]) fetchbufC_instr <= `NOP_INSN;
	if (inv_fetchbuf[3]) fetchbufD_instr <= `NOP_INSN;
	if (inv_fetchbuf[4]) fetchbufE_instr <= `NOP_INSN;
	if (inv_fetchbuf[5]) fetchbufF_instr <= `NOP_INSN;
	if (inv_fetchbuf[6]) fetchbufG_instr <= `NOP_INSN;
	if (inv_fetchbuf[7]) fetchbufH_instr <= `NOP_INSN;
end

assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufE_instr;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufE_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufE_pc   ;
assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufF_instr;
assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufF_v    ;
assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufF_pc   ;
assign fetchbuf2_instr = (fetchbuf == 1'b0) ? fetchbufC_instr : fetchbufG_instr;
assign fetchbuf2_v     = (fetchbuf == 1'b0) ? fetchbufC_v     : fetchbufG_v    ;
assign fetchbuf2_pc    = (fetchbuf == 1'b0) ? fetchbufC_pc    : fetchbufG_pc   ;
assign fetchbuf3_instr = (fetchbuf == 1'b0) ? fetchbufD_instr : fetchbufH_instr;
assign fetchbuf3_v     = (fetchbuf == 1'b0) ? fetchbufD_v     : fetchbufH_v    ;
assign fetchbuf3_pc    = (fetchbuf == 1'b0) ? fetchbufD_pc    : fetchbufH_pc   ;

task FetchABCD;
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
        fetchbufA_instr <= codebuf0;
    else
        fetchbufA_instr <= insn0;
    fetchbufA_v <= `VAL;
    fetchbufA_pc <= pc0;
    if (insn1[`INSTRUCTION_OP]==`EXEC)
        fetchbufB_instr <= codebuf1;
    else
        fetchbufB_instr <= insn1;
    fetchbufB_v <= `VAL;
    fetchbufB_pc <= pc1;
    if (insn2[`INSTRUCTION_OP]==`EXEC)
        fetchbufC_instr <= codebuf2;
    else
        fetchbufC_instr <= insn2;
    fetchbufC_v <= `VAL;
    fetchbufC_pc <= pc2;
    if (insn3[`INSTRUCTION_OP]==`EXEC)
        fetchbufD_instr <= codebuf3;
    else
        fetchbufD_instr <= insn3;
    fetchbufD_v <= `VAL;
    fetchbufD_pc <= pc3;
    if (phit) begin
    pc0 <= pc0 + 16;
    pc1 <= pc1 + 16;
    pc2 <= pc2 + 16;
    pc3 <= pc3 + 16;
    end
end
endtask

task FetchEFGH;
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
        fetchbufE_instr <= codebuf0;
    else
        fetchbufE_instr <= insn0;
    fetchbufE_v <= `VAL;
    fetchbufE_pc <= pc0;
    if (insn1[`INSTRUCTION_OP]==`EXEC)
        fetchbufF_instr <= codebuf1;
    else
        fetchbufF_instr <= insn1;
    fetchbufF_v <= `VAL;
    fetchbufF_pc <= pc1;
    if (insn2[`INSTRUCTION_OP]==`EXEC)
        fetchbufG_instr <= codebuf2;
    else
        fetchbufG_instr <= insn2;
    fetchbufG_v <= `VAL;
    fetchbufG_pc <= pc2;
    if (insn3[`INSTRUCTION_OP]==`EXEC)
        fetchbufH_instr <= codebuf3;
    else
        fetchbufH_instr <= insn3;
    fetchbufH_v <= `VAL;
    fetchbufH_pc <= pc3;
    if (phit) begin
    pc0 <= pc0 + 16;
    pc1 <= pc1 + 16;
    pc2 <= pc2 + 16;
    pc3 <= pc3 + 16;
    end
end
endtask

endmodule
