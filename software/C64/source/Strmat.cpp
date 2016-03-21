#include "stdafx.h"
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "fwstr.h"
#include "fwlib.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved
=============================================================== */

/* ---------------------------------------------------------------------------
   int strmat(char *, char *, ...);
   char *matstr;     pointer to string to match parameters from
   char *format;     pointer to format string indicating parameter types and
                     match characters.
   ... (? *) pointer to type of parameter that must be matched in the format
         string.

   Description :

      Performs pattern matching on strings.
         %c - single character
         %d - integer

         %s - a string of characters ended by a match of the next character
              in the format string
               strmat("Hello [there", "%s[", &string);
              would return "Hello " in string.

         %% - match '%' sign

      A space in the format string causes any number (include 0) of space,
   tab or newline characters in the match string to be ignored.
      Any character in the match string not matching the one in the format
   string causes a false return.
      A '*' in the format string after '%' indicates to suppress assignment
   to a variable.

   Returns :
      TRUE if match string matched format string, otherwise false.

   Changes
           Author      : R. Finch
           Date        : 09/09/90
           Release     : 1.0
           Description : new module

   Changes
           Author      : R. Finch
           Date        : 92/09/29
           Release     : 
           Description : suppression of assignment indicator (*) added.

--------------------------------------------------------------------------- */

int strmat(char *str, char *format, ...)
{
   va_list ptr;
   int i, formatlen, c = TRUE, xx, Suppress = FALSE;
   char *tmp;
   long value;

   va_start(ptr, format);
   formatlen = strlen(format);
   for(i = 0; i < formatlen && *str; i++)
   {
      /* ----------------------------------------------------------
            '%' indicates to match a particular type of variable
         against the contents of the match string.
      ---------------------------------------------------------- */
      if(format[i] == '%')
      {
         /* ----------------------------------------------------------
               Check for flag indicating suppression of value read.
         ---------------------------------------------------------- */
         ++i;
         if (format[i] == '*') {
            Suppress = TRUE;
            i++;
         }
         switch(format[i])
         {
            /* ----------------------------------------------------
                  If a second '%' then a match against a '%' was
               really desired.
            ---------------------------------------------------- */
            case '%':
               if (*str != '%')
                  goto strmatx;
               break;

            case 'd':
               value = strtol(str, &tmp, 0);
			   if (tmp==str)	// there wasn't a number
				   goto strmatx;
               if (!Suppress)
                  *va_arg(ptr, int *) = (int)value;
               str = tmp;
               break;

            case 'c':
/*
               if (!Suppress)
                  *va_arg(ptr, char *) = *str;
*/
				if (!Suppress) {
					tmp = va_arg(ptr, char *);
					*tmp = *str;
				}
               str++;
               break;

            case 's':
               if (!Suppress) {
                  tmp = va_arg(ptr, char *);
                  for (xx = 0; str[xx] && str[xx] != format[i+1]; xx++)
                     tmp[xx] = str[xx];
                  tmp[xx] = '\0';
               }
               else
                  for (xx = 0; str[xx] && str[xx] != format[i+1]; xx++);
               str += xx;
               break;
         }
         Suppress = FALSE;
      }
      /* -----------------------------------------------------------------
            A space in the format string causes any spaces in the match
         string to be skipped. A space is a space, tab, vertical tab,
         newline, carriage return or form feed character.
      ----------------------------------------------------------------- */
      else if (format[i] == ' ')
         while(isspace(*str)) str++;
      /* ----------------------------------------------------------------
            Match character in match string against contents of format
         string.
      ---------------------------------------------------------------- */
      else if (format[i] != *str)
         goto strmatx;
      else
         str++;
   }
strmatx:
   va_end(ptr);
   if (i < formatlen)
      while(isspace(format[i])) i++;
   return ((i < formatlen) ? FALSE : *str ? FALSE : c);
}


// same as above except case insensitive
int strimat(char *str, char *format, ...)
{
   va_list ptr;
   int i, formatlen, c = TRUE, xx, Suppress = FALSE;
   char *tmp;
   long value;

   va_start(ptr, format);
   formatlen = strlen(format);
   for(i = 0; i < formatlen && *str; i++)
   {
      /* ----------------------------------------------------------
            '%' indicates to match a particular type of variable
         against the contents of the match string.
      ---------------------------------------------------------- */
      if(format[i] == '%')
      {
         /* ----------------------------------------------------------
               Check for flag indicating suppression of value read.
         ---------------------------------------------------------- */
         ++i;
         if (format[i] == '*') {
            Suppress = TRUE;
            i++;
         }
         switch(format[i])
         {
            /* ----------------------------------------------------
                  If a second '%' then a match against a '%' was
               really desired.
            ---------------------------------------------------- */
            case '%':
               if (*str != '%')
                  goto strmatx;
               break;

            case 'd':
               value = strtol(str, &tmp, 0);
 			   if (tmp==str)	// there wasn't a number
				   goto strmatx;
			   if (!Suppress)
                  *va_arg(ptr, int *) = (int)value;
               str = tmp;
               break;

            case 'c':
               if (!Suppress)
                  *va_arg(ptr, char *) = *str;
               str++;
               break;

            case 's':
               if (!Suppress) {
                  tmp = va_arg(ptr, char *);
                  for (xx = 0; str[xx] && toupper(str[xx]) != toupper(format[i+1]); xx++)
                     tmp[xx] = str[xx];
                  tmp[xx] = '\0';
               }
               else
                  for (xx = 0; str[xx] && toupper(str[xx]) != toupper(format[i+1]); xx++);
               str += xx;
               break;
         }
         Suppress = FALSE;
      }
      /* -----------------------------------------------------------------
            A space in the format string causes any spaces in the match
         string to be skipped. A space is a space, tab, vertical tab,
         newline, carriage return or form feed character.
      ----------------------------------------------------------------- */
      else if (format[i] == ' ')
         while(isspace(*str)) str++;
      /* ----------------------------------------------------------------
            Match character in match string against contents of format
         string.
      ---------------------------------------------------------------- */
      else if (toupper(format[i]) != toupper(*str))
         goto strmatx;
      else
         str++;
   }
strmatx:
   va_end(ptr);
   if (i < formatlen)
      while(isspace(format[i])) i++;
   return ((i < formatlen) ? FALSE : *str ? FALSE : c);
}
