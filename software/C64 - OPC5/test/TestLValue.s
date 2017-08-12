#	code
	# int TestLValue()
_TestLValue:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   dec  	r14,3
	      	   push 	r3,r14
	      	   mov  	r1,r12,-2
	# 	int x;
	      	   mov  	r3,r1
	# 	x = y + z;
	      	   ld   	r5,r3
	      	   ld   	r6,r12,-3
	      	   mov  	r1,r5
	      	   add  	r1,r6
	      	   sto  	r1,r12,-1
	# 	x = &y + 20;
	      	   mov  	r5,r0,20
	      	   mov  	r1,r3
	      	   add  	r1,r5
	      	   sto  	r1,r12,-1
	# 	x = y + &x;
	      	   ld   	r5,r3
	      	   mov  	r6,r12,-1
	      	   mov  	r1,r5
	      	   add  	r1,r6
	      	   sto  	r1,r12,-1
	      	   pop  	r3,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13


#	rodata
#	global	_TestLValue
