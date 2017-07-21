	code
	align	16
_RTGetButtonSTKSIZE_ EQU 0

_TwoSpaces:
	      	push 	xlr
	      	ldi  	xlr,#ramtest_2
	      	link 	#-_TwoSpacesSTKSIZE_-8
; 	putch(' ');
	      	push 	r18
	      	ldi  	r18,#32
	      	call 	_putch
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
ramtest_5:
	      	unlink
	      	pop  	xlr
	      	ret  	#8
ramtest_2:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_5
_TwoSpacesSTKSIZE_ EQU 0

_puthex:
	      	push 	xlr
	      	link 	#-_puthexSTKSIZE_-8
; 	asm {
	      	     	
			mov		r1,r18
			call	_DisplayTetra
ramtest_9:
	      	unlink
	      	pop  	xlr
	      	ret  	#8
_puthexSTKSIZE_ EQU 0

_dumpaddr:
	      	push 	xlr
	      	ldi  	xlr,#ramtest_10
	      	link 	#-_dumpaddrSTKSIZE_-8
; 	TwoSpaces();
	      	call 	_TwoSpaces
; 	puthex((int)p);
	      	push 	r18
	      	call 	_puthex
; 	putch(' ');
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
; 	puthex(p[0]);
	      	push 	r18
	      	lw   	r3,[r18]
	      	mov  	r18,r3
	      	call 	_puthex
; 	putch('\r');
	      	ldi  	r18,#13
	      	call 	_putch
; 	putch('\n');
	      	ldi  	r18,#10
	      	call 	_putch
	      	pop  	r18
ramtest_13:
	      	unlink
	      	pop  	xlr
	      	ret  	#8
ramtest_10:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_13
_dumpaddrSTKSIZE_ EQU 0

_SetMem:
	      	push 	xlr
	      	ldi  	xlr,#ramtest_15
	      	link 	#-_SetMemSTKSIZE_-8
; 	for (p = (__int32 *)0x10000; p < (__int32 *)0x20000000; p+=2) {
	      	ldi  	r3,#65536
	      	mov  	r11,r3
ramtest_18:
	      	cmp  	r3,r11,#536870912
	      	bge  	r3,r0,ramtest_19
; 		if ((p & 0xFFF)==0) {
	      	and  	r3,r11,#4095
	      	cmp  	r4,r3,#0
	      	bne  	r4,r0,ramtest_21
; 			TwoSpaces();
	      	call 	_TwoSpaces
; 			puthex((int)p>>12);
	      	push 	r18
	      	asr.w	r3,r11,#12
	      	mov  	r18,r3
	      	call 	_puthex
; 			putch('\r');
	      	ldi  	r18,#13
	      	call 	_putch
	      	pop  	r18
; 	asm {
	      	     	
			lcu		r1,BUTTONS
ramtest_28:
ramtest_25:
ramtest_27:
	      	cmp  	r3,r1,#4
	      	bne  	r3,r0,ramtest_23
ramtest_29:
	      	pop  	r11
	      	unlink
	      	pop  	xlr
	      	ret  	#8
ramtest_23:
ramtest_21:
; 		p[0] = (__int32)n1;
	      	sh   	r18,[r11]
; 		p[1] = (__int32)n2;
	      	sh   	r19,4[r11]
ramtest_20:
	      	add  	r11,r11,#8
	      	bra  	ramtest_18
ramtest_19:
	      	bra  	ramtest_29
ramtest_15:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_29
_SetMemSTKSIZE_ EQU 8

_CheckMem:
	      	push 	xlr
	      	ldi  	xlr,#ramtest_31
	      	link 	#-_CheckMemSTKSIZE_-8
; 	__int32 *p;
	      	sw   	r0,-16[bp]
; 	for (p = (__int32 *)0x10000; p < (__int32 *)0x20000000; p+=2) {
	      	ldi  	r3,#65536
	      	mov  	r11,r3
ramtest_34:
	      	cmp  	r3,r11,#536870912
	      	bge  	r3,r0,ramtest_35
; 		if ((p & 0xFFF)==0) {
	      	and  	r3,r11,#4095
	      	cmp  	r4,r3,#0
	      	bne  	r4,r0,ramtest_37
; 			TwoSpaces();
	      	call 	_TwoSpaces
; 			puthex((int)p>>12);
	      	push 	r18
	      	asr.w	r3,r11,#12
	      	mov  	r18,r3
	      	call 	_puthex
; 			putch('\r');
	      	ldi  	r18,#13
	      	call 	_putch
	      	pop  	r18
; 	asm {
	      	     	
			lcu		r1,BUTTONS
ramtest_44:
ramtest_41:
ramtest_43:
	      	cmp  	r3,r1,#4
	      	bne  	r3,r0,ramtest_39
ramtest_45:
	      	pop  	r11
	      	unlink
	      	pop  	xlr
	      	ret  	#8
ramtest_39:
ramtest_37:
; 		if (p[0] != (__int32)n1) {
	      	lh   	r3,[r11]
	      	beq  	r3,r18,ramtest_46
; 			badcount++;
	      	lw   	r3,-16[bp]
	      	add  	r3,r3,#1
	      	sw   	r3,-16[bp]
; 			dumpaddr(p);
	      	push 	r18
	      	mov  	r18,r11
	      	call 	_dumpaddr
	      	pop  	r18
ramtest_46:
; 		if (p[1] != (__int32)n2) {
	      	lh   	r3,4[r11]
	      	beq  	r3,r19,ramtest_48
; 			badcount++;
	      	lw   	r3,-16[bp]
	      	add  	r3,r3,#1
	      	sw   	r3,-16[bp]
; 			dumpaddr(p);
	      	push 	r18
	      	mov  	r18,r11
	      	call 	_dumpaddr
	      	pop  	r18
ramtest_48:
; 		if (badcount > 10)
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#10
	      	bge  	r0,r4,ramtest_50
; 			break;
	      	bra  	ramtest_35
ramtest_50:
ramtest_36:
	      	add  	r11,r11,#8
	      	bra  	ramtest_34
ramtest_35:
; 	putch('\r');
	      	push 	r18
	      	ldi  	r18,#13
	      	call 	_putch
; 	putch('\n');
	      	ldi  	r18,#10
	      	call 	_putch
	      	pop  	r18
	      	bra  	ramtest_45
ramtest_31:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_45
_CheckMemSTKSIZE_ EQU 16

public code _ramtest:
	      	push 	xlr
	      	ldi  	xlr,#ramtest_53
	      	link 	#-_ramtestSTKSIZE_-8
; 	DBGDisplayString("  RAM Test\r\n");
	      	push 	r18
	      	ldi  	r18,#ramtest_52
	      	call 	_DBGDisplayString
	      	pop  	r18
; 	SetMem(0xAAAAAAAA,0x55555555);
	      	push 	r18
	      	push 	r19
	      	ldi  	r19,#1431655765
	      	ldi  	r18,#-1431655766
	      	call 	_SetMem
	      	pop  	r19
	      	pop  	r18
; 	CheckMem(0xAAAAAAAA,0x55555555);
	      	push 	r18
	      	push 	r19
	      	ldi  	r19,#1431655765
	      	ldi  	r18,#-1431655766
	      	call 	_CheckMem
	      	pop  	r19
; 	putch('\r');
	      	ldi  	r18,#13
	      	call 	_putch
; 	putch('\n');
	      	ldi  	r18,#10
	      	call 	_putch
	      	pop  	r18
; 	SetMem(0x55555555,0xAAAAAAAA);
	      	push 	r18
	      	push 	r19
	      	ldi  	r19,#-1431655766
	      	ldi  	r18,#1431655765
	      	call 	_SetMem
	      	pop  	r19
	      	pop  	r18
; 	CheckMem(0x55555555,0xAAAAAAAA);
	      	push 	r18
	      	push 	r19
	      	ldi  	r19,#-1431655766
	      	ldi  	r18,#1431655765
	      	call 	_CheckMem
	      	pop  	r19
	      	pop  	r18
ramtest_56:
	      	unlink
	      	pop  	xlr
	      	ret  	#8
ramtest_53:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ramtest_56
endpublic



_ramtestSTKSIZE_ EQU 8

	rodata
	align	16
	align	8
	align	1
ramtest_52:	;   RAM Test
	dc	32,32,82,65,77,32,84,101
	dc	115,116,13,10,0
	extern	_DBGHideCursor
	extern	_puthexnum
;	global	_ramtest
	extern	_DBGDisplayString
	extern	_putch
	extern	_dumpaddr
	extern	_puthex
