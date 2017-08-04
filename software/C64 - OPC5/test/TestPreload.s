#	code
_TestPreload:
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,1
	# 	int x = a < 10;
	      	   mov  	r1,r0,1
	      	   ld   	r2,r12,1
	      	   cmp  	r2,r0,10
	      	pl.mov  	r1,r0
	      	   sto  	r1,r12,-1
	# 	return(x);
	      	   ld   	r1,r12,-1
TestPreload_6:
	      	   nop  
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
#	extern	_TestPreload
