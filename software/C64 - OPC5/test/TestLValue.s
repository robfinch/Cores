#	code
_TestLValue:
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,3
	      	   push 	r2
	      	   mov  	r1,r0
	      	   add  	r1,r12,-2
	      	   mov  	r2,r1
	# 	x = y + z;
	      	   ld   	r1,r2,0
	      	   ld   	r2,r12,-3
	      	   add  	r1,r2
	      	   sto  	r1,r12,-1
	# 	x = &y + 20;
	      	   mov  	r1,r0,20
	      	   add  	r2,r1
	      	   sto  	r2,r12,-1
	# 	x = y + &x;
	      	   ld   	r1,r2,0
	      	   mov  	r2,r0
	      	   add  	r2,r12,-1
	      	   add  	r1,r2
	      	   sto  	r1,r12,-1
	# 	&x = y + z;	// should give an LValue error
	      	   mov  	r1,r0
	      	   add  	r1,r12,-1
	      	   pop  	r2
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13


#	rodata
#	global	_TestLValue
