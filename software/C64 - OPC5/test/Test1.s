	code
_main:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,1
	# 	for (x = 0; x < 10; x++)  {
	      	sto  	r0,r12,-1
Test1_8:
	      	ld   	r5,r12,-1
	      	cmp  	r5,r0,10
	      	pl.mov  	r15,r0,Test1_9
	# 		printf("Hello World!");
	      	mov  	r5,r0,Test1_1
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	ld   	r5,r12,-1
	      	add  	r5,r0,1
	      	sto  	r5,r12,-1
	      	mov  	r15,r0,Test1_8
Test1_9:
	# 	switch(argc) {
	      	ld   	r5,r12,2
	# 	case 1:	printf("One"); break;
	      	cmp  	r6,r5,1
	      	z.mov  	r15,r0,Test1_17
	# 	case 2:	printf("Two"); break;
	      	cmp  	r6,r5,2
	      	z.mov  	r15,r0,Test1_18
	# 	case 3:	printf("Three"); break;
	      	cmp  	r6,r5,3
	      	z.mov  	r15,r0,Test1_19
	      	mov  	r15,r0,Test1_12
Test1_17:
	      	mov  	r5,r0,Test1_2
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	mov  	r15,r0,Test1_12
Test1_18:
	      	mov  	r5,r0,Test1_3
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	mov  	r15,r0,Test1_12
Test1_19:
	      	mov  	r5,r0,Test1_4
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	mov  	r15,r0,Test1_12
Test1_12:
	# 	exit(0);
	      	sub  	r14,r0,1
	      	sto  	r0,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_exit
	      	add  	r14,r0,1
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,1
	      	add  	r14,r0,2
	      	mov  	r15,r13,0
	rodata
	align	2
Test1_4:	; Three
	word	84,104,114,101,101,0
Test1_3:	; Two
	word	84,119,111,0
Test1_2:	; One
	word	79,110,101,0
Test1_1:	; Hello World!
	word	72,101,108,108,111,32,87,111
	word	114,108,100,33,0
	extern	_main
	extern	_exit
	extern	_printf
