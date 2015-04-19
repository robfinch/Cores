
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


extern JCB *IOFocusNdx;
extern int IOFocusTbl[4];

void ForceIOFocus(JCB *j)
{
    RequestIOFocus(j);   // In case it isn't requested yet.
    LockIOF();
        if (j != IOFocusNdx) {
            CopyScreenToVirtualScreen();
            j->pVidMem = j->pVirtVidMem;
            IOFocusNdx = j;
            j->pVidMem = 0xFFD00000;
            CopyVirtualScreenToScreen();
        }
    UnlockIOF();
}

// First check if it's even possible to switch the focus to another
// task. The I/O focus list could be empty or there may be only a
// single task in the list. In either case it's not possible to
// switch.
void SwitchIOFocus()
{
     JCB *j, *p;

     LockIOF();
         j = IOFocusNdx;
         if (j) {
             p = IOFocusNdx->iof_next;
             if (p <> IOFocusNdx) {
                 if (p) {
                     CopyScreenToVirtualScreen();
                     j->pVidMem = j->pVirtVidMem;
                     IOFocusNdx = p;
                     p->pVidMem = 0xFFD00000;
                     CopyVirtualScreenToScreen();
                 }
             }
         }
     UnlockIOF();
}

//-----------------------------------------------------------------------------
// The I/O focus list is an array indicating which jobs are requesting the
// I/O focus. The I/O focus is user controlled by pressing ALT-TAB on the
// keyboard.
//-----------------------------------------------------------------------------

void RequestIOFocus(JCB *j)
{
     int nj;
     int stat;

     nj = j->number;
     LockIOF();
        stat = (IOFocusTbl[0] >> nj) & 1;
        if (!stat) {
           if (IOFocusNdx==null) {
               IOFocusNdx = j;
               j->iof_next = j;
               j->iof_prev = j;
           }
           else {
               j->iof_prev = IOFocusNdx->iof_prev;
               j->iof_next = IOFocusNdx;
               IOFocusNdx->iof_prev->iof_next = j;
               IOFocusNdx->iof_prev = j;
           }
           IOFocusTbl[0] |= (1 << nj);
        }
     UnlockIOF();
}
        
//-----------------------------------------------------------------------------
// Release the IO focus for the current job.
//-----------------------------------------------------------------------------
void ReleaseIOFocus()
{
     ForceReleaseIOFocus(GetJCBPtr());
}

//-----------------------------------------------------------------------------
// Releasing the I/O focus causes the focus to switch if the running job
// had the I/O focus.
// ForceReleaseIOFocus forces the release of the IO focus for a job
// different than the one currently running.
//-----------------------------------------------------------------------------

void ForceReleaseIOFocus(JCB * j)
{
     JCB *p;
     
     LockIOF();
         if (IOFocusTbl[0] & (1 << (int)j->number)) {
             IOFocusTbl[0] &= ~(1 << j->number);
             if (j == IOFocusNdx)
                SwitchIOFocus();
             p = j->iof_next;
             if (p) {
                  if (p <> j) {
                        p->iof_prev = j->iof_prev;
                        j->iof_prev->iof_next = p;
                  } 
                  else {
                       IOFocusNdx = null;
                  }
                  j->iof_next = null;
                  j->iof_prev = null;
             }
         }
     UnlockIOF();
}

void CopyVirtualScreenToScreen()
{
     short int *p, *q;
     JCB *j;
     int nn, pos;

     j = IOFocusNdx;
     p = j->pVidMem;
     q = j->pVirtVidMem;
     nn = j->VideoRows * j->VideoCols;
     for (; nn >= 0; nn--)
         p[nn] = q[nn];
    pos = j->CursorRow * j->VideoCols + j->CursorCol;
    SetVideoReg(11,pos);
}

void CopyScreenToVirtualScreen()
{
     short int *p, *q;
     JCB *j;
     int nn;

     j = IOFocusNdx;
     p = j->pVidMem;
     q = j->pVirtVidMem;
     nn = j->VideoRows * j->VideoCols;
     for (; nn >= 0; nn--)
         q[nn] = p[nn];
}
