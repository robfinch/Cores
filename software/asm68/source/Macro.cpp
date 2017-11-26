#include <stdio.h>
#include <buf.hpp>
#include "err.h"
#define ALLOC
#include "macro.h"
#undef ALLOC
#include "fasm68.h"

/* ---------------------------------------------------------------
   Description :
      Gets the body of a macro defined in the following fashion:

      macro <macro name> <parm1> [,<parm n>]...
         <macro text>
      endm
                
   All macro bodies must be < 2k in size. Macro parameters are
   matched up with their positions in the macro. A $<number>
   (as in $1, $2, etc) is substituted in the macro body in
   place of the parameter name (we don't actually care what
   the parameter name is).
      Macros continued on the next line with '\' are also
	 processed. The newline is removed from the macro.
--------------------------------------------------------------- */

char *CMacro::InitBody(char *plist[])
{
   char *b, *p1, *sptr, *eptr;
   static char buf[MAX_MACRO_EXP];
   int ii, found, c, idlen;
   CBuf tb;

   memset(buf, 0, sizeof(buf));
   tb.set(body, strlen(body));
   b = buf;
   while (1)
   {
StartOfLoop:
      c = tb.PeekCh();
      if (c < 1)
         break;
      // If quote detected scan to end of quote, end of line, or end of
      // buffer.
      if (c == '"') {
         while(1) {
            *b = c;
            b++;
            c = tb.NextCh();
            if (c == '\n' || c == '"')
               break;
            if (c < 1)
               goto EndOfLoop2;
         }
         goto EndOfLoop;
      }
      // If quote detected scan to end of quote, end of line, or end of
      // buffer.
      else if (c == '\'') {
         while(1) {
            *b = c;
            b++;
            c = tb.NextCh();
            if (c == '\n' || c == '\'')
               break;
            if (c < 1)
               goto EndOfLoop2;
         }
         goto EndOfLoop;
      }
      else if (c == '\n') {
         goto EndOfLoop;
      }

      // Copy spaces
      else if (isspace(c))
         goto EndOfLoop;
      
      if (plist == NULL)
         goto EndOfLoop;
         
      // First search for an identifier to substitute with parameter
      p1 = tb.Ptr();
      idlen = tb.GetIdentifier(&sptr, &eptr, FALSE);
      if (idlen)
      {
         for (found = ii = 0; plist[ii]; ii++)
            if (strncmp(plist[ii], sptr, idlen) == 0)
            {
               *b = MACRO_PARM_MARKER;
               b++;
               *b = (char)ii+'A';
               b++;
               found = 1;
               goto StartOfLoop;
            }
         // if the identifier was not a parameter then just copy it to
         // the macro body
         if (!found)
         {
            strncpy(b, p1, eptr - p1);
            b += eptr-p1;
            goto StartOfLoop;
         }
      }
      else
         tb.setptr(p1);    // reset inptr if no identifier found
EndOfLoop:
      *b = c;
      b++;
      c = tb.NextCh();
   }
EndOfLoop2:
   *b = 0;
   return (buf);
}


/* ---------------------------------------------------------------------------
   char *SubParmList(list);
   char *list[];  - substitution list

   Description:
      Searches the macro body and substitutes the passed parameters for the
   placeholders in the macro body. A pointer to a static buffer containing
   a copy of the macro body with the argument susbstituted in is returned.
      The actual macro body is not modified.
--------------------------------------------------------------------------- */

char *CMacro::SubParmList(char *parmlist[])
{
   static char buf[MAX_MACRO_EXP];
   int count = sizeof(buf);
   char *s, *o = buf, *bdy = body;

   memset(buf, 0, sizeof(buf));

   // Scan through the body for the correct substitution code
   for (o = buf; *bdy && --count > 0; bdy++, o++)
   {
      if (*bdy == MACRO_PARM_MARKER)   // we have found a parameter to sub
      {
         // Copy substitution to output buffer
         bdy++;
         for (s = parmlist[*bdy-'A']; *s && --count > 0;)
            *o++ = *s++;
         --o;
         continue;
      }
      *o = *bdy;
   }
   return (buf);
}


/* -----------------------------------------------------------------------------
   Description :
      Copies a macro into the input buffer. When the '@' symbol is
   encountered while performing the copy the instance number of the macro
   is substituted for the '@' symbol.
      Resets the input buffer pointer to the start of the macro.
      Increments the MacroCounter.

   plist = list of parameters to substitute into macro
   slen; - the number of characters being substituted
   eptr = where to begin substitution
   tomove = number of characters to move
----------------------------------------------------------------------------- */

void CMacro::sub(char *plist[], char *eptr, int slen, int tomove)
{
   int mlen, dif;
   static char buf[MAX_MACRO_EXP];
   int ii, jj;
   char *mp;

   // Substitute parameter list into macro body, if needed.
   mp = nargs ? SubParmList(plist) : body;

   // Stick in macro number where requested
   MacroCounter++;
   memset(buf, '\0', sizeof(buf));
   for (jj = ii = 0; mp[ii]; ii++)
   {
      if (mp[ii] == '@')
         jj += sprintf(&buf[jj], "%ld", MacroCounter);
      else
         buf[jj++] = mp[ii];
   }

   mlen = jj;                    // macro length
   // dif = difference in length between characters being substituted and
   // macro substitution
   dif = mlen - slen;
//   printf("mlen = %d,dif = %d\n", mlen, dif);
//   printf("writing over:%s|\n", eptr+dif);
//   printf("writing from:%s|\n", eptr);
   if (dif > 0)
      memmove(eptr+dif, eptr, tomove - dif); // shift open space in destination buffer
   else if (dif < 0)
      memmove(eptr, eptr - dif, tomove + dif);
//   printf("wro:%s|\n", eptr);
//   printf("buf:%s|\n", buf);
   memcpy(eptr, buf, mlen);      // copy macro body in place over identifier
}


/* ----------------------------------------------------------------------------
   Compare two.
---------------------------------------------------------------------------- */
int CMacro::cmp(CMacro *ps)
{
   return strcmp((char *)name, (char *)ps->name);
}

/* ----------------------------------------------------------------------------
   Print a single symbol.
---------------------------------------------------------------------------- */

int CMacro::print(FILE *fp)
{
   fprintf(fp, "%-32.32s  %2d   %5d  %s\n", name, nargs, line, ::File[file].name);
//   fprintf(fp, "%s\n", body);
   return 1;
}


/* -----------------------------------------------------------------------------
   Description :

   Returns :

----------------------------------------------------------------------------- */

/* HashPJW Aho's - version
*/
//#define SEVENTY_FIVE_PERCENT ((int)(NBITS(unsigned int) * .75))
//#define TWELVE_PERCENT ((int)(NBITS)(unsigned int)*0.125))
#define SEVENTY_FIVE_PERCENT  12
#define TWELVE_PERCENT 2
#define HIGH_BITS (~((unsigned)(~0) >> TWELVE_PERCENT))

SHashVal CMacro::hash(int ssz)
{
   static SHashVal h;
   unsigned g;
   unsigned char *nm = (unsigned char *)name;

   h.delta = 1;
   h.hash = 0;
   for (; *nm; ++nm)
   {
      h.hash = ((h.hash << TWELVE_PERCENT) + *nm);
      if (g = (h.hash & HIGH_BITS))
         h.hash = ((h.hash^(g>>SEVENTY_FIVE_PERCENT)) & ~HIGH_BITS);
   }
   h.hash %= ssz; // ***** this is the size of the macro table
   return h;
}


/*****************************************************************************
*****************************************************************************/

CMacroTbl::CMacroTbl(unsigned nel)
{
   NumSyms = 0;
   sz = nel;
   tbl = (CHashBucket **)calloc(nel, sizeof(CHashBucket *));
   if (tbl == NULL)
      throw FatalErr(E_MEMORY);
}


/* -----------------------------------------------------------------------------
   Description :
      Allocates a new symbol table element.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */

CMacro *CMacroTbl::allocmac()
{
   CHashBucket *ptr;

   ptr = (CHashBucket *)calloc(1, sizeof(CHashBucket)+sizeof(CMacro));
   if (ptr == NULL)
      throw FatalErr(E_MEMORY);
   return (CMacro *)(ptr + 1);
}


/* -----------------------------------------------------------------------------
   void CSymbolTbl::freesym(void *ptr);
   ptr - pointer to data area of symbol table element.

   Description :
      Deallocates a symbol table element.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
void CMacroTbl::freemac(CMacro *ptr)
{
   free((char *)((CHashBucket *)ptr - 1));
}


/* -----------------------------------------------------------------------------
   void *CSymbolTblB::insert(void *item);
   item - pointer to entry to insert

   Description :
      Insert data item in table.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
CMacro *CMacroTbl::insert(CMacro *item)
{
   CHashBucket **p, *tmp, *hsym;

   hsym = (CHashBucket *)item - 1;
   p = &tbl[item->hash(sz).hash];
   tmp = *p;
   *p = hsym;
   hsym->insert(tmp, p);
   NumSyms++;
   return item;
};


/* -----------------------------------------------------------------------------
   void *CSymbolTbl::remove(void *item);
   item - pointer to entry to remove

   Description :
      Removes data item in table.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
void CMacroTbl::remove(CMacro *item)
{
   CHashBucket *hsym = (CHashBucket *)item - 1;

   if (item) {
      --NumSyms;
      if (*(hsym->prev) = hsym->next)
         hsym->next->prev = hsym->prev;
   }
}


/* -----------------------------------------------------------------------------
   void *CSymbolTbl::find(void *item);
   item - pointer to entry to find

   Description :
      Find data item stored in table.
      
      The bucket from the table contains no data, it is just the head of
   a chain of buckets containing data.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
CMacro *CMacroTbl::find(CMacro *item)
{
   CHashBucket *p;

   for (p = tbl[item->hash(sz).hash]; p && item->cmp((CMacro *)(p+1)); p = p->next);
   return p ? (CMacro *)(p + 1) : NULL;
}


/* -----------------------------------------------------------------------------
   Description :
      Prints a symbol table. If sorted output is requested but there is
   insufficent memory then unsorted output results.

   Returns:
      (int) 1 if table is output as requested
            0 if memory for sorted table could not be allocated.
----------------------------------------------------------------------------- */
int CMacroTbl::print(FILE *fp, int sortFlag)
{
   CHashBucket **OutTab, *hsym;
   CMacro *sym;
   int i, j, ret = 1;

   /* -------------------------------------------------------------------
         This chunk of code builds an additional table containing
      pointers to every symbol element in the symbol table. It
      essentially maps all entries into a linear(vertical) list for
      sorting.
   ------------------------------------------------------------------- */
   fprintf(fp, "\nMacro Table:\n");
   fprintf(fp, " #  Name                            Nargs  Line   File\n");
   if (sortFlag) {
      OutTab = (CHashBucket **)malloc(NumSyms * sizeof(CHashBucket *));
      if (!OutTab) {
         ret = 0;
         goto nosort;
      }
      for (j = i = 0; i < NumSyms; j++) {
         // Extract all hash clash elements from horizontal linked list.
         for (hsym = tbl[j]; hsym; hsym = hsym->next) {
            if (i > NumSyms)
               throw FatalErr(E_TBLOVR, "Internal error <print>, table overflow.\n");
            OutTab[i] = hsym;  // map to vertical list
            i++;
         }
      }

      // Now that we have a linear list we can sort and print
      sort(OutTab);
      for (i = 0; i < NumSyms; i++) {
         hsym = OutTab[i];
         sym = (CMacro *)(hsym+1);
         fprintf(fp, "%3d ", i);
         sym->print(fp);
      }
      free(OutTab);
   }

   // Prints out symbol table unsorted.
   else
   {
nosort:
      for (j = i = 0; i < NumSyms; j++)
      {
         for (hsym = tbl[j]; hsym; hsym = hsym->next) {
            sym = (CMacro *)(hsym+1);
            fprintf(fp, "%3d ", i);
            sym->print(fp);
            fprintf(fp, "\n");
            i++;
         }
      }
   }
   return ret;
}


/* -----------------------------------------------------------------------------
   Description:
      This routine performs a shell sort on an array of pointers.
----------------------------------------------------------------------------- */
void CMacroTbl::sort(CHashBucket **base)
{
   int i,j,gap;
   CHashBucket *tmp, **p1, **p2;
   CMacro *ps1, *ps2;

   for (gap = 1; gap <= NumSyms; gap = 3 * gap + 1);

   for (gap /= 3; gap > 0; gap /= 3)
      for (i = gap; i < NumSyms; i++)
         for (j = i - gap; j >= 0; j -= gap) {
            p1 = &base[j];
            p2 = &base[j+gap];

            ps1 = (CMacro *)((*p1)+1);
            ps2 = (CMacro *)((*p2)+1);
            if (ps1->cmp(ps2) <= 0)
               break;

            tmp = *p1;
            *p1 = *p2;
            *p2 = tmp;
         }
}




