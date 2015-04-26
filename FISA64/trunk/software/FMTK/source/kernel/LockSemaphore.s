	code
	align	16
public code LockSemaphore_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw      r1,24[bp]
        lw      r2,32[bp]
        ; Interrupts should be already enabled or there would be no way for a locked
        ; semaphore to clear. Let's enable interrupts just in case.
        cli
    .0001:
        beq     r2,.0004  
        subui   r2,r2,#1  
        lwar    r3,[r1]
        beq     r3,.0003            ; branch if free
        cmpu    r2,r3,tr            ; test if already locked by this task
        beq     r2,.0002
        ;chk     r3,r0,#256          ; check if locked by a valid task
    .0003:
        swcr    tr,[r1]             ; try and lock it
        nop                         ; cr0 needs time to update???
        nop
        mfspr   r3,cr0
        bfextu  r3,r3,#36,#36       ; status is bit 36 of cr0
        beq     r3,.0001            ; lock failed, go try again
    .0002:
        ldi     r1,#1
        bra     .0005
    .0004:
        ldi     r1,#0
    .0005:
    
LockSemaphore_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#32
endpublic

public code ILockSemaphore_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw      r1,24[bp]
        lw      r2,32[bp]
    .0001:
        beq     r2,.0004  
        subui   r2,r2,#1  
        lwar    r3,[r1]
        beq     r3,.0003            ; branch if free
        cmpu    r2,r3,tr            ; test if already locked by this task
        beq     r2,.0002
       ;chk     r3,r0,#256          ; check if locked by a valid task
    .0003:
        swcr    tr,[r1]             ; try and lock it
        nop                         ; cr0 needs time to update???
        nop
        mfspr   r3,cr0
        bfextu  r3,r3,#36,#36       ; status is bit 36 of cr0
        beq     r3,.0001            ; lock failed, go try again
    .0002:
        ldi     r1,#1
        bra     .0005
    .0004:
        ldi     r1,#0
    .0005:
    
LockSemaphore_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#32
endpublic

	rodata
	align	16
	align	8
;	global	LockSemaphore_
;	global	ILockSemaphore_
