/*
	This kind of code is normally emmitted by the compiler, and hidden.
*/

naked crt_start()
{
	asm {
		.bss
		.org	$300000
		.data
		.org	$250000
		.code
		.org	$23E200
		db		"BOOT"
		fill.b	252,0
		jmp		main
	}
}

