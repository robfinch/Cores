// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	shift.v
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
`include "nvio3-config.sv"
`include "nvio3-defines.sv"

`define HIGHWORD    15:7

module shift8(instr, a, b, res, ov);
parameter WID=8;
parameter SUP_VECTOR = 1;
localparam DMSB=WID-1;
input [39:0] instr;
input [DMSB:0] a;
input [6:0] b;
output [DMSB:0] res;
reg [DMSB:0] res;
output ov;
parameter ROTATE_INSN = 1;

wire [5:0] opcode = {instr[`FUNCT6]};

wire [15:0] shl = {8'd0,a} << b[2:0];
wire [15:0] shr = {a,{WID{1'b0}}} >> b[2:0];

assign ov = shl[15:8] != {WID{a[DMSB]}};

always @*
casez(instr[`OPCODE])
`R2,`R2S:
  case(instr[`FUNCT6])
  `SHL,`ASL,`SHLI,`ASLI:	res <= shl[DMSB:0];
  `SHR,`SHRI:	res <= shr[`HIGHWORD];
  `ASR,`ASRI:	if (a[DMSB])
              res <= (shr[`HIGHWORD]) | ~({8{1'b1}} >> b[2:0]);
          else
              res <= shr[`HIGHWORD];
  `ROL,`ROLI:	res <= ROTATE_INSN ? shl[7:0]|shl[`HIGHWORD] : 8'hDE;
  `ROR,`RORI:	res <= ROTATE_INSN ? shr[7:0]|shr[`HIGHWORD] : 8'hDE;
  default:    res <= 8'd0;
  endcase
default:	res <= 8'd0;
endcase

endmodule

