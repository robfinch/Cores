	code
	align	16
_GetButtonSTKSIZE_ EQU 0

public code _BIOSMain:
	      	push 	xlr
	      	ldi  	xlr,#BIOSMain_4
	      	link 	#-_BIOSMainSTKSIZE_-8
; 	float pi = 3.1415926535897932384626;
	      	lw   	r3,BIOSMain_1
	      	sw   	r3,-8[bp]
	      	sw   	r0,-40[bp]
; 	DBGAttr = 0x087FC00;//0b0000_1000_0111_1111_1100_0000_0000;
	      	ldi  	r3,#8911872
	      	sh   	r3,_DBGAttr
; 	DBGClearScreen();
	      	call 	_DBGClearScreen
; 	DBGHomeCursor();
	      	call 	_DBGHomeCursor
; 	DBGDisplayString("  FT64 Bios Started\r\n");
	      	push 	r18
	      	ldi  	r18,#BIOSMain_2
	      	call 	_DBGDisplayString
; 	DBGDisplayString("  Menu\r\n  up = ramtest\r\n  left = float test\r\n  right=TinyBasic\r\n");
	      	ldi  	r18,#BIOSMain_3
	      	call 	_DBGDisplayString
	      	pop  	r18
BIOSMain_7:
; 	asm {
	      	     	
			lb		r1,BUTTONS
BIOSMain_12:
BIOSMain_9:
BIOSMain_11:
	      	sw   	r1,-32[bp]
; 		switch(btn) {
	      	lw   	r3,-32[bp]
; 		case 8:
	      	bbs  	r3,#3,BIOSMain_18
; 		case 2:
	      	bbs  	r3,#1,BIOSMain_19
; 		case 1:
	      	bbs  	r3,#0,BIOSMain_20
	      	bra  	BIOSMain_13
BIOSMain_18:
BIOSMain_21:
; 	asm {
	      	     	
			lb		r1,BUTTONS
BIOSMain_26:
BIOSMain_23:
BIOSMain_25:
	      	beq  	r1,r0,BIOSMain_22
; 			while(GetButton());
	      	bra  	BIOSMain_21
BIOSMain_22:
; 			ramtest();
	      	call 	_ramtest
; 			break;
	      	bra  	BIOSMain_13
BIOSMain_19:
BIOSMain_27:
; 	asm {
	      	     	
			lb		r1,BUTTONS
BIOSMain_32:
BIOSMain_29:
BIOSMain_31:
	      	beq  	r1,r0,BIOSMain_28
; 			while(GetButton());
	      	bra  	BIOSMain_27
BIOSMain_28:
; 			FloatTest();
	      	call 	_FloatTest
; 			break;
	      	bra  	BIOSMain_13
BIOSMain_20:
BIOSMain_33:
; 	asm {
	      	     	
			lb		r1,BUTTONS
BIOSMain_38:
BIOSMain_35:
BIOSMain_37:
	      	beq  	r1,r0,BIOSMain_34
; 			while(GetButton());
	      	bra  	BIOSMain_33
BIOSMain_34:
; 			asm {
	      	     	
			jmp	TinyBasicDSD9
BIOSMain_13:
	      	bra  	BIOSMain_7
BIOSMain_8:
BIOSMain_39:
	      	unlink
	      	pop  	xlr
	      	ret  	#8
BIOSMain_4:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	BIOSMain_39
endpublic



_BIOSMainSTKSIZE_ EQU 40

_GetEPCSTKSIZE_ EQU 0

_GetBadAddrSTKSIZE_ EQU 0

_SetPCHNDXSTKSIZE_ EQU 0

_ReadPCHISTSTKSIZE_ EQU 0

public code _BTNCIRQHandler:
	      	push 	bp
	      	push 	lr
	      	push 	xlr
	      	push 	gp
	      	push 	r26
	      	push 	r25
	      	push 	r24
	      	push 	r23
	      	push 	r22
	      	push 	r21
	      	push 	r20
	      	push 	r19
	      	push 	r18
	      	push 	r17
	      	push 	r16
	      	push 	r15
	      	push 	r14
	      	push 	r13
	      	push 	r12
	      	push 	r11
	      	push 	r10
	      	push 	r9
	      	push 	r8
	      	push 	r7
	      	push 	r6
	      	push 	r5
	      	push 	r4
	      	push 	r3
	      	push 	r2
	      	push 	r1
	      	push 	xlr
	      	ldi  	xlr,#BIOSMain_45
	      	link 	#-_BTNCIRQHandlerSTKSIZE_-8
; 	asm {
	      	     	
			ldi		r1,#30
			sh		r1,PIC_ESR
; 	DBGDisplayString("\r\nPC History:\r\n");
	      	push 	r18
	      	ldi  	r18,#BIOSMain_44
	      	call 	_DBGDisplayString
	      	pop  	r18
; 	for (nn = 63; nn >= 0; nn--) {
	      	ldi  	r3,#63
	      	sw   	r3,-8[bp]
BIOSMain_48:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	blt  	r4,r0,BIOSMain_49
; 		SetPCHNDX(nn);
	      	push 	r18
	      	lw   	r3,-8[bp]
	      	mov  	r18,r3
; 	asm {
	      	     	
			csrrw	r0,#$101,r18
BIOSMain_54:
BIOSMain_51:
BIOSMain_53:
	      	pop  	r18
; 		puthex(ReadPCHIST());
	      	push 	r18
; 	asm {
	      	     	
			csrrd	r1,#$100,r0
BIOSMain_58:
BIOSMain_55:
BIOSMain_57:
	      	hint 	#1
	      	mov  	r18,r1
	      	call 	_puthex
; 		putch(' ');
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
BIOSMain_50:
	      	lw   	r3,-8[bp]
	      	sub  	r3,r3,#1
	      	sw   	r3,-8[bp]
	      	bra  	BIOSMain_48
BIOSMain_49:
BIOSMain_59:
	      	unlink
	      	pop  	xlr
	      	pop  	r1
	      	pop  	r2
	      	pop  	r3
	      	pop  	r4
	      	pop  	r5
	      	pop  	r6
	      	pop  	r7
	      	pop  	r8
	      	pop  	r9
	      	pop  	r10
	      	pop  	r11
	      	pop  	r12
	      	pop  	r13
	      	pop  	r14
	      	pop  	r15
	      	pop  	r16
	      	pop  	r17
	      	pop  	r18
	      	pop  	r19
	      	pop  	r20
	      	pop  	r21
	      	pop  	r22
	      	pop  	r23
	      	pop  	r24
	      	pop  	r25
	      	pop  	r26
	      	pop  	gp
	      	pop  	xlr
	      	pop  	lr
	      	pop  	bp
	      	iret 
BIOSMain_45:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	BIOSMain_59
endpublic



_BTNCIRQHandlerSTKSIZE_ EQU 8

public code _DBERout:
	      	push 	bp
	      	push 	lr
	      	push 	xlr
	      	push 	gp
	      	push 	r26
	      	push 	r25
	      	push 	r24
	      	push 	r23
	      	push 	r22
	      	push 	r21
	      	push 	r20
	      	push 	r19
	      	push 	r18
	      	push 	r17
	      	push 	r16
	      	push 	r15
	      	push 	r14
	      	push 	r13
	      	push 	r12
	      	push 	r11
	      	push 	r10
	      	push 	r9
	      	push 	r8
	      	push 	r7
	      	push 	r6
	      	push 	r5
	      	push 	r4
	      	push 	r3
	      	push 	r2
	      	push 	r1
	      	push 	xlr
	      	ldi  	xlr,#BIOSMain_61
	      	link 	#-_DBERoutSTKSIZE_-8
; 	DBGDisplayString("\r\nDatabus error: ");
	      	push 	r18
	      	ldi  	r18,#BIOSMain_60
	      	call 	_DBGDisplayString
	      	pop  	r18
; 	puthex(GetEPC());
	      	push 	r18
; 	asm {
	      	     	
			csrrd	r1,#$40,r0
BIOSMain_67:
BIOSMain_64:
BIOSMain_66:
	      	hint 	#1
	      	mov  	r18,r1
	      	call 	_puthex
; 	putch(' ');
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
; 	puthex(GetBadAddr());
	      	push 	r18
; 	asm {
	      	     	
			csrrd	r1,#7,r0
			sh		r1,$FFDC0080
BIOSMain_71:
BIOSMain_68:
BIOSMain_70:
	      	hint 	#1
	      	mov  	r18,r1
	      	call 	_puthex
; 	putch(' ');
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
; 	for (nn = 63; nn >= 0; nn--) {
	      	ldi  	r3,#63
	      	sw   	r3,-8[bp]
BIOSMain_72:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	blt  	r4,r0,BIOSMain_73
; 		SetPCHNDX(nn);
	      	push 	r18
	      	lw   	r3,-8[bp]
	      	mov  	r18,r3
; 	asm {
	      	     	
			csrrw	r0,#$101,r18
BIOSMain_78:
BIOSMain_75:
BIOSMain_77:
	      	pop  	r18
; 		puthex(ReadPCHIST());
	      	push 	r18
; 	asm {
	      	     	
			csrrd	r1,#$100,r0
BIOSMain_82:
BIOSMain_79:
BIOSMain_81:
	      	hint 	#1
	      	mov  	r18,r1
	      	call 	_puthex
; 		putch(' ');
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
BIOSMain_74:
	      	lw   	r3,-8[bp]
	      	sub  	r3,r3,#1
	      	sw   	r3,-8[bp]
	      	bra  	BIOSMain_72
BIOSMain_73:
BIOSMain_83:
	      	bra  	BIOSMain_83
BIOSMain_84:
BIOSMain_85:
	      	unlink
	      	pop  	xlr
	      	pop  	r1
	      	pop  	r2
	      	pop  	r3
	      	pop  	r4
	      	pop  	r5
	      	pop  	r6
	      	pop  	r7
	      	pop  	r8
	      	pop  	r9
	      	pop  	r10
	      	pop  	r11
	      	pop  	r12
	      	pop  	r13
	      	pop  	r14
	      	pop  	r15
	      	pop  	r16
	      	pop  	r17
	      	pop  	r18
	      	pop  	r19
	      	pop  	r20
	      	pop  	r21
	      	pop  	r22
	      	pop  	r23
	      	pop  	r24
	      	pop  	r25
	      	pop  	r26
	      	pop  	gp
	      	pop  	xlr
	      	pop  	lr
	      	pop  	bp
	      	iret 
BIOSMain_61:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	BIOSMain_85
endpublic



_DBERoutSTKSIZE_ EQU 8

public code _IBERout:
	      	push 	bp
	      	push 	lr
	      	push 	xlr
	      	push 	gp
	      	push 	r26
	      	push 	r25
	      	push 	r24
	      	push 	r23
	      	push 	r22
	      	push 	r21
	      	push 	r20
	      	push 	r19
	      	push 	r18
	      	push 	r17
	      	push 	r16
	      	push 	r15
	      	push 	r14
	      	push 	r13
	      	push 	r12
	      	push 	r11
	      	push 	r10
	      	push 	r9
	      	push 	r8
	      	push 	r7
	      	push 	r6
	      	push 	r5
	      	push 	r4
	      	push 	r3
	      	push 	r2
	      	push 	r1
	      	push 	xlr
	      	ldi  	xlr,#BIOSMain_88
	      	link 	#-_IBERoutSTKSIZE_-8
; 	DBGDisplayString("\r\nInstruction Bus Error:\r\n");
	      	push 	r18
	      	ldi  	r18,#BIOSMain_86
	      	call 	_DBGDisplayString
; 	DBGDisplayString("PC History:\r\n");
	      	ldi  	r18,#BIOSMain_87
	      	call 	_DBGDisplayString
	      	pop  	r18
; 	for (nn = 63; nn >= 0; nn--) {
	      	ldi  	r3,#63
	      	sw   	r3,-8[bp]
BIOSMain_91:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	blt  	r4,r0,BIOSMain_92
; 		SetPCHNDX(nn);
	      	push 	r18
	      	lw   	r3,-8[bp]
	      	mov  	r18,r3
; 	asm {
	      	     	
			csrrw	r0,#$101,r18
BIOSMain_97:
BIOSMain_94:
BIOSMain_96:
	      	pop  	r18
; 		puthex(ReadPCHIST());
	      	push 	r18
; 	asm {
	      	     	
			csrrd	r1,#$100,r0
BIOSMain_101:
BIOSMain_98:
BIOSMain_100:
	      	hint 	#1
	      	mov  	r18,r1
	      	call 	_puthex
; 		putch(' ');
	      	ldi  	r18,#32
	      	call 	_putch
	      	pop  	r18
BIOSMain_93:
	      	lw   	r3,-8[bp]
	      	sub  	r3,r3,#1
	      	sw   	r3,-8[bp]
	      	bra  	BIOSMain_91
BIOSMain_92:
BIOSMain_102:
	      	bra  	BIOSMain_102
BIOSMain_103:
BIOSMain_104:
	      	unlink
	      	pop  	xlr
	      	pop  	r1
	      	pop  	r2
	      	pop  	r3
	      	pop  	r4
	      	pop  	r5
	      	pop  	r6
	      	pop  	r7
	      	pop  	r8
	      	pop  	r9
	      	pop  	r10
	      	pop  	r11
	      	pop  	r12
	      	pop  	r13
	      	pop  	r14
	      	pop  	r15
	      	pop  	r16
	      	pop  	r17
	      	pop  	r18
	      	pop  	r19
	      	pop  	r20
	      	pop  	r21
	      	pop  	r22
	      	pop  	r23
	      	pop  	r24
	      	pop  	r25
	      	pop  	r26
	      	pop  	gp
	      	pop  	xlr
	      	pop  	lr
	      	pop  	bp
	      	iret 
BIOSMain_88:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	BIOSMain_104
endpublic



_IBERoutSTKSIZE_ EQU 8

	rodata
	align	16
	align	8
	align	8
BIOSMain_1:
	dh	0x54442D18,0x400921FB
	align	2
BIOSMain_87:	; PC History:
	dc	80,67,32,72,105,115,116,111
	dc	114,121,58,13,10,0
BIOSMain_86:	; Instruction Bus Error:
	dc	13,10,73,110,115,116,114,117
	dc	99,116,105,111,110,32,66,117
	dc	115,32,69,114,114,111,114,58
	dc	13,10,0
BIOSMain_60:	; Databus error: 
	dc	13,10,68,97,116,97,98,117
	dc	115,32,101,114,114,111,114,58
	dc	32,0
BIOSMain_44:	; PC History:
	dc	13,10,80,67,32,72,105,115
	dc	116,111,114,121,58,13,10,0
BIOSMain_3:	;   Menu  up = ramtest  left = float test  right=TinyBasic
	dc	32,32,77,101,110,117,13,10
	dc	32,32,117,112,32,61,32,114
	dc	97,109,116,101,115,116,13,10
	dc	32,32,108,101,102,116,32,61
	dc	32,102,108,111,97,116,32,116
	dc	101,115,116,13,10,32,32,114
	dc	105,103,104,116,61,84,105,110
	dc	121,66,97,115,105,99,13,10
	dc	0
BIOSMain_2:	;   FT64 Bios Started
	dc	32,32,70,84,54,52,32,66
	dc	105,111,115,32,83,116,97,114
	dc	116,101,100,13,10,0
;	global	_BIOSMain
;	global	_BTNCIRQHandler
	extern	_DBGHomeCursor
	extern	_ramtest
	extern	_DBGClearScreen
	extern	_DBGDisplayString
	extern	_putch
	extern	_DBGAttr
;	global	_DBERout
;	global	_IBERout
	extern	_printf
	extern	_FloatTest
	extern	_prtflt
	extern	_puthex
