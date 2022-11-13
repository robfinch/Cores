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

TinyBasic:
	vasmrf68000_mot_win32.exe -Fvobj -L TinyBasic.lst TinyBasic.asm -o TinyBasic.o
	vlink -T TinyBasic.cmd -bsrec37 TinyBasic.o -o TinyBasic.s37

