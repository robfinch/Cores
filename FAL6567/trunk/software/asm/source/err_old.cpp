#include <stdio.h>
#include <stdarg.h>
#include <setjmp.h>
#include <stdlib.h>
#include <string.h>
#include "err.h"
#include "asm24.h"

/* ===============================================================
	(C) 2000 Bird Computer
	All rights reserved

		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

/* --------------------------
      Error message table.
-------------------------- */

static char *error[] =
{
   "Eunbalanced parentheses",                // 2001
   "Edivision by zero",
   "Eundefined symbol '%s'",
   "E'%s' already defined",
   "Ewrong length",                          // 2005
   "Eexpecting a register",
   "E",
   "Einvalid instruction or argument",
   "Eerror",    // macro definition error
   "E",         //structured code error",    // 2010
   "Ephasing error - '%s' value different on second pass",
   "Wunknown command line switch '%s' ignored",
   "Eunable to open file '%s'",
   "Eno closing quotes",
   "Ecan not calculate mod(0)",              // 2015
   "Einvalid register '%s'",
   "Etoo many ",   // macros
   "EMore memory required than is available.",
   "E",            // endif without if",
   "E",            // else without if",      // 2020
   "E",            // endwhile without while",
   "E",            // endloop without loop",
   "E",            // forever without do",
   "E'%s' undefined",    // macro
   "E",            // until without do",     // 2025
   "Woperand addressing mode '%s' not supported by selected processor",
   "Eextra ')'",
   "Ebranch out of range - displacement %0lX",
   "Wword assembled at odd address - output padded with zero byte",
   "W%d too big for immediate data - truncated",   // 2030
   "W%d too big for shift count - truncated",
   "Wshort branch converted to long branch",
   "Wquick immediate data (%lX) truncated",
   "Eerror writing output",
   "Winvalid label '%s' - ignored",          // 2035
   "Ebyte size not supported with address registers",
   "W'%c' illegal size for status register operation - assuming word size",
   "W'%c' only byte operations allowed on ccr - assuming byte size",
   "Einvalid operand '%s'",
   "Wonly long ('.L') size supported",       // 2040
   "Winstruction '%s' not supported by selected processor",
   "Edisplacement %lx too large",
   "Wassembler does not support %ld processor",
   "Eillegal scale %d - using scale size of 1",
   "Einvalid memory indirect operand component '%s'", // 2045
   "Esource operand '%s' must be immediate",
   "Emissing destination operand",
   "Eexpecting %d operand(s)",
   "Wonly byte ('.B') size supported",
   "Etoo many operands - extra operands ignored",     // 2050
   "Wno assembler output for shift of zero count",
   "Wonly word ('.W') size supported",
   "Windex scaling '%s' not supported on selected processor",
   "Eexpecting a macro name",
   "Eexpecting ',' separator in macro definition",    // 2055
   "Etoo many files.",
   "Edefined needs a symbol name",
   "Eerror in expression",
   "Wextra '.' ignored",
   "Esize needs a symbolic name",                     // 2060
   "Epublic needs an address label",
   "Eexpecting a label",
   "Etoo many macro parameters",
   "Eincorrect number of macro arguments were passed",
   "Etable overflow",                                 // 2065
   "Emacro too large",
   "Eunrecognized characters on line",
   "Eextra 'endm' encountered",
   "Eexpecting address label",
   "Eaddress size must be either word ('.W') or long ('.L')",  // 2070
   "Esize does not match existing definition",
   "Easm68 error:IsSameType(): Unknown link class",
   "Wwarning, void object has zero for size.",
   "Wwarning, assuming pointer size for label.",
   "Einternal, GetSizeof(): Can't size type: %s.",    // 2075
   "Easm68 error : ConstStr() : Can't make constant for type %s",
   "Easm68 error : GetAlignment(): Object aligned on zero boundary",
   "Easm68 error : SetClassBit() : bad storage class '%c'",
   "Wwarning, compiler does not support floating point.",
   "ECompiler error : GetPrefix(): Can't process type %s.",     // 2080
   "Eonly bits 0-%d available for operation",
   "Einvalid register list '%s'",
   "ECALLM argument count ('%s') must be immediate value",
   "Emust be between 0 and 255 arguments for CALLM",
   "Eregister suppression not supported on selected processor",	// 2085
   "Ememory indirect modes not supported on selected processor",
   "Eonly word (.W) or long (.L) size supported",
	"Eillegal address mode ('%s')",
	"Emissing bitfield specification ('%s')",
	"Eexpecting a data register, found '%s'",	// 2090
	"Eexpecting data register pair, found '%s'",
	"Eexpecting a register pair, found '%s'",
	"Eexpecting register indirect pair, found '%s'",
	"Einvalid cache code '%s' valid codes are I,D,ID,DI,N,<nothing>",
	"Eexpecting (An) address mode, found '%s'",	// 2095
	"Emissing coprocessor extension word(s)",
	"Etoo many coprocessor extension words",
	"Eoperation size not supported",
	"Eexpecting a floating point register, found '%s'",
	"Ek-factor required",	// 2100
	"Eonly extended (.X) size supported",
	"Willegal or reserved ROM constant (#%02x), will read as 0.0 on 68040",
	"Esize must be byte, word, long, or single",
	"Econtrol register (%s) not valid on selected processor",
	"Eexpecting three bit immediate mask, found '%s'",	// 2105
	"Emask value (%02x) out of range, truncated",
	"Efunction code select (%d) out of range",
	"Emmu register (%s) not valid on selected processor",
	"Eexpecting level indicator, found '%s'",
	"Elevel value (%02x) out of range (0-7 valid), truncated",	// 2110
	"Eexpecting an address register, found '%s'",
	"Winstruction should not be executed on an EC040",
	"Etoo few operands",
	"Eexpecting data register or register pair, found '%s'",
	"Edemo version, macro limit reached",	// 2115
	"Edemo version, file inclusion not supported",
	"Edemo version, line number limit reached",
   "Eonly byte (.B) or word (.W) size supported",
   "Erotate count must be one.",
   "Ecab constant must be one of -8,-4,-2,-1,1,2,4, or 8."	// 2120
};


char errMsgBuf[128];

/* --------------------------------------------------------------------------
   Description:
      This is a general purpose error trapping function.
-------------------------------------------------------------------------- */

void err(jmp_buf jb, int num, ...)
{
   int tmp, nn;
   va_list ap;
   char errch;

   tmp = errno;
   va_start(ap, num);
   errch = error[num-2001][0];
   nn = sprintf(errMsgBuf, ERR_MSG_PREFIX " %c%03d (line %d): ", errch, num, lineno);
   nn += vsprintf(&errMsgBuf[nn], &error[num-2001][1], ap);
   sprintf(&errMsgBuf[nn], "\r\n");
   va_end(ap);

   if (errch == 'E')
	   errors2++;
   // Only output err on second pass,
   if (bGen || ForceErr) {
      fputs(errMsgBuf, fpErr);
      if (errch == 'E') {
         File[CurFileNum].errors++;
         errors++;
      }
      else {
         File[CurFileNum].warnings++;
         warnings++;
      }
   }

   if (jb)
      longjmp(jb, num);
}

