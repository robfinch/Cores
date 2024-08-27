/*
// ============================================================================
//        __
//   \\__/ o\    (C) 1992-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
*/

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
   "WUnexpected 'endif' - ignored.",
   "WEvaluation of strings not supported. Value assumed to be 1.",
   "EOpen error attempting to open '%s'.",
   "EInvalid identifier '%s'.",
// 10
   "EInvalid exponent.",
   "WMissing 'endif'.",
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
// 25
   "Emacro too large",
   "EConditional operator missing ':'",
   "ECannot rename temp file to output filename: %s",
   "Eendr without rept",
   "Eiterative repeat expecting a symbol",
// 30
   "Eendm without macr",
   "WNested macro definiton (%s)",
   "EMissing endm",
   "EMissing endr",
   "WMax macro (%d) substitutions reached"
};

extern int InLineNo;
extern buf_t* inbuf;

// Generates error messages
void err(int num, ...)
{
	va_list ptr;

  va_start(ptr, num);
  fprintf(stderr, "FPP%c%03.3d(%d): ", error[num][0], num, InLineNo);
  if (ptr)
    vfprintf(stderr, &error[num][1], ptr);
  fprintf(stderr, "\n");
  if (inbuf)
    if (inbuf->buf)
      fprintf(stderr, "%.60s", inbuf->buf);
  va_end(ptr);
  if (error[num][0] == 'E')
    errors++;
  else
    warnings++;
}
