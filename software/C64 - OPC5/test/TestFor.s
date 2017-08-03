	code
_TestFor:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,3
	# 	for (x = 1; x < 100; x++) {
	      	mov  	r5,r0,1
	      	sto  	r5,r12,-1
TestFor_4:
	      	ld   	r5,r12,-1
	      	cmp  	r5,r0,100
	      	pl.mov  	r15,r0,TestFor_5
	# 		putch('a');
	      	mov  	r5,r0,97
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_putch
	      	add  	r14,r0,1
	      	ld   	r5,r12,-1
	      	add  	r5,r0,1
	      	sto  	r5,r12,-1
	      	mov  	r15,r0,TestFor_4
TestFor_5:
	# 	y = 50;
	      	mov  	r5,r0,50
	      	sto  	r5,r12,-2
TestFor_8:
	      	ld   	r5,r12,-2
	      	cmp  	r5,r0,0
	      	mi.mov  	r15,r0,TestFor_9
	      	z.mov  	r15,r0,TestFor_9
	# 		putch('b');
	      	mov  	r5,r0,98
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_putch
	      	add  	r14,r0,1
	# 		--y;
	      	ld   	r5,r12,-2
	      	sub  	r5,r0,1
	      	sto  	r5,r12,-2
	      	mov  	r15,r0,TestFor_8
TestFor_9:
	# 	for (z = 1; z < 10; ) ;
	      	mov  	r5,r0,1
	      	sto  	r5,r12,-3
TestFor_11:
	      	ld   	r5,r12,-3
	      	cmp  	r5,r0,10
	      	mi.mov  	r15,r0,TestFor_11
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0




	rodata
;	global	_TestFor
	extern	_putch
