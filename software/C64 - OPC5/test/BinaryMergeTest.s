	code
_BinaryMergeTest:
	      	sub  	r14,r0,1
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	return a + a;
	      	ld   	r1,r12,1
	      	add  	r1,r1,0
BinaryMergeTest_4:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,1
	      	mov  	r15,r13,0
	rodata
	extern	_BinaryMergeTest
