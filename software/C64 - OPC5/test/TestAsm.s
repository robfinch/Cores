#	code
_TestAsm:
	# int TestAsm(register int a, register int b)
	      	   push 	r13
	# 	asm __leafs {
	      	        	
			push	r8
			push	r9
			jsr		a_sub
			inc		r14,2
	      	   pop  	r13
	      	   mov  	r15,r13
	# int TestAsm(register int a, register int b)
_TestAsm2:
	# 	asm {
	      	        	
			add		r8,r0,1
#	rodata
#	extern	_TestAsm
#	extern	_TestAsm2
