#ifndef TYPES_H
#define TYPES_H

typedef unsigned int uint;
typedef __int16 hTCB;
typedef __int16 hACB;
typedef __int16 hMBX;
typedef __int16 hMSG;

typedef struct _tagPTE {
	unsigned __int8 acr;
	unsigned __int8 pl;
	unsigned __int8 u;
	unsigned __int8 reserved;
	unsigned __int32 refcount;
	unsigned int PhysPage;
} PTE;

typedef struct _tagPageTable {
	PTE pte[1024];
} PageTable;

typedef struct _tagPageTables {
	PageTable pgtbl[256];
} PageTables;

typedef struct _tagMBLK {
	__int32 magic;
	__int32 size;
	struct _tagMBLK *next;
	struct _tagMBLK *prev;
} MBLK;

typedef struct _tagObject align(64) {
	int magic;
	int size;
//	__gc_skip skip1 {
		__int32 typenum;
		__int32 id;
		__int8 state;			// WHITE, GREY, or BLACK
		__int8 scavangeCount;
		__int8 owningMap;
		__int8 pad1;
		__int32 pad2;
		unsigned int usedInMap;		
//	};
	struct _tagObject *forwardingAddress;
	void (*finalizer)();
} __object;

// Types of memory spaces
#define MS_FROM		0
#define MS_TO		1
#define MS_OLD		2
#define MS_PRIM		3
#define MS_LO		4
#define MS_CODE		5
#define MS_CELL		6
#define MS_PCELL	7
#define MS_MAP		8

typedef struct _tagMEMORY {
	unsigned int key;
	void *addr;
	int size;
	int owningMap;
	unsigned int shareMap;
	__object *allocptr;
	struct _tagMEMORY *next;
} MEMORY;

typedef struct _tagHeap {
	MEMORY mem[9];
	MEMORY *fromSpace;
	MEMORY *toSpace;
	int size;
	int owningMap;
	struct _tagHeap *next;
} HEAP;

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
typedef struct _tagACB align(8192)
{
	// 4x64 bits = 256 bits, which indicates which L1 card to scan
	// resolves the pointer address to a 65k memory block
	unsigned int L2cards[4];
	// A pointer cannot be within the first 65kB of the virtual
	// address space. So storage for the heap can't begin before
	// page 8.
	unsigned int L1cards[252];	// 256*64=16384 bits (2048 bytes)
	unsigned int magic;			// ACB ACB 
	int regset;
	int *pData;
	int pDataSize;
	int *pUIData;
	int pUIDataSize;
	__object **gc_roots;
	int gc_rootcnt;
	int gc_ndx;
	__object **gc_markingQue;
	__int8 gc_markingQueFull;
	__int8 gc_markingQueEmpty;
	__int8 gc_overflow;
	__int16 *pCode;
	struct _tagObject *objectList;
	struct _tagObject *garbage_list;
	HEAP Heap;
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
    int *templates[256];
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
	int uidatasize;	// uninitialized data
	int heapsize;
	int stacksize;
	__int16 *pCode;
	int *pData;
	int *pUIData;
} AppStartupRec;

#endif
