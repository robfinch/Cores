	bss
_nums:
	fill.w	15,0x00

	code
_main:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   sub  	r14,r0,4
	# 	c1 = 0;
	      	   sto  	r0,r12,-2
	# 	c2 = 1;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-3
	# 	for (n = 0; n < 23; n = n + 1) {
	      	   sto  	r0,r12,-4
Fibonnaci_4:
	      	   ld   	r5,r12,-4
	      	   cmp  	r5,r0,23
	      	pl.mov  	r15,r0,Fibonnaci_5
	# 		if (n < 1) {
	      	   ld   	r5,r12,-4
	      	   cmp  	r5,r0,1
	      	pl.inc  	r15,Fibonnaci_8-PC
	# 			nums[0] = 1;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r0,_nums
	# 			c = 1;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-1
	      	   mov  	r15,r0,Fibonnaci_9
Fibonnaci_8:
	# 			nums[n] = c;
	      	   ld   	r5,r12,-4
	      	   ld   	r6,r12,-1
	      	   sto  	r6,r5,_nums
	# 			c = c1 + c2;
	      	   ld   	r5,r12,-2
	      	   ld   	r6,r12,-3
	      	   add  	r5,r6
	      	   sto  	r5,r12,-1
	# 			c1 = c2;
	      	   ld   	r5,r12,-3
	      	   sto  	r5,r12,-2
	# 			c2 = c;
	      	   ld   	r5,r12,-1
	      	   sto  	r5,r12,-3
Fibonnaci_9:
	      	   ld   	r5,r12,-4
	      	   add  	r5,r0,1
	      	   sto  	r5,r12,-4
	      	   mov  	r15,r0,Fibonnaci_4
Fibonnaci_5:
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13




	rodata
;	global	_main
;	global	_nums
