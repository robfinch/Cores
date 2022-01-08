	.text
	.global	start
start:
	lds		#0x10000
	ldaa	#0xAA
	staa	0xE60000
	jmp		start
	jmp		main



