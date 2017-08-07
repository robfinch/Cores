#	code
#	data
#	code
	# long TestLong(int a, int b)
_TestLong:
	      	   push 	r12
	      	   mov  	r12,r14
	# 	long c, d, e;
	      	   dec  	r14,12
	# 	for (x = 0; x < 100000L; x++) {
	      	   sto  	r0,r12,-8
	      	   sto  	r0,r12,-7
TestLong_4:
	      	   ld   	r1,r12,-8
	      	   ld   	r5,r12,-7
	      	   cmp  	r1,r0,34464
	      	   cmpc 	r5,r0,1
	      	pl.mov  	r15,r0,TestLong_5
	# 		c = d + e + b - a;
	      	   push 	r1
	      	   push 	r5
	      	   ld   	r1,r12,-4
	      	   ld   	r5,r12,-3
	      	   push 	r6
	      	   push 	r7
	      	   ld   	r6,r12,-6
	      	   ld   	r7,r12,-5
	      	   mov  	r3,r1
	      	   mov  	r4,r5
	      	   add  	r3,r6
	      	   adc  	r4,r7
	      	   ld   	r1,r12,2
	      	   mov  	r5,r0
	      	   or   	r1,r1
	      	mi.mov  	r5,r0,-1
	      	   mov  	r6,r3
	      	   mov  	r7,r4
	      	   add  	r6,r1
	      	   adc  	r7,r5
	      	   ld   	r3,r12,1
	      	   mov  	r4,r0
	      	   or   	r3,r3
	      	mi.mov  	r4,r0,-1
	      	   mov  	r1,r6
	      	   mov  	r5,r7
	      	   sub  	r1,r3
	      	   sbc  	r5,r4
	      	   pop  	r7
	      	   pop  	r6
	      	   sto  	r1,r12,-2
	      	   sto  	r5,r12,-1
	      	   pop  	r5
	      	   pop  	r1
	# 		c = e * x;
	      	   ld   	r6,r12,-6
	      	   ld   	r7,r12,-5
	      	   ld   	r3,r12,-8
	      	   ld   	r4,r12,-7
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   push 	r3
	      	   push 	r4
	      	   jsr  	r13,r0,__mul32
	      	   pop  	r4
	      	   pop  	r3
	      	   mov  	r5,r2
	      	   sto  	r1,r12,-2
	      	   sto  	r5,r12,-1
	      	   ld   	r1,r12,-8
	      	   ld   	r5,r12,-7
	      	   inc  	r1,1
	      	   adc  	r5,r0
	      	   sto  	r1,r12,-8
	      	   sto  	r5,r12,-7
	      	   mov  	r15,r0,TestLong_4
TestLong_5:
	# 	x = c / d;
	      	   ld   	r6,r12,-2
	      	   ld   	r7,r12,-1
	      	   ld   	r3,r12,-4
	      	   ld   	r4,r12,-3
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   push 	r3
	      	   push 	r4
	      	   jsr  	r13,r0,__div32
	      	   pop  	r4
	      	   pop  	r3
	      	   mov  	r5,r2
	      	   sto  	r1,r12,-8
	      	   sto  	r5,r12,-7
	# 	d = (x >> 15) | (x << (31-15));
	      	   ld   	r6,r12,-8
	      	   ld   	r7,r12,-7
	      	   mov  	r3,r0,15
	      	   mov  	r4,r0
	      	   or   	r3,r3
	      	mi.mov  	r4,r0,-1
TestLong_8:
	      	   add  	r6,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	   ror  	r7,r0,0
	      	   ror  	r6,r0,0
	      	   sub  	r3,r0,1
	      	nz.dec  	r15,TestLong_8-PC
	      	   ld   	r3,r12,-8
	      	   ld   	r4,r12,-7
	      	   push 	r1
	      	   push 	r5
	      	   mov  	r5,r0,31
	      	   sub  	r1,r5,15
	      	   mov  	r5,r0
	      	   or   	r1,r1
	      	mi.mov  	r5,r0,-1
TestLong_9:
	      	   add  	r3,r0,0
	      	   adc  	r4,r0,0
	      	   sub  	r1,r0,1
	      	nz.dec  	r15,TestLong_9-PC
	      	   mov  	r1,r6
	      	   mov  	r5,r7
	      	   or   	r1,r3
	      	   or   	r5,r4
	      	   sto  	r1,r12,-4
	      	   sto  	r5,r12,-3
	      	   pop  	r5
	      	   pop  	r1
	# 	r = d < x;
	      	   mov  	r1,r0,1
	      	   mov  	r5,r0
	      	   ld   	r6,r12,-4
	      	   ld   	r7,r12,-3
	      	   ld   	r3,r12,-8
	      	   ld   	r4,r12,-7
	      	   cmp  	r6,r3
	      	   cmpc 	r7,r4
	      	pl.mov  	r1,r0
	      	   sto  	r1,r12,-9
	# 	r2 = d > x;
	      	   mov  	r1,r0
	      	   mov  	r5,r0
	      	   ld   	r6,r12,-4
	      	   ld   	r7,r12,-3
	      	   ld   	r3,r12,-8
	      	   ld   	r4,r12,-7
	      	   cmp  	r6,r3
	      	   cmpc 	r7,r4
	      	pl.mov  	r1,r0,1
	      	   sto  	r1,r12,-12
	      	   sto  	r5,r12,-11
	# 	return c;
	      	   ld   	r1,r12,-2
	      	   ld   	r5,r12,-1
	      	   mov  	r2,r5
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
#	extern	_TestLong
