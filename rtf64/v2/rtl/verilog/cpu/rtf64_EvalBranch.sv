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

module rtf64_EvalBranch(inst, brdat, takb);
parameter WID=64;
input [23:0] inst;  // low 24 bits of instruction
input [WID-1:0] brdat;
output reg takb;

always @*
case(inst[7:0])
`BEQ: takb =  brdat[1];
`BNE: takb = ~brdat[1];
`BMI: takb =  brdat[7];
`BPL: takb = ~brdat[7];
`BVS: takb =  brdat[6];
`BVC: takb = ~brdat[6];
`BCS,`BT: takb =  brdat[0];
`BCC: takb = ~brdat[0];
`BLE: takb = brdat[1] | brdat[7];
`BGT: takb = ~(brdat[1] | brdat[7]);
`BLEU:  takb = brdat[1] | brdat[0];
`BGTU:  takb = ~(brdat[1] | brdat[0]);
`BOD:   takb = brdat[5];
`BPS:   takb = brdat[4];
`BEQZ:  takb = brdat=={WID{1'd0}};
`BNEZ:  takb = brdat!={WID{1'd0}};
`BBC:   takb = ~brdat[inst[18:13]];
`BBS:   takb =  brdat[inst[18:13]];
`BEQI:  takb = brdat=={{56{inst[20]}},inst[20:13]};
`BRA:   takb = 1'b1;
default:  takb = 1'b0;
endcase

endmodule
