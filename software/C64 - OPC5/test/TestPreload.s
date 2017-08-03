	code
_TestPreload:
	      	   sub  	r14,r0,1
	      	   sto  	r12,r14,0
	      	   mov  	r12,r14,0
	      	   sub  	r14,r0,1
	# 	int x = a < 10;
	      	   mov  	r1,r0,1
	      	   ld   	r2,r12,1
	      	   cmp  	r2,r0,10
	      	pl.mov  	r1,r0,0
	      	   sto  	r1,r12,-1
	# 	return(x);
	      	   ld   	r1,r12,-1
TestPreload_6:
	      	   hint 	6
	      	   mov  	r14,r12,0
	      	   ld   	r12,r14,0
	      	   add  	r14,r0,1
	      	   mov  	r15,r13,0
	rodata
	extern	_TestPreload
