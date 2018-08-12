; 000000 +---------+
;        | 1 page  | JCB vars
; 002000 +---------+
;        | 4 pages | JCB video buffer
; 00A000 +---------+

			.bss
			org		$1F800000
_tcbs		
			org		$1FB00000
_stacks
			org		$1FD00000
_sys_stacks
			org		$1FE00000
_bios_stacks	
; Message area 16384x32 byte messages
			org		$1FF00000
_message
			org		$1FF80000
; Mailbox area 1024 * 64 byte mailboxes
			org		$1FFC0000
_mailbox	fill.w	8192,0
			org		$1FFD7800
_keybd_irq_stack
			org		$1FFD8000
_fmtk_sys_stack
			org		$1FFD9000
_fmtk_irq_stack
			org		$1FFDA000
_sysstack	fill.w	1024,0
			org		$1FFDD000
_ACBPtrs		fill.w	64,0
_FMTK_inited	dw		0
_missed_ticks	dw		0
_IOFocusNdx		dw		0
_IOFocusTbl		fill.w	4,0
_iof_switch		dw		0
_nMsgBlk		dw		0
_nMailbox		dw		0
_FreeACB		dc		0
_freeTCB		dc		0
_FreeMSG		dc		0
_FreeMBX		dc		0
_TimeoutList	dc		0
_hKeybdMbx		dc		-1
_hFocusSwitchMbx	dc		-1
_BIOS_RespMbx	dc		0
_hasUltraHighPriorityTasks	db		0
			align	8
_im_save		dw		0
_sp_tmp			dw		0
_readyQ			fill.c	8,0
_syspages					dw	0
_sys_pages_available		dw	0
_sys_512k_pages_available	dw	0
_mmu_FreeMaps	dw		0
_mmu_entries	dh		0
_freelist		dc		0
_hSearchMap		db		0

_gc_state		dw		0
_gc_stack		fill.w	256,0
_gc_regs		fill.w	32,0
_gc_pc			dw		0
_gc_omapno		dw		0
_gc_mapno		dw		0
_gc_ol			dw		0

; 512kB page allocation map (bit for each 8k page)
			org		$1FFDE000
_pam512:	fill.w	1024,0
; page allocation map (links like a DOS FAT)
			org		$1FFE0000
_pam8:		fill.c	65519,0
			org		$FF407000
_brk_stack	fill.w	512,0			

;extern TCB tcbs[NR_TCB];
