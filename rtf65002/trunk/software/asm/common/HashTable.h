#pragma once

#include "ListObject.h"

namespace RTFClasses
{
	class HashTable
	{
		ListObject **getChain(ListObject *) const;
	public:
		ListObject **getLinearList() const;
	public:
		int numObjects;	// Number of objects stored in the table
		int sz;			// Number of elements in table
		ListObject **tbl;	// pointer to table
		ListObject **tbl2;

		HashTable(int);
		~HashTable();

		virtual void printHeading(FILE *fp) const;
		bool printUnsorted(FILE *fp) const;
		bool printSorted(FILE *fp) const;	
		bool print(FILE *fp, bool doSort);
		bool print(FILE *);		// assume sorted
		void *next(void *);
	
		ListObject *insert(ListObject *);
		void remove(ListObject *);
		ListObject *find(ListObject *) const;
		ListObject **sort() const;
		void sort(ListObject **) const;
		int countObjects() const;
	};
}
