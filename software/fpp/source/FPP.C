#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <malloc.h>
#include <time.h>
#include <dos.h>
#include <ht.h>
#include <direct.h>
#include <inttypes.h>

#define ALLOC
#include "fpp.h"

/* ---------------------------------------------------------------------------
   (C) 1992-2024 Robert T Finch

   fpp - PreProcessor for Assembler / Compiler
   This file contains processing for main and most of the directives.
--------------------------------------------------------------------------- */

void ShellSort(void *, int, int, int (*)());   // Does a shellsort - like bsort()
SHashVal HashFnc(void *def);
int icmp (const void *n1, const void *n2);

int errors;
int InLineNo = 1;
char SourceName[250];
char OutputName[250];
char BaseSourceName[250];
//char *SymSpace, *SymSpacePtr;
buf_t* SymSpace;
SHashTbl HashInfo = { HashFnc, icmp, 0, sizeof(def_t), NULL };
int MacroCount;
FILE *ofp;
int banner = 1;
int ostdo = 1;
int pass = 0;
int keep_output = 0;
FILE* ifps[20];
int ifp_sp = 0;
int rep_def_cnt = 0;
int rept_inst = 0;
int inst=0;      // macro instance
char incdir[4096];    // additional include directory specified with .incdir
int inst_stk[20];
int inst_sp;

// Storage for standard #defines

def_t
bbstdc = { 0, "__STDC__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbline = { 0, "__LINE__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbdate = { 0, "__DATE__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbfile = { 0, "__FILE__", NULL, -1, 0, 0, "<fpp>", NULL },
  bbbasefile = { 0, "__BASEFILE__", NULL, -1, 0, 0, "<fpp>", NULL },
  bbtime = { 0, "__TIME__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbpp   = { 0, "__PP__", NULL, -1, 0, 0, "<fpp>", NULL };

void PrintDefines(void);

size_t SymSpaceLeft()
{
  return (SymSpace->size - SymSpace->pos);
}

/*****************************************************************************
   Functions for parser (RR(0)).
*****************************************************************************/

SHashVal HashFnc(void *d)
{
   def_t *def = (def_t *)d;
   return htSymHash(&HashInfo, def->name);
}



/* ----------------------------------------------------------------------------
      Comparison routines.
---------------------------------------------------------------------------- */

int icmp (const void *m1, const void *m2)
{
    def_t *n1; def_t *n2;
    n1 = (def_t *)m1;
    n2 = (def_t *)m2;
	if (n1->name==NULL) return 1;
	if (n2->name==NULL) return -1;
  return (strcmp(n1->name, n2->name));
}

int fcmp(char *key, def_t *n2)
{
   printf("Key:%s, Entry:%s|\n", key, n2->name);
   return (strncmp(key, n2->name, strlen(n2->name)));
}

int ecmp(def_t *aa)
{
   return (aa->name ? 1 : 0);
}

char syntax_ch()
{
  if (syntax == ASTD)
    return '.';
  else
    return '#';
}


def_t* new_def()
{
  def_t* p;
  static int defcnt = 0;

  defcnt++;
  p = malloc(sizeof(def_t));
  if (p == NULL) {
    err(5);
    exit(5);
  }
  memset(p, 0, sizeof(def_t));
  p->defno = defcnt;
  return (p);
}

def_t* clone_def(def_t* dp)
{
  def_t* p;

  p = new_def();
  memcpy_s(p, sizeof(def_t), dp, sizeof(def_t));
  p->body = clone_buf(p->body);
  return (p);
}

pos_t* GetPos()
{
  pos_t* pos;

  pos = malloc(sizeof(pos_t));
  if (pos == NULL) {
    err(5);   // out of memory
    exit(5);
  }
  pos->file = fin;
  pos->bufpos = inptr - inbuf->buf;
  return (pos);
}

void SetPos(pos_t* pos)
{
//  fin = pos->file;
  inptr = inbuf->buf + pos->bufpos;
}

/* ---------------------------------------------------------------------------
   Description :
      Define a macro. This is used by a couple of directives. It used used
   by the usual 'define' and 'set' directives. However it is also used to
   define multi-line macros with the '.macro' directive.

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
---------------------------------------------------------------------------- */

void ddefine(int opt)
{
   int c, n = 0;
   def_t *dp, *p;
   arg_t parms[100];
   arg_t* pl[100];
   buf_t *ptr;
   char* ptr2;
   int need_cb = 0;

   mac_depth++;
   memset(parms, 0, 100 * sizeof(arg_t));
   for (n = 0; n < 100; n++)
     pl[n] = &parms[n];

   dp = new_def();
   dp->nArgs = 0;           // no arguments or round brackets
   dp->line = InLineNo;     // line number macro defined on
   dp->file = bbfile.body->buf;  // file macro defined in
   SkipSpaces();
   ptr2 = GetIdentifier();
   if (ptr2 == NULL) {
      err(19);    // nothing to define
      return;
   }
   dp->name = _strdup(ptr2);
   dp->body = new_buf();

   SearchAndSub(dp);
   inbuf;

   // Check for macro parameters. There must be no space between the
   // macro name and ')'.
   if (PeekCh() == '(') {
      NextCh();
      dp->varg = 0;
   	  dp->nArgs = GetMacroParmList(pl);
      if (dp->nArgs < 0) {
        dp->nArgs = -dp->nArgs;
        dp->varg = 1;
      }
      c = NextNonSpace(0);
      if (c != ')') {
         err(16);
         unNextCh();
      }
   }
   else if (syntax == ASTD) {
     // for .set and .equ there are no parameters allowed
     if (opt != 2) {
       if (PeekCh() == '(') {
         NextCh();
         need_cb = 1;
       }
       dp->varg = 0;
       dp->nArgs = GetMacroParmList(pl);
       if (dp->nArgs < 0) {
         dp->nArgs = -dp->nArgs;
         dp->varg = 1;
       }
       c = NextNonSpace(0);
       if (need_cb) {
         if (c != ')') {
           err(16);
           unNextCh();
         }
       }
     }
     // We allow
     //   .set <symbol> <value>
     // in addition to the regular
     //   .set <symbol>, <value>
     else if (PeekCh() == ',')
       NextCh();
   }
   ptr = GetMacroBody(dp, opt==2 ? 0 : 1, 0);
   inptr;
   inbuf;
   dp->parms = malloc(sizeof(arg_t*) * dp->nArgs);
   if (dp->parms == NULL) {
     err(5);    // out of memory
     exit(5);
   }
   memset(dp->parms, 0, sizeof(arg_t*) * dp->nArgs);
   for (n = 0; n < dp->nArgs; n++)
     {
       dp->parms[n] = malloc(sizeof(arg_t));
       if (dp->parms[n] == NULL) {
         err(5);    // out of memory
         exit(5);
       }
       if (dp->parms[n])
         memcpy(dp->parms[n], &parms[n], sizeof(arg_t));
     }

   // Do pasteing
   //DoPastes(ptr);

   // See if the macro is already defined. If it is then if the definition
   // is not the same spit out an error, otherwise spit out warning.
   dp->body = ptr;
   p = (def_t *)htFind(&HashInfo, dp);
   if (p) {
		 if (strcmp(p->body->buf, dp->body->buf))
			 err(6, dp->name);
      //err((strcmp(p->body, dp.body) ? 6 : 23), dp.name);
      free(dp->name);
      return;
   }
   ptr2 = ptr->buf;
   dp->name = StorePlainStr(dp->name);
   dp->body->buf = StorePlainStr(dp->body->buf);
   dp->body->alloc = 1;
   free(ptr2);
   htInsert(&HashInfo, dp);
   inst++;
}

/* ----------------------------------------------------------------------------
   Description :
      Cause preprocessor display a message on stderr. The 'abort' directive
   will cause the pre-procesor to exit back to the OS. The 'error' directive
   displays an error message then continues.

   Parameters
    (int) opt   - 0=continue 1=abort (exit program)

    Returns
      (none)
---------------------------------------------------------------------------- */

void derror(int opt)
{
  int c;

  SearchAndSub(NULL);
  DoPastes(inbuf->buf);
  SkipSpaces();
  do
  {
    c = NextCh();
    if (c > 0)
      fputc(c, stderr);
    if (c == '\n' || c == 0)
      break;
  } while (1);
//   exit(0);
  if (opt)
    exit(100);
}


/* ---------------------------------------------------------------------------
   Description :

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
----------------------------------------------------------------------------- */

void dincdir(int opt)
{
  char ch;
  char* f;
  char name[4096];

  SearchAndSub(NULL);
  DoPastes(inbuf->buf);
  ch = NextNonSpace(0);
  if (ch == '"')  // search the path specified
  {
    f = name;
    do
    {
      ch = NextCh();
      if (ch <= 1 || ch == '"' || ch == '\n')
        break;
      *f = ch;
      f++;
    } while (f - name < sizeof(name) - 2);
    *f = 0;
  }
  else if (ch == '<')
  {
    f = name;
    do
    {
      ch = NextCh();
      if (ch <= 1 || ch == '>' || ch == '\n')
        break;
      *f = ch;
      f++;
    } while (f - name < sizeof(name) - 2);
    *f = 0;
  }
  strcpy_s(incdir, sizeof(incdir), name);
  if (ch != '\n')
    ScanPastEOL();
}

/* ---------------------------------------------------------------------------
   Description :
      Include another file within the current one. Locates the file in the
   typical fashion using the 'INCLUDE' environment variable.

   Nesting of Included Files:
      The current file pointer is stacked on an internal stack and a new file
   pointer allocated and used in opening the included file. The current file
   is left open on the assumption it will be returned to. Files are closed
   once the end of the file is reached. If the end of the current file is an
   included file, then the file pointer stack is popped.

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
----------------------------------------------------------------------------- */

void dinclude(int opt)
{
   char *tname;
   char *f;
   char path[4096];
   char name[4096];
   char wpath[4096];
	 char buf[4096];
   int ch;
   def_t *p;
   pos_t* ndx;

   ndx = GetPos();
   SearchAndSub(NULL);
   DoPastes(inbuf->buf);
   SetPos(ndx);
   free(ndx);
   tname = bbfile.body->buf;
   name[0] = 0;

   ch = NextNonSpace(0);
  if (ch == '"')  // search the path specified
  {
    f = name;
    do
    {
      ch = NextCh();
      if (ch <= 1 || ch == '"' || ch == '\n')
        break;
      *f = ch;
      f++;
    } while (f - name < sizeof(name) - 2);
    *f = 0;
    strcpy_s(path, sizeof(path), name);
    if (_access(path, 0) < 0) {
      _getcwd(wpath, sizeof(wpath) - 1);
      strcpy_s(path, sizeof(path), SourceName);
      f = strrchr(path, '\\');
      if (!f)
        f = strrchr(path, '/');
      if (f) {
        strcpy_s(f + 1, sizeof(path - 1), name);
      }
      // Try the .incdir path first.
      if (!f || _access(path, 0) < 0) {
        strcpy_s(path, sizeof(path), incdir);
        if (path[strlen(path) - 1] != '\\')
          path[strlen(path)] = '\\';
        strcat_s(path, sizeof(path), SourceName);
        if (_access(path) < 0) {
          // Can't find the file in the given path, try the include paths.
          if (!f || _access(path, 0) < 0) {
            searchenv((char*)name, (char*)"FPPINC", (char*)path, sizeof(path));
            if (path[0] == '\0')
              searchenv((char*)name, (char*)"INCLUDE", (char*)path, sizeof(path));
            if (path[0] == '\0') {
              err(9, name);
              return;
            }
          }
        }
      }
    }
  }
  else if (ch == '<')
  {
    f = name;
    do
    {
        ch = NextCh();
        if (ch <= 1 || ch == '>' || ch == '\n')
          break;
        *f = ch;
        f++;
    } while (f - name < sizeof(name) - 2);
    *f = 0;
    searchenv((char *)name, (char *)"FPPINC", (char *)path, sizeof(path));
	if (path[0]=='\0')
  	searchenv((char *)name, (char *)"INCLUDE", (char *)path, sizeof(path));
  }
  if (pass == npass) {
    if (ch != '\n')
      ScanPastEOL();
  }
  else {
    if (ch != '\n')
      ScanPastEOL();
//     sprintf_s(buf, sizeof(buf), ".include \"%s\"\n", path);
//    if (fputs(buf, ofp) == EOF)
//      printf("fputs failed.\n");
  }

  if (path[0])
  {
		sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, path, 0x22);
  bbfile.body->buf = StorePlainStr(buf);
  p = (def_t *)htFind(&HashInfo, &bbfile);
  if (p)
      p->body = bbfile.body;
  ifps[ifp_sp] = fin;
  ifp_sp++;
  // Strip leading/trailing quotes from filename.
  if (bbfile.body->buf[0] == '"')
    strcpy_s(buf, sizeof(buf), bbfile.body->buf + 1);
  else
    strcpy_s(buf, sizeof(buf), bbfile.body->buf);
  if (buf[strlen(buf) - 1] == '"')
    buf[strlen(buf) - 1] = '\0';

  fin = NULL;
  if ((fopen_s(&fin, buf, "r")) != 0) {
    err(9, buf);
    fin = NULL;
    return;
  }

//    ProcFile(bbfile.body->buf);
  bbfile.body->buf = tname;
  p = (def_t *)htFind(&HashInfo, &bbfile);
  if (p)
      p->body = bbfile.body;
  }
  else
    err(9, name);
}

/* -----------------------------------------------------------------------------
   Description :
      Undefines a macro by removing its definition from the table.

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
----------------------------------------------------------------------------- */

void dundef(int opt)
{
	def_t dp;

	dp.name = GetIdentifier();
	if (dp.name)
		htDelete(&HashInfo, &dp);
}


/* ----------------------------------------------------------------------------
   Description :
      Sets line number equal to line number specified and file name to
   name specified.

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
---------------------------------------------------------------------------- */

void dline(int opt)
{
  char *ptr;
  char name[MAXLINE];
  def_t *p;

  SearchAndSub(NULL);
  DoPastes(inbuf->buf);
  InLineNo = atoi(inptr);
  sprintf_s(bbline.body->buf, 6, "%5d", InLineNo-2);
  if ((ptr = strchr(inptr, '"')) != NULL)
  {
    inptr = ptr;
    memset(name, 0, sizeof(name));
    strncpy_s(name, sizeof(name), ptr, strcspn(ptr+1, " \t\n\r\x22"));
		strcat_s(name, sizeof(name), "\"");
    bbfile.body->buf = StorePlainStr(name);
    bbfile.body->alloc = 1;
    p = (def_t *)htFind(&HashInfo, &bbfile);
    if (p)
      p->body = bbfile.body;
  }
}


/* ----------------------------------------------------------------------------
   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
---------------------------------------------------------------------------- */

void dpragma(int opt)
{
  SearchAndSub(NULL);
   DoPastes(inbuf->buf);
}


/* ----------------------------------------------------------------------------
   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
---------------------------------------------------------------------------- */

void dendm(int opt)
{
  if (mac_depth > 0)
    mac_depth--;
  else
    err(31);    // endm without macr
}

/* -----------------------------------------------------------------------------
   Description :

      This is a jump table of directive mnemonics and the addresses of the 
   corresponding processing routine. This table is searched in a linear
   fashion. So placing directives earlier in the table will result in them
   being found the fastest.
----------------------------------------------------------------------------- */

static directive_t dir[] =
{
   // Standard C directives
   "define",  6, ddefine, 0, 0,
   "error",   5, derror,  0, 0,
   "include", 7, dinclude,0, 0,
   "else",    4, delse,   0, 0,
   "endif",   5, dendif,  0, 0,
   "elif",    4, delif,   0, 0,
   "ifdef",   5, difdef,  0, 0,
   "ifndef",  6, difndef, 0, 0,
   "if",      2, dif,     0, 0,  // must come after ifdef/ifndef
   "undef",   5, dundef,  0, 0,
   "line",    4, dline,   0, 0,
   "pragma",  6, dpragma, 0, 0,
   // Assembler directives
   //12 v
   "define",  6, ddefine, 1, 0,
   "set",     3, ddefine, 1, 2,
   "equ",     3, ddefine, 1, 2,
   "err",     3, derror,  1, 0,
   "abort",   5, derror,  1, 1,
   "include", 7, dinclude,1, 0,
   "else",    4, delse,   1, 0,
   "ifdef",   5, difdef,  1, 0,
   // 20 v
   "ifndef",  6, difndef, 1, 0,
   "ifeq",    4, dif,     1, 1,
   "ifne",    4, dif,     1, 0,
   "ifgt",    4, dif,     1, 2,
   "ifge",    4, dif,     1, 3,
   "iflt",    4, dif,     1, 4,
   "ifle",    4, dif,     1, 5,
   "ifb",     3, dif,     1, 6,
   "ifnb",    3, dif,     1, 7,
   "if",      2, dif,     1, 0,  // must come after ifdef/ifndef
   // 30 v
   "incdir",  6, dincdir, 1, 0,
   "endif",   5, dendif,  1, 0,
   "undef",   5, dundef,  1, 0,
   "macro",   5, ddefine, 1, 1,
   "endm",    4, dendm,   1, 0,
   "irp",     3, drept,   1, 1,
   "rept",    4, drept,   1, 0,
   "endr",    4, dendr,   1, 0
};

/* -----------------------------------------------------------------------------
   Description :
      Looks at line and determines if it is a preprocessor directive. If it
   is then processing for the directive is executed.
      A directive begins with a pre-processor character (must have already
   been fetched from input) followed by optional spaces then the directive
   mnemonic.

   Parameters
    (char*) ptr  - pointer to text to check for directive.

   Returns :
      non-zero if preprocessor directive, otherwise zero.
----------------------------------------------------------------------------- */

int directive(char *p)
{
   int i;
   char* q = inptr;

   if (p)
     q = p;

   // Skip any whitespace following '#'
   if (p == NULL) {
     NextNonSpace(0);
     unNextCh();
   }
   for(i = 0; i < sizeof(dir)/sizeof(directive_t); i++)
   {
      if (!strncmp(q, dir[i].name, dir[i].len) && dir[i].syntax==syntax)
      {
         inptr += dir[i].len;
         (*dir[i].func)(dir[i].opt);
		 // Including this causes #define to fail because it already
		 // scans to the end of the line
		 //ScanPastEOL();
         //for (; *inptr != 0; inptr++); // skip to eol
         return (i+1);
      }
   }
   return (0);
}


/* -----------------------------------------------------------------------------
   Description :
      Process a line of text from the input. Tries to detect a directive
   first and invokes directive processing if found. Otherwise looks for
   macros that need to be substituted into the input and then performs
   paste operations. Finally, the processed line is dumped to the output
   file.

   Returns:
      (int) - indication to abort processing in the file processing loop.
              not currently used and should be zero.
----------------------------------------------------------------------------- */

int ProcLine()
{
   int ch;
   int def = 0;
   char* ptr, *ptr2, *ptr3;
   int64_t ndx3;

   //printf("Processing line: %d\r", InLineNo);
   ch = NextNonSpace(0);
   if (ch == syntax_ch() && in_comment == 0) {
      if (ShowLines)
         fprintf(stdout, "#line %5d\n", InLineNo);
      def = directive(NULL);
      if (def)
        ptr = inptr;
      if (def==36 || def==37)  // irp,rept
        goto jmp1;
   }
   else {
//     DoPastes(inbuf->buf);
     //      inptr = inbuf;
     unNextCh();
jmp1:
     ndx3 = SkipComments() - inbuf->buf;
     inptr = inbuf->buf + ndx3;
     if (fdbg) fprintf(fdbg, "bef sub  :%s", inbuf->buf + ndx3);
     collect = 1;
     SearchAndSub(NULL);
     collect = 0;
     if (fdbg) fprintf(fdbg, "aft sub  :%s", inbuf->buf + ndx3);
     DoPastes(inbuf->buf + ndx3);
     // write out the current input buffer
     if (fdbg) fprintf(fdbg, "aft paste:%s", inbuf->buf + ndx3);
     rtrim(inbuf->buf + ndx3);
     inptr = inbuf->buf + ndx3 + strlen(inbuf->buf + ndx3);
     ptr2 = inbuf->buf + ndx3;
//     do ptr2++; while (ptr2[0] == '\n' || ptr2[0] == '\r');
//     ptr2--;
     ptr3 = strip_blank_lines(ptr2);
     if (!is_blank(ptr3)) {
       if (fputs(ptr3, ofp) == EOF)
        printf("fputs failed.\n");
       if (ptr3[strlen(ptr3)-1]!='\n')
        fputs("\n", ofp);
     }
     if (ptr3)
       free(ptr3);
   }
   inbuf->buf[0] = 0;
   inbuf->buf[1] = 0;
   inbuf->buf[2] = 0;
   inptr = inbuf->buf;
   InLineNo++;          // Update line number (including __LINE__).
   sprintf_s(bbline.body->buf, 6, "%5d", InLineNo-1);
   return(0);
}

/* -----------------------------------------------------------------------------
   Description :
      Process files. Loops reading lines from input, performing macro
   substitutions and processing preprocessor commands. Macro substitution
   is done first to allow a macro to be defined in terms of another macro.
   The input files may be processed in a loop multiple times to resolve
   nested structures that may be part of the source text.
   This function is called by the 'include' directive as well as being
   called from the mainline routine.

   Side Effects:
      Creates temporary files with names based on the source text file.
   These files are removed automatically at the end of processing.

   Parameters:
      (char *) - pointer to text string containing the file name to process.
   Returns:
      (none)
----------------------------------------------------------------------------- */

void ProcFile(char *fname)
{
  FILE* fp;
	char* buf;
  char filebuf[2048];
  static char OutName[500];
  FILE* fpo[10];
  int nn;

  memset(fpo, 0, sizeof(fpo));

  fp = NULL;
	// Strip leading/trailing quotes from filename.
  buf = strip_quotes(fname);

  strcpy_s(OutName, sizeof(OutName), buf);
  strcat_s(OutName, sizeof(OutName), ".out0");

  fin = NULL;
  if ((fopen_s(&fin, buf, "r")) != 0) {
    fprintf(stdout, "errno: %d\n", errno);
    fprintf(stderr, "errno: %d\n", errno);
    err(9, buf);
    fin = NULL;
    goto xit;
  }

  pass = 0;
  do {

    OutName[strlen(OutName) - 1] = '0' + pass;
    if (fpo[pass] == NULL) {
      if (fopen_s(&fpo[pass], OutName, "w") != 0)
        if (fpo[pass] == NULL) {
          fprintf(stdout, "errno: %d\n", errno);
          fprintf(stderr, "errno: %d\n", errno);
          err(9, OutName);
          fclose(fin);
          fin = NULL;
          goto xit;
        }
    }
    ofp = fpo[pass];
    NextCh();
    unNextCh();
    do {
      while (!feof(fin)) {
        if (ProcLine())
          break;
      }
      fclose(fin);
      ifp_sp--;
      if (ifp_sp >= 0) {
        fin = ifps[ifp_sp];
        inptr = inbuf->buf;
        inbuf->buf[0] = 0;
        NextCh();
        unNextCh();
      }
    }
    while (ifp_sp >= 0);
    fin = NULL;
    fflush(fpo[pass]);
    fclose(fpo[pass]);
    OutName[strlen(OutName) - 1] = '0' + pass;
    fin = NULL;
    if ((fopen_s(&fin, OutName, "r")) != 0) {
      err(9, OutName);
      fin = NULL;
      goto xit;
    }
    pass++;
  } while (pass < npass);

xit:
  if (buf)
    free(buf);
  if (fin)
    fclose(fin);
  for (nn = 0; nn < npass; nn++) {
    if (fpo[nn]) {
      if (fpo[nn] != stdout) {
        fflush(fpo[nn]);
        fclose(fpo[nn]);
        fpo[nn] = NULL;
      }
    }
  }
  if (ostdo) {
    if (npass > 0)
      OutName[strlen(OutName) - 1] = '0' + pass-1;
    else
      OutName[strlen(OutName) - 1] = '0';
    if ((fopen_s(&fin, OutName, "r")) != 0) {
      err(9, OutName);
      fin = NULL;
    }
    else {
      while (!feof(fin)) {
        if (fgets(filebuf, sizeof(filebuf), fin)!=NULL)
          fputs(filebuf, stdout);
      }
      fclose(fin);
      fin = NULL;
    }
    remove(OutName);
  }
  else {
    if (npass > 0) {
      OutName[strlen(OutName) - 1] = '0' + pass - 1;
//      remove(OutputName);
    }
    else {
      OutName[strlen(OutName) - 1] = '0';
    }
    remove(OutputName);
    if (rename(OutName, OutputName) != 0) {
      err(28, OutputName);
      fprintf(stdout, "errno: %d\n", errno);
      fprintf(stderr, "errno: %d\n", errno);
    }
  }
  // Get rid of temp files.
  for (pass = 0; pass < npass - 1; pass++) {
    OutName[strlen(OutName) - 1] = '0' + pass;
    remove(OutName);
  }
}

/* ----------------------------------------------------------------------------
   Description:
 	   Parse command line switches. This routine parses one switch may be
   specified in any order on the command line.

   Parameters:
      (char *) pointer to the command line switch
---------------------------------------------------------------------------- */

void parsesw(char *s)
{
  def_t tdef;
  char buf[MAXLINE];
  char buf2[MAXLINE];
  int ii, jj;

  switch(s[1])
  {
  case 'd':
	  debug = 1;
	  break;
  case 'b':
	  banner = 0;
	  break;

  case 'D':
    strcpy_s(buf2, MAXLINE, &s[2]);
    for(ii = 0; buf2[ii] && IsIdentChar(buf2[ii]); ii++)
      buf[ii] = buf2[ii];
    buf[ii] = 0;
    if (buf[0]) {
      tdef.nArgs = -1;
      tdef.name = StorePlainStr(buf);
      tdef.body = new_buf();
      if (buf2[ii++] == '=') {
          for(jj = 0; buf2[ii];)
            buf[jj++] = buf2[ii++];
          buf[jj] = 0;
          tdef.body->buf = (char *)(buf[0] ? StorePlainStr(buf) : "");
      }
      else
          tdef.body->buf = "";
      tdef.line = 0;
      tdef.file = "<cmd line>";
      htInsert(&HashInfo, &tdef);
    }
    break;

  case 'S':
    if (strncmp(&s[2], "astd", 4) == 0)
      syntax = ASTD;
    break;

  case 'V':
    verbose = 1;
    break;

  case 'L':
    ShowLines = 1;
    break;

  case 'P':
    npass = s[2] - '0';
    if (npass < 0 || npass > 9)
      npass = 0;
    break;
  }
}


/* -----------------------------------------------------------------------------
   Description :
      Prints a table of macros defined. Mainly for debugging.
----------------------------------------------------------------------------- */

void PrintDefines()
{
  int ii, count, blnk, jj;
  def_t *dp, *pt;
  char buf[8];

  pt = (def_t *)HashInfo.table;

  // Pack any 'holes' in the table
  for(blnk= ii = count = 0; count < HashInfo.size; count++, ii++) {
    dp = &pt[ii];
    if (dp->name) {
        if (blnk > 0)
          memmove(&pt[ii-blnk], &pt[ii], (HashInfo.size - count) * sizeof(def_t));
        ii -= blnk;
        blnk = 0;
    }
    else
        blnk++;
  }

  // Sort the table
  qsort(pt, ii, sizeof(def_t), icmp);

  printf("\n\nMacro Table:\n");
  printf("Name         Args Body                                     Line  File\n");
  for (MacroCount = 0; --ii >= 0;) {
    dp = &pt[MacroCount];
    if (dp->name) {
        MacroCount++;
        if (dp->nArgs >= 0)
          sprintf_s(buf, sizeof(buf), " %2d ", dp->nArgs);
        else 
          sprintf_s(buf, sizeof(buf), " -- ");
        // Display only the first line of a macro.
        for (jj = 0; dp->body->buf[jj] != 0 && dp->body->buf[jj] != '\n'; jj++);
        if (jj > 1) dp->body->buf[jj - 2] = 0;
        printf("%-12.12s %4.4s %-40.40s %5d %-12.12s\n", dp->name, buf, dp->body->buf, dp->line, dp->file);
    }
  }
  getchar();
}


/* -----------------------------------------------------------------------------
   Description :
      Stores a string. Currently uses a statically allocated string storage
   area. Used mainly for storing the macro definition names.

   ToDo:
      Update to use buffer class.

   Returns :
      (char *) pointer to area where string is stored.

----------------------------------------------------------------------------- */

char *StoreStr(char *body, ...)
{
  va_list argptr;
  static char buf[100000]; // allow for a large expanded macro
  int64_t pos;
  char ch;

  pos = SymSpace->pos;
  va_start(argptr, body);
  vsprintf_s(buf, sizeof(buf), body, argptr);
  va_end(argptr);
  insert_into_buf(&SymSpace, buf, 1);
  ch = SymSpace->buf[pos];
  return (SymSpace->buf + pos);
}


/* -----------------------------------------------------------------------------
   Description :
      Stores actual string without calling vsprintf().

   Returns :
      (char *) pointer to area where string is stored.

----------------------------------------------------------------------------- */

char *StorePlainStr(char *str)
{
  int64_t pos;

  pos = SymSpace->pos;
  insert_into_buf(&SymSpace, str, 1);
  return (SymSpace->buf + pos);
}


/* -----------------------------------------------------------------------------
   Description :
      Creates predefined preprocessor symbols __LINE__, __FILE__, __DATE__,
   __TIME__

----------------------------------------------------------------------------- */

void SetStandardDefines(void)
{
   time_t ltm;
   struct tm LocalTime;
	 char buf[260];

   time(&ltm);
   localtime_s(&LocalTime, &ltm);
   bbstdc.body = new_buf();
   bbstdc.body->buf = StoreStr("1");
   bbstdc.body->alloc = 1;
   bbline.body = new_buf();
   bbline.body->buf = StoreStr("%5d", 1);
   bbline.body->alloc = 1;
   sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, SourceName, 0x22);
   bbfile.body = new_buf();
   bbfile.body->buf = StoreStr(buf);
   bbfile.body->alloc = 1;
   sprintf_s(buf, sizeof(buf), "%s", BaseSourceName);
   bbbasefile.body = new_buf();
   bbbasefile.body->buf = StoreStr(buf);
   bbbasefile.body->alloc = 1;
   bbdate.body = new_buf();
   bbdate.body->buf = StoreStr("%04d/%02d/%02d", LocalTime.tm_year+1900, LocalTime.tm_mon+1, LocalTime.tm_mday);
   bbdate.body->alloc = 1;
   bbtime.body = new_buf();
   bbtime.body->buf = StoreStr("%02d:%02d:%02d", LocalTime.tm_hour, LocalTime.tm_min, LocalTime.tm_sec);
   bbtime.body->alloc = 1;
   bbpp.body = new_buf();
   bbpp.body->buf = StoreStr("fpp");
   bbpp.body->alloc = 1;

   htInsert(&HashInfo, &bbstdc);
   htInsert(&HashInfo, &bbline);
   htInsert(&HashInfo, &bbfile);
   htInsert(&HashInfo, &bbbasefile);
   htInsert(&HashInfo, &bbtime);
   htInsert(&HashInfo, &bbdate);
   htInsert(&HashInfo, &bbpp);
}


/* ----------------------------------------------------------------------------
   Description :
      The mainline of the program. Displays help if no command line args
   are present. Gets the ball rolling performing inializations then calls
   ProcFile() to process the input files. After processing is complete
   error status is reported.

   Parameters:
      (int) number of command line arguments.
      (char *[]) - pointer to array of text strings containing command
                   line arguments.

   Returns:
      (int) - normally zero if everything completed successfully, otherwise
              an error code.
---------------------------------------------------------------------------- */

int main(int argc, char *argv[]) {
  int
    xx;
  def_t *p;
	char buf[260];
  char* p1;
   
  HashInfo.size = MAXMACROS;
  HashInfo.width = sizeof(def_t);
  if (argc < 2)
  {
		fprintf(stderr, "FPP version 2.58  (C) 1998-2024 Robert T Finch  \n");
		fprintf(stderr, "\nfpp64 [options] <filename> [<output filename>]\n\n");
		fprintf(stderr, "Options:\n");
		fprintf(stderr, "/D<macro name>[=<definition>] - define a macro\n");
		fprintf(stderr, "/L                            - output #lines\n");
		fprintf(stderr, "/V                            - verbose, outputs macro table\n");
    fprintf(stderr, "/S<syntax>                    - select processing syntax\n");
    fprintf(stderr, "   <syntax> = astd            - assembly language syntax\n");
    fprintf(stderr, "   <syntax> = cstd            - 'C' language syntax (default)\n");
    fprintf(stderr, "/P<n>                         - number of passes (0=1 default)\n\n");
    exit(0);
  }
  /* ----------------------------------------------
    Initialize any globals needing so.
  ---------------------------------------------  */
  memset(incdir, 0, sizeof(incdir));
  mac_depth = 0;
  rep_depth = 0;
  rept_inst = 0;
  SymSpace = new_buf();

  /* ----------------------------------------------
        Allocate storage for macro information.
  ---------------------------------------------  */
  if ((HashInfo.table = calloc(HashInfo.size, sizeof(def_t))) == NULL) {
    err(5);
    return (1);
  }
  bbfile.body = new_buf();
  bbfile.body->buf = StorePlainStr("<cmdln>");
  bbfile.body->alloc = 1;
  for(xx = 1; strchr("-/+", argv[xx][0]) && (xx < argc); xx++)
    parsesw(argv[xx]);

  if (banner)
    fprintf(stderr, "FPP version 2.58  (C) 1998-2024 Robert T Finch  \n");

  /* ---------------------------
        Get source file name.
  --------------------------- */
  if(xx >= argc) {
    fprintf(stderr, "\nSource filename[.c]: ");
    fgets(SourceName, sizeof(SourceName)-3, stdin);
  }
  else {
    strncpy_s(SourceName, sizeof(SourceName), argv[xx], sizeof(SourceName)-3);
    xx++;
  }
  /* -----------------------------------------------------
        Check for extension and add one if neccessary.
  ----------------------------------------------------- */
  if (!strchr(SourceName, '.'))
    strcat_s(SourceName, sizeof(SourceName)-1, ".c");

  OutputName[0] = '\0';
  if (xx < argc) {
    ostdo = 0;
  strncpy_s(OutputName, sizeof(OutputName), argv[xx], sizeof(OutputName));
  if (!strchr(OutputName, '.'))
    strcat_s(OutputName, sizeof(OutputName)-1,".pp");
  }
  else {
    strncpy_s(OutputName, sizeof(OutputName), SourceName, sizeof(OutputName));
    p1 = strchr(OutputName, '.');
    if (p1) {
      p1 = strrchr(OutputName, '.');
      strcpy_s(p1, sizeof(OutputName) - (p1 - OutputName), ".fpp");
    }
    else
      strcat_s(OutputName, sizeof(OutputName), ".fpp");
  }
  strncpy_s(BaseSourceName, sizeof(BaseSourceName), OutputName, sizeof(OutputName));
  p1 = strrchr(BaseSourceName, '.');
  if (p1)
  p1[0] = '\0';
  if (xx >= argc)
    OutputName[0] = 0;

  /* ------------------------------
        Define standard defines.
  ------------------------------ */
  SetStandardDefines();
  /* -----------------------
        Process file. 
  ----------------------- */
  if (debug)
	  fopen_s(&fdbg, "fpp_debug_log","w");
  else
	  fdbg = NULL;
//   strcpy_s(OutputName, sizeof(OutputName), SourceName);
//   strcat_s(OutputName, sizeof(OutputName), ".pp");

  if (OutputName[0]) {
    /*
    if (fopen_s(&ofp, OutputName, "w") != 0)
      if (ofp == NULL) {
        err(9, OutputName);
        exit(9);
      }
    */
  }
  else {
    ostdo = 1;
    ofp = stdout;
  }
  errors = warnings = 0;
	sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, SourceName, 0x22);
	bbfile.body->buf = StorePlainStr(buf);
  bbfile.body->alloc = 1;
  p = (def_t *)htFind(&HashInfo, &bbfile);
  if (p)
    p->body = bbfile.body;
  ProcFile(SourceName);
  /*
  if (ofp != stdout) {
	  fflush(ofp);
    fclose(ofp);
  }
  */
  if (fdbg)
	  fclose(fdbg);

  if(errors > 0)
    fprintf(stderr, "\nPreProcessor Errors: %d\n",errors);
  if(warnings > 0)
    fprintf(stderr, "\nPreProcessor Warnings: %d\n",warnings);
  if (verbose) {
    PrintDefines();
    printf("\n%d/%d macros\n", MacroCount, MAXMACROS);
    printf("%u/%u macro space used\n", SymSpace->pos, SymSpace->size);
  }
  if (SymSpace)
    free_buf(SymSpace);
  //getchar();
  exit(0);
}
