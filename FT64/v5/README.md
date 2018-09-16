# Welcome to the FT64v5 core

## Overview
FT64v5 is a revision of the FT64 core with support for three different lengths of instructions. FT64v5 offers 16 bit compressed instructions and 48 bit extended instructions in addition to a 32 bit instruction size. The author desired to get the benefits of code dense 16 bit instructions.
FT64v5 is a superscalar core with the following features:
- 32 general purpose registers
- 32 vector registers of 63 elements
- 16/32/48 bit size instruction set
- 64 bit data width
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- out-of-order instruction execution
- precise exception handling
- speculative loading
- bus interface unit
- instruction (L1, L2) and data caches
- Functional Units (configurable):
	- one to three instruction decoders
	- one or two ALU's,
	- one flow control unit
	- zero to two floating point units
	- one memory unit (handles 3 loads one store)
	- one or two commit busses
- vector instructions
- SIMD instructions

FT64v5 can issue up to eight instructions in a single cycle (2 alu, 1 flow control, 2 floating point, 3 memory) and is capable of committing up to three instructions in a single cycle. Fetch and queue are limited to two instructions per cycle however.
Currently in the works is a version that can fetch and queue four instructions at a time.

# History
FT64v5 is a work-in-progress beginning in August 2018. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v. FT64 is the author's fourth attempt at a 64 bit ISA. Other attempts including Raptor64, FISA64, and DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Software
There is an assembler and 'CC64' compiler for FT64. The assembler does not yet fully support all the instructions for the core.

# Status
Current focus is on getting the base integer instruction set working including the most common operations.
Floating point is largely untested.
There is an off by one error in the vector processing instructions. The core tries to process too many elements sometimes.
The RSB doesn't work very well, causing most returns to be multi-cycle operations instead of single cycle.
An attempt is being made to get the core to run a BIOS demo program. Currently it clears the screen then appears to hang.

# Configurability
FT64v5 is configurable to allow tuning of performance and core size. If desired the core may be used effectively as an OoO scalar processor by reducing the number of commit busses and functional units.
Functional units within the core may also be disabled for power management.

# Power Management
One recently added feature is the ability of the core to disable functional units to reduce power requirements.

# Instruction Set
The instruction set allows for up to three register read ports and a single register write port for a single instruction. The primary motivations for this being the desire for indexed addressing and branch-to-register. Three read ports are also handy for multiply-accumulate instructions. While the ISA probably does not offer leading edge performance, it's designed to be more programmer friendly in the author's opinion, while still offering good performance.
Excepting vector operations the design is limited to one memory access per instruction in a load / store architecture.
Instructions are executed independently of each other and there is no flags register.
Most recently added instructions were loads that bypass the data cache.
A number of instructions support SIMD operation.
The base instruction set is 32 bit, but 16 bit compressed instruction forms are also supported. There are also 48 bit long forms of instructions.
Two bits (bits 6 and 7) of the instruction are used to determine the instruction size.
Many instructions directly support operations of less than a word in size including:
ADD/SUB - support 8,16,32, and 64 bit operations
LOADS/STORES - support 8,16,32, and 64 bit operations
Loading a 64 bit constant into a register may be done using only two instructions. LUI (load upper immediate) and ORI (or immediate).


  