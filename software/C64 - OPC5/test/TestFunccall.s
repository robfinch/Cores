#	code
	# int SomeFunc(int a, int b, register int c)
_SomeFunc:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a + b - c;
	      	   ld   	r6,r12,1
	      	   ld   	r7,r12,2
	      	   mov  	r5,r6
	      	   add  	r5,r7
	      	   mov  	r1,r5
	      	   sub  	r1,r8
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
_main:
	# int SomeFunc(int a, int b, register int c)
	      	   push 	r13
	# 	SomeFunc(10,20,30);
	      	   push 	r8
	      	   mov  	r5,r0,30
	      	   mov  	r8,r5
	      	   mov  	r6,r0,20
	      	   push 	r6
	      	   mov  	r7,r0,10
	      	   push 	r7
	      	   jsr  	r13,r0,_SomeFunc
	      	   inc  	r14,2
	      	   pop  	r8
	      	   pop  	r13
	      	   mov  	r15,r13




#	rodata
#	global	_main
#	extern	_SomeFunc
