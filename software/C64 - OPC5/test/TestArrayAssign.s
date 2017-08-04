#	code
_TestArrayAssign:
	      	   push 	r12
	      	   mov  	r12,r14
	      	   sub  	r14,r0,53
	# 	y[0] = 1;
	      	   mov  	r1,r0,1
	      	   sto  	r1,r12,-23
	# 	y[1] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,1
	# 	y[2] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,2
	# 	y[3] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,3
	# 	y[4] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,4
	# 	y[5] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,5
	# 	y[6] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,6
	# 	y[7] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,7
	# 	y = {1,2,3,4,5,6,7,8};
	      	   mov  	r1,r0
	      	   add  	r1,r12,-23
	# 	x[0][0] = 1;
	      	   mov  	r1,r0,1
	      	   sto  	r1,r12,-15
	# 	x[0][1] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,1
	# 	x[0][2] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,2
	# 	x[0][3] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,3
	# 	x[0][4] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,4
	# 	x[1][0] = 3;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,3
	      	   sto  	r2,r1,5
	# 	x[1][1] = 3;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,3
	      	   sto  	r2,r1,6
	# 	x[1][2] = 3;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,3
	      	   sto  	r2,r1,7
	# 	x[1][3] = 3;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,3
	      	   sto  	r2,r1,8
	# 	x[1][4] = 5;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,5
	      	   sto  	r2,r1,9
	# 	x[2][0] = 5;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,5
	      	   sto  	r2,r1,10
	# 	x[2][1] = 5;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,5
	      	   sto  	r2,r1,11
	# 	x[2][2] = 5;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,5
	      	   sto  	r2,r1,12
	# 	x[2][3] = 5;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,5
	      	   sto  	r2,r1,13
	# 	x[2][4] = 5;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-15
	      	   mov  	r2,r0,5
	      	   sto  	r2,r1,14
	# 	z[0][0][0] = 1;
	      	   mov  	r1,r0,1
	      	   sto  	r1,r12,-53
	# 	z[0][0][1] = 1;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,1
	      	   sto  	r2,r1,1
	# 	z[0][0][2] = 1;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,1
	      	   sto  	r2,r1,2
	# 	z[0][0][3] = 1;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,1
	      	   sto  	r2,r1,3
	# 	z[0][0][4] = 1;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,1
	      	   sto  	r2,r1,4
	# 	z[0][1][0] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,5
	# 	z[0][1][1] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,6
	# 	z[0][1][2] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,7
	# 	z[0][1][3] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,8
	# 	z[0][1][4] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,9
	# 	z[0][2][0] = 2;
	      	   mov  	r1,r0
	      	   add  	r1,r12,-53
	      	   mov  	r2,r0,2
	      	   sto  	r2,r1,10
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   mov  	r15,r13


_TestArrayAssign2:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,15
	# 	x[2] = {10,9,8,7,6};
	      	   mov  	r5,r0,10
	      	   mov  	r6,r0
	      	   add  	r6,r12,-15
	      	   add  	r5,r6
	      	   mov  	r6,r5
	      	   mov  	r7,r0,10
	      	   sto  	r7,r6,10
	      	   mov  	r7,r0,9
	      	   sto  	r7,r6,11
	      	   mov  	r7,r0,8
	      	   sto  	r7,r6,12
	      	   mov  	r7,r0,7
	      	   sto  	r7,r6,13
	      	   mov  	r7,r0,6
	      	   sto  	r7,r6,14
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13


_TestArrayAssign3:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   sub  	r14,r0,63
	# 	for (m = 0; m < 3; m++) {
	      	   sto  	r0,r12,-3
TestArrayAssign_12:
	      	   ld   	r5,r12,-3
	      	   cmp  	r5,r0,3
	      	mi.mov  	r15,r0,TestArrayAssign_13
	# 		for (j = 0; j < 4; j++) {
	      	   sto  	r0,r12,-1
TestArrayAssign_15:
	      	   ld   	r5,r12,-1
	      	   cmp  	r5,r0,4
	      	mi.mov  	r15,r0,TestArrayAssign_16
	# 			for (k = 0; k < 5; k++)
	      	   sto  	r0,r12,-2
TestArrayAssign_18:
	      	   ld   	r5,r12,-2
	      	   cmp  	r5,r0,5
	      	mi.mov  	r15,r0,TestArrayAssign_19
	# 				x[m][j][k] = rand();
	      	   ld   	r5,r12,-2
	      	   ld   	r6,r12,-1
	      	   mov  	r7,r0,5
	      	   mov  	r1,r6
	      	   mov  	r2,r7
	      	   jsr  	r13,r0,_mulu
	      	   mov  	r6,r1
	      	   ld   	r7,r12,-3
	      	   push 	r5
	      	   mov  	r5,r0,20
	      	   mov  	r1,r7
	      	   mov  	r2,r5
	      	   jsr  	r13,r0,_mulu
	      	   mov  	r7,r1
	      	   mov  	r5,r0
	      	   add  	r5,r12,-63
	      	   add  	r7,r5
	      	   add  	r6,r7
	      	   mov  	r7,r5
	      	   add  	r5,r6
	      	   jsr  	r13,r0,_rand
	      	   sto  	r1,r5,0
	      	   pop  	r5
	      	   ld   	r5,r12,-2
	      	   inc  	r5,1
	      	   sto  	r5,r12,-2
	      	   mov  	r15,r0,TestArrayAssign_18
TestArrayAssign_19:
	      	   ld   	r5,r12,-1
	      	   inc  	r5,1
	      	   sto  	r5,r12,-1
	      	   mov  	r15,r0,TestArrayAssign_15
TestArrayAssign_16:
	      	   ld   	r5,r12,-3
	      	   inc  	r5,1
	      	   sto  	r5,r12,-3
	      	   mov  	r15,r0,TestArrayAssign_12
TestArrayAssign_13:
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13


#	rodata
#	extern	_rand
#	global	_TestArrayAssign
#	global	_TestArrayAssign2
#	global	_TestArrayAssign3
