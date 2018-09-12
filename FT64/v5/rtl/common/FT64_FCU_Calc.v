// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT64_FCU_Calc.v
// - FT64 flow control calcs
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
`include ".\FT64_defines.vh"

module FT64_FCU_Calc(ol, instr, tvec, a, i, pc, im, waitctr, bus);
parameter WID = 64;
parameter AMSB = 31;
input [1:0] ol;
input [47:0] instr;
input [WID-1:0] tvec;
input [WID-1:0] a;
input [WID-1:0] i;
input [AMSB:0] pc;
input [2:0] im;
input [WID-1:0] waitctr;
output reg [WID-1:0] bus;

always @*
begin
  casez(instr[`INSTRUCTION_OP])
  `BRK:   bus <= {{56{1'b0}},instr[15:8]};
  `BBc:
    case(instr[20:19])
		`IBNE:	bus <=  a + 64'd1;
		`DBNZ:	bus <=  a - 64'd1;
		default:	bus <= 64'hCCCCCCCCCCCCCCCC;
		endcase
  `JAL:   bus <= pc + (instr[6] ? 32'd6 : 32'd4);
  `CALL:	bus <= pc + (instr[6] ? 32'd6 : 32'd4);
  `RET:	bus <= a + i;
  `REX:
    case(ol)
    `OL_USER:   bus <= 64'hCCCCCCCCCCCCCCCC;
    // ToDo: fix im test
    default:    bus <= (im < ~ol) ? tvec : pc + 32'd4;
    endcase
  `WAIT:  bus = waitctr==64'd1;
  default:    bus <= 64'hCCCCCCCCCCCCCCCC;
  endcase
end

endmodule

