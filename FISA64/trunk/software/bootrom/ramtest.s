	data
	align	8
	align	8
public data msgBadAddr:
	dw	ramtest_0
endpublic

	code
	align	16
putaddr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        push  lr
        lw    r1,24[bp]
        bsr   DisplayHalf
        ldi   r1,#'\r'
        bsr   DisplayChar
        pop   lr
    
ramtest_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
badaddr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        push   lr
        lea    r1,msgBadAddr
        bsr    DisplayString16
        lw     r1,24[bp]
        bsr    DisplayHalf
        ldi    r1,#'='
        bsr    DisplayChar
        lw     r1,24[bp]
        lw     r1,[r1]
        bsr    DisplayHalf
        bsr    CRLF
        pop    lr
        
ramtest_6:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ramtest_between:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#ramtest_9
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lw   	r3,24[bp]
	      	lsr  	r3,r3,#3
	      	sw   	r3,24[bp]
	      	lw   	r3,32[bp]
	      	lsr  	r3,r3,#3
	      	sw   	r3,32[bp]
	      	lw   	r3,24[bp]
	      	sw   	r3,-8[bp]
	      	sw   	r0,-16[bp]
	      	lw   	r3,24[bp]
	      	sw   	r3,-8[bp]
ramtest_10:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bge  	r3,ramtest_11
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	sw   	r4,[r3]
	      	lw   	r3,-8[bp]
	      	and  	r3,r3,#4095
	      	bne  	r3,ramtest_13
	      	lw   	r3,-8[bp]
	      	asri 	r3,r3,#12
	      	push 	r3
	      	bsr  	putaddr
	      	addui	sp,sp,#8
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	sc   	r3,-18[bp]
	      	lcu  	r3,-18[bp]
	      	cmp  	r3,r3,#3
	      	bne  	r3,ramtest_15
	      	bra  	ramtest_8
ramtest_15:
ramtest_13:
ramtest_12:
	      	inc  	-8[bp],#8
	      	bra  	ramtest_10
ramtest_11:
	      	     	bsr CRLF 
	      	lw   	r3,24[bp]
	      	sw   	r3,-8[bp]
ramtest_17:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bge  	r3,ramtest_18
	      	lw   	r3,-8[bp]
	      	lw   	r3,[r3]
	      	lw   	r4,40[bp]
	      	cmp  	r3,r3,r4
	      	beq  	r3,ramtest_20
	      	push 	-8[bp]
	      	bsr  	badaddr
	      	addui	sp,sp,#8
	      	inc  	-16[bp],#1
ramtest_20:
	      	lw   	r3,-16[bp]
	      	cmp  	r3,r3,#10
	      	ble  	r3,ramtest_22
	      	bra  	ramtest_18
ramtest_22:
	      	lw   	r3,-8[bp]
	      	and  	r3,r3,#4095
	      	bne  	r3,ramtest_24
	      	lw   	r3,-8[bp]
	      	asri 	r3,r3,#12
	      	push 	r3
	      	bsr  	putaddr
	      	addui	sp,sp,#8
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	sc   	r3,-18[bp]
	      	lcu  	r3,-18[bp]
	      	cmp  	r3,r3,#3
	      	bne  	r3,ramtest_26
	      	bra  	ramtest_8
ramtest_26:
ramtest_24:
ramtest_19:
	      	inc  	-8[bp],#8
	      	bra  	ramtest_17
ramtest_18:
ramtest_8:
ramtest_28:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
ramtest_9:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_28
public code ramtest:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#ramtest_29
	      	mov  	bp,sp
	      	push 	#-6149008514797120171
	      	push 	#65536
	      	push 	#32768
	      	bsr  	ramtest_between
	      	addui	sp,sp,#24
	      	push 	#6149008514797120170
	      	push 	#65536
	      	push 	#32768
	      	bsr  	ramtest_between
	      	addui	sp,sp,#24
	      	push 	#-6149008514797120171
	      	push 	#134217728
	      	push 	#131072
	      	bsr  	ramtest_betweem
	      	addui	sp,sp,#24
	      	push 	#6149008514797120170
	      	push 	#134217728
	      	push 	#131072
	      	bsr  	ramtest_betweem
	      	addui	sp,sp,#24
ramtest_30:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
ramtest_29:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_30
endpublic

	rodata
	align	16
	align	8
ramtest_0:	; bad at address: 
	dc	98,97,100,32,97,116,32,97
	dc	100,100,114,101,115,115,58,32
	dc	0
;	global	ramtest
	extern	getcharNoWait
	extern	ramtest_betweem
;	global	msgBadAddr
