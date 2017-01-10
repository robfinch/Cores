;****************************************************************;
;                                                                ;
;		Tiny BASIC for the DSD9                              ;
;                                                                ;
; Derived from a 68000 derivative of Palo Alto Tiny BASIC as     ;
; published in the May 1976 issue of Dr. Dobb's Journal.         ;
; Adapted to the 68000 by:                                       ;
;	Gordon brndly						                         ;
;	12147 - 51 Street					                         ;
;	Edmonton AB  T5W 3G8					                     ;
;	Canada							                             ;
;	(updated mailing address for 1996)			                 ;
;                                                                ;
; Adapted to the DSD9 by:                                    ;
;    Robert Finch                                                ;
;    Ontario, Canada                                             ;
;	 robfinch<remove>@opencores.org	                             ;  
;****************************************************************;
;    Copyright (C) 2016 by Robert Finch. This program may be	 ;
;    freely distributed for personal use only. All commercial	 ;
;		       rights are reserved.			                     ;
;****************************************************************;
;
; Register Usage
; r8 = text pointer (global usage)
; r3,r4 = inputs parameters to subroutines
; r2 = return value
;
;* Vers. 1.0  1984/7/17	- Original version by Gordon brndly
;*	1.1  1984/12/9	- Addition of '0x' print term by Marvin Lipford
;*	1.2  1985/4/9	- Bug fix in multiply routine by Rick Murray

CR		EQU	0x0D		;ASCII equates
LINEFD	EQU	0x0A		; Don't use LF (same as load float instruction)
TAB		EQU	0x09
CTRLC	EQU	0x03
CTRLH	EQU	0x08
CTRLI	EQU	0x09
CTRLJ	EQU	0x0A
CTRLK	EQU	0x0B
CTRLM   EQU 0x0D
CTRLS	EQU	0x13
CTRLX	EQU	0x18
XON		EQU	0x11
XOFF	EQU	0x13

FILENAME	EQU		0x6C0
FILEBUF		EQU		0x01F60000
OSSP		EQU		0x700
TXTUNF		EQU		OSSP+10
VARBGN		EQU		TXTUNF+10
LOPVAR		EQU		VARBGN+10
STKGOS		EQU		LOPVAR+10
CURRNT		EQU		STKGOS+10
BUFFER		EQU		CURRNT+10
BUFLEN		EQU		84
LOPPT		EQU		BUFFER+168
LOPLN		EQU		LOPPT+10
LOPINC		EQU		LOPLN+10
LOPLMT		EQU		LOPINC+10
NUMWKA		EQU		LOPLMT+10
STKINP		EQU		NUMWKA+48
STKBOT		EQU		STKINP+10
usrJmp		EQU		STKBOT+10
IRQROUT		EQU		usrJmp+10

OUTPTR		EQU		IRQROUT+10
INPPTR		EQU		OUTPTR+10
CursorFlash	EQU		INPPTR+10
IRQFlag		EQU		CursorFlash+10

;
; Modifiable system constants:
;
;THRD_AREA	dw	0x04000000	; threading switch area 0x04000000-0x40FFFFF
;bitmap dw	0x00100000	; bitmap graphics memory 0x04100000-0x417FFFF
TXTBGN		EQU		0x01800000	;TXT ;beginning of program memory
ENDMEM		EQU		0x07FFEFFE	; end of available memory
STACKOFFS	EQU		0x07FFEFFE	; stack offset - leave a little room for the BIOS stacks


		code
		align	16
;
; Standard jump table. You can change these addresses if you are
; customizing this interpreter for a different environment.
;
TinyBasicDSD9:
GOSTART:	
		jmp	CSTART[pc]	;	Cold Start entry point
GOWARM:	
		jmp	WSTART[pc]	;	Warm Start entry point
GOOUT:	
		jmp	OUTC[pc]	;	Jump to character-out routine
GOIN:	
		jmp	INCH[pc]	;Jump to character-in routine
GOAUXO:	
		jmp	AUXOUT[pc]	;	Jump to auxiliary-out routine
GOAUXI:	
		jmp	AUXIN[pc]	;	Jump to auxiliary-in routine
GOBYE:	
		jmp	BYEBYE[pc]	;	Jump to monitor, DOS, etc.
;
; The main interpreter starts here:
;
; Usage
; r1 = temp
; r8 = text buffer pointer
; r12 = end of text in text buffer
;
	align	16
//message "CSTART"
public CSTART:
	; First save off the link register and OS sp value
	std		r63,OSSP
	ld		r63,#STACKOFFS	; initialize stack pointer
//	call	_RequestIOFocus
	call	_DBGHomeCursor[pc]
	mov		r1,r0			; turn off keyboard echoing
//	call	SetKeyboardEcho
//	stz		CursorFlash
//	ldx		#0x10000020	; black chars, yellow background
;	stx		charToPrint
	call	_DBGClearScreen[pc]
	ld		r1,#msgInit	;	tell who we are
	call	PRMESG
	ld		r1,#TXTBGN	;	init. end-of-program pointer
	std		r1,TXTUNF
	ld		r1,#ENDMEM	;	get address of end of memory
	sub		r1,r1,#8192	; 	reserve 4K for the stack
	std		r1,STKBOT
	sub		r1,r1,#32768 ;   1000 vars
	std     r1,VARBGN
	call    clearVars   ; clear the variable area
	std		r0,IRQROUT
	ldd     r1,VARBGN   ; calculate number of bytes free
	ldd		r2,TXTUNF
	sub     r1,r1,r2
	ld		r2,#12		; max 12 digits
	call  	PRTNUM
	ld		r1,#msgBytesFree
	call	PRMESG
WSTART:
	std		r0,LOPVAR   ; initialize internal variables
	std		r0,STKGOS
	std		r0,CURRNT	;	current line number pointer = 0
	ld		r31,#ENDMEM	;	init S.P. again, just in case
	ld		r1,#msgReady	;	display "Ready"
	call	PRMESG
ST3:
	ld		r1,#'>'		; Prompt with a '>' and
	call	GETLN		; read a line.
	call	TOUPBUF 	; convert to upper case
	mov		r12,r8		; save pointer to end of line
	ld		r8,#BUFFER	; point to the beginning of line
	call	TSTNUM		; is there a number there?
	call	IGNBLK		; skip trailing blanks
; does line no. exist? (or nonzero?)
	beq		r2,r0,DIRECT		; if not, it's a direct statement
	ble		r1,#$FFFFF,ST2	; see if line no. is <= 16 bits
	ld		r1,#msgLineRange	; if not, we've overflowed
	jmp		ERROR
ST2:
    ; ugliness - store a character at potentially an
    ; odd address (unaligned).
    mov		r2,r1		; r2 = line number
	sub		r8,r8,#5
    stp		r2,[r8]		;
	call	FNDLN		; find this line in save area
	mov		r13,r9		; save possible line pointer
	beq		r1,r0,ST4	; if not found, insert
	; here we found the line, so we're replacing the line
	; in the text area
	; first step - delete the line
	mov		r1,r0
	call	FNDNXT		; find the next line (into r9)
	bne		r1,r0,ST7
	ldd		r20,TXTUNF
	bgeu	r9,r20,ST6
	beq		r9,r0,ST6
ST7:
	mov		r1,r9		; r1 = pointer to next line
	mov		r2,r13		; pointer to line to be deleted
	ldd		r3,TXTUNF		; points to top of save area
	sub		r1,r3,r9	; r1 = length to move TXTUNF-pointer to next line
;	dea					; count is one less
	mov		r2,r9		; r2 = pointer to next line
	mov		r3,r13		; r3 = pointer to line to delete
	push	r4

ST8:
	ldw		r4,[r2]
	stw		r4,[r3]
	add		r2,r2,#2
	add		r3,r3,#2
	sub		r1,r1,#1
	bne		r1,r0,ST8

	pop		r4
	std		r3,TXTUNF		; update the end pointer
	; we moved the lines of text after the line being
	; deleted down, so the pointer to the next line
	; needs to be reset
	mov		r9,r13
	bra		ST4
	; here there were no more lines, so just move the
	; end of text pointer down
ST6:
	std		r13,TXTUNF
	mov		r9,r13
ST4:
	; here we're inserting because the line wasn't found
	; or it was deleted	from the text area
	sub		r1,r12,r8		; calculate the length of new line
	bleu	r1,#7,ST3		; is it just a line no. & CR? if so, it was just a delete

	; compute new end of text
	ldd		r10,TXTUNF		; r10 = old TXTUNF
	add		r11,r10,r1		; r11 = new top of TXTUNF (r1=line length)

	ldd		r20,VARBGN
	bleu	r11,r20,ST5		; see if there's enough room
	ld		r1,#msgTooBig	; if not, say so
	jmp		ERROR

	; open a space in the text area
ST5:
	std		r11,TXTUNF	; if so, store new end position
	mov		r1,r10		; points to old end of text
	mov		r2,r11		; points to new end of text
	mov		r3,r9	    ; points to start of line after insert line
	call	MVDOWN		; move things out of the way

	; copy line into text space
	mov		r1,r8		; set up to do the insertion; move from buffer
	mov		r2,r13		; to vacated space
	mov		r3,r12		; until end of buffer
	call	MVUP		; do it
	jmp		ST3			; go back and get another line

;******************************************************************
;
; *** Tables *** DIRECT *** EXEC ***
;
; This section of the code tests a string against a table. When
; a match is found, control is transferred to the section of
; code according to the table.
;
; At 'EXEC', r8 should point to the string, r9 should point to
; the character table, and r10 should point to the execution
; table. At 'DIRECT', r8 should point to the string, r9 and
; r10 will be set up to point to TAB1 and TAB1_1, which are
; the tables of all direct and statement commands.
;
; A '.' in the string will terminate the test and the partial
; match will be considered as a match, e.g. 'P.', 'PR.','PRI.',
; 'PRIN.', or 'PRINT' will all match 'PRINT'.
;
; There are two tables: the character table and the execution
; table. The character table consists of any number of text items.
; Each item is a string of characters with the last character's
; high bit set to one. The execution table holds a 32-bit
; execution addresses that correspond to each entry in the
; character table.
;
; The end of the character table is a 0 byte which corresponds
; to the default routine in the execution table, which is
; executed if none of the other table items are matched.
;
; Character-matching tables:
	align	2
TAB1:
	dw	"LIS",'T'+0x80        ; Direct commands
	dw	"LOA",'D'+0x80
	dw	"NE",'W'+0x80
	dw	"RU",'N'+0x80
	dw	"SAV",'E'+0x80
TAB2:
	dw	"NEX",'T'+0x80         ; Direct / statement
	dw	"LE",'T'+0x80
	dw	"I",'F'+0x80
	dw	"GOT",'O'+0x80
	dw	"GOSU",'B'+0x80
	dw	"RETUR",'N'+0x80
	dw	"RE",'M'+0x80
	dw	"FO",'R'+0x80
	dw	"INPU",'T'+0x80
	dw	"PRIN",'T'+0x80
	dw	"POK",'E'+0x80
	dw	"POKE",'W'+0x80
	dw	"POKE",'T'+0x80
	dw	"POKE",'P'+0x80
	dw	"POKE",'D'+0x80
	dw	"STO",'P'+0x80
	dw	"BY",'E'+0x80
	dw	"SY",'S'+0x80
	dw	"CL",'S'+0x80
    dw  "CL",'R'+0x80
    dw	"RDC",'F'+0x80
    dw	"ONIR",'Q'+0x80
    dw	"WAI",'T'+0x80
	dw	0
TAB4:
	dw	"PEE",'K'+0x80         ;Functions
	dw	"PEEK",'W'+0x80
	dw	"PEEK",'T'+0x80
	dw	"PEEK",'P'+0x80
	dw	"PEEK",'D'+0x80
	dw	"RN",'D'+0x80
	dw	"AB",'S'+0x80
	dw  "SG",'N'+0x80
	dw	"TIC",'K'+0x80
	dw	"SIZ",'E'+0x80
	dw  "US",'R'+0x80
	dw	0
TAB5:
	dw	"T",'O'+0x80           ;"TO" in "FOR"
	dw	0
TAB6:
	dw	"STE",'P'+0x80         ;"STEP" in "FOR"
	dw	0
TAB8:
	dw	'>','='+0x80           ;Relational operators
	dw	'<','>'+0x80
	dw	'>'+0x80
	dw	'='+0x80
	dw	'<','='+0x80
	dw	'<'+0x80
	dw	0
TAB9:
    dw  "AN",'D'+0x80
    dw  0
TAB10:
    dw  "O",'R'+0x80
    dw  0

;* Execution address tables:
; We save some bytes by specifiying only the low order 16 bits of the address
;
	align	4
TAB1_1:
	dt	LISTX			;Direct commands
	dt	LOAD3
	dt	NEW
	dt	RUN
	dt	SAVE3
TAB2_1:
	dt	NEXT		;	Direct / statement
	dt	LET
	dt	IF
	dt	GOTO
	dt	GOSUB
	dt	RETURN
	dt	IF2			; REM
	dt	FOR
	dt	INPUT
	dt	PRINT
	dt	POKE
	dt	POKEW
	dt	POKET
	dt	POKEP
	dt	POKED
	dt	STOP
	dt	GOBYE
	dt	SYSX
	dt	_cls
	dt  _clr
	dt	_rdcf
	dt  ONIRQ
	dt	WAITIRQ
	dt	DEFLT
TAB4_1:
	dt	PEEK			;Functions
	dt	PEEKW
	dt	PEEKT
	dt	PEEKP
	dt	PEEKD
	dt	RND
	dt	ABS
	dt  SGN
	dt	TICKX
	dt	SIZEX
	dt  USRX
	dt	XP40
TAB5_1
	dt	FR1			;"TO" in "FOR"
	dt	QWHAT
TAB6_1
	dt	FR2			;"STEP" in "FOR"
	dt	FR3
TAB8_1
	dt	XP11	;>=		Relational operators
	dt	XP12	;<>
	dt	XP13	;>
	dt	XP15	;=
	dt	XP14	;<=
	dt	XP16	;<
	dt	XP17
TAB9_1
    dt  XP_AND
    dt  XP_ANDX
TAB10_1
    dt  XP_OR
    dt  XP_ORX

;*
; r3 = match flag (trashed)
; r9 = text table
; r10 = exec table
; r11 = trashed
	align	16
//message "DIRECT"
DIRECT:
	ld		r9,#TAB1
	ld		r10,#TAB1_1
EXEC:
	call	IGNBLK		; ignore leading blanks
	mov		r11,r8		; save the pointer
	mov		r3,r0		; clear match flag
EXLP:
	ldwu	r1,[r8]		; get the program character
	add		r8,r8,#2
	ldwu	r2,[r9]		; get the table character
	bne		r2,r0,EXNGO		; If end of table,
	mov		r8,r11		;	restore the text pointer and...
	bra		EXGO		;   execute the default.
EXNGO:
	beq		r1,r3,EXGO	; Else check for period... if so, execute
	and		r2,r2,#0x7f	; ignore the table's high bit
	beq		r2,r1,EXMAT	;		is there a match?
	add		r10,r10,#4	;if not, try the next entry
	mov		r8,r11		; reset the program pointer
	mov		r3,r0		; sorry, no match
EX1:
	ldwu	r1,[r9]		; get to the end of the entry
	add		r9,r9,#2
	bbc		r1,#7,EX1	; test for bit 7 set
	bra		EXLP		; back for more matching
EXMAT:
	ld		r3,#'.'		; we've got a match so far
	ldwu	r1,[r9]		; end of table entry?
	add		r9,r9,#2
	bbc		r1,#7,EXLP		; test for bit 7 set, if not, go back for more
EXGO:
	; execute the appropriate routine
	ldtu	r1,[r10]	; get the low mid order byte
	or		r1,r1,#$FFFD0000	; add in ROM base
	jmp		[r1]

    
;******************************************************************
;
; What follows is the code to execute direct and statement
; commands. Control is transferred to these points via the command
; table lookup code of 'DIRECT' and 'EXEC' in the last section.
; After the command is executed, control is transferred to other
; sections as follows:
;
; For 'LISTX', 'NEW', and 'STOP': go back to the warm start point.
; For 'RUN': go execute the first stored line if any; else go
; back to the warm start point.
; For 'GOTO' and 'GOSUB': go execute the target line.
; For 'RETURN' and 'NEXT'; go back to saved return line.
; For all others: if 'CURRNT' is 0, go to warm start; else go
; execute next command. (This is done in 'FINISH'.)
;
;******************************************************************
;
; *** NEW *** STOP *** RUN (& friends) *** GOTO ***
;
; 'NEW<CR>' sets TXTUNF to point to TXTBGN
;

NEW:
	call	ENDCHK
	ld		r1,#TXTBGN
	std		r1,TXTUNF	;	set the end pointer
	call    clearVars

; 'STOP<CR>' goes back to WSTART
;
STOP:
	call	ENDCHK
	jmp		WSTART		; WSTART will reset the stack

; 'RUN<CR>' finds the first stored line, stores its address
; in CURRNT, and starts executing it. Note that only those
; commands in TAB2 are legal for a stored program.
;
; There are 3 more entries in 'RUN':
; 'RUNNXL' finds next line, stores it's address and executes it.
; 'RUNTSL' stores the address of this line and executes it.
; 'RUNSML' continues the execution on same line.
;
RUN:
	call	ENDCHK
	ld		r8,#TXTBGN	;	set pointer to beginning
	std		r8,CURRNT
	call    clearVars

RUNNXL					; RUN <next line>
	ldd		r1,CURRNT	; executing a program?
	beq		r1,r0,WSTART	; if not, we've finished a direct stat.
	ldd		r1,IRQROUT		; are we handling IRQ's ?
	beq		r1,r0,RUN1
	ldd		r20,IRQFlag		; was there an IRQ ?
	beq		r20,r0,RUN1
	std		r0,IRQFlag
	call	PUSHA_		; the same code as a GOSUB
	push	r8
	ldd		r1,CURRNT
	push	r1			; found it, save old 'CURRNT'...
	ldd		r1,STKGOS
	push	r1			; and 'STKGOS'
	std		r0,LOPVAR		; load new values
	std		r31,STKGOS
	ldd		r9,IRQROUT
	bra		RUNTSL
RUN1
	mov		r1,r0	    ; else find the next line number
	mov		r9,r8
	call	FNDLNP		; search for the next line
;	cmp		#0
;	bne		RUNTSL
	ldd		r20,TXTUNF	; if we've fallen off the end, stop
	bgeu	r9,r20,WSTART

RUNTSL					; RUN <this line>
	std		r9,CURRNT	; set CURRNT to point to the line no.
	add		r8,r9,#5	; set the text pointer to

RUNSML                 ; RUN <same line>
	call	CHKIO		; see if a control-C was pressed
	ld		r9,#TAB2		; find command in TAB2
	ld		r10,#TAB2_1
	jmp		EXEC		; and execute it


; 'GOTO expr<CR>' evaluates the expression, finds the target
; line, and jumps to 'RUNTSL' to do it.
;
GOTO
	call	OREXPR		;evaluate the following expression
;	call	DisplayWord
	mov     r5,r1
	call 	ENDCHK		;must find end of line
	mov     r1,r5
	call 	FNDLN		; find the target line
	bne		r1,r0,RUNTSL; go do it
	ld		r1,#msgBadGotoGosub
	jmp		ERROR		; no such line no.

_clr:
    call    clearVars
    jmp     FINISH

; Clear the variable area of memory
clearVars:
	push	r6
    ld      r6,#1024    ; number of words to clear
    ldd     r1,VARBGN
.cv1:
    std		r0,[r1]
    add		r1,r1,#20
    sub		r6,r6,#1
	bne		r6,r0,.cv1
    pop		r6
    ret

;******************************************************************
; ONIRQ <line number>
; ONIRQ sets up an interrupt handler which acts like a specialized
; subroutine call. ONIRQ is coded like a GOTO that never executes.
;******************************************************************
;
ONIRQ:
	call	OREXPR		;evaluate the following expression
	mov     r5,r1
	call 	ENDCHK		;must find end of line
	mov     r1,r5
	call 	FNDLN		; find the target line
	bne		r1,r0,ONIRQ1
	std		r0,IRQROUT
	jmp		FINISH
ONIRQ1:
	std		r9,IRQROUT
	jmp		FINISH

WAITIRQ:
	call	CHKIO		; see if a control-C was pressed
	ldd		r20,IRQFlag
	beq		r20,r0,WAITIRQ
	jmp		FINISH


;******************************************************************
; LIST
;
; LISTX has two forms:
; 'LIST<CR>' lists all saved lines
; 'LIST #<CR>' starts listing at the line #
; Control-S pauses the listing, control-C stops it.
;******************************************************************
;
LISTX:
	call		TSTNUM		; see if there's a line no.
	mov      r5,r1
	call		ENDCHK		; if not, we get a zero
	mov      r1,r5
	call		FNDLN		; find this or next line
LS1:
	bne		r1,r0,LS4
	ldd		r20,TXTUNF
	bgeu	r9,r20,WSTART	; warm start if we passed the end
LS4:
	mov		r1,r9
	call		PRTLN		; print the line
	mov		r9,r1		; set pointer for next
	call		CHKIO		; check for listing halt request
	beq		r1,r0,LS3
	bne		r1,#CTRLS,LS3; pause the listing?
LS2:
	call 	CHKIO		; if so, wait for another keypress
	beq		r1,r0,LS2
LS3:
	mov		r1,r0
	call	FNDLNP		; find the next line
	bra		LS1


;******************************************************************
; PRINT command is 'PRINT ....:' or 'PRINT ....<CR>'
; where '....' is a list of expressions, formats, back-arrows,
; and strings.	These items a separated by commas.
;
; A format is a pound sign followed by a number.  It controls
; the number of spaces the value of an expression is going to
; be printed in.  It stays effective for the rest of the print
; command unless changed by another format.  If no format is
; specified, 11 positions will be used.
;
; A string is quoted in a pair of single- or double-quotes.
;
; An underline (back-arrow) means generate a <CR> without a <LF>
;
; A <CR LF> is generated after the entire list has been printed
; or if the list is empty.  If the list ends with a semicolon,
; however, no <CR LF> is generated.
;******************************************************************
;
PRINT:
	ld		r5,#11		; D4 = number of print spaces
	ld		r3,#':'
	ld		r4,#PR2
	call	TSTC		; if null list and ":"
	call	CRLF		; give CR-LF and continue
	jmp		RUNSML		;		execution on the same line
PR2:
	ld		r3,#CR
	ld		r4,#PR0
	call	TSTC		;if null list and <CR>
	call	CRLF		;also give CR-LF and
	jmp		RUNNXL		;execute the next line
PR0:
	ld		r3,#'#'
	ld		r4,#PR1
	call	TSTC		;else is it a format?
	call	OREXPR		; yes, evaluate expression
	mov		r5,r1	; and save it as print width
	bra		PR3		; look for more to print
PR1:
	ld		r3,#'$'
	ld		r4,#PR4
	call	TSTC	;	is character expression? (MRL)
	call	OREXPR	;	yep. Evaluate expression (MRL)
	call	GOOUT	;	print low byte (MRL)
	bra		PR3		;look for more. (MRL)
PR4:
	call	QTSTG	;	is it a string?
	; the following branch must occupy only two bytes!
	bra		PR8		;	if not, must be an expression
PR3:
	ld		r3,#','
	ld		r4,#PR6
	call		TSTC	;	if ",", go find next
	call		FIN		;in the list.
	bra		PR0
PR6:
	call		CRLF		;list ends here
	jmp		FINISH
PR8:
	call	OREXPR		; evaluate the expression
	mov		r2,r5		; set the width
	call	PRTNUM		; print its value
	bra		PR3			; more to print?

FINISH:
	call	FIN		; Check end of command
	jmp		QWHAT	; print "What?" if wrong


;*******************************************************************
;
; *** GOSUB *** & RETURN ***
;
; 'GOSUB expr:' or 'GOSUB expr<CR>' is like the 'GOTO' command,
; except that the current text pointer, stack pointer, etc. are
; saved so that execution can be continued after the subroutine
; 'RETURN's.  In order that 'GOSUB' can be nested (and even
; recursive), the save area must be stacked.  The stack pointer
; is saved in 'STKGOS'.  The old 'STKGOS' is saved on the stack.
; If we are in the main routine, 'STKGOS' is zero (this was done
; in the initialization section of the interpreter), but we still
; save it as a flag for no further 'RETURN's.
;******************************************************************
;
GOSUB:
	call	PUSHA_		; save the current 'FOR' parameters
	call	OREXPR		; get line number
	call	FNDLN		; find the target line
	bne		r1,r0,gosub1
	ld		r1,#msgBadGotoGosub
	jmp		ERROR		; if not there, say "How?"
gosub1:
	push	r8
	ldd		r1,CURRNT	; found it, save old 'CURRNT'...
	push	r1
	ldd		r1,STKGOS
	push	r1			; and 'STKGOS'
	std		r0,LOPVAR		; load new values
	std		r63,STKGOS
	jmp		RUNTSL


;******************************************************************
; 'RETURN<CR>' undoes everything that 'GOSUB' did, and thus
; returns the execution to the command after the most recent
; 'GOSUB'.  If 'STKGOS' is zero, it indicates that we never had
; a 'GOSUB' and is thus an error.
;******************************************************************
;
RETURN:
	call	ENDCHK		; there should be just a <CR>
	ldd		r2,STKGOS		; get old stack pointer
	bne		r2,r0,return1
	ld		r1,#msgRetWoGosub
	jmp		ERROR		; if zero, it doesn't exist
return1:
	mov		r31,r2		; else restore it
	pop		r1
	std		r1,STKGOS	; and the old 'STKGOS'
	pop		r1
	std		r1,CURRNT	; and the old 'CURRNT'
	pop		r8			; and the old text pointer
	call	POPA_		;and the old 'FOR' parameters
	jmp		FINISH		;and we are back home

;******************************************************************
; *** FOR *** & NEXT ***
;
; 'FOR' has two forms:
; 'FOR var=exp1 TO exp2 STEP exp1' and 'FOR var=exp1 TO exp2'
; The second form means the same thing as the first form with a
; STEP of positive 1.  The interpreter will find the variable 'var'
; and set its value to the current value of 'exp1'.  It also
; evaluates 'exp2' and 'exp1' and saves all these together with
; the text pointer, etc. in the 'FOR' save area, which consists of
; 'LOPVAR', 'LOPINC', 'LOPLMT', 'LOPLN', and 'LOPPT'.  If there is
; already something in the save area (indicated by a non-zero
; 'LOPVAR'), then the old save area is saved on the stack before
; the new values are stored.  The interpreter will then dig in the
; stack and find out if this same variable was used in another
; currently active 'FOR' loop.  If that is the case, then the old
; 'FOR' loop is deactivated. (i.e. purged from the stack)
;******************************************************************
;
FOR:
	call	PUSHA_		; save the old 'FOR' save area
	call	SETVAL		; set the control variable
	std		r1,LOPVAR		; save its address
	ld		r9,#TAB5
	ld		r10,#TAB5_1	; use 'EXEC' to test for 'TO'
	jmp		EXEC
FR1:
	call	OREXPR		; evaluate the limit
	std		r1,LOPLMT	; save that
	ld		r9,#TAB6
	ld		r10,#TAB6_1	; use 'EXEC' to test for the word 'STEP
	jmp		EXEC
FR2:
	call	OREXPR		; found it, get the step value
	bra		FR4
FR3:
	ld		r1,#1		; not found, step defaults to 1
FR4:
	std		r1,LOPINC	; save that too
FR5:
	ldd		r2,CURRNT
	std		r2,LOPLN	; save address of current line number
	std		r8,LOPPT	; and text pointer
	mov		r3,r31		; dig into the stack to find 'LOPVAR'
	ldd		r6,LOPVAR
	bra		FR7
FR6:
	add		r3,r3,#50	; look at next stack frame
FR7:
	ldd		r2,[r3]		; is it zero?
	beq		r2,r0,FR8	; if so, we're done
	bne		r2,r6,FR6	; same as current LOPVAR? nope, look some more

    mov		r1,r3	   ; Else remove 5 long words from...
	add		r2,r3,#50  ; inside the stack.
	mov		r2,r63
	mov		r3,r2
	call	MVDOWN
	add		r63,r63,#50	; set the SP 5 long words up
	pop		r1
FR8:
    jmp	    FINISH		; and continue execution


;******************************************************************
; 'NEXT var' serves as the logical (not necessarily physical) end
; of the 'FOR' loop.  The control variable 'var' is checked with
; the 'LOPVAR'.  If they are not the same, the interpreter digs in
; the stack to find the right one and purges all those that didn't
; match.  Either way, it then adds the 'STEP' to that variable and
; checks the result with against the limit value.  If it is within
; the limit, control loops back to the command following the
; 'FOR'.  If it's outside the limit, the save area is purged and
; execution continues.
;******************************************************************
;
NEXT:
	mov		r1,r0		; don't allocate it
	call	TSTV		; get address of variable
	bne		r1,r0,NX4
	ld		r1,#msgNextVar
	bra		ERROR		; if no variable, say "What?"
NX4:
	mov		r9,r1	; save variable's address
NX0:
	ldd		r1,LOPVAR	; If 'LOPVAR' is zero, we never...
	bne		r1,r0,NX5	; had a FOR loop
	ld		r1,#msgNextFor
	bra		ERROR
NX5:
	beq		r1,r9,NX2	; else we check them OK, they agree
	call	POPA_		; nope, let's see the next frame
	bra		NX0
NX2:
	ldd		r1,[r9]		; get control variable's value
	ldd		r2,LOPINC
	add		r1,r1,r2	; add in loop increment
;	BVS.L	QHOW		say "How?" for 32-bit overflow
	std		r1,[r9]		; save control variable's new value
	ldd		r3,LOPLMT	; get loop's limit value
	bge		r2,r0,NX1	; check loop increment, branch if loop increment is positive
	blt		r1,r3,NXPurge	; test against limit
	bra     NX3
NX1:
	bgt		r1,r3,NXPurge
NX3:
	ldd		r8,LOPLN	; Within limit, go back to the...
	std		r8,CURRNT
	ldd		r8,LOPPT	; saved 'CURRNT' and text pointer.
	jmp		FINISH
NXPurge:
    call    POPA_        ; purge this loop
    jmp     FINISH


;******************************************************************
; *** REM *** IF *** INPUT *** LET (& DEFLT) ***
;
; 'REM' can be followed by anything and is ignored by the
; interpreter.
;
;REM
;    br	    IF2		    ; skip the rest of the line
; 'IF' is followed by an expression, as a condition and one or
; more commands (including other 'IF's) separated by colons.
; Note that the word 'THEN' is not used.  The interpreter evaluates
; the expression.  If it is non-zero, execution continues.  If it
; is zero, the commands that follow are ignored and execution
; continues on the next line.
;******************************************************************
;
IF:
    call	OREXPR		; evaluate the expression
IF1:
    bne	    r1,r0,RUNSML		; is it zero? if not, continue
IF2:
    mov		r9,r8	; set lookup pointer
	mov		r1,r0		; find line #0 (impossible)
	call	FNDSKP		; if so, skip the rest of the line
	blt		r1,r0,WSTART; if no next line, do a warm start
IF3:
	jmp		RUNTSL		; run the next line


;******************************************************************
; INPUT is called first and establishes a stack frame
INPERR:
	ldd		r63,STKINP		; restore the old stack pointer
	pop		r1
	std		r1,CURRNT		; and old 'CURRNT'
	pop		r8			; and old text pointer
	add		r63,r63,#50	; fall through will subtract 50

; 'INPUT' is like the 'PRINT' command, and is followed by a list
; of items.  If the item is a string in single or double quotes,
; or is an underline (back arrow), it has the same effect as in
; 'PRINT'.  If an item is a variable, this variable name is
; printed out followed by a colon, then the interpreter waits for
; an expression to be typed in.  The variable is then set to the
; value of this expression.  If the variable is preceeded by a
; string (again in single or double quotes), the string will be
; displayed followed by a colon.  The interpreter the waits for an
; expression to be entered and sets the variable equal to the
; expression's value.  If the input expression is invalid, the
; interpreter will print "What?", "How?", or "Sorry" and reprint
; the prompt and redo the input.  The execution will not terminate
; unless you press control-C.  This is handled in 'INPERR'.
;
INPUT:
	sub		r63,r63,#50	; allocate five words on stack
	std		r5,40[r63]	; save off r5 into stack var
IP6:
	std		r8,[r63]	; save in case of error
	call	QTSTG		; is next item a string?
	bra		IP2			; nope - this branch must take only two bytes
	ld		r1,#1		; allocate var
	call	TSTV		; yes, but is it followed by a variable?
	beq     r1,r0,IP4   ; if not, brnch
	mov		r10,r1		; put away the variable's address
	bra		IP3			; if so, input to variable
IP2:
	std		r8,10[r63]	; save off in stack var for 'PRTSTG'
	ld		r1,#1
	call	TSTV		; must be a variable now
	bne		r1,r0,IP7
	ld		r1,#msgInputVar
	add		r63,r63,#50	; cleanup stack
	bra		ERROR		; "What?" it isn't?
IP7:
	mov		r10,r1		; put away the variable's address
	ldwu	r5,[r8]		; get ready for 'PRTSTG' by null terminating
	stw		r0,[r8]
	ldd		r1,10[r63]	; get back text pointer
	call	PRTSTG		; print string as prompt
	stw		r5,[r8]		; un-null terminate
IP3
	std		r8,10[r63]	; save in case of error
	ldd		r1,CURRNT
	std		r1,20[r63]	; also save 'CURRNT'
	ld		r1,#-1
	std		r1,CURRNT	; flag that we are in INPUT
	std		r63,STKINP	; save the stack pointer too
	std		r10,30[r63]	; save the variable address
	ld		r1,#':'		; print a colon first
	call	GETLN		; then get an input line
	ld		r8,#BUFFER	; point to the buffer
	call	OREXPR		; evaluate the input
	ldd		r10,30[r63]	; restore the variable address
	std		r1,[r10]	; save value in variable
	ldd		r1,20[r63]	; restore old 'CURRNT'
	std		r1,CURRNT
	ldd		r8,10[r63]	; and the old text pointer
IP4:
	ld		r3,#','
	ld		r4,#IP5		; is the next thing a comma?
	call	TSTC
	bra		IP6			; yes, more items
IP5:
	ldd		r5,40[r63]
	add		r63,r63,#50	; cleanup stack
 	jmp		FINISH


DEFLT:
    ldwu    r1,[r8]
	beq	    r1,#CR,FINISH	    ; empty line is OK else it is 'LET'


;******************************************************************
; 'LET' is followed by a list of items separated by commas.
; Each item consists of a variable, an equals sign, and an
; expression.  The interpreter evaluates the expression and sets
; the variable to that value.  The interpreter will also handle
; 'LET' commands without the word 'LET'.  This is done by 'DEFLT'.
;******************************************************************
;
LET:
    call	SETVAL		; do the assignment
    ld		r3,#','
    ld		r4,#FINISH
	call	TSTC		; check for more 'LET' items
	bra	    LET
LT1:
    jmp	    FINISH		; until we are finished.


;******************************************************************
; *** LOAD *** & SAVE ***
;
; These two commands transfer a program to/from an auxiliary
; device such as a cassette, another computer, etc.  The program
; is converted to an easily-stored format: each line starts with
; a colon, the line no. as 4 hex digits, and the rest of the line.
; At the end, a line starting with an '@' sign is sent.  This
; format can be read back with a minimum of processing time by
; the RTF65002
;******************************************************************
;
LOAD
	ld		r8,#TXTBGN	; set pointer to start of prog. area
	ld		r1,#CR		; For a CP/M host, tell it we're ready...
	call	GOAUXO		; by sending a CR to finish PIP command.
LOD1:
	call	GOAUXI		; look for start of line
	ble		r1,r0,LOD1
	beq		r1,#'@',LODEND	; end of program?
	beq		r1,#$1A,LODEND	; or EOF marker
	bne		r1,#':',LOD1	; if not, is it start of line? if not, wait for it
	call	GCHAR		; get line number
	stp		r1,[r8]		; store it
	add		r8,r8,#5
LOD2:
	call	GOAUXI		; get another text char.
	ble		r1,r0,LOD2
	stw		r1,[r8]		; store it
	add		r8,r8,#2
	bne		r1,#CR,LOD2		; is it the end of the line? if not, go back for more
	bra		LOD1		; if so, start a new line
LODEND:
	std		r8,TXTUNF	; set end-of program pointer
	jmp		WSTART		; back to direct mode


; get character from input (40 bit value)
GCHAR:
	push	r5
	push	r6
	ld		r6,#10       ; repeat ten times
	ld		r5,#0
GCHAR1:
	call	GOAUXI		; get a char
	ble		r1,r0,GCHAR1
	call	asciiToHex
	shl		r5,r5,#4
	or		r5,r5,r1
	sub		r6,r6,#1
	bgtu	r6,r0,GCHAR1
	mov		r1,r5
	pop		r6
	pop		r5
	ret

; convert an ascii char to hex code
; input
;	r1 = char to convert

asciiToHex:
	bleu	r1,#'9',a2h1; less than '9'
	sub		r1,r1,#7	; shift 'A' to '9'+1
a2h1:
	sub		r1,r1,#'0'
	and		r1,r1,#15	; make sure a nybble
	ret

GetFilename:
	ld		r3,#'"'
	ld		r4,#gfn1
	call	TSTC
	mov		r3,r0
gfn2:
	ldwu	r1,[r8]		; get text character
	add		r8,r8,#2
	beq		r1,#'"',gfn3
	beq		r1,r0,gfn3
	stw		r1,FILENAME[r3]
	add		r3,r3,#2
	bltu	r3,#64,gfn2
	ret
gfn3:
	ld		r1,#' '
	stw		r1,FILENAME[r3]
	add		r3,r3,#2
	bltu	r3,#64,gfn3
	ret
gfn1:
	jmp		WSTART

LOAD3:
	call	GetFilename
	call	AUXIN_INIT
	jmp		LOAD

;	call		OREXPR		;evaluate the following expression
;	ld		r1,#5000
	ld		r2,#$E00
	call	SDReadSector
	add		r1,r1,#1
	ld		r2,#TXTBGN
LOAD4:
	push	r1
	call	SDReadSector
	add		r2,r2,#512
	pop		r1
	add		r1,r1,#1
	ld		r4,#TXTBGN
	add		r4,r4,#65536
	blt		r2,r4,LOAD4
LOAD5:
	bra		WSTART

SAVE3:
	call	GetFilename
	call	AUXOUT_INIT
	jmp		SAVE

	call	OREXPR		;evaluate the following expression
;	lda		#5000		; starting sector
	ld		r2,#$E00	; starting address to write
	call	SDWriteSector
	add		r1,r1,#1
	ld		r2,#TXTBGN
SAVE4:
	push	r1
	call	SDWriteSector
	add		r2,r2,#512
	pop		r1
	add		r1,r1,#1
	ld		r4,#TXTBGN
	add		r4,r4,#65536
	blt		r2,r4,SAVE4
	bra		WSTART

SAVE:
	ld		r8,#TXTBGN	;set pointer to start of prog. area
	ldd		r9,TXTUNF	;set pointer to end of prog. area
SAVE1:
	call	AUXOCRLF    ; send out a CR & LF (CP/M likes this)
	bgt		r8,r9,SAVEND; are we finished?
	ld		r1,#':'		; if not, start a line
	call	GOAUXO
	ldp		r1,[r8]		; get line number
	add		r8,r8,#5
	call	PWORD       ; output line number as 5-digit hex
SAVE2:
	ldwu	r1,[r8]		; get a text char.
	add		r8,r8,#2
	beq		r1,#CR,SAVE1	; is it the end of the line? if so, send CR & LF and start new line
	call	GOAUXO		; send it out
	bra		SAVE2		; go back for more text
SAVEND:
	ld		r1,#'@'		; send end-of-program indicator
	call	GOAUXO
	call	AUXOCRLF    ; followed by a CR & LF
	ld		r1,#$1A		; and a control-Z to end the CP/M file
	call	GOAUXO
	call	AUXOUT_FLUSH
	bra		WSTART		; then go do a warm start

; output a CR LF sequence to auxillary output
; Registers Affected
;   r3 = LF
AUXOCRLF:
    ld		r1,#CR
    call	GOAUXO
    ld		r1,#LINEFD
    call	GOAUXO
    ret


; output a word in hex format
; tricky because of the need to reverse the order of the chars
PWORD:
	push	r5
	ld		r5,#NUMWKA+14
	mov		r4,r1		; r4 = value
pword1:
    mov     r1,r4	    ; r1 = value
    shru	r4,r4,#4	; shift over to next nybble
    call	toAsciiHex  ; convert LS nybble to ascii hex
    stw     r1,[r5]		; save in work area
    sub		r5,r5,#2
	bge		r5,#NUMWKA,pword1
pword2:
    add		r5,r5,#2
    ldwu    r1,[r5]     ; get char to output
	call	GOAUXO		; send it
	blt		r5,#NUMWKA+14,pword2
	pop		r5
	ret

; convert nybble in r2 to ascii hex char2
; r2 = character to convert

toAsciiHex:
	and		r1,r1,#15	; make sure it's a nybble
	blt		r1,#10,tah1	; > 10 ?
	add		r1,r1,#7	; bump it up to the letter 'A'
tah1:
	add		r1,r1,#'0'	; bump up to ascii '0'
	ret


;******************************************************************
; *** POKE ***
;
; 'POKE expr1,expr2' stores the byte from 'expr2' into the memory
; address specified by 'expr1'.
; 'POKEW expr1,expr2' stores the wyde from 'expr2' into the memory
; address specified by 'expr1'.
; 'POKET expr1,expr2' stores the tetra from 'expr2' into the memory
; address specified by 'expr1'.
; 'POKEP expr1,expr2' stores the penta from 'expr2' into the memory
; address specified by 'expr1'.
; 'POKED expr1,expr2' stores the deci from 'expr2' into the memory
; address specified by 'expr1'.
;******************************************************************
;
POKE:
	call	OREXPR		; get the memory address
	ld		r3,#','
	ld		r4,#PKER	; it must be followed by a comma
	call	TSTC		; it must be followed by a comma
	push	r1			; save the address
	call	OREXPR		; get the byte to be POKE'd
	pop		r2		    ; get the address back
	stb		r1,[r2]		; store the byte in memory
	jmp		FINISH

POKEW:
	call	OREXPR		; get the memory address
	ld		r3,#','
	ld		r4,#PKER	; it must be followed by a comma
	call	TSTC		; it must be followed by a comma
	push	r1			; save the address
	call	OREXPR		; get the byte to be POKE'd
	pop		r2		    ; get the address back
	stw		r1,[r2]		; store the byte in memory
	jmp		FINISH

POKET:
	call	OREXPR		; get the memory address
	ld		r3,#','
	ld		r4,#PKER	; it must be followed by a comma
	call	TSTC		; it must be followed by a comma
	push	r1			; save the address
	call	OREXPR		; get the byte to be POKE'd
	pop		r2		    ; get the address back
	stt		r1,[r2]		; store the byte in memory
	jmp		FINISH

POKEP:
	call	OREXPR		; get the memory address
	ld		r3,#','
	ld		r4,#PKER	; it must be followed by a comma
	call	TSTC		; it must be followed by a comma
	push	r1			; save the address
	call	OREXPR		; get the byte to be POKE'd
	pop		r2		    ; get the address back
	stp		r1,[r2]		; store the byte in memory
	jmp		FINISH

POKED:
	call	OREXPR		; get the memory address
	ld		r3,#','
	ld		r4,#PKER	; it must be followed by a comma
	call	TSTC		; it must be followed by a comma
	push	r1			; save the address
	call	OREXPR		; get the byte to be POKE'd
	pop		r2		    ; get the address back
	std		r1,[r2]		; store the byte in memory
	jmp		FINISH

PKER:
	ld		r1,#msgComma
	jmp		ERROR		; if no comma, say "What?"

;******************************************************************
; 'SYSX expr' jumps to the machine language subroutine whose
; starting address is specified by 'expr'.  The subroutine can use
; all registers but must leave the stack the way it found it.
; The subroutine returns to the interpreter by executing an RTS.
;******************************************************************

SYSX:
	call	OREXPR		; get the subroutine's address
	bne		r1,r0,sysx1; make sure we got a valid address
	ld		r1,#msgSYSBad
	jmp		ERROR
sysx1:
	push	r8			; save the text pointer
	call	[r1]		; jump to the subroutine
	pop		r8		    ; restore the text pointer
	jmp		FINISH

;******************************************************************
; *** EXPR ***
;
; 'EXPR' evaluates arithmetical or logical expressions.
; <OREXPR>::= <ANDEXPR> OR <ANDEXPR> ...
; <ANDEXPR>::=<EXPR> AND <EXPR> ...
; <EXPR>::=<EXPR2>
;	   <EXPR2><rel.op.><EXPR2>
; where <rel.op.> is one of the operators in TAB8 and the result
; of these operations is 1 if true and 0 if false.
; <EXPR2>::=(+ or -)<EXPR3>(+ or -)<EXPR3>(...
; where () are optional and (... are optional repeats.
; <EXPR3>::=<EXPR4>( <* or /><EXPR4> )(...
; <EXPR4>::=<variable>
;	    <function>
;	    (<EXPR>)
; <EXPR> is recursive so that the variable '@' can have an <EXPR>
; as an index, functions can have an <EXPR> as arguments, and
; <EXPR4> can be an <EXPR> in parenthesis.
;

; <OREXPR>::=<ANDEXPR> OR <ANDEXPR> ...
;
OREXPR:
	call	ANDEXPR		; get first <ANDEXPR>
XP_OR1:
	push	r1			; save <ANDEXPR> value
	ld		r9,#TAB10	; look up a logical operator
	ld		r10,#TAB10_1
	jmp		EXEC		; go do it
XP_OR:
    call	ANDEXPR
    pop		r2
    or      r1,r1,r2
    bra     XP_OR1
XP_ORX:
	pop		r1
    ret


; <ANDEXPR>::=<EXPR> AND <EXPR> ...
;
ANDEXPR:
	call	EXPR		; get first <EXPR>
XP_AND1:
	push	r1			; save <EXPR> value
	ld		r9,#TAB9	; look up a logical operator
	ld		r10,#TAB9_1
	jmp		EXEC		; go do it
XP_AND:
    call	EXPR
    pop		r2
    and     r1,r1,r2
    bra     XP_AND1
XP_ANDX:
	pop		r1
    ret


; Determine if the character is a digit
;   Parameters
;       r1 = char to test
;   Returns
;       r1 = 1 if digit, otherwise 0
;
isDigit:
	blt		r1,#'0',isDigitFalse
	bgt		r1,#'9',isDigitFalse
	ld		r1,#1
    ret
isDigitFalse:
    mov		r1,r0
    ret


; Determine if the character is a alphabetic
;   Parameters
;       r1 = char to test
;   Returns
;       r1 = 1 if alpha, otherwise 0
;
isAlpha:
	blt		r1,#'A',isAlphaFalse
	ble		r1,#'Z',isAlphaTrue
	blt		r1,#'a',isAlphaFalse
	bgt		r1,#'z',isAlphaFalse
isAlphaTrue:
    ld		r1,#1
    ret
isAlphaFalse:
    mov		r1,r0
    ret


; Determine if the character is a alphanumeric
;   Parameters
;       r1 = char to test
;   Returns
;       r1 = 1 if alpha, otherwise 0
;
isAlnum:
    mov		r2,r1			; save test char
    call	isDigit
	bne		r1,r0,isDigitx	; if it is a digit
    mov		r1,r2			; get back test char
    call    isAlpha
isDigitx:
    ret


EXPR:
	call	EXPR2
	push	r1				; save <EXPR2> value
	ld		r9,#TAB8		; look up a relational operator
	ld		r10,#TAB8_1
	jmp		EXEC		; go do it
XP11:
	pop		r1
	call	XP18	; is it ">="?
	bge		r2,r1,XPRT1	; no, return r2=1
	bra		XPRT0	; else return r2=0
XP12:
	pop		r1
	call	XP18	; is it "<>"?
	bne		r2,r1,XPRT1	; no, return r2=1
	bra		XPRT0	; else return r2=0
XP13:
	pop		r1
	call	XP18	; is it ">"?
	bgt		r2,r1,XPRT1	; no, return r2=1
	bra		XPRT0	; else return r2=0
XP14:
	pop		r1
	call	XP18	; is it "<="?
	ble		r2,r1,XPRT1	; no, return r2=1
	bra		XPRT0	; else return r2=0
XP15:
	pop		r1
	call	XP18	; is it "="?
	beq		r2,r1,XPRT1	; if not, return r2=1
	bra		XPRT0	; else return r2=0
XP16:
	ppp		r1
	call	XP18	; is it "<"?
	blt		r2,r1,XPRT1	; if not, return r2=1
	bra		XPRT0	; else return r2=0
XPRT0:
	mov		r1,r0   ; return r1=0 (false)
	ret
XPRT1:
	ld		r1,#1	; return r1=1 (true)
	ret

XP17:				; it's not a rel. operator
	pop		r1		; return r2=<EXPR2>
	ret

XP18:
	push		r1
	call		EXPR2		; do a second <EXPR2>
	pop			r2
	ret

; <EXPR2>::=(+ or -)<EXPR3>(+ or -)<EXPR3>(...
//message "EXPR2"
EXPR2:
	ld		r3,#'-'
	ld		r4,#XP21
	call	TSTC		; negative sign?
	mov		r1,r0		; yes, fake '0-'
	push	r1
	bra		XP26
XP21:
	ld		r3,#'+'
	ld		r4,#XP22
	call	TSTC		; positive sign? ignore it
XP22:
	call	EXPR3		; first <EXPR3>
XP23:
	push	r1			; yes, save the value
	ld		r3,#'+'
	ld		r4,#XP25
	call	TSTC		; add?
	call	EXPR3		; get the second <EXPR3>
XP24:
	pop		r2
	add		r1,r1,r2	; add it to the first <EXPR3>
;	BVS.L	QHOW		brnch if there's an overflow
	bra		XP23		; else go back for more operations
XP25:
	ld		r3,#'-'
	ld		r4,#XP45
	call	TSTC		; subtract?
XP26:
	call	EXPR3		; get second <EXPR3>
	sub		r1,r0,r1	; change its sign
	bra		XP24		; and do an addition
XP45:
	pop		r1
	ret


; <EXPR3>::=<EXPR4>( <* or /><EXPR4> )(...

EXPR3:
	call	EXPR4		; get first <EXPR4>
XP31:
	push	r1			; yes, save that first result
	ld		r3,#'*'
	ld		r4,#XP34
	call	TSTC		; multiply?
	call	EXPR4		; get second <EXPR4>
	pop		r2
	mul		r1,r1,r2	; multiply the two
	bra		XP31        ; then look for more terms
XP34:
	ld		r3,#'/'
	ld		r4,#XP35
	call	TSTC		; divide?
	call	EXPR4		; get second <EXPR4>
	mov		r2,r1
	pop		r1
	div		r1,r1,r2	; do the division
	bra		XP31		; go back for any more terms
XP35:
	ld		r3,#'%'
	ld		r4,#XP47
	call	TSTC
	call	EXPR4
	mov		r2,r1
	pop		r1
	mod		r1,r1,r2
	bra		XP31
XP47:
	pop		r1
	ret


; Functions are called through EXPR4
; <EXPR4>::=<variable>
;	    <function>
;	    (<EXPR>)

EXPR4:
    ld		r9,#TAB4		; find possible function
    ld		r10,#TAB4_1
	jmp		EXEC        ; branch to function which does subsequent ret for EXPR4
XP40:                   ; we get here if it wasn't a function
	mov		r1,r0
	call	TSTV
	beq     r1,r0,XP41	; nor a variable
	ldd		r1,[r1]		; if a variable, return its value in r1
	ret
XP41:
	call	TSTNUM		; or is it a number?
	bne		r2,r0,XP46	; (if not, # of digits will be zero) if so, return it in r1
	call	PARN        ; check for (EXPR)
XP46:
	ret


; Check for a parenthesized expression
PARN:	
	ld		r3,#'('
	ld		r4,#XP43
	call	TSTC		; else look for ( OREXPR )
	call	OREXPR
	ld		r3,#')'
	ld		r4,#XP43
	call	TSTC
XP42:
	ret
XP43:
	add		r63,r63,#10	; get rid of return address
	ld		r1,#msgWhat
	jmp		ERROR


; ===== Test for a valid variable name.  Returns Z=1 if not
;	found, else returns Z=0 and the address of the
;	variable in r1.
; Parameters
;	r1 = 1 = allocate if not found
; Returns
;	r1 = address of variable, zero if not found

TSTV:
	push	r5
	mov		r5,r1		; r5=allocate flag
	call	IGNBLK
	ldwu	r1,[r8]		; look at the program text
	blt		r1,#'@',tstv_notfound	; C=1: not a variable
	bne		r1,#'@',TV1				; brnch if not "@" array
	add		r8,r8,#2	; If it is, it should be
	call	PARN		; followed by (EXPR) as its index.
;	BCS.L	QHOW		say "How?" if index is too big
    push	r1		    ; save the index
	call	SIZEX		; get amount of free memory
	pop		r2		    ; get back the index
	blt		r2,r1,TV2	; see if there's enough memory
	jmp    	QSORRY		; if not, say "Sorry"
TV2:
	ldd		r1,VARBGN	; put address of array element...
	sub     r1,r1,r2    ; into r1 (neg. offset is used)
	bra     TSTVRT
TV1:	
    call	getVarName      ; get variable name
    beq     r1,r0,TSTVRT    ; if not, return r1=0
    mov		r2,r5
    call	findVar     ; find or allocate
TSTVRT:
	pop		r5
	ret					; r1<>0 (found)
tstv_notfound:
	pop		r5
	mov		r1,r0		; r1=0 if not found
    ret


; Returns
;   r1 = 4 character variable name + type
;
getVarName:
    push	r5

    ldwu    r1,[r8]		; get first character
    push	r1			; save off current name
    call	isAlpha
    beq     r1,r0,gvn1
    ld	    r5,#3       ; loop three more times

	; check for second/third character
gvn4:
	add		r8,r8,#2
	ldwu    r1,[r8]		; do we have another char ?
	call	isAlnum
	beq     r1,r0,gvn2	; nope
	pop		r1			; get varname
	shl		r1,r1,#16
	ldwu    r2,[r8]
	or      r1,r1,r2   ; add in new char
    push	r1		   ; save off name again
    sub		r5,r5,#1
    bgt		r5,r0,gvn4

    ; now ignore extra variable name characters
gvn6:
	add		r8,r8,#2
	ldwu    r1,[r8]		; do we have another char ?
    call    isAlnum
    bne     r1,r0,gvn6	; keep looping as long as we have identifier chars

    ; check for a variable type
gvn2:
	ldwu    r1,[r8]
	beq		r1,#'%',gvn3
	beq		r1,#'$',gvn3
	mov		r1,r0
    sub		r8,r8,#2

    ; insert variable type indicator and return
gvn3:
	add		r8,r8,#2
    pop		r2
	shl		r2,r2,#16
    or      r1,r1,r2    ; add in variable type
    pop		r5
    ret					; return Z = 0, r1 = varname

    ; not a variable name
gvn1:
	add		r63,r63,#10	; pop r1
	pop		r5
    mov		r1,r0       ; return Z = 1 if not a varname
    ret


; Find variable
;   r1 = varname
;	r2 = allocate flag
; Returns
;   r1 = variable address, Z =0 if found / allocated, Z=1 if not found

findVar:
	push	r7
    ldd     r3,VARBGN
fv4:
    ldd     r7,[r3]     ; get varname / type
    beq     r7,r0,fv3	; no more vars ?
    beq     r1,r7,fv1	; match ?
	add		r3,r3,#20	; move to next var
    lw      r7,STKBOT
    blt     r3,r7,fv4	; loop back to look at next var

    ; variable not found
    ; no more memory
    ld		r1,#msgVarSpace
    jmp     ERROR
;    lw      lr,[sp]
;    lw      r7,4[sp]
;    add     sp,sp,#8
;    lw      r1,#0
;    ret

    ; variable not found
    ; allocate new ?
fv3:
	beq		r2,r0,fv2
    std     r1,[r3]     ; save varname / type
    ; found variable
    ; return address
fv1:
    add		r1,r3,#10
	pop		r7
    ret			    ; Z = 0, r1 = address

    ; didn't find var and not allocating
fv2:
    pop		r7
	mov		r1,r0	; Z = 1, r1 = 0
    ret


; ===== The PEEK function returns the byte stored at the address
;	contained in the following expression.
;
PEEK:
	call	PARN		; get the memory address
	ldb		r1,[r1]		; get the addressed byte
	ret
PEEKW:
	call	PARN		; get the memory address
	ldw		r1,[r1]		; get the addressed byte
	ret
PEEKT:
	call	PARN		; get the memory address
	ldt		r1,[r1]		; get the addressed byte
	ret
PEEKP:
	call	PARN		; get the memory address
	ldp		r1,[r1]		; get the addressed byte
	ret
PEEKD:
	call	PARN		; get the memory address
	ldd		r1,[r1]		; get the addressed byte
	ret


; user function call
; call the user function with argument in r1
USRX:
	call	PARN		; get expression value
	push	r8			; save the text pointer
	ldd		r2,usrJmp
	call	[r2]		; get usr vector, jump to the subroutine
	pop		r8			; restore the text pointer
	ret


; ===== The RND function returns a random number from 1 to
;	the value of the following expression in D0.
;
RND:
	call	PARN		; get the upper limit
	beq		r1,r0,rnd2	; it must be positive and non-zero
	blt		r1,r0,rnd1
	mov		r2,r1
	call	gen_rand	; generate a random number
	mod		r1,r1,r2
	add		r1,r1,#1
	ret
rnd1:
	ld		r1,#msgRNDBad
	jmp		ERROR
rnd2:
	call	gen_rand	; generate a random number
	ret

; ===== The ABS function returns an absolute value in r2.
;
ABS:
	call	PARN		; get the following expr.'s value
	blt		r1,r0,ABS1
	ret
ABS1:
	sub		r1,r0,r1
	ret

;==== The TICK function returns the cpu tick value in r1.
;
TICKX:
	csrrw	r1,#2,r0
	ret

; ===== The SGN function returns the sign in r1. +1,0, or -1
;
SGN:
	call	PARN		; get the following expr.'s value
	beq		r1,r0,SGN1
	blt		r1,r0,SGN2
	ld		r1,#1
	ret
SGN2:
	ld		r1,#-1
	ret
SGN1:
	ret	

; ===== The SIZE function returns the size of free memory in r1.
;
SIZEX:
	ldd		r1,VARBGN	; get the number of free bytes...
	ldd		r2,TXTUNF	; between 'TXTUNF' and 'VARBGN'
	sub		r1,r1,r2
	ret					; return the number in r1


;******************************************************************
;
; *** SETVAL *** FIN *** ENDCHK *** ERROR (& friends) ***
;
; 'SETVAL' expects a variable, followed by an equal sign and then
; an expression.  It evaluates the expression and sets the variable
; to that value.
;
; returns
; r2 = variable's address
;
SETVAL:
    ld		r1,#1		; allocate var
    call	TSTV		; variable name?
    bne		r1,r0,.sv2
   	ld		r1,#msgVar
   	jmp		ERROR 
.sv2:
	push	r1		    ; save the variable's address
	ld		r3,#'='
	ld		r4,#SV1
	call	TSTC		; get past the "=" sign
	call	OREXPR		; evaluate the expression
	pop		r2		    ; get back the variable's address
	std     r1,[r2]	    ; and save value in the variable
	mov		r1,r2		; return r1 = variable address
	ret
SV1:
    jmp	    QWHAT		; if no "=" sign


; 'FIN' checks the end of a command.  If it ended with ":",
; execution continues.	If it ended with a CR, it finds the
; the next line and continues from there.
;
FIN:
	ld		r3,#':'
	ld		r4,#FI1
	call	TSTC		; *** FIN ***
	add		r63,r63,#10	; if ":", discard return address
	jmp		RUNSML		; continue on the same line
FI1:
	ld		r3,#CR
	ld		r4,#FI2
	call	TSTC		; not ":", is it a CR?
						; else return to the caller
	add		r63,r63,#10	; yes, purge return address
	jmp		RUNNXL		; execute the next line
FI2:
	ret					; else return to the caller


; 'ENDCHK' checks if a command is ended with a CR. This is
; required in certain commands, such as GOTO, RETURN, STOP, etc.
;
; Check that there is nothing else on the line
; Registers Affected
;   r1
;
ENDCHK:
	call	IGNBLK
	ldwu	r1,[r8]
	beq		r1,#CR,ec1	; does it end with a CR?
	ld		r1,#msgExtraChars
	jmp		ERROR
ec1:
	ret

; 'ERROR' prints the string pointed to by r1. It then prints the
; line pointed to by CURRNT with a "?" inserted at where the
; old text pointer (should be on top of the stack) points to.
; Execution of Tiny BASIC is stopped and a warm start is done.
; If CURRNT is zero (indicating a direct command), the direct
; command is not printed. If CURRNT is -1 (indicating
; 'INPUT' command in progress), the input line is not printed
; and execution is not terminated but continues at 'INPERR'.
;
; Related to 'ERROR' are the following:
; 'QWHAT' saves text pointer on stack and gets "What?" message.
; 'AWHAT' just gets the "What?" message and jumps to 'ERROR'.
; 'QSORRY' and 'ASORRY' do the same kind of thing.
; 'QHOW' and 'AHOW' also do this for "How?".
;
TOOBIG:
	ld		r1,#msgTooBig
	bra		ERROR
QSORRY:
    ld		r1,#SRYMSG
	bra	    ERROR
QWHAT:
	ld		r1,#msgWhat
ERROR:
	call	PRMESG		; display the error message
	ldd		r1,CURRNT	; get the current line pointer
	beq		r1,r0,ERROR1	; if zero, do a warm start
	beq		r1,#-1,INPERR	; is the line no. pointer = -1? if so, redo input
	ldwu	r5,[r8]		; save the char. pointed to
	stw		r0,[r8]		; put a zero where the error is
	ldd		r1,CURRNT	; point to start of current line
	call	PRTLN		; display the line in error up to the 0
	mov     r6,r1	    ; save off end pointer
	stw		r5,[r8]		; restore the character
	ld		r1,#'?'		; display a "?"
	call	GOOUT
	mov		r2,r0		; stop char = 0
	sub		r1,r6,#1	; point back to the error char.
	call	PRTSTG		; display the rest of the line
ERROR1:
	jmp	    WSTART		; and do a warm start

;******************************************************************
;
; *** GETLN *** FNDLN (& friends) ***
;
; 'GETLN' reads in input line into 'BUFFER'. It first prompts with
; the character in r3 (given by the caller), then it fills the
; buffer and echos. It ignores LF's but still echos
; them back. Control-H is used to delete the last character
; entered (if there is one), and control-X is used to delete the
; whole line and start over again. CR signals the end of a line,
; and causes 'GETLN' to return.
;
;
GETLN:
	push	r5
	call	GOOUT		; display the prompt
	ld		r1,#1
	std		r1,CursorFlash	; turn on cursor flash
	ld		r1,#' '		; and a space
	call	GOOUT
	ld		r8,#BUFFER	; r8 is the buffer pointer
.GL1:
	call	CHKIO		; check keyboard
	beq		r1,r0,.GL1	; wait for a char. to come in
	beq		r1,#CTRLH,.GL3	; delete last character? if so
	beq		r1,#CTRLX,.GL4	; delete the whole line?
	beq		r1,#CR,.GL2		; accept a CR
	blt		r1,#' ',.GL1	; if other control char., discard it
.GL2:
	stw		r1,[r8]		; save the char.
	add		r8,r8,#2
	push	r1
	call	GOOUT		; echo the char back out
	pop		r1			; get char back (GOOUT destroys r1)
	beq		r1,#CR,.GL7			; if it's a CR, end the line
	blt		r8,#BUFFER+BUFLEN-1,.GL1		; any more room? ; yes: get some more, else delete last char.
.GL3:
	ld		r1,#CTRLH	; delete a char. if possible
	call	GOOUT
	ld		r1,#' '
	call	GOOUT
	ble		r8,#BUFFER,.GL1	; any char.'s left?	; if not
	ld		r1,#CTRLH		; if so, finish the BS-space-BS sequence
	call	GOOUT
	sub		r8,r8,#2	; decrement the text pointer
	bra		.GL1		; back for more
.GL4:
	mov		r1,r8		; delete the whole line
	sub		r5,r1,#BUFFER   ; figure out how many backspaces we need
	beq		r5,r0,.GL6		; if none needed, brnch
	sub		r5,r5,#1		; loop count is one less
.GL5:
	ld		r1,#CTRLH		; and display BS-space-BS sequences
	call	GOOUT
	ld		r1,#' '
	call	GOOUT
	ld		r1,#CTRLH
	call	GOOUT
	sub		r5,r5,#1
	bne		r5,r0,.GL5
.GL6:
	ld		r8,#BUFFER	; reinitialize the text pointer
	bra		.GL1		; and go back for more
.GL7:
	stw		r0,[r8]		; null terminate line
	std		r0,CursorFlash	; turn off cursor flash
	ld		r1,#LINEFD	; echo a LF for the CR
	call	GOOUT
	pop		r5
	ret


; 'FNDLN' finds a line with a given line no. (in r1) in the
; text save area.  r9 is used as the text pointer. If the line
; is found, r9 will point to the beginning of that line
; (i.e. the high byte of the line no.), and r1 = 1.
; If that line is not there and a line with a higher line no.
; is found, r9 points there and r1 = 0. If we reached
; the end of the text save area and cannot find the line, flags
; r9 = 0, r1 = 0.
; r1=1 if line found
; r0 = 1	<= line is found
;	r9 = pointer to line
; r0 = 0    <= line is not found
;	r9 = zero, if end of text area
;	r9 = otherwise higher line number
;
; 'FNDLN' will initialize r9 to the beginning of the text save
; area to start the search. Some other entries of this routine
; will not initialize r9 and do the search.
; 'FNDLNP' will start with r9 and search for the line no.
; 'FNDNXT' will bump r9 by 2, find a CR and then start search.
; 'FNDSKP' uses r9 to find a CR, and then starts the search.
; return Z=1 if line is found, r9 = pointer to line
;
; Parameters
;	r1 = line number to find
;
FNDLN:
	blt		r1,#$FFFFF,fl1	; line no. must be < 65535
	ld		r1,#msgLineRange
	jmp		ERROR
fl1:
	ld		r9,#TXTBGN	; init. the text save pointer

FNDLNP:
	ldd		r20,TXTUNF	; check if we passed the end
	bge		r9,r20,FNDRET1; if so, return with r9=0,r1=0
	ldpu	r1,[r9]		; get line number
	beq		r1,r2,FNDRET2
	bgt		r1,r2,FNDNXT	; is this the line we want? no, not there yet
FNDRET:
	mov		r1,r0	; line not found, but r9=next line pointer
	ret			; return the cond. codes
FNDRET1:
;	eor		r9,r9,r9	; no higher line
	mov		r1,r0	; line not found
	ret
FNDRET2:
	ld		r1,#1	; line found
	ret

FNDNXT:
	add		r9,r9,#5	; find the next line

FNDSKP:
	ldwu	r2,[r9]
	add		r9,r9,#2
	bne		r2,#CR,FNDSKP	; try to find a CR, keep looking
	bra		FNDLNP		; check if end of text


;******************************************************************
; 'MVUP' moves a block up from where r1 points to where r2 points
; until r1=r3
;
MVUP1:
	ldb		r4,[r1]
	stb		r4,[r2]
	add		r1,r1,#1
	add		r2,r2,#1
MVUP:
	bne		r1,r3,MVUP1
MVRET:
	ret


; 'MVDOWN' moves a block down from where r1 points to where r2
; points until r1=r3
;
MVDOWN1:
	sub		r1,r1,#1
	sub		r2,r2,#1
	ldb		r4,[r1]
	stb		r4,[r2]
MVDOWN:
	bne		r1,r3,MVDOWN1
	ret


; 'POPA_' restores the 'FOR' loop variable save area from the stack
;
; 'PUSHA_' stacks for 'FOR' loop variable save area onto the stack
;
; Note: a single zero word is stored on the stack in the
; case that no FOR loops need to be saved. This needs to be
; done because PUSHA_ / POPA_ is called all the time.
//message "POPA_"
POPA_:
	pop		r3
	pop		r1
	std		r1,LOPVAR	; restore LOPVAR, but zero means no more
	beq		r1,r0,PP1
	pop		r1
	std		r1,LOPINC
	pop		r1
	std		r1,LOPLMT
	pop		r1
	std		r1,LOPLN
	pop		r1
	std		r1,LOPPT
PP1:
	jmp		[r3]


PUSHA_:
	pop		r3
	ldd		r1,STKBOT	; Are we running out of stack room?
	add		r1,r1,#50	; we might need this many bytes
	blt		r63,r1,QSORRY	; out of stack space
	ldd		r2,LOPVAR		; save loop variables
	beq		r2,r0,PU1		; if LOPVAR is zero, that's all
	ldd		r1,LOPPT
	push	r1
	ldd		r1,LOPLN
	push	r1
	ldd		r1,LOPLMT
	push	r1
	ldd		r1,LOPINC
	push	r1
PU1:
	push	r2
	jmp		[r3]


;******************************************************************
;
; 'PRTSTG' prints a string pointed to by r1. It stops printing
; and returns to the caller when either a CR is printed or when
; the next byte is the same as what was passed in r2 by the
; caller.
;
; 'PRTLN' prints the saved text line pointed to by r3
; with line no. and all.
;

; r1 = pointer to string
; r2 = stop character
; return r1 = pointer to end of line + 1

PRTSTG:
	push	r5
	push	r6
	push	r7
    mov     r5,r1	    ; r5 = pointer
	mov     r6,r2	    ; r6 = stop char
.PS1:
    ldwu    r7,[r5]     ; get a text character
	add		r5,r5,#2
	beq	    r7,r6,.PRTRET	; same as stop character? if so, return
	mov     r1,r7
	call	GOOUT		; display the char.
	bne     r7,#CR,.PS1	; is it a C.R.? no, go back for more
	ld		r1,#LINEFD  ; yes, add a L.F.
	call	GOOUT
.PRTRET:
    mov     r2,r7	    ; return r2 = stop char
	mov		r1,r5		; return r1 = line pointer
	pop		r7
	pop		r6
	pop		r5
    ret					; then return


; 'QTSTG' looks for an underline (back-arrow on some systems),
; single-quote, or double-quote.  If none of these are found, returns
; to the caller.  If underline, outputs a CR without a LF.  If single
; or double quote, prints the quoted string and demands a matching
; end quote.  After the printing, the next i-word of the caller is
; skipped over (usually a branch instruction).
;
QTSTG:
	ld		r3,#'"'
	ld		r4,#QT3
	call	TSTC		; *** QTSTG ***
	ld		r2,#'"'		; it is a "
QT1:
	mov		r1,r8
	call	PRTSTG		; print until another
	mov		r8,r1
	bne		r2,#CR,QT2	; was last one a CR?
	jmp		RUNNXL		; if so run next line
QT3:
	ld		r3,#'\''
	ld		r4,#QT4
	call	TSTC		; is it a single quote?
	ld		r2,#'\''	; if so, do same as above
	bra		QT1
QT4:
	ld		r3,#'_'
	ld		r4,#QT5
	call	TSTC		; is it an underline?
	ld		r1,#CR		; if so, output a CR without LF
	call	GOOUT
QT2:
	pop		r1			; get return address
	and		r20,r1,#15
	beq		r20,#0,QT6
	beq		r20,#5,QT6
	add		r1,r1,#6	; add 2 to it in order to skip following branch
	jmp		[r1]		; skip over next i-word when returning
QT5:					; not " ' or _
	ret
QT6:
	add		r1,r1,#5
	jmp		[r1]

; Output a CR LF sequence
;
prCRLF:
	ld		r1,#CR
	call	GOOUT
	ld		r1,#LINEFD
	call	GOOUT
	ret

; 'PRTNUM' prints the 32 bit number in r1, leading blanks are added if
; needed to pad the number of spaces to the number in r2.
; However, if the number of digits is larger than the no. in
; r2, all digits are printed anyway. Negative sign is also
; printed and counted in, positive sign is not.
;
; r1 = number to print
; r2 = number of digits
; Register Usage
;	r5 = number of padding spaces
public PRTNUM:
	push	r3
	push	r5
	push	r6
	push	r7
	ld		r7,#NUMWKA	; r7 = pointer to numeric work area
	ld		r6,r1		; save number for later
	ld		r5,r2		; r5 = min number of chars
	bge		r1,r0,PN2	; is it negative? if not
	sub		r1,r0,r1	; else make it positive
	sub		r5,r5,#1	; one less for width count
PN2:
;	ld		r3,#10
PN1:
	mod		r2,r1,#10	; r2 = r1 mod 10
	div		r1,r1,#10	; r1 /= 10 divide by 10
	add		r2,r2,#'0'	; convert remainder to ascii
	stw		r2,[r7]		; and store in buffer
	add		r7,r7,#2
	sub		r5,r5,#1	; decrement width
	bne		r1,r0,PN1
PN6:
	ble		r5,r0,PN4	; test pad count, skip padding if not needed
PN3:
	ld		r1,#' '		; display the required leading spaces
	call	GOOUT
	sub		r5,r5,#1
	bgt		r5,r0,PN3
PN4:
	bge		r6,r0,PN5	; is number negative?
	ld		r1,#'-'		; if so, display the sign
	call	GOOUT
PN5:
	sub		r7,r7,#2
	ldwu	r1,[r7]		; now unstack the digits and display
	call	GOOUT
	bgtu	r7,#NUMWKA,PN5
PNRET:
	pop		r7
	pop		r6
	pop		r5
	pop		r3
	ret

; r1 = number to print
; r2 = number of digits
public PRTHEXNUM:
	push	r4
	push	r5
	push	r6
	push	r7
	push	r8
	ld		r7,#NUMWKA	; r7 = pointer to numeric work area
	mov		r6,r1		; save number for later
;	setlo	r5,#20		; r5 = min number of chars
	mov		r5,r2
	mov		r4,r1
	bge		r4,r0,PHN2	; is it negative? if not
	sub		r4,r0,r4	; else make it positive
	sub		r5,r5,#1	; one less for width count
PHN2
	ld		r8,#10		; maximum of 10 digits
PHN1:
	mov		r1,r4
	and		r1,r1,#15
	bltu	r1,#10,PHN7
	add		r1,r1,#'A'-10
	bra		PHN8
PHN7:
	add		r1,r1,#'0'	; convert remainder to ascii
PHN8:
	stw		r1,[r7]		; and store in buffer
	add		r7,r7,#2
	sub		r5,r5,#1	; decrement width
	shru	r4,r4,#4
	beq		r4,r0,PHN6	; is it zero yet ?
	sub		r8,r8,#1
	bgt		r8,r0,PHN1
PHN6:	; test pad count	
	ble		r5,r0,PHN4	; skip padding if not needed
PHN3:
	ld		r1,#' '		; display the required leading spaces
	call	GOOUT
	sub		r5,r5,#1
	bgt		r5,r0,PHN3
PHN4:
	bge		r6,r0,PHN5	; is number negative?
	ld		r1,#'-'		; if so, display the sign
	call	GOOUT
PHN5:
	sub		r7,r7,#2
	ldwu	r1,[r7]		; now unstack the digits and display
	call	GOOUT
	bgt		r7,#NUMWKA,PHN5
PHNRET:
	pop		r8
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ret


; r1 = pointer to line
; returns r1 = pointer to end of line + 1
PRTLN:
	push	r5
    mov		r5,r1		; r5 = pointer
    ldp		r1,[r5]		; get the binary line number
	add		r5,r5,#5
    ld		r2,#5       ; display a 0 or more digit line no.
	call	PRTNUM
	ld		r1,#' '     ; followed by a blank
	call	GOOUT
	mov		r2,r0       ; stop char. is a zero
	mov		r1,r5
	call    PRTSTG		; display the rest of the line
	pop		r5
	ret


; ===== Test text byte following the call to this subroutine. If it
;	equals the byte pointed to by r8, return to the code following
;	the call. If they are not equal, brnch to the point
;	indicated in r4.
;
; Registers Affected
;   r3,r8
; Returns
;	r8 = updated text pointer
;
TSTC
	push	r1
	call	IGNBLK		; ignore leading blanks
	ldwu	r1,[r8]
	beq		r3,r1,TC1	; is it = to what r8 points to? if so
	pop		r1
	add		r63,r63,#10	; increment stack pointer (get rid of return address)
	jmp		[r4]		; jump to the routine
TC1:
	add		r8,r8,#2	; if equal, bump text pointer
	pop		r1
	ret

; ===== See if the text pointed to by r8 is a number. If so,
;	return the number in r2 and the number of digits in r3,
;	else return zero in r2 and r3.
; Registers Affected
;   r1,r2,r3,r4
; Returns
; 	r1 = number
;	r2 = number of digits in number
;	r8 = updated text pointer
;
TSTNUM:
	push	r3
	call	IGNBLK		; skip over blanks
	mov		r1,r0		; initialize return parameters
	mov		r2,r0
TN1:
	ldwu	r3,[r8]
	blt		r3,#'0',TSNMRET; is it less than zero?
	bgt		r3,#'9',TSNMRET; is it greater than nine?
	bleu	r1,#$7FFFFFFFFFFFFFF,TN2; see if there's room for new digit
	ld		r1,#msgNumTooBig
	jmp		ERROR		; if not, we've overflowd
TN2:
	add		r8,r8,#2	; adjust text pointer
	mul		r1,r1,#10	; quickly multiply result by 10
	and		r3,r3,#$0F	; add in the new digit
	add		r1,r1,r3
	add		r2,r2,#1	; increment the no. of digits
	bra		TN1
TSNMRET:
	pop		r3
	ret


;===== Skip over blanks in the text pointed to by r8.
;
; Registers Affected:
;	r8
; Returns
;	r8 = pointer updateded past any spaces or tabs
;
IGNBLK:
	push	r1
IGB2:
	ldwu	r1,[r8]			; get char
	beq		r1,#' ',IGB1	; see if it's a space
	bne		r1,#'\t',IGBRET	; or a tab
IGB1:
	add		r8,r8,#2		; increment the text pointer
	bra		IGB2
IGBRET:
	pop		r1
	ret

; ===== Convert the line of text in the input buffer to upper
;	case (except for stuff between quotes).
;
; Registers Affected
;   r1,r3
; Returns
;	r8 = pointing to end of text in buffer
;
TOUPBUF:
	ld		r8,#BUFFER	; set up text pointer
	mov		r3,r0		; clear quote flag
TOUPB1:
	ldwu	r1,[r8]		; get the next text char.
	add		r8,r8,#2
	beq		r1,#CR,TOUPBRT		; is it end of line?
	beq		r1,#'"',DOQUO	; a double quote?
	beq		r1,#'\'',DOQUO	; or a single quote?
	bne		r3,r0,TOUPB1	; inside quotes?
	call	toUpper 	; convert to upper case
	stw		r1,-2[r8]	; store it
	bra		TOUPB1		; and go back for more
DOQUO:
	bne		r3,r0,DOQUO1; are we inside quotes?
	mov		r3,r1		; if not, toggle inside-quotes flag
	bra		TOUPB1
DOQUO1:
	bne		r3,r1,TOUPB1; make sure we're ending proper quote
	mov		r3,r0		; else clear quote flag
	bra		TOUPB1
TOUPBRT:
	ret


; ===== Convert the character in r1 to upper case
;
toUpper
	blt     r1,#'a',TOUPRET	; is it < 'a'?
	bgt		r1,#'z',TOUPRET	; or > 'z'?
	sub		r1,r1,#32	  ; if not, make it upper case
TOUPRET
	ret


; 'CHKIO' checks the input. If there's no input, it will return
; to the caller with the r1=0. If there is input, the input byte is in r1.
; However, if a control-C is read, 'CHKIO' will warm-start BASIC and will
; not return to the caller.
;
//message "CHKIO"
CHKIO:
	call	GOIN		; get input if possible
	beq		r1,r0,CHKRET2	; if Zero, no input
	bne		r1,#CTRLC,CHKRET; is it control-C?
	add		r63,r63,#10	; dump return address
	jmp		WSTART		; if so, do a warm start
CHKRET2:
	mov		r1,r0
CHKRET:
	ret

; ===== Display a CR-LF sequence
;
CRLF:
	ld		r1,#CLMSG

; ===== Display a zero-ended string pointed to by register r1
; Registers Affected
;   r1,r2,r4
;
PRMESG:
	push	r5
	mov     r5,r1		; r5 = pointer to message
PRMESG1:
	add		r5,r5,#2
	ldwu	r1,-2[r5]	; 	get the char.
	beq		r1,r0,PRMRET
	call	GOOUT		;else display it trashes r4
	bra		PRMESG1
PRMRET:
	mov		r1,r5
	pop		r5
	ret


; ===== Display a zero-ended string pointed to by register r1
; Registers Affected
;   r1,r2,r3
;
PRMESGAUX:
	push	r3
	mov		r3,r1		; y = pointer
PRMESGA1:
	add		r3,r3,#2
	ldwu	r1,-2[r3]		; 	get the char.
	beq		r1,r0,PRMRETA
	call	GOAUXO		;else display it
	bra		PRMESGA1
PRMRETA:
	mov		r1,r3
	pop		r3
	ret

;*****************************************************
; The following routines are the only ones that need *
; to be changed for a different I/O environment.     *
;*****************************************************


; ===== Output character to the console (Port 1) from register r1
;	(Preserves all registers.)
;
OUTC:
	mov		r18,r1
	jmp		_DBGDisplayChar


; ===== Input a character from the console into register R1 (or
;	return Zero status if there's no character available).
;
INCH:
;	call		KeybdCheckForKeyDirect
;	cmp		#0
;	beq		INCH1
	call	_DBGKeybdGetChar
	beq		r1,#-1,INCH1
	ret
INCH1:
	mov		r1,r0	; return a zero for no-char
	ret

;*
;* ===== Input a character from the host into register r1 (or
;*	return Zero status if there's no character available).
;*
AUXIN_INIT:
	sw		r0,INPPTR
	ld		r1,#FILENAME
	ld		r2,#FILEBUF
	ld		r3,#$10000
	call	do_load
	ret

AUXIN:
	push	r2
	ldd		r2,INPPTR
	ldwu	r1,FILEBUF[r2]
	add		r2,r2,#2
	std		r2,INPPTR
	pop		r2
	ret
	
;	call		SerialGetChar
;	cmp		#-1
;	beq		AXIRET_ZERO
;	and		#$7F				;zero out the high bit
;AXIRET:
;	ret
;AXIRET_ZERO:
;	lda		#0
;	ret

; ===== Output character to the host (Port 2) from register r1
;	(Preserves all registers.)
;
AUXOUT_INIT:
	std		r0,OUTPTR
	ret

AUXOUT:
	push	r2
	ldd		r2,OUTPTR
	stw		r1,FILEBUF[r2]
	add		r2,r2,#2
	std		r2,OUTPTR
	pop		r2
	ret

AUXOUT_FLUSH:
	ld		r1,#FILENAME
	ld		r2,#FILEBUF
	ldd		r3,OUTPTR
	call	do_save
	ret

;	jmp		SerialPutChar	; call boot rom routine


_cls
	call	_DBGClearScreen
	call	_DBGHomeCursor
	jmp		FINISH

_wait10
	ret
_getATAStatus
	ret
_waitCFNotBusy
	ret
_rdcf
	jmp		FINISH
rdcf6
	bra		ERROR


; ===== Return to the resident monitor, operating system, etc.
;
//message "BYEBYE"
BYEBYE:
//	call	ReleaseIOFocus
	ldd		r63,OSSP
	ret
 
;	MOVE.B	#228,D7 	return to Tutor
;	TRAP	#14

	align	2
msgInit dw	CR,LINEFD,"DSD9 Tiny BASIC v1.0",CR,LINEFD,"(C) 2017  Robert Finch",CR,LINEFD,LINEFD,0
OKMSG	dw	CR,LINEFD,"OK",CR,LINEFD,0
msgWhat	dw	"What?",CR,LINEFD,0
SRYMSG	dw	"Sorry."
CLMSG	dw	CR,LINEFD,0
msgReadError	dw	"Compact FLASH read error",CR,LINEFD,0
msgNumTooBig	dw	"Number is too big",CR,LINEFD,0
msgDivZero		dw	"Division by zero",CR,LINEFD,0
msgVarSpace     dw  "Out of variable space",CR,LINEFD,0
msgBytesFree	dw	" bytes free",CR,LINEFD,0
msgReady		dw	CR,LINEFD,"Ready",CR,LINEFD,0
msgComma		dw	"Expecting a comma",CR,LINEFD,0
msgLineRange	dw	"Line number too big",CR,LINEFD,0
msgVar			dw	"Expecting a variable",CR,LINEFD,0
msgRNDBad		dw	"RND bad parameter",CR,LINEFD,0
msgSYSBad		dw	"SYS bad address",CR,LINEFD,0
msgInputVar		dw	"INPUT expecting a variable",CR,LINEFD,0
msgNextFor		dw	"NEXT without FOR",CR,LINEFD,0
msgNextVar		dw	"NEXT expecting a defined variable",CR,LINEFD,0
msgBadGotoGosub	dw	"GOTO/GOSUB bad line number",CR,LINEFD,0
msgRetWoGosub   dw	"RETURN without GOSUB",CR,LINEFD,0
msgTooBig		dw	"Program is too big",CR,LINEFD,0
msgExtraChars	dw	"Extra characters on line ignored",CR,LINEFD,0

	align	2
LSTROM	equ	*		; end of possible ROM area
;	END

;*
;* ===== Return to the resident monitor, operating system, etc.
;*
;BYEBYE:
;	jmp		Monitor
;    MOVE.B	#228,D7 	;return to Tutor
;	TRAP	#14

