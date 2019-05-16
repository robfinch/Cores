// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_InsLength.v
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
// Computes the length of an instruction.
// There are also other places in code where the length is determined
// without the use of this module.
// ============================================================================
//
`include "FT64_config.vh"
`include "FT64_defines.vh"

module FT64_InsLength(ins, len, pred_on);
input [47:0] ins;
output reg [2:0] len;
input pred_on;

always @*
`ifdef SUPPORT_DCI
if (ins[`INSTRUCTION_OP]==`CMPRSSD)
	len <= 3'd2 | pred_on;
else
`endif
	case(ins[7:6])
	2'd0:	len <= 3'd4 | pred_on;
	2'd1:	len <= 3'd6 | pred_on;
	default:	len <= 3'd2 | pred_on;
	endcase

endmodule
