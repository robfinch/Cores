        ; Simple Fibonacci number program ported from earlier machines

        .code 18 bits
        ORG 0xFFFC0000
        ldi   r10,#RSLTS      ; initialise the results pointer
        ldi   r63,#RETSTK     ; initialise the return address stack
        ldi   r5,#0           ; Seed fibonacci numbers in r5,r6
        ldi   r6,#1

        std   r5,[r10]        ; save r5 and r6 as first resultson results stack
        std   r6,8[r10]
        add   r10,r10,#8

        ldi   r4,#-23       ; set up a counter in R4
LP1:    jsr   FIB
        add.  r4,r0,#1      ; inc loop counter
p1.ne   jmp   LP1           ; another iteration if not zero

END1:   jmp   END1           ; halt    r0,r0,0x999     # Finish simulation


FIB:    or   r2,r5,r0          ; Fibonacci computation
        add  r2,r2,r6
        std  r2,[r10]         ; Push result in results stack
        add  r10,r10,#8       ; incrementing stack pointer
        or   r5,r6,r0         ; Prepare r5,r6 for next iteration
        or   r6,r2,r0
        rts

        .bss
        ORG 0x100

; 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

; stack for results with stack pointer
RSLTS:  WORD 0
