//#include "c:\AtlysCores\RTF65000\trunk\software\stdio.h"

void putch(char ch)
{
	asm {
		ldi	r1,#$0A
		sb	r1,$FFDC0600	; LEDS
	}
	asm {
		lw		r1,32[bp]
		jsr		($8028)
	}
}

void putnum(int num, int wid)
{
	int n;
	char sign;
	char numwka[20];

	n = 0;
	sign = num < 0 ? '-' : '+';
	if (num < 0) num = -num;
	do {
		numwka[n] = (num % 10) + '0';
		num = num / 10;
		n++;
	}
	while (num != 0 && n < 18);
	if (sign=='-') {
		numwka[n] = sign;
		n++;
	}
	while (n < wid) {
		putch(' ');
		wid--;
	}
	while (n > 0) {
		--n;
		putch(numwka[n]);
	}
}

void puthexnum(int num, int wid)
{
	int n, m;
	char sign;
	char numwka[20];

	n = 0;
	sign = num < 0 ? '-' : '+';
	if (num < 0) num = -num;
	do {
		m = num & 15;
		if (m < 10)
			numwka[n] = m + '0';
		else
			numwka[n] = m + 'A'-10;
		num = num >> 4;
		n++;
	}
	while (num != 0);
	if (sign=='-') {
		numwka[n] = sign;
		n++;
	}
	while (n < wid) {
		putch(' ');
		wid--;
	}
	while (n > 0) {
		--n;
		putch(numwka[n]);
	}
}

void putstr(char *p, int maxchars)
{
	asm {
		ldi	r1,#$09
		sb	r1,$FFDC0600	; LEDS
	}
	for (; *p && maxchars > 0; p++, maxchars--)
		putch(*p);
}

naked getcharNoWait()
{
	asm {
		jmp		($8018)
	}
}

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
	int fmtwidth;
	int maxwidth;
	q = &p;

	for (; *p; p++) {
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
				putnum(*q,fmtwidth);
				break;
			case 'x':
				q++;
				puthexnum(*q,fmtwidth);
				break;
			case 's':
				q++;
				putstr(*q,maxwidth);
				break;
			// width specification
			case '0','1','2','3','4','5','6','7','8','9':
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
