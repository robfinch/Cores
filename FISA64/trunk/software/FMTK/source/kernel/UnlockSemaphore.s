	code
	align	16
public code UnlockSemaphore_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw      r1,24[bp]
    .0001:
        sw      r0,[r1]
        lw      r2,[r1]
        beq     r2,.0002  ; the semaphore is unlock, by this task or another
        cmpu    r3,r2,tr
        beq     r3,.0001  ; ??? this task still has it locked - store failed
        ; Here the semaphore was locked, but not by this task anymore. Another task
        ; must have interceded amd locked the semaphore right after it was unlocked
        ; by this task. Make sure this is the case, and it's not just bad memory.
        ; Make sure the semaphore was locked by a valid task
        ;chk     r2,r0,#256
        ; Here the semaphore probably was validly locked by a different task.
        ; Assume the unlock must have been successful.
    .0002:
    
UnlockSemaphore_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

	rodata
	align	16
	align	8
;	global	UnlockSemaphore_
