// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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

module F80ToF32(a, o);
input [79:0] a;
output [31:0] o;

reg signo;
reg [7:0] expo;
reg [22:0] mano;

assign o = {signo,expo,mano};

wire signi;
wire [14:0] expi;
wire [63:0] mani;
wire xinf;	// exponent infinite
wire vz;	// value zero
wire xz;	// exponent zero

fpDecomp #(80) u1 (.i(a), .sgn(signi), .exp(expi), .man(mani), .xinf(xinf), .xz(xz), .vz(vz) );

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
    expo <= 8'h7f;
    mano <= mani[63:41];
  end
  // convert denormal
  // a denormal was really a number with an exponent of -126
  // this value is easily represented in the double format
  // it may be possible to normalize the value if it isn't
  // zero
  else if (xz) begin
    expo <= 8'h00;
    mano <= 23'h0;
  end
  // convert typical number
  // adjust exponent, copy mantissa
  else begin
  	if (expi < 15'h3fff - 8'h7f) begin
  		expo <= 8'h00;	// zero
  		mano <= 23'h0;
  	end
  	else if (expi > 15'h3fff + 8'h7f) begin
  		expo <= 8'hFF;	// Infinity
  		mano <= 23'h0;
  	end
  	else begin
    	expo <= expi - 15'h3fff + 8'h7f;
    	mano <= mani[63:41];
    end
  end
end

endmodule
