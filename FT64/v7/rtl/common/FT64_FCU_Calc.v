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
`include ".\FT64_defines.vh"

module FT64_FCU_Calc(ol, instr, tvec, a, pc, nextpc, im, waitctr, bus);
parameter WID = 64;
parameter AMSB = 31;
input [1:0] ol;
input [47:0] instr;
input [WID-1:0] tvec;
input [WID-1:0] a;
input [AMSB:0] pc;
input [AMSB:0] nextpc;
input [3:0] im;
input [WID-1:0] waitctr;
output reg [WID-1:0] bus;

always @*
begin
  casez(instr[`INSTRUCTION_OP])
  `BRK:   bus <= instr[16] ? {56'd0,a[7:0]} : {56'b0,instr[15:8]};
  `BBc:
    case(instr[20:19])
		`IBNE:	bus <=  a + 64'd1;
		`DBNZ:	bus <=  a - 64'd1;
		default:	bus <= 64'hCCCCCCCCCCCCCCCC;
		endcase
  `JAL:		bus <= nextpc;
  `CALL:	bus <= nextpc;
  `RET:		bus <= a + (instr[7:6]==2'b01 ? {instr[47:23],3'b0} : {instr[31:23],3'b0});
  `REX:
    case(ol)
    `OL_USER:   bus <= 64'hCCCCCCCCCCCCCCCC;
    // ToDo: fix im test
    default:    bus <= (im < ~{ol,2'b00}) ? tvec : nextpc;
    endcase
  `WAIT:  bus = waitctr==64'd1;
  default:    bus <= 64'hCCCCCCCCCCCCCCCC;
  endcase
end

endmodule

