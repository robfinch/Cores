#ifndef _PROTO_H
#define _PROTO_H

// Register.cpp
bool IsArgumentReg(int regno);
bool IsCalleeSave(int regno);

int64_t GetConstExpression(ENODE **pnode);
void GenMemop(int op, AMODE *ap1, AMODE *ap2, int ssize);
void GenerateHint(int num);

void SaveRegisterVars(int64_t mask, int64_t rmask);
void SaveFPRegisterVars(int64_t fpmask, int64_t fprmask);
void GenLdi(AMODE *, AMODE *);
void SaveRegisterVars(int64_t mask, int64_t rmask);
void SaveFPRegisterVars(int64_t mask, int64_t rmask);
void funcbottom(Statement *stmt);
Function *allocFunction(int id);
SYM *makeint2(std::string na);
int round8(int n);

#endif
