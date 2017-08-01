	code
_ZBBAA_ClassTest:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,4
	      	sub  	r14,r0,2
	      	sto  	r2,r14,0
	      	sto  	r3,r14,1
	      	mov  	r5,r0,0
	      	add  	r5,r12,-3
	      	mov  	r2,r5
	      	mov  	r5,r0,0
	      	add  	r5,r12,-1
	      	mov  	r3,r5
	# 	a.a = a.a + b.a + g.c + g.a;
	      	ld   	r5,r3,1
	      	mov  	r6,r0,0
	      	add  	r6,r12,-2
	      	ld   	r6,r6,1
	      	add  	r5,r6,0
	      	ld   	r6,r2,2
	      	add  	r5,r6,0
	      	ld   	r6,r2,1
	      	add  	r5,r6,0
	      	sto  	r5,r3,1
	# 	return a.a;
	      	ld   	r1,r3,1
ClassTest_4:
	      	ld   	r3,r14,2
	      	ld   	r2,r14,1
	      	add  	r14,r0,2
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0


_ZBBAAMBAA_AddQAAAQAAA:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	return a + b + c + d;
	      	ld   	r5,r11,1
	      	ld   	r6,r11,2
	      	add  	r5,r6,0
	      	ld   	r6,r12,2
	      	add  	r5,r6,0
	      	ld   	r6,r12,3
	      	add  	r1,r6,0
ClassTest_8:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
	rodata
;	global	_ClassTest
	extern	_Add
