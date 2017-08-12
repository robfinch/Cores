#	code
_TestDivmod:
	# int TestDivmod(int a, int b)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a / b;
	      	   ld   	r6,r12,2
	      	   ld   	r7,r12,3
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   jsr  	r13,r0,__div
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
_TestDivmod2:
	# int TestDivmod(int a, int b)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a / 10;
	      	   ld   	r6,r12,2
	      	   mov  	r1,r6
	      	   mov  	r2,r0,10
	      	   jsr  	r13,r0,__div
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
_TestMod:
	# int TestDivmod(int a, int b)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a % b;
	      	   ld   	r6,r12,2
	      	   ld   	r7,r12,3
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   jsr  	r13,r0,__mod
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
	# int TestDivmod(int a, int b)
_TestDivmod3:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	a /= b;
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   mov  	r2,r5
	      	   mov  	r13,r15,2
	      	   mov  	r15,r0,__div
	      	   sto  	r1,r12,1
	# 	return a;
	      	   ld   	r1,r12,1
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
_TestModu:
	# int TestDivmod(int a, int b)
	      	   push 	r13,r14
	# 	return a % b;
	      	   mov  	r1,r8
	      	   mov  	r2,r9
	      	   jsr  	r13,r0,__modu
	      	   pop  	r13,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_TestMod
#	extern	_TestDivmod
#	extern	_TestDivmod2
#	extern	_TestModu
#	extern	_TestDivmod3
