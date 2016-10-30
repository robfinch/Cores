#include "stdafx.h"

Finray::SymbolTable symbolTable;

namespace Finray
{
SymbolTable::SymbolTable()
{
	count = 0;
}

void SymbolTable::AddDefaultSymbols()
{
	Symbol sym;
	sym.varname = std::string("_x");
	sym.value.type = TYP_VECTOR;
	sym.value.v3 = Vector(1.0,0.0,0.0);
	Add(&sym);
	sym.varname = std::string("_y");
	sym.value.type = TYP_VECTOR;
	sym.value.v3 = Vector(0.0,1.0,0.0);
	Add(&sym);
	sym.varname = std::string("_z");
	sym.value.type = TYP_VECTOR;
	sym.value.v3 = Vector(0.0,0.0,1.0);
	Add(&sym);
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
