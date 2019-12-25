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

integer n;
reg branchmiss2;
reg [`AMSB:0] pcr [0:1];
reg [`AMSB:0] pcrx [0:1];
reg [2:0] mipst;
reg [51:0] insnxy [0:1];
reg [1:0] tb;
reg [2:0] uopqd1;
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

// Ready to fetch once both macro-instructions have queued, or we've run out of micro-ops.
wire ready_to_fetch = qcnt==3'd2 || (mip2==1'd0 && qcnt==3'd1) || (mip1==1'd0 && mip2==1'd0);

assign nextBundle = rst || ((mipst==MIP_RUN && !stall_uoq) && (ready_to_fetch) && (phit));// || nxtb;

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
	branchmiss1 <= branchmiss;
	branchmiss2 <= branchmiss1;

	case(mipst)
	MIP_RUN:
		begin
			if (!stall_uoq) begin
				// stage 2
				// select micro-instructions to queue
				// increment mmicro-program counters
				propagatePipeline();
				advancePtrs();

				// Stage 1
				// map opcodes
				// Fetch new pointers or advance current ones.
				if (ready_to_fetch) begin
					if (phit) begin
						mip1 <= uop_map[{opcode1[5:0],opcode1[8:6]}];
						mip2 <= uop_map[{opcode2[5:0],opcode2[8:6]}];
						pcr[0] <= pc;						// and associated program counter
						pcr[1] <= pc + len1;
						insnxy[0] <= insnx[0];	// capture instruction
						insnxy[1] <= insnx[1];
					end
					else begin
						mip1 <= 1'd0;
						mip2 <= 1'd0;
						pcr[0] <= 1'd0;
						pcr[1] <= 1'd0;
						insnxy[0] <= 1'd0;
						insnxy[1] <= 1'd0;
					end
				end
			end
		end
	
	endcase

	if (branchmiss) begin
		mip1 <= uop_map[{opcode1[5:0],opcode1[8:6]}];
		mip2 <= uop_map[{opcode2[5:0],opcode2[8:6]}];
		pcr[0] <= pc;						// and associated program counter
		pcr[1] <= pc + len1;
		insnxy[0] <= insnx[0];	// capture instruction
		insnxy[1] <= insnx[1];
	end

end

task propagatePipeline;
begin
	insnxy[0] <= insnx[0];
	insnxy[1] <= insnx[1];
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

// Advance the micro-program pointers.

task advancePtrs;
begin
	if (|mip1) begin
		mip1 <= mip1 + uopqd;
		for (n = `MAX_UOPQ - 1; n >= 0; n = n - 1) begin
			if (uop_prg[ptr[n]].fl[1] && uopqd > n + 1) begin
				// Mip1 has gone to zero, there are only uops to queue for mip2.
				if (whinst[n]==1'b0) begin
					if (mip2) begin
						mip1 <= mip2 + uopqd - n - 1;
						mip2 <= 1'd0;
						insnxy[0] <= insnxy[1];
						insnxy[1] <= 52'd0;
						pcr[0] <= pcr[1];
						pcr[1] <= 1'd0;
					end
					else begin
						mip1 <= 1'd0;
						insnxy[0] <= 52'd0;
						insnxy[1] <= 52'd0;
						pcr[0] <= 1'd0;
						pcr[1] <= 1'd0;
					end
				end
			end
		end
	end
end
endtask

endmodule
