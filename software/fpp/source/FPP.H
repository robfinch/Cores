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

#define LF 0x0a
// The following character is used to mark the end of the file during processing.
// It is removed from the file at the end.
#define ETB 0x17    // End of transmission block

#define IsIdentChar(ch)       strchr(identchars, (ch))
#define IsFirstIdentChar(ch)  (isalpha((ch)) || (ch) == '_')
#define PeekCh()              (*inptr)

#define FALSE     0
#define TRUE      1

// The following is the maximum number of chars the input will fetch at one time.
#define MAXLINE   4000

#define STRAREA   1000000

// The following controls the size of the hash table used to store symbols.
#define MAXMACROS 4001

// The maximum number of arguments associated with a macro.
#define MAX_MACRO_ARGS  100

// The following controls how many times the substituter will loop performing
// substitutions. It is a safety.
#define MAX_SUBS  10000

// (Not yet implemented)
// The following controls when the buffer is slid. If the input pointer is past
// this point, then the buffer will slide to reduce the memory footprint.
// Macro expansions are limited by this size.
#define SLIDE_SZ  4096

#define DIGITS "0123456789abcdefghijklmnopqrstuvwxyz"

#define CSTD 0
#define ASTD 1

typedef enum {
  DIR_NONE = 0,
  DIR_REPT = 1,
  DIR_ENDM = 2,
  DIR_ENDIF = 3,
  DIR_ENDR = 4,
  DIR_MACR = 5,
  DIR_IF = 6,
  DIR_IFDEF = 7,
  DIR_IRP = 8,
  DIR_ELSE = 9,
  DIR_ELIF = 10
} dir_e;

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
  int64_t st;		// start of definiton (index)
  int64_t nd;		// end of definition (index)
  int inst;     // instance counter for this def.
} def_t;

typedef struct
{
  int defno;     // repeat definition number
  def_t* def;    // associated def
  int rcnt;     // current repeat counter (.rept)
  int orcnt;    // original repeat count
  int done;     // 1= done already
  char* st;      
  char* nd;
  int64_t start;  // start and end of repeat definition
  int64_t end;
  int64_t bdystart; // start and end of repeat body text
  int64_t bdyend;
} rep_t;

typedef struct
{
  char *name;
  int len;
  void (*func)(int, char*);
  int syntax;
  int opt;
  dir_e flags;
} directive_t;

typedef struct
{
  FILE* file;
  int64_t bufpos;
} pos_t;

buf_t* new_buf();
void free_buf(buf_t*);
void enlarge_buf(buf_t** b);
buf_t* clone_buf(buf_t* b);
void insert_into_buf(buf_t** buf, char* p, int pos);
void char_to_buf(buf_t** buf, char ch);
int64_t get_input_buf_ndx();
void set_input_buf_ptr(int64_t ndx);
int check_buf_ptr(buf_t* buf, char* ptr);

def_t* new_def();
void free_def(def_t* def);
def_t* clone_def(def_t*);

pos_t* GetPos();
void SetPos(pos_t*);
size_t SymSpaceLeft();

int icmp(const void *, const void *);
int fcmp(char *, def_t *);
int ecmp(def_t *);
char *StoreBody(char *,...);
char *StorePlainStr(char *);
char *StoreStr(char *, ...);



void err(int, ...);
int64_t expeval(int* undef);
int directive(char* p, char** pos);
int directive_id(char* p, char** pos);

void ProcFile(char*);
int ProcLine(void);
int NextCh();
int NextNonSpace(int);
void SkipSpaces();
void unNextCh(void);
char *GetIdentifier();
void ScanPastEOL();
void input_to(buf_t*);
void fetch_line();
int peek_eof();

buf_t *GetMacroBody(def_t*, int opt, int rpt, int dodir);
char *GetMacroArg(void);
int GetMacroParmList(arg_t *[]);
void SubMacro(buf_t*, int, int);
char *SubMacroArg(char *, int, char *, arg_t* def);
int SubParmMacro(def_t* p, int opt, pos_t* id_pos);
void mac_collect(buf_t** buf, int opt);

int SearchAndSub(def_t* excld, int opt, char** nd);
int SearchAndSubBuf(buf_t** buf, int opt, char** nd);
void SearchForDefined(void);
void DoPastes(char *);

void ddefine(int, char*);
void derror(int, char*);
void dinclude(int, char*);
void delse(int, char*);
void delif(int, char*);
void dendif(int, char*);
void difdef(int, char*);
void difndef(int, char*);
void dif(int, char*);
void dundef(int, char*);
void dline(int, char*);
void dpragma(int, char*);
void dendm(int, char*);
void drept(int, char*);
void dendr(int, char*);

void searchenv(char *filename, char *envname, char *pathname, int pathsize);
// Utility type functions
char* rtrim(char*);
char* strip_quotes(char*);
char* strip_blank_lines(char*);
char* strip_directives(char*);
int is_blank(char*);
int count_lines(char* buf);
int line_length(char* buf);

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
extern int IfLevel;
extern int sub_pass;