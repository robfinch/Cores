#	code
	# int TestRotate(int a, int b)
_TestRotate:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return ((a << b) | (a >> (16-b)));
	      	   ld   	r5,r12,1
	      	   ld   	r6,r12,2
TestRotate_4:
	      	   add  	r5,r0,0
	      	   sub  	r6,r0,1
	      	nz.dec  	r15,TestRotate_4-PC
	      	   ld   	r6,r12,1
	      	   push 	r1
	      	   mov  	r1,r0,16
	      	   push 	r5
	      	   ld   	r5,r12,2
	      	   mov  	r7,r1
	      	   sub  	r7,r5
TestRotate_5:
	      	   add  	r6,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r6,r0,0
	      	   sub  	r7,r0,1
	      	nz.dec  	r15,TestRotate_5-PC
	      	   mov  	r1,r5
	      	   or   	r1,r6
	      	   pop  	r5
	      	   pop  	r1
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
	# int TestRotate(int a, int b)
_TestRotate2:
TestRotate_10:
	      	   add  	r8,r0,0
	      	   sub  	r9,r0,1
	      	nz.dec  	r15,TestRotate_10-PC
	      	   mov  	r6,r0,16
	      	   mov  	r5,r6
	      	   sub  	r5,r9
TestRotate_11:
	      	   add  	r8,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r8,r0,0
	      	   sub  	r5,r0,1
	      	nz.dec  	r15,TestRotate_11-PC
	      	   mov  	r1,r8
	      	   or   	r1,r8
	      	   mov  	r15,r13
#	rodata
#	extern	_TestRotate
#	extern	_TestRotate2
