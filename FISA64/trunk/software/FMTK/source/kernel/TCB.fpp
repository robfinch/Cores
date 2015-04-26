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






// message types

enum {
     E_Ok = 0,
     E_BadTCBHandle,
     E_BadPriority,
     E_BadCallno,
     E_Arg,
     E_BadMbx,
     E_QueFull,
     E_NoThread,
     E_NotAlloc,
     E_NoMsg,
     E_Timeout,
     E_BadAlarm,
     E_NotOwner,
     E_QueStrategy,
     E_DCBInUse,
     //; Device driver errors
     E_BadDevNum =	0x20,
     E_NoDev,
     E_BadDevOp,
     E_ReadError,
     E_WriteError,
     E_BadBlockNum,
     E_TooManyBlocks,

     // resource errors
     E_NoMoreMbx =	0x40,
     E_NoMoreMsgBlks,
     E_NoMoreAlarmBlks,
     E_NoMoreTCBs,
     E_NoMem,
     E_TooManyTasks
};


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
    unsigned __int8 KeybdBuffer[32];
    hJCB number;
    hTCB tasks[8];
    hJCB next;
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
	int exception;
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

pascal void set_vector(unsigned int, unsigned int);
int getCPU();
int GetVecno();          // get the last interrupt vector number
void outb(unsigned int, int);
void outc(unsigned int, int);
void outh(unsigned int, int);
void outw(unsigned int, int);
pascal int LockSemaphore(int *sema, int retries);
pascal void UnlockSemaphore(int *sema);

// The following causes a privilege violation if called from user mode


extern char hasUltraHighPriorityTasks;
extern pascal prtdbl(double);

TCB tcbs[256];
hTCB freeTCB;
hTCB TimeoutList;
hTCB readyQ[8];

pascal int chkTCB(TCB *p)
{
    asm {
        lw    r1,24[bp]
        chk   r1,r1,b48
    }
}

naked TCB *GetRunningTCBPtr()
{
    asm {
        mov   r1,tr
        rtl
    }
}

naked hTCB GetRunningTCB()
{
    asm {
        subui  r1,tr,#tcbs_
        lsri   r1,r1,#10
        rtl
    }
}

pascal void SetRunningTCB(hTCB ht)
{
     asm {
         lw      tr,24[bp]
         asli    tr,tr,#10
         addui   tr,tr,#tcbs_
     }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int InsertIntoReadyList(hTCB ht)
{
    hTCB hq;
    TCB *p, *q;

    __check(ht >=0 && ht < 256);
    p = &tcbs[ht];
	if (p->priority > 077 || p->priority < 000)
		return E_BadPriority;
	if (p->priority < 003)
	   hasUltraHighPriorityTasks |= (1 << p->priority);
	p->status = 16;
	hq = readyQ[p->priority>>3];
	// Ready list empty ?
	if (hq<0) {
		p->next = ht;
		p->prev = ht;
		readyQ[p->priority>>3] = ht;
		return E_Ok;
	}
	// Insert at tail of list
	q = &tcbs[hq];
	p->next = hq;
	p->prev = q->prev;
	tcbs[q->prev].next = ht;
	q->prev = ht;
	return E_Ok;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int RemoveFromReadyList(hTCB ht)
{
    TCB *t;

    __check(ht >=0 && ht < 256);
    t = &tcbs[ht];
	if (t->priority > 077 || t->priority < 000)
		return E_BadPriority;
    if (ht==readyQ[t->priority>>3])
       readyQ[t->priority>>3] = t->next;
    if (ht==readyQ[t->priority>>3])
       readyQ[t->priority>>3] = -1;
    tcbs[t->next].prev = t->prev;
    tcbs[t->prev].next = t->next;
    t->next = -1;
    t->prev = -1;
    t->status = 0;
    return E_Ok;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int InsertIntoTimeoutList(hTCB ht, int to)
{
    TCB *p, *q, *t;

    __check(ht >=0 && ht < 256);
    t = &tcbs[ht];
    if (TimeoutList<0) {
        t->timeout = to;
        TimeoutList = ht;
        t->next = -1;
        t->prev = -1;
        return E_Ok;
    }
    q = (void *)0;
    p = &tcbs[TimeoutList];
    while (to > p->timeout) {
        to -= p->timeout;
        q = p;
        p = &tcbs[p->next];
    }
    t->next = p - tcbs;
    t->prev = q - tcbs;
    if (p) {
        p->timeout -= to;
        p->prev = ht;
    }
    if (q)
        q->next = ht;
    else
        TimeoutList = ht;
    t->status |= 1;
    return E_Ok;
};

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int RemoveFromTimeoutList(hTCB ht)
{
    TCB *t;
    
    __check(ht >=0 && ht < 256);
    t = &tcbs[ht];
    if (t->next) {
       tcbs[t->next].prev = t->prev;
       tcbs[t->next].timeout += t->timeout;
    }
    if (t->prev >= 0)
       tcbs[t->prev].next = t->next;
    t->status = 0;
    t->next = -1;
    t->prev = -1;
}

// ----------------------------------------------------------------------------
// Pop the top entry from the timeout list.
// ----------------------------------------------------------------------------

hTCB PopTimeoutList()
{
    TCB *p;
    hTCB h;

    h = TimeoutList;
    if (TimeoutList >= 0 && TimeoutList < 256) {
        TimeoutList = tcbs[TimeoutList].next;
        if (TimeoutList >= 0 && TimeoutList < 256)
            tcbs[TimeoutList].prev = -1;
    }
    return h;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void DumpTaskList()
{
     TCB *p, *q;
     int n;
     int kk;
     hTCB h, j;
   
//     printf("pi is ");
//     prtdbl(3.141592653589793238,10,6,'E');
     printf("CPU Pri Stat Task Prev Next Timeout\r\n");
     for (n = 0; n < 8; n++) {
         h = readyQ[n];
         if (h >= 0 && h < 256) {
             q = &tcbs[h];
             p = q;
             kk = 0;
             do {
//                 if (!chkTCB(p)) {
//                     printf("Bad TCB (%X)\r\n", p);
//                     break;
//                 }
                   j = p - tcbs;
                 printf("%3d %3d  %02X  %04X %04X %04X %08X %08X\r\n", p->affinity, p->priority, p->status, (int)j, p->prev, p->next, p->timeout, p->ticks);
                 if (p->next < 0 || p->next >= 256)
                     break;
                 p = &tcbs[p->next];
                 if (getcharNoWait()==3)
                    goto j1;
                 kk = kk + 1;
             } while (p != q && kk < 10);
         }
     }
     printf("Waiting tasks\r\n");
     h = TimeoutList;
     while (h >= 0 && h < 256) {
         p = &tcbs[h];
         printf("%3d %3d  %02X  %04X %04X %04X %08X %08X\r\n", p->affinity, p->priority, p->status, (int)j, p->prev, p->next, p->timeout, p->ticks);
         h = p->next;
         if (getcharNoWait()==3)
            goto j1;
     }
j1:  ;
}


