# Makefile for FMTK
#
CXX = cc64 -w -S 

ASMS = app.s monitor.s disassem.s OSCall.s memmgnt2.s memmgnt3.s shell.s \
	open.s close.s read.s write.s sleep.s misc.s

FMTK:	$(ASMS)
	echo FMTK source built
	cd drivers
	nmake /C FMTK
	cd ..
	cd kernel
	nmake /C FMTK
	cd ..

.c.s:
	$(CXX) $<

clean:
	del *.c.xml
	del *.fpp
	del *.lis
	del *.s
	del FMTK.txt
