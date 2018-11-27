
#include <stdlib.h>
#include <ctype.h>

extern int *inptr;
extern char cmdbuf[48];
extern int ndx;
extern int col;
extern __int8 DBGCursorRow;
extern __int8 KeyLED;
extern __int8 KeyState1;
extern __int8 KeyState2;
extern int DBGGetKey(int block);
extern int GetRand(int stream);
extern __int8 RTCBuf[96];
extern __int8 msgTestString[64];
extern int int64(int port);
extern void out64(int port, int val);
extern int FT64TinyBasic();

void help()
{
	DBGDisplayStringCRLF("Commands");
	DBGDisplayStringCRLF("B Tiny BASIC");
	DBGDisplayStringCRLF("C <address> - call subroutine");
	DBGDisplayStringCRLF("D start debugger");
	DBGDisplayStringCRLF("M <address> <length> - dump memory");
}

pascal void DispNybble(int n)
{
	n &= 0xf;
	if (n > 9)
		DBGDisplayChar('A' + (n-10));
	else
		DBGDisplayChar('0' + n);
}

pascal void DispByte(int n)
{
	DispNybble(n>>4);
	DispNybble(n);
}

pascal void MDispChar(int n)
{
	DispByte(n >> 8);
	DispByte(n);
}

pascal void DispHalf(int n)
{
	MDispChar(n >> 16);
	MDispChar(n);
}

static int GetNum(int *ln)
{
	char buf[20];
	int count;
	int num;
	int radix = 16;
	int ch;

	SkipSpaces();
	ch = in64(&inptr[ndx]) & 0xff;
	if (ch=='$') {
		radix = 16;
		ndx++;
	}
	else
		radix = 10;
	for (count = 0; count < 19; count++) {
		ch = in64(&inptr[ndx]) & 0xff;
		if (radix==10) {
			if (isdigit(ch))
				buf[count] = ch;
			else {
				buf[count] = '\0';
				break;
			}
		}
		else {
			if (isxdigit(ch))
				buf[count] = ch;
			else {
				buf[count] = '\0';
				break;
			}
		}
		ndx++;
	}
	*ln = count;
	num = strtoul(buf,NULL,radix);
	return (num);
}

static void CallCode2(unsigned int *p)
{
	__asm {
		ldi		$r1,#_regfile
		lw		$r2,$08[$r1]
		lw		$r3,$10[$r1]
		lw		$r4,$18[$r1]
		lw		$r5,$20[$r1]
		lw		$r6,$28[$r1]
		lw		$r7,$30[$r1]
		lw		$r8,$38[$r1]
		lw		$r9,$40[$r1]
		lw		$r10,$48[$r1]
		lw		$r11,$50[$r1]
		lw		$r12,$58[$r1]
		lw		$r13,$60[$r1]
		lw		$r14,$68[$r1]
		lw		$r15,$70[$r1]
		lw		$r16,$78[$r1]
		lw		$r17,$80[$r1]
		lw		$r18,$88[$r1]
		lw		$r19,$88[$r1]
		lw		$r20,$88[$r1]
		lw		$r21,$88[$r1]
		lw		$r22,$88[$r1]
		lw		$r23,$88[$r1]
		lw		$r24,$88[$r1]
		lw		$r25,$88[$r1]
		lw		$r26,$88[$r1]
		lw		$r27,$88[$r1]
		lw		$r28,$88[$r1]
		lw		$r29,$88[$r1]
		lw		$r1,32[$fp]
		call	[$r1]
		sw		$r1,_regfile
		lw		$r1,#_regfile
		sw		$r2,$08[$r1]
		sw		$r3,$10[$r1]
		sw		$r4,$18[$r1]
		sw		$r5,$20[$r1]
		sw		$r6,$28[$r1]
		sw		$r7,$30[$r1]
		sw		$r8,$38[$r1]
		sw		$r9,$40[$r1]
		sw		$r10,$48[$r1]
		sw		$r11,$50[$r1]
		sw		$r12,$58[$r1]
		sw		$r13,$60[$r1]
		sw		$r14,$68[$r1]
		sw		$r15,$70[$r1]
		sw		$r16,$78[$r1]
		sw		$r17,$80[$r1]
		sw		$r18,$88[$r1]
		sw		$r19,$88[$r1]
		sw		$r20,$88[$r1]
		sw		$r21,$88[$r1]
		sw		$r22,$88[$r1]
		sw		$r23,$88[$r1]
		sw		$r24,$88[$r1]
		sw		$r25,$88[$r1]
		sw		$r26,$88[$r1]
		sw		$r27,$88[$r1]
		sw		$r28,$88[$r1]
		sw		$r29,$88[$r1]
	}
}

static void CallCode()
{
	unsigned __int8 *p;

	p = GetNum();
	CallCode2(p);
}

static void ProcessR()
{
	int ch;
	
	ch = in64(&inptr[ndx]);
	ch &= 0xff;
	switch(ch) {
	case 'C','c':
		ndx++;
		rtc_read();
		break;
	}
}

static void DisplayTime()
{
	__int8 dt;

	DBGCRLF();
	rtc_read();
	dt = RTCBuf[6];
	DispByte(dt);
	DBGDisplayChar('/');
	dt = RTCBuf[5];
	DispByte(dt & 0x1f);
	DBGDisplayChar('/');
	dt = RTCBuf[4];
	DispByte(dt & 0x3f);
	DBGDisplayChar(' ');
	dt = RTCBuf[2];
	DispByte(dt & 0x1f);
	DBGDisplayChar(':');
	dt = RTCBuf[1];
	DispByte(dt & 0x7f);
	DBGDisplayChar(':');
	dt = RTCBuf[0];
	DispByte(dt & 0x7f);
	DBGDisplayChar(' ');
	dt = RTCBuf[2];
	DBGDisplayString((dt & 0x20) ? "PM" : "AM");
}

static void ProcessT()
{
	int ch;

	ch = in64(&inptr[ndx]);
	ch &= 0xff;
	switch(ch) {
	case 'I','i':
		ndx++;
		ch = in64(&inptr[ndx]);
		ch &= 0xff;
		if (ch=='M' || ch=='m') {
			DisplayTime();
		}
		break;
	case 'R','r':
		ramtest();
		break;
	}
}

void ProcessW()
{
	int ch;

	ch = in64(&inptr[ndx]);
	ch &= 0xff;
	switch(ch) {
	case 'T':
		rtc_write();
		break;
	}	
}

static void SkipSpaces()
{
	int ch;

	for (; ; ndx++) {
		ch = in64(&inptr[ndx]);
		ch &= 0xff;
		if ((ch & 0xff) != ' ')
			break;
	}
}

void DumpMem()
{
	unsigned int st;
	int ln;
	unsigned __int8 *pb;
	int c;
	int ch;

	st = GetNum(&ln);
	ln = GetNum(&ln);
	for (pb = st; ln >= 0; ln -= 16) {
		DBGDisplayChar('\r');
		DBGDisplayChar('\n');
		DBGDisplayChar(':');
		DispHalf(pb);
		DBGDisplayChar(' ');
		for (c = 0; c < 16; c++) {
			DispByte(pb[c]);
			DBGDisplayChar(' ');			
		}
		DBGDisplayChar('"');
		for (c = 0; c < 16; c++) {
			DBGDisplayChar((pb[c] < 0x20) ? '.' : pb[c]);
		}
		DBGDisplayChar('"');
		pb += 16;
		if ((ch = DBGGetKey(0)) >= 0)
			break;
	}
}

void EditMem()
{
	unsigned int st;
	unsigned __int8 *pb;
	int ln;
	__int8 byt;
	char ch;

	ch = in64(&inptr[ndx]);
	if (ch=='W')
		ndx++;
	st = GetNum(&ln);
	if (ln < 1)
		return;
	forever {
		pb = st;
		byt = GetNum(&ln);
		if (ln < 1)
			return;
		*pb = byt;
		pb++;
	}
}

// DCache test routine.
// Writes a 65-character string to a random place in the scratchpad memory then
// reads it back.

void TestDCache()
{
	__int8 *addr;
	int n, j;
	int errcount;

	for (errcount = n = 0; n < 10000; n++) {
		if ((n & 0xff)==0)
			DBGDisplayChar('.');
		addr = (__int8 *)(0x0401000L + (GetRand(0) & 0x3fff));
		for (j = 0; j < 65; j++)
			addr[j] = msgTestString[j];
		for (j = 0; j < 65; j++) {
			if (addr[j] != msgTestString[j]) {
				errcount++;
				DBGDisplayString("Error ");
				if (errcount > 10)
					goto j1;
				break;
			}
		}
	}
j1:;
}

static int ProcessCmd()
{
	int row;
	int ch;
	
	inptr = (int *)0xFFFFFFFFFFD00000L;
	row = DBGCursorRow;
	ndx = __mulf(row, 48);
	SkipSpaces();
	ch = in64(&inptr[ndx]);
	ch &= 0xff;
//	DispByte(ch);
	if (ch=='>') {
		ndx++;
		SkipSpaces();
	}
	ch = in64(&inptr[ndx]);
	ch &= 0xff;
	//	DispByte(ch);
	switch(ch) {
	case ':': EditMem(); break;
	case 'b','B':	FT64TinyBasic(); break;
	case 'C': CallCode(); break;
	case 'D','d': dbg_init(); debugger(0xfffffffffffc0000,0); break;
	case 'H', 'h': HexLoader(); break;
	case 'S','s':	SpriteDemo(); break;
	case 'M':	DumpMem(); break;
	case 'R', 'r':
		ndx++;	
		ProcessR();
		break;
	case 'T','t':
		ndx++;
		ProcessT();
		break;
	case 'W':
		ndx++;
		ProcessW();
		break;
	case 'X','x': return (0);
	case '?': help(); break;
	}	
	return (1);
}

void monitor()
{
	char ch;

	KeyLED = 0;
	KeyState1 = 0;
	KeyState2 = 0;
	DBGDisplayStringCRLF("\r\nROM Monitor v1.0");
//	TestDCache();
	DisplayTime();
	DBGDisplayString("\r\n>");
	forever {
		ch = DBGGetKey(1) & 0xff;
		switch(ch) {
		case '\r':
			//DBGCRLF();
			if (ProcessCmd()==0) goto xit; 
			DBGDisplayString("\r\n>");
			break;
		case 255:	break;
		default:
			DBGDisplayChar(ch);
		}
	}
xit:
	;
}

