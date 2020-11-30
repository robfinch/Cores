# Makefile for FMTK
#
PATH = $PATH;D:\cores2020\rtf64\v2\software\CC64\C64\debug\;D:\cores2020\rtf64\v2\software\AS64\A64\debug\;D:\cores2020\rtf64\v2\software\FPP\FPP\debug\;D:\cores2020\rtf64\v2\software\APP\debug\
FPPINC = D:\cores2020\rtf64\v2\software\source\;D:\cores2020\rtf64\v2\software\FMTK\source\kernel\;D:\cores2020\rtf64\v2\software\inc
APPINC = D:\cores2020\rtf64\v2\software\source\;D:\cores2020\rtf64\v2\software\FMTK\source\kernel\;D:\cores2020\rtf64\v2\software\inc
INC = D:\cores2020\rtf64\v2\software\source\;D:\cores2020\rtf64\v2\software\FMTK\source\kernel\;D:\cores2020\rtf64\v2\software\inc
INCLUDE = D:\cores2020\rtf64\v2\software\source\;D:\cores2020\rtf64\v2\software\FMTK\source\kernel\;D:\cores2020\rtf64\v2\software\inc
CXX = cc64 -w -S 

CFLAGS = -w -S 

ASMS = app.s disassem.s OSCall.s shell.s \
	open.s close.s read.s write.s sleep.s misc.s memmgnt3.s

FMTK:	$(ASMS)
	echo FMTK source built
	cd drivers
	$(MAKE) /C FMTK
	move drivers.l64 ..
	cd ..
	cd kernel
	$(MAKE) /C FMTK
	move kernel.l64 ..
	cd ..
	copy *.r64 source.l64
	copy *.l64 fmtk.l64

.c.s:
	cc64 $(CFLAGS) $<

clean:
	cd drivers
	nmake /C clean
	cd ..
	cd kernel
	nmake /C clean
	cd ..
	del *.c.xml
	del *.fpp
	del *.lis
	del *.s
	del FMTK.txt
