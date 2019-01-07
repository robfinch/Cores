// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_insn_length.v
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
module FT64v8d_insn_length(ir, o);
input [7:0] ir;
output reg [2:0] o;

always @*
case(ir)
// Prefixes
`I_BYTE:	o <= 3'd1;
`I_UBYTE:	o <= 3'd1;
`I_HALF:	o <= 3'd1;
`I_UHALF:	o <= 3'd1;
`I_WORD:	o <= 3'd1;
`I_UWORD: o <= 3'd1;

`I_ADD:		o <= 3'd3;
`I_ADD6:	o <= 3'd3;
`I_ADD14:	o <= 3'd4;
`I_ADD30:	o <= 3'd6;
`I_AND:		o <= 3'd3;
`I_AND6:	o <= 3'd3;
`I_AND14:	o <= 3'd4;
`I_AND30:	o <= 3'd6;

`I_BRK:		o <= 3'd2;
`I_CLI:		o <= 3'd1;
`I_CMP:		o <= 3'd3;
`I_CMP6:	o <= 3'd3;
`I_CMP14:	o <= 3'd4;
`I_CMP30:	o <= 3'd6;
`I_EOR:		o <= 3'd3;
`I_EOR6:	o <= 3'd3;
`I_EOR14:	o <= 3'd4;
`I_EOR30:	o <= 3'd6;
`I_JMF:		o <= 3'd6;
`I_JMP:		o <= 3'd4;
`I_JSF:		o <= 3'd6;
`I_JSR:		o <= 3'd4;
`I_NOP:		o <= 3'd1;
`I_OR:		o <= 3'd3;
`I_OR6:		o <= 3'd3;
`I_OR14:	o <= 3'd4;
`I_OR30:	o <= 3'd6;
`I_RTI:		o <= 3'd1;
`I_RTS:		o <= 3'd1;
`I_WAI:		o <= 3'd1;
default:	o <= 3'd1;
endcase

endmodule
