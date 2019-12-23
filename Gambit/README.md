# Gambit
52-bit processor

## Features
- 52-bit datapath
- variable length instructions (13,26,39 or 52 bits)
- 32 entry general purpose register file
-  8 compare results registers
- two-way instruction fetch

## Motivation:
	Made for a friend / associate. Specially requested at 52 bits width. A 52 bit processor is about 20% smaller than a 64-bit one. It may allow some cost reduction over a 64-bit processor.

## Approach
	A 52-bit processing core is challenging in several ways. 52 is not an even power of two, which most other processors are. That means standard memories and components must be adapted for use. The approach used here is a 13-bit byte. For the test ROM a 16 bit wide "byte" was used from which only 13 bits were mapped for use internally by the core. This allows assembler software to generate 16-bit values of which only 13-bits are significant for processing.

## Instruction Set
	Instructions are one of 13,26,39 or 52 bits in size.
	v5 uses an additional opcode bit to allow more opcodes at a root level. This has shifted the register fields over by a bit and shortened the constant field by a bit.
	v5 also uses compare result registers rather than a status register or general purpose registers. The compare results registers are two bits wide, allowing the storage of -1,0, or +1, representing less than, equal, or greater than. The compare results registers may also store a true/false value generated from a set instruction.
	There is room in the instruction set for some basic floating point operations (FADD,FSUB,FMUL,FDIV).
	Load / store instructions allow only for full 52-bit word, or 13-bit byte sizes.
	Interruptible string instructions (move set and compare) are present.



