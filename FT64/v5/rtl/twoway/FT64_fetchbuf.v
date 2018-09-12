// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_fetchbuf.v
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
    fetchbuf0_instr, fetchbuf1_instr, fetchbuf0_insln, fetchbuf1_insln,
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
output reg [3:0] fetchbuf0_insln;
output reg [3:0] fetchbuf1_insln;
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

integer n;
reg [3:0] fetchbufA_insln;
reg [3:0] fetchbufB_insln;
reg [3:0] fetchbufC_insln;
reg [3:0] fetchbufD_insln;

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

// Maps a subset of registers for compressed instructions.
function [4:0] fnRp;
input [2:0] rg;
case(rg)
3'd0:	fnRp = 5'd1;		// return value 0
3'd1:	fnRp = 5'd3;		// temp
3'd2:	fnRp = 5'd4;		// temp
3'd3:	fnRp = 5'd11;		// regvar
3'd4:	fnRp = 5'd12;		// regvar
3'd5:	fnRp = 5'd18;		// arg1
3'd6:	fnRp = 5'd19;		// arg2
3'd7:	fnRp = 5'd20;		// arg3
endcase
endfunction

function [47:0] expand;
input [15:0] cinstr;
casez({cinstr[15:12],cinstr[6]})
5'b00000:	// NOP / ADDI
	case(cinstr[4:0])
	5'd31:	begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5],3'b0};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = `ADDI;
			end
	default:
			begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5]};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = `ADDI;
			end
	endcase
5'b00010:	// SYS
			if (cinstr[4:0]==5'd0) begin
				expand[47:32] = 16'h0000;
				expand[5:0] = `BRK;
				expand[7:6] = 2'b10;
				expand[15:8] = {3'd1,cinstr[11:8],cinstr[5]};
				expand[16] = 1'b0;
				expand[19:17] = 3'd0;
				expand[23:20] = 4'd1;
				expand[31:24] = 8'd0;
			end
			// LDI
			else begin
				expand[47:32] = 16'h0000;
				expand[31:18] = {{9{cinstr[11]}},cinstr[11:8],cinstr[5]};
				expand[17:13] = cinstr[4:0];
				expand[12:8] = 5'd0;
				expand[7:6] = 2'b10;
				expand[5:0] = `ORI;
			end
5'b00100:	// RET / ANDI
			if (cinstr[4:0]==5'd0) begin
				expand[47:32] = 16'h0000;
				expand[5:0] = `RET;
				expand[7:6] = 2'b10;
				expand[12:8] = 5'd31;
				expand[17:13] = 5'd29;
				expand[31:18] = {8'd0,cinstr[11:8],cinstr[5],3'd0};
			end
			else begin
				expand[47:32] = 16'h0000;
				expand[5:0] = `ANDI;
				expand[7:6] = 2'b10;
				expand[12:8] = cinstr[4:0];
				expand[17:13] = cinstr[4:0];
				expand[31:18] = {{11{cinstr[11]}},cinstr[11:8],cinstr[5]};
			end
5'b00110:	// SHLI
			begin
			expand[47:32] = 16'h0000;
			expand[31:26] = 6'h0F;	// immediate mode 0-31
			expand[25:23] = 3'd0;	// SHL
			expand[22:18] = {cinstr[11:8],cinstr[5]};	// amount
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = 8'h02;		// R2 instruction
			end
5'b01000:
			case(cinstr[5:4])
			2'd0:		// SHRI
				begin
				expand[47:32] = 16'h0000;
				expand[31:26] = 6'h0F;		// shift immediate 0-31
				expand[25:23] = 3'd1;		// SHR
				expand[22:18] = {cinstr[11:8],cinstr[3]};	// amount
				expand[17:13] = fnRp(cinstr[2:0]);
				expand[12:8] = fnRp(cinstr[2:0]);
				expand[7:6] = 2'b10;
				expand[5:0] = 8'h02;		// R2 instruction
				end
			2'd1:		// ASRI
				begin
				expand[47:32] = 16'h0000;
				expand[31:26] = 6'h0F;		// shift immediate 0-31
				expand[25:23] = 3'd3;		// ASR
				expand[22:18] = {cinstr[11:8],cinstr[3]};	// amount
				expand[17:13] = fnRp(cinstr[2:0]);
				expand[12:8] = fnRp(cinstr[2:0]);
				expand[7:6] = 2'b10;
				expand[5:0] = 8'h02;		// R2 instruction
				end
			2'd2:		// ORI
				begin
				expand[47:32] = 16'h0000;
				expand[31:18] = {{9{cinstr[11]}},cinstr[11:8],cinstr[3]};
				expand[17:13] = fnRp(cinstr[2:0]);
				expand[12:8] = fnRp(cinstr[2:0]);
				expand[7:6] = 2'b10;
				expand[5:0] = `ORI;
				end
			2'd3:
				case(cinstr[11:10])
				2'd0:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `SUB;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 8'h02;		// R2 instruction
						end
				2'd1:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `AND;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 8'h02;		// R2 instruction
						end
				2'd2:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `OR;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 8'h02;		// R2 instruction
						end
				2'd3:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `XOR;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 8'h02;		// R2 instruction
						end
				endcase
			endcase
5'b01110:
		begin
			expand[47:32] = 16'h0000;
			expand[31:21] = {{1{cinstr[11]}},{cinstr[11:8],cinstr[5:0]}};
			expand[20:18] = 3'd0;		// BEQ
			expand[17:8] = 10'd0;		// r0==r0
			expand[7:6] = 2'b10;
			expand[5:0] = `Bcc;		// 0x38
		end
5'b10??0:
		begin
			expand[47:32] = 16'h0000;
			expand[31:21] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5]};
			expand[20:18] = 3'd0;			// BEQ
			expand[17:13] = 5'd0;			// r0
			expand[12:8] = cinstr[4:0];	// Ra
			expand[7:6] = 2'b10;
			expand[5:0] = `Bcc;
		end
5'b11??0:
		begin
			expand[47:32] = 16'h0000;
			expand[31:21] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5]};
			expand[20:18] = 3'd1;			// BNE
			expand[17:13] = 5'd0;			// r0
			expand[12:8] = cinstr[4:0];	// Ra
			expand[7:6] = 2'b10;
			expand[5:0] = `Bcc;
		end
5'b00001:
		begin
			expand[47:32] = 16'h0000;
			expand[31:26] = `MOV;
			expand[25:23] = 3'd7;			// move current to current
			expand[22:18] = 5'd0;			// register set (ignored)
			expand[17:13] = {cinstr[11:8],cinstr[5]};
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = 8'h02;
		end
5'b00011:	// ADD
		begin
			expand[47:32] = 16'h0000;
			expand[31:26] = `ADD;
			expand[27:23] = 3'b011;	// word size
			expand[22:18] = cinstr[4:0];
			expand[17:13] = {cinstr[11:8],cinstr[5]};
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = 6'h02;		// R2 instruction
		end
5'b00101:	// JALR
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = 14'd0;
			expand[17:13] = {cinstr[11:8],cinstr[5]};
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = `JAL;
		end
5'b01001:	// LH Rt,d[SP]
		begin
			expand[31:18] = {{8{cinstr[11]}},cinstr[11:8],cinstr[5],1'd1};
			expand[17:13] = {cinstr[4:0]};
			expand[12:8] = 65'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `Lx;
		end
5'b01011:	// LW Rt,d[SP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5],3'd4};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `Lx;
		end
5'b01101:	// LH Rt,d[fP]
		begin
			expand[31:18] = {{8{cinstr[11]}},cinstr[11:8],cinstr[5],1'd1};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 6'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `Lx;
		end
5'b01111:	// LW Rt,d[FP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5],3'd4};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `Lx;
		end
5'b10001:	// SH Rt,d[SP]
		begin
			expand[31:18] = {{8{cinstr[11]}},cinstr[11:8],cinstr[5],1'd1};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `Sx;
		end
5'b10011:	// SW Rt,d[SP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5],3'd4};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `Sx;
		end
5'b10101:	// SH Rt,d[fP]
		begin
			expand[31:18] = {{8{cinstr[11]}},cinstr[11:8],cinstr[5],1'd1};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 6'd62;
			expand[7:6] = 2'b10;
			expand[5:0] = `Sx;
		end
5'b10111:	// SW Rt,d[FP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:8],cinstr[5],3'd4};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `Sx;
		end
5'b11001:
		begin
			expand[31:18] = {{9{cinstr[11:10]}},cinstr[4:3],1'd1};
			expand[17:13] = fnRp({cinstr[9:8],cinstr[5]});
			expand[12:8] = fnRp(cinstr[2:0]);
			expand[7:6] = 2'b10;
			expand[5:0] = `Lx;
		end
5'b11111:
		begin
			expand[31:18] = {{9{cinstr[11:10]}},cinstr[4:3],3'd0};
			expand[17:13] = fnRp({cinstr[9:8],cinstr[5]});
			expand[12:8] = fnRp(cinstr[2:0]);
			expand[7:6] = 2'b10;
			expand[5:0] = `Sx;
		end
default:
		begin
			expand[47:8] = 40'd0;
			expand[7:6] = 2'b10;
			expand[5:0] = `NOP;
		end
endcase

endfunction

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Table of decompressed instructions.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
assign ack_o = cs_i & cyc_i & stb_i;
reg [31:0] DecompressTable [0:1023];
always @(posedge clk)
	if (cs_i & cyc_i & stb_i & we_i)
		DecompressTable[adr_i[11:2]] <= dat_i;
wire [31:0] expand0 = DecompressTable[insn0[15:6]];
wire [31:0] expand1 = DecompressTable[insn1[15:6]];

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
`JMP,`CALL: branch_pcA = fetchbufA_instr[6] ? {fetchbufA_instr[39:8],1'b0} : {fetchbufA_pc[31:25],fetchbufA_instr[31:8],1'b0};
`R2:		branch_pcA = btgtA;	// RTI
`BRK,`JAL:	branch_pcA = btgtA;
default:	branch_pcA = fetchbufA_pc + {{20{fetchbufA_instr[31]}},fetchbufA_instr[31:21],1'b0} + fnInsLength(fetchbufA_instr);
endcase

always @*
case(fetchbufB_instr[`INSTRUCTION_OP])
`RET:		branch_pcB = retpc1;
`JMP,`CALL: branch_pcB = fetchbufB_instr[6] ? {fetchbufB_instr[39:8],1'b0} : {fetchbufB_pc[31:25],fetchbufB_instr[31:8],1'b0};
`R2:		branch_pcB = btgtB;	// RTI
`BRK,`JAL:	branch_pcB = btgtB;
default:	branch_pcB = fetchbufB_pc + {{20{fetchbufB_instr[31]}},fetchbufB_instr[31:21],1'b0} + fnInsLength(fetchbufB_instr);
endcase

always @*
case(fetchbufC_instr[`INSTRUCTION_OP])
`RET:		branch_pcC = retpc0;
`JMP,`CALL: branch_pcC = fetchbufC_instr[6] ? {fetchbufC_instr[39:8],1'b0} : {fetchbufC_pc[31:25],fetchbufC_instr[31:8],1'b0};
`R2:		branch_pcC = btgtC;	// RTI
`BRK,`JAL:	branch_pcC = btgtC;
default:	branch_pcC = fetchbufC_pc + {{20{fetchbufC_instr[31]}},fetchbufC_instr[31:21],1'b0} + fnInsLength(fetchbufC_instr);
endcase

always @*
case(fetchbufD_instr[`INSTRUCTION_OP])
`RET:		branch_pcD = retpc1;
`JMP,`CALL: branch_pcD = fetchbufD_instr[6] ? {fetchbufD_instr[39:8],1'b0} : {fetchbufD_pc[31:25],fetchbufD_instr[31:8],1'b0};
`R2:		branch_pcD = btgtD;	// RTI
`BRK,`JAL:	branch_pcD = btgtD;
default:	branch_pcD = fetchbufD_pc + {{20{fetchbufD_instr[31]}},fetchbufD_instr[31:21],1'b0} + fnInsLength(fetchbufD_instr);
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

wire peclk, neclk;
edge_det ued1 (.rst(rst), .clk(clk4x), .ce(1'b1), .i(clk), .pe(peclk), .ne(neclk), .ee());

always @(posedge clk)
if (rst) begin
	  pc0 <= RSTPC;
`ifdef SUPPORT_SMT
      pc1 <= RSTPC;
`endif
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
		if (branchmiss_thrd) begin
 			pc0 <= fetchbuf0_pc;
`ifdef SUPPORT_SMT
			pc1 <= misspc;
`endif
		end
		else begin
			pc0 <= misspc;
`ifdef SUPPORT_SMT
 			pc1 <= fetchbuf1_pc;
`endif
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
    if (insn0[`INSTRUCTION_OP]==`EXEC)
         fetchbuf0_insln <= fnInsLength(codebuf0);
	else
    	 fetchbuf0_insln <= fnInsLength(insn0);
end

always @*
begin
    if (insn1[`INSTRUCTION_OP]==`EXEC)
         fetchbuf1_insln <= fnInsLength(codebuf1);
	else
    	 fetchbuf1_insln <= fnInsLength(insn1);
end

reg [47:0] cinsn0, cinsn1;

always @*
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
         cinsn0 <= codebuf0;
    else if (insn0[7])
    	 cinsn0 <= expand(insn0[15:0]);
    else
         cinsn0 <= insn0;
end

always @*
begin
    if (insn1[`INSTRUCTION_OP]==`EXEC)
         cinsn1 <= codebuf1;
    else if (insn1[7])
    	 cinsn1 <= expand(insn1[15:0]);
    else
         cinsn1 <= insn1;
end

task FetchA;
begin
     fetchbufA_instr <= cinsn0;
     fetchbufA_v <= `VAL;
     fetchbufA_pc <= pc0;
    if (phit && ~hirq)
`ifdef SUPPORT_SMT
    	pc0 <= pc0 + fetchbuf0_insln;
`else
    	pc0 <= pc0 + fetchbuf0_insln + fetchbuf1_insln;
`endif
end
endtask

task FetchB;
begin
	fetchbufB_instr <= cinsn1;
	fetchbufB_v <= `VAL;
`ifdef SUPPORT_SMT
	fetchbufB_pc <= pc1;
	if (phit)
		pc1 <= pc1 + fetchbuf1_insln;
`else
	fetchbufB_pc <= pc0 + fetchbuf0_insln;
`endif
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
    if (phit && ~hirq)
`ifdef SUPPORT_SMT
    	pc0 <= pc0 + fetchbuf0_insln;
`else
    	pc0 <= pc0 + fetchbuf0_insln + fetchbuf1_insln;
`endif
end
endtask

task FetchD;
begin
	fetchbufD_instr <= cinsn1;
	fetchbufD_v <= `VAL;
`ifdef SUPPORT_SMT
	fetchbufD_pc <= pc1;
	if (phit)
		pc1 <= pc1 + fetchbuf1_insln;
`else
	fetchbufD_pc <= pc0 + fetchbuf0_insln;
`endif
end
endtask

task FetchCD;
begin
	FetchC();
	FetchD();
end
endtask

endmodule
