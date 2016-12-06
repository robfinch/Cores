#include "types.h"
#include "const.h"
#include "config.h"
#include "proto.h"
#include "glo.h"

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
			case MQS_UNLIMITED:
				break;
				
			// buffer newest
			// if the queue is full then old messages are lost
			// Older messages are at the head of the queue.
			// loop incase message queing strategy was changed
		    case MQS_NEWEST:
		        while (mbx->mq_count > mbx->mq_size) {
		            // return outdated message to message pool
		            htmp = message[mbx->mq_head].link;
		            tmpmsg = &message[htmp];
		            message[mbx->mq_head].link = freeMSG;
		            freeMSG = mbx->mq_head;
					nMsgBlk++;
					mbx->mq_count--;
		            mbx->mq_head = htmp;
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
					freeMSG = msg-message;
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
					tmpmsg = &message[mbx->mq_head];
					while (tmpmsg-message <> mbx->mq_tail) {
						msg = tmpmsg;
						tmpmsg = &message[tmpmsg->link];
					}
					mbx->mq_tail = msg-message;
					tmpmsg->link = freeMSG;
					freeMSG = tmpmsg-message;
					nMsgBlk++;
					if (mbx->mq_missed < MAX_UINT)
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
	MSG *tmpmsg = null;
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
		Dequeues a thread from a mailbox. The thread will also
	be removed from the timeout list (if it's present there),
	and	the timeout list will be adjusted accordingly.

	Assumptions:
		Mailbox parameter is valid.
--------------------------------------------------------------- */

private int DequeThreadFromMbx(MBX *mbx, TCB **thrd)
{
	if (thrd == null || mbx == null)
		return E_Arg;

	if (LockSemaphore(&sys_sema,-1)) {
		if (mbx->tq_head == -1) {
      		UnlockSemaphore(&sys_sema);
			*thrd = null;
			return E_NoThread;
		}
	
		mbx->tq_count--;
		*thrd = &tcbs[mbx->tq_head];
		mbx->tq_head = tcbs[mbx->tq_head].mbq_next;
		if (mbx->tq_head > 0)
			tcbs[mbx->tq_head].mbq_prev = -1;
		else
			mbx->tq_tail = -1;
		UnlockSemaphore(&sys_sema);
	}

	// if thread is also on the timeout list then
	// remove from timeout list
	// adjust succeeding thread timeout if present
	if ((*thrd)->status & TS_TIMEOUT)
		RemoveFromTimeoutList(*thrd);

	(*thrd)->mbq_prev = (*thrd)->mbq_next = -1;
	(*thrd)->hWaitMbx = -1;	// no longer waiting at mailbox
	(*thrd)->status &= ~TS_WAITMSG;
	return E_Ok;

}


/* ---------------------------------------------------------------
	Description:
		Allocate a mailbox. The default queue strategy is to
	queue the eight most recent messages.
--------------------------------------------------------------- */
public int FMTK_AllocMbx(hMBX *phMbx)
{
	MBX *mbx;

    check_privilege();
	if (phMbx==null)
    	return E_Arg;
	if (LockSemaphore(&sys_sema,-1)) {
		if (freeMBX < 0 || freeMBX >= NR_MBX) {
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
	mbx->mq_strategy = MQS_NEWEST;
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
	
    check_privilege();
	__check (hMbx >= 0 && hMbx < NR_MBX);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		if ((mbx->owner <> GetJCBPtr()) and (GetJCBPtr() <> &jcbs)) {
    	    UnlockSemaphore(&sys_sema);
			return E_NotOwner;
        }
		// Free up any queued messages
		while (msg = DequeueMsg(mbx)) {
            msg->type = MT_FREE;
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
			if (thrd == null)
				break;
			thrd->msg.type = MT_NONE;
			if (thrd->status & TS_TIMEOUT)
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

    check_privilege();
	__check (hMbx >= 0 && hMbx < NR_MBX);
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

    check_privilege();
	__check (hMbx >= 0 && hMbx < NR_MBX);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner < 0 || mbx->owner >= NR_JCB) {
    	    UnlockSemaphore(&sys_sema);
            return E_NotAlloc;
        }
		if (freeMSG < 0 || freeMSG >= NR_MSG) {
    	    UnlockSemaphore(&sys_sema);
			return E_NoMoreMsgBlks;
        }
		msg = &message[freeMSG];
		freeMSG = msg->link;
		--nMsgBlk;
		msg->retadr = GetJCBPtr()-jcbs;
		msg->tgtadr = hMbx;
		msg->type = MBT_DATA;
		msg->d1 = d1;
		msg->d2 = d2;
		msg->d3 = d3;
		DequeThreadFromMbx(mbx, &thrd);
	    UnlockSemaphore(&sys_sema);
    }
	if (thrd == null)
		return QueueMsg(mbx, msg);
	if (LockSemaphore(&sys_sema,-1)) {
        thrd->msg.retadr = msg->retadr;
        thrd->msg.tgtadr = msg->tgtadr;
        thrd->msg.type = msg->type;
        thrd->msg.d1 = msg->d1;
        thrd->msg.d2 = msg->d2;
        thrd->msg.d3 = msg->d3;
        // free message here
        msg->type = MT_FREE;
        msg->retadr = -1;
        msg->tgtadr = -1;
        msg->link = freeMSG;
        freeMSG = msg-message;
    	if (thrd->status & TS_TIMEOUT)
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

    check_privilege();
	__check (hMbx >= 0 && hMbx < NR_MBX);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
		// check for a mailbox owner which indicates the mailbox
		// is active.
		if (mbx->owner < 0 || mbx->owner >= NR_JCB) {
    	    UnlockSemaphore(&sys_sema);
			return E_NotAlloc;
        }
		if (freeMSG  <0 || freeMSG >= NR_MSG) {
    	    UnlockSemaphore(&sys_sema);
			return E_NoMoreMsgBlks;
        }
		msg = &message[freeMSG];
		freeMSG = msg->link;
		--nMsgBlk;
		msg->retadr = GetJCBPtr()-jcbs;
		msg->tgtadr = hMbx;
		msg->type = MBT_DATA;
		msg->d1 = d1;
		msg->d2 = d2;
		msg->d3 = d3;
		DequeThreadFromMbx(mbx, &thrd);
	    UnlockSemaphore(&sys_sema);
    }
	if (thrd == null) {
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
        msg->type = MT_FREE;
        msg->retadr = -1;
        msg->tgtadr = -1;
        msg->link = freeMSG;
        freeMSG = msg-message;
    	if (thrd->status & TS_TIMEOUT)
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

    check_privilege();
	__check (hMbx >= 0 && hMbx < NR_MBX);
	mbx = &mailbox[hMbx];
	if (LockSemaphore(&sys_sema,-1)) {
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner <0 || mbx->owner >= NR_JCB) {
     	    UnlockSemaphore(&sys_sema);
        	return E_NotAlloc;
        }
    	msg = DequeueMsg(mbx);
	    UnlockSemaphore(&sys_sema);
    }
	if (msg == null) {
    	if (LockSemaphore(&sys_sema,-1)) {
			thrd = GetRunningTCBPtr();
			RemoveFromReadyList(thrd-tcbs);
    	    UnlockSemaphore(&sys_sema);
        }
		//-----------------------
		// Queue task at mailbox
		//-----------------------
		thrd->status |= TS_WAITMSG;
		thrd->hWaitMbx = hMbx;
		thrd->mbq_next = -1;
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
            asm { ; Waitmsg here; }
        	if (LockSemaphore(&sys_sema,-1)) {
        	    InsertIntoTimeoutList(thrd-tcbs, timelimit);
        	    UnlockSemaphore(&sys_sema);
            }
        }
		asm { int #2 }     // reschedule
		// Control will return here as a result of a SendMsg or a
		// timeout expiring
		rt = GetRunningTCBPtr(); 
		if (rt->msg.type == MT_NONE)
			return E_NoMsg;
		// rip up the envelope
		rt->msg.type = MT_NONE;
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
        msg->type = MT_FREE;
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

    check_privilege();
	__check (hMbx >= 0 && hMbx < NR_MBX);
	mbx = &mailbox[hMbx];
   	if (LockSemaphore(&sys_sema,-1)) {
    	// check for a mailbox owner which indicates the mailbox
    	// is active.
    	if (mbx->owner == null) {
    	    UnlockSemaphore(&sys_sema);
    		return E_NotAlloc;
        }
    	if (qrmv == true)
    		msg = DequeueMsg(mbx);
    	else
    		msg = mbx->mq_head;
	    UnlockSemaphore(&sys_sema);
    }
	if (msg == null)
		return E_NoMsg;
	if (d1)
		*d1 = msg->d1;
	if (d2)
		*d2 = msg->d2;
	if (d3)
		*d3 = msg->d3;
	if (qrmv == true) {
       	if (LockSemaphore(&sys_sema,-1)) {
            msg->type = MT_FREE;
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


