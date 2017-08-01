	data
	code
_TestStruct:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,6
	      	sub  	r14,r0,1
	      	sto  	r2,r14,0
	      	mov  	r5,r0,0
	      	add  	r5,r12,-6
	      	mov  	r2,r5
	# 	ts.a = 1;
	      	mov  	r5,r0,1
	      	sto  	r5,r2,0
	# 	ts.b = 2;
	      	mov  	r5,r0,2
	      	sto  	r5,r2,2
	# 	ts.c = 3;
	      	mov  	r5,r0,3
	      	ld   	r6,r2,4
	      	and  	r5,r0,16383
	      	and  	r6,r0,-16384
	      	or   	r6,r5,0
	      	sto  	r6,r2,4
	# 	ts.d = 1;
	      	mov  	r5,r0,1
	      	ld   	r6,r2,4
	      	and  	r5,r0,3
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	and  	r6,r0,-4
	      	or   	r6,r5,0
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	adc  	r6,r0,14
	      	sto  	r6,r2,4
	# 	return (ts.c+ts.d);
	      	ld   	r6,r2,4
	      	mov  	r5,r6,0
	      	and  	r5,r0,16383
	      	mov  	r6,r0,-8192
	      	add  	r5,r0,r6
	      	xor  	r5,r0,r6
	      	ld   	r7,r2,4
	      	mov  	r6,r7,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	ror  	r6,r0,0
	      	and  	r6,r0,3
	      	mov  	r7,r0,-2
	      	add  	r6,r0,r7
	      	xor  	r6,r0,r7
	      	add  	r1,r6,0
TestStruct_4:
	      	ld   	r2,r14,1
	      	add  	r14,r0,1
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
_TestStruct2:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,6
	# 	b.a = a;
	      	sto  	r8,r12,-6
	# 	return b;
	      	mov  	r5,r0,0
	      	add  	r5,r12,-6
	      	ld   	r1,r12,0
	      	mov  	r2,r0,5
	      	sub  	r14,r0,3
	      	sto  	r2,r14,2
	      	sto  	r5,r14,1
	      	sto  	r1,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_memcpy
	      	add  	r14,r0,3
TestStruct_8:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
	rodata
	extern	_TestStruct2
