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
#define STRAREA   640000
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
  char* buf;
} buf_t;

typedef struct
{
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
} SDef;

typedef struct _tagRep_t
{
  int ino;      // repeat instance number
  SDef* def;    // associated def
  int rcnt;      // current repeat counter (.rept)
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
}  SDirective;


buf_t* new_buf();
buf_t* enlarge_buf(buf_t* b);
buf_t* clone_buf(buf_t* b);
void insert_into_buf(buf_t** buf, char* p, int pos);
size_t SymSpaceLeft();
void ProcFile(char *);

int icmp(const void *, const void *);
int fcmp(char *, SDef *);
int ecmp(SDef *);
char *StoreBody(char *,...);
char *StorePlainStr(char *);
char *StoreStr(char *, ...);



void err(int, ...);
long expeval(void);

int ProcLine(void);
int NextCh(void);
int NextNonSpace(int);
void SkipSpaces(void);
void unNextCh(void);
char *GetIdentifier(void);
void ScanPastEOL();

buf_t *GetMacroBody(SDef*, int opt);
char *GetMacroArg(void);
int GetMacroParmList(arg_t *[]);
void SubMacro(char *, int);
char *SubMacroArg(char *, int, char *);
int SubParmMacro(SDef* p, int opt);

void SearchAndSub(SDef* excld);
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

void searchenv(char *filename, char *envname, char *pathname, int pathsize);
char* rtrim(char*);

char syntax_ch();
int GetReptArgList(arg_t* arglist[], int opt);

SHashVal HashFnc(SDef *);

E char *identchars I(= "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@?0123456789");
extern SHashTbl HashInfo;
E char *inptr;      // pointer to current character in input buffer
E buf_t* inbuf;     // input buffer
extern int errors;
E int warnings;
E FILE *fin, *fout,* ofp;
E FILE *fdbg;
E int verbose I(=0);
E int ShowLines I(=0);
E int CharCount I(=0);
E char *cmdStart I(=0);
E char *cmdEnd I(=0);
E int collect I(=0);
E int debug I(=0);
E int lasttk I(= 0);
E int in_comment I(= 0);
E int syntax I(= 0);
extern char *SkipComments();
