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

module FT64_FCU_Calc(ol, instr, tvec, a, i, next_pc, im, waitctr, bus);
parameter WID = 64;
parameter AMSB = 31;
input [2:0] ol;
input [31:0] instr;
input [WID-1:0] tvec;
input [WID-1:0] a;
input [WID-1:0] i;
input [AMSB:-2] next_pc;
input [2:0] im;
input [WID-1:0] waitctr;
output reg [WID-1:0] bus;

always @*
begin
    casez(instr[`INSTRUCTION_OP])
    `BRK:   bus <= {{57{1'b1}},instr[12:6]};
    `BBc:   case(instr[19:17])
    		`IBNE:	bus <=  a + 64'd1;
    		`DBNZ:	bus <=  a - 64'd1;
    		default:	bus <= 64'hCCCCCCCCCCCCCCCC;
    		endcase
    `JAL:   bus <= next_pc;
    `CALL:	bus <= next_pc;
    `RET:	bus <= a + i;
    `REX:
        case(ol)
        `OL_USER:   bus <= 64'hCCCCCCCCCCCCCCCC;
        default:    bus <= (im < ~ol) ? tvec : next_pc;
        endcase
    `WAIT:  bus = waitctr==64'd1;
    default:    bus <= 64'hCCCCCCCCCCCCCCCC;
    endcase
end

endmodule

