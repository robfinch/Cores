// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPPkg.sv
//    - decimal floating point package
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
//	This unit takes a floating point number in an intermediate
// format and normalizes it. No normalization occurs
// for NaN's or infinities. The unit has a two cycle latency.
//
// The mantissa is assumed to start with two whole bits on
// the left. The remaining bits are fractional.
//
// The width of the incoming format is reduced via a generation
// of sticky bit in place of the low order fractional bits.
//
// On an underflowed input, the incoming exponent is assumed
// to be negative. A right shift is needed.
// ============================================================================

package DFPPkg;

`define SUPPORT_DENORMALS	1'b1

typedef struct packed
{
	logic sign;
	logic [4:0] combo;
	logic [14:0] expc;	// exponent continuation field
	logic [139:0] sigc;	// significand continuation field
} DFP160;

// Packed 128 bit (storage) format
typedef struct packed
{
	logic sign;
	logic [4:0] combo;
	logic [11:0] expc;	// exponent continuation field
	logic [109:0] sigc;	// significand continuation field
} DFP128;

typedef logic [13:0] DFP128EXP;
typedef logic [135:0] DFP128SIG;

// Unpacked 128 bit format
typedef struct packed
{
	logic nan;
	logic qnan;
	logic snan;
	logic infinity;
	logic sign;
	logic [13:0] exp;
	logic [135:0] sig;	// significand 34 digits
} DFP128U;

// Normalizer output to rounding, one extra digit
typedef struct packed
{
	logic nan;
	logic qnan;
	logic snan;
	logic infinity;
	logic sign;
	logic [13:0] exp;
	logic [139:0] sig;	// significand 35 digits
} DFP128UN;

// 128-bit Double width significand, normalizer input
typedef struct packed
{
	logic nan;
	logic qnan;
	logic snan;
	logic infinity;
	logic sign;
	logic [13:0] exp;
	logic [279:0] sig;	// significand 68+ 1 lead, 1-trail digit
} DFP128UD;

typedef logic [9:0] DFP64EXP;
typedef logic [63:0] DFP64SIG;

typedef struct packed
{
	logic sign;
	logic [4:0] combo;
	logic [7:0] expc;		// exponent continuation field
	logic [49:0] sigc;	// significand continuation field
} DFP64;

typedef struct packed
{
	logic nan;
	logic qnan;
	logic snan;
	logic infinity;
	logic sign;
	logic [9:0] exp;
	logic [63:0] sig;		// significand 16 digits
} DFP64U;

typedef struct packed
{
	logic nan;
	logic qnan;
	logic snan;
	logic infinity;
	logic sign;
	logic [9:0] exp;
	logic [67:0] sig;		// significand 17 digits
} DFP64UN;

typedef struct packed
{
	logic nan;
	logic qnan;
	logic snan;
	logic infinity;
	logic sign;
	logic [9:0] exp;
	logic [127:0] sig;		// significand 32 digits
} DFP64UD;

endpackage
