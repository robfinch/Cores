ENTRY (_start)

MEMORY {
	TB_CODE : ORIGIN = 0x00010000, LENGTH = 16k
}

MEMORY {
	TB_BSS : ORIGIN = 0x00014000, LENGTH = 32k
}

PHDRS {
	tb_code PT_LOAD AT (0x00010000);
	tb_bss PT_LOAD AT (0x00014000);
}

SECTIONS {
	code: {
		. = 0x00010000;
		*(code);
		. = ALIGN(2);
		_etext = .;
	} >TB_CODE
	bss: {
		. = 0x00014000
		_start_bss = .;
		*(bss);
		. = ALIGN(2);
		_end_bss = .;
	} >TB_BSS
}
