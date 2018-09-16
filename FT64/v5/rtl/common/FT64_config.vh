// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_config.vh
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
//
`define SIM		1'b1
//`define SUPPORT_SMT		1'b1
//`define DEBUG_LOGIC 1'b1

`define AMSB			31
`define ABITS			`AMSB:0
`define QBITS			2:0
`define QENTRIES	8
`define XBITS			7:0

//`define SUPPORT_DBG		1'b1
`define FULL_ISSUE_LOGIC	1'b1

`define NUM_ALU		2
`define ID1_AVAIL	1'b1
`define ID2_AVAIL	1'b1
`define ALU0_AVAIL	1'b1
`define ALU1_AVAIL	1'b1
`define FPU1_AVAIL	1'b1
`define FPU2_AVAIL	1'b0
`define FCU_AVAIL 1'b1

