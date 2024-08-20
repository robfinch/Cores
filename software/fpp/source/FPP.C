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
char *SymSpace, *SymSpacePtr;
SHashTbl HashInfo = { HashFnc, icmp, 0, sizeof(SDef), NULL };
int MacroCount;
FILE *ofp;
FILE* fout;
int banner = 1;
int ostdo = 1;
int npass = 0;
int pass = 0;
int keep_output = 0;
FILE* ifps[20];
int ifp_sp = 0;
int rep_inst = 0;
rep_t rept_array[2000];
int minst=0;      // macro instance
char incdir[4096];    // additional include directory specified with .incdir

// Storage for standard #defines

SDef
bbstdc = { "__STDC__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbline = { "__LINE__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbdate = { "__DATE__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbfile = { "__FILE__", NULL, -1, 0, 0, "<fpp>", NULL },
  bbbasefile = { "__BASEFILE__", NULL, -1, 0, 0, "<fpp>", NULL },
  bbtime = { "__TIME__", NULL, -1, 0, 0, "<fpp>", NULL },
   bbpp   = { "__PP__", NULL, -1, 0, 0, "<fpp>", NULL };

void PrintDefines(void);

size_t SymSpaceLeft()
{
  return (STRAREA - (SymSpacePtr - SymSpace));
}

/*****************************************************************************
   Functions for parser (RR(0)).
*****************************************************************************/

SHashVal HashFnc(void *d)
{
   SDef *def = (SDef *)d;
   return htSymHash(&HashInfo, def->name);
}



/* ----------------------------------------------------------------------------
      Comparison routines.
---------------------------------------------------------------------------- */

int icmp (const void *m1, const void *m2)
{
    SDef *n1; SDef *n2;
    n1 = (SDef *)m1;
    n2 = (SDef *)m2;
	if (n1->name==NULL) return 1;
	if (n2->name==NULL) return -1;
  return (strcmp(n1->name, n2->name));
}

int fcmp(char *key, SDef *n2)
{
   printf("Key:%s, Entry:%s|\n", key, n2->name);
   return (strncmp(key, n2->name, strlen(n2->name)));
}

int ecmp(SDef *aa)
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


SDef* new_def()
{
  SDef* p;

  p = malloc(sizeof(SDef));
  if (p == NULL) {
    err(5);
    exit(5);
  }
  memset(p, 0, sizeof(SDef));
  return (p);
}

SDef* clone_def(SDef* dp)
{
  SDef* p;

  p = new_def();
  memcpy_s(p, sizeof(SDef), dp, sizeof(SDef));
  p->body = clone_buf(p->body);
  return (p);
}

rep_t* new_rept()
{
  rep_t* p;

  if (rep_inst > 1999)
    exit(0);
  p = &rept_array[rep_inst];
  memset(p, 0, sizeof(rep_t));
  p->ino = rep_inst;
  p->def = new_def();
  rep_inst++;
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
   SDef *dp, *p;
   arg_t parms[100];
   arg_t* pl[100];
   buf_t *ptr;
   char* ptr2;
   int need_cb = 0;

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
   if (dp->parms == NULL)
     exit(0);
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
   p = (SDef *)htFind(&HashInfo, dp);
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
   free(ptr2);
   htInsert(&HashInfo, dp);
   minst++;
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
   SDef *p;
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
  p = (SDef *)htFind(&HashInfo, &bbfile);
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
  p = (SDef *)htFind(&HashInfo, &bbfile);
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
	SDef dp;

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
   SDef *p;

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
      p = (SDef *)htFind(&HashInfo, &bbfile);
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
}

/* ---------------------------------------------------------------------------
   Description :
      Define a repeat block.

   Parameters
    (int) opt   - 0=rept,1=irp

    Returns
      (none)
---------------------------------------------------------------------------- */

void* drept(int opt)
{
  rep_t* dr;
  int c, n = 0;
  SDef* dp1;
  arg_t pary[100];
  arg_t* parms[100];
  char* st;
  pos_t* opndx = NULL;
  int count = 0;
  int ii;
  int wd;
  int ri;
  SDef* dp, * ptdef, *ptdef2;
  SDef tdef;
  char* vname;

  // Update the repeat nesting depth. This is a global var manipulated when a
  // repeat body is gotten.
  rep_depth++;

  dr = new_rept();
  dp = dr->def;
  if (dp == NULL)
    return (NULL);

  dp->varg = 0;
  dp->nArgs = -1;          // no arguments or round brackets
  dp->line = InLineNo;     // line number macro defined on
  dp->file = bbfile.body->buf;  // file macro defined in
  dp->name = NULL;

  memset(pary, 0, sizeof(pary));
  for (ii = 0; ii < 100; ii++)
    parms[ii] = &pary[ii];

  // Get the var name for .irp, and absorb a following comma.
  if (opt == 1) {
    SkipSpaces();
    vname = GetIdentifier();
    if (vname)
      tdef.name = _strdup(vname);
    else {
      err(30);    // expecting a symbol
      ScanPastEOL();
      goto xit;
    }
    SkipSpaces();
    if (PeekCh() == ',')
      NextCh();
  }

  SearchAndSub(NULL);

  // expeval() will eat a newline char
  if (opt == 0)
    dr->orcnt = dr->rcnt = expeval();
  st = inptr;

  // Check for repeat parameters. There must be no space between the
  // macro name and ')'.
  SkipSpaces();
  c = PeekCh();
  if (c == ',' || opt==1) {
    if (c == ',')
      NextCh();
    dp->varg = 0;
    dp->nArgs = GetReptArgList(parms, opt);
    if (dp->nArgs < 0) {
      dp->nArgs = -dp->nArgs;
      dp->varg = 1;
    }
    if (dp->nArgs) {
      dp->parms = malloc(sizeof(arg_t*) * dp->nArgs);
      if (dp->parms == NULL) {
        err(5);
        exit(5);
      }
      for (ii = 0; ii < dp->nArgs; ii++) {
        dp->parms[ii] = malloc(sizeof(arg_t));
        if (dp->parms[ii] == NULL) {
          err(5);
          exit(5);
        }
        dp->parms[ii]->num = ii;
        dp->parms[ii]->name = opt==1 ? tdef.name : NULL;
        dp->parms[ii]->def = _strdup(parms[ii]->def);
      }
    }
    // Note that getting the rept arg list might scan until the end of line
    // already. We do not want to do this twice, or the contents of the 
    // start of the next line will be missed.
    if (PeekCh() != 0)
      ScanPastEOL();
  }
  c = PeekCh();
  if (c < 0) {
    err(26);
    return (NULL);
  }
  dp->body = GetMacroBody(dp, 1, 1);

  // Advance past the '.endr'
  inptr += 5;

  // Dump the repeat body to the input repeat count number of times.
  opndx = GetPos();
  ri = rep_inst;

  // Handle an iterative repeat
  if (opt == 1) {
    ptdef2 = htFind(&HashInfo, &tdef);
    if (ptdef2) {
      ii = 0;
      do {
        // The variable is being modified, but we want to retain the original state,
        // so clone it and modify the clone.
        ptdef = clone_def(ptdef2);
        // We wnat to substitute into the body of the repeat statement.
        ptdef->body = dp->body;
        // Assign the symbol the iteration value.
        ptdef->nArgs = 1;         // we are only subbing one arg
        ptdef->parms = malloc(sizeof(arg_t*));  // only 1 arg
        if (ptdef->parms == NULL) {
          err(5);
          exit(5);
        }
        ptdef->parms[0] = malloc(sizeof(arg_t));
        if (ptdef->parms[0] == NULL) {
          err(5);
          exit(5);
        }
        ptdef->parms[0]->name = ptdef2->name;
        ptdef->parms[0]->num = 0;
        // A symbol without an iteration value iterates to an empty string.
        // Other assign the iteration value from the argument list.
        if (dp->nArgs < 1)
          ptdef->parms[0]->def = "";
        else
          ptdef->parms[0]->def = dp->parms[ii]->def;
        // Substitute 1 arg into macro body and into the input.
        wd = SubParmMacro(ptdef, 1);
        inbuf;
        inptr += strlen(inptr);
        free(ptdef->parms[0]);
        free(ptdef->parms);
        free(ptdef);
        ptdef = NULL;
        ii++;
      } while (ii < dp->nArgs);
    }
  }
  // Handle the usual repeat.
  else {
    dp1 = new_def();
    dp1->body = dp->body;
    for (ii = 0; ii < dr->rcnt && ii < 100; ii++) {
      // Substitute args into macro body and into the input.
      dp1->abody = clone_buf(dp->body);
      wd = SubParmMacro(dp1, 1);
      free(dp1->abody);
      inptr += strlen(inptr);
    }
  }

  // Set the input point back to the start of the dump.
xit:
  if (opndx) {
    SetPos(opndx);
    free(opndx);
  }
  return ((void*)dr);
}

/* ----------------------------------------------------------------------------
   Description:
      Process end of repeat block marker. This marker should have been 
   absorbed when the repeat body was collected. If it is encountered then
   there must have been an end without a start. So spit out an error.

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
---------------------------------------------------------------------------- */

void dendr(int opt)
{
  err(29);    // .endr without .rept
}


/* -----------------------------------------------------------------------------
   Description :

      This is a jump table of directive mnemonics and the addresses of the 
   corresponding processing routine. This table is searched in a linear
   fashion. So placing directives earlier in the table will result in them
   being found the fastest.
----------------------------------------------------------------------------- */

static SDirective dir[] =
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
   for(i = 0; i < sizeof(dir)/sizeof(SDirective); i++)
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
   char* ptr, *ptr2;
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
     if (syntax==CSTD)
       ptr2 = inbuf->buf + ndx3;
     else
       ptr2 = inbuf->buf + ndx3;
//     do ptr2++; while (ptr2[0] == '\n' || ptr2[0] == '\r');
//     ptr2--;
     if (fputs(ptr2, ofp) == EOF)
       printf("fputs failed.\n");
     fputs("\n", ofp);
   }
   inbuf->buf[0] = 0;
   inbuf->buf[1] = 0;
   inbuf->buf[2] = 0;
   inptr = inbuf->buf;
   lasttk = 0;
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
      OutName[strlen(OutName) - 1] = '0' + pass;
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
      remove(OutputName);
    }
    else {
      OutName[strlen(OutName) - 1] = '0' + pass;
    }
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
   SDef tdef;
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
  int ii, count, blnk;
  SDef *dp, *pt;
  char buf[8];

  pt = (SDef *)HashInfo.table;

  // Pack any 'holes' in the table
  for(blnk= ii = count = 0; count < HashInfo.size; count++, ii++) {
    dp = &pt[ii];
    if (dp->name) {
        if (blnk > 0)
          memmove(&pt[ii-blnk], &pt[ii], (HashInfo.size - count) * sizeof(SDef));
        ii -= blnk;
        blnk = 0;
    }
    else
        blnk++;
  }

  // Sort the table
  qsort(pt, ii, sizeof(SDef), icmp);

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
  char *ptr;
  va_list argptr;

  if (strlen(body) > SymSpaceLeft() - 2000) {
    err(5);
    exit(3);
  }
  ptr = SymSpacePtr;
  va_start(argptr, body);
  SymSpacePtr += vsprintf_s(SymSpacePtr, SymSpaceLeft()-1, body, argptr) + 1;
  va_end(argptr);
  return (ptr);
}


/* -----------------------------------------------------------------------------
   Description :
      Stores actual string without calling vsprintf().

   Returns :
      (char *) pointer to area where string is stored.

----------------------------------------------------------------------------- */

char *StorePlainStr(char *str)
{
  char *ptr = SymSpacePtr;

  if (strlen(str) > SymSpaceLeft() - 2000) {
    err(5);
    exit(3);
  }
  strcpy_s(SymSpacePtr, SymSpaceLeft()-1, str);
  SymSpacePtr += strlen(str) + 1;
  return (ptr);
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
   bbline.body = new_buf();
   bbline.body->buf = StoreStr("%5d", 1);
	 sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, SourceName, 0x22);
   bbfile.body = new_buf();
   bbfile.body->buf = StoreStr(buf);
   sprintf_s(buf, sizeof(buf), "%s", BaseSourceName);
   bbbasefile.body = new_buf();
   bbbasefile.body->buf = StoreStr(buf);
   bbdate.body = new_buf();
   bbdate.body->buf = StoreStr("%04d/%02d/%02d", LocalTime.tm_year+1900, LocalTime.tm_mon+1, LocalTime.tm_mday);
   bbtime.body = new_buf();
   bbtime.body->buf = StoreStr("%02d:%02d:%02d", LocalTime.tm_hour, LocalTime.tm_min, LocalTime.tm_sec);
   bbpp.body = new_buf();
   bbpp.body->buf = StoreStr("fpp");

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
  SDef *p;
	char buf[260];
  char* p1;
   
  HashInfo.size = MAXMACROS;
  HashInfo.width = sizeof(SDef);
  if (argc < 2)
  {
		fprintf(stderr, "FPP version 2.53  (C) 1998-2024 Robert T Finch  \n");
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
  rep_depth = 0;

  /* ----------------------------------------------
        Allocate storage for macro information.
  ---------------------------------------------  */
  if ((HashInfo.table = calloc(HashInfo.size, sizeof(SDef))) == NULL) {
    err(5);
    return (1);
  }
  if ((SymSpace = (char *)calloc(1, STRAREA)) == NULL) {
    free(HashInfo.table);
    err(5);
    return(2);
  }
  SymSpacePtr = SymSpace;
  bbfile.body = new_buf();
  bbfile.body->buf = StorePlainStr("<cmdln>");
  for(xx = 1; strchr("-/+", argv[xx][0]) && (xx < argc); xx++)
    parsesw(argv[xx]);

if (banner)
	fprintf(stderr, "FPP version 2.53  (C) 1998-2024 Robert T Finch  \n");

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
  p = (SDef *)htFind(&HashInfo, &bbfile);
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
    printf("%u/%u macro space used\n", (int)(SymSpacePtr - SymSpace), STRAREA);
  }
  if (SymSpace)
    free(SymSpace);
  //getchar();
  exit(0);
}
