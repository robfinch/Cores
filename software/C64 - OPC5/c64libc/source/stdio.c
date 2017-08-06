//#include "c:\AtlysCores\RTF65000\trunk\software\stdio.h"
extern pascal int prtflt(register double,register int, register int, register char E);
extern void DBGDisplayChar(register char ch);

int out_fh;

naked inline void LEDS(register int val)  __attribute__(__no_temps)
{
    asm {
        sb    r18,LEDS
    }
}
//
//typedef struct tagFlt {
//	__int16 man0;
//	__int16 man1;
//	__int16 man2;
//	__int16 man3;
//	__int16 exp;
//} fltStruct;
//
typedef struct tagFlt {
	__int64 man : 52;
	__int64 exp : 11;
	__int64 sign : 1;
} fltStruct;

typedef union tagfval {
	float flt;
	fltStruct fs;
} fval;

typedef union tagval {
    int i;
    double d;
} uval;

static naked inline int abs(register int num)
{
	asm {
		abs		r1,r18
	}
}

pascal void putch(register char ch)
{
	if (1;1)
		DBGDisplayChar(ch);
	else {
		LEDS(45);
		asm {
			push	r6
			mov		r1,r18
			ldi     r6,#14    ; Teletype output function
			int     #10       ; Video BIOS call
			pop		r6
		}
		LEDS(46);
	}
}

pascal void putnum(register int num, register int wid, register char sep, register char padchar)
{
	int n, m10;
	char sign;
	static char numwka[200];

	LEDS(80);
	if (wid < 0 or wid > 200;0)	// take care of nutty parameter
		wid = 0;
	sign = num < 0 ? '-' : '+';
	if (num < 0) num = abs(num);
	n = 0;
	do {
		if ((n % 4)==3 && sep) {
			numwka[n]=sep;
			n++;
		}
		m10 = num % 10;
		numwka[n] = m10 + '0';
		num = num / 10;
		n++;
	} until (num == 0 or n > 18);
	if (sign=='-') {
		numwka[n] = sign;
		n++;
	}
	LEDS(88);
	for (; n < wid; wid--)
		putch(padchar);
	LEDS(89);
	while (n > 0) {
		--n;
		putch(numwka[n]);
	}
	LEDS(90);
}

pascal void puthexnum(register int num, register int wid, register int ul, register char padchar)
{
	int n, m;
	char sign;
	char numwka[100];

	asm {
		sw	r18,$FFDC0080
	}
	if (wid < 0 or wid > 100;0)	// take care of nutty parameter
		wid = 0;
	n = 0;
	sign = num < 0 ? '-' : '+';
	if (num < 0) num = -num;
	do {
		m = num & 15;
		if (m < 10)
			numwka[n] = m + '0';
		else if (ul)
			numwka[n] = m + 'A'-10;
		else
			numwka[n] = m + 'a'-10;
		num = num >> 4;
		n++;
	}
	while (num != 0 && n < 18);
	if (sign=='-') {
		numwka[n] = sign;
		n++;
	}
	while (n < wid) {
		putch(sign=='-' ? ' ' : padchar);
		wid--;
	}
	while (n > 0) {
		--n;
		asm { nop }
		putch(numwka[n]);
	}
}

pascal int putstr(register char *p, register int maxchars)
{
	char *q;

	for (q = p; *p && maxchars > 0; p++, maxchars--)
		putch(*p);
	return p-q;
}

pascal int putstrD(register int *p, register int maxchars)
{
	int *q;

	for (q = p; *p && maxchars > 0; p++, maxchars--)
		putch((char)*p);
	return p-q;
}

pascal void putstr2(register char *p)
{
    asm {
		push	r6
        mov     r1,r18
        ldi     r6,#$1B   ; Video BIOS DisplayString16 function
        int     #10
		pop		r6
    }
}

int getcharNoWait()
{
    return KeybdGetBufferedCharNoWait();
}

/*
naked int getcharNoWait()
{
	asm {
        push    lr
        bsr     KeybdGetBufferedCharNoWait_
        pop     lr
        rtl
        push    r6
        ld      r6,#3    ; KeybdGetCharNoWait
        sys     #10
        pop     r6
        rtl
	}
}
*/

int (getchar)()
{
	int ch;

	do {
		ch = getcharNoWait();
	}
	while (ch==-1);
	return ch & 255;
}


int printf(char *p, ...)
{
	int *q;
	__int64 *q1;
	int fmtwidth;
	int maxwidth;
	int wd;
	uval v;
	fval f;
	char padchar;
	q = &p;

	for (; *p; p++) {
        padchar = ' ';
		if (*p=='%') {
			fmtwidth = 0;
			maxwidth = 65535;
			p++;
j1:
			switch(*p) {
			case '%':
				putch('%');
				break;
			case 'c':
				q++;
				putch(*q);
				break;
			case 'd':
				q++;
				putnum(*q,fmtwidth,0,padchar);
				break;
			case 'e','E':
				q1 = q;
				q1++;
				f.flt = *q1;
				q = q1;
				prtflt(f.flt,fmtwidth,maxwidth,*p);
				break;
			case 'x':
				q++;
				puthexnum(*q,fmtwidth,0,padchar);
				break;
			case 'X':
				q++;
				puthexnum(*q,fmtwidth,1,padchar);
				break;
			case 's':
				q++;
				wd = putstr(*q,maxwidth);
				//while (wd < fmtwidth) {
				//	putch(' ');
				//	wd++;
				//}
				break;
			// width specification
			case '0':
                padchar = '0';
            case '1','2','3','4','5','6','7','8','9':
				fmtwidth = *p - '0';
				p++;
				while (isdigit(*p)) { 
					fmtwidth *= 10;
					fmtwidth += *p - '0';
					p++;
				}
				if (*p != '.')
					goto j1;
			case '.':
				p++;
				if (!isdigit(*p))
					goto j1;
				maxwidth = *p - '0';
				p++;
				while (isdigit(*p)) {
					maxwidth *= 10;
					maxwidth += *p - '0';
					p++;
				}
				goto j1;
			}
		}
		else
			putch(*p);
	}
}
