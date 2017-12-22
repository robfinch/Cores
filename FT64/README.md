# Welcome to the FT64 core

## Overview
FT64 is a superscalar core with the following features:
- 32 general purpose registers
- 32 vector registers of 64 elements
- 32 bit fixed size instruction set
- 64 bit data width
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- speculative loading
- bus interface unit
- instruction (L1, L2) and data caches
- Functional Units:
	- dual ALU's with dual result busses,
	- one flow control unit
	- one floating point unit
	- one memory unit
- vector instructions

FT64 can issue up to four instructions in a single cycle (2 alu, 1 flow control, 1 floating point) and is capable of committing up to three instructions in a single cycle. Fetch and queue are limited to two instructions per cycle however.

# History
FT64 is a work-in-progress beginning in July 2017. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v

# Software
There is an asssembler and 'C64' compiler for FT64. The assembler does not yet fully support all the instructions for the core.

# Versions
There is now a non-superscalar clocked sequential version of the FT64 core. This allows the instruction set to be executed on a smaller core.
