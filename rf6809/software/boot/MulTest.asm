;------------------------------------------------------------------------------
; Multiplier timing test routine.
;
; Fills the block of memory from $10000 to $1FFFF with random multiply
; immediate instructions. At the end of the block there is an RTS.
; There should be 21845 multiplies. The start time is set to zero using VIA
; timer #3. Then the subroutine is run. The end time is then retrieved from
; the VIA timer and displayed.
; !! Need to find way to bypass cache load times.
;------------------------------------------------------------------------------

MulTest:
	ldd		#123456		; seed the random number generator
	ldx		#876543
	lbsr	mon_srand
	; Fill $10000 to $1FFFF with random values
	ldu		#$10000
multest1:
	ldd		#0
	lbsr	mon_rand
	std		,u++
	stx		,u++
	cmpu	#$20000
	blo		multest1
	; Now insert multiply immediate opcodes
	ldu		#$10000
	ldb		#$28F			; MULD #
multest2:
	stb		,u				; store opcode
	leau	3,u				; every third byte
	cmpu	#$20000
	blo		multest2
	ldb		#$039			; RTS
	stb		,u
	; Now time the multiplies
	sei							; mask off interrupts
	ldd		#0
	std		VIA+VIA_T3LL
	jsr		$10000
	ldd		VIA+VIA_T3CL
	cli							; re-enable interrupts
	exg		a,b
	lbsr	CRLF
	lbsr	DispWordAsHex
	lbsr	CRLF
	lbra	Monitor
