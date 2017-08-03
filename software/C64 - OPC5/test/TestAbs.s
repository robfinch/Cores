	code
_abs:
	# 	return a < 0 ? -a : a;
	      	   cmp  	r8,r0,0
	      	pl.mov  	r15,r0,TestAbs_4
	      	   not  	r1,r8
	      	   add  	r1,r0,1
	      	   mov  	r15,r0,TestAbs_5
TestAbs_4:
	      	   mov  	r1,r8
TestAbs_5:
TestAbs_7:
	      	   mov  	r15,r13
	      	   mov  	r15,r0,TestAbs_7
_min:
	# 	return a < b ? a : b;
	      	   cmp  	r8,r9
	      	pl.mov  	r15,r0,TestAbs_11
	      	   mov  	r1,r8
	      	   mov  	r15,r0,TestAbs_12
TestAbs_11:
	      	   mov  	r1,r9
TestAbs_12:
TestAbs_14:
	      	   mov  	r15,r13
	      	   mov  	r15,r0,TestAbs_14
_max:
	# 	return a > b ? a : b;
	      	   cmp  	r8,r9
	      	mi.mov  	r15,r0,TestAbs_18
	      	   cmp  	r8,r9
	      	 z.mov  	r15,r0,TestAbs_18
	      	   mov  	r1,r8
	      	   mov  	r15,r0,TestAbs_19
TestAbs_18:
	      	   mov  	r1,r9
TestAbs_19:
TestAbs_20:
	      	   mov  	r15,r13
	      	   mov  	r15,r0,TestAbs_20
_minu:
	# 	return a < b ? a : b;
	      	   cmp  	r8,r9
	      	nc.mov  	r15,r0,TestAbs_24
	      	   mov  	r1,r8
	      	   mov  	r15,r0,TestAbs_25
TestAbs_24:
	      	   mov  	r1,r9
TestAbs_25:
TestAbs_27:
	      	   mov  	r15,r13
	      	   mov  	r15,r0,TestAbs_27
	rodata
	extern	_minu
	extern	_abs
	extern	_min
	extern	_max
