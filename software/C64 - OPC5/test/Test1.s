	code
	align	16
_main:
	      	sub  	r14,r14,#2
	      	sto  	r12,0[r14]
	      	mov  	r12,r14,#0
	      	sub  	r14,r14,#2
Test1_7:
	      	ld   	r5,-2[r12]
	      	ld   	r6,-2[r12]
	      	cmp  	r6,r0,#10
	      	pl.mov  	r15,r0,Test1_8
Test1_10:
	      	sub  	r14,r14,#2
	      	push 	r0
	      	call 	_printf
	      	add  	r14,r14,#2
	      	add  	r14,r14,#2
Test1_9:
	      	ld   	r5,-2[r12]
	      	add  	r5,r5,#1
	      	sto  	r5,-2[r12]
	      	mov  	r15,r0,Test1_7
Test1_8:
	      	ld   	r5,6[r12]
	      	cmp  	r6,r5,#1
	      	z.mov  	r15,r0,Test1_16
	      	cmp  	r6,r5,#2
	      	z.mov  	r15,r0,Test1_17
	      	cmp  	r6,r5,#3
	      	z.mov  	r15,r0,Test1_18
	      	mov  	r15,r0,Test1_11
Test1_16:
	      	sub  	r14,r14,#2
	      	ldi  	r5,#Test1_1
	      	sub  	r14,r14,#2
	      	sto  	r5,0[r14]
	      	call 	_printf
	      	add  	r14,r14,#2
	      	add  	r14,r14,#2
	      	mov  	r15,r0,Test1_11
Test1_17:
	      	sub  	r14,r14,#2
	      	ldi  	r5,#Test1_1
	      	sub  	r14,r14,#2
	      	sto  	r5,0[r14]
	      	call 	_printf
	      	add  	r14,r14,#2
	      	add  	r14,r14,#2
	      	mov  	r15,r0,Test1_11
Test1_18:
	      	sub  	r14,r14,#2
	      	ldi  	r5,#Test1_1
	      	sub  	r14,r14,#2
	      	sto  	r5,0[r14]
	      	call 	_printf
	      	add  	r14,r14,#2
	      	add  	r14,r14,#2
	      	mov  	r15,r0,Test1_11
Test1_11:
	      	sub  	r14,r14,#2
	      	push 	r0
	      	call 	_exit
	      	add  	r14,r14,#2
	      	add  	r14,r14,#2
Test1_19:
	      	mov  	r14,r12,#0
	      	ld   	r12,0[r14]
	      	add  	r14,r14,#2
	      	mov  	r15,r13,#0
	rodata
	align	16
	align	2
Test1_3:	; Three
	dc	84,104,114,101,101,0
Test1_2:	; Two
	dc	84,119,111,0
Test1_1:	; One
	dc	79,110,101,0
Test1_0:	; Hello World!
	dc	72,101,108,108,111,32,87,111
	dc	114,108,100,33,0
	extern	_main
	extern	_exit
	extern	_printf
