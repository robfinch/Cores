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
output [$clog2(PSTWID-2):0] o;

generate begin : gClz
  case(PSTWID)
  16: cntlz16 u1 (.i({i,1'b1}), .o(o));
  20: cntlz24 u1 (.i({i,1'b1,4'hF}), .o(o));
  32: cntlz32 u1 (.i({i,1'b1}), .o(o));
  40: cntlz48 u1 (.i({i,1'b1,8'hFF}), .o(o));
  52: cntlz64 u1 (.i({i,1'b1,12'hFFF}), .o(o));
  64: cntlz64 u1 (.i({i,1'b1}), .o(o));
  80: cntlz80 u1 (.i({i,1'b1}), .o(o));
  default:  ;
  endcase
end
endgenerate

endmodule
