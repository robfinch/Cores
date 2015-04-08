set INCLUDE=c:\Cores3\FISA64\trunk\software\source\;c:\Cores3\FISA64\trunk\software\FMTK\source\kernel\
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\FMTKc.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\IOFocusc.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\console.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\PIC.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\stdio.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\ctype.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\string.c
c64 -pFISA64 -w -fno-exceptions debugger.c disassem.c
a64 +g6 bootrom.s
