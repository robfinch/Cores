#ifndef _PROTO_H
#define _PROTO_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
extern int PeepCount(OCODE *ip);

// Analyze.c

extern int opt1(Statement *stmt);
// CMain.c
extern void closefiles();

extern void error(int n);
extern void needpunc(enum e_sym p,int);
// Memmgt.c
extern void *allocx(int);
extern char *xalloc(int);
extern SYM *allocSYM();
extern TYP *allocTYP();
extern AMODE *allocAmode();
extern ENODE *allocEnode();
extern CSE *allocCSE();
extern void ReleaseGlobalMemory();
extern void ReleaseLocalMemory();

// NextToken.c
extern void initsym();
extern void NextToken();
extern int getch();
extern int my_isspace(char c);
extern void getbase(int64_t);
extern void SkipSpaces();

// Stmt.c
extern Statement *ParseCompoundStatement();

extern void GenerateDiadic(int op, int len, struct amode *ap1,struct amode *ap2);
// Symbol.c
extern SYM *gsearch(std::string na);
extern SYM *search(std::string na,TABLE *thead);
extern void insert(SYM* sp, TABLE *table);

// ParseFunction.c
extern SYM *BuildParameterList(SYM *sp, int *);

extern char *my_strdup(char *);
// Decl.c
extern int imax(int i, int j);
extern TYP *maketype(int bt, int siz);
extern void dodecl(int defclass);
extern int ParseParameterDeclarations(int);
extern void ParseAutoDeclarations(SYM *sym, TABLE *table);
extern int ParseSpecifier(TABLE *table);
extern SYM* ParseDeclarationPrefix(char isUnion);
extern int ParseStructDeclaration(int);
extern void ParseEnumerationList(TABLE *table);
extern int ParseFunction(SYM *sp);
extern int declare(SYM *sym,TABLE *table,int al,int ilc,int ztype);
extern void initstack();
extern int getline(int listflag);
extern void compile();

// Init.c
extern void doinit(SYM *sp);
// Func.c
extern SYM *makeint(char *);
extern void funcbody(SYM *sp);
// Intexpr.c
extern int GetIntegerExpression(ENODE **p);
// Expr.c
extern SYM *makeStructPtr(std::string name);
extern ENODE *makenode(int nt, ENODE *v1, ENODE *v2);
extern ENODE *makeinode(int nt, int v1);
extern ENODE *makesnode(int nt, std::string *v1, std::string *v2, int i);
extern TYP *nameref(ENODE **node,int);
extern TYP *forcefit(ENODE **node1,TYP *tp1,ENODE **node2,TYP *tp2,bool);
extern TYP *expression(ENODE **node);
extern AMODE *GenerateExpression(ENODE *node, int flags, int size);
extern int GetNaturalSize(ENODE *node);
extern TYP *asnop(ENODE **node);
extern TYP *NonCommaExpression(ENODE **);
// Optimize.c
extern void opt_const(ENODE **node);
// GenerateStatement.c
//extern void GenerateFunction(Statement *stmt);
extern void GenerateIntoff(Statement *stmt);
extern void GenerateInton(Statement *stmt);
extern void GenerateStop(Statement *stmt);
extern void gen_regrestore();
extern AMODE *make_direct(int i);
extern AMODE *makereg(int r);
extern AMODE *makefpreg(int t);
extern AMODE *makebreg(int r);
extern AMODE *makepred(int r);
extern int bitsset(int64_t mask);
extern int popcnt(int64_t m);
// Outcode.c
extern void GenerateByte(int val);
extern void GenerateChar(int val);
extern void genhalf(int val);
extern void GenerateWord(int val);
extern void GenerateLong(int val);
extern void genstorage(int nbytes);
extern void GenerateReference(SYM *sp,int offset);
extern void GenerateLabelReference(int n);
extern void gen_strlab(char *s);
extern void dumplits();
extern int  stringlit(char *s);
extern void nl();
extern void seg(int sg, int algn);
extern void cseg();
extern void dseg();
extern void tseg();
//extern void put_code(int op, int len,AMODE *aps, AMODE *apd, AMODE *);
extern void put_code(OCODE *);
extern char *put_label(int lab, char*, char*, char);
extern char *opstr(int op);
// Peepgen.c
extern AMODE *copy_addr(AMODE *ap);
extern void MarkRemoveRange(OCODE *bp, OCODE *ep);
extern void PeepRemove();
extern void PeepNop(OCODE *ip1, OCODE *ip2);
extern void flush_peep();
extern int equal_address(AMODE *ap1, AMODE *ap2);
extern int GeneratePreload();
extern void OverwritePreload(int handle, int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4);
extern void GenerateLabel(int labno);
extern void GenerateZeradic(int op);
extern void GenerateMonadic(int op, int len, AMODE *ap1);
extern void GenerateDiadic(int op, int len, AMODE *ap1, AMODE *ap2);
extern void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3);
extern void Generate4adic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4);
extern void GeneratePredicatedMonadic(int pr, int pop, int op, int len, AMODE *ap1);
extern void GeneratePredicatedDiadic(int pop, int pr, int op, int len, AMODE *ap1, AMODE *ap2);
extern void GeneratePredicatedTriadic(int pop, int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3);
// Gencode.c
extern void GenerateHint(int n);
extern void GenLdi(AMODE *, AMODE *);
extern AMODE *make_label(int lab);
extern AMODE *make_clabel(int lab);
extern AMODE *make_clabel2(int lab,char*);
extern AMODE *make_immed(int i);
extern AMODE *make_indirect(int i);
extern AMODE *make_offset(ENODE *node);
extern void swap_nodes(ENODE *node);
extern int isshort(ENODE *node);
// IdentifyKeyword.c
extern int IdentifyKeyword();
// Preproc.c
extern int preprocess();
// OPC6.cpp
extern void GenerateCmp(ENODE *node, int label, int predreg, unsigned int prediction, int type);
// CodeGenerator.c
extern AMODE *make_indirect(int i);
extern AMODE *make_indexed(int o, int i);
extern AMODE *make_indx(ENODE *node, int reg);
extern AMODE *make_string(char *s);
extern void GenerateFalseJump(ENODE *node,int label, unsigned int);
extern void GenerateTrueJump(ENODE *node,int label, unsigned int);
extern char *GetNamespace();
extern char nmspace[20][100];
extern AMODE *GenerateDereference(ENODE *, int, int, int);
extern void MakeLegalAmode(AMODE *ap,int flags, int size);
extern void GenLoad(AMODE *, AMODE *, int size, int);
extern void GenStore(AMODE *, AMODE *, int size);
// List.c
extern void ListTable(TABLE *t, int i);
// Register.c
extern AMODE *GetTempRegister();
extern AMODE *GetTempRegister2(int *pushed);
extern AMODE *GetTempRegisterPair();
extern AMODE *GetTempBrRegister();
extern AMODE *GetTempFPRegister();
extern void ReleaseTempRegister(AMODE *ap);
extern void ReleaseTempReg(AMODE *ap);
extern int TempInvalidate();
extern void TempRevalidate(int sp);
extern AMODE *GenerateFunctionCall(ENODE *node, int flags);

extern void GenerateFunction(SYM *sym);
extern void GenerateReturn(Statement *stmt);

extern AMODE *GenerateShift(ENODE *node,int flags, int size);
extern AMODE *GenerateAssignShift(ENODE *node,int flags,int size);
extern AMODE *GenerateBitfieldDereference(ENODE *node, int flags, int size);
extern AMODE *GenerateBitfieldAssign(ENODE *node, int flags, int size);
// err.c
extern void fatal(char *str);

extern int GetReturnBlockSize();

extern void ComputeLiveVars();
extern void DumpLiveVars();

#endif
