#	bss
_pi:
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0
	WORD	0

#	code
_main:
	# int pi[20];
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	int x, i;
	      	   dec  	r14,2
	# 	x = 10 * pi[i];
	      	   ld   	r7,r12,-2
	      	   mov  	r6,r7
	      	   ld   	r6,r6,_pi
	      	   mov  	r7,r0,10
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   jsr  	r13,r0,__mul
	      	   mov  	r5,r1
	      	   sto  	r5,r12,-1
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13


#	rodata
#	global	_main
#	global	_pi
