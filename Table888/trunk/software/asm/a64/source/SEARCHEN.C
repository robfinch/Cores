#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include <unistd.h>

/* ---------------------------------------------------------------------------
   void searchenv(filename, envname, pathname);
   char *filename;
   char *envname;
   char **pathname;

   Description :
      Search for a file by looking in the directories listed in the envname
   environment. Puts the full path name (if you find it) into pathname.
   Otherwise set *pathname to 0.

   Returns :
      nothing
--------------------------------------------------------------------------- */

void searchenv(char *filename, char *envname, char **pathname)
{
   static char pbuf[5000];
   static char pname[5000];
   char *p;
//   char *strpbrk(), *strtok(), *getenv();

    if (pathname==(char **)NULL)
        return;
   strncpy(pname, filename, sizeof(pname)/sizeof(char)-1);
   pname[4999] = '\0';
   if (access(pname, 0) != -1) {
      *pathname = strdup(pname);
      return;
   }

   /* ----------------------------------------------------------------------
         The file doesn't exist in the current directory. If a specific
      path was requested (ie. file contains \ or /) or if the environment
      isn't set, return a NULL, else search for the file on the path.
   ---------------------------------------------------------------------- */
   
   if (!(p = getenv(envname)))
   {
      *pathname = strdup("");
      return;
   }

   strcpy(pbuf, "");
   strcat(pbuf, p);
   if (p = strtok(pbuf, ";"))
   {
      do
      {
         sprintf(pname, "%0.4999s\\%s", p, filename);

         if (access(pname, 0) >= 0) {
            *pathname = strdup(pname);
            return;
         }
      }
      while(p = strtok(NULL, ";"));
   }
   *pathname = strdup("");
}

