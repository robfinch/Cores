// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fcvtsq.v
//		- convert single precision to quad precision
//		- zero latency
//		- IEEE 754 representation
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

module fcvtsq(a, o);
parameter FPWID = 128;
`include "fpSize.sv"
input [31:0] a;
output reg [FPWID-1:0] o;
wire sa;
wire [7:0] xa;
wire [22:0] ma;
wire [23:0] fracta;
wire adn;
wire az;
wire xaInf;
wire xInf;
wire aNan;

fpDecomp #(32) u1a (.i(a), .sgn(sa), .exp(xa), .man(ma), .fract(fracta), .xz(adn), .vz(az), .xinf(xaInf), .inf(aInf), .nan(aNan) );



always @*
begin
    o[127] <= a[31];    // sign bit
casex({aNan,aInf,az,adn})
// NaN in, NaN out
4'b1xxx:
    begin
        o[126:111] <= 16'hFFFF;
        o[110:103] <= a[22:15];
        o[14:0] <= a[14:0];  
    end
// Infinity in, infinity out
4'bx1xx:
    begin
        o[126:111] <= 16'hFFFF;
        o[110:0] <= 111'b0;
    end
// Zero in, zero out
4'bxx1x:
        o[126:0] <= 127'b0;
// Denormal
4'bxxx1:
    begin
        o[126:111] <= 16'h0000;
        o[110:88] <= ma;
    end
default:
    begin
        o[126:111] <= xa + 16256;
        o[110:88] <= ma;
    end
endcase
end

endmodule
