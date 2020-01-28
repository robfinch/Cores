STRTMP		equ		$0200

; -----------------------------------------------------------------------------
;		$fa0 = number to convert (f18)
;		$a1	= width
;		$a2 = precision
;		$a3 = E
;		$t2 = ndx
;		$s9 = exp
; -----------------------------------------------------------------------------

fltToString:
		ldi		$t2,#0				; $t2 = 0
		fmv		$a0,$f18
		and		$t0,$a0,#$7F800000
		ldi		$t1,#$7F800000
		bne		$t0,$t1,.0001
		and		$t0,$a0,#$007FFFFF
		beq		$t0,$x0,.inf
		ldt		$t0,msgNan
		stt		$t0,STRTMP
		bra		.prt
.inf:
		ldt		$t0,msgInf
		stt		$t0,STRTMP
		bra		.prt
.0001:
		and		$t0,$a0,#$80000000
		beq		$t0,$x0,.pos
		ldi		$t0,#'-'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		and		$a0,$a0,#$7FFFFFFF
.pos:
		bne		$a0,$x0,.notZero
		ldi		$t0,#'0'
		stb		$t0,STRTMP[$t2]
		stb		$x0,STRTMP+1[$t2]
		bra		.prt		
.notZero:
		mov		$s9,$x0			; exp = 0.0
;	// Make a small number > 0 so we can get at the digits.
;	if (dbl < 1.0) {
;		while (dbl < 1.0) {
;			dbl *= 1000000.0;
;			exp -= 6;  
;		}
;	}
		flw		$f3,fltOne
		fmv		$f0,$a0
		flt		$t0,$f18,$f3
		beq		$t0,$x0,.0002
		flw		$f4,fltMillion
.0003:
		flt		$t0,$f18,$f3
		beq		$t0,$x0,.0002
		fmul	$f18,$f18,$f4
		sub		$s9,$s9,#6
		bra		.0003
.0002:
;	// The following is similar to using log10() and pow() functions.
;	// Now dbl is >= 1.0
;	// Create a number dbl2 on the same order of magnitude as dbl, but
;	// less than dbl.
;	dbl2 = 1.0;
;	dbla = dbl2;
;	if (dbl > dbl2) {	// dbl > 1.0 ?
;		while (dbl2 <= dbl) {
;			dbla = dbl2;
;			dbl2 *= 10.0;	// increase power of 10
;			exp++;
;		}
;		// The above loop goes one too far, we want the last value less
;		// than dbl.
;		dbl2 = dbla;
;		exp--;
;	}
		flw		$f1,fltOne				; $f1 = dbl2 = 1.0
		fmov	$f2,$f1						; $f2 = dbla = dbl2
		flt		$t0,$f1,$f18				; if (dbl2 < dbl)
		beq		$t0,$x0,.0004
		flw		$f5,fltTen				; $f5 = 10.0
.0006:
		fle		$t0,$f1,$f18				; while ($f1 <= $f18)
		beq		$t0,$x0,.0005
		fmov	$f2,$f1						; dbla = dbl2
		fmul	$f1,$f1,$f5				; dbl2 *= 10.0
		add		$s9,$s9,#1				; exp++;
		bra		.0006
.0005:
		fmov	$f1,$f2						; dbl2 = dbla
		sub		$s9,$s9,#1				; exp--;
.0004:
;	// For small constants < 1000000 try and spit out a whole number
;    if (exp >= 0 && exp < 6) {
;        digits_before_decpt = exp+1;
;		exp = 0;
;	}
;	else if (exp >= -6)
;		digits_before_decpt = 1;
;	else
;		digits_before_decpt = -1;
		blt		$s9,$x0,.0007
		ldi		$s5,#6
		bge		$s9,$s5,.0007
		mov		$s1,#s0						; s1 = digits before decpt
		add		$s1,$s1,#1
		ldi		$s9,#0						; exp = 0
		bra		.0008
.0007:
		ldi		$s5,#-7
		blt		$s9,$s5,.0009
		ldi		$s1,#1
		bra		.0008
.0009:
		ldi		$s1,#-1
.0008:
;	// Spit out a leading zero before the decimal point for a small number.
;    if (exp < -6) {
;		buf[ndx] = '0';
;		ndx++;
;        buf[ndx] = '.';
;        ndx++;
;    }
		ldi		$s5,#-6
		bge		$s9,$s5,.0010
		ldi		$t0,#'0'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		ldi		$t0,#'.'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
.0010:
;	// Now loop processing one digit at a time.
;    for (nn = 0; nn < 30 && precision > 0; nn++) {
;        digit = 0;
;		dbla = dbl;
;		// dbl is on the same order of magnitude as dbl2 so
;		// a repeated subtract can be used to find the digit.
;        while (dbl >= dbl2) {
;            dbl -= dbl2;
;            digit++;
;        }
;        buf[ndx] = digit + '0';
;		// Now go back and perform just a single subtract and
;		// a multiply to find out how much to reduce dbl by.
;		// This should improve the accuracy
;		if (digit > 2)
;			dbl = dbla - dbl2 * digit;
;        ndx++;
;        digits_before_decpt--;
;        if (digits_before_decpt==0) {
;           buf[ndx] = '.';
;           ndx++;
;        }
;        else if (digits_before_decpt < 0)
;            precision--;
;		// Shift the next digit to be tested into position.
;        dbl *= 10.0;
;    }
		ldi		$s3,#0						; s3 = nn = 0
		ldi		$s5,#30
		flw		$f7,fltTen				; f7 = 10.0
.0016:
		slt		$t0,$s3,$s5
		beq		$t0,$x0,.0011
		ldi		$s5,#0
		bge		$s5,$a2,.0011			; (0 < precision)
		ldi		$s4,#0						; s4 = digit = 0
		fmov	$f2,$f18						; dbla = dbl
.0013:
		fle		$t0,$f1,$f18						; while (dbl2 <= dbl)
		beq		$t0,$x0,.0012
		fsub	$f18,$f18,$f1						; dbl -= dbl2
		add		$s4,$s4,#1						; digit++
		bra		.0013
.0012:
		add		$s5,$s4,#'0'			; buf[ndx] = digit + '0'
		stb		$s5,STRTMP[$t2]
		ldi		$s5,#2						; if (2 < digit)
		bge		$s5,$s4,.0014
		fcvt.s.w	$f5,$s4				; f5 = digit as float
		fmul	$f6,$f1,$f5				; f6 = dbl2 * digit
		fsub	$f18,$f2,$f6				; dbl = dbla - dbl2 * digit
.0014:
		add		$t2,$t2,#1				; ndx++
		sub		$s1,$s1,#1				; digits_before_decpt--;
		bne		$s1,$x0,.0015			; if (digits_before_decpt==0)
		ldi		$t0,#'.'
		stb		$t0,STRTMP[$t2]		; buf[ndx] = '.'
		add		$t2,$t2,#1				; ndx++
		bra		.0017
.0015:
		bge		$s1,$x0,.0017			; else if (digits_before_decpt < 0)
		sub		$a2,$a2,#1				; 	precision--
.0017:
		fmul	$f18,$f18,$f7				; dbl *= 10.0
		bra		.0016
.0011:
;	// Trim trailing zeros from the number
;    do {
;        ndx--;
;    } while(buf[ndx]=='0');
;    ndx++;
.0018:
		sub		$t2,$t2,#1				; ndx--
		ldb		$t0,STRTMP[$t2]
		xor		$t0,$t0,#'0'
		beq		$t0,$x0,.0018
		add		$t2,$t2,#1				; ndx++
;	// Make sure we have at least one digit after the decimal point.
;	if (buf[ndx]=='.') {
;		ndx++;
;		buf[ndx]='0';
;		ndx++;
;        buf[ndx]='\0';
;	}
		ldb		$t0,STRTMP[$t2]
		xor		$t0,$t0,#'.'
		bne		$t0,$x0,.0019
		add		$t2,$t2,#1
		ldi		$t0,#'0'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		stb		$x0,STRTMP[$t2]
.0019:
;	// If the number is times 10^0 don't output the exponent
;   if (exp==0) {
;        buf[ndx]='\0';
;        goto prt;
;    }
		bne		$s9,$x0,.0020
		stb		$x0,STRTMP[$t2]
		bra		.prt
.0020:
;	// Spit out +/-E
;    buf[ndx] = E;
;    ndx++;
;    if (exp < 0) {
;        buf[ndx]='-';
;        ndx++;
;        exp = -exp;
;    }
;    else {
;         buf[ndx]='+';
;         ndx++;
;    }
		ldi		$t0,#'E'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		bge		$s9,$x0,.0021
		ldi		$t0,#'-'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		sub		$s9,$x0,$s9			; exp = -exp
		bra		.0022
.0021:
		ldi		$t0,#'+'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
.0022:
;	// now process the exponent
;    digit = 0;
;    while (exp >= 1000) {
;        exp -= 1000;
;        digit++;
;    }
		ldi		$s4,#0
		ldi		$t0,#1000
.0025:
		bge		$s9,$t0,.0023
		bra		.0024
.0023:
		sub		$s9,$s9,$t0
		add		$s4,$s4,#1
		bra		.0025
.0024:
;	d1 = digit;
;	if (digit) {
;		buf[ndx] = digit + '0';
;		ndx++;
;	}
		mov		$s6,$s4					; s6 = d1 = s4 = digit
		bne		$s4,$x0,.0026
		add		$t0,$s4,#'0'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
.0026:
;	digit = 0;
;    while (exp >= 100) {
;        exp -= 100;
;        digit++;
;    }
		ldi		$s4,#0
		ldi		$t0,#100
.0027:
		bge		$s9,$t0,.0028
		bra		.0029
.0028:
		sub		$s9,$s9,$t0
		add		$s4,$s4,#1
		bra		.0027
.0029:	
;	d2 = digit;
;	if (digit==0 && d1==0)
;		;
;	else {
;		buf[ndx] = digit + '0';
;		ndx++;
;	}
		mov		$s7,$s4				; $s7 = d2
		bne		$s6,$x0,.0030
		beq		$s4,$x0,.0031
.0030:
		add		$t0,$s4,#'0'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
.0031:
;	digit = 0;
;    while (exp >= 10) {
;        exp -= 10;
;        digit++;
;    }
		ldi		$s4,#0
		ldi		$t0,#10
.0032:
		bge		$s9,$t0,.0034
		bra		.0035
.0034:
		sub		$s9,$s9,$t0
		add		$s4,$s4,#1
		bra		.0032
.0035:	
;	d3 = digit;
;	if (digit==0 && d1==0 && d2==0)
;		;
;	else {
;		buf[ndx] = digit + '0';
;		ndx++;
;	}
		mov		$s8,$s4
		bne		$s4,$x0,.0036
		bne		$s6,$x0,.0036
		beq		$s7,$x0,.0037
.0036:
		add		$t0,$s4,#'0'
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
.0037:
;	digit = 0;
;    while (exp >= 1) {
;        exp -= 1;
;        digit++;
;    }
		ldi		$s4,#0
		ldi		$t0,#1
.0038:
		bge		$s9,$t0,.0040
		bra		.0039
.0040:
		sub		$s9,$s9,$t0
		add		$s4,$s4,#1
		bra		.0038
.0039:	
;    buf[ndx] = digit + '0';
;    ndx++;
;    buf[ndx] = '\0';
		add		$t0,$s4,#'0'
		sb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		sb		$x0,STRTMP[$t2]
;	// Now pad the number on the left or right as requested.
.prt:
;    // pad left
;    if (width > 0) {
;        if (ndx < width) {
;            for (nn = 39; nn >= width-ndx; nn--)
;                buf[nn] = buf[nn-(width-ndx)];
;            for (; nn >= 0; nn--)
;                buf[nn] = ' ';
;        }
;    }
		blt		$a1,$x0,.0041
		beq		$a1,$x0,.0041
		blt		$t2,$a1,.0042
		bra		.0041
.0042:
		ldi		$s3,#39					; s3 = nn
		sub		$t0,$a1,$t2			; width-ndx
.0045:
		bge		$s3,$t0,.0043
		bra		.0044
.0043:
		sub		$s6,$s3,$t0			; nn-(width-ndx)
		ldb		$t1,STRTMP[$s3]
		stb		$t1,STRTMP[$s6]
		sub		$s3,$s3,#1
		bra		.0045
.0044:
		ldi		$t0,#' '
.0048:
		bge		$s3,$x0,.0046
		bra		.0047
.0046:
		stb		$t0,STRTMP[$s3]
		sub		$s3,$s3,#1
		bra		.0048
.0047:
.0041:
;    // pad right
;    if (width < 0) {
;        width = -width;
;        while (ndx < width) {
;            buf[ndx]=' ';
;            ndx++;
;        }
;        buf[ndx]='\0';
;    }
;    return (ndx);
		bge		$a1,$x0,.0050
		sub		$a1,$x0,$a1
		ldi		$t0,#' '
.0052:
		bge		$t2,$a1,.0051
		stb		$t0,STRTMP[$t2]
		add		$t2,$t2,#1
		bra		.0052
.0051:
		stb		$x0,STRTMP[$t2]
.0050:
		mov		$v0,$t2
		ret

		align	4
msgInf:
		db	"Inf",0
msgNan:
		db	"Nan",0
fltOne:
		dw		$3F800000					; 1.0
fltTen:
		dw		$41200000					; 10.0
fltMillion:
		dw		$49742400					; 1,000,000

