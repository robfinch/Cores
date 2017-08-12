#	code
	# int TestIf(int a, int b)
_TestIf:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	if (a < b)
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,2
	      	   cmp  	r1,r5
	      	pl.inc  	r15,TestIf_4-PC
	# 		return a;
	      	   ld   	r1,r12,1
TestIf_7:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
TestIf_4:
	# 	elsif (a==10)
	      	   ld   	r1,r12,1
	      	   cmp  	r1,r0,10
	# 		return 10;
	      	nz.inc  	r15,TestIf_8-PC
	      	   mov  	r1,r0,10
	      	   mov  	r15,r0,TestIf_7
	      	   inc  	r15,TestIf_9-PC
TestIf_8:
	# 		return b;
	      	   ld   	r1,r12,2
	      	   mov  	r15,r0,TestIf_7
TestIf_9:
	      	   mov  	r15,r0,TestIf_7
	# int TestIf(int a, int b)
_TestIf2:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	if (a and b)
	      	   ld   	r1,r12,1
	      	   add  	r1,r0
	      	 z.mov  	r15,r0,TestIf_13
	      	   ld   	r1,r12,2
	      	   add  	r1,r0
	      	 z.inc  	r15,TestIf_13-PC
	# 		return a;
	      	   ld   	r1,r12,1
TestIf_15:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
TestIf_13:
	# 	elsif (a or b)
	      	   ld   	r1,r12,1
	      	   add  	r1,r0
	      	nz.inc  	r15,TestIf_18-PC
	      	   ld   	r1,r12,2
	      	   add  	r1,r0
	      	 z.inc  	r15,TestIf_16-PC
TestIf_18:
	      	   mov  	r1,r0,10
	      	   mov  	r15,r0,TestIf_15
	      	   inc  	r15,TestIf_17-PC
TestIf_16:
	# 		return b;
	      	   ld   	r1,r12,2
	      	   mov  	r15,r0,TestIf_15
TestIf_17:
	      	   mov  	r15,r0,TestIf_15
#	rodata
#	extern	_TestIf
#	extern	_TestIf2
