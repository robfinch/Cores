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
// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//



// Including SDKDDKVer.h defines the highest available Windows platform.

// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.







// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// 128 bit floating point class
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
// Floats here are actually represented with a 128 bit mantissa for simpliity
// rather than 112 bits.
// ============================================================================
//

class Float128
{
public:
	static const __int16 bias = 0x3FFF;
	static const __int16 infxp = 0x7FFF;
public:
	unsigned __int32 pack[4];
	unsigned __int32 man[4];
	unsigned __int16 exp;
	bool sign;
	// The following is for compiler use
	//-----------------------------------
	Float128 *next;	// next in a list
	int label;
	char *nmspace;
	//-----------------------------------
	void ShiftManLeft();
private:
	void ShiftManRight();
	static bool ManEQ(Float128 *a, Float128 *b);
	static bool ManGT(Float128 *a, Float128 *b);
	static bool ManGE(Float128 *a, Float128 *b) {
		if (ManGT(a,b))
			return (true);
		if (ManEQ(a,b))
			return (true);
		return (false);
	};
	static bool AddMan(Float128 *s, Float128 *a, Float128 *b);
	static bool SubMan(Float128 *d, Float128 *a, Float128 *b);
	void Denormalize(unsigned __int16 xp);
	void Denorm1();
public:
	Float128() {
		Zeroman();
		exp = 0;
		sign = false;
	};
	Float128(Float128 *a);
	void Zeroman() {
		int nn;
		for (nn = 0; nn < 4; nn++)
			man[nn] = 0;
	};
	static Float128 *Zero() {
		static Float128 p;
		p.Zeroman();
		p.exp = 0x0000;
		return (&p);
	};
	static Float128 *One() {
		static Float128 p;
		p.Zeroman();
		p.man[4-1] = 0x40000000;
		p.exp = 0x3FFF;
		return (&p);
	};
	static Float128 *Ten() {
		static Float128 p;
		p.Zeroman();
		p.man[4-1] = 0x50000000;
		p.exp = 0x4002;
		return (&p);
	};
	static Float128 *OneTenth() {
		int nn;
		static Float128 p;
		for (nn = 0; nn < 4; nn++)
			p.man[nn] = 0x66666666;
		p.exp = 0x3FFB;
		return (&p);
	};
	static Float128 *FloatMax() {
		int nn;
		static Float128 p;
		for (nn = 0; nn < 4; nn++)
			p.man[nn] = 0xFFFFFFFF;
		for (nn = 0; nn < 4/2; nn++)
			p.man[nn] = 0;
		for (; nn < 4-1; nn++)
			p.man[nn] = 0xFFFFFFFF;
		p.man[4/2-1] = 0x80000000;
		p.man[4-1] = 0x7FFFFFFF;
		p.exp = 0x7FFE;
		return (&p);
	};
	static Float128 *Neg(Float128 *p) {
		Float128 *q = new Float128;
		q->sign = !p->sign;
		return q;
	};
	static void Add(Float128 *s, Float128 *a, Float128 *b);
	static void Sub(Float128 *d, Float128 *a, Float128 *b) {
		Float128 *b1 = Neg(b);
		Add(d, a, b1);
		delete b1;
	};
	static void Mul(Float128 *p, Float128 *a, Float128 *b);
	static void Div(Float128 *q, Float128 *a, Float128 *b);
	static void Assign(Float128 *d, Float128 *s) {
		int nn;
		for (nn = 0; nn < 4; nn++)
			d->man[nn] = s->man[nn];
		d->exp = s->exp;
		d->sign = s->sign;
	};
	static void Normalize(Float128 *a);
	static void IntToFloat(Float128 *d, __int64 v);
	static void FloatToInt(__int64 *i, Float128 *a);
	static void Float128ToDouble(double *d, Float128 *a);
	void Pack(int);
	char *ToString();
	char *ToString(int);
	bool IsManZero() const;
	bool IsZero() const;
	bool IsInfinite() const;
	static bool IsEqual(Float128 *a, Float128 *b);
	static bool IsEqualNZ(Float128 *a, Float128 *b);
	static bool IsNaN(Float128 *a);
	bool IsNaN() { return (IsNaN(this)); };
};
/********************************************************************** 
 Freeciv - Copyright (C) 1996 - A Kjeldberg, L Gregersen, P Unold
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
***********************************************************************/


/* This is duplicated in shared.h to avoid extra includes: */

typedef unsigned int RANDOM_TYPE;

typedef struct {
  RANDOM_TYPE v[56];
  int j, k, x;
  bool is_init;			/* initially 0 for static storage */
} RANDOM_STATE;

namespace RTFClasses
{
class Random
{
private:
	static RANDOM_STATE rand_state;
	RANDOM_STATE static getRandState(void) {
		return rand_state;
	}
	void static setRandState(RANDOM_STATE state) {;
		rand_state = state;
	}
public:
	bool static isInit(void) {
		return rand_state.is_init;
	}
	RANDOM_TYPE static rand(RANDOM_TYPE size);
	void static srand(RANDOM_TYPE seed);
	void test(int n);
};
};

class txtoStream : public std::ofstream
{
	char buf[500];
public:
	int level;
public:
  txtoStream() : std::ofstream() {};
	void write(char *buf) { if (level) {
	   std::ofstream::write(buf, strlen(buf));
       flush(); }};
	void printf(char *str) { if (level) write(str); };
	void printf(const char *str) { if (level) write((char *)str); };
	void printf(char *fmt, char *str);
	void printf(char *fmt, char *str, int n);
	void printf(char *fmt, char *str, char *str2);
	void printf(char *fmt, char *str, char *str2, int n);
	void printf(char *fmt, int n, char *str);
	void printf(char *fmt, int n);
	void printf(char *fmt, int n, int m);
	void printf(char *fmt, __int64 n);
	void putch(char ch) { 
	    if (level) {
	     buf[0] = ch;
	     buf[1] = '\0';
	     buf[2] = '\0';
	     buf[3] = '\0';
       std::ofstream::write(buf, 1);
       }};
	void puts(const char *);
};

// Make it easy to disable debugging output
// Mirror the txtoStream class with one that does nothing.

class txtoStreamNull
{
public:
  int level;
  void open(...);
  void close();
  void write(char *) { };
  void printf(...) { };
  void putch(char) { };
  void puts(const char *) {} ;
};


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
class ENODE;
class Statement;

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

enum e_bt {
		bt_none,
		bt_8, bt_8u, bt_16, bt_16u, bt_int32, bt_int32u, bt_40, bt_40u, bt_64, bt_64u, bt_80, bt_80u,
		bt_byte, bt_ubyte,
        bt_char, bt_short, bt_long, bt_float, bt_double, bt_triple, bt_quad, bt_pointer,
		bt_uchar, bt_ushort, bt_ulong,
        bt_unsigned, bt_vector, bt_vector_mask,
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
	ENODE *initexp;
	__int16 reg;
    union {
        int i;
        unsigned int u;
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
  bool IsInt(int);
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
	static void ParseVoid();
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

//#define SYM     struct sym
//#define TYP     struct typ
//#define TABLE   struct stab


/*      alignment sizes         */


//#define NULL	((void *)0)
 

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C32 - 'C' derived language compiler
//  - 32 bit CPU
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

/*      expression tree descriptions    */

enum e_node {
        en_void,        /* used for parameter lists */
		en_list, en_aggregate,
		en_cbu, en_ccu, en_chu,
		en_cubu, en_cucu, en_cuhu,
		en_cbw, en_ccw, en_chw,
		en_cubw, en_cucw, en_cuhw,

        en_cbc, en_cbh,
		en_cch,
		en_cwl, en_cld, en_cfd,
        en_icon, en_fcon, en_fqcon, en_dcon, en_tcon, en_labcon, en_nacon, en_autocon, en_autofcon, en_classcon,
		en_clabcon, en_cnacon,
		en_dlabcon, en_dnacon, // 30<-
		
		en_c_ref, en_uc_ref, en_h_ref, en_uh_ref,
        en_b_ref, en_w_ref, en_ub_ref, en_uw_ref,
		en_ref32, en_ref32u,
		en_struct_ref,
        en_fcall, en_ifcall,
         en_tempref, en_regvar, en_fpregvar, en_tempfpref,
		en_add, en_sub, en_mul, en_mod,
		en_ftadd, en_ftsub, en_ftmul, en_ftdiv,
		en_fdadd, en_fdsub, en_fdmul, en_fddiv,
		en_fsadd, en_fssub, en_fsmul, en_fsdiv,
		en_fadd, en_fsub, en_fmul, en_fdiv,
		en_i2d, en_i2t, en_i2q, en_d2i, en_q2i, en_s2q, en_t2i, // 63<-
        en_div, en_asl, en_shl, en_shlu, en_shr, en_shru, en_asr, en_rol, en_ror,
		en_cond, en_assign, 
        en_asadd, en_assub, en_asmul, en_asdiv, en_asdivu, en_asmod, en_asmodu,
		en_asrsh, en_asrshu, en_asmulu, //81
        en_aslsh, en_asand, en_asor, en_asxor, en_uminus, en_not, en_compl,
        en_eq, en_ne, en_lt, en_le, en_gt, en_ge,
        en_feq, en_fne, en_flt, en_fle, en_fgt, en_fge,
        en_veq, en_vne, en_vlt, en_vle, en_vgt, en_vge,
		en_and, en_or, en_land, en_lor, //104
        en_xor, en_ainc, en_adec, en_mulu, en_udiv, en_umod, en_ugt,
        en_uge, en_ule, en_ult,
		en_ref, en_ursh,
		en_uwfieldref,en_wfieldref,en_bfieldref,en_ubfieldref,
		en_uhfieldref,en_hfieldref,en_ucfieldref,en_cfieldref,
		en_dbl_ref, en_flt_ref, en_triple_ref, en_quad_ref,
		en_chk,
		en_abs, en_max, en_min,
		// Vector
		en_autovcon, en_autovmcon, en_vector_ref, en_vex, en_veins,
		en_vadd, en_vsub, en_vmul, en_vdiv,
		en_vadds, en_vsubs, en_vmuls, en_vdivs
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
  int i;
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

//typedef struct enode ENODE;

class CSE {
public:
	short int nxt;
    ENODE *exp;           /* optimizable expression */
    short int       uses;           /* number of uses */
    short int       duses;          /* number of dereferenced uses */
    short int       voidf;          /* cannot optimize flag */
    short int       reg;            /* AllocateRegisterVarsd register */
    unsigned int    isfp : 1;
};



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
enum e_stmt {
		st_empty, st_funcbody,
        st_expr, st_compound, st_while, 
		st_until, st_forever, st_firstcall, st_asm,
		st_dountil, st_doloop,
		st_try, st_catch, st_throw, st_critical, st_spinlock, st_spinunlock,
		st_for,
		st_do, st_if, st_switch, st_default,
        st_case, st_goto, st_break, st_continue, st_label,
        st_return, st_vortex, st_intoff, st_inton, st_stop, st_check };

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
	int *label;         // label number for goto
	int *casevals;		// case values
	TABLE ssyms;		// local symbols associated with statement
	char *fcname;       // firstcall block var name
	char *lptr;
	unsigned int prediction : 2;	// static prediction for if statements
	
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
	static Statement *Parse(int);

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

/*
 *      code generation structures and constants
 */


/*      addressing mode structure       */

typedef struct amode {
	unsigned int mode : 6;
	unsigned int preg : 8;
	unsigned int sreg : 8;
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
	short int deep;           /* stack depth on allocation */
	short int deep2;
	ENODE *offset;
	int8_t scale;
} AMODE;

/*      output code structure   */

struct ocode {
	struct ocode *fwd, *back, *comment;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;	// label is referenced by code
	unsigned int remove : 1;
	short pregreg;
	short predop;
	AMODE *oper1, *oper2, *oper3, *oper4;
};

enum e_op {
        op_move, op_add, op_addu, op_addi, op_sub, op_subi, op_mov, op_mtspr, op_mfspr, op_ldi, op_ld,
        op_mul, op_muli, op_mulu, op_divi, op_modi, op_modui, 
        op_div, op_divs, op_divsi, op_divu, op_and, op_andi, op_eor, op_eori,
        op_or, op_ori, op_xor, op_xori, op_redor,
		op_asr, op_asri, op_shl, op_shr, op_shru, op_ror, op_rol,
		op_shli, op_shri, op_shrui, op_shlu, op_shlui, op_rori, op_roli,
		op_bfext, op_bfextu, op_bfins,
		op_jmp, op_jsr, op_mului, op_mod, op_modu,
		op_bmi, op_subu, op_lwr, op_swc, op_loop, op_iret,
		op_sext32,op_sext16,op_sext8, op_sxb, op_sxc, op_sxh, op_zxb, op_zxc, op_zxh,
		op_dw, op_cache,
		op_subui, op_addui, op_sei,
		op_sw, op_sh, op_sc, op_sb, op_outb, op_inb, op_inbu,
		op_sfd, op_lfd,
		op_call, op_jal, op_beqi, op_bnei, op_tst,

		op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
		op_bltu, op_bleu, op_bgtu, op_bgeu,
		op_bltui, op_bleui, op_blti, op_blei, op_bgti, op_bgtui, op_bgei, op_bgeui,
		op_bbs, op_bbc, op_bor,

		op_brz, op_brnz, op_br,
		op_lft, op_sft,
		op_lw, op_lh, op_lc, op_lb, op_ret, op_sm, op_lm, op_ldis, op_lws, op_sws,
		op_lvb, op_lvc, op_lvh, op_lvw,
		op_inc, op_dec,
		op_lbu, op_lcu, op_lhu, op_sti,
		op_lf, op_sf,
        op_rts, op_rti, op_rtd,
		op_push, op_pop, op_movs,
		op_seq, op_sne, op_slt, op_sle, op_sgt, op_sge, op_sltu, op_sleu, op_sgtu, op_sgeu,
		op_bra, op_bf, op_eq, op_ne, op_lt, op_le, op_gt, op_ge,
		op_feq, op_fne, op_flt, op_fle, op_fgt, op_fge,
		op_gtu, op_geu, op_ltu, op_leu, op_nr,
        op_bhi, op_bhs, op_blo, op_bls, op_ext, op_lea, op_swap,
        op_neg, op_not, op_com, op_cmp, op_clr, op_link, op_unlk, op_label,
        op_pea, op_cmpi, op_dc, op_asm, op_stop, op_fnname, 
        // W65C816 ops
        op_sec, op_clc, op_lda, op_sta, op_stz, op_adc, op_sbc, op_ora,
        op_jsl, 
        op_rtl, op_php, op_plp, op_cli, op_ldx, op_stx, op_brl,
        op_pha, op_phx, op_pla, op_plx, op_rep, op_sep,
        op_bpl, op_tsa, op_tas,
        // FISA64
        op_lc0i, op_lc1i, op_lc2i, op_lc3i, op_chk, op_chki,
        op_cmpu, op_bsr, op_bun,
        op_sll, op_slli, op_srl, op_srli, op_sra, op_srai, op_asl, op_lsr, op_asli, op_lsri, op_rem,
        // floating point
		op_fbeq, op_fbne, op_fbor, op_fbun, op_fblt, op_fble, op_fbgt, op_fbge,
		op_fcvtsq,
		op_fadd, op_fsub, op_fmul, op_fdiv, op_fcmp, op_fneg,
		op_ftmul, op_ftsub, op_ftdiv, op_ftadd, op_ftneg, op_ftcmp,
		op_fdmul, op_fdsub, op_fddiv, op_fdadd, op_fdneg, op_fdcmp,
		op_fsmul, op_fssub, op_fsdiv, op_fsadd, op_fsneg, op_fscmp,
		op_fs2d, op_i2d, op_i2t, op_ftoi, op_itof, op_qtoi,
		op_fmov,
        op_fdmov, op_fix2flt, op_mtfp, op_mffp, op_flt2fix, op_mv2flt, op_mv2fix,
		// Vector
		op_lv, op_sv,
		op_vadd, op_vsub, op_vmul, op_vdiv,
		op_vadds, op_vsubs, op_vmuls, op_vdivs,
		op_vseq, op_vsne,
		op_vslt, op_vsge, op_vsle, op_vsgt,
		op_vex, op_veins,
		// DSD9
		op_ldd, op_ldb, op_ldp, op_ldw, op_ldbu, op_ldwu, op_ldpu, op_ldt, op_ldtu,
		op_std, op_stb, op_stp, op_stw, op_stt, op_calltgt,
		op_csrrw, op_nop,
		op_hint, op_hint2,
		// Built in functions
		op_abs,
        op_empty };

enum e_seg {
	op_ns = 0,
	op_ds = 1 << 8,
	op_ts = 2 << 8,
	op_bs = 3 << 8,
	op_rs = 4 << 8,
	op_es = 5 << 8,
	op_seg6 = 6 << 8,
	op_seg7 = 7 << 8,
	op_seg8 = 8 << 8,
	op_seg9 = 9 << 8,
	op_seg10 = 10 << 8,
	op_seg11 = 11 << 8, 
	op_seg12 = 12 << 8,
	op_seg13 = 13 << 8,
	op_ss = 14 << 8,
	op_cs = 15 << 8
};

enum e_am {
        am_reg, am_sreg, am_breg, am_fpreg, am_vreg, am_vmreg, am_ind, am_brind, am_ainc, am_adec, am_indx, am_indx2,
        am_direct, am_jdirect, am_immed, am_mask, am_none, am_indx3, am_predreg
	};





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
//#define DOTRACE	1

extern int maxPn;
extern int hook_predreg;
extern int gCpu;
extern int regGP;
extern int regSP;
extern int regBP;
extern int regLR;
extern int regXLR;
extern int regPC;
extern int regCLP;
extern int farcode;
extern int wcharSupport;
extern int verbose;
extern int use_gp;
extern int address_bits;
extern std::ifstream *ifs;
extern txtoStream ofs;
extern txtoStream lfs;
extern txtoStream dfs;
extern int mangledNames;
extern int sizeOfWord;
extern int sizeOfPtr;
extern int sizeOfFP;
extern int sizeOfFPS;
extern int sizeOfFPT;
extern int sizeOfFPD;
extern int sizeOfFPQ;
extern int maxVL;

/*
extern FILE             *input,
                        *list,
                        *output;
*/
extern FILE *outputG;
extern int incldepth;
extern int              lineno;
extern int              nextlabel;
extern int              lastch;
extern int              lastst;
extern char             lastid[128];
extern char             lastkw[128];
extern char             laststr[121];
extern int64_t	ival;
extern double           rval;
extern Float128			rval128;
extern char float_precision;
extern int parseEsc;
//extern FloatTriple      FAC1,FAC2;

extern TABLE            gsyms[257],
                        lsyms;
extern TABLE            tagtable;
extern SYM              *lasthead;
extern struct slit      *strtab;
extern struct clit		*casetab;
extern Float128		    *quadtab;
extern int              lc_static;
extern int              lc_auto;
extern int				lc_thread;
extern Statement     *bodyptr;       /* parse tree for function */
extern int              global_flag;
extern TABLE            defsyms;
extern int64_t          save_mask;      /* register save mask */
extern int64_t          fpsave_mask;
extern int				bsave_mask;
extern int uctran_off;
extern int isKernel;
extern int isPascal;
extern int isOscall;
extern int isInterrupt;
extern int isTask;
extern int isNocall;
extern bool isRegister;
extern int asmblock;
extern int optimize;
extern int opt_noregs;
extern int opt_nopeep;
extern int opt_noexpr;
extern int opt_nocgo;
extern int exceptions;
extern int mixedSource;
extern SYM *currentFn;
extern int iflevel;
extern int foreverlevel;
extern int looplevel;
extern int loopexit;
extern int regmask;
extern int bregmask;
extern Statement *currentStmt;
extern bool dogen;
extern struct ocode *peep_tail;

extern TYP stdint;
extern TYP stduint;
extern TYP stdlong;
extern TYP stdulong;
extern TYP stdshort;
extern TYP stdushort;
extern TYP stdchar;
extern TYP stduchar;
extern TYP stdbyte;
extern TYP stdubyte;
extern TYP stdstring;
extern TYP stddbl;
extern TYP stdtriple;
extern TYP stdflt;
extern TYP stddouble;
extern TYP stdfunc;
extern TYP stdexception;
extern TYP stdconst;
extern TYP stdquad;
extern TYP stdvector;
extern TYP *stdvectormask;

extern std::string *declid;
extern Compiler compiler;

// Analyze.c
extern short int csendx;
extern CSE CSETable[500];
extern int equalnode(ENODE *node1, ENODE *node2);
extern int bsort(CSE **list);
extern int OptimizationDesireability(CSE *csp);
extern int opt1(Statement *stmt);
extern CSE *olist;         /* list of optimizable expressions */
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
extern Float128 *GetFloatExpression(ENODE **pnode);
// Expr.c
extern SYM *makeStructPtr(std::string name);
extern ENODE *makenode(int nt, ENODE *v1, ENODE *v2);
extern ENODE *makeinode(int nt, int v1);
extern ENODE *makesnode(int nt, std::string *v1, std::string *v2, int i);
extern TYP *nameref(ENODE **node,int);
extern TYP *forcefit(ENODE **node1,TYP *tp1,ENODE **node2,TYP *tp2,bool);
extern TYP *expression(ENODE **node);
extern int IsLValue(ENODE *node);
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
extern AMODE *makevreg(int r);
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
extern void GenerateFloat(Float128 *val);
extern void GenerateQuad(Float128 *);
extern void genstorage(int nbytes);
extern void GenerateReference(SYM *sp,int offset);
extern void GenerateLabelReference(int n);
extern void gen_strlab(char *s);
extern void dumplits();
extern int  stringlit(char *s);
extern int quadlit(Float128 *f128);
extern void nl();
extern void seg(int sg, int algn);
extern void cseg();
extern void dseg();
extern void tseg();
//extern void put_code(int op, int len,AMODE *aps, AMODE *apd, AMODE *);
extern void put_code(struct ocode *);
extern char *put_label(int lab, char*, char*, char);
extern char *opstr(int op);
// Peepgen.c
extern int PeepCount(struct ocode *);
extern void flush_peep();
extern int equal_address(AMODE *ap1, AMODE *ap2);
extern void GenerateLabel(int labno);
extern void GenerateZeradic(int op);
extern void GenerateMonadic(int op, int len, AMODE *ap1);
extern void GenerateDiadic(int op, int len, AMODE *ap1, AMODE *ap2);
extern void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3);
extern void Generate4adic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4);
extern void GeneratePredicatedMonadic(int pr, int pop, int op, int len, AMODE *ap1);
extern void GeneratePredicatedDiadic(int pop, int pr, int op, int len, AMODE *ap1, AMODE *ap2);
// Gencode.c
extern AMODE *make_label(int lab);
extern AMODE *make_clabel(int lab);
extern AMODE *make_immed(int i);
extern AMODE *make_indirect(int i);
extern AMODE *make_offset(ENODE *node);
extern void swap_nodes(ENODE *node);
extern int isshort(ENODE *node);
// IdentifyKeyword.c
extern int IdentifyKeyword();
// Preproc.c
extern int preprocess();
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
extern AMODE *GetTempReg(int);
extern AMODE *GetTempRegister();
extern AMODE *GetTempBrRegister();
extern AMODE *GetTempFPRegister();
extern AMODE *GetTempVectorRegister();
extern AMODE *GetTempVectorMaskRegister();
extern void ReleaseTempRegister(AMODE *ap);
extern void ReleaseTempReg(AMODE *ap);
extern int TempInvalidate();
extern void TempRevalidate(int sp);
// Table888.c
extern void GenerateTable888Function(SYM *sym, Statement *stmt);
extern void GenerateTable888Return(SYM *sym, Statement *stmt);
extern AMODE *GenerateTable888FunctionCall(ENODE *node, int flags);
extern AMODE *GenTable888Set(ENODE *node);
// Raptor64.c
extern void GenerateRaptor64Function(SYM *sym, Statement *stmt);
extern void GenerateRaptor64Return(SYM *sym, Statement *stmt);
extern AMODE *GenerateRaptor64FunctionCall(ENODE *node, int flags);
extern AMODE *GenerateFunctionCall(ENODE *node, int flags);

extern void GenerateFunction(SYM *sym);
extern void GenerateReturn(Statement *stmt);

extern AMODE *GenerateShift(ENODE *node,int flags, int size, int op);
extern AMODE *GenerateAssignShift(ENODE *node,int flags,int size,int op);
extern AMODE *GenerateBitfieldDereference(ENODE *node, int flags, int size);
extern AMODE *GenerateBitfieldAssign(ENODE *node, int flags, int size);
// err.c
extern void fatal(char *str);

extern int tmpVarSpace();
extern void tmpFreeAll();
extern void tmpReset();
extern int tmpAlloc(int);
extern void tmpFree(int);

extern int GetReturnBlockSize();

enum e_sg { noseg, codeseg, dataseg, stackseg, bssseg, idataseg, tlsseg, rodataseg };


// TODO: reference additional headers your program requires here

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

/*
 *      this module contains all of the code generation routines
 *      for evaluating expressions and conditions.
 */

int hook_predreg=15;

AMODE *GenerateExpression();            /* forward ParseSpecifieraration */
extern AMODE *GenExprRaptor64(ENODE *node);

extern AMODE *copy_addr(AMODE *);
extern AMODE *GenExpr(ENODE *node);
extern AMODE *GenerateFunctionCall(ENODE *node, int flags);
extern void GenLdi(AMODE*,AMODE *);
extern void GenerateCmp(ENODE *node, int op, int label, int predreg, unsigned int prediction);

void GenerateRaptor64Cmp(ENODE *node, int op, int label, int predreg);
void GenerateTable888Cmp(ENODE *node, int op, int label, int predreg);
void GenerateThorCmp(ENODE *node, int op, int label, int predreg);
void GenLoad(AMODE *ap3, AMODE *ap1, int ssize, int size);
void GenerateZeroExtend(AMODE *ap, int isize, int osize);
void GenerateSignExtend(AMODE *ap, int isize, int osize, int flags);

extern int throwlab;
static int nest_level = 0;

static void Enter(char *p)
{
/*
     int nn;
     
     for (nn = 0; nn < nest_level; nn++)
         printf(" ");
     printf("%s: %d ", p, lineno);
     nest_level++;
*/
}
static void Leave(char *p, int n)
{
/*
     int nn;
     
     nest_level--;
     for (nn = 0; nn < nest_level; nn++)
         printf(" ");
     printf("%s (%d) ", p, n);
*/
}


static char fpsize(AMODE *ap1)
{
	if (ap1->FloatSize)
		return (ap1->FloatSize);
	if (ap1->offset==nullptr)
		return ('d');
	if (ap1->offset->tp==nullptr)
		return ('d');
	switch(ap1->offset->tp->precision) {
	case 32:	return ('s');
	case 64:	return ('d');
	case 96:	return ('t');
	case 128:	return ('q');
	default:	return ('t');
	}
}

static char fsize(ENODE *n)
{
	switch(n->etype) {
	case bt_float:	return ('d');
	case bt_double:	return ('d');
	case bt_triple:	return ('t');
	case bt_quad:	return ('q');
	default:	return ('d');
	}
}

/*
 *      construct a reference node for an internal label number.
 */
AMODE *make_label(int lab)
{
	ENODE *lnode;
	AMODE *ap;

	lnode = allocEnode();
	lnode->nodetype = en_labcon;
	lnode->i = lab;
	ap = allocAmode();
	ap->mode = am_direct;
	ap->offset = lnode;
	ap->isUnsigned = 1;
	return ap;
}

AMODE *make_clabel(int lab)
{
	ENODE *lnode;
    AMODE *ap;

    lnode = allocEnode();
    lnode->nodetype = en_clabcon;
    lnode->i = lab;
	if (lab==-1)
		printf("-1\r\n");
    ap = allocAmode();
    ap->mode = am_direct;
    ap->offset = lnode;
	ap->isUnsigned = 1;
    return ap;
}

AMODE *make_string(char *s)
{
	ENODE *lnode;
	AMODE *ap;

	lnode = allocEnode();
	lnode->nodetype = en_nacon;
	lnode->sp = new std::string(s);
	ap = allocAmode();
	ap->mode = am_direct;
	ap->offset = lnode;
	return ap;
}

/*
 *      make a node to reference an immediate value i.
 */
AMODE *make_immed(int i)
{
	AMODE *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_icon;
    ep->i = i;
    ap = allocAmode();
    ap->mode = am_immed;
    ap->offset = ep;
    return ap;
}

AMODE *make_indirect(int i)
{
	AMODE *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_uw_ref;
    ep->i = 0;
    ap = allocAmode();
	ap->mode = am_ind;
	ap->preg = i;
    ap->offset = 0;//ep;	//=0;
    return ap;
}

AMODE *make_indexed(int o, int i)
{
	AMODE *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_icon;
    ep->i = o;
    ap = allocAmode();
	ap->mode = am_indx;
	ap->preg = i;
    ap->offset = ep;
    return ap;
}

/*
 *      make a direct reference to a node.
 */
AMODE *make_offset(ENODE *node)
{
	AMODE *ap;
	ap = allocAmode();
	ap->mode = am_direct;
	ap->offset = node;
	return ap;
}
        
AMODE *make_indx(ENODE *node, int rg)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_indx;
    ap->offset = node;
    ap->preg = rg;
    return ap;
}

void GenerateHint(int num)
{
	GenerateMonadic(op_hint,0,make_immed(num));
}

// ----------------------------------------------------------------------------
//      MakeLegalAmode will coerce the addressing mode in ap1 into a
//      mode that is satisfactory for the flag word.
// ----------------------------------------------------------------------------
void MakeLegalAmode(AMODE *ap,int flags, int size)
{
	AMODE *ap2;
	int64_t i;

//     Enter("MkLegalAmode");
	if (ap==(AMODE*)NULL) return;
//	if (flags & F_NOVALUE) return;
    if( ((flags & 16) == 0) || ap->tempflag )
    {
        switch( ap->mode ) {
            case am_immed:
					i = ((ENODE *)(ap->offset))->i;
					if (flags & 256) {
						if (i < 256 && i >= 0)
							return;
					}
					else if (flags & 2048) {
						if (i < 64 && i >= 0)
							return;
					}
					else if (flags & 128) {
						if (i==0)
							return;
					}
                    else if( flags & 8 )
                        return;         /* mode ok */
                    break;
            case am_reg:
                    if( flags & 1 )
                        return;
                    break;
            case am_fpreg:
                    if( flags & 1024 )
                        return;
                    break;
            case am_ind:
			case am_indx:
            case am_indx2: 
			case am_direct:
			case am_indx3:
                    if( flags & 4 )
                        return;
                    break;
            }
        }

        if( flags & 1 )
        {
            ReleaseTempRegister(ap);      /* maybe we can use it... */
			if (ap)
				ap2 = GetTempReg(ap->type);
			else
				ap2 = GetTempReg(stdint.GetIndex());
			if (ap->mode == am_ind || ap->mode==am_indx)
                GenLoad(ap2,ap,size,size);
			else if (ap->mode==am_immed) {
			    GenerateDiadic(op_ldi,0,ap2,ap);
            }
			else {
				if (ap->mode==am_reg)
					GenerateDiadic(op_mov,0,ap2,ap);
				else
                    GenLoad(ap2,ap,size,size);
			}
            ap->mode = am_reg;
            ap->preg = ap2->preg;
            ap->deep = ap2->deep;
            ap->tempflag = 1;
            return;
        }
        if( flags & 1024 )
        {
            ReleaseTempReg(ap);      /* maybe we can use it... */
            ap2 = GetTempRegister();
			if (ap->mode == am_ind || ap->mode==am_indx)
                GenLoad(ap2,ap,size,size);
			else if (ap->mode==am_immed) {
			    GenerateDiadic(op_ldi,0,ap2,ap);
            }
			else {
				if (ap->mode==am_reg)
					GenerateDiadic(op_mov,0,ap2,ap);
				else
                    GenLoad(ap2,ap,size,size);
			}
            ap->mode = am_fpreg;
            ap->preg = ap2->preg;
            ap->deep = ap2->deep;
            ap->tempflag = 1;
            return;
        }
		// Here we wanted the mode to be non-register (memory/immed)
		// Should fix the following to place the result in memory and
		// not a register.
        if( size == 1 )
		{
			ReleaseTempRegister(ap);
			ap2 = GetTempRegister();
			GenerateDiadic(op_mov,0,ap2,ap);
			if (ap->isUnsigned)
				GenerateTriadic(op_and,0,ap2,ap2,make_immed(255));
			else {
				GenerateDiadic(op_sext8,0,ap2,ap2);
			}
			ap->mode = ap2->mode;
			ap->preg = ap2->preg;
			ap->deep = ap2->deep;
			size = 2;
        }
        ap2 = GetTempRegister();
		switch(ap->mode) {
		case am_ind:
		case am_indx:
            GenLoad(ap2,ap,size,size);
			break;
		case am_immed:
			GenerateDiadic(op_ldi,0,ap2,ap);
			break;
		case am_reg:
			GenerateDiadic(op_mov,0,ap2,ap);
			break;
		default:
            GenLoad(ap2,ap,size,size);
		}
    ap->mode = am_reg;
    ap->preg = ap2->preg;
    ap->deep = ap2->deep;
    ap->tempflag = 1;
//     Leave("MkLegalAmode",0);
}

void GenLoad(AMODE *ap3, AMODE *ap1, int ssize, int size)
{
	if (ap3->type==stdvector.GetIndex()) {
        GenerateDiadic(op_lv,0,ap3,ap1);
	}
    else if (ap3->isUnsigned) {
        switch(size) {
        case 1:	GenerateDiadic(op_lbu,0,ap3,ap1); break;
        case 2:	GenerateDiadic(op_lcu,0,ap3,ap1); break;
        case 4:	GenerateDiadic(op_lhu,0,ap3,ap1); break;
        case 8: GenerateDiadic(op_lw,0,ap3,ap1); break;
        }
    }
    else {
        switch(size) {
        case 1:	GenerateDiadic(op_lb,0,ap3,ap1); break;
        case 2:	GenerateDiadic(op_lc,0,ap3,ap1); break;
        case 4:	GenerateDiadic(op_lh,0,ap3,ap1); break;
        case 8:	GenerateDiadic(op_lw,0,ap3,ap1); break;
        }
    }
}

void GenStore(AMODE *ap1, AMODE *ap3, int size)
{
	if (ap1->type==stdvector.GetIndex())
	    GenerateDiadic(op_sv,0,ap1,ap3);
	else
		switch(size) {
		case 1: GenerateDiadic(op_sb,0,ap1,ap3); break;
		case 2: GenerateDiadic(op_sc,0,ap1,ap3); break;
		case 4: GenerateDiadic(op_sh,0,ap1,ap3); break;
		case 8: GenerateDiadic(op_sw,0,ap1,ap3); break;
		}
}

/*
 *      if isize is not equal to osize then the operand ap will be
 *      loaded into a register (if not already) and if osize is
 *      greater than isize it will be extended to match.
 */
void GenerateSignExtend(AMODE *ap, int isize, int osize, int flags)
{    
	AMODE *ap1;

	if( isize == osize )
        return;
	if (ap->isUnsigned)
		return;
    if(ap->mode != am_reg && ap->mode != am_fpreg) {
		ap1 = GetTempRegister();
		GenLoad(ap1,ap,isize,isize);
		switch( isize )
		{
		case 1:	Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(7)); break;
		case 2:	Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(15)); break;
		case 4:	Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(31)); break;
		}
		GenStore(ap1,ap,osize);
		ReleaseTempRegister(ap1);
		return;
        //MakeLegalAmode(ap,flags & (F_REG|F_FPREG),isize);
	}
	if (ap->type==stddouble.GetIndex()) {
		switch(isize) {
		case 4:	GenerateDiadic(op_fs2d,0,ap,ap); break;
		}
	}
	else {
			switch( isize )
			{
			case 1:	Generate4adic(op_bfext,0,ap,ap,make_immed(0),make_immed(7)); break;
			case 2:	Generate4adic(op_bfext,0,ap,ap,make_immed(0),make_immed(15)); break;
			case 4:	Generate4adic(op_bfext,0,ap,ap,make_immed(0),make_immed(31)); break;
			}
	}
}

void GenerateZeroExtend(AMODE *ap, int isize, int osize)
{    
    if(ap->mode != am_reg)
        MakeLegalAmode(ap,1,isize);
	switch( osize )
	{
	case 1:	GenerateTriadic(op_and,0,ap,ap,make_immed(0xFF)); break;
	case 2:	GenerateTriadic(op_and,0,ap,ap,make_immed(0xFFFF)); break;
	case 4:	GenerateTriadic(op_and,0,ap,ap,make_immed(0xFFFFFFFF)); break;
    }
}

/*
 *      return true if the node passed can be generated as a short
 *      offset.
 */
int isshort(ENODE *node)
{
	return node->nodetype == en_icon &&
        (node->i >= -32768 && node->i <= 32767);
}

/*
 *      return true if the node passed can be evaluated as a byte
 *      offset.
 */
int isbyte(ENODE *node)
{
	return node->nodetype == en_icon &&
       (-128 <= node->i && node->i <= 127);
}

int ischar(ENODE *node)
{
	return node->nodetype == en_icon &&
        (node->i >= -32768 && node->i <= 32767);
}

// ----------------------------------------------------------------------------
// Generate code to evaluate an index node (^+) and return the addressing mode
// of the result. This routine takes no flags since it always returns either
// am_ind or am_indx.
//
// No reason to ReleaseTempReg() because the registers used are transported
// forward.
// ----------------------------------------------------------------------------
AMODE *GenerateIndex(ENODE *node)
{       
	AMODE *ap1, *ap2;
	
    if( (node->p[0]->nodetype == en_tempref || node->p[0]->nodetype==en_regvar)
    	 && (node->p[1]->nodetype == en_tempref || node->p[1]->nodetype==en_regvar))
    {       /* both nodes are registers */
    	// Don't need to free ap2 here. It is included in ap1.
		GenerateHint(8);
        ap1 = GenerateExpression(node->p[0],1,8);
        ap2 = GenerateExpression(node->p[1],1,8);
		GenerateHint(9);
        ap1->mode = am_indx2;
        ap1->sreg = ap2->preg;
		ap1->deep2 = ap2->deep2;
		ap1->offset = makeinode(en_icon,0);
		ap1->scale = node->scale;
        return (ap1);
    }
	GenerateHint(8);
    ap1 = GenerateExpression(node->p[0],1 | 8,8);
    if( ap1->mode == am_immed )
    {
		ap2 = GenerateExpression(node->p[1],1,8);
		GenerateHint(9);
		ap2->mode = am_indx;
		ap2->offset = ap1->offset;
		ap2->isUnsigned = ap1->isUnsigned;
		return ap2;
    }
    ap2 = GenerateExpression(node->p[1],(15|1024|8192|16384),8);   /* get right op */
	GenerateHint(9);
    if( ap2->mode == am_immed && ap1->mode == am_reg ) /* make am_indx */
    {
        ap2->mode = am_indx;
        ap2->preg = ap1->preg;
        ap2->deep = ap1->deep;
        return ap2;
    }
	if (ap2->mode == am_ind && ap1->mode == am_reg) {
        ap2->mode = am_indx2;
        ap2->sreg = ap1->preg;
		ap2->deep2 = ap1->deep;
        return ap2;
	}
	if (ap2->mode == am_direct && ap1->mode==am_reg) {
        ap2->mode = am_indx;
        ap2->preg = ap1->preg;
        ap2->deep = ap1->deep;
        return ap2;
    }
	// ap1->mode must be F_REG
	MakeLegalAmode(ap2,1,8);
    ap1->mode = am_indx2;            /* make indexed */
	ap1->sreg = ap2->preg;
	ap1->deep2 = ap2->deep;
	ap1->offset = makeinode(en_icon,0);
	ap1->scale = node->scale;
    return ap1;                     /* return indexed */
}

long GetReferenceSize(ENODE *node)
{
    switch( node->nodetype )        /* get load size */
    {
    case en_b_ref:
    case en_ub_ref:
    case en_bfieldref:
    case en_ubfieldref:
            return 1;
	case en_c_ref:
	case en_uc_ref:
	case en_cfieldref:
	case en_ucfieldref:
			return 2;
	case en_ref32:
	case en_ref32u:
			return 4;
	case en_h_ref:
	case en_uh_ref:
	case en_hfieldref:
	case en_uhfieldref:
			return sizeOfWord/2;
    case en_w_ref:
	case en_uw_ref:
    case en_wfieldref:
	case en_uwfieldref:
            return sizeOfWord;
	case en_tempref:
	case en_fpregvar:
	case en_regvar:
            return sizeOfWord;
	case en_dbl_ref:
            return sizeOfFPD;
	case en_quad_ref:
			return sizeOfFPQ;
	case en_flt_ref:
			return sizeOfFPD;
    case en_triple_ref:
            return sizeOfFPT;
	case en_struct_ref:
            return sizeOfPtr;
	case en_vector_ref:
			return 512;
//			return node->esize;
    }
	return 8;
}

//
//  Return the addressing mode of a dereferenced node.
//
AMODE *GenerateDereference(ENODE *node,int flags,int size, int su)
{    
	AMODE *ap1;
    int siz1;

    Enter("Genderef");
	siz1 = GetReferenceSize(node);
	// When dereferencing a struct or union return a pointer to the struct or
	// union.
//	if (node->tp->type==bt_struct || node->tp->type==bt_union) {
//        return GenerateExpression(node,F_REG|F_MEM,size);
//    }
    if( node->p[0]->nodetype == en_add )
    {
//        ap2 = GetTempRegister();
        ap1 = GenerateIndex(node->p[0]);
//        GenerateTriadic(op_add,0,ap2,makereg(ap1->preg),makereg(regGP));
		ap1->isUnsigned = !su;//node->isUnsigned;
		// *** may have to fix for stackseg
		ap1->segment = dataseg;
//		ap2->mode = ap1->mode;
//		ap2->segment = dataseg;
//		ap2->offset = ap1->offset;
//		ReleaseTempRegister(ap1);
		if (!node->isUnsigned)
			GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autocon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regBP;
		ap1->segment = stackseg;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_classcon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regCLP;
		ap1->segment = dataseg;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autofcon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regBP;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 32: ap1->FloatSize = 's'; break;
			case 64: ap1->FloatSize = 'd'; break;
			default: ap1->FloatSize = 'd'; break;
			}
		else
			ap1->FloatSize = 'd';
		ap1->segment = stackseg;
		ap1->type = stddouble.GetIndex();
//	    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autovcon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regBP;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 32: ap1->FloatSize = 's'; break;
			case 64: ap1->FloatSize = 'd'; break;
			default: ap1->FloatSize = 'd'; break;
			}
		else
			ap1->FloatSize = 'd';
		ap1->segment = stackseg;
		ap1->type = stdvector.GetIndex();
		//	    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autovmcon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regBP;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 32: ap1->FloatSize = 's'; break;
			case 64: ap1->FloatSize = 'd'; break;
			default: ap1->FloatSize = 'd'; break;
			}
		else
			ap1->FloatSize = 'd';
		ap1->segment = stackseg;
		ap1->type = stdvectormask->GetIndex();
		//	    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if(( node->p[0]->nodetype == en_labcon || node->p[0]->nodetype==en_nacon ) && use_gp)
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regGP;
		ap1->segment = dataseg;
        ap1->offset = node->p[0];//makeinode(en_icon,node->p[0]->i);
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        ap1->isVolatile = node->isVolatile;
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
	else if (node->p[0]->nodetype == en_regvar) {
        ap1 = allocAmode();
		// For parameters we want Rn, for others [Rn]
		// This seems like an error earlier in the compiler
		// See setting val_flag in ParseExpressions
		ap1->mode = node->p[0]->i < 18 ? am_ind : am_reg;
//		ap1->mode = node->p[0]->tp->val_flag ? am_reg : am_ind;
		ap1->preg = node->p[0]->i;
        MakeLegalAmode(ap1,flags,size);
	    Leave("Genderef",3);
        return ap1;
	}
	else if (node->p[0]->nodetype == en_fpregvar) {
		//error(ERR_DEREF);
        ap1 = allocAmode();
		ap1->mode = node->p[0]->i < 18 ? am_ind : am_fpreg;
		ap1->preg = node->p[0]->i;
		ap1->type = stddouble.GetIndex();
        MakeLegalAmode(ap1,flags,size);
	    Leave("Genderef",3);
        return ap1;
	}
	else if (node->p[0]->nodetype == en_vex) {
		AMODE *ap2;
		if (node->p[0]->p[0]->nodetype==en_vector_ref) {
			ap1 = GenerateDereference(node->p[0]->p[0],1,8,0);
			ap2 = GenerateExpression(node->p[0]->p[1],1,8);
			if (ap1->offset && ap2->offset) {
				GenerateTriadic(op_add,0,ap1,makereg(0),make_immed(ap2->offset->i));
			}
			ReleaseTempReg(ap2);
			//ap1->mode = node->p[0]->i < 18 ? am_ind : am_reg;
			//ap1->preg = node->p[0]->i;
			ap1->type = stdvector.GetIndex();
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		}
	}
    ap1 = GenerateExpression(node->p[0],1 | 8,8); /* generate address */
    if( ap1->mode == am_reg || ap1->mode==am_fpreg)
    {
//        ap1->mode = am_ind;
          if (use_gp) {
              ap1->mode = am_indx;
              ap1->sreg = regGP;
          }
          else
             ap1->mode = am_ind;
		  if (node->p[0]->constflag==1)
			  ap1->offset = node->p[0];
		  else
			ap1->offset = nullptr;	// ****
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        ap1->isVolatile = node->isVolatile;
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    if( ap1->mode == am_fpreg )
    {
//        ap1->mode = am_ind;
          if (use_gp) {
              ap1->mode = am_indx;
              ap1->sreg = regGP;
          }
          else
             ap1->mode = am_ind;
		ap1->offset = 0;	// ****
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
	// See segments notes
	//if (node->p[0]->nodetype == en_labcon &&
	//	node->p[0]->etype == bt_pointer && node->p[0]->constflag)
	//	ap1->segment = codeseg;
	//else
	//	ap1->segment = dataseg;
    if (use_gp) {
        ap1->mode = am_indx;
        ap1->preg = regGP;
    	ap1->segment = dataseg;
    }
    else {
        ap1->mode = am_direct;
	    ap1->isUnsigned = !su;
    }
//    ap1->offset = makeinode(en_icon,node->p[0]->i);
    ap1->isUnsigned = !su;
	if (!node->isUnsigned)
	    GenerateSignExtend(ap1,siz1,size,flags);
	else
		MakeLegalAmode(ap1,flags,siz1);
    ap1->isVolatile = node->isVolatile;
    MakeLegalAmode(ap1,flags,size);
xit:
    Leave("Genderef",0);
    return ap1;
}

//
// Generate code to evaluate a unary minus or complement.
//
AMODE *GenerateUnary(ENODE *node,int flags, int size, int op)
{
	AMODE *ap, *ap2;

	if (node->etype==bt_double || node->etype==bt_quad || node->etype==bt_float || node->etype==bt_triple) {
        ap2 = GetTempRegister();
        ap = GenerateExpression(node->p[0],1,size);
        if (op==op_neg)
           op=op_fneg;
	    GenerateDiadic(op,fsize(node),ap2,ap);
    }
	else if (node->etype==bt_vector) {
        ap2 = GetTempVectorRegister();
        ap = GenerateExpression(node->p[0],1,size);
	    GenerateDiadic(op,0,ap2,ap);
	}
    else {
        ap2 = GetTempRegister();
        ap = GenerateExpression(node->p[0],1,size);
	    GenerateDiadic(op,0,ap2,ap);
    }
    ReleaseTempReg(ap);
    MakeLegalAmode(ap2,flags,size);
    return ap2;
}

// Generate code for a binary expression

AMODE *GenerateBinary(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3, *ap4;
	
	if (op==op_fadd || op==op_fsub || op==op_fmul || op==op_fdiv ||
        op==op_fdadd || op==op_fdsub || op==op_fdmul || op==op_fddiv ||
	    op==op_fsadd || op==op_fssub || op==op_fsmul || op==op_fsdiv)
	{
   		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],1,size);
		ap2 = GenerateExpression(node->p[1],1,size);
		// Generate a convert operation ?
		if (fpsize(ap1) != fpsize(ap2)) {
			if (fpsize(ap2)=='s')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
	    GenerateTriadic(op,fpsize(ap1),ap3,ap1,ap2);
	}
	else if (op==op_vadd || op==op_vsub || op==op_vmul || op==op_vdiv
		|| op==op_vadds || op==op_vsubs || op==op_vmuls || op==op_vdivs
		|| op==op_veins) {
   		ap3 = GetTempVectorRegister();
		if (equalnode(node->p[0],node->p[1]) && !opt_nocgo) {
			ap1 = GenerateExpression(node->p[0],1,size);
			ap2 = GenerateExpression(node->vmask,16384,size);
		    Generate4adic(op,0,ap3,ap1,ap1,ap2);
			ReleaseTempReg(ap2);
			ap2 = nullptr;
		}
		else {
			ap1 = GenerateExpression(node->p[0],8192,size);
			ap2 = GenerateExpression(node->p[1],8192,size);
			ap4 = GenerateExpression(node->vmask,16384,size);
		    Generate4adic(op,0,ap3,ap1,ap2,ap4);
			ReleaseTempReg(ap4);
		}
		// Generate a convert operation ?
		//if (fpsize(ap1) != fpsize(ap2)) {
		//	if (fpsize(ap2)=='s')
		//		GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		//}
	}
	else if (op==op_vex) {
   		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],1,size);
		ap2 = GenerateExpression(node->p[1],1,size);
	    GenerateTriadic(op,0,ap3,ap1,ap2);
	}
	else {
   		ap3 = GetTempRegister();
		if (equalnode(node->p[0],node->p[1]) && !opt_nocgo) {
			ap1 = GenerateExpression(node->p[0],1,size);
			ap2 = nullptr;
		    GenerateTriadic(op,0,ap3,ap1,ap1);
		}
		else {
			ap1 = GenerateExpression(node->p[0],1,size);
			ap2 = GenerateExpression(node->p[1],1|8,size);
		    GenerateTriadic(op,0,ap3,ap1,ap2);
		}
	}
	if (ap2)
		ReleaseTempReg(ap2);
    ReleaseTempReg(ap1);
    MakeLegalAmode(ap3,flags,size);
    return ap3;
}

/*
 *      generate code to evaluate a mod operator or a divide
 *      operator.
 */
AMODE *GenerateModDiv(ENODE *node,int flags,int size, int op)
{
	AMODE *ap1, *ap2, *ap3;

	if( node->p[0]->nodetype == en_icon ) //???
		swap_nodes(node);
	if (op==op_fdiv) {
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],1,8);
		ap2 = GenerateExpression(node->p[1],1,8);
	}
	else {
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],1,8);
		ap2 = GenerateExpression(node->p[1],1 | 8,8);
	}
	if (op==op_fdiv) {
		// Generate a convert operation ?
		if (fpsize(ap1) != fpsize(ap2)) {
			if (fpsize(ap2)=='s')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
	    GenerateTriadic(op,fpsize(ap1),ap3,ap1,ap2);
	}
	else
		GenerateTriadic(op,0,ap3,ap1,ap2);
//    GenerateDiadic(op_ext,0,ap3,0);
  MakeLegalAmode(ap3,flags,2);
  ReleaseTempReg(ap2);
  ReleaseTempReg(ap1);
  return ap3;
}

/*
 *      exchange the two operands in a node.
 */
void swap_nodes(ENODE *node)
{
	ENODE *temp;
    temp = node->p[0];
    node->p[0] = node->p[1];
    node->p[1] = temp;
}

/*
 *      generate code to evaluate a multiply node. 
 */
AMODE *GenerateMultiply(ENODE *node, int flags, int size, int op)
{       
	AMODE *ap1, *ap2, *ap3;
  Enter("Genmul");
    if( node->p[0]->nodetype == en_icon )
        swap_nodes(node);
    if (op==op_fmul) {
        ap3 = GetTempRegister();
        ap1 = GenerateExpression(node->p[0],1,8);
        ap2 = GenerateExpression(node->p[1],1,8);
    }
    else {
        ap3 = GetTempRegister();
        ap1 = GenerateExpression(node->p[0],1,8);
        ap2 = GenerateExpression(node->p[1],1 | 8,8);
    }
	if (op==op_fmul) {
		// Generate a convert operation ?
		if (fpsize(ap1) != fpsize(ap2)) {
			if (fpsize(ap2)=='s')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
	    GenerateTriadic(op,fpsize(ap1),ap3,ap1,ap2);
	}
	else
		GenerateTriadic(op,0,ap3,ap1,ap2);
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
	MakeLegalAmode(ap3,flags,2);
	Leave("Genmul",0);
	return ap3;
}

//
// Generate code to evaluate a condition operator node (?:)
//
AMODE *GenerateHook(ENODE *node,int flags, int size)
{
	AMODE *ap1, *ap2;
    int false_label, end_label;
	struct ocode *ip1;
	int n1;

    false_label = nextlabel++;
    end_label = nextlabel++;
    flags = (flags & 1) | 16;
/*
    if (node->p[0]->constflag && node->p[1]->constflag) {
    	GeneratePredicateMonadic(hook_predreg,op_op_ldi,make_immed(node->p[0]->i));
    	GeneratePredicateMonadic(hook_predreg,op_ldi,make_immed(node->p[0]->i));
	}
*/
	ip1 = peep_tail;
	ap2 = GenerateExpression(node->p[1]->p[1],flags,size);
	n1 = PeepCount(ip1);
	if (opt_nocgo)
		n1 = 9999;
	if (n1 > 4) {
		peep_tail = ip1;
		peep_tail->fwd = nullptr;
	}
    GenerateFalseJump(node->p[0],false_label,0);
    node = node->p[1];
    ap1 = GenerateExpression(node->p[0],flags,size);
	if (n1 > 4)
		GenerateDiadic(op_bra,0,make_clabel(end_label),0);
	else {
		if( !equal_address(ap1,ap2) )
		{
			GenerateMonadic(op_hint,0,make_immed(2));
			GenerateDiadic(op_mov,0,ap2,ap1);
		}
	}
    GenerateLabel(false_label);
	if (n1 > 4) {
		ap2 = GenerateExpression(node->p[1],flags,size);
		if( !equal_address(ap1,ap2) )
		{
			GenerateMonadic(op_hint,0,make_immed(2));
			GenerateDiadic(op_mov,0,ap1,ap2);
		}
	}
	if (n1 > 4) {
		ReleaseTempReg(ap2);
		GenerateLabel(end_label);
		return (ap1);
	}
	else {
		ReleaseTempReg(ap1);
		GenerateLabel(end_label);
		return (ap2);
	}
}

void GenMemop(int op, AMODE *ap1, AMODE *ap2, int ssize)
{
	AMODE *ap3;

	if (ap1->type==stddouble.GetIndex()) {
     	ap3 = GetTempRegister();
		GenLoad(ap3,ap1,ssize,ssize);
		GenerateTriadic(op,ap1->FloatSize,ap3,ap3,ap2);
		GenStore(ap3,ap1,ssize);
		ReleaseTempReg(ap3);
		return;
	}
	else if (ap1->type==stdvector.GetIndex()) {
   		ap3 = GetTempVectorRegister();
		GenLoad(ap3,ap1,ssize,ssize);
		GenerateTriadic(op,0,ap3,ap3,ap2);
		GenStore(ap3,ap1,ssize);
		ReleaseTempReg(ap3);
		return;
	}
	//if (ap1->mode != am_indx2) {
	//	if (op==op_add && ap2->mode==am_immed && ap2->offset->i >= -16 && ap2->offset->i < 16 && ssize==2) {
	//		GenerateDiadic(op_inc,0,ap1,ap2);
	//		return;
	//	}
	//	if (op==op_sub && ap2->mode==am_immed && ap2->offset->i >= -15 && ap2->offset->i < 15 && ssize==2) {
	//		GenerateDiadic(op_dec,0,ap1,ap2);
	//		return;
	//	}
	//}
   	ap3 = GetTempRegister();
    GenLoad(ap3,ap1,ssize,ssize);
	GenerateTriadic(op,0,ap3,ap3,ap2);
	GenStore(ap3,ap1,ssize);
	ReleaseTempReg(ap3);
}

AMODE *GenerateAssignAdd(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2;
    int ssize;
	bool negf = false;

    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
    if (node->etype==bt_double || node->etype==bt_quad || node->etype==bt_float||node->etype==bt_triple) {
        ap1 = GenerateExpression(node->p[0],1|4,ssize);
        ap2 = GenerateExpression(node->p[1],1,size);
        if (op==op_add)
           op = op_fadd;
        else if (op==op_sub)
           op = op_fsub;
    }
    else if (node->etype==bt_vector) {
        ap1 = GenerateExpression(node->p[0],1|4,ssize);
        ap2 = GenerateExpression(node->p[1],1,size);
        if (op==op_add)
           op = op_vadd;
        else if (op==op_sub)
           op = op_vsub;
    }
    else {
        ap1 = GenerateExpression(node->p[0],(15|1024|8192|16384),ssize);
        ap2 = GenerateExpression(node->p[1],1 | 8,size);
    }
	if (ap1->mode==am_reg) {
	    GenerateTriadic(op,0,ap1,ap1,ap2);
	}
	else if (ap1->mode==am_fpreg) {
	    GenerateTriadic(op,fpsize(ap1),ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
	    MakeLegalAmode(ap1,flags,size);
		return (ap1);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
    ReleaseTempReg(ap2);
	if (ap1->type!=stddouble.GetIndex() && !ap1->isUnsigned)
		GenerateSignExtend(ap1,ssize,size,flags);
    MakeLegalAmode(ap1,flags,size);
    return ap1;
}

AMODE *GenerateAssignLogic(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2;
    int             ssize;
    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
    ap1 = GenerateExpression(node->p[0],(15|1024|8192|16384),ssize);
    ap2 = GenerateExpression(node->p[1],1 | 8,size);
	if (ap1->mode==am_reg) {
	    GenerateTriadic(op,0,ap1,ap1,ap2);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
    ReleaseTempRegister(ap2);
	if (!ap1->isUnsigned)
		GenerateSignExtend(ap1,ssize,size,flags);
    MakeLegalAmode(ap1,flags,size);
    return ap1;
}

//
//      generate a *= node.
//
AMODE *GenerateAssignMultiply(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2;
    int             ssize;
    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
    if (node->etype==bt_double || node->etype==bt_quad || node->etype==bt_float || node->etype==bt_triple) {
        ap1 = GenerateExpression(node->p[0],1 | 4,ssize);
        ap2 = GenerateExpression(node->p[1],1,size);
        op = op_fmul;
    }
    else if (node->etype==bt_vector) {
        ap1 = GenerateExpression(node->p[0],1 | 4,ssize);
        ap2 = GenerateExpression(node->p[1],1,size);
		op = ap2->type==stdvector.GetIndex() ? op_vmul : op_vmuls;
    }
    else {
        ap1 = GenerateExpression(node->p[0],(15|1024|8192|16384) & ~8,ssize);
        ap2 = GenerateExpression(node->p[1],1 | 8,size);
    }
	if (ap1->mode==am_reg) {
	    GenerateTriadic(op,0,ap1,ap1,ap2);
	}
	else if (ap1->mode==am_fpreg) {
	    GenerateTriadic(op,ssize==4?'s':ssize==8?'d':ssize==12?'t':ssize==16 ? 'q' : 'd',ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
	    MakeLegalAmode(ap1,flags,size);
		return ap1;
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
    ReleaseTempReg(ap2);
    GenerateSignExtend(ap1,ssize,size,flags);
    MakeLegalAmode(ap1,flags,size);
    return ap1;
}

/*
 *      generate /= and %= nodes.
 */
AMODE *GenerateAssignModiv(ENODE *node,int flags,int size,int op)
{
	AMODE *ap1, *ap2, *ap3;
    int             siz1;
    int isFP;
 
    siz1 = GetNaturalSize(node->p[0]);
    isFP = node->etype==bt_double || node->etype==bt_float || node->etype==bt_triple || node->etype==bt_quad;
    if (isFP) {
        if (op==op_div || op==op_divu)
           op = op_fdiv;
        ap1 = GenerateExpression(node->p[0],1,siz1);
        ap2 = GenerateExpression(node->p[1],1,size);
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
		MakeLegalAmode(ap1,flags,size);
	    return ap1;
//        else if (op==op_mod || op==op_modu)
//           op = op_fdmod;
    }
    else {
        ap1 = GetTempRegister();
        ap2 = GenerateExpression(node->p[0],(15|1024|8192|16384) & ~8,siz1);
    }
	if (ap2->mode==am_reg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov,0,ap1,ap2);
	else if (ap2->mode==am_fpreg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov,0,ap1,ap2);
	else
        GenLoad(ap1,ap2,siz1,siz1);
    //GenerateSignExtend(ap1,siz1,2,flags);
    if (isFP)
        ap3 = GenerateExpression(node->p[1],1,8);
    else
        ap3 = GenerateExpression(node->p[1],1|8,8);
	if (op==op_fdiv) {
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap3);
	}
	else
		GenerateTriadic(op,0,ap1,ap1,ap3);
    ReleaseTempReg(ap3);
    //GenerateDiadic(op_ext,0,ap1,0);
	if (ap2->mode==am_reg)
		GenerateDiadic(op_mov,0,ap2,ap1);
	else if (ap2->mode==am_fpreg)
		GenerateDiadic(op_mov,0,ap2,ap1);
	else
	    GenStore(ap1,ap2,siz1);
    ReleaseTempReg(ap2);
	if (!isFP)
		MakeLegalAmode(ap1,flags,size);
    return ap1;
}

// The problem is there are two trees of information. The LHS and the RHS.
// The RHS is a tree of nodes containing expressions and data to load.
// The nodes in the RHS have to be matched up against the structure elements
// of the target LHS.

// This little bit of code is dead code. But it might be useful to match
// the expression trees at some point.

ENODE *BuildEnodeTree(TYP *tp)
{
	ENODE *ep1, *ep2, *ep3;
	SYM *thead, *first;

	first = thead = SYM::GetPtr(tp->lst.GetHead());
	ep1 = ep2 = nullptr;
	while (thead) {
		if (thead->tp->IsStructType()) {
			ep3 = BuildEnodeTree(thead->tp);
		}
		else
			ep3 = nullptr;
		ep1 = makenode(en_void, ep2, ep1);
		ep1->SetType(thead->tp);
		ep1->p[2] = ep3;
		thead = SYM::GetPtr(thead->next);
	}
	return ep1;
}

// This little bit of code a debugging aid.
// Dumps the expression nodes associated with an aggregate assignment.

void DumpStructEnodes(ENODE *node)
{
	ENODE *head;
	TYP *tp;

	lfs.printf("{");
	head = node;
	while (head) {
		tp = head->tp;
		if (tp)
			tp->put_ty();
		if (head->nodetype==en_aggregate) {
			DumpStructEnodes(head->p[0]);
		}
		if (head->nodetype==en_icon)
			lfs.printf("%d", head->i);
		head = head->p[2];
	}
	lfs.printf("}");
}

AMODE *GenerateAssign(ENODE *node, int flags, int size);

// Generate an assignment to a structure type. The type passed must be a
// structure type.

void GenerateStructAssign(TYP *tp, int offset, ENODE *ep, AMODE *base)
{
	SYM *thead, *first;
	AMODE *ap1, *ap2;
	int offset2;

	first = thead = SYM::GetPtr(tp->lst.GetHead());
	ep = ep->p[0];
	while (thead) {
		if (ep == nullptr)
			break;
		if (thead->tp->IsAggregateType()) {
			if (ep->p[2])
				GenerateStructAssign(thead->tp, offset, ep->p[2], base);
		}
		else {
			ap2 = nullptr;
			if (ep->p[2]==nullptr)
				break;
			ap1 = GenerateExpression(ep->p[2],1,thead->tp->size);
			if (ap1->mode==am_immed) {
				ap2 = GetTempRegister();
				GenLdi(ap2,ap1);
			}
			else {
				ap2 = ap1;
				ap1 = nullptr;
			}
			if (base->offset)
				offset2 = base->offset->i + offset;
			else
				offset2 = offset;
			switch(thead->tp->size)
			{
			case 1:	GenerateDiadic(op_sb,0,ap2,make_indexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_sc,0,ap2,make_indexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_sh,0,ap2,make_indexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,make_indexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sw,0,ap2,make_indexed(offset,base->preg)); break;
			}
			if (ap2)
				ReleaseTempReg(ap2);
			if (ap1)
				ReleaseTempReg(ap1);
		}
		if (!thead->tp->IsUnion())
			offset += thead->tp->size;
		thead = SYM::GetPtr(thead->next);
		ep = ep->p[2];
	}
	if (!thead && ep)
		error(58);
}


AMODE *GenerateAggregateAssign(ENODE *node1, ENODE *node2);

// Generate an assignment to an array.

void GenerateArrayAssign(TYP *tp, ENODE *node1, ENODE *node2, AMODE *base)
{
	ENODE *ep1;
	AMODE *ap1, *ap2;
	int size = tp->size;
	int offset, offset2;

	offset = 0;
	if (node1->tp)
		tp = node1->tp->GetBtp();
	else
		tp = nullptr;
	if (tp==nullptr)
		tp = &stdlong;
	if (tp->IsStructType()) {
		ep1 = nullptr;
		ep1 = node2->p[0];
		while (ep1 && offset < size) {
			GenerateStructAssign(tp, offset, ep1->p[2], base);
			if (!tp->IsUnion())
				offset += tp->size;
			ep1 = ep1->p[2];
		}
	}
	else if (tp->IsAggregateType()){
		GenerateAggregateAssign(node1->p[0],node2->p[0]);
	}
	else {
		ep1 = node2->p[0];
		offset = 0;
		if (base->offset)
			offset = base->offset->i;
		ep1 = ep1->p[2];
		while (ep1) {
			ap1 = GenerateExpression(ep1,1|8,sizeOfWord);
			ap2 = GetTempRegister();
			if (ap1->mode==am_immed)
				GenLdi(ap2,ap1);
			else {
				if (ap1->offset)
					offset2 = ap1->offset->i;
				else
					offset2 = 0;
				GenerateDiadic(op_mov,0,ap2,ap1);
			}
			switch(tp->GetElementSize())
			{
			case 1:	GenerateDiadic(op_sb,0,ap2,make_indexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_sc,0,ap2,make_indexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_sh,0,ap2,make_indexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,make_indexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sw,0,ap2,make_indexed(offset,base->preg)); break;
			}
			offset += tp->GetElementSize();
			ReleaseTempReg(ap2);
			ReleaseTempReg(ap1);
			ep1 = ep1->p[2];
		}
	}
}

AMODE *GenerateAggregateAssign(ENODE *node1, ENODE *node2)
{
	ENODE *ep1, *ep2;
	AMODE *ap1, *ap2, *ap3, *base;
	SYM *thead, *first, *thead2, *first2;
	TYP *tp;
	int offset = 0;

	if (node1==nullptr || node2==nullptr)
		return nullptr;
	//DumpStructEnodes(node2);
	base = GenerateExpression(node1,4,sizeOfWord);
	//base = GenerateDereference(node1,F_MEM,sizeOfWord,0);
	tp = node1->tp;
	if (tp==nullptr)
		tp = &stdlong;
	if (tp->IsStructType()) {
		if (base->offset)
			offset = base->offset->i;
		else
			offset = 0;
		GenerateStructAssign(tp,offset,node2->p[0],base);
		//GenerateStructAssign(tp,offset2,node2->p[0]->p[0],base);
	}
	// Process Array
	else {
		GenerateArrayAssign(tp, node1, node2, base);
	}
	return base;
}


// ----------------------------------------------------------------------------
// Generate code for an assignment node. If the size of the assignment
// destination is larger than the size passed then everything below this node
// will be evaluated with the assignment size.
// ----------------------------------------------------------------------------
AMODE *GenerateAssign(ENODE *node, int flags, int size)
{
	AMODE *ap1, *ap2 ,*ap3;
	TYP *tp;
    int ssize;

    Enter("GenAssign");

    if (node->p[0]->nodetype == en_uwfieldref ||
		node->p[0]->nodetype == en_wfieldref ||
		node->p[0]->nodetype == en_uhfieldref ||
		node->p[0]->nodetype == en_hfieldref ||
		node->p[0]->nodetype == en_ucfieldref ||
		node->p[0]->nodetype == en_cfieldref ||
		node->p[0]->nodetype == en_ubfieldref ||
		node->p[0]->nodetype == en_bfieldref) {

      Leave("GenAssign",0);
		return GenerateBitfieldAssign(node, flags, size);
    }

	ssize = GetReferenceSize(node->p[0]);
//	if( ssize > size )
//			size = ssize;
/*
    if (node->tp->type==bt_struct || node->tp->type==bt_union) {
		ap1 = GenerateExpression(node->p[0],F_REG,ssize);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateMonadic(op_push,0,make_immed(node->tp->size));
		GenerateMonadic(op_push,0,ap2);
		GenerateMonadic(op_push,0,ap1);
		GenerateMonadic(op_bsr,0,make_string("memcpy_"));
		GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(24));
		ReleaseTempReg(ap2);
		return ap1;
    }
*/
	tp = node->p[0]->tp;
	if (tp) {
		if (node->p[0]->tp->IsAggregateType() || node->p[1]->nodetype==en_list || node->p[1]->nodetype==en_aggregate)
			return GenerateAggregateAssign(node->p[0],node->p[1]);
	}
	//if (size > 8) {
	//	ap1 = GenerateExpression(node->p[0],F_MEM,ssize);
	//	ap2 = GenerateExpression(node->p[1],F_MEM,size);
	//}
	//else {
		ap1 = GenerateExpression(node->p[0],1|1024|4|8192|16384,ssize);
  		ap2 = GenerateExpression(node->p[1],(15|1024|8192|16384),size);
		if (node->p[0]->isUnsigned && !node->p[1]->isUnsigned)
		    GenerateZeroExtend(ap2,size,ssize);
//	}
	if (ap1->mode == am_reg || ap1->mode==am_fpreg) {
		if (ap2->mode==am_reg) {
			GenerateHint(2);
			GenerateDiadic(op_mov,0,ap1,ap2);
		}
		else if (ap2->mode==am_immed) {
			GenerateDiadic(op_ldi,0,ap1,ap2);
		}
		else {
			GenLoad(ap1,ap2,ssize,size);
		}
	}
	else if (ap1->mode == am_vreg) {
		if (ap2->mode==am_vreg) {
			GenerateDiadic(op_mov,0,ap1,ap2);
		}
		else
			GenLoad(ap1,ap2,ssize,size);
	}
	// ap1 is memory
	else {
		if (ap2->mode == am_reg || ap2->mode == am_fpreg) {
		    GenStore(ap2,ap1,ssize);
        }
		else if (ap2->mode == am_immed) {
            if (ap2->offset->i == 0 && ap2->offset->nodetype != en_labcon) {
                GenStore(makereg(0),ap1,ssize);
            }
            else {
    			ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				GenStore(ap3,ap1,ssize);
		    	ReleaseTempReg(ap3);
          }
		}
		else {
//			if (ap1->isFloat)
//				ap3 = GetTempRegister();
//			else
				ap3 = GetTempRegister();
			// Generate a memory to memory move (struct assignments)
			if (ssize > 8) {
				if (ap1->type==stdvector.GetIndex() && ap2->type==stdvector.GetIndex()) {
					if (ap2->mode==am_reg)
						GenStore(ap2,ap1,ssize);
					else {
						ap3 = GetTempVectorRegister();
						GenLoad(ap3,ap2,ssize,ssize);
						GenStore(ap3,ap1,ssize);
						ReleaseTempRegister(ap3);
					}
				}
				else {
					ap3 = GetTempRegister();
					GenerateDiadic(op_ldi,0,ap3,make_immed(size));
					GenerateTriadic(op_push,0,ap3,ap2,ap1);
					GenerateDiadic(op_jal,0,makereg(regLR),make_string("memcpy_"));
					GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(24));
					ReleaseTempRegister(ap3);
				}
			}
			else {
                GenLoad(ap3,ap2,ssize,size);
/*                
				if (ap1->isUnsigned) {
					switch(size) {
					case 1:	GenerateDiadic(op_lbu,0,ap3,ap2); break;
					case 2:	GenerateDiadic(op_lcu,0,ap3,ap2); break;
					case 4: GenerateDiadic(op_lhu,0,ap3,ap2); break;
					case 8:	GenerateDiadic(op_lw,0,ap3,ap2); break;
					}
				}
				else {
					switch(size) {
					case 1:	GenerateDiadic(op_lb,0,ap3,ap2); break;
					case 2:	GenerateDiadic(op_lc,0,ap3,ap2); break;
					case 4: GenerateDiadic(op_lh,0,ap3,ap2); break;
					case 8:	GenerateDiadic(op_lw,0,ap3,ap2); break;
					}
					if (ssize > size) {
						switch(size) {
						case 1:	GenerateDiadic(op_sxb,0,ap3,ap3); break;
						case 2:	GenerateDiadic(op_sxc,0,ap3,ap3); break;
						case 4: GenerateDiadic(op_sxh,0,ap3,ap3); break;
						}
					}
				}
*/
				GenStore(ap3,ap1,ssize);
				ReleaseTempRegister(ap3);
			}
		}
	}
/*
	if (ap1->mode == am_reg) {
		if (ap2->mode==am_immed)	// must be zero
			GenerateDiadic(op_mov,0,ap1,makereg(0));
		else
			GenerateDiadic(op_mov,0,ap1,ap2);
	}
	else {
		if (ap2->mode==am_immed)
		switch(size) {
		case 1:	GenerateDiadic(op_sb,0,makereg(0),ap1); break;
		case 2:	GenerateDiadic(op_sc,0,makereg(0),ap1); break;
		case 4: GenerateDiadic(op_sh,0,makereg(0),ap1); break;
		case 8:	GenerateDiadic(op_sw,0,makereg(0),ap1); break;
		}
		else
		switch(size) {
		case 1:	GenerateDiadic(op_sb,0,ap2,ap1); break;
		case 2:	GenerateDiadic(op_sc,0,ap2,ap1); break;
		case 4: GenerateDiadic(op_sh,0,ap2,ap1); break;
		case 8:	GenerateDiadic(op_sw,0,ap2,ap1); break;
		// Do structure assignment
		default: {
			ap3 = GetTempRegister();
			GenerateDiadic(op_ldi,0,ap3,make_immed(size));
			GenerateTriadic(op_push,0,ap3,ap2,ap1);
			GenerateDiadic(op_jal,0,makereg(LR),make_string("memcpy"));
			GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(24));
			ReleaseTempRegister(ap3);
		}
		}
	}
*/
	ReleaseTempReg(ap2);
    MakeLegalAmode(ap1,flags,size);
    Leave("GenAssign",1);
	return ap1;
}

/*
 *      generate an auto increment or decrement node. op should be
 *      either op_add (for increment) or op_sub (for decrement).
 */
AMODE *GenerateAutoIncrement(ENODE *node,int flags,int size,int op)
{
	AMODE *ap1, *ap2;
    int siz1;

    siz1 = GetNaturalSize(node->p[0]);
    if( flags & 32768 )         /* dont need result */
            {
            ap1 = GenerateExpression(node->p[0],(15|1024|8192|16384),siz1);
			if (ap1->mode != am_reg) {
                GenMemop(op, ap1, make_immed(node->i), size)
                ;
/*
				ap2 = GetTempRegister();
				if (ap1->isUnsigned) {
					switch(size) {
					case 1:	GenerateDiadic(op_lbu,0,ap2,ap1); break;
					case 2:	GenerateDiadic(op_lcu,0,ap2,ap1); break;
					case 4:	GenerateDiadic(op_lhu,0,ap2,ap1); break;
					case 8:	GenerateDiadic(op_lw,0,ap2,ap1); break;
					}
				}
				else {
					switch(size) {
					case 1:	GenerateDiadic(op_lb,0,ap2,ap1); break;
					case 2:	GenerateDiadic(op_lc,0,ap2,ap1); break;
					case 4:	GenerateDiadic(op_lh,0,ap2,ap1); break;
					case 8:	GenerateDiadic(op_lw,0,ap2,ap1); break;
					}
				}
	            GenerateTriadic(op,0,ap2,ap2,make_immed(node->i));
				switch(size) {
				case 1:	GenerateDiadic(op_sb,0,ap2,ap1); break;
				case 2:	GenerateDiadic(op_sc,0,ap2,ap1); break;
				case 4:	GenerateDiadic(op_sh,0,ap2,ap1); break;
				case 8:	GenerateDiadic(op_sw,0,ap2,ap1); break;
				}
				ReleaseTempRegister(ap2);
*/
			}
			else
				GenerateTriadic(op,0,ap1,ap1,make_immed(node->i));
            //ReleaseTempRegister(ap1);
            return ap1;
            }
    ap2 = GenerateExpression(node->p[0],(15|1024|8192|16384),siz1);
	if (ap2->mode == am_reg) {
	    GenerateTriadic(op,0,ap2,ap2,make_immed(node->i));
		return ap2;
	}
	else {
//	    ap1 = GetTempRegister();
        GenMemop(op, ap2, make_immed(node->i), siz1);
        return ap2;
        GenLoad(ap1,ap2,siz1,siz1);
		GenerateTriadic(op,0,ap1,ap1,make_immed(node->i));
		GenStore(ap1,ap2,siz1);
//		ReleaseTempRegister(ap1);
	}
    //ReleaseTempRegister(ap2);
    //GenerateSignExtend(ap1,siz1,size,flags);
    return ap2;
}

// autocon and autofcon nodes

AMODE *GenAutocon(ENODE *node, int flags, int size, int type)
{
	AMODE *ap1, *ap2;

	ap1 = GetTempRegister();
	ap2 = allocAmode();
	ap2->mode = am_indx;
	ap2->preg = regBP;          /* frame pointer */
	ap2->offset = node;     /* use as constant node */
	ap2->type = type;
	GenerateDiadic(op_lea,0,ap1,ap2);
	MakeLegalAmode(ap1,flags,size);
	return ap1;             /* return reg */
}

//
// General expression evaluation. returns the addressing mode
// of the result.
//
AMODE *GenerateExpression(ENODE *node, int flags, int size)
{   
	AMODE *ap1, *ap2, *ap3;
    int natsize;
	static char buf[4][20];
	static int ndx;
	static int numDiags = 0;

    Enter("<GenerateExpression>"); 
    if( node == (ENODE *)NULL )
    {
		throw new C64PException(1000, 'G');
		numDiags++;
        printf("DIAG - null node in GenerateExpression.\n");
		if (numDiags > 100)
			exit(0);
        Leave("</GenerateExpression>",2); 
        return (AMODE *)NULL;
    }
	//size = node->esize;
    switch( node->nodetype )
    {
	case en_fcon:
        ap1 = allocAmode();
        ap1->mode = am_direct;
        ap1->offset = node;
		ap1->type = stdflt.GetIndex();
        MakeLegalAmode(ap1,flags,size);
        Leave("</GenerateExpression>",2); 
        return ap1;
		/*
            ap1 = allocAmode();
            ap1->mode = am_immed;
            ap1->offset = node;
			ap1->isFloat = TRUE;
            MakeLegalAmode(ap1,flags,size);
         Leave("GenExperssion",2); 
            return ap1;
		*/
    case en_icon:
        ap1 = allocAmode();
        ap1->mode = am_immed;
        ap1->offset = node;
        MakeLegalAmode(ap1,flags,size);
        Leave("GenExperssion",3); 
        return ap1;

	case en_labcon:
            if (use_gp) {
                ap1 = GetTempRegister();
                ap2 = allocAmode();
                ap2->mode = am_indx;
                ap2->preg = regGP;      // global pointer
                ap2->offset = node;     // use as constant node
                GenerateDiadic(op_lea,0,ap1,ap2);
                MakeLegalAmode(ap1,flags,size);
         Leave("GenExperssion",4); 
                return ap1;             // return reg
            }
            ap1 = allocAmode();
			/* this code not really necessary, see segments notes
			if (node->etype==bt_pointer && node->constflag) {
				ap1->segment = codeseg;
			}
			else {
				ap1->segment = dataseg;
			}
			*/
            ap1->mode = am_immed;
            ap1->offset = node;
			ap1->isUnsigned = node->isUnsigned;
            MakeLegalAmode(ap1,flags,size);
         Leave("GenExperssion",5); 
            return ap1;

    case en_nacon:
            if (use_gp) {
                ap1 = GetTempRegister();
                ap2 = allocAmode();
                ap2->mode = am_indx;
                ap2->preg = regGP;      // global pointer
                ap2->offset = node;     // use as constant node
                GenerateDiadic(op_lea,0,ap1,ap2);
                MakeLegalAmode(ap1,flags,size);
				Leave("GenExpression",6); 
                return ap1;             // return reg
            }
            // fallthru
	case en_cnacon:
            ap1 = allocAmode();
            ap1->mode = am_immed;
            ap1->offset = node;
			if (node->i==0)
				node->i = -1;
			ap1->isUnsigned = node->isUnsigned;
            MakeLegalAmode(ap1,flags,size);
			Leave("GenExpression",7); 
            return ap1;
	case en_clabcon:
            ap1 = allocAmode();
            ap1->mode = am_immed;
            ap1->offset = node;
			ap1->isUnsigned = node->isUnsigned;
            MakeLegalAmode(ap1,flags,size);
			Leave("GenExpression",7); 
            return ap1;
    case en_autocon:	return GenAutocon(node, flags, size, stdint.GetIndex());
    case en_autofcon:	return GenAutocon(node, flags, size, stddouble.GetIndex());
    case en_autovcon:	return GenAutocon(node, flags, size, stdvector.GetIndex());
    case en_autovmcon:	return GenAutocon(node, flags, size, stdvectormask->GetIndex());
    case en_classcon:
            ap1 = GetTempRegister();
            ap2 = allocAmode();
            ap2->mode = am_indx;
            ap2->preg = regCLP;     /* frame pointer */
            ap2->offset = node;     /* use as constant node */
            GenerateDiadic(op_lea,0,ap1,ap2);
            MakeLegalAmode(ap1,flags,size);
            return ap1;             /* return reg */
    case en_ub_ref:
	case en_uc_ref:
	case en_uh_ref:
	case en_uw_ref:
			ap1 = GenerateDereference(node,flags,size,0);
			ap1->isUnsigned = 1;
            return ap1;
	case en_struct_ref:
			ap1 = GenerateDereference(node,flags,size,0);
			ap1->isUnsigned = 1;
            return ap1;
	case en_vector_ref:	return GenerateDereference(node,flags,512,0);
	case en_ref32:	return GenerateDereference(node,flags,4,1);
	case en_ref32u:	return GenerateDereference(node,flags,4,0);
    case en_b_ref:	return GenerateDereference(node,flags,1,1);
	case en_c_ref:	return GenerateDereference(node,flags,2,1);
	case en_h_ref:	return GenerateDereference(node,flags,4,1);
    case en_w_ref:	return GenerateDereference(node,flags,8,1);
	case en_flt_ref:
	case en_dbl_ref:
    case en_triple_ref:
	case en_quad_ref:
			ap1 = GenerateDereference(node,flags,size,1);
			ap1->type = stddouble.GetIndex();
            return ap1;
	case en_ubfieldref:
	case en_ucfieldref:
	case en_uhfieldref:
	case en_uwfieldref:
			ap1 = (flags & 4096) ? GenerateDereference(node,flags & ~4096,size,0) : GenerateBitfieldDereference(node,flags,size);
			ap1->isUnsigned = 1;
			return ap1;
	case en_wfieldref:
	case en_bfieldref:
	case en_cfieldref:
	case en_hfieldref:
			ap1 = (flags & 4096) ? GenerateDereference(node,flags & ~4096,size,1) : GenerateBitfieldDereference(node,flags,size);
			return ap1;
	case en_regvar:
    case en_tempref:
            ap1 = allocAmode();
            ap1->mode = am_reg;
            ap1->preg = node->i;
            ap1->tempflag = 0;      /* not a temporary */
            MakeLegalAmode(ap1,flags,size);
            return ap1;
    case en_tempfpref:
            ap1 = allocAmode();
            ap1->mode = am_fpreg;
            ap1->preg = node->i;
            ap1->tempflag = 0;      /* not a temporary */
            MakeLegalAmode(ap1,flags,size);
            return ap1;
	case en_fpregvar:
//    case en_fptempref:
            ap1 = allocAmode();
            ap1->mode = am_fpreg;
            ap1->preg = node->i;
            ap1->tempflag = 0;      /* not a temporary */
            MakeLegalAmode(ap1,flags,size);
            return ap1;
	case en_abs:	return GenerateUnary(node,flags,size,op_abs);
    case en_uminus: return GenerateUnary(node,flags,size,op_neg);
    case en_compl:  return GenerateUnary(node,flags,size,op_com);
    case en_add:    return GenerateBinary(node,flags,size,op_add);
    case en_sub:    return GenerateBinary(node,flags,size,op_sub);
    case en_i2d:
         ap1 = GetTempRegister();	
         ap2=GenerateExpression(node->p[0],1,8);
         GenerateDiadic(op_itof,'d',ap1,ap2);
         ReleaseTempReg(ap2);
         return ap1;
    case en_i2q:
         ap1 = GetTempRegister();	
         ap2 = GenerateExpression(node->p[0],1,8);
		 GenerateTriadic(op_csrrw,0,makereg(0),make_immed(0x18),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
         GenerateDiadic(op_itof,'q',ap1,makereg(63));
         ReleaseTempReg(ap2);
         return ap1;
    case en_i2t:
         ap1 = GetTempRegister();	
         ap2 = GenerateExpression(node->p[0],1,8);
		 GenerateTriadic(op_csrrw,0,makereg(0),make_immed(0x18),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
         GenerateDiadic(op_itof,'t',ap1,makereg(63));
         ReleaseTempReg(ap2);
         return ap1;
    case en_d2i:
         ap1 = GetTempRegister();	
         ap2 = GenerateExpression(node->p[0],1,8);
         GenerateDiadic(op_ftoi,'d',ap1,ap2);
         ReleaseTempReg(ap2);
         return ap1;
    case en_q2i:
         ap1 = GetTempRegister();
         ap2 = GenerateExpression(node->p[0],1024,8);
         GenerateDiadic(op_ftoi,'q',makereg(63),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
		 GenerateTriadic(op_csrrw,0,ap1,make_immed(0x18),makereg(0));
         ReleaseTempReg(ap2);
         return ap1;
    case en_t2i:
         ap1 = GetTempRegister();
         ap2 = GenerateExpression(node->p[0],1024,8);
         GenerateDiadic(op_ftoi,'t',makereg(63),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
		 GenerateTriadic(op_csrrw,0,ap1,make_immed(0x18),makereg(0));
         ReleaseTempReg(ap2);
         return ap1;
	case en_s2q:
		ap1 = GetTempRegister();
        ap2 = GenerateExpression(node->p[0],1024,8);
        GenerateDiadic(op_fcvtsq,0,ap1,ap2);
        ReleaseTempReg(ap2);
		return ap1;

	case en_vadd:	  return GenerateBinary(node,flags,size,op_vadd);
	case en_vsub:	  return GenerateBinary(node,flags,size,op_vsub);
	case en_vmul:	  return GenerateBinary(node,flags,size,op_vmul);
	case en_vadds:	  return GenerateBinary(node,flags,size,op_vadds);
	case en_vsubs:	  return GenerateBinary(node,flags,size,op_vsubs);
	case en_vmuls:	  return GenerateBinary(node,flags,size,op_vmuls);
	case en_vex:      return GenerateBinary(node,flags,size,op_vex);
	case en_veins:    return GenerateBinary(node,flags,size,op_veins);

	case en_fadd:	  return GenerateBinary(node,flags,size,op_fadd);
	case en_fsub:	  return GenerateBinary(node,flags,size,op_fsub);
	case en_fmul:	  return GenerateBinary(node,flags,size,op_fmul);
	case en_fdiv:	  return GenerateBinary(node,flags,size,op_fdiv);

	case en_fdadd:    return GenerateBinary(node,flags,size,op_fdadd);
    case en_fdsub:    return GenerateBinary(node,flags,size,op_fdsub);
    case en_fsadd:    return GenerateBinary(node,flags,size,op_fsadd);
    case en_fssub:    return GenerateBinary(node,flags,size,op_fssub);
    case en_fdmul:    return GenerateMultiply(node,flags,size,op_fdmul);
    case en_fsmul:    return GenerateMultiply(node,flags,size,op_fsmul);
    case en_fddiv:    return GenerateMultiply(node,flags,size,op_fddiv);
    case en_fsdiv:    return GenerateMultiply(node,flags,size,op_fsdiv);
	case en_ftadd:    return GenerateBinary(node,flags,size,op_ftadd);
    case en_ftsub:    return GenerateBinary(node,flags,size,op_ftsub);
    case en_ftmul:    return GenerateMultiply(node,flags,size,op_ftmul);
    case en_ftdiv:    return GenerateMultiply(node,flags,size,op_ftdiv);

	case en_and:    return GenerateBinary(node,flags,size,op_and);
    case en_or:     return GenerateBinary(node,flags,size,op_or);
	case en_xor:	return GenerateBinary(node,flags,size,op_xor);
    case en_mul:    return GenerateMultiply(node,flags,size,op_mul);
    case en_mulu:   return GenerateMultiply(node,flags,size,op_mulu);
    case en_div:    return GenerateModDiv(node,flags,size,op_div);
    case en_udiv:   return GenerateModDiv(node,flags,size,op_divu);
    case en_mod:    return GenerateModDiv(node,flags,size,op_mod);
    case en_umod:   return GenerateModDiv(node,flags,size,op_modu);
    case en_asl:    return GenerateShift(node,flags,size,op_asl);
    case en_shl:    return GenerateShift(node,flags,size,op_shl);
    case en_shlu:   return GenerateShift(node,flags,size,op_shlu);
    case en_asr:	return GenerateShift(node,flags,size,op_asr);
    case en_shr:	return GenerateShift(node,flags,size,op_asr);
    case en_shru:   return GenerateShift(node,flags,size,op_shru);
	case en_rol:   return GenerateShift(node,flags,size,op_rol);
	case en_ror:   return GenerateShift(node,flags,size,op_ror);
	/*	
	case en_asfadd: return GenerateAssignAdd(node,flags,size,op_fadd);
	case en_asfsub: return GenerateAssignAdd(node,flags,size,op_fsub);
	case en_asfmul: return GenerateAssignAdd(node,flags,size,op_fmul);
	case en_asfdiv: return GenerateAssignAdd(node,flags,size,op_fdiv);
	*/
    case en_asadd:  return GenerateAssignAdd(node,flags,size,op_add);
    case en_assub:  return GenerateAssignAdd(node,flags,size,op_sub);
    case en_asand:  return GenerateAssignLogic(node,flags,size,op_and);
    case en_asor:   return GenerateAssignLogic(node,flags,size,op_or);
	case en_asxor:  return GenerateAssignLogic(node,flags,size,op_xor);
    case en_aslsh:
            return GenerateAssignShift(node,flags,size,op_shl);
    case en_asrsh:
            return GenerateAssignShift(node,flags,size,op_asr);
    case en_asrshu:
            return GenerateAssignShift(node,flags,size,op_shru);
    case en_asmul: return GenerateAssignMultiply(node,flags,size,op_mul);
    case en_asmulu: return GenerateAssignMultiply(node,flags,size,op_mulu);
    case en_asdiv: return GenerateAssignModiv(node,flags,size,op_div);
    case en_asdivu: return GenerateAssignModiv(node,flags,size,op_divu);
    case en_asmod: return GenerateAssignModiv(node,flags,size,op_mod);
    case en_asmodu: return GenerateAssignModiv(node,flags,size,op_modu);
    case en_assign:
            return GenerateAssign(node,flags,size);
    case en_ainc: return GenerateAutoIncrement(node,flags,size,op_add);
    case en_adec: return GenerateAutoIncrement(node,flags,size,op_sub);

    case en_land:
        return (GenExpr(node));

	case en_lor:
      return (GenExpr(node));

	case en_not:
	    return (GenExpr(node));

	case en_chk:
        return (GenExpr(node));
         
    case en_eq:     case en_ne:
    case en_lt:     case en_le:
    case en_gt:     case en_ge:
    case en_ult:    case en_ule:
    case en_ugt:    case en_uge:
    case en_feq:    case en_fne:
    case en_flt:    case en_fle:
    case en_fgt:    case en_fge:
    case en_veq:    case en_vne:
    case en_vlt:    case en_vle:
    case en_vgt:    case en_vge:
      return GenExpr(node);

	case en_cond:
            return GenerateHook(node,flags,size);
    case en_void:
            natsize = GetNaturalSize(node->p[0]);
            ReleaseTempRegister(GenerateExpression(node->p[0],(15|1024|8192|16384) | 32768,natsize));
            return (GenerateExpression(node->p[1],flags,size));

    case en_fcall:
		return (GenerateFunctionCall(node,flags));

	case en_cubw:
	case en_cubu:
	case en_cbu:
			ap1 = GenerateExpression(node->p[0],1,size);
			GenerateTriadic(op_and,0,ap1,ap1,make_immed(0xff));
			return (ap1);
	case en_cucw:
	case en_cucu:
	case en_ccu:
			ap1 = GenerateExpression(node->p[0],1,size);
			Generate4adic(op_bfextu,0,ap1,ap1,make_immed(0),make_immed(15));
			return ap1;
	case en_cuhw:
	case en_cuhu:
	case en_chu:
			ap1 = GenerateExpression(node->p[0],1,size);
			Generate4adic(op_bfextu,0,ap1,ap1,make_immed(0),make_immed(31));
			return ap1;
	case en_cbw:
			ap1 = GenerateExpression(node->p[0],1,size);
			//GenerateDiadic(op_sxb,0,ap1,ap1);
			Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(7));
			return ap1;
	case en_ccw:
			ap1 = GenerateExpression(node->p[0],1,size);
			Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(15));
			//GenerateDiadic(op_sxh,0,ap1,ap1);
			return ap1;
	case en_chw:
			ap1 = GenerateExpression(node->p[0],1,size);
			Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(31));
			//GenerateDiadic(op_sxh,0,ap1,ap1);
			return ap1;
    default:
            printf("DIAG - uncoded node (%d) in GenerateExpression.\n", node->nodetype);
            return 0;
    }
}

// return the natural evaluation size of a node.

int GetNaturalSize(ENODE *node)
{ 
	int siz0, siz1;
	if( node == NULL )
		return 0;
	switch( node->nodetype )
	{
	case en_uwfieldref:
	case en_wfieldref:
		return sizeOfWord;
	case en_bfieldref:
	case en_ubfieldref:
		return 1;
	case en_cfieldref:
	case en_ucfieldref:
		return 2;
	case en_hfieldref:
	case en_uhfieldref:
		return 4;
	case en_icon:
		if( -32768 <= node->i && node->i <= 32767 )
			return 2;
		if (-2147483648LL <= node->i && node->i <= 2147483647LL)
			return 4;
		return 8;
	case en_fcon:
		return node->tp->precision / 16;
	case en_tcon: return 6;
	case en_fcall:  case en_labcon: case en_clabcon:
	case en_cnacon: case en_nacon:  case en_autocon: case en_classcon:
	case en_tempref:
	case en_regvar:
	case en_fpregvar:
	case en_cbw: case en_cubw:
	case en_ccw: case en_cucw:
	case en_chw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
		return 8;
	case en_autofcon:
		return 8;
	case en_ref32: case en_ref32u:
		return 4;
	case en_b_ref:
	case en_ub_ref:
		return 1;
	case en_cbc:
	case en_c_ref:	return 2;
	case en_uc_ref:	return 2;
	case en_cbh:	return 2;
	case en_cch:	return 2;
	case en_h_ref:	return 4;
	case en_uh_ref:	return 4;
	case en_flt_ref: return sizeOfFPS;
	case en_w_ref:  case en_uw_ref:
		return 8;
	case en_autovcon:
	case en_vector_ref:
		return 512;
	case en_dbl_ref:
		return sizeOfFPD;
	case en_quad_ref:
		return sizeOfFPQ;
	case en_triple_ref:
		return sizeOfFPT;
	case en_struct_ref:
	return node->esize;
	case en_tempfpref:
	if (node->tp)
		return node->tp->precision/16;
	else
		return 8;
	case en_not:    case en_compl:
	case en_uminus: case en_assign:
	case en_ainc:   case en_adec:
		return GetNaturalSize(node->p[0]);
	case en_fadd:	case en_fsub:
	case en_fmul:	case en_fdiv:
	case en_fsadd:	case en_fssub:
	case en_fsmul:	case en_fsdiv:
	case en_vadd:	case en_vsub:
	case en_vmul:	case en_vdiv:
	case en_vadds:	case en_vsubs:
	case en_vmuls:	case en_vdivs:
	case en_add:    case en_sub:
	case en_mul:    case en_mulu:
	case en_div:	case en_udiv:
	case en_mod:    case en_umod:
	case en_and:    case en_or:     case en_xor:
	case en_asl:
	case en_shl:    case en_shlu:
	case en_shr:	case en_shru:
	case en_asr:	case en_asrshu:
	case en_feq:    case en_fne:
	case en_flt:    case en_fle:
	case en_fgt:    case en_fge:
	case en_eq:     case en_ne:
	case en_lt:     case en_le:
	case en_gt:     case en_ge:
	case en_ult:	case en_ule:
	case en_ugt:	case en_uge:
	case en_land:   case en_lor:
	case en_asadd:  case en_assub:
	case en_asmul:  case en_asmulu:
	case en_asdiv:	case en_asdivu:
	case en_asmod:  case en_asand:
	case en_asor:   case en_asxor:	case en_aslsh:
	case en_asrsh:
		siz0 = GetNaturalSize(node->p[0]);
		siz1 = GetNaturalSize(node->p[1]);
		if( siz1 > siz0 )
			return siz1;
		else
			return siz0;
	case en_void:   case en_cond:
		return GetNaturalSize(node->p[1]);
	case en_chk:
		return 8;
	case en_q2i:
	case en_t2i:
		return (sizeOfWord);
	case en_i2t:
		return (sizeOfFPT);
	case en_i2q:
		return (sizeOfFPQ);
	default:
		printf("DIAG - natural size error %d.\n", node->nodetype);
		break;
	}
	return 0;
}


static void GenerateCmp(ENODE *node, int op, int label, unsigned int prediction)
{
	Enter("GenCmp");
	GenerateCmp(node, op, label, 0, prediction);
	Leave("GenCmp",0);
}

//
// Generate a jump to label if the node passed evaluates to
// a true condition.
//
void GenerateTrueJump(ENODE *node, int label, unsigned int prediction)
{ 
	AMODE  *ap1;
	int    siz1;
	int    lab0;

	if( node == 0 )
		return;
	switch( node->nodetype )
	{
	case en_eq:	GenerateCmp(node, op_eq, label, prediction); break;
	case en_ne: GenerateCmp(node, op_ne, label, prediction); break;
	case en_lt: GenerateCmp(node, op_lt, label, prediction); break;
	case en_le:	GenerateCmp(node, op_le, label, prediction); break;
	case en_gt: GenerateCmp(node, op_gt, label, prediction); break;
	case en_ge: GenerateCmp(node, op_ge, label, prediction); break;
	case en_ult: GenerateCmp(node, op_ltu, label, prediction); break;
	case en_ule: GenerateCmp(node, op_leu, label, prediction); break;
	case en_ugt: GenerateCmp(node, op_gtu, label, prediction); break;
	case en_uge: GenerateCmp(node, op_geu, label, prediction); break;
	case en_feq: GenerateCmp(node, op_feq, label, prediction); break;
	case en_fne: GenerateCmp(node, op_fne, label, prediction); break;
	case en_flt: GenerateCmp(node, op_flt, label, prediction); break;
	case en_fle: GenerateCmp(node, op_fle, label, prediction); break;
	case en_fgt: GenerateCmp(node, op_fgt, label, prediction); break;
	case en_fge: GenerateCmp(node, op_fge, label, prediction); break;
	case en_veq: GenerateCmp(node, op_vseq, label, prediction); break;
	case en_vne: GenerateCmp(node, op_vsne, label, prediction); break;
	case en_vlt: GenerateCmp(node, op_vslt, label, prediction); break;
	case en_vle: GenerateCmp(node, op_vsle, label, prediction); break;
	case en_vgt: GenerateCmp(node, op_vsgt, label, prediction); break;
	case en_vge: GenerateCmp(node, op_vsge, label, prediction); break;
	case en_land:
		lab0 = nextlabel++;
		GenerateFalseJump(node->p[0],lab0,prediction);
		GenerateTrueJump(node->p[1],label,prediction^1);
		GenerateLabel(lab0);
		break;
	case en_lor:
		GenerateTrueJump(node->p[0],label,prediction);
		GenerateTrueJump(node->p[1],label,prediction);
		break;
	case en_not:
		GenerateFalseJump(node->p[0],label,prediction^1);
		break;
	default:
		siz1 = GetNaturalSize(node);
		ap1 = GenerateExpression(node,1,siz1);
		//                        GenerateDiadic(op_tst,siz1,ap1,0);
		ReleaseTempRegister(ap1);
		GenerateTriadic(op_bne,0,ap1,makereg(0),make_label(label));
		break;
	}
}

//
// Generate code to execute a jump to label if the expression
// passed is false.
//
void GenerateFalseJump(ENODE *node,int label, unsigned int prediction)
{
	AMODE *ap, *ap1, *ap2;
	int siz1;
	int lab0;

	if( node == (ENODE *)NULL )
		return;
	switch( node->nodetype )
	{
	case en_eq:	GenerateCmp(node, op_ne, label, prediction); break;
	case en_ne: GenerateCmp(node, op_eq, label, prediction); break;
	case en_lt: GenerateCmp(node, op_ge, label, prediction); break;
	case en_le: GenerateCmp(node, op_gt, label, prediction); break;
	case en_gt: GenerateCmp(node, op_le, label, prediction); break;
	case en_ge: GenerateCmp(node, op_lt, label, prediction); break;
	case en_ult: GenerateCmp(node, op_geu, label, prediction); break;
	case en_ule: GenerateCmp(node, op_gtu, label, prediction); break;
	case en_ugt: GenerateCmp(node, op_leu, label, prediction); break;
	case en_uge: GenerateCmp(node, op_ltu, label, prediction); break;
	case en_feq: GenerateCmp(node, op_fne, label, prediction); break;
	case en_fne: GenerateCmp(node, op_feq, label, prediction); break;
	case en_flt: GenerateCmp(node, op_fge, label, prediction); break;
	case en_fle: GenerateCmp(node, op_fgt, label, prediction); break;
	case en_fgt: GenerateCmp(node, op_fle, label, prediction); break;
	case en_fge: GenerateCmp(node, op_flt, label, prediction); break;
	case en_veq: GenerateCmp(node, op_vsne, label, prediction); break;
	case en_vne: GenerateCmp(node, op_vseq, label, prediction); break;
	case en_vlt: GenerateCmp(node, op_vsge, label, prediction); break;
	case en_vle: GenerateCmp(node, op_vsgt, label, prediction); break;
	case en_vgt: GenerateCmp(node, op_vsle, label, prediction); break;
	case en_vge: GenerateCmp(node, op_vslt, label, prediction); break;
	case en_land:
		GenerateFalseJump(node->p[0],label,prediction^1);
		GenerateFalseJump(node->p[1],label,prediction^1);
		break;
	case en_lor:
		lab0 = nextlabel++;
		GenerateTrueJump(node->p[0],lab0,prediction);
		GenerateFalseJump(node->p[1],label,prediction^1);
		GenerateLabel(lab0);
		break;
	case en_not:
		GenerateTrueJump(node->p[0],label,prediction);
		break;
	default:
		siz1 = GetNaturalSize(node);
		ap = GenerateExpression(node,1,siz1);
		//                        GenerateDiadic(op_tst,siz1,ap,0);
		ReleaseTempRegister(ap);
		GenerateTriadic(op_beq,0,ap,makereg(0),make_label(label));
		break;
	}
}
