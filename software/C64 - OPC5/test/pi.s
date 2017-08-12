#	code
_main:
	# long main()
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	long pi[333];
	      	   sub  	r14,r0,672
	# 	x = 10 * pi[i] + q * i;
	      	   push 	r5,r14
	      	   push 	r6,r14
	      	   ld   	r5,r12,-670
	      	   ld   	r6,r12,-669
	      	   push 	r7,r14
	      	   mov  	r7,r12,-666
	      	   mov  	r4,r5
	      	   add  	r4,r7
	      	   ld   	r4,r4
	      	   ld   	r5,r4,1
	      	   mov  	r6,r0,10
	      	   mov  	r1,r4
	      	   mov  	r2,r5
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   mov  	r3,r6
	      	   mov  	r4,r0
	      	   jsr  	r13,r0,__mul32
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   mov  	r7,r1
	      	   mov  	r3,r2
	      	   ld   	r6,r12,-672
	      	   ld   	r7,r12,-671
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   ld   	r3,r12,-670
	      	   ld   	r4,r12,-669
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   jsr  	r13,r0,__mul32
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   mov  	r4,r1
	      	   mov  	r5,r2
	      	   mov  	r5,r7
	      	   mov  	r6,r3
	      	   add  	r5,r4
	      	   adc  	r6,r5
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   pop  	r7,r14
	      	   sto  	r5,r12,-668
	      	   sto  	r6,r12,-667
	      	   pop  	r6,r14
	      	   pop  	r5,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13


#	rodata
#	global	_main
