`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fs2d.v
//    - convert floating point single to double
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

module fs2d(a, o);
input [31:0] a;
output [63:0] o;

reg signo;
reg [10:0] expo;
reg [51:0] mano;

assign o = {signo,expo,mano};

wire signi;
wire [7:0] expi;
wire [22:0] mani;
wire xinf;	// exponent infinite
wire vz;	// value zero
wire xz;	// exponent zero

fpDecomp #(32) u1 (.i(a), .sgn(signi), .exp(expi), .man(mani), .xinf(xinf), .xz(xz), .vz(vz) );
wire [4:0] lz;
cntlz24 u2 ({mani,1'b1}, lz);	// '1' bit already unhidden due to denormalized number

always @(a)
begin
    // sign out always just = sign in
    signo = signi;

    // special check for zero
    if (vz) begin
        expo <= 0;
        mano <= 0;
    end
    // convert infinity / nan
    // infinity in = infinity out
    else if (xinf) begin
        expo <= 11'h7ff;
        mano <= {mani,29'b0};
    end
    // convert denormal
    // a denormal was really a number with an exponent of -126
    // this value is easily represented in the double format
    // it may be possible to normalize the value if it isn't
    // zero
    else if (xz) begin
        expo <= 11'd897 - lz;	// 1023 "zero" -126 - lz
        mano <= {mani << (lz + 1), 29'd0};	// shift one more to hide leading '1'
    end
    // convert typical number
    // adjust exponent, copy mantissa
    else begin
        expo <= expi + 11'd896;		// 1023-127
        mano <= {mani,29'd0};
    end
end

endmodule
