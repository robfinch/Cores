// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fd2s.v
//    - convert floating point double to single
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

`include "fpConfig.sv"

module fd2s(a, o);
input [63:0] a;
output reg [31:0] o;

wire signi;
wire [10:0] expi;
wire [51:0] mani;
wire xinf;
wire xz;
wire vz;
fpDecomp #(64) u1 (.i(a), .sgn(signi), .exp(expi), .man(mani), .xinf(xinf), .xz(xz), .vz(vz) );
wire [11:0] exp = expi - 11'h896;   // 1023-127 (difference of the bias)

always @*
begin
o[31] <= signi;         // sign out = sign in, easy
o[22:0] <= a[51:29];
if (xinf)
    o[30:23] <= 8'hFF;
else if (vz)
    o[30:23] <= 8'h00;
else if (xz)
    o[30:23] <= 8'h00;
else begin
    if (exp[11]) begin  // exponent is too low - set number to zero
        o[30:23] <= 8'h00;
        o[22:0] <= 23'h000000;
    end
    else if (|exp[10:8]) begin  // exponent is too high - set number to infinity
        o[30:23] <= 8'hFF;
        o[22:0] <= 23'h000000;
    end
    else    // exponent in range
        o[30:23] <= exp[7:0];
end
end

endmodule
