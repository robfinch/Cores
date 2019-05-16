rem This is a Powershell script file.
rem This is provided as a sample of how to compile and assemble files using CC64 and AS64.
rem This batch file compiles everything then assembles it into an image suitable to be used as
rem initialization data for system ROM. The final output product is a file called "boot.ve0"
rem
set path=$PATH;D:\Cores5\FT64\v7\software\C64\C64\debug\;D:\Cores5\FT64\v7\software\A64\A64\debug\;D:\Cores5\FT64\v7\software\FPP\FPP\debug\;D:\Cores5\FT64\v7\software\APP\debug\;"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\Hostx64\x64"
rem set path=$PATH;"C:\Program Files (x86)\Finitron\C64\C64\";C:\Cores5\FT64\trunk\software\A64\A64\debug\
set FPPINC=d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc\
set APPINC=d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc\
CC64 -w -S .\cc64libc\source\gc.c
CC64 -w -S .\cc64libc\source\cc64rt.c
CC64 -w -S .\boot\BIOSMain.c
CC64 -w -S .\boot\FloatTest.c
CC64 -w -S .\boot\ramtest.c
CC64 -w -S .\boot\HexLoader.c
CC64 -w -S .\boot\S19Loader.c
CC64 -w -S .\boot\FT64TinyBasic.c
CC64 -w -S .\test\SieveOfE.c
CC64 -w -S .\cc64libc\source\malloc.c
rem CC64 -w -S .\cc64libc\source\stdio.c
cd cc64libc
cd source
nmake /C cc64libc
cd ..
cd ..
CC64 -w -S .\cc64libc\source\FT64\io.c
CC64 -w -S .\cc64libc\source\FT64\getCPU.c
CC64 -w -S .\cc64libc\source\libquadmath\log10q.c
cd .\FMTK
nmake /C FMTK
cd ..
CC64 -w -S set_time_serial.c highest_data_word.c
CC64 -w -S sd_controller.c sdc_test.c mainpred.c
#AS64 +gG .\boot\boot.asm
AS64 +gFmg .\boot\GPU.asm
AS64 +gFn .\boot\boottc.asm

