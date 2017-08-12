#	code
_bug8:
	# int bug8(int a, int b)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a*b;
	      	   ld   	r6,r12,2
	      	   ld   	r7,r12,3
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   jsr  	r13,r0,__mul
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_bug8
