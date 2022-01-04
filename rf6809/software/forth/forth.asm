; Fig FORTH ported for the RF6809
;
;                        Through the courtesy of
;
;                         FORTH INTEREST GROUP
;                            P.O. BOX  2154
;                         OAKLAND, CALIFORNIA
;                                94621
;
;
;                             Release 1.1
;
;                        with compiler security
;                                  and
;                        variable length names
;
;    Further distribution must include the above notice.
;    The FIG installation Manual is required as it contains
;    the model of FORTH and glossary of the system.
;    Available from FIG at the above address for **.** postpaid.
;
;    Translated from the FIG model by W.F. Ragsdale with input-
;    output given for the Rockwell System-65. Transportation to
;    other systems requires only the alteration of :
;                 XEMIT, XKEY, XQTER, XCR, AND RSLW
;
;    Equates giving memory assignments, machine
;    registers, and disk parameters.
;
SSIZE     =512           ; sector size in bytes
NBUF      =8             ; number of buffers desired in RAM
;                             (SSIZE*NBUF >= 1024 bytes)
SECTR     =800           ; sector per drive
;                              forcing high drive to zero
SECTL     =1600          ; sector limit for two drives
;                              of 800 per drive.
BMAG      =4128          ; total buffer magnitude, in bytes
;                              expressed by SSIZE+4*NBUF
;
BOS       EQU $B800         ; bottom of data stack, in zero-page.
TOS       EQU $BBFF         ; top of data stack, in zero-page.
N         EQU $30             ; scratch workspace.
IP        EQU N+16          ; interpretive pointer.
W         EQU IP+4          ; code field pointer.
W2		  EQU W+4
UP        EQU W2+4           ; user area pointer.
XSAVE     EQU UP+4          ; temporary for X register.
YSAVE	  EQU XSAVE+2
USAVE		EQU	YSAVE+2
TMP			EQU	USAVE+2
TRACEF	  EQU	TMP+4
;
TIBX      EQU $0100         ; terminal input buffer of 84 bytes.
ORIG      EQU $20000        ; origin of FORTH's Dictionary.
TOP		  EQU $100000
MEM       EQU $160000     	; top of assigned memory+1 byte.
UAREA     EQU MEM-256       ; 256 bytes of user area
DAREA     EQU UAREA-BMAG    ; disk buffer space.
;
;         Monitor calls for terminal support
;
OUTCH     EQU $D2C1         ; output one ASCII char. to term.
INCH      EQU $D1DC         ; input one ASCII char. to term.
TCR       EQU $D0F1         ; terminal return and line feed.
CLEARSCREEN	EQU	$D300
HOME_CURSOR	EQU	$D308
;
;    From DAREA downward to the top of the dictionary is free
;    space where the user's applications are compiled.
;
;    Boot up parameters. This area provides jump vectors
;    to Boot up  code, and parameters describing the system.
;
;
		  ORG $20000
;          *=*+2
;
		 ; These two jumps must occupy four bytes each.
                         ; User cold entry point
                         ; User cold entry point
ENTER     NOP            ; Vector to COLD entry
;		  NOP
;		  SWI3
          JMP COLD+4     ;
REENTR    NOP            ; User Warm entry point
          JMP WARM       ; Vector to WARM entry
          FCDW $0004    ; 6502 in radix-36
          FCDW $5ED2    ;
          FCDW NTOP     ; Name address of MON
          FCDW $7F      ; Backspace Character
          FCDW UAREA    ; Initial User Area
          FCDW TOS      ; Initial Top of Stack
          FCDW $BFFF    ; Initial Top of Return Stack
          FCDW TIBX     ; $14 Initial terminal input buffer
;
;
          FCDW 31       ; $18 Initial name field width
          FCDW 0        ; 0=nod disk, 1=disk
          FCDW TOP      ; $20 Initial fence address
          FCDW TOP      ; $24 Initial top of dictionary
          FCDW VL0      ; $28 Initial Vocabulary link ptr.
		  ;$2C - BLK
		  ;$30 - IN
		  ;$34 - OUT	output character count
		  ;$38 - screen
		  ;$3C - OFSET
		  ;$40 - CONTEXT
		  ;$44 - CURRENT
		  ;$48 - STATE
		  ;$4C - numeric base
		  ;$50 - DPL
		  ;$54 - FLD
		  ;$58 - CSP
		  ;$5C - RNUM
		  ;$60 - HLD
;
;    The following offset adjusts all code fields to avoid an
;    address ending $XXFF. This must be checked and altered on
;    any alteration , for the indirect jump at W-1 to operate !
;
          .ORIGIN *+2
;
;
;                                       LIT
;                                       SCREEN 13 LINE 1
;
L22       FCB $83,"LI",$D4            ; <--- name field
;                          <----- link field
          FCDW 00			; last link marked by zero
LIT       FCDW *+4			; <----- code address field
          LDD	FAR [IP]    ; <----- start of parameter field
          PSHS	D
		  BSR	INC_IP
		  BSR	INC_IP
L30       LDD	FAR [IP]
		  BSR	INC_IP
L31		  BSR	INC_IP

PUSH	  LEAU	-4,U

PUT		  STD	2,U
		  PULS	D
		  STD	,U

NEXT	  JSR	TRACE
		  LDY	#2
		  LDD	FAR [IP]
		  STD	W
		  LDD	FAR [IP],Y
		  STD	W+2
		  BSR	INC4_IP

; Note standard forth practice places self-modifying code to implement a doubly
; indirect jump. Self modifying code is avoided here by using an additional
; variable. The cost is some performance.

;		  JMP	FAR [[W]]	; this is the instruction we really want
NEXTW	  LDY	#2			; entry point from EXEC
		  LDD	FAR [W]		; double indirect far jump is needed here
		  LDX	FAR [W],Y
		  STD	W2
		  STX	W2+2
		  JMP	FAR [W2]

; Increment IP by 1
; Most of the time only the LSB of the IP needs to be incremented, so avoid a 
; carry chain adder.

INC_IP	;  INC  IP+3
		  ;    BNE  INC_IP_1
		  INC  IP+2
		  BNE  INC_IP_1
		  INC  IP+1
		  BNE  INC_IP_1
		  INC  IP
INC_IP_1  RTS
	
; Increment IP by 2

INC2_IP	  BSR	INC_IP
		  BRA	INC_IP

; Here we just use a carry chain adder, rather than calling INC_IP four times.

INC4_IP	  LDD	IP+2
		  ADDD	#4
		  STD	IP+2
		  LDD	IP
		  ADCB	#0
		  ADCA	#0
		  STD	IP
		  RTS

; Add DX to IP
; This is used for branches.

ADXIP	  TFR	D,Y
		  TFR	X,D
		  ADDD	IP+2
		  STD	IP+2
		  TFR   Y,D
		  ADCB	IP+1
		  ADCA	IP
		  STD	IP
		  RTS

;    CLIT pushes the next inline byte to data stack
;
L35       FCB $84,"CLI",$D4
          FCDW L22      ; Link to LIT
CLIT      FCDW *+4
		  CLRD
		  PSHS	D
          LDB	FAR [IP]
          JMP	L31        ; a forced branch into LIT
;
;
;    This is a temporary trace routine, to be used until FORTH
;    is generally operating. Then NOP the terminal query
;    "JSR ONEKEY". This will allow user input to the text
;    interpreter. When crashes occur, the display shows IP, W,
;    and the word locations of the offending code. When all is
;    well, remove : TRACE, TCOLON, PRNAM, DECNP, and the
;    following monitor/register equates.
;
;
;
;    Monitor routines needed to trace.
;
XBLANK    EQU $D0AF         ; print one blank
CRLF      EQU $D0D2         ; print a carriage return and line feed.
HEX2      EQU $D2CE         ; print accum as two hex numbers
HEX4		EQU	$D2D2		; print accum D as four hex numbers
LETTER    EQU $D2C1         ; print accum as one ASCII character
ONEKEY    EQU $D1DC         ; wait for keystroke
XW        EQU $60           ; scratch reg. to next code field add
NP        EQU XW+4              ; scratch reg. pointing to name field
;
;
TRACE     TST	TRACEF
          BNE	TRACE3
		  RTS
TRACE3	  JSR	FAR CRLF
		  LDD	IP			; print IP, the interpreter pointer
		  JSR	FAR HEX4
		  LDD	IP+2
		  JSR	FAR HEX4
          JSR	FAR XBLANK
;
;
          LDD	FAR [IP]
          STD	XW
          STD	NP         ; fetch the next code field pointer
		  LDY	#2
          LDD	FAR [IP],Y
          STD	XW+2
          STD	NP+2
          JSR	PRNAM  ; print dictionary name
;
          LDD	XW
          JSR	FAR HEX4   ; print code field address
          LDD	XW+2
          JSR	FAR HEX4
          JSR	FAR XBLANK
;
		  TFR	U,D		; print stack location in zero-page
          JSR	FAR HEX4
          JSR	FAR XBLANK
;
		  TFR	S,D		; print return stack bottom in page 1
          JSR	FAR HEX4
          JSR	FAR XBLANK
;
          JSR	FAR ONEKEY ; wait for operator keystroke
		  CMPA	#'c'
		  BNE	TRACE1
		  JSR	FAR CLEARSCREEN
		  JSR	FAR HOME_CURSOR
TRACE1:	  CMPA  #'s'
		  BNE	TRACE2
		  JSR	DumpDStack
TRACE2:
          RTS
;
;    TCOLON is called from DOCOLON to label each point
;    where FORTH 'nests' one level.
;
TCOLON    TST	TRACEF
          BNE	TCOLON1
		  RTS
TCOLON1	  LDD	W
          STD	NP         ; locate the name of the called word
          LDD	W+2
          STD	NP+2
          JSR	FAR CRLF
          LDA	#$3A       ; ':
          JSR	FAR LETTER
          JSR	FAR XBLANK
;          BSR	 PRNAM
;          RTS
;
;    Print name by it's code field address in NP
;
PRNAM     BSR	DECNP
          BSR	DECNP
          BSR	DECNP
          BSR	DECNP
          BSR	DECNP
          LDY	#0
PN1       BSR	DECNP
          LDA	FAR [NP]       ; loop till D7 in name set
          BPL	PN1
PN2       INY
          LDA	FAR [NP],Y
		  PSHS	CCR
		  ANDA	#$7F
          JSR	FAR LETTER     ; print letters of name field
          PULS	CCR
          BPL	PN2
          JSR	FAR XBLANK
          RTS
;
;    Decrement name field pointer
;
DECNP	  LDD	NP+2
          SUBD	#1
		  STD	NP+2
		  LDD	NP
		  SBCB	#0
		  SBCA	#0
		  STD	NP
		  RTS

SETUP     LDY	#0
		  CLRA
		  ASLB
		  ROLA
		  ASLB
		  ROLA
		  STD	N-2
L63       LDA	,U+
          STA	N,Y
          INY
          CPY	N-2
          BNE	L63
		  LDY	#0
          RTS
;
;                                       EXCECUTE
;                                       SCREEN 14 LINE 11
;
L75       FCB $87,"EXECUT",$C5
          FCDW L35      ; link to CLIT
EXEC      FCDW *+4
		  PULU	D,X
          STD	W
          STX	W+2
          JMP	NEXTW   ; to JMP (W) in z-page
;
;                                       BRANCH
;                                       SCREEN 15 LINE 11
;
L89       FCB $86,"BRANC",$C8
          FCDW L75      ; link to EXCECUTE
BRAN      FCDW *+4
BRAN_4:
		  LDY	#2
		  LDD	FAR [IP]
		  LDX	FAR [IP],Y
		  JSR	ADXIP
          JMP	NEXT
;
;                                       0BRANCH
;                                       SCREEN 15 LINE 6
;
L107      FCB $87,"0BRANC",$C8
          FCDW L89      ; link to BRANCH
ZBRAN     FCDW *+4
		  PULU	D,X
		  CMPD	#0
		  BNE	BUMP
		  CMPX	#0
          BEQ	BRAN_4
;
BUMP      JSR	INC4_IP
L122	  JMP	NEXT
;
;                                       (LOOP)
;                                       SCREEN 16 LINE 1
;
L127      FCB $86,"(LOOP",$A9
          FCDW L107     ; link to 0BRANCH
PLOOP     FCDW L130
L130      INC   3,S		; Increment LOOP var
          BNE   PL1
		  INC   2,S
		  BNE   PL1
		  INC   1,S
		  BNE   PL1
		  INC   ,S
;
PL1		  LDD	6,S		; compare LOOP var to limit
		  SEC			; subtract an extra one because we test for minus
		  SBCB  3,S
		  SBCA  2,S
		  LDD	4,S
		  SBCB	1,S
		  SBCA	0,S
;
PL2       ASLA			; get sign bit into carry
          BCC	BRAN+4
		  LEAS	8,S		; LOOP finished, pop stacked info
          JMP	BUMP

;
;                                       (+LOOP)
;                                       SCREEN 16 LINE 8
;
L154      FCB $87,"(+LOOP",$A9
          FCDW L127     ; link to (loop)
PPLOO     FCDW *+4
		  LDD	2,U
		  LDX	,U
		  LEAU	4,U
		  ADDD	2,S
		  STD	2,S
		  TFR	X,D
		  ADCB	1,S
		  ADCA	0,S
		  STD	0,S
		  TFR	X,D
		  ASLA
		  BCC	PL1
	      LDD	2,S		; compare LOOP var to limit
		  SEC
		  SBCB  7,S
		  SBCA  6,S
		  LDD	0,S
		  SBCB	5,S
		  SBCA	4,S
		  BRA	PL2
;
;                                       (DO)
;                                       SCREEN 17 LINE 2
;
L185      FCB $84,"(DO",$A9
          FCDW L154     ; link to (+LOOP)
PDO       FCDW *+4
		  LDD	6,U
		  PSHS	D
		  LDD	4,U
		  PSHS	D
		  LDD	2,U
		  PSHS	D
		  LDD	,U
		  PSHS	D
;
POPTWO    LEAU	8,U
		  JMP	NEXT
;
;
;
POP       LEAU	4,U
          JMP NEXT
;
;                                       I
;                                       SCREEN 17 LINE 9
;
L207      FCB $81,$C9
          FCDW L185     ; link to (DO)
I         FCDW R+4      ; share the code for R
;
;                                       DIGIT
;                                       SCREEN 18 LINE 1
;
L214      FCB $85,"DIGI",$D4
          FCDW L207     ; link to I
DIGIT     FCDW *+4
          LDA	7,U
          SUBA	#$30	; if < '0' exit false
          BMI	L234
          CMPA	#$A		; if > 9
          BMI	L227
          SUBA	#7
          CMPA	#$A
          BMI	L234
L227      CMPA	3,U		; compare to radix (here we assume radix < 256)
          BPL	L234	; greater than radix ? then return false
          STA	7,U		; save conversion on stack
		  CLR	6,U
		  CLR	5,U
		  CLR	4,U
		  CLRD
		  PSHS	D
          INCB
          JMP	PUT        ; exit true with converted value
L234      CLRD
          PSHS	D
		  LEAU	4,U		   ; pop and
          JMP	PUT        ; exit false with bad conversion
;
;                                       (FIND)
;                                       SCREEN 19 LINE 1
;
L243      FCB $86,"(FIND",$A9
          FCDW L214   ; Link to DIGIT
PFIND     FCDW *+4
          LDB	#2
          JSR	SETUP
L249
;		  JSR   FAR XBLANK
;		  LDD   N
;		  JSR   FAR HEX4
;		  LDD   N+2
;		  JSR   FAR HEX4
	      LDY	#0
          LDA	FAR [N]			; check the length for a match
          EORA	FAR [N+4]
;
;
          ANDA	#$3F			; only bit 0-5 need match
          BNE	L281			; go scan for next word
L254      INY					; check spelling match
          LDA	FAR [N],Y
          EORA	FAR [N+4],Y
          ASLA
          BNE	L280			; branch if bits 6-0 are different
          BCC	L254			; branch if not last character word
		  LEAU	-8,U			; here the word matched, allocate stack
		  TFR	Y,D
		  ADDD	#9
		  ADCB	N+3
		  ADCA	N+2
		  STD	6,U
		  PSHS	CCR
		  CLRD
		  PULS	CCR
		  ADCB	N+1
		  ADCA	N
		  STD	4,U
		  CLR	,U
		  CLR	1,U
		  CLR	2,U
		  LDB	FAR [N]		; length of word
		  STB	3,U
		  CLRD
		  PSHS	D
		  LDB	#1			; return TRUE (1)
		  JMP	PUSH
L280      BCS   L284
;		  LDA	FAR [N],Y	; more bullet proof than a simple BCS
;         BITA	#$80        ; which fails if MSB is set in word searched for
;		  BNE	L284		; carry set if at end of word
L281      INY				; scan until end of word reached
          LDA	FAR [N],Y
          BPL	L281
L284      INY
          LDD	FAR [N],Y	; get the link to the next in list
		  LEAY	2,Y
          LDX	FAR [N],Y
          STD	N
          STX	N+2
		  LBNE	L249		; keep looking through dictionary if
		  CMPD	#0			; not the last link
          LBNE	L249
          PSHS	D
          JMP	PUSH		; exit false upon reading null link
;
;                                       ENCLOSE
;                                       SCREEN 20 LINE 1
;
L301      FCB $87,"ENCLOS",$C5
          FCDW L243     ; link to (FIND)
ENCL      FCDW *+4
          LDB	#2
          JSR	SETUP
		  LEAU	-16,U
		  CLRD
		  STD	,U
;		  STD	2,U
		  STD	4,U
;		  STD	6,U
		  STD	8,U
		  LDY	#0
          DEY
L313      INY
          LDA	FAR [N+4],Y
          CMPA	N+3
          BEQ	L313
          STY	10,U
L318      LDA	FAR [N+4],Y
          BNE	L327
          STY	6,U
          STY	2,U
          CMPY	10,U
          BNE	L326
          INC	7,U
		  BNE	L326
		  INC   6,U
L326      JMP	NEXT
L327      STY	6,U
          INY
          CMPA	N+3
          BNE	L318
          STY	2,U
          JMP	NEXT
;
;                                       EMIT
;                                       SCREEN 21 LINE 5
;
L337      FCB $84,"EMI",$D4
          FCDW L301     ; link to ENCLOSE
EMIT      FCDW XEMIT    ; Vector to code for KEY
;
;                                       KEY
;                                       SCREEN 21 LINE 7
;
L344      FCB $83,"KE",$D9
          FCDW L337     ; link to EMIT
KEY       FCDW XKEY     ; Vector to code for KEY
;
;                                       ?TERMINAL
;                                       SCREEN 21 LINE 9
;
L351      FCB $89,"?TERMINA",$CC
          FCDW L344     ; link to KEY
QTERM     FCDW XQTER    ; Vector to code for ?TERMINAL
;
;
;
;
;
;                                       CR
;                                       SCREEN 21 LINE 11
;
L358      FCB $82,"C",$D2
          FCDW L351     ; link to ?TERMINAL
CR        FCDW XCR      ; Vector to code for CR
;
;                                       CMOVE
;                                       SCREEN 22 LINE 1
;
L365      FCB $85,"CMOV",$C5
          FCDW L358     ; link to CR
CMOVE     FCDW *+4
          LDB	#3
          JSR	SETUP
L370      CMPY	N+2
          BNE	L375
		  LDD	N
		  SUBD	#1
		  STD	N
          BPL	L375
          JMP	NEXT
L375      LDA	FAR [N+8],Y
          STA	FAR [N+4],Y
          INY
          BNE	L370
          INC	N+9
		  BNE	L376
		  INC	N+8
L376	  INC	N+5
		  BNE	L370
          INC	N+4
          JMP	L370
;
;                                       U*
;                                       SCREEN 23 LINE 1
;
L386      FCB $82,"U",$AA
          FCDW L365     ; link to CMOVE
USTAR     FCDW *+4
		  LDD	4,U
		  STD	N
		  LDD	6,U
		  STD	N+2
		  CLRD
		  STD	4,U
		  STD	6,U
		  LDY	#32		; for 32 bits
L396	  ASL	7,U
		  ROL	6,U
		  ROL	5,U
		  ROL	4,U
		  ROL   3,U
		  ROL	2,U
		  ROL	1,U
		  ROL	0,U
		  BCC	L411
		  LDD	N+2
		  ADDD	6,U
		  STD	6,U
		  LDD	N
		  ADCB	5,U
		  ADCA	4,U
		  STD	4,U
		  LDA	#0
		  ADCA	3,U
		  STA	3,U
L411	  DEY
		  BNE   L396
		  JMP	NEXT
;
;                                       U/
;                                       SCREEN 24 LINE 1
;
L418      FCB $82,"U",$AF
          FCDW L386     ; link to U*
USLAS     FCDW *+4
		  LDD   10,U
		  LDY   6,U
		  STY   10,U
		  ASLB
		  ROLA
		  STD	6,U
		  LDD	8,U
		  LDY	4,U
		  STY	8,U
		  ROLB
		  ROLA
		  STD	4,U
		  LDY	#32
L433	  ROL	11,U
		  ROL	10,U
		  ROL	9,U
		  ROL	8,U
		  LDD	10,U
		  SUBD	2,U
		  TFR	D,X
		  LDD	8,U
		  SBCB	1,U
		  SBCA	0,U
		  RORA				; complement carry flag
		  EORA  #$80
		  ROLA
		  BCC	L444
		  STD	8,U
		  STX	10,U
L444	  ROL   7,U
		  ROL   6,U
		  ROL   5,U
		  ROL   4,U
		  DEY
		  BNE	L433
		  JMP	POP
;
		  JSR	FAR CRLF
		  LDA	#'V'
		  JSR	FAR LETTER
		  LDD	6,U
		  JSR	FAR HEX4
		  LDD	4,U
		  JSR	FAR HEX4
		  JSR	FAR XBLANK
		  LDD	10,U
		  JSR	FAR HEX4
		  LDD	8,U
		  JSR	FAR HEX4
		  JSR	FAR XBLANK
		  LDD	,U
		  JSR	FAR HEX4
		  LDD	2,U
		  JSR	FAR HEX4
		  JSR	FAR CRLF
		  JSR	FAR ONEKEY
;                                       AND
;                                       SCREEN 25 LINE 2
;
L453      FCB $83,"AN",$C4
          FCDW	L418     ; link to U/
ANDD_     FCDW	*+4
		  PULU	D,X
		  ANDA	,U
		  ANDB	1,U
		  EXG	D,X
		  ANDA	2,U
		  ANDB	3,U
		  EXG	D,X
		  STD	,U
		  STX	2,U
		  JMP	NEXT
;
BINARY    LEAU	4,U
          JMP	PUT
;
;                                       OR
;                                       SCREEN 25 LINE 7
;
L469      FCB $82,"O",$D2
          FCDW	L453     ; link to AND
OR        FCDW	*+4
		  PULU  D,X
		  ORA	,U
		  ORB	1,U
		  EXG	D,X
		  ORA	2,U
		  ORB	3,U
		  EXG	D,X
		  STD	,U
		  STX	2,U
		  JMP	NEXT
;
;                                       XOR
;                                       SCREEN 25 LINE 11
;
L484      FCB $83,"XO",$D2
          FCDW L469     ; link to OR
XOR       FCDW *+4
		  PULU  D,X
		  EORA	,U
		  EORB	1,U
		  EXG	D,X
		  EORA	2,U
		  EORB	3,U
		  EXG	D,X
		  STD	,U
		  STX	2,U
		  JMP	NEXT
;
;                                       SP@
;                                       SCREEN 26 LINE 1
;
L499      FCB $83,"SP",$C0
          FCDW L484     ; link  to XOR
SPAT      FCDW *+4
		  CLRD
		  PSHS	D
		  TFR	U,D
          JMP	PUSH

PUSHOA    CLRD
		  PSHS	D
		  TFR	X,D
          JMP	PUSH
;
;                                       SP!
;                                       SCREEN 26 LINE 5
;
;
L511      FCB $83,"SP",$A1
          FCDW L499     ; link to SP@
SPSTO     FCDW *+4
          LDY #14		 ; 6 or 12 ? User area format ????
          LDU FAR [UP],Y ; load data stack pointer (X reg) from
          JMP NEXT		 ; silent user variable S0.
;
;                                       RP!
;                                       SCREEN 26 LINE 8
;
L522      FCB $83,"RP",$A1
          FCDW	L511     ; link to SP!
RPSTO     FCDW	*+4
							; load return stack pointer (machine
          LDY	#18         ; stack pointer) from silent user
          LDS	FAR [UP],Y  ; VARIABLE R0
          JMP	NEXT
;
;                                       ;S
;                                       SCREEN 26 LINE 12
;
L536      FCB $82,";",$D3
          FCDW L522     ; link to RP!
SEMIS     FCDW *+4
		  PULS	D,X
		  STD	IP
		  STX	IP+2
          JMP	NEXT
;
;                                       LEAVE
;                                       SCREEN 27 LINE  1
;
L548      FCB $85,"LEAV",$C5
          FCDW	L536     ; link to ;S
LEAVE     FCDW	*+4
          LDD   ,S
		  LDX   2,S
		  STD   4,S
		  STX	6,S
          JMP	NEXT
;
;                                       >R
;                                       SCREEN 27 LINE 5
;
L563      FCB $82,">",$D2
          FCDW	L548     ; link to LEAVE
TOR       FCDW	*+4
		  PULU	D,X			; transfer from data stack to return stack
		  PSHS	D,X
          JMP	NEXT
;
;                                       R>
;                                       SCREEN 27 LINE 8
;
L577      FCB $82,"R",$BE
          FCDW	L563     ; link to >R
RFROM     FCDW	*+4
		  PULS	D,X
		  PSHU	D,X
          JMP	NEXT
;
;                                       R
;                                       SCREEN 27 LINE 11
;
L591      FCB $81,$D2
          FCDW	L577     ; link to R>
R         FCDW	*+4
		  LDD	,S
		  LDX	2,S
		  PSHS	D
		  TFR	X,D
		  JMP	PUSH

;		  PULU	D,X
;		  PSHS	D,X
;		  JMP	NEXT
;
;                                       0=
;                                       SCREEN 28 LINE 2
;
L605      FCB $82,"0",$BD
          FCDW	L591     ; link to R
ZEQU      FCDW	*+4
		  LDD	,U
		  BNE	ZEQU_1
		  LDD	2,U
		  BNE	ZEQU_1
		  STD	,U
		  INCB
		  STD	2,U
		  JMP	NEXT
ZEQU_1	  CLRD
		  STD	,U
		  STD	2,U
		  JMP	NEXT
;
;                                       0<
;                                       SCREEN 28 LINE 6
;
L619      FCB $82,"0",$BC
          FCDW	L605     ; link to 0=
ZLESS     FCDW *+4
		  CLRD
		  ASL	,U
		  ROLB
		  BNE	ZLESS_1
		  STD	,U
		  STD	2,U
		  JMP	NEXT
ZLESS_1	  STD	2,U
		  CLRB
		  STD	,U
		  JMP	NEXT
;
;                                       +
;                                       SCREEN 29 LINE 1
;
L632      FCB $81,$AB
          FCDW	L619     ; link to V-ADJ
PLUS      FCDW	*+4
		  LDD	6,U
		  ADDD	2,U
		  STD	6,U
		  LDD	4,U
		  ADCB	1,U
		  ADCA	,U
		  STD	4,U
		  LEAU	4,U		; POP
          JMP	NEXT
;
;                                       D+
;                                       SCREEN 29 LINE 4
;
L649      FCB $82,"D",$AB
          FCDW L632     ;    LINK TO +
DPLUS     FCDW *+4
		  LDD	6,U
		  ADDD	2,U
		  STD	6,U
		  LDD	4,U
		  ADCB	1,U
		  ADCA	,U
		  STD	4,U
		  LEAU	4,U		; POP
          JMP	NEXT

L660      FCB $84,"D64",$AB
          FCDW L649     ;    LINK TO +
D64PLUS   FCDW *+4
		  LDD	14,U
		  ADDD	6,U
		  STD	14,U
		  LDD	12,U
		  ADCB	5,U
		  ADCA	4,U
		  STD	12,U
		  LDD	10,U
		  ADCB	3,U
		  ADCA	2,U
		  STD	10,U
		  LDD	8,U
		  ADCB  1,U
		  ADCA	0,U
		  STD	8,U
		  LEAU	8,U		; POP
          JMP	NEXT
;
;                                       MINUS
;                                       SCREEN 29 LINE 9
;
L670      FCB $85,"MINU",$D3
          FCDW L660     ; link to D64+
MINUS     FCDW *+4
          CLRD
		  SUBD	2,U
		  STD	2,U
		  PSHS	CCR
		  CLRD
		  PULS	CCR
		  SBCB	1,U
		  SBCA	,U
		  STD	,U
          JMP	NEXT
;
;                                       DMINUS
;                                       SCREEN 29 LINE 12
;
L685      FCB	$86,"DMINU",$D3
          FCDW L670     ; link to  MINUS
DMINU     FCDW *+4
          CLRD
		  SUBD	2,U
		  STD	2,U
		  PSHS	CCR
		  CLRD
		  PULS	CCR
		  SBCB	1,U
		  SBCA	,U
		  STD	,U
          JMP	NEXT
;
;                                       OVER
;                                       SCREEN 30 LINE 1
;
L700      FCB $84,"OVE",$D2
          FCDW L685     ; link to DMINUS
OVER      FCDW *+4
		  LDD	4,U
		  PSHS	D
		  LDD	6,U
		  JMP	PUSH
;
;                                       DROP
;                                       SCREEN 30 LINE 4
;
L711      FCB $84,"DRO",$D0
          FCDW L700     ; link to OVER
DROP      FCDW POP
;
;                                       SWAP
;                                       SCREEN 30 LINE 8
;
L718      FCB $84,"SWA",$D0
          FCDW L711     ; link to DROP
SWAP      FCDW *+4
		  LDD	4,U
		  PSHS	D
		  LDD	6,U
		  PSHS	D
		  LDD	0,U
		  STD	4,U
		  LDD	2,U
		  STD	6,U
		  PULS	D
		  STD	2,U
		  PULS	D
		  STD	0,U
		  JMP	NEXT
;
;                                       DUP
;                                       SCREEN 30 LINE 21
;
L733      FCB $83,"DU",$D0
          FCDW	L718     ; link to SWAP
DUP       FCDW	*+4
          LDD	0,U
		  LDX	2,U
		  PSHU	D,X
		  JMP	NEXT
;
;                                       +!
;                                       SCREEN 31 LINE 2
;
L744      FCB $82,'+',$A1
          FCDW L733     ; link to DUP
PSTOR     FCDW *+4
	      PULU	D,X		 ; get address of value
		  STD	TMP		 ; store in TMP pointer
		  STX	TMP+2
		  LDY	#2
		  LDD	FAR [TMP],Y	 ; add second on stack to
		  ADDD	2,U		 ; value
		  STD	FAR [TMP],Y
		  LDD	FAR [TMP]
		  ADCB	1,U
		  ADCA  ,U
		  STD   FAR [TMP]
		  JMP	POP
;
;                                       TOGGLE
;                                       SCREEN 31 LINE 7
;
L762      FCB $81,"TOGGL",$C5
          FCDW	L744     ; link to +!
TOGGL     FCDW	*+4
          LDA	FAR [4,U]  ; complement bits in memory address
          EORA	3,U        ; second on stack, by pattern on
          STA	FAR [4,U]  ; bottom of stack.
		  LEAU	8,U
          JMP	NEXT
;
;                                       @
;                                       SCREEN 32 LINE 1
;
L773      FCB $81,$C0
          FCDW L762     ; link to TOGGLE
AT        FCDW *+4
          LDD	FAR [0,U]
          PSHS	D
		  LDD	2,U
		  ADDD	#2
		  STD	2,U
		  LDD	,U
		  ADCB	#0
		  ADCA	#0
		  STD	,U
	      LDD	FAR [0,U]
          JMP	PUT
;
;                                       C@
;                                       SCREEN 32 LINE 5
;
L787      FCB $82,"C",$C0
          FCDW	L773		; link to @
CAT       FCDW	*+4
          LDA	FAR [0,U]	; fetch byte addressed by bottom of
		  CLR	,U			; stack to stack, zeroing the high bits
		  CLR	1,U
		  CLR	2,U
		  STA	3,U
          JMP	NEXT
;
;                                       W@
;                                       SCREEN 32 LINE 1
;
L790      FCB $82,"W",$C0
          FCDW	L787     ; link to C@
WAT       FCDW	*+4
          LDD	FAR [0,U]
          STD	2,U			; stack to stack, zeroing the high
		  CLRD
          STD	,U			; byte
          JMP	NEXT
;
;                                       !
;                                       SCREEN 32 LINE 8
;
L798      FCB $81,$A1
          FCDW	L790     ; link to W@
STORE     FCDW	*+4
          LDD	4,U
		  LDX	6,U
          STD	FAR [0,U]; store second high 16 bits of 32bit value on stack
                         ; to memory as addressed by bottom
                        ; of stack.
		  LDD	2,U
		  ADDD	#2
		  STD	2,U
		  LDD	,U
		  ADCB	#0
		  ADCA	#0
		  STD	,U
          STX	FAR [0,U]; store second low 16 bits of 32bit value on stack
                         ; to memory as addressed by bottom
                        ; of stack.
          JMP POPTWO
;
;                                       C!
;                                       SCREEN 32 LINE 12
;
L813      FCB $82,"C",$A1
          FCDW L798     ; link to !
CSTOR     FCDW *+4
          LDA	7,U
          STA	FAR [0,U]
          JMP	POPTWO
;
;                                       W!
;                                       SCREEN 32 LINE 12
;
L815      FCB $82,"W",$A1
          FCDW L813     ; link to C!
WSTOR     FCDW *+4
          LDD	6,U
          STD	FAR [0,U]
          JMP	POPTWO
;
;                                       :
;                                       SCREEN 33 LINE 2
;
L823      FCB $C1,$BA
          FCDW L815     ; link to W!
COLON     FCDW	DOCOL
          FCDW	QEXEC
          FCDW	SCSP
          FCDW	CURR
          FCDW	AT
          FCDW	CON_
          FCDW	STORE
          FCDW	CREAT
          FCDW	RBRAC
          FCDW	PSCOD
;
DOCOL     LDD	IP+2
		  PSHS	D
		  LDD	IP
		  PSHS	D
          JSR	TCOLON     ; mark the start of a traced : def.
		  LDD	W+2
		  ADDD	#4
		  STD	IP+2
		  LDD	W
		  ADCB	#0
		  ADCA	#0
		  STD	IP
          JMP	NEXT
;
;                                       ;
;                                       SCREEN 33 LINE 9
;
L853      FCB $C1,$BB
          FCDW	L823     ; link to :
          FCDW	DOCOL
          FCDW	QCSP
          FCDW	COMP
          FCDW	SEMIS
          FCDW	SMUDG
          FCDW	LBRAC
          FCDW	SEMIS
;
;                                       CONSTANT
;                                       SCREEN 34 LINE 1
;
L867      FCB $88,"CONSTAN",$D4
          FCDW L853     ; link to ;
CONST     FCDW DOCOL
          FCDW CREAT
          FCDW SMUDG
          FCDW COMMA
          FCDW PSCOD
;
DOCON     LDY	#4
          LDD	FAR [W],Y
          PSHS	D
          LEAY	2,Y
          LDD	FAR [W],Y
          JMP	PUSH
;
;                                       VARIABLE
;                                       SCREEN 34 LINE 5
;
L885      FCB $88,"VARIABL",$C5
          FCDW L867     ; link to CONSTANT
VAR       FCDW DOCOL
          FCDW CONST
          FCDW PSCOD
;
DOVAR     LDD	W+2
          ADDD	#4
		  EXG	D,X
		  LDD	W
		  ADCB	#0
		  ADCA	#0
		  PSHS	D
		  EXG	D,X
          JMP	PUSH
;
;                                       USER
;                                       SCREEN 34 LINE 10
;
L902      FCB $84,"USE",$D2
          FCDW L885     ; link to VARIABLE
USER      FCDW DOCOL
          FCDW CONST
          FCDW PSCOD
;
DOUSE     LDD	UP
		  LDD   UP+2
		  LDY	#4
		  CLRA
          LDB	FAR [W],Y
          ADDD	UP+2
		  TFR   D,Y
		  PSHS  CCR
		  EXG	D,X
		  CLRD
		  PULS  CCR
		  ADCB	UP+1
		  ADCA	UP
		  PSHS	D
		  TFR   Y,D
		  EXG	D,X
		  JMP	PUSH
;
;                                       0
;                                       SCREEN 35 LINE 2
;
L920      FCB $81,$B0
          FCDW L902     ; link to USER
ZERO      FCDW DOCON
          FCDW 0
;
;                                       1
;                                       SCREEN 35 LINE 2
;
L928      FCB $81,$B1
          FCDW L920     ; link to 0
ONE       FCDW DOCON
          FCDW 1
;
;                                       2
;                                       SCREEN 35 LINE 3
;
L936      FCB $81,$B2
          FCDW L928     ; link to 1
TWO       FCDW DOCON
          FCDW 2
;
;                                       3
;                                       SCREEN 35 LINE 3
;
L944      FCB $81,$B3
          FCDW L936     ; link to 2
THREE     FCDW DOCON
          FCDW 3
;
;                                       4
;                                       SCREEN 35 LINE 3
;
L948      FCB $81,$B4
          FCDW L944     ; link to 3
FOUR      FCDW DOCON
          FCDW 4
;
;                                       BL
;                                       SCREEN 35 LINE 4
;
L952      FCB $82,"B",$CC
          FCDW L948     ; link to 4
BL        FCDW DOCON
          FCDW $20
;
;                                       C/L
;                                       SCREEN 35 LINE 5
;                                       Characters per line
L960      FCB $83,"C/",$CC
          FCDW L952     ; link to BL
CSLL      FCDW DOCON
          FCDW 56						; was 64
;
;                                       FIRST
;                                       SCREEN 35 LINE 7
;
L968      FCB $85,"FIRS",$D4
          FCDW L960     ; link to C/L
FIRST     FCDW DOCON
          FCDW DAREA    ; bottom of disk buffer area
;
;                                       LIMIT
;                                       SCREEN 35 LINE 8
;
L976      FCB $85,"LIMI",$D4
          FCDW L968     ; link to FIRST
LIMIT     FCDW DOCON
          FCDW UAREA    ; buffers end at user area
;
;                                       B/BUF
;                                       SCREEN 35 LINE 9
;                                       Bytes per Buffer
;
L984      FCB $85,"B/BU",$C6
          FCDW L976     ; link to LIMIT
BBUF      FCDW DOCON
          FCDW SSIZE    ; sector size
;
;                                       B/SCR
;                                       SCREEN 35 LINE 10
;                                       Blocks per screen
;
L992      FCB $85,"B/SC",$D2
          FCDW L984     ; link to B/BUF
BSCR      FCDW DOCON
          FCDW 8        ; blocks to make one screen





;
;                                       +ORIGIN
;                                       SCREEN 35 LINE 12
;
L1000     FCB $87,"+ORIGI",$CE
          FCDW L992     ; link to B/SCR
PORIG     FCDW DOCOL
          FCDW LIT,ORIG
          FCDW PLUS
          FCDW SEMIS
;
;                                       TIB
;                                       SCREEN 36 LINE 4
;
L1010     FCB $83,"TI",$C2
          FCDW L1000    ; link to +ORIGIN
TIB       FCDW DOUSE
          FCB $14
;
;                                       WIDTH
;                                       SCREEN 36 LINE 5
;
L1018     FCB $85,"WIDT",$C8
          FCDW L1010    ; link to TIB
WIDTH     FCDW DOUSE
          FCB $18
;
;                                       WARNING
;                                       SCREEN 36 LINE 6
;
L1026     FCB $87,"WARNIN",$C7
          FCDW L1018    ; link to WIDTH
WARN      FCDW DOUSE
          FCB $1C
;
;                                       FENCE
;                                       SCREEN 36 LINE 7
;
L1034     FCB $85,"FENC",$C5
          FCDW L1026    ; link to WARNING
FENCE     FCDW DOUSE
          FCB $20
;
;
;                                       DP
;                                       SCREEN 36 LINE 8
;
L1042     FCB $82,"D",$D0
          FCDW L1034    ; link to FENCE
DP        FCDW DOUSE
          FCB $24
;
;                                       VOC-LINK
;                                       SCREEN 36 LINE 9
;
L1050     FCB $88,"VOC-LIN",$CB
          FCDW L1042    ; link to DP
VOCL      FCDW DOUSE
          FCB $28
;
;                                       BLK
;                                       SCREEN 36 LINE 10
;
L1058     FCB $83,"BL",$CB
          FCDW L1050    ; link to VOC-LINK
BLK       FCDW DOUSE
          FCB $2C
;
;                                       IN
;                                       SCREEN 36 LINE 11
;
L1066     FCB $82,"I",$CE
          FCDW L1058    ; link to BLK
IN        FCDW DOUSE
          FCB $30
;
;                                       OUT
;                                       SCREEN 36 LINE 12
;
L1074     FCB $83,"OU",$D4
          FCDW L1066    ; link to IN
OUT       FCDW DOUSE
          FCB $34
;
;                                       SCR
;                                       SCREEN 36 LINE 13
;
L1082     FCB $83,"SC",$D2
          FCDW L1074    ; link to OUT
SCR       FCDW DOUSE
          FCB $38
;
;                                       OFFSET
;                                       SCREEN 37 LINE 1
;
L1090     FCB $86,"OFFSE",$D4
          FCDW L1082    ; link to SCR
OFSET     FCDW DOUSE
          FCB $3C
;
;                                       CONTEXT
;                                       SCREEN 37 LINE 2
;
L1098     FCB $87,"CONTEX",$D4
          FCDW L1090    ; link to OFFSET
CON_      FCDW DOUSE
          FCB $40
;
;                                       CURRENT
;                                       SCREEN 37 LINE 3
;
L1106     FCB $87,"CURREN",$D4
          FCDW L1098    ; link to CONTEXT
CURR      FCDW DOUSE
          FCB $44
;
;                                       STATE
;                                       SCREEN 37 LINE 4
;
L1114     FCB $85,"STAT",$C5
          FCDW L1106    ; link to CURRENT
STATE     FCDW DOUSE
          FCB $48
;
;                                       BASE
;                                       SCREEN 37 LINE 5
;
L1122     FCB $84,"BAS",$C5
          FCDW L1114    ; link to STATE
BASE      FCDW DOUSE
          FCB $4C
;
;                                       DPL
;                                       SCREEN 37 LINE 6
;
L1130     FCB $83,"DP",$CC
          FCDW L1122    ; link to BASE
DPL       FCDW DOUSE
          FCB $50
;
;                                       FLD
;                                       SCREEN 37 LINE 7
;
L1138     FCB $83,"FL",$C4
          FCDW L1130    ; link to DPL
FLD       FCDW DOUSE
          FCB $54
;
;
;
;                                       CSP
;                                       SCREEN 37 LINE 8
;
L1146     FCB $83,"CS",$D0
          FCDW L1138    ; link to FLD
CSP       FCDW DOUSE
          FCB $58
;
;                                       R#
;                                       SCREEN 37  LINE 9
;
L1154     FCB $82,"R",$A3
          FCDW L1146    ; link to CSP
RNUM      FCDW DOUSE
          FCB $5C
;
;                                       HLD
;                                       SCREEN 37 LINE 10
;
L1162     FCB $83,"HL",$C4
          FCDW L1154    ; link to R#
HLD       FCDW DOUSE
          FCB $60
;
;                                       1+
;                                       SCREEN 38 LINE  1
;
L1170     FCB $82,"1",$AB
          FCDW L1162    ; link to HLD
ONEP      FCDW DOCOL
          FCDW ONE
          FCDW PLUS
          FCDW SEMIS
;
;                                       2+
;                                       SCREEN 38 LINE 2
;
L1180     FCB $82,"2",$AB
          FCDW L1170    ; link to 1+
TWOP      FCDW DOCOL
          FCDW TWO
          FCDW PLUS
          FCDW SEMIS
;
;                                       4+
;                                       SCREEN 38 LINE 2
;
L1185     FCB $82,"4",$AB
          FCDW L1180    ; link to 1+
FOURP     FCDW DOCOL
          FCDW FOUR
          FCDW PLUS
          FCDW SEMIS
;
;                                       HERE
;                                       SCREEN 38 LINE 3
;
L1190     FCB $84,"HER",$C5
          FCDW L1185    ; link to 2+
HERE      FCDW DOCOL
          FCDW DP
          FCDW AT
          FCDW SEMIS
;
;                                       ALLOT
;                                       SCREEN 38 LINE 4
;
L1200     FCB $85,"ALLO",$D4
          FCDW L1190    ; link to HERE
ALLOT     FCDW DOCOL
          FCDW DP
          FCDW PSTOR
          FCDW SEMIS
;
;                                       ,
;                                       SCREEN 38 LINE 5
;
L1210     FCB $81,$AC
          FCDW L1200    ; link to ALLOT
COMMA     FCDW DOCOL
          FCDW HERE
          FCDW STORE
          FCDW FOUR
          FCDW ALLOT
          FCDW SEMIS
;
;                                       C,
;                                       SCREEN 38 LINE 6
;
L1222     FCB $82,"C",$AC
          FCDW L1210    ; link to ,
CCOMM     FCDW DOCOL
          FCDW HERE
          FCDW CSTOR
          FCDW ONE
          FCDW ALLOT
          FCDW SEMIS
;
;                                       -
;                                       SCREEN 38 LINE 7
;
L1234     FCB $81,$AD
          FCDW L1222    ; link to C,
SUB       FCDW DOCOL
          FCDW MINUS
          FCDW PLUS
          FCDW SEMIS
;
;                                       =
;                                       SCREEN 38 LINE 8
;
L1244     FCB $81,$BD
          FCDW L1234    ; link to -
EQUAL     FCDW DOCOL
          FCDW SUB
          FCDW ZEQU
          FCDW SEMIS
;
;                                       U<
;                                       Unsigned less than
;
L1246     FCB $82,"U",$BC
          FCDW L1244    ; link to =
ULESS     FCDW DOCOL
          FCDW SUB      ; subtract two values
          FCDW ZLESS    ; test sign
          FCDW SEMIS
;                                       <
;                                       Altered from model
;                                       SCREEN 38 LINE 9
;
L1254     FCB $81,$BC
          FCDW	L1246    ; link to U<
LESS      FCDW	*+4
		  LDD	6,U
		  SUBD	2,U
		  LDD	4,U
		  SBCB	1,U
		  SBCA	0,U
		  BVC	L1258
		  EORA	#$80
L1258	  BPL   L1260
		  LDD	#1
		  STD	6,U
		  CLR	4,U
		  CLR	5,U
		  LEAU	4,U
		  JMP	NEXT
L1260	  CLRD
		  STD	4,U
		  STD	6,U
		  LEAU	4,U
		  JMP	NEXT
;
;                                       >
;                                       SCREEN 38 LINE 10
L1264     FCB $81,$BE
          FCDW L1254    ; link to <
GREAT     FCDW DOCOL
          FCDW SWAP
          FCDW LESS
          FCDW SEMIS
;
;                                       ROT
;                                       SCREEN 38 LINE 11
;
L1274     FCB $83,"RO",$D4
          FCDW L1264    ; link to >
ROT       FCDW DOCOL
          FCDW TOR
          FCDW SWAP
          FCDW RFROM
          FCDW SWAP
          FCDW SEMIS
;
;                                       SPACE
;                                       SCREEN 38 LINE 12
;
L1286     FCB $85,"SPAC",$C5
          FCDW L1274    ; link to ROT
SPACE     FCDW DOCOL
          FCDW BL
          FCDW EMIT
          FCDW SEMIS
;
;                                       -DUP
;                                       SCREEN 38 LINE 13
;
L1296     FCB $84,"-DU",$D0
          FCDW L1286    ; link to SPACE
DDUP      FCDW DOCOL
          FCDW DUP
          FCDW ZBRAN
L1301     FCDW L1303-L1301
          FCDW DUP
L1303     FCDW SEMIS
;
;                                       TRAVERSE
;                                       SCREEN 39 LINE 14
;
L1308     FCB $88,"TRAVERS",$C5
          FCDW L1296    ; link to -DUP
TRAV      FCDW DOCOL
          FCDW SWAP
L1312     FCDW OVER
          FCDW PLUS
          FCDW CLIT
          FCB $7F
          FCDW OVER
          FCDW CAT
          FCDW LESS
          FCDW ZBRAN
L1320     FCDW L1312-L1320
          FCDW SWAP
          FCDW DROP
          FCDW SEMIS
;
;                                       LATEST
;                                       SCREEN 39 LINE 6
;
L1328     FCB $86,"LATES",$D4
          FCDW L1308    ; link to TRAVERSE
LATES     FCDW DOCOL
          FCDW CURR
          FCDW AT
          FCDW AT
          FCDW SEMIS
;
;
;                                       LFA
;                                       SCREEN 39 LINE 11
;
L1339     FCB $83,"LF",$C1
          FCDW L1328    ; link to LATEST
LFA       FCDW DOCOL
          FCDW CLIT
          FCB 8
          FCDW SUB
          FCDW SEMIS
;
;                                       CFA
;                                       SCREEN 39 LINE 12
;
L1350     FCB $83,"CF",$C1
          FCDW L1339    ; link to LFA
CFA       FCDW DOCOL
          FCDW FOUR
          FCDW SUB
          FCDW SEMIS
;
;                                       NFA
;                                       SCREEN 39 LIINE 13
;
L1360     FCB $83,"NF",$C1
          FCDW L1350    ; link to CFA
NFA       FCDW DOCOL
          FCDW CLIT
          FCB $9
          FCDW SUB
          FCDW LIT,$FFFFFFFF
          FCDW TRAV
          FCDW SEMIS
;
;                                       PFA
;                                       SCREEN 39 LINE 14
;
L1373     FCB $83,"PF",$C1
          FCDW L1360    ; link to NFA
PFA       FCDW DOCOL
          FCDW ONE
          FCDW TRAV
          FCDW CLIT
          FCB 9
          FCDW PLUS
          FCDW SEMIS
;
;                                       !CSP
;                                       SCREEN 40 LINE 1
;
L1386     FCB $84,"!CS",$D0
          FCDW L1373    ; link to PFA
SCSP      FCDW DOCOL
          FCDW SPAT
          FCDW CSP
          FCDW STORE
          FCDW SEMIS
;
;                                       ?ERROR
;                                       SCREEN 40 LINE 3
;
L1397     FCB $86,"?ERRO",$D2
          FCDW L1386    ; link to !CSP
QERR      FCDW DOCOL
          FCDW SWAP
          FCDW ZBRAN
L1402     FCDW L1406-L1402
          FCDW ERROR
          FCDW BRAN
L1405     FCDW L1407-L1405
L1406     FCDW DROP
L1407     FCDW SEMIS
;
;                                       ?COMP
;                                       SCREEN 40 LINE 6
;
L1412     FCB $85,"?COM",$D0
          FCDW L1397    ; link to ?ERROR
QCOMP     FCDW DOCOL
          FCDW STATE
          FCDW AT
          FCDW ZEQU
          FCDW CLIT
          FCB $11
          FCDW QERR
          FCDW SEMIS
;
;                                       ?EXEC
;                                       SCREEN 40 LINE 8
;
L1426    FCB $85,"?EXE",$C3
          FCDW L1412    ; link to ?COMP
QEXEC     FCDW DOCOL
          FCDW STATE
          FCDW AT
          FCDW CLIT
          FCB $12
          FCDW QERR
          FCDW SEMIS
;
;                                       ?PAIRS
;                                       SCREEN 40 LINE 10
;
L1439     FCB $86,"?PAIR",$D3
          FCDW L1426    ; link to ?EXEC
QPAIR     FCDW DOCOL
          FCDW SUB
          FCDW CLIT
          FCB $13
          FCDW QERR
          FCDW SEMIS
;
;                                       ?CSP
;                                       SCREEN 40 LINE 12
;
L1451     FCB $84,"?CS",$D0
          FCDW L1439    ; link to ?PAIRS
QCSP      FCDW DOCOL
          FCDW SPAT
          FCDW CSP
          FCDW AT
          FCDW SUB
          FCDW CLIT
          FCB $14
          FCDW QERR
          FCDW SEMIS
;
;                                       ?LOADING
;                                       SCREEN 40 LINE 14
;
L1466     FCB $88,"?LOADIN",$C7
          FCDW L1451    ; link to ?CSP
QLOAD     FCDW DOCOL
          FCDW BLK
          FCDW AT
          FCDW ZEQU
          FCDW CLIT
          FCB $16
          FCDW QERR
          FCDW SEMIS
;
;                                       COMPILE
;                                       SCREEN 41 LINE 2
;
L1480     FCB $87,"COMPIL",$C5
          FCDW L1466    ; link to ?LOADING
COMP      FCDW DOCOL
          FCDW QCOMP
          FCDW RFROM
          FCDW DUP
          FCDW FOURP
          FCDW TOR
          FCDW AT
          FCDW COMMA
          FCDW SEMIS
;
;                                       [
;                                       SCREEN 41 LINE 5
;
L1495     FCB $C1,$DB
          FCDW L1480    ; link to COMPILE
LBRAC     FCDW DOCOL
          FCDW ZERO
          FCDW STATE
          FCDW STORE
          FCDW SEMIS
;
;                                       ]
;                                       SCREEN 41 LINE 7
;
L1507     FCB $81,$DD
          FCDW L1495    ; link to [
RBRAC     FCDW DOCOL
          FCDW CLIT
          FCB $C0
          FCDW STATE
          FCDW STORE
          FCDW SEMIS
;
;                                       SMUDGE
;                                       SCREEN 41 LINE 9
;
L1519     FCB $86,"SMUDG",$C5
          FCDW L1507    ; link to ]
SMUDG     FCDW DOCOL
          FCDW LATES
          FCDW CLIT
          FCB $20
          FCDW TOGGL
          FCDW SEMIS
;
;                                       HEX
;                                       SCREEN 41 LINE 11
;
L1531     FCB $83,"HE",$D8
          FCDW L1519    ; link to SMUDGE
HEX       FCDW DOCOL
          FCDW CLIT
          FCB 16
          FCDW BASE
          FCDW STORE
          FCDW SEMIS
;
;                                       DECIMAL
;                                       SCREEN 41 LINE 13
;
L1543     FCB $87,"DECIMA",$CC
          FCDW L1531    ; link to HEX
DECIM     FCDW DOCOL
          FCDW CLIT
          FCB 10
          FCDW BASE
          FCDW STORE
          FCDW SEMIS
;
;                                       (;CODE)
;                                       SCREEN 42 LINE 2
;
L1555     FCB $87,"(;CODE",$A9
          FCDW L1543    ; link to DECIMAL
PSCOD     FCDW DOCOL
          FCDW RFROM
          FCDW LATES
          FCDW PFA
          FCDW CFA
          FCDW STORE
          FCDW SEMIS
;
;                                       ;CODE
;                                       SCREEN 42 LINE 6
;
L1568     FCB $C5,";COD",$C5
          FCDW L1555    ; link to (;CODE)
          FCDW DOCOL
          FCDW QCSP
          FCDW COMP
          FCDW PSCOD
          FCDW LBRAC
          FCDW SMUDG
          FCDW SEMIS
;
;                                       <BUILDS
;                                       SCREEN 43 LINE 2
;
L1582     FCB $87,"<BUILD",$D3
          FCDW L1568    ; link to ;CODE
BUILD     FCDW DOCOL
          FCDW ZERO
          FCDW CONST
          FCDW SEMIS
;
;                                       DOES>
;                                       SCREEN 43 LINE 4
;
L1592     FCB $85,"DOES",$BE
          FCDW L1582    ; link to <BUILDS
DOES      FCDW DOCOL
          FCDW RFROM
          FCDW LATES
          FCDW PFA
          FCDW STORE
          FCDW PSCOD
;
DODOE     LDD	IP		; X and D in right order ???
		  LDX	IP+2
		  PSHS	D,X
		  LDY	#4
		  LDD	FAR [W],Y
		  STD	IP
		  LEAY	2,Y
		  LDD	FAR [W],Y
		  STD	IP+2
		  LDD	W+2
		  ADDD	#8
		  TFR	D,X
		  LDD	W
		  ADCB	#0
		  ADCA	#0
		  PSHS	D
		  TFR	X,D
		  JMP	PUSH
;
;                                       COUNT
;                                       SCREEN 44 LINE 1
;
L1622     FCB $85,"COUN",$D4
          FCDW L1592    ; link to DOES>
COUNT     FCDW DOCOL
          FCDW DUP
          FCDW ONEP
          FCDW SWAP
          FCDW CAT
          FCDW SEMIS
;
;                                       TYPE
;                                       SCREEN 44 LINE 2
;
L1634     FCB $84,"TYP",$C5
          FCDW L1622    ; link to COUNT
TYPE      FCDW DOCOL
          FCDW DDUP
          FCDW ZBRAN
L1639     FCDW L1651-L1639
          FCDW OVER
          FCDW PLUS
          FCDW SWAP
          FCDW PDO
L1644     FCDW I
          FCDW CAT
          FCDW EMIT
          FCDW PLOOP
L1648     FCDW L1644-L1648
          FCDW BRAN
L1650     FCDW L1652-L1650
L1651     FCDW DROP
L1652     FCDW SEMIS
;
;                                       -TRAILING
;                                       SCREEN 44 LINE 5
;
L1657     FCB $89,"-TRAILIN",$C7
          FCDW L1634    ; link to TYPE
DTRAI     FCDW DOCOL
          FCDW DUP
          FCDW ZERO
          FCDW PDO
L1663     FCDW OVER
          FCDW OVER
          FCDW PLUS
          FCDW ONE
          FCDW SUB
          FCDW CAT
          FCDW BL
          FCDW SUB
          FCDW ZBRAN
L1672     FCDW L1676-L1672
          FCDW LEAVE
          FCDW BRAN
L1675     FCDW L1678-L1675
L1676     FCDW ONE
          FCDW SUB
L1678     FCDW PLOOP
L1679     FCDW L1663-L1679
          FCDW SEMIS
;
;                                       (.")
;                                       SCREEN 44 LINE 8
L1685     FCB $84,"(.",$22,$A9
          FCDW L1657    ; link to -TRAILING
PDOTQ     FCDW DOCOL
          FCDW R
          FCDW COUNT
          FCDW DUP
          FCDW ONEP
          FCDW RFROM
          FCDW PLUS
          FCDW TOR
          FCDW TYPE
          FCDW SEMIS
;
;                                       ."
;                                       SCREEN 44 LINE12
;
L1701     FCB $C2,".",$A2
          FCDW L1685    ; link to PDOTQ
          FCDW DOCOL
          FCDW CLIT
          FCB $22
          FCDW STATE
          FCDW AT
          FCDW ZBRAN
L1709     FCDW L1719-L1709
          FCDW COMP
          FCDW PDOTQ
          FCDW WORD
          FCDW HERE
          FCDW CAT
          FCDW ONEP
          FCDW ALLOT
          FCDW BRAN
L1718     FCDW L1723-L1718
L1719     FCDW WORD
          FCDW HERE
          FCDW COUNT
          FCDW TYPE
L1723     FCDW SEMIS
;
;                                       EXPECT
;                                       SCREEN 45 LINE 2
;
L1729     FCB $86,"EXPEC",$D4
          FCDW L1701    ; link to ."
EXPEC     FCDW DOCOL
          FCDW OVER
          FCDW PLUS
          FCDW OVER
          FCDW PDO
L1736     FCDW KEY
          FCDW DUP
          FCDW CLIT
          FCB $20				; backspace character config offset
          FCDW PORIG
          FCDW AT
          FCDW EQUAL
          FCDW ZBRAN
L1744     FCDW L1760-L1744
          FCDW DROP
          FCDW CLIT
          FCB 08
          FCDW OVER
          FCDW I
          FCDW EQUAL
          FCDW DUP
          FCDW RFROM
          FCDW TWO	
          FCDW SUB
          FCDW PLUS
          FCDW TOR
          FCDW SUB
          FCDW BRAN
L1759     FCDW L1779-L1759
L1760     FCDW DUP
          FCDW CLIT
          FCB $0D
          FCDW EQUAL
          FCDW ZBRAN
L1765     FCDW L1772-L1765
          FCDW LEAVE
          FCDW DROP
          FCDW BL
          FCDW ZERO
          FCDW BRAN
L1771     FCDW L1773-L1771
L1772     FCDW DUP
L1773     FCDW I
          FCDW CSTOR
          FCDW ZERO
          FCDW I
          FCDW ONEP
          FCDW STORE
L1779     FCDW EMIT
          FCDW PLOOP
L1781     FCDW L1736-L1781
          FCDW DROP      ; L1736-L1781
          FCDW SEMIS
;
;                                       QUERY
;                                       SCREEN 45 LINE 9
;
L1788     FCB $85,"QUER",$D9
          FCDW L1729    ; link to EXPECT
QUERY     FCDW DOCOL
          FCDW TIB
          FCDW AT
          FCDW CLIT
          FCB 80       ; 80 characters from terminal
          FCDW EXPEC
          FCDW ZERO
          FCDW IN
          FCDW STORE
          FCDW SEMIS
;
;                                       X
;                                       SCREEN 45 LINE 11
;                                       Actually Ascii Null
;
L1804     FCB $C1,$80
          FCDW L1788    ; link to QUERY
          FCDW DOCOL
          FCDW BLK
          FCDW AT
          FCDW ZBRAN
L1810     FCDW L1830-L1810
          FCDW ONE
          FCDW BLK
          FCDW PSTOR
          FCDW ZERO
          FCDW IN
          FCDW STORE
          FCDW BLK
          FCDW AT
          FCDW ZERO,BSCR
          FCDW USLAS
          FCDW DROP     ; fixed from model
          FCDW ZEQU
          FCDW ZBRAN
L1824     FCDW L1828-L1824
          FCDW QEXEC
          FCDW RFROM
          FCDW DROP
L1828     FCDW BRAN
L1829     FCDW L1832-L1829
L1830     FCDW RFROM
          FCDW DROP
L1832     FCDW SEMIS
;
;                                       FILL
;                                       SCREEN 46 LINE 1
;
;
L1838     FCB $84,"FIL",$CC
          FCDW L1804    ; link to X
FILL      FCDW DOCOL
          FCDW SWAP
          FCDW TOR
          FCDW OVER
          FCDW CSTOR
          FCDW DUP
          FCDW ONEP
          FCDW RFROM
          FCDW ONE
          FCDW SUB
          FCDW CMOVE
          FCDW SEMIS
;
;                                       ERASE
;                                       SCREEN 46 LINE 4
;
L1856     FCB $85,"ERAS",$C5
          FCDW L1838    ; link to FILL
ERASE     FCDW DOCOL
          FCDW ZERO
          FCDW FILL
          FCDW SEMIS
;
;                                       BLANKS
;                                       SCREEN 46 LINE 7
;
L1866     FCB $86,"BLANK",$D3
          FCDW L1856    ; link to ERASE
BLANK     FCDW DOCOL
          FCDW BL
          FCDW FILL
          FCDW SEMIS
;
;                                       HOLD
;                                       SCREEN 46 LINE 10
;
L1876     FCB $84,"HOL",$C4
          FCDW L1866    ; link to BLANKS
HOLD      FCDW DOCOL
          FCDW LIT,$FFFFFFFF
          FCDW HLD
          FCDW PSTOR
          FCDW HLD
          FCDW AT
          FCDW CSTOR
          FCDW SEMIS
;
;                                       PAD
;                                       SCREEN 46 LINE 13
;
L1890     FCB $83,"PA",$C4
          FCDW L1876    ; link to HOLD
PAD       FCDW DOCOL
          FCDW HERE
          FCDW CLIT
          FCB 68       ; PAD is 68 bytes above here.
          FCDW PLUS
          FCDW SEMIS
;
;                                       WORD
;                                       SCREEN 47 LINE 1
;
L1902     FCB $84,"WOR",$C4
          FCDW L1890    ; link to PAD
WORD      FCDW DOCOL
          FCDW BLK
          FCDW AT
          FCDW ZBRAN
L1908     FCDW L1914-L1908
          FCDW BLK
          FCDW AT
          FCDW BLOCK
          FCDW BRAN
L1913     FCDW L1916-L1913
L1914     FCDW TIB
          FCDW AT
L1916     FCDW IN
          FCDW AT
          FCDW PLUS
          FCDW SWAP
          FCDW ENCL
          FCDW HERE
          FCDW CLIT
          FCB $22
          FCDW BLANK
          FCDW IN
          FCDW PSTOR
          FCDW OVER
          FCDW SUB
          FCDW TOR
          FCDW R
          FCDW HERE
          FCDW CSTOR
          FCDW PLUS
          FCDW HERE
          FCDW ONEP
          FCDW RFROM
          FCDW CMOVE
          FCDW SEMIS
;
;                                       UPPER
;                                       SCREEN 47 LINE 12
;
L1943     FCB $85,"UPPE",$D2
          FCDW L1902    ; link to WORD
UPPER     FCDW DOCOL
          FCDW OVER     ; This routine converts text to U case
          FCDW PLUS     ; It allows interpretation from a term.
          FCDW SWAP     ; without a shift-lock.
          FCDW PDO
L1950     FCDW I
          FCDW CAT
          FCDW CLIT
          FCB $5F
          FCDW GREAT
          FCDW ZBRAN
L1956     FCDW L1961-L1956
          FCDW I
          FCDW CLIT
          FCB $20
          FCDW TOGGL
L1961     FCDW PLOOP
L1962     FCDW L1950-L1962
          FCDW SEMIS
;
;                                       (NUMBER)
;                                       SCREEN 48 LINE 1
;
L1968     FCB $88,"(NUMBER",$A9
          FCDW L1943    ; link to UPPER
PNUMB     FCDW DOCOL
L1971     FCDW ONEP
          FCDW DUP
          FCDW TOR
          FCDW CAT
          FCDW BASE
          FCDW AT
          FCDW DIGIT
          FCDW ZBRAN
L1979     FCDW L2001-L1979
          FCDW SWAP
          FCDW BASE
          FCDW AT
          FCDW USTAR
          FCDW DROP
          FCDW ROT
          FCDW BASE
          FCDW AT
          FCDW USTAR	; ustar leaves 64 bit product
          FCDW D64PLUS	; DPLUS is only 32 bits not 64 bits
          FCDW DPL
          FCDW AT
          FCDW ONEP
          FCDW ZBRAN
L1994     FCDW L1998-L1994
          FCDW ONE
          FCDW DPL
          FCDW PSTOR
L1998     FCDW RFROM
          FCDW BRAN
L2000     FCDW L1971-L2000
L2001     FCDW RFROM
          FCDW SEMIS
;
;                                       NUMBER
;                                       SCREEN 48 LINE 6
;
L2007     FCB $86,"NUMBE",$D2
          FCDW L1968    ; link to (NUMBER)
NUMBER    FCDW DOCOL
          FCDW ZERO
          FCDW ZERO
          FCDW ROT
          FCDW DUP
          FCDW ONEP
          FCDW CAT
          FCDW CLIT
          FCB $2D				; minus sign
          FCDW EQUAL
          FCDW DUP
          FCDW TOR
          FCDW PLUS
          FCDW LIT,$FFFFFFFF
L2023     FCDW DPL
          FCDW STORE
          FCDW PNUMB
          FCDW DUP
          FCDW CAT
          FCDW BL
          FCDW SUB
          FCDW ZBRAN
L2031     FCDW L2042-L2031
          FCDW DUP
          FCDW CAT
          FCDW CLIT
          FCB $2E				; decimal point
          FCDW SUB
          FCDW ZERO
          FCDW QERR
          FCDW ZERO
          FCDW BRAN
L2041     FCDW L2023-L2041
L2042     FCDW DROP
          FCDW RFROM
          FCDW ZBRAN
L2045     FCDW L2047-L2045
          FCDW DMINU
L2047     FCDW SEMIS
;
;                                       -FIND
;                                       SCREEN 48 LINE 12
;
L2052     FCB $85,"-FIN",$C4
          FCDW L2007    ; link to NUMBER
DFIND     FCDW DOCOL
          FCDW BL
          FCDW WORD
          FCDW HERE     ; )
          FCDW COUNT    ; |- Optional allowing free use of low
          FCDW UPPER    ; )  case from terminal
          FCDW HERE
          FCDW CON_
          FCDW AT
          FCDW AT
          FCDW PFIND
          FCDW DUP
          FCDW ZEQU
          FCDW ZBRAN
L2068     FCDW L2073-L2068
          FCDW DROP
          FCDW HERE
          FCDW LATES
          FCDW PFIND
L2073     FCDW SEMIS
;
;                                       (ABORT)
;                                       SCREEN 49 LINE 2
;
L2078     FCB $87,"(ABORT",$A9
          FCDW L2052    ; link to -FIND
PABOR     FCDW DOCOL
          FCDW ABORT
          FCDW SEMIS
;
;                                       ERROR
;                                       SCREEN 49 LINE 4
;
L2087     FCB $85,"ERRO",$D2
          FCDW L2078    ; link to (ABORT)
ERROR     FCDW DOCOL
          FCDW WARN
          FCDW AT
          FCDW ZLESS
          FCDW ZBRAN
L2094     FCDW L2096-L2094
          FCDW PABOR
L2096     FCDW HERE
          FCDW COUNT
          FCDW TYPE
          FCDW PDOTQ
          FCB 4,"  ? "
          FCDW MESS
          FCDW SPSTO
          FCDW DROP,DROP; make room for 2 error values
          FCDW IN
          FCDW AT
          FCDW BLK
          FCDW AT
          FCDW QUIT
          FCDW SEMIS
;
;                                       ID.
;                                       SCREEN 49 LINE 9
;
L2113     FCB $83,"ID",$AE
          FCDW L2087    ; link to ERROR
IDDOT     FCDW DOCOL
          FCDW PAD
          FCDW CLIT
          FCB $20
          FCDW CLIT
          FCB $5F
          FCDW FILL
          FCDW DUP
          FCDW PFA
          FCDW LFA
          FCDW OVER
          FCDW SUB
          FCDW PAD
          FCDW SWAP
          FCDW CMOVE
          FCDW PAD
          FCDW COUNT
          FCDW CLIT
          FCB $1F
          FCDW ANDD_
          FCDW TYPE
          FCDW SPACE
          FCDW SEMIS
;
;                                       CREATE
;                                       SCREEN 50 LINE 2
;
L2142     FCB $86,"CREAT",$C5
          FCDW L2113    ; link to ID
CREAT     FCDW DOCOL
          FCDW TIB      ;)
          FCDW HERE     ;|
          FCDW CLIT     ;|  6502 only, assures
          FCB $A0        ;|  room exists in dict.
          FCDW PLUS     ;|
          FCDW ULESS    ;|
          FCDW FOUR     ;|
          FCDW QERR     ;)
          FCDW DFIND
          FCDW ZBRAN
L2155     FCDW L2163-L2155
          FCDW DROP
          FCDW NFA
          FCDW IDDOT
          FCDW CLIT
          FCB 4
          FCDW MESS
          FCDW SPACE
L2163     FCDW HERE
          FCDW DUP
          FCDW CAT
          FCDW WIDTH
          FCDW AT
          FCDW MIN
          FCDW ONEP
          FCDW ALLOT
          FCDW DP       ;)
          FCDW CAT      ;| 6502 only. The code field
          FCDW CLIT     ;| must not straddle page
          FCB   $FD      ;| boundaries
          FCDW EQUAL    ;|
          FCDW ALLOT    ;)
          FCDW DUP
          FCDW CLIT
          FCB $A0
          FCDW TOGGL
          FCDW HERE
          FCDW ONE
          FCDW SUB
          FCDW CLIT
          FCB $80
          FCDW TOGGL
          FCDW LATES
          FCDW COMMA
          FCDW CURR
          FCDW AT
          FCDW STORE
          FCDW HERE
          FCDW FOURP
          FCDW COMMA
          FCDW SEMIS
;
;                                       [COMPILE]
;                                       SCREEN 51 LINE 2
;
L2200     FCB $C9,"[COMPILE",$DD
          FCDW L2142    ; link to CREATE
          FCDW DOCOL
          FCDW DFIND
          FCDW ZEQU
          FCDW ZERO
          FCDW QERR
          FCDW DROP
          FCDW CFA
          FCDW COMMA
          FCDW SEMIS
;
;                                       LITERAL
;                                       SCREEN 51 LINE 2
;
L2216     FCB $C7,"LITERA",$CC
          FCDW L2200    ; link to [COMPILE]
LITER     FCDW DOCOL
          FCDW STATE
          FCDW AT
          FCDW ZBRAN
L2222     FCDW L2226-L2222
          FCDW COMP
          FCDW LIT
          FCDW COMMA
L2226     FCDW SEMIS
;
;                                       DLITERAL
;                                       SCREEN 51 LINE 8
;
L2232     FCB $C8,"DLITERA",$CC
          FCDW L2216    ; link to LITERAL
DLIT      FCDW DOCOL
          FCDW STATE
          FCDW AT
          FCDW ZBRAN
L2238     FCDW L2242-L2238
          FCDW SWAP
          FCDW LITER
          FCDW LITER
L2242     FCDW SEMIS
;
;                                       ?STACK
;                                       SCREEN 51 LINE 13
;
L2248     FCB $86,"?STAC",$CB
          FCDW L2232    ; link to DLITERAL
QSTAC     FCDW DOCOL
          FCDW LIT
          FCDW TOS
          FCDW SPAT
          FCDW ULESS
          FCDW ONE
          FCDW QERR
          FCDW SPAT
          FCDW LIT
          FCDW BOS
          FCDW ULESS
          FCDW LIT
          FCDW 7
          FCDW QERR
          FCDW SEMIS
;
;                                       INTERPRET
;                                       SCREEN 52 LINE 2
;
L2269     FCB $89,"INTERPRE",$D4
          FCDW L2248    ; link to ?STACK
INTER     FCDW DOCOL
;		  FCDW TRON
L2272	  FCDW DFIND
          FCDW ZBRAN
L2274     FCDW L2289-L2274
          FCDW STATE
          FCDW AT
          FCDW LESS
          FCDW ZBRAN
L2279     FCDW L2284-L2279
          FCDW CFA
          FCDW COMMA
          FCDW BRAN
L2283     FCDW L2286-L2283
L2284     FCDW CFA
          FCDW EXEC
L2286     FCDW QSTAC
          FCDW BRAN
L2288     FCDW L2302-L2288
L2289     FCDW HERE
          FCDW NUMBER
          FCDW DPL
          FCDW AT
          FCDW ONEP
          FCDW ZBRAN
L2295     FCDW L2299-L2295
          FCDW DLIT
          FCDW BRAN
L2298     FCDW L2301-L2298
L2299     FCDW DROP
          FCDW LITER
L2301     FCDW QSTAC
L2302     FCDW BRAN
L2303     FCDW L2272-L2303
;
;                                       IMMEDIATE
;                                       SCREEN 53 LINE 1
;
L2309     FCB $89,"IMMEDIAT",$C5
          FCDW L2269;   ; link to INTERPRET
          FCDW DOCOL
          FCDW LATES
          FCDW CLIT
          FCB $40
          FCDW TOGGL
          FCDW SEMIS
;
;                                       VOCABULARY
;                                       SCREEN 53 LINE 4
;
L2321     FCB $8A,"VOCABULAR",$D9
          FCDW L2309    ; link to IMMEDIATE
          FCDW DOCOL
          FCDW BUILD
          FCDW LIT,$A081
          FCDW COMMA
          FCDW CURR
          FCDW AT
          FCDW CFA
          FCDW COMMA
          FCDW HERE
          FCDW VOCL
          FCDW AT
          FCDW COMMA
          FCDW VOCL
          FCDW STORE
          FCDW DOES
DOVOC     FCDW FOURP
          FCDW CON_
          FCDW STORE
          FCDW SEMIS
;
;                                       FORTH
;                                       SCREEN 53 LINE 9
;
L2346     FCB $C5,"FORT",$C8
          FCDW L2321    ; link to VOCABULARY
FORTH     FCDW DODOE
          FCDW DOVOC
          FCDW $A081
XFOR      FCDW NTOP     ; points to top name in FORTH
VL0       FCDW 0        ; last vocab link ends at zero
;
;                                       DEFINITIONS
;                                       SCREEN 53 LINE 11
;
;
L2357     FCB $8B,"DEFINITION",$D3
          FCDW L2346    ; link to FORTH
DEFIN     FCDW DOCOL
          FCDW CON_
          FCDW AT
          FCDW CURR
          FCDW STORE
          FCDW SEMIS
;
;                                       (
;                                       SCREEN 53 LINE 14
;
L2369     FCB $C1,$A8
          FCDW L2357    ; link to DEFINITIONS
          FCDW DOCOL
          FCDW CLIT
          FCB $29
          FCDW WORD
          FCDW SEMIS
;
;                                       QUIT
;                                       SCREEN 54 LINE 2
;
L2381     FCB $84,"QUI",$D4
          FCDW L2369    ; link to (
QUIT      FCDW DOCOL
          FCDW ZERO
          FCDW BLK
          FCDW STORE
          FCDW LBRAC
L2388     FCDW RPSTO
          FCDW CR
          FCDW QUERY
          FCDW INTER
          FCDW STATE
          FCDW AT
          FCDW ZEQU
          FCDW ZBRAN
L2396     FCDW L2399-L2396
          FCDW PDOTQ
          FCB 2,"OK"
L2399     FCDW BRAN
L2400     FCDW L2388-L2400
          FCDW SEMIS
;
;                                       ABORT
;                                       SCREEN 54 LINE 7
;
L2406     FCB $85,"ABOR",$D4
          FCDW L2381    ; link to QUIT
ABORT     FCDW DOCOL
          FCDW SPSTO
          FCDW DECIM
          FCDW DR0
          FCDW CR
          FCDW PDOTQ
          FCB 14,"fig-FORTH  1.0"
          FCDW FORTH
          FCDW DEFIN
          FCDW QUIT

L2410	  FCB $84,"TRO",$CE
		  FCDW  L2406
TRON	  FCDW	*+4
		  LDA	#1
		  STA	TRACEF
		  JMP	NEXT

L2420	  FCB $85,"TROF",$C6
		  FCDW	L2410
TROFF	  FCDW	*+4
		  CLR	TRACEF
		  JMP	NEXT
;
;                                       COLD
;                                       SCREEN 55 LINE 1
;
L2423     FCB $84,"COL",$C4
          FCDW L2420    ; link to ABORT
COLD      FCDW *+4
          LDD ORIG+$10   ; from cold start area
          STD FORTH+12
          LDD ORIG+$12
          STD FORTH+14

          LDD	ORIG+$18
          STD	UP
          LDD	ORIG+$1A
          STD	UP+2
		  LDY	#$5F
L2427	  CLR	FAR [UP],Y
		  DEY
		  CMPY	#0
		  BPL	L2427

          LDY #$2A
          BNE L2433
WARM      LDY #$1E
L2433     CLR TRACEF
;          INC TRACEF
		  LDD ORIG+$18
          STD UP
          LDD ORIG+$1A
          STD UP+2

L2437     LDD ORIG+$10,Y
          STD FAR [UP],Y
		  LEAY -2,Y
		  CMPY #0
          BPL L2437
          LDD #((ABORT+4)>>16) ; actually #>(ABORT+2)
          STD IP
          LDD #ABORT+4
          STD IP+2
;          CLD
;          LDA #$6C
;          STA W-1
          JMP RPSTO+4    ; And off we go !

DumpUserArea:
	LDY		#0
	JSR		FAR CRLF
dua_1:
	LDD		FAR [UP],Y
	JSR		FAR HEX4
	LEAY	2,Y
	LDD		FAR [UP],Y
	JSR		FAR HEX4
	LEAY	2,Y
	JSR		FAR CRLF
	CMPY	#$30
	BLO		dua_1
	RTS
;
;                                       S->D
;                                       SCREEN 56 LINE 1
;
L2453     FCB $84,"S->",$C4
          FCDW L2423    ; link to COLD
STOD      FCDW DOCOL
          FCDW DUP
          FCDW ZLESS
          FCDW MINUS
          FCDW SEMIS
;
;                                       +-
;                                       SCREEN 56 LINE 4
;
L2464     FCB $82,"+",$AD
          FCDW L2453    ; link to S->D
PM        FCDW DOCOL
          FCDW ZLESS
          FCDW ZBRAN
L2469     FCDW 8
          FCDW MINUS
L2471     FCDW SEMIS
;
;                                       D+-
;                                       SCREEN 56 LINE 6
;
L2476     FCB $83,"D+",$AD
          FCDW L2464    ; link to +-
DPM       FCDW DOCOL
          FCDW ZLESS
          FCDW ZBRAN
L2481     FCDW L2483-L2481
          FCDW DMINU
L2483     FCDW SEMIS
;
;                                       ABS
;                                       SCREEN 56 LINE 9
;
L2488     FCB $83,"AB",$D3
          FCDW L2476    ; link to D+-
ABS       FCDW DOCOL
          FCDW DUP
          FCDW PM
          FCDW SEMIS
;
;                                       DABS
;                                       SCREEN 56 LINE 10
;
L2498     FCB $84,"DAB",$D3
          FCDW L2488    ; link to ABS
DABS      FCDW DOCOL
          FCDW DUP
          FCDW DPM
          FCDW SEMIS
;
;                                       MIN
;                                       SCREEN 56 LINE 12
;
L2508     FCB $83,"MI",$CE
          FCDW L2498    ; link to DABS
MIN       FCDW DOCOL
          FCDW OVER
          FCDW OVER
          FCDW GREAT
          FCDW ZBRAN
L2515     FCDW L2517-L2515
          FCDW SWAP
L2517     FCDW DROP
          FCDW SEMIS
;
;                                       MAX
;                                       SCREEN 56 LINE 14
;
L2523     FCB $83,"MA",$D8
          FCDW L2508     ; link to MIN
MAX       FCDW DOCOL
          FCDW OVER
          FCDW OVER
          FCDW LESS
          FCDW ZBRAN
L2530     FCDW L2532-L2530
          FCDW SWAP
L2532     FCDW DROP
          FCDW SEMIS
;
;                                       M*
;                                       SCREEN 57 LINE 1
;
L2538     FCB $82,"M",$AA
          FCDW L2523    ; link to MAX
MSTAR     FCDW DOCOL
          FCDW OVER
          FCDW OVER
          FCDW XOR
          FCDW TOR
          FCDW ABS
          FCDW SWAP
          FCDW ABS
          FCDW USTAR
          FCDW RFROM
          FCDW DPM
          FCDW SEMIS
;
;                                       M/
;                                       SCREEN 57 LINE 3
;
L2556     FCB $82,"M",$AF
          FCDW L2538    ; link to M*
MSLAS     FCDW DOCOL
          FCDW OVER
          FCDW TOR
          FCDW TOR
          FCDW DABS
          FCDW R
          FCDW ABS
          FCDW USLAS
          FCDW RFROM
          FCDW R
          FCDW XOR
          FCDW PM
          FCDW SWAP
          FCDW RFROM
          FCDW PM
          FCDW SWAP
          FCDW SEMIS
;
;                                       *
;                                       SCREEN 57 LINE 7
;
L2579     FCB $81,$AA
          FCDW L2556    ; link to M/
STAR      FCDW DOCOL
          FCDW USTAR
          FCDW DROP
          FCDW SEMIS
;
;                                       /MOD
;                                       SCREEN 57 LINE 8
;
L2589     FCB $84,"/MO",$C4
          FCDW L2579    ; link to *
SLMOD     FCDW DOCOL
          FCDW TOR
          FCDW STOD
          FCDW RFROM
          FCDW MSLAS
          FCDW SEMIS
;
;                                       /
;                                       SCREEN 57 LINE 9
;
L2601     FCB $81,$AF
          FCDW L2589    ; link to /MOD
SLASH     FCDW DOCOL
          FCDW SLMOD
          FCDW SWAP
          FCDW DROP
          FCDW SEMIS
;
;                                       MOD
;                                       SCREEN 57 LINE 10
;
L2612     FCB $83,"MO",$C4
          FCDW L2601    ; link to /
MOD       FCDW DOCOL
          FCDW SLMOD
          FCDW DROP
          FCDW SEMIS
;
;                                       */MOD
;                                       SCREEN 57 LINE 11
;
L2622     FCB $85,"*/MO",$C4
          FCDW L2612    ; link to MOD
SSMOD     FCDW DOCOL
          FCDW TOR
          FCDW MSTAR
          FCDW RFROM
          FCDW MSLAS
          FCDW SEMIS
;
;                                       */
;                                       SCREEN 57 LINE 13
;
L2634     FCB $82,"*",$AF
          FCDW L2622    ; link to */MOD
SSLAS     FCDW DOCOL
          FCDW SSMOD
          FCDW SWAP
          FCDW DROP
          FCDW SEMIS
;
;                                       M/MOD
;                                       SCREEN 57 LINE 14
;
L2645     FCB $85,"M/MO",$C4
          FCDW L2634    ; link to */
MSMOD     FCDW DOCOL
          FCDW TOR
          FCDW ZERO
          FCDW R
          FCDW USLAS
          FCDW RFROM
          FCDW SWAP
          FCDW TOR
          FCDW USLAS
          FCDW RFROM
          FCDW SEMIS
;
;                                       USE
;                                       SCREEN 58 LINE 1
;
L2662     FCB $83,"US",$C5
          FCDW L2645    ; link to M/MOD
USE       FCDW DOVAR
          FCDW DAREA
;
;                                       PREV
;                                       SCREEN 58 LINE 2
;
L2670     FCB $84,"PRE",$D6
          FCDW L2662    ; link to USE
PREV      FCDW DOVAR
          FCDW DAREA
;
;                                       +BUF
;                                       SCREEN 58 LINE 4
;
;
L2678     FCB $84,"+BU",$C6
          FCDW L2670    ; link to PREV
PBUF      FCDW DOCOL
          FCDW LIT
          FCDW SSIZE+4  ; hold block #, one sector two num
          FCDW PLUS
          FCDW DUP
          FCDW LIMIT
          FCDW EQUAL
          FCDW ZBRAN
L2688     FCDW 12        ; L2691-L2688
          FCDW DROP
          FCDW FIRST
L2691     FCDW DUP
          FCDW PREV
          FCDW AT
          FCDW SUB
          FCDW SEMIS
;
;                                       UPDATE
;                                       SCREEN 58 LINE 8
;
L2700     FCB $86,"UPDAT",$C5
          FCDW L2678    ; link to +BUF
UPDAT     FCDW DOCOL
          FCDW PREV
          FCDW AT
          FCDW AT
          FCDW LIT,$80000000	; was $8000
          FCDW OR
          FCDW PREV
          FCDW AT
          FCDW STORE
          FCDW SEMIS
;
;                                       FLUSH
;
L2705     FCB $85,"FLUS",$C8
          FCDW L2700    ; link to UPDATE
          FCDW DOCOL
          FCDW LIMIT,FIRST,SUB
          FCDW BBUF,CLIT
          FCB 4
          FCDW PLUS,SLASH,ONEP
          FCDW ZERO,PDO
L2835     FCDW LIT,$7FFFFFFF,BUFFR
          FCDW DROP,PLOOP
L2839     FCDW L2835-L2839
          FCDW SEMIS
;
;                                       EMPTY-BUFFERS
;                                       SCREEN 58 LINE 11
;
L2716     FCB $8D,"EMPTY-BUFFER",$D3
          FCDW L2705    ; link to FLUSH
          FCDW DOCOL
          FCDW FIRST
          FCDW LIMIT
          FCDW OVER
          FCDW SUB
          FCDW ERASE
          FCDW SEMIS
;
;                                       DR0
;                                       SCREEN 58 LINE 14
;
L2729     FCB $83,"DR",$B0
          FCDW L2716    ; link to EMPTY-BUFFERS
DR0       FCDW DOCOL
          FCDW ZERO
          FCDW OFSET
          FCDW STORE
          FCDW SEMIS
;
;                                       DR1
;                                       SCREEN 58 LINE 15
;
L2740     FCB $83,"DR",$B1
          FCDW L2729    ; link to DR0
          FCDW DOCOL
          FCDW LIT,SECTR ; sectors per drive
          FCDW OFSET
          FCDW STORE
          FCDW SEMIS
;
;                                       BUFFER
;                                       SCREEN 59 LINE 1
;
L2751     FCB $86,"BUFFE",$D2
          FCDW L2740    ; link to DR1
BUFFR     FCDW DOCOL
          FCDW USE
          FCDW AT
          FCDW DUP
          FCDW TOR
L2758     FCDW PBUF
          FCDW ZBRAN
L2760     FCDW L2758-L2760
          FCDW USE
          FCDW STORE
          FCDW R
          FCDW AT
          FCDW ZLESS
          FCDW ZBRAN
L2767     FCDW L2776-L2767
          FCDW R
          FCDW FOURP
          FCDW R
          FCDW AT
          FCDW LIT,$7FFFFFFF
          FCDW ANDD_
          FCDW ZERO
          FCDW RSLW
L2776     FCDW R
          FCDW STORE
          FCDW R
          FCDW PREV
          FCDW STORE
          FCDW RFROM
          FCDW FOURP
          FCDW SEMIS
;
;                                       BLOCK
;                                       SCREEN 60 LINE 1
;
L2788     FCB $85,"BLOC",$CB
          FCDW L2751    ; link to BUFFER
BLOCK     FCDW DOCOL
          FCDW OFSET
          FCDW AT
          FCDW PLUS
          FCDW TOR
          FCDW PREV
          FCDW AT
          FCDW DUP
          FCDW AT
          FCDW R
          FCDW SUB
          FCDW DUP
          FCDW PLUS
          FCDW ZBRAN
L2804     FCDW L2830-L2804
L2805     FCDW PBUF
          FCDW ZEQU
          FCDW ZBRAN
L2808     FCDW L2818-L2808
          FCDW DROP
          FCDW R
          FCDW BUFFR
          FCDW DUP
          FCDW R
          FCDW ONE
          FCDW RSLW
          FCDW FOUR
          FCDW SUB
L2818     FCDW DUP
          FCDW AT
          FCDW R
          FCDW SUB
          FCDW DUP
          FCDW PLUS
          FCDW ZEQU
          FCDW ZBRAN
L2826     FCDW L2805-L2826
          FCDW DUP
          FCDW PREV
          FCDW STORE
L2830     FCDW RFROM
          FCDW DROP
          FCDW FOURP
          FCDW SEMIS    ; end of BLOCK
;
;
;                                       (LINE)
;                                       SCREEN 61 LINE 2
;
L2838     FCB $86,"(LINE",$A9
          FCDW L2788    ; link to BLOCK
PLINE     FCDW DOCOL
          FCDW TOR
          FCDW CSLL
          FCDW BBUF
          FCDW SSMOD
          FCDW RFROM
          FCDW BSCR
          FCDW STAR
          FCDW PLUS
          FCDW BLOCK
          FCDW PLUS
          FCDW CSLL
          FCDW SEMIS
;
;                                       .LINE
;                                       SCREEN 61 LINE 6
;
L2857     FCB $85,".LIN",$C5
          FCDW L2838    ; link to (LINE)
DLINE     FCDW DOCOL
          FCDW PLINE
          FCDW DTRAI
          FCDW TYPE
          FCDW SEMIS
;
;                                       MESSAGE
;                                       SCREEN 61 LINE 9
;
L2868     FCB $87,"MESSAG",$C5
          FCDW L2857    ; link to .LINE
MESS      FCDW DOCOL
          FCDW WARN
          FCDW AT
          FCDW ZBRAN
L2874     FCDW L2888-L2874
          FCDW DDUP
          FCDW ZBRAN
L2877     FCDW L2886-L2877
          FCDW CLIT
          FCB 4
          FCDW OFSET
          FCDW AT
          FCDW BSCR
          FCDW SLASH
          FCDW SUB
          FCDW DLINE
L2886     FCDW BRAN
L2887     FCDW L2891-L2887
L2888     FCDW PDOTQ
          FCB 6,"MSG # "
          FCDW DOT
L2891     FCDW SEMIS
;
;                                       LOAD
;                                       SCREEN 62 LINE 2
;
L2896     FCB $84,"LOA",$C4
          FCDW L2868    ; link to MESSAGE
LOAD      FCDW DOCOL
          FCDW BLK
          FCDW AT
          FCDW TOR
          FCDW IN
          FCDW AT
          FCDW TOR
          FCDW ZERO
          FCDW IN
          FCDW STORE
          FCDW BSCR
          FCDW STAR
          FCDW BLK
          FCDW STORE
          FCDW INTER
          FCDW RFROM
          FCDW IN
          FCDW STORE
          FCDW RFROM
          FCDW BLK
          FCDW STORE
          FCDW SEMIS
;
;                                       -->
;                                       SCREEN 62 LINE 6
;
L2924     FCB $C3,"--",$BE
          FCDW L2896    ; link to LOAD
          FCDW DOCOL
          FCDW QLOAD
          FCDW ZERO
          FCDW IN
          FCDW STORE
          FCDW BSCR
          FCDW BLK
          FCDW AT
          FCDW OVER
          FCDW MOD
          FCDW SUB
          FCDW BLK
          FCDW PSTOR
          FCDW SEMIS
;
;    XEMIT writes one ascii character to terminal
;
;
XEMIT     LDY	#$36
		  LDD	FAR [UP],Y
		  ADDD	#1
		  STD	FAR [UP],Y
		  LEAY	-2,Y
		  LDD	FAR [UP],Y
		  ADCB	#0
		  ADCA	#0
		  STD	FAR [UP],Y
		  LDA   3,U
		  JSR	FAR OUTCH
		  JMP	POP
;
;         XKEY reads one terminal keystroke to stack
;
;
XKEY      JSR	FAR INCH       ; might otherwise clobber it while
          TFR   A,B
          CLRA
		  TFR	D,X
		  CLRB
          JMP	PUSHOA
;
;         XQTER leaves a boolean representing terminal break
;
;
XQTER     CLRD
		  PSHS	D
		  JMP	PUSH
;		  LDA $C000      ; system depend port test
;          CMPA $C001
;          ANDA #1
;          JMP PUSHOA
;
;         XCR displays a CR and LF to terminal
;
;
XCR       JSR	FAR TCR        ; use monitor call
          JMP	NEXT
;
;                                       -DISC
;                                       machine level sector R/W
;
L3030     FCB $85,"-DIS",$C3
          FCDW L2924    ; link to -->
DDISC     FCDW *+4
		  JMP POPTWO	; added to bypass routine
          LDA 0,X
          STA $C60C
          STA $C60D      ; store sector number
          LDA 2,X
          STA $C60A
          STA $C60B      ; store track number
          LDA 4,X
          STA $C4CD
          STA $C4CE      ; store drive number
          STX XSAVE
          LDA $C4DA      ; sense read or write
          BNE L3032
          JSR $E1FE
          JMP L3040
L3032     JSR $E262
L3040     JSR $E3EF      ; head up motor off
          LDX XSAVE
          LDA $C4E1      ; report error code
          STA 4,X
          JMP POPTWO
;
;                                       -BCD
;                             Convert binary value to BCD
;
L3050     FCB $84,"-BC",$C4
          FCDW L3030    ; link to -DISC
DBCD      FCDW DOCOL
          FCDW ZERO,CLIT
          FCB 10
          FCDW USLAS,CLIT
          FCB 16
          FCDW STAR,OR,SEMIS
;
;                                       R/W
;                              Read or write one sector
;
L3060     FCB $83,"R/",$D7
          FCDW L3050    ; link to -BCD
RSLW      FCDW DOCOL
          FCDW ZEQU,LIT,$C4DA,CSTOR
          FCDW SWAP,ZERO,STORE
          FCDW ZERO,OVER,GREAT,OVER
          FCDW LIT,SECTL-1,GREAT,OR,CLIT
          FCB 6
          FCDW QERR
          FCDW ZERO,LIT,SECTR,USLAS,ONEP
          FCDW SWAP,ZERO,CLIT
          FCB $12
          FCDW USLAS,DBCD,SWAP,ONEP
          FCDW DBCD,DDISC,CLIT
          FCB 8
          FCDW QERR
          FCDW SEMIS
;
;
;
          FCDW SEMIS
;
;                                       '
;                                       SCREEN 72 LINE 2
;
L3202     FCB $C1,$A7
          FCDW L3060    ; link to R/W
TICK      FCDW DOCOL
          FCDW DFIND
          FCDW ZEQU
          FCDW ZERO
          FCDW QERR
          FCDW DROP
          FCDW LITER
          FCDW SEMIS
;
;                                       FORGET
;                                       Altered from model
;                                       SCREEN 72 LINE 6
;
L3217     FCB $86,"FORGE",$D4
          FCDW L3202    ; link to ' TICK
FORG      FCDW DOCOL
          FCDW TICK,NFA,DUP
          FCDW FENCE,AT,ULESS,CLIT
          FCB $15
          FCDW QERR,TOR,VOCL,AT
L3220     FCDW R,OVER,ULESS
          FCDW ZBRAN,L3225-*
          FCDW FORTH,DEFIN,AT,DUP
          FCDW VOCL,STORE
          FCDW BRAN,$FFFFFFFF-48+1 ; L3220-*
L3225     FCDW DUP,CLIT
          FCB 4
          FCDW SUB
L3228     FCDW PFA,LFA,AT
          FCDW DUP,R,ULESS
          FCDW ZBRAN,$FFFFFFFF-28+1 ; L3228-*
          FCDW OVER,FOUR,SUB,STORE
          FCDW AT,DDUP,ZEQU
          FCDW ZBRAN,$FFFFFFFF-77+1 ; L3225-*
          FCDW RFROM,DP,STORE
          FCDW SEMIS
;
;                                       BACK
;                                       SCREEN 73 LINE 1
;
L3250     FCB $84,"BAC",$CB
          FCDW L3217    ; link to FORGET
BACK      FCDW DOCOL
          FCDW HERE
          FCDW SUB
          FCDW COMMA
          FCDW SEMIS
;
;                                       BEGIN
;                                       SCREEN 73 LINE 3
;
L3261     FCB $C5,"BEGI",$CE
          FCDW L3250    ; link to BACK
          FCDW DOCOL
          FCDW QCOMP
          FCDW HERE
          FCDW ONE
          FCDW SEMIS
;
;                                       ENDIF
;                                       SCREEN 73 LINE 5
;
L3273     FCB $C5,"ENDI",$C6
          FCDW L3261    ; link to BEGIN
ENDIF     FCDW DOCOL
          FCDW QCOMP
          FCDW FOUR
          FCDW QPAIR
          FCDW HERE
          FCDW OVER
          FCDW SUB
          FCDW SWAP
          FCDW STORE
          FCDW SEMIS
;
;                                       THEN
;                                       SCREEN 73 LINE 7
;
L3290     FCB $C4,"THE",$CE
          FCDW L3273    ; link to ENDIF
          FCDW DOCOL
          FCDW ENDIF
          FCDW SEMIS
;
;                                       DO
;                                       SCREEN 73 LINE 9
;
L3300     FCB $C2,"D",$CF
          FCDW L3290    ; link to THEN
          FCDW DOCOL
          FCDW COMP
          FCDW PDO
          FCDW HERE
          FCDW THREE
          FCDW SEMIS
;
;                                       LOOP
;                                       SCREEN 73 LINE 11
;
;
L3313     FCB $C4,"LOO",$D0
          FCDW L3300    ; link to DO
          FCDW DOCOL
          FCDW THREE
          FCDW QPAIR
          FCDW COMP
          FCDW PLOOP
          FCDW BACK
          FCDW SEMIS
;
;                                       +LOOP
;                                       SCREEN 73 LINE 13
;
L3327     FCB $C5,"+LOO",$D0
          FCDW L3313    ; link to LOOP
          FCDW DOCOL
          FCDW THREE
          FCDW QPAIR
          FCDW COMP
          FCDW PPLOO
          FCDW BACK
          FCDW SEMIS
;
;                                       UNTIL
;                                       SCREEN 73 LINE 15
;
L3341     FCB $C5,"UNTI",$CC
          FCDW L3327    ; link to +LOOP
UNTIL     FCDW DOCOL
          FCDW ONE
          FCDW QPAIR
          FCDW COMP
          FCDW ZBRAN
          FCDW BACK
          FCDW SEMIS
;
;                                       END
;                                       SCREEN 74 LINE 1
;
L3355     FCB $C3,"EN",$C4
          FCDW L3341    ; link to UNTIL
          FCDW DOCOL
          FCDW UNTIL
          FCDW SEMIS
;
;                                       AGAIN
;                                       SCREEN 74 LINE 3
;
L3365     FCB $C5,"AGAI",$CE
          FCDW L3355    ; link to END
AGAIN     FCDW DOCOL
          FCDW ONE
          FCDW QPAIR
          FCDW COMP
          FCDW BRAN
          FCDW BACK
          FCDW SEMIS
;
;                                       REPEAT
;                                       SCREEN 74 LINE 5
;
L3379     FCB $C6,"REPEA",$D4
          FCDW L3365    ; link to AGAIN
          FCDW DOCOL
          FCDW TOR
          FCDW TOR
          FCDW AGAIN
          FCDW RFROM
          FCDW RFROM
          FCDW FOUR
          FCDW SUB
          FCDW ENDIF
          FCDW SEMIS
;
;                                       IF
;                                       SCREEN 74 LINE 8
;
L3396     FCB $C2,"I",$C6
          FCDW L3379    ; link to REPEAT
IF        FCDW DOCOL
          FCDW COMP
          FCDW ZBRAN
          FCDW HERE
          FCDW ZERO
          FCDW COMMA
          FCDW FOUR
          FCDW SEMIS
;
;                                       ELSE
;                                       SCREEN 74 LINE 10
;
L3411     FCB $C4,"ELS",$C5
          FCDW L3396    ; link to IF
          FCDW DOCOL
          FCDW FOUR
          FCDW QPAIR
          FCDW COMP
          FCDW BRAN
          FCDW HERE
          FCDW ZERO
          FCDW COMMA
          FCDW SWAP
          FCDW FOUR
          FCDW ENDIF
          FCDW FOUR
          FCDW SEMIS
;
;                                       WHILE
;                                       SCREEN 74 LINE 13
;
L3431     FCB $C5,"WHIL",$C5
          FCDW L3411    ; link to ELSE
          FCDW DOCOL
          FCDW IF
          FCDW FOURP
          FCDW SEMIS
;
;                                       SPACES
;                                       SCREEN 75 LINE 1
;
L3442     FCB $86,"SPACE",$D3
          FCDW L3431    ; link to WHILE
SPACS     FCDW DOCOL
          FCDW ZERO
          FCDW MAX
          FCDW DDUP
          FCDW ZBRAN
L3449     FCDW L3455-L3449
          FCDW ZERO
          FCDW PDO
L3452     FCDW SPACE
          FCDW PLOOP
L3454     FCDW L3452-L3454
L3455     FCDW SEMIS
;
;                                       <#
;                                       SCREEN 75 LINE 3
;
L3460     FCB $82,"<",$A3
          FCDW L3442    ; link to SPACES
BDIGS     FCDW DOCOL
          FCDW PAD
          FCDW HLD
          FCDW STORE
          FCDW SEMIS
;
;                                       #>
;                                       SCREEN 75 LINE 5
;
L3471     FCB $82,"#",$BE
          FCDW L3460    ; link to <#
EDIGS     FCDW DOCOL
          FCDW DROP
          FCDW DROP
          FCDW HLD
          FCDW AT
          FCDW PAD
          FCDW OVER
          FCDW SUB
          FCDW SEMIS
;
;                                       SIGN
;                                       SCREEN 75 LINE 7
;
L3486     FCB $84,"SIG",$CE
          FCDW L3471    ; link to #>
SIGN      FCDW DOCOL
          FCDW ROT
          FCDW ZLESS
          FCDW ZBRAN
L3492     FCDW L3496-L3492
          FCDW CLIT
          FCB $2D
          FCDW HOLD
L3496     FCDW SEMIS
;
;                                       #
;                                       SCREEN 75 LINE 9
;
L3501     FCB $81,$A3
          FCDW L3486    ; link to SIGN
DIG       FCDW DOCOL
          FCDW BASE
          FCDW AT
          FCDW MSMOD
          FCDW ROT
          FCDW CLIT
          FCB 9
          FCDW OVER
          FCDW LESS
          FCDW ZBRAN
L3513     FCDW L3517-L3513
          FCDW CLIT
          FCB 7
          FCDW PLUS
L3517     FCDW CLIT
          FCB $30
          FCDW PLUS
          FCDW HOLD
          FCDW SEMIS
;
;                                       #S
;                                       SCREEN 75 LINE 12
;
L3526     FCB $82,"#",$D3
          FCDW L3501    ; link to #
DIGS      FCDW DOCOL
L3529     FCDW DIG
          FCDW OVER
          FCDW OVER
          FCDW OR
          FCDW ZEQU
          FCDW ZBRAN
L3535     FCDW L3529-L3535
          FCDW SEMIS
;
;                                       D.R
;                                       SCREEN 76 LINE 1
;
L3541     FCB $83,"D.",$D2
          FCDW L3526    ; link to #S
DDOTR     FCDW DOCOL
          FCDW TOR
          FCDW SWAP
          FCDW OVER
          FCDW DABS
          FCDW BDIGS
          FCDW DIGS
          FCDW SIGN
          FCDW EDIGS
          FCDW RFROM
          FCDW OVER
          FCDW SUB
          FCDW SPACS
          FCDW TYPE
          FCDW SEMIS
;
;                                       D.
;                                       SCREEN 76 LINE 5
;
L3562     FCB $82,"D",$AE
          FCDW L3541    ; link to D.R
DDOT      FCDW DOCOL
          FCDW ZERO
          FCDW DDOTR
          FCDW SPACE
          FCDW SEMIS
;
;                                       .R
;                                       SCREEN 76 LINE 7
;
L3573     FCB $82,".",$D2
          FCDW L3562     ; link to D.
DOTR      FCDW DOCOL
          FCDW TOR
          FCDW STOD
          FCDW RFROM
          FCDW DDOTR
          FCDW SEMIS
;
;                                       .
;                                       SCREEN 76  LINE  9
;
L3585     FCB $81,$AE
          FCDW L3573    ; link to .R
DOT       FCDW DOCOL
          FCDW STOD
          FCDW DDOT
          FCDW SEMIS
;
;                                       ?
;                                       SCREEN 76 LINE 11
;
L3595     FCB $81,$BF
          FCDW L3585    ; link to .
QUES      FCDW DOCOL
          FCDW AT
          FCDW DOT
          FCDW SEMIS
;
;                                       LIST
;                                       SCREEN 77 LINE 2
;
L3605     FCB $84,"LIS",$D4
          FCDW L3595    ; link to ?
LIST      FCDW DOCOL
          FCDW DECIM
          FCDW CR
          FCDW DUP
          FCDW SCR
          FCDW STORE
          FCDW PDOTQ
          FCB 6,"SCR # "
          FCDW DOT
          FCDW CLIT
          FCB 16
          FCDW ZERO
          FCDW PDO
L3620     FCDW CR
          FCDW I
          FCDW THREE
          FCDW DOTR
          FCDW SPACE
          FCDW I
          FCDW SCR
          FCDW AT
          FCDW DLINE
          FCDW PLOOP
L3630     FCDW $FFFFFFD8
          FCDW CR
          FCDW SEMIS
;
;                                       INDEX
;                                       SCREEN 77 LINE 7
;
L3637     FCB $85,"INDE",$D8
          FCDW L3605    ; link to LIST
          FCDW DOCOL
          FCDW CR
          FCDW ONEP
          FCDW SWAP
          FCDW PDO
L3647     FCDW CR
          FCDW I
          FCDW THREE
          FCDW DOTR
          FCDW SPACE
          FCDW ZERO
          FCDW I
          FCDW DLINE
          FCDW QTERM
          FCDW ZBRAN
L3657     FCDW L3659-L3657
          FCDW LEAVE
L3659     FCDW PLOOP
L3660     FCDW L3647-L3660
          FCDW CLIT
          FCB $0C      ; form feed for printer
          FCDW EMIT
          FCDW SEMIS
;
;                                       TRIAD
;                                       SCREEN 77 LINE 12
;
L3666     FCB $85,"TRIA",$C4
          FCDW L3637    ; link to INDEX
          FCDW DOCOL
          FCDW THREE
          FCDW SLASH
          FCDW THREE
          FCDW STAR
          FCDW THREE
          FCDW OVER
          FCDW PLUS
          FCDW SWAP
          FCDW PDO
L3681     FCDW CR
          FCDW I
          FCDW LIST
          FCDW PLOOP
L3685     FCDW L3681-L3685
          FCDW CR
          FCDW CLIT
          FCB $F
          FCDW MESS
          FCDW CR
          FCDW CLIT
          FCB $0C      ;  form feed for printer
          FCDW EMIT
          FCDW SEMIS
;
;                                       VLIST
;                                       SCREEN 78 LINE 2
;
;
L3696     FCB $85,"VLIS",$D4
          FCDW L3666    ; link to TRIAD
VLIST     FCDW DOCOL
          FCDW CLIT
          FCB $80
          FCDW OUT
          FCDW STORE
          FCDW CON_
          FCDW AT
          FCDW AT
L3706     FCDW OUT
          FCDW AT
          FCDW CSLL
          FCDW GREAT
          FCDW ZBRAN
L3711     FCDW L3716-L3711
          FCDW CR
          FCDW ZERO
          FCDW OUT
          FCDW STORE
L3716     FCDW DUP
          FCDW IDDOT
          FCDW SPACE
          FCDW SPACE
          FCDW PFA
          FCDW LFA
          FCDW AT
          FCDW DUP
          FCDW ZEQU
          FCDW QTERM
          FCDW OR
          FCDW ZBRAN
L3728     FCDW L3706-L3728
          FCDW DROP
          FCDW SEMIS
;
;                                       MON
;                                       SCREEN 79 LINE 3
;
NTOP      FCB $83,"MO",$CE
          FCDW L3696    ; link to VLIST
MON       FCDW *+4
          STU USAVE
          SWI3       ; break to monitor which is assumed
          LDU USAVE ; to save this as reentry point
          JMP NEXT
;
DumpDStack
		  JSR	FAR CRLF
		  LDD	,U
		  JSR	FAR HEX4
		  LDD	2,U
		  JSR	FAR HEX4
		  JSR	FAR CRLF
		  LDD	4,U
		  JSR	FAR HEX4
		  LDD	6,U
		  JSR	FAR HEX4
		  JSR	FAR CRLF
		  LDD	8,U
		  JSR	FAR HEX4
		  LDD	10,U
		  JSR	FAR HEX4
		  JSR	FAR CRLF
		  LDD	12,U
		  JSR	FAR HEX4
		  LDD	14,U
		  JSR	FAR HEX4
		  JSR	FAR CRLF
		  RTS

         .END           ; end of listing
