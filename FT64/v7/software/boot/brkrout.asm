PIC					equ		$FFFFFFFFFFDC0F00
PIC_ES      equ		$FFFFFFFFFFDC0F10
PIC_ESR			equ		$FFFFFFFFFFDC0F14
FLT_SSM			equ		32
FLT_ALN			equ		48
FLT_CMT			equ		54
FMTK_SCHEDULE	equ		66
FMTK_SYSCALL	equ		70
KBD_IRQ			equ		156
GCS_IRQ			equ		157
GC_IRQ			equ		158
TS_IRQ			equ		159
FLT_CS			equ		239
FLT_RET			equ		238
		data
_brk_stack	fill.w	512,0
_brk_stack_top:

		code	18
__BrkHandlerOL01:
__BrkHandlerOL02:
__BrkHandlerOL03:
__BrkHandler:
		sync
		and		r0,r0,#0						; load r0 with 0
		ldi		$r22,#$FF0000300030	; set ASID, OL, DL to zero
		csrrc	$r22,#$044,$r22
		csrwr	$r0,#$0BF,$r22			; save previous in a code buffer
		csrrd	r22,#6,r0						; Get cause code
		ldi		$sp,#_brk_stack_top
;		call	_DBGHomeCursor
;		push	$r22
;		call	_DispByte
		and		r22,r22,#$FF
		xor		r1,r22,#TS_IRQ
		beq		r1,r0,.ts
		xor		r1,r22,#GC_IRQ
		beq		r1,r0,.lvl6
		xor		r1,r22,#KBD_IRQ
		beq		r1,r0,.kbd
		xor		r1,r22,#FLT_CS
		beq		r1,r0,.ldcsFlt
		xor		r1,r22,#FLT_RET
		beq		r1,r0,.retFlt
		xor		r1,r22,#240				; OS system call
		beq		r1,r0,.callOS
		beq		r22,#FLT_CMT,.cmt
		beq		r22,#FMTK_SYSCALL,.lvl6
		beq		r22,#FMTK_SCHEDULE,.ts2
		beq		r22,#FLT_SSM,ssm_irq
;		beq		r22,#FLT_ALN,aln_irq
		jmp		_return_from_interrupt
.lvl6:
		// Redirect to level #6
;		rex		r0,6,6,1
		; Commit failed to occur
		; go back and re-execute the instruction
.cmt:
		jmp		_return_from_interrupt
.kbd:
;		rex		r0,6,6,2
		jmp		_return_from_interrupt
.ts:
		ldi		$r1,#31						; interrupt to reset
		sh		$r1,PIC+$14				; reset edge sense circuit register
		lw		$r1,_milliseconds
		add		$r1,$r1,#1
		sw		$r1,_milliseconds
		shl		$r2,$r1,#16
		and		$r1,$r1,#$FFFF
		or		$r1,$r1,$r2
		sw		$r1,$FFFFFFFFFFD00178	; screen display
		jmp		_return_from_interrupt
.ts2:
		jmp		_FMTK_SchedulerIRQ
.callOS:
		ldi		sp,#$FFFFFFFFFFD1C7F8
		call	_OSCall
		jmp		_return_from_interrupt

__BrkHandler6:
		csrrd	r1,#6,r0		// get cause code
		beq		r1,#KBD_IRQ,.kbd
		beq		r1,#FMTK_SYSCALL,.sc
		beq		r1,#GC_IRQ,.gc
		jmp			_return_from_interrupt
.gc:
    ld		r1,#30			// reset the edge sense circuit
    sh		r1,PIC_ESR
    rti
		call	__GarbageCollector
		jmp		_return_from_interrupt
.sc:	jmp		_FMTK_SystemCall
.kbd:	
    ld		r1,#29			// reset the edge sense circuit
    sh		r1,PIC_ESR
		jmp		_return_from_interrupt
		jmp		_KeybdIRQ

; Processing for a CS load exception in order to perform far jump or call.
;
.ldcsFLT:
		csrrd		r1,#$0DF,r0		; get CS
		mov			sp,sp:x
		push		r1
		csrrd		r1,#$048,r0		; get EPC
		csrrd		r2,#$00B,r0		; get exceptioned instruction
		shr			r2,r2,#8			; r2 = 24 bit selector value
		shl			r2,r2,#10			; shift by size of TCB
		push		r2						; save for later reference
		; lookup the handle in the TCB table
		; and check privileges as desired
		;
		; Fetch the next instruction from the instruction stream
		; it should be a jump or call instruction
		lcu			r2,4[r1]		; instruction could be up to 3 parcels (48 bits)
		lcu			r3,6[r1]		; must fetch 16 bits at a time due to alignment
		shl			r3,r3,#16
		lcu			r4,8[r1]		; get bits 32 to 47
		shl			r4,r4,#32		; shift into pos
		or			r2,r2,r3		; build instruction in r2
		or			r2,r2,r4		; r2 = next instruction
		shr			r3,r2,#5		; extract the instruction length
		and			r3,r3,#2		; just need bit 6
		add			r3,r3,#4		; if it was zero, makes 4 otherwise 6
		add			r3,r3,#4		; add length of CS prefix instruction (should be 4)
		add			r3,r3,r1		; now add address of exceptioned instruction
		; now the return address is computed (keep selector from r1)
		mov			r29:x,r3		; move to link register
		shl			r3,r2,#57		; move length to bit 63
		asr			r3,r3,#16		; generate mask
		shr			r3,r3,#16		; put into bits 47 to 32
		or			r3,r3,#$FFFFFFFF	; keep bits 31 to 0
		and			r3,r3,r2		; truncate instruction
		; now the proper instruction is in r3
		; it is JMP $xxxxxx or CALL
		shr			r3,r3,#8		; compute address
		lw			r2,[sp]			; get back selector << 10
		add			sp,sp,#8
		shl			r2,r2,#30		; r2 = selector << 40
		or			r3,r3,r2		; r3 = address + selector
		csrrw		r0,#$048,r3	; put target address into EPC
		jmp			_return_from_interrupt

.retFlt:
		csrrd		r1,#$048,r0	; get EPC (exceptioned pc)
		; get the ret instruction from the instruction stream
		csrrd		r3,#$00B,r0		; get r3 = exceptioned instruction
		; Get the target selector
		mov			r2,r29:x		; get link register
		shr			r2,r2,#40		; extract selector value
		; now lookup the handle in the descriptor table
		; and check privileges as desired
		; then set the current handle
		;
		; now the ret instruction must be emulated
		; compute stack pointer increment
		shr			r2,r3,#20		; shift offset down
		and			r2,r2,#$FF8	; mask off 3 lsb
		mov			r3,r31:x		; get stack pointer
		add			r3,r3,r2		; add offset to stack pointer
		mov			r31:x,r3		; save it back
		mov			r1,r29:x		; get link register
		csrrw		r0,#$048,r1	; put return address in EPC
		jmp			_return_from_interrupt

ssm_irq:
		ldi			sp,#$FFFFFFFFFFD1C3F8	; debug stack
		ldi			r2,#_regfile
		mov			r1,r1:x
		sw			r1,8[r2]
		mov			r1,r2:x
		sw			r1,16[r2]
		mov			r1,r3:x
		sw			r1,24[r2]
		mov			r1,r4:x
		sw			r1,32[r2]
		mov			r1,r5:x
		sw			r1,40[r2]
		mov			r1,r6:x
		sw			r1,48[r2]
		mov			r1,r7:x
		sw			r1,56[r2]
		mov			r1,r8:x
		sw			r1,64[r2]
		mov			r1,r9:x
		sw			r1,72[r2]
		mov			r1,r10:x
		sw			r1,80[r2]
		mov			r1,r11:x
		sw			r1,88[r2]
		mov			r1,r12:x
		sw			r1,96[r2]
		mov			r1,r13:x
		sw			r1,104[r2]
		mov			r1,r14:x
		sw			r1,112[r2]
		mov			r1,r15:x
		sw			r1,120[r2]
		mov			r1,r16:x
		sw			r1,128[r2]
		mov			r1,r17:x
		sw			r1,136[r2]
		mov			r1,r18:x
		sw			r1,144[r2]
		mov			r1,r19:x
		sw			r1,152[r2]
		mov			r1,r20:x
		sw			r1,160[r2]
		mov			r1,r21:x
		sw			r1,168[r2]
		mov			r1,r22:x
		sw			r1,176[r2]
		mov			r1,r23:x
		sw			r1,184[r2]
		mov			r1,r24:x
		sw			r1,192[r2]
		mov			r1,r25:x
		sw			r1,200[r2]
		mov			r1,r26:x
		sw			r1,208[r2]
		mov			r1,r27:x
		sw			r1,216[r2]
		mov			r1,r28:x
		sw			r1,224[r2]
		mov			r1,r29:x
		sw			r1,232[r2]
		mov			r1,r30:x
		sw			r1,240[r2]
		mov			r1,r31:x
		sw			r1,248[r2]
		ldi			r1,#0
		csrrw		r1,#$01C,r1	; clear debug control reg
		push		r1
		csrrd		r1,#$048,r0	; get address
		push		r1
		call		_debugger
		add			sp,sp,#16
		ldi			r2,#_regfile
		lw			r1,8[r2]
		mov			r1:x,r1
		lw			r1,16[r2]
		mov			r2:x,r1
		lw			r1,24[r2]
		mov			r3:x,r1
		lw			r1,32[r2]
		mov			r4:x,r1
		lw			r1,40[r2]
		mov			r5:x,r1
		lw			r1,48[r2]
		mov			r6:x,r1
		lw			r1,56[r2]
		mov			r7:x,r1
		lw			r1,64[r2]
		mov			r8:x,r1
		lw			r1,72[r2]
		mov			r9:x,r1
		lw			r1,80[r2]
		mov			r10:x,r1
		lw			r1,88[r2]
		mov			r11:x,r1
		lw			r1,96[r2]
		mov			r12:x,r1
		lw			r1,104[r2]
		mov			r13:x,r1
		lw			r1,112[r2]
		mov			r14:x,r1
		lw			r1,120[r2]
		mov			r15:x,r1
		lw			r1,128[r2]
		mov			r16:x,r1
		lw			r1,136[r2]
		mov			r17:x,r1
		lw			r1,144[r2]
		mov			r18:x,r1
		lw			r1,152[r2]
		mov			r19:x,r1
		lw			r1,160[r2]
		mov			r20:x,r1
		lw			r1,168[r2]
		mov			r21:x,r1
		lw			r1,176[r2]
		mov			r22:x,r1
		lw			r1,184[r2]
		mov			r23:x,r1
		lw			r1,192[r2]
		mov			r24:x,r1
		lw			r1,200[r2]
		mov			r25:x,r1
		lw			r1,208[r2]
		mov			r26:x,r1
		lw			r1,216[r2]
		mov			r27:x,r1
		lw			r1,224[r2]
		mov			r28:x,r1
		lw			r1,232[r2]
		mov			r29:x,r1
		lw			r1,240[r2]
		mov			r30:x,r1
		lw			r1,248[r2]
		mov			r31:x,r1
_return_from_interrupt:
		csrrd		$r1,#$0BF,$r0	; restore machine status register (ASID, OL, DL)
		csrrw		$r0,#$044,$r1
		rti

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
