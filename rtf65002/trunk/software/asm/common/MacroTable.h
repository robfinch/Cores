#pragma once

#include "Macro.h"

namespace RTFClasses
{
	class MacroTable
	{
		friend class Macro;
	public:
		int NumSyms;	// Number of macros stored in the table
		int sz;			// Number of elements in table
		Macro **tbl;	// pointer to table
	
		MacroTable(int);
		~MacroTable() { if (tbl) delete[] tbl; };
	
		int print(FILE *, int);
		void *next(void *);
	
		Macro *insert(Macro *);
		void remove(Macro *);
		Macro *find(Macro *);
		void sort(Macro **);
	};
}
