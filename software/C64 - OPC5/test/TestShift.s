#	code
_TestShiftLeft:
TestShift_4:
	      	   add  	r8,r0,0
	      	   sub  	r9,r0,1
	      	nz.dec  	r15,TestShift_4-PC
	      	   mov  	r1,r8
	      	   mov  	r15,r13
_TestShiftRight:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a >> b;
	      	   ld   	r1,r12,1
	      	   ld   	r2,r12,2
TestShift_9:
	      	   add  	r1,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r1,r0,0
	      	   sub  	r2,r0,1
	      	nz.dec  	r15,TestShift_9-PC
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
_TestShiftLeftI1:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a << 1;
	      	   ld   	r1,r12,1
	      	   add  	r1,r0,0
TestShift_14:
	      	   nop  
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
_TestShiftLeftI5:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a << 1;
	      	   ld   	r1,r12,1
	      	   add  	r1,r0,0
TestShift_18:
	      	   nop  
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
_TestShiftRight:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a >> b;
	      	   ld   	r1,r12,1
	      	   ld   	r2,r12,2
TestShift_22:
	      	   add  	r1,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r1,r0,0
	      	   sub  	r2,r0,1
	      	nz.dec  	r15,TestShift_22-PC
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
#	extern	_TestShiftLeftI1
#	extern	_TestShiftLeftI5
#	extern	_TestShiftLeft
#	extern	_TestShiftRight
#	extern	_TestShiftRight
