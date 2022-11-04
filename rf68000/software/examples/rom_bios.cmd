ENTRY (_start)

MEMORY {
	BIOS_DATA : ORIGIN = 0x00000000, LENGTH = 1k
}

MEMORY {
	BIOS_BSS : ORIGIN = 0x00000400, LENGTH = 1k
}

MEMORY {
	BIOS_CODE : ORIGIN = 0x00000800, LENGTH = 20k
}

MEMORY {
	BIOS_RODATA : ORIGIN = 0x00008000, LENGTH = 16K
}

PHDRS {
	bios_hdr PT_LOAD AT (0x00000000);
	bios_bss PT_LOAD AT (0x00000400);
	bios_code PT_LOAD AT (0x00000800);
	bios_rodata PT_LOAD AT (0x00008000);
}

SECTIONS {
	data: {
		. = 0x00000000;
		_start_data = .;
		*(data);
		. = ALIGN(2);
		_end_data = .;
	} >BIOS_DATA
	bss: {
		. = 0x00000400
		_start_bss = .;
		*(bss);
		. = ALIGN(2);
		_end_bss = .;
	} >BIOS_BSS
	code: {
		. = 0x00000800;
		*(code);
		. = ALIGN(2);
		_etext = .;
	} >BIOS_CODE
	rodata: {
		. = 0x00008000;
		_start_rodata = .;
		*(rodata);
		. = ALIGN(2);
		_end_rodata = .;
	} >BIOS_RODATA
}
