# FT68000
robfinch<remove>@finitron.ca

# Overview
FT68000 is Finitron’s rendition of a 68000 similar core. It features all the instructions, opcode and addressing modes of the 68k with only minor differences. Differences are outlined in the FT68000.docx document. The instruction formats are similar enough to the 68k’s to make it possible to leverage existing software for use with the FT68000.
The most significant difference from the 68000 is the use of tasks to handle exceptional conditions. The vector table contains task identifiers rather than program counter vectors.
The FT68000 supports high-speed hardware multi-tasking. The program visible register state is stored in an internal task state memory. Loading or storing the entire register set is a single cycle operation. Task switching may be done in fewer than 10 cycles (exact timing TBD).
