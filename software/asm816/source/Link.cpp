#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "sym.h"
#include "err.h"
#include "fasm68.h"

extern "C" {
   char *BinToAscii(int, int);
};

/******************************************************************************
   Methods operating on links.
******************************************************************************/

#define LCHUNK 50 // New link gets this many nodes in one shot

/* ----------------------------------------------------------------------------
   Description :
      Return a new link. It's initialized to zero, so it's a declarator.
   LCHUNK nodes are allocated from malloc() at one time.

   Returns :
      void *   - pointer to new link object, NULL if insufficient memory
---------------------------------------------------------------------------- */

void *CLink::operator new(size_t sz)
{
   CLink *p;
   int i;

   // If there are no free links then allocate a whole bunch at once.
   if (!HeadFreeLink)
   {
      if (!(HeadFreeLink = (CLink *)malloc(sz * LCHUNK))) {
         err(NULL, E_MEMORY);
         return (NULL);
      }

      // Set up free chain
      for (p = HeadFreeLink, i = LCHUNK; --i > 0; ++p)
         p->next = p+1;

      p->next = NULL;
   }

   p = HeadFreeLink;
   HeadFreeLink = HeadFreeLink->next;
   memset(p, 0, sizeof(CLink));
   return (p);
}


/* ---------------------------------------------------------------------------
   Description :
      Delete a link. Doesn't actually free memory, just puts the link into
   the free list.
--------------------------------------------------------------------------- */

void CLink::operator delete(void *pp)
{
   ((CLink *)pp)->next = HeadFreeLink;
   HeadFreeLink = (CLink *)pp;
}


/* ----------------------------------------------------------------------------
   Description :
      Delete all links in the chain. Nothing is removed from the structure
   table, however. There's no point in discarding the nodes one at a time
   since they're already linked together, so find the first and last nodes
   in the input chain and link the whole list (as free) directly.
---------------------------------------------------------------------------- */

void CLink::DeleteChain()
{
   CLink *start, *lp;

   if (start = this)
   {
      lp = this;
      while(lp->next)   // Find the end of the chain.
         lp = lp->next;

      lp->next = HeadFreeLink; // Link the whole lot into the free list.
      HeadFreeLink = start;
   }
}


/* ---------------------------------------------------------------------------
   Description :
      Copy all initialized fields in src to dst.
--------------------------------------------------------------------------- */

void CLink::CpySpec(CLink *src)
{
   if (src->NOUN) NOUN = src->NOUN;
   if (src->SCLASS) SCLASS = src->SCLASS;
   if (src->LONG) LONG = src->LONG;
   if (src->UNSIGNED) UNSIGNED = src->UNSIGNED;
   if (src->STATIC) STATIC = src->STATIC;
   if (src->EXTERN) EXTERN = src->EXTERN;
   if (src->UNICODE) UNICODE = src->UNICODE;
   if (src->VOLATILE) VOLATILE = src->VOLATILE;
   if (src->INTERRUPT) INTERRUPT = src->INTERRUPT;
   if (src->TRAP) TRAP = src->TRAP;
   if (src->tdef) tdef = src->tdef;

   if (src->SCLASS == CONSTANT || src->NOUN == STRUCTURE)
      memcpy(&VALUE, &src->VALUE, sizeof(src->VALUE));
}


/* ---------------------------------------------------------------------------
   Description :
      Clone the type chain of the source. Return a reference to the cloned
   chain, NULL if there were no declarators to clone. The tdef bit in the
   copy is always cleared.
-------------------------------------------------------------------------- */

CLink *CLink::clone(CLink **endp)
{
   CLink *last, *head = NULL, *tc = this;

   for (; tc; tc = tc->next)
   {
      if (!head)
         head = last = new CLink();
      else
      {
         last->next = new CLink();
         last = last->next;
      }

      memcpy(last, (void *)tc, sizeof(*last));
      last->next = NULL;
      last->tdef = 0;
   }

   *endp = last;
   return (head);
}


/* ---------------------------------------------------------------------------
   Description :
      Return 1 if the types match, 0 if they don't. Ignore the storage
   class. If "relax" is true and the array declarator is the first link
   in the chain, then a pointer is considered equivalent to an array.
--------------------------------------------------------------------------- */

int CLink::IsSameType(CLink *p2, int relax)  // TypesMatch
{
   CLink *p1 = this;

   if (relax && p1->IsPtrType() && p2->IsPtrType())
   {
      p1 = p1->next;
      p2 = p2->next;
   }

   for (; p1 && p2; p1 = p1->next, p2 = p2->next)
   {
      if (p1->lclass != p2->lclass)
         return (0);

      if (p1->lclass == DECLARATOR)
      {
         if ((p1->DCL_TYPE != p2->DCL_TYPE) ||
            (p1->DCL_TYPE == ARRAY && (p1->NUM_ELE != p2->NUM_ELE)))
            return (0);
      }
      else
      {
         if ((p1->NOUN == p2->NOUN) && (p1->LONG == p2->LONG) &&
            (p1->UNSIGNED == p2->UNSIGNED))
         {
            return (p1->NOUN == STRUCTURE) ? p1->V_STRUCT == p2->V_STRUCT : 1;
         }
         return (0);
      }
   }

   err(jbFatalErr, E_LINKCLASS);
   return (0);
}


/* ---------------------------------------------------------------------------
   Description :
      Return the size (in bits) of an object of the type pointed to by p.
   Functions are considered to be pointer sized because that's how they're
   represented internally.

      GetSize returned 
         return (IsArray()) ? GetSize(next) : PSIZE;
      for arrays and
         return CSIZE;
      for structures, but otherwise works the same.
--------------------------------------------------------------------------- */

long CLink::GetSizeof()
{
   size_t size = 0;

   if (IsDeclarator())
      return ((IsArray()) ? NUM_ELE * next->GetSizeof() : PSIZE);
   // must be specifier
   else
   {
      switch(NOUN)
      {
         case BOOL: return (1);
         case CHAR: return ((LONG) ? 16 : 8);
         case INT: return (((LONG) ? LSIZE : ISIZE) * 8);
         case REAL: return (64);
         case STRUCTURE: return (V_STRUCT->size * 8);
         case VOID:
            err(NULL, E_LINKVOIDSZ);
            return (0);
         case LABEL:
            err(NULL, E_LINKLABELSZ);
            return (PSIZE * 8);
         case DATE: return (sizeof(SDate) * 8);
         case TIME: return (sizeof(STime) * 8);
         case STRING: return (sizeof(SString) * 8);
         case CURRENCY: return (sizeof(SCurrency) * 8);
      }
   }
   err(NULL, E_LINKSIZE, TypeStr());
   return (12 * 8);
}


/* ---------------------------------------------------------------------------
   Description :
      Return a string representing the type represented by the link chain.
--------------------------------------------------------------------------- */

char *CLink::TypeStr()
{
   CLink *linkp = this;
   int i;
   static char target[80];
   static char buf[64];
   int available = sizeof(target) - 1;

   *buf = '\0';
   *target = '\0';
   if (!linkp)
      return ("(NULL)");

   if (linkp->tdef)
   {
      strcpy(target, "tdef ");
      available -= 5;
   }

   for (; linkp; linkp = linkp->next)
   {
      if (linkp->IsDeclarator())
      {
         switch(linkp->DCL_TYPE)
         {
            case POINTER:  i = sprintf(buf, "*"); break;
            case ARRAY:    i = sprintf(buf, "[%d]", linkp->NUM_ELE); break;
            case FUNCTION: i = sprintf(buf, "()"); break;
            case LABEL:    i = sprintf(buf, ":"); break;
            default:       i = sprintf(buf, "decl=???"); break;
         }
      }
      else  /* It's a specifier. */
      {
         i = sprintf(buf, "%s %s %s %s", linkp->sd.s.NounStr(),
            linkp->sd.s.sclassStr(), linkp->sd.s.oclassStr(),
            linkp->sd.s.AttrStr());

         if (linkp->NOUN == STRUCTURE || linkp->SCLASS == CONSTANT)
         {
            strncat(target, buf, available);
            available -= i;

            if (linkp->NOUN != STRUCTURE)
               continue;
            else
               i = sprintf(buf, " %s", linkp->V_STRUCT->tag ?
                  linkp->V_STRUCT->tag : "untagged");
         }
      }

      strncat(target, buf, available);
      available -= i;
   }

   return (target);
}


/* ---------------------------------------------------------------------------
   Description :
      Return a string representing the value field at the end of the
   specified type (which must be char *, char, int, long, unsigned int, or
   unsigned long). Return "?" if the type isn't any of these.
--------------------------------------------------------------------------- */

char *CLink::ConstStr()
{
   static char buf[80];

   buf[0] = '?';
   buf[1] = '\0';

   if (IsPointer() && next->IsChar())
   {
      sprintf(buf, "%s%d", L_STRING, next->V_INT);
   }
   else if (!(IsAggregate() || IsFunc()))
   {
      switch(NOUN)
      {
         case BOOL:
            sprintf(buf, "%c", V_BOOL ? "T" : "F");
            break;

         case CHAR:
            sprintf(buf, "'%s' (%d)", BinToAscii(UNSIGNED ?
               V_UINT : V_INT, 1), UNSIGNED ? V_UINT : V_INT, 1);
            break;

         case INT:
            if (LONG)
            {
               if (UNSIGNED)
                  sprintf(buf, "%luL", V_ULONG);
               else
                  sprintf(buf, "%ldL", V_LONG);
            }
            else
            {
               if (UNSIGNED)
                  sprintf(buf, "%u", V_UINT);
               else
                  sprintf(buf, "%d", V_INT);
            }
            break;
      }
   }

   if (*buf == '?')
      err(NULL, E_LINKCONST, TypeStr());
   return (buf);
}


/* ***************************************************************************
   Declaration processing code
*************************************************************************** */
/* ---------------------------------------------------------------------------
   Description :
      Returns the alignment -- the number by which the base address of the
   object must be an even multiple. This number is the same one that is
   returned by GetSizeof(), except for structures which are worst-case
   aligned, and arrays, which are aligned according to the type of the
   first element.
--------------------------------------------------------------------------- */

int CLink::GetAlignment()
{
   int size;

   if (IsArray())
      return (next->GetAlignment());
   if (IsStruct())
      return (ALIGN_WORST);
   if (size = GetSizeof())
      return (size);

   err(jbFatalErr, E_LINKALIGN);
   return (1);
}


/* ---------------------------------------------------------------------------
   Description :
      Return a new specifier link with the sclass field to hold a storage
   class, the first character of which is passed in as an argument ('e')
   for extern 's' for static, and so forth).
--------------------------------------------------------------------------- */

CLink *CLink::NewClassSpec(int FirstCharOfLexeme)
{
   CLink *p = new CLink();

   p->lclass = SPECIFIER;
   p->SetClassBit(FirstCharOfLexeme);
   return (p);
}


/* ---------------------------------------------------------------------------
   Description :
      Change the class of the specifier pointed to by p as indicated by the
   first character in the lexeme. If it's 0, then the defaults are restored
   (fixed, nonstatic, nonexternal). Note that the TYPEDEF class is used
   here only to remember that the input storage class was a typedef, the
   tdef field in the link is set to true (and the storage class is cleared)
   before the entry is added to the symbol table.

   Returns :
      nothing
--------------------------------------------------------------------------- */

void CLink::SetClassBit(int FirstCharOfLexeme)
{
   switch(FirstCharOfLexeme)
   {
      case 0:
         SCLASS = FIXED;
         STATIC = 0;
         EXTERN = 0;
         break;

      case 't':   SCLASS = TYPEDEF; break;
      case 'r':   SCLASS = REGISTER; break;
      case 's':   STATIC = 1; break;
      case 'e':   EXTERN = 1; break;
      case 'i':   INTERRUPT = 1; break;
      case 'v':   VOLATILE = 1; break;

      default:
         err(jbFatalErr, E_LINKSCBIT, FirstCharOfLexeme);
         break;
   }
}


/* ---------------------------------------------------------------------------
   Description :
      Create a new specifier and initialize the type according to the
   indicated lexeme. Input lexemes are:
      bit bool char const currency date double float int long short signed
   unsigned void volatile time interrupt string.
--------------------------------------------------------------------------- */

CLink *CLink::NewTypeSpec(char *lexeme)
{
   CLink *p = new CLink();

   p->lclass = SPECIFIER;

   switch(lexeme[0])
   {
      case 'a': p->LONG = 0; break;    // ascii
      case 'b': p->NOUN = BIT; break;  // bool or bit

      case 'c':
         if (lexeme[1] == 'h')         // char | const | currency
            p->NOUN = CHAR;            // (Ignore const.)
         else if (lexeme[1] == 'u')    // currency
            p->NOUN = CURRENCY;
         break;

      case 'd':
         if (lexeme[1] == 'a') {       // date
            p->NOUN = DATE;
            break;
         }
         else
            p->LONG = 1;               // double (fall though into float)
            
//    case 'e':                        // ignore enum

      case 'f':
         p->NOUN = FLOAT;
         err(NULL, E_LINKFLOAT);       // double
         break;                           /* float */

      case 'i':                        // int | interrupt
         if (lexeme[1] == 'n')
            if (lexeme[2] == 't') {
               if (lexeme[3] == 'e')
                  p->NOUN = INTERRUPT;
               else
                  p->NOUN = INT;
            }
         break;

      case 'l': p->LONG = 1; break;       // long
      
      case 'u':
         if (lexeme[1] == 'n') {
            if (lexeme[2] == 'i')         // unicode
               p->LONG = 1;
            else
               p->UNSIGNED = 1;           // unsigned
         }
         break;

      case 'v':
         if (lexeme[1] == 'o')
            if (lexeme[2] == 'i')         // void | volatile
               p->NOUN = VOID;            // ignore volatile
         break;

      case 's':                           // short | signed | string
         if (lexeme[1] == 't')            // ignore short | signed
            p->NOUN = STRING;
         break;

      case 't': p->NOUN = TIME; break;    // time
   }

   return (p);
}


/* ***************************************************************************
   Value processing code
*************************************************************************** */
/* ---------------------------------------------------------------------------
   Description :
      Return the first character of the LP(), BP(), WP(), etc., directive
   that accesses a variable of the given type. Note that an array or
   structure type is assumed to be a pointer to the first cell at run
   time.
      This prefix will be used in building references to the variable.
--------------------------------------------------------------------------- */

char *CLink::GetPrefix()
{
   char c;

   if (lclass == DECLARATOR)
   {
      switch(DCL_TYPE)
      {
         case ARRAY:    return (next->GetPrefix());
         case LABEL:
         case FUNCTION: return (PTR_PREFIX);
         case POINTER:
            c = *next->GetPrefix();
            if (c == *BYTE_PREFIX) return (BYTEPTR_PREFIX);
            else if (c == *WORD_PREFIX) return (WORDPTR_PREFIX);
            else if (c == *LWORD_PREFIX) return (LWORDPTR_PREFIX);
            return (PTRPTR_PREFIX);
      }
   }
   else
   {
      switch(NOUN)
      {
         case INT: return ((LONG) ? LWORD_PREFIX : WORD_PREFIX);
         case CHAR: return ((LONG) ? WORD_PREFIX : BYTE_PREFIX);
         case DATE:
         case TIME: return (LWORD_PREFIX);
         case STRUCTURE: return (BYTEPTR_PREFIX);
      }
   }
   err(jbFatalErr, E_LINKPREFIX, TypeStr());
   return "";
}




