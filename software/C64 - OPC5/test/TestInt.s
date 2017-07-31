	code
	align	16
public code _myint:
	# void interrupt myint()
	      	sub  	r14,r0,26
	      	sto  	r1,r14,0
	      	sto  	r2,r14,2
	      	sto  	r3,r14,4
	      	sto  	r4,r14,6
	      	sto  	r5,r14,8
	      	sto  	r6,r14,10
	      	sto  	r7,r14,12
	      	sto  	r8,r14,14
	      	sto  	r9,r14,16
	      	sto  	r10,r14,18
	      	sto  	r11,r14,20
	      	sto  	r12,r14,22
	      	sto  	r13,r14,24
	      	sub  	r14,r0,4
	      	sto  	r13,r14,0
	      	sto  	r12,r14,2
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	# 	printf("Hello again.");
	      	mov  	r5,r0,TestInt_1
	      	sub  	r14,r0,2
	      	sto  	r5,r14,0
	      	mov  	r13,r15,2
	      	mov  	r15,r0,_printf
	      	add  	r14,r0,2
TestInt_5:
	      	mov  	r14,r12,0
	      	ld   	r13,r14,0
	      	ld   	r12,r14,2
	      	add  	r14,r0,4
	      	ld   	r1,r14,0
	      	ld   	r2,r14,2
	      	ld   	r3,r14,4
	      	ld   	r4,r14,6
	      	ld   	r5,r14,8
	      	ld   	r6,r14,10
	      	ld   	r7,r14,12
	      	ld   	r8,r14,14
	      	ld   	r9,r14,16
	      	ld   	r10,r14,18
	      	ld   	r11,r14,20
	      	ld   	r12,r14,22
	      	ld   	r13,r14,24
	      	add  	r14,r0,26
	      	rti  
endpublic



public code _BIOScall:
	# void interrupt myint()
	      	sub  	r14,r0,26
	      	sto  	r1,r14,0
	      	sto  	r2,r14,2
	      	sto  	r3,r14,4
	      	sto  	r4,r14,6
	      	sto  	r5,r14,8
	      	sto  	r6,r14,10
	      	sto  	r7,r14,12
	      	sto  	r8,r14,14
	      	sto  	r9,r14,16
	      	sto  	r10,r14,18
	      	sto  	r11,r14,20
	      	sto  	r12,r14,22
	      	sto  	r13,r14,24
	      	sub  	r14,r0,2
	      	sto  	r12,r14,0
	      	mov  	r12,r14,0
	      	sub  	r14,r0,0
	      	mov  	r1,r0,-1
TestInt_9:
	      	mov  	r14,r12,0
	      	ld   	r12,r14,0
	      	add  	r14,r0,2
	      	ld   	r2,r14,2
	      	ld   	r3,r14,4
	      	ld   	r4,r14,6
	      	ld   	r5,r14,8
	      	ld   	r6,r14,10
	      	ld   	r7,r14,12
	      	ld   	r8,r14,14
	      	ld   	r9,r14,16
	      	ld   	r10,r14,18
	      	ld   	r11,r14,20
	      	ld   	r12,r14,22
	      	ld   	r13,r14,24
	      	add  	r14,r0,26
	      	rti  
endpublic



	rodata
	align	16
	align	2
TestInt_1:	; Hello again.
	word	72,101,108,108,111,32,97,103
	word	97,105,110,46,0
;	global	_BIOScall
;	global	_myint
	extern	_printf
