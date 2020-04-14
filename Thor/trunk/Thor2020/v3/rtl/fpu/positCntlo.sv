`include "positConfig.sv"
// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positCntlo.sv
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
module positCntlo(i, o);
parameter PSTWID = `PSTWID;
input [PSTWID-2:0] i;
output [$clog2(PSTWID-2):0] o;

generate begin : gClz
  case(PSTWID)
  16: cntlo16 u1 (.i({i,1'b1}), .o(o));
  20: cntlo24 u1 (.i({i,1'b1,4'hF}), .o(o));
  32: cntlo32 u1 (.i({i,1'b1}), .o(o));
  40: cntlo48 u1 (.i({i,1'b1,8'hFF}), .o(o));
  52: cntlo64 u1 (.i({i,1'b1,12'hFFF}), .o(o));
  64: cntlo64 u1 (.i({i,1'b1}), .o(o));
  80: cntlo80 u1 (.i({i,1'b1}), .o(o));
  default:  ;
  endcase
end
endgenerate

endmodule
