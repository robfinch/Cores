	code
	align	16
_TestShiftLeft:
; int TestShiftLeft(register int a, register int b)
	      	sub  	r14,r14,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r14,0
; 	return a << b;
	      	ld   	r5,r8
	      	ld   	r6,r9
TestShift_4:
	      	add  	r5,r5,0
	      	sub  	r6,r6,1
	      	nz.mov  	r15,r0,TestShift_4
	      	mov  	r1,r5
TestShift_5:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r14,2
	      	mov  	r15,r13,0
_TestShiftRight:
; int TestShiftLeft(register int a, register int b)
	      	sub  	r14,r14,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r14,0
; 	return a >> b;
	      	ld   	r5,r12,2
	      	ld   	r6,r12,4
TestShift_9:
	      	add  	r5,r0,0
	      	pl.add  	r0,r0,0
	      	mi.sub  	r0,r0,1
	      	ror  	r5,r5,0
	      	sub  	r6,r6,1
	      	nz.mov  	r15,r0,TestShift_9
	      	mov  	r1,r5
TestShift_10:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r14,2
	      	mov  	r15,r13,0
_TestShiftLeftI1:
; int TestShiftLeft(register int a, register int b)
	      	sub  	r14,r14,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r14,0
; 	return a << 1;
	      	ld   	r5,r12,2
	      	add  	r1,r5,0
TestShift_14:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r14,2
	      	mov  	r15,r13,0
_TestShiftLeftI5:
; int TestShiftLeft(register int a, register int b)
	      	sub  	r14,r14,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r14,0
; 	return a << 1;
	      	ld   	r5,r12,2
	      	add  	r1,r5,0
TestShift_18:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r14,2
	      	mov  	r15,r13,0
_TestShiftRight:
; int TestShiftLeft(register int a, register int b)
	      	sub  	r14,r14,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r14,0
; 	return a >> b;
	      	ld   	r5,r12,2
	      	ld   	r6,r12,4
	      	add  	r6,r6,0
	      	mi.sub  	r6,r6,0
TestShift_22:
	      	add  	r0,r0,0
	      	ror  	r5,r5,0
	      	sub  	r6,r6,1
	      	nz.mov  	r15,r0,TestShift_22
	      	mov  	r1,r5
TestShift_23:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r14,2
	      	mov  	r15,r13,0
	rodata
	align	16
	extern	_TestShiftLeftI1
	extern	_TestShiftLeftI5
	extern	_TestShiftLeft
	extern	_TestShiftRight
	extern	_TestShiftRight
