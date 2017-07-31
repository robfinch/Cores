	code
	align	16
_TestDivmod:
	      	sub  	r14,r0,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	return a / b;
	      	ld   	r1,r12,2
	      	ld   	r2,r12,4
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_div
TestDivmod_4:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
_TestDivmod2:
	      	sub  	r14,r0,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	return a / 10;
	      	ld   	r1,r12,2
	      	mov  	r2,r0,10
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_div
TestDivmod_8:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
_TestMod:
	      	sub  	r14,r0,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	return a % b;
	      	ld   	r1,r12,2
	      	ld   	r2,r12,4
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_mod
TestDivmod_12:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
_TestDivmod3:
	      	sub  	r14,r0,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	a /= b;
	      	ld   	r1,r12,2
	      	ld   	r2,r12,4
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_div
	      	sto  	r1,r12,2
	# 	return a;
	      	ld   	r1,r12,2
TestDivmod_16:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
_TestModu:
	# 	return a % b;
	      	mov  	r1,r8,0
	      	mov  	r2,r9,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_modu
TestDivmod_20:
	      	mov  	r15,r13,0
	rodata
	align	16
	extern	_TestMod
	extern	_TestDivmod
	extern	_TestDivmod2
	extern	_TestModu
	extern	_TestDivmod3
