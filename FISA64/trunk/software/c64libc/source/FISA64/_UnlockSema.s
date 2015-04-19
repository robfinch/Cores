;------------------------------------------------------------------------------
; Unlock a semaphore
;
; When unlocking the semaphore a test is made to see if the semaphore is still
; locked by same task attempting an unlock. If that is the case then the 
; SW instruction must have failed to clear the semaphore. So that the system
; isn't hung, we go back and redo the unlock.
; Parameters:
; r1 = address of semaphore to unlock
;------------------------------------------------------------------------------

_UnlockSema:
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
