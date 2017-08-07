#	code
_TestStruct:
	# typedef struct _tagTestStruct
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,3
	      	   push 	r3
	      	   push 	r4
	      	   mov  	r4,r0,2
	      	   mov  	r5,r12,-3
	# 	TestStruct ts;
	      	   mov  	r3,r5
	# 	ts.a = 1;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r3
	# 	ts.b = 2;
	      	   sto  	r4,r3,1
	# 	ts.c = 3;
	      	   mov  	r5,r3
	      	   add  	r5,r4
	      	   mov  	r6,r0,3
	      	   and  	r6,r0,16383
	      	   and  	r5,r0,-16384
	      	   or   	r5,r6,0
	# 	ts.d = 1;
	      	   mov  	r5,r3
	      	   add  	r5,r4
	      	   mov  	r6,r0,1
	      	   and  	r6,r0,3
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   ror  	r5,r0,0
	      	   and  	r5,r0,-4
	      	   or   	r5,r6,0
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	      	   adc  	r5,r0,14
	# 	return (ts.c+ts.d);
	      	   mov  	r7,r3
	      	   add  	r7,r4
	      	   mov  	r6,r7,0
	      	   and  	r6,r0,16383
	      	   mov  	r7,r0,-8192
	      	   add  	r6,r0,r7
	      	   xor  	r6,r0,r7
	      	   push 	r5
	      	   mov  	r5,r3
	      	   add  	r5,r4
	      	   mov  	r7,r5,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   ror  	r7,r0,0
	      	   and  	r7,r0,3
	      	   mov  	r5,r0,-2
	      	   add  	r7,r0,r5
	      	   xor  	r7,r0,r5
	      	   mov  	r5,r6
	      	   add  	r1,r7
	      	   pop  	r5
	      	   pop  	r4
	      	   pop  	r3
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   pop  	r13
	      	   mov  	r15,r13
_TestStruct2:
	# typedef struct _tagTestStruct
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	# 	TestStruct b;
	      	   dec  	r14,3
	# 	b.a = a;
	      	   sto  	r8,r12,-3
	# 	return (b);
	      	   mov  	r5,r12,-3
	      	   ld   	r7,r12,3
	      	   ld   	r6,r5
	      	   sto  	r6,r7
	      	   ld   	r6,r5,1
	      	   sto  	r6,r7,1
	      	   ld   	r6,r5,2
	      	   sto  	r6,r7,2
	      	   mov  	r14,r12
	      	   pop  	r12
	      	   pop  	r13
	      	   mov  	r15,r13
#	rodata
#	extern	_TestStruct2
