PIC_ES          equ		$FFDC0F10
FMTK_SCHEDULE	equ		66
FMTK_SYSCALL	equ		70
KBD_IRQ			equ		157
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
		ldi		r1,#$20000		// sequence number reset bit
		csrrs	r0,#0,r1		// pulse sn reset bit
		// Need at least 8 linear instructions after sn reset
		lh		r1,_milliseconds
		add		r1,r1,#1
		sh		r1,_milliseconds
		lh		r1,$FFD0013C	// Update screen indicator
		add		r1,r1,#1
		sh		r1,$FFD0013C
        ld		r1,#31			// reset the edge sense circuit
        sh		r1,PIC_ESR
        add		r0,r0,#0
        add		r0,r0,#0
.ts2:
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

