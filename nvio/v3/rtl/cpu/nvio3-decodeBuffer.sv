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
`include "nvio-config.sv"
`include "nvio-defines.sv"

module decodeBuffer(rst, clk, irq_i, im, cause_i, freezeip, int_commit,
	ic_fault, ic_out, codebuf,
	phit, next_bundle,
	ibundlep, templatep, insnxp,
	ibundle, template, insnx, queued, queuedOnp
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
input [127:0] ic_out;
input [47:0] codebuf [0:63];
output reg [127:0] ibundlep;
output reg [7:0] templatep [0:QSLOTS-1];
output reg [40:0] insnxp [0:QSLOTS-1];
output reg [127:0] ibundle;
output reg [7:0] template [0:QSLOTS-1];
output reg [40:0] insnx [0:QSLOTS-1];
input queued;
input [2:0] queuedOnp;

integer n;

function IsExec;
input [40:0] isn;
IsExec = (isn[`OPCODE]==`BMISC && isn[`FUNCT5]==`EXEC);
endfunction

function IsPfi;
input [40:0] isn;
IsPfi = (isn[`OPCODE]==`BRK && isn[`FUNCT5]==`PFI);
endfunction

// freezePC squashes the pc increment if there's an irq.
// If a hardware interrupt instruction is encountered in the instruction stream
// flag it as a privilege violation.

assign freezeip = (irq_i > im) && !int_commit;
always @*
if (freezeip) begin
	ibundlep <= {3'b0,{3{1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0}}};
	insnxp[0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[1] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[2] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
end
else begin
	ibundlep <= ic_out;
	insnxp[0] <= ic_out[40:0];
	insnxp[1] <= ic_out[81:41];
	insnxp[2] <= ic_out[122:82];
	case(ic_fault)
	2'd1:	
		begin
			ibundlep <= {3'b0,{3{1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0}}};
			insnxp[0] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
		end
	2'd2:	
		begin
			ibundlep <= {3'b0,{3{1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0}}};
			insnxp[0] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
		end
	2'd3:
		begin
			ibundlep <= {3'b0,{3{1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0}}};
			insnxp[0] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
		end
	default:
		if (ic_out==128'h0) begin
			ibundlep <= {3'b0,{3{1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0}}};
			insnxp[0] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
		end
		else begin
			if (IsPfi(ic_out[40:0]))	begin
				if (~|irq_i) begin
					ibundlep[40:0] <= `NOP_INSN;
					insnxp[0] <= `NOP_INSN;
				end
				else begin
					// Need to reset the template here as an instruction is being converted to a NOP.
					ibundlep <= {3'b0,`NOP_INSN,`NOP_INSN,1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[1] <= `NOP_INSN;
					insnxp[2] <= `NOP_INSN;
				end
			end
			else if (IsExec(ic_out[40:0])) begin
				insnxp[0] <= codebuf[ic_out[`RS1]][40:0];
			end
			if (IsPfi(ic_out[81:41])) begin
				if (~|irq_i) begin
					ibundlep[81:41] <= `NOP_INSN;
					insnxp[1] <= `NOP_INSN;
				end
				else begin
					// Need to reset the template here as an instruction is being converted to a NOP.
					ibundlep[127:41] <= {3'b0,`NOP_INSN,1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[1] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[2] <= `NOP_INSN;
				end
			end
			else if (IsExec(ic_out[81:41])) begin
				insnxp[1] <= codebuf[ic_out[`RS1]][40:0];
			end
			if (IsPfi(ic_out[122:82])) begin
				if (~|irq_i) begin
					ibundlep[122:82] <= `NOP_INSN;
					insnxp[2] <= `NOP_INSN;
				end
				else begin
					ibundlep[122:82] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[2] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
				end
			end
			else if (IsExec(ic_out[122:82])) begin
				insnxp[2] <= codebuf[ic_out[`RS1]][40:0];
			end
		end
	endcase
end

always @(posedge clk)
if (rst) begin
	ibundle <= {3'b0,{3{`NOP_INSN}}};
	insnx[0] <= `NOP_INSN;
	insnx[1] <= `NOP_INSN;
	insnx[2] <= `NOP_INSN;
end
else begin
	if (queuedOnp[0])
		ibundle[123] <= 1'b0;
	if (queuedOnp[1])
		ibundle[124] <= 1'b0;
	if (queuedOnp[2])
		ibundle[125] <= 1'b0;
	if (phit & next_bundle) begin
		ibundle <= ibundlep;
		insnx[0] <= insnxp[0];
		insnx[1] <= insnxp[1];
		insnx[2] <= insnxp[2];
	end
end
// On a cache miss load NOPs
/*else begin
	ibundle <= {BBB,`NOP_INSN,`NOP_INSN,`NOP_INSN};
	insnx[0] <= `NOP_INSN;
	insnx[1] <= `NOP_INSN;
	insnx[2] <= `NOP_INSN;
	template[0] <= BBB;
	template[1] <= BBB;
	template[2] <= BBB;
end
*/
//else begin
//	ibundle <= {BBB,{3{`NOP_INSN}}};
//	insnx[0] <= `NOP_INSN;
//	insnx[1] <= `NOP_INSN;
//	insnx[2] <= `NOP_INSN;
//	template[0] <= BBB;	// Branch,Branch,Branch
//	template[1] <= BBB;
//	template[2] <= BBB;
//end


endmodule
