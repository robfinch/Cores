#	code
_SomeFunc:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a + b - c;
	      	   ld   	r1,r12,1
	      	   ld   	r2,r12,2
	      	   add  	r1,r2
	      	   sub  	r1,r8
TestFunccall_4:
	      	   nop  
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
_main:
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
	      	   mov  	r15,r13


#	rodata
#	global	_main
#	extern	_SomeFunc
