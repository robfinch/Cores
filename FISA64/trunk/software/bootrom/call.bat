set INCLUDE=c:\Cores3\FISA64\trunk\software\source\;c:\Cores3\FISA64\trunk\software\FMTK\source\kernel\
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\FMTKc.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\FMTKmsg.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\TCB.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\IOFocusc.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\console.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\keybd.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\PIC.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\LockSemaphore.c
c64 -pFISA64 -w -fno-exceptions ..\FMTK\source\kernel\UnlockSemaphore.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\stdio.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\ctype.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\string.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\FISA64\getCPU.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\FISA64\outb.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\FISA64\outc.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\FISA64\outh.c
c64 -pFISA64 -w -fno-exceptions ..\c64libc\source\FISA64\outw.c
c64 -pFISA64 -w -fno-exceptions debugger.c disassem.c set_time_serial.c
a64 +g6 bootrom.s
