#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include <malloc.h>
#include "err.h"
#include "HashVal.h"
#define ALLOC
#include "sym.h"
#undef ALLOC
#include "asm24.h"

/* ===============================================================
=============================================================== */

void HashBucket::insert(HashBucket *nx, HashBucket **prv)
{
	prev = prv;
	next = nx;
	if (nx)
		(nx)->prev = &next;
}

void HashBucket::remove()
{
	*prev = next;
	if (next)
		next->prev = prev;
}

/* ----------------------------------------------------------------------------
      Define symbol. Value is assigned the current section counter.
---------------------------------------------------------------------------- */

void Symbol::define(int ocls)
{
	// Set section and offset value
	switch(CurrentArea) {
		case DATA_AREA:
			base = DATA_AREA;
			value = DataCounter.val;
			break;
		case BSS_AREA:
			base = BSS_AREA;
			value = BSSCounter.val;
			break;
		case CODE_AREA:
		default:
			base = CODE_AREA;
			value = ProgramCounter.val;
	}
	if ((unsigned long)value < (unsigned)0x8000L || (unsigned)value >= (unsigned)0xffff8000L) {
		_long = false;
		size = 'H';
	}
	else {
		_long = true;
		size = 'W';
	}
	oclass = ocls;
	line = File[CurFileNum].LastLine;
	file = CurFileNum;
	defined = 1;
	label = 1;
}


/* ----------------------------------------------------------------------------
   Compare two symbols.
---------------------------------------------------------------------------- */
int Symbol::cmp(Symbol *ps)
{
	return strcmp((char *)name.buf(), (char *)ps->name.buf());
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

int Symbol::print(FILE *fp)
{
   fprintf(fp, "%-32.32s %3.3s  %4.4s   %c   %08lX%08lX   %5d   %s", name, oclassstr(oclass),
      basestr(base), size, (__int32)(value >> 32), (__int32)(value & 0xffffffff), line, File[file].name);
   return 1;
}

int Symbol::print2(FILE *fp)
{
	fprintf(fp, "%s    16'h%04lX", name, (__int32)(value & 0xffff));
	return 1;
}


/*****************************************************************************
   Bucket Hash Class functions.
   Bucket hash works by hash value and seeing if that bucket is empty.
   If the bucket is empty then it is used. If the bucket is not empty
   then a linked list of buckets beginning with the bucket identified 
   by the hash is used.
*****************************************************************************/

SymbolTable::SymbolTable(unsigned nel)
{
   NumSyms = 0;
   sz = nel;
   tbl = (HashBucket **)calloc(nel, sizeof(HashBucket *));
   if (tbl == NULL)
      throw Err(E_MEMORY);
}

SymbolTable::~SymbolTable()
{
	HashBucket *tmp, *sym;
	int i,j;
	// free all entries in the symbol table
	for (j = i = 0; i < NumSyms; j++)
	{
		for (sym = tbl[j]; sym; sym = tmp) {
			tmp = sym->next;
			freesym((Symbol*)(sym+1));
			i++;
		}
	}
	if (tbl)
		::free(tbl);
}

/* -----------------------------------------------------------------------------
   Description :
      Allocates a new symbol table element.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */

Symbol *SymbolTable::allocsym()
{
   HashBucket *ptr;

   ptr = (HashBucket *)calloc(1, sizeof(HashBucket)+sizeof(Symbol));
   if (ptr == NULL)
      throw Err(E_MEMORY, "More memory required than is available.");
   return (Symbol *)(ptr + 1);
}


/* -----------------------------------------------------------------------------
   void CSymbolTable::freesym(void *ptr);
   ptr - pointer to data area of symbol table element.

   Description :
      Deallocates a symbol table element.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
void SymbolTable::freesym(Symbol *ptr)
{
   free((char *)((HashBucket *)ptr - 1));
}


/* -----------------------------------------------------------------------------
   void *SymbolTableB::insert(void *item);
   item - pointer to entry to insert

   Description :
      Insert data item in table.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
Symbol *SymbolTable::insert(Symbol *item)
{
	HashBucket **p, *tmp, *hsym;

	hsym = (HashBucket *)item - 1;
	p = &tbl[item->getHash(sz).hash];
	tmp = *p;
	*p = hsym;
	hsym->insert(tmp, p);
	NumSyms++;
	return item;
};


/* -----------------------------------------------------------------------------
   void *CSymbolTable::remove(void *item);
   item - pointer to entry to remove

   Description :
      Removes data item in table.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
void SymbolTable::remove(Symbol *item)
{
   HashBucket *hsym = (HashBucket *)item - 1;

   if (item) {
      --NumSyms;
      if (*(hsym->prev) = hsym->next)
         hsym->next->prev = hsym->prev;
   }
}


/* -----------------------------------------------------------------------------
   void *CSymbolTable::find(void *item);
   item - pointer to entry to find

   Description :
      Find data item stored in table.
      
      The bucket from the table contains no data, it is just the head of
   a chain of buckets containing data.

   Returns :
      (void *) pointer to element data area.

----------------------------------------------------------------------------- */
Symbol *SymbolTable::find(Symbol *item)
{
   HashBucket *p;

   for (p = tbl[item->getHash(sz).hash]; p && item->cmp((Symbol *)(p+1)); p = p->next);
   return p ? (Symbol *)(p + 1) : NULL;
}


/* -----------------------------------------------------------------------------
   CSymbol *CSymbolTable::next(CSymbol *ptr);

   Description :
      Advances to the next symbol in the symbol table with the same
   name.

   Returns :

----------------------------------------------------------------------------- */
Symbol *SymbolTable::next(Symbol *i_last)
{
   HashBucket *last = (HashBucket *)i_last -1;
   Symbol *sym;

   for (; last->next; last = last->next) {
      sym = (Symbol *)(last + 1);
      if (sym->cmp((Symbol *)(last->next+1)) == 0)
         return (Symbol *)(last->next + 1);
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
int SymbolTable::print(FILE *fp, int sortFlag)
{
   HashBucket **OutTab, *hsym;
   Symbol *sym;
   int i, j, ret = 1;

   /* -------------------------------------------------------------------
         This chunk of code builds an additional table containing
      pointers to every symbol element in the symbol table. It
      essentially maps all entries into a linear(vertical) list for
      sorting.
   ------------------------------------------------------------------- */
   fprintf(fp, "\nSymbol Table:\n");
   fprintf(fp, " #  Name                            OCLS  Base Len        Value         Line     File\n");
   if (sortFlag) {
      OutTab = (HashBucket **)malloc(NumSyms * sizeof(HashBucket *));
      if (!OutTab) {
         ret = 0;
         goto nosort;
      }
      for (j = i = 0; i < NumSyms; j++) {
         // Extract all hash clash elements from horizontal linked list.
         for (hsym = tbl[j]; hsym; hsym = hsym->next) {
            if (i > NumSyms)
               throw Err(E_TBLOVR, "Internal error <print>, table overflow.\n");
            OutTab[i] = hsym;  // map to vertical list
            i++;
         }
      }

      // Now that we have a linear list we can sort and print
      sort(OutTab);
      for (i = 0; i < NumSyms; i++) {
         hsym = OutTab[i];
         sym = (Symbol *)(hsym+1);
         fprintf(fp, "%3d ", i);
         sym->print(fp);
         fprintf(fp, "\n");
      }
/*
      for (i = 0; i < NumSyms; i++) {
         hsym = OutTab[i];
         sym = (CSymbol *)(hsym+1);
         fprintf(fp, "`define ");
         sym->print2(fp);
         fprintf(fp, "\n");
      }
*/
      free(OutTab);
   }

   // Prints out symbol table unsorted.
   else
   {
nosort:
      for (j = i = 0; i < NumSyms; j++)
      {
         for (hsym = tbl[j]; hsym; hsym = hsym->next) {
            sym = (Symbol *)(hsym+1);
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
void SymbolTable::sort(HashBucket **base)
{
   int i,j,gap;
   HashBucket *tmp, **p1, **p2;
   Symbol *ps1, *ps2;

   for (gap = 1; gap <= NumSyms; gap = 3 * gap + 1);

   for (gap /= 3; gap > 0; gap /= 3)
      for (i = gap; i < NumSyms; i++)
         for (j = i - gap; j >= 0; j -= gap) {
            p1 = &base[j];
            p2 = &base[j+gap];

            ps1 = (Symbol *)((*p1)+1);
            ps2 = (Symbol *)((*p2)+1);
            if (ps1->cmp(ps2) <= 0)
               break;

            tmp = *p1;
            *p1 = *p2;
            *p2 = tmp;
         }
}



/* -----------------------------------------------------------------------------
   Description:
----------------------------------------------------------------------------- */
ExtRefTbl::ExtRefTbl(unsigned nel)
{
	NumRefs = 0;
	sz = nel;
	tbl = (ExtRef *)calloc(nel, sizeof(ExtRef));
	if (tbl == NULL)
		throw Err(E_MEMORY);
}



