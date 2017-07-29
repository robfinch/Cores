	code
	align	16
_main:
	      	sub  	r14,r14,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r14,2
Test1_8:
	      	ld   	r5,r12,-2
	      	ld   	r6,r12,-2
	      	cmp  	r6,r0,10
	      	pl.mov  	r15,r0,Test1_9
Test1_11:
	      	mov  	r5,r0,Test1_1
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
Test1_10:
	      	ld   	r5,r12,-2
	      	add  	r5,r5,1
	      	sto  	r5,r12,-2
	      	mov  	r15,r0,Test1_8
Test1_9:
	      	ld   	r5,r12,4
	      	cmp  	r6,r5,1
	      	z.mov  	r15,r0,Test1_17
	      	cmp  	r6,r5,2
	      	z.mov  	r15,r0,Test1_18
	      	cmp  	r6,r5,3
	      	z.mov  	r15,r0,Test1_19
	      	mov  	r15,r0,Test1_12
Test1_17:
	      	mov  	r5,r0,Test1_2
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
	      	mov  	r15,r0,Test1_12
Test1_18:
	      	mov  	r5,r0,Test1_3
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
	      	mov  	r15,r0,Test1_12
Test1_19:
	      	mov  	r5,r0,Test1_4
	      	sub  	r14,r14,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r14,2
	      	mov  	r15,r0,Test1_12
Test1_12:
	      	sub  	r14,r14,2
	      	sto  	r0,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_exit
	      	add  	r14,r14,2
Test1_20:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r14,4
	      	mov  	r15,r13,0
	rodata
	align	16
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
