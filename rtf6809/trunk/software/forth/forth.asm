; Fig FORTH ported for the RTF6809
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
BOS       EQU $20           ; bottom of data stack, in zero-page.
TOS       EQU $9E           ; top of data stack, in zero-page.
N         EQU TOS+8         ; scratch workspace.
IP        EQU N+8           ; interpretive pointer.
W         EQU IP+4          ; code field pointer.
UP        EQU W+4           ; user area pointer.
XSAVE     EQU UP+4          ; temporary for X register.
YSAVE	  EQU XSAVE+2
USAVE		EQU	YSAVE+2
;
TIBX      EQU $0100         ; terminal input buffer of 84 bytes.
ORIG      EQU $C000         ; origin of FORTH's Dictionary.
MEM       EQU $C000         ; top of assigned memory+1 byte.
UAREA     EQU MEM-256       ; 256 bytes of user area
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
		  ORG $C000
;          *=*+2
;
                         ; User cold entry point
                         ; User cold entry point
ENTER     NOP            ; Vector to COLD entry
          JMP COLD+4     ;
REENTR    NOP            ; User Warm entry point
          JMP WARM       ; Vector to WARM entry
          FCDW $0004    ; 6502 in radix-36
          FCDW $5ED2    ;
          FCDW NTOP     ; Name address of MON
          FCDW $7F      ; Backspace Character
          FCDW UAREA    ; Initial User Area
          FCDW TOS      ; Initial Top of Stack
          FCDW $1FF     ; Initial Top of Return Stack
          FCDW TIBX     ; Initial terminal input buffer
;
;
          FCDW 31       ; Initial name field width
          FCDW 0        ; 0=nod disk, 1=disk
          FCDW TOP      ; Initial fence address
          FCDW TOP      ; Initial top of dictionary
          FCDW VL0      ; Initial Vocabulary link ptr.
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
          LDD	FAR (IP)    ; <----- start of parameter field
          PSHS	D
		  BSR	INC_IP
		  BSR	INC_IP
L30       LDD	FAR (IP)
		  BSR	INC_IP
L31		  BSR	INC_IP
PUSH	  LEAU	-4,U
PUT		  STD	2,U
		  PULS	D
		  STD	,U

NEXT      LDD	FAR (IP)
		  STD	W
		  LDY	#2
		  LDD	FAR (IP),Y
		  STD	W+2
		  LDD	IP+2		; inline increment IP by 4
		  ADDD	#4
		  STD	IP+2
		  LDD	IP
		  ADCB	#0
		  ADCA	#0
		  STD	IP
		  JMP	FAR [W]

; Increment IP by 1
; Most of the time only the LSB of the IP needs to be incremented, so avoid a 
; carry chain adder.

INC_IP	  INC  IP+3
		  BNE  INC_IP_1
		  INC  IP+2
		  BNE  INC_IP_1
		  INC  IP+1
		  BNE  INC_IP_1
		  INC  IP
INC_IP_1  RTS
	
; Increment IP by 2

INC2_IP	  BSR	INC_IP
		  BRA	INC_IP

;    CLIT pushes the next inline byte to data stack
;
L35       FCB $84,'CLI',$D4
          FCDW L22      ; Link to LIT
CLIT      FCDW *+4
		  CLRD
		  PSHS	D
          LDB	FAR (IP)
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
BRAN      FCDW *+4
BRAN_4:
		  LDD	FAR (IP),Y
		  PSHU	D
		  JSR	INC2_IP
		  LDD	FAR (IP),Y
		  JSR	INC2_IP
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
BUMP      LDD	IP+2
		  ADDD  #4
		  STD	IP+2
		  LDD	IP
		  ADCB	#0
		  ADCA	#0
		  STD	IP
L122	  JMP	NEXT
;
;                                       (LOOP)
;                                       SCREEN 16 LINE 1
;
L127      FCB $86,"(LOOP",$A9
          FCDW L107     ; link to 0BRANCH
PLOOP     FCDW L130
L130      LDD	2,S		; Increment LOOP var
		  ADDD	#1
		  STD	2,S
		  LDD	,S
		  ADCB	#0
		  ADCA	#0
		  STD	,S
;
PL1       LDD	6,S		; compare LOOP var to limit
		  SUBD  2,S
		  LDD	4,S
		  SBCB	1,S
		  SBCA	0,S
;
PL2       ASL	A
          BCC	BRAN+4
		  LEAS	8,S		; LOOP finished, pop stacked info
          JMP	BUMP

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
L214      FCB $85,'DIGI',$D4
          FCDW L207     ; link to I
DIGIT     FCDW *+4
          LDA	3,U
          SUBA	#$30
          BMI	L234
          CMPA	#$A
          BMI	L227
          SUBA	#7
          CMP	#$A
          BMI	L234
L227      CMP	0,X
          BPL	L234
          STA	2,X
          LDA	#1
          PHA
          TYA
          JMP	PUT        ; exit true with converted value
L234      TYA
          PHA
          INX
          INX
          JMP	PUT        ; exit false with bad conversion
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
          STA	FAR (0,U)
          JMP	POPTWO
;
;                                       W!
;                                       SCREEN 32 LINE 12
;
L815      FCB $82,"W",$A1
          FCDW L813     ; link to C!
WSTOR     FCDW *+4
          LDD	6,U
          STD	FAR (0,U)
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
;                                       HERE
;                                       SCREEN 38 LINE 3
;
L1190     FCB $84,"HER",$C5
          FCDW L1180    ; link to 2+
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
          FCDW TWO
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
L1246     FCB $82,'U',$BC
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
L1274     FCB $83,'RO',$D4
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
L1301     FCDW $8       ; L1303-L1301
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
L1320     FCDW $FFFFFFE2    ; L1312-L1320
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
          FCB 4
          FCDW SUB
          FCDW SEMIS
;
;                                       CFA
;                                       SCREEN 39 LINE 12
;
L1350     FCB $83,"CF",$C1
          FCDW L1339    ; link to LFA
CFA       FCDW DOCOL
          FCDW TWO
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
          FCB $5
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
          FCB 5
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
L1402     FCDW 16        ; L1406-L1402
          FCDW ERROR
          FCDW BRAN
L1405     FCDW 8        ; L1407-L1405
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
          FCDW TWOP
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
DODOE     LDD	IP+2	; X and D in right order ???
		  LDX	IP
		  PSHS	D,X
		  LDY	#4
		  LDD	FAR (W),Y
		  STD	IP
		  LEAY	2,Y
		  LDD	FAR (W),Y
		  STD	IP+2
		  LDD	W+2
		  ADDD	#4
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
L1639     FCDW $30      ; L1651-L1639
          FCDW OVER
          FCDW PLUS
          FCDW SWAP
          FCDW PDO
L1644     FCDW I
          FCDW CAT
          FCDW EMIT
          FCDW PLOOP
L1648     FCDW $FFFFFFF0    ; L1644-L1648
          FCDW BRAN
L1650     FCDW $8       ; L1652-L1650
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
L1672     FCDW 16        ; L1676-L1672
          FCDW LEAVE
          FCDW BRAN
L1675     FCDW 12        ; L1678-L1675
L1676     FCDW ONE
          FCDW SUB
L1678     FCDW PLOOP
L1679     FCDW $FFFFFFC0    ; L1663-L1679
          FCDW SEMIS
;
;                                       (.")
;                                       SCREEN 44 LINE 8
L1685     FCB $84,"(.\"",$A9
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
L1709     FCDW $28      ;L1719-L1709
          FCDW COMP
          FCDW PDOTQ
          FCDW WORD
          FCDW HERE
          FCDW CAT
          FCDW ONEP
          FCDW ALLOT
          FCDW BRAN
L1718     FCDW $14       ;L1723-L1718
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
          FCB $E
          FCDW PORIG
          FCDW AT
          FCDW EQUAL
          FCDW ZBRAN
L1744     FCDW $3E       ; L1760-L1744
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
L1759     FCDW $4E       ; L1779-L1759
L1760     FCDW DUP
          FCDW CLIT
          FCB $0D
          FCDW EQUAL
          FCDW ZBRAN
L1765     FCDW $1C       ; L1772-L1765
          FCDW LEAVE
          FCDW DROP
          FCDW BL
          FCDW ZERO
          FCDW BRAN
L1771     FCDW 8        ; L1773-L1771
L1772     FCDW DUP
L1773     FCDW I
          FCDW CSTOR
          FCDW ZERO
          FCDW I
          FCDW ONEP
          FCDW STORE
L1779     FCDW EMIT
          FCDW PLOOP
L1781     FCDW $FFFFFF52
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
L1810     FCDW $54      ; L1830-l1810
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
L1824     FCDW 16        ; L1828-L1824
          FCDW QEXEC
          FCDW RFROM
          FCDW DROP
L1828     FCDW BRAN
L1829     FCDW 12        ; L1832-L1829
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
;                                       COLD
;                                       SCREEN 55 LINE 1
;
L2423     FCB $84,"COL",$C4
          FCDW L2406    ; link to ABORT
COLD      FCDW *+4
          LDD ORIG+$10   ; from cold start area
          STD FORTH+12
          LDD ORIG+$12
          STD FORTH+14

          LDY #$2A
          BNE L2433
WARM      LDY #$1E
L2433     LDD ORIG+$18
          STD UP
          LDD ORIG+$1A
          STD UP+2

L2437     LDD ORIG+$10,Y
          STD FAR (UP),Y
          DEY
		  DEY
          BPL L2437
          LDD #((ABORT+4)>>16) ; actually #>(ABORT+2)
          STD IP
          LDD #ABORT+4
          STD IP+2
          CLD
;          LDA #$6C
;          STA W-1
          JMP RPSTO+4    ; And off we go !
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
          FCDW OVER,TWO,SUB,STORE
          FCDW AT,DDUP,ZEQU
          FCDW ZBRAN,$FFFFFFFF-78+1 ; L3225-*
          FCDW RFROM,DP,STORE
          FCDW SEMIS
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
L3526     FCB $82,"#",$D3
          FCDW L3501    ; link to #
DIGS      FCDW DOCOL
L3529     FCDW DIG
          FCDW OVER
          FCDW OVER
          FCDW OR
          FCDW ZEQU
          FCDW ZBRAN
L3535     FCDW $FFFFFFE8    ; L3529-L3535
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
L3657     FCDW 8        ; L3659-L3657
          FCDW LEAVE
L3659     FCDW PLOOP
L3660     FCDW $FFFFFFCC    ; L3647-L3660
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
L3696     FCB $85,"VLIS",$D4
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
          STU USAVE
          BRK       ; break to monitor which is assumed
          LDU USAVE ; to save this as reentry point
          JMP NEXT
;
TOP       .END           ; end of listing
