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

// Uncomment the following to generate code with minimum latency.
// Minimum latency is zero meaning all the clock edges are removed and 
// calculations are performed in one long clock cycle. This will result in
// the maximum clock rate being really low.

//`define MIN_LATENCY		1'b1

// Number of bits extra beyond specified width for calculation results
// should be a multiple of four
`define EXTRA_BITS		0
`define EMSB	10

