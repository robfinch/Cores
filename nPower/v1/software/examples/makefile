
#

BIOS:
	del SieveOfE.bin
	del SieveOfE.lst
	del rom_bios.bin
	del rom_bios.lst
	vbccppc SieveOfE.c
#	vasmppc_std_win32 -L SieveOfE.lst -Fbin SieveOfE.asm
	vasmppc_std_win32 -Felf -L SieveOfE.lst SieveOfE.asm -o Sieve.out
	vbccppc rom_bios.c
#	vasmppc_std_win32 -L rom_bios.lst -Fbin rom_bios_start.asm
	vasmppc_std_win32 -Felf -L rom_bios.lst rom_bios_start.asm -o rom_bios.out
	vlink -T rom_bios.lnk rom_bios.out
#	ren a.out rom_bios.bin
	bin2ver rom_bios.bin 128

#	vasmppc_std_win32 -L SieveOfE.lst -Fbin SieveOfE.asm
#	vasmppc_std_win32 -L rom_bios.lst -Fbin rom_bios_start.asm

