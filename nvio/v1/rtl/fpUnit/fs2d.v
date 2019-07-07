// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
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
input [39:0] a;
output [79:0] o;

reg signo;
reg [14:0] expo;
reg [63:0] mano;

assign o = {signo,expo,mano};

wire signi;
wire [9:0] expi;
wire [28:0] mani;
wire xinf;	// exponent infinite
wire vz;	// value zero
wire xz;	// exponent zero

fpDecomp #(40) u1 (.i(a), .sgn(signi), .exp(expi), .man(mani), .xinf(xinf), .xz(xz), .vz(vz) );
wire [5:0] lz;
cntlz32 u2 ({mani,3'b111}, lz);	// '1' bit already unhidden due to denormalized number

always @*
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
    expo <= 15'h7fff;
    mano <= {mani,35'b0};
  end
  // convert denormal
  // a denormal was really a number with an exponent of -126
  // this value is easily represented in the double format
  // it may be possible to normalize the value if it isn't
  // zero
  else if (xz) begin
    expo <= 15'd31745 - lz;	// 32767 "zero" -1022 - lz
    mano <= {mani << (lz + 1), 35'd0};	// shift one more to hide leading '1'
  end
  // convert typical number
  // adjust exponent, copy mantissa
  else begin
    expo <= expi + 15'd31744;		// 32767-1023  1023-127
    mano <= {mani,35'd0};
  end
end

endmodule
