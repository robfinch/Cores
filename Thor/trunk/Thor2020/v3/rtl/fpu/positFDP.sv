// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positFDP.v
//    - posit number fused dot product
//    - parameterized width
//    - performs: a*b +/- c*d
//
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

`include "positConfig.sv"

module positFDP(op, a, b, c, d, o, zero, inf);
`include "positSize.sv"
input op;
input [PSTWID-1:0] a;
input [PSTWID-1:0] b;
input [PSTWID-1:0] c;
input [PSTWID-1:0] d;
output [PSTWID-1:0] o;
output zero;
output inf;

wire [PSTWID+es+(PSTWID-es)*2-1:0] o1;
wire [PSTWID+es+(PSTWID-es)*2-1:0] o2;

positFDPMul #(.PSTWID(PSTWID), .es(es)) u1 (a, b, o1, zero1, inf1);
positFDPMul #(.PSTWID(PSTWID), .es(es)) u2 (c, d, o2, zero2, inf2);
positFDPAddsub #(.PSTWID(PSTWID), .es(es)) u3 (op, o1, o2, o, zero, inf);

endmodule
