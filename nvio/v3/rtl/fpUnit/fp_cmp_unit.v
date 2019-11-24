// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fp_cmp_unit.v
//    - floating point comparison unit
//    - parameterized FPWIDth
//    - IEEE 754 representation
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

module fp_cmp_unit(a, b, o, nanx);
parameter FPWID = 32;
`include "fpSize.sv"

input [FPWID-1+`EXTRA_BITS:0] a, b;
output [4:0] o;
reg [4:0] o;
output nanx;

// Decompose the operands
wire sa;
wire sb;
wire [EMSB:0] xa;
wire [EMSB:0] xb;
wire [FMSB:0] ma;
wire [FMSB:0] mb;
wire az, bz;
wire nan_a, nan_b;

fpDecomp #(FPWID) u1(.i(a), .sgn(sa), .exp(xa), .man(ma), .vz(az), .qnan(), .snan(), .nan(nan_a) );
fpDecomp #(FPWID) u2(.i(b), .sgn(sb), .exp(xb), .man(mb), .vz(bz), .qnan(), .snan(), .nan(nan_b) );

wire unordered = nan_a | nan_b;

wire eq = !unordered & ((az & bz) || (a==b));	// special test for zero
wire gt1 = {xa,ma} > {xb,mb};
wire lt1 = {xa,ma} < {xb,mb};

wire lt = sa ^ sb ? sa & !(az & bz): sa ? gt1 : lt1;

always @(unordered or eq or lt or lt1)
begin
	o[0] = eq;
	o[1] = lt;
	o[2] = lt|eq;
	o[3] = lt1;
	o[4] = unordered;
end

// an unorder comparison will signal a nan exception
//assign nanx = op!=`FCOR && op!=`FCUN && unordered;
assign nanx = 1'b0;

endmodule
