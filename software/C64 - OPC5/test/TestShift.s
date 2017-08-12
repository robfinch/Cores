#	code
	# int TestShiftLeft(register int a, register int b)
_TestShiftLeft:
	# 	return a << b;
	      	   mov  	r1,r8
TestShift_4:
	      	   add  	r1,r1
	      	   sub  	r9,r0,1
	      	nz.inc  	r15,TestShift_4-PC
	      	   mov  	r15,r13
	# int TestShiftLeft(register int a, register int b)
_TestShiftRight:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a >> b;
	      	   ld   	r5,r12,1
	      	   ld   	r6,r12,2
	      	   mov  	r1,r5
TestShift_9:
	      	   asr  	r1,r1
	      	   sub  	r6,r0,1
	      	nz.inc  	r15,TestShift_9-PC
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestShiftLeft(register int a, register int b)
_TestShiftLeftI1:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a << 1;
	      	   ld   	r5,r12,1
	      	   mov  	r1,r5
	      	   add  	r1,r1
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestShiftLeft(register int a, register int b)
_TestShiftLeftI5:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a << 1;
	      	   ld   	r5,r12,1
	      	   mov  	r1,r5
	      	   add  	r1,r1
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestShiftLeft(register int a, register int b)
_TestShiftRight:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a >> b;
	      	   ld   	r5,r12,1
	      	   ld   	r6,r12,2
	      	   mov  	r1,r5
TestShift_22:
	      	   asr  	r1,r1
	      	   sub  	r6,r0,1
	      	nz.inc  	r15,TestShift_22-PC
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_TestShiftLeftI1
#	extern	_TestShiftLeftI5
#	extern	_TestShiftLeft
#	extern	_TestShiftRight
#	extern	_TestShiftRight
