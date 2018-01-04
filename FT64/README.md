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
FT64 is a work-in-progress beginning in July 2017. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v. FT64 is the author's fourth attempt at a 64 bit ISA. Other attempts including Raptor64, FISA64, and DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Software
There is an assembler and 'C64' compiler for FT64. The assembler does not yet fully support all the instructions for the core.

# Versions
There is now a non-superscalar clocked sequential version of the FT64 core. This allows the instruction set to be executed on a smaller core. The sequential version does not support the full instruction set. Just the most commonly used instructions are supported.

# Instruction Set
The instruction set allows for up to three register read ports and up to two register write ports for a single instruction. The motivation for this being the desire for indexed addressing and stack operations. While the ISA probably does not offer leading edge performance, it's designed to be more programmer friendly in the author's opinion, while still offering good performance.
Excepting vector operations the design is limited to one memory access in a load / store architecture.
Instructions are executed independently of each other and there is no flags register.

Instructions allowed with two write ports include:
XCHG (exchange two registers),
POP (pop value off stack),
MUL (multiply return both high and low product words),
DIV/MOD (return both quotient and remainder),
LINK/UNLINK (stack linkage operations)

Several instructions directly support operations of less than a word in size:
ADD/SUB - support 8,16,32, and 64 bit operations
SHIFT - support 8,16,32, and 64 bit operations
LOADS/STORES - support 8,16,32, and 64 bit operations

A quadrant based immediate 'or' instruction allows building a 64 bit constant in a register with minimal headaches.
