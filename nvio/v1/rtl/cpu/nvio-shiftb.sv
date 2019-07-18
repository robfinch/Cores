// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_shiftb.v
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
//
// ============================================================================
//
`include "nvio-config.sv"
`include "nvio-defines.sv"
`define HIGHWORDB    15:8

module shiftb(instr, a, b, res, ov);
parameter DMSB=7;
input [39:0] instr;
input [DMSB:0] a;
input [DMSB:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output ov;
parameter ROTATE_INSN = 1;

wire [5:0] opcode = {instr[34:33],instr[`OPCODE4]};
wire [5:0] func = {instr[`FUNCT5],instr[6]};
wire [2:0] bb = b;

wire [15:0] shl = {8'd0,a} << bb[2:0];
wire [15:0] shr = {a,8'd0} >> bb[2:0];

assign ov = 1'b0;

always @*
casez(opcode)
`R3:
	case(func)
	`SHL,`ASL,`SHLI,`ASLI:	res <= shl[DMSB:0];
	`SHR,`SHRI:	res <= shr[`HIGHWORDB];
	`ASR,`ASRI:
		if (a[DMSB])
      res <= (shr[`HIGHWORDB]) | ~({8{1'b1}} >> bb[2:0]);
    else
      res <= shr[`HIGHWORDB];
	`ROL,`ROLI:	res <= ROTATE_INSN ? shl[DMSB:0]|shl[`HIGHWORDB] : 8'hDE;
	`ROR,`RORI:	res <= ROTATE_INSN ? shr[DMSB:0]|shr[`HIGHWORDB] : 8'hDE;
	default: res <= 8'd0;
	endcase
default: res <= 8'd0;
endcase

endmodule

