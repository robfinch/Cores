#include "types.h"
#include "const.h"

int chkMBX(int hMBX) {
    asm {
        lw    r1,24[bp]
        chk   r1,r1,b49
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
			case MQS_UNLIMITED:
				break;
				
			// buffer newest
			// if the queue is full then old messages are lost
			// Older messages are at the head of the queue.
			// loop incase message queing strategy was changed
		    case MQS_NEWEST:
		        while (mbx->mq_count > mbx->mq_size) {
		            // return outdated message to message pool
		            tmpmsg = mbx->mq_head->link;
		            mbx->mq_head->link = freeMSG;
		            freeMSG = mbx->mq_head;
					nMsgBlk++;
					mbx->mq_count--;
		            mbx->mq_head = tmpmsg;
					if (mbx->mq_missed < MAX_UINT)
						mbx->mq_missed++;
					rr = E_QueFull;
				}
		        break;
   
			// buffer oldest
			// if the queue is full then new messages are lost
			// loop incase message queing strategy was changed
			case MQS_OLDEST:
				// first return the passed message to free pool
				if (mbx->mq_count > mbx->mq_size) {
					// return new message to pool
					msg->link = freeMSG;
					freeMSG = msg;
					nMsgBlk++;
					if (mbx->mq_missed < MAX_UINT)
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
					if (mbx->mq_missed < MAX_UINT)
						mbx->mq_missed++;
					mbx->mq_count--;
					rr = E_QueFull;
				}
				if (rr == E_QueFull) {
                    UnlockSYS(); 
					return rr;
                }
			}
		}
		// if there is a message in the queue
		if (mbx->mq_tail)
			mbx->mq_tail->link = msg;
		else
			mbx->mq_head = msg;
		mbx->mq_tail = msg;
		msg->link = null;
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
	MSG *tmpmsg = null;

	if (mbx->mq_count) {
		mbx->mq_count--;
		tmpmsg = mbx->mq_head;
		if (tmpmsg) {	// should not be null
			mbx->mq_head = tmpmsg->link;
			if (mbx->mq_head == null)
				mbx->mq_tail = null;
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

	if (phMBX==null)
    	return E_Arg;
	LockSYS();
		if (FreeMBX == null) {
            UnlockSYS();
			return E_NoMoreMbx;
        }
		mbx = FreeMBX;
		FreeMBX = mbx->link;
		nMailbox--;
	UnlockSYS();
	*phMbx = mbx - mailbox;
	mbx->owner = GetJCBPtr();
	mbx->tq_head = null;
	mbx->tq_tail = null;
	mbx->mq_head = null;
	mbx->mq_tail = null;
	mbx->tq_count = 0;
	mbx->mq_count = 0;
	mbx->mq_missed = 0;
	mbx->mq_size = 8;
	mbx->mq_strategy = MQS_NEWEST;
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
	TCB *thread;
	
	if (hMbx >= NR_MBX)
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
			DequeThreadFromMbx(mbx, &thread);
			if (thread == null)
				break;
			thread->MsgPtr = null;
			if (thread->status & TS_TIMEOUT)
				RemoveFromTimeoutList(thread);
			InsertIntoReadyList(thread);
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

	if (hMbx >= NR_MBX)
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
	TCB *thread;

	if (hMbx >= NR_MBX)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner == null) {
           UnlockSYS();
           return E_NotAlloc;
        }
		msg = freeMSG;
		if (msg == null) {
		    UnlockSYS();
			return E_NoMoreMsgBlks;
        }
		freeMSG = msg->link;
		--nMsgBlk;
		msg->msgtype = MBT_DATA;
		msg->d1 = d1;
		msg->d2 = d2;
		DequeThreadFromMbx(mbx, &thread);
	UnlockSYS();
	if (thread == null)
		return QueueMsg(mbx, msg);
	LockSYS();
    	thread->MsgPtr = msg;
    	if (thread->status & TS_TIMEOUT)
    		RemoveFromTimeoutList(thread);
    	InsertIntoReadyList(thread);
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
	TCB *thread;
    int ret;

	if (hMbx >= MaxMailbox)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner == null) {
            UnlockSYS();
			return E_NotAlloc;
        }
		msg = freeMsg;
		if (msg == null) {
            UnlockSYS();
			return E_NoMoreMsgBlks;
        }
		freeMsg = msg->link;
		--nMsgBlk;
		msg->msgtype = MBT_DATA;
		msg->d1 = d1;
		msg->d2 = d2;
		DequeueThreadFromMbx(mbx, &thread);
	UnlockSYS();
	if (thread == null) {
        ret = QueueMsg(mbx, msg);
		return ret;
    }
    LockSYS();
    	thread->MsgPtr = msg;
    	if (thread->status & TS_TIMEOUT)
    		RemoveFromTimeoutList(thread);
    	AddToReadyList(thread);
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
	TCB *thread;

	if (hMbx >= NR_MBX)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner == null) {
            UnlockSYS();
        	return E_NotAlloc;
        }
    	msg = DequeueMsg(mbx);
	UnlockSYS();
	if (msg == null) {
		LockSYS();
			thread = GetRunningTCB();
			RemoveFromReadyList(thread);
		UnlockSYS();
		//-----------------------
		// Queue task at mailbox
		//-----------------------
		thread->status |= TS_WAITMSG;
		thread->hWaitMbx = hMbx;
		thread->mbq_next = null;
		LockSYS();
			if (mbx->tq_head == null) {
				thread->mbq_prev = null;
				mbx->tq_head = thread;
				mbx->tq_tail = thread;
				mbx->tq_count = 1;
			}
			else {
				thread->mbq_prev = mbx->tq_tail;
				mbx->tq_tail->mbq_next = thread;
				mbx->tq_tail = thread;
				mbx->tq_count++;
			}
		UnlockSYS();
		//---------------------------
		// Is a timeout specified ?
		if (timelimit) {
            LockSYS();
        	    AddToTimeoutList(thread, timelimit);
       	    UnlockSYS();
        }
		asm { int #2 }     // reschedule
		// Control will return here as a result of a SendMsg or a
		// timeout expiring
		msg = GetRunningTCB()->MsgPtr;
		if (msg == null)
			return E_NoMsg;
		GetRunningTCB()->MsgPtr = null;
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

	if (hMbx >= NR_MBX)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
	// check for a mailbox owner which indicates the mailbox
	// is active.
	if (mbx->owner == null) {
        UnlockSYS();
		return E_NotAlloc;
    }
	if (qrmv == true)
		msg = DequeueMsg(mbx);
	else
		msg = mbx->mq_head;
	UnlockSYS();
	if (msg == null)
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


