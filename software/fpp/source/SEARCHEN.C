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
   char *p, *np;
//   char *strpbrk(), *strtok(), *getenv();

   strcpy_s(pathname, pathsize-1, filename);
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

   strcpy_s(pbuf, sizeof(pbuf)-1, "");
   strcat_s(pbuf, sizeof(pbuf)-1, p);
   np = NULL;
   if (p = strtok_s(pbuf, ";", &np))
   {
      do
      {
		  if (p[strlen(p)-1]=='\\')
	         sprintf_s(pathname, pathsize-1, "%0.90s%s", p, filename);
		  else
		     sprintf_s(pathname, pathsize-1, "%0.90s\\%s", p, filename);
         if (_access(pathname, 0) >= 0)
            return;
      }
      while(p = strtok_s(NULL, "; ", &np));
   }
   *pathname = 0;
}

