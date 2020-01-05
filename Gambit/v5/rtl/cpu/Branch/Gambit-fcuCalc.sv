// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// - flow control calcs
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
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module fcuCalc(ol, instr, a, nextpc, im, waitctr, bus);
parameter WID = 52;
parameter AMSB = 51;
input [2:0] ol;
input Instruction instr;
input [WID-1:0] a;
input Address nextpc;
input [3:0] im;
input [WID-1:0] waitctr;
output reg [WID-1:0] bus;

always @*
begin
  case(instr.gen.opcode)
  `RETGRP:	bus <= a;
  `BRKGRP:	;
  `JAL,`JAL_RN:		bus <= nextpc;
  default:    bus <= {13{4'hC}};
  endcase
end

endmodule

