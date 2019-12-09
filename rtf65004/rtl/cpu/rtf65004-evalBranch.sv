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
input [5:0] instr;
input [7:0] sr;
output reg takb;

//Evaluate branch condition
always @*
case(instr)
`UO_BEQ:		takb <=  sr[1];
`UO_BCS:		takb <=  sr[0];
`UO_BVS:		takb <=  sr[6];
`UO_BNE:		takb <= !sr[1];
`UO_BCC:		takb <= !sr[0];
`UO_BVC:		takb <= !sr[6];
`UO_BMI:		takb <=  sr[7];
`UO_BPL:		takb <= !sr[7];
`UO_BRA:		takb <= `TRUE;
default:	takb <= `TRUE;
endcase

endmodule
