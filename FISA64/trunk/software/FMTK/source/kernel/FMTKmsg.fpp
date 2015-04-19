
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
extern int BIOS_RespMbx;
extern char hasUltraHighPriorityTasks;
extern int missed_ticks;
extern short int video_bufs[][];
extern hTCB TimeoutList;


extern int sys_sema;

/* ---------------------------------------------------------------
	Description:
		Queue a message at a mailbox.

	Assumptions:
		valid mailbox parameter.

	Called from:
		SendMsg
		PostMsg
--------------------------------------------------------------- */
private pascal int QueueMsg(MBX *mbx, MSG *msg)
{
    MSG *tmpmsg;
    hMSG htmp;
	int rr = E_Ok;

	if (LockSemaphore(&sys_sema,-1)) {
		mbx->mq_count++;
	
		// handle potential queue overflows
	    switch (mbx->mq_strategy) {
	    
	    	// unlimited queing (do nothing)
			case 0:
				break;
				
			// buffer newest
			// if the queue is full then old messages are lost
			// Older messages are at the head of the queue.
			// loop incase message queing strategy was changed
		    case 2:
		        while (mbx->mq_count > mbx->mq_size) {
		            // return outdated message to message pool
		            htmp = message[mbx->mq_head].link;
		            tmpmsg = &message[htmp];
		            message[mbx->mq_head].link = freeMSG;
		            freeMSG = mbx->mq_head;
					nMsgBlk++;
					mbx->mq_count--;
		            mbx->mq_head = htmp;
					if (mbx->mq_missed < 0xFFFFFFFFFFFFFFFFL)
						mbx->mq_missed++;
					rr = E_QueFull;
				}
		        break;
   
			// buffer oldest
			// if the queue is full then new messages are lost
			// loop incase message queing strategy was changed
			case 1:
				// first return the passed message to free pool
				if (mbx->mq_count > mbx->mq_size) {
					// return new message to pool
					msg->link = freeMSG;
					freeMSG = msg-message;
					nMsgBlk++;
					if (mbx->mq_missed < 0xFFFFFFFFFFFFFFFFL)
						mbx->mq_missed++;
					rr = E_QueFull;
					mbx->mq_count--;
				}
				// next if still over the message limit (which
				// might happen if que strategy was changed), return
				// messages to free pool
				while (mbx->mq_count > mbx->mq_size) {
					// locate the second last message on the que
					tmpmsg = &message[mbx->mq_head];
					while (tmpmsg-message <> mbx->mq_tail) {
						msg = tmpmsg;
						tmpmsg = &message[tmpmsg->link];
					}
					mbx->mq_tail = msg-message;
					tmpmsg->link = freeMSG;
					freeMSG = tmpmsg-message;
					nMsgBlk++;
					if (mbx->mq_missed < 0xFFFFFFFFFFFFFFFFL)
						mbx->mq_missed++;
					mbx->mq_count--;
					rr = E_QueFull;
				}
				if (rr == E_QueFull) {
             	    UnlockSemaphore(&sys_sema);
					return rr;
                }
                break;
		}
		// if there is a message in the queue
		if (mbx->mq_tail >= 0)
			message[mbx->mq_tail].link = msg-message;
		else
			mbx->mq_head = msg-message;
		mbx->mq_tail = msg-message;
		msg->link = -1;
	    UnlockSemaphore(&sys_sema);
    }
	return rr;
}


/* ---------------------------------------------------------------
	Description:
		Dequeues a message from a mailbox.

	Assumptions:
		Mailbox parameter is valid.
		System semaphore is locked already.

	Called from:
		FreeMbx - (locks mailbox)
		WaitMsg	-	"
		CheckMsg-	"
--------------------------------------------------------------- */

private pascal MSG *DequeueMsg(MBX *mbx)
{
	MSG *tmpmsg = (void *)0;
    hMSG hm;
 
	if (mbx->mq_count) {
		mbx->mq_count--;
		hm = mbx->mq_head;
		if (hm >= 0) {	// should not be null
		    tmpmsg = &message[hm];
			mbx->mq_head = tmpmsg->link;
			if (mbx->mq_head < 0)
				mbx->mq_tail = -1;
			tmpmsg->link = hm;
		}
	}
	return tmpmsg;
}


/* ---------------------------------------------------------------
	Description:
		Allocate a mailbox. The default queue strategy is to
	queue the eight most recent messages.
--------------------------------------------------------------- */
public int FMTK_AllocMbx(hMBX *phMbx)
{
	MBX *mbx;

    asm { mfspr r1,ivno };
	if (phMbx==(void *)0)
    	return E_Arg;
	if (LockSemaphore(&sys_sema,-1)) {
		if (freeMBX < 0 || freeMBX >= 1024) {
    	    UnlockSemaphore(&sys_sema);
			return E_NoMoreMbx;
        }
		mbx = &mailbox[freeMBX];
		freeMBX = mbx->link;
		nMailbox--;
	    UnlockSemaphore(&sys_sema);
    }
	*phMbx = mbx - mailbox;
	mbx->owner = GetJCBPtr();
	mbx->tq_head = -1;
	mbx->tq_tail = -1;
	mbx->mq_head = -1;
	mbx->mq_tail = -1;
	mbx->tq_count = 0;
	mbx->mq_count = 0;
	mbx->mq_missed = 0;
	mbx->mq_size = 8;
	mbx->mq_strategy = 2;
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Free up a mailbox. When the mailbox is freed any queued
	messages must be freed. Any queued threads must also be
	dequeued. 
--------------------------------------------------------------- */
public int FMTK_FreeMbx(hMBX hMbx) 
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;
	
    asm { mfspr r1,ivno };
	__check (hMbx >= 0 && hMbx < 1024);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		if ((mbx->owner <> GetJCBPtr()) and (GetJCBPtr() <> &jcbs)) {
    	    UnlockSemaphore(&sys_sema);
			return E_NotOwner;
        }
		// Free up any queued messages
		while (msg = DequeueMsg(mbx)) {
            msg->type = 1;
            msg->retadr = -1;
            msg->tgtadr = -1;
			msg->link = freeMSG;
			freeMSG = msg - message;
			nMsgBlk++;
		}
		// Send an indicator to any queued threads that the mailbox
		// is now defunct Setting MsgPtr = null will cause any
		// outstanding WaitMsg() to return E_NoMsg.
		forever {
			DequeThreadFromMbx(mbx, &thrd);
			if (thrd == (void *)0)
				break;
			thrd->msg.type = 0;
			if (thrd->status & 1)
				RemoveFromTimeoutList(thrd-tcbs);
			InsertIntoReadyList(thrd-tcbs);
		}
		mbx->link = freeMBX;
		freeMBX = mbx-mailbox;
		nMailbox++;
	    UnlockSemaphore(&sys_sema);
    }
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Set the mailbox message queueing strategy.
--------------------------------------------------------------- */
public int SetMbxMsgQueStrategy(hMBX hMbx, int qStrategy, int qSize)
{
	MBX *mbx;

    asm { mfspr r1,ivno };
	__check (hMbx >= 0 && hMbx < 1024);
	if (qStrategy > 2)
		return E_Arg;
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		if ((mbx->owner <> GetJCBPtr()) and GetJCBPtr() <> &jcbs[0]) {
      	    UnlockSemaphore(&sys_sema);
			return E_NotOwner;
        }
		mbx->mq_strategy = qStrategy;
		mbx->mq_size = qSize;
	    UnlockSemaphore(&sys_sema);
    }
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Send a message.
--------------------------------------------------------------- */
public int FMTK_SendMsg(hMBX hMbx, int d1, int d2, int d3)
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;

    asm { mfspr r1,ivno };
	__check (hMbx >= 0 && hMbx < 1024);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner < 0 || mbx->owner >= 51) {
    	    UnlockSemaphore(&sys_sema);
            return E_NotAlloc;
        }
		if (freeMSG < 0 || freeMSG >= 16384) {
    	    UnlockSemaphore(&sys_sema);
			return E_NoMoreMsgBlks;
        }
		msg = &message[freeMSG];
		freeMSG = msg->link;
		--nMsgBlk;
		msg->retadr = GetJCBPtr()-jcbs;
		msg->tgtadr = hMbx;
		msg->type = 2;
		msg->d1 = d1;
		msg->d2 = d2;
		msg->d3 = d3;
		DequeThreadFromMbx(mbx, &thrd);
	    UnlockSemaphore(&sys_sema);
    }
	if (thrd == (void *)0)
		return QueueMsg(mbx, msg);
	if (LockSemaphore(&sys_sema,-1)) {
        thrd->msg.retadr = msg->retadr;
        thrd->msg.tgtadr = msg->tgtadr;
        thrd->msg.type = msg->type;
        thrd->msg.d1 = msg->d1;
        thrd->msg.d2 = msg->d2;
        thrd->msg.d3 = msg->d3;
        // free message here
        msg->type = 1;
        msg->retadr = -1;
        msg->tgtadr = -1;
        msg->link = freeMSG;
        freeMSG = msg-message;
    	if (thrd->status & 1)
    		RemoveFromTimeoutList(thrd-tcbs);
    	InsertIntoReadyList(thrd-tcbs);
	    UnlockSemaphore(&sys_sema);
    }
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		PostMsg() is meant to be called in order to send a
	message without causing the thread to switch. This is
	useful in some cases. For example interrupts that don't
	require a low latency. Normally SendMsg() will be called,
	even from an ISR to allow the OS to prioritize events.
--------------------------------------------------------------- */
public int FMTK_PostMsg(hMBX hMbx, int d1, int d2, int d3)
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;
    int ret;

    asm { mfspr r1,ivno };
	__check (hMbx >= 0 && hMbx < 1024);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner < 0 || mbx->owner >= 51) {
    	    UnlockSemaphore(&sys_sema);
			return E_NotAlloc;
        }
		if (freeMSG  <0 || freeMSG >= 16384) {
    	    UnlockSemaphore(&sys_sema);
			return E_NoMoreMsgBlks;
        }
		msg = &message[freeMSG];
		freeMSG = msg->link;
		--nMsgBlk;
		msg->retadr = GetJCBPtr()-jcbs;
		msg->tgtadr = hMbx;
		msg->type = 2;
		msg->d1 = d1;
		msg->d2 = d2;
		msg->d3 = d3;
		DequeueThreadFromMbx(mbx, &thrd);
	    UnlockSemaphore(&sys_sema);
    }
	if (thrd == (void *)0) {
        ret = QueueMsg(mbx, msg);
		return ret;
    }
	if (LockSemaphore(&sys_sema,-1)) {
        thrd->msg.retadr = msg->retadr;
        thrd->msg.tgtadr = msg->tgtadr;
        thrd->msg.type = msg->type;
        thrd->msg.d1 = msg->d1;
        thrd->msg.d2 = msg->d2;
        thrd->msg.d3 = msg->d3;
        // free message here
        msg->type = 1;
        msg->retadr = -1;
        msg->tgtadr = -1;
        msg->link = freeMSG;
        freeMSG = msg-message;
    	if (thrd->status & 1)
    		RemoveFromTimeoutList(thrd-tcbs);
    	InsertIntoReadyList(thrd-tcbs);
	    UnlockSemaphore(&sys_sema);
    }
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Wait for message. If timelimit is zero then the thread
	will wait indefinately for a message.
--------------------------------------------------------------- */

public int FMTK_WaitMsg(hMBX hMbx, int *d1, int *d2, int *d3, int timelimit)
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;
	TCB *rt;

    asm { mfspr r1,ivno };
	__check (hMbx >= 0 && hMbx < 1024);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner <0 || mbx->owner >= 51) {
     	    UnlockSemaphore(&sys_sema);
        	return E_NotAlloc;
        }
    	msg = DequeueMsg(mbx);
	    UnlockSemaphore(&sys_sema);
    }
	if (msg == (void *)0) {
    	if (LockSemaphore(&sys_sema,-1)) {
			thrd = GetRunningTCBPtr();
			RemoveFromReadyList(thrd-tcbs);
    	    UnlockSemaphore(&sys_sema);
        }
		//-----------------------
		// Queue task at mailbox
		//-----------------------
		thrd->status |= 2;
		thrd->hWaitMbx = hMbx;
		thrd->mbq_next = (void *)0;
    	if (LockSemaphore(&sys_sema,-1)) {
			if (mbx->tq_head < 0) {
				thrd->mbq_prev = -1;
				mbx->tq_head = thrd-tcbs;
				mbx->tq_tail = thrd-tcbs;
				mbx->tq_count = 1;
			}
			else {
				thrd->mbq_prev = mbx->tq_tail;
				tcbs[mbx->tq_tail].mbq_next = thrd-tcbs;
				mbx->tq_tail = thrd-tcbs;
				mbx->tq_count++;
			}
    	    UnlockSemaphore(&sys_sema);
        }
		//---------------------------
		// Is a timeout specified ?
		if (timelimit) {
        	if (LockSemaphore(&sys_sema,-1)) {
        	    InsertIntoTimeoutList(thrd-tcbs, timelimit);
        	    UnlockSemaphore(&sys_sema);
            }
        }
		asm { int #2 }     // reschedule
		// Control will return here as a result of a SendMsg or a
		// timeout expiring
		rt = GetRunningTCBPtr(); 
		if (rt->msg.type == 0)
			return E_NoMsg;
		// rip up the envelope
		rt->msg.type = 0;
		rt->msg.tgtadr = -1;
		rt->msg.retadr = -1;
    	if (d1)
    		*d1 = rt->msg.d1;
    	if (d2)
    		*d2 = rt->msg.d2;
    	if (d3)
    		*d3 = rt->msg.d3;
		return E_Ok;
	}
	//-----------------------------------------------------
	// We get here if there was initially a message
	// available in the mailbox, or a message was made
	// available after a task switch.
	//-----------------------------------------------------
	if (d1)
		*d1 = msg->d1;
	if (d2)
		*d2 = msg->d2;
	if (d3)
		*d3 = msg->d3;
   	if (LockSemaphore(&sys_sema,-1)) {
        msg->type = 1;
        msg->retadr = -1;
        msg->tgtadr = -1;
		msg->link = freeMSG;
		freeMSG = msg-message;
		nMsgBlk++;
	    UnlockSemaphore(&sys_sema);
    }
	return E_Ok;
}

// ----------------------------------------------------------------------------
// PeekMsg()
//     Look for a message in the queue but don't remove it from the queue.
//     This is a convenince wrapper for CheckMsg().
// ----------------------------------------------------------------------------

int FMTK_PeekMsg(uint hMbx, int *d1, int *d2)
{
    return CheckMsg(hMbx, d1, d2, 0);
}

/* ---------------------------------------------------------------
	Description:
		Check for message at mailbox. If no message is
	available return immediately to the caller (CheckMsg() is
	non blocking). Optionally removes the message from the
	mailbox.
--------------------------------------------------------------- */

int FMTK_CheckMsg(hMBX hMbx, int *d1, int *d2, int *d3, int qrmv)
{
	MBX *mbx;
	MSG *msg;

    asm { mfspr r1,ivno };
	__check (hMbx >= 0 && hMbx < 1024);
	mbx = &mailbox[hMbx];
   	if (LockSemaphore(&sys_sema,-1)) {
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner == (void *)0) {
    	    UnlockSemaphore(&sys_sema);
    		return E_NotAlloc;
        }
    	if (qrmv == true)
    		msg = DequeueMsg(mbx);
    	else
    		msg = mbx->mq_head;
	    UnlockSemaphore(&sys_sema);
    }
	if (msg == (void *)0)
		return E_NoMsg;
	if (d1)
		*d1 = msg->d1;
	if (d2)
		*d2 = msg->d2;
	if (d3)
		*d3 = msg->d3;
	if (qrmv == true) {
       	if (LockSemaphore(&sys_sema,-1)) {
            msg->type = 1;
            msg->retadr = -1;
            msg->tgtadr = -1;
    		msg->link = freeMSG;
    		freeMSG = msg-message;
    		nMsgBlk++;
    	    UnlockSemaphore(&sys_sema);
        }
	}
	return E_Ok;
}


