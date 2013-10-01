#include <stdio.h>
#include <string.h>
#include "c:\cores\bc65xx\asm\err.h"
#include "HashTable.h"

namespace RTFClasses
{

	HashTable::HashTable(int nel)
	{
		numObjects = 0;
		sz = nel;
		tbl = (ListObject **)new ListObject *[nel];
		if (tbl == NULL)
			throw FatalErr(E_MEMORY);
		memset (tbl, 0, nel * sizeof(ListObject *));
	}

	HashTable::~HashTable()
	{
		ListObject *tmp, *obj;
		if (tbl)
		{
			for (int j = 0; j < sz; j++)
			{
				for (obj = tbl[j]; obj; obj = tmp) {
					tmp = obj->next;
					delete obj;
				}
			}
			delete[] tbl;
		}
	}

	ListObject **HashTable::getChain(ListObject *item) const
	{
		ListObject **p = &tbl[item->getHash().hash % sz];
		return p;
	}


	// insert always inserts at the head of the chain
	ListObject *HashTable::insert(ListObject *item)
	{
		if (item)
		{
			ListObject **p = getChain(item);
			item->insertBefore(*p);
			*p = item;
			numObjects++;
		}
		return item;
	}


	void HashTable::remove(ListObject *item)
	{
		if (item) {
			item->removeFromList();
			--numObjects;
		}
	}


	ListObject *HashTable::find(ListObject *item) const
	{
		ListObject *p;
	
		for (p = *getChain(item); p && item->cmp(p); p = p->getNext());
		return p;
	}


	// get a linear list of objects in the HashTable.
	ListObject **HashTable::getLinearList() const
	{
		ListObject **linearList;
		ListObject *obj;

		try {
			linearList = (ListObject **)new ListObject *[numObjects];
		}
		catch(...) {
			return NULL;
		}
		if (linearList==NULL)
			return NULL;
		memset(linearList, 0, numObjects * sizeof(ListObject *));

		int i, j;
		for (j = i = 0; j < sz; j++) {
			// Extract all hash clash elements from horizontal linked list.
			for (obj = tbl[j]; obj; obj = obj->getNext()) {
				if (i > numObjects)
					throw FatalErr(E_TBLOVR, "Internal error <getList()>, table overflow.\n");
				linearList[i] = obj;	// map to vertical list
				i++;
			}
		}
		return linearList;
	}


	void HashTable::printHeading(FILE *fp)
	{
		fprintf(fp, "\nHash Table:\n");
		fprintf(fp, " #  Name                            Nargs  Line   File\n");
	}


	/* -----------------------------------------------------------------------------
	      Prints a table.
	   Returns:
	      (int) 1 if table is output as requested
	            0 if memory for sorted table could not be allocated.
	----------------------------------------------------------------------------- */
	bool HashTable::printSorted(FILE *fp)
	{
		ListObject **OutTab;
		ListObject *obj;
		int i;
		
		OutTab = getLinearList();
		if (OutTab==NULL)
			return false;
			
		sort(OutTab);
		printHeading(fp);
		for (i = 0; i < numObjects; i++) {
			obj = OutTab[i];
			fprintf(fp, "%3d ", i);
			if (obj)
				obj->print(fp);
			else
				fputs("????", fp);
			fputs("\r\n",fp);
		}
		delete[] OutTab;
		return true;
	}


	bool HashTable::printUnsorted(FILE *fp)
	{
		ListObject *obj;
		int i, j;

		printHeading(fp);
		for (j = i = 0; j < sz; j++)
		{
			for (obj = tbl[j]; obj; obj = obj->getNext()) {
				fprintf(fp, "%3d ", i);
				if (obj)
					obj->print(fp);
				else
					fputs("?????", fp);
				fprintf(fp, "\n");
				i++;
			}
		}
		return true;
	}


	/* -----------------------------------------------------------------------------
	      Prints a symbol table. If sorted output is requested but there is
	   insufficent memory then unsorted output results.
	
	   Returns:
	      (int) 1 if table is output as requested
	            0 if memory for sorted table could not be allocated.
	----------------------------------------------------------------------------- */
	bool HashTable::print(FILE *fp, bool sortFlag)
	{
		if (sortFlag) {
			if (!printSorted(fp))
				printUnsorted(fp);
			else
				return true;
		}
		else
			printUnsorted(fp);
		return false;
	}

	bool HashTable::print(FILE *fp)
	{
		return print(fp, true);
	}

	// This routine performs a shell sort on an array of list objects

	void HashTable::sort(ListObject **base) const
	{
		int i,j,gap;
		ListObject *p1, *p2;
		
		if (numObjects==1) return;
		for (gap = 1; gap <= numObjects; gap = 3 * gap + 1);
		
		for (gap /= 3; gap > 0; gap /= 3)
			for (i = gap; i < numObjects; i++)
				for (j = i - gap; j >= 0; j -= gap) {
					p1 = base[j];
					p2 = base[j+gap];
					
					if(p1==NULL||p2==NULL)
						break;
					if (p1->cmp(p2) <= 0)
						break;

					base[j] = p2;
					base[j+gap] = p1;
				}
	}

	ListObject **HashTable::sort() const
	{
		ListObject **p = getLinearList();
		sort(p);
		return p;
	}
}
