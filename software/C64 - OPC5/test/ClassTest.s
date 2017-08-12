#	code
	# class ClassTest
_ZBBAA_ClassTest:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	      	   dec  	r14,2
	      	   push 	r3,r14
	# 	ClassTest a, b;
	      	   mov  	r3,r0,1
	# 	a.a = a.a + b.a;
	      	   mov  	r5,r12,-1
	      	   mov  	r1,r5
	      	   add  	r1,r3
	      	   mov  	r7,r12,-1
	      	   mov  	r6,r7
	      	   add  	r6,r3
	      	   ld   	r6,r6
	      	   push 	r1,r14
	      	   mov  	r1,r12,-2
	      	   mov  	r7,r1
	      	   add  	r7,r3
	      	   ld   	r7,r7
	      	   mov  	r5,r6
	      	   add  	r5,r7
	      	   sto  	r5,r1
	      	   pop  	r1,r14
	# 	return a.a;
	      	   mov  	r5,r12,-1
	      	   mov  	r1,r5
	      	   add  	r1,r3
	      	   ld   	r1,r1
	      	   pop  	r3,r14
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13


_ZBBAAMBAA_AddQAAAQAAA:
	# class ClassTest
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	return a + b + c + d;
	      	   ld   	r3,r11,1
	      	   ld   	r4,r11,2
	      	   mov  	r7,r3
	      	   add  	r7,r4
	      	   ld   	r3,r12,2
	      	   mov  	r6,r7
	      	   add  	r6,r3
	      	   ld   	r7,r12,3
	      	   mov  	r5,r6
	      	   add  	r1,r7
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
#	rodata
#	global	_ClassTest
#	extern	_Add
