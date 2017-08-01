	code
	align	16
public code _TestArrayAssign:
	      	sub  	r14,r0,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r0,30
	# 	x[2][4] = 10;
	      	lea  	r5,r12,-30
	      	mov  	r5,r0,10
	      	sto  	r5,r5,20
TestArrayAssign_4:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r0,4
	      	mov  	r15,r13,0
endpublic



public code _TestArrayAssign2:
	      	sub  	r14,r0,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r0,30
	# 	x[2] = {10,9,8,7,6};
	      	lea  	r5,r12,-30
	      	mov  	r5,r0,10
	      	sto  	r5,r5,12
	      	mov  	r5,r0,9
	      	sto  	r5,r5,14
	      	mov  	r5,r0,8
	      	sto  	r5,r5,16
	      	mov  	r5,r0,7
	      	sto  	r5,r5,18
	      	mov  	r5,r0,6
	      	sto  	r5,r5,20
TestArrayAssign_8:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r0,4
	      	mov  	r15,r13,0
endpublic



	rodata
	align	16
;	global	_TestArrayAssign
;	global	_TestArrayAssign2
