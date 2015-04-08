#ifndef CONST_H
#define CONST_H

#define TRUE        1
#define FALSE       0

#define null        (void *)0
#define MAX_UINT    0xFFFFFFFFFFFFFFFFL
#define TS_NONE     0
#define TS_TIMEOUT  1
#define TS_WAITMSG  2
#define TS_PREEMPT  4
#define TS_RUNNING  8
#define TS_READY   16

enum {
     E_Ok = 0,
     E_BadTCBHandle,
     E_BadPriority
};

#endif
