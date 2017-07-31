	bss
	align	2
public bss _nums:
	fill.w	30,0x00

endpublic
	code
	align	16
	data
	align	8
	align	8
	align	8
	code
	align	16
public code _main:
	# int nums [30];
	      	sub  	r14,r0,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,14
	# 	c1 = 0;
	      	sto  	r0,r12,-6
	# 	c2 = 1;
	      	mov  	r1,r0,1
	      	sto  	r1,r12,-10
	# 	for (n = 0; n < 23; n = n + 1) {
	      	sto  	r0,r12,-14
fibonnaci_4:
	      	ld   	r1,r12,-14
	      	cmp  	r1,r0,23
	      	pl.mov  	r15,r0,fibonnaci_5
fibonnaci_7:
	# 		if (n < 1) {
	      	ld   	r1,r12,-14
	      	cmp  	r1,r0,1
	      	pl.mov  	r15,r0,fibonnaci_8
fibonnaci_10:
	# 			nums[0] = 1;
	      	mov  	r1,r0,1
	      	sto  	r1,r0,_nums
	# 			c = 1;
	      	mov  	r1,r0,1
	      	sto  	r1,r12,-2
	      	mov  	r15,r0,fibonnaci_9
fibonnaci_8:
	# 			nums[n] = c;
	      	ld   	r1,r12,-14
	      	add  	r1,r1,0
	      	ld   	r5,r12,-2
	      	sto  	r5,r1,_nums
	# 			c = c1 + c2;
	      	ld   	r1,r12,-6
	      	ld   	r2,r12,-10
	      	add  	r1,r2,0
	      	sto  	r1,r12,-2
	# 			c1 = c2;
	      	ld   	r1,r12,-10
	      	sto  	r1,r12,-6
	# 			c2 = c;
	      	ld   	r1,r12,-2
	      	sto  	r1,r12,-10
fibonnaci_9:
fibonnaci_6:
	      	ld   	r1,r12,-14
	      	add  	r1,r0,1
	      	sto  	r1,r12,-14
	      	mov  	r15,r0,fibonnaci_4
fibonnaci_5:
fibonnaci_11:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
endpublic



	rodata
	align	16
;	global	_main
;	global	_nums
