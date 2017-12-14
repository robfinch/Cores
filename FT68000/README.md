# FT68000 / FT68000x16
robfinch<remove>@finitron.ca

# Overview
FT68000 is Finitron’s rendition of a 68000 similar core. It features all the instructions, opcode and addressing modes of the 68k with only minor differences. Differences are outlined in the FT68000.docx document. The instruction formats are similar enough to the 68k’s to make it possible to leverage existing software for use with the FT68000.
The most significant difference from the 68000 is the use of tasks to handle exceptional conditions. The vector table contains task identifiers rather than program counter vectors.
The FT68000 supports high-speed hardware multi-tasking. The program visible register state is stored in an internal task state memory. Loading or storing the entire register set is a single cycle operation. Task switching may be done in fewer than 10 cycles (exact timing TBD).
FT68000 stores data in little-endian format where the least significant byte of data is at the lowest address. This is opposite to the MC68k's big-endian data storage.

## Task Number and Code Addresses
Code addresses are always even as the processor works with 16 bit instruction parcels. So task numbers are always odd so that tasks may be distinguished from code addresses by several of the instructions. Task numbers vary between 1 and 1023.

## CSR - Control and Status Registers
There are some additional CSR's associated with the FT68k. CSR's are accessed using the move.l instruction and are located in the memory range $FFFFC000 to $FFFFFFFF. Note that the CSR's are not actually stored in memory but instead are stored in registers within the core.

#Instructions

## DIVS and DIVU
DIVS and DIVU use a long word divisor and perform a 32/32 divide rather than a 32/16 divide.

## JMP and JSR
JMP and JSR can transfer processing to another task by specifying a task number rather than a code address. The difference between a jmp and jsr is that jsr stores the outgoing task number on the incooming task's stack and jump does not.

## LTSK
LTSK is a new instruction that loads the task registers identified by the task number in the d0 register. This instruction does not cause a task switch.

## RTS
RTS can recognize that a task number has been stacked on the stack and return to the task.

## STSK
STSK is a new instruction that stores the task registers identified by the task number in the d0 register. This instruction does not cause a task switch.

## Trap
The trap instruction can jump to any of 512 task vectors. There are 15 "quick" traps, corresponding to the traps 1 to 15 on the 68k.
