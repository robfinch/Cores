# This is a Powershell script file.
# This is provided as a sample of how to compile and assemble files using CC64 and AS64.
# This batch file compiles everything then assembles it into an image suitable to be used as
# initialization data for system ROM. The final output product is a file called "boot.ve0"
#
set path=$PATH;C:\Cores5\FT64\trunk\software\C64\C64\debug\;C:\Cores5\FT64\trunk\software\A64\A64\debug\;C:\Cores5\FT64\trunk\software\FPP\FPP\debug\;C:\Cores5\FT64\trunk\software\APP\debug\
# set path=$PATH;"C:\Program Files (x86)\Finitron\C64\C64\";C:\Cores5\FT64\trunk\software\A64\A64\debug\
set FPPINC=c:\Cores5\FT64\trunk\software\source\;c:\Cores5\FT64\trunk\software\FMTK\source\kernel\
set APPINC=c:\Cores5\FT64\trunk\software\source\;c:\Cores5\FT64\trunk\software\FMTK\source\kernel\
CC64 -w -S .\c64libc\source\cc64rt.c
CC64 -w -S .\boot\BIOSMain.c
CC64 -w -S .\boot\FloatTest.c
CC64 -w -S .\boot\ramtest.c
CC64 -w -S .\FMTK\source\kernel\FMTKc.c
CC64 -w -S .\FMTK\source\kernel\FMTKmsg.c
CC64 -w -S .\FMTK\source\kernel\TCB.c
CC64 -w -S .\FMTK\source\kernel\IOFocusc.c
CC64 -w -S .\FMTK\source\kernel\console.c
CC64 -w -S .\FMTK\source\kernel\keybd.c
CC64 -w -S .\FMTK\source\kernel\PIC.c
CC64 -w -S .\FMTK\source\kernel\LockSemaphore.c
CC64 -w -S .\FMTK\source\kernel\UnlockSemaphore.c
CC64 -w -S .\FMTK\source\app.c
CC64 -w -S .\FMTK\source\shell.c
CC64 -w -S .\FMTK\source\memmgnt2.c
CC64 -w -S .\c64libc\source\malloc.c
CC64 -w -S .\c64libc\source\stdio.c
CC64 -w -S .\c64libc\source\ctype.c
CC64 -w -S .\c64libc\source\string.c
CC64 -w -S .\c64libc\source\prtflt.c
CC64 -w -S .\c64libc\source\gfx.c
CC64 -w -S .\c64libc\source\FT64\io.h
CC64 -w -S .\c64libc\source\libquadmath\log10q.c
CC64 -w debugger.c disassem.c set_time_serial.c highest_data_word.c
CC64 -w sd_controller.c sdc_test.c mainpred.c
#AS64 +gG .\boot\boot.asm
AS64 +gFn .\boot\boottc.asm
