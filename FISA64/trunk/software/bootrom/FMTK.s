;==============================================================================
; Finitron Multi-Tasking Kernel (FMTK)
;        __
;   \\__/ o\    (C) 2013, 2014, 2015  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;==============================================================================
    code
	org		$14000
	; Compress vector table by storing only the low order 16 bits of the
	; vector. The high order bits are always the same.
syscall_vectors:
	dc		FMTKInitialize
	dc		StartTask
	dc		ExitTask
	dc   	KillTask
	dc		SetTaskPriority
	dc		Sleep
	dc		AllocMbx
	dc		FreeMbx
	dc		PostMsg
	dc		SendMsg
	dc		WaitMsg
	dc		CheckMsg

message "InitFMTK"
BranchToSelf:
    bra     BranchToSelf

FMTKInitialize:
InitFMTK:
    push    lr
    mfspr   r20,tick

    ; Clear memory used by FMTK
    ldi     r1,#VAR_Area
zap1:
    sw      r0,[r1]
    addui   r1,r1,#8
    cmpu    r2,r1,#DCB_ArrayEnd
    blt     r2,zap1

	; Initialize semaphores
	sw      r0,sys_sema
	sw		r0,freetcb_sema
	sw		r0,freembx_sema
	sw		r0,freemsg_sema
	sw		r0,tcb_sema
	sw		r0,readylist_sema
	sw		r0,tolist_sema
	sw		r0,mbx_sema
	sw		r0,msg_sema
	sw		r0,jcb_sema

    ; Set interrupt vectors
	mfspr	r2,vbr
	ldi		r1,#reschedule
	sw		r1,16[r2]
	ldi		r1,#syscall_exception
	sw		r1,32[r2]
	ldi		r1,#FMTKTick
	sw		r1,(448+3)<<3[r2]
	sw		r0,UserTick

	sw		r0,TimeoutList		; no entries in timeout list
	sw		r0,QNdx0
	sw		r0,QNdx1
	sw		r0,QNdx2
	sw		r0,QNdx3
	sw		r0,QNdx4
	sw		r0,QNdx5
	sw		r0,QNdx6
	sw		r0,QNdx7

	sw		r0,missed_ticks

	; Initialize IO Focus List
	;
	sw      r0,IOFocusTbl
	sw      r0,IOFocusTbl+8
	sw      r0,IOFocusTbl+16
	sw      r0,IOFocusTbl+32

	; Initialize the FreeJCB list
	ldi		r1,#JCB_Array+JCB_Size		; the next available JCB
	sw		r1,FreeJCB
	mov     r2,r1
	addui	r1,r1,#JCB_Size
	ldi		r3,#NR_JCB-1
st5:
	sw		r1,JCB_Next[r2]
	addui	r1,r1,#JCB_Size
	addui	r2,r2,#JCB_Size
	subui   r3,r3,#1
	bne		r3,st5
	sw      r0,JCB_Next[r2]

	; Setup default values in the JCB's
	ldi		r3,#0
	ldi		r2,#NR_JCB
	ldi     r4,#JCB_Array
ijcb1:
	sc		r3,JCB_Number[r4]
	sb		r0,JCB_esc[r4]
	ldi     r1,#31
	sb		r1,JCB_VideoRows[r4]
	ldi		r1,#84
	sb		r1,JCB_VideoCols[r4]
	ldi		r1,#1				; turn on keyboard echo
	sb		r1,JCB_KeybdEcho[r4]
	sb		r1,JCB_CursorOn[r4]
	sb		r1,JCB_CursorFlash[r4]
	sb		r0,JCB_CursorRow[r4]
	sb		r0,JCB_CursorCol[r4]
	sb		r0,JCB_CursorType[r4]
	ldi		r1,#%010010010_111111111_0000000000	; white on grey
	sh		r1,JCB_NormAttr[r4]
	sh		r1,JCB_CurrAttr[r4]
	mulu	r5,r3,#16384		; 8192 words per screen
	addui   r5,r5,#SCREEN_Array
	sh		r5,JCB_pVirtVid[r4]
	sh		r5,JCB_pVidMem[r4]
	bne		r3,ijcb2
	ldi		r1,#%001000110_010010010_0000000000	; grey on blue
	sh		r1,JCB_NormAttr[r4]
	sh		r1,JCB_CurrAttr[r4]
	lh		r5,#TEXTSCR
	sh		r5,JCB_pVidMem[r4]
ijcb2:
    addui   r3,r3,#1
	addui	r4,r4,#JCB_Size
	cmp     r2,r3,#NR_JCB
	blt		r2,ijcb1

	; Initialize free message list
	ldi		r1,#NR_MSG
	sw		r1,nMsgBlk
	ldi     r1,#MSG_Array
	sw		r1,FreeMsg
	addui   r2,r1,MSG_Size
st4:
	sw		r2,MSG_LINK[r1]
	sw      r0,MSG_D1[r1]
	sw      r0,MSG_D2[r1]
	sw      r0,MSG_TYPE[r1]
	addui	r1,r1,#MSG_Size
	addui   r2,r2,#MSG_Size
	cmp     r3,r2,#MSG_ArrayEnd-MSG_Size
	blt     r3,st4
	sw      r0,MSG_LINK[r1]

	; Initialize free mailbox list
	; Note the first NR_TCB mailboxes are statically allocated to the tasks.
	; They are effectively pre-allocated.
	ldi		r5,#NR_MBX-NR_TCB
	sw		r5,nMailbox

    ldi     r1,#NR_TCB
    mulu    r2,r1,#MBX_Size
    addui   r2,r2,#MBX_Array
    sw      r2,FreeMbxHandle
    mov     r3,r2
    addui   r3,r3,#MBX_Size
.imbxl1:
    sw      r3,MBX_LINK[r2]
    addui   r2,r2,#MBX_Size
    addui   r3,r3,#MBX_Size
    subui   r5,r5,#1
    bgt     r5,.imbxl1

    ; Initialize the free TCB list
    ; The first two TCB's are pre-allocated and so aren't part of the list
    ldi     r2,#TCB_Array+TCB_Size
    sw      r2,FreeTCB
.0001:
    addui   r3,r2,#TCB_Size
    sw      r3,TCB_NextFree[r2]
    addui   r2,r2,#TCB_Size
    cmpu    r4,r2,#TCB_ArrayEnd-TCB_Size
    blt     r4,.0001
    nop
    sw      r0,TCB_NextFree[r2]

    ldi     r2,#TCB_Array
    ldi     r4,#0
.nextTCB:
    ldi     r5,#0
    sw      r5,TCB_hJCB[r2]   ; owning JOB = monitor
    ldi     r3,#BranchToSelf
    sw      r3,TCB_IPC[r2]    ; set startup address
    mulu    r3,r4,#4096       ; initial stack size=4096
    addui   r3,r3,#STACKS_Array+4088
    sw      r3,TCB_r30[r2]    ; set the stack pointer to the default stack
    addui   r2,r2,#TCB_Size   ; move to next TCB 768B TCB size
    addui   r4,r4,#1
    cmpu    r1,r4,#NR_TCB
    blt     r1,.nextTCB

	; Manually setup the BIOS task
	; FMTK can't be called to setup the first task because it uses the
	; SYS_STACK associated with the running task which hasn't been set yet.
	ldi     tr,#TCB_Array
	sw		tr,TCB_NextRdy[tr]	; manually build the ready list
	sw		tr,TCB_PrevRdy[tr]
	sw		r0,TCB_NextTo[tr]
	sw		r0,TCB_PrevTo[tr]
	ldi     r1,#SYS_STACKS_Array + 4088
	sw      r1,TCB_SYS_Stack[tr]
	ldi     r1,#BIOS_STACKS_Array + 4088
	sw      r1,TCB_BIOS_Stack[tr]
	ldi		r1,#3
	sc		r1,TCB_Priority[tr]
	sb      r0,TCB_Affinity[tr]
	sw		r0,TCB_Timeout[tr]
	ldi		r1,#TS_RUNNING|TS_READY
	sb		r1,TCB_Status[tr]
	ldi     r1,#STACKS_Array+$FF8   ; setup stack pointer top of memory
	sw		r1,TCB_r31[tr]
	sw		tr,QNdx3		; insert at priority 3

	; manually build the IO focus list
	ldi		r1,#JCB_Array
	sw	    r1,IOFocusNdx		; Job #0 (Monitor) has the focus
	sw		r1,JCB_iof_next[r1]
	sw		r1,JCB_iof_prev[r1]
	ldi		r1,#1
	sw		r1,IOFocusTbl		; set the job #0 request bit
 
	ldi		r1,#0          ; priority
	ldi		r2,#1          ; processor #1
	ldi		r3,#CPU1_Start ; start address
	ldi     r4,#0          ; start parameter (NULL)
	ldi     r5,#0          ; r5 = job handle of owning job
	sys     #FMTK_CALL
	dh      1              ; start task

	ldi		r1,#7          ; priority
	ldi		r2,#0          ; processor #0
	ldi		r3,#IdleTask   ; start address
	ldi     r4,#0          ; start parameter (NULL)
	ldi     r5,#0          ; r5 = job handle of owning job
	sys     #FMTK_CALL
	dh      1              ; start task

    mfspr   r21,tick
    subu    r21,r21,r20
    sw      r21,sys_ticks
    rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
StartIdleTask:
    push    lr
	ldi		r1,#7          ; priority
	ldi		r2,#0
	ldi		r3,#IdleTask   ; start address
	ldi     r4,#0          ; start parameter (NULL)
	ldi     r5,#JCB_Array  ; r5 = job handle of owning job
	bsr		StartTask
	rts

;------------------------------------------------------------------------------
; IdleTask
;
; IdleTask is a low priority task that is always running. It runs when there
; is nothing else to run.
; This task check for tasks that are stuck in infinite loops and kills them.
;------------------------------------------------------------------------------
IdleTask:
it3:
    ldi     r2,#TCB_Array
it2:
;	inc		TEXTSCR+444		; increment IDLE active flag
	cmpu    r1,r2,#TCB_Array
	beq		r1,it1
	lb		r1,TCB_Status[r2]
	cmp		r1,r1,#TS_SLEEP
	bne		r1,it1
	mov     r1,r2
;	sys		#4				; KillTask function
;	dh		3
it1:
    addui   r2,r2,#TCB_Size
    cmpu    r1,r2,#TCB_ArrayEnd-TCB_Size
    blt     r1,it2
    bra     it3
	cli						; enable interrupts
	wai						; wait for one to happen
	bra		it2

;------------------------------------------------------------------------------
; Parameters:
;	r1 = job name
;	r2 = start address
;------------------------------------------------------------------------------

StartJob:
    push    lr
	push    r1
	
	; Get a free JCB
    bsr     LockSYS

	lw		r6,FreeJCB
	beq		r6,sjob1
	lw		r7,JCB_Next[r6]
	sw		r7,FreeJCB

	lea		r7,JCB_Name[r6]		; r7 = address of name field
	mov		r9,r7				; save off buffer address
	ldi		r8,#0				; r8 = count of characters (0 to 31)
sjob3:
	lb	    r5,[r1]				; get a character
	beq		r5,sjob2			; end of string ?
	sb		r5,1[r7]
	addui   r1,r1,#1
	addui   r7,r7,#1
	addui   r8,r8,#1
	cmpu	r5,r8,#31   		; max number of chars ?
	blt		r5,sjob3
sjob2:
	sb		r8,[r9]				; save name length

sjob1:
	bsr     UnlockSYS
	pop     r1
	rts

;------------------------------------------------------------------------------
; Lock routines.
;------------------------------------------------------------------------------

LockSYS:
    push    lr
    push    r1
    lea     r1,sys_sema
    bsr     LockSema
    pop     r1
    rts

UnlockSYS:
    sw      r0,sys_sema
    rtl

;------------------------------------------------------------------------------
; Lock the semaphore.
; Locking the semaphore checks how long the lock is taking. If the lock is
; taking a ridiculously long time, then something went awry in the system.
; If it takes too long to obtain a lock, the lock is taken over.
;
;
; Parameters:
; r1 = address of semaphore to lock
;------------------------------------------------------------------------------

LockSema:
    push    r2
    push    r3
    push    r4
    push    r5

    ; Interrupts should be already enabled or there would be no way for a locked
    ; semaphore to clear. Let's enable interrupts just in case.
    mfspr   r4,tick
.0001:
    cli
    lwar    r3,[r1]
    beq     r3,.0003            ; branch if free
    mfspr   r5,tick
    subu    r5,r5,r4
    cmp     r5,r5,#2500000
    blt     r5,.0001
    ; Here the semaphore timed out. Notify the user.
.takeOver:
    push    r1
    lea     r1,msgSemaTo
    bsr     DisplayString
    pop     r1
    bsr     DisplayHalf
    bsr     CRLF
    sw      tr,[r1]
    bra     .0002
.0003:
    ; Disable interrupts here until cr0 can be read. Otherwise there's no
    ; guarentee that cr0 didn't change.
    sei
    swcr    tr,[r1]             ; try and lock it
    mfspr   r3,cr0
    cli
    mfspr   r5,tick
    subu    r5,r5,r4
    cmp     r5,r5,#2500000
    bgt     r5,.takeOver
    and     r3,r3,#$1000000000
    beq     r3,.0001            ; lock failed, go try again
.0002:
    pop     r5
    pop     r4
    pop     r3
    pop     r2
    rtl

msgSemaTo:
    db     "A semaphore timed out: ",0
    
    align 4
;------------------------------------------------------------------------------
; StartTask
;
; Startup a task. The task is automatically allocated a 1kW stack from the BIOS
; stacks area. 
;
; Parameters:
;	r1 = task priority
;	r2 = start flags
;	r3 = start address
;	r4 = start parameter
;	r5 = job handle
;------------------------------------------------------------------------------

StartTask:
    push    lr
    push    r1
    push    r2
    push    r3
    push    r4
    push    r5
	push    r6
	push    r7
	push    r8
	push    r9
	push    r10
	push    r11
	mov		r6,r1				; r6 = task priority
	mov		r9,r2				; r9 = flag register value on startup
	
	; get a free TCB
	;
    bsr     LockSYS
	lw		r1,FreeTCB			; get free tcb list pointer
	beq		r1,stask1
	mov     r2,r1
	lw		r1,TCB_NextFree[r2]
	sw		r1,FreeTCB			; update the FreeTCB list pointer

	bsr     UnlockSYS
	mov     r1,r2				; r1 = TCB pointer

	; setup the stack for the task
	; Zap the stack memory.
	mov		r7,r2
	subui   r2,r2,#TCB_Array
	lsr     r2,r2,#TCB_LogSize  ; r2 = index number of TCB
	asl		r2,r2,#12			; 4kB stack per task
	addui	r8,r2,#STACKS_Array	; add in stack base
	addui   r10,r2,#BIOS_STACKS_Array
	addui   r11,r2,#SYS_STACKS_Array

	; It's safe to update the TCB here without checking the semaphore because
	; the TCB isn't on any list. It's in no-man's land at this point.
	addui   r2,r8,#4088
	sw      r2,TCB_StackTop[r7]
	sw      r2,TCB_r31[r7]
	; Fill the stack with the ExitTask address. This will cause a return
	; to the ExitTask routine when the task finishes.
;	push    r1
;	push    r2
;	push    r3
;	push    r4
;	ldi		r1,#ExitTask		; r1 = fill value
;	subui   r4,r2,#4088
.stask6:
;	sw      r1,[r2]
;	subui   r2,r2,#8
;	cmpu    r3,r2,r4
;	bgt     r3,.stask6
;	pop     r4
;	pop     r3
;	pop     r2
;	pop     r1
	addui   r8,r10,#4088
	sw      r8,TCB_BIOS_Stack[r7]
	addui   r8,r11,#4088
	sw      r8,TCB_SYS_Stack[r7]
	sw      r4,TCB_r1[r7]
	sb      r9,TCB_Affinity[r7]
	sb		r6,TCB_Priority[r7]
	sb		r0,TCB_Status[r7]
	sw		r0,TCB_Timeout[r7]
	sw		r5,TCB_hJCB[r7]		; save job handle
	sw		r0,TCB_MbxList[r7]
	sw      r3,TCB_IPC[r7];     ; set starting address
	sw      r3,TCB_DPC[r7];
	sw      r3,TCB_EPC[r7];

	; Insert the task into the ready list
	mov     r1,r7
    bsr     LockSYS
	bsr		AddTaskToReadyList
	bsr     UnlockSYS
stask2:
    pop     r11
    pop     r10
    pop     r9
	pop     r8
	pop     r7
	pop     r6
	pop     r5
	pop     r4
	pop     r3
	pop     r2
	pop     r1
	rts
stask1:
	bsr     UnlockSYS
	bsr		kernel_panic
	db		"No more task control blocks available.",0
	bra		stask2

;------------------------------------------------------------------------------
; ExitTask
;
; This routine is called when the task exits with an rts instruction. OR
; it may be invoked with a JMP ExitTask. In either case the task must be
; running so it can't be on the timeout list.
;------------------------------------------------------------------------------
message "ExitTask"
ExitTask:
	; release any aquired resources
	; - mailboxes
	; - messages
;	hoff
    bsr     LockSYS
	bsr		RemoveTaskFromReadyList
	bsr		RemoveFromTimeoutList
	sw		r0,TCB_Status[tr]				; set task status to TS_NONE
	bsr		ReleaseIOFocus
	; Free up all the mailboxes associated with the task.
xtsk7:
	lw		r1,TCB_MbxList[tr]
	beq		r1,xtsk6
	bsr		FreeMbx
	bra		xtsk7
xtsk6:
	lw		r1,FreeTCB						; add the task control block to the free list
	sw		r1,TCB_NextFree[tr]
	sw		tr,FreeTCB
	bsr     UnlockSYS
	; This loop will eventually be interrupted, the interrupt return will not
	; return to here.
xtsk1:
	bra     xtsk1

;------------------------------------------------------------------------------
; KillTask
;
; "Kills" a task, removing it from all system lists. If the task has the 
; IO focus, the IO focus is switched. Task #0 is immortal and cannot be
; killed. Task #1 is immortal and cannot be killed.
;
; Registers Affected: none
; Parameters:
;	r1 = task number
;------------------------------------------------------------------------------
;
KillTask:
    push    lr
	push    r2
	push    r3
	bsr     ValidateTCBPtr
	beq		r1,kt1
	mov     r2,r1
	bsr     LockSYS
	lw		r1,TCB_hJCB[r1]
	bsr		ForceReleaseIOFocus
	mov     r1,r2
	jsr		RemoveTaskFromReadyList
	jsr		RemoveFromTimeoutList
	sb		r0,TCB_Status[r1]    		; set task status to TS_NONE

	; Free up all the mailboxes associated with the task.
	push    r1
	mov     r2,r1
	mov     r3,r1
	lw		r1,TCB_MbxList[r3]
kt7:
	beq		r1,kt6
	lw      r3,MBX_LINK[r1]
	bsr		FreeMbx2
	mov     r1,r3
	bra		kt7
kt6:
    pop     r1
	lw		r2,FreeTCB					; add the task control block to the free list
	sw		r2,TCB_NextFree[r1]
	sw		r1,FreeTCB
	bsr     UnlockSYS
	cmp     r2,r1,tr                    ; keep running the current task as long as
	bne		r2,kt1						; the task didn't kill itself.
.self:
	bra     .self
kt1:
    pop     r3
	pop     r2
	rts

;------------------------------------------------------------------------------
; Dump the task list. The task list isn't locked while it is being dumped
; because that would prevent task switches from occuring and we probably
; don't want to interfere with the system. However because it's not locked,
; there's no guarentee that everything will display correctly. It's safe to
; not lock the task list because we are simply reading the fields from it and
; not updating information.
;------------------------------------------------------------------------------

message "DumpTaskList"
DumpTaskList:
    push    lr
	push    r1
	push    r2
	push    r3
	push	r4
	ldi		r1,#msgTaskList
	bsr		DisplayString
	ldi		r3,#0
.0001:
;    lwar    r4,tcb_sema
;    bne     r4,.0001
;    swcr    tr,tcb_sema
;    mfspr   r4,cr0
;    and     r4,r4,#$1000000000
;    beq     r4,.0001
dtl2:
	lw		r1,QNdx0[r3]
	mov		r4,r1
	beq		r4,dtl1
dtl3:
    ldi     r2,#3
    mov     r4,r1
    lb      r1,TCB_Affinity[r1]
    bsr     PRTNUM
    mov     r1,r4
	ldi	    r2,#4
	lsr     r1,r3,#3
	bsr		PRTNUM
	bsr		DisplaySpace
	mov		r1,r4
	bsr		DisplayHalf
	bsr		DisplaySpace
	bsr		DisplaySpace
	mov		r1,r4
	lb		r1,TCB_Status[r1]
	bsr		DisplayByte
	bsr		DisplaySpace
	ldi		r2,#3
	lw		r1,TCB_PrevRdy[r4]
	bsr		DisplayHalf
	bsr		DisplaySpace
	ldi		r2,#3
	lw		r1,TCB_NextRdy[r4]
	bsr		DisplayHalf
	bsr		DisplaySpace
	lw		r1,TCB_Timeout[r4]
	bsr		DisplayWord
	bsr		CRLF
	lw		r4,TCB_NextRdy[r4]
	lw      r1,QNdx0[r3]
	cmp		r1,r4,r1
	bne		r1,dtl3
dtl1:
	addui   r3,r3,#8
	cmp     r4,r3,#64
	blt		r4,dtl2
	sw		r0,tcb_sema       ; release semaphore
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rts

msgTaskList:
	db	CR,LF,"CPU Pri   Task   Stat    Prv     Nxt     Timeout",CR,LF,0


;------------------------------------------------------------------------------
; r1 = task number
; r2 = new priority
;------------------------------------------------------------------------------

SetTaskPriority:
    push    lr
	push    r3
	bsr     LockSYS
	lb		r3,TCB_Status[r1]			    ; if the task is on the ready list
	and		r3,r3,#TS_READY|TS_RUNNING		; then remove it and re-add it.
	beq		r3,.stp2						; Otherwise just go set the priority field
	bsr		RemoveTaskFromReadyList
	sb		r3,TCB_Priority[r1]
	bsr		AddTaskToReadyList
	bra		.stp3
.stp2:
	sb		r3,TCB_Priority[r1]
.stp3:
	bsr     UnlockSYS
	pop     r3
	rts

;------------------------------------------------------------------------------
; Make sure we have a real TCB pointer.
;------------------------------------------------------------------------------

ValidateTCBPtr:
    push    r2
    and     r2,r1,#$3FF
    beq     r2,.0001
.badPtr:
    ldi     r1,#0
    pop     r2
    rtl
.0001:
    cmp     r2,r1,#TCB_Array
    blt     r2,.badPtr
    cmp     r2,r1,#TCB_ArrayEnd
    bge     r2,.badPtr
    pop     r2
    rtl

;------------------------------------------------------------------------------
; AddTaskToReadyList
;
; The ready list is a group of eight ready lists, one for each priority
; level. Each ready list is organized as a doubly linked list to allow fast
; insertions and removals. The list is organized as a ring (or bubble) with
; the last entry pointing back to the first. This allows a fast task switch
; to the next task. Which task is at the head of the list is maintained
; in the variable QNdx for the priority level.
;
; On Entry: Task list must be locked
; Registers Affected: none
; Parameters:
;	r1 = pointer to task control block
; Returns:
;	none
;------------------------------------------------------------------------------
message "AddToReadyList"
AddTaskToReadyList:
    push    lr
    push    r2
    push    r3
    push    r4
    bsr     ValidateTCBPtr
    beq     r1,.0001
	ldi     r2,#TS_READY
	sb		r2,TCB_Status[r1]
	lb		r3,TCB_Priority[r1]
	cmp		r4,r3,#8
	blt		r4,.0002
	ldi		r3,#PRI_LOWEST
.0002:
    mov     r4,r1
    asl     r3,r3,#3
	lw		r1,QNdx0[r3]
	bsr     ValidateTCBPtr
	beq		r1,.0003
	lw		r3,TCB_PrevRdy[r1]
	sw		r1,TCB_NextRdy[r3]
	sw		r3,TCB_PrevRdy[r4]
	sw		r4,TCB_PrevRdy[r1]
	sw		r1,TCB_NextRdy[r4]
.0001:
	pop     r4
	pop     r3
	pop     r2
	rts

	; Here the ready list was empty, so add at head
.0003:
	sw		r4,QNdx0[r3]
	sw		r4,TCB_NextRdy[r4]
	sw		r4,TCB_PrevRdy[r4]
	pop     r4
	pop     r3
	pop     r2
	rts
	

;------------------------------------------------------------------------------
; RemoveTaskFromReadyList
;
; This subroutine removes a task from the ready list.
;
; Registers Affected: none
; Parameters:
;	r1 = pointer to task control block
; Returns:
;   r1 = pointer to task control block
;------------------------------------------------------------------------------
message "RemoveFromReadyList"
RemoveTaskFromReadyList:
    push    lr
    push    r2
    push    r3
	push	r4
	push	r5

    bsr     ValidateTCBPtr
    beq     r1,rfr1
	lb		r3,TCB_Status[r1]	; is the task on the ready list ?
	and		r4,r3,#TS_READY|TS_RUNNING
	beq		r4,rfr2
	and		r3,r3,#~(TS_READY|TS_RUNNING)
	sb		r3,TCB_Status[r1]	; task status no longer running or ready
	lw		r4,TCB_NextRdy[r1]	; Get previous and next fields.
	lw		r5,TCB_PrevRdy[r1]
	sw		r4,TCB_NextRdy[r5]
	sw		r5,TCB_PrevRdy[r4]
	lb		r3,TCB_Priority[r1]
	asl     r3,r3,#3
	lw      r5,QNdx0[r3]
	cmp		r5,r1,r5			; Are we removing the QNdx task ?
	bne		r5,rfr2
	sw		r4,QNdx0[r3]
	; Now we test for the case where the task being removed was the only one
	; on the ready list of that priority level. We can tell because the
	; NxtRdy would point to the task itself.
	cmp		r5,r4,r1				
	bne		r5,rfr2
	sw		r0,QNdx0[r3]        ; Make QNdx NULL
	sw		r0,TCB_NextRdy[r1]
	sw		r0,TCB_PrevRdy[r1]
rfr2:
	pop		r5
	pop		r4
	pop     r3
	pop     r2
rfr1:
	rts

;------------------------------------------------------------------------------
; AddToTimeoutList
; AddToTimeoutList adds a task to the timeout list. The task is placed in the
; list depending on it's timeout value.
;
; Registers Affected: none
; Parameters:
;	r1 = task
;	r2 = timeout value
;------------------------------------------------------------------------------
message "AddToTimeoutList"
AddToTimeoutList:
    push    lr
	push    r2
	push    r3
	push	r4
	push	r5

    bsr     ValidateTCBPtr
    beq     r1,attl1
    ldi     r5,#0
	sw		r0,TCB_NextTo[r1]   ; these fields should already be NULL
	sw		r0,TCB_PrevTo[r1]
	lw		r4,TimeoutList		; are there any tasks on the timeout list ?
	beq		r4,attl_add_at_head	; If not, update head of list
attl_check_next:
    lw      r3,TCB_Timeout[r4]            
	subu	r2,r2,r3	        ; is this timeout > next
	blt		r2,attl_insert_before
	mov		r5,r4
	lw		r4,TCB_NextTo[r4]
	bne		r4,attl_check_next

	; timeout of a greater value. So we add the task to the end of the list.
attl_add_at_end:
	; Here we scanned until the end of the timeout list and didn't find a 
	sw		r0,TCB_NextTo[r1]		; 
	sw		r1,TCB_NextTo[r5]
	sw		r5,TCB_PrevTo[r1]
	sw		r2,TCB_Timeout[r1]
	bra		attl_exit

attl_insert_before:
	beq		r5,attl_insert_before_head
	sw		r4,TCB_NextTo[r1]	; next on list goes after this task
	sw		r5,TCB_PrevTo[r1]	; set previous link
	sw		r1,TCB_NextTo[r5]
	sw		r1,TCB_PrevTo[r4]
	bra		attl_adjust_timeout

	; Here there is no previous entry in the timeout list
	; Add at start
attl_insert_before_head:
	sw		r1,TCB_PrevTo[r4]
	sw		r0,TCB_PrevTo[r1]	;
	sw		r4,TCB_NextTo[r1]
	sw		r1,TimeoutList			; update the head pointer
attl_adjust_timeout:
	addu	r2,r2,r3	       ; get back timeout
	sw		r2,TCB_Timeout[r1]
	lw		r5,TCB_Timeout[r4]	; adjust the timeout of the next task
	subu	r5,r5,r2
	sw		r5,TCB_Timeout[r4]
	bra		attl_exit

	; Here there were no tasks on the timeout list, so we add at the
	; head of the list.
attl_add_at_head:
	sw		r1,TimeoutList		; set the head of the timeout list
	sw		r2,TCB_Timeout[r1]
	; flag no more entries in timeout list
	sw		r0,TCB_NextTo[r1]	; no next entries
	sw		r0,TCB_PrevTo[r1]	; and no prev entries
attl_exit:
	lb		r2,TCB_Status[r1]	; set the task's status as timing out
	or		r2,r2,#TS_TIMEOUT
	sb		r2,TCB_Status[r1]
	pop		r5
	pop		r4
	pop     r3
	pop     r2
attl1:
	rts
	
;------------------------------------------------------------------------------
; RemoveFromTimeoutList
;
; This routine is called when a task is killed. The task may need to be
; removed from the middle of the timeout list.
;
; On entry: the timeout list semaphore must be already set.
; Registers Affected: none
; Parameters:
;	 r1 = pointer to task control block
;------------------------------------------------------------------------------

RemoveFromTimeoutList:
    push    lr
	push    r2
	push    r3
	push	r4
	push	r5

    bsr     ValidateTCBPtr
    beq     r1,rftBadPtr
	lb		r4,TCB_Status[r1]		; Is the task even on the timeout list ?
	and		r4,r4,#TS_TIMEOUT
	beq		r4,rftl_not_on_list
	lw      r5,TimeoutList
	cmp		r4,r1,r5         		; Are we removing the head of the list ?
	beq		r4,rftl_remove_from_head
	lw		r4,TCB_PrevTo[r1]		; adjust the links of the next and previous
	beq		r4,rftl_empty_list		; no previous link - list corrupt?
	lw		r5,TCB_NextTo[r1]		; tasks on the list to point around the task
	sw		r5,TCB_NextTo[r4]
	beq		r5,rftl_empty_list
	sw		r4,TCB_PrevTo[r5]
	lw		r2,TCB_Timeout[r1]		; update the timeout of the next on list
	lw      r3,TCB_Timeout[r5]
	add		r2,r2,r3            	; with any remaining timeout in the task
	sw		r2,TCB_Timeout[r5]		; removed from the list
	bra		rftl_empty_list

	; Update the head of the list.
rftl_remove_from_head:
	lw		r5,TCB_NextTo[r1]
	sw		r5,TimeoutList			; store next field into list head
	beq		r5,rftl_empty_list
	lw		r4,TCB_Timeout[r1]		; add any remaining timeout to the timeout
	lw      r3,TCB_Timeout[r5]
	add		r4,r4,r3            	; of the next task on the list.
	sw		r4,TCB_Timeout[r5]
	sw		r0,TCB_PrevTo[r5]       ; there is no previous item to the head
	
	; Here there is no previous or next items in the list, so the list
	; will be empty once this task is removed from it.
rftl_empty_list:
	mov     r2,r1
	lb		r3,TCB_Status[r2]	; clear timeout status (bit #0)
	and     r3,r3,#$FE
	sb      r3,TCB_Status[r2]
	sw		r0,TCB_NextTo[r2]	; make sure the next and prev fields indicate	
	sw	    r0,TCB_PrevTo[r2]   ; the task is not on a list.
	mov     r1,r2
rftl_not_on_list:
	pop		r5
	pop		r4
	pop     r3
	pop     r2
rftl_not_on_list2:
rftBadPtr:
	rts

;------------------------------------------------------------------------------
; PopTimeoutList
;
; This subroutine is called from within the timer ISR when the task's 
; timeout expires. It's always the head of the list that's being removed in
; the timer ISR so the removal from the timeout list is optimized. We know
; the timeout expired, so the amount of time to add to the next task is zero.
;
; Registers Affected: 
; Parameters:
;	r2: head of timeout list
; Returns:
;	r1 = task id of task popped from timeout list
;------------------------------------------------------------------------------

PopTimeoutList:
	lw		r1,TCB_NextTo[r2]
	sw		r1,TimeoutList  ; store next field into list head
	beq		r1,ptl1
	sw		r0,TCB_PrevTo[r1]; previous link = NULL
ptl1:
    lb      r1,TCB_Status[r2]
    and     r1,r1,#$FE       ; clear timeout status
    sb      r1,TCB_Status[r2]
	sw		r0,TCB_NextTo[r2]	; make sure the next and prev fields indicate
	sw		r0,TCB_PrevTo[r2]		; the task is not on a list.
	mov     r1,r2
    rtl

;------------------------------------------------------------------------------
; Sleep
;
; Put the currently running task to sleep for a specified time.
;
; Registers Affected: none
; Parameters:
;	r1 = time duration in jiffies (1/60 second).
; Returns: none
;------------------------------------------------------------------------------
message "sleep"

Sleep:
    push    lr
    push    r1
    push    r2
	mov     r2,r1
	bsr     LockSYS
	mov		r1,tr
	bsr		RemoveTaskFromReadyList
	bsr		AddToTimeoutList	; The scheduler will be returning to this
	bsr     UnlockSYS
	int		#2				; task eventually, once the timeout expires,
	pop     r2
	pop     r1
	rts

;------------------------------------------------------------------------------
; Allocate a mailbox
; Parameters:
;	r1 = pointer to place to store handle
; Returns:
;	r1 = E_Ok	means mailbox allocated properly
;	r1 = E_Arg	means a NULL pointer was passed in r1
;	r1 = E_NoMoreMbx	means no more mailboxes were available
;	zf is set if everything is ok, otherwise zf is clear
;------------------------------------------------------------------------------
;
AllocMbx:
	beq		r1,ambx_bad_ptr
	push    lr
	push    r2
	push    r3
	push	r4
	mov		r4,r1			; r4 = pointer to returned handle
	bsr     LockSYS
	lw		r1,FreeMbxHandle			; Get mailbox off of free mailbox list
	sw		r1,[r4]			; store off the mailbox number
	beq		r1,ambx_no_mbxs
	lw		r2,MBX_LINK[r1]		; and update the head of the list
	sw		r2,FreeMbxHandle
	dec		nMailbox		; decrement number of available mailboxes
	mov		r3,tr           ; Add the mailbox to the list of mailboxes
	lw		r2,TCB_MbxList[tr]	; managed by the task.
	sw		r2,MBX_LINK[r1]
	sw		r1,TCB_MbxList[tr]
	mov     r2,r1
	lw		r1,TCB_hJCB[tr]

	sw		tr,MBX_OWNER[r2]
	sw		r0,MBX_TQ_HEAD[r2] ; initialize the head and tail of the queues
	sw		r0,MBX_TQ_TAIL[r2]
	sw		r0,MBX_MQ_HEAD[r2]
	sw		r0,MBX_MQ_TAIL[r2]
	sw		r0,MBX_TQ_COUNT[r2]	; initialize counts to zero
	sw		r0,MBX_MQ_COUNT[r2]
	sw		r0,MBX_MQ_MISSED[r2]
	ldi		r1,#8				; set the max queue size
	sw		r1,MBX_MQ_SIZE[r2]	; and
	ldi		r1,#MQS_NEWEST		; queueing strategy
	sw		r1,MBX_MQ_STRATEGY[r2]
	bsr     UnlockSYS
	pop		r4
	pop     r3
	pop     r2
	ldi		r1,#E_Ok
	rts
ambx_bad_ptr:
	ldi		r1,#E_Arg
	rtl
ambx_no_mbxs:
	bsr     UnlockSYS
	pop		r4
	pop     r3
	pop     r2
	ldi		r1,#E_NoMoreMbx
	rts

;------------------------------------------------------------------------------
; Free up a mailbox.
;	This function frees a mailbox from the currently running task. It may be
; called by ExitTask().
;
; Parameters:
;	r1 = mailbox handle
;------------------------------------------------------------------------------

FreeMbx:
    push    lr
	push    r2
	mov     r2,tr
	bsr		FreeMbx2
	pop     r2
	rts

;------------------------------------------------------------------------------
; Free up a mailbox.
;	This function dequeues any messages from the mailbox and adds the messages
; back to the free message pool. The function also dequeues any threads from
; the mailbox.
;	Called from KillTask() and FreeMbx().
;
; Parameters:
;	r1 = mailbox handle
;	r2 = task handle
; Returns:
;	r1 = E_Ok	if everything ok
;	r1 = E_Arg	if a bad handle is passed
;------------------------------------------------------------------------------

FreeMbx2:
    push    lr
	push    r2
	push    r3
	push    r4
	cmp     r3,r1,#MBX_Array
	blt     r3,fmbx0
	cmp     r3,r1,#MBX_ArrayEnd
	bge     r3,fmbx0
	mov     r4,r1
	mov     r1,r2
	bsr     ValidateTCBPtr
	beq     r1,fmbx0
	mov     r1,r4
	bsr     LockSYS

	; Dequeue messages from mailbox and add them back to the free message list.
fmbx5:
	push    r1
	bsr		DequeueMsgFromMbx
	beq		r1,fmbx3
	push    r2
	lw		r2,FreeMsg
	sw		r2,MSG_LINK[r1]
	sw		r1,FreeMsg
	pop     r2
	pop     r1
	bra		fmbx5
fmbx3:
	pop     r1

	; Dequeue threads from mailbox.
fmbx6:
	push    r1
	bsr		DequeueThreadFromMbx2
	beq		r1,fmbx7
	pop     r1
	bra		fmbx6
fmbx7:
	pop     r1

	; Remove mailbox from TCB list
	lw		r3,TCB_MbxList[r2]
	push    r2
	ldi		r2,#-1
fmbx10:
	cmp		r4,r1,r3
	beq		r4,fmbx9
	mov     r2,r3
	lw		r3,MBX_LINK[r3]
	bne		r3,fmbx10
	; ?The mailbox was not in the list managed by the task.
	pop     r2
	bra		fmbx2
fmbx9:
	beq		r2,fmbx11
	lw		r3,MBX_LINK[r3]
	sw		r3,MBX_LINK[r2]
	pop     r2
	bra		fmbx12
fmbx11:
	; No prior mailbox in list, update head
	lw		r3,MBX_LINK[r1]
	pop     r2
	sw		r3,TCB_MbxList[r2]

fmbx12:
	; Add mailbox back to mailbox pool
	lw		r2,FreeMbxHandle
	sw		r2,MBX_LINK[r1]
	sw		r1,FreeMbxHandle
fmbx2:
	bsr     UnlockSYS
	pop     r4
	pop     r3
	pop     r2
	ldi		r1,#E_Ok
	rts
fmbx1:
	bsr     UnlockSYS
fmbx0:
	pop     r4
	pop     r3
	pop     r2
	ldi		r1,#E_Arg
	rts

;------------------------------------------------------------------------------
; Queue a message at a mailbox.
; On entry the mailbox semaphore is already activated.
;
; Parameters:
;	r1 = message
;	r2 = mailbox
;------------------------------------------------------------------------------

QueueMsgAtMbx:
	beq		r1,qmam_bad_msg
	push    lr
	push    r1
	push    r2
	push    r3
	push	r4
	lw		r4,MBX_MQ_STRATEGY[r2]
	cmp		r3,r4,#MQS_UNLIMITED
	beq		r3,qmam_unlimited
	cmp		r3,r4,#MQS_NEWEST
	beq		r3,qmam_newest
	cmp		r3,r4,#MQS_OLDEST
	beq		r3,qmam_oldest
	bsr		kernel_panic
	db		"Illegal message queue strategy",0
	bra		qmam8
	; Here we assumed "unlimited" message storage. Just add the new message at
	; the tail of the queue.
qmam_unlimited:
	lw		r3,MBX_MQ_TAIL[r2]
	beq		r3,qmam_add_at_head
	sw		r1,MSG_LINK[r3]
	bra		qmam2
qmam_add_at_head:
	sw		r1,MBX_MQ_HEAD[r2]
qmam2:
	sw		r1,MBX_MQ_TAIL[r2]
qmam6:
	inc		MBX_MQ_COUNT[r2]		; increase the queued message count
	sw		r0,MSG_LINK[r1]
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rts
qmam_bad_msg:
	rtl
	; Here we are queueing a limited number of messages. As new messages are
	; added at the tail of the queue, messages drop off the head of the queue.
qmam_newest:
	lw		r3,MBX_MQ_TAIL[r2]
	beq		r3,qmam3
	sw		r1,MSG_LINK[r3]
	bra		qmam4
qmam3:
	sw		r1,MBX_MQ_HEAD[r2]
qmam4:
	sw		r1,MBX_MQ_TAIL[r2]
	lw		r3,MBX_MQ_COUNT[r2]
	addui   r3,r3,#1
	lw      r4,MBX_MQ_SIZE[r2]
	cmpu    r3,r3,r4
	ble		r3,qmam6
	sw		r0,MSG_LINK[r1]
	; Remove the oldest message which is the one at the head of the mailbox queue.
	; Add the message back to the pool of free messages.
	lw		r1,MBX_MQ_HEAD[r2]
	lw		r3,MSG_LINK[r1]		; move next in queue
	sw		r3,MBX_MQ_HEAD[r2]	; to head of list
qmam8:
	inc		MBX_MQ_MISSED[r2]
qmam1:
    bsr     LockFreeMSG
	lw		r3,FreeMsg				; put old message back into free message list
	sw		r3,MSG_LINK[r1]
	sw		r1,FreeMsg
	inc		nMsgBlk
	sw		r0,freemsg_sema
	;GoReschedule
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rts
	; Here we are buffering the oldest messages. So if there are too many messages
	; in the queue already, then the queue doesn't change and the new message is
	; lost.
qmam_oldest:
	lw		r3,MBX_MQ_COUNT[r2]		; Check if the queue is full
	lw      r4,MBX_MQ_SIZE[r2]
	cmpu	r3,r3,r4
	bge		r3,qmam8			; If the queue is full, then lose the current message
	bra		qmam_unlimited		; Otherwise add message to queue

;------------------------------------------------------------------------------
; Dequeue a message from a mailbox.
;
; Returns
;	r1 = message pointer (NULL if there are no messages)
;------------------------------------------------------------------------------

DequeueMsgFromMbx:
    push    r2
    push    r3
	mov     r2,r1				; x = mailbox index
	lw		r1,MBX_MQ_COUNT[r2]		; are there any messages available ?
	beq		r1,dmfm3
	subui   r1,r1,#1
	sw		r1,MBX_MQ_COUNT[r2]		; update the message count
	lw		r1,MBX_MQ_HEAD[r2]		; Get the head of the list, this should not be NULL
	beq		r1,dmfm3			; since the message count > 0
	lw		r3,MSG_LINK[r1]		; get the link to the next message
	sw		r3,MBX_MQ_HEAD[r2]		; update the head of the list
	bne		r3,dmfm2			; if there was no more messages then update the
	sw		r3,MBX_MQ_TAIL[r2]	; tail of the list as well.
dmfm2:
	sw		r1,MSG_LINK[r1]		; point the link to the message itself to indicate it's dequeued
dmfm1:
    pop     r3
    pop     r2
	rts
dmfm3:
    pop     r3
    pop     r2
	ldi		r1,#0
	rtl

;------------------------------------------------------------------------------
; Parameters:
;	r1 = mailbox handle
; Returns:
;	r1 = E_arg		means pointer is invalid
;	r1 = E_NoThread	means no thread was queued at the mailbox
;	r2 = thead handle
;------------------------------------------------------------------------------

DequeueThreadFromMbx:
	push	r4
	lw		r4,MBX_TQ_HEAD[r1]
	bne		r4,dtfm2
	pop		r4
	ldi		r2,#0
	ldi		r1,#E_NoThread
	rtl
dtfm2:
	push	r5
	dec		MBX_TQ_COUNT[r1]
	mov		r2,r4
	lw		r4,TCB_mbq_next[r4]
	sw		r4,MBX_TQ_HEAD[r1]
	beq		r4,dtfm3
		sw		r0,TCB_mbq_prev[r4]
		bra		dtfm4
dtfm3:
		sw		r0,MBX_TQ_TAIL[r1]
dtfm4:
	mov		r5,r2
	lb		r1,TCB_Status[r5]
	and		r1,r1,#TS_TIMEOUT
	beq		r1,dtfm5
	mov		r1,r5
	push    lr
	jsr		RemoveFromTimeoutList
	pop     lr
dtfm5:
	sw		r0,TCB_mbq_next[r5]
	sw		r0,TCB_mbq_prev[r5]
	sw		r0,TCB_hWaitMbx[r5]
	sb		r0,TCB_Status[r5]		; set task status = TS_NONE
	pop		r5
	pop		r4
	ldi		r1,#E_Ok
	rtl

;------------------------------------------------------------------------------
;	This function is called from FreeMbx(). It dequeues threads from the
; mailbox without removing the thread from the timeout list. The thread will
; then timeout waiting for a message that can never be delivered.
;
; Parameters:
;	r1 = mailbox handle
; Returns:
;	r1 = E_arg		means pointer is invalid
;	r1 = E_NoThread	means no thread was queued at the mailbox
;	r2 = thead handle
;------------------------------------------------------------------------------

DequeueThreadFromMbx2:
	push	r4
	lw		r4,MBX_TQ_HEAD[r1]
	bne		r4,dtfm2a
	pop		r4
	ldi		r2,#0
	ldi		r1,#E_NoThread
	rtl
dtfm2a:
	push	r5
	dec		MBX_TQ_COUNT[r1]
	mov		r2,r4
	lw		r4,TCB_mbq_next[r4]
	sw		r4,MBX_TQ_HEAD[r1]
	beq		r4,dtfm3a
		sw		r0,TCB_mbq_prev[r4]
		bra		dtfm4a
dtfm3a:
		sw		r0,MBX_TQ_TAIL[r1]
dtfm4a:
	sw	    r0,TCB_mbq_next[r2]
	sw		r0,TCB_mbq_prev[r2]
	sw		r0,TCB_hWaitMbx[r2]
;	sei
    lb      r1,TCB_Status[r2]
    and     r1,r1,#~TS_WAITMSG
    sb      r1,TCB_Status[r2]
;	cli
	pop		r5
	pop		r4
	ldi		r1,#E_Ok
	rtl

;------------------------------------------------------------------------------
; PostMsg and SendMsg are the same operation except that PostMsg doesn't
; invoke rescheduling while SendMsg does. So they both call the same
; SendMsgPrim primitive routine. This two wrapper functions for convenience.
;------------------------------------------------------------------------------

PostMsg:
    push    lr
	push	r4
	ldi		r4,#0			; Don't invoke scheduler
	bsr		SendMsgPrim
	pop		r4
	rts

SendMsg:
    push    lr
	push	r4
	ldi		r4,#1			; Do invoke scheduler
	jsr		SendMsgPrim
	pop		r4
	rts

;------------------------------------------------------------------------------
; SendMsgPrim
; Send a message to a mailbox
;
; Parameters
;	r1 = handle to mailbox
;	r2 = message D1
;	r3 = message D2
;	r4 = scheduler flag		1=invoke,0=don't invoke
;
; Returns
;	r1=E_Ok			everything is ok
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r1=E_NoMsg		if there are no more message blocks available
;------------------------------------------------------------------------------
message "SendMsgPrim"
SendMsgPrim:
    push    lr
	push	r5
	push	r6
	push	r7

    cmpu    r5,r1,#MBX_Array
    blt     r5,smsg1
    cmpu    r5,r1,#MBX_ArrayEnd
    bge     r5,smsg1
    bsr     LockSYS
	lw		r7,MBX_OWNER[r1]
	beq		r7,smsg2				; error: no owner
	push    r1
	push    r2
	bsr		DequeueThreadFromMbx	; r1=mbx
	mov		r6,r2					; r6 = thread
	pop     r2
	pop     r1
	bne		r6,smsg3
		; Here there was no thread waiting at the mailbox, so a message needs to
		; be allocated
smp2:
		lw		r7,FreeMsg
		beq		r7,smsg4		; no more messages available
		lw		r5,MSG_LINK[r7]
		sw		r5,FreeMsg
		dec		nMsgBlk		; decrement the number of available messages
		sw		r0,freemsg_sema
		sw		r2,MSG_D1[r7]
		sw		r3,MSG_D2[r7]
		push    r1
		push    r2
		mov     r2,r1			; r2 = mailbox
		mov		r1,r7			; r1 = message
		bsr		QueueMsgAtMbx
		pop     r2
		pop     r1
		beq		r6,smsg5    ; check if there is a thread waiting for a message
smsg3:
	sw		r2,TCB_MSG_D1[r6]
	sw		r3,TCB_MSG_D2[r6]
smsg7:
	lb		r5,TCB_Status[r6]
	and		r5,r5,#TS_TIMEOUT
	beq		r5,smsg8
	mov		r1,r6
	bsr		RemoveFromTimeoutList
smsg8:
    lb      r1,TCB_Status[r6]
    and     r1,r1,#~TS_WAITMSG
    sb      r1,TCB_Status[r6]
	mov		r1,r6
	bsr		AddTaskToReadyList
	sw		r0,sys_sema
	beq		r4,smsg5
	bsr     UnlockSYS
	int		#2
	;GoReschedule
	bra		smsg9
smsg5:
	bsr     UnlockSYS
smsg9:
	pop		r7
	pop		r6
	pop		r5
	ldi		r1,#E_Ok
	rts
smsg1:
	pop		r7
	pop		r6
	pop		r5
	ldi		r1,#E_BadMbx
	rtl
smsg2:
	bsr     UnlockSYS
	pop		r7
	pop		r6
	pop		r5
	ldi		r1,#E_NotAlloc
	rts
smsg4:
	bsr     UnlockSYS
	pop		r7
	pop		r6
	pop		r5
	ldi		r1,#E_NoMsg
	rts

;------------------------------------------------------------------------------
; WaitMsg
; Wait at a mailbox for a message to arrive. This subroutine will block the
; task until a message is available or the task times out on the timeout
; list.
;
; Parameters
;	r1=mailbox
;	r2=timeout
; Returns:
;	r1=E_Ok			if everything is ok
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r2=message D1
;	r3=message D2
;------------------------------------------------------------------------------
message "WaitMsg"
WaitMsg:
	push    lr
	push	r4
	push	r5
	push	r6
	push	r7
    cmpu    r5,r1,#MBX_Array
    blt     r5,wmsg1
    cmpu    r5,r1,#MBX_ArrayEnd
    bge     r5,wmsg1
	mov		r6,r1
wmsg11:
    bsr     LockSYS
	lw		r5,MBX_OWNER[r1]
;	cmp		r3,r5,#MAX_TASKNO
;	bgt		r3,wmsg2				; error: no owner
	bsr		DequeueMsgFromMbx
	bne		r1,wmsg3

	; Here there was no message available, remove the task from
	; the ready list, and optionally add it to the timeout list.
	; Queue the task at the mailbox.
wmsg12:
	mov		r1,tr				; remove the task from the ready list
	bsr		RemoveTaskFromReadyList
wmsg13:
	lb		r7,TCB_Status[r1]
	or		r7,r7,#TS_WAITMSG			; set task status to waiting
	sb		r7,TCB_Status[r1]
	sw		r6,TCB_hWaitMbx[r1]			; set which mailbox is waited for
	sw		r0,TCB_mbq_next[r1]			; adding at tail, so there is no next
	lw		r7,MBX_TQ_HEAD[r6]			; is there a task que setup at the mailbox ?
	beq		r7,wmsg6
	lw		r7,MBX_TQ_TAIL[r6]
	sw		r7,TCB_mbq_prev[r1]
	sw		r1,TCB_mbq_next[r7]
	sw		r1,MBX_TQ_TAIL[r6]
	inc		MBX_TQ_COUNT[r6]			; increment number of tasks queued
wmsg7:
	beq		r2,wmsg10                   ; check for a timeout
wmsg14:
	bsr		AddToTimeoutList
	bsr     UnlockSYS
	int		#2	;	GoReschedule			; invoke the scheduler
	bsr     LockSYS
wmsg10:
	; At this point either a message was sent to the task, or the task
	; timed out. If a message is still not available then the task must
	; have timed out. Return a timeout error.
	; Note that SendMsg will directly set the message D1, D2 data
	; without queing a message at the mailbox (if there is a task
	; waiting already). So we cannot just try dequeing a message again.
	lw		r2,TCB_MSG_D1[r1]
	lw		r3,TCB_MSG_D2[r1]
	lb		r4,TCB_Status[r1]
	bsr     UnlockSYS
	and		r4,r4,#TS_WAITMSG	; Is the task still waiting for a message ?
	beq		r4,wmsg8			; If not, go return OK status
	pop		r7				; Otherwise return timeout error
	pop		r6
	pop		r5
	pop		r4
	ldi		r1,#E_Timeout
	rts
	
	; Here there were no prior tasks queued at the mailbox
wmsg6:
	sw		r0,TCB_mbq_prev[r1]		; no previous tasks
	sw		r0,TCB_mbq_next[r1]
	sw		r1,MBX_TQ_HEAD[r6]		; set both head and tail indexes
	sw		r1,MBX_TQ_TAIL[r6]
	ldi		r7,#1
	sw		r7,MBX_TQ_COUNT[r6]		; one task queued
	bra		wmsg7					; check for a timeout value
	
wmsg3:
	lw		r2,MSG_D1[r1]
	lw		r3,MSG_D2[r1]
	; Add the newly dequeued message to the free messsage list
	lw		r7,FreeMsg
	sw		r7,MSG_LINK[r1]
	sw		r1,FreeMsg
	inc		nMsgBlk
	bsr     UnlockSYS
wmsg8:
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ldi		r1,#E_Ok
	rts
wmsg1:
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ldi		r1,#E_BadMbx
	rts
wmsg2:
	bsr     UnlockSYS
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ldi		r1,#E_NotAlloc
	rts

;------------------------------------------------------------------------------
; Check for a message at a mailbox. Does not block. This function is a
; convenience wrapper for CheckMsg().
;
; Parameters
;	r1=mailbox handle
; Returns:
;	r1=E_Ok			if everything is ok
;	r1=E_NoMsg		if no message is available
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r2=message D1
;	r3=message D2
;------------------------------------------------------------------------------

PeekMsg:
    push    lr
	ldi		r2,#0		; don't remove from queue
	bsr		CheckMsg
	rts

;------------------------------------------------------------------------------
; CheckMsg
; Check for a message at a mailbox. Does not block.
;
; Parameters
;	r1=mailbox handle
;	r2=remove from queue if present
; Returns:
;	r1=E_Ok			if everything is ok
;	r1=E_NoMsg		if no message is available
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r2=message D1
;	r3=message D2
;------------------------------------------------------------------------------
message "CheckMsg"
CheckMsg:
    push    lr
    push    r6
;	cmp		r3,r1,#NR_MBX			; check the mailbox number to make sure
;	bge		r3,cmsg1				; that it's sensible
    cmpu    r6,r1,#MBX_Array
    blt     r6,cmsg1
    cmpu    r6,r1,#MBX_ArrayEnd
    bge     r6,cmsg1
	push	r4
	push	r5

    bsr     LockSYS

	lw		r5,MBX_OWNER[r1]
	beq		r5,cmsg2				; error: no owner
	beq		r2,cmsg3                ; are we to dequeue the message ?
	bsr		DequeueMsgFromMbx
	bra		cmsg4
cmsg3:
	lw		r1,MBX_MQ_HEAD[r1]		; peek the message at the head of the messages queue
cmsg4:
	beq		r1,cmsg5
	mov     r4,r2
	lw		r2,MSG_D1[r1]
	lw		r3,MSG_D2[r1]
	beq		r4,cmsg8
cmsg10:
	lw		r5,FreeMsg
	sw		r5,MSG_LINK[r1]
	sw		r1,FreeMsg
	inc		nMsgBlk
cmsg8:
	bsr     UnlockSYS
	pop		r5
	pop		r4
	pop     r6
	ldi		r1,#E_Ok
	rts
cmsg1:
	ldi		r1,#E_BadMbx
	pop     r6
	rts
cmsg2:
	bsr     UnlockSYS
	pop		r5
	pop		r4
	pop     r6
	ldi		r1,#E_NotAlloc
	rts
cmsg5:
	bsr     UnlockSYS
	pop		r5
	pop		r4
	pop     r6
	ldi		r1,#E_NoMsg
	rts

;------------------------------------------------------------------------------
; System Call Exception
;
;------------------------------------------------------------------------------
;
syscall_exception:
    ldi     sp,TCB_SYS_Stack[tr]
	push	r6					; save off some working registers
	push	r7
	mfspr   r6,epc              ; get return address into r6
	and     r7,r6,#-2           ; clear LSB
	lh	    r7,4[r7]			; get static call number parameter into r7
	addui   r6,r6,#8			; update return address
	mtspr   epc,r6
	cmpu    r6,r7,#20
	bgt     r6,.bad_callno
	asl     r7,r7,#1
	lcu     r6,syscall_vectors[r7]       ; load the vector into r6
	or      r6,r6,#syscall_exception & 0xFFFFFFFFFFFF0000
	push    lr
	jsr		[r6]				; do the system function
	pop     lr
.bad_callno:
	pop		r7
	pop		r6
	rte

;------------------------------------------------------------------------------
; Reschedule tasks to run without affecting the timeout list timing.
;------------------------------------------------------------------------------

reschedule:
    cpuid   sp,r0,#0
    beq     sp,.0001
    ldi     sp,#CPU1_IRQ_STACK
    bra     .0002
.0001:
    ldi     sp,#CPU0_IRQ_STACK
.0002:
    push    r1
	push    r2
	lwar    r1,sys_sema
	bne     r1,.0004   
	swcr    tr,sys_sema       ; In this case interrupts are off already
	mfspr   r1,cr0            ; because we are in an interrupt routine.
	and     r1,r1,#$1000000000
	bne     r1,.0005
.0004:
	pop     r2
	pop     r1
	rti
.0005:
    pop     r2
    pop     r1
    sw      r1,TCB_r1[tr]
    sw      r2,TCB_r2[tr]
    sw      r3,TCB_r3[tr]
    sw      r4,TCB_r4[tr]
    sw      r5,TCB_r5[tr]
    sw      r6,TCB_r6[tr]
    sw      r7,TCB_r7[tr]
    sw      r8,TCB_r8[tr]
    sw      r9,TCB_r9[tr]
    sw      r10,TCB_r10[tr]
    sw      r11,TCB_r11[tr]
    sw      r12,TCB_r12[tr]
    sw      r13,TCB_r13[tr]
    sw      r14,TCB_r14[tr]
    sw      r15,TCB_r15[tr]
    sw      r16,TCB_r16[tr]
    sw      r17,TCB_r17[tr]
    sw      r18,TCB_r18[tr]
    sw      r19,TCB_r19[tr]
    sw      r20,TCB_r20[tr]
    sw      r21,TCB_r21[tr]
    sw      r22,TCB_r22[tr]
    sw      r23,TCB_r23[tr]
    sw      r24,TCB_r24[tr]
    sw      r25,TCB_r25[tr]
    sw      r26,TCB_r26[tr]
    sw      r27,TCB_r27[tr]
    sw      r28,TCB_r28[tr]
    sw      r29,TCB_r29[tr]
    mfspr   r1,isp
    sw      r1,TCB_ISP[tr]
    mfspr   r1,dsp
    sw      r1,TCB_DSP[tr]
    mfspr   r1,esp
    sw      r1,TCB_ESP[tr]
    sw      r31,TCB_r31[tr]
    mfspr   r1,ipc
    sw      r1,TCB_IPC[tr]
    mfspr   r1,dpc
    sw      r1,TCB_DPC[tr]
    mfspr   r1,epc
    sw      r1,TCB_EPC[tr]
    mfspr   r1,cr0
    sw      r1,TCB_CR0[tr]
resched1:
    lb      r1,TCB_Status[tr]  ; clear RUNNING status (bit #3)
    and     r1,r1,#~TS_RUNNING
    sb      r1,TCB_Status[tr]
	jmp		SelectTaskToRun

strStartQue:
	db		0,0,0,1,0,0,0,2,0,1,0,3,0,0,0,4,0,1,0,5,0,0,0,6,0,1,0,7
;	db		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;------------------------------------------------------------------------------
; 60 Hz interrupt
; - takes care of "flashing" the cursor
; - decrements timeouts for tasks on timeout list
; - switching tasks
;------------------------------------------------------------------------------

FMTKTick:
    cpuid   sp,r0,#0
    beq     sp,.0001
    ldi     sp,#CPU1_IRQ_STACK
    bra     .0002
.0001:
    ldi     sp,#CPU0_IRQ_STACK
.0002:
    push    r1
    
    ; Lock up the resources needed by the tick routine
    lwar    r1,sys_sema
    bne     r1,.cantLockSYS
    swcr    tr,sys_sema
    mfspr   r1,cr0
    and     r1,r1,#1000000000
    bne     r1,.SYSLocked
.cantLockSYS:
    pop     r1
    rti

.SYSLocked:
    ; Each CPU has it's own PIC mapped at the same address.
	ldi		r1,#3				; reset the edge sense circuit
	sh		r1,PIC_RSTE
	inc		IRQFlag

    pop     r1
    sw      r1,TCB_r1[tr]
    sw      r2,TCB_r2[tr]
    sw      r3,TCB_r3[tr]
    sw      r4,TCB_r4[tr]
    sw      r5,TCB_r5[tr]
    sw      r6,TCB_r6[tr]
    sw      r7,TCB_r7[tr]
    sw      r8,TCB_r8[tr]
    sw      r9,TCB_r9[tr]
    sw      r10,TCB_r10[tr]
    sw      r11,TCB_r11[tr]
    sw      r12,TCB_r12[tr]
    sw      r13,TCB_r13[tr]
    sw      r14,TCB_r14[tr]
    sw      r15,TCB_r15[tr]
    sw      r16,TCB_r16[tr]
    sw      r17,TCB_r17[tr]
    sw      r18,TCB_r18[tr]
    sw      r19,TCB_r19[tr]
    sw      r20,TCB_r20[tr]
    sw      r21,TCB_r21[tr]
    sw      r22,TCB_r22[tr]
    sw      r23,TCB_r23[tr]
    sw      r24,TCB_r24[tr]
    sw      r25,TCB_r25[tr]
    sw      r26,TCB_r26[tr]
    sw      r27,TCB_r27[tr]
    sw      r28,TCB_r28[tr]
    sw      r29,TCB_r29[tr]
    mfspr   r1,isp
    sw      r1,TCB_ISP[tr]
    mfspr   r1,dsp
    sw      r1,TCB_DSP[tr]
    mfspr   r1,esp
    sw      r1,TCB_ESP[tr]
    sw      r31,TCB_r31[tr]
    mfspr   r1,ipc
    sw      r1,TCB_IPC[tr]
    mfspr   r1,dpc
    sw      r1,TCB_DPC[tr]
    mfspr   r1,epc
    sw      r1,TCB_EPC[tr]
    mfspr   r1,cr0
    sw      r1,TCB_CR0[tr]

	cpuid   r1,r0,#0
	bne     r1,p100Hz4
	lw		r1,UserTick
	beq		r1,p100Hz4
	push    lr
	jsr		[r1]
	pop     lr
p100Hz4:
    lb      r1,TCB_Status[tr]
    and     r1,r1,#~TS_RUNNING
    sb      r1,TCB_Status[tr]

	; Check the timeout list to see if there are items ready to be removed from
	; the list. Also decrement the timeout of the item at the head of the list.
	; Note the timeout list is checked by each CPU which decrements timeouts,
	; the resulting decrement rate is 60Hz as each CPU services the interrupt
	; at a 30Hz rate.
p100Hz15:
	lw		r2,TimeoutList
	beq		r2,p100Hz12				; are there any entries in the timeout list ?
	lw		r1,TCB_Timeout[r2]
	bne		r1,p100Hz14				; has this entry timed out ?
p100Hz1:
	push    lr
	bsr     PopTimeoutList
	bsr		AddTaskToReadyList
	pop     lr
	bra		p100Hz15				; go back and see if there's another task to be removed
									; there could be a string of tasks to make ready.
p100Hz_missed_tick:
    inc     missed_ticks
    bra     p100Hz12

p100Hz14:
	subui   r1,r1,#1				; decrement the entry's timeout
	lw      r3,missed_ticks
	subu	r1,r1,r3        		; account for any missed ticks
	sw		r0,missed_ticks
	sw		r1,TCB_Timeout[r2]
	bmi     r1,p100Hz1
	
p100Hz12:
	; Falls through into selecting a task to run
tck3:

;------------------------------------------------------------------------------
; Search the ready queues for a ready task.
; The search is occasionally started at a lower priority queue in order
; to prevent starvation of lower priority tasks. This is managed by 
; using a tick count as an index to a string containing the start que.
;------------------------------------------------------------------------------
;
SelectTaskToRun:
	ldi		r6,#8			; number of queues to search
	lw		r3,IRQFlag		; use the IRQFlag as a buffer index
	and		r3,r3,#$1F		; counts from 0 to 31
	lb	    r3,strStartQue[r3]	; get the queue to start search at
	and     r3,r3,#7
sttr2:
    asl     r4,r3,#3
	lw		r1,QNdx0[r4]
	beq		r1,sttr1
	; The task could already be running on the other CPU, don't run a running
	; task.
	lb      r5,TCB_Status[r1]
	and     r7,r5,#TS_RUNNING
	bne     r7,sttr9
sttr10:
	lw		r1,TCB_NextRdy[r1]		; Advance the queue index
	; Task control blocks are aligned on 256B boundaries. Address ends in "$00"
    ; Check and make sure this is the case. This should catch most bad pointers.
	and     r7,r1,#$FF
	bne     r7,sttr_badtask
	; Now make sure the pointer is within the Task Control Block memory range.
	cmpu    r7,r1,#TCB_Array
	blt     r7,sttr_badtask
	cmpu    r7,r1,#TCB_ArrayEnd-TCB_Size
	bgt     r7,sttr_badtask
	; Probably got a valid pointer...
	; CPU #0 can run any task, CPU #1 can only run tasks associated with it as
	; it has no I/O. -- for the moment
	cpuid   r7,r0,#0
;	beq     r7,sttr5
	lbu     r8,TCB_Affinity[r1]
	cmp     r7,r7,r8
	bne     r7,sttr1
sttr5:
	; This is the only place the RunningTCB is set (except for initialization).
	sw		r1,QNdx0[r4]
	mov     tr,r1
	lb      r1,TCB_Status[tr]
	or      r1,r1,#TS_RUNNING    ; flag the task as the running task
	sb      r1,TCB_Status[tr]
	; Only CPU #0 has access to I/O, so check for an I/O focus switch only
	; on CPU #0.
	cpuid   r1,r0,#0
	bne     r1,sttr6
	lw		r1,iof_switch		
	beq		r1,sttr6				
	lwar	r1,iof_sema		; just ignore the request to switch
	bne		r1,sttr7		; I/O focus if the semaphore can't be aquired
	swcr    tr,iof_sema
	mfspr   r1,cr0
	and     r1,r1,#$1000000000
	beq     r1,sttr6
	sw		r0,iof_switch
	push    lr
	bsr		SwitchIOFocus
	pop     lr
	sw		r0,iof_sema
	; Restore the task context
sttr6:
    lw      r1,TCB_CR0[tr]
    mtspr   cr0,r1
    lw      r1,TCB_EPC[tr]
    mtspr   epc,r1
    lw      r1,TCB_DPC[tr]
    mtspr   dpc,r1
    lw      r1,TCB_IPC[tr]
    mtspr   ipc,r1
    lw      r31,TCB_r31[tr]
    lw      r1,TCB_ESP[tr]
    mtspr   esp,r1
    lw      r1,TCB_DSP[tr]
    mtspr   dsp,r1
    lw      r1,TCB_ISP[tr]
    mtspr   isp,r1
    lw      r29,TCB_r29[tr]
    lw      r28,TCB_r28[tr]
    lw      r27,TCB_r27[tr]
    lw      r26,TCB_r26[tr]
    lw      r25,TCB_r25[tr]
;   lw      r24,TCB_r24[tr]    ; r24 is the task register - no need to load
    lw      r23,TCB_r23[tr]
    lw      r22,TCB_r22[tr]
    lw      r21,TCB_r21[tr]
    lw      r20,TCB_r20[tr]
    lw      r19,TCB_r19[tr]
    lw      r18,TCB_r18[tr]
    lw      r17,TCB_r17[tr]
    lw      r16,TCB_r16[tr]
    lw      r15,TCB_r15[tr]
    lw      r14,TCB_r14[tr]
    lw      r13,TCB_r13[tr]
    lw      r12,TCB_r12[tr]
    lw      r11,TCB_r11[tr]
    lw      r10,TCB_r10[tr]
    lw      r9,TCB_r9[tr]
    lw      r8,TCB_r8[tr]
    lw      r7,TCB_r7[tr]
    lw      r6,TCB_r6[tr]
    lw      r5,TCB_r5[tr]
    lw      r4,TCB_r4[tr]
    lw      r3,TCB_r3[tr]
    lw      r2,TCB_r2[tr]
    lw      r1,TCB_r1[tr]
    sw      r0,sys_sema
	rti
sttr7:
    swcr    r1,iof_sema
    bra     sttr6

	; Set index to check the next ready list for a task to run
sttr1:
	addui   r3,r3,#1
	and     r3,r3,#7     ; count moduluo 8
	subui   r6,r6,#1
	bge		r6,sttr2
 
	; Here there were no tasks ready
	; This should not be able to happen, so hang the machine (in a lower
	; power mode).
	; For now just go back to running whatever was running in the first place.
	; Something had to be running sucessfully before the interrupt; return to
    ; it.
    bra     sttr6
sttr3:
	cpuid   r1,r0,#0
sttr8:
	bne     r1,sttr8
	push    lr
	bsr		kernel_panic
	db		"No tasks in ready queue.",0
	bsr     DumpTaskList
	pop     lr
	; Might as well power down the clock and wait for a reset or
	; NMI. In the case of an NMI the kernel is reinitialized without
	; doing the boot reset.
	stp								
	jmp		FMTKInitialize

    ; We found a running task at the head of a ready queue. Check for a next
    ; ready task.
sttr9:
    ; If the next ready task is just the running one, then go check the next
    ; queue.
    lw      r7,TCB_NextRdy[r1]
    beq     r7,sttr1            ; NULL pointer ?
    cmp     r7,r1,r7
    beq     r7,sttr1            ; Running = next
    ; Assume there aren't two running tasks (there shouldn't be)
    cmp     r7,r1,tr            ; skip over outgoing task
    beq     r7,sttr1    
    bra     sttr10
    ;
    
    
    
    
sttr_badtask:
	cpuid   r1,r0,#0
	bne     r1,sttr1
    bsr     kernel_panic
    db      "Bad task on ready list.",0
    bra     sttr1

;------------------------------------------------------------------------------
; kernal_panic:
;	All this does right now is display the panic message on the screen.
; Parameters:
;	inline: string
;------------------------------------------------------------------------------
;
kernel_panic:
    push    r1
kpan2:
	lbu	    r1,[lr]		; get a byte from the code space
	beq		r1,kpan1		; is it end of string ?
	addui	lr,lr,#1	; increment pointer
	push    lr
	bsr		OutChar
	pop     lr
	bra		kpan2
kpan1:
    push    lr   		; must update the return address !
	bsr		CRLF
	pop     lr
	pop     r1
	addui   lr,lr,#3    ; round the link register to the next instruction address
	and     lr,lr,#-4
	rtl

