	code
_abs:
	# 	return a < 0 ? -a : a;
	      	cmp  	r8,r0,0
	      	mi.not  	r1,r8,0
	      	mi.add  	r1,r0,1
	      	pl.mov  	r1,r8
	      	mov  	r15,r13,0
_min:
	# 	return a < b ? a : b;
	      	cmp  	r8,r9,0
	      	mi.mov  	r1,r8
	      	pl.mov  	r1,r9
	      	mov  	r15,r13,0
_max:
	# 	return a > b ? a : b;
	      	cmp  	r8,r9,0
	      	mi.mov  	r1,r8
	      	pl.mov  	r1,r9
	      	mov  	r15,r13,0
_minu:
	# 	return a < b ? a : b;
	      	cmp  	r8,r9,0
	      	c.mov  	r1,r8
	      	nc.mov  	r1,r9
	      	mov  	r15,r13,0
	rodata
	extern	_minu
	extern	_abs
	extern	_min
	extern	_max
