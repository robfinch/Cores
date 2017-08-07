#	code
	# int TestDivmod(int a, int b)
_TestDivmod:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a / b;
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   mov  	r2,r5,0
	      	   mov  	r13,r15,2
	      	   mov  	r15,r0,_div
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
	# int TestDivmod(int a, int b)
_TestDivmod2:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a / 10;
	      	   ld   	r1,r12,1
	      	   mov  	r2,r0,10
	      	   mov  	r13,r15,2
	      	   mov  	r15,r0,_div
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
	# int TestDivmod(int a, int b)
_TestMod:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a % b;
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   mov  	r2,r5,0
	      	   mov  	r13,r15,2
	      	   mov  	r15,r0,_mod
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
	# int TestDivmod(int a, int b)
_TestDivmod3:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	a /= b;
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   mov  	r2,r5
	      	   mov  	r13,r15,2
	      	   mov  	r15,r0,_div
	      	   sto  	r1,r12,1
	# 	return a;
	      	   ld   	r1,r12,1
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
	# int TestDivmod(int a, int b)
_TestModu:
	# 	return a % b;
	      	   mov  	r1,r8,0
	      	   mov  	r2,r9,0
	      	   mov  	r13,r15,2
	      	   mov  	r15,r0,_modu
	      	   mov  	r15,r13
#	rodata
#	extern	_TestMod
#	extern	_TestDivmod
#	extern	_TestDivmod2
#	extern	_TestModu
#	extern	_TestDivmod3
