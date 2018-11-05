PIC					equ			$FFFFFFFFFFDC0F00
PIC_ES          equ		$FFFFFFFFFFDC0F10
FMTK_SCHEDULE	equ		66
FMTK_SYSCALL	equ		70
KBD_IRQ			equ		156
GCS_IRQ			equ		157
GC_IRQ			equ		158
TS_IRQ			equ		159

__BrkHandler:
		add		r0,r0,#0			// load r0 with 0
		csrrd	r22,#6,r0			// Get cause code
		beq		r22,#TS_IRQ,.ts
		beq		r22,#GC_IRQ,.lvl6
		beq		r22,#KBD_IRQ,.kbd
		beq		r22,#FMTK_SYSCALL,.lvl6
		beq		r22,#FMTK_SCHEDULE,.ts2
		rti						// Unknown interrupt
.lvl6:
		// Redirect to level #6
		rex		r0,6,6,1
		rti						// Redirect failed
.kbd:
		rex		r0,6,6,2
		rti
.ts:
		ldi		$r1,#31						; interrupt to reset
		sh		$r1,PIC+$14				; reset edge sense circuit register
		lw		$r1,_milliseconds
		add		$r1,$r1,#1
		sw		$r1,_milliseconds
		shl		$r2,$r1,#16
		and		$r1,$r1,#$FFFF
		or		$r1,$r1,$r2
		sw		$r1,$FFFFFFFFFFD0178
		rti
		
		jmp		_FMTK_SchedulerIRQ

__BrkHandler6:
		csrrd	r1,#6,r0		// get cause code
		beq		r1,#KBD_IRQ,.kbd
		beq		r1,#FMTK_SYSCALL,.sc
		beq		r1,#GC_IRQ,.gc
		rti
.gc:
        ld		r1,#30			// reset the edge sense circuit
        sh		r1,PIC_ESR
		call	__GarbageCollector
		rti
.sc:	jmp		_FMTK_SystemCall
.kbd:	
        ld		r1,#29			// reset the edge sense circuit
        sh		r1,PIC_ESR
		jmp		_KeybdIRQ

