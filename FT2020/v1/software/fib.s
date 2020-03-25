MACRO   PUSH( _data_)
    addi     r31, r31, -4
    sw      _data_, r31, 0
ENDMACRO

MACRO   POP( _data_ )
    lw      _data_, r14, 0
    addi    r31, r31, 4
ENDMACRO

        # Simple Fibonacci number program ported from earlier machines

        ORG 0x0000
        ori  r10,r0,RSLTS      # initialise the results pointer
        ori  r31,r0,RETSTK     # initialise the return address stack
        or   r5,r0,r0          # Seed fibonacci numbers in r5,r6
        ori  r6,r0,1

        sw    r5,r10            # save r5 and r6 as first resultson results stack
        sw    r6,r10,4
        addi  r10,r0,8

        ori   r4,r0,-23         # set up a counter in R4
        ori   r8,r0,FIB
LOOP:   jsr   FIB
CONT:   addi  r4,r0,1               # inc loop counter
        ceq   p1,r4,r0
     p1.jmp   LOOP          # another iteration if not zero

END:    jmp   END           # halt    r0,r0,0x999     # Finish simulation


FIB:    or   r2,r5,r0          # Fibonacci computation
        add  r2,r2,r6
        sw   r2,r10,0         # Push result in results stack
        addi r10,r0,4       # incrementing stack pointer

        or   r5,r6,r0         # Prepare r5,r6 for next iteration
        or   r6,r2,r0
        rts

        ORG 0x100

# 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSLTS:  WORD 0