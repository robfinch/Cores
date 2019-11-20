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

`define HIGHWORD    63:32

module shift32(instr, a, b, res, ov);
parameter WID=32;
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

wire [63:0] shl = {32'd0,a} << b[4:0];
wire [63:0] shr = {a,{WID{1'b0}}} >> b[4:0];

assign ov = shl[63:32] != {WID{a[DMSB]}};

always @*
casez(instr[`OPCODE])
`R2,`R2S:
  case(instr[`FUNCT6])
  `SHL,`ASL,`SHLI,`ASLI:	res <= shl[DMSB:0];
  `SHR,`SHRI:	res <= shr[`HIGHWORD];
  `ASR,`ASRI:	if (a[DMSB])
              res <= (shr[`HIGHWORD]) | ~({32{1'b1}} >> b[4:0]);
          else
              res <= shr[`HIGHWORD];
  `ROL,`ROLI:	res <= ROTATE_INSN ? shl[31:0]|shl[`HIGHWORD] : 32'hDEADDEAD;
  `ROR,`RORI:	res <= ROTATE_INSN ? shr[31:0]|shr[`HIGHWORD] : 32'hDEADDEAD;
  default:    res <= 32'd0;
  endcase
default:	res <= 32'd0;
endcase

endmodule

