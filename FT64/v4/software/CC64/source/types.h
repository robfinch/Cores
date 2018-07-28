#ifndef _TYPES_H
#define _TYPES_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
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
class ENODE;
class Statement;
class BasicBlock;
class Instruction;
class Var;
class CSE;

enum e_sym {
  tk_nop,
        id, cconst, iconst, lconst, sconst, rconst, plus, minus,
        star, divide, lshift, rshift, lrot, rrot,
		modop, eq, neq, lt, leq, gt,
        geq, assign, asplus, asminus, astimes, asdivide, asmodop,
		aslshift, asrshift, aslrot, asrrot,
		asand, asor, asxor, autoinc, autodec, hook, cmpl,
        comma, colon, semicolon, double_colon, uparrow, openbr, closebr, begin, end,
        openpa, closepa, pointsto, dot, lor, land, nott, bitorr, bitandd,
		ellipsis,
		// functions
		kw_abs, kw_max, kw_min,

		kw_vector, kw_vector_mask,
		kw_int, kw_byte, kw_int8, kw_int16, kw_int32, kw_int40, kw_int64, kw_int80,
		kw_icache, kw_dcache, kw_thread,
        kw_void, kw_char, kw_float, kw_double, kw_triple,
        kw_struct, kw_union, kw_class,
        kw_long, kw_short, kw_unsigned, kw_auto, kw_extern,
        kw_register, kw_typedef, kw_static, kw_goto, kw_return,
        kw_sizeof, kw_break, kw_continue, kw_if, kw_else, kw_elsif,
		kw_for, kw_forever, kw_signed,
		kw_firstcall, kw_asm, kw_fallthru, kw_until, kw_loop,
		kw_try, kw_catch, kw_throw, kw_typenum, kw_const, kw_volatile,
        kw_do, kw_while, kw_switch, kw_case, kw_default, kw_enum,
		kw_interrupt, kw_vortex, kw_pascal, kw_oscall, kw_nocall, kw_naked,
		kw_intoff, kw_inton, kw_then,
		kw_private,kw_public,kw_stop,kw_critical,kw_spinlock,kw_spinunlock,kw_lockfail,
		kw_cdecl, kw_align, kw_prolog, kw_epilog, kw_check, kw_exception, kw_task,
		kw_unordered, kw_inline, kw_kernel, kw_inout, kw_leafs,
    kw_unique, kw_virtual, kw_this,
		kw_new, kw_delete, kw_using, kw_namespace, kw_not, kw_attribute,
		kw_no_temps, kw_no_parms, kw_floatmax,
        my_eof };

enum e_sc {
        sc_static, sc_auto, sc_global, sc_thread, sc_external, sc_type, sc_const,
        sc_member, sc_label, sc_ulabel, sc_typedef, sc_register };

class CompilerType
{
public:
	static CompilerType *alloc();
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
	int64_t val;
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


struct typ;
Statement;

class TYP;
class SYM;
class TypeArray;

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

class SYM {
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
	int argbot;
	int tempbot;
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
	unsigned int UsesNew : 1;
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
	ENODE *initexp;
	__int16 reg;
    union {
        int64_t i;
        uint64_t u;
        double f;
        uint16_t wa[8];
        char *s;
    } value;
	Float128 f128;
	TYP *tp;
    Statement *stmt;
    Statement *prolog;
    Statement *epilog;
    unsigned int stksize;
	CSE *csetbl;
	int csendx;

	TypeArray *GetParameterTypes();
	TypeArray *GetProtoTypes();
	void PrintParameterTypes();
	bool HasRegisterParameters();
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
       name3 = new std::string(nm); };
	void SetNext(int nxt) { next = nxt; };
	int GetNext() { return next; };
	SYM *GetNextPtr();
	int GetIndex();
	void AddDerived(SYM *sym);
	void SetType(TYP *t) { 
		if (t == (TYP *)0x500000005) {
			printf("Press key\n");
			getchar();
	}
	else
		tp = t;
} ;
};

class TYP {
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
	int8_t		ven;			// vector element number
	long        size;
	int8_t dimen;
	int numele;					// number of elements in array / vector length
	TABLE lst;
	int btp;
	TYP *GetBtp();
	static TYP *GetPtr(int n);
	int GetIndex();
	int GetHash();
	static int GetSize(int num);
	int GetElementSize();
	static int GetBasicType(int num);
	std::string *sname;
	unsigned int alignment;
	static TYP *Make(int bt, int siz);
	static TYP *Copy(TYP *src);
	bool IsFloatType() const { return (type==bt_quad || type==bt_float || type==bt_double || type==bt_triple); };
	bool IsVectorType() const { return (type==bt_vector); };
	bool IsUnion() const { return (type==bt_union); };
	bool IsStructType() const { return (type==bt_struct || type==bt_class || type==bt_union); };
	bool IsAggregateType() const { return (IsStructType() | isArray); };
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
	bool IsByte(int);
	bool IsInt(int);
	void Clear();
	TypeArray *Alloc();
	void Print(txtoStream *);
	void Print();
	std::string *BuildSignature();
};

class ENODE {
public:
    enum e_node nodetype;
	enum e_bt etype;
	long      esize;
    TYP *tp;
    SYM *sym;
    __int8 constflag;
    unsigned int predreg : 4;
	unsigned int isVolatile : 1;
	unsigned int isIO : 1;
	unsigned int isUnsigned : 1;
	unsigned int isDouble : 1;
	unsigned int isCheckExpr : 1;
	unsigned int isPascal : 1;
	ENODE *vmask;
	__int8 bit_width;
	__int8 bit_offset;
	__int8 scale;
	// The following could be in a value union
  int64_t i;
  double f;
  double f1, f2;
  Float128 f128;
  std::string *sp;
  std::string *msp;
	std::string *udnm;			// undecorated name
	void *ctor;
	void *dtor;
  ENODE *p[3];
  void SetType(TYP *t) { tp = t; };
};

class AMODE : public CompilerType
{
public:
	unsigned int mode : 6;
	unsigned int preg : 8;		// primary virtual register number
	unsigned int sreg : 8;		// secondary virtual register number (indexed addressing modes)
	unsigned int lrpreg : 8;	// renumbered live range register
	unsigned int lrsreg : 8;
	unsigned int pregs;			// subscripted register number
	unsigned int sregs;
	unsigned int segment : 4;
	unsigned int defseg : 1;
	unsigned int tempflag : 1;
	unsigned int type : 16;
	char FloatSize;
	unsigned int isUnsigned : 1;
	unsigned int lowhigh : 2;
	unsigned int isVolatile : 1;
	unsigned int isPascal : 1;
	unsigned int rshift : 8;
	unsigned int isTarget : 1;
	short int deep;           /* stack depth on allocation */
	short int deep2;
	ENODE *offset;
	int8_t scale;
	AMODE *next;			// For extended sizes (long)
};

// Output code structure

class OCODE : public CompilerType
{
public:
	OCODE *fwd, *back, *comment;
	BasicBlock *bb;
	Instruction *insn;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;	// label is referenced by code
	unsigned int remove : 1;
	unsigned int remove2 : 1;
	unsigned int leader : 1;
	short pregreg;
	short predop;
	int loop_depth;
	AMODE *oper1, *oper2, *oper3, *oper4;
	__int16 phiops[100];
public:
	static OCODE *MakeNew();
	bool HasTargetReg() const;
	int GetTargetReg() const;
	bool HasSourceReg(int) const;
	//Edge *MakeEdge(OCODE *ip1, OCODE *ip2);
};

// Control Flow Graph
// For now everything in this class is static and there are no member variables
// to it.
class CFG
{
public:
	static void Create();
	static void CalcDominatorTree();
	static void CalcDominanceFrontiers();
	static void InsertPhiInsns();
	static void Rename();
	static void Search(BasicBlock *);
	static void Subscript(AMODE *oper);
	static int WhichPred(BasicBlock *x, int y);
};


/*      output code structure   */
/*
OCODE {
	OCODE *fwd, *back, *comment;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;	// label is referenced by code
	unsigned int remove : 1;
	short pregreg;
	short predop;
	AMODE *oper1, *oper2, *oper3, *oper4;
};
typedef OCODE OCODE;
*/

class IntStack
{
public:
	int *stk;
	int sp;
public:
	static IntStack *MakeNew() {
		IntStack *s;
		s = (IntStack *)allocx(sizeof(IntStack));
		s->stk = (int *)allocx(1000 * sizeof(int));
		s->sp = 1000;
		return (s);
	}
	void push(int v) {
		if (sp > 0) {
			sp--;
			stk[sp] = v;
		}
	};
	int pop() {
		int v = 0;
		if (sp < 1000) {
			v = stk[sp];
			sp++;
		}
		return (v);
	};
	int tos() {
		return (stk[sp]);
	};
};

class Edge : public CompilerType
{
public:
	bool backedge;
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
	Edge *dhead;
	Edge *dtail;
public:
	unsigned int changed : 1;
	int depth;
	CSet *gen;		// use
	CSet *kill;		// def
	CSet *LiveIn;
	CSet *LiveOut;
	CSet *live;
	CSet *MustSpill;
	CSet *NeedLoad;
	CSet *DF;		// dominance frontier
	int HasAlready;
	int Work;
	static CSet *livo;
	BasicBlock *next;
	BasicBlock *prev;
	OCODE *code;
	OCODE *lcode;
public:
	static BasicBlock *MakeNew();
	static BasicBlock *Blockize(OCODE *start);
	Edge *MakeOutputEdge(BasicBlock *dst);
	Edge *MakeInputEdge(BasicBlock *src);
	Edge *MakeDomEdge(BasicBlock *dst);
	void ComputeLiveVars();
	void AddLiveOut(BasicBlock *ip);
	bool IsIdom(BasicBlock *b);
};

// A "tree" is a "range" in Briggs terminology
class Tree : public CompilerType
{
public:
	static int treecount;
	int var;
	int num;
	Tree *next;
	CSet *tree;
	// Cost accounting
	float loads;
	float stores;
	float copies;
	bool infinite;
	float cost;
public:
	static Tree *MakeNew();
};

class Var : public CompilerType
{
public:
	Var *next;
	int num;
	int cnum;
	Tree *trees;
	CSet *forest;
	CSet *visited;
	IntStack *istk;
	int subscript;
public:
	static Var *MakeNew();
	void GrowTree(Tree *, BasicBlock *);
	// Create a forest for a specific Var
	void CreateForest();
	// Create a forest for each Var object
	static void CreateForests();
	static Var *Find(int);
	static Var *Find2(int);
	static void DumpForests();
};

class Instruction
{
public:
	char *mnem;		// mnemonic
	short opcode;	// matches OCODE opcode
	short extime;	// execution time, divide may take hundreds of cycles
	bool HasTarget;	// has a target register
	bool memacc;	// instruction accesses memory
};

class CSE {
public:
	short int nxt;
    ENODE *exp;           /* optimizable expression */
    short int       uses;           /* number of uses */
    short int       duses;          /* number of dereferenced uses */
    short int       reg;            /* AllocateRegisterVarsd register */
    unsigned int    voidf : 1;      /* cannot optimize flag */
    unsigned int    isfp : 1;
public:
	int OptimizationDesireability();
};

class Peep
{
public:
	static void InsertBefore(OCODE *an, OCODE *cd);
	static void InsertAfter(OCODE *an, OCODE *cd);
};

class Statement {
public:
	__int8 stype;
	Statement *outer;
	Statement *next;
	Statement *prolog;
	Statement *epilog;
	bool nkd;
	int predreg;		// assigned predicate register
	ENODE *exp;         // condition or expression
	ENODE *initExpr;    // initialization expression - for loops
	ENODE *incrExpr;    // increment expression - for loops
	Statement *s1, *s2; // internal statements
	int num;			// resulting expression type (hash code for throw)
	int64_t *label;     // label number for goto
	int64_t *casevals;	// case values
	TABLE ssyms;		// local symbols associated with statement
	char *fcname;       // firstcall block var name
	char *lptr;
	unsigned int prediction : 2;	// static prediction for if statements
	int depth;
	
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
	static Statement *ParseSwitch();
	static Statement *Parse();

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
	static int declare(SYM *parent,TABLE *table,int al,int ilc,int ztype);
	static void ParseVoid();
	static void ParseConst();
	static void ParseTypedef();
	static void ParseNaked();
	static void ParseShort();
	static void ParseLong();
	static void ParseInt();
	static void ParseInt80();
	static void ParseInt64();
	static void ParseInt40();
	static void ParseInt32();
	static void ParseInt16();
	static void ParseInt8();
	static void ParseByte();
	static void ParseFloat();
	static void ParseDouble();
	static void ParseVector();
	static void ParseVectorMask();
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

class CPU
{
public:
	bool SupportsPush;
	bool SupportsPop;
	bool SupportsLink;
	bool SupportsUnlink;
};

//#define SYM     struct sym
//#define TYP     struct typ
//#define TABLE   struct stab

#define MAX_STRLEN      120
#define MAX_STLP1       121
#define ERR_SYNTAX      0
#define ERR_ILLCHAR     1
#define ERR_FPCON       2
#define ERR_ILLTYPE     3
#define ERR_UNDEFINED   4
#define ERR_DUPSYM      5
#define ERR_PUNCT       6
#define ERR_IDEXPECT    7
#define ERR_NOINIT      8
#define ERR_INCOMPLETE  9
#define ERR_ILLINIT     10
#define ERR_INITSIZE    11
#define ERR_ILLCLASS    12
#define ERR_BLOCK       13
#define ERR_NOPOINTER   14
#define ERR_NOFUNC      15
#define ERR_NOMEMBER    16
#define ERR_LVALUE      17
#define ERR_DEREF       18
#define ERR_MISMATCH    19
#define ERR_EXPREXPECT  20
#define ERR_WHILEXPECT  21
#define ERR_NOCASE      22
#define ERR_DUPCASE     23
#define ERR_LABEL       24
#define ERR_PREPROC     25
#define ERR_INCLFILE    26
#define ERR_CANTOPEN    27
#define ERR_DEFINE      28
#define ERR_CATCHEXPECT	29
#define ERR_BITFIELD_WIDTH	30
#define ERR_EXPRTOOCOMPLEX	31
#define ERR_ASMTOOLONG	32
#define ERR_TOOMANYCASECONSTANTS	33
#define ERR_CATCHSTRUCT		34
#define ERR_SEMA_INCR	35
#define ERR_SEMA_ADDR	36
#define ERR_UNDEF_OP	37
#define ERR_INT_CONST	38
#define ERR_BAD_SWITCH_EXPR	39
#define ERR_NOT_IN_LOOP	40
#define ERR_CHECK       41
#define ERR_BADARRAYNDX	42
#define ERR_TOOMANYDIMEN	43
#define ERR_OUTOFPREDS  44 
#define ERR_PARMLIST_MISMATCH	45
#define ERR_PRIVATE		46
#define ERR_CALLSIG2	47
#define ERR_METHOD_NOTFOUND	48
#define ERR_OUT_OF_MEMORY   49
#define ERR_TOOMANY_SYMBOLS 50
#define ERR_TOOMANY_PARAMS  51
#define ERR_THIS            52
#define ERR_BADARG			53
#define ERR_CSETABLE		54
#define ERR_UBLTZ			55
#define ERR_UBGEQ			56
#define ERR_INFINITELOOP	57
#define ERR_TOOMANYELEMENTS	58
#define ERR_NULLPOINTER		1000
#define ERR_CIRCULAR_LIST 1001

/*      alignment sizes         */

#define AL_BYTE			1
#define AL_CHAR         2
#define AL_SHORT        4
#define AL_LONG         8
#define AL_POINTER      8
#define AL_FLOAT        8
#define AL_DOUBLE       8
#define AL_QUAD			16
#define AL_STRUCT       2
#define AL_TRIPLE       12

#define TRUE	1
#define FALSE	0
//#define NULL	((void *)0)
 
#endif
