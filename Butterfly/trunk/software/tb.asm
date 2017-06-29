;****************************************************************;
;                                                                ;
;		Tiny BASIC for the Finitron Butterfly                    ;
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
; Adapted to the Butterfly by:                                    ;
;    Robert Finch                                                ;
;    Ontario, Canada                                             ;
;	 rob<remove>@finitron.ca                                     ;  
;****************************************************************;
;    Copyright (C) 2005 by Robert Finch. This program may be	 ;
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

;	OPT	FRS,BRS 	forward ref.'s & brnches default to short

;XMIT_FULL		equ	0x40		; the transmit buffer is full
;DATA_PRESENT	equ	0x08		; there is data preset at the serial port bc_uart3
DATA_PRESENT	equ	0x01		; there is data preset at the serial port bc_uart3
XMIT_NOT_FULL	equ	0x20

TS_TIMER	equ		0xFFFFDC40		; system time slice timer
KBD			equ		0xFFFFDC50

RAND		equ		0xFFFFDCA0
VIC			equ		0xFFFFD800

VIDEORAM	equ		0x00002000

; BOOT ROM routines

getSerial	equ		0xFFFFFF804	; get a serial port character
peekSerial	equ		0xFFFFFF808	; get a serial port character
putSerial	equ		0xFFFFFF80C	; put a character to serial port
getKbdCharWait	equ	0xFFFFFF840
getKbdChar		equ	0xFFFFFF844

warmStart   equ     0x20
usrJmp      equ     0x24

CR		equ	0x0D		; ASCII equates
LF		equ	0x0A
TAB		equ	0x09
CTRLC	equ	0x03
CTRLH	equ	0x08
CTRLS	equ	0x13
CTRLX	equ	0x18

BUFLEN	equ	80	;	length of keyboard input buffer

	code
;	org	0xC000	;
;
; Standard jump table. You can change these addresses if you are
; customizing this interpreter for a different environment.
;
START	jmp	CSTART	;	Cold Start entry point
GOWARM	jmp	WSTART	;	Warm Start entry point
GOOUT	jmp	OUTC	;	Jump to character-out routine
GOIN	jmp	INC		;Jump to character-in routine
GOAUXO	jmp	AUXOUT	;	Jump to auxiliary-out routine
GOAUXI	jmp	AUXIN	;	Jump to auxiliary-in routine
GOBYE	jmp	BYEBYE	;	Jump to monitor, DOS, etc.
;
; Modifiable system constants:
;
TXTBGN	dw	0x0600		;beginning of program memory
ENDMEM	dw	0x1E00	;	end of available memory
;
; The main interpreter starts here:
;
; Usage
; r1 = temp
; r8 = text buffer pointer
; r12 = end of text in text buffer
;
CSTART
	lw		r1,#6
	sb		r1,LEDS
	; First save off the link register and OS sp value
	sub		sp,sp,#4
	sw		lr,[sp]
	sw		sp,OSSP
	lw		sp,ENDMEM	; initialize stack pointer
	sw      lr,[sp]    ; save off return address
;	lw		r1,#TXT_WIDTH
;	sb		r1,txtWidth
;	lw		r1,#TXT_HEIGHT
;	sb		r1,txtHeight
	sb		r0,cursx	; set screen output
	sb		r0,cursy
	sb		r0,cursFlash
	sw		r0,pos
;	lw		r2,#0xBF20	; black chars, yellow background
;	sw		r2,charToPrint
;	call	ClearScreen
;	lea		r1,msgInit	;	tell who we are
;	call	PRMESGAUX
	lea		r1,msgInit	;	tell who we are
	call	PRMESG
	lw		r1,TXTBGN	;	init. end-of-program pointer
	sw		r1,TXTUNF
	lw		r1,ENDMEM	;	get address of end of memory
	sub		r1,r1,#512	; 	reserve 512 bytes for the stack
	sw		r1,STKBOT
	sub     r1,r1,#512 ;   128 vars
	sw      r1,VARBGN
	call    clearVars   ; clear the variable area
	lw      r1,VARBGN   ; calculate number of bytes free
	lw		r3,TXTUNF
	sub     r1,r3
	lw		r2,#0
	call	PRTNUM
	lw		r1,#7
	sb		r1,LEDS
	lea		r1,msgBytesFree
	call	PRMESG
WSTART
	sw		r0,LOPVAR   ; initialize internal variables
	sw		r0,STKGOS
	sw		r0,CURRNT	;	current line number pointer = 0
	lw		sp,ENDMEM	;	init S.P. again, just in case
	lea		r1,msgReady	;	display "Ready"
	call	PRMESG
ST3
	lw		r1,#'>'		; Prompt with a '>' and
	call	GETLN		; read a line.
	call	TOUPBUF 	; convert to upper case
	lw		r12,r8		; save pointer to end of line
	lea		r8,BUFFER	; point to the beginning of line
	call	TSTNUM		; is there a number there?
	call	IGNBLK		; skip trailing blanks
	or      r1,r1       ; does line no. exist? (or nonzero?)
	beq		DIRECT		; if not, it's a direct statement
	cmp		r1,#0xFFFF	; see if line no. is <= 16 bits
	bleu	ST2
	lea		r1,msgLineRange	; if not, we've overflowed
	br		ERROR
ST2
    ; ugliness - store a character at potentially an
    ; odd address (unaligned).
	lw		r2,r1       ; r2 = line number
	sb		r2,-2[r8]
	shr		r2,#1
	shr		r2,#1
	shr		r2,#1
	shr		r2,#1
	shr		r2,#1
	shr		r2,#1
	shr		r2,#1
	shr		r2,#1
	sb		r2,-1[r8]	; store the binary line no.
	sub		r8,r8,#2
	call	FNDLN		; find this line in save area
	tsr		r1,sr
	lw		r13,r9		; save possible line pointer
	trs		r1,sr
	bne		ST4			; if not found, insert
	; here we found the line, so we're replacing the line
	; in the text area
	; first step - delete the line
	lw		r1,#0
	call	FNDNXT		; find the next line (into r9)
	bgtu	ST6			; no more lines
	lw		r1,r9		; r1 = pointer to next line
	lw		r2,r13		; pointer to line to be deleted
	lw		r3,TXTUNF	; points to top of save area
	call	MVUP		; move up to delete
	sw		r2,TXTUNF	; update the end pointer
	; we moved the lines of text after the line being
	; deleted down, so the pointer to the next line
	; needs to be reset
	lw		r9,r13
	br		ST4
	; here there were no more lines, so just move the
	; end of text pointer down
ST6
	sw		r13,TXTUNF
	lw		r9,r13
ST4
	; here we're inserting because the line wasn't found
	; or it was deleted	from the text area
	lw		r1,r12		; calculate the length of new line
	sub		r1,r8
	cmp		r1,#3		; is it just a line no. & CR?
	ble		ST3			; if so, it was just a delete

	lw		r11,TXTUNF	; compute new end of text
	lw		r10,r11		; r10 = old TXTUNF
	add		r11,r1		; r11 = new top of TXTUNF (r1=line length)

	lw		r1,VARBGN	; see if there's enough room
	cmp		r11,r1
	bltu	ST5
	lea		r1,msgTooBig	; if not, say so
	jmp		ERROR

	; open a space in the text area
ST5
	sw		r11,TXTUNF	; if so, store new end position
	lw		r1,r10		; points to old end of text
	lw		r2,r11		; points to new end of text
	lw		r3,r9       ; points to start of line after insert line
	call	MVDOWN		; move things out of the way

	; copy line into text space
	lw		r1,r8		; set up to do the insertion; move from buffer
	lw		r2,r13		; to vacated space
	lw		r3,r12		; until end of buffer
	call	MVUP		; do it
	br		ST3			; go back and get another line


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
TAB1
	db	"LIS",('T'+0x80)        ; Direct commands
	db	"LOA",('D'+0x80)
	db	"NE",('W'+0x80)
	db	"RU",('N'+0x80)
	db	"SAV",('E'+0x80)
TAB2
	db	"NEX",('T'+0x80)         ; Direct / statement
	db	"LE",('T'+0x80)
	db	"I",('F'+0x80)
	db	"GOT",('O'+0x80)
	db	"GOSU",('B'+0x80)
	db	"RETUR",('N'+0x80)
	db	"RE",('M'+0x80)
	db	"FO",('R'+0x80)
	db	"INPU",('T'+0x80)
	db	"PRIN",('T'+0x80)
	db	"POKE",('W'+0x80)
	db	"POK",('E'+0x80)
	db	"STO",('P'+0x80)
	db	"BY",('E'+0x80)
	db	"SY",('S'+0x80)
	db	"CL",('S'+0x80)
    db  "CL",('R'+0x80)
	db	0
TAB4
	db	"NODENU",('M'+0x80)
	db	"PEEK",('W'+0x80)        ;Functions
	db	"PEE",('K'+0x80)         ;Functions
	db	"RN",('D'+0x80)
	db	"AB",('S'+0x80)
	db	"SIZ",('E'+0x80)
	db  "US",('R'+0x80)
	db	0
TAB5
	db	"T",('O'+0x80)           ;"TO" in "FOR"
	db	0
TAB6
	db	"STE",('P'+0x80)         ;"STEP" in "FOR"
	db	0
TAB8
	db	'>',('='+0x80)           ;Relational operators
	db	'<',('>'+0x80)
	db	('>'+0x80)
	db	('='+0x80)
	db	'<',('='+0x80)
	db	('<'+0x80)
	db	0
TAB9
    db  "AN",('D'+0x80)
    db  0
TAB10
    db  "O",('R'+0x80)
    db  0

	.align	4

;* Execution address tables:
TAB1_1
	dw	LISTX			;Direct commands
	dw	LOAD
	dw	NEW
	dw	RUN
	dw	SAVE
TAB2_1
	dw	NEXT		;	Direct / statement
	dw	LET
	dw	IF
	dw	GOTO
	dw	GOSUB
	dw	RETURN
	dw	IF2			; REM
	dw	FOR
	dw	INPUT
	dw	PRINT
	dw	POKEW
	dw	POKE
	dw	STOP
	dw	GOBYE
	dw	SYSX
	dw	_cls
	dw  _clr
	dw	DEFLT
TAB4_1
	dw	NODENUM
	dw  PEEKW
	dw	PEEK			;Functions
	dw	RND
	dw	ABS
	dw	SIZEX
	dw  USRX
	dw	XP40
TAB5_1
	dw	FR1			;"TO" in "FOR"
	dw	QWHAT
TAB6_1
	dw	FR2			;"STEP" in "FOR"
	dw	FR3
TAB8_1
	dw	XP11	;>=		Relational operators
	dw	XP12	;<>
	dw	XP13	;>
	dw	XP15	;=
	dw	XP14	;<=
	dw	XP16	;<
	dw	XP17
TAB9_1
    dw  XP_AND
    dw  XP_ANDX
TAB10_1
    dw  XP_OR
    dw  XP_ORX

;*
; r3 = match flag (trashed)
; r9 = text table
; r10 = exec table
; r11 = trashed
DIRECT
	lea		r9,TAB1
	lea		r10,TAB1_1
EXEC
	lw		r11,lr		; save link reg
	call	IGNBLK		; ignore leading blanks
	lw		lr,r11		; restore link reg
	lw		r11,r8		; save the pointer
	lw		r3,#0		; clear match flag
EXLP
	lb		r1,[r8]		; get the program character
	add		r8,r8,#1
	lb		r2,[r9]		; get the table character
	bne		EXNGO		; If end of table,
	lw		r8,r11		;	restore the text pointer and...
	br		EXGO		;   execute the default.
EXNGO
	cmp		r1,r3		; Else check for period...
	beq		EXGO		; if so, execute
	and		r2,#0x7f	; ignore the table's high bit
	cmp		r2,r1		;		is there a match?
	beq		EXMAT
	add		r10,r10,#4	;if not, try the next entry
	lw		r8,r11		; reset the program pointer
	lw		r3,#0		; sorry, no match
EX1
	add		r9,r9,#1
	lb		r1,-1[r9]	; get to the end of the entry
	bpl		EX1
	br		EXLP		; back for more matching
EXMAT
	lw		r3,#'.'		; we've got a match so far
	add		r9,r9,#1
	lb		r1,-1[r9]	; end of table entry?
	bpl		EXLP		; if not, go back for more
EXGO
	lb		r1,ROUTER+RTR_RXSTAT
	beq		EXGO1
	call	Recv
	call	RecvDispatch
EXGO1
	lw		r11,[r10]	; execute the appropriate routine
	jmp		[r11]


;    lb      r1,[r8]     ; get token from text space
;    bpl
;    and     r1,#0x7f
;    shl     r1,#2       ; * 4 - word offset
;    add     r1,r1,#TAB1_1
;    lw      r1,[r1]
;    jmp     [r1]

    
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
; 'STOP<CR>' goes back to WSTART
;
; 'RUN<CR>' finds the first stored line, stores its address
; in CURRNT, and starts executing it. Note that only those
; commands in TAB2 are legal for a stored program.
;
; RUN ON <node number> sends a run command to the specified node
;
; There are 3 more entries in 'RUN':
; 'RUNNXL' finds next line, stores it's address and executes it.
; 'RUNTSL' stores the address of this line and executes it.
; 'RUNSML' continues the execution on same line.
;
; 'GOTO expr<CR>' evaluates the expression, finds the target
; line, and jumps to 'RUNTSL' to do it.
;
NEW
	call	ENDCHK
	lw		r1,TXTBGN
	sw		r1,TXTUNF	;	set the end pointer
	call    clearVars

STOP
	call	ENDCHK
	br		WSTART		; WSTART will reset the stack

RUN
	call	IGNBLK
	lb		r1,[r8]
	cmp		r1,#'O'
	bne		RUN1
	lb		r1,1[r8]
	cmp		r1,#'N'
	bne		RUN1
	add		r8,r8,#2
	call	OREXPR
	call	zeroTxBuf
	sb		r1,txBuf+MSG_DST
	tsr		r1,ID
	sb		r1,txBuf+MSG_SRC
	lw		r1,#MT_RUN_BASIC_PROG
	sb		r1,txBuf+MSG_TYPE
	call	Xmit
	br		WSTART
RUN1
	call	ENDCHK
	lw		r8,TXTBGN	;	set pointer to beginning
	sw		r8,CURRNT
	call    clearVars

RUNNXL					; RUN <next line>
	lw		r1,CURRNT	; executing a program?
	beq		WSTART		; if not, we've finished a direct stat.
	lw		r1,#0	    ; else find the next line number
	lw		r9,r8
	call	FNDLNP		; search for the next line
	bgtu	WSTART		; if we've fallen off the end, stop

RUNTSL					; RUN <this line>
	sw		r9,CURRNT	; set CURRNT to point to the line no.
	lea		r8,2[r9]	; set the text pointer to

RUNSML                  ; RUN <same line>
	call	CHKIO		; see if a control-C was pressed
	lea		r9,TAB2		; find command in TAB2
	lea		r10,TAB2_1
	br		EXEC		; and execute it

GOTO
	call	OREXPR		;evaluate the following expression
	lw      r5,r1
	call	ENDCHK		;must find end of line
	lw      r1,r5
	call	FNDLN		; find the target line
	beq		RUNTSL		; go do it
	lea		r1,msgBadGotoGosub
	br		ERROR		; no such line no.


_clr
    call    clearVars
    br      FINISH

; Clear the variable area of memory
clearVars
    sub     sp,sp,#4
    sw      lr,[sp]
    sw      r6,2[sp]
    lw      r6,#256		; number of words to clear
    lw      r1,VARBGN
cv1
    sw      r0,[r1]
    add     r1,r1,#2
    sub		r6,r6,#1
    bne     cv1
    lw      lr,[sp]
    lw      r6,2[sp]
    add     sp,sp,#4
    ret    


;******************************************************************
;
; LIST
;
; LISTX has two forms:
; 'LIST<CR>' lists all saved lines
; 'LIST #<CR>' starts listing at the line #
; Control-S pauses the listing, control-C stops it.
;

LISTX
	call	TSTNUM		; see if there's a line no.
	lw      r5,r1
	call	ENDCHK		; if not, we get a zero
	lw      r1,r5
	call	FNDLN		; find this or next line
LS1
	bgtu	WSTART		; warm start if we passed the end

	lw		r1,r9
	call	PRTLN		; print the line
	lw		r9,r1		; set pointer for next
	call	CHKIO		; check for listing halt request
	beq		LS3
	cmp		r1,#CTRLS	; pause the listing?
	bne		LS3
LS2
	call	CHKIO		; if so, wait for another keypress
	beq		LS2
LS3
	lw		r1,#0
	call	FNDLNP		; find the next line
	br		LS1


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
;

PRINT
	lw		r5,#11		; D4 = number of print spaces
	call	TSTC		; if null list and ":"
	db	':',PR2-*+1
	call	CRLF		; give CR-LF and continue
	br		RUNSML		;		execution on the same line
PR2
	call	TSTC		;if null list and <CR>
	db	CR,PR0-*+1
	call	CRLF		;also give CR-LF and
	br		RUNNXL		;execute the next line
PR0
	call	TSTC		;else is it a format?
	db	'#',PR1-*+1
	call	OREXPR		; yes, evaluate expression
	lw		r5,r1		; and save it as print width
	br		PR3		; look for more to print
PR1
	call	TSTC	;	is character expression? (MRL)
	db	'$',PR4-*+1
	call	OREXPR	;	yep. Evaluate expression (MRL)
	call	GOOUT	;	print low byte (MRL)
	br		PR3		;look for more. (MRL)
PR4
	call	QTSTG	;	is it a string?
	; the following branch must occupy only two bytes!
	br		PR8		;	if not, must be an expression
PR3
	call	TSTC	;	if ",", go find next
	db	',',PR6-*+1
	call	FIN		;in the list.
	br		PR0
PR6
	call	CRLF		;list ends here
	br		FINISH
PR8
	call	OREXPR		; evaluate the expression
	lw		r2,r5		; set the width
	call	PRTNUM		; print its value
	br		PR3			; more to print?

FINISH
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
;
GOSUB
	call	PUSHA		; save the current 'FOR' parameters
	call	OREXPR		; get line number
	call	FNDLN		; find the target line
	beq		gosub1
	lea		r1,msgBadGotoGosub
	br		ERROR		; if not there, say "How?"
gosub1
	sub		sp,sp,#6
	sw		r8,[sp]		; save text pointer
	lw		r1,CURRNT
	sw		r1,2[sp]	; found it, save old 'CURRNT'...
	lw		r1,STKGOS
	sw		r1,4[sp]	; and 'STKGOS'
	sw		r0,LOPVAR	; load new values
	sw		sp,STKGOS
	br		RUNTSL


; 'RETURN<CR>' undoes everything that 'GOSUB' did, and thus
; returns the execution to the command after the most recent
; 'GOSUB'.  If 'STKGOS' is zero, it indicates that we never had
; a 'GOSUB' and is thus an error.
;
RETURN
	call	ENDCHK		; there should be just a <CR>
	lw		r1,STKGOS	; get old stack pointer
	bne		return1
	lea		r1,msgRetWoGosub
	br		ERROR		; if zero, it doesn't exist
return1
	lw		sp,r1		; else restore it
	lw		r1,4[sp]
	sw		r1,STKGOS	; and the old 'STKGOS'
	lw		r1,2[sp]
	sw		r1,CURRNT	; and the old 'CURRNT'
	lw		r8,[sp]		; and the old text pointer
	add		sp,sp,#6
	call	POPA		;and the old 'FOR' parameters
	br		FINISH		;and we are back home


;******************************************************************
;
; *** FOR *** & NEXT ***
;
; 'FOR' has two forms:
; 'FOR var=exp1 TO exp2 STEP exp1' and 'FOR var=exp1 TO exp2'
; The second form means the same thing as the first form with a
; STEP of positive 1.  The interpreter will find the variable 'var'
; and set its value to the current value of 'exp1'.  It also
; evaluates 'exp2' and 'exp1' and saves all these together with
; the text pointer, etc. in the 'FOR' save area, which consisits of
; 'LOPVAR', 'LOPINC', 'LOPLMT', 'LOPLN', and 'LOPPT'.  If there is
; already something in the save area (indicated by a non-zero
; 'LOPVAR'), then the old save area is saved on the stack before
; the new values are stored.  The interpreter will then dig in the
; stack and find out if this same variable was used in another
; currently active 'FOR' loop.  If that is the case, then the old
; 'FOR' loop is deactivated. (i.e. purged from the stack)
;
FOR
	call	PUSHA		; save the old 'FOR' save area
	call	SETVAL		; set the control variable
	sw		r1,LOPVAR	; save its address
	lea		r9,TAB5		; use 'EXEC' to test for 'TO'
	lea		r10,TAB5_1
	jmp		EXEC
FR1
	call	OREXPR		; evaluate the limit
	sw		r1,LOPLMT	; save that
	lea		r9,TAB6		; use 'EXEC' to look for the
	lea		r10,TAB6_1	; word 'STEP'
	jmp		EXEC
FR2
	call	OREXPR		; found it, get the step value
	br		FR4
FR3
	lw		r1,#1		; not found, step defaults to 1
FR4
	sw		r1,LOPINC	; save that too

FR5
	lw		r2,CURRNT
	sw		r2,LOPLN	; save address of current line number
	sw		r8,LOPPT	; and text pointer


	lw		r3,sp		; dig into the stack to find 'LOPVAR'
	lw		r6,LOPVAR
	br		FR7
FR6
	lea		r3,10[r3]	; look at next stack frame
FR7
	lw		r2,[r3]		; is it zero?
	beq		FR8			; if so, we're done
	cmp		r2,r6		; same as current LOPVAR?
	bne		FR6			; nope, look some more

    lw      r1,r3       ; Else remove 5 words from...
	lea		r2,10[r3]   ; inside the stack.
	lw		r3,sp		
	call	MVDOWN
	add		sp,sp,#10	; set the SP 5 words up
FR8
    br	    FINISH		; and continue execution


; 'NEXT var' serves as the logical (not necessarily physical) end
; of the 'FOR' loop.  The control variable 'var' is checked with
; the 'LOPVAR'.  If they are not the same, the interpreter digs in
; the stack to find the right one and purges all those that didn't
; match.  Either way, it then adds the 'STEP' to that variable and
; checks the result with against the limit value.  If it is within
; the limit, control loops back to the command following the
; 'FOR'.  If it's outside the limit, the save area is purged and
; execution continues.
;
NEXT
	lw		r1,#0		; don't allocate it
	call	TSTV		; get address of variable
	bne		NX4
	lea		r1,msgNextVar
	br		ERROR		; if no variable, say "What?"
NX4
	lw		r9,r1		; save variable's address
NX0
	lw		r1,LOPVAR	; If 'LOPVAR' is zero, we never...
	bne		NX5         ; had a FOR loop
	lea		r1,msgNextFor
	br		ERROR		
NX5
	cmp		r1,r9		; else we check them
	beq		NX2			; OK, they agree
	call	POPA		; nope, let's see the next frame
	br		NX0
NX2
	lw		r1,[r9]		; get control variable's value
	lw		r2,LOPINC
	add		r1,r2		; add in loop increment
;	BVS.L	QHOW		say "How?" for 32-bit overflow
	sw		r1,[r9]		; save control variable's new value
	lw		r3,LOPLMT	; get loop's limit value
	or		r2,r2       ; check loop increment
	bpl		NX1			; branch if loop increment is positive
	cmp		r1,r3		; test against limit
	blt		NXPurge
	br      NX3
NX1
	cmp		r1,r3
	bgt		NXPurge
NX3	
	lw		r8,LOPLN	; Within limit, go back to the...
	sw		r8,CURRNT
	lw		r8,LOPPT	; saved 'CURRNT' and text pointer.
	br		FINISH

NXPurge
    call    POPA        ; purge this loop
    br      FINISH


;******************************************************************
;
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
;
IF
    call	OREXPR		; evaluate the expression
IF1
    or      r1,r1       ; is it zero?
    bne	    RUNSML		; if not, continue
IF2
    lw		r9,r8		; set lookup pointer
	lw		r1,#0		; find line #0 (impossible)
	call	FNDSKP		; if so, skip the rest of the line
	bgtu	WSTART		; if no next line, do a warm start
IF3
	br		RUNTSL		; run the next line


; INPUT is called first and establishes a stack frame
INPERR
	lw		sp,STKINP	; restore the old stack pointer
	lw		r8,4[sp]
	sw		r8,CURRNT	; and old 'CURRNT'
	lw		r8,2[sp]	; and old text pointer
	add		sp,sp,#10	; fall through will subtract 10

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
INPUT
	sub		sp,sp,#10	; allocate stack frame
	sw      r5,8[sp]
IP6
	sw		r8,[sp]		; save in case of error
	call	QTSTG		; is next item a string?
	br		IP2			; nope - this branch must take only two bytes
	lw		r1,#1		; allocate var
	call	TSTV		; yes, but is it followed by a variable?
	beq     IP4		    ; if not, brnch
	lw		r10,r1		; put away the variable's address
	br		IP3			; if so, input to variable
IP2
	sw		r8,2[sp]	; save for 'PRTSTG'
	lw		r1,#1
	call	TSTV		; must be a variable now
	bne		IP7
	lea		r1,msgInputVar
	br		ERROR		; "What?" it isn't?
IP7
	lw		r10,r1		; put away the variable's address
	lb		r5,[r8]		; get ready for 'PRTSTG' by null terminating
	sb		r0,[r8]
	lw		r1,2[sp]	; get back text pointer
	call	PRTSTG		; print string as prompt
	sb		r5,[r8]		; un-null terminate
IP3
	sw		r8,2[sp]	; save in case of error
	lw		r1,CURRNT
	sw		r1,4[sp]	; also save 'CURRNT'
	lw		r1,#-1
	sw		r1,CURRNT	; flag that we are in INPUT
	sw		sp,STKINP	; save the stack pointer too
	sw		r10,6[sp]	; save the variable address
	lw		r1,#':'		; print a colon first
	call	GETLN		; then get an input line
	lea		r8,BUFFER	; point to the buffer
	call	OREXPR		; evaluate the input
	lw		r10,6[sp]	; restore the variable address
	sw		r1,[r10]	; save value in variable
	lw		r1,4[sp]	; restore old 'CURRNT'
	sw		r1,CURRNT
	lw		r8,2[sp]	; and the old text pointer
IP4
	call	TSTC		; is the next thing a comma?
	db	',',IP5-*+1
	br		IP6			; yes, more items
IP5
    lw      r5,8[sp]
	add		sp,sp,#10	; clean up the stack
	jmp		FINISH


DEFLT
    lb      r1,[r8]
    cmp     r1,#CR      ; empty line is OK
	beq	    FINISH	    ; else it is 'LET'


; 'LET' is followed by a list of items separated by commas.
; Each item consists of a variable, an equals sign, and an
; expression.  The interpreter evaluates the expression and sets
; the variable to that value.  The interpreter will also handle
; 'LET' commands without the word 'LET'.  This is done by 'DEFLT'.
;
LET
    call	SETVAL		; do the assignment
	call	TSTC		; check for more 'LET' items
	db	',',LT1-*+1
	br	    LET
LT1
    br	    FINISH		; until we are finished.


;******************************************************************
;
; *** LOAD *** & SAVE ***
;
; These two commands transfer a program to/from an auxiliary
; device such as a cassette, another computer, etc.  The program
; is converted to an easily-stored format: each line starts with
; a colon, the line no. as 4 hex digits, and the rest of the line.
; At the end, a line starting with an '@' sign is sent.  This
; format can be read back with a minimum of processing time by
; the Butterfly.
;
LOAD
	lw		r8,TXTBGN	; set pointer to start of prog. area
	lw		r1,#CR		; For a CP/M host, tell it we're ready...
	call	GOAUXO		; by sending a CR to finish PIP command.
LOD1
	call	GOAUXI		; look for start of line
	bmi		LOD1
	cmp		r1,#'@'		; end of program?
	beq		LODEND
	cmp     r1,#0x1A    ; or EOF marker
	beq     LODEND
	cmp		r1,#':'		; if not, is it start of line?
	bne		LOD1		; if not, wait for it
	call	GCHAR		; get line number
	sb		r1,[r8]		; store it
	shr		r1,#1
	shr		r1,#1
	shr		r1,#1
	shr		r1,#1
	shr		r1,#1
	shr		r1,#1
	shr		r1,#1
	shr		r1,#1
	sb		r1,1[r8]
	add		r8,r8,#2
LOD2
	call	GOAUXI		; get another text char.
	bmi		LOD2
	sb		r1,[r8]
	add		r8,r8,#1	; store it
	cmp		r1,#CR		; is it the end of the line?
	bne		LOD2		; if not, go back for more
	br		LOD1		; if so, start a new line
LODEND
	sw		r8,TXTUNF	; set end-of program pointer
	br		WSTART		; back to direct mode

; get character from input (16 bit value)
GCHAR
	sub		sp,sp,#6
	sw		lr,[sp]
	sw		r5,2[sp]
	sw		r6,4[sp]
	lw      r6,#4       ; repeat four times
	lw		r5,#0
GCHAR1
	call	GOAUXI		; get a char
	bmi		GCHAR1
	call	asciiToHex
	shl		r5,#1
	shl		r5,#1
	shl		r5,#1
	shl		r5,#1
	or		r5,r1
	sub		r6,r6,#1
	bne     GCHAR1
	lw		r1,r5
	lw		lr,[sp]
	lw		r5,2[sp]
	lw		r6,4[sp]
	add     sp,sp,#6
	ret

; convert an ascii char to hex code
; input
;	r2 = char to convert

asciiToHex
	cmp		r1,#'9'
	ble		a2h1		; less than '9'
	sub		r1,r1,#7	; shift 'A' to '9'+1
a2h1
	sub		r1,r1,#'0'	;
	and		r1,#15		; make sure a nybble
	ret

;----------------------------------------------------------------------------
; SAVE
; SAVE ON <node number> - copies the code to the specified node
;----------------------------------------------------------------------------

SAVE
	call	IGNBLK		; ignore blanks
	lb		r1,[r8]
	cmp		r1,#'O'
	bne		SAVE3
	lb		r1,1[r8]
	cmp		r1,#'N'
	beq		SAVEON1
SAVE3:
	lw		r8,TXTBGN	;set pointer to start of prog. area
	lw		r9,TXTUNF	;set pointer to end of prog. area
SAVE1
	call    AUXOCRLF    ; send out a CR & LF (CP/M likes this)
	cmp		r8,r9		; are we finished?
	bgeu	SAVEND
SAVE4:
	lw		r1,#':'		; if not, start a line
	call	GOAUXO
	lb		r1,[r8]		; get line number
	zxb		r1
	lb		r2,1[r8]
	zxb		r2
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	or		r1,r2
	add		r8,r8,#2
	call	PWORD       ; output line number as 4-digit hex
SAVE2
	lb		r1,[r8]		; get a text char.
	add		r8,r8,#1
	cmp		r1,#CR		; is it the end of the line?
	beq		SAVE1		; if so, send CR & LF and start new line
	call	GOAUXO		; send it out
	br		SAVE2		; go back for more text
SAVEND
	lw		r1,#'@'		; send end-of-program indicator
	call	GOAUXO
	call    AUXOCRLF    ; followed by a CR & LF
	lw		r1,#0x1A	; and a control-Z to end the CP/M file
	call	GOAUXO
	br		WSTART		; then go do a warm start

; Copy program to specified node. Transfers six bytes at a time per
; network message.

SAVEON1
	add		r8,r8,#2
	call	OREXPR		; get core #
	sb		r1,tgtNode
	call	TriggerTgtLoad
	lw		r8,TXTBGN	;set pointer to start of prog. area
	lw		r9,TXTUNF	;set pointer to end of prog. area
SAVEON3:
	cmp		r8,r9
	bgeu	SAVEON2
	lw		r1,[r8]
	sw		r1,txBuf
	lw		r1,2[r8]
	sw		r1,txBuf+2
	lw		r1,4[r8]
	sw		r1,txBuf+4
	tsr		r1,ID
	sb		r1,txBuf+MSG_SRC
	lb		r1,tgtNode
	sb		r1,txBuf+MSG_DST
	lw		r1,#MT_LOAD_BASIC_CHAR
	sb		r1,txBuf+MSG_TYPE
	call	Xmit
	add		r8,r8,#6
	br		SAVEON3
SAVEON2:
	br		WSTART

; output a CR LF sequence to auxillary output
; Registers Affected
;   r3 = LF
AUXOCRLF
    sub     sp,sp,#2
    sw      lr,[sp]
    lw      r1,#CR
    call    GOAUXO
    lw      r1,#LF
    call    GOAUXO
    lw      lr,[sp]
	add		sp,sp,#2
    ret


; output a word in hex format
; tricky because of the need to reverse the order of the chars
PWORD
	sub		sp,sp,#4
	sw		lr,[sp]
	sw		r5,2[sp]
	lea     r5,NUMWKA+3
	lw		r4,r1		; r4 = value
pword1
    lw      r1,r4       ; r1 = value
    shr     r4,#1       ; shift over to next nybble
    shr     r4,#1
    shr     r4,#1
    shr     r4,#1
    call    toAsciiHex  ; convert LS nybble to ascii hex
    sb      r1,[r5]     ; save in work area
    sub     r5,r5,#1
    cmp     r5,#NUMWKA
    bgeu    pword1
pword2
    add     r5,r5,#1
    lb      r1,[r5]     ; get char to output
	call	GOAUXO		; send it
	cmp     r5,#NUMWKA+3
	bltu    pword2

	lw		r5,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret


; convert nybble in r2 to ascii hex char2
; r2 = character to convert

toAsciiHex
	and		r1,#15		; make sure it's a nybble
	cmp		r1,#10		; > 10 ?
	blt		tah1
	add		r1,r1,#7	; bump it up to the letter 'A'
tah1
	add		r1,r1,#'0'	; bump up to ascii '0'
	ret



;******************************************************************
;
; *** POKE *** & SYSX ***
;
; 'POKE expr1,expr2' stores the byte from 'expr2' into the memory
; address specified by 'expr1'.
;
; 'SYSX expr' jumps to the machine language subroutine whose
; starting address is specified by 'expr'.  The subroutine can use
; all registers but must leave the stack the way it found it.
; The subroutine returns to the interpreter by executing an RET.
;
POKE
	sub		sp,sp,#2
	call	OREXPR		; get the memory address
	call	TSTC		; it must be followed by a comma
	db	',',PKER-*+1
	sw		r1,[sp]	    ; save the address
	call	OREXPR		; get the byte to be POKE'd
	lw		r2,[sp]	    ; get the address back
	sb		r1,[r2]		; store the byte in memory
	add		sp,sp,#2
	br		FINISH
PKER
	lea		r1,msgComma
	br		ERROR		; if no comma, say "What?"


POKEW
	sub		sp,sp,#2
	call	OREXPR		; get the memory address
	call	TSTC		; it must be followed by a comma
	db	',',PKER-*+1
	sw		r1,[sp]	    ; save the address
	call	OREXPR		; get the byte to be POKE'd
	lw		r2,[sp]	    ; get the address back
	sw		r1,[r2]		; store the word in memory
	add		sp,sp,#2
	jmp		FINISH


SYSX
	sub		sp,sp,#2
	call	OREXPR		; get the subroutine's address
	or		r0,r1		; make sure we got a valid address
	bne		sysx1
	lea		r1,msgSYSBad
	br		ERROR
sysx1
	sw		r8,[sp]	    ; save the text pointer
	call	[r1]		; jump to the subroutine
	lw		r8,[sp]	    ; restore the text pointer
	add		sp,sp,#2
	br		FINISH


;******************************************************************
;
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
OREXPR
	sub		sp,sp,#4
	sw		lr,[sp]
	call	ANDEXPR		; get first <ANDEXPR>
XP_OR1
	sw		r1,2[sp]	; save <ANDEXPR> value
	lea		r9,TAB10		; look up a logical operator
	lea		r10,TAB10_1
	jmp		EXEC		; go do it

XP_OR
    call    ANDEXPR
    lw      r2,2[sp]
    or      r1,r2
    br      XP_OR1

XP_ORX
	lw		r1,2[sp]
    lw      lr,[sp]
    add     sp,sp,#4
    ret


; <ANDEXPR>::=<EXPR> AND <EXPR> ...
;
ANDEXPR
	sub		sp,sp,#4
	sw		lr,[sp]
	call	EXPR		; get first <EXPR>
XP_AND1
	sw		r1,2[sp]	; save <EXPR> value
	lea		r9,TAB9		; look up a logical operator
	lea		r10,TAB9_1
	jmp		EXEC		; go do it

XP_AND
    call    EXPR
    lw      r2,2[sp]
    and     r1,r2
    br      XP_AND1

XP_ANDX
	lw		r1,2[sp]
    lw      lr,[sp]
    add     sp,sp,#4
    ret


; Determine if the character is a digit
;   Parameters
;       r2 = char to test
;   Returns
;       r1 = 1 if digit, otherwise 0
;
isDigit
    cmp     r1,#'0'
    blt     isDigitFalse
    cmp     r1,#'9'
    bgt     isDigitFalse
    lw      r1,#1
    ret
isDigitFalse
    lw      r1,#0
    ret


; Determine if the character is a alphabetic
;   Parameters
;       r2 = char to test
;   Returns
;       r1 = 1 if alpha, otherwise 0
;
isAlpha
    cmp     r1,#'A'
    blt     isAlphaFalse
    cmp     r1,#'Z'
    ble     isAlphaTrue
    cmp     r1,#'a'
    blt     isAlphaFalse
    cmp     r1,#'z'
    bgt     isAlphaFalse
isAlphaTrue
    lw      r1,#1
    ret
isAlphaFalse
    lw      r1,#0
    ret


; Determine if the character is a alphanumeric
;   Parameters
;       r1 = char to test
;   Returns
;       r1 = 1 if alpha, otherwise 0
;
isAlnum
    sub     sp,sp,#2
    sw      lr,[sp]
    lw      r2,r1		; save test char
    call    isDigit
    bne		isDigitx	; if it is a digit
    lw      r1,r2		; get back test char
    call    isAlpha
    lw      lr,[sp]
    add		sp,sp,#2
    or      r1,r1
    ret
isDigitx
    lw      lr,[sp]
    add     sp,sp,#2	; return Z=0
    ret


EXPR
	sub		sp,sp,#4
	sw		lr,[sp]
	call	EXPR2
	sw		r1,2[sp]	; save <EXPR2> value
	lea		r9,TAB8		; look up a relational operator
	lea		r10,TAB8_1
	jmp		EXEC		; go do it

XP11
	lw		r1,2[sp]
	call	XP18	; is it ">="?
	cmp		r2,r1
	bge		XPRT1	; no, return r2=1
	br		XPRT0	; else return r2=0

XP12
	lw		r1,2[sp]
	call	XP18	; is it "<>"?
	cmp		r2,r1
	bne		XPRT1	; no, return r2=1
	br		XPRT0	; else return r2=0

XP13
	lw		r1,2[sp]
	call	XP18	; is it ">"?
	cmp		r2,r1
	bgt		XPRT1	; no, return r2=1
	br		XPRT0	; else return r2=0

XP14
	lw		r1,2[sp]
	call	XP18	; is it "<="?
	cmp		r2,r1
	ble		XPRT1	; no, return r2=1
	br		XPRT0	; else return r2=0

XP15
	lw		r1,2[sp]
	call	XP18	; is it "="?
	cmp		r2,r1
	beq		XPRT1	; if not, return r2=1
	br		XPRT0	; else return r2=0


XP16
	lw		r1,2[sp]
	call	XP18	; is it "<"?
	cmp		r2,r1
	blt		XPRT1	; if not, return r2=1
	br		XPRT0	; else return r2=0

XPRT0
	lw		lr,[sp]
	add		sp,sp,#4
	lw		r1,#0   ; return r1=0 (false)
	ret

XPRT1
	lw		lr,[sp]
	add		sp,sp,#4
	lw		r1,#1	; return r1=1 (true)
	ret

XP17				; it's not a rel. operator
	lw		r1,2[sp]	; return r2=<EXPR2>
	lw		lr,[sp]
	add		sp,sp,#4
	ret

XP18
	sub		sp,sp,#4
	sw		lr,[sp]
	sw		r1,2[sp]
	call	EXPR2		; do a second <EXPR2>
	lw		r2,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret

; <EXPR2>::=(+ or -)<EXPR3>(+ or -)<EXPR3>(...

EXPR2
	sub		sp,sp,#4
	sw		lr,[sp]
	call	TSTC		; negative sign?
	db	'-',XP21-*+1
	lw		r1,#0		; yes, fake '0-'
	sw		r1,2[sp]
	br		XP26
XP21
	call	TSTC		; positive sign? ignore it
	db	'+',XP22-*+1
XP22
	call	EXPR3		; first <EXPR3>
XP23
	sw		r1,2[sp]	; yes, save the value
	call	TSTC		; add?
	db	'+',XP25-*+1
	call	EXPR3		; get the second <EXPR3>
XP24
	lw		r2,2[sp]
	add		r1,r2		; add it to the first <EXPR3>
;	BVS.L	QHOW		brnch if there's an overflow
	br		XP23		; else go back for more operations
XP25
	call	TSTC		; subtract?
	db	'-',XP45-*+1
XP26
	call	EXPR3		; get second <EXPR3>
	neg		r1			; change its sign
	br		XP24		; and do an addition

XP45
	lw		r1,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret


; <EXPR3>::=<EXPR4>( <* or /><EXPR4> )(...

EXPR3
	sub		sp,sp,#4
	sw		lr,[sp]
	call	EXPR4		; get first <EXPR4>
XP31
	sw		r1,2[sp]	; yes, save that first result
	call	TSTC		; multiply?
	db	'*',XP34-*+1
	call	EXPR4		; get second <EXPR4>
	lw		r2,2[sp]
	call	MULT32		; multiply the two
	br		XP31		 ; then look for more terms
XP34
	call	TSTC		; divide?
	db	'/',XP47-*+1
	call	EXPR4		; get second <EXPR4>
	lw      r2,r1
	lw		r1,2[sp]
	call	DIV32		; do the division
	br		XP31		; go back for any more terms

XP47
	lw		r1,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret


; Functions are called through EXPR4
; <EXPR4>::=<variable>
;	    <function>
;	    (<EXPR>)

EXPR4
    sub     sp,sp,#6
    sw      lr,[sp]
	lea		r9,TAB4		; find possible function
	lea		r10,TAB4_1
	jmp		EXEC        ; branch to function which does subsequent
	                    ; ret for EXPR4

XP40                    ; we get here if it wasn't a function
	lw		r1,#0
	call	TSTV		
	beq     XP41        ; nor a variable
	lw		r1,[r1]		; if a variable, return its value in r1
	lw      lr,[sp]
	add     sp,sp,#6
	ret
XP41
	call	TSTNUM		; or is it a number?
	or		r3,r3		; (if not, # of digits will be zero)
	bne		XP46		; if so, return it in r1
	call    PARN        ; check for (EXPR)
XP46
	lw      lr,[sp]
	add     sp,sp,#6
	ret


; Check for a parenthesized expression
PARN
	sub		sp,sp,#2
	sw		lr,[sp]
	call	TSTC		; else look for ( OREXPR )
	db	'(',XP43-*+1
	call	OREXPR
	call	TSTC
	db	')',XP43-*+1
XP42
	lw		lr,[sp]
	add		sp,sp,#2
	ret
XP43
	lea		r1,msgWhat
	br		ERROR


; ===== Test for a valid variable name.  Returns Z=1 if not
;	found, else returns Z=0 and the address of the
;	variable in r1.
; Parameters
;	r1 = 1 = allocate if not found
; Returns
;	r1 = address of variable, zero if not found

TSTV
	sub		sp,sp,#6
	sw		lr,[sp]
	sw		r5,2[sp]
	lw		r5,r1		; allocate flag
	call	IGNBLK
	lb		r1,[r8]		; look at the program text
	cmp     r1,#'@'
	blt     tstv_notfound   ; C=1: not a variable
	bne		TV1			; brnch if not "@" array
	add		r8,r8,#1	; If it is, it should be
	call	PARN		; followed by (EXPR) as its index.
	shl     r1,#1
	shl     r1,#1
;	BCS.L	QHOW		say "How?" if index is too big
    sw      r1,4[sp]    ; save the index
    sub		sp,sp,#12
    sw		lr,[sp]
	call	SIZEX		; get amount of free memory
	lw      r2,4[sp]    ; get back the index
	cmp     r2,r1       ; see if there's enough memory
	bltu	TV2
	jmp    	QSORRY		; if not, say "Sorry"
TV2
	lw      r1,VARBGN   ; put address of array element...
	sub     r1,r2       ; into r1 (neg. offset is used)
	br      TSTVRT
TV1	
    call    getVarName      ; get variable name
    beq     tstv_notfound   ; if not, set Z=1 and return
    lw		r2,r5
    call    findVar     ; find or allocate
    beq		tstv_notfound
TSTVRT
	lw		r5,2[sp]
	lw		lr,[sp]
	add		sp,sp,#6    ; Z=0 (found)
	ret
tstv_notfound
	lw		r5,2[sp]
    lw      lr,[sp]
    add     sp,sp,#6
    lw      r1,#0       ; Z=1 if not found
    ret


; Returns
;   r3,r1 = 3 character variable name + type
;
getVarName
    sub     sp,sp,#8
    sw      lr,[sp]
    sw		r5,6[sp]

    lb      r1,[r8]     ; get first character
    sw		r1,2[sp]	; save off current name
	sw		r3,4[sp]
    call    isAlpha
    beq     gvn1
    lw      r5,#2       ; loop twice more

	; check for second/third character
gvn4
	add     r8,r8,#1
	lb      r1,[r8]     ; do we have another char ?
	call    isAlnum
	beq     gvn2        ; nope
	lw      r1,2[sp]    ; get varname
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	shl     r1,#1       ; shift left by eight
	rol		r3,#1
	lb      r2,[r8]
	or      r1,r2       ; add in new char
    sw      r1,2[sp]   ; save off name again
	sw		r3,4[sp]
    sub		r5,r5,#1
    bne     gvn4

    ; now ignore extra variable name characters
gvn6
    add     r8,r8,#1
    lb      r1,[r8]
    call    isAlnum
    bne     gvn6        ; keep looping as long as we have identifier chars
    
    ; check for a variable type
gvn2
	lb		r1,[r8]
    cmp     r1,#'%'
    beq     gvn3
    cmp     r1,#'$'
    beq     gvn3
    lw      r1,#0
    sub     r8,r8,#1

    ; insert variable type indicator and return
gvn3
    add     r8,r8,#1
    lw      r2,2[sp]
	lw		r3,4[sp]
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    shl     r2,#1
	rol		r3,#1
    or      r1,r2       ; add in variable type
    lw      lr,[sp]
    lw		r5,4[sp]
    add     sp,sp,#6   ; return Z = 0, r3,r1 = varname
    ret

    ; not a variable name
gvn1
    lw      lr,[sp]
    lw		r5,6[sp]
    add     sp,sp,#8
    lw      r1,#0       ; return Z = 1 if not a varname
    ret


; Find variable
;   r3,r1 = varname
;	r2 = allocate flag
; Returns
;   r1 = variable address, Z =0 if found / allocated, Z=1 if not found

findVar
    sub     sp,sp,#6
    sw      lr,[sp]
    sw      r7,2[sp]
	sw		r12,4[sp]
    lw      r12,VARBGN
fv4
    lw      r7,[r12]     ; get varname / type
    beq     fv3         ; no more vars ?
    cmp     r3,r7       ; match ?
	bne		fv5
	lw		r7,2[r12]
	cmp		r1,r7
    beq     fv1
fv5
    add     r12,r12,#8    ; move to next var
    lw      r7,STKBOT
    cmp     r12,r7
    blt     fv4         ; loop back to look at next var

    ; variable not found
    ; no more memory
    lea     r1,msgVarSpace
    br      ERROR
;    lw      lr,[sp]
;    lw      r7,2[sp]
;    add     sp,sp,#4
;    lw      r1,#0
;    ret

    ; variable not found
    ; allocate new ?
fv3
	or		r2,r2
	beq		fv2
    sw      r3,[r12]     ; save varname / type
	sw		r1,2[r12]
    ; found variable
    ; return address
fv1
    add     r1,r12,#4
    lw      lr,[sp]
    lw      r7,2[sp]
	lw		r12,4[sp]
    add     sp,sp,#6    ; Z = 0, r1 = address
    ret

    ; didn't find var and not allocating
fv2
    lw      lr,[sp]
    lw      r7,2[sp]
	lw		r12,4[sp]
    add     sp,sp,#6    ; Z = 0, r1 = address
	lw		r1,#0		; Z = 1, r1 = 0
    ret


; ===== Multiplies the 32 bit values in r1 and r2, returning
;	the 32 bit result in r1.
;

MULT32
	sub		sp,sp,#6
	sw		r5,[sp]		; w
	sw		r6,2[sp]	; s
	sw		r7,4[sp]

	lw		r5,#0		; w = 0;
	lw		r6,r1
	xor		r6,r2		; s = a ^ b
	or		r1,r1
	bpl		mult1
	neg		r1
mult1
	or		r2,r2
	bpl		mult2
	neg		r2
mult2
	lw		r7,r1
	and		r7,#1
	beq		mult3
	add		r5,r2		; w += b
mult3
	shl		r2,#1		; b <<= 1
	shr		r1,#1		; a >>= 1
	bne		mult2       ; a = 0 ?
mult4
    or      r6,r6
	bpl		mult5
	neg		r5
mult5
	lw		r1,r5
	lw		r7,4[sp]
	lw		r6,2[sp]
	lw		r5,[sp]
	add		sp,sp,#6
	ret


; ===== Divide the 32 bit value in r2 by the 32 bit value in r3.
;	Returns the 32 bit quotient in r1, remainder in r2
;
; r2 = a
; r3 = b
; r6 = remainder
; r7 = iteration count
; r8 = sign
;

; q = a / b
; a = r1
; b = r2
; q = r2

DIV32
    or      r2,r2       ; check for divide-by-zero
    bne		div6
    lea		r1,msgDivZero
    br		ERROR		; divide by zero error
div6
	sub		sp,sp,#8
	sw		r6,[sp]
	sw		r7,2[sp]
	sw		r8,4[sp]
	sw		r9,6[sp]

    lw      r8,#16      ; iteration count for 16 bits
	lw		r9,#0		; q = 0
	lw		r6,#0		; r = 0
    lw      r7,r2       ; r7 = sign of result
    xor     r7,r1
	or	    r1,r1	    ; take absolute value of r1 (a)
	bpl     div1
	neg     r1
div1
    or      r2,r2	    ; take absolute value of r2 (b)
	bpl	    div2
	neg     r2
div2
	shl		r9,#1		; q <<= 1
	shl		r1,#1		; a <<= 1
	adc		r6,r6		; r <<= 1
	cmp		r2,r6		; b < r ?
	bgtu	div4
	sub		r6,r2		; r -= b
	or      r9,#1       ; q |= 1
div4
	sub		r8,r8,#1
    bne     div2        ; n--
	or      r7,r7
	bpl     div5
	neg     r1
div5
	mov		r2,r6		; r2 = r
	mov		r1,r9
	lw		r6,[sp]
	lw		r7,2[sp]
	lw		r8,4[sp]
	lw		r9,6[sp]
	add		sp,sp,#8
	ret

; ===== The PEEK function returns the byte stored at the address
;	contained in the following expression.
;
PEEK
	call	PARN		; get the memory address
	lb		r1,[r1]		; get the addressed byte
	zxb		r1			; upper 3 bytes will be zero
	lw		lr,[sp]	; and return it
	add		sp,sp,#6
	ret


; ===== The PEEK function returns the byte stored at the address
;	contained in the following expression.
;
PEEKW
	call	PARN		; get the memory address
	and		r1,#-4		; align to word address
	lw		r1,[r1]		; get the addressed word
	lw		lr,[sp]	; and return it
	add		sp,sp,#6
	ret


; user function call
; call the user function with argument in r1
USRX
	call	PARN		; get expression value
	sw		r8,2[sp]	; save the text pointer
	lw      r2,usrJmp   ; get usr vector
	call	[r2]		; jump to the subroutine
	lw		r8,2[sp]	; restore the text pointer
	lw		lr,[sp]
	add		sp,sp,#6
	ret


; ===== The RND function returns a random number from 1 to
;	the value of the following expression in D0.
;
RND
	call	PARN		; get the upper limit
	or		r1,r1		; it must be positive and non-zero
	beq		rnd2
	bmi		rnd1
	lw		r2,r1
	sw		r0,RAND+4	; read command
	lw		r1,RAND		; get a number
	call	modu4		; RND(n)=MOD(number,n)+1
	add		r1,r1,#1
	lw		lr,[sp]
	add		sp,sp,#6
	ret
rnd1
	lea		r1,msgRNDBad
	br		ERROR
rnd2
	sw		r0,RAND+4
	lw		r1,RAND
	lw		lr,[sp]
	add		sp,sp,#6
	ret


; r = a mod b
; a = r2
; b = r3
; r = r1
modu4
	sub		sp,sp,#6
	sw		r5,[sp]
	sw		r6,2[sp]
	sw		r7,4[sp]
	lw      r7,#16		; n = 32
	lw		r5,#0		; w = 0
	lw		r6,#0		; r = 0
mod2
	shl		r1,#1		; a <<= 1
	adc		r6,r6		; r <<= 1
	cmp		r2,r6		; b < r ?
	bgtu	mod1
	sub		r6,r2		; r -= b
mod1
	sub		r7,r7,#1
    bne     mod2        ; n--
	lw		r1,r6
	lw		r5,[sp]
	lw		r6,2[sp]
	lw		r7,4[sp]
	add		sp,sp,#6
	ret



; ===== The ABS function returns an absolute value in r2.
;
ABS
	call	PARN		; get the following expr.'s value
	or		r1,r1
	bpl		abs1
	neg		r1			; if negative, complement it
;	bmi		QHOW		; if still negative, it was too big
abs1
	lw		lr,[sp]
	add		sp,sp,#6
	ret


; ===== The SGN function returns the sign in r1. +1,0, or -1
;
SGN
	call	PARN		; get the following expr.'s value
	or		r1,r1
	beq		sgn1
	bpl		sgn2
	lw		r1,#-1
	br		sgn1
sgn2
	lw		r1,#1
sgn1
	lw		lr,[sp]
	add		sp,sp,#6
	ret


; ===== The SIZE function returns the size of free memory in r1.
;
SIZEX
	lw		r1,VARBGN	; get the number of free bytes...
	lw		r2,TXTUNF	; between 'TXTUNF' and 'VARBGN'
	sub		r1,r2
	lw		lr,[sp]
	add		sp,sp,#6
	ret					; return the number in r2

; ==== Return the node number that the code is running on
;
NODENUM
	tsr		r1,ID
	lw		lr,[sp]
	add		sp,sp,#6
	ret

;******************************************************************
;
; *** SETVAL *** FIN *** ENDCHK *** ERROR (& friends) ***
;
; 'SETVAL' expects a variable, followed by an equal sign and then
; an expression.  It evaluates the expression and sets the variable
; to that value.
;
; 'FIN' checks the end of a command.  If it ended with ":",
; execution continues.	If it ended with a CR, it finds the
; the next line and continues from there.
;
; 'ENDCHK' checks if a command is ended with a CR. This is
; required in certain commands, such as GOTO, RETURN, STOP, etc.
;
; 'ERROR' prints the string pointed to by A0. It then prints the
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

; returns
; r2 = variable's address
;
SETVAL
    sub     sp,sp,#4
    sw      lr,[sp]
    lw		r1,#1		; allocate var
    call	TSTV		; variable name?
    bne		sv2
   	lea		r1,msgVar
   	br		ERROR 
sv2
	sw      r1,2[sp]    ; save the variable's address
	call	TSTC		; get past the "=" sign
	db	'=',SV1-*+1
	call	OREXPR		; evaluate the expression
	lw      r2,2[sp]    ; get back the variable's address
	sw      r1,[r2]     ; and save value in the variable
	lw		r1,r2		; return r1 = variable address
	lw      lr,[sp]
	add     sp,sp,#4
	ret
SV1
    br	    QWHAT		; if no "=" sign


FIN
	sub		sp,sp,#2
	sw		lr,[sp]
	call	TSTC		; *** FIN ***
	db	':',FI1-*+1
	add		sp,sp,#2	; if ":", discard return address
	br		RUNSML		; continue on the same line
FI1
	call	TSTC		; not ":", is it a CR?
	db	CR,FI2-*+1
	lw		lr,[sp]	; else return to the caller
	add		sp,sp,#2	; yes, purge return address
	br		RUNNXL		; execute the next line
FI2
	lw		lr,[sp]	; else return to the caller
	add		sp,sp,#2
	ret


; Check that there is nothing else on the line
; Registers Affected
;   r1
;
ENDCHK
	sub		sp,sp,#2
	sw		lr,[sp]
	call	IGNBLK
	lb		r1,[r8]
	cmp		r1,#CR		; does it end with a CR?
	beq		ec1
	lea		r1,msgExtraChars
	jmp		ERROR
ec1
	lw		lr,[sp]
	add		sp,sp,#2
	ret


TOOBIG
	lea		r1,msgTooBig
	br		ERROR
QSORRY
    lea     r1,SRYMSG
	br	    ERROR
QWHAT
	lea		r1,msgWhat
ERROR
	call	PRMESG		; display the error message
	lw		r1,CURRNT	; get the current line number
	beq		WSTART		; if zero, do a warm start
	cmp		r1,#-1		; is the line no. pointer = -1?
	beq		INPERR		; if so, redo input
	lb		r5,[r8]		; save the char. pointed to
	sb		r0,[r8]		; put a zero where the error is
	lw		r1,CURRNT	; point to start of current line
	call	PRTLN		; display the line in error up to the 0
	lw      r6,r1       ; save off end pointer
	sb		r5,[r8]		; restore the character
	lw		r1,#'?'		; display a "?"
	call	GOOUT
	lw      r2,#0       ; stop char = 0
	sub		r1,r6,#1	; point back to the error char.
	call	PRTSTG		; display the rest of the line
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
GETLN
	sub		sp,sp,#4
	sw		lr,[sp]
	sw		r5,2[sp]
	call	GOOUT		; display the prompt
	lw		r1,#1		; turn on cursor flash
	sb		r1,cursFlash
	lw		r1,#' '		; and a space
	call	GOOUT
	lea		r8,BUFFER	; r8 is the buffer pointer
GL1
	call	CHKIO		; check keyboard
	beq		GL1			; wait for a char. to come in
	cmp		r1,#'4'
	beq		GL1
	cmp		r1,#'1'
	beq		GL1
	cmp		r1,#CR		; accept a CR
	beq		GL2
	call	GOOUT
	br		GL1
GL2:
	call	GOOUT		; spit out CR
	lw		r1,#0		; turn off cursor flash
	sb		r1,cursFlash
	lb		r3,cursy
	lb		r5,cursx
	lw		r1,#LF		; echo a LF for the CR
	call	GOOUT
	shl		r3,#1
	lw		r3,lineTbl[r3]
	lw		r2,#0
	lw		r4,#0
GL3:
	lb		r1,TXTSCR[r3]
	call	ScreenToAscii
	sb		r1,BUFFER[r4]
	add		r3,r3,#2
	add		r4,r4,#1
	cmp		r4,#52
	blt		GL3
	lw		r1,#CR
	sb		r1,BUFFER[r5]
	sb		r0,BUFFER+1[r5]
	lw		lr,[sp]
	lw		r5,2[sp]
	add		sp,sp,#4
	ret


; 'FNDLN' finds a line with a given line no. (in r1) in the
; text save area.  r9 is used as the text pointer. If the line
; is found, r9 will point to the beginning of that line
; (i.e. the high byte of the line no.), and flags are Z.
; If that line is not there and a line with a higher line no.
; is found, r9 points there and flags are NC & NZ. If we reached
; the end of the text save area and cannot find the line, flags
; are C & NZ.
; Z=1 if line found
; N=1 if end of text save area
; Z=0 & N=0 if higher line found
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
FNDLN
	cmp		r1,#0xFFFF	; line no. must be < 65535
	bleu	fl1
	lea		r1,msgLineRange
	br		ERROR
fl1
	lw		r9,TXTBGN	; init. the text save pointer

FNDLNP
	lw		r10,TXTUNF	; check if we passed the end
	sub		r10,r10,#1
	cmp		r9,r10
	bgtu	FNDRET		; if so, return with Z=0 & C=1
	lb		r3,[r9]		; get low order byte of line number
	zxb		r3
	lb		r2,1[r9]	; get high order byte
	zxb		r2
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	shl		r2,#1
	or		r2,r3		; build whole line number
	cmp		r1,r2		; is this the line we want?
	bgtu	FNDNXT		; no, not there yet
FNDRET
	ret			; return the cond. codes

FNDNXT
	add		r9,r9,#2	; find the next line

FNDSKP
	lb		r2,[r9]
	add		r9,r9,#1
	cmp		r2,#CR		; try to find a CR
	bne		FNDSKP		; keep looking
	br		FNDLNP		; check if end of text


;******************************************************************
; 'MVUP' moves a block up from where r1 points to where r2 points
; until r1=r3
;
MVUP1
	lb		r4,[r1]
	sb		r4,[r2]
	add		r1,r1,#1
	add		r2,r2,#1
MVUP
	cmp		r1,r3
	bne		MVUP1
MVRET
	ret


; 'MVDOWN' moves a block down from where r1 points to where r2
; points until r1=r3
;
MVDOWN1
	sub		r1,r1,#1
	sub		r2,r2,#1
	lb		r4,[r1]
	sb		r4,[r2]
MVDOWN
	cmp		r1,r3
	bne		MVDOWN1
	ret


; 'POPA' restores the 'FOR' loop variable save area from the stack
;
; 'PUSHA' stacks for 'FOR' loop variable save area onto the stack
;
; Note: a single zero word is stored on the stack in the
; case that no FOR loops need to be saved. This needs to be
; done because PUSHA / POPA is called all the time.

POPA
	lw		r1,[sp]		; restore LOPVAR, but zero means no more
	sw		r1,LOPVAR
	beq		PP1
	lw		r1,8[sp]	; if not zero, restore the rest
	sw		r1,LOPPT
	lw		r1,6[sp]
	sw		r1,LOPLN
	lw		r1,4[sp]
	sw		r1,LOPLMT
	lw		r1,2[sp]
	sw		r1,LOPINC
	add		sp,sp,#10
	ret
PP1
	add		sp,sp,#2
	ret


PUSHA
	lw		r1,STKBOT	; Are we running out of stack room?
	add		r1,r1,#10	; we might need this many bytes
	cmp		sp,r1
	bltu	QSORRY		; out of stack space
	lw		r1,LOPVAR	; save loop variables
	beq		PU1			; if LOPVAR is zero, that's all
	sub		sp,sp,#10
	sw		r1,[sp]
	lw		r1,LOPPT
	sw		r1,8[sp]	; else save all the others
	lw		r1,LOPLN
	sw		r1,6[sp]
	lw		r1,LOPLMT
	sw		r1,4[sp]
	lw		r1,LOPINC
	sw		r1,2[sp]
	ret
PU1
	sub		sp,sp,#2
	sw		r1,[sp]
	ret


;******************************************************************
;
; *** PRTSTG *** QTSTG *** PRTNUM *** PRTLN ***
;
; 'PRTSTG' prints a string pointed to by r3. It stops printing
; and returns to the caller when either a CR is printed or when
; the next byte is the same as what was passed in r4 by the
; caller.
;
; 'QTSTG' looks for an underline (back-arrow on some systems),
; single-quote, or double-quote.  If none of these are found, returns
; to the caller.  If underline, outputs a CR without a LF.  If single
; or double quote, prints the quoted string and demands a matching
; end quote.  After the printing, the next 2 bytes of the caller are
; skipped over (usually a short brnch instruction).
;
; 'PRTNUM' prints the 32 bit number in r3, leading blanks are added if
; needed to pad the number of spaces to the number in r4.
; However, if the number of digits is larger than the no. in
; r4, all digits are printed anyway. Negative sign is also
; printed and counted in, positive sign is not.
;
; 'PRTLN' prints the saved text line pointed to by r3
; with line no. and all.
;

; r1 = pointer to string
; r2 = stop character
; return r1 = pointer to end of line + 1

PRTSTG
    sub     sp,sp,#8
    sw      lr,[sp]
    sw      r5,2[sp]
    sw      r6,4[sp]
    sw      r7,6[sp]
    lw      r5,r1       ; r5 = pointer
    lw      r6,r2       ; r6 = stop char
PS1
    lb      r7,[r5]     ; get a text character
    add     r5,r5,#1
	cmp     r7,r6		; same as stop character?
	beq	    PRTRET		; if so, return
	lw      r1,r7
	call	GOOUT		; display the char.
	cmp     r7,#CR      ; is it a C.R.?
	bne	    PS1		    ; no, go back for more
	lw      r1,#LF      ; yes, add a L.F.
	call	GOOUT
PRTRET
    lw      r2,r7       ; return r2 = stop char
	lw		r1,r5		; return r1 = line pointer
    lw      r5,2[sp]
    lw      r6,4[sp]
    lw      r7,6[sp]
    lw      lr,[sp]
    add     sp,sp,#8
    ret			        ; then return


QTSTG
	sub		sp,sp,#2
	sw		lr,[sp]
	call	TSTC		; *** QTSTG ***
	db	'"',QT3-*+1
	lw		r2,#'"'		; it is a "
QT1
	lw		r1,r8
	call	PRTSTG		; print until another
	lw		r8,r1
	cmp		r2,#LF		; was last one a CR?
	bne		QT2
	add		sp,sp,#2
	br		RUNNXL		; if so, run next line
QT3
	call	TSTC		; is it a single quote?
	db	"'",QT4-*+1
	lw		r2,#''''	; if so, do same as above
	br		QT1
QT4
	call	TSTC		; is it an underline?
	db	'_',QT5-*+1
	lw		r1,#CR		; if so, output a CR without LF
	call	GOOUT
QT2
	lw		lr,[sp]
	add		sp,sp,#2
	jmp		2[lr]		; skip over 2 bytes when returning
QT5						; not " ' or _
	lw		lr,[sp]
	add		sp,sp,#2
	ret


; Output a CR LF sequence
;
prCRLF
	sub		sp,sp,#2
	sw		lr,[sp]
	lw		r1,#CR
	call	GOOUT
	lw		r1,#LF
	call	GOOUT
	lw		lr,[sp]
	add		sp,sp,#2
	ret


; r1 = number to print
; r2 = number of digits
; Register Usage
;	r5 = number of padding spaces
PRTNUM
	sub		sp,sp,#8
	sw		lr,[sp]
	sw		r5,2[sp]
	sw		r6,4[sp]
	sw		r7,6[sp]

	lea		r7,NUMWKA	; r7 = pointer to numeric work area
	lw		r6,r1		; save number for later
	lw		r5,r2		; r5 = min number of chars
	
	or		r1,r1		; is it negative?
	bpl		PN1			; if not
	neg		r1			; else make it positive
	sub		r5,r5,#1	; one less for width count
PN1
	lw		r2,#10		; divide by 10
	call	DIV32
	add		r2,r2,#'0'	; convert remainder to ascii
	sb		r2,[r7]		; and store in buffer
	add		r7,r7,#1
	sub		r5,r5,#1	; decrement width
	cmp		r1,#0
	bne		PN1
PN6
	or		r5,r5		; test pad count
	ble		PN4			; skip padding if not needed
PN3
	lw		r1,#' '		; display the required leading spaces
	call	GOOUT
	sub		r5,r5,#1
	bne		PN3
PN4
	or		r6,r6		; is number negative?
	bpl		PN5
	lw		r1,#'-'		; if so, display the sign
	call	GOOUT
PN5
	sub		r7,r7,#1
	lb		r1,[r7]		; now unstack the digits and display
	call	GOOUT
	cmp		r7,#NUMWKA
	bgtu	PN5
PNRET
	lw		lr,[sp]
	lw		r5,2[sp]
	lw		r6,4[sp]
	lw		r7,6[sp]
	add		sp,sp,#8
	ret


; r1 = number to print
; r2 = number of digits
PRTHEXNUM
	sub		sp,sp,#10
	sw		lr,[sp]
	sw		r5,2[sp]
	sw		r6,4[sp]
	sw		r7,6[sp]
	sw		r8,8[sp]

	lea		r7,NUMWKA	; r7 = pointer to numeric work area
	lw		r6,r1		; save number for later
	lw		r5,#10		; r5 = min number of chars
	lw		r4,r1
	
	or		r4,r4		; is it negative?
	bpl		PHN1		; if not
	neg		r4			; else make it positive
	sub		r5,r5,#1	; one less for width count
	lw		r8,#10		; maximum of 10 digits
PHN1
	lw		r1,r4
	and		r1,#15
	cmp		r1,#10
	blt		PHN7
	add		r1,r1,#'A'-10
	br		PHN8
PHN7
	add		r1,r1,#'0'		; convert remainder to ascii
PHN8
	sb		r1,[r7]		; and store in buffer
	add		r7,r7,#1
	sub		r5,r5,#1	; decrement width
	shr		r4,#1
	shr		r4,#1
	shr		r4,#1
	shr		r4,#1
	beq		PHN6			; is it zero yet ?
	sub		r8,r8,#1	; safety
	bne		PHN1
PHN6
	or		r5,r5		; test pad count
	ble		PHN4			; skip padding if not needed
PHN3
	lw		r1,#' '		; display the required leading spaces
	call	GOOUT
	sub		r5,r5,#1
	bne		PHN3
PHN4
	or		r6,r6		; is number negative?
	bpl		PHN5
	lw		r1,#'-'		; if so, display the sign
	call	GOOUT
PHN5
	sub		r7,r7,#1
	lb		r1,[r7]		; now unstack the digits and display
	call	GOOUT
	cmp		r7,#NUMWKA
	bgtu	PHN5
PHNRET
	lw		lr,[sp]
	lw		r5,2[sp]
	lw		r6,4[sp]
	lw		r7,6[sp]
	lw		r8,8[sp]
	add		sp,sp,#10
	ret


; r1 = pointer to line
; returns r1 = pointer to end of line + 1
PRTLN
    sub     sp,sp,#4
    sw      lr,[sp]
    sw      r5,2[sp]
    add     r5,r1,#2
    lb		r1,-2[r5]	; get the binary line number
    zxb		r1
    lb		r2,-1[r5]
    zxb		r2
    shl		r2,#1
    shl		r2,#1
    shl		r2,#1
    shl		r2,#1
    shl		r2,#1
    shl		r2,#1
    shl		r2,#1
    shl		r2,#1
    or		r1,r2
    lw      r2,#0       ; display a 0 or more digit line no.
	call	PRTNUM
	lw      r1,#' '     ; followed by a blank
	call	GOOUT
	lw      r2,#0       ; stop char. is a zero
	lw      r1,r5
	call    PRTSTG		; display the rest of the line
	lw      r5,2[sp]
	lw      lr,[sp]
	add     sp,sp,#4
	ret


; ===== Test text byte following the call to this subroutine. If it
;	equals the byte pointed to by r8, return to the code following
;	the call. If they are not equal, brnch to the point
;	indicated by the offset byte following the text byte.
;
; Registers Affected
;   r8
; Returns
;	r8 = updated text pointer
;
TSTC
	sub		sp,sp,#6
	sw		lr,[sp]
	sw		r1,2[sp]
	sw		r3,4[sp]
	call	IGNBLK		; ignore leading blanks
	lw		lr,[sp]	; get the return address
	lb		r3,[lr]	; get the byte to compare
	lb		r1,[r8]
	cmp		r3,r1		; is it = to what r8 points to?
	beq		TSTC1			; if so
						; If not, add the second
	lb		r3,1[lr]	; byte following the call to
	add		lr,r3		; the return address.
	lw		r1,2[sp]
	lw		r3,4[sp]
	add		sp,sp,#6
	ret					; jump to the routine
TSTC1
	add		r8,r8,#1	; if equal, bump text pointer
	lw		r1,2[sp]
	lw		r3,4[sp]
	add     sp,sp,#6
	jmp		2[lr]		; Skip the 2 bytes following
						; the call and continue.


; ===== See if the text pointed to by r8 is a number. If so,
;	return the number in r2 and the number of digits in r3,
;	else return zero in r2 and r3.
; Registers Affected
;   r1,r2,r3,r4
; Returns
; 	r1 = number
;	r2 = number high order
;	r3 = number of digits in number
;	r8 = updated text pointer
;
TSTNUM
	sub		sp,sp,#6
	sw		lr,[sp]
	sw		r5,2[sp]
	sw		r6,4[sp]
	;call	GetHexNumber
	;cmp		r3,#0
	;bgtu	TSNMRET
	call	IGNBLK		; skip over blanks
	lw		r1,#0		; initialize return parameters
	lw		r2,#0
	lw		r3,#0
TN1
	lb		r5,[r8]
	cmp		r5,#'0'		; is it less than zero?
	bltu	TSNMRET 	; if so, that's all
	cmp		r5,#'9'		; is it greater than nine?
	bgtu	TSNMRET 	; if so, return
	cmp		r2,#$CCC
	bleu	TN2
;	cmp		r1,#214748364	; see if there's room for new digit
	lea		r1,msgNumTooBig
	br		ERROR		; if not, we've overflowd
TN2
	lw		r4,r1		; quickly multiply result by 10
	lw		r6,r2
	shl		r1,#1		; * 2
	adc		r2,r2
	shl		r1,#1		; * 4
	adc		r2,r2
	add		r1,r4		; * 5
	adc		r2,r6
	shl		r1,#1		; * 10
	adc		r2,r2
	add		r8,r8,#1	; adjust text pointer
	and		r5,#0xF		; add in the new digit
	add		r1,r5
	add		r3,r3,#1	; increment the no. of digits
	br		TN1
TSNMRET
	lw		lr,[sp]
	lw		r5,2[sp]
	lw		r6,4[sp]
	add		sp,sp,#6
	ret

ConvHexDigit:
	cmp		r1,#'0'
	blt		ConvHexDigit1
	cmp		r1,#'9'
	bgt		ConvHexDigit3
	sub		r1,r1,#'0'
	ret
ConvHexDigit3:
	cmp		r1,#'a'
	blt		ConvHexDigit1
	cmp		r1,#'f'
	bgt		ConvHexDigit2
	sub		r1,r1,#'a'
	add		r1,r1,#10
	ret
ConvHexDigit2:
	cmp		r1,#'A'
	blt		ConvHexDigit1
	cmp		r1,#'F'
	bgt		ConvHexDigit1
	sub		r1,r1,#'A'
	add		r1,r1,#10
	ret
ConvHexDigit1:
	lw		r1,#-1
	ret

GetHexNumber:
	sub		sp,sp,#4
	sw		lr,[sp]
	call	IGNBLK		; skip over blanks
	lw		r1,#0		; initialize return parameters
	lw		r2,#0
	lw		r3,#0
	mov		r9,r8
	lb		r4,[r8]
	cmp		r4,#'$'
	bne		GetHexNumberRet
	add		r8,r8,#1
GetHexNumber1
	sw		r1,2[sp]
	lb		r1,[r8]
	call	ConvHexDigit
	bmi		GetHexNumber4
	mov		r4,r1
	lw		r1,2[sp]
	cmp		r2,#$FFF
	bgtu	GetHexNumberErr
GetHexNumber2
	shl		r1,#1
	adc		r2,r2
	shl		r1,#1
	adc		r2,r2
	shl		r1,#1
	adc		r2,r2
	shl		r1,#1
	adc		r2,r2
	or		r1,r4
	mov		r9,r8
	add		r8,r8,#1	; adjust text pointer
	add		r3,r3,#1	; increment the no. of digits
	br		GetHexNumber1
GetHexNumber4:
	lw		r1,2[sp]
GetHexNumberRet:
	mov		r8,r9
	lw		lr,[sp]
	add		sp,sp,#4
	ret
GetHexNumberErr:
	lea		r1,msgNumTooBig
	br		ERROR		; if not, we've overflowd

;===== Skip over blanks in the text pointed to by r8.
;
; Registers Affected:
;	r8
; Returns
;	r8 = pointer updateded past any spaces or tabs
;
IGNBLK
	sub		sp,sp,#2
	sw		r1,[sp]
IGB2
	lb		r1,[r8]			; get char
	cmp		r1,#' '			; see if it's a space
	beq		IGB1			; if so, swallow it
	cmp		r1,#'\t'		; or a tab
	bne		IGBRET
IGB1
	add		r8,r8,#1		; increment the text pointer
	br		IGB2
IGBRET
	lw		r1,[sp]
	add		sp,sp,#2
	ret


; ===== Convert the line of text in the input buffer to upper
;	case (except for stuff between quotes).
;
; Registers Affected
;   r1,r3
; Returns
;	r8 = pointing to end of text in buffer
;
TOUPBUF
	sub		sp,sp,#2
	sw		lr,[sp]
	lea		r8,BUFFER	; set up text pointer
	lw		r3,#0		; clear quote flag
TOUPB1
	lb		r1,[r8]		; get the next text char.
	add		r8,r8,#1
	cmp		r1,#CR		; is it end of line?
	beq		TOUPBRT 	; if so, return
	cmp		r1,#'"'		; a double quote?
	beq		DOQUO
	cmp		r1,#''''	; or a single quote?
	beq		DOQUO
	cmp		r3,#0		; inside quotes?
	bne		TOUPB1		; if so, do the next one
	call	toUpper 	; convert to upper case
	sb		r1,-1[r8]	; store it
	br		TOUPB1		; and go back for more
DOQUO
	cmp		r3,#0		; are we inside quotes?
	bne		DOQUO1
	lw		r3,r1		; if not, toggle inside-quotes flag
	br		TOUPB1
DOQUO1
	cmp		r3,r1		; make sure we're ending proper quote
	bne		TOUPB1		; if not, ignore it
	lw		r3,#0		; else clear quote flag
	br		TOUPB1
TOUPBRT
	lw		lr,[sp]
	add		sp,sp,#2
	ret


; ===== Convert the character in r1 to upper case
;
toUpper
	cmp		r1,#'a'		; is it < 'a'?
	blt	    TOUPRET
	cmp		r1,#'z'		; or > 'z'?
	bgt	    TOUPRET
	sub		r1,r1,#32	; if not, make it upper case
TOUPRET
	ret


; 'CHKIO' checks the input. If there's no input, it will return
; to the caller with the Z flag set. If there is input, the Z
; flag is cleared and the input byte is in r2. However, if a
; control-C is read, 'CHKIO' will warm-start BASIC and will not
; return to the caller.
;
CHKIO
	sub		sp,sp,#2	; save link reg
	sw		lr,[sp]
	call	GOIN		; get input if possible
	beq		CHKRET2		; if Zero, no input
	cmp		r1,#CTRLC	; is it control-C?
	bne		CHKRET		; if not
	jmp		WSTART		; if so, do a warm start
CHKRET
	lw		lr,[sp]
	add		sp,sp,#2	; Z=0
	ret
CHKRET2
	lw		lr,[sp]
	add		sp,sp,#2
	lw		r1,#0		; Z=1
	ret


; ===== Display a CR-LF sequence
;
CRLF
	lea		r1,CLMSG


; ===== Display a zero-ended string pointed to by register r1
; Registers Affected
;   r1,r2,r4
;
PRMESG
	sub		sp,sp,#4
	sw		lr,[sp]
	sw		r5,2[sp]
	lw      r5,r1       ; r5 = pointer to message
PRMESG1
	add		r5,r5,#1
	lb		r1,-1[r5]	; 	get the char.
	beq		PRMRET
	call	GOOUT		;else display it trashes r4
	br		PRMESG1
PRMRET
	lw		r1,r5
	lw		r5,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret


; ===== Display a zero-ended string pointed to by register r1
; Registers Affected
;   r1,r2,r3
;
PRMESGAUX
	sub		sp,sp,#4
	sw		lr,[sp]
	sw		r5,2[sp]
	lw      r5,r1       ; r3 = pointer
PRMESGA1
	add		r5,r5,#1
	lb		r1,-1[r5]	; 	get the char.
	beq		PRMRETA
	call	GOAUXO		;else display it
	br		PRMESGA1
PRMRETA
	lw		r1,r5
	lw		r5,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret

;*****************************************************
; The following routines are the only ones that need *
; to be changed for a different I/O environment.     *
;*****************************************************


; ===== Output character to the console (Port 1) from register D0
;	(Preserves all registers.)
;
OUTC
	add		sp,sp,#-4
	sw		lr,[sp]
	sw		r1,2[sp]
	call	DoPing
	lb		r1,ROUTER+RTR_RXSTAT
	beq		OUTC1
	call	Recv
	call	RecvDispatch
OUTC1
	lw		r1,2[sp]
	call	putcharScr
	lw		lr,[sp]
	add		sp,sp,#4
	ret


; ===== Input a character from the console into register D0 (or
;	return Zero status if there's no character available).
;
; A bit of cooperative multi-tasking here. A check for network
; messages is made.
;
INC
	add		sp,sp,#-2
	sw		lr,[sp]
	lw		r1,TXTSCR+86
	add		r1,r1,#1
	sw		r1,TXTSCR+86
	call	DoPing
	lb		r1,ROUTER+RTR_RXSTAT
	beq		INC1
	call	Recv
	call	RecvDispatch
INC1
	call	kbdGetChar
	beq		INC2
	lw		lr,[sp]
	add		sp,sp,#2
	ret
INC2:
	lw		lr,[sp]
	add		sp,sp,#2
	lw		r1,#0
	ret


; Trigger a load operation on the target node.

TriggerTgtLoad:
	add		sp,sp,#-4
	sw		lr,[sp]
	sw		r2,2[sp]
	call	zeroTxBuf
	lb		r2,tgtNode
	sb		r2,txBuf+MSG_DST
	lw		r2,#MT_START_BASIC_LOAD	; trigger load on target node
	sb		r2,txBuf+MSG_TYPE
	call	Xmit
	lw		r2,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret

; ===== Output character to the host (Port 2) from register r1
;	(Preserves all registers.)
;
AUXOUT
	add		sp,sp,#-2
	sw		lr,[sp]
	call	putSerial	; call boot rom routine
	lw		lr,[sp]
	add		sp,sp,#2
	ret

;
; ===== Input a character from the host into register D0 (or
;	return negative status if there's no character available).
;
AUXIN
; get character from serial port
; return  N=1 if no character available
	jmp		peekSerial


; flash the character at the screen position
;   r1: 1 = flash, 0 = no flash
_flashCursor
	lw		r2,#VIDEORAM
	lh		r3,pos
	shl		r3,#1
	shl		r3,#1
	add		r3,r2		; r3 = scr[pos]

	or		r1,r1
	beq		fc1
	lb		r2,3[r3]	; get background color
	or		r2,#0x80	; set flash indicator
	br		fcx
fc1
	lb		r2,3[r3]	; get background color
	and		r2,#0x7f	; clear flash indicator
fcx:
	sb		r2,3[r3]
	ret


_cls
	call	ClearScreen
	br		FINISH


; ===== Return to the resident monitor, operating system, etc.
;
BYEBYE
	lw		sp,OSSP
    lw      lr,[sp]
    add		sp,sp,#2
	ret

;	MOVE.B	#228,D7 	return to Tutor
;	TRAP	#14

msgInit db	CR,LF,"Butterfly Tiny BASIC v1.1",CR,LF,"(C) 2005-2017  Robert Finch",CR,LF,LF,0
OKMSG	db	CR,LF,"OK",CR,LF,0
msgWhat	db	"What?",CR,LF,0
SRYMSG	db	"Sorry."
CLMSG	db	CR,LF,0
msgReadError	db	"Compact FLASH read error",CR,LF,0
msgNumTooBig	db	"Number is too big",CR,LF,0
msgDivZero		db	"Division by zero",CR,LF,0
msgVarSpace     db  "Out of variable space",CR,LF,0
msgBytesFree	db	" bytes free",CR,LF,0
msgReady		db	CR,LF,"Ready",CR,LF,0
msgComma		db	"Expecting a comma",CR,LF,0
msgLineRange	db	"Line number too big",CR,LF,0
msgVar			db	"Expecting a variable",CR,LF,0
msgRNDBad		db	"RND bad parameter",CR,LF,0
msgSYSBad		db	"SYS bad address",CR,LF,0
msgInputVar		db	"INPUT expecting a variable",CR,LF,0
msgNextFor		db	"NEXT without FOR",CR,LF,0
msgNextVar		db	"NEXT expecting a defined variable",CR,LF,0
msgBadGotoGosub	db	"GOTO/GOSUB bad line number",CR,LF,0
msgRetWoGosub   db	"RETURN without GOSUB",CR,LF,0
msgTooBig		db	"Program is too big",CR,LF,0
msgExtraChars	db	"Extra characters on line ignored",CR,LF,0

	.align	4
LSTROM	equ	*		; end of possible ROM area
;
; Internal variables follow:
;
		bss
txtWidth	db	0		; BIOS var =60
txtHeight	db	0		; BIOS var =27
cursx	db		0		; cursor x position
cursy	db		0		; cursor y position
pos		dw		0		; text screen position
tgtNode	db		0
srcNode	db		0
charToPrint		dw		0
fgColor			db		0
bkColor			db		0
cursFlash		db		0	; flash the cursor ?
				db		0
NormAttr		dw		0

lineLinkTbl		fill.b	25,0	; screen line link table
	align 4

		;org		0x0080
typef   db      0   ; variable / expression type
        align   2
OSSP	dw	1	; OS value of sp
CURRNT	dw	1	;	Current line pointer
STKGOS	dw	1	;	Saves stack pointer in 'GOSUB'
STKINP	dw	1	;	Saves stack pointer during 'INPUT'
LOPVAR	dw	1	;	'FOR' loop save area
LOPINC	dw	1	;	increment
LOPLMT	dw	1	;	limit
LOPLN	dw	1	;	line number
LOPPT	dw	1	;	text pointer
TXTUNF	dw	1	;	points to unfilled text area
VARBGN	dw	1	;	points to variable area
IVARBGN dw  1   ;   points to integer variable area
SVARBGN dw  1   ;   points to string variable area
FVARBGN dw  1   ;   points to float variable area
STKBOT	dw	1	;	holds lower limit for stack growth
NUMWKA	fill.b	50,0			; numeric work area
BUFFER	fill.b	BUFLEN,0x00		;		Keyboard input buffer

        bss
        org     0x2000
textScr1
        org     0x2000
;	END
