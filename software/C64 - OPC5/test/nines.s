#	code
_main:
	# int main()
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	int nines;
	      	   dec  	r14,1
nines_4:
	      	   ld   	r5,r12,-1
	      	   add  	r5,r0
	      	 z.mov  	r15,r0,nines_5
	# 		putchar('0');
	      	   mov  	r5,r0,48
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_putchar
	      	   inc  	r14,1
	# 		nines--;
	      	   ld   	r5,r12,-1
	      	   dec  	r5,1
	      	   sto  	r5,r12,-1
	      	   mov  	r15,r0,nines_4
nines_5:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13


#	rodata
#	global	_main
#	extern	_putchar
