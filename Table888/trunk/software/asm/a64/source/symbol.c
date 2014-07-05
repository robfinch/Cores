#include <inttypes.h>
#include <stdio.h>
#include <string.h>
#include "symbol.h"

extern FILE *ofp;
SYM syms[65535];
short int symorder[65535];
int numsym = 0;

// Do a binary search to find the symbol.
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
        rel = strcmp(name, syms[nn].name);
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
    rel = strcmp(name, syms[nn].name);
    if (rel==0)
        return &syms[nn];
    return (SYM *)NULL;    
}


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
        rel = strcmp(sym->name, syms[nn].name);
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
    rel = strcmp(sym->name, syms[nn].name);
    if (rel > 0)
        mid++;
    memmove(&symorder[mid+1],&symorder[mid],(numsym-mid+1) * sizeof(short int));
    symorder[mid] = symndx;
    return 1;    
}


SYM *new_symbol(char *name)
{
    if (numsym > 65535) {
        printf("Too many symbols.\r\n");
        return (SYM *)NULL;
    }
     strncpy(syms[numsym].name, name, sizeof(syms[numsym].name)/sizeof(char)-1);
     syms[numsym].name[199] = '\0';
     syms[numsym].value = 0;
     syms[numsym].defined = 0;
     insert_symbol(&syms[numsym]);
     numsym++;
     return &syms[numsym-1];
}

void DumpSymbols()
{
    int nn,qq;
    
    fprintf(ofp, "%d symbols\n", numsym);
    fprintf(ofp, "  Symbol Name                            seg address\n"); 
    for (nn = 0; nn < numsym; nn++) {
        qq = symorder[nn];
        fprintf(ofp, "%c %-40s %d  %06llx\n", syms[qq].phaserr, syms[qq].name, syms[qq].segment, syms[qq].value);
    }
}
