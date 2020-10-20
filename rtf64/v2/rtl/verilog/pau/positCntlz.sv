`include "positConfig.sv"
// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positCntlz.sv
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
module positCntlz(i, o);
parameter PSTWID = `PSTWID;
input [PSTWID-2:0] i;
output [$clog2(PSTWID-1)-1:0] o;

generate begin : gClz
  if (PSTWID <= 8)
    cntlz8 u1 (.i({i,{9-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 16)
    cntlz16 u1 (.i({i,{17-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 24)
    cntlz24 u1 (.i({i,{25-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 32)
    cntlz32 u1 (.i({i,{33-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 48)
    cntlz48 u1 (.i({i,{49-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 64)
    cntlz64 u1 (.i({i,{65-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 80)
    cntlz80 u1 (.i({i,{81-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 96)
    cntlz96 u1 (.i({i,{97-PSTWID{1'b1}}}), .o(o));
  else if (PSTWID <= 128)
    cntlz128 u1 (.i({i,{129-PSTWID{1'b1}}}), .o(o));
end
endgenerate

endmodule
