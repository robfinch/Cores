#
PATH = $PATH;D:\cores2020\nPower\v1\software\CC64\vbcc\bin\;"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.28.29333\bin\Hostx64\x64\bin\Hostx64\x64\"
INC = D:\cores2020\nPower\v1\software\source\;D:\cores2020\nPower\v1\software\FMTK\source\kernel\;D:\cores2020\nPower\v1\software\inc\
INCLUDE = D:\cores2020\nPower\v1\software\source\;D:\cores2020\nPower\v1\software\FMTK\source\kernel\;D:\cores2020\nPower\v1\software\inc\
CXX = vbccppc
CFLAGS = -c99 -ID:\cores2020\nPower\v1\software\inc\ -O=31

#

BIOS:
	del bios_pam.asm
	vbccppc $(CFLAGS) bios_pam.c
	vbccppc $(CFLAGS) rom_bios.c
	vbccppc $(CFLAGS) SieveOfE.c
	vbccppc $(CFLAGS) os_stub.c
	copy rom_bios_start.asm +rom_bios.asm +SieveOfE.asm +c_standard_lib.asm +os_stub.asm +bios_pam.asm +..\fmtk\source\kernel\DBGConsole.asm build.asm
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

