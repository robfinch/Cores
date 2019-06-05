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
`include "rtfItanium-config.sv"
`include "rtfItanium-defines.sv"

module decode_buffer(rst, clk, irq_i, im, cause_i, freezeip, int_commit,
	ic_fault, ic_out, codebuf,
	phit, next_bundle,
	ibundlep, templatep, insnxp,
	ibundle, template, insnx
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
output reg [39:0] insnxp [0:QSLOTS-1];
output reg [127:0] ibundle;
output reg [7:0] template [0:QSLOTS-1];
output reg [39:0] insnx [0:QSLOTS-1];

function [7:0] mxtbl;
input [2:0] units;
case(units)
`BUnit:	mxtbl = 8'h00;	// branch,branch,branch
`IUnit:	mxtbl = 8'h01;	// int, branch, branch
`FUnit:	mxtbl = 8'h02;
`MUnit:	mxtbl = 8'h03;
default:	mxtbl = 8'hFF;
endcase
endfunction

function [2:0] Unit0;
input [6:0] tmp;
reg [8:0] units;
units = fnUnits(tmp);
Unit0 = units[8:6];
endfunction

function IsExec;
input [2:0] unit;
input [39:0] isn;
IsExec = unit==`BUnit && (isn[`OPCODE4]==`RTI && isn[`FUNCT5]==`EXEC);
endfunction

function IsPfi;
input [2:0] unit;
input [39:0] isn;
IsPfi = unit==`BUnit && (isn[`OPCODE4]==`BRK && isn[`FUNCT5]==`PFI);
endfunction

// freezePC squashes the pc increment if there's an irq.
// If a hardware interrupt instruction is encountered in the instruction stream
// flag it as a privilege violation.

assign freezeip = (irq_i > im) && !int_commit;
always @*
if (freezeip) begin
	ibundlep <= {BBB,{3{1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0}}};
	templatep[0] <= BBB;	// Branch,Branch,Branch
	templatep[1] <= BBB;
	templatep[2] <= BBB;
	insnxp[0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[1] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
	insnxp[2] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
end
else begin
	ibundlep <= ic_out;
	insnxp[0] <= ic_out[39:0];
	insnxp[1] <= ic_out[79:40];
	insnxp[2] <= ic_out[119:80];
	templatep[0] <= ic_out[126:120];
	templatep[1] <= ic_out[126:120];
	templatep[2] <= ic_out[126:120];
	case(ic_fault)
	2'd1:	
		begin
			ibundlep <= {BBB,{3{1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0}}};
			templatep[0] <= BBB;	// Branch,Branch,Branch
			templatep[1] <= BBB;
			templatep[2] <= BBB;
			insnxp[0] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0};
		end
	2'd2:	
		begin
			ibundlep <= {BBB,{3{1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0}}};
			templatep[0] <= BBB;	// Branch,Branch,Branch
			templatep[1] <= BBB;
			templatep[2] <= BBB;
			insnxp[0] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0};
		end
	2'd3:
		begin
			ibundlep <= {BBB,{3{1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0}}};
			templatep[0] <= BBB;	// Branch,Branch,Branch
			templatep[1] <= BBB;
			templatep[2] <= BBB;
			insnxp[0] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
		end
	default:
		if (ic_out==128'h0) begin
			ibundlep <= {BBB,{3{1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0}}};
			insnxp[0] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[1] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			insnxp[2] <= {1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0};
			templatep[0] <= BBB;	// Branch,Branch,Branch
			templatep[1] <= BBB;
			templatep[2] <= BBB;
		end
		else begin
			if (IsPfi(Unit0(ic_out[127:120]),ic_out[39:0]))	begin
				if (~|irq_i) begin
					ibundlep[39:0] <= `NOP_INSN;
					insnxp[0] <= `NOP_INSN;
				end
				else begin
					// Need to reset the template here as an instruction is being converted to a NOP.
					ibundlep <= {BBB,`NOP_INSN,`NOP_INSN,1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[1] <= `NOP_INSN;
					insnxp[2] <= `NOP_INSN;
					templatep[0] <= BBB;	// Branch,Branch,Branch
					templatep[1] <= BBB;
					templatep[2] <= BBB;
				end
			end
			else if (IsExec(Unit0(ic_out[127:120]),ic_out[39:0])) begin
				templatep[0] <= codebuf[ic_out[`RS1]][46:40];
				insnxp[0] <= codebuf[ic_out[`RS1]][39:0];
			end
			if (IsPfi(Unit1(ic_out[127:120]),ic_out[79:40])) begin
				if (~|irq_i) begin
					ibundlep[79:40] <= `NOP_INSN;
					insnxp[1] <= `NOP_INSN;
				end
				else begin
					// Need to reset the template here as an instruction is being converted to a NOP.
					ibundlep[127:40] <= {mxtbl(Unit0(ic_out[127:120])),`NOP_INSN,1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[1] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[2] <= `NOP_INSN;
					templatep[0] <= mxtbl(Unit0(ic_out[127:120]));
					templatep[1] <= mxtbl(Unit0(ic_out[127:120]));
					templatep[2] <= mxtbl(Unit0(ic_out[127:120]));
				end
			end
			else if (IsExec(Unit0(ic_out[127:120]),ic_out[79:40])) begin
				templatep[1] <= codebuf[ic_out[`RS1]][46:40];
				insnxp[1] <= codebuf[ic_out[`RS1]][39:0];
			end
			if (IsPfi(Unit2(ic_out[127:120]),ic_out[119:80])) begin
				if (~|irq_i) begin
					ibundlep[119:80] <= `NOP_INSN;
					insnxp[2] <= `NOP_INSN;
				end
				else begin
					ibundlep[119:80] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
					insnxp[2] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
				end
			end
			else if (IsExec(Unit0(ic_out[127:120]),ic_out[119:80])) begin
				templatep[2] <= codebuf[ic_out[`RS1]][46:40];
				insnxp[2] <= codebuf[ic_out[`RS1]][39:0];
			end
		end
	endcase
end

always @(posedge clk)
if (rst) begin
	ibundle <= {BBB,{3{`NOP_INSN}}};
	insnx[0] <= `NOP_INSN;
	insnx[1] <= `NOP_INSN;
	insnx[2] <= `NOP_INSN;
	template[0] <= BBB;
	template[1] <= BBB;
	template[2] <= BBB;
end
else if (phit & next_bundle) begin
	ibundle <= ibundlep;
	insnx[0] <= insnxp[0];
	insnx[1] <= insnxp[1];
	insnx[2] <= insnxp[2];
	template[0] <= templatep[0];
	template[1] <= templatep[1];
	template[2] <= templatep[2];
end
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
