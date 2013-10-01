#pragma once

#include "ListObject.h"

namespace RTFClasses
{
	class HashTable
	{
		ListObject **getChain(ListObject *) const;
		ListObject **getLinearList() const;
	public:
		int numObjects;	// Number of objects stored in the table
		int sz;			// Number of elements in table
		ListObject **tbl;	// pointer to table
	
		HashTable(int);
		~HashTable();

		virtual void printHeading(FILE *fp);
		bool printUnsorted(FILE *fp);
		bool printSorted(FILE *fp);	
		bool print(FILE *fp, bool doSort);
		bool print(FILE *);		// assume sorted
		void *next(void *);
	
		ListObject *insert(ListObject *);
		void remove(ListObject *);
		ListObject *find(ListObject *) const;
		ListObject **sort() const;
		void sort(ListObject **) const;
	};
}
