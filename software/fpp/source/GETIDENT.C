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
#include <malloc.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

static char buf[MAXLINE];

// Get identifier from input
char *GetIdentifier()
{
   int c, count;
   char *p;
   pos_t* pos;

   if (peek_eof() || PeekCh() == '\n')
      return (NULL);
   memset(buf,0,sizeof(buf));
   p = buf;
   pos = GetPos();
   c = NextNonSpace(0);
   if (c == '.' && PeekCh() == '.' && inptr[1] == '.') {
     strncpy_s(buf, sizeof(buf), "...", 3);
     inptr += 2;
     return (buf);
   }
   if (IsFirstIdentChar(c) && c != 0)
   {
     count = 0;
     do
     {
       buf[count++] = c;
       c = NextCh();
     } while (c != 0 && c != ETB && IsIdentChar(c) && count < sizeof(buf) - 1);
     unNextCh();
   }
   else
     SetPos(pos);
   free(pos);
   return (buf[0] ? buf : NULL);
}

