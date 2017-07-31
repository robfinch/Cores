	code
	align	16
_abs:
	# 	return a < 0 ? -a : a;
	      	cmp  	r8,r0,0
	      	pl.mov  	r15,r0,TestAbs_4
TestAbs_6:
	      	not  	r1,r8,0
	      	add  	r1,r0,1
	      	mov  	r2,r1
	      	mov  	r15,r0,TestAbs_5
TestAbs_4:
	      	mov  	r2,r8
TestAbs_5:
	      	mov  	r1,r2,0
TestAbs_7:
	      	mov  	r15,r13,0
_min:
	# 	return a < b ? a : b;
	      	cmp  	r8,r9,0
	      	pl.mov  	r15,r0,TestAbs_11
TestAbs_13:
	      	mov  	r1,r8
	      	mov  	r15,r0,TestAbs_12
TestAbs_11:
	      	mov  	r1,r9
TestAbs_12:
TestAbs_14:
	      	mov  	r15,r13,0
_max:
	# 	return a > b ? a : b;
	      	cmp  	r8,r9,0
	      	mi.mov  	r15,r0,TestAbs_18
	      	z.mov  	r15,r0,TestAbs_18
	      	mov  	r1,r8
	      	mov  	r15,r0,TestAbs_19
TestAbs_18:
	      	mov  	r1,r9
TestAbs_19:
TestAbs_20:
	      	mov  	r15,r13,0
_minu:
	# 	return a < b ? a : b;
	      	cmp  	r8,r9,0
	      	nc.mov  	r15,r0,TestAbs_24
TestAbs_26:
	      	mov  	r1,r8
	      	mov  	r15,r0,TestAbs_25
TestAbs_24:
	      	mov  	r1,r9
TestAbs_25:
TestAbs_27:
	      	mov  	r15,r13,0
	rodata
	align	16
	extern	_minu
	extern	_abs
	extern	_min
	extern	_max
