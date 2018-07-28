# Welcome to the FT64v4 core
This core is similar to the original FT64 core but using a 40 bit instructions.

## Overview
FT64v4 is a superscalar core with the following features:
- 64 general purpose registers
- 64 vector registers of 63 elements
- 40 bit fixed size instruction set
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

FT64v4 can issue up to seven instructions in a single cycle (2 alu, 1 flow control, 1 floating point, 3 memory) and is capable of committing up to three instructions in a single cycle. Fetch and queue are limited to two instructions per cycle however.
Currently in the works is a version that can fetch and queue four instructions at a time.

# History
FT64v4 is a work-in-progress beginning in July 2018. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v. FT64 is the author's fourth attempt at a 64 bit ISA. Other attempts including Raptor64, FISA64, and DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Software
There is an assembler 'AS64' and 'CC64' compiler for FT64. The assembler does not yet fully support all the instructions for the core.

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

Most instructions have a precision field associated with them that determines the size of the operation and whether or not the operation is performed in a SIMD style.

A quadrant based immediate instruction allows building a 64 bit constant in a register with minimal headaches.

  