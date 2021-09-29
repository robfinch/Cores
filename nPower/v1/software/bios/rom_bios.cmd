ENTRY (_start)

MEMORY {
	BIOS_BSS : ORIGIN = 0xFFFC0000, LENGTH = 512
}

MEMORY {
	BIOS_DATA : ORIGIN = 0xFFFC0200, LENGTH = 63k
}

MEMORY {
	BIOS_CODE : ORIGIN = 0xFFFD0000, LENGTH = 128K
}

MEMORY {
	BIOS_RODATA : ORIGIN = 0xFFFF0000, LENGTH = 64K
}

PHDRS {
	bios_bss PT_LOAD AT (0xFFFC0000);
	bios_hdr PT_LOAD AT (0xFFFC0200);
	bios_code PT_LOAD AT (0xFFFD0000);
	bios_rodata PT_LOAD AT (0xFFFF0000);
}

SECTIONS {
	.bss: {
		. = 0xfffc0000
		_start_bss = .;
		*(.bss);
		. = ALIGN(4);
		_end_bss = .;
	} >BIOS_BSS
	.data: {
		. = 0xfffc0200;
		_start_data = .;
		*(.data);
		. = ALIGN(4);
		_end_data = .;
	} >BIOS_DATA
	.text: {
		. = 0xfffd0000;
		*(.text);
		. = ALIGN(4);
		_etext = .;
	} >BIOS_CODE
	.rodata: {
		. = 0xffff0000;
		_start_rodata = .;
		*(.rodata);
		. = ALIGN(4);
		_end_rodata = .;
	} >BIOS_RODATA
}
