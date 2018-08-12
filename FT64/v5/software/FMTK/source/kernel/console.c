#include "types.h"
#include "proto.h"

extern memsetH(register int *, register int, register int);

// The text screen memory can only handle half-word transfers, hence the use
// of memsetH, memcpyH.
//#define DBGScreen	(__int32 *)0xFFD00000
#define DBGScreen	(__int32 *)0xFFD00000
#define DBGCOLS		80

extern int IOFocusNdx;
extern __int32 DBGCursorCol;
extern __int32 DBGCursorRow;
extern __int32 DBGAttr;
extern void DispChar(register char ch);

void DBGClearScreen()
{
     __int32 *p;
     __int32 vc;

	asm {
		ldi	r1,#$26
		sb	r1,LEDS
	}     
     p = DBGScreen;
     //vc = AsciiToScreen(' ') | DBGAttr;
     vc = AsciiToScreen(' ') | 0x87fc00;
     memsetH(p, (int)vc, 20); //2604);
	asm {
		ldi	r1,#$27
		sb	r1,LEDS
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
     GetACBPtr()->NormAttr = attr & 0xFFFFFC00;
}

static void SetVideoReg(register int regno, register int val)
{
     if (regno < 0 or regno > 11) {
         printf("bad video regno: %d", regno);
         return;
     }
     asm {
         shl	r1,r18,#2
         sh		r19,$FFD0DF00[r1]
     }
}

static void DBGSetVideoReg(register int regno, register int val)
{
     asm {
         shl	r1,r18,#2
         sh		r19,$FFDCC000[r1]
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

pascal char AsciiToScreen(char ch)
{
     if (ch==0x5B)
         return 0x1B;
     if (ch==0x5D)
         return 0x1D;
     ch &= 0xFF;
     ch |= 0x100;
     if (!(ch & 0x20))
         return ch;
     if (!(ch & 0x40))
         return ch;
     ch = ch & 0x19F;
     return ch;
}

pascal char ScreenToAscii(char ch)
{
     ch &= 0xFF;
     if (ch==0x1B)
        return 0x5B;
     if (ch==0x1D)
        return 0x5D;
     if (ch < 27)
        ch += 0x60;
     return ch;
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

void DBGUpdateCursorPos()
{
    int pos;
	
    pos = DBGCursorRow * DBGCOLS + DBGCursorCol;
//    SetVideoReg(11,pos);
}

void HomeCursor()
{
    ACB *j;

    j = GetACBPtr();
    j->CursorCol = 0;
    j->CursorRow = 0;
    UpdateCursorPos();
}

void DBGHomeCursor()
{
    DBGCursorCol = 0;
    DBGCursorRow = 0;
    DBGUpdateCursorPos();
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
     __int32 *p;
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
     vc = GetCurrAttr() | AsciiToScreen(' ');
     memsetH(p, vc, mx);
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
     vc = GetCurrAttr() | AsciiToScreen(' ');
     memsetH(p, vc, j->VideoCols);
}

void DBGBlankLine(int row)
{
     __int32 *p;
     int nn;
     int mx;
     int vc;
     
     p = DBGScreen;
     p = p + row * DBGCOLS;
     vc = DBGAttr | AsciiToScreen(' ');
     memsetH(p, vc, DBGCOLS);
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

void DBGScrollUp()
{
	__int32 *scrn = DBGScreen;
	int nn;
	int count;

	count = 2604;
	for (nn = 0; nn < count; nn++)
		scrn[nn] = scrn[nn+84];

	DBGBlankLine(31);
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
     ScrollUp();
}

void DBGIncrementCursorRow()
{
     DBGCursorRow++;
     if (DBGCursorRow < 31) {
         DBGUpdateCursorPos();
         return;
     }
     DBGCursorRow--;
     DBGUpdateCursorPos();
     DBGScrollUp();
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

void DBGIncrementCursorPos()
{
     DBGCursorCol++;
     if (DBGCursorCol < 84) {
         DBGUpdateCursorPos();
         return;
     }
     DBGCursorCol = 0;
     DBGIncrementCursorRow();
}

void DisplayChar(char ch)
{
     int *p;
     int nn;
     ACB *j;

     j = GetACBPtr();
     switch(ch) {
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
          DisplayChar(' ');
          DisplayChar(' ');
          DisplayChar(' ');
          DisplayChar(' ');
          break;
     default:
          p = CalcScreenLocation();
          *p = GetCurrAttr() | AsciiToScreen(ch);
          IncrementCursorPos();
          break;
     }
}

void CRLF()
{
     DisplayChar('\r');
     DisplayChar('\n');
}

void DisplayString(char *s)
{
     while (*s) { DisplayChar(*s); s++; }
}

void DisplayStringCRLF(char *s)
{
     DisplayString(s);
     CRLF();
}


void DBGDisplayChar(char ch)
{
     __int32 *p;
     int nn;
     ACB *j;

     switch(ch) {
     case '\r':  DBGCursorCol = 0; DBGUpdateCursorPos(); break;
     case '\n':  DBGIncrementCursorRow(); break;
     case 0x91:
          if (DBGCursorCol < DBGCOLS) {
             DBGCursorCol++;
             DBGUpdateCursorPos();
          }
          break;
     case 0x90:
          if (DBGCursorRow > 0) {
               DBGCursorRow--;
               DBGUpdateCursorPos();
          }
          break;
     case 0x93:
          if (DBGCursorCol > 0) {
               DBGCursorCol--;
               DBGUpdateCursorPos();
          }
          break;
     case 0x92:
          if (DBGCursorRow < 30) {
             DBGCursorRow++;
             DBGUpdateCursorPos();
          }
          break;
     case 0x94:
          if (DBGCursorCol==0)
             DBGCursorRow = 0;
          DBGCursorCol = 0;
          DBGUpdateCursorPos();
          break;
     case 0x99:  // delete
          p = DBGScreen;
          for (nn = DBGCursorCol; nn < DBGCOLS-1; nn++) {
              p[nn-DBGCursorCol] = p[nn+1-DBGCursorCol];
          }
		  p[nn-DBGCursorCol] = DBGAttr | AsciiToScreen((char)' ');
          break;
     case 0x08: // backspace
          if (DBGCursorCol > 0) {
              DBGCursorCol--;
	          p = DBGScreen;
              for (nn = DBGCursorCol; nn < DBGCOLS-1; nn++) {
                  p[nn-DBGCursorCol] = p[nn+1-DBGCursorCol];
              }
              p[nn-DBGCursorCol] = DBGAttr | AsciiToScreen((char)' ');
		  }
          break;
     case 0x0C:   // CTRL-L
          DBGClearScreen();
          DBGHomeCursor();
          break;
     case '\t':
          DBGDisplayChar(' ');
          DBGDisplayChar(' ');
          DBGDisplayChar(' ');
          DBGDisplayChar(' ');
          break;
     default:
		asm {
			ldi		r1,#50
			sb		r1,LEDS
		}
          p = DBGScreen;
		  nn = DBGCursorRow * DBGCOLS + DBGCursorCol;
          //p[nn] = AsciiToScreen(ch) | DBGAttr;
          //DispChar(ch);
          p[nn] = AsciiToScreen(ch) | 0x87fc00;
          DBGIncrementCursorPos();
		asm {
			ldi		r1,#51
			sb		r1,LEDS
		}
          break;
     }
}

void DBGCRLF()
{
     DBGDisplayChar('\r');
     DBGDisplayChar('\n');
}

void DBGDisplayString(char *s)
{
	asm {
		ldi	r1,#$28
		sb	r1,LEDS
	}     
     while (*s) {DBGDisplayChar(*s); s++; }
	asm {
		ldi	r1,#$29
		sb	r1,LEDS
	}     
}

void DBGDisplayStringCRLF(char *s)
{
     DBGDisplayString(s);
     DBGCRLF();
}

void DBGHideCursor(int hide)
{
	/*
	if (hide) {
		asm {
			ldi		r1,#%00100000
			stt		r1,$FFD0DF10
		}
	}
	else {
		asm {
			ldi		r1,#%11100000
			stt		r1,$FFD0DF10
		}
	}
	*/
}

