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

`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"

module alu(op, a, imm, b, o, csr_i, idle);
parameter WID=52;
input Instruction op;
input Data a;
input Data imm;
input Data b;
output Data o;
input Data csr_i;
output idle;

assign idle = 1'b1;
reg [WID:0] os;

function [51:0] shl;
input [51:0] a;
input [51:0] b;
shl = a << b[5:0];
endfunction

function [51:0] shr;
input [51:0] a;
input [51:0] b;
shr = a >> b[5:0];
endfunction

always @*
case(op.rr.opcode)
`MUL_3R:	o = op.rr.zero ? $signed(a) * $signed(imm) : $signed(a) * $signed(b);
`ADD_3R:	o = op.rr.zero ? a + imm : a + b;
`SUB_3R:	o = op.rr.zero ? a - imm : a - b;
`AND_3R:	o = op.rr.zero ? a & imm : a & b;
`OR_3R:		o = op.rr.zero ? a | imm : a | b;
`EOR_3R:	o = op.rr.zero ? a ^ imm : a ^ b;
`CMP_3R:	o = op.rr.zero ? ($signed(a) < $signed(imm) ? 2'b11 : a == imm ? 2'b00 : 2'b01)
								: ($signed(a) < $signed(b) ? 2'b11 : a == b ? 2'b00 : 2'b01);
`CMPU_3R:	o = op.rr.zero ? (a < imm ? 2'b11 : a == imm ? 2'b00 : 2'b01)
		: (a < b ? 2'b11 : a == b ? 2'b00 : 2'b01);
`MUL_RI22,`MUL_RI35:	o = $signed(a) * $signed(imm);
`ADD_RI22,`ADD_RI35:	o = a + imm;
`SUB_RI22,`SUB_RI35:	o = a + imm;
`CMP_RI22,`CMP_RI35: o = $signed(a) < $signed(imm) ? 2'b11 : a == imm ? 2'b00 : 2'b01;
`CMPU_RI22,`CMPU_RI35: o = a < imm ? 2'b11 : a == imm ? 2'b00 : 2'b01;
`AND_RI22,`AND_RI35:	o = a & imm;
`OR_RI22,`OR_RI35:	o = a | imm;
`EOR_RI22,`EOR_RI35:	o = a ^ imm;
`ASL_3R:	o = op.rr.zero ? shl(a,imm[5:0]) : shl(a,b);
`ASR_3R:	o = op.rr.zero ? (a[51] ? ~(52'hFFFFFFFFFFFFF >> imm[5:0]) | shr(a,imm[5:0]) : shr(a,imm[5:0]))
							: (a[51] ? ~(52'hFFFFFFFFFFFFF >> b[5:0]) | shr(a,b) : shr(a,b));
`LSR_3R:	o = op.rr.zero ? shr(a,imm[5:0]) : shr(a,b);
`ROL_3R:	o = op.rr.zero ? shl(a,imm[5:0]) | shr(a,52-imm[5:0]) : shl(a,b) | shr(a,52-b);
`ROR_3R:	o = op.rr.zero ? shr(a,imm[5:0]) | shl(a,52-imm[5:0]) : shr(a,b) | shl(a,52-b);
`CSR:			o = csr_i;
default:	o = {3{16'hDEAE}};
endcase

endmodule
