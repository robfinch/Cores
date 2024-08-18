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
int banner = 1;
int ostdo = 1;

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

/* ---------------------------------------------------------------------------
   Description :
      Define a macro.
---------------------------------------------------------------------------- */

void ddefine()
{
   int c, n = 0;
   SDef *dp, *p;
   arg_t parms[100];
   arg_t* pl[100];
   buf_t *ptr;
   char* ptr2;

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
   ptr = GetMacroBody(dp);
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
}

/* ----------------------------------------------------------------------------
   Description :
      Cause preprocessor to stop and display a message on stderr.
---------------------------------------------------------------------------- */

void derror()
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
      if (c == '\n')
         break;
   } while (1);
//   exit(0);
}


/* ---------------------------------------------------------------------------
   Description :
      Include another file within the current one.
----------------------------------------------------------------------------- */

void dinclude()
{
   char *tname;
   char *f;
   char path[250];
   char name[250];
   char wpath[250];
	 char buf[260];
   int ch;
   SDef *p;

   SearchAndSub(NULL);
   DoPastes(inbuf->buf);
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
      } while(1);
      *f = 0;
      strcpy_s(path, sizeof(path), name);
      if (_access(path, 0) < 0) {
		  _getcwd(wpath, sizeof(wpath) - 1);
           strcpy_s(path, sizeof(path), SourceName);
           f = strrchr(path,'\\');
           if (!f)
               f = strrchr(path, '/');
           if (f) {
               strcpy_s(f+1,sizeof(path-1),name);
           }
				// Can't find the file in the given path, try the include paths.
		   if (!f || _access(path, 0) < 0) {
				 searchenv((char *)name, (char *)"FPPINC", (char *)path, sizeof(path));
				 if (path[0] == '\0')
					 searchenv((char *)name, (char *)"INCLUDE", (char *)path, sizeof(path));
				 if (path[0] == '\0') {
					 err(9, name);
					 return;
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
      } while(1);
      *f = 0;
      searchenv((char *)name, (char *)"FPPINC", (char *)path, sizeof(path));
	  if (path[0]=='\0')
		searchenv((char *)name, (char *)"INCLUDE", (char *)path, sizeof(path));
   }
   if (ch != '\n')
	   ScanPastEOL();

   if (path[0])
   {
		 sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, path, 0x22);
    bbfile.body->buf = StorePlainStr(buf);
    p = (SDef *)htFind(&HashInfo, &bbfile);
    if (p)
        p->body = bbfile.body;
    ProcFile(bbfile.body->buf);
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

----------------------------------------------------------------------------- */

void dundef()
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
---------------------------------------------------------------------------- */

void dline()
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
---------------------------------------------------------------------------- */

void dpragma()
{
   SearchAndSub(NULL);
   DoPastes(inbuf->buf);
}


/* -----------------------------------------------------------------------------
   Description :
      Looks at line and determines if it is a preprocessor directive. If it
   is then processing for the directive is executed.
      Macro substitutions are optionally performed on the line before
   processing the directive. Several directives such as else/endif can have
   nothing else on the line so we save time by not performing susbtitutions.

   Returns :
      TRUE if preprocessor directive, otherwise FALSE.

----------------------------------------------------------------------------- */

int directive()
{
   int i;
   static SDirective dir[] =
   {
      "define",  6, ddefine, 
      "error",   5, derror,  
      "include", 7, dinclude,
      "else",    4, delse,   
      "endif",   5, dendif,  
      "elif",    4, delif,   
      "ifdef",   5, difdef,  
      "ifndef",  6, difndef, 
      "if",      2, dif,      // must come after ifdef/ifndef
      "undef",   5, dundef,  
      "line",    4, dline,   
      "pragma",  6, dpragma,
   };

   // Skip any whitespace following '#'
   NextNonSpace(0);
   unNextCh();
   for(i = 0; i < sizeof(dir)/sizeof(SDirective); i++)
   {
      if (!strncmp(inptr, dir[i].name, dir[i].len))
      {
         inptr += dir[i].len;
         (*dir[i].func)();
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
      Process files. Loops reading lines from input, performing macro
   substitutions and processing preprocessor commands. Macro substitution
   is done first to allow a macro to be defined in terms of another macro.

----------------------------------------------------------------------------- */

void ProcLine()
{
   int ch;
   int def = 0;
   char* ptr, *ptr2;
   int64_t ndx2;

   //printf("Processing line: %d\r", InLineNo);
//   inptr = inbuf->buf;
//   ptr = inbuf->buf;
//   ptr2 = inbuf->buf;
//   ch = NextCh();          // get first character
   ndx2 = SkipComments() - inbuf->buf;
   ch = NextNonSpace(0);
   if (ch == '#' && in_comment==0) {
      if (ShowLines)
         fprintf(stdout, "#line %5d\n", InLineNo);
      def = directive()==1;
      if (def)
        ptr = inptr;
   }
   else {
//     DoPastes(inbuf->buf);
     //      inptr = inbuf;
     unNextCh();
     ndx2 = SkipComments() - inbuf->buf;
     inptr = inbuf->buf + ndx2;
     if (fdbg) fprintf(fdbg, "bef sub  :%s", inbuf->buf + ndx2);
     SearchAndSub(NULL);
     if (fdbg) fprintf(fdbg, "aft sub  :%s", inbuf->buf + ndx2);
     DoPastes(inbuf->buf + ndx2);
     // write out the current input buffer
     if (fdbg) fprintf(fdbg, "aft paste:%s", inbuf->buf + ndx2);
     rtrim(inbuf->buf + ndx2);
     inptr = inbuf->buf + ndx2 + strlen(inbuf->buf + ndx2);
     ptr2 = inbuf->buf + ndx2;
     do ptr2++; while (ptr2[0] == '\n' || ptr2[0] == '\r');
     ptr2--;
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
}

/* -----------------------------------------------------------------------------
   Description :
      Process files. Loops reading lines from input, performing macro
   substitutions and processing preprocessor commands. Macro substitution
   is done first to allow a macro to be defined in terms of another macro.

----------------------------------------------------------------------------- */

void ProcFile(char *fname)
{
   FILE *fp;
	 char buf[500];

	 // Strip leading/trailing quotes from filename.
	 if (fname[0] == '"')
		 strcpy_s(buf, sizeof(buf), fname + 1);
	 else
		 strcpy_s(buf, sizeof(buf), fname);
	 if (buf[strlen(buf) - 1] == '"')
		 buf[strlen(buf) - 1] = '\0';

	 if((fopen_s(&fp, buf,"r")) != NULL) {
      err(9, buf);
      return;
   }

   fin = fp;
   NextCh();
   unNextCh();
   while(!feof(fp)) {
      ProcLine();
      fin = fp;
   }
   fclose(fp);
}

/* ----------------------------------------------------------------------------
   Description:
 	   Parse command line switches.
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

      case 'V':
         verbose = 1;
         break;

      case 'L':
         ShowLines = 1;
         break;
   }
}


/* -----------------------------------------------------------------------------
   Description :
      Prints a table of macros defined.
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
      Stores a string.

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
   bbdate.body->buf = StoreStr("%02d/%02d/%02d", LocalTime.tm_year, LocalTime.tm_mon+1, LocalTime.tm_mday);
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
---------------------------------------------------------------------------- */

main(int argc, char *argv[]) {
   int
      xx;
   SDef *p;
	 char buf[260];
   char* p1;
   
   HashInfo.size = MAXMACROS;
   HashInfo.width = sizeof(SDef);
   if (argc < 2)
   {
		fprintf(stderr, "FPP version 2.10  (C) 1998-2024 Robert T Finch  \n");
		fprintf(stderr, "\nfpp64 [options] <filename> [<output filename>]\n\n");
		fprintf(stderr, "Options:\n");
		fprintf(stderr, "/D<macro name>[=<definition>] - define a macro\n");
		fprintf(stderr, "/L                            - output #lines\n");
		fprintf(stderr, "/V                            - verbose, outputs macro table\n\n");
		exit(0);
   }
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
		fprintf(stderr, "FPP version 2.10  (C) 1998-2024 Robert T Finch  \n");

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
   if (OutputName[0]) {
      if (fopen_s(&ofp, OutputName, "w") != 0)
      if (ofp == NULL) {
         err(9, OutputName);
         exit(0);
      }
      ostdo = 0;
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
   if (ofp != stdout) {
	   fflush(ofp);
      fclose(ofp);
   }
   if (fdbg)
	   fclose(fdbg);

   if(errors > 0)
      fprintf(stderr, "\nPreProcessor Errors: %d\n",errors);
   if(warnings > 0)
      fprintf(stderr, "\nPreProcessor Warnings: %d\n",warnings);
   if (verbose) {
      PrintDefines();
      printf("\n%d/%d macros\n", MacroCount, MAXMACROS);
      printf("%u/%u macro space used\n", SymSpacePtr - SymSpace, STRAREA);
   }
   if (SymSpace)
      free(SymSpace);
   //getchar();
   exit(0);
}
