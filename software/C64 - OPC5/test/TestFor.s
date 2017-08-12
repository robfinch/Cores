#	code
_TestFor:
	# int TestFor()
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   dec  	r14,3
	      	   push 	r3,r14
	      	   push 	r4,r14
	      	   ld   	r3,r12,-1
	# 	int x, y, z;
	      	   ld   	r4,r12,-2
	# 	for (x = 1; x < 100; x++) {
	      	   mov  	r3,r0,1
TestFor_4:
	      	   cmp  	r3,r0,100
	      	pl.inc  	r15,TestFor_5-PC
	# 		putch('a');
	      	   mov  	r5,r0,97
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_putch
	      	   inc  	r14,1
	      	   inc  	r3,1
	      	   inc  	r15,TestFor_4-PC
TestFor_5:
	# 	y = 50;
	      	   mov  	r4,r0,50
TestFor_8:
	      	   cmp  	r4,r0
	      	mi.mov  	r15,r0,TestFor_9
	      	   cmp  	r4,r0
	      	 z.inc  	r15,TestFor_9-PC
	# 		putch('b');
	      	   mov  	r5,r0,98
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_putch
	      	   inc  	r14,1
	# 		--y;
	      	   dec  	r4,1
TestFor_10:
	      	   mov  	r15,r0,TestFor_8
TestFor_9:
	# 	for (z = 1; z < 10; ) ;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-3
TestFor_11:
	      	   ld   	r5,r12,-3
	      	   cmp  	r5,r0,10
	      	pl.inc  	r15,TestFor_12-PC
	      	   inc  	r15,TestFor_11-PC
TestFor_12:
	# 	for (x = 1; x < 100; x++) {
	      	   mov  	r3,r0,1
TestFor_15:
	      	   cmp  	r3,r0,100
	      	pl.mov  	r15,r0,TestFor_16
	# 		for (y = 50; y > 0; --y) {
	      	   mov  	r4,r0,50
TestFor_19:
	      	   cmp  	r4,r0
	      	mi.mov  	r15,r0,TestFor_20
	      	   cmp  	r4,r0
	      	 z.mov  	r15,r0,TestFor_20
	# 			for (z = 1; z < 10; z++) {
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-3
TestFor_22:
	      	   ld   	r5,r12,-3
	      	   cmp  	r5,r0,10
	      	pl.mov  	r15,r0,TestFor_23
	# 				putch(rand());
	      	   jsr  	r13,r0,_rand
	      	   push 	r1,r14
	      	   jsr  	r13,r0,_putch
	      	   inc  	r14,1
	      	   ld   	r5,r12,-3
	      	   inc  	r5,1
	      	   sto  	r5,r12,-3
	      	   mov  	r15,r0,TestFor_22
TestFor_23:
	      	   dec  	r4,1
	      	   mov  	r15,r0,TestFor_19
TestFor_20:
	      	   inc  	r3,1
	      	   mov  	r15,r0,TestFor_15
TestFor_16:
	      	   pop  	r4,r14
	      	   pop  	r3,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13


_TestFor2:
	# int TestFor()
	      	   push 	r13,r14
TestFor_30:
	# 		putch('h');
	      	   mov  	r5,r0,104
	      	   push 	r5,r14
	      	   jsr  	r13,r0,_putch
	      	   inc  	r14,1
	      	   inc  	r15,TestFor_30-PC
	      	   pop  	r13,r14
	      	   mov  	r15,r13


#	rodata
#	extern	_rand
#	global	_TestFor
#	global	_TestFor2
#	extern	_putch
