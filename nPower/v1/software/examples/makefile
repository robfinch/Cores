
#

BIOS:
	del SieveOfE.bin
	del SieveOfE.lst
	del rom_bios.bin
	del rom_bios.lst
	vbccppc SieveOfE.c -c99 -O=31
	vbccppc rom_bios.c -c99 -O=31
	vbccppc os_stub.c -c99 -O=31 -ID:\cores2020\nPower\v1\software\inc
	copy rom_bios_start.asm +rom_bios.asm +SieveOfE.asm +c_standard_lib.asm +os_stub.asm build.asm
	secsrt build.asm	
#	vasmppc_std_win32 -L SieveOfE.lst -Fbin SieveOfE.asm
#	vasmppc_std_win32 -Fbin -L SieveOfE.lst SieveOfE.asm -o Sieve.out
#	vasmppc_std_win32 -Fbin -L rom_bios.lst rom_bios_start.asm -o rom_bios.bin
	vasmppc_std_win32 -maxerrors=0 -Felf -L build.lst secsorted.asm -o rom_bios.elf
	vlink -Trom_bios.cmd -brawbin1 rom_bios.elf
	ren a.out rom_bios.bin
	bin2ver rom_bios.bin 128

#	vasmppc_std_win32 -L SieveOfE.lst -Fbin SieveOfE.asm
#	vasmppc_std_win32 -L rom_bios.lst -Fbin rom_bios_start.asm

