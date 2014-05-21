/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	StripComments.cpp

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

		Scan through the string, replacing C-like comments with
	space characters. Multiple line comments are supported as
	are to end of line comments. Comments within macros are
	preserved when the ';;' indicator is used.

=============================================================== */

#include <string.h>
#include <ctype.h>
#include "ctypex.h"

int StripComments(char *string, int incomment, int CollectingMacro)
{
	int incomment;
	char *p;

	for (; *string; ++string)
	{
		if (*string == '/')
		{
			p = string;
			if (string[1]=='*')
			{
				string += 2;
				while(*string && *string != '*')
					string++;
				if (string[1]=='/')
					string += 2;
				strcpy(p, string);
			}
		}
	}


		// Check for block comment closure
		if (incomment) {
			if (*string == '~')
				incomment--;
			else if (!strcmp(string, "*/")) {
				incomment--;
				*string = ' ';
				string++;
		}
		*string = ' ';
	}

      else {
         // Look for 'comment ~' comment
         if (!strnicmp(string, "comment", 7) && !IsIdentChar(string[7]))
            incomment++;

         // Look for block comment
         if (!strcmp(string, "/*"))
            incomment++;

         // To EOL comment
         if (!strcmp(string, "//"))
            while(*string && *string != '\n')
               *string++ = ' ';

         // Look for ';' comment
         if (*string == ';') {
            if (CollectingMacro) {
               if (string[1] == ';') {
                  string++;
                  continue;
               }
            }

            while(*string && *string != '\n')
               *string++ = ' ';
         }
      }
   }

   return incomment;
}



