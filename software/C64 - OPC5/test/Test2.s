	bss
_ary:
	fill.w	450,0x00

	code
_main:
	      	sub  	r14,r0,2
	      	sto  	r13,r14,0
	      	sto  	r12,r14,1
	      	mov  	r12,r14,0
	      	sub  	r14,r0,3
	# 	for (y = 0; y < argc; y++) {
	      	sto  	r0,r12,-2
Test2_8:
	      	ld   	r5,r12,-2
	      	ld   	r6,r12,2
	      	cmp  	r5,r6,0
	      	pl.mov  	r15,r0,Test2_9
	# 		for (z = 0; z < 45; z++)
	      	sto  	r0,r12,-3
Test2_12:
	      	ld   	r5,r12,-3
	      	cmp  	r5,r0,45
	      	pl.mov  	r15,r0,Test2_13
	# 			ary[y][z] = rand();
	      	ld   	r5,r12,-3
	      	ld   	r6,r12,-2
	      	mov  	r7,r0,20
	      	mov  	r1,r6,0
	      	mov  	r2,r7,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_mulu
	      	add  	r1,r0,_ary
	      	mov  	r6,r5,0
	      	add  	r5,r1,0
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_rand
	      	ld   	r5,r14,0
	      	add  	r14,r0,1
	      	mov  	r5,r1
	      	ld   	r5,r12,-3
	      	add  	r5,r0,1
	      	sto  	r5,r12,-3
	      	mov  	r15,r0,Test2_12
Test2_13:
	      	ld   	r5,r12,-2
	      	add  	r5,r0,1
	      	sto  	r5,r12,-2
	      	mov  	r15,r0,Test2_8
Test2_9:
	# 	for (x = 0; x < 10; x++)  {
	      	sto  	r0,r12,-1
Test2_16:
	      	ld   	r5,r12,-1
	      	cmp  	r5,r0,10
	      	pl.mov  	r15,r0,Test2_17
	# 		printf("Hello World!");
	      	mov  	r5,r0,Test2_1
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	ld   	r5,r12,-1
	      	add  	r5,r0,1
	      	sto  	r5,r12,-1
	      	mov  	r15,r0,Test2_16
Test2_17:
	# 	naked switch(argc) {
	      	ld   	r5,r12,2
	# 	case 1:	printf("One"); break;
	      	cmp  	r6,r5,1
	      	z.mov  	r15,r0,Test2_25
	# 	case 2:	printf("Two"); break;
	      	cmp  	r6,r5,2
	      	z.mov  	r15,r0,Test2_26
	# 	case 3:	printf("Three"); break;
	      	cmp  	r6,r5,3
	      	z.mov  	r15,r0,Test2_27
	      	mov  	r15,r0,Test2_20
Test2_25:
	      	mov  	r5,r0,Test2_2
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	mov  	r15,r0,Test2_20
Test2_26:
	      	mov  	r5,r0,Test2_3
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	mov  	r15,r0,Test2_20
Test2_27:
	      	mov  	r5,r0,Test2_4
	      	sub  	r14,r0,1
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,1
	      	mov  	r15,r0,Test2_20
Test2_20:
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
Test2_4:	; Three
	word	84,104,114,101,101,0
Test2_3:	; Two
	word	84,119,111,0
Test2_2:	; One
	word	79,110,101,0
Test2_1:	; Hello World!
	word	72,101,108,108,111,32,87,111
	word	114,108,100,33,0
	extern	_main
	extern	_rand
	extern	_exit
;	global	_ary
	extern	_printf
