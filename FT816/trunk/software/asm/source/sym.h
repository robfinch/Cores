#pragma once

#include <string.h>
#include <stdio.h>
#include "ListObject.h"
#include "MyString.h"
#include "Declarator.h"
#include "HashTable.h"


#define NAME_MAX  32    // Maximum identifier length.
#define LABEL_MAX 32    // Maximum output label length.

#define L_STRING  "S"
#define ALIGN_WORST  4

#define BYTE_PREFIX  "b"
#define WORD_PREFIX  "w"
#define LWORD_PREFIX "l"
#define PTR_PREFIX   "P"
#define BYTEPTR_PREFIX  "bP"
#define WORDPTR_PREFIX  "wP"
#define LWORDPTR_PREFIX "lP"
#define PTRPTR_PREFIX   "pP"

namespace RTFClasses
{
// specifier noun. INT has the value 0 so that an 
// uninitialized structure defaults to int, same
// goes for EXTERN, below.

// Primitive Types
enum ePrimType {
	ptINT = 0,
	ptCHAR,
	ptSTRING,
	ptFLOAT,
	ptDOUBLE,
	ptBOOL,
	ptVOID,
	ptTIME,
	ptDATE,
	ptCURRENCY,
	ptSTRUCTURE,
	ptLABEL,
	ptNYBBLE,
	ptBIT,
	ptBYTE,
	ptWORD,
	ptLWORD,
	ptDWORD,
	ptENUM
};

//#define ISIZE     2
//#define LSIZE     4
//#define PSIZE     4

// Storage classes
enum eStorageClass {
	scFIXED,		// at a fixed address
	scREGISTER,	// in a register
	scAUTO,		// on the runtime stack
	scCONSTANT,	// in code
	scTYPEDEF
};

#define NO_OCLASS 0     // no output class (var is auto)
#define PUB       1     // public
#define PRI       2     // private
#define EXT       3     // extern
#define COM       4     // common


// Sections

#define DATA      0
#define CODE      1
#define BSS       2

typedef int Date;
typedef int Time;

/*    Currency var is represented as a packed 18 digit BCD number
   compatible with numeric coprocessor format.
*/
typedef struct
{
   char decimals;       /* number of decimal places */
   char sgn;            /* sign 128 if negative, 0 if positive */
   char man[9];         /* mantissa */
} Currency;


	class SymbolTable;
	class ExtRefTbl;
	class Symbol;


	class StructDef
	{
		friend class StructTbl;
	public:
		String tag;
		int level;		// Nesting level at which struct declared
		Symbol *fields;	// Link list of field declarations
		int size;		// Size of structure in bytes
	};


/* --------------------------------------------------------------------------
   Link class. Used for links in type chain of variable.
-------------------------------------------------------------------------- */
/*
class SpecOrDec
{
public:
   void DeleteChain();
   void CpySpec(SpecOrDec *);
   SpecOrDec *clone(SpecOrDec **);
   long GetSizeof();
   char *TypeStr();
   char *ConstStr();

   // Declaration Processing
   SpecOrDec *NewClassSpec(int);
   void SetClassBit(int);
   SpecOrDec *NewTypeSpec(char *);
   int GetAlignment();

   // Value Processing
   char *GetPrefix();
   size_t GetSize();

   int IsLabel() { return (IsDeclarator() && DCL_TYPE == LABEL); };
};

*/

class Symbol : public ListObject
{
	friend class SymbolTable;

	String name;

	// VECTOR: location of symbol
	int line;			// line symbol defined on
	int file;			// file number symbol defined in

	bool defined;		// definition for symbol has been encountered
	bool label;			// True if address label
	int level;			// declaration level, field offset
	bool implicit;		// declaration created implicitly
	bool duplicate;		// duplicate declaration
	char oclass;		// output storage class PUB/PRI/COM/EXT
	int base;			// CODE, DATA, or BSS

	bool _long;			// true = long
	char size;			// 'B', 'W', or 'L'
	int noun;			// CHAR INT STRUCTURE LABEL bool time currency real
	int sclass;			// REGISTER AUTO FIXED CONSTANT TYPEDEF
	bool _static;		// 1 = static keyword found in declarations.
	bool _private;		// 1 = private keyword found in declarations.
	bool _volatile;		// volatile
	bool _extern;		// true iff extern keyword found in declarations.
	bool _intr;			// 1 = interrupt function declaration
	bool _trap;			// 1 = trap function declaration

	int section;          // Symbol location CODE/DATA/BSS

	Declarator *type;		// first link in declarator chain
	Symbol *args;           // If a function, the arg list
							// If a var, the initializer
	Symbol *next;           // Cross link to next variable at current nesting level
	__int64 value;			// symbol value

public:
	Symbol() { phaseErr = false; defined = false; };
	bool phaseErr;
	bool isDefined() { return defined; };
	bool isExtern() { return _extern; };
	bool isLabel() { return label; };

	bool isBool() { return noun == ptBOOL; };
	bool isBit()  { return noun == ptBIT; };
	bool isChar() { return noun == ptCHAR; };
	bool isInt()  { return noun == ptINT; };
	bool isTime() { return noun == ptTIME; };
	bool isDate() { return noun == ptDATE; };
	bool isString() { return noun == ptSTRING; };
	bool isCurrency() { return noun == ptCURRENCY; };

	bool isLong () { return (isInt() && _long); };

	bool isStruct() { return noun == ptSTRUCTURE; };
//	bool isAggregate() { return (isArray() || isStruct()); };
//	bool isPtrType() { return (isArray() || isPointer()); };
	bool isConstant() { return sclass == scCONSTANT; };
	bool isTypeDef() { return sclass == scTYPEDEF; };
	bool isIntConstant() { return isConstant() && noun == ptINT; };

	bool isSameType(Symbol *, int) { return true; };	// Do type chains match ?
	long getSizeof() { return 4; };

	void setBase(int bs) { base = bs; };
	void setSize(char sz) { size = sz; _long = (sz == 'L') ? 1 : 0; };
	void setValue(__int64 val) { value = val; };
	void setLong(bool lng) { _long = lng; };
	void setName(char *nm) { name.copy(nm); };
	void setLine(int ln) { line = ln; };
	void setFile(int fl) { file = fl; };
	void setDefined(bool df) { defined = df; };
	void setOClass(int oc) { oclass = oc; };
	void setLabel(bool lb) { label = lb; };

	String getName() { return name; };
	__int64 getValue() { return value; };

	void Def(int oc, int ln, int fl) { oclass = oc; line = ln; file = fl; if (oc==EXT) _extern = true; else _extern = false; };
	int getSize() { return size; };
	void define(int);
	HashVal getHash() {  return name.hashPJW(); };
	bool equals(Symbol *);
	int cmp(Object *);
	void print(FILE *);
	int print2(FILE *);
	const char *oclassstr(int n) const;
	const char *basestr(int n) const;
};


	class ExtRef
	{
		friend class ExtRefTbl;
		char type;			// reference type
		Symbol *pSym;		// pointer to symbol in global symbol table
		long offset;		// offset into segment where fix occurs
	};


	class SymbolTable : public HashTable
	{
	public:

		SymbolTable(int n) : HashTable(n) {};

		Symbol *next(Symbol *);
		void printHeading(FILE *fp);
		bool print(FILE *, int);
		Symbol *insert(Symbol *s) { return (Symbol *)HashTable::insert((ListObject *)s); };
		void remove(Symbol *s) { HashTable::remove((ListObject *)s); };
		Symbol *find(Symbol *s) { return (Symbol *)HashTable::find((ListObject *)s); };
		int getExternCount() const {
			int ii,undef=0;
			int cnt = countObjects();
			Symbol **symlist = (Symbol **)getLinearList();
			for (ii = 0; ii < cnt; ii++) {
				if (symlist[ii]) {
					if (symlist[ii]->isExtern()==true)
						undef++;
				}
			}
			delete[] symlist;
			return undef;
		};
		int getUndefinedCount() const {
			int ii,undef=0;
			int cnt = countObjects();
			Symbol **symlist = (Symbol **)getLinearList();
			for (ii = 0; ii < cnt; ii++) {
				if (symlist[ii]) {
					if (symlist[ii]->isDefined()!=true)
						undef++;
				}
			}
			delete[] symlist;
			return undef;
		}

	};


	class StructTbl : public HashTable
	{
		friend class StructDef;
		int NumStructDefs;
		unsigned sz;
		StructDef **tbl;
	public:
		StructTbl(int n) : HashTable(n) {};
	};


	class ExtRefTbl : public HashTable
	{
		friend class ExtRef;
		int NumRefs;
		unsigned sz;         // max number of references
		ExtRef *tbl;        // pointer to table
	public:
		ExtRefTbl(int n) : HashTable(n) {};
	};
}
