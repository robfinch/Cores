#ifndef TYPES_H
#define TYPES_H

typedef unsigned int uint;
typedef __int16 hTCB;
typedef __int16 hACB;
typedef __int16 hMBX;
typedef __int16 hMSG;

typedef struct _tagObject {
	__int32 typenum;
	__int32 id;
	struct _tagObject *prev;
} __object;

typedef struct _tagMBLK {
	__int32 magic;
	__int32 size;
	struct _tagMBLK *next;
	struct _tagMBLK *prev;
} MBLK;

typedef struct tagMSG align(32) {
	unsigned __int16 link;
	unsigned __int16 retadr;    // return address
	unsigned __int16 tgtadr;    // target address
	unsigned __int16 type;
	unsigned int d1;            // payload data 1
	unsigned int d2;            // payload data 2
	unsigned int d3;            // payload data 3
} MSG;

// Application control block
typedef struct _tagACB align(2048)
{
	unsigned int magic;			// ACB ACB 
	struct _tagObject *garbage_list;
	MBLK *pHeap;
	int HeapSize;
    struct _tagACB *iof_next;
    struct _tagACB *iof_prev;
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
    __int16 KeyState1;
    __int16 KeyState2;
    __int16 KeybdWaitFlag;
    __int16 KeybdHead;
    __int16 KeybdTail;
    unsigned __int16 KeybdBuffer[32];
    hACB number;
    hACB next;
    hTCB thrd;
} ACB;

struct tagMBX;

typedef struct _tagTCB align(1024) {
    // exception storage area
	int regs[32];
	int fpregs[32];
	int xregs[32];
	int epc;
	int vl;
	int cr0;
	hTCB acbnext;
	hTCB next;
	hTCB prev;
	hTCB mbq_next;
	hTCB mbq_prev;
	int stacksize;
	int *stack;
	int *sys_stack;
	int *bios_stack;
	int timeout;
	MSG msg;
	hMBX hMailboxes[4]; // handles of mailboxes owned by task
	hMBX hWaitMbx;      // handle of mailbox task is waiting at
	hTCB number;
	hACB hApp;
	__int8 priority;
	__int8 status;
	__int32 affinity;
	int startTick;
	int endTick;
	int ticks;
	int exception;
} TCB;

typedef struct tagMBX align(64) {
    hMBX link;
	hACB owner;		// hApp of owner
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

typedef struct tagAppStartupRec {
	int pagesize : 4;
	int priority : 4;
	int reserved : 24;
	__int32 affinity;
	int codesize;
	int datasize;	// Initialized data
	int heapsize;
	int stacksize;
	__int32 *pCode;
	int *pData;
} AppStartupRec;

#endif
