#include "types.h"
#include "proto.h"
#include <fmtk/const.h>
#include <fmtk/device.h>
#include <fmtk/config.h>
#include <fmtk/types.h>
#include <fmtk/glo.h>
#include <fmtk/proto.h>
#include <ft64/io.h>

extern int *memsetW(int *, int, int);
extern rmemsetW(register int *, register int, register int);

// The text screen memory can only handle word transfers, hence the use
// of memsetW, memcpyW.
//#define DBGScreen	(__int32 *)0xFFD00000
#define DBGScreen	(int *)0xFFFFFFFFFFD00000
#define DBGCOLS		56
#define DBGROWS		29

extern int IOFocusNdx;
extern __int8 DBGCursorCol;
extern __int8 DBGCursorRow;
extern int DBGAttr;
extern void DispChar(register char ch);
extern void puthexnum(int num, int wid, int ul, char padchar);

__int8 tabstops[32];

void DisplayChar(char ch)
{
	int *p;
	int nn;
	ACB *j;

	j = GetACBPtr();
	switch(ch) {
		/*
	case '\r':  j->CursorCol = 0; UpdateCursorPos(); break;
	case '\n':  IncrementCursorRow(); break;
	case 0x91:
	  if (j->CursorCol < j->VideoCols-1) {
			j->CursorCol++;
			UpdateCursorPos();
	  }
	  break;
	case 0x90:
    if (j->CursorRow > 0) {
			j->CursorRow--;
			UpdateCursorPos();
    }
    break;
	case 0x93:
    if (j->CursorCol > 0) {
			j->CursorCol--;
			UpdateCursorPos();
    }
    break;
	case 0x92:
		if (j->CursorRow < j->VideoRows-1) {
			j->CursorRow++;
			UpdateCursorPos();
		}
		break;
	case 0x94:
		if (j->CursorCol==0)
			j->CursorRow = 0;
		j->CursorCol = 0;
		UpdateCursorPos();
		break;
	
	case 0x99:  // delete
		p = CalcScreenLocation();
		for (nn = j->CursorCol; nn < j->VideoCols-1; nn++) {
			p[nn-j->CursorCol] = p[nn+1-j->CursorCol];
		}
		p[nn-j->CursorCol] = GetCurrAttr() | AsciiToScreen(' ');
		break;
		*/
	case 0x08: // backspace
		if (j->CursorCol > 0) {
			j->CursorCol--;
			p = CalcScreenLocation();
			for (nn = j->CursorCol; nn < j->VideoCols-1; nn++) {
				p[nn-j->CursorCol] = p[nn+1-j->CursorCol];
			}
			p[nn-j->CursorCol] = GetCurrAttr() | AsciiToScreen(' ');
		}
		break;

	case 0x0C:   // CTRL-L
		ClearScreen();
		HomeCursor();
		break;
		
	case '\t':
		for (nn = 0; nn < 32; nn++) {
			if (j->CursorCol < tabstops[nn]) {
				j->CursorCol = tabstops[nn];
				break;
			}
		}
		break;

	default:
		p = CalcScreenLocation();
		*p = GetCurrAttr() | AsciiToScreen(ch);
		IncrementCursorPos();
		break;
	}
}

void init_console()
{
	int n;
	
	for (n = 0; n < 32; n++) {
		if (n < 14)
			tabstops[n] = n * 4;
		else
			tabstops[n] = 55;
	}
}

short int *GetScreenLocation()
{
  return GetACBPtr()->pVidMem;
}

short int GetCurrAttr()
{
  return GetACBPtr()->NormAttr;
}

void SetCurrAttr(int attr)
{
   GetACBPtr()->NormAttr = attr & 0xFFFFFFFFFFFF0000;
}

static void SetVideoReg(register int regno, register int val)
{
	if (regno < 0 ||| regno > 4) {
		printf("bad video regno: %d", regno);
		return;
	}
	__asm {
		shl		$r1,$r18,#3
		sw		$r19,$FFFFFFFFFFD0DF00[$r1]
	}
}

void SetCursorPos(int row, int col)
{
	ACB *j;

	j = GetACBPtr();
	j->CursorCol = col;
	j->CursorRow = row;
	UpdateCursorPos();
}

void SetCursorCol(int col)
{
	ACB *j;

	j = GetACBPtr();
	j->CursorCol = col;
	UpdateCursorPos();
}

int GetCursorPos()
{
	ACB *j;

	j = GetACBPtr();
	return j->CursorCol | (j->CursorRow << 8);
}

int GetTextCols()
{
	return GetACBPtr()->VideoCols;
}

int GetTextRows()
{
	return GetACBPtr()->VideoRows;
}

char AsciiToScreen(char ch)
{
/*
	if (ch==0x5B)
		return (0x1B);
	if (ch==0x5D)
		return (0x1D);
	ch &= 0xFF;
	ch |= 0x100;
	if (!(ch & 0x20))
		return (ch);
	if (!(ch & 0x40))
		return (ch);
	ch = ch & 0x19F;
*/
	return (ch);
}

char ScreenToAscii(char ch)
{
/*
	ch &= 0xFF;
	if (ch==0x1B)
		return 0x5B;
	if (ch==0x1D)
		return 0x5D;
	if (ch < 27)
		ch += 0x60;
*/
	return (ch);
}
    

void UpdateCursorPos()
{
	ACB *j;
	int pos;

	j = GetACBPtr();
//    if (j == IOFocusNdx) {
	pos = j->CursorRow * j->VideoCols + j->CursorCol;
	SetVideoReg(11,pos);
//    }
}

void HomeCursor()
{
	ACB *j;

	j = GetACBPtr();
	j->CursorCol = 0;
	j->CursorRow = 0;
	UpdateCursorPos();
}

int *CalcScreenLocation()
{
    ACB *j;
    int pos;

    j = GetACBPtr();
    pos = j->CursorRow * j->VideoCols + j->CursorCol;
//    if (j == IOFocusNdx) {
       SetVideoReg(11,pos);
//    }
    return GetScreenLocation()+pos;
}

void ClearScreen()
{
	int *p;
	int nn;
	int mx;
	ACB *j;
	int vc;

	j = GetACBPtr();
	p = GetScreenLocation();
	// Compiler did a byte multiply generating a single byte result first
	// before assigning it to mx. The (int) casts force the compiler to use
	// an int result.
	mx = (int)j->VideoRows * (int)j->VideoCols;
	vc = GetCurrAttr() | ' ';
	memsetW(p, vc, mx);
}

void ClearBmpScreen()
{
   memsetH(0x200000, 0, 0x40000);
}

void BlankLine(int row)
{
	int *p;
	int nn;
	int mx;
	ACB *j;
	int vc;

	j = GetACBPtr();
	p = GetScreenLocation();
	p = p + (int)j->VideoCols * row;
	vc = GetCurrAttr() | ' ';
	memsetW(p, vc, j->VideoCols);
}

void VBScrollUp()
{
	int *scrn = GetScreenLocation();
	int nn;
	int count;
  ACB *j;

  j = GetACBPtr();
	count = (int)j->VideoCols*(int)(j->VideoRows-1);
	for (nn = 0; nn < count; nn++)
		scrn[nn] = scrn[nn+(int)j->VideoCols];

	BlankLine(GetTextRows()-1);
}

void IncrementCursorRow()
{
	ACB *j;

	j = GetACBPtr();
	j->CursorRow++;
	if (j->CursorRow < j->VideoRows) {
		UpdateCursorPos();
		return;
	}
	j->CursorRow--;
	UpdateCursorPos();
	VBScrollUp();
}

void IncrementCursorPos()
{
	ACB *j;

	j = GetACBPtr();
	j->CursorCol++;
	if (j->CursorCol < j->VideoCols) {
		UpdateCursorPos();
		return;
	}
	j->CursorCol = 0;
	IncrementCursorRow();
}

void CRLF()
{
	DisplayChar('\r');
	DisplayChar('\n');
}

void DisplayString(char *s)
{
	char ch;
	while (ch = *s) { DisplayChar(ch); s++; }
}

void DisplayStringCRLF(char *s)
{
	DisplayString(s);
	CRLF();
}

pascal int con_CmdProc(int cmd, int cmdParm1, int cmdParm2, int cmdParm3, int cmdParm4)
{
	int val;
	int err = E_Ok;
	ACB *j;

	switch(cmd) {
	case DVC_GetUnit:
	case DVC_GetUnitDirect:
		val = DBGGetKey(1);
		*(int *)cmdParm2 = val;
		break;
	case DVC_PutUnit:
		kbd_put(cmdParm1,cmdParm2);
		break;
	case DVC_PeekUnit:
	case DVC_PeekUnitDirect:
		val = DBGGetKey(0);
		*(int *)cmdParm2 = val;
		break;
	case DVC_Open:
		if (cmdParm4)
			*(int *)cmdParm4 = 0;
		else
			err = E_Arg;
		break;
	case DVC_Close:
		break;
	case DVC_Status:
		*(int *)cmdParm2 = 0;
		break;
	case DVC_Nop:
		break;
	case DVC_Setup:
		DBGDisplayAsciiStringCRLF(B"CON setup");
		init_console();
		break;
	case DVC_Initialize:
		init_console();
		break;
	case DVC_SetPosition:
		j = GetACBPtr();
		if (j) {
			j->CursorRow = (cmdParm1 >> 8) & 0xff;
			j->CursorCol = cmdParm1 & 0xff;
		}
		break;
	case DVC_FlushInput:
		break;
	case DVC_IsRemoveable:
		*(int *)cmdParm1 = 0;
		break;
	default:
		return err = E_BadDevOp;
	}
	return (err);
}
