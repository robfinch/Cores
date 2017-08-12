#	code
_bug12:
	# int bug12()
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   dec  	r14,2
	# 	int a = 123;
	      	   mov  	r5,r0,123
	      	   sto  	r5,r12,-1
	      	   ld   	r6,r12,-1
	      	   mov  	r5,r6
	      	   add  	r5,r5
	      	   sto  	r5,r12,-2
	# 	return b;
	      	   ld   	r5,r12,-2
	      	   mov  	r1,r5
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13


#	rodata
#	global	_bug12
