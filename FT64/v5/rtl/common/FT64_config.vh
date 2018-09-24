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
`define SUPPORT_VECTOR	1'b1
//`define DEBUG_LOGIC 1'b1

`define AMSB			31
`define ABITS			`AMSB:0
`define QBITS			3:0
`define QENTRIES	10			// changing this still requires changing code in FT64.
`define XBITS			7:0

//`define SUPPORT_DBG		1'b1
`define FULL_ISSUE_LOGIC	1'b1

`define WAYS			2				// number of ways parallel (not working yet)
`define NUM_IDU		2				// number of instruction decode units (1-3)
`define NUM_ALU		2				// number of ALU's (1-2)
`define NUM_MEM		2				// number of memory queues (1-3)
`define NUM_FPU		2				// number of floating-point units (0-2)
`define NUM_CMT		2				// number of commit busses (1-2)
// Comment out the following to remove FCU enhancements (branch predictor, BTB, RSB)
`define FCU_ENH		1
// Comment out the following to remove bypassing logic on the functional units
`define FU_BYPASS	1

// These are unit availability settings at reset.
`define ID1_AVAIL	1'b1
`define ID2_AVAIL	1'b1
`define ID3_AVAIL 1'b0
`define ALU0_AVAIL	1'b1
`define ALU1_AVAIL	1'b1
`define FPU1_AVAIL	1'b1
`define FPU2_AVAIL	1'b0
`define MEM1_AVAIL	1'b1
`define MEM2_AVAIL	1'b1
`define MEM3_AVAIL	1'b0
`define FCU_AVAIL 1'b1

// Comment out to remove the write buffer from the core.
`define HAS_WB	1'b1
`define	WB_DEPTH	8			// must be one more than desired depth

// Uncomment to allow SIMD operations
`define SIMD	1'b1

// Comment the following to disable registering the output of instruction decoders.
// Inline decoding should not be registered.
`define REGISTER_DECODE		1'b1
//`define INLINE_DECODE		1'b1
