# FTFM - Finitron Forth Machine

FTFM is an in-order superscalar stack machine executing a subset of the Forth language which is currently in development. It can execute up to five instructions per clock cycle.

# History
This project is just started Jan 2018. After reading about the Bugs18 machine and reviewing the J1.

# Instructions
Instructions are five bits in size. Five instructions are bundled together in a 27 (3x9 bits) bit wide memory cell.
The top bit of the bundle indicates that a 26 bit sign extended literal constant occupies the remainder of the bundle.
The program counter only addresses bundles. The program counter is fifteen bits wide, allowing access to 32k words of memory. All instructions in the bundle execute as a unit.
Fetch, store, jump, and call instructions must be located in the first slot of the bundle. Jump and call instructions occupy four of the five slots in a bundle and include the target address as part of the instruction.

nop
@		fetch
!		store
>r
r>
r@
2/		asr
		shl
		shr
dup
over
drop
+		add
&		and
|		or
^		xor
*		mul
~		inv	(invert)
; 		ret
jz		jz
j		jmp
p		call
		lit

Note it is possible to perform multi-level returns by placing the ret instruction in more than one slot of the bundle.
