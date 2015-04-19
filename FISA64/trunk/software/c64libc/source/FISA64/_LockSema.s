;------------------------------------------------------------------------------
; Lock the semaphore.
;
; Occasionally the semaphore fails to lock correctly and the system hangs up
; waiting for the semaphore lock. This could be because the SWCR works but
; cr0 doesn't get updated, or the bfextu instruction fails?? So the lock is
; tested to see if the current task is the one holding the lock. If same task
; that holds the lock is attempting a new lock, then we just return and assume
; a successful lock. The problem with this approach is if the task attempts a
; lock both while running and during an interrupt routine. The resource wouldn't
; be corectly protected in that case. So no BIOS calls during interrupt
; routines! The BIOS isn't re-entrant.
;
; Parameters:
; r1 = address of semaphore to lock
; r2 = number of times to retry
;------------------------------------------------------------------------------

_LockSema:
    push    r4
    push    r3

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
    chk     r2,r3,b48           ; check if locked by a valid task
    bne     r2,.0001
.0003:
    swcr    tr,[r1]             ; try and lock it
    nop                         ; cr0 needs time to update???
    nop
    mfspr   r3,cr0
    bfextu  r3,r3,#36,#36       ; status is bit 36 of cr0
    beq     r3,.0001            ; lock failed, go try again
.0002:
    ldi     r1,#1
    pop     r3
    pop     r4
    rtl
.0004:
    ldi     r1,#0
    pop     r3
    pop     r4
    rtl
