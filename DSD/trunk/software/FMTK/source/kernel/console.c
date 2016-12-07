#include "types.h"
#include "proto.h"

extern memsetW(register int *, register int, register int);

// The text screen memory can only handle half-word transfers, hence the use
// of memsetH, memcpyH.
#define DBGScreen	(int *)0xFFD00000

extern int IOFocusNdx;
extern int DBGCursorCol;
extern int DBGCursorRow;
extern int DBGAttr;

short int *GetScreenLocation()
{
      return GetJCBPtr()->pVidMem;
}

short int GetCurrAttr()
{
      return GetJCBPtr()->NormAttr;
}

void SetCurrAttr(register int attr)
{
     GetJCBPtr()->NormAttr = attr & 0xFFFFFC00;
}

static void SetVideoReg(register int regno, register int val)
{
     if (regno < 0 or regno > 11) {
         printf("bad video regno: %d", regno);
         return;
     }
     asm {
         shl  r1,r18,#1
         sw   r19,$FFDA0000[r1]
     }
}

static void DBGSetVideoReg(register int regno, register int val)
{
     asm {
		 sw		r18,$FFDC0080
         shl  r1,r18,#1
		 nop
		 nop
         sw   r19,$FFDA0000[r1]
     }
}

void SetCursorPos(register int row, register int col)
{
    JCB *j;

    j = GetJCBPtr();
    j->CursorCol = col;
    j->CursorRow = row;
    UpdateCursorPos();
}

void SetCursorCol(register int col)
{
    JCB *j;

    j = GetJCBPtr();
    j->CursorCol = col;
    UpdateCursorPos();
}

int GetCursorPos()
{
    JCB *j;

    j = GetJCBPtr();
    return j->CursorCol | (j->CursorRow << 8);
}

int GetTextCols()
{
    return GetJCBPtr()->VideoCols;
}

int GetTextRows()
{
    return GetJCBPtr()->VideoRows;
}

char AsciiToScreen(register char ch)
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

char ScreenToAscii(register char ch)
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
    JCB *j;
    int pos;

    j = GetJCBPtr();
//    if (j == IOFocusNdx) {
       pos = j->CursorRow * j->VideoCols + j->CursorCol;
       SetVideoReg(11,pos);
//    }
}

void DBGUpdateCursorPos()
{
    int pos;
	
    pos = DBGCursorRow * 84 + DBGCursorCol;
    SetVideoReg(11,pos);
}

void HomeCursor()
{
    JCB *j;

    j = GetJCBPtr();
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
    JCB *j;
    int pos;

    j = GetJCBPtr();
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
     JCB *j;
     int vc;
     
     j = GetJCBPtr();
     p = GetScreenLocation();
     // Compiler did a byte multiply generating a single byte result first
     // before assigning it to mx. The (int) casts force the compiler to use
     // an int result.
     mx = (int)j->VideoRows * (int)j->VideoCols;
     vc = GetCurrAttr() | AsciiToScreen(' ');
     memsetW(p, vc, mx);
}

void DBGClearScreen()
{
     int *p;
     int vc;
     
     p = DBGScreen;
     vc = DBGAttr | AsciiToScreen(' ');
     memsetW(p, vc, 2604);
}

void ClearBmpScreen()
{
     memsetW(0x200000, 0, 0x40000);
}

void BlankLine(register int row)
{
     int *p;
     int nn;
     int mx;
     JCB *j;
     int vc;
     
     j = GetJCBPtr();
     p = GetScreenLocation();
     p = p + (int)j->VideoCols * row;
     vc = GetCurrAttr() | AsciiToScreen(' ');
     memsetW(p, vc, j->VideoCols);
}

void DBGBlankLine(register int row)
{
     int *p;
     int nn;
     int mx;
     int vc;
     
     p = DBGScreen;
     p = p + row * 84;
     vc = DBGAttr | AsciiToScreen(' ');
     memsetW(p, vc, 84);
}

void VBScrollUp()
{
	int *scrn = GetScreenLocation();
	int nn;
	int count;
    JCB *j;

    j = GetJCBPtr();
	count = (int)j->VideoCols*(int)(j->VideoRows-1);
	for (nn = 0; nn < count; nn++)
		scrn[nn] = scrn[nn+(int)j->VideoCols];

	BlankLine(GetTextRows()-1);
}

void DBGScrollUp()
{
	int *scrn = DBGScreen;
	int nn;
	int count;

	count = 2604;
	for (nn = 0; nn < count; nn++)
		scrn[nn] = scrn[nn+84];

	DBGBlankLine(31);
}

void IncrementCursorRow()
{
     JCB *j;
     
     j = GetJCBPtr();
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
     JCB *j;
     
     j = GetJCBPtr();
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

void DisplayChar(register char ch)
{
     int *p;
     int nn;
     JCB *j;

     j = GetJCBPtr();
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

void DBGCRLF()
{
     DBGDisplayChar('\r');
     DBGDisplayChar('\n');
}

void DisplayString(register char *s)
{
     while (*s) { DisplayChar(*s); s++; }
}

void DisplayStringCRLF(register char *s)
{
     DisplayString(s);
     CRLF();
}


void DBGDisplayChar(register char ch)
{
     int *p;
     int nn;
     JCB *j;

     switch(ch) {
     case '\r':  DBGCursorCol = 0; DBGUpdateCursorPos(); break;
     case '\n':  DBGIncrementCursorRow(); break;
     case 0x91:
          if (DBGCursorCol < 84) {
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
          for (nn = DBGCursorCol; nn < 83; nn++) {
              p[nn-DBGCursorCol] = p[nn+1-DBGCursorCol];
          }
		  p[nn-DBGCursorCol] = DBGAttr | AsciiToScreen((char)' ');
          break;
     case 0x08: // backspace
          if (DBGCursorCol > 0) {
              DBGCursorCol--;
	          p = DBGScreen;
              for (nn = DBGCursorCol; nn < 83; nn++) {
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
			sw		r1,LEDS
		}
          p = DBGScreen;
		  nn = DBGCursorRow * 84 + DBGCursorCol;
          p[nn] = DBGAttr | AsciiToScreen(ch);
          DBGIncrementCursorPos();
		asm {
			ldi		r1,#51
			sw		r1,LEDS
		}
          break;
     }
}

void DBGDisplayString(register char *s)
{
     while (*s) {DBGDisplayChar(*s); s++; }
}

void DBGDisplayStringCRLF(register char *s)
{
     DBGDisplayString(s);
     DBGCRLF();
}

void DBGHideCursor(int hide)
{
	if (hide) {
		asm {
			ldi		r1,#%00100000
			sw		r1,$FFDA0010
		}
	}
	else {
		asm {
			ldi		r1,#%11100000
			sw		r1,$FFDA0010
		}
	}
}


