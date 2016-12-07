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
extern pascal int prtflt(register float, register int, register int, register char);
extern void ramtest();
extern void FloatTest();
extern void DBGDisplayString(register char *p);
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
			while(GetButton());
			ramtest();
			break;
		case BTNL:
			while(GetButton());
			FloatTest();
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
}

interrupt IBERout()
{
	int nn;

	DBGDisplayString("\r\nInstruction Bus Error:\r\n");
	DBGDisplayString("PC History:\r\n");
	for (nn = 63; nn >= 0; nn--) {
		SetPCHNDX(nn);
		puthex(ReadPCHIST());
		putch(' ');
	}
	forever {}
}

