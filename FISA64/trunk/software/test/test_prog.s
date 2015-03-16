;
;
    code
    org     $10000
    sei     ; interrupts off
    nop
    nop
    ; cache misses here after first prefix fetch
    ldi     r1,#$1234567812345678
    addu    r2,r1,r1
    nop
    nop
    nop
    ; cache misses here after second prefix fetch
    ldi     r1,#$1234567812345678
    addu    r1,r1,r2
    nop
    nop
    nop
    ldi     r30,#16376           ; set stack pointer to top of 16k Area
    ldi     r3,#10
loop1:
    subui   r3,r3,#1
    bne     r3,loop1
    nop
    nop
    nop
    mtspr   lotgrp,r0            ; operating system is group #0
    bsr     SetupMemtags
    ldi     r1,#100
    bsr     MicroDelay
    bsr     Clearscreen
    nop
    nop
hangprg:
    nop
    nop
    nop
    bra     hangprg

SetupMemtags:
    mtspr   ea,r0                ; select tag for first 64kB
    ldi     r1,#$0006            ; system only: readable, writeable, not executable
    mtspr   tag,r1
    ldi     r1,#$10000           ; select tag for second 64kB
    mtspr   ea,r1
    ldi     r2,#$0005            ; systme only: readable, executable, not writeable
    mtspr   tag,r2
    ldi     r3,#20-2             ; number of tags to setup
.0001:
    addui   r1,r1,#$10000
    mtspr   ea,r1
    ldi     r2,#$0006            ; set them up as data
    mtspr   tag,r2
    subui   r3,r3,#1
    bne     r3,.0001
    rts

; Delay for a short time for at least the specified number of clock cycles
;
MicroDelay:
    push    r2
    push    r3
    push    $10000              ; test push memory
    push    $10008
    mfspr   r3,tick             ; get starting tick
.0001:
    mfspr   r2,tick
    subu    r2,r2,r3
    cmp     r2,r2,r1
    blt     r2,.0001
    addui   sp,sp,#16
    pop     r3
    pop     r2
    rts

;
Clearscreen:
    push    r2
    push    r3
    ldi     r2,#2604
    ldi     r3,#$FFD00000
    ldi     r1,#$0C0E0020
.0001:
    sh      r1,[r3+r2*4]        ; test indexed addressing
    subui   r2,r2,#1
    bne     r2,.0001
    pop     r3
    pop     r2
    rts

    nop
    nop
    nop

