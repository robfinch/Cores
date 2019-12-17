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

`include "rtf65004-defines.sv"

module rtf65004_alu(op, a, imm, b, o, s_i, s_o, idle);
parameter WID=64;
input [5:0] op;
input [WID-1:0] a;
input [WID-1:0] imm;
input [WID-1:0] b;
output reg [WID-1:0] o;
input [15:0] s_i;
output reg [15:0] s_o;
output idle;

assign idle = 1'b1;

always @*
case(op)
`UO_LDIB:	o = {{56{imm[7]}},imm[7:0]};
`UO_ADDW:	o = a + imm + b;
`UO_ADDB:	o = a[7:0] + imm[7:0] + b[7:0];
`UO_ADCB:	o = a[7:0] + imm[7:0] + b[7:0] + s_i[0];
`UO_SBCB:	o = a[7:0] - imm[7:0] - b[7:0] - ~s_i[0];
`UO_CMPB:	o = a[7:0] - imm[7:0] - b[7:0] - ~s_i[0];
`UO_ANDB:	o = a[7:0] & imm[7:0] & b[7:0];
`UO_ANDC:	o = a[7:0] & imm[7:0] & ~b[7:0];
`UO_BITB:	o = a[7:0] & imm[7:0] & b[7:0];
`UO_ORB:		o = a[7:0] | imm[7:0] | b[7:0];
`UO_EORB:	o = a[7:0] ^ imm[7:0] ^ b[7:0];
`UO_MOV:		o = b;
`UO_ASLB:	o = {a[7:0],1'b0};
`UO_LSRB:	o = {a[0],1'b0,a[7:1]};
`UO_ROLB:	o = {a[7:0],s_i[0]};
`UO_RORB:	o = {7'h00,a[7],s_i[0],a[7:1]};
`UO_ADD:	o = a + imm + b;
`UO_SUB:	o = a - imm - b;
`UO_CMP:	o = a - imm - b;
`UO_AND:	o = a & imm & b;
`UO_OR:		o = a | imm | b;
`UO_EOR:	o = a ^ imm ^ b;
`UO_ASL:	o = a << (imm[5:0] + b[5:0]);
`UO_LSR:	o = a >> (imm[5:0] + b[5:0]);
default:	o = {4{16'hDEAE}};
endcase

always @*
begin
s_o = s_i;
case(op)
`UO_LDIB,`UO_ADDB,
`UO_ANDB,`UO_BITB,`UO_ORB,`UO_EORB:
	begin
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`UO_ANDC:
	begin
		s_o[1] = o[7:0]==8'h00;
	end
`UO_ADCB:
	begin
		s_o[0] = o[8];
		s_o[1] = o[7:0]==8'h00;
		s_o[6] = (o[7] ^ imm[7] ^ b[7]) & (1'b1 ^ a[7] ^ imm[7] ^ b[7]);
		s_o[7] = o[7];
	end
`UO_SBCB:
	begin
		s_o[0] = ~o[8];
		s_o[1] = o[7:0]==8'h00;
		s_o[6] = (1'b1 ^ o[7] ^ imm[7] ^ b[7]) & (a[7] ^ imm[7] ^ b[7]);
		s_o[7] = o[7];
	end
`UO_CMPB:
	begin
		s_o[0] = o[8];
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`UO_ASLB,`UO_LSRB,`UO_ROLB,`UO_RORB:
	begin
		s_o[0] = o[8];
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`UO_MOV:
	begin
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`UO_AND,`UO_OR,`UO_EOR:
	begin
		s_o[1] = o==64'h00;
		s_o[7] = o[63];
	end
`UO_CLC:	s_o[0] = 1'b0;
`UO_SEC:	s_o[0] = 1'b1;
`UO_CLV:	s_o[6] = 1'b0;
`UO_SEI:	s_o[2] = 1'b1;
`UO_CLI:	s_o[2] = 1'b0;
`UO_SED:	s_o[3] = 1'b1;
`UO_CLD:	s_o[3] = 1'b0;
`UO_SEB:	s_o[4] = 1'b1;
`UO_CLB:	s_o[4] = 1'b0;
`UO_XCE:	s_o = {s_i[7:0],s_i[15:8]};
default:
	s_o = 8'h00;
endcase
end

endmodule
