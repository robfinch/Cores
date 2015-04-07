#include "config.h"
#include "const.h"
#include "types.h"

int irq_stack[512];

int FMTK_Inited;
TCB tempTCB;
JCB jcbs[NR_JCB];
TCB tcbs[NR_TCB];
TCB *readyQ[8];
TCB *runningTCB;
TCB *freeTCB;
int sysstack[1024];
int stacks[NR_TCB][512];
int sys_stacks[NR_TCB][512];
int bios_stacks[NR_TCB][512];
int fmtk_irq_stack[512];
MBX mailbox[NR_MBX];
MSG message[NR_MSG];

JCB *IOFocusNdx;
int IOFocusTbl[4];
int iof_switch;
int BIOS1_sema;
int iof_sema;
int sys_sema;
int BIOS_RespMbx;

short int video_bufs[NR_JCB][4096];
TCB *TimeoutList;

naked int getCPU()
{
     asm {
         cpuid r1,r0,#0
         rtl
     };
     
}

void SetBound48(TCB *ps, TCB *pe)
{
     asm {
     lw      r1,24[bp]
     mtspr   112,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   176,r1      ; set upper bound
     mtspr   240,r0      ; modulo mask not used
     }
}

void SetBound49(JCB *ps, JCB *pe)
{
     asm {
     lw      r1,24[bp]
     mtspr   113,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   177,r1      ; set upper bound
     mtspr   241,r0      ; modulo mask not used
     }
}

void SetBound50(MBX *ps, MBX *pe)
{
     asm {
     lw      r1,24[bp]
     mtspr   114,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   178,r1      ; set upper bound
     mtspr   242,r0      ; modulo mask not used
     }
}

void SetBound51(MSG *ps, MSG *pe)
{
     asm {
     lw      r1,24[bp]
     mtspr   115,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   179,r1      ; set upper bound
     mtspr   243,r0      ; modulo mask not used
     }
}

int chkTCB(TCB *p)
{
    asm {
        lw    r1,24[bp]
        chk   r1,r1,b48
    }
}

naked TCB *GetRunningTCB()
{
    asm {
        mov r1,tr
        rtl
    }
}

void SetRunningTCB(TCB *p)
{
     asm {
         lw  tr,24[bp]
     }
}

naked void DisplayIRQLive()
{
     asm {
         inc  $FFD00000+220,#1
         rtl
     }
}

JCB *GetJCBPtr()
{
    return GetRunningTCB()->hJob;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private int InsertIntoReadyList(TCB *p)
{
    TCB *q;

    if (!chkTCB(p))
        return E_BadTCBHandle;
	if (p->priority > 7 || p->priority < 0)
		return E_BadPriority;
	p->status = TS_READY;
	q = readyQ[p->priority];
	// Ready list empty ?
	if (q==0) {
		p->next = p;
		p->prev = p;
		readyQ[p->priority] = p;
		return E_Ok;
	}
	// Insert at tail of list
	p->next = q;
	p->prev = q->prev;
	q->prev->next = p;
	q->prev = p;
	return E_Ok;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private int RemoveFromReadyList(TCB *t)
{
    if (!chkTCB(t))
        return E_BadTCBHandle;
	if (t->priority > 7 || t->priority < 0)
		return E_BadPriority;
    if (t==readyQ[t->priority])
       readyQ[t->priority] = t->next;
    if (t==readyQ[t->priority])
       readyQ[t->prioriiy] = null;
    t->next->prev = t->prev;
    t->prev->next = t->next;
    t->next = null;
    t->prev = null;
    t->status = TS_NONE;
    return E_Ok;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private int InsertIntoTimeoutList(TCB *t, int to)
{
    TCB *p, *q;

    if (TimeoutList==null) {
        t->timeout = to;
        TimeoutList = t;
        t->next = null;
        t->prev = null;
        return E_Ok;
    }
    q = null;
    p = TimeoutList;
    while (to > p->timeout) {
        to -= p->timeout;
        q = p;
        p = p->next;
    }
    t->next = p;
    t->prev = q;
    if (p) {
        p->timeout -= to;
        p->prev = t;
    }
    if (q)
        q->next = t;
    else
        TimeoutList = t;
    t->status |= TS_TIMEOUT;
    return E_Ok;
};

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private int RemoveFromTimeoutList(TCB *t)
{
    if (t->next) {
       t->next->prev = t->prev;
       t->next->timeout += t->timeout;
    }
    if (t->prev)
       t->prev->next = t->next;
    t->status = TS_NONE;
    t->next = null;
    t->prev = null;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private TCB *PopTimeoutList()
{
    TCB *p;
    
    p = TimeoutList;
    if (TimeoutList)
        TimeoutList = TimeoutList->next;
    return p;
}

// ----------------------------------------------------------------------------
// Select a task to run.
// ----------------------------------------------------------------------------

private __int8 startQ[32] = { 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 1, 0, 4, 0, 0, 0, 5, 0, 0, 0, 6, 0, 1, 0, 7, 0, 0, 0, 0 };
private __int8 startQNdx;

private TCB *SelectTaskToRun()
{
	int nn;
	TCB *p, *q;
	int qToCheck;

	startQNdx++;
	startQNdx &= 31;
	qToCheck = startQ[startQNdx];
	for (nn = 0; nn < 8; nn++) {
		p = readyQ[qToCheck];
		if (p) {
     		q = p->next;
            do {  
                if (!(q->status & TS_RUNNING)) {
                    if (q->affinity == getCPU()) {
        			   readyQ[qToCheck] = q;
        			   return q;
                    }
                }
                q = q->next;
            } while (q != p);
        }
		qToCheck++;
		qToCheck &= 7;
	}
	return GetRunningTCB();
	panic("No entries in ready queue.");
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

naked TimerIRQ()
{
     asm {
         lea   sp,fmtk_irq_stack+4088
         sw    r1,8[tr]
         sw    r2,16[tr]
         sw    r3,24[tr]
         sw    r4,32[tr]
         sw    r5,40[tr]
         sw    r6,48[tr]
         sw    r7,56[tr]
         sw    r8,64[tr]
         sw    r9,72[tr]
         sw    r10,80[tr]
         sw    r11,88[tr]
         sw    r12,96[tr]
         sw    r13,104[tr]
         sw    r14,112[tr]
         sw    r15,120[tr]
         sw    r16,128[tr]
         sw    r17,136[tr]
         sw    r18,144[tr]
         sw    r19,152[tr]
         sw    r20,160[tr]
         sw    r21,168[tr]
         sw    r22,176[tr]
         sw    r23,184[tr]
         sw    r24,192[tr]
         sw    r25,200[tr]
         sw    r26,208[tr]
         sw    r27,216[tr]
         sw    r28,224[tr]
         sw    r29,232[tr]
         sw    r30,240[tr]
         sw    r31,248[tr]
         mfspr r1,isp
         sw    r1,256[tr]
         mfspr r1,dsp
         sw    r1,264[tr]
         mfspr r1,esp
         sw    r1,272[tr]
         mfspr r1,ipc
         sw    r1,280[tr]
         mfspr r1,dpc
         sw    r1,288[tr]
         mfspr r1,epc
         sw    r1,296[tr]
         mfspr r1,cr0
         sw    r1,304[tr]
     }
     DisplayIRQLive();
     GetRunningTCB()->status = TS_PREEMPT;
     while (TimeoutList) {
         if (TimeoutList->timeout==0)
             InsertIntoReadyList(PopTimeoutList());
         else {
              TimeoutList->timeout--;
              break;
         }
     }
     SetRunningTCB(SelectTasktoRun());
     GetRunningTCB()->status = TS_RUNNING;
     asm {
RestoreContext:
         lw    r1,256[tr]
         mtspr isp,r1
         lw    r1,264[tr]
         mtspr dsp,r1
         sl    r1,272[tr]
         mtspr esp,r1
         lw    r1,280[tr]
         mtspr ipc,r1
         lw    r1,288[tr]
         mtspr dpc,r1
         lw    r1,296[tr]
         mtspr epc,r1
         lw    r1,304[tr]
         mtspr cr0,r1
         lw    r1,8[tr]
         lw    r2,16[tr]
         lw    r3,24[tr]
         lw    r4,32[tr]
         lw    r5,40[tr]
         lw    r6,48[tr]
         lw    r7,56[tr]
         lw    r8,64[tr]
         lw    r9,72[tr]
         lw    r10,80[tr]
         lw    r11,88[tr]
         lw    r12,96[tr]
         lw    r13,104[tr]
         lw    r14,112[tr]
         lw    r15,120[tr]
         lw    r16,128[tr]
         lw    r17,136[tr]
         lw    r18,144[tr]
         lw    r19,152[tr]
         lw    r20,160[tr]
         lw    r21,168[tr]
         lw    r22,176[tr]
         lw    r23,184[tr]
         lw    r25,200[tr]
         lw    r26,208[tr]
         lw    r27,216[tr]
         lw    r28,224[tr]
         lw    r29,232[tr]
         lw    r30,240[tr]
         lw    r31,248[tr]
         rti
     }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

naked RescheduleIRQ()
{
     asm {
         lea   sp,fmtk_irq_stack+4088
         sw    r1,8[tr]
         sw    r2,16[tr]
         sw    r3,24[tr]
         sw    r4,32[tr]
         sw    r5,40[tr]
         sw    r6,48[tr]
         sw    r7,56[tr]
         sw    r8,64[tr]
         sw    r9,72[tr]
         sw    r10,80[tr]
         sw    r11,88[tr]
         sw    r12,96[tr]
         sw    r13,104[tr]
         sw    r14,112[tr]
         sw    r15,120[tr]
         sw    r16,128[tr]
         sw    r17,136[tr]
         sw    r18,144[tr]
         sw    r19,152[tr]
         sw    r20,160[tr]
         sw    r21,168[tr]
         sw    r22,176[tr]
         sw    r23,184[tr]
         sw    r24,192[tr]
         sw    r25,200[tr]
         sw    r26,208[tr]
         sw    r27,216[tr]
         sw    r28,224[tr]
         sw    r29,232[tr]
         sw    r30,240[tr]
         sw    r31,248[tr]
         mfspr r1,isp
         sw    r1,256[tr]
         mfspr r1,dsp
         sw    r1,264[tr]
         mfspr r1,esp
         sw    r1,272[tr]
         mfspr r1,ipc
         sw    r1,280[tr]
         mfspr r1,dpc
         sw    r1,288[tr]
         mfspr r1,epc
         sw    r1,296[tr]
         mfspr r1,cr0
         sw    r1,304[tr]
     }
     GetRunningTCB()->status = TS_PREEMPT;
     SetRunningTCB(SelectTasktoRun());
     GetRunningTCB()->status = TS_RUNNING;
     asm {
         bra   RestoreContext
     }
}

void panic(char *msg)
{
     putstr(msg);
j1:  goto j1;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void DumpTaskList()
{
     TCB *p, *q;
     int n;
     
     printf("CPU Pri   Task     Prev     Next   Timeout\r\n");
     for (n = 0; n < 8; n++) {
         q = readyQ[n];
         p = q;
         if (q) {
             do {
                 printf("%3d %3d %08X %08X %08X %08X\r\n", p->affinity, p->priority, p, p->prev, p->next, p->timeout);
                 p = p->next;
                 if (getcharNoWait()==3)
                    goto j1;
             } while (p != q);
         }
     }
j1:  ;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void IdleTask()
{
     while(1) {
         asm {
             inc  $FFD00000+228
         }
     }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int ExitTask()
{
    TCB *t;
    MBX *m, *n;

    LockSYS();
        RemoveFromReadyList(t);
        RemoveFromTimeoutList(t);
        t = GetRunningTCB();
        m = t->mailboxes;
        while (m) {
            n = m->next;
            FreeMbx(m);
            m = n;
        }
    UnlockSYS();
    asm { int #2 }     // reschedule
j1: goto j1;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int StartTask(int priority, int affinity, int adr, int parm, int job)
{
    TCB *t;

    LockSYS();
        t = freeTCB;
        freeTCB = t->next;
    UnlockSYS();
        t->affinity = affinity;
        t->ipc = adr;
        t->isp = t->stack + 511;
        t->hJob = job;
        t->regs[1] = parm;
        t->regs[31] = ExitTask;
    LockSYS();
        InsertIntoReadyList(t);
    UnlockSYS();
    return E_Ok;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void FMTKInitialize()
{
	int nn;

    if (FMTK_Inited!=0x12345678) {
        asm {
            ldi   r1,#20
            sc    r1,LEDS
        }
        UnlockSYS();
        UnlockIOF();
        for (nn = 0; nn < NR_JCB; nn++) {
            jcbs[nn].number = nn;
            if (nn == 0 ) {
                jcbs[nn].pVidMem = 0xFFD00000;
                jcbs[nn].pVirtVidMem = video_bufs[nn];
                jcbs[nn].NormAttr = 0x0026B800;
                RequestIOFocus(&jcbs[0]);
            }
            else {
                 jcbs[nn].pVidMem = video_bufs[nn];
                 jcbs[nn].pVirtVidMem = video_bufs[nn];
                 jcbs[nn].NormAttr = 0x0026B800;
            }
            jcbs[nn].VideoRows = 31;
            jcbs[nn].VideoCols = 84;
            jcbs[nn].CursorRow = 0;
            jcbs[nn].CursorCol = 0;
        }

        SetBound48(tcbs, &tcbs[NR_TCB]);
        SetBound49(jcbs, &jcbs[NR_JCB]);
        SetBound50(mailbox, &mailbox[MR_MBX]);
        SetBound51(message, &message[NR_MSG]);

    	for (nn = 0; nn < 8; nn++)
    		readyQ[nn] = 0;
    	for (nn = 0; nn < NR_TCB; nn++) {
            tcbs[nn].number = nn;
    		tcbs[nn].next = &tcbs[nn+1];
    		tcbs[nn].prev = 0;
    		tcbs[nn].status = 0;
    		tcbs[nn].priority = 7;
    		tcbs[nn].affinity = 0;
    		tcbs[nn].sys_stack = &sys_stacks[nn] + 511;
    		tcbs[nn].bios_stack = &bios_stacks[nn] + 511;
    		tcbs[nn].stack = &stacks[nn] + 511;
    		tcbs[nn].hJob = &jcbs[0];
    		tcbs[nn].timeout = 0;
    		tcbs[nn].mailboxes = 0;
    		if (nn==0) {
                tcbs[nn].priority = 3;
            }
    	}
    	tcbs[NR_TCB-1].next = (TCB *)0;
    	freeTCB = &tcbs[1];
    	InsertIntoReadyList(&tcbs[0]);
    	SetRunningTCB(&tcbs[0]);
    	TimeoutList = (TCB *)0;
    	IOFocusNdx = &jcbs[0];
    	IOFocusTbl[0] = 1;
    	set_vector(2,RescheduleIRQ);
    	set_vector(451,TimerIRQ);
        StartTask(7, 0, IdleTask, 0, jcbs);
        StartTask(7, 1, IdleTask, 0, jcbs);
    	FMTK_Inited = 0x12345678;
        asm {
            ldi   r1,#50
            sc    r1,LEDS
        }
    }
}

