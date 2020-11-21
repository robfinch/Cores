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
`include "../inc/rtf64-defines.sv"

module rtf64_EvalBranch(inst, cd, id, takb);
parameter WID=64;
input [23:0] inst;  // low 24 bits of instruction
input [7:0] cd;
input [WID-1:0] id;
output reg takb;

always @*
case(inst[7:0])
`BEQ: takb =  cd[1];
`BNE: takb = ~cd[1];
`BMI: takb =  cd[7];
`BPL: takb = ~cd[7];
`BVS: takb =  cd[6];
`BVC: takb = ~cd[6];
`BCS,`BT: takb =  cd[0];
`BCC: takb = ~cd[0];
`BLE: takb = cd[1] | cd[7];
`BGT: takb = ~(cd[1] | cd[7]);
`BLEU:  takb = cd[1] | cd[0];
`BGTU:  takb = ~(cd[1] | cd[0]);
`BOD:   takb = cd[5];
`BPS:   takb = cd[4];
`BEQZ:  takb = id=={WID{1'd0}};
`BNEZ:  takb = id!={WID{1'd0}};
`BBC:   takb = ~id[inst[18:13]];
`BBS:   takb =  id[inst[18:13]];
`BEQI:  takb = id=={{56{inst[20]}},inst[20:13]};
`BRA:   takb = 1'b1;
default:  takb = 1'b0;
endcase

endmodule
