#	bss
_nums:
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0
	word	0

#	code
	# int nums [30];
_main:
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,4
	      	   push 	r3
	# 	int c,c1,c2;
	      	   push 	r4
	# 	c1 = 0;
	      	   sto  	r0,r12,-2
	# 	c2 = 1;
	      	   mov  	r4,r0,1
	# 	for (n = 0; n < 23; n++) {
	      	   sto  	r0,r12,-4
fibonnaci_4:
	      	   ld   	r1,r12,-4
	      	   cmp  	r1,r0,23
	      	mi.mov  	r15,r0,fibonnaci_5
	# 		if (n < 1) {
	      	   ld   	r1,r12,-4
	      	   cmp  	r1,r0,1
	      	mi.inc  	r15,fibonnaci_7-PC
	# 			nums[0] = 1;
	      	   mov  	r1,r0,1
	      	   sto  	r1,r0,_nums
	# 			c = 1;
	      	   mov  	r3,r0,1
	      	   inc  	r15,fibonnaci_8-PC
fibonnaci_7:
	# 			nums[n] = c;
	      	   ld   	r1,r12,-4
	      	   sto  	r3,r1,_nums
	# 			c = c1 + c2;
	      	   ld   	r5,r12,-2
	      	   mov  	r1,r5
	      	   add  	r1,r4
	      	   mov  	r3,r1
	# 			c1 = c2;
	      	   sto  	r4,r12,-2
	# 			c2 = c;
	      	   mov  	r4,r3
fibonnaci_8:
	      	   ld   	r1,r12,-4
	      	   inc  	r1,1
	      	   sto  	r1,r12,-4
	      	   mov  	r15,r0,fibonnaci_4
fibonnaci_5:
	      	   pop  	r4
	      	   pop  	r3
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13




#	rodata
#	global	_main
#	global	_nums
