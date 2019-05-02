// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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
// The following line is to enable simulation versions of some modules.
// Comment out for synthesis.
//`define SIM		1'b1

//`define SUPPORT_SMT		1'b1
//`define SUPPORT_VECTOR	1'b1
//`define SUPPORT_DCI			1'b1	// dynamically compressed instructions
//`define SUPPORT_BBMS	1'b1
//`define SUPPORT_SEGMENTATION	1'b1
//`define SUPPORT_PREDICATION	1'b1
//`define DEBUG_LOGIC 1'b1

// The following define generates rtl to support 40-bit jumps and calls,
// otherwise only 24-bit jumps and calls are supported.
//`define JMP40	1'b1
`define L1_ICACHE_SIZE	2				// 2 or 4 for 2 or 4 kB

// One way to tweak the size of the core a little bit is to limit the number
// of address bits processed. The test system for instance has only 512MB of
// memory, so the address size is limited to 32 bits.
// ** The ASID is stored in the upper 8 bits of the address
`define AMSB			63
`define ABITS			`AMSB:0


// bitfield representing a queue entry index. The field must be large
// enough to accomodate a queue entry number, determined by the number
// of queue entries below.
`define QBIT			4
`define QBITS			3:0
`define QBITSP1		4:0

// The following bitfield spec is for the instruction sequence number. It
// must have at least one more bit in it than the QBITS above as the counter
// can overflow a little bit.
`define SNBITS		4:0

// If set greater than 10, then memory instructions won't
// issue until they are within 10 of the head of the queue.
`define QENTRIES	4

// Bitfield for representing exception codes
`define XBITS			7:0

//`define SUPPORT_DBG		1'b1

// Issue logic is not really required for every possible distance from
// the head of the queue. Later queue entries tend to depend on prior
// ones and hence may not be ready to be issued. Also note that 
// instruction decode takes a cycle making the last entry or two in the
// queue not ready to be issued. Commenting out this line will limit
// much of the issue logic to the first six queue slots relative to the
// head of the queue.
`define FULL_ISSUE_LOGIC	1'b1

// The WAYS config define affects things like the number of ports on the
// register file, the number of ports on the instruction cache, and how
// many entries are contained in the fetch buffers. It also indirectly
// affects how many instructions are queued.
`define WAYS			1				// number of ways parallel (1-3 3 not working yet)
`define NUM_IDU		1				// number of instruction decode units (1-3)
`define NUM_ALU		1				// number of ALU's (1-2)
`define NUM_MEM		1				// number of memory queues (1-3)
`define NUM_FPU		0				// number of floating-point units (0-2)
// Note that even with just a single commit bus, multiple instructions may
// commit if they do not target any registers. Up to three instruction may
// commit even with just a single bus.
`define NUM_CMT		1				// number of commit busses (1-3)
// Comment out the following to remove FCU enhancements (branch predictor, BTB, RSB)
//`define FCU_ENH		1
// Comment out the following to remove bypassing logic on the functional units
`define FU_BYPASS	1

//`define SUPPORT_TLB		1

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
`define	WB_DEPTH	5			// must be one more than desired depth

// Uncomment to allow SIMD operations
//`define SIMD	1'b1

// Comment the following to disable registering the output of instruction decoders.
// Inline decoding should not be registered.
//`define REGISTER_DECODE		1'b1
`define INLINE_DECODE		1'b1
