	code
_BinaryMergeTest:
	# 	return a + b + 1;
	      	add  	r8,r9,0
	      	add  	r8,r0,1
	      	mov  	r1,r8,0
BinaryMergeTest_4:
	      	mov  	r15,r13,0
	rodata
	extern	_BinaryMergeTest
