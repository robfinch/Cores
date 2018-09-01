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
void ListCompound(Statement *stmt);
std::string TraceName(SYM *sp);
void MarkRemove(OCODE *ip);
void IRemove();
int roundSize(TYP *tp);
extern char *rtrim(char *);
extern int caselit(scase *casetab, int64_t);
AMODE *make_indexed2(int lab, int i);

// MemoryManagement.cpp
void FreeFunction(Function *fn);

// Outcode.cpp
extern void genstorage(int64_t nbytes);
extern void GenerateByte(int64_t val);
extern void GenerateChar(int64_t val);
extern void genhalf(int64_t val);
extern void GenerateWord(int64_t val);
extern void GenerateLong(int64_t val);
extern void GenerateFloat(Float128 *val);
extern void GenerateQuad(Float128 *);
extern void GenerateReference(SYM *sp, int offset);
extern void GenerateLabelReference(int n);

#endif
