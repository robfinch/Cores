
typedef unsigned int uint;
typedef __int16 hTCB;
typedef __int8 hJCB;
typedef __int16 hMBX;
typedef __int16 hMSG;

typedef struct tagMSG align(32) {
	unsigned __int16 link;
	unsigned __int16 retadr;    // return address
	unsigned __int16 tgtadr;    // target address
	unsigned __int16 type;
	unsigned int d1;            // payload data 1
	unsigned int d2;            // payload data 2
	unsigned int d3;            // payload data 3
} MSG;

typedef struct _tagJCB align(2048)
{
    struct _tagJCB *iof_next;
    struct _tagJCB *iof_prev;
    char UserName[32];
    char path[256];
    char exitRunFile[256];
    char commandLine[256];
    unsigned __int32 *pVidMem;
    unsigned __int32 *pVirtVidMem;
    unsigned __int16 VideoRows;
    unsigned __int16 VideoCols;
    unsigned __int16 CursorRow;
    unsigned __int16 CursorCol;
    unsigned __int32 NormAttr;
    __int8 KeyState1;
    __int8 KeyState2;
    __int8 KeybdWaitFlag;
    __int8 KeybdHead;
    __int8 KeybdTail;
    unsigned __int16 KeybdBuffer[16];
    hJCB number;
} JCB;

struct tagMBX;

typedef struct _tagTCB align(1024) {
    // exception storage area
	int regs[32];
	int isp;
	int dsp;
	int esp;
	int ipc;
	int dpc;
	int epc;
	int cr0;
	// interrupt storage
	int iregs[32];
	int iisp;
	int idsp;
	int iesp;
	int iipc;
	int idpc;
	int iepc;
	int icr0;
	hTCB next;
	hTCB prev;
	hTCB mbq_next;
	hTCB mbq_prev;
	int *sys_stack;
	int *bios_stack;
	int *stack;
	__int64 timeout;
	MSG msg;
	hMBX hMailboxes[4]; // handles of mailboxes owned by task
	hMBX hWaitMbx;      // handle of mailbox task is waiting at
	hTCB number;
	__int8 priority;
	__int8 status;
	__int8 affinity;
	hJCB hJob;
	__int64 startTick;
	__int64 endTick;
	__int64 ticks;
} TCB;

typedef struct tagMBX align(64) {
    hMBX link;
	hJCB owner;		// hJcb of owner
	hTCB tq_head;
	hTCB tq_tail;
	hMSG mq_head;
	hMSG mq_tail;
	char mq_strategy;
	byte resv[2];
	uint tq_count;
	uint mq_size;
	uint mq_count;
	uint mq_missed;
} MBX;

typedef struct tagALARM {
	struct tagALARM *next;
	struct tagALARM *prev;
	MBX *mbx;
	MSG *msg;
	uint BaseTimeout;
	uint timeout;
	uint repeat;
	byte resv[8];		// padding to 64 bytes
} ALARM;


// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// TCB.c
// Task Control Block related functions.
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
// JCB functions
JCB *GetJCBPtr();                   // get the JCB pointer of the running task

// TCB functions
TCB *GetRunningTCBPtr();
hTCB GetRunningTCB();
pascal void SetRunningTCB(hTCB ht);
pascal int chkTCB(TCB *p);
pascal int InsertIntoReadyList(hTCB ht);
pascal int RemoveFromReadyList(hTCB ht);
pascal int InsertIntoTimeoutList(hTCB ht, int to);
pascal int RemoveFromTimeoutList(hTCB ht);
void DumpTaskList();

pascal void SetBound48(TCB *ps, TCB *pe, int algn);
pascal void SetBound49(JCB *ps, JCB *pe, int algn);
pascal void SetBound50(MBX *ps, MBX *pe, int algn);
pascal void SetBound51(MSG *ps, MSG *pe, int algn);

void set_vector(unsigned int, unsigned int);
int getCPU();
int GetVecno();          // get the last interrupt vector number
void outb(unsigned int, int);
void outc(unsigned int, int);
void outh(unsigned int, int);
void outw(unsigned int, int);
pascal int LockSemaphore(int *sema, int retries);
pascal void UnlockSemaphore(int *sema);

// The following causes a privilege violation if called from user mode


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
     GetJCBPtr()->NormAttr = attr & 0xFFFFFC00;
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

int GetTextCols()
{
    return GetJCBPtr()->VideoCols;
}

int GetTextRows()
{
    return GetJCBPtr()->VideoRows;
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
     p = p + (int)j->VideoCols * row;
     vc = GetCurrAttr() | AsciiToScreen(' ');
     memsetH(p, vc, j->VideoCols);
}

// ScrollUp will call BlankLine. Scrollup is written in assembler for
// performance reasons and is included as part of the video BIOS. Note the
// BIOS cannot be called with SYS #10 because the bios isn't re-entrant and
// the bios is already active from putch().
naked ScrollUp()
{
     asm {
         push  lr
         bsr   VBScrollUp
         rts
     }
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

void DisplayChar(char ch)
{
     short int *p;
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

void DisplayString(char *s)
{
     while (*s) { DisplayChar(*s); s++; }
}

void DisplayStringCRLF(char *s)
{
     DisplayString(s);
     CRLF();
}

