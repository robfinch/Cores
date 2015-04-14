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
;------------------------------------------------------------------------------

LockSema:
    push    r2
    push    r3

    ; Interrupts should be already enabled or there would be no way for a locked
    ; semaphore to clear. Let's enable interrupts just in case.
    cli
.0001:
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
    pop     r3
    pop     r2
    rtl

;------------------------------------------------------------------------------
; Unlock a semaphore
;
; When unlocking the semaphore a test is made to see if the semaphore is still
; locked by same task attempting an unlock. If that is the case then the 
; SW instruction must have failed to clear the semaphore. So that the system
; isn't hung, we go back and redo the unlock.
;------------------------------------------------------------------------------

UnlockSema:
    push    r2
    push    r3
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
    chk     r3,r2,b48
    beq     r3,.0001
    ; Here the semaphore probably was validly locked by a different task.
    ; Assume the unlock must have been successful.
.0002:
    pop     r3
    pop     r2
    rtl

;------------------------------------------------------------------------------
; Lock/unlock routines.
;------------------------------------------------------------------------------

LockSYS_:
    push    lr
    push    r1
    lea     r1,sys_sema_
    bsr     LockSema
    pop     r1
    rts
UnlockSYS_:
    push    lr
    push    r1
    lea     r1,sys_sema_
    bsr     UnlockSema
    pop     r1
    rts
LockIOF_:
     push    lr
     push    r1
     ldi     r1,#iof_sema_
     bsr     LockSema
     pop     r1
     rts
UnlockIOF_:
     push   lr
     push   r1
     lea    r1,iof_sema_
     bsr    UnlockSema
     pop    r1
     rts
     
