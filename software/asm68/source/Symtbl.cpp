#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include <malloc.h>
#include "err.h"
#include "d:\projects\fw\inc\hash.h"
#define ALLOC
#include "sym.h"
#undef ALLOC
#include "fasm68.h"

void CHashBucket::insert(CHashBucket *nx, CHashBucket **prv)
{
   prev = prv;
   next = nx;
   if (nx)
      (nx)->prev = &next;
}

void CHashBucket::remove()
{
   *prev = next;
   if (next)
      next->prev = prev;
}

/* ----------------------------------------------------------------------------
      Define symbol. Value is assigned the current section counter.
---------------------------------------------------------------------------- */

void CSymbol::define(int ocls)
{
   // Set section and offset value
 /*  switch(CurrentSection) {
      case DATA_AREA:
         base = DATA_AREA;
         value = DataCounter;
         break;
      case BSS_AREA:
         base = BSS_AREA;
         value = BSSCounter;
         break;
      case CODE_AREA:
      default:
         base = CODE_AREA;
         value = ProgramCounter;
   }*/
	base = CurrentSection();
	value = SectionTbl.activeSection->Counter();
   if ((unsigned long)value < (unsigned)0x8000L || (unsigned)value >= (unsigned)0xffff8000L) {
      _long = 0;
      size = 'W';
   }
   else {
      _long = 1;
      size = 'L';
   }
   oclass = ocls;
   line = File[CurFileNum].LastLine;
   file = CurFileNum;
   defined = 1;
   label = 1;
}

void CSymbol::AddReference(unsigned __int64 n)
{
	CReference *r,*p;
	if (pass==lastpass) {
		p = NULL;
		for (r = references; r; r=r->next) {
			if (r->location == n)
				return;		// reference already recorded
			p = r;
		}
		r = NewReference();
		r->location = n;
		r->next = NULL;
		if (p)
			p->next = r;
		else
			references = r;
	}
}

/* ----------------------------------------------------------------------------
   Compare two symbols.
---------------------------------------------------------------------------- */
int CSymbol::cmp(CSymbol *ps)
{
   return strncmp((char *)Name(), (char *)ps->Name(), NAME_MAX);
}

static char *oclassstr(int n)
{
   static char *str[5] = {
      "NON", "PUB", "PRI", "COM", "EXT"
   };
   return (str[n]);
}

static char *basestr(int n)
{
   static char *str[4] = {
      "DATA", "CODE", "BSS", "NONE" };
   return str[n];
}

/* ----------------------------------------------------------------------------
   Print a single symbol.
---------------------------------------------------------------------------- */

int CSymbol::print(FILE *fp)
{
	CReference *r;
   fprintf(fp, "%-32.32s %3.3s  %4.4s   %c   %08lX%08lX   %c %5d   %s", Name(), oclassstr(oclass),
	   basestr(base), size, (__int32)(value >> 32), (__int32)(value & 0xffffffff), defined?' ':'u',
	  line, File[file].name);
   fprintf(fp, "   ");
	for (r = references; r; r=r->next)
		fprintf(fp, "%08lX ", r->location);
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

SHashVal CSymbol::hash(int ssz)
{
   static SHashVal h;
   unsigned g;
   unsigned char *nm = (unsigned char *)Name();

   h.delta = 1;
   h.hash = 0;
   for (; *nm; ++nm)
   {
      h.hash = ((h.hash << TWELVE_PERCENT) + *nm);
      if (g = (h.hash & HIGH_BITS))
         h.hash = ((h.hash^(g>>SEVENTY_FIVE_PERCENT)) & ~HIGH_BITS);
   }
   h.hash %= ssz; // ***** this is the size of the symbol table
   return h;
}


/*****************************************************************************
   Bucket Hash Class functions.
   Bucket hash works by hash value and seeing if that bucket is empty.
   If the bucket is empty then it is used. If the bucket is not empty
   then a linked list of buckets beginning with the bucket identified 
   by the hash is used.
*****************************************************************************/

CSymbolTbl::CSymbolTbl(unsigned nel)
{
   NumSyms = 0;
   sz = nel;
   string_table = NULL;
   tbl = (CHashBucket **)calloc(nel, sizeof(CHashBucket *));
   if (tbl == NULL)
      throw FatalErr(E_MEMORY);
}

CSymbolTbl::~CSymbolTbl()
{
	int nn;
	CHashBucket *hb,*hbn;

	for (nn = 0; nn < sz; nn++) {
		hb = tbl[nn];
		for (; hb; hb = hbn) {
			hbn = hb->next;
			free(hb);
		}
	}
	if (tbl) ::free(tbl);
	if (string_table) ::free(string_table);
};
/* -----------------------------------------------------------------------------
   Description :
      Allocates a new symbol table element.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */

CSymbol *CSymbolTbl::allocsym()
{
   CHashBucket *ptr;

   ptr = (CHashBucket *)calloc(1, sizeof(CHashBucket)+sizeof(CSymbol));
   if (ptr == NULL)
      throw FatalErr(E_MEMORY, "More memory required than is available.");
   return (CSymbol *)(ptr + 1);
}


/* -----------------------------------------------------------------------------
   void CSymbolTbl::freesym(void *ptr);
   ptr - pointer to data area of symbol table element.

   Description :
      Deallocates a symbol table element.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
void CSymbolTbl::freesym(CSymbol *ptr)
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
CSymbol *CSymbolTbl::insert(CSymbol *item)
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
void CSymbolTbl::remove(CSymbol *item)
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
CSymbol *CSymbolTbl::find(CSymbol *item)
{
   CHashBucket *p;

   for (p = tbl[item->hash(sz).hash]; p && item->cmp((CSymbol *)(p+1)); p = p->next);
   return p ? (CSymbol *)(p + 1) : NULL;
}


/* -----------------------------------------------------------------------------
   CSymbol *CSymbolTbl::next(CSymbol *ptr);

   Description :
      Advances to the next symbol in the symbol table with the same
   name.

   Returns :

----------------------------------------------------------------------------- */
CSymbol *CSymbolTbl::next(CSymbol *i_last)
{
   CHashBucket *last = (CHashBucket *)i_last -1;
   CSymbol *sym;

   for (; last->next; last = last->next) {
      sym = (CSymbol *)(last + 1);
      if (sym->cmp((CSymbol *)(last->next+1)) == 0)
         return (CSymbol *)(last->next + 1);
   }
   return NULL;
}


/* -----------------------------------------------------------------------------
   Description :
      Prints a symbol table. If sorted output is requested but there is
   insufficent memory then unsorted output results.

   Returns:
      (int) 1 if table is output as requested
            0 if memory for sorted table could not be allocated.
----------------------------------------------------------------------------- */
int CSymbolTbl::print(FILE *fp, int sortFlag)
{
   CHashBucket **OutTab, *hsym;
   CSymbol *sym;
   int i, j, ret = 1;

   /* -------------------------------------------------------------------
         This chunk of code builds an additional table containing
      pointers to every symbol element in the symbol table. It
      essentially maps all entries into a linear(vertical) list for
      sorting.
   ------------------------------------------------------------------- */
   fprintf(fp, "\nSymbol Table:\n");
   fprintf(fp, " #  Name                            OCLS  Base Len        Value       Def Line     File        References\n");
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
         sym = (CSymbol *)(hsym+1);
         fprintf(fp, "%3d ", i);
         sym->print(fp);
         fprintf(fp, "\n");
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
            sym = (CSymbol *)(hsym+1);
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
void CSymbolTbl::sort(CHashBucket **base)
{
   int i,j,gap;
   CHashBucket *tmp, **p1, **p2;
   CSymbol *ps1, *ps2;

   for (gap = 1; gap <= NumSyms; gap = 3 * gap + 1);

   for (gap /= 3; gap > 0; gap /= 3)
      for (i = gap; i < NumSyms; i++)
         for (j = i - gap; j >= 0; j -= gap) {
            p1 = &base[j];
            p2 = &base[j+gap];

            ps1 = (CSymbol *)((*p1)+1);
            ps2 = (CSymbol *)((*p2)+1);
            if (ps1->cmp(ps2) <= 0)
               break;

            tmp = *p1;
            *p1 = *p2;
            *p2 = tmp;
         }
}

// Build a table of strings 
// Update the symbol table with indicies
//
char *CSymbolTbl::BuildStringTable()
{
	CHashBucket *hsym, *p;
	CSymbol *sym;
	int nn;
	int maxlen;
	int i,j;
	char *buf;

	// Compute the length of the string table
	//
	maxlen = 0;
    for (j = i = 0; i < NumSyms; j++)
    {
        for (hsym = tbl[j]; hsym; hsym = hsym->next) {
	        sym = (CSymbol *)(hsym+1);
			maxlen = maxlen + strlen((char *)sym->name)+1;
			i++;
        }
    }
	maxlen += 2;

	buf = (char* )calloc(1,maxlen);

	// Copy name data to the string table
	//
	nn = 1;
    for (j = i = 0; i < NumSyms; j++)
    {
        for (hsym = tbl[j]; hsym; hsym = hsym->next) {
	        sym = (CSymbol *)(hsym+1);
			sym->name_ndx = nn;
			strcpy(&buf[nn],(char *)sym->name);
			nn += strlen((char *)sym->name) + 1;
			i++;
        }
    }
	string_table = buf;
	return buf;
}

/* -----------------------------------------------------------------------------
   Description:
----------------------------------------------------------------------------- */
CExtRefTbl::CExtRefTbl(unsigned nel)
{
   NumRefs = 0;
   sz = nel;
   tbl = (CExtRef *)calloc(nel, sizeof(CExtRef));
   if (tbl == NULL)
      throw FatalErr(E_MEMORY);
}



