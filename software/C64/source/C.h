#ifndef C_H
#define C_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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

/*      compiler header file    */

typedef __int8 int8_t;
typedef __int16 int16_t;
typedef __int64 int64_t;

typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int64 uint64_t;

class ENODE;

enum e_sym {
  tk_nop,
        id, cconst, iconst, lconst, sconst, rconst, plus, minus,
        star, divide, lshift, rshift, modop, eq, neq, lt, leq, gt,
        geq, assign, asplus, asminus, astimes, asdivide, asmodop,
		aslshift, asrshift, asand, asor, asxor, autoinc, autodec, hook, cmpl,
        comma, colon, semicolon, double_colon, uparrow, openbr, closebr, begin, end,
        openpa, closepa, pointsto, dot, lor, land, nott, bitorr, bitandd,
		ellipsis,

		kw_int, kw_byte, kw_int8, kw_int16, kw_int32, kw_int64,
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
		kw_new, kw_delete, kw_using, kw_namespace, kw_not,
        my_eof };

enum e_sc {
        sc_static, sc_auto, sc_global, sc_thread, sc_external, sc_type, sc_const,
        sc_member, sc_label, sc_ulabel, sc_typedef };

enum e_bt {
		bt_none,
		bt_byte, bt_ubyte,
        bt_char, bt_short, bt_long, bt_float, bt_double, bt_triple, bt_pointer,
		bt_uchar, bt_ushort, bt_ulong,
        bt_unsigned,
        bt_struct, bt_union, bt_class, bt_enum, bt_void,
        bt_func, bt_ifunc, bt_label,
		bt_interrupt, bt_oscall, bt_pascal, bt_kernel, bt_bitfield, bt_ubitfield,
		bt_exception, bt_ellipsis,
        bt_last};

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

class C64PException
{
public:
	int errnum;
	int data;
	C64PException(int e, int d) { errnum = e; data = d; };
};

struct typ;
struct snode;

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
	// Auto's are ehandled by compound statements
	TABLE proto;
	TABLE params;
	TABLE lsyms;              // local symbols (goto labels)
	SYM *parms;					      // List of parameters associated with symbol
	SYM *nextparm;
	DerivedMethod *derivitives;
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
	unsigned int IsUndefined : 1;  // undefined function
	unsigned int ctor : 1;
	unsigned int dtor : 1;
	ENODE *initexp;
    union {
        int64_t i;
        uint64_t u;
        double f;
        uint16_t wa[8];
        char *s;
    } value;
  TYP *tp;
    struct snode *prolog;
    struct snode *epilog;
    unsigned int stksize;

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
	void BuildParameterList(int *num);
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
	int8_t		bit_width;
	int8_t		bit_offset;
  long        size;
  long 		size2;
  TABLE lst;
  int btp;
  TYP *GetBtp();
  static TYP *GetPtr(int n);
  int GetIndex();
  static int GetSize(int num);
  static int GetBasicType(int num);
  std::string *sname;
	unsigned int alignment;
	static TYP *Make(int bt, int siz);
	static TYP *Copy(TYP *src);
};

class TypeArray
{
public:
  int types[40];
  int length;
  TypeArray();
  void Add(int tp);
  void Add(TYP *tp);
  bool IsEmpty();
  bool IsEqual(TypeArray *);
  void Clear();
  TypeArray *Alloc();
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
	static int declare(SYM *parent,TABLE *table,int al,int ilc,int ztype);
	static void ParseConst();
	static void ParseTypedef();
	static void ParseNaked();
	static void ParseLong();
	static void ParseInt();
	static void ParseInt32();
	static void ParseInt8();
	static void ParseByte();
	static SYM *ParseId();
	static void ParseDoubleColon(SYM *sp);
	static void ParseBitfieldSpec(bool isUnion);
	static int ParseSpecifier(TABLE *table);
	static SYM *ParsePrefixId();
	static SYM *ParsePrefixOpenpa(bool isUnion);
	static SYM *ParsePrefix(char isUnion);
	static void ParseSuffixOpenbr();
	static void ParseSuffixOpenpa(SYM *);
	static SYM *ParseSuffix(SYM *sp);
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
#define ERR_NULLPOINTER		1000
#define ERR_CIRCULAR_LIST 1001

/*      alignment sizes         */

#define AL_BYTE			1
#define AL_CHAR         2
#define AL_SHORT        4
#define AL_LONG         8
#define AL_POINTER      8
#define AL_FLOAT        4
#define AL_DOUBLE       8
#define AL_STRUCT       8
#define AL_TRIPLE       4

#define TRUE	1
#define FALSE	0
//#define NULL	((void *)0)

#endif
