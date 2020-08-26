#ifndef SYM_H
#define SYM_H

#include <string.h>
#include <malloc.h>

#ifndef HASH_H
#include "d:\projects\fw\inc\hash.h"
#endif

#undef E
#ifdef ALLOC
#  define E
#else
#  define E  extern
#endif

#define NAME_MAX  32    // Maximum identifier length.
#define LABEL_MAX 32    // Maximum output label length.

#define DECLARATOR   0
#define SPECIFIER    1

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

// Types
#define INT       0     // specifier noun. INT has the value 0 so that an 
#define CHAR      1     // uninitialized structure defaults to int, same
#define FLOAT     2     // goes for EXTERN, below.
#define REAL      2
#define DOUBLE    2
#define STRING    3
#define VOID      4
#define STRUCTURE 5
#define LABEL     6
#define BIT       7
#define BOOL      7
#define TIME      8
#define DATE      9
#define CURRENCY  10
#define NYBBLE    11
#define BYTE      12
#define WORD      13
#define LWORD     14
#define DWORD     14
#define ENUM      15

#define ISIZE     2
#define LSIZE     4
#define PSIZE     4

// Storage classes
#define FIXED     0     // at a fixed address
#define REGISTER  1     // in a register
#define AUTO      2     // on the run-time stack
#define TYPEDEF   3
#define CONSTANT  4


#define NO_OCLASS 0     // no output class (var is auto)
#define PUB       1     // public
#define PRI       2     // private
#define EXT       3     // extern
#define COM       4     // common


// values for declarator type.

#define POINTER   0
#define ARRAY     1
#define FUNCTION  2


// Sections

#define DATA      0
#define CODE      1
#define BSS       2


// Use the following p->XXX where p is a pointer to a link structure.

#define SPEC      sd.s
#define NOUN      sd.s.noun
#define SCLASS    sd.s.sclass
#define LONG      sd.s._long
#define UNSIGNED  sd.s._unsigned
#define UNICODE   sd.s._unicode
#define EXTERN    sd.s._extern
#define STATIC    sd.s._static
#define VOLATILE  sd.s._volatile
#define INTERRUPT sd.s._intr
#define TRAP      sd.s._trap
#define OCLASS    sd.s.oclass
#define SECTION   sd.s.section

#define DCL_TYPE  sd.d.dcl_type
#define NUM_ELE   sd.d.num_ele

#define VALUE     sd.s.const_val
#define V_BIT     VALUE.v_bit
#define V_BOOL    VALUE.v_bool
#define V_INT     VALUE.v_int
#define V_UINT    VALUE.v_uint
#define V_LONG    VALUE.v_long
#define V_ULONG   VALUE.v_ulong
#define V_STRUCT  VALUE.v_struct
#define V_REAL    VALUE.v_double
#define V_FLOAT   VALUE.v_double
#define V_DOUBLE  VALUE.v_double
#define V_TIME    VALUE.v_time
#define V_DATE    VALUE.v_date
#define V_STRING  VALUE.v_string
#define V_CURRENCY   VALUE.v_currency
#define V_BYTE    VALUE.v_byte
#define V_WORD    VALUE.v_word
#define V_DWORD   VALUE.v_dword
#define V_NYBBLE  VALUE.v_nybble
#define V_OFFSET  VALUE.v_offset

typedef long SDate;
typedef long STime;

//    Strings are represented with an int specifying the length of the
// string followed by a pointer to the string itself.
typedef struct
{
   int len;
   char *ptr;
} SString;

/*    Currency var is represented as a packed 18 digit BCD number
   compatible with numeric coprocessor format.
*/
typedef struct
{
   char decimals;       /* number of decimal places */
   char sgn;            /* sign 128 if negative, 0 if positive */
   char man[9];         /* mantissa */
} SCurrency;


class CSymbolTbl;
class CExtRefTbl;
class CSymbol;


class CStructDef
{
   friend class CStructTbl;
public:
   char tag[NAME_MAX+1];
   unsigned char level;    // Nesting level at which struct declared
   CSymbol *fields;        // Link list of field declarations
   unsigned size;          // Size of structure in bytes
};


// There is one and only one specifier for each variable
class CSpecifier
{
public:
   unsigned noun        : 5;  /* CHAR INT STRUCTURE LABEL bool time currency real */
   unsigned sclass      : 3;  /* REGISTER AUTO FIXED CONSTANT TYPEDEF */
   unsigned oclass      : 3;  /* output storage class: PUB PRI COM EXT. */
   unsigned _long       : 1;  /* 1 = long,      0 = short,  1 = unicode,   0 = ascii */
   unsigned _unsigned   : 1;  /* 1 = unsigned,  0 = signed */
   unsigned _unicode    : 1;  /* 1 = unicode,   0 = ascii */
   unsigned _static     : 1;  /* 1 = static keyword found in declarations. */
   unsigned _private    : 1;  /* 1 = private keyword found in declarations. */
   unsigned _volatile   : 1;  /* 1 = volatile */
   unsigned _extern     : 1;  /* 1 = extern keyword found in declarations. */
   unsigned _intr       : 1;  // 1 = interrupt function declaration
   unsigned _trap       : 1;  // 1 = trap function declaration
   unsigned section;          // Symbol location CODE/DATA/BSS

   union
   {
      unsigned long  v_offset;
      unsigned int   v_bool;
      int            v_int;
      unsigned int   v_bit;
      unsigned int   v_byte;
      unsigned int   v_nybble;
      unsigned int   v_uint;
      unsigned int   v_word;
      long           v_long;
      unsigned long  v_ulong;
      unsigned long  v_dword;
      double         v_real;
      STime          v_time;
      SDate          v_date;
      SString        *v_string;
      SCurrency      v_currency;
      CStructDef     *v_struct;
   } const_val;
public:
   char *AttrStr();
   char *NounStr();
   char *sclassStr();
   char *oclassStr();
};


typedef struct SDeclarator
{
   unsigned int dcl_type : 2;    // POINTER, ARRAY, or FUNCTION.
   unsigned long num_ele : 30;   // If class == ARRAY, # of elements.
} SDeclarator;


/* --------------------------------------------------------------------------
   Link class. Used for links in type chain of variable.
-------------------------------------------------------------------------- */
class CLink
{
   CLink *next;
   unsigned lclass : 1;    // Declarator or specifier.
   unsigned tdef : 1;      // chain was created by a typedef.

   union
   {
      CSpecifier s;
      SDeclarator d;
   } sd;

public:
   void *operator new(size_t sz);
   void operator delete(void *);
   CLink() { };
   CLink(unsigned lc, unsigned nn) { lclass = lc; NOUN = nn; };
   CLink(unsigned lc, unsigned nn, CStructDef *ps) { lclass = lc; NOUN = nn; V_STRUCT = ps; };
   void DeleteChain();
   void CpySpec(CLink *);
   CLink *clone(CLink **);
   int IsSameType(CLink *, int);    // Do type chains match ?
   long GetSizeof();
   char *TypeStr();
   char *ConstStr();

   // Declaration Processing
   CLink *NewClassSpec(int);
   void SetClassBit(int);
   CLink *NewTypeSpec(char *);
   int GetAlignment();

   // Value Processing
   char *GetPrefix();
   size_t GetSize();

   int IsSpecifier() { return (lclass == SPECIFIER); };
   int IsDeclarator() { return (lclass == DECLARATOR); };

   int IsArray() { return (IsDeclarator() && DCL_TYPE == ARRAY); };
   int IsPointer() { return (IsDeclarator() && DCL_TYPE == POINTER); };
   int IsFunc() { return (IsDeclarator() && DCL_TYPE == FUNCTION); };
   int IsLabel() { return (IsDeclarator() && DCL_TYPE == LABEL); };

   int IsStruct() { return (IsSpecifier() && NOUN == STRUCTURE); };

   int IsBool() { return (IsSpecifier() && NOUN == BOOL); };
   int IsBit() { return (IsSpecifier() && NOUN == BIT); };
   int IsChar() { return (IsSpecifier() && NOUN == CHAR); };
   int IsInt() { return (IsSpecifier() && NOUN == INT); };
   int IsReal() { return (IsSpecifier() && NOUN == REAL); };
   int IsTime() { return (IsSpecifier() && NOUN == TIME); };
   int IsDate() { return (IsSpecifier() && NOUN == DATE); };
   int IsString() { return (IsSpecifier() && NOUN == STRING); };
   int IsCurrency() { return (IsSpecifier() && NOUN == CURRENCY); };

   int IsLong () { return (IsInt() && LONG); };
   int IsUInt () { return (IsInt() && UNSIGNED); };
   int IsULong () { return (IsInt() && LONG && UNSIGNED); };
   int IsUnsigned() { return (UNSIGNED); };
   int IsUnicode() { return (IsString() && LONG); };

   int IsAggregate() { return (IsArray() || IsStruct()); };
   int IsPtrType() { return (IsArray() || IsPointer()); };
   int IsConstant() { return (IsSpecifier() && SCLASS == CONSTANT); };
   int IsTypeDef() { return (IsSpecifier() && SCLASS == TYPEDEF); };
   int IsIntConstant() { return (IsConstant() && NOUN == INT); };
};


/* --------------------------------------------------------------------------
   Symbol class. 
-------------------------------------------------------------------------- */
extern int pass;

class CReference
{
public:
	unsigned __int64 location;
	CReference *next;
};

class CSymbol
{
   friend class CSymbolTbl;
   unsigned char name[NAME_MAX+1];
   unsigned __int16 name_ndx;		// index into string table
   unsigned level;            // declaration level, field offset
   unsigned implicit : 1;     // declaration created implicitly
   unsigned duplicate : 1;    // duplicate declaration
   unsigned oclass : 3;       // output storage class PUB/PRI/COM/EXT
   unsigned base : 2;         // CODE, DATA, or BSS
   unsigned defined : 1;
   unsigned label : 1;			// True if address label
   unsigned _long;            // 1 = long, 0 = short
   unsigned char size;        // 'B', 'W', or 'L'
   CLink *type;               // first link in declarator chain
   CLink *etype;              // Last link in declarator chain
   CSymbol *args;             // If a funct decl, the arg list
                              // If a var, the initializer
   CSymbol *next;             // Cross link to next variable at
                              // current nesting level
   int line;                  // line symbol defined on
   int file;                  // file number symbol defined in
   CReference *references;		// counter locations that the symbol is referenced from

public:
   __int64 value;             // symbol value
   unsigned PhaseErr : 1;
	 unsigned reglist : 1;			// 1 = register list value
public:
	int min(int a, int b) { return a < b ? a : b; };
   void SetBase(int bs) { base = bs; };
   void SetSize(char sz) { size = sz; _long = (sz == 'L') ? 1 : 0; };
   void SetValue(__int64 val) { value = val; };
   void SetLong(int lng) { _long = lng; };
   void SetName(char *nm) { strncpy((char *)&name, nm, NAME_MAX); };
   void SetLine(int ln) { line = ln; };
   void SetFile(int fl) { file = fl; };
   void SetDefined(int df) { defined = df; };
   void SetOClass(int oc) { oclass = oc; };
   void SetLabel(int lb) { label = lb; };
	char *Name() { 	return (char *)name; };
   __int64 Value() { return value; };
   void Def(int oc, int ln, int fl) { oclass = oc; line = ln; file = fl; };
   int Size() { return size; };
   int Defined() { return defined; };
   void define(int);
   int IsLabel() { return label; };
   bool IsExtern() { return oclass==EXT; };
   SHashVal hash(int);
   int cmp(CSymbol *);
   int print(FILE *);
   CReference *NewReference() { return new CReference(); };
   void AddReference(unsigned __int64 n);
};

class CExtRef
{
   friend class CExtRefTbl;
   char type;                 // reference type
   CSymbol *pSym;             // pointer to symbol in global symbol table
   long offset;               // offset into segment where fix occurs
};


/* -------------------------------------------------------------------------
   Description :
      The hash bucket is merely a header for a block of memory containing
   a pointer to a bucket chain containing the actual hashed information.
   This header contains information neccesary for linking hash buckets in
   a chain (used for managing collisions).
        Note the backward pointer (prev) is a pointer to a pointer to
   account for the fact that the head of the chain is only a simple
   pointer NOT an entire bucket structure.
------------------------------------------------------------------------- */

class CHashBucket
{
public:
   CHashBucket *next;
   CHashBucket **prev;

   void insert(CHashBucket *, CHashBucket **);
   void remove();
};

/* --------------------------------------------------------------------------
   Description :
      Bucket based symbol table class definition. Collisions are handled
   by extending the table with a linked list of buckets containing
   collided symbols at that location. Data is not actually stored in the
   base table, rather the bucket pointer points to memory containing a
   bucket header followed by data for the stored symbol.
-------------------------------------------------------------------------- */

class CSymbolTbl
{
   friend class CSymbol;
	char *string_table;	// table of name strings
   int NumSyms;         // Number of symbols stored in the table
   unsigned sz;         // Number of elements in table
   CHashBucket **tbl;   // pointer to table
public:

   CSymbolTbl(unsigned);
   ~CSymbolTbl();

   int print(FILE *, int);
   void *next(void *);

   CSymbol *allocsym();
   void freesym(CSymbol *);

   CSymbol *insert(CSymbol *);
   void remove(CSymbol *);
   CSymbol *find(CSymbol *);
   CSymbol *next(CSymbol *);
   void sort(CHashBucket **);
   char *BuildStringTable();
};


class CStructTbl
{
   friend class CStructDef;
   int NumStructDefs;
   unsigned sz;
   CHashBucket **tbl;
public:
   ~CStructTbl() { if (tbl) ::free(tbl); };
};


class CExtRefTbl
{
   friend class CExtRef;
   int NumRefs;
   unsigned sz;         // max number of references
   CExtRef *tbl;        // pointer to table
public:
   CExtRefTbl(unsigned);
   ~CExtRefTbl() { if (tbl) ::free(tbl); };
};

#endif

