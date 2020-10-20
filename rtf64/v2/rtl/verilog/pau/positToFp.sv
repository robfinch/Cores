// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	positToFp.v
//    - posit number to floating point convertor
//    - can issue every clock cycle
//    - parameterized width
//    - IEEE 754 representation
//
// Parts of this code originated from Posit_to_FP.v by Manish Kumar Jaiswal
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
`include "fpConfig.sv"
`include "fpTypes.sv"

module positToFp(i, o);
parameter FPWID = 32;
`include "fpSize.sv"
`include "positSize.sv"
input [FPWID-1:0] i;
output reg [FPWID-1:0] o;

parameter BIAS = {1'b0,{EMSB{1'b1}}};
localparam N = FPWID;
localparam E = EMSB+1;
localparam M = FMSB+1;
localparam Bs = $clog2(FPWID-1);
localparam EO = E > es+Bs ? E : es+Bs;

wire sgn;
wire rgs;
wire [Bs-1:0] rgm;
wire [es-1:0] exp;
wire [N-es-1:0] sig;
wire zer;
wire inf;

positDecompose #(.PSTWID(PSTWID), .es(es)) u1 (.i(i), .sgn(sgn), .rgs(rgs), .rgm(rgm), .exp(exp), .sig(sig), .zer(zer), .inf(inf));

wire [N-1:0] m = {sig,{es{1'b0}}};
wire [EO+1:0] e;
assign e = {(rgs ? {{EO-es-Bs+1{1'b0}},rgm} : -{{EO-es-Bs+1{1'b0}},rgm}),exp} + BIAS;
wire exv = |e[EO:E];
wire exinf = &e[E-1:0];

always @*
casez({zer,inf|exv|exinf})    // exponent all ones or exponent overflow?
// convert to +0.0 zero-in zero-out (the sign will always be plus)
2'b1?:  o = {sgn,{FPWID-1{1'b0}}};
// Infinity in or exponent overflow in conversion = infinity out
2'b01:  o = {sgn,{E-1{1'b1}},{M{1'b0}}}; 
// Other numbers
default:  o = {sgn,e[E-1:0],m[N-2:E]};
endcase

endmodule
