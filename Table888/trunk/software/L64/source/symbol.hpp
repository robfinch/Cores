// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// L64 - Linker
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#ifndef SYMBOL_HPP
#define SYMBOL_HPP

#include "NameTable.hpp"

extern NameTable nmTable;
extern char *segname(int seg);
extern int trigger;

class Symbol {
public:
    int name;       // name table index
    int64_t value;
    char segment;
    char defined;
    char phaserr;
    char scope;     // P = public
public:
    char *GetName() { return nmTable.GetName(name); };
};

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
        return sym;
    };
};

class SymbolWarehouse {
public:
    int numsym;
    int maxsym;
    Symbol **syms;

    SymbolWarehouse() {
        maxsym = 30000;
        numsym = 0;
        syms = new Symbol *[maxsym];
    };
    ~SymbolWarehouse() {
        delete[] syms;
    }
    Symbol *FindSymbol(char *name) {
        int rel;
        int low,mid,high;

        if (numsym==0)
            return (Symbol *)NULL;    
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
        Symbol **ns;
    
        if (numsym==0) {
            syms[0] = sym;
            numsym++;
            return 1;
        }
        if (numsym>=maxsym-5) {
            ns = new Symbol *[maxsym+30000];
            memcpy(ns, syms, maxsym);
            maxsym += 30000;
            delete[] syms;
            syms = ns;
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
        numsym++;
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
