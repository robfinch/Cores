#ifndef TYPES_H
#define TYPES_H

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

#endif
