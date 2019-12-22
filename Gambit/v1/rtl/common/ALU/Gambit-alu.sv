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

`include "..\Gambit-defines.sv"

module alu(op, a, imm, b, o, s_i, s_o, idle);
parameter WID=52;
input [5:0] op;
input [WID-1:0] a;
input [WID-1:0] imm;
input [WID-1:0] b;
output reg [WID-1:0] o;
input [15:0] s_i;
output reg [15:0] s_o;
output idle;

assign idle = 1'b1;
reg [WID:0] os;

always @*
case(op)
`UO_ADD:	o = a + imm + b;
`UO_ADDu:
	begin
		os = a + imm + b;
		o = os[WID-1:0];
	end
`UO_SUB:	o = a - imm - b;
`UO_SUBu:
	begin
		os = a - imm - b;
		o = os[WID-1:0];
	end
`UO_ANDu:	o = a & imm & b;
`UO_ORu:	o = a | imm | b;
`UO_EORu:	o = a ^ imm ^ b;
`UO_ASLu:	o = a << b[5:0];
`UO_LSRu:	o = a >> b[5:0];
`UO_ROLu:	o = a << b[5:0];
`UO_RORu:	o = a >> b[5:0];
default:	o = {4{16'hDEAE}};
endcase

always @*
begin
s_o = s_i;
case(op)
`UO_ADDu:
	begin
		s_o[0] = o[51:0]==52'h00;
		s_o[3] = os[WID];
		s_o[6] = o[51];
	end
`UO_ANDu,`UO_ORu,`UO_EORu:
	begin
		s_o[0] = o[51:0]==52'h00;
		s_o[6] = o[51];
	end
`UO_SUBu:
	begin
		s_o[0] = o[51:0]==52'h00;
		s_o[3] = os[WID];
		s_o[6] = o[51];
	end
`UO_ASLu,`UO_LSRu,`UO_ROLu,`UO_RORu:
	begin
		s_o[3] = o[8];
		s_o[0] = o[51:0]==52'h00;
		s_o[6] = o[51];
	end
`UO_REP:	s_o[6:0] = s_i[6:0] & ~imm[6:0];
`UO_SEP:	s_o[6:0] = s_i[6:0] | imm[6:0];
default:
	s_o = 8'h00;
endcase
end

endmodule
