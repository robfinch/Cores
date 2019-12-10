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

module rtf65004_alu(op, dst, src1, src2, o, s_i, s_o, idle);
input [5:0] op;
input [23:0] dst;
input [23:0] src1;
input [23:0] src2;
output reg [23:0] o;
input [7:0] s_i;
output reg [7:0] s_o;
output idle;

assign idle = 1'b1;

always @*
case(op)
`UO_LDIB:	o = {{8{src1[7]}},src1[7:0]};
`UO_ADDW:	o = dst + src1 + src2;
`UO_ADDB:	o = dst[7:0] + src1[7:0] + src2[7:0];
`UO_ADCB:	o = dst[7:0] + src1[7:0] + src2[7:0] + s_i[0];
`UO_SBCB:	o = dst[7:0] - src1[7:0] - src2[7:0] - ~s_i[0];
`UO_CMPB:	o = dst[7:0] - src1[7:0] - src2[7:0] - ~s_i[0];
`UO_ANDB:	o = dst[7:0] & src1[7:0] & src2[7:0];
`UO_ANDC:	o = dst[7:0] & src1[7:0] & ~src2[7:0];
`UO_BITB:	o = dst[7:0] & src1[7:0] & src2[7:0];
`UO_ORB:		o = dst[7:0] | src1[7:0] | src2[7:0];
`UO_EORB:	o = dst[7:0] ^ src1[7:0] ^ src2[7:0];
`UO_MOV:		o = src2[7:0];
`UO_ASLB:	o = {dst[7:0],1'b0};
`UO_LSRB:	o = {dst[0],1'b0,dst[7:1]};
`UO_ROLB:	o = {dst[7:0],s_i[0]};
`UO_RORB:	o = {7'h00,dst[7],s_i[0],dst[7:1]};
default:	o = 16'hDEAE;
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
		s_o[6] = (o[7] ^ src1[7] ^ src2[7]) & (1'b1 ^ dst[7] ^ src1[7] ^ src2[7]);
		s_o[7] = o[7];
	end
`UO_SBCB:
	begin
		s_o[0] = ~o[8];
		s_o[1] = o[7:0]==8'h00;
		s_o[6] = (1'b1 ^ o[7] ^ src1[7] ^ src2[7]) & (dst[7] ^ src1[7] ^ src2[7]);
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
`UO_CLC:	s_o[0] = 1'b0;
`UO_SEC:	s_o[0] = 1'b1;
`UO_CLV:	s_o[6] = 1'b0;
`UO_SEI:	s_o[2] = 1'b1;
`UO_CLI:	s_o[2] = 1'b0;
`UO_SED:	s_o[3] = 1'b1;
`UO_CLD:	s_o[3] = 1'b0;
`UO_SEB:	s_o[4] = 1'b1;
`UO_CLB:	s_o[4] = 1'b0;
default:
	s_o = 8'h00;
endcase
end

endmodule
