#
PATH = $PATH;D:\cores2022\Thor\software\CC64\cc64\debug;"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.28.29333\bin\Hostx64\x64\bin\Hostx64\x64\"
INC = D:\cores2022\Thor\software\source\;D:\cores2022\Thor\software\FMTK\source\kernel\;D:\cores2022\Thor\software\inc\
INCLUDE = D:\cores2022\Thor\software\source\;D:\cores2022\Thor\software\FMTK\source\kernel\;D:\cores2022\Thor\software\inc\
FPPINC  = D:\cores2022\Thor\software\source\;D:\cores2022\Thor\software\FMTK\source\kernel\;D:\cores2022\Thor\software\inc\
CXX = cc64
#CXX = opt
CFLAGS2 = -c99 -ID:\cores2022\Thor\software\inc\ -O=31
CFLAGS = -w -S -fno-exceptions

#

BIOS:
	del boot_rom.bin
	del boot_rom.lst
	del rom1.mem
	del rom2.mem
	del rom3.mem
	del rom4.mem
	del rom5.mem
	del rom6.mem
	del rom7.mem
#	cc64 $(CFLAGS) SieveOfE.c
#	cc64 $(CFLAGS) os_stub.c

#	vasmrf68000_mot_win32.exe -Fvobj -L fibonacci.lst fibonacci.asm -o fibonacci.o
	vasmrf68000_mot_win32.exe -Fvobj -L LEDTest.lst LEDTest.asm -o LEDTest.o
	vasmrf68000_mot_win32.exe -Fvobj -L cputest.lst cputest.asm -o cputest.o
	vasmrf68000_mot_win32.exe -Fvobj -L boot.lst boot.asm -o boot.o -m68010
#	vasmrfPhoenix_std_win32.exe -Fvobj -L add.lst add.asm -o add.o
#	vlink -T rom_bios.cmd -brawbin1 fibonacci.o -o fibonacci.bin
#	vlink -T rom_bios.cmd -brawbin1 LEDTest.o -o LEDTest.bin
#	vlink -T rom_bios.cmd -brawbin1 cputest.o -o cputest.bin
	vlink -T rom_bios.cmd -bsrec37 boot.o -o boot.s37
	vlink -T rom_bios.cmd -brawbin1 boot.o -o boot.bin
#	vlink -T rom_bios.cmd -brawbin1 add.o -o add.bin
#	bin2ver fibonacci.bin 128
#	bin2ver LEDTest.bin 32 m
	bin2ver boot.bin 32 m
	copy rom.mem rom1.mem
	copy rom.mem rom2.mem
	copy rom.mem rom3.mem
	copy rom.mem rom4.mem
	copy rom.mem rom5.mem
	copy rom.mem rom6.mem
	copy rom.mem rom7.mem
#	bin2ver cputest.bin 32 m
#	bin2ver add.bin 128

