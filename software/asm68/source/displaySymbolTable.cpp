/* ===============================================================
    (C) 2004  Bird Computer
    All rights reserved.
=============================================================== */

#include <stdio.h>
#include "fasm68.h"
#include "err.h"

void displaySymbolTable()
{
	// Display symbol table.
	fpSym = fopen(fnameSym, "w");
	if (fpSym) {
		int ii;
		
		fprintf(fpSym, "Global symbols:\n");
		SymbolTbl->print(fpSym, 1);
		
		// Print local symbol tables
		fprintf(fpSym, "\n\nLocal symbols:\n");
		for (ii = 0; ii < FileNum; ii++)
			if (File[ii].lst) {
				fprintf(fpSym, "File:%s\n", File[ii].name);
				File[ii].lst->print(fpSym, 1);
				fprintf(fpSym, "\n\n");
			}
		
		MacroTbl->print(fpSym, 1);
		fclose(fpSym);
	}
	else
		Err(E_OPEN, fnameSym);
}
