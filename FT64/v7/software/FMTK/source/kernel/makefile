# Makefile for FMTK
#
CXX = cc64 -w -S 
DIRS = drivers
ASMS = SetupDevices.s console.s FMTKc.s FMTKmsg.s IOFocusc.s pic.c pit.s TCB.s \
	DBGConsole.s DBGKeybd.s LockSemaphore.s UnlockSemaphore.s debugger.s

FMTK:	$(ASMS)
	echo Kernel built

.c.s:
	$(CXX) $<

#SetupDevices.s:	SetupDevices.c
#	$(CXX) SetupDevices.c >>FMTK.txt
#console.s:	console.c
#	$(CXX) console.c >>FMTK.txt
#FMTKc.s:	FMTKc.c
#	$(CXX) FMTKc.c >>FMTK.txt
#FMTKmsg.s:	FMTKmsg.c
#	$(CXX) FMTKmsg.c >>FMTK.txt
#IOFocusc.s:	IOFocusc.c
#	$(CXX) IOFocusc.c >>FMTK.txt
#pic.s:	pic.c
#	$(CXX) pic.c >>FMTK.txt
#pit.s:	pit.c
#	$(CXX) pit.c >>FMTK.txt
#TCB.s:	TCB.c
#	$(CXX) TCB.c >>FMTK.txt
#DBGConsole.s:	DBGConsole.c
#	$(CXX) DBGConsole.c >>FMTK.txt
#read.s:	read.c
#	$(CXX) read.c >>FMTK.txt
#write.s:	write.c
#	$(CXX) write.c >>FMTK.txt
#sleep.s:	sleep.c
#	$(CXX) sleep.c >>FMTK.txt
#misc.s:	misc.c
#	$(CXX) misc.c >>FMTK.txt

clean:
	del *.c.xml
	del *.fpp
	del *.lis
	del *.s
	del FMTK.txt
