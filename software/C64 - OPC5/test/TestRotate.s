#	code
_TestRotate:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return ((a << b) | (a >> (16-b)));
	      	   ld   	r1,r12,1
	      	   ld   	r2,r12,2
TestRotate_4:
	      	   add  	r1,r0,0
	      	   sub  	r2,r0,1
	      	nz.dec  	r15,TestRotate_4-PC
	      	   ld   	r2,r12,1
	      	   mov  	r5,r0,16
	      	   ld   	r6,r12,2
	      	   sub  	r5,r6
TestRotate_5:
	      	   add  	r2,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r2,r0,0
	      	   sub  	r5,r0,1
	      	nz.dec  	r15,TestRotate_5-PC
	      	   or   	r1,r2
TestRotate_6:
	      	   nop  
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
_TestRotate2:
TestRotate_10:
	      	   add  	r8,r0,0
	      	   sub  	r9,r0,1
	      	nz.dec  	r15,TestRotate_10-PC
	      	   mov  	r1,r0,16
	      	   sub  	r1,r9
TestRotate_11:
	      	   add  	r8,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r8,r0,0
	      	   sub  	r1,r0,1
	      	nz.dec  	r15,TestRotate_11-PC
	      	   or   	r1,r8
	      	   mov  	r15,r13
#	rodata
#	extern	_TestRotate
#	extern	_TestRotate2
