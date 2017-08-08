#	code
	# void TestCheck(int a, int b, int c)
_TestCheck:
	      	   push 	r12
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
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
#	extern	_TestCheck
