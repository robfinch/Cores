; ============================================================================
; iofocus.s
;        __
;   \\__/ o\    (C) 2014, 2015  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;  
;
; This source file is free software: you can redistribute it and/or modify 
; it under the terms of the GNU Lesser General Public License as published 
; by the Free Software Foundation, either version 3 of the License, or     
; (at your option) any later version.                                      
;                                                                          
; This source file is distributed in the hope that it will be useful,      
; but WITHOUT ANY WARRANTY; without even the implied warranty of           
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
; GNU General Public License for more details.                             
;                                                                          
; You should have received a copy of the GNU General Public License        
; along with this program.  If not, see <http://www.gnu.org/licenses/>.    
;
; iofocus.s
; ============================================================================

LockIOF:
    push    lr
    push    r1
    ldi     r1,#iof_sema
    bsr     LockSema
    pop     r1
    rts
    
;------------------------------------------------------------------------------
; ForceIOFocus
;
; Force the IO focus to a specific job.
;------------------------------------------------------------------------------
;
ForceIOFocus:
    push    lr
	push    r1
    push    r2
    push    r3 
    bsr     LockIOF
	lw		r3,IOFocusNdx
	cmp		r2,r1,r3
	beq		r2,fif1
	mov     r2,r1
	bsr		CopyScreenToVirtualScreen
	lw		r1,JCB_pVirtVid[r3]
	sw		r1,JCB_pVidMem[r3]
	sw		r2,IOFocusNdx
	ldi		r1,#TEXTSCR
	sw		r1,JCB_pVidMem[r2]
	bsr		CopyVirtualScreenToScreen
fif1:
	sw		r0,iof_sema
	pop     r3
	pop     r2
	pop     r1
	rts
	
;------------------------------------------------------------------------------
; SwitchIOFocus
;
; Switches the IO focus to the next task requesting the I/O focus. This
; routine may be called when a task releases the I/O focus as well as when
; the user presses ALT-TAB on the keyboard.
; On Entry: the io focus semaphore is set already.
;------------------------------------------------------------------------------
;
SwitchIOFocus:
    push    lr
    push    r1
    push    r2
    push    r3

	; First check if it's even possible to switch the focus to another
	; task. The I/O focus list could be empty or there may be only a
	; single task in the list. In either case it's not possible to
	; switch.
	lw		r3,IOFocusNdx		; Get the job at the head of the list.
	beq	    r3,siof3			; Is the list empty ?
	lw		r2,JCB_iof_next[r3]	; Get the next job on the list.
	beq		r2,siof3			; Nothing to switch to

	; Copy the current task's screen to it's virtual screen buffer.
	bsr		CopyScreenToVirtualScreen
	lw		r1,JCB_pVirtVid[r3]
	sw		r1,JCB_pVidMem[r3]

	sw		r2,IOFocusNdx		; Make task the new head of list.
	ldi		r1,#TEXTSCR
	sw		r1,JCB_pVidMem[r2]

	; Copy the virtual screen of the task recieving the I/O focus to the
	; text screen.
	bsr		CopyVirtualScreenToScreen
siof3:
	pop     r3
	pop     r2
	pop     r1
	rts

;------------------------------------------------------------------------------
; The I/O focus list is an array indicating which jobs are requesting the
; I/O focus. The I/O focus is user controlled by pressing ALT-TAB on the
; keyboard.
;------------------------------------------------------------------------------

RequestIOFocus:
	pha
	phx
	phy
	push	r4
	DisTmrKbd
	ldx		RunningTCB	
	ldx.ub	TCB_hJCB,x
	cpx		#NR_JCB
	bhs		riof1
	txa
	bmt		IOFocusTbl		; is the job already in the IO focus list ?
	bne		riof1
	mul		r4,r2,#JCB_Size
	add		r4,r4,#JCBs
	lda		IOFocusNdx		; Is the focus list empty ?
	beq		riof2
	ldy		JCB_iof_prev,r1
	beq		riof4
	st		r4,JCB_iof_prev,r1
	sta		JCB_iof_next,r4
	sty		JCB_iof_prev,r4
	st		r4,JCB_iof_next,y
riof3:
	txa
	bms		IOFocusTbl
riof1:
	EnTmrKbd
	pop		r4
	ply
	plx
	pla
	rts

	; Here, the IO focus list was empty. So expand it.
	; Make sure pointers are NULL
riof2:
	st		r4,IOFocusNdx
	stz		JCB_iof_next,r4
	stz		JCB_iof_prev,r4
	bra		riof3

	; Here there was only a single entry in the list.
	; Setup pointers appropriately.
riof4:
	sta		JCB_iof_next,r4
	sta		JCB_iof_prev,r4
	st		r4,JCB_iof_next,r1
	st		r4,JCB_iof_prev,r1
	bra		riof3

;------------------------------------------------------------------------------
; Releasing the I/O focus causes the focus to switch if the running job
; had the I/O focus.
; ForceReleaseIOFocus forces the release of the IO focus for a job
; different than the one currently running.
;------------------------------------------------------------------------------

ForceReleaseIOFocus:
	pha
	phx
	phy
	push	r4
	tax
	DisTmrKbd
	jmp		rliof4
message "ReleaseIOFocus"	
public ReleaseIOFocus:
	pha
	phx
	phy
	push	r4
	DisTmrKbd
	ldx		RunningTCB	
	ldx.ub	TCB_hJCB,x
rliof4:
	cpx		#NR_JCB
	bhs		rliof3
;	phx	
	ldy		#1
	txa
	bmt		IOFocusTbl
	beq		rliof3
	bmc		IOFocusTbl
;	plx
	mul		r4,r2,#JCB_Size
	add		r4,r4,#JCBs
	cmp		r4,IOFocusNdx	; Does the running job have the I/O focus ?
	bne		rliof1
	jsr		SwitchIOFocus	; If so, then switch the focus.
rliof1:
	lda		JCB_iof_next,r4	; get next and previous fields.
	beq		rliof5			; Is list emptying ?
	ldy		JCB_iof_prev,r4
	sta		JCB_iof_next,y	; prev->next = current->next
	sty		JCB_iof_prev,r1	; next->prev = current->prev
	bra		rliof2
rliof5:
	stz		IOFocusNdx		; emptied.
rliof2:
	stz		JCB_iof_next,r4	; Update the next and prev fields to indicate
	stz		JCB_iof_prev,r4	; the job is no longer on the list.
rliof3:
	EnTmrKbd
	pop		r4
	ply
	plx
	pla
	rts

