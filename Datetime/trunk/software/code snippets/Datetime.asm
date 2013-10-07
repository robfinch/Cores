
DATETIME	EQU		0xFFDC0400
DATETIME_TIME		EQU		0xFFDC0400
DATETIME_DATE		EQU		0xFFDC0401
DATETIME_ALMTIME	EQU		0xFFDC0402
DATETIME_ALMDATE	EQU		0xFFDC0403
DATETIME_CTRL		EQU		0xFFDC0404
DATETIME_SNAPSHOT	EQU		0xFFDC0405

;--------------------------------------------------------------------------
; RTF65002 code to display the date and time from the date/time device.
;--------------------------------------------------------------------------
DisplayDatetime
	pha
	phx
	lda		#' '
	jsr		DisplayChar
	stz		DATETIME_SNAPSHOT	; take a snapshot of the running date/time
	lda		DATETIME_DATE
	tax
	lsr		r1,r1,#16
	jsr		DisplayHalf		; display the year
	lda		#'/'
	jsr		DisplayChar
	txa
	lsr		r1,r1,#8
	and		#$FF
	jsr		DisplayByte		; display the month
	lda		#'/'
	jsr		DisplayChar
	txa
	and		#$FF
	jsr		DisplayByte		; display the day
	lda		#' '
	jsr		DisplayChar
	lda		#' '
	jsr		DisplayChar
	lda		DATETIME_TIME
	tax
	lsr		r1,r1,#24
	jsr		DisplayByte		; display hours
	lda		#':'
	jsr		DisplayChar
	txa
	lsr		r1,r1,#16
	jsr		DisplayByte		; display minutes
	lda		#':'
	jsr		DisplayChar
	txa
	lsr		r1,r1,#8
	jsr		DisplayByte		; display seconds
	lda		#'.'
	jsr		DisplayChar
	txa
	jsr		DisplayByte		; display 100ths seconds
	jsr		CRLF
	plx
	pla
	rts
