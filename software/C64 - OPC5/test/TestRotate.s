	code
_TestRotate:
	      	sub  	r14,r0,1
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	return ((a << b) | (a >> (16-b));
	      	ld   	r1,r12,1
	      	ld   	r2,r12,2
TestRotate_4:
	      	add  	r1,r0,0
	      	sub  	r2,r0,1
	      	nz.mov  	r15,r0,TestRotate_4
	      	ld   	r2,r12,1
	      	mov  	r5,r0,16
	      	ld   	r6,r12,2
	      	sub  	r5,r6,0
TestRotate_5:
	      	add  	r2,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	ror  	r2,r0,0
	      	sub  	r5,r0,1
	      	nz.mov  	r15,r0,TestRotate_5
	      	or   	r1,r2,0
TestRotate_6:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,1
	      	mov  	r15,r13,0
_TestRotate2:
TestRotate_10:
	      	add  	r8,r0,0
	      	sub  	r9,r0,1
	      	nz.mov  	r15,r0,TestRotate_10
	      	mov  	r1,r0,16
	      	sub  	r1,r9,0
TestRotate_11:
	      	add  	r8,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	ror  	r8,r0,0
	      	sub  	r1,r0,1
	      	nz.mov  	r15,r0,TestRotate_11
	      	or   	r1,r8,0
TestRotate_12:
	      	mov  	r15,r13,0
	rodata
	extern	_TestRotate
	extern	_TestRotate2
