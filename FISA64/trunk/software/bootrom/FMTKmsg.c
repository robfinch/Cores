#include "types.h"
#include "const.h"

int chkMBX(int hMBX) {
    asm {
        lw    r1,24[bp]
        chk   r1,r1,b49
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
static int QueueMsg(MBX *mbx, MSG *msg)
{
    MSG *tmpmsg;
	int rr = E_Ok;

    if (msg == null)
        return E_Ok;

	critical (mbx->sf) {
		mbx->mq_count++;
	
		// handle potential queue overflows
	    select mbx->mq_strategy {
	    
	    	// unlimited queing (do nothing)
			case MQS_UNLIMITED:
				;
				
			// buffer newest
			// if the queue is full then old messages are lost
			// loop incase message queing strategy was changed
		    case MQS_NEWEST:
		        while mbx->mq_count > mbx->mq_size do {
		            // return outdated message to message pool
		            tmpmsg = mbx->mq_head->link
		            critical sfFreeMsg {
			            mbx->mq_head->link = FreeMsg
			            FreeMsg = mbx->mq_head
						nMsgBlk++
					}
					mbx->mq_count--
		            mbx->mq_head = tmpmsg
					if mbx->mq_missed < MAX_UINT then
						mbx->mq_missed++
					rr = E_QueFull
				}
		           
			// buffer oldest
			// if the queue is full then new messages are lost
			// loop incase message queing strategy was changed
			case MQS_OLDEST:
				// first return the passed message to free pool
				if mbx->mq_count > mbx->mq_size then {
					// return new message to pool
					critical sfFreeMsg {
						msg->link = FreeMsg
						FreeMsg = msg
						nMsgBlk++
					}
					if mbx->mq_missed < MAX_UINT then
						mbx->mq_missed++
					rr = E_QueFull
					mbx->mq_count--
				}
				// next if still over the message limit (which
				// might happen if que strategy was changed), return
				// messages to free pool
				while mbx->mq_count > mbx->mq_size do {
					// locate the second last message on the que
					tmpmsg = mbx->mq_head
					while tmpmsg <> mbx->mq_tail do {
						msg = tmpmsg
						tmpmsg = tmpmsg->link
					}
					mbx->mq_tail = msg
					critical sfFreeMsg {
						tmpmsg->link = FreeMsg
						FreeMsg = tmpmsg
						nMsgBlk++
					}
					if mbx->mq_missed < MAX_UINT then
						mbx->mq_missed++
					mbx->mq_count--
					rr = E_QueFull
				}
				if rr == E_QueFull then
					return rr
			}
		}
		// if there is a message in the queue
		if mbx->mq_tail then
			mbx->mq_tail->link = msg
		else
			mbx->mq_head = msg
		mbx->mq_tail = msg
		msg->link = null
	}
	return rr
}


/* ---------------------------------------------------------------
	Description:
		Dequeues a message from a mailbox.

	Assumptions:
		Mailbox parameter is valid.

	Called from:
		FreeMbx - (locks mailbox)
		WaitMsg	-	"
		CheckMsg-	"
--------------------------------------------------------------- */

private MSG *DequeueMsg(MBX *mbx)
{
	MSG *tmpmsg = null

	if mbx->mq_count then {
		mbx->mq_count--
		tmpmsg = mbx->mq_head
		if tmpmsg then {	// should not be null
			mbx->mq_head = tmpmsg->link
			if mbx->mq_head == null then
				mbx->mq_tail = null
			tmpmsg->link = tmpmsg
		}
	}
	return tmpmsg
}


/* ---------------------------------------------------------------
	Description:
		Allocate a mailbox. The default queue strategy is to
	queue the eight most recent messages.
--------------------------------------------------------------- */
public oscall int _AllocMbx(uint *hMbx)
{
	MBX *mbx

	if hMbx == null then
		return E_Arg
	critical sfFreeMbx {
		if FreeMBX == null then
			return E_NoMoreMbx
		mbx = FreeMBX
		FreeMBX = mbx->link
		nMailbox--
	}
	*hMbx = mbx - mailbox
	mbx->owner = Running->jcb
	mbx->tq_head = null
	mbx->tq_tail = null
	mbx->mq_head = null
	mbx->mq_tail = null
	mbx->tq_count = 0
	mbx->mq_count = 0
	mbx->mq_missed = 0
	mbx->mq_size = 8
	mbx->mq_strategy = MQS_NEWEST
	mbx->sf = true
	return E_Ok
}


/* ---------------------------------------------------------------
	Description:
		Free up a mailbox. When the mailbox is freed any queued
	messages must be freed. Any queued threads must also be
	dequeued. Since threads are being made ready a call to
	SwitchThread() is performed at the end of this routine.
--------------------------------------------------------------- */
public oscall int _FreeMbx(uint hMbx) 
{
	MBX *mbx
	MSG *msg
	TCB *thread
	
	if hMbx >= MaxMailbox then
		return E_BadMbx
	mbx = &mailbox[hMbx]
	critical mbx->sf {
		if mbx->owner <> Running->jcb and
			Running->jcb <> &MonJCB then
				return E_NotOwner
		// Free up any queued messages
		while msg = DequeueMsg(mbx) do {
			critical sfFreeMsg {
				msg->link = FreeMsg
				FreeMsg = msg
				nMsgBlk++
			}
		}
		// Send an indicator to any queued threads that the mailbox
		// is now defunct Setting MsgPtr = null will cause any
		// outstanding WaitMsg() to return E_NoMsg.
		forever do {
			DequeThreadFromMbx(mbx, &thread);
			if thread == null then
				break
			thread->MsgPtr = null
			if thread->status & TS_TIMEOUT then
				RmvFromTimeoutList(thread)
			AddToReadyQue(thread)
		}
		critical sfFreeMbx {
			mbx->link = FreeMBX
			FreeMBX = mbx
			nMailbox++
		}
	}
	SwitchThread()
	return E_Ok
}


/* ---------------------------------------------------------------
	Description:
		Set the mailbox message queueing strategy.
--------------------------------------------------------------- */
public oscall int _SetMbxMsgQueStrategy(
	uint hMbx, qStrategy, qSize)
{
	MBX *mbx

	if hMbx >= MaxMailbox then
		return E_BadMbx
	if qStrategy > 2 then
		return E_Arg
	mbx = &mailbox[hMbx]
	critical mbx->sf {
		if mbx->owner <> Running->jcb and
			Running->jcb <> &MonJCB then
				return E_NotOwner
		mbx->mq_strategy = qStrategy
		mbx->mq_size = qSize
	}
	return E_Ok
}


/* ---------------------------------------------------------------
	Description:
		Send a message. This will cause the thread to switch if
	another thread of equal or higher priority is made ready.
--------------------------------------------------------------- */
public int SendMsg(int hMbx, int d1, int d2)
{
	MBX *mbx;
	MSG *msg;
	TCB *thread;

	if (hMbx >= MaxMailbox)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	critical mbx->sf {
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if mbx->owner == null then return E_NotAlloc
		critical sfFreeMsg {
			msg = FreeMsg
			if msg == null then
				return E_NoMoreMsgBlks
			FreeMsg = msg->link
			--nMsgBlk
		}
		msg->msgtype = MBT_DATA
		msg->d1 = d1
		msg->d2 = d2
		DequeThreadFromMbx(mbx, &thread)
	}
	if thread == null then
		return QueueMsg(mbx, msg)
	thread->MsgPtr = msg
	if thread->status & TS_TIMEOUT then
		RmvFromTimeoutList(thread)
	AddToReadyQue(thread)
	// Don't allow a thread switch to occur for the top three
	// priorities. These threads must be allowed to continue
	// until they intentionally surrender execution by calling
	// WaitMsg() or Sleep().
	if Running->priority & 31 > 2 then
		SwitchThread()
	return E_Ok
}


/* ---------------------------------------------------------------
	Description:
		PostMsg() is meant to be called in order to send a
	message without causing the thread to switch. This is
	useful in some cases. For example interrupts that don't
	require a low latency. Normally SendMsg() will be called,
	even from an ISR to allow the OS to prioritize events.
--------------------------------------------------------------- */
public int PostMsg(int hMbx, int d1, int d2)
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
		msg = FreeMsg;
		if (msg == null) {
            UnlockSYS();
			return E_NoMoreMsgBlks;
        }
		FreeMsg = msg->link;
		--nMsgBlk;
		msg->msgtype = MBT_DATA;
		msg->d1 = d1;
		msg->d2 = d2;
		DequeueThreadFromMbx(mbx, &thread);
	UnlockSYS();
	if (thread == null) {
        LockSYS();
            ret = QueueMsg(mbx, msg);
        UnlockSYS();
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
		Wait for message. If timelinit is zero then the thread
	will wait indefinately for a message.
--------------------------------------------------------------- */

public int WaitMsg(int hMbx, int *d1, int *d2, int timelimit)
{
	MBX *mbx;
	MSG *msg;
	TCB *thread;

	if (chkMBX(hMbx)==0)
		return E_BadMbx;

	mbx = &mailbox[hMbx];
	LockSYS();
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner == 0) {
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
		thread->WaitMbx = mbx;
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
		msg = Running->MsgPtr;
		if (msg == null)
			return E_NoMsg;
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
		msg->link = FreeMsg;
		FreeMsg = msg;
		nMsgBlk++;
	UnlockSYS();
	return E_Ok;
}


/* ---------------------------------------------------------------
	Description:
		Check for message at mailbox. If no message is
	available return immediately to the caller (CheckMsg() is
	non blocking). Optionally removes the message from the
	mailbox.
--------------------------------------------------------------- */

int CheckMsg(int hMbx, int *d1, int *d2, int qrmv)
{
	MBX *mbx;
	MSG *msg;

	if (chkMBX(hMbx)==0)
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
		msg->link = FreeMsg;
		FreeMsg = msg;
		nMsgBlk++;
		UnlockSYS();
	}
	return E_Ok;
}


