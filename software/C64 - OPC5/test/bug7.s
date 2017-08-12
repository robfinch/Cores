#	code
_bug7:
	# int bug7(int d)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return (d/1000) % 10;
	      	   ld   	r7,r12,2
	      	   mov  	r1,r7
	      	   mov  	r2,r0,1000
	      	   jsr  	r13,r0,__div
	      	   mov  	r2,r0,10
	      	   jsr  	r13,r0,__mod
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_bug7
