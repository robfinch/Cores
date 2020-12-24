ENTRY (_start)

MEMORY {
	BIOS_ROM : ORIGIN = 0xFFFC0000, LENGTH = 256K
}

MEMORY {
	BIOS_DATA : ORIGIN = 0xFF400000, LENGTH = 64K
}

SECTIONS {
	.text: {
		. = ALIGN(4);
		*(.text);
		. = ALIGN(4);
		_etext = .;
	} >BIOS_ROM
	.rodata: {
		. = (_etext + 0x1000) & 0xFFFFF000;
		. = ALIGN(4);
		_start_rodata = .;
		*(.rodata);
		. = ALIGN(4);
		_end_rodata = .;
	} >BIOS_ROM
	.data: AT (0xFF400000) {
		. = (_end_rodata + 0x1000) & 0xFFFFF000;
		. = ALIGN(4);
		_start_data = .;
		*(.data);
		. = ALIGN(4);
		_end_data = .;
	} >BIOS_ROM
}
