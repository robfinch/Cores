#	code
_bug14:
	      	   #    	int bug14() {
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   dec  	r14,2
	      	   #    	   int a = 123;
	      	   mov  	r5,r0,123
	      	   sto  	r5,r12,-1
	      	   ld   	r7,r12,-1
	      	   mov  	r6,r7
	      	   add  	r6,r6
	      	   mov  	r5,r6
	      	   sub  	r5,r0,1
	      	   sto  	r5,r12,-2
	      	   #    	   return b;
	      	   ld   	r5,r12,-2
	      	   mov  	r1,r5
bug14_4:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
	      	   mov  	r15,r0,bug14_4


#	rodata
#	global	_bug14
