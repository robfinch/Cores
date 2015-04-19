	code
	align	16
public code outb_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        lw    r2,32[bp]
        sb    r2,[r1]
     
outb_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

	rodata
	align	16
	align	8
;	global	outb_
