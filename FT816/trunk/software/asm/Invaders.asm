	CPU		FT832

PRNG		EQU		$FEA100
PRNG_NUM	EQU		$FEA108
PRNG_ADV	EQU		$FEA10E
MAN_EXPLODING	EQU		1

; which invaders are still active (not destroyed)
; These var addresses are segment offsets into seg $7800
active				EQU		$00
left_right			EQU		$5E
rightmost_column	EQU		$60
leftmost_column		EQU		$62
bottom_row			EQU		$64
top_row				EQU		$66
inv_tick			EQU		$6A
inv_tick2			EQU		$6C
manX				EQU		$6E
manY				EQU		$70
manState			EQU		$72
InvadersX			EQU		$100
InvadersY			EQU		$200
min_right			EQU		$300
max_left			EQU		$310
bombX				EQU		$320
bombY				EQU		$330
inv_state			EQU		$400

; This var is shared, must be referenced ZS:
do_invaders			EQU		$7868

	; minimum right co-ordinate for each column of invaders
st_min_right:
	.word	1
	.word	5
	.word	9
	.word	13
	.word	17
	.word	21
	.word	25
	.word	29

	; maximum left co-ordinate for each column of invaders
	.word	52
	.word	56
	.word	60
	.word	64
	.word	68
	.word	72
	.word	76
	.word	80

	.word	0		; rightmost column
	.word	7		; lefmost column
	.word	1		; dx

	MEM		16
	NDX		16

	code

InvBomb:
	LDX		#0
.0001:
	LDA		active,X
	BEQ		.0002
	JSR		CanDropBomb
	BEQ		.0002
	LDA		ZS:PRNG_NUM
	STA		ZS:PRNG_ADV
	AND		#$63
	BNE		.0002
	JSR		FindEmptyBomb
	BMI		.0003
	LDA		InvadersX,X
	STA		bombX,Y
	LDA		InvadersY,X
	STA		bombY,Y
.0002:
	INX
	INX
	CPX		#80
	BMI		.0001
.0003:
	RTS

FindEmptyBomb:
	LDY		#0
.0001:
	LDA		bombX,Y
	BEQ		.0002
	INY
	INY
	CPY		#16
	BMI		.0001
	LDY		#-1
.0002:
	RTS

MoveBombs:
	LDX		#0
.0002:
	LDA		bombX,X
	BEQ		.0001
	LDA		bombY,X
	CMP		#30			; has the bomb fallen all the way to the ground ?
	BPL		.0003		; if yes, reset bomb
	INA
	STA		bombY,X
	BRA		.0001
.0003:
	STZ		bombX,X
	STZ		bombY,X
.0001:
	INX
	INX
	CPX		#16
	BMI		.0002
	RTS

GetBombOffset:
	LDA		bombY,Y
	ASL
	TAX
	LDA		ZS:LineTbl,X
	CLC
	ADC		bombX,Y
	ADC		bombX,Y
	TAX
	RTS

RenderBombs:
	LDY		#0
.0001:
	LDA		bombY,Y
	BEQ		.0002
	JSR		GetBombOffset
	LDA		#'$'
	STA		ZS:VIDBUF,X
.0002:
	INY
	INY
	CPY		#16
	BMI		.0001
	RTS

TestBombsIntercept:
	LDY		#0
.0001:
	JSR		TestBombIntercept
	INY
	INY
	CPY		#16
	BMI		.0001
	RTS

TestBombIntercept:
	JSR		GetBombOffset
	LDA		ZS:VIDBUF,X
	CMP		#' '
	BEQ		.0001
	LDA		bombY,Y
	CMP		#29
	BNE		.0002
	LDA		bombX,Y
	CMP		manX,Y
	BNE		.0003
	LDA		#MAN_EXPLODING
	STA		manState
.0003:
	TYX
	STZ		bombY,X
	STZ		bombX,X
	RTS
.0001:
	RTS
.0002:
	LDA		#' '
	STA		VIDBUF,X
	BRA		.0003

; An invader can drop a bomb only if there are no invaders underneath it.

CanDropBomb:
	CPX		#15
	BGE		.0001
	LDA		active+16,X
	ORA		active+32,X
	ORA		active+48,X
	ORA		active+64,X
	EOR		#1
	RTS
.0001:
	CPX		#31
	BGE		.0002
	LDA		active+16,X
	ORA		active+32,X
	ORA		active+48,X
	EOR		#1
	RTS
.0002:
	CPX		#47
	BGE		.0003
	LDA		active+16,X
	ORA		active+32,X
	EOR		#1
	RTS
.0003:
	CPX		#63
	BGE		.0004
	LDA		active+16,X
	EOR		#1
	RTS
.0004:
	LDA		#1
	RTS


; Test if it's possible to move to the left anymore.
;
CanMoveLeft:
	LDA		leftmost_column
	ASL
	TAX
	LDA		max_left,X
	CMP		InvadersX,X
	BMI		.0001
	LDA		#0
	RTS
.0001:
	LDA		#1
	RTS

; Test if it's possible to move to the right anymore.
;
CanMoveRight:
	LDA		rightmost_column
	ASL
	TAX
	LDA		min_right,X
	CMP		InvadersX,X
	BPL		.0001
	LDA		#0
	RTS
.0001:
	LDA		#1
	RTS

; Test if it's possible to move down anymore
;
CanMoveDown:
	LDA		bottom_row
	ASL
	ASL
	ASL
	ASL
	TAX
	LDA		InvadersY,X
	CMP		#30
	BMI		.0001
	LDA		#0
	RTS
.0001:
	LDA		#1
	RTS

; Move all the invaders to the left
; Means incrementing the X co-ordinate
;
MoveLeft:
	LDX		#00
.0002:
	INC		InvadersX,X
	INX
	INX
	CPX		#80
	BNE		.0002
	RTS

; Move all the invaders to the right.
; means decrementing the X co-ordinate
;
MoveRight:
	LDX		#0
.0002:
	DEC		InvadersX,X
	INX
	INX
	CPX		#80
	BNE		.0002
	RTS

; Move all the invaders down a row.
; Means incrementing the Y co-ordinate
;
MoveDown:
	LDX		#00
.0002:
	INC		InvadersY,X
	INX
	INX
	CPX		#80
	BNE		.0002
	RTS

; Move the invaders
; Retuns
; .A = 1 if it was possible to do a move, 0 otherwise
;
Move:
	BIT		left_right
	BMI		.0002
	JSR		CanMoveLeft
	BEQ		.0001
	JSR		MoveLeft
	BRA		.0003
.0002:
	JSR		CanMoveRight
	BEQ		.0001
	JSR		MoveRight
	BRA		.0003
.0001:
	JSR		CanMoveDown
	BEQ		.0004
	LDA		left_right
	EOR		#$FFFF
	STA		left_right
	JSR		MoveDown
.0003:
	LDA		#1
	RTS
.0004:
	LDA		#0
	RTS

Initialize:
	STZ		rightmost_column
	LDA		#7
	STA		leftmost_column
	STZ		top_row
	LDA		#4
	STA		bottom_row
	STZ		left_right
	JSR		ActivateAllInvaders
	LDX		#0
.0001:
	LDA		CS:StartX,X
	STA		InvadersX,X
	LDA		CS:StartY,X
	STA		InvadersY,X
	INX
	INX
	CPX		#80
	BMI		.0001
	LDX		#0
.0002:
	LDA		CS:st_min_right,X
	STA		min_right,X
	INX
	INX
	CPX		#32
	BMI		.0002
	; Initialize Bombs
	LDX		#0
.0003:
	STZ		bombX,X
	STZ		bombY,X
	INX
	INX
	CPX		#16
	BMI		.0003
	LDA		#$FFFE
	STA		ZS:do_invaders
	RTS

ActivateAllInvaders:
	LDX		#0
	LDA		#1
.0001:
	STA		active,X
	INX
	INX
	CPX		#80
	BNE		.0001
	RTS

IsAllDestroyed:
	JSR		IsRightmostColumnDestroyed
	BEQ		.0001
	INC		rightmost_column
	LDA		min_right+12
	STA		min_right+14
	LDA		min_right+10
	STA		min_right+12
	LDA		min_right+8
	STA		min_right+10
	LDA		min_right+6
	STA		min_right+8
	LDA		min_right+4
	STA		min_right+6
	LDA		min_right+2
	STA		min_right+4
	LDA		min_right
	STA		min_right+2
.0001:
	JSR		IsLeftmostColumnDestroyed
	BEQ		.0002
	DEC		leftmost_column
	LDA		max_left+2
	STA		max_left
	LDA		max_left+4
	STA		max_left+2
	LDA		max_left+6
	STA		max_left+4
	LDA		max_left+8
	STA		max_left+6
	LDA		max_left+10
	STA		max_left+8
	LDA		max_left+12
	STA		max_left+10
	LDA		max_left+14
	STA		max_left+12
.0002:
	LDA		leftmost_column
	CMP		rightmost_column
	BMI		.allDestroyed
	JSR		IsBottomRowDestroyed
	BEQ		.0003
	DEC		bottom_row
.0003:
	JSR		IsTopRowDestroyed
	BEQ		.0004
	INC		top_row
.0004:
	LDA		bottom_row
	CMP		top_row
	BMI		.allDestroyed
	LDA		#0
	RTS
.allDestroyed:
	LDA		#1
	RTS


IsLeftmostColumnDestroyed:
	LDA		leftmost_column
	BRA		IsColumnDestroyed
IsRightmostColumnDestroyed:
	LDA		rightmost_column
IsColumnDestroyed:
	ASL
	TAX
	LDA		active,X
	ORA		active+16,X
	ORA		active+32,X
	ORA		active+48,X
	ORA		active+64,X
	ORA		active+80,X
	ORA		active+96,X
	ORA		active+112,X
	EOR		#1
	RTS

IsTopRowDestroyed:
	LDA		top_row
	BRA		IsRowDestroyed
IsBottomRowDestroyed:
	LDA		bottom_row
IsRowDestroyed:
	ASL
	ASL
	ASL
	ASL
	LDA		active,X
	ORA		active+2,X
	ORA		active+4,X
	ORA		active+6,X
	ORA		active+8,X
	ORA		active+10,X
	ORA		active+12,X
	ORA		active+14,X
	EOR		#1
	RTS

; TickCount counts 1/100 of a second. We want to animate the graphics at a much
; slower rate, so we use bit 6 of the tick count to indicate when to animate.
;
ShiftTick:
	LDA		ZS:TickCount
	LSR
	LSR
	LSR
	LSR
	LSR
	LSR
	RTS

RenderInvaders:
	; First, clear the screen
	LDX		#0
	LDA		#' '
	ORA		#$BF00
.0003:
	STA		ZS:VIDBUF,X
	INX
	INX
	CPX		#84*31*2
	BMI		.0003
	LDX		#0
.0002:
	REP		#$30
	MEM		16
	NDX		16
	LDA		active,X
	LBEQ	.0001
	LDA		inv_state,X
	LDA		InvadersY,X
	ASL
	TAY
	LDA		ZS:LineTbl,Y
	CLC
	ADC		InvadersX,X
	CLC
	ADC		InvadersX,X
	TAY
	SEP		#$20			; eight bit acc
	MEM		8
	LDA		CS:InvaderType,X
	CMP		#1
	BNE		.0004
	LDA		#233
	STA		ZS:VIDBUF,Y
	LDA		#242
	STA		ZS:VIDBUF+2,Y
	LDA		#223
	STA		ZS:VIDBUF+4,Y
	JSR		ShiftTick
	BCC		.0005
	LDA		#'X'
	BRA		.0006
.0005:
	LDA		#'V'
.0006:
	STA		ZS:VIDBUF+84,Y
	STA		ZS:VIDBUF+88,Y
	LDA		#' '
	STA		ZS:VIDBUF+86,Y
	BRL		.0007
.0004:
	CMP		#2
	LBNE	.0008
	JSR		ShiftTick
	BCC		.0009
	LDA		#252
	STA		ZS:VIDBUF,Y
	LDA		#153
	STA		ZS:VIDBUF+2,Y
	LDA		#254
	STA		ZS:VIDBUF+4,Y
	LDA		#226
	STA		ZS:VIDBUF+84,Y
	LDA		#98
	STA		ZS:VIDBUF+86,Y
	LDA		#226
	STA		ZS:VIDBUF+88,Y
	BRL		.0007
.0009:
	LDA		#98
	STA		ZS:VIDBUF,Y
	LDA		#153
	STA		ZS:VIDBUF+2,Y
	LDA		#98
	STA		ZS:VIDBUF+4,Y
	LDA		#236
	STA		ZS:VIDBUF+84,Y
	LDA		#98
	STA		ZS:VIDBUF+86,Y
	LDA		#251
	STA		ZS:VIDBUF+88,Y
	BRL		.0007
.0008:
	LDA		#255
	STA		ZS:VIDBUF,Y
	LDA		#248
	STA		ZS:VIDBUF+2,Y
	LDA		#127
	STA		ZS:VIDBUf+4,Y
	JSR		ShiftTick
	BCC		.0010
	LDA		#255
	STA		ZS:VIDBUF+84,Y
	LDA		#249
	STA		ZS:VIDBUF+86,Y
	LDA		#127
	STA		ZS:VIDBUF+88,Y
	BRA		.0007
.0010:
	LDA		#225
	STA		ZS:VIDBUf+84,Y
	LDA		#249
	STA		ZS:VIDBUF+86,Y
	LDA		#96
	STA		ZS:VIDBUF+88,Y
.0007:
	; Surround the alien with spaces
	LDA		#' '
	STA		ZS:VIDBUF-86,Y
	STA		ZS:VIDBUF-84,Y
	STA		ZS:VIDBUF-82,Y
	STA		ZS:VIDBUF-80,Y
	STA		ZS:VIDBUF-78,Y
	STA		ZS:VIDBUF-2,Y
	STA		ZS:VIDBUF+6,Y
	STA		ZS:VIDBUF+82,Y
	STA		ZS:VIDBUF+90,Y
	STA		ZS:VIDBUF+166,Y
	STA		ZS:VIDBUF+168,Y
	STA		ZS:VIDBUF+170,Y
	STA		ZS:VIDBUF+172,Y
	STA		ZS:VIDBUF+174,Y
.0001:
	INX
	INX
	CPX		#80
	LBNE	.0002
	REP		#$20
	MEM		16
	RTS

public InvadersTask:
.0001:
	PEA		0				; set data segment to $7800
	PEA		$7800
	PLDS
	LDA		#$2BFF			; set stack to $2BFF
	TAS
	JSR		Initialize
	SEP		#$1000			; turn on single step mode
	JSR		RenderInvaders
.0002:
	JCR 	KeybdGetCharNoWaitCtx,7	; check for char at keyboard
.0004:
	LDX		#0
.0006:
	INX
	CPX		#2000
	BNE		.0006
	LDA		ZS:TickCount
	AND		#$3
	BNE		.0002
	JSR		InvBomb
	JSR		RenderInvaders
	JSR		RenderBombs
	JSR		MoveBombs
	LDA		ZS:TickCount
	AND		#$F
	BNE		.0002
	JSR		IsAllDestroyed
	BNE		.0001
	JSR		Move
	BEQ		.0001				; Can't move, re-initialize
	BRA		.0002
.0005:
	STA		inv_tick
	BRA		.0002
.0003:
	CMP		#3
	BNE		.0004
	STZ		ZS:do_invaders
	RTT
	BRA		.0001

InvaderRow:
	.word	0
	.word	0
	.word	0
	.word	0
	.word	0
	.word	0
	.word	0
	.word	0

	.word	1
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1

	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2

	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3

	.word	4
	.word	4
	.word	4
	.word	4
	.word	4
	.word	4
	.word	4
	.word	4

InvaderCol:
	.word	0
	.word	1
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7

	.word	0
	.word	1
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7

	.word	0
	.word	1
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7

	.word	0
	.word	1
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7

	.word	0
	.word	1
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7

; Starting Y co-ordinate for each invader

StartY:
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3

	.word	6
	.word	6
	.word	6
	.word	6
	.word	6
	.word	6
	.word	6
	.word	6

	.word	9
	.word	9
	.word	9
	.word	9
	.word	9
	.word	9
	.word	9
	.word	9

	.word	12
	.word	12
	.word	12
	.word	12
	.word	12
	.word	12
	.word	12
	.word	12

	.word	15
	.word	15
	.word	15
	.word	15
	.word	15
	.word	15
	.word	15
	.word	15

; Starting X co-ordinate for each invader

StartX:
	.word	1
	.word	5
	.word	9
	.word	13
	.word	17
	.word	21
	.word	25
	.word	29

	.word	1
	.word	5
	.word	9
	.word	13
	.word	17
	.word	21
	.word	25
	.word	29

	.word	1
	.word	5
	.word	9
	.word	13
	.word	17
	.word	21
	.word	25
	.word	29

	.word	1
	.word	5
	.word	9
	.word	13
	.word	17
	.word	21
	.word	25
	.word	29

	.word	1
	.word	5
	.word	9
	.word	13
	.word	17
	.word	21
	.word	25
	.word	29

InvaderType:
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1
	.word	1

	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2

	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2
	.word	2

	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3

	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
	.word	3
			