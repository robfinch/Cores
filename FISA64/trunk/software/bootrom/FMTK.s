;==============================================================================
; Finitron Multi-Tasking Kernel (FMTK)
;        __
;   \\__/ o\    (C) 2013, 2014, 2015  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;==============================================================================
include "FMTK_Equates.inc"

	org		$1E000
syscall_vectors:
	dw		FMTKInitialize
	dw		StartTask
	dw		ExitTask
	dw		KillTask
	dw		SetTaskPriority
	dw		Sleep
	dw		AllocMbx
	dw		FreeMbx
	dw		PostMsg
	dw		SendMsg
	dw		WaitMsg
	dw		CheckMsg

message "InitFMTK"
BranchToSelf:
    bra     BranchToSelf

FMTKInitialize:
InitFMTK:
	; Initialize semaphores
	sw		r0,freetcb_sema
	sw		r0,freembx_sema
	sw		r0,freemsg_sema
	sw		r0,tcb_sema
	sw		r0,readylist_sema
	sw		r0,tolist_sema
	sw		r0,mbx_sema
	sw		r0,msg_sema
	sw		r0,jcb_sema

	mfspr	r2,vbr
	ldi		r1,#reschedule
	sw		r1,16[r2]
	ldi		r1,#syscall_int
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

	; zero out JCB's
	; This will NULL out the I/O focus list pointers
	ldi     r1,#NR_JCB * JCB_Size / 8 - 8
	ldi     r2,#JCB_Array
.0001:
	sw      r0,[r2+r1*8]
	subui   r1,r1,#1
	bge     r1,.0001

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
	mulu	r5,r3,#16284		; 8192 words per screen
	addui   r5,r5,#SCREEN_Array
	sw		r5,JCB_pVirtVid[r4]
	sw		r5,JCB_pVidMem[r4]
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
	addui	r1,r1,#MSG_Size
	addui   r2,r2,#MSG_Size
	cmp     r3,r2,#MSG_ArrayEnd
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

    ; Initialize the free TCB list
    ; The first two TCB's are pre-allocated and so aren't part of the list
    ldi     r2,#$TCB_Array+2*TCB_Size
    sw      r2,FreeTCB
    sw      r0,TCB_PrevFree[r2]
.0001:
    addui   r3,r2,#TCB_Size
    sw      r3,TCB_NextFree[r2]
    sw      r2,TCB_PrevFree[r3]
    addui   r2,r2,#TCB_Size
    cmpu    r4,r2,#TCB_ArrayEnd-TCB_Size
    blt     r4,.0001
    sw      r0,TCB_NextFree[r2]

    ldi     r2,#TCB_Array
    ldi     r4,#0
.nextTCB:
    ldi     r5,#JCB_Array
    sw      r5,TCB_hJCB[r2]   ; owning JOB = monitor
    ldi     r3,#BranchToSelf
    sw      r3,TCB_IPC[r2]    ; set startup address
    mulu    r3,r4,#4096       ; initial stack size=4096
    addui   r3,r3,#STACKS_Array+4088
    sw      r3,TCB_r30[r2]    ; set the stack pointer to the default stack
    addui   r2,r2,#TCB_size   ; move to next TCB 768B TCB size
    addui   r4,r4,#1
    cmpu    r1,r4,#NR_TCB
    blt     r1,.nextTCB

	; Manually setup the BIOS task
	ldi     tr,#TCB_Array
	sw		tr,RunningTCB	; BIOS is task #0
	sw		tr,TCB_NextRdy	; manually build the ready list
	sw		tr,TCB_PrevRdy
	sw		r0,TCB_NextTo
	sw		r0,TCB_PrevTo
	sw		tr,QNdx3		; insert at priority 3
	; manually build the IO focus list
	ldi		r1,#JCB_Array
	sw	    r1,IOFocusNdx		; Job #0 (Monitor) has the focus
	sw		r1,JCB_iof_next[r1]
	sw		r1,JCB_iof_prev[r1]
	ldi		r1,#1
	sw		r1,IOFocusTbl		; set the job #0 request bit

	ldi		r1,#3
	sc		r1,TCB_Priority[tr]
	sw		r0,TCB_Timeout[tr]
	ldi		r1,#TS_RUNNING|TS_READY
	sb		r1,TCB_Status[tr]
	sb		r0,TCB_CursorRow[tr]
	sb		r0,TCB_CursorCol[tr]
	ldi     r1,#STACKS_Array+$FF8   ; setup stack pointer top of memory
	sw		r1,TCB_r31[tr]

    rtl

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
StartIdleTask:
    push    lr
	ldi		r1,#7
	ldi		r2,#0
	ldi		r3,#IdleTask
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
	sys		#4				; KillTask function
	dh		3
;	jsr		KillTask
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
	push    r1
	
	; Get a free JCB
sjob4:
    lwar    r1,freejcb_sema
    bne     r1,sjob4
    swcr    tr,freejcb_sema
    mfspr   r1,cr0
    and     r1,r1,#$1000000000
    beq     r1,sjob4

	lw		r6,FreeJCB
	beq		r6,sjob1
	lw		r7,JCB_Next[r6]
	sw		r7,FreeJCB
	sw		r0,freejcb_sema

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
	blt		sjob3
sjob2:
	sb		r8,[r9]				; save name length

sjob1:
	sw		r0,freejcb_sema
	pop     r1
	rtl

;------------------------------------------------------------------------------
; Lock the task control blocks semaphore.
;------------------------------------------------------------------------------

LockFreeMBX:
    push    lr
    push    r1
    lea     r1,freembx_sema
    bsr     LockSema
    pop     r1
    rts

LockFreeMSG:
    push    lr
    push    r1
    lea     r1,freemsg_sema
    bsr     LockSema
    pop     r1
    rts

LockMBX:
    push    lr
    push    r1
    lea     r1,mbx_sema
    bsr     LockSema
    pop     r1
    rts

LockFreeTCB:
    push    lr
    push    r1
    lea     r1,freetcb_sema
    bsr     LockSema
    pop     r1
    rts

;------------------------------------------------------------------------------
; Lock the task control blocks semaphore.
;------------------------------------------------------------------------------

LockTCB:
    push    lr
    push    r1
    lea     r1,tcb_sema
    bsr     LockSema
    pop     r1
    rts

;------------------------------------------------------------------------------
; Lock the semaphore.
;
; While locking, a test is made to see if the task already owns the
; semaphore. This helps prevent problems in case of a software error in the
; OS. If an attempt is made to lock the semaphore twice (or more) by the same
; task, the OS would lock up waiting for the semaphore. Checking if it's
; already owned prevents this lockup.
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
    cmpu    r2,r3,tr            ; does the task already own the lock ?
    beq     r2,.0002
    bne     r3,.0001            ; branch if not yet free
    swcr    tr,[r1]             ; try and lock it
    mfspr   r3,cr0
    and     r3,r3,#$1000000000
    beq     r3,.0001            ; lock failed, go try again
    pop     r3
    pop     r2
    rtl
    ; Here we don't care if the store works, but we need to clear the
    ; address reservation.
.0002:
    swcr    tr,[r1]
    pop     r3
    pop     r2
    rtl

;------------------------------------------------------------------------------
; StartTask
;
; Startup a task. The task is automatically allocated a 1kW stack from the BIOS
; stacks area. The scheduler is invoked after the task is added to the ready
; list.
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
	mov		r6,r1				; r6 = task priority
	mov		r8,r2				; r8 = flag register value on startup
	
	; get a free TCB
	;
    bsr     LockFreeTCB
	lw		r1,FreeTCB			; get free tcb list pointer
	beq		r1,stask1
	mov     r2,r1
	lw		r1,TCB_NextFree[r2]
	sw		r1,FreeTCB			; update the FreeTCB list pointer
	sw		r0,freetcb_sema
	ldi		r1,#81
	sc		r1,LEDS
	mov     r1,r2				; r1 = TCB pointer

;	sw		r1,TCB_mbx[r2]???
	
	; setup the stack for the task
	; Zap the stack memory.
	mov		r7,r2
	subui   r2,r2,#TCB_Array
	divu    r2,r2,#TCB_Size     ; r2 = index number of TCB
	asl		r2,r2,#12			; 4kB stack per task
	addui	r8,r2,#STACKS_Array	; add in stack base
	mov     r2,r8
	addui   r2,r2,#4088
	sw      r2,TCB_StackTop[r7]
	sw      r2,TCB_r31[r7]
	
	; Fill the stack with the ExitTask address. This will cause a return
	; to the ExitTask routine when the task finishes.
	push    r1
	push    r2
	push    r3
	ldi		r1,#ExitTask		; r1 = fill value
.stask6:
	sw      r1,[r2]
	subui   r2,r2,#8
	cmpu    r3,r2,r8
	bgt     r3,.stask6
	pop     r3
	pop     r2
	pop     r1

    bsr     LockTCB
    	
	sb		r6,TCB_Priority[r7]
	sb		r0,TCB_Status[r7]
	sw		r0,TCB_Timeout[r7]
	sw		r5,TCB_hJCB[r7]		; save job handle
	ldi		r1,#82
	sc		r1,LEDS
	sw		r0,TCB_MbxList[r7]

	; Insert the task into the ready list
	mov     r1,r7
	bsr		AddTaskToReadyList
	sw		r0,tcb_sema       ; unlock TCB semaphore
	sys		#2			; invoke the scheduler
;	GoReschedule		; invoke the scheduler
stask2:
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
	sw		r0,freetcb_sema
	bsr		kernel_panic
	db		"No more task control blocks available.",0
	bra		stask2

;------------------------------------------------------------------------------
; ExitTask
;
; This routine is called when the task exits with an rts instruction. OR
; it may be invoked with a JMP ExitTask. In either case the task must be
; running so it can't be on the timeout list. The scheduler is invoked
; after the task is removed from the ready list.
;------------------------------------------------------------------------------
message "ExitTask"
ExitTask:
	; release any aquired resources
	; - mailboxes
	; - messages
;	hoff
    bsr     LockTCB
    mov     r1,tr
	bsr		RemoveTaskFromReadyList
	bsr		RemoveFromTimeoutList
	sw		r0,TCB_Status[r1]				; set task status to TS_NONE
	bsr		ReleaseIOFocus
	; Free up all the mailboxes associated with the task.
xtsk7:
	push    r1
	lw		r1,TCB_MbxList[r1]
	beq		r1,xtsk6
	bsr		FreeMbx
	pop     r1
	bra		xtsk7
xtsk6:
	pop     r1
	ldi		r2,#86
	sc		r2,LEDS
	bsr     LockFreeTCB
	lw		r2,FreeTCB						; add the task control block to the free list
	sw		r2,TCB_NextTCB[r1]
	sw		r1,FreeTCB
	sw		r0,freetcb_sema
	sw      r0,tcb_sema
xtsk1:
	jmp		SelectTaskToRun

;------------------------------------------------------------------------------
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
    lwar    r4,tcb_sema
    bne     r4,.0001
    swcr    tr,tcb_sema
    mfspr   r4,cr0
    and     r4,r4,#$1000000000
    beq     r4,.0001
dtl2:
	lw		r1,QNdx0[r3]
	mov		r4,r1
	beq		r4,dtl1
dtl3:
	ldi	    r2,#3
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
	db	CR,LF,"Pri Task Stat    Prv     Nxt     Timeout",CR,LF,0


;------------------------------------------------------------------------------
; r1 = task number
; r2 = new priority
;------------------------------------------------------------------------------

SetTaskPriority:
    push    lr
	push    r3
	bsr     LockTCB
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
	sw		r0,tcb_sema
	sys		#2
	pop     r3
	rts

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
; Registers Affected: none
; Parameters:
;	r1 = pointer to task control block
; Returns:
;	none
;------------------------------------------------------------------------------
message "AddToReadyList"
AddTaskToReadyList:
    push    r2
    push    r3
    push    r4
	ldi     r2,#TS_READY
	sb		r2,TCB_Status[r1]
	sw		r0,TCB_NextRdy[r1]
	sw		r0,TCB_PrevRdy[r1]
	lb		r3,TCB_Priority[r1]
	cmp		r4,r3,#8
	blt		r4,arl1
	ldi		r3,#PRI_LOWEST
arl1:
    asl     r3,r3,#3
	lw		r2,QNdx0[r3]
	beq		r2,arl5
	lw		r3,TCB_PrevRdy[r2]
	sw		r2,TCB_NextRdy[r3]
	sw		r3,TCB_PrevRdy[r1]
	sw		r1,TCB_PrevRdy[r2]
	sw		r2,TCB_NextRdy[r1]
	pop     r4
	pop     r3
	pop     r2
	rtl

	; Here the ready list was empty, so add at head
arl5:
	sw		r1,QNdx0[r3]
	sw		r1,TCB_NextRdy[r1]
	sw		r1,TCB_PrevRdy[r1]
	pop     r4
	pop     r3
	pop     r2
	rtl
	

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
    push    r2
    push    r3
	push	r4
	push	r5

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
	rtl

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
	push    r2
	push    r3
	push	r4
	push	r5

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
	rtl
	
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
	push    r2
	push    r3
	push	r4
	push	r5

	lb		r4,TCB_Status[r1]		; Is the task even on the timeout list ?
	and		r4,r4,#TS_TIMEOUT
	beq		r4,rftl_not_on_list
	cmp		r4,r1,TimeoutList		; Are we removing the head of the list ?
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
	rtl

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
	bsr     LockTCB
	lw		r1,RunningTCB
	bsr		RemoveTaskFromReadyList
	bsr		AddToTimeoutList	; The scheduler will be returning to this
	sw		r0,tcb_sema
	sys		2				; task eventually, once the timeout expires,
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
	ld		r4,r1			; r4 = pointer to returned handle
	bsr     LockFreeMBX
	lw		r1,FreeMbxHandle			; Get mailbox off of free mailbox list
	sw		r1,[r4]			; store off the mailbox number
	beq		r1,ambx_no_mbxs
	lw		r2,MBX_LINK[r1]		; and update the head of the list
	sw		r2,FreeMbxHandle
	dec		nMailbox		; decrement number of available mailboxes
	sw		r0,freembx_sema
	bsr     LockTCB
	mov		r3,tr           ; Add the mailbox to the list of mailboxes
	lw		r2,TCB_MbxList[tr]	; managed by the task.
	sw		r2,MBX_LINK[r1]
	sw		r1,TCB_MbxList[tr]
	mov     r2,r1
	lw		r1,TCB_hJCB[tr]
	sw		r0,tcb_sema

	bsr     LockMBX
	sw		tr,MBX_OWNER[r2]
	lda		#-1				
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
	sw		r0,mbx_sema
	pop		r4
	pop     r3
	pop     r2
	ldi		r1,#E_Ok
	rts
ambx_bad_ptr:
	ldi		r1,#E_Arg
	rtl
ambx_no_mbxs:
	sw		r0,freembx_sema
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
	bsr     LockMBX

	; Dequeue messages from mailbox and add them back to the free message list.
fmbx5:
	push    r1
	bsr		DequeueMsgFromMbx
	beq		r1,fmbx3
	bsr     LockFreeMSG
	push    r2
	lw		r2,FreeMsg
	sw		r2,MSG_LINK[r1]
	sw		r1,FreeMsg
	sw		r0,freemsg_sema
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
	bne		fmbx10
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
	bsr     LockFreeMBX
	lw		r2,FreeMbxHandle
	sw		r2,MBX_LINK[r1]
	sw		r1,FreeMbxHandle
	sw		r0,freembx_sema
fmbx2:
	sw		r0,mbx_sema
	pop     r4
	pop     r3
	pop     r2
	lda		#E_Ok
	rts
fmbx1:
	lda		#E_Arg
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

WaitMsg:
	cmp		r3,r1,#NR_MBX			; check the mailbox number to make sure
	bge		r3,wmsg1				; that it's sensible
	push    lr
	push	r4
	push	r5
	push	r6
	push	r7
	mov		r6,r1
wmsg11:
    lwar    r3,mbx_sema
    bne     r3,wmsg11
    swcr    tr,mbx_sema
    mfspr   r3,cr0
    and     r3,r3,#$1000000000
    beq     r3,wmsg11

	lw		r5,MBX_OWNER[r1]
	cmp		r3,r5,#MAX_TASKNO
	bgt		r3,wmsg2				; error: no owner
	bsr		DequeueMsgFromMbx
	bne		r1,wmsg3

	; Here there was no message available, remove the task from
	; the ready list, and optionally add it to the timeout list.
	; Queue the task at the mailbox.
wmsg12:
    lwar    r1,tcb_sema
    bne     r1,wmsg12
    swcr    tr,tcb_sema
    mfspr   r1,cr0
    and     r1,r1,#$1000000000
    beq     r1,wmsg12
	lw		r1,RunningTCB				; remove the task from the ready list
	bsr		RemoveTaskFromReadyList
	sw		r0,tcb_sema
wmsg13:
	lwar    r7,tcb_sema
	bne     r7,wmsg13
	swcr    tr,tcb_sema
	mfspr   r7,cr0
	and     r7,r7,#$1000000000
	beq     r7,wmsg13
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
	sw		r0,tcb_sema
	sw		r0,mbx_sema
	beq		r2,wmsg10                   ; check for a timeout
wmsg14:
    lwar    r7,tcb_sema
    bne     r7,wmsg14
    swcr    tr,tcb_sema
    mfspr   r7,cr0
    and     r7,r7,#$1000000000
    beq     r7,wmsg14
	bsr		AddToTimeoutList
	sw		r0,tcb_sema
;	hwi		#2	;	GoReschedule			; invoke the scheduler
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
	sw		r0,mbx_sema
	lw		r2,MSG_D1[r1]
	lw		r3,MSG_D2[r1]
	; Add the newly dequeued message to the free messsage list
wmsg5:
	lwar    r6,freemsg_sema
	bne     r6,wmsg5
	swcr    tr,freemsg_sema
	mfspr   r6,cr0
	and     r6,r6,#$1000000000
	beq     r6,wmsg5
	lw		r7,FreeMsg
	sw		r7,MSG_LINK[r1]
	sw		r1,FreeMsg
	inc		nMsgBlk
	sw		r0,freemsg_sema
wmsg8:
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ldi		r1,#E_Ok
	rts
wmsg1:
	ldi		r1,#E_BadMbx
	rtl
wmsg2:
	sw		r0,mbx_sema
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

CheckMsg:
    push    lr
    push    r6
	cmp		r3,r1,#NR_MBX			; check the mailbox number to make sure
	bge		r3,cmsg1				; that it's sensible
	push	r4
	push	r5

.0001:
    lwar    r3,mbx_sema
    bne     r3,.0001
    swcr    tr,mbx_sema
    mfspr   r3,cr0
    and     r3,r3,#$1000000000
    beq     r3,.0001

	lw		r5,MBX_OWNER[r1]
	beq		r5,cmsg2				; error: no owner
	cmp		#0						; are we to dequeue the message ?
	php
	beq		r2,cmsg3
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
    lwar    r6,freemsg_sema
    bne     r6,cmsg10
    swcr    tr,freemsg_sema
    mfspr   r6,cr0
    and     r6,r6,#$1000000000
    beq     r6,cmsg10

	lw		r5,FreeMsg
	sw		r5,MSG_LINK[r1]
	sw		r1,FreeMsg
	inc		nMsgBlk
	sw		r0,freemsg_sema
cmsg8:
	sw		r0,mbx_sema
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
	sw		r0,mbx_sema            ; unlock semaphore
	pop		r5
	pop		r4
	pop     r6
	ldi		r1,#E_NotAlloc
	rts
cmsg5:
	sw		r0,mbx_sema            ; unlock semaphore
	pop		r5
	pop		r4
	pop     r6
	ldi		r1,#E_NoMsg
	rts

