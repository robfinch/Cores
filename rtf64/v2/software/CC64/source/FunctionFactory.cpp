#include "stdafx.h"

Function* FunctionFactory::MakeFunction(int symnum)
{
	int count;

	for (count = 0; count < 3000; count++) {
		Function* sym = &compiler.functionTable[compiler.funcnum];
		if (!sym->valid) {
			ZeroMemory(sym, sizeof(Function));
			sym->alloced = true;
			sym->valid = TRUE;
			sym->NumParms = -1;
			sym->numa = -1;
			sym->params.SetOwner(symnum);
			sym->proto.SetOwner(symnum);
			sym->UsesTemps = true;
			sym->UsesStackParms = true;
			compiler.funcnum++;
			if (compiler.funcnum > 2999)
				compiler.funcnum = 0;
			return (sym);
		}
		compiler.funcnum++;
		if (compiler.funcnum > 2999)
			compiler.funcnum = 0;
	}
	dfs.printf("Too many functions.\n");
	throw new C64PException(ERR_TOOMANY_SYMBOLS, 1);
}
