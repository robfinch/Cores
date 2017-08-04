#	code
_abs:
	# 	return a < 0 ? -a : a;
	      	   cmp  	r8,r0
	      	mi.inc  	r15,TestAbs_4-PC
	      	   not  	r1,r8,-1
	      	   inc  	r15,TestAbs_5-PC
TestAbs_4:
	      	   mov  	r1,r8
TestAbs_5:
	      	   mov  	r15,r13
_min:
	# 	return a < b ? a : b;
	      	   cmp  	r8,r9
	      	mi.inc  	r15,TestAbs_10-PC
	      	   mov  	r1,r8
	      	   inc  	r15,TestAbs_11-PC
TestAbs_10:
	      	   mov  	r1,r9
TestAbs_11:
	      	   mov  	r15,r13
_max:
	# 	return a > b ? a : b;
	      	   cmp  	r8,r9
	      	 z.inc  	r15,TestAbs_18-PC
	      	   cmp  	r8,r9
	      	pl.inc  	r15,TestAbs_16-PC
TestAbs_18:
	      	   mov  	r1,r8
	      	   inc  	r15,TestAbs_17-PC
TestAbs_16:
	      	   mov  	r1,r9
TestAbs_17:
	      	   mov  	r15,r13
_minu:
	# 	return a < b ? a : b;
	      	   cmp  	r8,r9
	      	 c.inc  	r15,TestAbs_23-PC
	      	   mov  	r1,r8
	      	   inc  	r15,TestAbs_24-PC
TestAbs_23:
	      	   mov  	r1,r9
TestAbs_24:
	      	   mov  	r15,r13
#	rodata
#	extern	_minu
#	extern	_abs
#	extern	_min
#	extern	_max
