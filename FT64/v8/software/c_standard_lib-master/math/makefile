# Makefile for MATH
#
PATH = $PATH;D:\Cores5\FT64\v7\software\C64\C64\debug\;D:\Cores5\FT64\v7\software\A64\A64\debug\;D:\Cores5\FT64\v7\software\FPP\FPP\debug\;D:\Cores5\FT64\v7\software\APP\debug\;"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\Hostx64\x64"
FPPINC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
APPINC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
INC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
INCLUDE = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
#CCX = cc64
CFLAGS = -w -S
#CXX = cc64 -w -S 
ASMS =     acos.s \
           asin.s \
           atan.s \
           atan2.s \
           ceil.s \
           cos.s \
           cosh.s \
           exp.s \
           fabs.s \
           floor.s \
           fmod.s \
           frexp.s \
           ldexp.s \
           log.s \
           log10.s \
           modf.s \
           pow.s \
           sin.s \
           sinh.s \
           sqrt.s \
           tan.s \
           tanh.s \
           xasin.s \
           xatan.s \
           xdint.s \
           xdnorm.s \
           xdscale.s \
           xdtento.s \
           xdtest.s \
           xdunscal.s \
           xexp.s \
           xldunsca.s \
           xlog.s \
           xpoly.s \
           xsin.s \
           xvalues.s

all:	$(ASMS)
	echo "made MATH"

MATH:	$(ASMS)
	echo "made MATH"

.c.s:
	cc64 $(CFLAGS) $<

clean:
	del *.s
	del *.lis
	del *.c.xml
	del *.fpp
	del *.hir

