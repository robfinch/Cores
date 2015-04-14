	code
	align	16
public code GetVBR_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        mfspr r1,vbr
    
PIC_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code set_vector_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#PIC_2
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#511
	      	ble  	r3,PIC_3
PIC_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
PIC_3:
	      	lw   	r3,32[bp]
	      	beq  	r3,PIC_8
	      	lw   	r3,32[bp]
	      	and  	r3,r3,#3
	      	beq  	r3,PIC_6
PIC_8:
	      	bra  	PIC_5
PIC_6:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#3
	      	push 	r3
	      	bsr  	GetVBR_
	      	pop  	r3
	      	mov  	r4,r1
	      	lw   	r5,32[bp]
	      	sw   	r5,0[r4+r3]
	      	bra  	PIC_5
PIC_2:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	PIC_5
endpublic

public code InitPIC_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#PIC_9
	      	mov  	bp,sp
	      	push 	#12
	      	push 	#4292612048
	      	bsr  	outh_
	      	addui	sp,sp,#16
	      	bsr  	getCPU_
	      	mov  	r3,r1
	      	bne  	r3,PIC_10
	      	push 	#15
	      	push 	#4292612036
	      	bsr  	outh_
	      	addui	sp,sp,#16
	      	bra  	PIC_11
PIC_10:
	      	push 	#11
	      	push 	#4292612036
	      	bsr  	outh_
	      	addui	sp,sp,#16
PIC_11:
PIC_12:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
PIC_9:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	PIC_12
endpublic

	rodata
	align	16
	align	8
	extern	outh_
;	global	GetVBR_
	extern	getCPU_
;	global	set_vector_
;	global	InitPIC_
