#	code
_print:
	# void print(char *ptr)
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   push 	r3,r14
	      	   ld   	r3,r12,2
Test3_4:
	      	   ld   	r5,r3
	      	   add  	r5,r0
	      	 z.inc  	r15,Test3_5-PC
	# 		outch(*ptr);
	      	   ld   	r5,r3
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_outch
	      	   inc  	r14,1
	# 		ptr++;
	      	   inc  	r3,1
	      	   dec  	r15,Test3_4-PC
Test3_5:
	      	   pop  	r3,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
_main:
	# void print(char *ptr)
	      	   push 	r13,r14
	# 	print("Hello world\r\n");
	      	   mov  	r5,r0,Test3_7
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_print
	      	   inc  	r14,1
	      	   pop  	r13,r14
	      	   mov  	r15,r13


#	rodata
#	align	2
Test3_7:	# Hello world
	word	72,101,108,108,111,32,119,111
	word	114,108,100,13,10,0
#	global	_main
#	extern	_outch
#	extern	_print
