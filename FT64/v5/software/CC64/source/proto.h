#ifndef _PROTO_H
#define _PROTO_H

// Register.cpp
bool IsArgumentReg(int regno);
bool IsCalleeSave(int regno);

int64_t GetConstExpression(ENODE **pnode);
void GenMemop(int op, AMODE *ap1, AMODE *ap2, int ssize);
void GenerateHint(int num);

#endif
