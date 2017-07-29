	bss
	align	2
public bss _ary:
	fill.w	900,0x00

endpublic
	code
	align	16
	data
	align	8
	align	8
	code
	align	16
_main:
; int ary[20][45];
	      	sub  	r14,r0,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r0,10
; 	for (y = 0; y < argc; y++) {
	      	sto  	r0,r12,-6
test2_8:
	      	ld   	r5,r12,-6
	      	ld   	r6,r12,4
	      	ld   	r7,r12,-6
	      	ld   	r8,r12,4
	      	cmp  	r7,r8,0
	      	pl.mov  	r15,r0,r0,test2_9
test2_11:
; 		for (z = 0; z < 45; z++)
	      	sto  	r0,r12,-10
test2_12:
	      	ld   	r5,r12,-10
	      	ld   	r6,r12,-10
	      	cmp  	r6,r0,45
	      	pl.mov  	r15,r0,r0,test2_13
test2_15:
; 			ary[y][z] = rand();
	      	ld   	r5,r12,-10
	      	add  	r5,r5,0
	      	ld   	r6,r12,-6
	      	mov  	r1,r6,0
	      	mov  	r2,40,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_mulu
	      	add  	r1,r0,_ary
	      	mov  	r6,r5,0
	      	add  	r5,r1,0
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_rand
	      	ld   	r5,r14,0
	      	add  	r14,r0,2
	      	mov  	r5,r1
test2_14:
	      	ld   	r5,r12,-10
	      	add  	r5,r5,1
	      	sto  	r5,r12,-10
	      	mov  	r15,r0,r0,test2_12
test2_13:
test2_10:
	      	ld   	r5,r12,-6
	      	add  	r5,r5,1
	      	sto  	r5,r12,-6
	      	mov  	r15,r0,r0,test2_8
test2_9:
; 	for (x = 0; x < 10; x++)  {
	      	sto  	r0,r12,-2
test2_16:
	      	ld   	r5,r12,-2
	      	ld   	r6,r12,-2
	      	cmp  	r6,r0,10
	      	pl.mov  	r15,r0,r0,test2_17
test2_19:
; 		printf("Hello World!");
	      	mov  	r5,r0,test2_1
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_printf
	      	add  	r14,r0,2
test2_18:
	      	ld   	r5,r12,-2
	      	add  	r5,r5,1
	      	sto  	r5,r12,-2
	      	mov  	r15,r0,r0,test2_16
test2_17:
; 	naked switch(argc) {
	      	ld   	r5,r12,4
; 	case 1:	printf("One"); break;
	      	cmp  	r6,r5,1
	      	z.mov  	r15,r0,r0,test2_25
; 	case 2:	printf("Two"); break;
	      	cmp  	r6,r5,2
	      	z.mov  	r15,r0,r0,test2_26
; 	case 3:	printf("Three"); break;
	      	cmp  	r6,r5,3
	      	z.mov  	r15,r0,r0,test2_27
	      	mov  	r15,r0,r0,test2_20
test2_25:
	      	mov  	r5,r0,test2_2
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_printf
	      	add  	r14,r0,2
	      	mov  	r15,r0,r0,test2_20
test2_26:
	      	mov  	r5,r0,test2_3
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_printf
	      	add  	r14,r0,2
	      	mov  	r15,r0,r0,test2_20
test2_27:
	      	mov  	r5,r0,test2_4
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_printf
	      	add  	r14,r0,2
	      	mov  	r15,r0,r0,test2_20
test2_20:
; 	exit(0);
	      	sub  	r14,r0,2
	      	sto  	r0,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,r0,_exit
	      	add  	r14,r0,2
test2_28:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r0,4
	      	mov  	r15,r13,0
	rodata
	align	16
	align	2
test2_4:	; Three
	word	84,104,114,101,101,0
test2_3:	; Two
	word	84,119,111,0
test2_2:	; One
	word	79,110,101,0
test2_1:	; Hello World!
	word	72,101,108,108,111,32,87,111
	word	114,108,100,33,0
	extern	_main
	extern	_rand
	extern	_exit
;	global	_ary
	extern	_printf
