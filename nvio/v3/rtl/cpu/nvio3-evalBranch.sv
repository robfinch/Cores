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
`define TRUE    1'b1
`define JLT		8'hC0
`define JGE		8'hC1
`define JLE		8'hC2
`define JGT		8'hC3
`define JEQ		8'hC4
`define JNE		8'hC5
`define JCS		8'hC6
`define JCC		8'hC7
`define JVS		8'hC8
`define JVC		8'hC9
`define JUS		8'hCA
`define JUC		8'hCB

module EvalBranch(instr, cr, takb);
parameter WID=128;
input [39:0] instr;
input [7:0] cr;
output reg takb;

wire [7:0] opcode = instr[7:0];

//Evaluate branch condition
always @*
case(opcode)
`JEQ:		takb <=  cr[0];
`JLT:		takb <=  cr[1];
`JGT:		takb <=  cr[2];
`JCS:		takb <=  cr[3];
`JVS:		takb <=  cr[5];
`JNE:		takb <= !cr[0];
`JGE:		takb <= !cr[1];
`JLE:		takb <= !cr[2];
`JCC:		takb <= !cr[3];
`JVC:		takb <= !cr[5];
`JUS:		takb <=  cr[7];
`JUC:		takb <= !cr[7];
default:	takb <= `TRUE;
endcase

endmodule
