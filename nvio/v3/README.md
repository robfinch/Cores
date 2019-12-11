# Welcome to the nvio3 core

# Overview
nvio3 is a superscalar core with the following features:
- 32 entry general purpose registers (128-bits wide)
- 32 entry floating point registers	(128-bits wide)
- 32 vector registers (256-bits wide)
- 8 condition code registers
- 8 link registers
- 8 mask registers
- 40 bit fixed size instruction set
- 256 bit wide internal busses
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- out-of-order instruction execution (ROB)
- precise exception handling
- speculative loading
- bus interface unit
- instruction (L1, L2) and data (L1, L2) caches
- write buffering
- support for large immediates
- Functional Units:
	- dual ALU's,
	- dual address generators
	- one flow control unit
	- dual floating point unit
	- one memory unit (handles 2 load / stores)

The nvio3 fetches four instructions at once and can issue up to seven instructions in a single cycle (2 alu, 1 flow control, 2 floating point, 2 memory) and is capable of committing up to four instructions in a single cycle. 

## History
nvio3 is a work-in-progress beginning in July 2019. nvio originated from FT64 which originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. The nvio is the author's first attempt at an 128 bit ISA. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Rationale
It may seem strange to design an 128-bit cpu. Some of the rationale for doing so is that quad precision floating-point is 128-bits. In order to support the quad precision fp internal registers and busses need to be 128 bits in size. Given that a significant portion of the core is 128-bit it was decided just to make the whole core an 128-bit core. Quad precision is more than enough precision for many types of apps. Ordinary double-precision arithmetic only offers about 19 digits, which isn't quite enough for some apps once things like rounding are considered.

# Implementation Language
The core has been implemented in the System Verilog language. The core is mostly plain Verilog but makes use of System Verilog's capability to pass arrays of bits to modules.

# Software
Assembler, compiler and emulator, all very buggy at this stage.

# Versions
The current version in the works is version three.

# Status
Still working on the ISA, some preliminary coding has been done. A test synthesis shows the core to be about 900,000 LC's. The most recent update was to change absolute branches to relative ones.

# Primitive Data Types
The ISA supports more data types than usual due to the 128-bit data path size. The author feels it would be foolish not to support typical sizes found in a 64-bit core which include 1,2,4 and 8 byte data types. So, nvio supports 1,2,4,5,8 and 16 byte data types. The data types are referred to as numbers - byte, wyde, tetra, penta, octa, and hexi. Scaled indexed addressing accomodates 5 byte sized primitives as well as the 1,2,4,8,16 type sizes. The penta-byte data size is provided for accessing instructions which are five bytes in size.

# Instruction Set
The current instruction set allows for up to three register read ports and one register write ports for a single instruction. Three read ports are handy for multiply-accumulate instructions. While the ISA probably does not offer leading edge performance, it's designed to be more programmer friendly in the author's opinion, while still offering good performance.
Instructions are executed independently of each other.
Large 128-bit immediate constants are supported as sequence of instruction prefixes. Each prefix provides 31 bits of the value. Using a prefix serializes the queuing of the instruction. One clock cycle per prefix is required.
The ISA supports four addressing modes for load / store instructions. d[Rn], d[Rn]+, -d[Rn], and d[Rx+Ry*Sc].
