# Makefile for FMTK
#
CXX = cc64 -w -S 
ASMS = null_driver.s keybd_driver.s pti_driver.s prng_driver.s sdc_driver.s
FMTK:	$(ASMS)
	echo "made drivers"

.c.s:
	$(CXX) $<

clean:
	del FMTK.txt
	del null_driver.s
	del keybd_driver.s
	del pti_driver.s
	del prng_driver.s
	del sdc_driver.s
	del *.lis
	del *.c.xml
	del *.fpp
