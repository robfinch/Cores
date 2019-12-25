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
module instLength(opcode,len);
input [5:0] opcode;
output reg [2:0] len;

always @*
case(opcode)
`ADD_3R:	len <= 3'd2;
`ADD_I23:	len <= 3'd3;
`ADD_I36:	len <= 3'd4;
`JMP:			len <= 3'd4;
`ASL_3R:	len <= 3'd2;
`SUB_3R:	len <= 3'd2;
`SUB_I23:	len <= 3'd3;
`SUB_I36:	len <= 3'd4;
`JSR:			len <= 3'd4;
`LSR_3R:	len <= 3'd2;
`RETGRP:	len <= 3'd1;
`ROL_3R:	len <= 3'd2;
`AND_3R:	len <= 3'd2;
`AND_I23: len <= 3'd3;
`AND_I36: len <= 3'd4;
`BRKGRP:	len <= 3'd1;
`ROR_3R:	len <= 3'd2;
`OR_3R:		len <= 3'd2;
`OR_I23:	len <= 3'd3;
`OR_I36:	len <= 3'd4;
`JMP_RN:	len <= 3'd1;
`SEP:			len <= 3'd1;
`EOR_3R:	len <= 3'd2;
`EOR_I23:	len <= 3'd3;
`EOR_I36: len <= 3'd4;
`JSR_RN:	len <= 3'd1;
`REP:			len <= 3'd1;
`LD_D9:		len <= 3'd2;
`LD_D23:	len <= 3'd3;
`LD_D36:	len <= 3'd4;
`LDB_D36:	len <= 3'd4;
`PLP:			len <= 3'd1;
`POP:			len <= 3'd1;
`ST_D9:		len <= 3'd2;
`ST_D23:	len <= 3'd3;
`ST_D36:	len <= 3'd4;
`STB_D36:	len <= 3'd4;
`PHP:			len <= 3'd1;
`PSH:			len <= 3'd1;
`BccD4a:	len <= 3'd1;
`BccD4b:	len <= 3'd1;
`BccD17a:	len <= 3'd2;
`BccD17b:	len <= 3'd2;
default:	len <= 3'd1;	// unimplemented instruction
endcase
endmodule
