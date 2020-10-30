// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positToInt.sv
//    - posit number to integer convertor
//    - can issue every clock cycle
//    - parameterized width
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

module positToInt(i, o);
`include "positSize.sv"
input [PSTWID-1:0] i;
output reg [PSTWID-1:0] o;

localparam N = PSTWID;
localparam Bs = $clog2(PSTWID-1);

wire sgn;
wire rgs;
wire [Bs-1:0] rgm;
wire [es-1:0] exp;
wire [N-es-1:0] sig;
wire zer;
wire inf;

positDecompose #(.PSTWID(PSTWID), .es(es)) u1 (.i(i), .sgn(sgn), .rgs(rgs), .rgm(rgm), .exp(exp), .sig(sig), .zer(zer), .inf(inf));

wire [N-1:0] m = {sig,{es{1'b0}}};
wire isZero = zer;
wire [15:0] argm = rgs ? rgm : -rgm;
wire [15:0] ex1 = (argm << es) + exp;
wire exv = ~ex1[15] && ex1 > PSTWID-1;
wire [N*2-1:0] mo = {m,{N{1'b0}}} >> (PSTWID-ex1-1);
wire L = mo[N];
wire G = mo[N-1];
wire R = mo[N-2];
wire St = |mo[N-3:0];
// If regime+exp == -1 then the value is 0.5 or greater, so round up.
// If the regime+exp < -1 then the values is 0.25 or less, do not round up.
// Otherwise use rounding rules.
wire ulp = (~ex1[15] && ((G & (R | St)) | (L & G & ~(R | St)))) ||
              (ex1==16'hFFFF);
wire [PSTWID-1:0] rnd_ulp = {{PSTWID-1{1'b0}},ulp};
wire [PSTWID-1:0] tmp = ~rgs ? rnd_ulp : mo[N*2-1:N] + rnd_ulp;

always @*
casez({isZero,inf|exv})    // exponent all ones or exponent overflow?
// convert to +0.0 zero-in zero-out (the sign will always be plus)
2'b1?:  o = {PSTWID{1'b0}};
// Infinity in or exponent overflow in conversion = infinity out
2'b01:  o = {1'b1,{PSTWID-1{1'b0}}};
// Other numbers
default:  o = sgn ? -tmp : tmp;
endcase

endmodule
