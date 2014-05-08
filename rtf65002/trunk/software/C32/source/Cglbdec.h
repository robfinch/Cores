/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */

/*      global ParseSpecifierarations     */
#include "statement.h"

extern FILE             *input,
                        *list,
                        *output;
extern FILE *outputG;
extern int incldepth;
extern int              lineno;
extern int              nextlabel;
extern int              lastch;
extern int              lastst;
extern char             lastid[33];
extern char             laststr[MAX_STLP1];
extern __int64	ival;
extern double           rval;
extern int parseEsc;

extern TABLE            gsyms[257],
                        lsyms;
extern SYM              *lasthead;
extern struct slit      *strtab;
extern int              lc_static;
extern int              lc_auto;
extern int				lc_thread;
extern struct snode     *bodyptr;       /* parse tree for function */
extern int              global_flag;
extern TABLE            defsyms;
extern int              save_mask;      /* register save mask */
extern int uctran_off;
extern int isPascal;
extern int isOscall;
extern int isInterrupt;
extern int isNocall;
extern int asmblock;
extern int optimize;
extern int exceptions;
extern SYM *currentFn;

extern void error(int n);
extern void needpunc(enum e_sym p);
// main.c
extern void closefiles();
// Memmgt.c
extern char *xalloc(int);
extern SYM *allocSYM();
extern TYP *allocTYP();
extern AMODE *allocAmode();
extern void ReleaseLocalMemory();

// NextToken.c
extern void initsym();
extern void NextToken();
extern int getch();
extern int isspace(char c);
extern void getbase(b);
extern void SkipSpaces();

// Stmt.c
extern struct snode *ParseCompoundStatement();
extern int GetTypeHash(TYP *p);
extern void GenerateDiadic(int op, int len, struct amode *ap1,struct amode *ap2);
// Symbol.c
extern SYM *gsearch(char *na);
extern SYM *search(char *na,TABLE *thead);
extern void insert(SYM* sp, TABLE *table);

extern char *litlate(char *);
// Decl.c
extern void dodecl(int defclass);
extern void ParseParameterDeclarations(int);
extern void ParseAutoDeclarations();
extern void ParseSpecifier(TABLE *table);
extern int ParseDeclarationPrefix();
extern void ParseStructDeclaration(int);
extern void ParseEnumerationList(TABLE *table);
extern int ParseDeclarationPrefix(char isUnion);
extern void compile();
extern void initstack();
extern int getline(int listflag);
extern TYP *maketype(int bt, int siz);

// Init.c
extern void doinit(SYM *sp);
// Func.c
extern void funcbody(SYM *sp);
// Intexpr.c
extern __int32 GetIntegerExpression();
// ParseExpressions.c
extern ENODE *makenode(int nt, ENODE *v1, ENODE *v2);
extern ENODE *makeinode(int nt, __int32 v1);
extern ENODE *makesnode(int nt, char *v1);
extern TYP *expression(struct enode **node);
extern int IsLValue(struct enode *node);
extern TYP *NonCommaExpression(ENODE **node);
extern TYP *ParseUnaryExpression(ENODE **node);
extern int isscalar(TYP *tp);
// ParseFunction.c
extern SYM *makeint(char *name);
extern void ParseFunction(SYM *sp);
// Optimize.c
extern void opt4(struct enode **node);
// GenerateStatement.c
extern void GenerateStatement(struct snode *stmt);
extern void GenerateIntoff(struct snode *stmt);
extern void GenerateInton(struct snode *stmt);
extern void GenerateStop(struct snode *stmt);
extern void GenerateAsm(struct snode *stmt);
extern void GenerateFirstcall(struct snode *stmt);
extern void gen_regrestore();
extern AMODE *make_direct(__int64 i);
extern int popcnt(int m);
// Outcode.c
extern void GenerateByte(int val);
extern void GenerateChar(int val);
extern void genhalf(int val);
extern void GenerateWord(__int64 val);
extern void GenerateLong(__int64 val);
extern void genstorage(int nbytes);
extern void GenerateReference(SYM *sp,int offset);
extern void GenerateLabelReference(int n);
extern void gen_strlab(char *s);
extern void dumplits();
extern int  stringlit(char *s);
extern void nl();
extern void seg(int sg);
extern void cseg();
extern void dseg();
extern void tseg();
extern void put_code(int op, int len,AMODE *aps, AMODE *apd, AMODE *);
extern void put_label(int lab, char*);
// Peepgen.c
extern void flush_peep();
extern void GenerateLabel(int labno);
extern int equal_address(AMODE *ap1, AMODE *ap2);
// Gencode.c
extern AMODE *make_label(__int64 lab);
extern AMODE *make_immed(__int64);
extern AMODE *make_indirect(int i);
extern AMODE *make_offset(struct enode *node);
extern void swap_nodes(struct enode *node);
extern int isshort(struct enode *node);
// IdentifyKeyword.c
extern int IdentifyKeyword();
// Preproc.c
extern int preprocess();
// CodeGenerator.c
extern AMODE *make_indirect(int i);
extern AMODE *make_indexed(__int64 o, int i);
extern AMODE *make_string(char *s);
extern void GenerateFalseJump(struct enode *node,int label);
extern char *GetNamespace();
extern AMODE *MakeLegalAmode(AMODE *ap,int flags, int size);
extern void GenerateTrueJump(ENODE *node, int label);
extern char nmspace[20][100];
enum e_sg { noseg, codeseg, dataseg, bssseg, idataseg, tlsseg };
// MemoryManagement.c
ENODE *allocEnode();
SYM *allocSYM();
TYP *allocTYP();
struct snode *allocSnode();
ENODE *allocEnode();
AMODE *allocAmode();
CSE *allocCSE();
void ReleaseGlobalMemory();
// Register.c
extern AMODE *GetTempRegister();
extern void ReleaseTempRegister(AMODE *ap);
extern int SaveTempRegs();
extern void RestoreTempRegs(int rgmask);
extern int PopFromRstk();
extern void validate(AMODE *ap);
// list.c
void ListTable(TABLE *t, int i);
// GenerateShift.c
AMODE *GenerateShift(ENODE *node,int flags, int size, int op);
AMODE *GenerateAssignShift(ENODE *node,int flags,int size,int op);
// GenerateFunction.c
extern AMODE *GenerateFunctionCall(ENODE *node, int flags);
extern void GenerateReturn(SYM *sym, Statement *stmt);
extern void GenerateFunction(SYM *sym, Statement *stmt);
//Analyze.c
void opt1(Statement *block);
// Err.c
void fatal(char *);

