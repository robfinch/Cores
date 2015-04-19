#include "types.h"
#include "proto.h"

// The text screen memory can only handle half-word transfers, hence the use
// of memsetH, memcpyH.

extern int IOFocusNdx;

short int *GetScreenLocation()
{
      return GetJCBPtr()->pVidMem;
}

short int GetCurrAttr()
{
      return GetJCBPtr()->NormAttr;
}

void SetCurrAttr(short int attr)
{
     GetJCBPtr()->NormAttr = attr;
}

void SetVideoReg(int regno, int val)
{
     asm {
         lw   r1,24[bp]
         lw   r2,32[bp]
         asl  r1,r1,#2
         sh   r2,$FFDA0000[r1]
     }
}

void SetCursorPos(int row, int col)
{
    JCB *j;

    j = GetJCBPtr();
    j->CursorCol = col;
    j->CursorRow = row;
    UpdateCursorPos();
}

void SetCursorCol(int col)
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


char AsciiToScreen(char ch)
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

char ScreenToAscii(char ch)
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

void HomeCursor()
{
    JCB *j;

    j = GetJCBPtr();
    j->CursorCol = 0;
    j->CursorRow = 0;
    UpdateCursorPos();
}

short int *CalcScreenLocation()
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
     short int *p;
     int nn;
     int mx;
     JCB *j;
     short int vc;
     
     j = GetJCBPtr();
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
     memsetW(0x400000, 0, 0x80000);
}

void BlankLine(int row)
{
     short int *p;
     int nn;
     int mx;
     JCB *j;
     short int vc;
     
     j = GetJCBPtr();
     p = GetScreenLocation();
     p = p + j->VideoCols * row;
     vc = GetCurrAttr() | AsciiToScreen(' ');
     memsetH(p, vc, j->VideoCols);
}

void ScrollUp()
{
     short int *p;
     int nn;
     int mx;
     JCB *j;
     
     j = GetJCBPtr();
     p = GetScreenLocation();
     mx = (j->VideoRows-1) * j->VideoCols;
     memcpyH(p, &p[j->VideoCols], mx);
     BlankLine(j->VideoRows-1);
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
     j->CursorRow++;
     if (j->CursorRow < j->VideoRows) {
         UpdateCursorPos();
         return;
     }
     j->CursorRow--;
     ScrollUp();
}

void DisplayChar(char ch)
{
     short int *p;
     int nn;
     JCB *j;

     j = GetJCBPtr();
     switch(ch) {
     case '\r':  j->CursorCol = 0; UpdateCursorPos(); break;
     case '\n':  if (j->CursorRow < j->VideoRows) { j->CursorRow++; UpdateCursorPos(); } else ScrollUp(); break;
     case 0x91:
          if (j->CursorCol < j->VideoCols) {
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
          if (j->CursorRow < j->VideoRows) {
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
              p[nn] = p[nn+1];
          }
          p[nn] = GetCurrAttr() | AsciiToScreen(' ');
          break;
     case 0x08: // backspace
          if (j->CursorCol > 0) {
              j->CursorCol--;
              p = CalcScreenLocation();
              for (nn = j->CursorCol; nn < j->VideoCols-1; nn++) {
                  p[nn] = p[nn+1];
              }
              p[nn] = GetCurrAttr() | AsciiToScreen(' ');
          }
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

