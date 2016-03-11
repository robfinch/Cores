#include "stdafx.h"

Finray::SymbolTable symbolTable;

namespace Finray
{
SymbolTable::SymbolTable()
{
	count = 0;
}

Symbol *SymbolTable::Find(std::string nm)
{
	int nn;

	for (nn = 0; nn < count; nn++) {
		if (symbols[nn].varname == nm)
			return &symbols[nn];
	}
	return nullptr;
}

void SymbolTable::Add(Symbol *sym)
{
	Symbol *s = Find(sym->varname);

	if (s) {
		s->value = sym->value;
	}
	else if (count < 1000) {
		symbols[count].varname = sym->varname;
		symbols[count].value = sym->value;
		count++;
	}
	else {
		throw gcnew Finray::FinrayException(ERR_TOOMANY_SYMBOLS,0);
	}
}

};
