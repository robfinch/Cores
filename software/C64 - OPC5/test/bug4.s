#	code
_print:
	# int print(char *ptr)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
bug4_4:
	      	   ld   	r5,r12,2
	      	   inc  	r5,1
	      	   sto  	r5,r12,2
	      	   ld   	r5,r12,2
	      	   ld   	r5,r5
	      	   add  	r5,r0
	      	 z.inc  	r15,bug4_5-PC
	# 		outch(*ptr);
	      	   ld   	r5,r12,2
	      	   ld   	r5,r5
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_outch
	      	   inc  	r14,1
	      	   mov  	r15,r0,bug4_4
bug4_5:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_outch
#	extern	_print
