






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


int irq_stack[512];

int FMTK_Inited;
TCB tempTCB;
JCB jcbs[51];
TCB tcbs[256];
unsigned int readyQ[8];
TCB *freeTCB;
int sysstack[1024];
int stacks[256][1024];
int sys_stacks[256][512];
int bios_stacks[256][512];
int fmtk_irq_stack[512];
int fmtk_sys_stack[512];
MBX mailbox[2048];
MSG message[32768];
int nMsgBlk;
int nMailbox;
MSG *freeMSG;
MBX *freeMBX;
JCB *IOFocusNdx;
int IOFocusTbl[4];
int iof_switch;
int BIOS1_sema;
int iof_sema;
int sys_sema;
int BIOS_RespMbx;
char hasUltraHighPriorityTasks;
int missed_ticks;

short int video_bufs[51][4096];
TCB *TimeoutList;

void SetBound48(TCB *ps, TCB *pe, int algn)
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

void SetBound49(JCB *ps, JCB *pe, int algn)
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

void SetBound50(MBX *ps, MBX *pe, int algn)
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

void SetBound51(MSG *ps, MSG *pe, int algn)
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

naked int GetVecno()
{
    asm {
        mfspr  r1,12
        rtl
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
	if (p->priority > 077 || p->priority < 000)
		return E_BadPriority;
	if (p->priority < 003)
	   hasUltraHighPriorityTasks |= (1 << p->priority);
	p->status = 16;
	q = readyQ[p->priority>>3];
	// Ready list empty ?
	if (q==0) {
		p->next = p;
		p->prev = p;
		readyQ[p->priority>>3] = p;
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
	if (t->priority > 077 || t->priority < 000)
		return E_BadPriority;
    if (t==readyQ[t->priority>>3])
       readyQ[t->priority>>3] = t->next;
    if (t==readyQ[t->priority>>3])
       readyQ[t->priority>>3] = (void *)0;
    t->next->prev = t->prev;
    t->prev->next = t->next;
    t->next = (void *)0;
    t->prev = (void *)0;
    t->status = 0;
    return E_Ok;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private int InsertIntoTimeoutList(TCB *t, int to)
{
    TCB *p, *q;

    if (TimeoutList==(void *)0) {
        t->timeout = to;
        TimeoutList = t;
        t->next = (void *)0;
        t->prev = (void *)0;
        return E_Ok;
    }
    q = (void *)0;
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
    t->status |= 1;
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
    t->status = 0;
    t->next = (void *)0;
    t->prev = (void *)0;
}

// ----------------------------------------------------------------------------
// Pop the top entry from the timeout list.
// ----------------------------------------------------------------------------

private TCB *PopTimeoutList()
{
    TCB *p;
    
    p = TimeoutList;
    if (TimeoutList) {
        TimeoutList = TimeoutList->next;
        if (TimeoutList)
            TimeoutList->prev = (void *)0;
    }
    return p;
}

// ----------------------------------------------------------------------------
// Select a task to run.
// ----------------------------------------------------------------------------

private __int8 startQ[32] = { 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 1, 0, 4, 0, 0, 0, 5, 0, 0, 0, 6, 0, 1, 0, 7, 0, 0, 0, 0 };
private __int8 startQNdx;

private TCB *SelectTaskToRun()
{
	int nn,kk;
	TCB *p, *q;
	int qToCheck;

	startQNdx++;
	startQNdx &= 31;
	qToCheck = startQ[startQNdx];
	for (nn = 0; nn < 8; nn++) {
		p = readyQ[qToCheck];
		if (p) {
            kk = 0;
     		q = p->next;
            do {  
                if (!(q->status & 8)) {
                    if (q->affinity == getCPU()) {
        			   readyQ[qToCheck] = q;
        			   return q;
                    }
                }
                q = q->next;
                kk = kk + 1;
            } while (q != p && kk < 256);
        }
		qToCheck++;
		qToCheck &= 7;
	}
	return GetRunningTCB();
	panic("No entries in ready queue.");
}

// ----------------------------------------------------------------------------
// There isn't any 'C' code in the SystemCall() function. If there were it
// would have to be arranged like the TimerIRQ() or RescheduleIRQ() functions.
// ----------------------------------------------------------------------------

naked FMTK_SystemCall()
{
    asm {
         lea   sp,sys_stacks_[tr]
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

    	 mfspr r6,epc           ; get return address into r6
    	 and   r7,r6,#-4        ; clear LSB's
    	 lh	   r7,4[r7]			; get static call number parameter into r7
    	 addui r6,r6,#8		    ; update return address
    	 sw    r6,296[tr]
    	 cmpu  r6,r7,#20
    	 bgt   r6,.bad_callno
    	 asl   r7,r7,#1
    	 lcu   r6,syscall_vectors[r7]       ; load the vector into r6
    	 or    r6,r6,#FMTK_SystemCall_ & 0xFFFFFFFFFFFF0000
    	 jsr   [r6]				; do the system function
    	 sw    r1,8[tr]
.0001:
         lw    r1,256[tr]
         mtspr isp,r1
         lw    r1,264[tr]
         mtspr dsp,r1
         lw    r1,272[tr]
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
         lw    r31,248[tr]
         rte
.bad_callno:
         ldi   r1,#E_BadFuncno
         sw    r1,8[tr]
         bra   .0001   
syscall_vectors:
        dc    FMTKInitialize_
        dc    FMTK_StartTask_
        dc    FMTK_ExitTask_
        dc    FMTK_KillTask_
        dc    FMTK_SetTaskPriority_
        dc    FMTK_Sleep_
        dc    FMTK_AllocMbx_
        dc    FMTK_FreeMbx_
        dc    FMTK_PostMsg_
        dc    FMTK_SendMsg_
        dc    FMTK_WaitMsg_
        dc    FMTK_CheckMsg_
        align  4
    }
}

// ----------------------------------------------------------------------------
// If timer interrupts are enabled during a priority #0 task, this routine
// only updates the missed ticks and remains in the same task. No timeouts
// are updated and no task switches will occur. The timer tick routine
// basically has a fixed latency when priority #0 is present.
// ----------------------------------------------------------------------------

void FMTK_SchedulerIRQ()
{
     prolog asm {
         lea   sp,fmtk_irq_stack_+4088
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
     switch(GetVecno()) {
     // Timer tick interrupt
     case 451:
          asm {
             ldi   r1,#3				; reset the edge sense circuit
             sh	   r1,PIC_RSTE
         }
         DisplayIRQLive();
         spinlock(&sys_sema,10) {
             if (GetRunningTCB()->priority != 000) {
                 GetRunningTCB()->status = 4;
                 while (TimeoutList) {
                     if (TimeoutList->timeout<=0)
                         InsertIntoReadyList(PopTimeoutList());
                     else {
                          TimeoutList->timeout = TimeoutList->timeout - missed_ticks - 1;
                          missed_ticks = 0;
                          break;
                     }
                 }
                 if (GetRunningTCB()->priority > 002)
                    SetRunningTCB(SelectTaskToRun());
                 GetRunningTCB()->status = 8;
             }
             else
                 missed_ticks++;
         }
         lockfail {
             missed_ticks++;
         }
         break;
     // Explicit rescheduling request.
     case 2:
         GetRunningTCB()->status = 4;
         SetRunningTCB(SelectTaskToRun());
         GetRunningTCB()->status = 8;
         break;
     default:  ;
     }
     // Restore the processor registers and return using an RTI.
     epilog asm {
RestoreContext:
         lw    r1,256[tr]
         mtspr isp,r1
         lw    r1,264[tr]
         mtspr dsp,r1
         lw    r1,272[tr]
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
         lw    r31,248[tr]
         rti
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
     int kk;
     
     printf("CPU Pri Stat   Task     Prev     Next   Timeout\r\n");
     for (n = 0; n < 8; n++) {
         q = readyQ[n];
         p = q;
         if (q) {
             kk = 0;
             do {
                 if (!chkTCB(p))
                     break;
                 printf("%3d %3d %02X %08X %08X %08X %08X\r\n", p->affinity, p->priority, p->status, p, p->prev, p->next, p->timeout);
                 p = p->next;
                 if (getcharNoWait()==3)
                    goto j1;
                 kk = kk + 1;
             } while (p != q && kk < 256);
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

int FMTK_ExitTask()
{
    TCB *t;
    MBX *m, *n;

    spinlock(&sys_sema) {
        RemoveFromReadyList(t);
        RemoveFromTimeoutList(t);
        t = GetRunningTCB();
        m = t->mailboxes;
        while (m) {
            n = m->link;
            FMTK_FreeMbx(m);
            m = n;
        }
    }
    asm { int #2 }     // reschedule
j1: goto j1;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_StartTask(int priority, int affinity, int adr, int parm, int job)
{
    TCB *t;

    spinlock(&sys_sema) {
        t = freeTCB;
        freeTCB = t->next;
    }
    t->affinity = affinity;
    t->priority = priority;
    t->ipc = adr;
    t->isp = t->stack + 1023;
    t->hJob = job;
    t->regs[1] = parm;
    t->regs[31] = FMTK_ExitTask;
    spinlock(&sys_sema) {
        InsertIntoReadyList(t); }
    return E_Ok;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_Sleep(int timeout)
{
    TCB *t;

    spinlock(&sys_sema) {
        t = GetRunningTCB();
        RemoveFromReadyList(t);
        InsertIntoTimeoutList(t, timeout);
    }
    asm { int #2 }      // reschedule
    return E_Ok;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_SetTaskPriority(TCB* t, int priority)
{
    if (priority > 077 || priority < 000)
       return E_Arg;
    spinlock(&sys_sema) {
        if (t->status & (8 | 16)) {
            RemoveFromReadyList(t);
            t->priority = priority;
            InsertIntoReadyList(t);
        }
        else
            t->priority = priority;
    }
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
        spinunlock(&sys_sema);
        spinunlock(&iof_sema);

        hasUltraHighPriorityTasks = 0;
        missed_ticks = 0;

        IOFocusTbl[0] = 0;
        IOFocusNdx = (void *)0;

        SetBound48(tcbs, &tcbs[256], 511);
        SetBound49(jcbs, &jcbs[51], 2047);
        SetBound50(mailbox, &mailbox[2048],127);
        SetBound51(message, &message[32768],31);

        for (nn = 0; nn < 32768; nn++) {
            message[nn].link = &message[nn+1];
        }
        message[32768-1].link = (void *)0;
        freeMSG = &message[0];

        asm {
            ldi   r1,#30
            sc    r1,LEDS
        }

        for (nn = 0; nn < 51; nn++) {
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

        asm {
            ldi   r1,#40
            sc    r1,LEDS
        }

    	for (nn = 0; nn < 8; nn++)
    		readyQ[nn] = 0;
    	for (nn = 0; nn < 256; nn++) {
            tcbs[nn].number = nn;
    		tcbs[nn].next = &tcbs[nn+1];
    		tcbs[nn].prev = 0;
    		tcbs[nn].status = 0;
    		tcbs[nn].priority = 070;
    		tcbs[nn].affinity = 0;
    		tcbs[nn].sys_stack = &sys_stacks[nn] + 511;
    		tcbs[nn].bios_stack = &bios_stacks[nn] + 511;
    		tcbs[nn].stack = &stacks[nn] + 1023;
    		tcbs[nn].hJob = &jcbs[0];
    		tcbs[nn].timeout = 0;
    		tcbs[nn].mailboxes = 0;
    		if (nn<2) {
                tcbs[nn].affinity = nn;
                tcbs[nn].priority = 030;
            }
    	}
    	tcbs[256-1].next = (TCB *)0;
    	freeTCB = &tcbs[2];
        asm {
            ldi   r1,#42
            sc    r1,LEDS
        }
    	InsertIntoReadyList(&tcbs[0]);
    	InsertIntoReadyList(&tcbs[1]);
    	tcbs[0].status = 8;
    	tcbs[1].status = 8;
        asm {
            ldi   r1,#44
            sc    r1,LEDS
        }
    	SetRunningTCB(&tcbs[0]);
    	TimeoutList = (TCB *)0;
    	set_vector(4,FMTK_SystemCall);
    	set_vector(2,FMTK_SchedulerIRQ);
    	set_vector(451,FMTK_SchedulerIRQ);
        FMTK_StartTask(070, 0, IdleTask, 0, jcbs);
        FMTK_StartTask(070, 1, IdleTask, 0, jcbs);
    	FMTK_Inited = 0x12345678;
        asm {
            ldi   r1,#50
            sc    r1,LEDS
        }
    }
}

