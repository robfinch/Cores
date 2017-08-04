#	code
_TestArrayY:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,8
	# 	y = {1,2,3,4,5,6,7,8};
	      	   mov  	r5,r0
	      	   add  	r5,r12,-8
	      	   mov  	r6,r5
	      	   mov  	r7,r0,1
	      	   sto  	r7,r6,0
	      	   mov  	r7,r0,2
	      	   sto  	r7,r6,1
	      	   mov  	r7,r0,3
	      	   sto  	r7,r6,2
	      	   mov  	r7,r0,4
	      	   sto  	r7,r6,3
	      	   mov  	r7,r0,5
	      	   sto  	r7,r6,4
	      	   mov  	r7,r0,6
	      	   sto  	r7,r6,5
	      	   mov  	r7,r0,7
	      	   sto  	r7,r6,6
	      	   mov  	r7,r0,8
	      	   sto  	r7,r6,7
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
#	extern	_TestArrayY
