FMTK_SCHEDULE	equ		66
FMTK_SYSCALL	equ		70
TS_IRQ			equ		131
GC_IRQ			equ		158
KBD_IRQ			equ		159

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
		lh		r1,_milliseconds
		add		r1,r1,#1
		sh		r1,_milliseconds
		ldi		r1,#$20000		// sequence number reset bit
		csrrs	r0,#0,r1		// pulse sn reset bit
		lh		r1,$FFD0013C	// Update screen indicator
		add		r1,r1,#1
		sh		r1,$FFD0013C
		add		r0,r0,#0		// now a ramp of instructions
		add		r0,r0,#0		// that don't depend on sequence
		add		r0,r0,#0		// number to operate properly
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
		call	__GarbageCollector
		rti
.sc:	jmp		_FMTK_SystemCall
.kbd:	jmp		_KeybdIRQ

