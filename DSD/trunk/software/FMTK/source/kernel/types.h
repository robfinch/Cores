#ifndef TYPES_H
#define TYPES_H

typedef unsigned int uint;
typedef __int16 hTCB;
typedef __int16 hJCB;
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
    __int16 KeyState1;
    __int16 KeyState2;
    __int16 KeybdWaitFlag;
    __int16 KeybdHead;
    __int16 KeybdTail;
    unsigned __int16 KeybdBuffer[32];
    hJCB number;
    hTCB tasks[8];
    hJCB next;
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
	__int16 priority : 8;
	__int16 status : 8;
	__int16 affinity : 8;
	hJCB hJob : 8;
	__int64 startTick;
	__int64 endTick;
	__int64 ticks;
	int exception;
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

#endif
