/* ---------------------------------------------------------------------------
   
   (C) 1992 FinchWare

   fpp.h

   Description :   Header file for cpp.

   Changes
           Author      : R. Finch
           Date        : /90
           Release     :
           Description : new module

--------------------------------------------------------------------------- */

#ifndef _INTTYPES
#  include <inttypes.h>
#endif

#ifndef HT_H
#  include <ht.h>
#endif

#ifdef ALLOC
#  define E
#  define I(x) x
#else
#  define E extern
#  define I(x)
#endif

#define IsIdentChar(ch)       strchr(identchars, (ch))
#define IsFirstIdentChar(ch)  (isalpha((ch)) || (ch) == '_')
#define PeekCh()              (*inptr)

#define FALSE     0
#define TRUE      1
#define MAXLINE   4000
#define STRAREA   1000000
#define MAXMACROS 4001
#define MAX_MACRO_ARGS  100

#define DIGITS "0123456789abcdefghijklmnopqrstuvwxyz"

#define CSTD 0
#define ASTD 1

typedef struct
{
  int num;        // parameter number
  char* name;     // parameter name
  char* def;      // default value
} arg_t;

typedef struct
{
  int size;
  int pos;
  int alloc;      // 0 = malloc, 1 = some other buffer.
  char* buf;
} buf_t;

typedef struct
{
  int defno;
  char *name;    // name of the macro
  buf_t *body;    // text to substitute when macro name is encountered
  int nArgs;     // Number of arguments passed to this macro
  int varg;      // variable argument list indicator
  int line;      // line number macro is defined on
  char *file;    // file macro is defined in
  arg_t** parms;
  buf_t* abody;  // text to substitute when macro name is encountered
  char *st;		// start of definiton
  char *nd;		// end of definition
  int inst;     // instance counter for this def.
} def_t;

typedef struct
{
  int defno;     // repeat definition number
  def_t* def;    // associated def
  int rcnt;     // current repeat counter (.rept)
  int orcnt;    // original repeat count
  char* st;      
  char* nd;
} rep_t;

typedef struct
{
  char *name;
  int len;
  void (*func)(int);
  int syntax;
  int opt;
} directive_t;

typedef struct
{
  FILE* file;
  int64_t bufpos;
} pos_t;

buf_t* new_buf();
void free_buf(buf_t*);
buf_t* enlarge_buf(buf_t* b);
buf_t* clone_buf(buf_t* b);
void insert_into_buf(buf_t** buf, char* p, int pos);

def_t* new_def();
def_t* clone_def(def_t*);

pos_t* GetPos();
void SetPos(pos_t*);
size_t SymSpaceLeft();
void ProcFile(char *);

int icmp(const void *, const void *);
int fcmp(char *, def_t *);
int ecmp(def_t *);
char *StoreBody(char *,...);
char *StorePlainStr(char *);
char *StoreStr(char *, ...);



void err(int, ...);
long expeval(void);
int directive(char* p);

int ProcLine(void);
int NextCh(void);
int NextNonSpace(int);
void SkipSpaces(void);
void unNextCh(void);
char *GetIdentifier(void);
void ScanPastEOL();

buf_t *GetMacroBody(def_t*, int opt, int rpt);
char *GetMacroArg(void);
int GetMacroParmList(arg_t *[]);
void SubMacro(char *, int);
char *SubMacroArg(char *, int, char *, int rpt);
int SubParmMacro(def_t* p, int opt, int rpt);

void SearchAndSub(def_t* excld);
void SearchForDefined(void);
void DoPastes(char *);

void ddefine(int);
void derror(int);
void dinclude(int);
void delse(int);
void delif(int);
void dendif(int);
void difdef(int);
void difndef(int);
void dif(int);
void dundef(int);
void dline(int);
void dpragma(int);
void dendm(int);
void drept(int);
void dendr(int);

void searchenv(char *filename, char *envname, char *pathname, int pathsize);
// Utility type functions
char* rtrim(char*);
char* strip_quotes(char*);
char* strip_blank_lines(char*);
int is_blank(char*);

char syntax_ch();
int GetReptArgList(arg_t* arglist[], int opt);

SHashVal HashFnc(def_t *);

E char *identchars I(= "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@?0123456789");
extern SHashTbl HashInfo;   // Hash table for storing macro definitions
E char *inptr;              // pointer to current character in input buffer
E buf_t* inbuf;             // input buffer
extern int errors;          // number of errors that occurred
E int warnings;             // number of warnings
E FILE *fin, * ofp;         // current input and output file pointers
E FILE *fdbg;               // file pointer for debug info
E int verbose I(=0);
E int ShowLines I(=0);
E int debug I(= 0);
E int syntax I(= 0);        // stores the selected syntax
E int npass I(=0);          // number of passes to perform-1
E int collect I(=0);        // Tells the input to collect up lines of text for a macro
E int in_comment I(= 0);    // Indicates if the input is in a comment
extern int rep_def_cnt;     // Repeat block definition counter
extern int rept_inst;       // Repeat block instance counter
extern int inst;            // def instance counter
extern int mac_depth;       // nessted macro definition depth
extern int rep_depth;       // nested repeat instance depth
extern char *SkipComments();
