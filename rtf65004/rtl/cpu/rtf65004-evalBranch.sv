// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// EvalBranch.v
// - branch evaluation
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
`include "rtf65004-defines.sv"

module EvalBranch(instr, sr, takb);
parameter WID=128;
input [15:0] instr;
input [7:0] sr;
output reg takb;

wire [5:0] opcode = instr[15:10];

//Evaluate branch condition
always @*
case(opcode)
`UO_BEQ:		takb <=  cr[1];
`UO_BCS:		takb <=  cr[0];
`UO_BVS:		takb <=  cr[6];
`UO_BNE:		takb <= !cr[1];
`UO_BCC:		takb <= !cr[0];
`UO_BVC:		takb <= !cr[6];
`UO_BMI:		takb <=  cr[7];
`UO_BPL:		takb <= !cr[7];
default:	takb <= `TRUE;
endcase

endmodule
