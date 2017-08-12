#	code
_TestStruct:
	# typedef struct _tagTestStruct
	      	   push 	r13,r14
	      	   push 	r12,r14
	      	   mov  	r12,r14
	# 	TestStruct ts;
	      	   dec  	r14,3
	# 	ts.a = 1;
	      	   mov  	r5,r0,1
	      	   sto  	r5,r12,-3
	# 	ts.b = 2;
	      	   mov  	r6,r12,-3
	      	   mov  	r5,r6
	      	   mov  	r6,r0,2
	      	   sto  	r6,r5,1
	# 	ts.c = 3;
	      	   mov  	r6,r12,-3
	      	   mov  	r5,r6
	      	   mov  	r6,r0,3
	      	   ld   	r7,r5,2
	      	   and  	r6,r0,16383
	      	   and  	r7,r0,-16384
	      	   or   	r7,r6,0
	      	   sto  	r7,r5,2
	# 	ts.d = 1;
	      	   mov  	r6,r12,-3
	      	   mov  	r5,r6
	      	   mov  	r6,r0,1
	      	   ld   	r7,r5,2
	      	   and  	r6,r0,3
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
	      	   and  	r7,r0,-4
	      	   or   	r7,r6,0
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   adc  	r7,r0,14
	      	   sto  	r7,r5,2
	# 	return (ts.c+ts.d);
	      	   mov  	r3,r12,-3
	      	   mov  	r7,r3
	      	   ld   	r7,r7,2
	      	   mov  	r6,r7,0
	      	   and  	r6,r0,16383
	      	   mov  	r7,r0,-8192
	      	   add  	r6,r0,r7
	      	   xor  	r6,r0,r7
	      	   mov  	r4,r12,-3
	      	   mov  	r3,r4
	      	   ld   	r3,r3,2
	      	   mov  	r7,r3,0
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
	      	   mov  	r3,r0,-2
	      	   add  	r7,r0,r3
	      	   xor  	r7,r0,r3
	      	   mov  	r5,r6
	      	   add  	r1,r7
	      	   mov  	r14,r12
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
_TestStruct2:
	# typedef struct _tagTestStruct
	      	   push 	r13,r14
	      	   push 	r12,r14
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
	      	   pop  	r12,r14
	      	   pop  	r13,r14
	      	   mov  	r15,r13
#	rodata
#	extern	_TestStruct2
