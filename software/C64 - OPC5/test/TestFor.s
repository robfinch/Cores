	code
	align	16
	data
	align	8
	code
	align	16
public code _TestFor:
	      	sub  	r14,r0,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r0,6
	# 	for (x = 1; x < 100; x++) {
	      	mov  	r5,r0,1
	      	sto  	r5,r12,-2
TestFor_4:
	      	ld   	r5,r12,-2
	      	cmp  	r5,r0,100
	      	pl.mov  	r15,r0,TestFor_5
TestFor_7:
	# 		putch('a');
	      	mov  	r5,r0,97
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_putch
	      	add  	r14,r0,2
TestFor_6:
	      	ld   	r5,r12,-2
	      	add  	r5,r0,1
	      	sto  	r5,r12,-2
	      	mov  	r15,r0,TestFor_4
TestFor_5:
	# 	y = 50;
	      	mov  	r5,r0,50
	      	sto  	r5,r12,-6
TestFor_8:
	      	ld   	r5,r12,-6
	      	cmp  	r5,r0,0
	      	mi.mov  	r15,r0,TestFor_9
	      	z.mov  	r15,r0,TestFor_9
	# 		putch('a');
	      	mov  	r5,r0,97
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_putch
	      	add  	r14,r0,2
	# 		--y;
	      	ld   	r5,r12,-6
	      	sub  	r5,r0,1
	      	sto  	r5,r12,-6
TestFor_10:
	      	mov  	r15,r0,TestFor_8
TestFor_9:
TestFor_11:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r0,4
	      	mov  	r15,r13,0
endpublic



	rodata
	align	16
;	global	_TestFor
	extern	_putch
