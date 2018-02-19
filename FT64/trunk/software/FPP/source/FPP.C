#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <malloc.h>
#include <time.h>
#include <dos.h>
#include <ht.h>

#define ALLOC
#include "fpp.h"

/* ---------------------------------------------------------------------------
   (C) 1992,2014 Robert T Finch

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
char *SymSpace, *SymSpacePtr;
SHashTbl HashInfo = { HashFnc, icmp, 0, sizeof(SDef), NULL };
int MacroCount;
FILE *ofp;
int banner = 1;

// Storage for standard #defines

SDef
bbstdc = { "__STDC__", "1", -1, 0, "<fpp>" },
   bbline = { "__LINE__", NULL, -1, 0, "<fpp>" },
   bbdate = { "__DATE__", NULL, -1, 0, "<fpp>" },
   bbfile = { "__FILE__", NULL, -1, 0, "<fpp>" },
   bbtime = { "__TIME__", NULL, -1, 0, "<fpp>" },
   bbpp   = { "__PP__", NULL, -1, 0, "<fpp>" };

void PrintDefines(void);

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


/* ---------------------------------------------------------------------------
   Description :
      Define a macro.
---------------------------------------------------------------------------- */

void ddefine()
{
   int c, n = 0;
   SDef dp, *p;
   char *parms[10];
   char *ptr;

   dp.nArgs = -1;          // no arguments or round brackets
   dp.line = InLineNo;     // line number macro defined on
   dp.file = bbfile.body;  // file macro defined in
   SkipSpaces();
   ptr = GetIdentifier();
   if (ptr == NULL) {
      err(19);    // nothing to define
      return;
   }
   dp.name = _strdup(ptr);

   SearchAndSub();

   // Check for macro parameters. There must be no space between the
   // macro name and ')'.
   if (PeekCh() == '(') {
      NextCh();
   	dp.nArgs = GetMacroParmList(parms);
      c = NextNonSpace(0);
      if (c != ')') {
         err(16);
         unNextCh();
      }
   }
   ptr = GetMacroBody((dp.nArgs > 0) ? parms : NULL);
   for (n = 0; n < dp.nArgs; n++)
      if (parms[n])
         free(parms[n]);

   // Do pasteing
   DoPastes(ptr);

   // See if the macro is already defined. If it is then if the definition
   // is not the same spit out an error, otherwise spit out warning.
   dp.body = ptr;
   p = (SDef *)htFind(&HashInfo, &dp);
   if (p) {
      err((strcmp(p->body, dp.body) ? 6 : 23), dp.name);
      free(dp.name);
      return;
   }
   ptr = dp.name;
   dp.name = StorePlainStr(ptr);
   free(ptr);
   dp.body = StorePlainStr(dp.body);
   htInsert(&HashInfo, &dp);
}

/* ----------------------------------------------------------------------------
   Description :
      Cause preprocessor to stop and display a message on stderr.
---------------------------------------------------------------------------- */

void derror()
{
   int c;

   SearchAndSub();
   DoPastes(inbuf);
   SkipSpaces();
   do
   {
      c = NextCh();
      if (c > 0)
         fputc(c, stderr);
      if (c == '\n')
         break;
   } while (1);
   exit(0);
}


/* ---------------------------------------------------------------------------
   Description :
      Include another file within the current one.
----------------------------------------------------------------------------- */

void dinclude()
{
   char *tname;
   char *f;
   char path[150];
   char name[150];
   int ch;
   SDef *p;

   SearchAndSub();
   DoPastes(inbuf);
   tname = bbfile.body;
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
      strcpy(path, name);
      if (_access(path, 0) < 0) {
           strcpy(path, SourceName);
           f = strrchr(path,'\\');
           if (!f)
               f = strrchr(path, '/');
           if (f) {
               strcpy(f+1,name);
           }
		   if (!f || _access(path, 0) < 0) {
				err(9, name);
				return;
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
      bbfile.body = StorePlainStr(path);
      p = (SDef *)htFind(&HashInfo, &bbfile);
      if (p)
         p->body = bbfile.body;
      ProcFile(bbfile.body);
      bbfile.body = tname;
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

   SearchAndSub();
   DoPastes(inbuf);
   InLineNo = atoi(inptr);
   sprintf(bbline.body, "%5d", InLineNo);
   if ((ptr = strchr(inptr, '"')) != NULL)
   {
      inptr = ptr;
      memset(name, 0, sizeof(name));
      strncpy(name, ptr+1, strcspn(ptr+1, " \t\n\r\x22"));
      bbfile.body = StorePlainStr(name);
      p = (SDef *)htFind(&HashInfo, &bbfile);
      if (p)
         p->body = bbfile.body;
   }
}


/* ----------------------------------------------------------------------------
---------------------------------------------------------------------------- */

void dpragma()
{
   SearchAndSub();
   DoPastes(inbuf);
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
      "pragma",  6, dpragma 
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
         return (TRUE);
      }
   }
   return (FALSE);
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

   //printf("Processing line: %d\r", InLineNo);
   inptr = inbuf;
   memset(inbuf, 0, sizeof(inbuf));
//   ch = NextCh();          // get first character
   ch = NextNonSpace(0);
   if (ch == '#') {
      if (ShowLines)
         fprintf(stdout, "#line %5d\n", InLineNo);
      directive();
   }
   else {
      inptr = inbuf;
//      unNextCh();
	  if (fdbg) fprintf(fdbg, "bef sub  :%s", inbuf);
      SearchAndSub();
	  if (fdbg) fprintf(fdbg, "aft sub  :%s", inbuf);
      DoPastes(inbuf);
	  // write out the current input buffer
	  if (fdbg) fprintf(fdbg, "aft paste:%s", inbuf);
      if (fputs(inbuf,ofp)==EOF)
		  printf("fputs failed.\n");
   }
   InLineNo++;          // Update line number (including __LINE__).
   sprintf(bbline.body, "%5d", InLineNo);
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

   if((fp = fopen(fname,"r")) == NULL) {
      err(9, fname);
      return;
   }

   fin = fp;
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
         strcpy(inbuf, &s[2]);
         for(ii = 0; inbuf[ii] && IsIdentChar(inbuf[ii]); ii++)
            buf[ii] = inbuf[ii];
         buf[ii] = 0;
         if (buf[0]) {
            tdef.nArgs = -1;
            tdef.name = StorePlainStr(buf);
            if (inbuf[ii++] == '=') {
               for(jj = 0; inbuf[ii];)
                  buf[jj++] = inbuf[ii++];
               buf[jj] = 0;
               tdef.body = (char *)(buf[0] ? StorePlainStr(buf) : "");
            }
            else
               tdef.body = "";
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
            sprintf(buf, " %2d ", dp->nArgs);
         else 
            sprintf(buf, " -- ");
         printf("%-12.12s %4.4s %-40.40s %5d %-12.12s\n", dp->name, buf, dp->body, dp->line, dp->file);
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

   if (SymSpacePtr + strlen(body) > SymSpace + STRAREA - 2000) {
      err(5);
      exit(3);
   }
   ptr = SymSpacePtr;
   va_start(argptr, body);
   SymSpacePtr += vsprintf(SymSpacePtr, body, argptr) + 1;
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

   if (SymSpacePtr + strlen(str) > SymSpace + STRAREA) {
      err(5);
      exit(3);
   }
   strcpy(SymSpacePtr, str);
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
   struct tm *LocalTime;

   time(&ltm);
   LocalTime = localtime(&ltm);
   bbstdc.body = StoreStr("1");
   bbline.body = StoreStr("%5d", 1);
   bbfile.body = StoreStr(SourceName);
   bbdate.body = StoreStr("%02d/%02d/%02d", LocalTime->tm_year, LocalTime->tm_mon+1, LocalTime->tm_mday);
   bbtime.body = StoreStr("%02d:%02d:%02d", LocalTime->tm_hour, LocalTime->tm_min, LocalTime->tm_sec);
   bbpp.body = StoreStr("fpp");

   htInsert(&HashInfo, &bbstdc);
   htInsert(&HashInfo, &bbline);
   htInsert(&HashInfo, &bbfile);
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
   
   HashInfo.size = MAXMACROS;
   HashInfo.width = sizeof(SDef);
   if (argc < 2)
   {
		fprintf(stderr, "FPP version 1.22  (C) 1998-2018 Robert T Finch  \n");
		fprintf(stderr, "\nfpp [options] <filename> [<output filename>]\n\n");
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
   bbfile.body = StorePlainStr("<cmdln>");
   for(xx = 1; strchr("-/+", argv[xx][0]) && (xx < argc); xx++)
      parsesw(argv[xx]);

	if (banner)
		fprintf(stderr, "FPP version 1.22  (C) 1998-2018 Robert T Finch  \n");

   /* ---------------------------
         Get source file name.
   --------------------------- */
   if(xx >= argc) {
      fprintf(stderr, "\nSource filename[.c]: ");
      fgets(SourceName, sizeof(SourceName)-3, stdin);
   }
   else {
      strncpy(SourceName, argv[xx], sizeof(SourceName)-3);
      xx++;
   }
   /* -----------------------------------------------------
          Check for extension and add one if neccessary.
   ----------------------------------------------------- */
   if (!strchr(SourceName, '.'))
      strcat_s(SourceName, sizeof(SourceName)-1, ".c");

   OutputName[0] = '\0';
   if (xx < argc) {
      strncpy(OutputName, argv[xx], sizeof(OutputName));
      if (!strchr(OutputName, '.'))
         strcat_s(OutputName, sizeof(OutputName)-1,".pp");
   }

   /* ------------------------------
         Define standard defines.
   ------------------------------ */
   SetStandardDefines();
   /* -----------------------
         Process file. 
   ----------------------- */
   if (debug)
	   fdbg = fopen("fpp_debug_log","w");
   else
	   fdbg = NULL;
   if (OutputName[0]) {
      ofp = fopen(OutputName, "w");
      if (ofp == NULL) {
         err(9, OutputName);
         exit(0);
      }
   }
   else
      ofp = stdout;
   errors = warnings = 0;
   bbfile.body = StorePlainStr(SourceName);
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
