# Welcome to the Monster64 core

## Overview
Monster64 is a 3-way superscalar core with the following features:
- 64 general purpose registers
- 64 vector registers of 64 elements
- 40 bit fixed size instruction set
- 64 bit data width
- branch prediction with branch target buffer (BTB)
- return address prediction (RSB)
- register renaming
- speculative loading
- bus interface unit
- instruction (L1, L2) and data caches
- Functional Units:
	- quad ALU's with dual result busses,
	- one flow control unit
	- eight floating point unit
	- three memory queues
- vector instructions

Monster64 can issue up to eight instructions in a single cycle (4 alu, 1 flow control, 8 floating point) and is capable of committing up to three instructions in a single cycle. Fetch and queue are limited to three instructions per cycle.

# History
Monster64 is a work-in-progress beginning in August 2017. Monster64 is an extension of FT64 which was July's core. FT64 originated from RiSC-16 by Dr. Bruce Jacob. RiSC-16 evolved from the Little Computer (LC-896) developed by Peter Chen at the University of Michigan. See the comment in FT64.v

# Software
Nothing yet.

