#	code
_myint:
	# void interrupt myint()
	      	   push 	r1
	      	   push 	r2
	      	   push 	r3
	      	   push 	r4
	      	   push 	r5
	      	   push 	r6
	      	   push 	r7
	      	   push 	r8
	      	   push 	r9
	      	   push 	r10
	      	   push 	r11
	      	   push 	r12
	      	   push 	r13
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	# 	printf("Hello again.");
	      	   mov  	r5,r0,TestInt_1
	      	   push 	r5
	      	   jsr  	r13,r0,_printf
	      	   inc  	r14,1
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   pop  	r13
	      	   pop  	r13
	      	   pop  	r12
	      	   pop  	r11
	      	   pop  	r10
	      	   pop  	r9
	      	   pop  	r8
	      	   pop  	r7
	      	   pop  	r6
	      	   pop  	r5
	      	   pop  	r4
	      	   pop  	r3
	      	   pop  	r2
	      	   rti  


_BIOScall:
	# void interrupt myint()
	      	   push 	r2
	      	   push 	r3
	      	   push 	r4
	      	   push 	r5
	      	   push 	r6
	      	   push 	r7
	      	   push 	r8
	      	   push 	r9
	      	   push 	r10
	      	   push 	r11
	      	   push 	r12
	      	   push 	r13
	      	   push 	r12
	# 	return -1;
	      	   mov  	r12,r14
	      	   mov  	r1,r0,-1
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   pop  	r13
	      	   pop  	r12
	      	   pop  	r11
	      	   pop  	r10
	      	   pop  	r9
	      	   pop  	r8
	      	   pop  	r7
	      	   pop  	r6
	      	   pop  	r5
	      	   pop  	r4
	      	   pop  	r3
	      	   pop  	r2
	      	   pop  	r1
	      	   rti  


#	rodata
	align	2
TestInt_1:	# Hello again.
	word	72,101,108,108,111,32,97,103
	word	97,105,110,46,0
#	global	_BIOScall
#	global	_myint
#	extern	_printf
