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
		tbl2 = tbl;
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
		int ndx;
		ListObject **p;
		HashVal h;
		h = item->getHash();
		ndx = h.hash % sz;
		p = &tbl[ndx];
		return p;
	}


	// insert always inserts at the head of the chain
	ListObject *HashTable::insert(ListObject *item)
	{
		ListObject *pp;

		if (item)
		{
			if (pp=find(item)) {
				if (pp==item)
					return item;
			}
			ListObject **p = getChain(item);
			item->insertBefore(*p);
			*p = item;
			numObjects++;
		}
		return item;
	}


	void HashTable::remove(ListObject *item)
	{
		ListObject **p,*q;

		p = getChain(item);
		q = item->next;
		if (item) {
			if (find(item)) {
				item->removeFromList();
				--numObjects;
				if (*p==item) {
					*p = q;
				}
			}
		}
	}


	ListObject *HashTable::find(ListObject *item) const
	{
		ListObject *p;
		ListObject *s;
		int ii = 0;

		s = *getChain(item);
		for (p = *getChain(item); p && item->cmp(p); p = p->getNext()) {
			if (p==s)
				if (ii > 0)
					throw "Stuck in loop.";
				else
					ii++;
		}
		return p;
	}


	// get a linear list of objects in the HashTable.
	ListObject **HashTable::getLinearList() const
	{
		ListObject **linearList;
		ListObject *obj;
		int cnt;

		cnt = countObjects();
		if (cnt != numObjects) {
			printf("cnt:%d num:%d\r\n", cnt, numObjects);
			getchar();
		}

		try {
			linearList = (ListObject **)new ListObject *[cnt];
		}
		catch(...) {
			return NULL;
		}
		if (linearList==NULL)
			return NULL;
		memset(linearList, 0, cnt * sizeof(ListObject *));

		int i, j;
		for (j = i = 0; j < sz; j++) {
			// Extract all hash clash elements from horizontal linked list.
			for (obj = tbl[j]; obj; obj = obj->getNext()) {
				if (i > cnt) {
					//goto xit;
					printUnsorted(stdout);
					throw FatalErr(E_TBLOVR, "Internal error <getList()>, table overflow.\n");
				}
				linearList[i] = obj;	// map to vertical list
				i++;
			}
		}
xit:;
		return linearList;
	}

	int HashTable::countObjects() const
	{
		int i,j;
		int cnt;
		ListObject *obj;

		for (cnt = j = i = 0; i < sz; i++) {
			for (obj = tbl[i]; obj; obj = obj->getNext())
				cnt++;
		}
		return cnt;
	}

	void HashTable::printHeading(FILE *fp) const
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
	bool HashTable::printSorted(FILE *fp) const
	{
		ListObject **OutTab;
		ListObject *obj;
		int i;
		int cnt = countObjects();
		
		OutTab = getLinearList();
		if (OutTab==NULL)
			return false;
			
		sort(OutTab);
		printHeading(fp);
		for (i = 0; i < cnt; i++) {
			obj = OutTab[i];
			fprintf(fp, "%3d ", i);
			if (obj)
				obj->print(fp);
			else
				fputs("????", fp);
			fputs("\n",fp);
		}
		delete[] OutTab;
		return true;
	}


	bool HashTable::printUnsorted(FILE *fp) const
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
		int cnt = countObjects();

		if (cnt==1) return;
		for (gap = 1; gap <= cnt; gap = 3 * gap + 1);
		
		for (gap /= 3; gap > 0; gap /= 3)
			for (i = gap; i < cnt; i++)
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
