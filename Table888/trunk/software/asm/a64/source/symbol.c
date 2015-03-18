// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// A64 - Assembler
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
#include <inttypes.h>
#include <stdio.h>
#include <string.h>
#include "symbol.h"
#include "a64.h"

extern FILE *ofp;
SYM syms[65535];
short int symorder[65535];
int numsym = 0;

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

char *segname(int seg)
{
     switch(seg) {
     case codeseg: return "code";
     case dataseg: return "data";
     case bssseg: return "bss";
     case tlsseg: return "tls";
     case rodataseg: return "rodata";
     case constseg: return "const";
     default: return "???";
     }
}

// ----------------------------------------------------------------------------
// Do a binary search to find the symbol.
// ----------------------------------------------------------------------------

SYM *find_symbol(char *name)
{
    int nn;
    int rel;
    int low,mid,high;

    high = numsym-1;
    low = 0;
    mid = (high+low) >> 1;
    do {
        nn = symorder[mid];
        rel = strcmp(name, nmTable.GetName(syms[nn].name));
        if (rel==0) {
            return &syms[nn];
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
    nn = symorder[mid];
    rel = strcmp(name, nmTable.GetName(syms[nn].name));
    if (rel==0)
        return &syms[nn];
    return (SYM *)NULL;    
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int insert_symbol(SYM *sym)
{
    int nn;
    int rel;
    int low,mid,high;
    int symndx = sym-&syms[0];

    if (numsym==0) {
        symorder[0] = symndx;
        return 1;
    }
    high = numsym-1;
    low = 0;
    mid = (high+low) >> 1;
    do {
        nn = symorder[mid];
        rel = strcmp(nmTable.GetName(sym->name), nmTable.GetName(syms[nn].name));
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
    nn = symorder[mid];
    rel = strcmp(nmTable.GetName(sym->name), nmTable.GetName(syms[nn].name));
    if (rel > 0)
        mid++;
    memmove(&symorder[mid+1],&symorder[mid],(numsym-mid+1) * sizeof(short int));
    symorder[mid] = symndx;
    return 1;    
}


// ----------------------------------------------------------------------------
// When the symbol is first setup we force the value to be a large one in
// order to force the assembler to generate a maximum size prefix in case the
// symbol ends up being unresolved.
// ----------------------------------------------------------------------------

SYM *new_symbol(char *name)
{
    if (numsym > 65535) {
        printf("Too many symbols.\r\n");
        return (SYM *)NULL;
    }
     syms[numsym].name = nmTable.AddName(name);
//     strncpy(syms[numsym].name, name, sizeof(syms[numsym].name)/sizeof(char)-1);
//     syms[numsym].name[199] = '\0';
     syms[numsym].value = 0x8000000000000000LL | numsym;
     syms[numsym].defined = 0;
     syms[numsym].segment = segment;
     syms[numsym].scope = ' ';
     syms[numsym].isExtern = 0;
     insert_symbol(&syms[numsym]);
     numsym++;
     return &syms[numsym-1];
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void DumpSymbols()
{
    int nn,qq;
    
    fprintf(ofp, "%d symbols\n", numsym);
    fprintf(ofp, "  Symbol Name                              seg     address\n"); 
    for (nn = 0; nn < numsym; nn++) {
        qq = symorder[nn];
        fprintf(ofp, "%c %-40s %6s  %06llx\n", syms[qq].phaserr, nmTable.GetName(syms[qq].name), segname(syms[qq].segment), syms[qq].value);
    }
}
