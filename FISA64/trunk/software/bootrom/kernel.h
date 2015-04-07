// error codes
#define E_Ok				0x00
#define E_Arg				0x01
#define E_BadMbx			0x04
#define E_QueFull			0x05
#define E_NoThread			0x06
#define E_NotAlloc			0x09
#define E_NoMsg				0x0b
#define E_Timeout			0x10
// resource errors
#define E_NoMoreMbx			0x40
#define E_NoMoreMsgBlks		0x41
#define E_NoMoreAlarmBlks	0x44
#define E_NoMoreTCBs		0x45

#define E_BadCallGate		0x49	// tried to call uninitialize gate

#define E_BadDMAChannel		0x400
#define E_DMABoundary		0x402	// transfer will cross 64/128k
#define E_BadDMAAddr		0x403	// address over 16M limit

#define OSCodeSel	8
#define DataSel		

// task status
#define TS_TIMEOUT	0
#define TS_WAITMSG	1
#define TS_PREEMP	2
#define TS_RUNNING	4
#define TS_READY	8

// message queuing strategy
#define MQS_UNLIMITED	0	// unlimited queue size
#define MQS_NEWEST		1	// buffer queue size newest messages
#define MQS_OLDEST		2	// buffer queue size oldest messages

// message block type
#define MBT_DATA	0

// alarm constants
#define ALM_FOREVER	-1		// repeat forever code

#define MAX_UINT	-1


typedef struct tagMSG {
	struct tagMSG *link;
	uint d1;
	uint d2;
	byte type;
	byte resv[3];
} MSG;

typedef struct tagMBX {
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
	byte resv[3];		// padding to 32 bytes
} MBX;

typedef struct tagALARM {
	ALARM *next;
	ALARM *prev;
	MBX *mbx;
	MSG *msg;
	uint BaseTimeout;
	uint timeout;
	uint repeat;
	byte resv[4];		// padding to 32 bytes
} ALARM;
