
#

BIOS:
	del SieveOfE.bin
	del SieveOfE.lst
	del rom_bios.bin
	del rom_bios.lst
	vbccppc SieveOfE.c
	vasmppc_std_win32 -L SieveOfE.lst -Fbin SieveOfE.asm
	vbccppc rom_bios.c
	vasmppc_std_win32 -L rom_bios.lst -Fbin rom_bios_start.asm
	ren a.out rom_bios.bin
	bin2ver rom_bios.bin 128
