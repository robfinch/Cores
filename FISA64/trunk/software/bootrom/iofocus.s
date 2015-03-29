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
	bsr     LockIOF
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
    sw      r0,iof_sema
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
    push    lr
    push    r1
    push    r2
    push    r3
	push	r4
	push    r5
;	DisTmrKbd
	lw	    r2,TCB_hJCB[tr]
	mov     r1,r2
	subui   r1,r1,#JCB_Array
	divu    r1,r1,#JCB_Size
	lsr     r3,r1,#6           ; r3 = word index into IO focus table
	bsr     LockIOF
	lw      r4,IOFocusTbl[r3]  ; r4 = word from IO focus table
	and     r3,r1,#$3F         ; r3 = bit number in word
	lsr     r5,r1,r3           ; extract bit into r5
	and     r5,r5,#1           ; mask off extra bits
	bne     r5,riof1           ; is the job already in the IO focus list ?
	lw		r1,IOFocusNdx	   ; Is the focus list empty ?
	beq		r1,riof2
	lw		r3,JCB_iof_prev[r1]
	beq		r3,riof4
	sw		r2,JCB_iof_prev[r1]
	sw		r1,JCB_iof_next[r2]
	sw		r3,JCB_iof_prev[r2]
	sw		r2,JCB_iof_next[r3]
riof3:
    mov     r1,r2
	subui   r1,r1,#JCB_Array
	divu    r1,r1,#JCB_Size    ; r1 = index into JCB array
	lsr     r3,r1,#6           ; r3 = word index into IO focus table
	lw      r4,IOFocusTbl[r3]  ; r4 = word from IO focus table
	and     r2,r1,#$3F         ; r2 = bit number in word
	ldi     r5,#1              ; r5 = 1 bit to insert
	asl     r5,r5,r2           ; r5 shifted into place
	or      r5,r5,r4           ; insert bit
	sw      r5,IOFocusTbl[r3]  ; store word back to IO focus table
riof1:
;	EnTmrKbd4
    sw      r0,iof_sema
    pop     r5
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rtl

	; Here, the IO focus list was empty. So expand it.
	; Make sure pointers are NULL
riof2:
	sw		r2,IOFocusNdx
	sw		r0,JCB_iof_next[r2]
	sw		r0,JCB_iof_prev[r2]
	bra		riof3

	; Here there was only a single entry in the list.
	; Setup pointers appropriately.
riof4:
	sw		r1,JCB_iof_next[r2]
	sw		r1,JCB_iof_prev[r2]
	sw		r2,JCB_iof_next[r1]
	st		r2,JCB_iof_prev[r1]
	bra		riof3

;------------------------------------------------------------------------------
; Releasing the I/O focus causes the focus to switch if the running job
; had the I/O focus.
; ForceReleaseIOFocus forces the release of the IO focus for a job
; different than the one currently running.
;------------------------------------------------------------------------------

ForceReleaseIOFocus:
    push    lr
	push    r1
	push    r2
	push    r3
	push	r4
	push    r5
	mov     r1,r2
;	DisTmrKbd
	bra		rliof4  ; wedge into ReleaseIOFocus

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
message "ReleaseIOFocus"	
ReleaseIOFocus:
    push    lr
	push    r1
	push    r2
	push    r3
	push	r4
	push    r5
;	DisTmrKbd
	lw	    r2,TCB_hJCB[tr]
rliof4:
	mov     r1,r2
	subui   r1,r1,#JCB_Array
	divu    r1,r1,#JCB_Size
	lsr     r3,r1,#6           ; r3 = word index into IO focus table
	bsr     LockIOF
	lw      r4,IOFocusTbl[r3]  ; r4 = word from IO focus table
	and     r3,r1,#$3F         ; r3 = bit number in word
	lsr     r5,r1,r3           ; extract bit into r5
	and     r5,r5,#1           ; mask off extra bits
	beq		r5,rliof3          ; nothing to do (not in table)
	ror     r4,r4,r3
	and     r4,r4,#-2          ; mask off LSB
	rol     r4,r4,r3           ; back in position
	sw		r4,IOFocusTbl
	lw      r5,IOFocusNdx	; Does the running job have the I/O focus ?
	cmp		r5,r2,r5
	bne		r5,rliof1
	bsr		SwitchIOFocus	; If so, then switch the focus.
rliof1:
	lw		r1,JCB_iof_next[r2]	; get next and previous fields.
	beq		r1,rliof5			; Is list emptying ?
	lw		r3,JCB_iof_prev[r2]
	sw		r1,JCB_iof_next[r3]	; prev->next = current->next
	sw	    r3,JCB_iof_prev[r1]	; next->prev = current->prev
	bra		rliof2
rliof5:
	sw		r0,IOFocusNdx		; emptied.
rliof2:
	sw		r0,JCB_iof_next[r2]	; Update the next and prev fields to indicate
	sw		r0,JCB_iof_prev[r2]	; the job is no longer on the list.
rliof3:
;	EnTmrKbd
    sw      r0,iof_sema
    pop     r5
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
message "CopyVirtualScreenToScreen"
CopyVirtualScreenToScreen
    push    r1
    push    r2
    push    r3
	push	r4
	lw		r2,IOFocusNdx		; compute virtual screen location
	beq		r2,cvss3
	; copy screen chars
	ldi		r1,#4095			; number of words to copy-1
	lw		r2,JCB_pVirtVid[r2]
	ldi		r3,#TEXTSCR
.0001:
	lh      r4,[r2+r1*4]       ; from virtual
	sh      r4,[r3+r1*4]       ; to screen
	subui   r1,r1,#1
	bge     r1,.0001
cvss3:
	; reset the cursor position in the text controller
	lw		r3,IOFocusNdx
	lb		r2,JCB_CursorRow[r3]
	ldi		r1,(TEXTREG+TEXT_COLS)|$FFD00000
	mulu	r2,r2,r1
	lb      r4,JCB_CursorCol[r3]
	add		r2,r2,r4
	sc		r2,(TEXTREG+TEXT_CURPOS)|$FFD00000
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rtl
message "CopyScreenToVirtualScreen"
CopyScreenToVirtualScreen
    push    r1
    push    r2
    push    r3
	push	r4
	ldi		r1,#4095
	ldi		r2,#TEXTSCR
	lw		r3,IOFocusNdx
	beq		r3,csvs3
	lw		r3,JCB_pVirtVid[r3]
.0001:
	lh      r4,[r2+r1*4]
	sh      r4,[r3+r1*4]
	subui   r1,r1,#1
	bge     r1,.0001
csvs3:
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rtl

