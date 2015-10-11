		.OPTION M68
BOS       EQU $20           ; bottom of data stack, in zero-page.
TOS       EQU $9E           ; top of data stack, in zero-page.
N         EQU TOS+8         ; scratch workspace.
IP        EQU N+8           ; interpretive pointer.
W         EQU IP+4          ; code field pointer.
UP        EQU W+4           ; user area pointer.
XSAVE     EQU UP+4          ; temporary for X register.
YSAVE	  EQU XSAVE+4
;
TIBX      EQU $0100         ; terminal input buffer of 84 bytes.
ORIG      EQU $0200         ; origin of FORTH's Dictionary.
MEM       EQU $4000         ; top of assigned memory+1 byte.
UAREA     EQU MEM-128       ; 128 bytes of user area
DAREA     EQU UAREA-BMAG    ; disk buffer space.
;
;         Monitor calls for terminal support
;
OUTCH     EQU $D2C1         ; output one ASCII char. to term.
INCH      EQU $D1DC         ; input one ASCII char. to term.
TCR       EQU $D0F1         ; terminal return and line feed.
;
;    From DAREA downward to the top of the dictionary is free
;    space where the user's applications are compiled.
;
;    Boot up parameters. This area provides jump vectors
;    to Boot up  code, and parameters describing the system.
;
;
          *=*+2
;
                         ; User cold entry point
                         ; User cold entry point
ENTER     NOP            ; Vector to COLD entry
          JMP FAR COLD+4     ;
REENTR    NOP            ; User Warm entry point
          JMP WARM       ; Vector to WARM entry
          FCW $0004    ; 6502 in radix-36
          FCW $5ED2    ;
          FCW NTOP     ; Name address of MON
          FCW $7F      ; Backspace Character
          FCW UAREA    ; Initial User Area
          FCW TOS      ; Initial Top of Stack
          FCW $1FF     ; Initial Top of Return Stack
          FCW TIBX     ; Initial terminal input buffer
;
;
          FCW 31       ; Initial name field width
          FCW 0        ; 0=nod disk, 1=disk
          FCW TOP      ; Initial fence address
          FCW TOP      ; Initial top of dictionary
          FCW VL0      ; Initial Vocabulary link ptr.
;
;    The following offset adjusts all code fields to avoid an
;    address ending $XXFF. This must be checked and altered on
;    any alteration , for the indirect jump at W-1 to operate !
;
	CLRD
	STD		IP
	STD		IP+2
	INC		IP
	STD		W
	STD		W+2
	LEAY	0
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
L22       FCB $83,'LI',$D4            ; <--- name field
;                          <----- link field
          FCDW 00			; last link marked by zero
LIT       FCDW *+4			; <----- code address field
          LDB	FAR (IP)    ; <----- start of parameter field
		  CLRA
          PSHS	D
		  JSR	INC_IP
L30       LDA	FAR (IP)
L31		  JSR	INC_IP
PUSH	  LEAU	-4,U
PUT		  STD	2,U
		  PULS	D
		  STD	,U

NEXT      LDD	FAR (IP)
		  STD	W
		  LDY	#2
		  LDD	FAR (IP),Y
		  STD	W+2
		  LDD	IP+2
		  ADDD	#4
		  STD	IP+2
		  LDD	IP
		  ADCB	#0
		  ADCA	#0
		  STD	IP
		  JMP	FAR [W]
	
;    CLIT pushes the next inline byte to data stack
;
L35       FCB $84,'CLI',$D4
          FCDW L22      ; Link to LIT
CLIT      FCDW *+4
          LDA	FAR (IP),Y
          PSHS	A
          TFR	Y,D
          BRA	L31        ; a forced branch into LIT

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
LETTER    EQU $D2C1         ; print accum as one ASCII character
ONEKEY    EQU $D1DC         ; wait for keystroke
XW        EQU $12           ; scratch reg. to next code field add
NP        EQU $14           ; scratch reg. pointing to name field
;
;
TRACE     STX XSAVE
          JSR FAR CRLF
          LDA IP+1
          JSR FAR HEX2
          LDA IP+2
          JSR FAR HEX2
          LDA IP+3
          JSR FAR HEX2       ; print IP, the interpreter pointer
          JSR FAR XBLANK
;
;
          LDA #0
          LDA FAR (IP),Y
          STA XW
          STA NP         ; fetch the next code field pointer
          INY
		  BNE TRACE_1
		  INC IP+1
TRACE_1:
          LDA FAR (IP),Y
          STA XW+1
          STA NP+1
          JSR FAR PRNAM  ; print dictionary name
;
          LDA XW
          JSR FAR HEX2   ; print code field address
          LDA XW+1
          JSR FAR HEX2
		  LDA #0
		  JSR FAR HEX2
          JSR FAR XBLANK
;
          LDA XSAVE      ; print stack location in zero-page
          JSR FAR HEX2
		  LDA XSAVE+1
		  JSR FAR HEX2
          JSR FAR XBLANK
;
          LDA #1         ; print return stack bottom in page 1
		  TFR S,D
		  EXG A,B
          JSR FAR HEX2
		  EXG A,B
          JSR FAR HEX2
          JSR FAR XBLANK
;
          JSR FAR ONEKEY ; wait for operator keystroke
          LDX XSAVE      ; just to pinpoint early problems
          LDY #0
          RTS
;
;    TCOLON is called from DOCOLON to label each point
;    where FORTH 'nests' one level.
;
TCOLON    STX XSAVE
          LDD W
          STD NP         ; locate the name of the called word
          LDD W+2
          STD NP+2
          JSR FAR CRLF
          LDA #$3A       ; ':
          JSR FAR LETTER
          JSR FAR XBLANK
          JSR FAR PRNAM
          LDX XSAVE
          RTS
;
;    Print name by it's code field address in NP
;
PRNAM     STY YSAVE
		  BSR DECNP
          BSR DECNP
          BSR DECNP
          LDY #0
PN1       BSR DECNP
          LDA FAR (NP),Y     ; loop till D7 in name set
          BPL PN1
PN2       INY
          LDA FAR (NP),Y
          JSR FAR LETTER     ; print letters of name field
          LDA FAR (NP),Y
          BPL PN2
          JSR FAR XBLANK
          LDY YSAVE
          RTF
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

SETUP     STY YSAVE
		  LDY #0
		  ASLA
		  ASLA
          STA N-1
L63       LDA 0,U
          STA N,Y
          INX
          INY
          CPY N-1
          BNE L63
          LDY YSAVE
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
          JMP	FAR [W]    ; to JMP (W) in z-page
;
;                                       BRANCH
;                                       SCREEN 15 LINE 11
;
L89       FCB $86,"BRANC",$C8
          FCW L75      ; link to EXCECUTE
BRAN      FCW *+2
BRAN_4:
		  LDD	FAR (IP),Y
		  PSHU	D
		  LEAY  2,Y
		  BNE	BRAN_1
		  INC	IP+1
BRAN_1:
		  LDD	FAR (IP),Y
		  LEAY  2,Y
		  BNE	BRAN_2
		  INC	IP+1
BRAN_2:
		  ADDD  IP+2
		  STD	IP+2
		  BCC  	BRAN_3
		  LDD	IP
		  ADDD	#1
		  STD	IP
BRAN_3:
		  PULU  D
		  ADDD	IP
		  STDD	IP
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
BUMP      LEAY	4,Y
		  BNE	L122
		  INC	IP+1
L122	  JMP	NEXT
;
;                                       (LOOP)
;                                       SCREEN 16 LINE 1
;
L127      FCB $86,"(LOOP",$A9
          FCDW L107     ; link to 0BRANCH
PLOOP     FCDW L130
L130      STX  XSAVE
          TSX
          INC $101,X
          BNE PL1
          INC $102,X
;
PL1       CLC
          LDA $103,X
          SBC $101,X
          LDA $104,X
          SBC $102,X
;
PL2       LDX XSAVE
          ASL A
          BCC BRAN+2
          PLA
          PLA
          PLA
          PLA
          JMP BUMP

;
;                                       (DO)
;                                       SCREEN 17 LINE 2
;
L185      FCB $84,"(DO",$A9
          FCW L154     ; link to (+LOOP)
PDO       FCW *+2
		  LDD	6,X
		  PSHU	D
		  LDD	4,X
		  PSHU	D
		  LDD	2,X
		  PSHU	D
		  LDD	,X
		  PSHU	D
;
POPTWO    LEAX	8,X
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
L207      .BYTE $81,$C9
          .WORD L185     ; link to (DO)
I         .WORD R+2      ; share the code for R
;
;                                       DIGIT
;                                       SCREEN 18 LINE 1
;
L214      .BYTE $85,'DIGI',$D4
          .WORD L207     ; link to I
DIGIT     .WORD *+2
          SEC
          LDA 2,X
          SBC #$30
          BMI L234
          CMP #$A
          BMI L227
          SEC
          SBC #7
          CMP #$A
          BMI L234
L227      CMP 0,X
          BPL L234
          STA 2,X
          LDA #1
          PHA
          TYA
          JMP PUT        ; exit true with converted value
L234      TYA
          PHA
          INX
          INX
          JMP PUT        ; exit false with bad conversion
;
;                                       (FIND)
;                                       SCREEN 19 LINE 1
;
L243      FCB $86,'(FIND',$A9
          FCDW L214   ; Link to DIGIT
PFIND     FCDW *+4
          LDA #4
          JSR SETUP
          STY YSAVE
L249      LDY #0
          LDA (N),Y
          EOR (N+4),Y
;
;
          AND #$3F
          BNE L281
L254      INY
          LDA FAR (N),Y
          EOR FAR (N+4),Y
          ASL A
          BNE L280
          BCC L254
          LDX XSAVE
          DEX
          DEX
          DEX
          DEX
          CLC
          TYA
          ADC #5
          ADC N
          STA 2,X
          LDY #0
          TYA
          ADC N+1
          STA 3,X
          STY 1,X
          LDA FAR (N),Y
          STA 0,X
          LDA #1
          PHA
          JMP PUSH
L280      BCS L284
L281      INY
          LDA FAR (N),Y
          BPL L281
L284      INY
          LDX	FAR (N),Y
		  LEAY	2,Y
          LDD	FAR (N),Y
          STD	N+2
          STX	N
          ORA N
          BNE L249
          LDY YSAVE
          LDA #0
          PHA
          JMP PUSH       ; exit false upon reading null link
;
;                                       ENCLOSE
;                                       SCREEN 20 LINE 1
;
L301      FCB $87,"ENCLOS",$C5
          FCW L243     ; link to (FIND)
ENCL      FCW *+2
          LDA #2
          JSR SETUP
		  LEAX	-8,X
          STY 3,X
          STY 1,X
          DEY
L313      INY
          LDA (N+2),Y
          CMP N
          BEQ L313
          STY 4,X
L318      LDA (N+2),Y
          BNE L327
          STY 2,X
          STY 0,X
          TYA
          CMP 4,X
          BNE L326
          INC 2,X
L326      JMP NEXT
L327      STY 2,X
          INY
          CMP N
          BNE L318
          STY 0,X
          JMP NEXT
;
;                                       EMIT
;                                       SCREEN 21 LINE 5
;
L337      FCB $84,'EMI',$D4
          FCW L301     ; link to ENCLOSE
EMIT      FCW XEMIT    ; Vector to code for KEY
;
;                                       KEY
;                                       SCREEN 21 LINE 7
;
L344      FCB $83,'KE',$D9
          FCW L337     ; link to EMIT
KEY       FCW XKEY     ; Vector to code for KEY
;
;                                       ?TERMINAL
;                                       SCREEN 21 LINE 9
;
L351      FCB $89,'?TERMINA',$CC
          FCW L344     ; link to KEY
QTERM     FCW XQTER    ; Vector to code for ?TERMINAL
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
;                                       AND
;                                       SCREEN 25 LINE 2
;
L453      FCB $83,"AN",$C4
          FCDW	L418     ; link to U/
ANDD      FCDW	*+4
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
BINARY    LEAX	4,X
          JMP PUT
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
;
PUSHOA    CLRD
		  PSHU	D
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
          LDY #6		 ; 6 or 12 ? User area format ????
          LDX FAR (UP),Y ; load data stack pointer (X reg) from
          JMP NEXT		 ; silent user variable S0.
;
;                                       RP!
;                                       SCREEN 26 LINE 8
;
L522      FCB $83,"RP",$A1
          FCDW	L511     ; link to SP!
RPSTO     FCDW	*+4
							; load return stack pointer (machine
          LDY	#8          ; stack pointer) from silent user
          LDS	FAR (UP),Y  ; VARIABLE R0
          JMP	NEXT
;
;                                       ;S
;                                       SCREEN 26 LINE 12
;
L536      FCB $82,';',$D3
          FCDW L522     ; link to RP!
SEMIS     FCDW *+4
          PULS	D,X
		  STD	IP+2
		  STX	IP
          JMP	NEXT
;
;                                       LEAVE
;                                       SCREEN 27 LINE  1
;
L548      FCB $85,"LEAV",$C5
          FCDW	L536     ; link to ;S
LEAVE     FCDW	*+4
          STX	XSAVE
          TFR	S,X
		  LDD	$101,X
		  STD	$105,X
		  LDD	$103,X
		  STD	$107,X
          LDX	XSAVE
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
		  LDD	,U
		  LDX	2,U
		  PSHS	D,X
		  JMP	NEXT
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
		  INCA
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
		  LDD	,U
		  ADDD	4,U
		  STD	4,U
		  LDD	2,U
		  ADCB	6,U
		  ADCA	7,U
		  STD	6,U
		  LEAU	4,U
          JMP NEXT

;
;                                       D+
;                                       SCREEN 29 LINE 4
;
L649      FCB $82,"D",$AB
          FCDW L632     ;    LINK TO +
DPLUS     FCDW *+4
		  LDD	,U
		  ADDD	4,U
		  STD	4,U
		  LDD	2,U
		  ADCB	6,U
		  ADCA	7,U
		  STD	6,U
		  LEAU	4,U
          JMP NEXT
;
;                                       MINUS
;                                       SCREEN 29 LINE 9
;
L670      FCB $85,"MINU",$D3
          FCDW L649     ; link to D+
MINUS     FCDW *+4
		  LDD	2,U
		  EORA	#$FF
		  EORB	#$FF
		  STD	2,U
		  LDD	,U
		  EORA	#$FF
		  EORB	#$FF
		  STD	,U
		  LDD	2,U
		  ADDD	#1
		  STD	2,U
		  LDD	,U
		  ADCB	#0
		  ADCA	#0
		  STD	,U
          JMP NEXT
;
;                                       DMINUS
;                                       SCREEN 29 LINE 12
;
L685      FCB	$86,"DMINU",$D3
          FCDW L670     ; link to  MINUS
DMINU     FCDW *+4
		  LDD	2,U
		  EORA	#$FF
		  EORB	#$FF
		  STD	2,U
		  LDD	,U
		  EORA	#$FF
		  EORB	#$FF
		  STD	,U
		  LDD	2,U
		  ADDD	#1
		  STD	2,U
		  LDD	,U
		  ADCB	#0
		  ADCA	#0
		  STD	,U
          JMP NEXT
;
;                                       OVER
;                                       SCREEN 30 LINE 1
;
L700      FCB $84,"OVE",$D2
          FCDW L685     ; link to DMINUS
OVER      FCDW *+4
		  LDD	,U
		  LDX	2,U
		  PSHS	D,X
		  JMP	NEXT
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
		  LDD	,U
		  LDX	4,U
		  STD	4,U
		  STX	,U
		  LDD	2,U
		  LDX	6,U
		  STD	6,U
		  STX	2,U
          JMP	NEXT
;
;                                       DUP
;                                       SCREEN 30 LINE 21
;
L733      FCB $83,"DU",$D0
          FCDW	L718     ; link to SWAP
DUP       FCDW	*+4
		  PULU	D,X
		  PSHU	D,X
		  PSHU	D,X
		  JMP	NEXT
;
;                                       +!
;                                       SCREEN 31 LINE 2
;
L744      FCB $82,'+',$A1
          FCDW L733     ; link to DUP
PSTOR     FCDW *+4
		  STY	YSAVE
	      PULU	D,X		 ; get address of value
		  STD	TMP		 ; store in TMP pointer
		  STX	TMP+2
		  LDY	#2
		  LDD	FAR (TMP),Y	 ; add second on stack to
		  ADDD	2,U		 ; value
		  STD	2,U
		  LDD	FAR (TMP)
		  ADCB	1,U
		  ADCA  ,U
		  STD   ,U
		  LDY	YSAVE
		  JMP	NEXT
;
;                                       TOGGLE
;                                       SCREEN 31 LINE 7
;
L762      FCB $81,'TOGGL',$C5
          FCDW	L744     ; link to +!
TOGGL     FCDW	*+4
          LDA	FAR (4,U)  ; complement bits in memory address
          EOR	3,U        ; second on stack, by pattern on
          STA	FAR (4,U)  ; bottom of stack.
		  LEAU	8,U
          JMP	NEXT
;
;                                       @
;                                       SCREEN 32 LINE 1
;
L773      FCB $81,$C0
          FCDW L762     ; link to TOGGLE
AT        FCDW *+4
          LDD	FAR (0,U)
          PSHS	D
		  LDD	2,U
		  ADDD	#2
		  STD	2,U
		  LDD	,U
		  ADCB	#0
		  ADCA	#0
		  STD	,U
	      LDD	FAR (0,U)
          JMP	PUT
;
;                                       C@
;                                       SCREEN 32 LINE 5
;
L787      FCB $82,"C",$C0
          FCDW	L773		; link to @
CAT       FCDW	*+4
          LDB	FAR (0,U)	; fetch byte addressed by bottom of
		  CLRA
          STD	2,U			; stack to stack, zeroing the high
		  CLRB
          STD	,U			; byte
          JMP	NEXT
;
;                                       W@
;                                       SCREEN 32 LINE 1
;
L790      FCB $82,"W",$C0
          FCDW	L787     ; link to C@
WAT       FCDW	*+4
          LDD	FAR (0,U)
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
          STD	FAR (0,U); store second high 16 bits of 32bit value on stack
                         ; to memory as addressed by bottom
                        ; of stack.
		  LDD	2,U
		  ADDD	#2
		  STD	2,U
		  LDD	,U
		  ADCB	#0
		  ADCA	#0
		  STD	,U
		  LDD	6,U
          STD	FAR (0,U); store second low 16 bits of 32bit value on stack
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
          STA	(0,U)
          JMP	POPTWO
;
;                                       W!
;                                       SCREEN 32 LINE 12
;
L815      FCB $82,"W",$A1
          FCDW L813     ; link to C!
WSTOR     FCDW *+4
          LDD	6,U
          STD	(0,U)
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
          FCDW	CON
          FCDW	STORE
          FCDW	CREAT
          FCDW	RBRAC
          FCDW	PSCOD
;
DOCOL     LDD	IP+2
		  LDX	IP
		  PSHS	D,X
          JSR	TCOLON     ; mark the start of a traced : def.
		  LDD	W+2
		  ADDD	#4
		  STD	IP+2
		  LDD	W
		  ADCB	#0
		  ADCA	#0
		  STD	W
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
          LDD	FAR (W),Y
          PSHS	D
          LEAY	2,Y
          LDD	FAR (W),Y
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
DOUSE     LDY	#4
		  CLRA
          LDB	FAR (W),Y
          ADDD	UP+2
		  EXG	D,X
		  CLRD
		  ADDD	UP
		  PSHS	D
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
;                                       BL
;                                       SCREEN 35 LINE 4
;
L952      FCB $82,"B",$CC
          FCDW L944     ; link to 3
BL        FCDW DOCON
          FCDW $20
;
;                                       C/L
;                                       SCREEN 35 LINE 5
;                                       Characters per line
L960      FCB $83,"C/",$CC
          FCDW L952     ; link to BL
CSLL      FCDW DOCON
          FCDW 84						; was 64
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
          FCB $A
;
;                                       WIDTH
;                                       SCREEN 36 LINE 5
;
L1018     FCB $85,"WIDT",$C8
          FCDW L1010    ; link to TIB
WIDTH     FCDW DOUSE
          FCB $C
;
;                                       WARNING
;                                       SCREEN 36 LINE 6
;
L1026     FCB $87,"WARNIN",$C7
          FCDW L1018    ; link to WIDTH
WARN      FCDW DOUSE
          FCB $E
;
;                                       FENCE
;                                       SCREEN 36 LINE 7
;
L1034     FCB $85,"FENC",$C5
          FCDW L1026    ; link to WARNING
FENCE     FCDW DOUSE
          FCB $10
;
;
;                                       DP
;                                       SCREEN 36 LINE 8
;
L1042     FCB $82,"D",$D0
          FCDW L1034    ; link to FENCE
DP        FCDW DOUSE
          FCB $12
;
;                                       VOC-LINK
;                                       SCREEN 36 LINE 9
;
L1050     FCB $88,"VOC-LIN",$CB
          FCDW L1042    ; link to DP
VOCL      FCDW DOUSE
          FCB $14
;
;                                       BLK
;                                       SCREEN 36 LINE 10
;
L1058     FCB $83,"BL",$CB
          FCDW L1050    ; link to VOC-LINK
BLK       FCDW DOUSE
          FCB $16
;
;                                       IN
;                                       SCREEN 36 LINE 11
;
L1066     FCB $82,"I",$CE
          FCDW L1058    ; link to BLK
IN        FCDW DOUSE
          FCB $18
;
;                                       OUT
;                                       SCREEN 36 LINE 12
;
L1074     FCB $83,"OU",$D4
          FCDW L1066    ; link to IN
OUT       FCDW DOUSE
          FCB $1A
;
;                                       SCR
;                                       SCREEN 36 LINE 13
;
L1082     FCB $83,"SC",$D2
          FCDW L1074    ; link to OUT
SCR       FCDW DOUSE
          FCB $1C
;
;                                       OFFSET
;                                       SCREEN 37 LINE 1
;
L1090     FCB $86,"OFFSE",$D4
          FCDW L1082    ; link to SCR
OFSET     FCDW DOUSE
          FCB $1E
;
;                                       CONTEXT
;                                       SCREEN 37 LINE 2
;
L1098     FCB $87,"CONTEX",$D4
          FCDW L1090    ; link to OFFSET
CON       FCDW DOUSE
          FCB $20
;
;                                       CURRENT
;                                       SCREEN 37 LINE 3
;
L1106     FCB $87,"CURREN",$D4
          FCDW L1098    ; link to CONTEXT
CURR      FCDW DOUSE
          FCB $22
;
;                                       STATE
;                                       SCREEN 37 LINE 4
;
L1114     FCB $85,"STAT",$C5
          FCDW L1106    ; link to CURRENT
STATE     FCDW DOUSE
          FCB $24
;
;                                       BASE
;                                       SCREEN 37 LINE 5
;
L1122     FCB $84,"BAS",$C5
          FCDW L1114    ; link to STATE
BASE      FCDW DOUSE
          FCB $26
;
;                                       DPL
;                                       SCREEN 37 LINE 6
;
L1130     FCB $83,"DP",$CC
          FCDW L1122    ; link to BASE
DPL       FCDW DOUSE
          FCB $28
;
;                                       FLD
;                                       SCREEN 37 LINE 7
;
L1138     FCB $83,"FL",$C4
          FCDW L1130    ; link to DPL
FLD       FCDW DOUSE
          FCB $2A
;
;
;
;                                       CSP
;                                       SCREEN 37 LINE 8
;
L1146     FCB $83,"CS",$D0
          FCDW L1138    ; link to FLD
CSP       FCDW DOUSE
          FCB $2C
;
;                                       R#
;                                       SCREEN 37  LINE 9
;
L1154     FCB $82,"R",$A3
          FCDW L1146    ; link to CSP
RNUM      FCDW DOUSE
          FCB $2E
;
;                                       HLD
;                                       SCREEN 37 LINE 10
;
L1162     FCB $83,"HL",$C4
          FCDW L1154    ; link to R#
HLD       FCDW DOUSE
          FCB $30
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
;
;
;                                       (;CODE)
;                                       SCREEN 42 LINE 2
;
L1555     FCB $87,'(;CODE',$A9
          FCDW L1543    ; link to DECIMAL
PSCOD     FCDW DOCOL
          FCDW RFROM
          FCDW LATES
          FCDW PFA
          FCDW CFA
          FCDW STORE
          FCDW SEMIS
;
;                                       COLD
;                                       SCREEN 55 LINE 1
;
L2423     FCB $84,"COL",$C4
          FCDW L2406    ; link to ABORT
COLD      FDCW *+4
          LDA ORIG+$0C   ; from cold start area
          STA FORTH+6
          LDA ORIG+$0D
          STA FORTH+7
          LDY #$15
          BNE L2433
WARM      LDY #$0F
L2433     LDA ORIG+$10
          STA UP
          LDA ORIG+$11
          STA UP+1
L2437     LDA ORIG+$0C,Y
          STA FAR (UP),Y
          DEY
          BPL  L2437
          LDD #((ABORT+4)>>16) ; actually #>(ABORT+2)
          STD IP
          LDD #ABORT+4
          STD IP+2
          CLD
;          LDA #$6C
;          STA W-1
          JMP RPSTO+2    ; And off we go !
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
L3202     .BYTE $C1,$A7
          FCW L3060    ; link to R/W
TICK      FCW DOCOL
          FCW DFIND
          FCW ZEQU
          FCW ZERO
          FCW QERR
          FCW DROP
          FCW LITER
          FCW SEMIS
;
;                                       FORGET
;                                       Altered from model
;                                       SCREEN 72 LINE 6
;
L3217     .BYTE $86,'FORGE',$D4
          FCW L3202    ; link to ' TICK
FORG      FCW DOCOL
          FCW TICK,NFA,DUP
          FCW FENCE,AT,ULESS,CLIT
          .BYTE $15
          FCW QERR,TOR,VOCL,AT
L3220     FCW R,OVER,ULESS
          FCW ZBRAN,L3225-*
          FCW FORTH,DEFIN,AT,DUP
          FCW VOCL,STORE
          FCW BRAN,$FFFF-24+1 ; L3220-*
L3225     FCW DUP,CLIT
          .BYTE 4
          FCW SUB
L3228     FCW PFA,LFA,AT
          FCW DUP,R,ULESS
          FCW ZBRAN,$FFFF-14+1 ; L3228-*
          FCW OVER,TWO,SUB,STORE
          FCW AT,DDUP,ZEQU
          FCW ZBRAN,$FFFF-39+1 ; L3225-*
          FCW RFROM,DP,STORE
          FCW SEMIS
;
;                                       BACK
;                                       SCREEN 73 LINE 1
;
L3250     .BYTE $84,'BAC',$CB
          FCW L3217    ; link to FORGET
BACK      FCW DOCOL
          FCW HERE
          FCW SUB
          FCW COMMA
          FCW SEMIS
;
;                                       BEGIN
;                                       SCREEN 73 LINE 3
;
L3261     .BYTE $C5,'BEGI',$CE
          FCW L3250    ; link to BACK
          FCW DOCOL
          FCW QCOMP
          FCW HERE
          FCW ONE
          FCW SEMIS
;
;                                       ENDIF
;                                       SCREEN 73 LINE 5
;
L3273     .BYTE $C5,'ENDI',$C6
          FCW L3261    ; link to BEGIN
ENDIF     FCW DOCOL
          FCW QCOMP
          FCW TWO
          FCW QPAIR
          FCW HERE
          FCW OVER
          FCW SUB
          FCW SWAP
          FCW STORE
          FCW SEMIS
;
;                                       THEN
;                                       SCREEN 73 LINE 7
;
L3290     .BYTE $C4,'THE',$CE
          FCW L3273    ; link to ENDIF
          FCW DOCOL
          FCW ENDIF
          FCW SEMIS
;
;                                       DO
;                                       SCREEN 73 LINE 9
;
L3300     .BYTE $C2,'D',$CF
          FCW L3290    ; link to THEN
          FCW DOCOL
          FCW COMP
          FCW PDO
          FCW HERE
          FCW THREE
          FCW SEMIS
;
;                                       LOOP
;                                       SCREEN 73 LINE 11
;
;
L3313     .BYTE $C4,'LOO',$D0
          FCW L3300    ; link to DO
          FCW DOCOL
          FCW THREE
          FCW QPAIR
          FCW COMP
          FCW PLOOP
          FCW BACK
          FCW SEMIS
;
;                                       +LOOP
;                                       SCREEN 73 LINE 13
;
L3327     .BYTE $C5,'+LOO',$D0
          FCW L3313    ; link to LOOP
          FCW DOCOL
          FCW THREE
          FCW QPAIR
          FCW COMP
          FCW PPLOO
          FCW BACK
          FCW SEMIS
;
;                                       UNTIL
;                                       SCREEN 73 LINE 15
;
L3341     .BYTE $C5,'UNTI',$CC
          FCW L3327    ; link to +LOOP
UNTIL     FCW DOCOL
          FCW ONE
          FCW QPAIR
          FCW COMP
          FCW ZBRAN
          FCW BACK
          FCW SEMIS
;
;                                       END
;                                       SCREEN 74 LINE 1
;
L3355     .BYTE $C3,'EN',$C4
          FCW L3341    ; link to UNTIL
          FCW DOCOL
          FCW UNTIL
          FCW SEMIS
;
;                                       AGAIN
;                                       SCREEN 74 LINE 3
;
L3365     .BYTE $C5,'AGAI',$CE
          FCW L3355    ; link to END
AGAIN     FCW DOCOL
          FCW ONE
          FCW QPAIR
          FCW COMP
          FCW BRAN
          FCW BACK
          FCW SEMIS
;
;                                       REPEAT
;                                       SCREEN 74 LINE 5
;
L3379     .BYTE $C6,'REPEA',$D4
          FCW L3365    ; link to AGAIN
          FCW DOCOL
          FCW TOR
          FCW TOR
          FCW AGAIN
          FCW RFROM
          FCW RFROM
          FCW TWO
          FCW SUB
          FCW ENDIF
          FCW SEMIS
;
;                                       IF
;                                       SCREEN 74 LINE 8
;
L3396     .BYTE $C2,'I',$C6
          FCW L3379    ; link to REPEAT
IF        FCW DOCOL
          FCW COMP
          FCW ZBRAN
          FCW HERE
          FCW ZERO
          FCW COMMA
          FCW TWO
          FCW SEMIS
;
;                                       ELSE
;                                       SCREEN 74 LINE 10
;
L3411     .BYTE $C4,'ELS',$C5
          FCW L3396    ; link to IF
          FCW DOCOL
          FCW TWO
          FCW QPAIR
          FCW COMP
          FCW BRAN
          FCW HERE
          FCW ZERO
          FCW COMMA
          FCW SWAP
          FCW TWO
          FCW ENDIF
          FCW TWO
          FCW SEMIS
;
;                                       WHILE
;                                       SCREEN 74 LINE 13
;
L3431     .BYTE $C5,'WHIL',$C5
          FCW L3411    ; link to ELSE
          FCW DOCOL
          FCW IF
          FCW TWOP
          FCW SEMIS
;
;                                       SPACES
;                                       SCREEN 75 LINE 1
;
L3442     .BYTE $86,'SPACE',$D3
          FCW L3431    ; link to WHILE
SPACS     FCW DOCOL
          FCW ZERO
          FCW MAX
          FCW DDUP
          FCW ZBRAN
L3449     FCW $0C      ; L3455-L3449
          FCW ZERO
          FCW PDO
L3452     FCW SPACE
          FCW PLOOP
L3454     FCW $FFFC    ; L3452-L3454
L3455     FCW SEMIS
;
;                                       <#
;                                       SCREEN 75 LINE 3
;
L3460     .BYTE $82,'<',$A3
          FCW L3442    ; link to SPACES
BDIGS     FCW DOCOL
          FCW PAD
          FCW HLD
          FCW STORE
          FCW SEMIS
;
;                                       #>
;                                       SCREEN 75 LINE 5
;
L3471     .BYTE $82,'#',$BE
          FCW L3460    ; link to <#
EDIGS     FCW DOCOL
          FCW DROP
          FCW DROP
          FCW HLD
          FCW AT
          FCW PAD
          FCW OVER
          FCW SUB
          FCW SEMIS
;
;                                       SIGN
;                                       SCREEN 75 LINE 7
;
L3486     .BYTE $84,'SIG',$CE
          FCW L3471    ; link to #>
SIGN      FCW DOCOL
          FCW ROT
          FCW ZLESS
          FCW ZBRAN
L3492     FCW $7       ; L3496-L3492
          FCW CLIT
          .BYTE $2D
          FCW HOLD
L3496     FCW SEMIS
;
;                                       #
;                                       SCREEN 75 LINE 9
;
L3501     .BYTE $81,$A3
          FCW L3486    ; link to SIGN
DIG       FCW DOCOL
          FCW BASE
          FCW AT
          FCW MSMOD
          FCW ROT
          FCW CLIT
          .BYTE 9
          FCW OVER
          FCW LESS
          FCW ZBRAN
L3513     FCW 7        ; L3517-L3513
          FCW CLIT
          .BYTE 7
          FCW PLUS
L3517     FCW CLIT
          .BYTE $30
          FCW PLUS
          FCW HOLD
          FCW SEMIS
;
;                                       #S
;                                       SCREEN 75 LINE 12
;
L3526     .BYTE $82,'#',$D3
          FCW L3501    ; link to #
DIGS      FCW DOCOL
L3529     FCW DIG
          FCW OVER
          FCW OVER
          FCW OR
          FCW ZEQU
          FCW ZBRAN
L3535     FCW $FFF4    ; L3529-L3535
          FCW SEMIS
;
;                                       D.R
;                                       SCREEN 76 LINE 1
;
L3541     .BYTE $83,'D.',$D2
          FCW L3526    ; link to #S
DDOTR     FCW DOCOL
          FCW TOR
          FCW SWAP
          FCW OVER
          FCW DABS
          FCW BDIGS
          FCW DIGS
          FCW SIGN
          FCW EDIGS
          FCW RFROM
          FCW OVER
          FCW SUB
          FCW SPACS
          FCW TYPE
          FCW SEMIS
;
;                                       D.
;                                       SCREEN 76 LINE 5
;
L3562     .BYTE $82,'D',$AE
          FCW L3541    ; link to D.R
DDOT      FCW DOCOL
          FCW ZERO
          FCW DDOTR
          FCW SPACE
          FCW SEMIS
;
;                                       .R
;                                       SCREEN 76 LINE 7
;
L3573     .BYTE $82,'.',$D2
          FCW L3562     ; link to D.
DOTR      FCW DOCOL
          FCW TOR
          FCW STOD
          FCW RFROM
          FCW DDOTR
          FCW SEMIS
;
;                                       .
;                                       SCREEN 76  LINE  9
;
L3585     .BYTE $81,$AE
          FCW L3573    ; link to .R
DOT       FCW DOCOL
          FCW STOD
          FCW DDOT
          FCW SEMIS
;
;                                       ?
;                                       SCREEN 76 LINE 11
;
L3595     .BYTE $81,$BF
          FCW L3585    ; link to .
QUES      FCW DOCOL
          FCW AT
          FCW DOT
          FCW SEMIS
;
;                                       LIST
;                                       SCREEN 77 LINE 2
;
L3605     .BYTE $84,'LIS',$D4
          FCW L3595    ; link to ?
LIST      FCW DOCOL
          FCW DECIM
          FCW CR
          FCW DUP
          FCW SCR
          FCW STORE
          FCW PDOTQ
          .BYTE 6,'SCR # '
          FCW DOT
          FCW CLIT
          .BYTE 16
          FCW ZERO
          FCW PDO
L3620     FCW CR
          FCW I
          FCW THREE
          FCW DOTR
          FCW SPACE
          FCW I
          FCW SCR
          FCW AT
          FCW DLINE
          FCW PLOOP
L3630     FCW $FFEC
          FCW CR
          FCW SEMIS;
;                                       INDEX
;                                       SCREEN 77 LINE 7
;
L3637     .BYTE $85,'INDE',$D8
          FCW L3605    ; link to LIST
          FCW DOCOL
          FCW CR
          FCW ONEP
          FCW SWAP
          FCW PDO
L3647     FCW CR
          FCW I
          FCW THREE
          FCW DOTR
          FCW SPACE
          FCW ZERO
          FCW I
          FCW DLINE
          FCW QTERM
          FCW ZBRAN
L3657     FCW 4        ; L3659-L3657
          FCW LEAVE
L3659     FCW PLOOP
L3660     FCW $FFE6    ; L3647-L3660
          FCW CLIT
          .BYTE $0C      ; form feed for printer
          FCW EMIT
          FCW SEMIS
;
;                                       TRIAD
;                                       SCREEN 77 LINE 12
;
L3666     FCB $85,'TRIA',$C4
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
L3685     FCDW $FFFFFFF0    ; L3681-L3685
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
L3696     FCB $85,'VLIS',$D4
          FCDW L3666    ; link to TRIAD
VLIST     FCDW DOCOL
          FCDW CLIT
          FCB $80
          FCDW OUT
          FCDW STORE
          FCDW CON
          FCDW AT
          FCDW AT
L3706     FCDW OUT
          FCDW AT
          FCDW CSLL
          FCDW GREAT
          FCDW ZBRAN
L3711     FCDW $A       ; L3716-L3711
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
L3728     FCDW $FFFFFFA8    ; L3706-L3728
          FCDW DROP
          FCDW SEMIS
;
;                                       MON
;                                       SCREEN 79 LINE 3
;
NTOP      FCB $83,"MO",$CE
          FCDW L3696    ; link to VLIST
MON       FCDW *+4
          STX XSAVE
		  STY YSAVE
          BRK       ; break to monitor which is assumed
		  LDY YSAVE
          LDX XSAVE ; to save this as reentry point
          JMP NEXT
;
TOP       .END           ; end of listing
