# Welcome to the FT64 core
Please see the v7 core in the v7 directory for the most recent version of the core.

## Overview
FT64 is a superscalar core with the following features:
- 32 general purpose registers
- 32 vector registers of 63 elements
- 32 bit fixed size instruction set
- 64 bit data width
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- out-of-order instruction execution
- precise exception handling
- speculative loading
- bus interface unit
- instruction (L1, L2) and data caches
- Functional Units:
	- dual ALU's,
	- one flow control unit
	- one floating point unit
	- one memory unit (handles 3 loads one store)
- vector instructions
- SIMD instructions

FT64 can issue up to seven instructions in a single cycle (2 alu, 1 flow control, 1 floating point, 3 memory) and is capable of committing up to three instructions in a single cycle. Fetch and queue are limited to two instructions per cycle however.
Currently in the works is a version that can fetch and queue four instructions at a time.

# History
FT64 is a work-in-progress beginning in July 2017. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v. FT64 is the author's fourth attempt at a 64 bit ISA. Other attempts including Raptor64, FISA64, and DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Software
There is an assembler and 'CC64' compiler for FT64. The assembler does not yet fully support all the instructions for the core.

# Versions
There is now a non-superscalar clocked sequential version of the FT64 core. This allows the instruction set to be executed on a smaller core. The author desired to use the same ISA to test other cores and a smaller version of the core was required. The sequential version does not support the full instruction set. Just the most commonly used instructions are supported.

# Status
Current focus is on getting the base integer instruction set working including the most common operations.
Floting point is largely untested.
There is an off by one error in the vector processing instructions. The core tries to process too many elements sometimes.
The RSB doesn't work very well, causing most returns to be multi-cycle operations instead of single cycle.
An attempt is being made to get the core to run a BIOS demo program. Currently it clears the screen then appears to hang.

# Instruction Set
The instruction set allows for up to three register read ports and a single register write port for a single instruction. The primary motivations for this being the desire for indexed addressing and branch-to-register. Three read ports are also handy for multiply-accumulate instructions. While the ISA probably does not offer leading edge performance, it's designed to be more programmer friendly in the author's opinion, while still offering good performance.
Excepting vector operations the design is limited to one memory access per instruction in a load / store architecture.
Instructions are executed independently of each other and there is no flags register.
Most recently added instructions were loads that bypass the data cache.
A number of instructions support SIMD operation.
* Stack operations have been dropped from the core.

Many instructions directly support operations of less than a word in size including:
ADD/SUB - support 8,16,32, and 64 bit operations
CMP/CMPU - support 8,16,32, and 64 bit operations
SHIFT - support 8,16,32, and 64 bit operations
LOADS/STORES - support 8,16,32, and 64 bit operations

A quadrant based immediate 'or' instruction allows building a 64 bit constant in a register with minimal headaches.

Directories
trunk
|
+doc	contains documentation
+rtl
  +--common		code common to all versions
  +--seq		sequential clocked version
  +--twoway		two way superscalar code
  +--fourway	four way supserscalar code
  +--fpUnit		floating point unit code
  +--lib		component library type code
  +--sandbox	scrap work area
 |
+soc
+software
  +--cc64		C comiler
  +--as64		Assembler
  +--em64		Emulator
  +--boot		

  