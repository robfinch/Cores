#include <stdio.h>
#include <stdlib.h>
#include "d:\projects\bcinc\fwstr.h"
#include <ctype.h>
#include "err.h"
#include <buf.hpp>

extern int min(int, int);

/* -----------------------------------------------------------------------------
   char *ptr;     - pointer to buffer to scan for identifier
   char **sptr;   - start of identifier (leading spaces skipped)
   char **eptr;   - just after end of identifier if found
   
   Description:
      Gets an identifier from input.

   Returns:
      The length of the identifier (0 if not found)
----------------------------------------------------------------------------- */

int CBuf::GetIdentifier(char **sptr, char **eptr, char pt)
{
   char *sp, *ep;
        
   skipSpacesLF();
   sp = ptr;
   if (IsFirstIdentChar(*ptr) || (*ptr=='.' && pt))
      do { ptr++; } while(IsIdentChar(*ptr));
   ep = ptr;
   if (eptr)
      *eptr = ep;
   if (sptr)
      *sptr = sp;
   return (ep - sp);
}


/* -----------------------------------------------------------------------------
   char **eptr;   - just after end of identifier if found
   
   Description:
      Gets a numeric from input.

   Returns:
      (long) The value of the numeric
----------------------------------------------------------------------------- */

unsigned long CBuf::GetNumeric(char **eptr, int base)
{
   unsigned long value = 0;
   char *eeptr;

   value = strtoul(ptr, &eeptr, base);
   ptr = eeptr;
   if (eptr)
      *eptr = eeptr;
   return (value);
}


// Gets next character from a buffer
int CBuf::NextCh()
{
   int ch;

   ch = *ptr;
   if (*ptr)
      ptr++;
   return (ch);
}

// skips spaces in the buffer
void CBuf::SkipSpaces()
{
   int ch;

   do
   {
      ch = NextCh();
   } while (isspace(ch));
   unNextCh();
}

// skips spaces without skipping line feeds in the buffer
void CBuf::skipSpacesLF()
{
	int ch;

	do
	{
		ch = NextCh();
	} while (isspace(ch)&&ch!='\n');
	if (ch!=0)
		unNextCh();
}


// skips to the next non space character
int CBuf::NextNonSpace()
{
   int ch;

   do
   {
       ch = NextCh();
   } while (isspace(ch));
   return (ch);
}


// Get the next line
int CBuf::NextLn(char *bp, int maxc)
{
   int aa;

   aa = min(maxc, strcspn(ptr, "\r\n"));
   if (aa)
      strncpy(bp, ptr, aa);
   return (aa);
}


// writes a string to the current buffer position
void CBuf::write(char *str)
{
   int len;

   len = strlen(str);
   strcpy(ptr, str);
   ptr += len;
}


// writes a string to the current buffer position and appends a newline character
void CBuf::writeln(char *str)
{
   int len;

   len = strlen(str);
   strcpy(ptr, str);
   ptr += len;
   strcpy(ptr, "\n");
   ptr++;
}

/* ---------------------------------------------------------------------------
   void CBuf::ScanToEOL();

   Description :
      Scans to the end of line or buffer.
--------------------------------------------------------------------------- */

void CBuf::ScanToEOL()
{
   char ch;

   while(1)
   {
      ch = (char)NextCh();
      if (ch < 1 || ch == '\n')
         break;
   }
}

