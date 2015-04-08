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

void searchenv(char *filename, char *envname, char *pathname)
{
   static char pbuf[5000];
   char *p;
//   char *strpbrk(), *strtok(), *getenv();

   strcpy(pathname, filename);
   if (_access(pathname, 0) != -1)
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

   strcpy(pbuf, "");
   strcat(pbuf, p);
   if (p = strtok(pbuf, ";"))
   {
      do
      {
         sprintf(pathname, "%0.90s\\%s", p, filename);

         if (_access(pathname, 0) >= 0)
            return;
      }
      while(p = strtok(NULL, "; "));
   }
   *pathname = 0;
}

