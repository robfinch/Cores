	bss
_nums:
	fill.w	15,0x00

	code
	data
	code
_main:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,7
	# 	c1 = 0;
	      	sto  	r0,r12,-3
	# 	c2 = 1;
	      	mov  	r5,r0,1
	      	sto  	r5,r12,-5
	# 	for (n = 0; n < 23; n = n + 1) {
	      	sto  	r0,r12,-7
fibonnaci_4:
	      	ld   	r5,r12,-7
	      	cmp  	r5,r0,23
	      	pl.mov  	r15,r0,fibonnaci_5
fibonnaci_7:
	# 		if (n < 1) {
	      	ld   	r5,r12,-7
	      	cmp  	r5,r0,1
	      	pl.mov  	r15,r0,fibonnaci_8
fibonnaci_10:
	# 			nums[0] = 1;
	      	mov  	r5,r0,1
	      	sto  	r5,r0,_nums
	# 			c = 1;
	      	mov  	r5,r0,1
	      	sto  	r5,r12,-1
	      	mov  	r15,r0,fibonnaci_9
fibonnaci_8:
	# 			nums[n] = c;
	      	ld   	r5,r12,-7
	      	ld   	r6,r12,-1
	      	sto  	r6,r5,_nums
	# 			c = c1 + c2;
	      	ld   	r5,r12,-3
	      	ld   	r6,r12,-5
	      	add  	r5,r6,0
	      	sto  	r5,r12,-1
	# 			c1 = c2;
	      	ld   	r5,r12,-5
	      	sto  	r5,r12,-3
	# 			c2 = c;
	      	ld   	r5,r12,-1
	      	sto  	r5,r12,-5
fibonnaci_9:
fibonnaci_6:
	      	ld   	r5,r12,-7
	      	add  	r5,r0,1
	      	sto  	r5,r12,-7
	      	mov  	r15,r0,fibonnaci_4
fibonnaci_5:
fibonnaci_11:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0




	rodata
;	global	_main
;	global	_nums
