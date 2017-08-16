#ifndef _TYPES_H
#define _TYPES_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
//  - 64 bit CPU
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
class CSet;
class ENODE;
class Statement;
class SYM;
class BasicBlock;
class TYP;
class TypeArray;
class TABLE;

class CompilerType
{
public:
	static CompilerType *alloc() {};
};

class MBlk
{
	static MBlk *first;
public:
	MBlk *next;
	static void ReleaseAll();
	static void *alloc(int sz);
};

struct slit {
    struct slit     *next;
    int             label;
    char            *str;
	char			*nmspace;
};

struct scase {
	int label;
	int val;
};

struct clit {
    struct clit *next;
    int     label;
	int		num;
    scase   *cases;
	char	*nmspace;
};

class C64PException
{
public:
	int errnum;
	int data;
	C64PException(int e, int d) { errnum = e; data = d; };
};

// Type for expression evaluation

class ENODE : public CompilerType {
public:
    enum e_node nodetype;
	enum e_bt etype;
	long esize;
    TYP *tp;
    SYM *sym;
    unsigned int constflag : 1;		// expression is constant
    unsigned int predreg : 6;		// predicate register (not used)
	unsigned int isVolatile : 1;	// volatile expression
	unsigned int isIO : 1;
	unsigned int isUnsigned : 1;
	unsigned int isDouble : 1;		// floating point double
	unsigned int isCheckExpr : 1;
	unsigned int isPascal : 1;		// pascal calling convention
	__int8 bit_width;				// width of bitfield
	__int8 bit_offset;				// offset of bitfield
	__int8 scale;					// index scaling factor
	// The following could be in a value union
	int i;
	int oi;							// original value of i for pass2
	double f;
	double f1, f2;
	std::string *sp;
	std::string *msp;
	std::string *udnm;				// undecorated name
	void *ctor;
	void *dtor;
	ENODE *p[3];					// pointers for expression tree

	void SetType(TYP *t) { tp = t; };
	static ENODE *alloc();
	ENODE *Duplicate();
	bool IsLValue(bool opt);
	static bool IsEqual(ENODE *, ENODE *);
	static void OptimizeConstants(ENODE **);
};


class CSE : public CompilerType
{
public:
	short int nxt;
    ENODE *exp;				/* optimizable expression */
    short int uses;           /* number of uses */
    short int duses;          /* number of dereferenced uses */
    unsigned int voidf : 1;   /* cannot optimize flag */
    unsigned int isfp : 1;
    short int reg;            /* Allocated Register register */
public:
	int OptimizationDesireability();
};

class CSEList : public CompilerType
{
public:
	CSE CSETable[500];
public:
	CSE *Insert(ENODE *node, int duse);
	CSE *Find(ENODE *);
	int voidauto(ENODE *);
	void Dump();
};

struct typ;

#ifndef __GNUC__
// Not sure what this is doing, but causes GCC to complain
Statement;
#endif

class AMODE {
public:
	unsigned int mode : 6;
	unsigned int preg : 8;
	unsigned int sreg : 8;
	int vpreg;					// virtual register number
	int vsreg;					// virtual register number
	unsigned int segment : 4;
	unsigned int defseg : 1;
	unsigned int tempflag : 1;
	unsigned int isFloat : 1;
	char FloatSize;
	unsigned int isAddress : 1;
	unsigned int isUnsigned : 1;
	unsigned int lowhigh : 2;
	unsigned int isVolatile : 1;
	unsigned int isPascal : 1;
	unsigned int rshift : 8;
	short int deep;           /* stack depth on allocation */
	short int deep2;
	ENODE *offset;
	int8_t scale;
	AMODE *amode2;
};

class OCODE : public CompilerType
{
public:
	OCODE *fwd, *back, *comment;
	BasicBlock *bb;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;		// set if label is referenced
	unsigned int remove : 1;			// set to remove instruction in peephole opt.
	unsigned int leader : 1;			// set if code is leading block of basic block
	short pregreg;
	short predop;
	AMODE *oper1, *oper2, *oper3, *oper4;
};

class Edge : public CompilerType
{
public:
	Edge *next;
	Edge *prev;
	BasicBlock *src;
	BasicBlock *dst;
};

class BasicBlock : public CompilerType
{
public:
	int num;
	Edge *ohead;
	Edge *otail;
	Edge *ihead;
	Edge *itail;
public:
	unsigned int changed : 1;
	CSet *gen;		// use
	CSet *kill;		// def
	CSet *LiveIn;
	CSet *LiveOut;
	CSet *MustSpill;
	CSet *NeedLoad;
	BasicBlock *next;
	BasicBlock *prev;
	OCODE *code;
public:
	static BasicBlock *MakeNew();
	static BasicBlock *Blockize(OCODE *start);
	Edge *MakeOutputEdge(BasicBlock *dst);
	Edge *MakeInputEdge(BasicBlock *src);
	void ComputeLiveVars();
};


// This tree structure is used to track live ranges of a variable.

class Tree : public CompilerType
{
public:
	int num;
	Tree *next;
	CSet *tree;
public:
	static Tree *MakeNew() {
		Tree *t;
		t = (Tree*)allocx(sizeof(Tree));
		t->tree = CSet::MakeNew();
		return (t);
	};
};

// Each variable, including compiler generate temporaries, has an associated
// Var object.

class Var : public CompilerType
{
public:
	static int count;
	Var *next;
	int num;
	Tree *trees;
	CSet *forest;
public:
	static int GetCount() { return (count); };
	static Var *MakeNew();
	static void CreateVars();
	// Create a forest for a specific Var
	void CreateForest();
	// Create a forest for each Var object
	static void CreateForests();
	static Var *Find(int);
	static void DumpForests();
};

class DerivedMethod
{
public:
  int typeno;
  DerivedMethod *next;
  std::string *name;
};

// Class for representing tables. Small footprint.

class TABLE {
public:
	int head, tail;
	int base;
	int owner;
	static SYM *match[100];
	static int matchno;
	TABLE();
	static void CopySymbolTable(TABLE *dst, TABLE *src);
	void insert(SYM* sp);
	SYM *Find(std::string na,bool opt);
	int Find(std::string na);
	int Find(std::string na,__int16,TypeArray *typearray, bool exact);
	int FindRising(std::string na);
	TABLE *GetPtr(int n);
	void SetOwner(int n) { owner = n; };
	int GetHead() { return head; };
	void SetHead(int p) { head = p; };
	void SetTail(int p) { tail = p; };
	void Clear() { head = tail = base = 0; };
	void CopyTo(TABLE *dst) {
		dst->head = head;
		dst->tail = tail;
	};
	void MoveTo(TABLE *dst) {
		CopyTo(dst);
		Clear();
	};
	void SetBase(int b) { base = b; };
};

class SYM : public CompilerType {
public:
	int id;
	int parent;
	int next;
	std::string *name;
	std::string *name2;
	std::string *name3;
	std::string *shortname;
	std::string *mangledName;
	char nameext[4];
	char *realname;
	char *stkname;
    __int8 storage_class;
	unsigned int pos : 4;			// position of the symbol (param, auto or return type)
	// Function attributes
	uint8_t NumRegisterVars;
	unsigned __int8 NumParms;
	unsigned __int8 numa;			// number of stack parameters (autos)
	int stkspace;					// stack space used by function
	// Auto's are handled by compound statements
	TABLE proto;
	TABLE params;
	TABLE lsyms;              // local symbols (goto labels)
	SYM *parms;					      // List of parameters associated with symbol
	SYM *nextparm;
	DerivedMethod *derivitives;
	unsigned int IsParameter : 1;
	unsigned int IsRegister : 1;
	unsigned int IsAuto : 1;
	unsigned int IsPrototype : 1;
	unsigned int IsTask : 1;
	unsigned int IsInterrupt : 1;
	unsigned int IsNocall : 1;
	unsigned int IsPascal : 1;
	unsigned int IsLeaf : 1;
	unsigned int DoesThrow : 1;
	unsigned int UsesPredicate : 1;
	unsigned int isConst : 1;
	unsigned int IsKernel : 1;
	unsigned int IsPrivate : 1;
	unsigned int IsVirtual : 1;
	unsigned int IsInline : 1;
	unsigned int UsesTemps : 1;		// uses temporary registers
	unsigned int UsesStackParms : 1;
	unsigned int IsUndefined : 1;  // undefined function
	unsigned int ctor : 1;
	unsigned int dtor : 1;
	unsigned int AllowRegVars : 1;
	ENODE *initexp;
	__int16 reg;
    union {
        int i;
        unsigned int u;
        double f;
        uint16_t wa[8];
        char *s;
    } value;
	TYP *tp;
    Statement *stmt;
    Statement *prolog;
    Statement *epilog;
    unsigned int stksize;

	static SYM *alloc();
	TypeArray *GetParameterTypes();
	TypeArray *GetProtoTypes();
	void PrintParameterTypes();
	static SYM *Copy(SYM *src);
	bool ProtoTypesMatch(SYM *sym);
	bool ProtoTypesMatch(TypeArray *typearray);
	bool ParameterTypesMatch(SYM *sym);
	bool ParameterTypesMatch(TypeArray *typearray);
	SYM *Find(std::string name);
	SYM *FindRisingMatch(bool ignore=false);
	int FindNextExactMatch(int startpos, TypeArray *);
	std::string *GetNameHash();
	bool CheckSignatureMatch(SYM *a, SYM *b) const;
	SYM *FindExactMatch(int mm);
	static SYM *FindExactMatch(int mm, std::string name, int rettype, TypeArray *typearray);
	std::string *BuildSignature(int opt = 0);
	void BuildParameterList(int *num, int*numa);
	void AddParameters(SYM *list);
	void AddProto(SYM *list);
	void AddProto(TypeArray *);
	static SYM *GetPtr(int n);
	SYM *GetParentPtr();
	void SetName(std::string nm) {
		name = new std::string(nm);
		name2 = new std::string(nm);
		name3 = new std::string(nm);
	};
	void SetNext(int nxt) { next = nxt; };
	int GetNext() { return next; };
	SYM *GetNextPtr();
	int GetIndex();
	void AddDerived(SYM *sym);
	void SetType(TYP *t) { 
		tp = t;
	};
};

class TYP : public CompilerType {
public:
    e_bt type;
	__int16 typeno;			// number of the type
	unsigned int val_flag : 1;       /* is it a value type */
	unsigned int isArray : 1;
	unsigned int isUnsigned : 1;
	unsigned int isShort : 1;
	unsigned int isVolatile : 1;
	unsigned int isIO : 1;
	unsigned int isConst : 1;	// const in declaration
	unsigned int isResv : 1;
	__int16 precision;			// precision of the numeric in bits
	int8_t		bit_width;
	int8_t		bit_offset;
	long        size;
	long		numele;			// number of elements
	long		dimen;			// number of the dimension
	TABLE lst;
	int btp;
	static TYP *alloc();
	TYP *GetBtp();
	static TYP *GetPtr(int n);
	int GetIndex();
	int GetHash();
	static int GetSize(int num);
	static int GetBasicType(int num);
	std::string *sname;
	unsigned int alignment;
	static TYP *Make(int bt, int siz);
	static TYP *Copy(TYP *src);
	bool IsFloatType() const { return (type==bt_quad || type==bt_float || type==bt_double || type==bt_triple); };
	bool IsStructType() const { return (type==bt_struct || type==bt_union || type==bt_class); };
	bool IsAggregateType() const { return IsStructType() | isArray; };
	bool IsUnion() const { return (type==bt_union); };
	void put_ty();
};

class TypeArray
{
public:
	int types[40];
	__int16 preg[40];
	int length;
	TypeArray();
	void Add(int tp, __int16 regno);
	void Add(TYP *tp, __int16 regno);
	bool IsEmpty();
	bool IsEqual(TypeArray *);
	bool IsLong(int);
	bool IsShort(int);
	bool IsChar(int);
	bool IsInt(int);
	void Clear();
	TypeArray *alloc();
	void Print(txtoStream *);
	void Print();
	std::string *BuildSignature();
};

class Stringx
{
public:
  std::string str;
};

class Declaration
{
	static void SetType(SYM *sp);
public:
	Declaration *next;
	char *lptr;
	static int declare(SYM *parent,TABLE *table,int al,int ilc,int ztype);
	static void ParseConst();
	static void ParseTypedef();
	static void ParseNaked();
	static void ParseLong();
	static void ParseInt();
	static void ParseInt80();
	static void ParseInt64();
	static void ParseInt40();
	static void ParseInt32();
	static void ParseInt16();
	static void ParseInt8();
	static void ParseByte();
	static SYM *ParseId();
	static void ParseDoubleColon(SYM *sp);
	static void ParseBitfieldSpec(bool isUnion);
	static int ParseSpecifier(TABLE *table);
	static SYM *ParsePrefixId();
	static SYM *ParsePrefixOpenpa(bool isUnion);
	static SYM *ParsePrefix(bool isUnion);
	static void ParseSuffixOpenbr();
	static void ParseSuffixOpenpa(SYM *);
	static SYM *ParseSuffix(SYM *sp);
	static void ParseFunctionAttribute(SYM *sym);
	void GenMixedSource();
};

class Statement : public CompilerType {
public:
	__int8 stype;		// type see above (if, else, return, etc)
	Statement *outer;	// more outer statement used for searching heirarchy
	Statement *next;	// next statement in list
	Statement *prolog;	// compound statements prolog code
	Statement *epilog;	// epilog code
	bool nkd;			// statement is naked (reduced code generation)
	int predreg;		// assigned predicate register
	ENODE *exp;         // condition or expression
	ENODE *initExpr;    // initialization expression - for loops
	ENODE *incrExpr;    // increment expression - for loops
	Statement *s1, *s2; // internal statements
	int num;			// resulting expression type (hash code for throw)
	int throwlab;		// label for throw statement
	int *label;         // label number for goto
	int *casevals;		// case values
	TABLE ssyms;		// local symbols associated with statement
	char *fcname;       // firstcall block var name
	char *lptr;			// pointer to copy of input line
	unsigned int prediction : 2;	// static prediction for if statements

	static Statement *NewStatement(int typ, int gt);

	// Parsing
	static Statement *ParseStop();
	static Statement *ParseCompound();
	static Statement *ParseDo();
	static Statement *ParseFor();
	static Statement *ParseForever();
	static Statement *ParseFirstcall();
	static Statement *ParseIf();
	static Statement *ParseCatch();
	static Statement *ParseCase();
	int CheckForDuplicateCases();
	static Statement *ParseThrow();
	static Statement *ParseContinue();
	static Statement *ParseAsm();
	static Statement *ParseTry();
	static Statement *ParseExpression();
	static Statement *ParseLabel();
	static Statement *ParseWhile();
	static Statement *ParseUntil();
	static Statement *ParseGoto();
	static Statement *ParseReturn();
	static Statement *ParseBreak();
	static Statement *ParseSwitch(int);
	static Statement *ParseCheck();
	static Statement *Parse(int);

	// Optimization
	void scan();
	void ScanCompound();
	int CSEOptimize();
	void repcse();
	void repcseCompound();

	// Code generation
	void GenMixedSource();
	void GenerateStop();
	void GenerateAsm();
	void GenerateFirstcall();
	void GenerateWhile();
	void GenerateUntil();
	void GenerateFor();
	void GenerateForever();
	void GenerateIf();
	void GenerateDo();
	void GenerateDoUntil();
	void GenerateCompound();
	void GenerateCase();
	void GenerateTry();
	void GenerateThrow();
	void GenerateCheck();
	void GenerateFuncBody();
	void GenerateSwitch();
	void GenerateLinearSwitch();
	void GenerateTabularSwitch();
	void Generate();
};

class StructDeclaration : public Declaration
{
public:
	static void ParseMembers(SYM * sym, TYP *tp, int ztype);
	static int Parse(int ztype);
};

class ClassDeclaration : public Declaration
{
public:
	static void ParseMembers(SYM * sym, int ztype);
	static int Parse(int ztype);
};

class AutoDeclaration : public Declaration
{
public:
	static void Parse(SYM *parent, TABLE *ssyms);
};

class ParameterDeclaration : public Declaration
{
public:
	static int Parse(int);
};

class GlobalDeclaration : public Declaration
{
public:
	void Parse();
	static GlobalDeclaration *Make();
};

class Compiler
{
public:
	int typenum;
	int symnum;
	int throwlab;
	SYM symbolTable[32768];
	TYP typeTable[32768];
public:
	GlobalDeclaration *decls;
	Compiler();
	void compile();
	int PreprocessFile(char *nm);
	void CloseFiles();
	void AddStandardTypes();
	int main2(int c, char **argv);
};

 
#endif
