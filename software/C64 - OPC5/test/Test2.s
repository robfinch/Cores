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
	      	sub  	r14,r14,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r14,10
Test2_8:
	      	ld   	r5,r12,-6
	      	ld   	r6,r12,4
	      	ld   	r7,r12,-6
	      	ld   	r8,r12,4
	      	cmp  	r7,r8,0
	      	pl.mov  	r15,r0,Test2_9
Test2_11:
Test2_12:
	      	ld   	r5,r12,-10
	      	ld   	r6,r12,-10
	      	cmp  	r6,r0,45
	      	pl.mov  	r15,r0,Test2_13
Test2_15:
	      	ld   	r5,r12,-10
	      	add  	r5,r5,0
	      	ld   	r7,r12,-6
	      	mov  	r1,r7,0
	      	mov  	r2,40,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_mulu
	      	add  	r6,r1,_ary
	      	mov  	r7,r5,0
	      	add  	r5,r6,0
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_rand
	      	ld   	r5,r14,0
	      	add  	r14,r14,2
	      	mov  	r5,r1
Test2_14:
	      	ld   	r5,r12,-10
	      	add  	r5,r5,1
	      	sto  	r5,r12,-10
	      	mov  	r15,r0,Test2_12
Test2_13:
Test2_10:
	      	ld   	r5,r12,-6
	      	add  	r5,r5,1
	      	sto  	r5,r12,-6
	      	mov  	r15,r0,Test2_8
Test2_9:
Test2_16:
	      	ld   	r5,r12,-2
	      	ld   	r6,r12,-2
	      	cmp  	r6,r0,10
	      	pl.mov  	r15,r0,Test2_17
Test2_19:
	      	mov  	r5,r0,Test2_1
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
Test2_18:
	      	ld   	r5,r12,-2
	      	add  	r5,r5,1
	      	sto  	r5,r12,-2
	      	mov  	r15,r0,Test2_16
Test2_17:
	      	ld   	r5,r12,4
	      	cmp  	r6,r5,1
	      	z.mov  	r15,r0,Test2_25
	      	cmp  	r6,r5,2
	      	z.mov  	r15,r0,Test2_26
	      	cmp  	r6,r5,3
	      	z.mov  	r15,r0,Test2_27
	      	mov  	r15,r0,Test2_20
Test2_25:
	      	mov  	r5,r0,Test2_2
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
	      	mov  	r15,r0,Test2_20
Test2_26:
	      	mov  	r5,r0,Test2_3
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
	      	mov  	r15,r0,Test2_20
Test2_27:
	      	mov  	r5,r0,Test2_4
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
	      	mov  	r15,r0,Test2_20
Test2_20:
	      	sub  	r14,r14,2
	      	sto  	r0,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_exit
	      	add  	r14,r14,2
Test2_28:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r14,4
	      	mov  	r15,r13,0
	rodata
	align	16
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
