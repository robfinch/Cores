set INCLUDE=c:\Cores3\FISA64\trunk\software\source\
c64 -pFISA64 -w -fno-exceptions FMTKc.c console.c debugger.c disassem.c stdio.c
c64 -pFISA64 -w -fno-exceptions ctype.c IOFocusc.c
a64 +g6 bootrom.s

