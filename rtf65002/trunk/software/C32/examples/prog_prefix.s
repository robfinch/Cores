	code
	align	16
public crt_start:
	     			cpu		RTF65002
		.bss						; allow room for 1MB of code
		.org	0x1900000>>2		; convert to data address
		.code
		.org	0x1800000			; allow room for command line
		db		"BOOT"
		.org	0x1800100
		lda		#2					; normal prioity
		ldx		#0					; flags
		ldy		#main				; start address
		ld		r4,#0x1800000			; start parameter
		ld		r5,#2				; job to associate with
		int		#4					; start as a task
		db		1
		jmp		(0xFFFF8040>>2)	; jump back to Monitor
	
L_1:
L_0:
	align	8
;	global	crt_start
