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
          JMP COLD+2     ;
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
L22       .BYTE $83,'LI',$D4            ; <--- name field
;                          <----- link field
          FCW 00			; last link marked by zero
LIT       FCW *+2			; <----- code address field
          LDA	FAR (IP),Y    ; <----- start of parameter field
          PSH	A
		  LEAY	1,Y
		  BNE	LIT_0001
          INC	IP+1
LIT_0001:
L30       LDA	FAR (IP),Y
L31		  LEAY	1,Y
		  BNE	L31_0001
          INC	IP+1
L31_0001:
PUSH:
	LEAX	-4,X
PUT:
	STD		2,X
	PULU	D
	STD		,X

NEXT:
    LDD		FAR (IP),Y          ; Y is used as the low order 16 bits of IP
    LEAY	2,Y
    BNE		NEXT_1
    INC		IP+1                   ;IP+2,IP+3=00 64k bank aligned
NEXT_1:
    STD		W+1                  ; set bits [23:8]
	JMP		FAR [W]

;    CLIT pushes the next inline byte to data stack
;
L35       .BYTE $84,'CLI',$D4
          FCW L22      ; Link to LIT
CLIT      FCW *+2
          LDA	FAR (IP),Y
          PSH	A
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
		  BCS   DECNP1
		  STD	NP+2
		  RTS
DECNP1:
		  STD	NP+2
		  LDD	NP
		  SUBD	#1
		  STD	NP
          RTS


SETUP     STY YSAVE
		  LDY #0
		  ASLA
          STA N-1
L63       LDA 0,X
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
          FCW L35      ; link to CLIT
EXEC      FCW *+2
          LDD	,X++
          STA	W
          LDD	,X++
          STA	W+2
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
		  ADD	IP
		  STDD	IP
          JMP	NEXT
;
;                                       0BRANCH
;                                       SCREEN 15 LINE 6
;
L107      FCB $87,"0BRANC",$C8
          FCW L89      ; link to BRANCH
ZBRAN     FCW *+2
		  LEAX	4,X
          LDD	$FC,X
		  BNE	BUMP
		  LDD	$FE,X
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
          FCW L107     ; link to 0BRANCH
PLOOP     FCW L130
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
;                                       DUP
;                                       SCREEN 30 LINE 21
;
L733      FCB $83,"DU",$D0
          FCW L718     ; link to SWAP
DUP       FCW *+2
          LDD 2,X
          PSH D
          LDD 0,X
          JMP PUSH

;
;                                       R/W
;                              Read or write one sector
;
L3060     .BYTE $83,'R/',$D7
          FCW L3050    ; link to -BCD
RSLW      FCW DOCOL
          FCW ZEQU,LIT,$C4DA,CSTOR
          FCW SWAP,ZERO,STORE
          FCW ZERO,OVER,GREAT,OVER
          FCW LIT,SECTL-1,GREAT,OR,CLIT
          .BYTE 6
          FCW QERR
          FCW ZERO,LIT,SECTR,USLAS,ONEP
          FCW SWAP,ZERO,CLIT
          .BYTE $12
          FCW USLAS,DBCD,SWAP,ONEP
          FCW DBCD,DDISC,CLIT
          .BYTE 8
          FCW QERR
          FCW SEMIS
;
;
;
          FCW SEMIS
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
L3666     .BYTE $85,'TRIA',$C4
          FCW L3637    ; link to INDEX
          FCW DOCOL
          FCW THREE
          FCW SLASH
          FCW THREE
          FCW STAR
          FCW THREE
          FCW OVER
          FCW PLUS
          FCW SWAP
          FCW PDO
L3681     FCW CR
          FCW I
          FCW LIST
          FCW PLOOP
L3685     FCW $FFF8    ; L3681-L3685
          FCW CR
          FCW CLIT
          .BYTE $F
          FCW MESS
          FCW CR
          FCW CLIT
          .BYTE $0C      ;  form feed for printer
          FCW EMIT
          FCW SEMIS
;
;                                       VLIST
;                                       SCREEN 78 LINE 2
;
;
L3696     .BYTE $85,'VLIS',$D4
          FCW L3666    ; link to TRIAD
VLIST     FCW DOCOL
          FCW CLIT
          .BYTE $80
          FCW OUT
          FCW STORE
          FCW CON
          FCW AT
          FCW AT
L3706     FCW OUT
          FCW AT
          FCW CSLL
          FCW GREAT
          FCW ZBRAN
L3711     FCW $A       ; L3716-L3711
          FCW CR
          FCW ZERO
          FCW OUT
          FCW STORE
L3716     FCW DUP
          FCW IDDOT
          FCW SPACE
          FCW SPACE
          FCW PFA
          FCW LFA
          FCW AT
          FCW DUP
          FCW ZEQU
          FCW QTERM
          FCW OR
          FCW ZBRAN
L3728     FCW $FFD4    ; L3706-L3728
          FCW DROP
          FCW SEMIS
;
;                                       MON
;                                       SCREEN 79 LINE 3
;
NTOP      FCB $83,"MO",$CE
          FCW L3696    ; link to VLIST
MON       FCW *+2
          STX XSAVE
		  STY YSAVE
          BRK       ; break to monitor which is assumed
		  LDY YSAVE
          LDX XSAVE ; to save this as reentry point
          JMP NEXT
;
TOP       .END           ; end of listing
