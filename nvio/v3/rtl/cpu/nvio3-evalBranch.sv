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
`include "nvio3-defines.sv"

module EvalBranch(instr, cr, takb);
parameter WID=128;
input [39:0] instr;
input [7:0] cr;
output reg takb;

wire [4:0] cond = instr[`RS1];

//Evaluate branch condition
always @*
case(cond)
`BEQ:		takb <=  cr[0];
`BLT:		takb <=  cr[1];
`BGT:		takb <=  cr[2];
`BCS:		takb <=  cr[3];
`BVS:		takb <=  cr[5];
`BNE:		takb <= !cr[0];
`BGE:		takb <= !cr[1];
`BLE:		takb <= !cr[2];
`BCC:		takb <= !cr[3];
`BVC:		takb <= !cr[5];
`BUS:		takb <=  cr[7];
`BUC:		takb <= !cr[7];
default:	takb <= 1'b1;
endcase

endmodule
