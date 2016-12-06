#define BTNC	16
#define BTNU	8
#define BTND	4
#define BTNL	2
#define BTNR	1

extern int DBGAttr;
extern void DBGClearScreen();
extern void DBGHomeCursor();
extern void putch(register char);
extern int printf(char *, ...);
extern void prtflt(float, int, int, char);
extern void ramtest();
void DBGDisplayString(register char *p);
extern void puthex(register int num);

static naked inline int GetButton()
{
	asm {
		lw		r1,BUTTONS
	}
}

void BIOSMain()
{
	float pi = 3.1415926535897932384626;
	float a,b;
	int btn;

	DBGAttr = 0x087FC00;//0b0000_1000_0111_1111_1100_0000_0000;
	DBGClearScreen();
	DBGHomeCursor();
	DBGDisplayString("  DSD7 Bios Started\r\n");
	DBGDisplayString("  Button Menu\r\n  up = ramtest\r\n  center = float test\r\n");
	forever {
		btn = GetButton();
		switch(btn) {
		case BTNU:
			ramtest();
			break;
		case BTNL:
			DBGDisplayString("  Float Test\r\n");
			DBGDisplayString("  PI is ");
			prtflt(pi,0,16,'E');
			asm {
				ldi	r1,#$1234
				sw	r1,$FFDC0080
			}
			DBGDisplayString("\r\n");
			a = 10.0;
			b = 10.0;
			prtflt(a+b,0,16,'E');
			DBGDisplayString("\r\n");
			break;
		}
	}
//	printf("PI is %e\r\n", pi);
}

static naked inline int GetEPC()
{
	asm {
		csrrw	r1,#$40,r0
	}
}

static naked inline int GetBadAddr()
{
	asm {
		csrrw	r1,#7,r0
		sw		r1,$FFDC0080
	}
}

void DBERout()
{
	DBGDisplayString("\r\nDatabus error: ");
	puthex(GetEPC());
	putch(' ');
	puthex(GetBadAddr());
	forever {}
}

static naked inline void SetPCHNDX(register int nn)
{
	asm {
		csrrw	r0,#$101,r18
	}
}

static naked inline int ReadPCHIST()
{
	asm {
		csrrw	r1,#$100,r0
	}
}

interrupt BTNCIRQHandler()
{
	int nn;

	asm {
		ldi		r1,#30
		sw		r1,PIC_ESR
	}
	DBGDisplayString("\r\nPC History:\r\n");
	for (nn = 63; nn >= 0; nn--) {
		SetPCHNDX(nn);
		puthex(ReadPCHIST());
		putch(' ');
	}
	forever {}
}
