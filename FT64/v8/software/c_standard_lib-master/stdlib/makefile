# Makefile for STDLIB
#
PATH = $PATH;D:\Cores5\FT64\v7\software\C64\C64\debug\;D:\Cores5\FT64\v7\software\A64\A64\debug\;D:\Cores5\FT64\v7\software\FPP\FPP\debug\;D:\Cores5\FT64\v7\software\APP\debug\;"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\Hostx64\x64"
FPPINC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
APPINC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
INC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
INCLUDE = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
#CCX = cc64
CFLAGS = -w -S
#CXX = cc64 -w -S 
ASMS = \
	abort.s \
	abs.s \
	atexit.s \
	atof.s \
	atoi.s \
	atol.s \
	bsearch.s \
	calloc.s \
	div.s \
	exit.s \
	free.s \
	getenv.s \
	labs.s \
	ldiv.s \
	malloc.s \
	mblen.s \
	mbstowcs.s \
	mbtowc.s \
	qsort.s \
	rand.s \
	realloc.s \
	srand.s \
	strtod.s \
	strtol.s \
	strtoul.s \
	system.s \
	wcstombs.s \
	wctomb.s \
	xgetmem.s \
	xmbtowc.s \
	xstod.s \
	xstoul.s
           
all:	$(ASMS)
	echo "made STDLIB"

STDLIB:	$(ASMS)
	echo "made STDLIB"

.c.s:
	cc64 $(CFLAGS) $<

clean:
	del *.s
	del *.lis
	del *.c.xml
	del *.fpp
	del *.hir
