#ifndef SYMBOL_HPP
#define SYMBOL_HPP

#include "NameTable.hpp"

extern NameTable nmTable;
extern char *segname(int seg);

class Symbol {
public:
    int name;       // name table index
    int64_t value;
    Symbol *next;
    Symbol *prev;
    char segment;
    char defined;
    char phaserr;
    char scope;     // P = public
} SYM;

class SymbolFactory {
public:
    Symbol *NewSymbol(char *name, char segment, int64_t val, char scope = ' ') {
        Symbol *sym;
        
        sym = new Symbol;
        sym->name = nmTable.AddName(name);
        sym->value = val;
        sym->segment = segment;
        sym->defined = 0;
        sym->phaserr = 0;
        sym->scope = scope;
        sym->next = (Symbol *)NULL;
        sym->prev = (Symbol *)NULL;
        return sym;
    };
};

class SymbolWarehouse {
public:
    int numsym;
    Symbol *syms[1000000];

    SymbolWarehouse() {
        numsym = 0;
    };
    Symbol *FindSymbol(char *name) {
        int rel;
        int low,mid,high;
    
        high = numsym-1;
        low = 0;
        mid = (high+low) >> 1;
        do {
            rel = strcmp(name, nmTable.GetName(syms[mid]->name));
            if (rel==0) {
                return syms[mid];
            }
            if (rel > 0) {
                if (low == mid)
                    low++;
                else
                    low = mid;
            }
            else
                high = mid;
            mid = (high+low) >> 1;
        } while (low < high);
        rel = strcmp(name, nmTable.GetName(syms[mid]->name));
        if (rel==0)
            return syms[mid];
        return (Symbol *)NULL;
    };

    int StoreSymbol(Symbol *sym)
    {
        int rel;
        int low,mid,high;
    
        if (numsym==0) {
            syms[0] = sym;
            return 1;
        }
        high = numsym-1;
        low = 0;
        mid = (high+low) >> 1;
        do {
            rel = strcmp(nmTable.GetName(sym->name), nmTable.GetName(syms[mid]->name));
            if (rel==0)        // symbol already in list
                return 0;
            if (rel > 0) {
                if (low == mid)
                    low++;
                else
                    low = mid;
            }
            else
                high = mid;
            mid = (high+low) >> 1;
        } while (low < high);
        rel = strcmp(nmTable.GetName(sym->name), nmTable.GetName(syms[mid]->name));
        if (rel > 0)
            mid++;
        memmove(&syms[mid+1],&syms[mid],(numsym-mid+1) * sizeof(Symbol *));
        syms[mid] = sym;
        return 1;    
    };

    void ListSymbols(FILE *ofp) {
        int nn;
        
        fprintf(ofp, "%d symbols\n", numsym);
        fprintf(ofp, "  Symbol Name                              seg     address\n"); 
        for (nn = 0; nn < numsym; nn++) {
            fprintf(ofp, "%c %-40s %6s  %06llx\n", syms[nn]->phaserr, nmTable.GetName(syms[nn]->name), segname(syms[nn]->segment), syms[nn]->value);
        }
    };
};

#endif
