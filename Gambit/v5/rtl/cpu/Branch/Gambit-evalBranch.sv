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
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module EvalBranch(instr, a, takb);
input Instruction instr;
input [1:0] a;
output reg takb;

//Evaluate branch condition
always @*
case(instr.gen.opcode)
`BRANCH0:
	case(instr.br.exop)
	`BEQ:		takb = a==2'b00;
	`BNE:		takb = a!=2'b00;
	`BGT:		takb = a==2'b01;
	`BLT:		takb = a==2'b11;
	endcase
`BRANCH1:
	case(instr.br.exop)
	`BGE:		takb = ~a[1];
	`BLE:		takb = $signed(a) <= 2'b00;
	`BRA:		takb = 1'b1;
	default:	takb = 1'b0;
	endcase
default:	takb = `TRUE;
endcase

endmodule
