`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fp_decomp.v
//    - decompose floating point value
//    - parameterized width
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

module fp_decomp(i, sgn, exp, man, fract, xz, mz, vz, inf, xinf, qnan, snan, nan);

parameter WID=32;

localparam MSB  = WID-1;
localparam EMSB = WID==128 ? 14 :
                  WID==96 ? 14 :
                  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? 111 :
                  WID==96 ? 79 :
                  WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

input [MSB:0] i;

output sgn;
output [EMSB:0] exp;
output [FMSB:0] man;
output [FMSB+1:0] fract;	// mantissa with hidden bit recovered
output xz;		// denormalized - exponent is zero
output mz;		// mantissa is zero
output vz;		// value is zero (both exponent and mantissa are zero)
output inf;		// all ones exponent, zero mantissa
output xinf;	// all ones exponent
output qnan;	// nan
output snan;	// signalling nan
output nan;

// Decompose input
assign sgn = i[MSB];
assign exp = i[MSB-1:FMSB+1];
assign man = i[FMSB:0];
assign xz = !(|exp);	// denormalized - exponent is zero
assign mz = !(|man);	// mantissa is zero
assign vz = xz & mz;	// value is zero (both exponent and mantissa are zero)
assign inf = &exp & mz;	// all ones exponent, zero mantissa
assign xinf = &exp;
assign qnan = &exp &  man[FMSB];
assign snan = &exp & !man[FMSB] & !mz;
assign nan = &exp & !mz;
assign fract = {!xz,i[FMSB:0]};

endmodule


