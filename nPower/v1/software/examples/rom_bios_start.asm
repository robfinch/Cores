
_start:
	lis		r1,0xff40
	addi	r1,r1,0x0ffc
	bl		_main
	.include "rom_bios.asm"	
	.include "SieveOfE.asm"
