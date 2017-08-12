#	code
_TestIncDec:
	# void TestIncDec()
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	# 	int x[4][5];
	      	   sub  	r14,r0,20
	# 	(x[2])++ = {1,2,3,4,5};
	      	   mov  	r6,r0,10
	      	   mov  	r7,r12,-20
	      	   mov  	r5,r6
	      	   add  	r5,r7
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
TestIncDec_4:
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   pop  	r13
	      	   mov  	r15,r13


#	rodata
#	global	_TestIncDec
