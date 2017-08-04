#	code
_main:
	      	   push 	r13
	      	   push 	r12
	      	   mov  	r12,r14
	      	   dec  	r14,1
	# 	for (x = 0; x < 10; x++)  {
	      	   sto  	r0,r12,-1
Test1_8:
	      	   ld   	r5,r12,-1
	      	   cmp  	r5,r0,10
	      	mi.inc  	r15,Test1_9-PC
	# 		printf("Hello World!");
	      	   mov  	r5,r0,Test1_1
	      	   push 	r5
	      	   jsr  	r13,r0,_printf
	      	   inc  	r14,1
	      	   ld   	r5,r12,-1
	      	   inc  	r5,1
	      	   sto  	r5,r12,-1
	      	   mov  	r15,r0,Test1_8
Test1_9:
	# 	switch(argc) {
	      	   ld   	r5,r12,2
	# 	case 1:	printf("One"); break;
	      	   cmp  	r6,r5,1
	      	 z.inc  	r15,Test1_16-PC
	# 	case 2:	printf("Two"); break;
	      	   cmp  	r6,r5,2
	      	 z.mov  	r15,r0,Test1_17
	# 	case 3:	printf("Three"); break;
	      	   cmp  	r6,r5,3
	      	 z.mov  	r15,r0,Test1_18
	      	   mov  	r15,r0,Test1_11
Test1_16:
	      	   mov  	r5,r0,Test1_2
	      	   push 	r5
	      	   jsr  	r13,r0,_printf
	      	   inc  	r14,1
	      	   mov  	r15,r0,Test1_11
Test1_17:
	      	   mov  	r5,r0,Test1_3
	      	   push 	r5
	      	   jsr  	r13,r0,_printf
	      	   inc  	r14,1
	      	   inc  	r15,Test1_11-PC
Test1_18:
	      	   mov  	r5,r0,Test1_4
	      	   push 	r5
	      	   jsr  	r13,r0,_printf
	      	   inc  	r14,1
Test1_11:
	# 	exit(0);
	      	   push 	r0
	      	   jsr  	r13,r0,_exit
	      	   inc  	r14,1
	      	   mov  	r14,r12
	      	   pop  	r13
	      	   pop  	r12
	      	   mov  	r15,r13
#	rodata
	align	2
Test1_4:	# Three
	word	84,104,114,101,101,0
Test1_3:	# Two
	word	84,119,111,0
Test1_2:	# One
	word	79,110,101,0
Test1_1:	# Hello World!
	word	72,101,108,108,111,32,87,111
	word	114,108,100,33,0
#	extern	_main
#	extern	_exit
#	extern	_printf
