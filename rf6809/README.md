# rf6809

rf6809 is a 6809 instruction set and programming model compatible core. The addressable memory range has been increased to 24-bits.
There are minimal changes to the programming model and instruction set to support 24-bit addressing.

# Differences from the 6809
There is an additional 16-bit register USPPG that allows the user stack pointer to be placed at any page of memory. The system stack pointer must remain within the lowest 16-bits of the address range.
The program counter is a full 24-bit register. The JMP and JSR instructions modify only the low order 16 bits of the program counter. To modify the full 24-bits use the JMP FAR and JSR FAR instructions. A return from a far subroutine may be done using the RTF instruction.
During interrupt processing the entire 24-bit program counter is stacked. The RTI instruction also loads the entire 24-bit program counter.
Far addressing makes use of two previously unused codes in the indexing byte of an instruction.
No attempt was made to mimic the 6809 bus cycle activity. Some instructions execute in fewer clock cycles than they would for a 6809.
Indirect addresses must reside within the first 64k bank of memory.
The core includes a small instruction cache to improve performance.

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

# Size
The core is approximately 4200 LUTs or 2100 slices and uses 4 block rams for the instruction cache.


