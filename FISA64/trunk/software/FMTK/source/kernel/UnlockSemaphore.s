	code
	align	16
public code UnlockSemaphore_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw      r1,24[bp]
        sw      r0,[r1]
    
UnlockSemaphore_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

	rodata
	align	16
	align	8
;	global	UnlockSemaphore_
