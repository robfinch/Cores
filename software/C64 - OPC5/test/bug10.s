#	code
	# void bug10() {
_bug10:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   sub  	r14,r0,335
	      	   push 	r3,r14
	# 	int x;
	      	   ld   	r3,r12,-1
	# 	for (x = 333; x > 0; x--) {
	      	   mov  	r3,r0,333
bug10_4:
	      	   cmp  	r3,r0
	      	mi.mov  	r15,r0,bug10_5
	      	   cmp  	r3,r0
	      	 z.inc  	r15,bug10_5-PC
	# 		pi[x] = 2;
	      	   mov  	r5,r12,-335
	      	   mov  	r1,r3
	      	   add  	r1,r5
	      	   mov  	r5,r0,2
	      	   sto  	r5,r1
	      	   dec  	r3,1
	      	   mov  	r15,r0,bug10_4
bug10_5:
	      	   pop  	r3,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13


#	rodata
#	global	_bug10
