
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


extern JCB *IOFocusNdx;
extern int IOFocusTbl[4];

void ForceIOFocus(JCB *j)
{
    RequestIOFocus(j);   // In case it isn't requested yet.
    LockIOF();
        if (j != IOFocusNdx) {
            CopyScreenToVirtualScreen();
            j->pVidMem = j->pVirtVidMem;
            IOFocusNdx = j;
            j->pVidMem = 0xFFD00000;
            CopyVirtualScreenToScreen();
        }
    UnlockIOF();
}

// First check if it's even possible to switch the focus to another
// task. The I/O focus list could be empty or there may be only a
// single task in the list. In either case it's not possible to
// switch.
void SwitchIOFocus()
{
     JCB *j, *p;

     LockIOF();
         j = IOFocusNdx;
         if (j) {
             p = IOFocusNdx->iof_next;
             if (p <> IOFocusNdx) {
                 if (p) {
                     CopyScreenToVirtualScreen();
                     j->pVidMem = j->pVirtVidMem;
                     IOFocusNdx = p;
                     p->pVidMem = 0xFFD00000;
                     CopyVirtualScreenToScreen();
                 }
             }
         }
     UnlockIOF();
}

//-----------------------------------------------------------------------------
// The I/O focus list is an array indicating which jobs are requesting the
// I/O focus. The I/O focus is user controlled by pressing ALT-TAB on the
// keyboard.
//-----------------------------------------------------------------------------

void RequestIOFocus(JCB *j)
{
     int nj;
     int stat;

     nj = j->number;
     LockIOF();
        stat = (IOFocusTbl[0] >> nj) & 1;
        if (!stat) {
           if (IOFocusNdx==null) {
               IOFocusNdx = j;
               j->iof_next = j;
               j->iof_prev = j;
           }
           else {
               j->iof_prev = IOFocusNdx->iof_prev;
               j->iof_next = IOFocusNdx;
               IOFocusNdx->iof_prev->iof_next = j;
               IOFocusNdx->iof_prev = j;
           }
           IOFocusTbl[0] |= (1 << nj);
        }
     UnlockIOF();
}
        
//-----------------------------------------------------------------------------
// Release the IO focus for the current job.
//-----------------------------------------------------------------------------
void ReleaseIOFocus()
{
     ForceReleaseIOFocus(GetJCBPtr());
}

//-----------------------------------------------------------------------------
// Releasing the I/O focus causes the focus to switch if the running job
// had the I/O focus.
// ForceReleaseIOFocus forces the release of the IO focus for a job
// different than the one currently running.
//-----------------------------------------------------------------------------

void ForceReleaseIOFocus(JCB * j)
{
     JCB *p;
     
     LockIOF();
         if (IOFocusTbl[0] & (1 << (int)j->number)) {
             IOFocusTbl[0] &= ~(1 << j->number);
             if (j == IOFocusNdx)
                SwitchIOFocus();
             p = j->iof_next;
             if (p) {
                  if (p <> j) {
                        p->iof_prev = j->iof_prev;
                        j->iof_prev->iof_next = p;
                  } 
                  else {
                       IOFocusNdx = null;
                  }
                  j->iof_next = null;
                  j->iof_prev = null;
             }
         }
     UnlockIOF();
}

void CopyVirtualScreenToScreen()
{
     short int *p, *q;
     JCB *j;
     int nn, pos;

     j = IOFocusNdx;
     p = j->pVidMem;
     q = j->pVirtVidMem;
     nn = j->VideoRows * j->VideoCols;
     for (; nn >= 0; nn--)
         p[nn] = q[nn];
    pos = j->CursorRow * j->VideoCols + j->CursorCol;
    SetVideoReg(11,pos);
}

void CopyScreenToVirtualScreen()
{
     short int *p, *q;
     JCB *j;
     int nn;

     j = IOFocusNdx;
     p = j->pVidMem;
     q = j->pVirtVidMem;
     nn = j->VideoRows * j->VideoCols;
     for (; nn >= 0; nn--)
         q[nn] = p[nn];
}
