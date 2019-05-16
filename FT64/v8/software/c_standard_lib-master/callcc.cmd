set path=$PATH;D:\Cores5\FT64\v7\software\C64\C64\debug\;D:\Cores5\FT64\v7\software\A64\A64\debug\;D:\Cores5\FT64\v7\software\FPP\FPP\debug\;D:\Cores5\FT64\v7\software\APP\debug\;"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\Hostx64\x64"
set FPPINC=d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\inc\
set APPINC=d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\inc\
rem 
nmake ASSERT
nmake CTYPE
nmake ERRNO
nmake FLOAT
nmake LOCALE
nmake MATH
# SETJMP needs more macros defined _JBFP, etc.
#nmake SETJMP
nmake SIGNAL
nmake STDIO
nmake STDLIB
nmake STRING
nmake TIME
cd ..\FMTK
nmake FMTK
