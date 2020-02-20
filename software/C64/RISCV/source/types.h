#ifndef _TYPES_H
#define _TYPES_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
class Operand;
class ENODE;
class Statement;
class BasicBlock;
class Instruction;
class Var;
class CSE;
class CSETable;
class Operand;
class SYM;
class Function;
class OCODE;
class PeepList;
class Var;

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
    struct slit *next;
		struct slit *tail;
    int             label;
    char            *str;
		bool		isString;
		int8_t pass;
	char			*nmspace;
};

struct scase {
	int label;
	int64_t val;
	int8_t pass;
};

struct clit {
  struct clit *next;
  int     label;
	int		num;
	int8_t pass;
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
class Statement;

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

class MachineReg
{
public:
	int number;
	bool isConst;
	bool assigned;
	bool modified;
	bool sub;
	bool IsArg;
	bool IsColorable;
	ENODE *offset;
	int val;
public:
	static bool IsCalleeSave(int regno);
	bool IsArgReg();
	static void MarkColorable();
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

class PeepList
{
public:
	OCODE *head;
	OCODE *tail;
public:
	void Add(OCODE *cd);
	int Count(OCODE *pos);
	bool HasCall(OCODE *pos);
	static OCODE *FindLabel(int64_t i);
	static void InsertBefore(OCODE *an, OCODE *cd);
	static void InsertAfter(OCODE *an, OCODE *cd);
	void MarkAllKeep();
	void MarkAllKeep2();
	void RemoveCompilerHints();
	void RemoveCompilerHints2();
	void Remove(OCODE *ip);
	void Remove();
	void Remove2();
	void RemoveLinkUnlink();
	void flush();
	void SetLabelReference();
	void EliminateUnreferencedLabels();
	bool FindTarget(OCODE *ip, int reg);

	void Dump(char *msg);
	BasicBlock *Blockize();
	int CountSPReferences();
	int CountBPReferences();
	void RemoveStackAlloc();
	void RemoveStackCode();
	void RemoveReturnBlock();

	// Optimizations
	void OptInstructions();
	void OptBranchToNext();
	void OptDoubleTargetRemoval();
	void OptConstReg();
	void OptLoopInvariants(OCODE *loophead);

	// Color Graphing
	void SetAllUncolored();
	void RemoveMoves();

	void loadHex(txtiStream& ifs);
	void storeHex(txtoStream& ofs);
};

class Function
{
public:
	unsigned short int number;
	unsigned int valid : 1;
	unsigned int IsPrototype : 1;
	unsigned int IsTask : 1;
	unsigned int IsInterrupt : 1;
	unsigned int IsNocall : 1;
	unsigned int IsPascal : 1;
	unsigned int IsLeaf : 1;
	unsigned int DoesThrow : 1;
	unsigned int UsesNew : 1;
	unsigned int UsesPredicate : 1;
	unsigned int IsVirtual : 1;
	unsigned int IsInline : 1;
	unsigned int UsesTemps : 1;		// uses temporary registers
	unsigned int UsesStackParms : 1;
	unsigned int hasSPReferences : 1;
	unsigned int hasBPReferences : 1;
	unsigned int didRemoveReturnBlock : 1;
	unsigned int retGenerated : 1;
	unsigned int alloced : 1;
	unsigned int hasAutonew : 1;
	uint8_t NumRegisterVars;
	unsigned __int8 NumParms;
	unsigned __int8 numa;			// number of stack parameters (autos)
	int stkspace;					// stack space used by function
	int argbot;
	int tempbot;
	TABLE proto;
	TABLE params;
	Statement *prolog;
	Statement *epilog;
	unsigned int stksize;
	CSETable *csetbl;
	SYM *sym;
	SYM *parms;					      // List of parameters associated with symbol
	SYM *nextparm;
	DerivedMethod *derivitives;
	CSet *mask, *rmask;
	CSet *fpmask, *fprmask;
	CSet *vmask, *vrmask;
	BasicBlock *RootBlock;
	BasicBlock *LastBlock;
	BasicBlock *ReturnBlock;
	Var *varlist;
	PeepList pl;					// under construction
	OCODE *spAdjust;				// place where sp adjustment takes place
	OCODE *rcode;
public:
	void RemoveDuplicates();
	int GetTempBot() { return (tempbot); };
	void CheckParameterListMatch(Function *s1, Function *s2);
	bool CheckSignatureMatch(Function *a, Function *b) const;
	TypeArray *GetParameterTypes();
	TypeArray *GetProtoTypes();
	void PrintParameterTypes();
	std::string *BuildSignature(int opt = 0);
	Function *FindExactMatch(int mm);
	static Function *FindExactMatch(int mm, std::string name, int rettype, TypeArray *typearray);
	bool HasRegisterParameters();
	bool ProtoTypesMatch(Function *sym);
	bool ProtoTypesMatch(TypeArray *typearray);
	bool ParameterTypesMatch(Function *sym);
	bool ParameterTypesMatch(TypeArray *typearray);
	void BuildParameterList(int *num, int*numa);
	void AddParameters(SYM *list);
	void AddProto(SYM *list);
	void AddProto(TypeArray *);
	void AddDerived();

	void CheckForUndefinedLabels();
	void Summary(Statement *);
	Statement *ParseBody();
	void Init();
	int Parse();
	void InsertMethod();

	void SaveGPRegisterVars();
	void SaveFPRegisterVars();
	void SaveRegisterVars();
	void SaveRegisterArguments();
	int RestoreGPRegisterVars();
	int RestoreFPRegisterVars();
	void RestoreRegisterVars();
	void RestoreRegisterArguments();
	void SaveTemporaries(int *sp, int *fsp);
	void RestoreTemporaries(int sp, int fsp);

	void UnlinkStack();

	// Optimization
	void PeepOpt();
	void FlushPeep() { pl.flush(); };

	// Code generation
	Operand *MakeDataLabel(int lab);
	Operand *MakeCodeLabel(int lab);
	Operand *MakeStringAsNameConst(char *s);
	Operand *MakeString(char *s);
	Operand *MakeImmediate(int64_t i);
	Operand *MakeIndirect(int i);
	Operand *MakeIndexed(int64_t o, int i);
	Operand *MakeDoubleIndexed(int i, int j, int scale);
	Operand *MakeDirect(ENODE *node);
	Operand *MakeIndexed(ENODE *node, int rg);

	void GenLoad(Operand *ap3, Operand *ap1, int ssize, int size);
	void SetupReturnBlock();
	bool GenDefaultCatch();
	void GenReturn(Statement *stmt);
	void Gen();

	void CreateVars();
	void ComputeLiveVars();
	void DumpLiveVars();

	void storeHex(txtoStream& ofs);
};

class SYM {
public:
	int number;
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
	unsigned int IsInline : 1;
	unsigned int pos : 4;			// position of the symbol (param, auto or return type)
	// Function attributes
	Function *fi;
	// Auto's are handled by compound statements
	TABLE lsyms;              // local symbols (goto labels)
	unsigned int IsParameter : 1;
	unsigned int IsRegister : 1;
	unsigned int IsAuto : 1;
	unsigned int isConst : 1;
	unsigned int IsKernel : 1;
	unsigned int IsPrivate : 1;
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

	static SYM *Copy(SYM *src);
	SYM *Find(std::string name);
	int FindNextExactMatch(int startpos, TypeArray *);
	SYM *FindRisingMatch(bool ignore = false);
	std::string *GetNameHash();
	std::string *BuildSignature(int opt);
	static SYM *GetPtr(int n);
	SYM *GetParentPtr();
	void SetName(std::string nm) {
       name = new std::string(nm);
       name2 = new std::string(nm);
       name3 = new std::string(nm);
	   if (mangledName == nullptr)
		   mangledName = new std::string(nm);
	};
	void SetNext(int nxt) { next = nxt; };
	int GetNext() { return next; };
	SYM *GetNextPtr();
	int GetIndex();
	void SetType(TYP *t) { 
		if (t == (TYP *)0x500000005) {
			printf("Press key\n");
			getchar();
	}
	else
		tp = t;
} ;
	void SetStorageOffset(TYP *head, int nbytes, int al, int ilc, int ztype);
	int AdjustNbytes(int nbytes, int al, int ztype);

	void storeHex(txtoStream& ofs);
};

class TYP {
public:
  int type;
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
	int64_t   size;
	int64_t struct_offset;
	int8_t dimen;
	int numele;					// number of elements in array / vector length
	TABLE lst;
	int btp;

	TYP *GetBtp();
	static TYP *GetPtr(int n);
	int GetIndex();
	int GetHash();
	static int64_t GetSize(int num);
	int64_t GetElementSize();
	static int GetBasicType(int num);
	std::string *sname;
	unsigned int alignment;
	static TYP *Make(int bt, int64_t siz);
	static TYP *Copy(TYP *src);
	bool IsScalar();
	bool IsFloatType() const { return (type==bt_quad || type==bt_float || type==bt_double || type==bt_triple); };
	bool IsVectorType() const { return (type==bt_vector); };
	bool IsUnion() const { return (type==bt_union); };
	bool IsStructType() const { return (type==bt_struct || type==bt_class || type==bt_union); };
	bool IsAggregateType() const { return (IsStructType() | isArray); };
	static bool IsSameType(TYP *a, TYP *b, bool exact);
	void put_ty();

	int Alignment();
	int walignment();
	int roundAlignment();
	int64_t roundSize();

	ENODE *BuildEnodeTree();

	// Initialization
	int64_t GenerateT(TYP *tp, ENODE *node);
	int64_t InitializeArray(int64_t sz);
	int64_t InitializeStruct();
	int64_t InitializeUnion();
	int64_t Initialize(int64_t val);
	int64_t Initialize(TYP *);

	// Serialization
	void storeHex(txtoStream& ofs);

	// GC support
	bool FindPointer();
	bool FindPointerInStruct();
	bool IsSkippable();
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
	int number;
	enum e_node nodetype;
	enum e_node new_nodetype;			// nodetype replaced by optimization
	int etype;
	int64_t esize;
	TYP *tp;
	SYM *sym;
	__int8 constflag;
	unsigned int segment : 4;
	unsigned int predreg : 4;
	unsigned int isVolatile : 1;
	unsigned int isIO : 1;
	unsigned int isUnsigned : 1;
	unsigned int isCheckExpr : 1;
	unsigned int isPascal : 1;
	unsigned int isAutonew : 1;
	unsigned int isNeg : 1;
	ENODE *vmask;
	__int8 bit_width;
	__int8 bit_offset;
	__int8 scale;
	short int rg;
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
	ENODE *p[4];
	ENODE *pfl;			// postfix list

	ENODE *Clone();

	void SetType(TYP *t) { tp = t; if (t) etype = t->type; };
	bool IsPtr() { return (etype == bt_pointer || etype == bt_struct || etype == bt_union || etype == bt_class || nodetype==en_addrof); };
	bool IsFloatType() { return (nodetype==en_addrof || nodetype==en_autofcon) ? false : (etype == bt_double || etype == bt_quad || etype == bt_float || etype == bt_triple); };
	bool IsVectorType() { return (etype == bt_vector); };
	bool IsAutocon() { return (nodetype == en_autocon || nodetype == en_autocon || nodetype == en_autovcon || nodetype == en_classcon); };
	bool IsUnsignedType() { return (etype == bt_ubyte || etype == bt_uchar || etype == bt_ushort || etype == bt_ulong || etype == bt_pointer || nodetype==en_addrof || nodetype==en_autofcon || nodetype==en_autocon); };
	bool IsRefType() {	return (nodetype == en_ref);	};
	bool IsBitfield();
	static bool IsEqualOperand(Operand *a, Operand *b);
	char fsize();
	int64_t GetReferenceSize();
	int GetNaturalSize();

	static bool IsSameType(ENODE *ep1, ENODE *ep2);
	static bool IsEqual(ENODE *a, ENODE *b, bool lit = false);
	bool HasAssignop();
	bool HasCall();

	// Parsing
	bool AssignTypeToList(TYP *);

	// Optimization
	CSE *OptInsertAutocon(int duse);
	CSE *OptInsertRef(int duse);
	void scanexpr(int duse);
	void repexpr();
	void update();

	// Code generation
	Operand *MakeDataLabel(int lab);
	Operand *MakeCodeLabel(int lab);
	Operand *MakeStringAsNameConst(char *s);
	Operand *MakeString(char *s);
	Operand *MakeImmediate(int64_t i);
	Operand *MakeIndirect(int i);
	Operand *MakeIndexed(int64_t o, int i);
	Operand *MakeDoubleIndexed(int i, int j, int scale);
	Operand *MakeDirect(ENODE *node);
	Operand *MakeIndexed(ENODE *node, int rg);

	void GenerateHint(int num);
	void GenMemop(int op, Operand *ap1, Operand *ap2, int ssize);
	void GenLoad(Operand *ap3, Operand *ap1, int ssize, int size);
	void GenStore(Operand *ap1, Operand *ap3, int size);
	static void GenRedor(Operand *ap1, Operand *ap2);
	Operand *GenIndex();
	Operand *GenHook(int flags, int size);
	Operand *GenSafeHook(int flags, int size);
	Operand *GenShift(int flags, int size, int op);
	Operand *GenMultiply(int flags, int size, int op);
	Operand *GenDivMod(int flags, int size, int op);
	Operand *GenUnary(int flags, int size, int op);
	Operand *GenBinary(int flags, int size, int op);
	Operand *GenAssignShift(int flags, int size, int op);
	Operand *GenerateAssignAdd(int flags, int size, int op);
	Operand *GenerateAssignLogic(int flags, int size, int op);
	Operand *GenerateAssignMultiply(int flags, int size, int op);
	Operand *GenerateAssignModiv(int flags, int size, int op);
	Operand *GenLand(int flags, int op, bool safe);
	Operand *GenerateAutocon(int flags, int size, int type);
	Operand *Generate(int flags, int size);

	void store(txtoStream& ofs);
	void load(txtiStream& ifs);
	void storeHex(txtoStream& ofs);
	void loadHex(txtiStream& ifs);

	int PutStructConst(txtoStream& ofs);
	void PutConstant(txtoStream& ofs, unsigned int lowhigh, unsigned int rshift, bool opt = false);
	void PutConstantHex(txtoStream& ofs, unsigned int lowhigh, unsigned int rshift);
	static ENODE *GetConstantHex(std::ifstream& ifs);

	// Debugging
	std::string nodetypeStr();
	void Dump();
};

class Expression : public CompilerType
{
private:
	static ENODE *ParseArgumentList(ENODE *hidden, TypeArray *typearray);
	static TYP *ParsePrimaryExpression(ENODE **node, int got_pa);
	static TYP *ParseUnaryExpression(ENODE **node, int got_pa);
	static TYP *ParsePostfixExpression(ENODE **node, int got_pa);
	static TYP *ParseCastExpression(ENODE **node);
	static TYP *ParseMultOps(ENODE **node);
	static TYP *ParseAddOps(ENODE **node);
	static TYP *ParseShiftOps(ENODE **node);
	static TYP *ParseRelationalOps(ENODE **node);
	static TYP *ParseEqualOps(ENODE **node);
	static TYP *ParseBitwiseAndOps(ENODE **node);
	static TYP *ParseBitwiseXorOps(ENODE **node);
	static TYP *ParseBitwiseOrOps(ENODE **node);
	static TYP *ParseAndOps(ENODE **node);
	static TYP *ParseSafeAndOps(ENODE **node);
	static TYP *ParseOrOps(ENODE **node);
	static TYP *ParseSafeOrOps(ENODE **node);
	static TYP *ParseConditionalOps(ENODE **node);
	static TYP *ParseNonAssignExpression(ENODE **node);
	static TYP *ParseCommaOp(ENODE **node);
public:
	// The following is called from declaration processing, so is made public
	static TYP *ParseAssignOps(ENODE **node);
	static TYP *ParseNonCommaExpression(ENODE **node);
	//static TYP *ParseBinaryOps(ENODE **node, TYP *(*xfunc)(ENODE **), int nt, int sy);
	static TYP *ParseExpression(ENODE **node);
};

class Operand : public CompilerType
{
public:
	int num;					// number of the operand
	unsigned int mode;
	unsigned int preg : 12;		// primary virtual register number
	unsigned int sreg : 12;		// secondary virtual register number (indexed addressing modes)
	unsigned int pcolored : 1;
	unsigned int scolored : 1;
	unsigned short int pregs;	// subscripted register number
	unsigned short int sregs;
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
	unsigned int isPtr : 1;
	unsigned int isConst : 1;
	unsigned int isBool : 1;
	short int pdeep;		// previous stack depth on allocation
	short int deep;           /* stack depth on allocation */
	short int deep2;
	ENODE *offset;
	ENODE *offset2;
	int8_t scale;
	Operand *next;			// For extended sizes (long)
public:
	Operand *Clone();
	static bool IsSameType(Operand *ap1, Operand *ap2);
	static bool IsEqual(Operand *ap1, Operand *ap2);
	char fpsize();

	void GenZeroExtend(int isize, int osize);
	Operand *GenSignExtend(int isize, int osize, int flags);
	void MakeLegal(int flags, int size);
	int OptRegConst(int regclass, bool tally=false);

	// Storage
	void PutAddressMode(txtoStream& ofs);
	void store(txtoStream& fp);
	void storeHex(txtoStream& fp);
	static Operand *loadHex(txtiStream& fp);
	void load(txtiStream& fp);
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
	unsigned int segment : 4;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;	// label is referenced by code
	unsigned int remove : 1;
	unsigned int remove2 : 1;
	unsigned int leader : 1;
	short pregreg;
	short predop;
	int loop_depth;
	Operand *oper1, *oper2, *oper3, *oper4;
	__int16 phiops[100];
public:
	static OCODE *MakeNew();
	static OCODE *Clone(OCODE *p);
	static bool IsEqualOperand(Operand *a, Operand *b) { return (Operand::IsEqual(a, b)); };
	static void Swap(OCODE *ip1, OCODE *ip2);
	void MarkRemove() { 
		remove = true;
	};
	void MarkRemove2() { remove2 = true; };
	void Remove();
	bool HasTargetReg() const;
	bool HasTargetReg(int regno) const;
	int GetTargetReg(int *rg1, int *rg2) const;
	bool HasSourceReg(int) const;
	bool IsFlowControl();
	//Edge *MakeEdge(OCODE *ip1, OCODE *ip2);
	// Optimizations
	bool IsSubiSP();
	void OptCom();
	void OptMul();
	void OptMulu();
	void OptDiv();
	void OptAnd();
	void OptMove();
	void OptRedor();
	void OptAdd();
	void OptSubtract();
	void OptLoad();
	void OptLoadByte();
	void OptLoadChar();
	void OptLoadHalf();
	void OptStoreHalf();
	void OptLoadWord();
	void OptStore();
	void OptSxb();
	void OptBra();
	void OptJAL();
	void OptUctran();
	void OptDoubleTargetRemoval();
	void OptHint();
	void OptLabel();
	void OptIndexScale();
	void OptLdi();
	void OptLea();
	void OptPfi();

	static OCODE *loadHex(txtiStream& ifs);
	void store(txtoStream& ofs);
	void storeHex(txtoStream& ofs);
};

class OperandFactory
{
public:
	Operand *MakeDataLabel(int labno);
	Operand *MakeCodeLabel(int lab);
	Operand *MakeStrlab(std::string s);
	Operand *MakeString(char *s);
	Operand *MakeStringAsNameConst(char *s);
	Operand *makereg(int r);
	Operand *makevreg(int r);
	Operand *makevmreg(int r);
	Operand *makefpreg(int r);
	Operand *MakeMask(int mask);
	Operand *MakeImmediate(int64_t i);
	Operand *MakeIndirect(short int regno);
	Operand *MakeIndexedCodeLabel(int lab, int i);
	Operand *MakeIndexed(int64_t offset, int regno);
	Operand *MakeIndexed(ENODE *node, int regno);
	Operand *MakeNegIndexed(ENODE *node, int regno);
	Operand *MakeDoubleIndexed(int regi, int regj, int scale);
	Operand *MakeDirect(ENODE *node);
};

class CodeGenerator
{
public:
	Operand *MakeDataLabel(int lab);
	Operand *MakeCodeLabel(int lab);
	Operand *MakeStringAsNameConst(char *s);
	Operand *MakeString(char *s);
	Operand *MakeImmediate(int64_t i);
	Operand *MakeIndirect(int i);
	Operand *MakeIndexed(int64_t o, int i);
	Operand *MakeDoubleIndexed(int i, int j, int scale);
	Operand *MakeDirect(ENODE *node);
	Operand *MakeIndexed(ENODE *node, int rg);

	void GenerateHint(int num);
	void GenerateComment(char *cm);
	void GenMemop(int op, Operand *ap1, Operand *ap2, int ssize);
	void GenLoad(Operand *ap3, Operand *ap1, int ssize, int size);
	void GenStore(Operand *ap1, Operand *ap3, int size);
	virtual bool GenerateBranch(ENODE *node, int op, int label, int predreg, unsigned int prediction, bool limit) { return (false); };
	Operand *GenerateBitfieldAssign(ENODE *node, int flags, int size);
	void GenerateBitfieldInsert(Operand *ap1, Operand *ap2, int offset, int width);
	Operand *GenerateBitfieldDereference(ENODE *node, int flags, int size, int opt);
	Operand *GenerateDereference(ENODE *node, int flags, int size, int su);
	Operand *GenerateAssignMultiply(ENODE *node, int flags, int size, int op);
	Operand *GenerateAssignModiv(ENODE *node, int flags, int size, int op);
	void GenerateStructAssign(TYP *tp, int64_t offset, ENODE *ep, Operand *base);
	void GenerateArrayAssign(TYP *tp, ENODE *node1, ENODE *node2, Operand *base);
	Operand *GenerateAggregateAssign(ENODE *node1, ENODE *node2);
	Operand *GenAutocon(ENODE *node, int flags, int size, int type);
	Operand *GenerateAssign(ENODE *node, int flags, int size);
	Operand *GenerateExpression(ENODE *node, int flags, int size);
	void GenerateTrueJump(ENODE *node, int label, unsigned int prediction);
	void GenerateFalseJump(ENODE *node, int label, unsigned int prediction);
	virtual Operand *GenExpr(ENODE *node) { return (nullptr); };
	void GenLoadConst(Operand *ap1, Operand *ap2);
	void SaveTemporaries(Function *sym, int *sp, int *fsp);
	void RestoreTemporaries(Function *sym, int sp, int fsp);
	int GenerateInlineArgumentList(Function *func, ENODE *plist);
	virtual int PushArgument(ENODE *ep, int regno, int stkoffs, bool *isFloat) { return(0); };
	virtual int PushArguments(Function *func, ENODE *plist) { return (0); };
	virtual void PopArguments(Function *func, int howMany) {};
	virtual Operand *GenerateFunctionCall(ENODE *node, int flags) { return (nullptr); };
	void GenerateFunction(Function *fn) { fn->Gen(); };
};

class FT64CodeGenerator : public CodeGenerator
{
public:
	bool GenerateBranch(ENODE *node, int op, int label, int predreg, unsigned int prediction, bool limit);
	Operand *GenExpr(ENODE *node);
	bool IsPascal(ENODE *ep);
	void LinkAutonew(ENODE *node);
	int PushArgument(ENODE *ep, int regno, int stkoffs, bool *isFloat);
	int PushArguments(Function *func, ENODE *plist);
	void PopArguments(Function *func, int howMany, bool isPascal = true);
	Operand *GenerateFunctionCall(ENODE *node, int flags);
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
	static OCODE *FindLabel(int64_t i) { return (PeepList::FindLabel(i)); };
	static void Rename();
	static void Search(BasicBlock *);
	static void Subscript(Operand *oper);
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
	Operand *oper1, *oper2, *oper3, *oper4;
};
typedef OCODE OCODE;
*/

class IntStack
{
public:
	int *stk;
	int sp;
	int size;
public:
	static IntStack *MakeNew(int sz) {
		IntStack *s;
		s = (IntStack *)allocx(sizeof(IntStack));
		s->stk = (int *)allocx(sz * sizeof(int));
		s->sp = sz;
		s->size = sz;
		return (s);
	}
	static IntStack *MakeNew() {
		return (MakeNew(1000));
	}
	void push(int v) {
		if (sp > 0) {
			sp--;
			stk[sp] = v;
		}
		else
			throw new C64PException(ERR_STACKFULL, 0);
	};
	int pop() {
		int v = 0;
		if (sp < size) {
			v = stk[sp];
			sp++;
			return (v);
		}
		throw new C64PException(ERR_STACKEMPTY, 0);
	};
	int tos() {
		return (stk[sp]);
	};
	bool IsEmpty() { return (sp == size); };
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
	int length;		// number of instructions
	unsigned int changed : 1;
	unsigned int isColored : 1;
	unsigned int isRetBlock : 1;
	int depth;
	CSet *gen;		// use
	CSet *kill;		// def
	CSet *LiveIn;
	CSet *LiveOut;
	CSet *live;
	CSet *MustSpill;
	CSet *NeedLoad;
	CSet *DF;		// dominance frontier
	CSet *trees;
	int HasAlready;
	int Work;
	static CSet *livo;
	BasicBlock *next;
	BasicBlock *prev;
	OCODE *code;
	OCODE *lcode;
	static BasicBlock *RootBlock;
	static int nBasicBlocks;
	CSet *color;
public:
	static BasicBlock *MakeNew();
	static BasicBlock *Blockize(OCODE *start);
	Edge *MakeOutputEdge(BasicBlock *dst);
	Edge *MakeInputEdge(BasicBlock *src);
	Edge *MakeDomEdge(BasicBlock *dst);
	static void Unite(int father, int son);
	void ComputeLiveVars();
	void AddLiveOut(BasicBlock *ip);
	bool IsIdom(BasicBlock *b);
	void ExpandReturnBlocks();

	void UpdateLive(int);
	void CheckForDeaths(int r);
	static void ComputeSpillCosts();
	static void InsertMove(int reg, int rreg, int blk);
	void BuildLivesetFromLiveout();
	static void DepthSort();
	static bool Coalesce();
	void InsertSpillCode(int reg, int64_t offs);
	void InsertFillCode(int reg, int64_t offs);
	static void SetAllUncolored();
	void Color();
	static void ColorAll();
};

class Map
{
public:
	int newnums[1024];
};

// A "tree" is a "range" in Briggs terminology
class Tree : public CompilerType
{
public:
	int var;
	int num;
	CSet *blocks;
	int degree;
	int lattice;
	bool spill;
	__int16 color;
	int regclass;		// 1 = integer, 2 = floating point, 4 = vector
	// Cost accounting
	float loads;
	float stores;
	float copies;
	float others;
	bool infinite;
	float cost;
	static int treeno;
public:
	Tree() { };
	static Tree *MakeNew();
	void ClearCosts();
	float SelectRatio() { return (cost / (float)degree); };
};

class Forest
{
public:
	short int treecount;
	Tree *trees[1032];
	Function *func;
	CSet low, high;
	IntStack *stk;
	static int k;
	short int map[1024];
	short int pass;
	// Cost accounting
	float loads;
	float stores;
	float copies;
	float others;
	bool infinite;
	float cost;
	Var *var;
public:
	Forest();
	Tree *MakeNewTree();
	Tree *PlantTree(Tree *t);
	void ClearCosts() {
		int r;
		for (r = 0; r < treecount; r++)
			trees[r]->ClearCosts();
	}
	void ClearCut() {
		int r;
		for (r = 0; r < treecount; r++) {
			delete trees[r];
			trees[r] = nullptr;
		}
	};
	void CalcRegclass();
	void SummarizeCost();
	void Renumber();
	void push(int n) { stk->push(n); };
	int pop() { return (stk->pop()); };
	void Simplify();
	void PreColor();
	void Color();
	void Select() { Color(); };
	int SelectSpillCandidate();
	int GetSpillCount();
	int GetRegisterToSpill(int tree);
	bool SpillCode();
	void ColorBlocks();
	bool IsAllTreesColored();
	unsigned int ColorUncolorable(unsigned int);
};


class Var : public CompilerType
{
public:
	Var *next;
	int num;
	int cnum;
	Forest trees;
	CSet *forest;
	CSet *visited;
	IntStack *istk;
	int subscript;
	int64_t spillOffset;	// offset in stack where spilled
	static int nvar;
public:
	static Var *MakeNew();
	void GrowTree(Tree *, BasicBlock *);
	// Create a forest for a specific Var
	void CreateForest();
	// Create a forest for each Var object
	static void CreateForests();
	static void Renumber(int old, int nw);
	static void RenumberNeg();
	static Var *Find(int);
	static Var *Find2(int);
	static Var *FindByCnum(int);
	static Var *FindByMac(int reg);
	static Var *FindByTreeno(int tn);
	static CSet *Find3(int reg, int blocknum);
	static int FindTreeno(int reg, int blocknum);
	static int PathCompress(int reg, int blocknum, int *);
	static void DumpForests(int);
	void Transplant(Var *);
	static bool Coalesce2();
	Var *GetVarToSpill(CSet *exc);
};

class IGraph
{
public:
	int *bitmatrix;
	__int16 *degrees;
	__int16 **vecs;
	int size;
	int K;
	Forest *frst;
	int pass;
	enum e_am workingRegclass;
	enum e_op workingMoveop;
public:
	~IGraph();
	void Destroy();
	void MakeNew(int n);
	void ClearBitmatrix();
	void Clear();
	int BitIndex(int x, int y, int *intndx, int *bitndx);
	void Add(int x, int y);
	void Add2(int x, int y);
	void AddToLive(BasicBlock *b, Operand *ap, OCODE *ip);
	void AddToVec(int x, int y);
	void InsertArgumentMoves();
	bool Remove(int n);
	static int FindTreeno(int reg, int blocknum) { return (Var::FindTreeno(reg, blocknum)); };
	bool DoesInterfere(int x, int y);
	int Degree(int n) { return ((int)degrees[n]); };
	__int16 *GetNeighbours(int n, int *count) { if (count) *count = degrees[n]; return (vecs[n]); };
	void Unite(int father, int son);
	void Fill();
	void AllocVecs();
	void BuildAndCoalesce();
	void Print(int);
};


class Instruction
{
public:
	char *mnem;		// mnemonic
	short opcode;	// matches OCODE opcode
	short extime;	// execution time, divide may take hundreds of cycles
	unsigned int targetCount : 2;	// number of target operands
	bool memacc;	// instruction accesses memory
	unsigned int amclass1;	// address mode class, one for each possible operand
	unsigned int amclass2;
	unsigned int amclass3;
	unsigned int amclass4;
public:
	static void SetMap();
	static Instruction *GetMapping(int op);
	bool IsFlowControl();
	bool IsLoad();
	bool IsIntegerLoad();
	bool IsStore();
	bool IsExt();
	bool IsSetInsn() {
		return (opcode == op_seq || opcode == op_sne
			|| opcode == op_slt || opcode == op_sle || opcode == op_sgt || opcode == op_sge
			|| opcode == op_sltu || opcode == op_sleu || opcode == op_sgtu || opcode == op_sgeu
			);
	};
	static Instruction *FindByMnem(std::string& mn);
	static Instruction *Get(int op);
	inline bool HasTarget() { return (targetCount != 0); };
	int store(txtoStream& ofs);
	int storeHex(txtoStream& ofs);	// hex intermediate representation
	int storeHRR(txtoStream& ofs);	// human readable representation
	static Instruction *loadHex(std::ifstream& fp);
	int load(std::ifstream& ifs, Instruction **p);
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
	void AccUses(int val);					// accumulate uses
	void AccDuses(int val);					// accumulate duses
	int OptimizationDesireability();
};

class CSETable
{
public:
	CSE table[500];
	short int csendx;
	short int cseiter;
	short int searchpos;
public:
	CSETable();
	~CSETable();
	CSE *First() { cseiter = 0; return &table[0]; };
	CSE *Next() { cseiter++; return (cseiter < csendx ? &table[cseiter] : nullptr); };
	void Clear() { ZeroMemory(table, sizeof(table)); csendx = 0; };
	void Sort(int (*)(const void *a, const void *b));
	void Assign(CSETable *);
	int voidauto2(ENODE *node);
	CSE *InsertNode(ENODE *node, int duse, bool *first);
	CSE *Search(ENODE *node);
	CSE *SearchNext(ENODE *node);
	CSE *SearchByNumber(ENODE *node);

	void GenerateRegMask(CSE *csp, CSet *mask, CSet *rmask);
	int AllocateGPRegisters();
	int AllocateFPRegisters();
	int AllocateVectorRegisters();
	int AllocateRegisterVars();
	void InitializeTempRegs();

	int Optimize(Statement *);

	// Debugging
	void Dump();
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
	char *lptr;			// pointer to source code
	char *lptr2;			// pointer to source code
	unsigned int prediction : 2;	// static prediction for if statements
	int depth;
	
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
	static Statement *ParseSwitch();
	static Statement *Parse();

	// Optimization
	void scan();
	void scan_compound();
	void repcse();
	void repcse_compound();
	void update();
	void update_compound();

	// Code generation
	Operand *MakeDataLabel(int lab);
	Operand *MakeCodeLabel(int lab);
	Operand *MakeStringAsNameConst(char *s);
	Operand *MakeString(char *s);
	Operand *MakeImmediate(int64_t i);
	Operand *MakeIndirect(int i);
	Operand *MakeIndexed(int64_t o, int i);
	Operand *MakeDoubleIndexed(int i, int j, int scale);
	Operand *MakeDirect(ENODE *node);
	Operand *MakeIndexed(ENODE *node, int rg);
	void GenStore(Operand *ap1, Operand *ap3, int size);

	void GenMixedSource();
	void GenMixedSource2();
	void GenerateStop();
	void GenerateAsm();
	void GenerateFirstcall();
	void GenerateWhile();
	void GenerateUntil();
	void GenerateFor();
	void GenerateForever();
	void GenerateIf();
	void GenerateDoWhile();
	void GenerateDoUntil();
	void GenerateDoLoop();
	void GenerateDoOnce();
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

	// Debugging
	void Dump();
	void DumpCompound();
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
	static void AssignParameterName();
	static int declare(SYM *parent,TABLE *table,int al,int ilc,int ztype);
	static void ParseEnumerationList(TABLE *table, int amt, SYM *parent);
	static void ParseEnum(TABLE *table);
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
	static void ParseChar();
	static void ParseInt8();
	static void ParseByte();
	static void ParseFloat();
	static void ParseDouble();
	static void ParseTriple();
	static void ParseFloat128();
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
	static void ParseSuffixOpenpa(Function *);
	static SYM *ParseSuffix(SYM *sp);
	static void ParseFunctionAttribute(Function *sym);
	static void ParseAssign(SYM *sp);
	static void DoDeclarationEnd(SYM *sp, SYM *sp1);
	static void DoInsert(SYM *sp, TABLE *table);
	static void AllocFunc(SYM *sp, SYM *sp1);
	static SYM *FindSymbol(SYM *sp, TABLE *table);

	static int GenStorage(int nbytes, int al, int ilc);
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
	short int funcnum;
	SYM symbolTable[32768];
	Function functionTable[3000];
	TYP typeTable[32768];
	OperandFactory of;
	short int pass;
public:
	GlobalDeclaration *decls;
	Compiler();
	void compile();
	int PreprocessFile(char *nm);
	void CloseFiles();
	void AddStandardTypes();
	void AddBuiltinFunctions();
	static int GetReturnBlockSize();
	int main2(int c, char **argv);
	void storeHex(txtoStream& ofs);
	void loadHex(txtiStream& ifs);
	void storeTables();
};

class CPU
{
public:
	int nregs;
	bool SupportsPush;
	bool SupportsPop;
	bool SupportsLink;
	bool SupportsUnlink;
	bool SupportsBitfield;
	void SetRealRegisters();
	void SetVirtualRegisters();
};

//#define SYM     struct sym
//#define TYP     struct typ
//#define TABLE   struct stab

 
#endif
