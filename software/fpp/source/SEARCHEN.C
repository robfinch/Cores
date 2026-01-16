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
#include <stdlib.h>
#include <string.h>
#include <io.h>

/* ---------------------------------------------------------------------------
   void searchenv(filename, envname, pathname);
   char *filename;
   char *envname;
   char *pathname;

   Description :
      Search for a file by looking in the directories listed in the envname
   environment. Puts the full path name (if you find it) into pathname.
   Otherwise set *pathname to 0. Unlike the DOS PATH command (and the
   microsoft _searchenv), you can use either a space or a semicolon to
   separate directory names. The pathname array must be at least 128
   characters.

   Returns :
      nothing
--------------------------------------------------------------------------- */

void searchenv(char *filename, char *envname, char *pathname, int pathsize)
{
   static char pbuf[5000];
   char* envbuf;
   char *p, *np;
   size_t buflen;
//   char *strpbrk(), *strtok(), *getenv();

   strcpy_s(pathname, pathsize-1, filename);
   if (_access(pathname, 0) != -1)
      return;

   /* ----------------------------------------------------------------------
         The file doesn't exist in the current directory. If a specific
      path was requested (ie. file contains \ or /) or if the environment
      isn't set, return a NULL, else search for the file on the path.
   ---------------------------------------------------------------------- */
   
   envbuf = NULL;
   buflen = 0;
   if (_dupenv_s(&envbuf, &buflen, envname) != 0)
   {
      *pathname = '\0';
      return;
   }
   p = envbuf;

   strcpy_s(pbuf, sizeof(pbuf)-1, "");
   if (p)
    strcat_s(pbuf, sizeof(pbuf)-1, p);
   np = NULL;
   if (p = strtok_s(pbuf, ";", &np))
   {
     do
      {
       if (p[strlen(p)-1]=='\\')
	         sprintf_s(pathname, pathsize-1, "%0.200s%s", p, filename);
		  else
		     sprintf_s(pathname, pathsize-1, "%0.200s\\%s", p, filename);
         if (_access(pathname, 0) >= 0)
            return;
      }
      while(p = strtok_s(NULL, "; ", &np));
   }
   *pathname = 0;
   free(envbuf);
}

