# Welcome to the nvio core

# Overview
nvio is a superscalar core with the following features:
- 64 general purpose registers
- 64 floating point registers
- 16 register sets
- 40 bit fixed size instruction set
- 3 instruction bundled together into 128 bits
- 80 bit data width
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- out-of-order instruction execution
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

The nvio fetches three instructions at once and can issue up to seven instructions in a single cycle (2 alu, 1 flow control, 2 floating point, 2 memory) and is capable of committing up to three instructions in a single cycle. The cpu makes use of templates to identify functional units and ease decoding. Every possible combination of units is represented with a template (currently 67 different templates). Because the core is superscalar and not VLIW it can queue any type of instruction even if it isn't ready to execute them. 

## History
nvio is a work-in-progress beginning in May 2019. nvio originated from FT64 which originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. The nvio is the author's second attempt at an 80 bit ISA. Other attempts including DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores. The core's name has been changed from rtfItanium to nvio.

# Rationale
It may seem strange to design an 80-bit cpu. Some of the rationale for doing so is that double-extended floating-point is 80-bits. In order to support the double extended fp internal registers and busses need to be 80 bits in size. Given that a significant portion of the core is 80-bit it was decided just to make the whole core an 80-bit core. Double-extended floating-point offers good precision with which to do business apps. It's approximately 19 digits of precision which amounts to 13 digits plus 6 decimal digits for instance. Ordinary double-precision arithmetic only offers about 16 digits, which isn't quite enough for some business apps once things like rounding are considered. That'd only be 10+6 decimal points. 

## Why so many registers?
For the register usage convention there are about 20 registers assigned statically for specific purposes. These registers include registers for modern software like garbage collectors. A couple of registers are allocated for the assembler to build large constants so that constant building may procesd in parallel. Then there's the usual stack and frame pointers, but also the exception link register which points to exception handlers. The exception offset register, exception type register, class type registers and others. Five registers are dedicated to interfacing to the OS. With so many registers assigned static uses the remaining registers might not be enough for good performance. It was also desirable for implementing a simple compiler, allowing good performance without a complex compiler.

# Implementation Language
The core has been implemented in the System Verilog language. The core is mostly plain Verilog but makes use of System Verilog's capability to pass arrays of bits to modules.

# Software
Assembler, compiler and emulator, all very buggy at this stage.

# Versions
The current version is version one.

# Status
Initial coding of the architecture complete along with documentation. Simulation runs of over 1,000 instructions are being made.

# Size
A minimal configuration of the core is approximately 140,000 LC's (86,000 LUTs). A maximal configuration is approximately  480,000 LC's (300,000 LUTs).

|Q Entries| Q Rate | ALU | FPU | Mem | LUTS |  LCs  |
|:-------:|:------:|:---:|:---:|:---:|:----:|:-----:|
|    3    |    1   |  1  |  1  |  1  |  86k |  140k |

|Q Entries| Q Rate | ALU | FPU | Mem | LUTS |  LCs  |
|:-------:|:------:|:---:|:---:|:---:|:----:|:-----:|
|   15    |    3   |  2  |  2  |  2  | 300k |  480k |

# Primitive Data Types
The ISA supports more data types than usual due to the 80-bit data path size. The author feels it would be foolish not to support typical sizes found in a 64-bit core which include 1,2,4 and 8 byte data types. So, nvio supports 1,2,4,5,8 and 10 byte data types. The data types are referred to as numbers - byte, wyde, tetra, penta, octa, and deci. Scaled indexed addressing accomodates 5 and 10 byte sized primitives as well as the 1,2,4,8 type sizes.
One difference in the floating-point unit from the usual 80-bit format is that the core maintains the paradigm of a hidden '1' bit in the mantissa. This gives the mantissa an extra bit making it effectively 65 bits in size.

# Instruction Set
Several operations similar in nature to what's available on the 68k are available. These include link and unlink stack, load and store multiple register, auto-increment, auto-decrement addressing, and scaled indexed addressing.
The current instruction set allows for up to three register read ports and two register write ports for a single instruction. The primary motivations for this being the desire for indexed addressing and branch-to-register and more complex instructions. Dual write ports allow several convenient operations to improve code density. Auto-increment and auto-decrement register during a memory operation for instance. Three read ports are handy for multiply-accumulate instructions. While the ISA probably does not offer leading edge performance, it's designed to be more programmer friendly in the author's opinion, while still offering good performance.
The design is limited to one memory access per instruction in a load / store architecture excepting load / store multiple.
Instructions are executed independently of each other and there is no flags register.
Large 80-bit immediate constants are supported using the entire bundle for one instruction. Currently 80-bit constants can be used only by integer and floating-point instructions.

