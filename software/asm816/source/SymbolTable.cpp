#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include "err.h"
#include "HashVal.h"
#include "sym.h"


namespace RTFClasses
{
	//      Advances to the next symbol in the symbol table with the same
	//   name.

	Symbol *SymbolTable::next(Symbol *last)
	{
		for (; last; last = last->next) {
			if (last->equals(last->next))
				return last->next;
		}
		return NULL;
	}

	void SymbolTable::printHeading(FILE *fp)
	{
		fprintf(fp, "\nSymbol Table:\n");
		fprintf(fp, " #  Name                            OCLS  Base Len        Value         Line     File\n");
	}


	/* -----------------------------------------------------------------------------
			Prints a symbol table. If sorted output is requested but there is
		insufficent memory then unsorted output results.

		Returns:
			(int) 1 if table is output as requested
					0 if memory for sorted table could not be allocated.
	----------------------------------------------------------------------------- */
	bool SymbolTable::print(FILE *fp, int sortFlag)
	{
		return HashTable::print(fp, sortFlag);
	}
}


