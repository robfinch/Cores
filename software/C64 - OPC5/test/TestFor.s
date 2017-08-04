#	code
_TestFor:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,3
	# 	for (x = 1; x < 100; x++) {
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-1
TestFor_4:
	      	   ld   	r5,r12,-1
	      	   cmp  	r5,r0,100
	      	mi.inc  	r15,TestFor_5-PC
	# 		putch('a');
	      	   mov  	r5,r0,97
	      	   push 	r5
	      	   jsr  	r13,r0,_putch
	      	   inc  	r14,1
	      	   ld   	r5,r12,-1
	      	   inc  	r5,1
	      	   sto  	r5,r12,-1
	      	   mov  	r15,r0,TestFor_4
TestFor_5:
	# 	y = 50;
	      	   mov  	r5,r0,50
	      	   sto  	r5,r12,-2
TestFor_7:
	      	   ld   	r5,r12,-2
	      	   cmp  	r5,r0
	      	 z.inc  	r15,TestFor_10-PC
	      	   cmp  	r5,r0
	      	pl.inc  	r15,TestFor_8-PC
TestFor_10:
	# 		putch('b');
	      	   mov  	r5,r0,98
	      	   push 	r5
	      	   jsr  	r13,r0,_putch
	      	   inc  	r14,1
	# 		--y;
	      	   ld   	r5,r12,-2
	      	   dec  	r5,1
	      	   sto  	r5,r12,-2
	      	   mov  	r15,r0,TestFor_7
TestFor_8:
	# 	for (z = 1; z < 10; ) ;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-3
TestFor_11:
	      	   ld   	r5,r12,-3
	      	   cmp  	r5,r0,10
	      	pl.dec  	r15,TestFor_11-PC
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13


#	rodata
#	global	_TestFor
#	extern	_putch
