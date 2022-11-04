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
#	cc64 $(CFLAGS) SieveOfE.c
#	cc64 $(CFLAGS) os_stub.c

#	vasmrf68000_mot_win32.exe -Fvobj -L fibonacci.lst fibonacci.asm -o fibonacci.o
	vasmrf68000_mot_win32.exe -Fvobj -L LEDTest.lst LEDTest.asm -o LEDTest.o
	vasmrf68000_mot_win32.exe -Fvobj -L cputest.lst cputest.asm -o cputest.o
#	vasmrfPhoenix_std_win32.exe -Fvobj -L add.lst add.asm -o add.o
#	vlink -T rom_bios.cmd -brawbin1 fibonacci.o -o fibonacci.bin
	vlink -T rom_bios.cmd -brawbin1 LEDTest.o -o LEDTest.bin
	vlink -T rom_bios.cmd -brawbin1 cputest.o -o cputest.bin
#	vlink -T rom_bios.cmd -brawbin1 add.o -o add.bin
#	bin2ver fibonacci.bin 128
#	bin2ver LEDTest.bin 32 m
	bin2ver cputest.bin 32 m
#	bin2ver add.bin 128

