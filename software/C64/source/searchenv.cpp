// ============================================================================
//        __
//   \\__/ o\    (C) 2012,2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
//#include <unistd.h>

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

void searchenv(char *filename, char *envname, char *pathname)
{
   static char pbuf[5000];
   char *p;
//   char *strpbrk(), *strtok(), *getenv();

   strcpy(pathname, filename);
   if (access(pathname, 0) != -1)
      return;

   /* ----------------------------------------------------------------------
         The file doesn't exist in the current directory. If a specific
      path was requested (ie. file contains \ or /) or if the environment
      isn't set, return a NULL, else search for the file on the path.
   ---------------------------------------------------------------------- */
   
   if (!(p = getenv(envname)))
   {
      *pathname = '\0';
      return;
   }

   strncpy(pbuf, p, sizeof(pbuf));
   if (p = strtok(pbuf, ";"))
   {
      do
      {
         sprintf(pathname, "%0.90s\\%s", p, filename);

         if (access(pathname, 0) >= 0)
            return;
      }
      while(p = strtok(NULL, ";"));
   }
   *pathname = 0;
}
