	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
	fill.b	1984,0x00
	align	8
	align	8
	bss
	align	8
public bss readyQ_:
	fill.b	16,0x00

endpublic
	data
	align	8
	fill.b	880,0x00
	bss
	align	1024
public bss tcbs_:
	fill.b	262144,0x00

endpublic
	code
	align	16
public code iirl_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r5,32[bp]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	lw   	r5,24[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,readyQ_[r4]
test_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

	rodata
	align	16
	align	8
;	global	tcbs_
;	global	iirl_
;	global	readyQ_
