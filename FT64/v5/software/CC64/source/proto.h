#ifndef _PROTO_H
#define _PROTO_H

// Register.cpp
bool IsArgumentReg(int regno);
bool IsCalleeSave(int regno);

int64_t GetConstExpression(ENODE **pnode);

#endif
