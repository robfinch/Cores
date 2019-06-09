// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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
`include ".\rtfItanium-defines.sv"

module FCU_Calc(ol, instr, tvec, a, nextpc, im, waitctr, bus);
parameter WID = 80;
parameter AMSB = 79;
input [1:0] ol;
input [39:0] instr;
input [WID-1:0] tvec;
input [WID-1:0] a;
input [AMSB:0] nextpc;
input [3:0] im;
input [WID-1:0] waitctr;
output reg [WID-1:0] bus;

always @*
begin
  case(instr[`OPCODE4])
  `BRK:   bus <= {72'd0,a[7:0]} | {72'b0,instr[29:22]};
  `JAL:		bus <= nextpc;
  `CALL:	bus <= nextpc;
  `RET:		bus <= a + {instr[39:22],1'b0};
  `REX:
    case(ol)
    `OL_USER:   bus <= 80'hCCCCCCCCCCCCCCCCCCCC;
    // ToDo: fix im test
    default:    bus <= (im < ~{ol,2'b00}) ? tvec : nextpc;
    endcase
  `BMISC:
  	case(instr[`FUNCT5])
  	`RTI:		bus <= 80'hCCCCCCCCCCCCCCCCCCCC;	// RTI
  	`WAIT:  bus = waitctr==64'd1;
  	default:	bus <= 80'hCCCCCCCCCCCCCCCCCCCC;
  	endcase
  default:    bus <= 80'hCCCCCCCCCCCCCCCCCCCC;
  endcase
end

endmodule

