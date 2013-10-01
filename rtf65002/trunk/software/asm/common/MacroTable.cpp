#include <stdio.h>
#include "buf.h"
#include "err.h"
#include "MacroTable.h"
#include "Assembler.h"

namespace RTFClasses
{

	MacroTable::MacroTable(int nel)
	{
		NumSyms = 0;
		sz = nel;
		tbl = (Macro **)new (Macro *)[nel];
		if (tbl == NULL)
			throw FatalErr(E_MEMORY);
	}


	Macro *MacroTable::insert(Macro *item)
	{
		Macro **p = &tbl[item->getHash().hash % sz];
		item->insertBefore(*p);
		*p = item;
		NumSyms++;
		return item;
	}


	void MacroTable::remove(Macro *item)
	{
		if (item) {
			item->removeFromList();
			--NumSyms;
		}
	}


	Macro *MacroTable::find(Macro *item)
	{
	Macro *p;

	for (p = tbl[item->getHash(sz).hash]; p && item->cmp((Macro *)(p+1)); p = p->next);
	return p ? (Macro *)(p + 1) : NULL;
	}


/* -----------------------------------------------------------------------------
   Description :
      Prints a symbol table. If sorted output is requested but there is
   insufficent memory then unsorted output results.

   Returns:
      (int) 1 if table is output as requested
            0 if memory for sorted table could not be allocated.
----------------------------------------------------------------------------- */
int MacroTable::print(FILE *fp, int sortFlag)
{
	Macro **OutTab, *hsym;
	Macro *sym;
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
		try {
			OutTab = (Macro **)new (Macro *)[NumSyms];
		}
		catch(...) {
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
			sym = (Macro *)(hsym+1);
			fprintf(fp, "%3d ", i);
			sym->print(fp);
		}
		delete[] OutTab;
	}

   // Prints out symbol table unsorted.
   else
   {
nosort:
      for (j = i = 0; i < NumSyms; j++)
      {
         for (hsym = tbl[j]; hsym; hsym = hsym->next) {
            sym = (Macro *)(hsym+1);
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
void MacroTable::sort(HashBucket **base)
{
   int i,j,gap;
   Macro *tmp, **p1, **p2;
   Macro *ps1, *ps2;

   for (gap = 1; gap <= NumSyms; gap = 3 * gap + 1);

   for (gap /= 3; gap > 0; gap /= 3)
      for (i = gap; i < NumSyms; i++)
         for (j = i - gap; j >= 0; j -= gap) {
            p1 = &base[j];
            p2 = &base[j+gap];

            ps1 = (Macro *)((*p1)+1);
            ps2 = (Macro *)((*p2)+1);
            if (ps1->cmp(ps2) <= 0)
               break;

            tmp = *p1;
            *p1 = *p2;
            *p2 = tmp;
         }
}

}
