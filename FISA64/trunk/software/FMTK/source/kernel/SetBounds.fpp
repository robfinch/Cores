// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// SetBounds.c
// Set processor bounds registers for FMTK.
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
     E_NoMem
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


pascal void SetBound48(TCB *ps, TCB *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   112,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   176,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   240,r1      ; modulo mask not used
     }
}

pascal void SetBound49(JCB *ps, JCB *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   113,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   177,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   241,r1      ; modulo mask not used
     }
}

pascal void SetBound50(MBX *ps, MBX *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   114,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   178,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   242,r1      ; modulo mask not used
     }
}

pascal void SetBound51(MSG *ps, MSG *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   115,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   179,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   243,r1      ; modulo mask not used
     }
}

