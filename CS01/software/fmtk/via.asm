;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Device command 
;
	align	8
ViaFuncTbl:
	dw		0							; no operation
	dw		0							; setup
	dw		0							; initialize
	dw		0							; status
	dw		0							; media check
	dw		0							; build BPB
	dw		0							; open
	dw		0							; close
	dw		0							; get char
	dw		0							; Peek char
	dw		0							; get char direct
	dw		0							; peek char direct
	dw		0							; input status
	dw		0							; Put char
	dw		0							; reserved
	dw		0							; set position
	dw		0							; read block
	dw		0							; write block
	dw		0							; verify block
	dw		0							; output status
	dw		0							; flush input
	dw		0							; flush output
	dw		ViaIRQ				; IRQ routine
	dw		0							; Is removable
	dw		0							; ioctrl read
	dw		0							; ioctrl write
	dw		0							; output until busy
	dw		0							; 27
	dw		0
	dw		0
	dw		0
	dw		0							; 31

;------------------------------------------------------------------------------
; ViaInit
;
; Initialize the versatile interface adapter.
;------------------------------------------------------------------------------

ViaInit:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	ldi		$a0,#15							; VIA device
	ldi		$a1,#ViaFuncTbl
	call	CopyDevFuncTbl
	; Initialize port A low order eight bits as output, the remaining bits as
	; input.
	ldi		$t1,VIA
	ldi		$t0,#$000000FF
	sw		$t0,VIA_DDRA[$t1]
	ldi		$t0,#1							; select timer 3 access
	sb		$t0,VIA_PCR+1[$t1]
	ldi		$t0,#$1F
	sb		$t0,VIA_ACR+1[$t1]		; set timer 3 mode, timer 1/2 = 64 bit
	ldi		$t0,#$0016E360			;	divider value for 33.333Hz (30 ms)
	sw		$t0,VIA_T1CL[$t1]
	sw		$x0,VIA_T1CH[$t1]		; trigger transfer to count registers
	ldi		$t0,#$180						; emable timer3 interrupts
	sw		$t0,VIA_IER[$t1]
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ret


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ViaIRQ:
	; Was it the VIA that caused the interrupt?
	lb		$t0,VIA+VIA_IFR
	bge		$t0,$x0,.0003			; no
	lw		$t0,VIA+VIA_T1CL	; yes, clear interrupt
	lw		$t0,milliseconds
	add		$t0,$t0,#30
	sw		$t0,milliseconds
	sw		$t0,switchflag
	call	FMTK_SchedulerIRQ
.0003:
	eret
