# Welcome to the FT64v8 core
Just started construction.

## Overview
FT64v8 is a revision of the FT64 core with support for variable lengths of instructions. 
FT64v8 is a superscalar core with the following features:
- many features are configurable
- 32 general purpose registers
- 32 floating point registers
- 16 data address registers
- 8 code address registers
- 8 condition code registers
- 8 segment registers
- variable length instructions 2 to 6 bytes
- 64 bit data width
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- out-of-order instruction execution
- 4 to 16 entry instruction queue (ROB)
- precise exception handling
- speculative loading (off by default)
- bus interface unit
- write buffering
- instruction (L1, L2) and data caches
- Functional Units (configurable):
	- one to three instruction decoders
	- one or two ALU's,
	- one flow control unit
	- zero to two floating point units
	- one memory unit (handles 3 loads one store)
	- one or two commit busses
- SIMD instructions
- bus randomizer on exceptions

FT64v8 can issue up to eight instructions in a single cycle (2 alu, 1 flow control, 2 floating point, 3 memory) and is capable of committing up to three instructions in a single cycle. v8 will be able to fetch and queue three or more instructions per clock cycle.

# History
FT64v8 is a work-in-progress beginning in December 2018. It is a significant revision of the core. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v. FT64 is the author's fourth attempt at a 64 bit ISA. Other attempts including Raptor64, FISA64, and DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Software
None at the moment.

# Status
Current focus is on the design.

# Issues with the v7 Core
The v7 core has a lot of scheduling logic.

# Configurability

# Power Management

# Security Features

# Instruction Set

  