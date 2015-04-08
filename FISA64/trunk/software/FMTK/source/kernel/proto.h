#ifndef PROTO_H
#define PROTO_H

TCB *GetRunningTCB();
JCB *GetJCBPtr();                   // get the JCB pointer of the running task
void set_vector(unsigned int, unsigned int);

#endif
