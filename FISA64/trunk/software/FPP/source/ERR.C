#include <stdio.h>
#include <stdarg.h>
#include "fpp.h"

char *error[] = {
   "EMissing '",
   "EError in expression.",
   "EType mismatch.",
   "EMissing ')' in expression.",
   "EAttempt to divide by zero.",
   "EOut of memory.",
// 5
   "ERedefined symbol '%s' - new definition ignored.",
   "WUnexpected '#endif' - ignored.",
   "WEvaluation of strings not supported. Value assumed to be 1.",
   "EOpen error attempting to open '%s'.",
   "EInvalid identifier '%s'.",
// 10
   "EInvalid exponent.",
   "WMissing '#endif'.",
   "EExpecting macro parameters",
   "EIncorrect number of arguments - expecting %d macro arguments",
   "EToo many macro arguments.",
// 15
   "EError in macro definition - expecting ',' or ')'",
   "EError in macro definition - expecting placeholder or ')'",
   "EMisplaced ')' in macro",
   "ENothing to define",
   "EExpecting a '(' for 'defined'.",
// 20
   "Edefined() operator needs a macro name",
   "Wdefined() expects only a macro name",
   "WDuplicate macro definition '%s' ignored",
   "Eunterminated comment",
   "Eunterminated string constant",    // 25
   "Emacro too large"
};

extern int InLineNo;
extern char inbuf[];

// Generates error messages
void err(int num, ...)
{
	va_list ptr;

	va_start(ptr, num);
   fprintf(stderr, "FPP%c%03.3d(%d): ", error[num][0], num, InLineNo);
	vfprintf(stderr, &error[num][1], ptr);
   fprintf(stderr, "\n");
   fprintf(stderr, "%.60s", inbuf);
	va_end(ptr);
   if (error[num][0] == 'E')
	   errors++;
   else
      warnings++;
}
