#	code
	# class ClassTest
_ZBBAA_ClassTest:
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,2
	      	   push 	r3
	# 	ClassTest a, b;
	      	   mov  	r3,r0,1
	# 	a.a = a.a + b.a;
	      	   mov  	r1,r12,-1
	      	   mov  	r5,r1
	      	   add  	r1,r3
	      	   mov  	r6,r12,-1
	      	   mov  	r7,r6
	      	   add  	r6,r3
	      	   mov  	r7,r12,-2
	      	   push 	r1
	      	   mov  	r1,r7
	      	   add  	r7,r3
	      	   mov  	r5,r6
	      	   add  	r5,r7
	      	   sto  	r5,r1
	      	   pop  	r1
	# 	return a.a;
	      	   mov  	r1,r12,-1
	      	   mov  	r5,r1
	      	   add  	r1,r3
	      	   pop  	r3
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13




_ZBBAAMBAA_AddQAAAQAAA:
	# class ClassTest
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a + b + c + d;
	      	   push 	r5
	      	   ld   	r5,r11,1
	      	   push 	r6
	      	   ld   	r6,r11,2
	      	   mov  	r7,r5
	      	   add  	r7,r6
	      	   ld   	r5,r12,2
	      	   mov  	r6,r7
	      	   add  	r6,r5
	      	   ld   	r7,r12,3
	      	   mov  	r5,r6
	      	   add  	r5,r7
	      	   pop  	r6
	      	   mov  	r1,r5
	      	   pop  	r5
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   pop  	r13
	      	   mov  	r15,r13
#	rodata
#	global	_ClassTest
#	extern	_Add
