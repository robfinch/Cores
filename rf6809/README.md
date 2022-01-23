# rf6809 Overview

rf6809 is a 6809 instruction set and programming model compatible core. The addressable memory range has been increased to 24-bits or three bytes.
There are minimal changes to the programming model and instruction set to support 24-bit addressing.
The core is configurable for either eight or twelve bit bytes. When configured for 12-bit bytes addressing is increased to 36-bits.

# Unusual Features
## 12-bit Bytes
The core may be configured to use 12-bit bytes. This increases the effective address range of the core.

## Instruction cache
There is a 4kB instruction cache. The cache can supply all the bytes of an instruction in one clock cycle improving performance.

## Pipeline
The pipeline is non-overlapped except that the writeback stage is performed during the instruction fetch stage of the next instruction.

## Asynchronous Readback Cycles
The core may be configured for asynchronous readback for instruction cache read cycles. With async. readback there may be multiple outstanding read requests made by the processor before any read data is returned to it. The read data may return out-of-order with respect to the read requests. Re-ordering is handled using a four-bit address tag returned along with the read data. Async readback offers higher performance than synchronous readback.

# Differences from the 6809
## Registers
There is an additional 16-bit register USPPG that allows the user stack pointer to be placed at any page of memory. The system stack pointer must remain within the lowest 16-bits of the address range.
The program counter is a full 24-bit register. The JMP and JSR instructions modify only the low order 16 bits of the program counter. To modify the full 24-bits use the JMP FAR and JSR FAR instructions. A return from a far subroutine may be done using the RTF instruction.

## Operations
During interrupt processing the entire 24-bit program counter is stacked. The RTI instruction also loads the entire 24-bit program counter.
Far addressing makes use of two previously unused codes in the indexing byte of an instruction.
No attempt was made to mimic the 6809 bus cycle activity. Some instructions execute in fewer clock cycles than they would for a 6809. For example branches only require two clock cycles.
Indirect addresses must reside within the first 64k bank of memory.
## Exception Vectors
The vectors are located beginning at $FFFFF0. It is possible to keep a set of vectors at the original address then perform an indirect jump to through the originally placed vectors from one of the vector processing routines.
## For the 12-bit Version
The PG2 and PG3 prefix bytes are not needed. The prefix is incorporated in extra bits available in the 12-bit opcode.
Prefix 10h becomes opcode 1xxh, prefix 11h becomes opcode 2xxh.

# Additional Instructions

Additional instructions and prefixes make use of previously unused opcodes.

**JMP FAR** – performs a jump using a 24-bit extended address.
Opcode: 0x8F

**JSR FAR** – performs a jump to subroutine using a 24-bit extended address. The full 24-bit program counter is stored on the stack.
Opcode: 0xCF

**RTF** – performs a far return from subroutine by loading a full 24-bit program counter from the stack.
Opcode: 0x38


## Instruction Prefixes

**FAR**
FAR when applied to extended addressing indicates to use a full 24-bit address rather than a 16 bit one.
When the FAR prefix is applied to indirect addressing the prefix indicates that the indirect address is 24-bit. This allows the use of a 24-bit indirect address to reach anywhere in memory.
The FAR prefix must be applied to a PUSH / PULL instruction to get the full 24-bit program counter pushed or pulled. Otherwise only the low order 16-bits of the PC are used.
Opcode: 0x15

**OUTER**
The OUTER prefix indicates that the index register is applied after retrieving an indirect address. Normally the index register is used in the calculation of the indirect address.
Opcode: 0x1B
For the twelve-bit byte version of the core the OUTER prefix is not used as there is room in the index postbyte to indicate outer indexing.

# Size
The core is approximately 4200 LUTs or 2100 slices and uses 4 block rams for the instruction cache.
Core size is approximately 6500 LUTs / 5 block rams for the 12-bit version.

# Software
Software is in the works along with hardware.
There is a modified version of the A09 assembler which supports twelve-bit bytes and far addressing.
There is a modified version of the hc12 VBCC compiler which also is for twelve bit-bytes.


# Test Project
There is a small system-on-chip setup for the CmodA7 FPGA board. The system includes the cpu core, an acia and via. Communication is via the serial port at 9600 baud.
The rf6809 is used in a another test project. Multiple rf6809 cores are networked together in a ring topology using a parallel bus.
