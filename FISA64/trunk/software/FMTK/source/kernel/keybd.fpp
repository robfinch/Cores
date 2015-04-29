// The keyboard semaphore is locked only for short durations, so the interrupt
// routine doesn't need to make many attempts to lock the semaphore.







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


extern int irq_stack[];
extern int FMTK_Inited;
extern JCB jcbs[];
extern TCB tcbs[];
extern hTCB readyQ[];
extern hTCB freeTCB;
extern int sysstack[];
extern int stacks[][];
extern int sys_stacks[][];
extern int bios_stacks[][];
extern int fmtk_irq_stack[];
extern int fmtk_sys_stack[];
extern MBX mailbox[];
extern MSG message[];
extern int nMsgBlk;
extern int nMailbox;
extern hMSG freeMSG;
extern hMBX freeMBX;
extern JCB *IOFocusNdx;
extern int IOFocusTbl[];
extern int iof_switch;
extern int BIOS1_sema;
extern int iof_sema;
extern int sys_sema;
extern int kbd_sema;
extern int BIOS_RespMbx;
extern char hasUltraHighPriorityTasks;
extern int missed_ticks;
extern short int video_bufs[][];
extern hTCB TimeoutList;


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


/*
SC_DEL		EQU		$71		; extend
SC_LCTRL	EQU		$58
*/

extern byte keybdExtendedCodes[];
extern byte keybdControlCodes[];
extern byte shiftedScanCodes[];
extern byte unshiftedScanCodes[];
extern signed byte KeybdGetStatus();
extern byte KeybdGetScancode();
extern void KeybdClearRcv();
int kbd_sema = 0;

//
// KeyState2_
// 876543210
// ||||||||+ = shift
// |||||||+- = alt
// ||||||+-- = control
// |||||+--- = numlock
// ||||+---- = capslock
// |||+----- = scrolllock
// ||+------ =
// |+------- = 
// +-------- = extended
//

unsigned int keybd_irq_stack[256];

void KeybdIRQ()
{
    __int8 sc;
    __int8 kh, kt;
    hTCB ht;
    TCB *t;
    JCB *jcb;
    int nn;

     prolog asm {
         lea   sp,keybd_irq_stack_+2040
         sw    r1,8+312[tr]
         sw    r2,16+312[tr]
         sw    r3,24+312[tr]
         sw    r4,32+312[tr]
         sw    r5,40+312[tr]
         sw    r6,48+312[tr]
         sw    r7,56+312[tr]
         sw    r8,64+312[tr]
         sw    r9,72+312[tr]
         sw    r10,80+312[tr]
         sw    r11,88+312[tr]
         sw    r12,96+312[tr]
         sw    r13,104+312[tr]
         sw    r14,112+312[tr]
         sw    r15,120+312[tr]
         sw    r16,128+312[tr]
         sw    r17,136+312[tr]
         sw    r18,144+312[tr]
         sw    r19,152+312[tr]
         sw    r20,160+312[tr]
         sw    r21,168+312[tr]
         sw    r22,176+312[tr]
         sw    r23,184+312[tr]
         sw    r24,192+312[tr]
         sw    r25,200+312[tr]
         sw    r26,208+312[tr]
         sw    r27,216+312[tr]
         sw    r28,224+312[tr]
         sw    r29,232+312[tr]
         sw    r30,240+312[tr]
         sw    r31,248+312[tr]
         mfspr r1,cr0
         sw    r1,304[tr]
     }
     while (KeybdGetStatus() < 0) {    // Is there actually a scancode available ?
         sc = KeybdGetScancode();
         jcb = IOFocusNdx;             // Are there any jobs with focus ?     
         if (jcb) {
          	 if (LockSemaphore(&kbd_sema,200)) {
                 KeybdClearRcv();              // clear recieve register
                 kh = jcb->KeybdHead;
                 kt = jcb->KeybdTail;
                 kh++;
                 kh &= 31;
                 if (kh <> kt) {
                     jcb->KeybdHead = kh;   
                     jcb->KeybdBuffer[kh] = sc;
                 }
                 UnlockSemaphore(&kbd_sema);
             }
             // If CTRL-C is pressed, cause the tasks to return to the 
             // catch handler.
             if (jcb->KeyState2 & 4) {
                 if(sc == 0x21) {      // control-c ?
                     for (nn = 0; nn < 8; nn++) {
                         if (jcb->tasks[nn]==-1)
                             break;
                         t = &tcbs[jcb->tasks[nn]];
                         t->exception = 512+3;     // CTRL-C type exception
                     }
                 }
                 else if (sc==0x2C || sc==0x1A) {
                      t = &tcbs[2];
                      t->exception = (512 + ((sc==0x2C) ? 20 : 26)) | (GetRunningTCB() << 32);
                 }
             }
             if ((jcb->KeyState2 & 2) && sc == 0x0D)    // ALT + TAB ?
                 iof_switch++;       
         }
     }
     // Restore the processor registers and return using an RTI.
     epilog asm {
         lw    r1,304[tr]
         mtspr cr0,r1
         lw    r1,8+312[tr]
         lw    r2,16+312[tr]
         lw    r3,24+312[tr]
         lw    r4,32+312[tr]
         lw    r5,40+312[tr]
         lw    r6,48+312[tr]
         lw    r7,56+312[tr]
         lw    r8,64+312[tr]
         lw    r9,72+312[tr]
         lw    r10,80+312[tr]
         lw    r11,88+312[tr]
         lw    r12,96+312[tr]
         lw    r13,104+312[tr]
         lw    r14,112+312[tr]
         lw    r15,120+312[tr]
         lw    r16,128+312[tr]
         lw    r17,136+312[tr]
         lw    r18,144+312[tr]
         lw    r19,152+312[tr]
         lw    r20,160+312[tr]
         lw    r21,168+312[tr]
         lw    r22,176+312[tr]
         lw    r23,184+312[tr]
         lw    r25,200+312[tr]
         lw    r26,208+312[tr]
         lw    r27,216+312[tr]
         lw    r28,224+312[tr]
         lw    r29,232+312[tr]
         lw    r31,248+312[tr]
         rti
     }
}


// Return -1 if there is a scancode available in the buffer.

int KeybdGetBufferStatus()
{
    JCB *j;
    __int8 kh, kt;

    kh = kt = 0;
    j = GetJCBPtr();
    if (LockSemaphore(&kbd_sema,200)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        UnlockSemaphore(&kbd_sema);
    }
    if (kh<>kt)
        return -1;
    return 0;
            
}

// Get a scancode from the keyboard buffer.

__int8 KeybdGetBufferedScancode()
{
    JCB *j;
    __int8 kh, kt;
    __int8 sc;

    j = GetJCBPtr();
    sc = 0;
    if (LockSemaphore(&kbd_sema,200)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        if (kh <> kt) {
            sc = j->KeybdBuffer[kt];
            kt++;
            kt &= 31;
            j->KeybdTail = kt;
        }
        UnlockSemaphore(&kbd_sema);
    }
    return sc;
}

private char KeybdGetBufferedChar()
{
    JCB *j;
    unsigned __int8 sc;
    char ch;

    j = GetJCBPtr();
    forever {
        while (KeybdGetBufferStatus() >= 0) {
            if (j->KeybdWaitFlag==0)
                return -1;
        }
        // The following typecast is needed to avoid a compiler bug in the
        // optimizer which removes the conversion from byte to word by zero
        // extension.
        sc = (unsigned __int8)KeybdGetBufferedScancode();
        switch(sc) {
        case 0xF0:
            j->KeyState1 = -1;
            break;
        case 0xE0:
            j->KeyState2 |= 0x80;
            break;
        case 0x14:
            if (j->KeyState1 >= 0)
                j->KeyState2 |= 4;
            else
                j->KeyState2 &= ~4;
            j->KeyState1 = 0;
            break;
        case 0x59:
            if (j->KeyState1 >= 0)
                j->KeyState2 |= 1;
            else
                j->KeyState2 &= ~1;
            j->KeyState1 = 0;
            break;
        case 0x77:
            j->KeyState2 ^= 16;
            //KeybdSetLEDStatus();
            break;
        case 0x58:
            j->KeyState2 ^= 32;
            //KeybdSetLEDStatus();
            break;
        case 0x7E:
            j->KeyState2 ^= 64;
            //KeybdSetLEDStatus();
            break;
        case 0x11:
            if (j->KeyState1 >= 0)
                j->KeyState2 |= 2;
            else
                j->KeyState2 &= ~2;
            j->KeyState1 = 0;
            break;
        default:
            if (sc == 0x0D && (j->KeyState2 & 2) && j->KeyState1==0) {
                iof_switch++;
            }
            else {
                 if (j->KeyState1) {
                     j->KeyState1 = 0;
                 }
                 else {
                      if (j->KeyState2 & 0x80) { // Extended code ?
                          j->KeyState2 &= ~0x80;
                          ch = keybdExtendedCodes[sc];
                          j->KeyState1 = 0;
                          return ch;
                      }
                      else if (j->KeyState2 & 0x04) { // control ?
                          ch = keybdControlCodes[sc];
                          return ch;
                      }
                      else if (j->KeyState2 & 0x01) { // shifted ?
                          ch = shiftedScanCodes[sc];
                          return ch;
                      }
                      else {
                          ch = unshiftedScanCodes[sc];
                          return ch;
                      }
                 }
            }
        }
    }
}

char KeybdGetBufferedCharWait() {
    JCB *j;
    j = GetJCBPtr();
    j->KeybdWaitFlag = 1;
    return KeybdGetBufferedChar();     
}

char KeybdGetBufferedCharNoWait() {
    JCB *j;
    j = GetJCBPtr();
    j->KeybdWaitFlag = 0;
    return KeybdGetBufferedChar();     
}

