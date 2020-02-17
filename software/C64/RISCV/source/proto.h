#ifndef _PROTO_H
#define _PROTO_H

TYP *forcefit(ENODE **srcnode, TYP *srctp, ENODE **dstnode, TYP *dsttp, bool promote, bool typecast);

// Register.cpp
bool IsArgumentReg(int regno);
bool IsCalleeSave(int regno);

int64_t GetConstExpression(ENODE **pnode);
void GenMemop(int op, Operand *ap1, Operand *ap2, int ssize);
void GenerateHint(int num);

void SaveRegisterVars(CSet *rmask);
void SaveFPRegisterVars(CSet *fprmask);
void funcbottom(Statement *stmt);
Function *allocFunction(int id);
Function *newFunction(int id);
SYM *makeint2(std::string na);
int64_t round10(int64_t n);
int pwrof2(int64_t);
void ListCompound(Statement *stmt);
std::string TraceName(SYM *sp);
void MarkRemove(OCODE *ip);
void IRemove();
int roundSize(TYP *tp);
extern char *rtrim(char *);
extern int caselit(scase *casetab, int64_t);
extern int litlist(ENODE *);
extern int longlit(__int64 i64);

// MemoryManagement.cpp
void FreeFunction(Function *fn);

// Outcode.cpp
extern void genstorage(int64_t nbytes);
extern void GenerateByte(int64_t val);
extern void GenerateChar(int64_t val);
extern void GenerateHalf(int64_t val);
extern void GenerateWord(int64_t val);
extern void GenerateLong(int64_t val);
extern void GenerateFloat(Float128 *val);
extern void GenerateQuad(Float128 *);
extern void GenerateReference(SYM *sp, int64_t offset);
extern void GenerateLabelReference(int n, int64_t);

extern char *RegMoniker(int regno);
extern void push_token();
extern void pop_token();
extern char *GetStrConst();

extern void push_typ(TYP *tp);
extern TYP *pop_typ();

extern TYP *nameref2(std::string name, ENODE **node, int nt, bool alloc, TypeArray*, TABLE* tbl);
extern void opt_const_unchecked(ENODE **node);
extern Operand *MakeString(char *s);
extern Operand *MakeDoubleIndexed(int i, int j, int scale);

#endif
