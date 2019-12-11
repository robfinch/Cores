// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
`include "nvio3-config.sv"
`include "nvio3-defines.sv"

module decodeBuffer(rst, clk, irq_i, im, cause_i, freezeip, int_commit,
	ic_fault, ic_out, codebuf, stop_string, lsm, ip,
	phit, next_bundle,
	insnxp, insnx, queued, queuedOnp
);
parameter QSLOTS = `QSLOTS;
parameter BBB = 8'h00;
input rst;
input clk;
input [3:0] irq_i;
input [3:0] im;
input [7:0] cause_i;
output freezeip;
input int_commit;
input next_bundle;
input phit;
input [1:0] ic_fault;
input [1023:0] ic_out;
input [47:0] codebuf [0:63];
input stop_string;
input [QSLOTS-1:0] lsm;
input [5:0] ip;
output reg [39:0] insnxp [0:QSLOTS-1];
output reg [39:0] insnx [0:QSLOTS-1];
input queued;
input [3:0] queuedOnp;

integer n;

function IsExec;
input [39:0] isn;
IsExec = (isn[`OPCODE]==`BMISC && isn[`FUNCT5]==`EXEC);
endfunction

function IsPfi;
input [39:0] isn;
IsPfi = (isn[`OPCODE]==`BRK && isn[`FUNCT5]==`PFI);
endfunction

reg [159:0] ic_outs;
always @*
 	ic_outs <= ic_out >> {ip[5:0],3'b0};

// freezePC squashes the pc increment if there's an irq.
// If a hardware interrupt instruction is encountered in the instruction stream
// flag it as a privilege violation.

assign freezeip = (irq_i > im) && !int_commit;
always @*
if (freezeip) begin
	insnxp[0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[1] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[2] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[3] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
end
else begin
	insnxp[0] <= ic_outs[39:0];
	insnxp[1] <= ic_outs[79:40];
	insnxp[2] <= ic_outs[119:80];
	insnxp[3] <= ic_outs[159:120];
	case(ic_fault)
	2'd1:	
		begin
			insnxp[0] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[3] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
		end
	2'd2:	
		begin
			insnxp[0] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[3] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
		end
	2'd3:
		begin
			insnxp[0] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[3] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
		end
	default:
		if (ic_out==128'h0) begin
			insnxp[0] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
		end
		else begin
			if (IsPfi(ic_outs[39:0]))	begin
				if (~|irq_i) begin
					insnxp[0] <= `NOP_INSN;
				end
				else begin
					// Need to reset the template here as an instruction is being converted to a NOP.
					insnxp[0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[1] <= `NOP_INSN;
					insnxp[2] <= `NOP_INSN;
					insnxp[3] <= `NOP_INSN;
				end
			end
			else if (IsExec(ic_outs[39:0])) begin
				insnxp[0] <= codebuf[ic_outs[17:13]][39:0];
			end

			if (IsPfi(ic_outs[79:40])) begin
				if (~|irq_i) begin
					insnxp[1] <= `NOP_INSN;
				end
				else begin
					// Need to reset the template here as an instruction is being converted to a NOP.
					insnxp[1] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[2] <= `NOP_INSN;
					insnxp[3] <= `NOP_INSN;
				end
			end
			else if (IsExec(ic_outs[79:40])) begin
				insnxp[1] <= codebuf[ic_outs[57:53]][39:0];
			end
	
			if (IsPfi(ic_outs[119:80])) begin
				if (~|irq_i) begin
					insnxp[2] <= `NOP_INSN;
				end
				else begin
					insnxp[2] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[3] <= `NOP_INSN;
				end
			end
			else if (IsExec(ic_outs[119:80])) begin
				insnxp[2] <= codebuf[ic_outs[97:93]][39:0];
			end

			if (IsPfi(ic_outs[159:120])) begin
				if (~|irq_i) begin
					insnxp[3] <= `NOP_INSN;
				end
				else begin
					insnxp[3] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
				end
			end
			else if (IsExec(ic_outs[159:120])) begin
				insnxp[2] <= codebuf[ic_outs[137:133]][39:0];
			end

		end
	endcase
end

always @(posedge clk)
if (rst) begin
	insnx[0] <= `NOP_INSN;
	insnx[1] <= `NOP_INSN;
	insnx[2] <= `NOP_INSN;
	insnx[3] <= `NOP_INSN;
end
else begin
	// Increment register spec fields (Rs2,Rd) once bundle has queued.
	// IF the instruction queues a subsequent time, then the updated 
	// register spec will apply.
	for (n = 0; n < 4; n = n + 1)
		if (queuedOnp[n]) begin
			insnx[n][`RD] <= insnx[n][`RD] + 5'd1;
			insnx[n][`RS2] <= insnx[n][`RS2] + 5'd1;
			if (stop_string) begin
				insnx[n] <= `NOP_INSN;
			end
			if (lsm[n]) begin
				if (insnx[n][27:23] != 5'd0)
					insnx[n][27:23] <= insnx[n][27:23] - 5'd1;
				else begin
					insnx[n] <= `NOP_INSN;
				end
			end
			else
				insnx[n][0] <= 1'b0;
		end
	if (phit & next_bundle) begin
		insnx[0] <= insnxp[0];
		insnx[1] <= insnxp[1];
		insnx[2] <= insnxp[2];
		insnx[3] <= insnxp[3];
	end
end

endmodule
