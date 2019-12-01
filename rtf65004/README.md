# Welcome to the rtf65004 core

## Overview
This core is a superscalar version of the 6502. It works by splitting up the 6502 instructions into multiple risc instructions called micro-ops. The micro-ops are very simple 16-bit instructions. Internal to the core it processes micro-ops. Externally it just looks like 6502 instructions are being executed. This is the same approach as is used by the pentium processor. 

## Features
- 6502 programming model
---- acc, x, y, sp, status registers
- variable length 6502 instruction set
- dual instruction fetch
- 16 bit wide internal busses
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- out-of-order instruction execution (ROB)
- precise exception handling
- speculative loading
- bus interface unit
- instruction (L1, L2) and data (L1, L2) caches
- write buffering
- Functional Units:
	- dual ALU's,
	- dual address generators
	- one flow control unit
	- one memory unit (handles 2 load / stores)

## History
rtf65004 is a work-in-progress beginning in November 2019. rtf65004 orignated from nvio which originated from FT64 which originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. The rtf65004 is the author's first attempt at a micro-op based processor. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Rationale
The 6502 is a highly popular processor. Rather than design another instruction set, the author wanted to build on something existing already. The rtf65004 is mainly a learning exercise for the author. It's simpler than the x86 instruction set and lends itself to what is probably a simpler implementation. To the author's knowledge there isn't a superscalar 6502 out there.

# Implementation Language
The core has been implemented in the System Verilog language. The core is mostly plain Verilog but makes use of System Verilog's capability to pass arrays of bits to modules.

# Software
None specific to the rtf65004 at this stage. But existing 6502 toolsets may be used to code assembler and produce binaries.

# Versions
The current version in the works is version one.

# Status
Some preliminary coding has been done. 

# Instruction Set
- the goal is to implement the 6502 instruction set. It should be possible to implement many of the undocumented instructions, but that is not being done at this time.
