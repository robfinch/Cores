#	code
	# int abs(register int a)
_abs:
	# 	return a < 0 ? -a : a;
	      	   cmp  	r8,r0
	      	pl.inc  	r15,TestAbs_4-PC
	      	   not  	r1,r8,-1
	      	   inc  	r15,TestAbs_5-PC
TestAbs_4:
	      	   mov  	r1,r8
TestAbs_5:
	      	   mov  	r15,r13
	# int abs(register int a)
_min:
	# 	return a < b ? a : b;
	      	   cmp  	r8,r9
	      	pl.inc  	r15,TestAbs_11-PC
	      	   mov  	r1,r8
	      	   inc  	r15,TestAbs_12-PC
TestAbs_11:
	      	   mov  	r1,r9
TestAbs_12:
	      	   mov  	r15,r13
	# int abs(register int a)
_max:
	# 	return a > b ? a : b;
	      	   cmp  	r8,r9
	      	mi.inc  	r15,TestAbs_18-PC
	      	   cmp  	r8,r9
	      	 z.inc  	r15,TestAbs_18-PC
	      	   mov  	r1,r8
	      	   inc  	r15,TestAbs_19-PC
TestAbs_18:
	      	   mov  	r1,r9
TestAbs_19:
	      	   mov  	r15,r13
	# int abs(register int a)
_minu:
	# 	return a < b ? a : b;
	      	   cmp  	r8,r9
	      	nc.inc  	r15,TestAbs_24-PC
	      	   mov  	r1,r8
	      	   inc  	r15,TestAbs_25-PC
TestAbs_24:
	      	   mov  	r1,r9
TestAbs_25:
	      	   mov  	r15,r13
#	rodata
#	extern	_minu
#	extern	_abs
#	extern	_min
#	extern	_max
