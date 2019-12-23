// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
`include "..\Gambit-defines.sv"
`include "..\Gambit-types.sv"
`include "..\Gambit-config.sv"

module microop_engine(rst, clk, qcnt, phit, stall_uoq, opcode1, opcode2, pc, len1,
	uop_prg, uopqd, uopqd_o, uoq_empty, branchmiss, ptr, take_branch, take_branchq, whinst_o,
	insnx, insnxx, whinst, mip1, mip2, uop2q, uoppc, branchmiss1, nextBundle);
input rst;
input clk;
input [2:0] qcnt;
input phit;
input stall_uoq;
input [8:0] opcode1;
input [8:0] opcode2;
input [`AMSB:0] pc;
input [2:0] len1;
input MicroOp uop_prg [0:`LAST_UOP];
input [2:0] uopqd;
output reg [2:0] uopqd_o;
input uoq_empty;
input branchmiss;
input [1:0] take_branch;
output reg [1:0] take_branchq;
input MicroOpPtr ptr [0:3];
input [51:0] insnx [0:1];
output reg [51:0] insnxx [0:1];
input [3:0] whinst;
output reg [3:0] whinst_o;
output MicroOpPtr mip1;
output MicroOpPtr mip2;
output MicroOp uop2q [0:3];
output reg [`AMSB:0] uoppc [0:3];
output reg branchmiss1;
output nextBundle;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

reg branchmiss2;
reg [`AMSB:0] pcr [0:1];
reg [`AMSB:0] pcrx [0:1];
reg [2:0] mipst;
reg [51:0] insnxy [0:1];
reg [1:0] tb;
reg [2:0] uopqd1;
reg stall1, stall2;
reg nxtb;
reg [5:0] empty_ctr;
MicroOpPtr mip1x, mip2x;
parameter MIP_RESET = 3'd1;
parameter MIP_RUN = 3'd2;
parameter MIP_STALL = 3'd3;
parameter MIP_UNSTALL = 3'd4;

`include ".\Gambit-micro-program-parameters.sv"

reg [7:0] uop_map [0:511];

// Instruction to micro-program address translation table.
initial begin
uop_map = {
	ADD_RR,ADD_RR,ADD_RR,ADD_RR,ADD_RR,ADD_RR,ADD_RR,ADD_RR,
	ADD_RI23,ADD_RI23,ADD_RI23,ADD_RI23,ADD_RI23,ADD_RI23,ADD_RI23,ADD_RI23,
	ADD_RI36,ADD_RI36,ADD_RI36,ADD_RI36,ADD_RI36,ADD_RI36,ADD_RI36,ADD_RI36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	JMP_ABS,JMP_ABS,JMP_ABS,JMP_ABS,JMP_ABS,JMP_ABS,JMP_ABS,JMP_ABS,
	BEQ_D4,BNE_D4,BPL_D4,BMI_D4,BVS_D4,BVC_D4,BCS_D4,BCC_D4,
	ASL_RR,ASL_RR,ASL_RR,ASL_RR,ASL_RR,ASL_RR,ASL_RR,ASL_RR,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	SUB_RR,SUB_RR,SUB_RR,SUB_RR,SUB_RR,SUB_RR,SUB_RR,SUB_RR,
	SUB_RI23,SUB_RI23,SUB_RI23,SUB_RI23,SUB_RI23,SUB_RI23,SUB_RI23,SUB_RI23,
	SUB_RI36,SUB_RI36,SUB_RI36,SUB_RI36,SUB_RI36,SUB_RI36,SUB_RI36,SUB_RI36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	JSR_ABS,JSR_ABS,JSR_ABS,JSR_ABS,JSR_ABS,JSR_ABS,JSR_ABS,JSR_ABS,
	BEQ_D17,BNE_D17,BPL_D17,BMI_D17,BVS_D17,BVC_D17,BCS_D17,BCC_D17,
	LSR_RR,LSR_RR,LSR_RR,LSR_RR,LSR_RR,LSR_RR,LSR_RR,LSR_RR,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	RTS,RTI,PFI_0,IRQ,WAI_0,IRQ,LSTP,LNOP,
	BRA_D4,UNIMP,BUS_D4,BUC_D4,UNIMP,UNIMP,UNIMP,UNIMP,
	ROL_RR,ROL_RR,ROL_RR,ROL_RR,ROL_RR,ROL_RR,ROL_RR,ROL_RR,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	AND_RR,AND_RR,AND_RR,AND_RR,AND_RR,AND_RR,AND_RR,AND_RR,
	AND_RI23,AND_RI23,AND_RI23,AND_RI23,AND_RI23,AND_RI23,AND_RI23,AND_RI23,
	AND_RI36,AND_RI36,AND_RI36,AND_RI36,AND_RI36,AND_RI36,AND_RI36,AND_RI36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	RST,NMI,IRQ,BRK,BRK,BRK,BRK,BRK,
	BRA_D17,UNIMP,BUS_D17,BUC_D17,UNIMP,UNIMP,UNIMP,UNIMP,
	ROR_RR,ROR_RR,ROR_RR,ROR_RR,ROR_RR,ROR_RR,ROR_RR,ROR_RR,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	OR_RR,OR_RR,OR_RR,OR_RR,OR_RR,OR_RR,OR_RR,OR_RR,
	OR_RI23,OR_RI23,OR_RI23,OR_RI23,OR_RI23,OR_RI23,OR_RI23,OR_RI23,
	OR_RI36,OR_RI36,OR_RI36,OR_RI36,OR_RI36,OR_RI36,OR_RI36,OR_RI36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	JMP_R,JMP_R,JMP_R,JMP_R,JMP_R,JMP_R,JMP_R,JMP_R,
	MVNB,MVPB,STSB,CMPSB,MVN,MVP,STS,CMPS,
	LSEP,LSEP,LSEP,LSEP,LSEP,LSEP,LSEP,LSEP,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	EOR_RR,EOR_RR,EOR_RR,EOR_RR,EOR_RR,EOR_RR,EOR_RR,EOR_RR,
	EOR_RI23,EOR_RI23,EOR_RI23,EOR_RI23,EOR_RI23,EOR_RI23,EOR_RI23,EOR_RI23,
	EOR_RI36,EOR_RI36,EOR_RI36,EOR_RI36,EOR_RI36,EOR_RI36,EOR_RI36,EOR_RI36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	JSR_R,JSR_R,JSR_R,JSR_R,JSR_R,JSR_R,JSR_R,JSR_R,			
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	LREP,LREP,LREP,LREP,LREP,LREP,LREP,LREP,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	LD_D9,LD_D9,LD_D9,LD_D9,LD_D9,LD_D9,LD_D9,LD_D9,
	LD_D23,LD_D23,LD_D23,LD_D23,LD_D23,LD_D23,LD_D23,LD_D23,
	LD_D36,LD_D36,LD_D36,LD_D36,LD_D36,LD_D36,LD_D36,LD_D36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	LDB_D36,LDB_D36,LDB_D36,LDB_D36,LDB_D36,LDB_D36,LDB_D36,LDB_D36,
	PLP,PLP,PLP,PLP,PLP,PLP,PLP,PLP,
	POP,POP,POP,POP,POP,POP,POP,POP,	
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,

	ST_D9,ST_D9,ST_D9,ST_D9,ST_D9,ST_D9,ST_D9,ST_D9,
	ST_D23,ST_D23,ST_D23,ST_D23,ST_D23,ST_D23,ST_D23,ST_D23,
	ST_D36,ST_D36,ST_D36,ST_D36,ST_D36,ST_D36,ST_D36,ST_D36,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,
	STB_D36,STB_D36,STB_D36,STB_D36,STB_D36,STB_D36,STB_D36,STB_D36,
	PHP,PHP,PHP,PHP,PHP,PHP,PHP,PHP,
	PSH,PSH,PSH,PSH,PSH,PSH,PSH,PSH,
	UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP,UNIMP
};
end

wire pcchg = pcr[0] != pc;
wire nbx;
wire willmap = 
	mipst==MIP_RUN && !stall1 && (qcnt==3'd2 || (mip1==1'd0 && qcnt==3'd1) || (mip1==1'd0 && mip2==1'd0)) && phit;
	
assign nextBundle = (mipst==MIP_RUN && !stall1 && (qcnt==3'd2 || (mip1==1'd0 && qcnt==3'd1) || (mip1==1'd0 && mip2==1'd0)) && (phit)) || nxtb;
//	(
//	(nbx && mipst==MIP_RUN && !stall1 && !(qcnt==3'd2 || (mip1==1'd0 && qcnt==3'd1) || (mip1==1'd0 && mip2==1'd0))) ||
//	(nbx && mipst==MIP_RUN && stall1 && uopqd > 3'd0) ||
//	(nbx && mipst==MIP_STALL && uopqd > 3'd0)
//	)
//	;

// The following is the micro-program engine. It advances the micro-program
// counters as micro-instructions are queued. And select which micro-program
// instructions to queue.
always @(posedge clk)
if (rst) begin
	mip1 <= 12'd0;
	mip2 <= 12'd0;
	uop2q[0] <= {2'd3,ADD,4'd0,4'd0,4'd0,4'd0};
	uop2q[1] <= {2'd3,ADD,4'd0,4'd0,4'd0,4'd0};
	uop2q[2] <= {2'd3,ADD,4'd0,4'd0,4'd0,4'd0};
	uop2q[3] <= {2'd3,ADD,4'd0,4'd0,4'd0,4'd0};
	pcr[0] <= 1'd0;
	pcr[1] <= 1'd0;
	insnxx[0] <= 52'd0;
	insnxx[1] <= 52'd0;
	insnxy[0] <= 52'd0;
	insnxy[1] <= 52'd0;
	mipst <= MIP_RUN;
	branchmiss1 <= FALSE;
	branchmiss2 <= FALSE;
	whinst_o <= 4'h0;
	uopqd_o <= 3'd0;
	stall1 <= 1'd0;
	stall2 <= 1'd0;
	nxtb <= 1'b0;
	empty_ctr <= 6'd0;
end
else begin
	nxtb <= FALSE;
	
	if (uoq_empty) begin
		empty_ctr <= empty_ctr + 2'd1;
		if (empty_ctr > 3'd4) begin
			nxtb <= TRUE;
			empty_ctr <= 6'd0;
		end
	end

	case(mipst)
	MIP_RUN:
		begin
			if (!pcchg) begin
				mip1 <= 1'd0;
				mip2 <= 1'd0;
			end
			stall1 <= stall_uoq;
			stall2 <= stall1;
			if (!stall1) begin
				// stage 2
				// select micro-instructions to queue
				// increment mmicro-program counters
				mip1 <= 1'd0;
				mip2 <= 1'd0;
				insnxy[0] <= 52'd0;
				insnxy[1] <= 52'd0;
				propagatePipeline();

				// Stage 1
				// map opcodes
				if (pcchg) begin
					insnxy[0] <= insnx[0];	// capture instruction
					insnxy[1] <= insnx[1];
				end
				else begin
					insnxy[0] <= 52'd0;
					insnxy[1] <= 52'd0;
					mip1 <= 1'd0;
					mip2 <= 1'd0;
				end

				// Fetch new pointers or advance current ones.
				if (qcnt==3'd2 || (mip1==1'd0 && qcnt==3'd1) || (mip1==1'd0 && mip2==1'd0)) begin
					if (phit) begin
						if (pcchg) begin
							mip1 <= uop_map[{opcode1[5:0],opcode1[8:6]}];
							mip2 <= uop_map[{opcode2[5:0],opcode2[8:6]}];
						end
						else if (!stall1) begin
							mip1 <= 1'd0;
							mip2 <= 1'd0;
						end
						pcr[0] <= pc;						// and associated program counter
						pcr[1] <= pc + len1;
					end
					else if (!stall1) begin
						mip1 <= 1'd0;
						mip2 <= 1'd0;
					end
				end
				else
					advancePtrs();
			end
			// A stall occurs when there isn't enough room in the micro-op queue to
			// queue more micro-ops. In that case a transition is made to a state
			// that waits for the stall to clear.
			else begin
				if (uopqd > 3'd0) begin
					mip1 <= 1'd0;
					mip2 <= 1'd0;
					insnxy[0] <= 52'd0;
					insnxy[1] <= 52'd0;
					propagatePipeline();
					advancePtrs();
				end
				mipst <= MIP_STALL;
			end
		end
	
	MIP_STALL:
		begin
			if (!pcchg) begin
				mip1 <= 1'd0;
				mip2 <= 1'd0;
			end
			stall1 <= stall_uoq;
			stall2 <= stall1;
			if (uopqd > 3'd0) begin
				insnxy[0] <= 52'd0;
				insnxy[1] <= 52'd0;
				mip1 <= 1'd0;
				mip2 <= 1'd0;
				propagatePipeline();
				advancePtrs();
			end
			else begin
				mip1 <= 1'd0;
				mip2 <= 1'd0;
			end		
			if (!stall1) begin
				mipst <= MIP_RUN;
			end
		end
	endcase
		
end

task doMap;
begin
	mip2 <= 1'd0;
	if (phit) begin
		if (pcchg) begin
			insnxy[0] <= insnx[0];
			insnxy[1] <= insnx[1];
			mip1 <= uop_map[{opcode1[5:0],opcode1[8:6]}];
			mip2 <= uop_map[{opcode2[5:0],opcode2[8:6]}];
			pcr[0] <= pc;						// and associated program counter
			pcr[1] <= pc + len1;
			nxtb <= TRUE;
			propagatePipeline();
		end
		else begin
			mip1 <= 1'd0;
			mip2 <= 1'd0;
		end
	end
	else begin
		mip1 <= 1'd0;
		mip2 <= 1'd0;
		insnxy[0] <= 52'd0;
		insnxy[1] <= 52'd0;
	end
end
endtask

task propagatePipeline;
begin
	branchmiss1 <= branchmiss;
	branchmiss2 <= branchmiss1;
	insnxx[0] <= insnxy[0];
	insnxx[1] <= insnxy[1];
	uop2q[0] <= uop_prg[ptr[0]];
	uop2q[1] <= uop_prg[ptr[1]];
	uop2q[2] <= uop_prg[ptr[2]];
	uop2q[3] <= uop_prg[ptr[3]];
	uoppc[0] <= whinst[0] ? pcr[1] : pcr[0];
	uoppc[1] <= whinst[1] ? pcr[1] : pcr[0];
	uoppc[2] <= whinst[2] ? pcr[1] : pcr[0];
	uoppc[3] <= whinst[3] ? pcr[1] : pcr[0];
	tb <= take_branch;
	take_branchq <= tb;
	whinst_o <= whinst;
//	uopqd1 <= uopqd;
	uopqd_o <= uopqd;
end
endtask

wire nb1 = |mip1 && !uop_prg[mip1].fl[1] && uopqd > 3'd1 && !uop_prg[mip1+1].fl[1] && (uopqd > 3'd2)
					&& uop_prg[mip1+2].fl[1] && (uopqd > 3'd3) && uop_prg[mip2].fl[1] && phit;
wire nb2 = |mip1 && !uop_prg[mip1].fl[1] && uopqd > 3'd1 &&  uop_prg[mip1+1].fl[1] && (uopqd > 3'd2)
					&& !uop_prg[mip2].fl[1] && (uopqd > 3'd3) && uop_prg[mip2+1].fl[1] && phit;
wire nb3 = |mip1 && !uop_prg[mip1].fl[1] && uopqd > 3'd1 &&  uop_prg[mip1+1].fl[1] && (uopqd > 3'd2)
					&& uop_prg[mip2].fl[1] && phit;
wire nb4 = |mip1 && uop_prg[mip1].fl[1] && (uopqd > 3'd1) && !uop_prg[mip2].fl[1] && (uopqd > 3'd2)
					&& !uop_prg[mip2+1].fl[1] && (uopqd > 3'd3) && uop_prg[mip2+2].fl[1] && phit;
wire nb5 = |mip1 && uop_prg[mip1].fl[1] && (uopqd > 3'd1) && !uop_prg[mip2].fl[1] && (uopqd > 3'd2)
					&& uop_prg[mip2+1].fl[1] && phit;
wire nb6 = |mip1 && uop_prg[mip1].fl[1] && (uopqd > 3'd1) && uop_prg[mip2].fl[1] && phit;
wire nb7 = ~|mip1 && !uop_prg[mip2].fl[1] && (uopqd > 3'd1) && !uop_prg[mip2+1].fl[1] && (uopqd > 3'd2)
					&& !uop_prg[mip2+2].fl[1] && (uopqd > 3'd3) && uop_prg[mip2+3].fl[1] && phit;
wire nb8 = ~|mip1 && !uop_prg[mip2].fl[1] && (uopqd > 3'd1) && !uop_prg[mip2+1].fl[1] && (uopqd > 3'd2)
					&& uop_prg[mip2+2].fl[1] && phit;
wire nb9 = ~|mip1 && !uop_prg[mip2].fl[1] && (uopqd > 3'd1) && uop_prg[mip2+1].fl[1] & phit;
wire nb10 = ~|mip1 && uop_prg[mip2].fl[1] & phit;

assign nbx = nb1|nb2|nb3|nb4|nb5|nb6|nb7|nb8|nb9|nb10;

task advancePtrs;
begin
	if (|mip1) begin
		mip1 <= mip1 + uopqd;
		if (!uop_prg[mip1].fl[1]) begin
			if (uopqd > 3'd1) begin
				if (!uop_prg[mip1+1].fl[1]) begin
					if (uopqd > 3'd2) begin
						if (!uop_prg[mip1+2].fl[1]) begin
							if (uopqd > 3'd3) begin
								if (uop_prg[mip1+3].fl[1])
									mip1 <= 1'd0;
							end
						end
						else begin
							mip1 <= 1'd0;
							if (uopqd > 3'd3) begin
								mip2 <= mip2 + uopqd - 3'd3;
								if (uop_prg[mip2].fl[1]) begin
									doMap();
								end
							end
						end
					end
				end
				else begin
					mip1 <= 1'd0;
					if (uopqd > 3'd2) begin
						mip2 <= mip2 + uopqd - 3'd2;
						if (!uop_prg[mip2].fl[1]) begin
							if (uopqd > 3'd3) begin
								mip2 <= mip2 + uopqd - 3'd3;
								if (uop_prg[mip2+1].fl[1]) begin
									doMap();
								end
							end
						end
						else begin
							doMap();
						end
					end
				end
			end
		end
		else begin
			mip1 <= 1'd0;
			if (uopqd > 3'd1) begin
				mip2 <= mip2 + uopqd - 3'd1;
				if (!uop_prg[mip2].fl[1]) begin
					if (uopqd > 3'd2) begin
						mip2 <= mip2 + uopqd - 3'd2;
						if (!uop_prg[mip2+1].fl[1]) begin
							if (uopqd > 3'd3) begin
								mip2 <= mip2 + uopqd - 3'd3;
								if (uop_prg[mip2+2].fl[1]) begin
									doMap();
								end
							end
						end
						else begin
							doMap();
						end
					end
				end
				else begin
					doMap();
				end
			end
		end
	end
	else begin
		if (|mip2) begin
			mip2 <= mip2 + uopqd;
			if (!uop_prg[mip2].fl[1]) begin
				if (uopqd > 3'd1) begin
					if (!uop_prg[mip2+1].fl[1]) begin
						if (uopqd > 3'd2) begin
							if (!uop_prg[mip2+2].fl[1]) begin
								if (uopqd > 3'd3) begin
									if (uop_prg[mip2+3].fl[1]) begin
										doMap();
									end
								end
							end
							else begin
								doMap();
							end
						end
					end
					else begin
						doMap();
					end
				end
			end
			else begin
				doMap();
			end
		end
	end
end
endtask

endmodule
