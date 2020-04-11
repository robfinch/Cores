// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	config.sv
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
`ifndef CONFIG_H
`define CONFIG_H	1

// The following line is to enable simulation versions of some modules.
// Comment out for synthesis
//`define SIM		1'b1

// The following bit select determines how long the reset counter is active.
// For sim to aid debugging it's good idea to set it to a low number >3
// otherwise there will be a lot of clock cycles before reset is finished.
// For synthesis and using the core a value of 28 (five seconds at 100MHz)
// may be used.
`ifdef SIM
`define RSTC_BIT	5
`else
`define RSTC_BIT	26
`endif

`define AREGS		128

//`define SUPPORT_VECTOR	1'b1
//`define SUPPORT_BBMS	1'b1
//`define DEBUG_LOGIC 1'b1

`define L1_ICACHE_SIZE	2				// 2 or 4 for 2 or 4 kB

// One way to tweak the size of the core a little bit is to limit the number
// of address bits processed. The test system for instance has only 512MB of
// memory, so the address size is limited to 32 bits.
// ** The ASID is stored in the upper 8 bits of the address
`define ABW				52
`define AMSB			51
`define ABITS			`AMSB:0

// The following should match the defintion in the fpConfig.sv file.
// It's the number of extra bits retained in fp calculations and affects the
// size of the result bus.
`define EXTRA_BITS	0

// Number of fetch slots
`define FSLOTS		2

`define UOQ_ENTRIES	8
`define UOQ_BIT 	$clog2(UOQ_ENTRIES)
`define UOQ_BITS	`UOQ_BIT:0

// The number of micro-ops in the program.
`define LAST_UOP	192

// Maximum number of micro-ops that can queue at once.
`define MAX_UOPQ 	4

// Queue size should not be an even power of two!
// Don't use 4,8,16,32,64 etc. As a value of all ones for the qid and rid
// is used to indicate and invalid value.
// If set greater than 10, then memory instructions won't
// issue until they are within 10 of the head of the queue.
`define IQ_ENTRIES	7		// (3 to 15)	// number of entries in dispatch queue
// The number of entries in the re-order buffer should not be greater than
// the number of entries in the dispatch buffer or some of them will sit
// empty all the time. For now it must be the same size as the dispatch
// queue.
`define RENTRIES	`IQ_ENTRIES		// number of entries in re-order buffer

// bitfield representing a queue entry index. The field must be large
// enough to accomodate a queue entry number, determined by the number
// of queue entries above.
// QBIT should be at least as large as RBIT
`define QBIT			$clog2(`RENTRIES > `IQ_ENTRIES ? `RENTRIES : `IQ_ENTRIES)
`define QBITS			`QBIT-1:0
`define QBITSP1		`QBIT:0

// bitfield representing a re-order buffer index.
`define RBIT			$clog2(`RENTRIES)
`define RBIT2			($clog2(`RENTRIES) << 1)
`define RBITS			`RBIT-1:0
`define RBITSP1		`RBIT:0

// The following bitfield spec is for the instruction sequence number. It should
// be at least one bit larger than the queue id.
`define SNBIT			(`QBIT+1)
`define SNBITS		`SNBIT:0

// The following constant controls the maximum number of instructions that will
// be queued in a single cycle. It can be reduced to reduce the size of the core,
// however the branch predictor won't be effective as it depends on this
// configuration constant. Reducing the constant to one for instance will cause
// the branch predictor to operate only on slot 0.
`define QSLOTS		2
`define RSLOTS		2

// Bitfield for representing exception codes
`define XBITS			7:0

//`define SUPPORT_DBG		1'b1

`define FULL_ISSUE_LOGIC	1'b1

// The WAYS config define affects things like the number of ports on the
// register file, the number of ports on the instruction cache, and how
// many entries are contained in the fetch buffers. It also indirectly
// affects how many instructions are queued.
`define WAYS			2				// number of ways parallel (1-2) (use only 2)
`define NUM_IDU		2				// number of instruction decode units (2 only)
`define NUM_ALU		1				// number of ALU's (1-2)
`define NUM_AGEN	2				// number of address generators (1-2)
`define NUM_MEM		2				// number of memory queues (1-2)
`define NUM_FPU		1				// number of floating-point units (0-2)

`define FCU_RSB		1				// return stack buffer
// Enable at most one branch predictor
`define BP_GSELECT	1
//`define BP_GSHARE		1
`define FCU_BTB		1				// Branch target buffer

`define FCU_RA		pc			// return address if no RSB

// Adds logic to bypass results directly from one queue entry to another. This option
// increases the core performance as results are bypassed more quickly, however it
// adds significantly to the size of the core (20%).
//`define QBYPASSING		1

// Comment out the following to remove bypassing logic on the functional units.
// Disabling the bypass will reduce core performance by about 15%-33% while also
// reducing the size of the core.
`define FU_BYPASS	1

`define SUPPORT_TLB		1

// These are unit availability settings at reset.
`define ID1_AVAIL	1'b1
`define ID2_AVAIL	1'b1
`define ID3_AVAIL 1'b1
`define ALU0_AVAIL	1'b1
`define ALU1_AVAIL	1'b1
`define FPU1_AVAIL	1'b1
`define FPU2_AVAIL	1'b1
`define MEM1_AVAIL	1'b1
`define MEM2_AVAIL	1'b1
`define FCU_AVAIL 1'b1

// Write buffer must always be present.
`define HAS_WB	1'b1
`define	WB_DEPTH	5			// must be one more than desired depth

// Uncomment to allow SIMD operations
//`define SIMD	1'b1

// Comment the following to disable registering the output of instruction decoders.
// Inline decoding should not be registered.
//`define REGISTER_DECODE		1'b1
`define INLINE_DECODE		1'b1
`endif

