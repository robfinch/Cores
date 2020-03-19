// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-defines.sv"

module instLength(opcode,len);
input [6:0] opcode;
output reg [2:0] len;

always @*
case(opcode)
`ADD_3R:	len <= 3'd2;
`ADD_RI22:	len <= 3'd3;
`ADD_RI35:	len <= 3'd4;
`JAL:			len <= 3'd4;
`ASL_3R:	len <= 3'd2;
`SUB_3R:	len <= 3'd2;
`SUB_RI22:	len <= 3'd3;
`SUB_RI35:	len <= 3'd4;
`CMP_3R:	len <= 3'd2;
`CMP_RI22:	len <= 3'd3;
`CMP_RI35:	len <= 3'd4;
`CMPU_3R:	len <= 3'd2;
`CMPU_RI22:	len <= 3'd3;
`CMPU_RI35:	len <= 3'd4;
`MUL_3R:	len <= 3'd2;
`MUL_RI22:	len <= 3'd3;
`MUL_RI35:	len <= 3'd4;
`JAL:			len <= 3'd4;
`LSR_3R:	len <= 3'd2;
`RETGRP:	len <= 3'd1;
`ROL_3R:	len <= 3'd2;
`AND_3R:	len <= 3'd2;
`AND_RI22: len <= 3'd3;
`AND_RI35: len <= 3'd4;
`BRKGRP:	len <= 3'd1;
`ROR_3R:	len <= 3'd2;
`OR_3R:		len <= 3'd2;
`OR_RI22:	len <= 3'd3;
`OR_RI35:	len <= 3'd4;
`EOR_3R:	len <= 3'd2;
`EOR_RI22:	len <= 3'd3;
`EOR_RI35: len <= 3'd4;
`JAL_RN:	len <= 3'd1;
`LD_D8:		len <= 3'd2;
`LD_D22:	len <= 3'd3;
`LD_D35:	len <= 3'd4;
`LDF_D8:	len <= 3'd2;
`LDF_D22:	len <= 3'd3;
`LDF_D35:	len <= 3'd4;
`LDB_D8:	len <= 3'd2;
`LDB_D22:	len <= 3'd3;
`LDB_D35:	len <= 3'd4;
`LDR_D8:	len <= 3'd2;
`ST_D8:		len <= 3'd2;
`ST_D22:	len <= 3'd3;
`ST_D35:	len <= 3'd4;
`STF_D8:	len <= 3'd2;
`STF_D22:	len <= 3'd3;
`STF_D35:	len <= 3'd4;
`STB_D8:	len <= 3'd2;
`STB_D22:	len <= 3'd3;
`STB_D35:	len <= 3'd4;
`STC_D8:	len <= 3'd2;
`BRANCH0:	len <= 3'd2;
`BRANCH1:	len <= 3'd2;
`ISOP:		len <= 3'd4;
`STPGRP:	len <= 3'd1;
`LDI:			len <= 3'd5;
default:	len <= 3'd1;	// unimplemented instruction
endcase
endmodule
