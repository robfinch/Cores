#	code
_ZBBAA_ClassTest:
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,2
	      	   push 	r2
	      	   mov  	r1,r0
	      	   add  	r1,r12,-1
	      	   mov  	r2,r1
	# 	a.a = a.a + b.a;
	      	   ld   	r1,r2,1
	      	   mov  	r2,r0
	      	   add  	r2,r12,-2
	      	   ld   	r2,r2,1
	      	   add  	r1,r2
	      	   sto  	r1,r2,1
	      	   pop  	r2
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13


_ZBBAAMBAA_AddQAAAQAAA:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	# 	return a + b + c + d;
	      	   ld   	r5,r11,1
	      	   ld   	r6,r11,2
	      	   add  	r5,r6
	      	   ld   	r6,r12,2
	      	   add  	r5,r6
	      	   ld   	r6,r12,3
	      	   add  	r1,r6
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
#	global	_ClassTest
#	extern	_Add
