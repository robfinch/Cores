# Makefile for cc64libc
#
CXX = cc64 -w -S 

ASMS = _aacpy.s dbg_stdio.s putch.s putnum.s puthexnum.s ctype.s string.s prtflt.s \
				gfx.s gfx_demo.s

cc64libc:	$(ASMS)
	echo cc64libc source built

.c.s:
	$(CXX) $<

clean:
	del *.c.xml
	del *.fpp
	del *.lis
	del *.s
