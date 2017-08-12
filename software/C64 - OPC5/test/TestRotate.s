#	code
	# int TestRotate(int a, int b)
_TestRotate:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return ((a << b) | (a >> (16-b)));
	      	   ld   	r6,r12,1
	      	   ld   	r7,r12,2
	      	   mov  	r5,r6
TestRotate_4:
	      	   add  	r5,r5
	      	   sub  	r7,r0,1
	      	nz.inc  	r15,TestRotate_4-PC
	      	   ld   	r7,r12,1
	      	   push 	r1,r14
	      	   push 	r5,r14
	      	   mov  	r5,r0,16
	      	   push 	r6,r14
	      	   ld   	r6,r12,2
	      	   mov  	r1,r5
	      	   sub  	r1,r6
	      	   mov  	r6,r7
TestRotate_5:
	      	   asr  	r6,r6
	      	   sub  	r1,r0,1
	      	nz.inc  	r15,TestRotate_5-PC
	      	   mov  	r1,r5
	      	   or   	r1,r6
	      	   pop  	r6,r14
	      	   pop  	r5,r14
	      	   pop  	r1,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestRotate(int a, int b)
_TestRotate2:
	# 	return ((a << b) | (a >> (16-b)));
	      	   mov  	r5,r8
TestRotate_10:
	      	   add  	r5,r5
	      	   sub  	r9,r0,1
	      	nz.inc  	r15,TestRotate_10-PC
	      	   push 	r1,r14
	      	   mov  	r1,r0,16
	      	   mov  	r7,r1
	      	   sub  	r7,r9
	      	   mov  	r6,r8
TestRotate_11:
	      	   asr  	r6,r6
	      	   sub  	r7,r0,1
	      	nz.inc  	r15,TestRotate_11-PC
	      	   mov  	r1,r5
	      	   or   	r1,r6
	      	   pop  	r1,r14
	      	   mov  	r15,r13
	# int TestRotate(int a, int b)
_TestRotate3:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return ((a << b) | (a >> (32-b)));
	      	   ld   	r3,r12,1
	      	   ld   	r4,r12,2
	      	   push 	r1,r14
	      	   push 	r5,r14
	      	   ld   	r1,r12,3
	      	   ld   	r5,r12,4
	      	   mov  	r6,r3
	      	   mov  	r7,r4
TestRotate_16:
	      	   add  	r6,r6
	      	   adc  	r7,r7
	      	   sub  	r1,r0,1
	      	nz.inc  	r15,TestRotate_16-PC
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   push 	r6,r14
	      	   push 	r7,r14
	      	   mov  	r7,r0,32
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   ld   	r3,r12,3
	      	   ld   	r4,r12,4
	      	   mov  	r6,r7
	      	   sub  	r6,r3
	      	   mov  	r3,r1
	      	   mov  	r4,r5
TestRotate_17:
	      	   asr  	r4,r4
	      	   ror  	r3,r3
	      	   sub  	r6,r0,1
	      	nz.inc  	r15,TestRotate_17-PC
	      	   mov  	r1,r6
	      	   mov  	r5,r7
	      	   or   	r1,r3
	      	   or   	r5,r4
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   pop  	r7,r14
	      	   pop  	r6,r14
	      	   mov  	r2,r5
	      	   pop  	r5,r14
	      	   pop  	r1,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestRotate(int a, int b)
_TestRotate4:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return ((a << b) | (a >> (32-b)));
	      	   ld   	r3,r12,1
	      	   ld   	r4,r12,2
	      	   push 	r1,r14
	      	   push 	r5,r14
	      	   ld   	r1,r12,3
	      	   ld   	r5,r12,4
	      	   add  	r1,r1,0
	      	mi.sub  	r1,r1,0
	      	   mov  	r6,r3
	      	   mov  	r7,r4
TestRotate_22:
	      	   add  	r6,r6
	      	   adc  	r7,r7
	      	   sub  	r1,r0,1
	      	nz.inc  	r15,TestRotate_22-PC
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   push 	r6,r14
	      	   push 	r7,r14
	      	   mov  	r7,r0,32
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   ld   	r3,r12,3
	      	   ld   	r4,r12,4
	      	   mov  	r6,r7
	      	   sub  	r6,r3
	      	   add  	r6,r6,0
	      	mi.sub  	r6,r6,0
	      	   mov  	r3,r1
	      	   mov  	r4,r5
TestRotate_23:
	      	   lsr  	r4,r4
	      	   ror  	r1,r1
	      	   sub  	r6,r0,1
	      	nz.inc  	r15,TestRotate_23-PC
	      	   mov  	r1,r6
	      	   mov  	r5,r7
	      	   or   	r1,r3
	      	   or   	r5,r4
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   pop  	r7,r14
	      	   pop  	r6,r14
	      	   mov  	r2,r5
	      	   pop  	r5,r14
	      	   pop  	r1,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_TestRotate
#	extern	_TestRotate2
#	extern	_TestRotate3
#	extern	_TestRotate4
