//#include "c:\AtlysCores\RTF65000\trunk\software\stdio.h"
extern pascal int prtflt(register float,int,int,char E);

naked inline void LEDS(register int val)  __attribute__(__no_temps)
{
    asm {
        sh    r18,LEDS
    }
}

typedef struct tagFlt {
	__int32 man0;
	__int32 man1;
	__int32 man2;
	__int32 manexp;
} fltStruct;

typedef union tagfval {
	float flt;
	fltStruct fs;
} fval;

typedef union tagval {
    __int64 i;
    double d;
} uval;


int printf(char *p, ...)
{
	int *q;
	int fmtwidth;
	int maxwidth;
	int wd;
	uval v;
	fval f;
	char padchar;
	q = (int *)&p;

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
			case 'e':
            case 'E':
				q++;
				f.fs.man0 = *q;
				q++;
				f.fs.man1 = *q;
				q++;
				f.fs.man2 = *q;
				q++;
				f.fs.manexp = *q;
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
