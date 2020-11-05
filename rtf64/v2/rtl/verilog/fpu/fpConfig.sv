`timescale 1ns / 1ps

// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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

// Uncomment the following to generate code with minimum latency.
// Minimum latency is zero meaning all the clock edges are removed and 
// calculations are performed in one long clock cycle. This will result in
// the maximum clock rate being really low.

`define MIN_LATENCY		1'b1

// Number of bits extra beyond specified FPWIDth for calculation results
// should be a multiple of four
`define EXTRA_BITS		0

`define FPWID		64

// This file contains defintions for fields to ease dealing with different fp
// FPWIDths. Some of the code still needs to be modified to support FPWIDths
// other than standard 32,64 or 80 bit.
`define	MSB 	(`FPWID-1)
`define EMSB	(`FPWID==128 ? 14 : `FPWID==96 ? 14 : `FPWID==80 ? 14 : `FPWID==64 ? 10 : `FPWID==52 ? 10 : `FPWID==48 ? 10 : `FPWID==44 ? 10 : `FPWID==42 ? 10 : `FPWID==40 ?  9 : `FPWID==32 ?  7 : `FPWID==24 ?  6 : 49)
`define FMSB 	(`FPWID==128 ? (111) : `FPWID==96 ? (79) : `FPWID==80 ? (63) : `FPWID==64 ? (51) : `FPWID==52 ? (39) : `FPWID==48 ? (35) : `FPWID==44 ? (31) : `FPWID==42 ? (29) : `FPWID==40 ? (28) : `FPWID==32 ? (22) : `FPWID==24 ? (15) : (9))
`define FX		((`FMSB+2)*2)	// the MSB of the expanded fraction
`define EX		(`FX + 1 + `EMSB + 1 + 1 - 1)
