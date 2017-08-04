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
	      	   pop  	r13
	      	   pop  	r12
	      	   ld   	r1,r14,0
	      	   ld   	r2,r14,1
	      	   ld   	r3,r14,2
	      	   ld   	r4,r14,3
	      	   ld   	r5,r14,4
	      	   ld   	r6,r14,5
	      	   ld   	r7,r14,6
	      	   ld   	r8,r14,7
	      	   ld   	r9,r14,8
	      	   ld   	r10,r14,9
	      	   ld   	r11,r14,10
	      	   ld   	r12,r14,11
	      	   ld   	r13,r14,12
	      	   add  	r14,r0,13
	      	   rti  


_BIOScall:
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
	      	   push 	r12
	      	   mov  	r12,r14
	      	   mov  	r1,r0,-1
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   ld   	r1,r14,0
	      	   ld   	r2,r14,1
	      	   ld   	r3,r14,2
	      	   ld   	r4,r14,3
	      	   ld   	r5,r14,4
	      	   ld   	r6,r14,5
	      	   ld   	r7,r14,6
	      	   ld   	r8,r14,7
	      	   ld   	r9,r14,8
	      	   ld   	r10,r14,9
	      	   ld   	r11,r14,10
	      	   ld   	r12,r14,11
	      	   ld   	r13,r14,12
	      	   add  	r14,r0,13
	      	   rti  


#	rodata
	align	2
TestInt_1:	# Hello again.
	word	72,101,108,108,111,32,97,103
	word	97,105,110,46,0
#	global	_BIOScall
#	global	_myint
#	extern	_printf
