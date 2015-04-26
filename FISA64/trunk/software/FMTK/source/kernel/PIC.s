	code
	align	16
public code GetVBR_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        mfspr r1,vbr
    
PIC_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code set_vector_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#PIC_3
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmpu 	r4,r3,#511
	      	ble  	r4,PIC_5
PIC_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
PIC_5:
	      	lw   	r3,32[bp]
	      	beq  	r3,PIC_10
	      	lw   	r4,32[bp]
	      	and  	r3,r4,#3
	      	beq  	r3,PIC_8
PIC_10:
	      	bra  	PIC_7
PIC_8:
	      	lw   	r4,24[bp]
	      	asli 	r3,r4,#3
	      	push 	r3
	      	bsr  	GetVBR_
	      	pop  	r3
	      	mov  	r4,r1
	      	lw   	r5,32[bp]
	      	sw   	r5,0[r4+r3]
	      	bra  	PIC_7
PIC_3:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	PIC_7
endpublic

public code InitPIC_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#PIC_11
	      	mov  	bp,sp
	      	push 	#12
	      	push 	#4292612048
	      	bsr  	outh_
	      	addui	sp,sp,#16
	      	bsr  	getCPU_
	      	mov  	r3,r1
	      	bne  	r3,PIC_13
	      	push 	#32783
	      	push 	#4292612036
	      	bsr  	outh_
	      	addui	sp,sp,#16
	      	bra  	PIC_14
PIC_13:
	      	push 	#11
	      	push 	#4292612036
	      	bsr  	outh_
	      	addui	sp,sp,#16
PIC_14:
PIC_15:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
PIC_11:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	PIC_15
endpublic

	rodata
	align	16
	align	8
	extern	outh_
;	global	GetVBR_
	extern	getCPU_
;	global	set_vector_
;	global	InitPIC_
