// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2017  Robert Finch, Waterloo
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
#include "stdafx.h"

extern FILE *ofp;
extern int pass;
int numsym = 0;

void ShellSort(void *, int, int, int (*)());   // Does a shellsort - like bsort()
SHashVal HashFnc(void *def);
int icmp (const void *n1, const void *n2);
int ncmp (char *n1, const void *n2);
SHashTbl HashInfo = { HashFnc, icmp, ncmp, 0, sizeof(SYM), NULL };

SHashVal HashFnc(void *d)
{
   SYM *def = (SYM *)d;
   return htSymHash(&HashInfo, nmTable.GetName(def->name));
}

int icmp (const void *m1, const void *m2)
{
    SYM *n1; SYM *n2;
    n1 = (SYM *)m1;
    n2 = (SYM *)m2;
	if (n1->name==NULL) return 1;
	if (n2->name==NULL) return -1;
  return (strcmp(nmTable.GetName(n1->name), nmTable.GetName(n2->name)));
}

int ncmp (char *m1, const void *m2)
{
    SYM *n2;
    n2 = (SYM *)m2;
	if (m1==NULL) return 1;
	if (n2->name==NULL) return -1;
  return (strcmp(m1, nmTable.GetName(n2->name)));
}

void SymbolInit()
{
   HashInfo.size = 65536;
   HashInfo.width = sizeof(SYM);
   if ((HashInfo.table = calloc(HashInfo.size, sizeof(SYM))) == NULL) {
      exit (1);
   }
}

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
    SYM *p;
    
    p = (SYM *)htFind2(&HashInfo, name);
    return p;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

SYM *insert_symbol(SYM *sym)
{
    SYM *p;

    if (!(p=(SYM *)htInsert(&HashInfo, sym)))
       printf("failed to insert symbol\r\n");
    if (p)
       p->ord = p-(SYM *)(HashInfo.table);
    return p;
}


// ----------------------------------------------------------------------------
// When the symbol is first setup we force the value to be a large one in
// order to force the assembler to generate a maximum size prefix in case the
// symbol ends up being unresolved.
// ----------------------------------------------------------------------------

SYM *new_symbol(char *name)
{
    SYM *p;
    SYM ts;

    if (p = find_symbol(name)) {
        printf("Symbol already in table.\r\n");
        return p;
    }
    if (numsym > 65525) {
        printf("Too many symbols.\r\n");
        return (SYM *)NULL;
    }
    if (pass > 5) {
        //printf("%s: added\r\n", name);
    }
     ts.name = nmTable.AddName(name);
//     strncpy(syms[numsym].name, name, sizeof(syms[numsym].name)/sizeof(char)-1);
//     syms[numsym].name[199] = '\0';
     ts.value.low = 0x8000000000000000LL | numsym;
	 ts.value.high = 0; 
     ts.defined = 0;
     ts.segment = segment;
     ts.scope = ' ';
     ts.isExtern = 0;
     p = insert_symbol(&ts);
     numsym++;
     return p;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void DumpSymbols()
{
    int nn,ii,blnk,count;
    SYM *dp, *pt;

   pt = (SYM *)HashInfo.table;

   // Pack any 'holes' in the table
   for(blnk= ii = count = 0; count < HashInfo.size; count++, ii++) {
      dp = &pt[ii];
      if (dp->name) {
         if (blnk > 0)
            memmove(&pt[ii-blnk], &pt[ii], (HashInfo.size - count) * sizeof(SYM));
         ii -= blnk;
         blnk = 0;
      }
      else
         blnk++;
   }

   // Sort the table
   qsort(pt, ii, sizeof(SYM), icmp);

    
    fprintf(ofp, "%d symbols\n", numsym);
    fprintf(ofp, "  Symbol Name                              seg     address bits\n"); 
    for (nn = 0; nn < ii; nn++) {
//        qq = symorder[nn];
        dp = &pt[nn];
        if (dp->name)
        fprintf(ofp, "%c %-40s %6s  %06llx %d\n", dp->phaserr, nmTable.GetName(dp->name), segname(dp->segment), dp->value.low, dp->bits);
    }
}
