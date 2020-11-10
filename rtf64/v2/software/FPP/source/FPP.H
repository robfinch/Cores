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
#define MAXLINE   300
#define STRAREA   640000
#define MAXMACROS 4001

#define DIGITS "0123456789abcdefghijklmnopqrstuvwxyz"

typedef struct
{
   char *name;    // name of the macro
   char *body;    // test to substitute when macro name is encountered
   int nArgs;     // Number of arguments passed to this macro
   int varg;      // variable argument list indicator
   int line;      // line number macro is defined on
   char *file;    // file macro is defined in
   char *st;		// start of definiton
   char *nd;		// end of definition
} SDef;

typedef struct
{
   char *name;
   int len;
   void (*func)(void);
}  SDirective;

void ProcFile(char *);

int icmp(const void *, const void *);
int fcmp(char *, SDef *);
int ecmp(SDef *);
char *StoreBody(char *,...);
char *StorePlainStr(char *);
char *StoreStr(char *, ...);



void err(int, ...);
long expeval(void);

void ProcLine(void);
int NextCh(void);
int NextNonSpace(int);
void SkipSpaces(void);
void unNextCh(void);
char *GetIdentifier(void);
void ScanPastEOL();

char *GetMacroBody(char *[]);
char *GetMacroArg(void);
int GetMacroParmList(char *[]);
void SubMacro(char *, int);
char *SubMacroArg(char *, int, char *);

void SearchAndSub(void);
void SearchForDefined(void);
void DoPastes(char *);

void ddefine(void);
void derror(void);
void dinclude(void);
void delse(void);
void delif(void);
void dendif(void);
void difdef(void);
void difndef(void);
void dif(void);
void dundef(void);
void dline(void);
void dpragma(void);

void searchenv(char *filename, char *envname, char *pathname);

SHashVal HashFnc(SDef *);

E char *identchars I(= "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@?0123456789");
extern SHashTbl HashInfo;
E char *inptr;       // pointer to current character in input buffer
E char inbuf[3000000];  // input buffer
extern int errors;
E int warnings;
E FILE *fin, *fout;
E FILE *fdbg;
E int verbose I(=0);
E int ShowLines I(=0);
E int CharCount I(=0);
E char *cmdStart I(=0);
E char *cmdEnd I(=0);
E int collect I(=0);
E int debug I(=0);

