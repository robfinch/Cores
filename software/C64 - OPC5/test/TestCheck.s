#	code
	# void TestCheck(int a, int b, int c)
_TestCheck:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	__check(a;b;c);
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   ld   	r6,r12,3
	      	   cmp  	r1,r5
	      	mi.inc  	r15,TestCheck_4-PC
	      	   cmp  	r1,r6
	      	mi.inc  	r15,TestCheck_5-PC
TestCheck_4:
	      	   putpsr	15
TestCheck_5:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# void TestCheck(int a, int b, int c)
_TestCheck:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	__check(a;b;c);
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   ld   	r6,r12,3
	      	   ld   	r7,r12,4
	      	   ld   	r3,r12,5
	      	   ld   	r4,r12,6
	      	   cmp  	r1,r6
	      	   cmpc 	r5,r7
	      	mi.inc  	r15,TestCheck_10-PC
	      	   cmp  	r1,r3
	      	   cmpc 	r5,r4
	      	mi.inc  	r15,TestCheck_11-PC
TestCheck_10:
	      	   putpsr	15
TestCheck_11:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# void TestCheck(int a, int b, int c)
_TestCheck:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	__check(a;0;1024);
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   mov  	r6,r0,0
	      	   mov  	r7,r0,1024
	      	   cmp  	r1,r6
	      	   cmpc 	r5,r0
	      	mi.inc  	r15,TestCheck_16-PC
	      	   cmp  	r1,r7
	      	   cmpc 	r5,r0
	      	mi.inc  	r15,TestCheck_17-PC
TestCheck_16:
	      	   putpsr	15
TestCheck_17:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_TestCheck
#	extern	_TestCheck
#	extern	_TestCheck
