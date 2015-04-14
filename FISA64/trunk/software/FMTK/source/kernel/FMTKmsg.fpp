
typedef unsigned int uint;

typedef struct tagMSG align(32) {
	struct tagMSG *link;
	uint d1;
	uint d2;
	uint type;
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
    __int16 number;
} JCB;

struct tagMBX;

typedef struct _tagTCB align(512) {
	int regs[32];
	int isp;
	int dsp;
	int esp;
	int ipc;
	int dpc;
	int epc;
	int cr0;
	struct _tagTCB *next;
	struct _tagTCB *prev;
	struct _tagTCB *mbq_next;
	struct _tagTCB *mbq_prev;
	int *sys_stack;
	int *bios_stack;
	int *stack;
	__int64 timeout;
	JCB *hJob;
	int msgD1;
	int msgD2;
	MSG *MsgPtr;
	uint hWaitMbx;
	struct tagMBX *mailboxes;
	__int8 priority;
	__int8 status;
	__int8 affinity;
	__int16 number;
} TCB;

typedef struct tagMBX align(128) {
    struct tagMBX *link;
	TCB *tq_head;
	TCB *tq_tail;
	MSG *mq_head;
	MSG *mq_tail;
	uint tq_count;
	uint mq_size;
	uint mq_count;
	uint mq_missed;
	uint owner;		// hJcb of owner
	char mq_strategy;
	byte resv[7];
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




TCB *GetRunningTCB();
JCB *GetJCBPtr();                   // get the JCB pointer of the running task
void set_vector(unsigned int, unsigned int);
int getCPU();
void outb(unsigned int, int);
void outc(unsigned int, int);
void outh(unsigned int, int);
void outw(unsigned int, int);


extern int irq_stack[];
extern int FMTK_Inited;
extern JCB jcbs[];
extern TCB tcbs[];
extern TCB *readyQ[];
extern TCB *runningTCB;
extern TCB *freeTCB;
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
extern MSG *freeMSG;
extern MBX *freeMBX;
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
extern TCB *TimeoutList;


int chkMBX(int hMBX) {
    asm {
        lw    r1,24[bp]
        chk   r1,r1,b50
    }
}

int chkMSG(int msg) {
    asm {
        lw    r1,24[bp]
        chk   r1,r1,b51
    }
}

/* ---------------------------------------------------------------
	Description:
		Queue a message at a mailbox.

	Assumptions:
		valid mailbox parameter.

	Called from:
		SendMsg
		PostMsg
--------------------------------------------------------------- */
private int QueueMsg(MBX *mbx, MSG *msg)
{
    MSG *tmpmsg;
	int rr = E_Ok;

    if (!chkMSG(msg))
        return E_Ok;

	LockSYS();
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
		            tmpmsg = mbx->mq_head->link;
		            mbx->mq_head->link = freeMSG;
		            freeMSG = mbx->mq_head;
					nMsgBlk++;
					mbx->mq_count--;
		            mbx->mq_head = tmpmsg;
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
					freeMSG = msg;
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
					tmpmsg = mbx->mq_head;
					while (tmpmsg <> mbx->mq_tail) {
						msg = tmpmsg;
						tmpmsg = tmpmsg->link;
					}
					mbx->mq_tail = msg;
					tmpmsg->link = freeMSG;
					freeMSG = tmpmsg;
					nMsgBlk++;
					if (mbx->mq_missed < 0xFFFFFFFFFFFFFFFFL)
						mbx->mq_missed++;
					mbx->mq_count--;
					rr = E_QueFull;
				}
				if (rr == E_QueFull) {
                    UnlockSYS(); 
					return rr;
                }
                break;
		}
		// if there is a message in the queue
		if (mbx->mq_tail)
			mbx->mq_tail->link = msg;
		else
			mbx->mq_head = msg;
		mbx->mq_tail = msg;
		msg->link = (void *)0;
	UnlockSYS();
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

private MSG *DequeueMsg(MBX *mbx)
{
	MSG *tmpmsg = (void *)0;

	if (mbx->mq_count) {
		mbx->mq_count--;
		tmpmsg = mbx->mq_head;
		if (tmpmsg) {	// should not be null
			mbx->mq_head = tmpmsg->link;
			if (mbx->mq_head == (void *)0)
				mbx->mq_tail = (void *)0;
			tmpmsg->link = tmpmsg;
		}
	}
	return tmpmsg;
}


/* ---------------------------------------------------------------
	Description:
		Allocate a mailbox. The default queue strategy is to
	queue the eight most recent messages.
--------------------------------------------------------------- */
public int FMTK_AllocMbx(uint *phMbx)
{
	MBX *mbx;

	if (phMbx==(void *)0)
    	return E_Arg;
	LockSYS();
		if (freeMBX == (void *)0) {
            UnlockSYS();
			return E_NoMoreMbx;
        }
		mbx = freeMBX;
		freeMBX = mbx->link;
		nMailbox--;
	UnlockSYS();
	*phMbx = mbx - mailbox;
	mbx->owner = GetJCBPtr();
	mbx->tq_head = (void *)0;
	mbx->tq_tail = (void *)0;
	mbx->mq_head = (void *)0;
	mbx->mq_tail = (void *)0;
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
public int FMTK_FreeMbx(uint hMbx) 
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;
	
	if (hMbx >= 2048)
		return E_BadMbx;
	mbx = &mailbox[hMbx];
	LockSYS();
		if ((mbx->owner <> GetJCBPtr()) and (GetJCBPtr() <> &jcbs))
				return E_NotOwner;
		// Free up any queued messages
		while (msg = DequeueMsg(mbx)) {
			msg->link = freeMSG;
			freeMSG = msg;
			nMsgBlk++;
		}
		// Send an indicator to any queued threads that the mailbox
		// is now defunct Setting MsgPtr = null will cause any
		// outstanding WaitMsg() to return E_NoMsg.
		forever {
			DequeThreadFromMbx(mbx, &thrd);
			if (thrd == (void *)0)
				break;
			thrd->MsgPtr = (void *)0;
			if (thrd->status & 1)
				RemoveFromTimeoutList(thrd);
			InsertIntoReadyList(thrd);
		}
		mbx->link = freeMBX;
		freeMBX = mbx;
		nMailbox++;
	UnlockSYS();
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Set the mailbox message queueing strategy.
--------------------------------------------------------------- */
public SetMbxMsgQueStrategy(uint hMbx, int qStrategy, int qSize)
{
	MBX *mbx;

	if (hMbx >= 2048)
		return E_BadMbx;
	if (qStrategy > 2)
		return E_Arg;
	mbx = &mailbox[hMbx];
	LockSYS();
		if ((mbx->owner <> GetJCBPtr()) and GetJCBPtr() <> &jcbs[0])
				return E_NotOwner;
		mbx->mq_strategy = qStrategy;
		mbx->mq_size = qSize;
	UnlockSYS();
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Send a message.
--------------------------------------------------------------- */
public int FMTK_SendMsg(uint hMbx, int d1, int d2)
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;

	if (hMbx >= 2048)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner == (void *)0) {
           UnlockSYS();
           return E_NotAlloc;
        }
		msg = freeMSG;
		if (msg == (void *)0) {
		    UnlockSYS();
			return E_NoMoreMsgBlks;
        }
		freeMSG = msg->link;
		--nMsgBlk;
		msg->type = 0;
		msg->d1 = d1;
		msg->d2 = d2;
		DequeThreadFromMbx(mbx, &thrd);
	UnlockSYS();
	if (thrd == (void *)0)
		return QueueMsg(mbx, msg);
	LockSYS();
    	thrd->MsgPtr = msg;
    	if (thrd->status & 1)
    		RemoveFromTimeoutList(thrd);
    	InsertIntoReadyList(thrd);
	UnlockSYS();
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
public int FMTK_PostMsg(int hMbx, int d1, int d2)
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;
    int ret;

	if (hMbx >= 2048)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner == (void *)0) {
            UnlockSYS();
			return E_NotAlloc;
        }
		msg = freeMSG;
		if (msg == (void *)0) {
            UnlockSYS();
			return E_NoMoreMsgBlks;
        }
		freeMSG = msg->link;
		--nMsgBlk;
		msg->type = 0;
		msg->d1 = d1;
		msg->d2 = d2;
		DequeueThreadFromMbx(mbx, &thrd);
	UnlockSYS();
	if (thrd == (void *)0) {
        ret = QueueMsg(mbx, msg);
		return ret;
    }
    LockSYS();
    	thrd->MsgPtr = msg;
    	if (thrd->status & 1)
    		RemoveFromTimeoutList(thrd);
    	AddToReadyList(thrd);
   	UnlockSYS();
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Wait for message. If timelimit is zero then the thread
	will wait indefinately for a message.
--------------------------------------------------------------- */

public int FMTK_WaitMsg(uint hMbx, int *d1, int *d2, int timelimit)
{
	MBX *mbx;
	MSG *msg;
	TCB *thrd;

	if (hMbx >= 2048)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner == (void *)0) {
            UnlockSYS();
        	return E_NotAlloc;
        }
    	msg = DequeueMsg(mbx);
	UnlockSYS();
	if (msg == (void *)0) {
		LockSYS();
			thrd = GetRunningTCB();
			RemoveFromReadyList(thrd);
		UnlockSYS();
		//-----------------------
		// Queue task at mailbox
		//-----------------------
		thrd->status |= 2;
		thrd->hWaitMbx = hMbx;
		thrd->mbq_next = (void *)0;
		LockSYS();
			if (mbx->tq_head == (void *)0) {
				thrd->mbq_prev = (void *)0;
				mbx->tq_head = thrd;
				mbx->tq_tail = thrd;
				mbx->tq_count = 1;
			}
			else {
				thrd->mbq_prev = mbx->tq_tail;
				mbx->tq_tail->mbq_next = thrd;
				mbx->tq_tail = thrd;
				mbx->tq_count++;
			}
		UnlockSYS();
		//---------------------------
		// Is a timeout specified ?
		if (timelimit) {
            LockSYS();
        	    AddToTimeoutList(thrd, timelimit);
       	    UnlockSYS();
        }
		asm { int #2 }     // reschedule
		// Control will return here as a result of a SendMsg or a
		// timeout expiring
		msg = GetRunningTCB()->MsgPtr;
		if (msg == (void *)0)
			return E_NoMsg;
		GetRunningTCB()->MsgPtr = (void *)0;
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
	LockSYS();
		msg->link = freeMSG;
		freeMSG = msg;
		nMsgBlk++;
	UnlockSYS();
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

int FMTK_CheckMsg(uint hMbx, int *d1, int *d2, int qrmv)
{
	MBX *mbx;
	MSG *msg;

	if (hMbx >= 2048)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
	// check for a mailbox owner which indicates the mailbox
	// is active.
	if (mbx->owner == (void *)0) {
        UnlockSYS();
		return E_NotAlloc;
    }
	if (qrmv == true)
		msg = DequeueMsg(mbx);
	else
		msg = mbx->mq_head;
	UnlockSYS();
	if (msg == (void *)0)
		return E_NoMsg;
	if (d1)
		*d1 = msg->d1;
	if (d2)
		*d2 = msg->d2;
	if (qrmv == true) {
        LockSYS();
    		msg->link = freeMSG;
    		freeMSG = msg;
    		nMsgBlk++;
		UnlockSYS();
	}
	return E_Ok;
}


