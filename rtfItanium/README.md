## Welcome to the rtfItanium core

For some reason the word Itanium reminds me of Titanic.

## Overview
rtfItanium is a superscalar core with the following features:
- 64 general purpose registers
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
- Functional Units:
	- dual ALU's,
	- one flow control unit
	- one floating point unit
	- one memory unit (handles 2 load / stores)

The rftItanium fetches three instructions at once and can issue up to six instructions in a single cycle (2 alu, 1 flow control, 1 floating point, 2 memory) and is capable of committing up to three instructions in a single cycle.

# History
rtfItanium is a work-in-progress beginning in May 2019. rtfItanium originated from FT64 which originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v. FT64 is the author's fourth attempt at a 64 bit ISA. Other attempts including Raptor64, FISA64, and DSD9. The author has tried to be innovative with this design borrowing ideas from a number of other processing cores.

# Rationale
It may seem strange to design an 80-bit cpu. Some of the rationale for doing so is that double-extended floating-point is 80-bits. In order to support the double extended fp internal registers and busses need to be 80 bits in size. Given that a significant portion of the core is 80-bit it was decided just to make the whole core an 80-bit core. Double-extended floating-point offers good precision with which to do business apps. It's approximately 19 digits of precision which amounts to 13 digits plus 6 decimal digits for instance. Ordinary double-precision arithmetic only offers about 16 digits, which isn't quite enough for some business apps once things like rounding are considered. That'd only be 10+6 decimal points. 
IA64 supports 81-bit floating point. So 80-bits seems reasonable to me.

# Software
none

# Versions

# Status
Performing an initial code of the architecture along with documentation.

# Instruction Set
The instruction set allows for up to three register read ports and a single register write port for a single instruction. The primary motivations for this being the desire for indexed addressing and branch-to-register. Three read ports are also handy for multiply-accumulate instructions. While the ISA probably does not offer leading edge performance, it's designed to be more programmer friendly in the author's opinion, while still offering good performance.
The design is limited to one memory access per instruction in a load / store architecture.
Instructions are executed independently of each other and there is no flags register.

