#	code
	# int TestDo(int c)
_TestDo:
	      	   push 	r12,r14
	      	   mov  	r12,r14
TestDo_4:
	# 		c--;
	      	   ld   	r1,r12,1
	      	   dec  	r1,1
	      	   sto  	r1,r12,1
	      	   ld   	r1,r12,1
	      	   cmp  	r1,r0
	      	 z.inc  	r15,TestDo_6-PC
	      	   cmp  	r1,r0
	      	pl.inc  	r15,TestDo_4-PC
TestDo_6:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestDo(int c)
_TestDo1:
	      	   push 	r12,r14
	      	   mov  	r12,r14
TestDo_11:
	# 		d++;
	      	   ld   	r1,r12,1
	      	   inc  	r1,1
	      	   sto  	r1,r12,1
	      	   ld   	r1,r12,1
	      	   cmp  	r1,r0,10
	      	nz.inc  	r15,TestDo_11-PC
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestDo(int c)
_TestWhile:
	      	   push 	r12,r14
	      	   mov  	r12,r14
TestDo_17:
	      	   ld   	r1,r12,1
	      	   cmp  	r1,r0
	      	mi.inc  	r15,TestDo_18-PC
	# 		e--;
	      	   ld   	r1,r12,1
	      	   dec  	r1,1
	      	   sto  	r1,r12,1
	      	   inc  	r15,TestDo_17-PC
TestDo_18:
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
	# int TestDo(int c)
_TestWhile2:
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	int x;
	      	   dec  	r14,1
	# 	x = 0;
	      	   sto  	r0,r12,-1
TestDo_23:
	# 		g++;
	      	   ld   	r1,r12,1
	      	   inc  	r1,1
	      	   sto  	r1,r12,1
	      	   ld   	r1,r12,1
	      	   ld   	r5,r12,-1
	      	   cmp  	r1,r5
	      	mi.inc  	r15,TestDo_23-PC
	      	   cmp  	r1,r5
	      	 z.inc  	r15,TestDo_23-PC
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_TestWhile2
#	extern	_TestDo
#	extern	_TestDo1
#	extern	_TestWhile
