`timescale 1ns / 1ps

// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
`ifndef FPTYPES_SV
`define FPTYPES_SV

`ifndef EMSB
`include "fpConfig.sv"
`endif

typedef logic [`EMSB:0] Exponent;
typedef logic [`FMSB:0] Mantissa;
typedef logic [`FX:0] ExpandedMantissa;
typedef logic [7:0] Exponent32;
typedef logic [22:0] Mantissa32;

typedef struct packed
{
	logic sign;
	Exponent32 exp;
	Mantissa32 man;
} Float32;

typedef struct packed
{
	logic sign;
	Exponent exp;
	Mantissa man;
} Float;

typedef struct packed
{
	Mantissa man;
	logic g;
	logic r;
	logic s;
} MantissaGRS;

typedef struct packed
{
	Float flt;
	logic g;
	logic r;
	logic s;
} FloatGRS;

typedef struct packed
{
	logic [`EX:0] flt;
} ExpandedFloat;

`endif
