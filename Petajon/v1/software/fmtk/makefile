# Makefile for FMTK
#
PATH = $PATH;D:\Cores6\Petajon\v1\software\CC64\C64\debug\;D:\Cores6\Petajon\v1\software\AS80\A64\debug\;D:\Cores6\Petajon\v1\software\FPP\FPP\debug\;D:\Cores6\Petajon\v1\software\APP\debug\;"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\Hostx64\x64"
FPPINC = d:\Cores6\Petajon\v1\software\source\;d:\Cores6\Petajon\v1\software\FMTK\source\kernel\;d:\Cores6\Petajon\v1\software\inc
APPINC = d:\Cores6\Petajon\v1\software\source\;d:\Cores6\Petajon\v1\software\FMTK\source\kernel\;d:\Cores6\Petajon\v1\software\inc
INC = d:\Cores6\Petajon\v1\software\source\;d:\Cores6\Petajon\v1\software\FMTK\source\kernel\;d:\Cores6\Petajon\v1\software\inc
INCLUDE = d:\Cores6\Petajon\v1\software\source\;d:\Cores6\Petajon\v1\software\FMTK\source\kernel\;d:\Cores6\Petajon\v1\software\inc
CXX = cc64 -w -S 

all:
	cd source
	nmake /C FMTK
	cd ..

FMTK:
	cd source
	nmake /C FMTK
	cd ..

clean:
	cd source
	nmake /C clean
	cd ..
	del FMTK.txt

