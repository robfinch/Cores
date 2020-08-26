#ifndef MACRO_H
#define MACRO_H

#ifndef BUF_HPP
#include <buf.hpp>
#endif

#ifndef HASH_H
#include "d:\projects\fw\inc\hash.h"
#endif

#include "sym.h"   // CHashBucket

#define NAME_MAX  32
#define MAX_MACRO_EXP   2048    // Maximum macro expansion

class CMacroTbl;

/* --------------------------------------------------------------------------
   Macro class.
-------------------------------------------------------------------------- */
class CMacro
{
   friend class CMacroTbl;
   char name[NAME_MAX+1];  // Input variable name
   char *body;
   int nargs;              // number of arguments
   int line;               // line symbol defined on
   int file;               // file number symbol defined in
public:
   SHashVal hash(int);
   int cmp(CMacro *);
   int Nargs() { return nargs; };
   char *Name() { return name; };
   int Line() { return line; };
   int File() { return file; };
   void SetBody(char *bdy) { body = bdy; };
   void SetName(char *nm) { strncpy((char *)name, nm, NAME_MAX); };
   void SetArgCount(int ac) { nargs = ac; };
   void SetFileLine(int fl, int ln) { file = fl; line = ln; };
   char *InitBody(char *[]);
   char *SubParmList(char *[]);             // substitute parameter list into macro body
   char *SubArg(char *, int, char *);
   char *GetBody(char *[]);
   void sub(char *[], char *, int, int);
   void write(FILE *);
   int print(FILE *);
};


/* -------------------------------------------------------------------------
   Description :
------------------------------------------------------------------------- */

class CMacroTbl
{
   friend class CMacro;
public:
   int NumSyms;      // Number of symbols stored in the table
   unsigned sz;      // Number of elements in table
   CHashBucket **tbl; // pointer to table

   CMacroTbl(unsigned);
   ~CMacroTbl() { if (tbl) ::free(tbl); };

   CMacro *allocmac();
   void freemac(CMacro *);

   int print(FILE *, int);
   void *next(void *);

   CMacro *insert(CMacro *);
   void remove(CMacro *);
   CMacro *find(CMacro *);
   void sort(CHashBucket **);
};

#endif
