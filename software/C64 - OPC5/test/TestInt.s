#	code
_myint:
	# void interrupt myint()
	      	   push 	r1,r14
	      	   push 	r2,r14
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   push 	r5,r14
	      	   push 	r6,r14
	      	   push 	r7,r14
	      	   push 	r8,r14
	      	   push 	r9,r14
	      	   push 	r10,r14
	      	   push 	r11,r14
	      	   push 	r12,r14
	      	   push 	r13,r14
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	printf("Hello again.");
	      	   mov  	r5,r0,TestInt_1
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_printf
	      	   inc  	r14,1
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   pop  	r13,r14
	      	   pop  	r12,r14
	      	   pop  	r11,r14
	      	   pop  	r10,r14
	      	   pop  	r9,r14
	      	   pop  	r8,r14
	      	   pop  	r7,r14
	      	   pop  	r6,r14
	      	   pop  	r5,r14
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   pop  	r2,r14
	      	   rti  


_BIOScall:
	# void interrupt myint()
	      	   push 	r2,r14
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   push 	r5,r14
	      	   push 	r6,r14
	      	   push 	r7,r14
	      	   push 	r8,r14
	      	   push 	r9,r14
	      	   push 	r10,r14
	      	   push 	r11,r14
	      	   push 	r12,r14
	      	   push 	r13,r14
	      	   push 	r12,r14
	# 	return -1;
	      	   mov  	r12,r14
	      	   mov  	r1,r0,65535
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   pop  	r12,r14
	      	   pop  	r11,r14
	      	   pop  	r10,r14
	      	   pop  	r9,r14
	      	   pop  	r8,r14
	      	   pop  	r7,r14
	      	   pop  	r6,r14
	      	   pop  	r5,r14
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   pop  	r2,r14
	      	   pop  	r1,r14
	      	   rti  


#	rodata
#	align	2
TestInt_1:	# Hello again.
	WORD	72,101,108,108,111,32,97,103
	WORD	97,105,110,46,0
#	global	_BIOScall
#	global	_myint
#	extern	_printf
